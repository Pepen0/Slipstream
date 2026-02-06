#include "dashboard_state.h"
#include "logger.h"
#include "session_store.h"

#include "dashboard/v1/dashboard.grpc.pb.h"

#include <chrono>
#include <mutex>
#include <thread>

using dashboard::v1::CalibrateRequest;
using dashboard::v1::CalibrateResponse;
using dashboard::v1::CancelCalibrationRequest;
using dashboard::v1::CancelCalibrationResponse;
using dashboard::v1::DashboardService;
using dashboard::v1::EStopRequest;
using dashboard::v1::EStopResponse;
using dashboard::v1::EndSessionRequest;
using dashboard::v1::EndSessionResponse;
using dashboard::v1::GetStatusRequest;
using dashboard::v1::GetStatusResponse;
using dashboard::v1::ListSessionsRequest;
using dashboard::v1::ListSessionsResponse;
using dashboard::v1::SetProfileRequest;
using dashboard::v1::SetProfileResponse;
using dashboard::v1::StartSessionRequest;
using dashboard::v1::StartSessionResponse;
using dashboard::v1::Status;
using dashboard::v1::TelemetrySample;
using dashboard::v1::TelemetryStreamRequest;

namespace slipstream::dashboard {

static Status::State to_proto_state(DashboardState state) {
  switch (state) {
    case DashboardState::Idle:
      return Status::STATE_IDLE;
    case DashboardState::Active:
      return Status::STATE_ACTIVE;
    case DashboardState::Fault:
      return Status::STATE_FAULT;
    case DashboardState::Init:
    default:
      return Status::STATE_INIT;
  }
}

static Status::CalibrationState to_proto_calibration_state(CalibrationState state) {
  switch (state) {
    case CalibrationState::Idle:
      return Status::CALIBRATION_IDLE;
    case CalibrationState::Running:
      return Status::CALIBRATION_RUNNING;
    case CalibrationState::Passed:
      return Status::CALIBRATION_PASSED;
    case CalibrationState::Failed:
      return Status::CALIBRATION_FAILED;
    case CalibrationState::Unknown:
    default:
      return Status::CALIBRATION_UNKNOWN;
  }
}

class DashboardServiceImpl final : public DashboardService::Service {
public:
  DashboardServiceImpl() = default;

  void update_telemetry(const TelemetrySample &sample) {
    {
      std::lock_guard<std::mutex> lock(mu_);
      auto status = state_.get_status();
      if (status.session_active && !status.session_id.empty()) {
        TelemetryRecord record{};
        record.timestamp_ns = sample.timestamp_ns();
        record.pitch_rad = sample.pitch_rad();
        record.roll_rad = sample.roll_rad();
        record.left_target_m = sample.left_target_m();
        record.right_target_m = sample.right_target_m();
        record.latency_ms = sample.latency_ms();
        store_.append_telemetry(status.session_id, record);
      }
    }
    std::lock_guard<std::mutex> lock(telemetry_mu_);
    last_sample_ = sample;
    telemetry_ready_ = true;
  }

  grpc::Status GetStatus(grpc::ServerContext *, const GetStatusRequest *, GetStatusResponse *resp) override {
    std::lock_guard<std::mutex> lock(mu_);
    auto status = state_.get_status();
    auto *out = resp->mutable_status();
    out->set_state(to_proto_state(status.state));
    out->set_estop_active(status.estop_active);
    out->set_session_active(status.session_active);
    out->set_active_profile(status.active_profile);
    out->set_session_id(status.session_id);
    out->set_last_error(status.last_error);
    out->set_updated_at_ns(status.updated_at_ns);
    out->set_calibration_state(to_proto_calibration_state(status.calibration_state));
    out->set_calibration_progress(status.calibration_progress);
    out->set_calibration_message(status.calibration_message);
    out->set_calibration_attempts(status.calibration_attempts);
    out->set_last_calibration_at_ns(status.last_calibration_at_ns);
    return grpc::Status::OK;
  }

  grpc::Status Calibrate(grpc::ServerContext *, const CalibrateRequest *req, CalibrateResponse *resp) override {
    std::lock_guard<std::mutex> lock(mu_);
    auto status = state_.calibrate(req->profile_id());
    log_info("Calibrate profile=" + req->profile_id());
    resp->set_ok(status.calibration_state != CalibrationState::Failed);
    resp->set_message(status.calibration_message);
    return grpc::Status::OK;
  }

  grpc::Status CancelCalibration(grpc::ServerContext *, const CancelCalibrationRequest *,
                                 CancelCalibrationResponse *resp) override {
    std::lock_guard<std::mutex> lock(mu_);
    auto status = state_.cancel_calibration();
    log_warn("Calibration canceled");
    resp->set_ok(true);
    resp->set_message(status.calibration_message);
    return grpc::Status::OK;
  }

  grpc::Status SetProfile(grpc::ServerContext *, const SetProfileRequest *req, SetProfileResponse *resp) override {
    std::lock_guard<std::mutex> lock(mu_);
    auto status = state_.set_profile(req->profile_id());
    log_info("SetProfile profile=" + req->profile_id());
    resp->set_ok(true);
    resp->set_active_profile(status.active_profile);
    return grpc::Status::OK;
  }

  grpc::Status EStop(grpc::ServerContext *, const EStopRequest *req, EStopResponse *resp) override {
    std::lock_guard<std::mutex> lock(mu_);
    state_.estop(req->engaged(), req->reason());
    log_warn(std::string("EStop ") + (req->engaged() ? "ENGAGED" : "RELEASED"));
    resp->set_ok(true);
    return grpc::Status::OK;
  }

  grpc::Status StartSession(grpc::ServerContext *, const StartSessionRequest *req, StartSessionResponse *resp) override {
    std::lock_guard<std::mutex> lock(mu_);
    state_.start_session(req->session_id());
    SessionMetadata meta;
    meta.session_id = req->session_id();
    meta.track = req->track();
    meta.car = req->car();
    meta.start_time_ns = req->start_time_ns();
    if (meta.start_time_ns == 0) {
      meta.start_time_ns = state_.get_status().updated_at_ns;
    }
    meta.end_time_ns = 0;
    meta.duration_ms = 0;

    store_.start_session(meta);
    log_info("StartSession id=" + req->session_id());
    resp->set_ok(true);
    return grpc::Status::OK;
  }

  grpc::Status EndSession(grpc::ServerContext *, const EndSessionRequest *req, EndSessionResponse *resp) override {
    std::lock_guard<std::mutex> lock(mu_);
    state_.end_session(req->session_id());
    store_.end_session(req->session_id(), state_.get_status().updated_at_ns);
    log_info("EndSession id=" + req->session_id());
    resp->set_ok(true);
    return grpc::Status::OK;
  }

  grpc::Status ListSessions(grpc::ServerContext *, const ListSessionsRequest *, ListSessionsResponse *resp) override {
    std::lock_guard<std::mutex> lock(mu_);
    auto sessions = store_.list_sessions();
    for (const auto &session : sessions) {
      auto *out = resp->add_sessions();
      out->set_session_id(session.session_id);
      out->set_track(session.track);
      out->set_car(session.car);
      out->set_start_time_ns(session.start_time_ns);
      out->set_end_time_ns(session.end_time_ns);
      out->set_duration_ms(session.duration_ms);
    }
    return grpc::Status::OK;
  }

  grpc::Status StreamTelemetry(grpc::ServerContext *ctx,
                               const TelemetryStreamRequest *,
                               grpc::ServerWriter<TelemetrySample> *writer) override {
    log_info("StreamTelemetry start");
    TelemetrySample last_sent;
    while (!ctx->IsCancelled()) {
      {
        std::lock_guard<std::mutex> lock(telemetry_mu_);
        if (telemetry_ready_) {
          last_sent = last_sample_;
        }
      }
      writer->Write(last_sent);
      std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    log_info("StreamTelemetry end");
    return grpc::Status::OK;
  }

private:
  std::mutex mu_;
  DashboardStateMachine state_{};
  SessionStore store_{"data/sessions"};

  std::mutex telemetry_mu_;
  TelemetrySample last_sample_{};
  bool telemetry_ready_ = false;
};

DashboardService::Service *make_dashboard_service() {
  return new DashboardServiceImpl();
}

} // namespace slipstream::dashboard
