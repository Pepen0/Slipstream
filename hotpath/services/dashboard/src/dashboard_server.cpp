#include "dashboard_state.h"
#include "logger.h"
#include "session_store.h"

#include "dashboard/v1/dashboard.grpc.pb.h"
#include "protocol.h"
#include "serial_port.h"

#include <atomic>
#include <chrono>
#include <cctype>
#include <condition_variable>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

using dashboard::v1::CalibrateRequest;
using dashboard::v1::CalibrateResponse;
using dashboard::v1::CancelCalibrationRequest;
using dashboard::v1::CancelCalibrationResponse;
using dashboard::v1::DashboardService;
using dashboard::v1::EStopRequest;
using dashboard::v1::EStopResponse;
using dashboard::v1::EndSessionRequest;
using dashboard::v1::EndSessionResponse;
using dashboard::v1::GetSessionTelemetryRequest;
using dashboard::v1::GetSessionTelemetryResponse;
using dashboard::v1::GetStatusRequest;
using dashboard::v1::GetStatusResponse;
using dashboard::v1::InputEvent;
using dashboard::v1::InputEventStreamRequest;
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

namespace {

static constexpr uint16_t kMcuPttMagic = 0x5054u;
static constexpr uint8_t kMcuPttEventDown = 1u;
static constexpr uint8_t kMcuPttEventUp = 2u;
static constexpr uint16_t kMcuMaintenanceMagic = 0xB007u;
static constexpr uint8_t kMcuProfileCarTypes = 8u;
static constexpr float kMcuForceIntensityMin = 0.10f;
static constexpr float kMcuForceIntensityMax = 1.00f;
static constexpr float kMcuMotionRangeMin = 0.20f;
static constexpr float kMcuMotionRangeMax = 1.00f;

enum class McuMaintenanceOp : uint8_t {
  UpdateRequest = 1,
  UpdateArm = 2,
  UpdateAbort = 3,
  SetTuning = 0x10,
  SaveProfile = 0x11,
  SwitchProfile = 0x12,
  LoadProfile = 0x13,
};

static uint64_t now_ns() {
  using clock = std::chrono::system_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(
             clock::now().time_since_epoch())
      .count();
}

static uint32_t read_u32(const uint8_t *data) {
  return static_cast<uint32_t>(data[0]) |
         (static_cast<uint32_t>(data[1]) << 8) |
         (static_cast<uint32_t>(data[2]) << 16) |
         (static_cast<uint32_t>(data[3]) << 24);
}

static uint16_t read_u16(const uint8_t *data) {
  return static_cast<uint16_t>(data[0]) |
         (static_cast<uint16_t>(data[1]) << 8);
}

static bool env_enabled(const char *name, bool fallback) {
  const char *value = std::getenv(name);
  if (!value || value[0] == '\0') {
    return fallback;
  }
  return !(std::strcmp(value, "0") == 0 || std::strcmp(value, "false") == 0 ||
           std::strcmp(value, "FALSE") == 0);
}

static std::string default_mcu_port() {
#ifdef _WIN32
  return "COM3";
#else
  return "/dev/ttyACM0";
#endif
}

static int env_int(const char *name, int fallback) {
  const char *value = std::getenv(name);
  if (!value || value[0] == '\0') {
    return fallback;
  }
  try {
    return std::stoi(value);
  } catch (...) {
    return fallback;
  }
}

static float clampf(float value, float min_value, float max_value) {
  if (value < min_value) {
    return min_value;
  }
  if (value > max_value) {
    return max_value;
  }
  return value;
}

static float env_float(const char *name, float fallback) {
  const char *value = std::getenv(name);
  if (!value || value[0] == '\0') {
    return fallback;
  }
  try {
    return std::stof(value);
  } catch (...) {
    return fallback;
  }
}

static uint8_t hash_profile_to_car_type(const std::string &profile_id) {
  uint32_t hash = 2166136261u;
  for (char ch : profile_id) {
    hash ^= static_cast<uint8_t>(ch);
    hash *= 16777619u;
  }
  return static_cast<uint8_t>(hash % kMcuProfileCarTypes);
}

static uint8_t infer_car_type(const std::string &profile_id) {
  uint32_t numeric = 0u;
  bool in_number = false;
  for (char ch : profile_id) {
    if (std::isdigit(static_cast<unsigned char>(ch)) != 0) {
      in_number = true;
      numeric = (numeric * 10u) + static_cast<uint32_t>(ch - '0');
      continue;
    }
    if (in_number) {
      break;
    }
  }
  if (in_number) {
    return static_cast<uint8_t>(numeric % kMcuProfileCarTypes);
  }
  if (profile_id.empty()) {
    return 0u;
  }
  return hash_profile_to_car_type(profile_id);
}

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

#pragma pack(push, 1)
struct McuPttEventPayload {
  uint16_t magic;
  uint8_t event;
  uint8_t source;
  uint32_t uptime_ms;
  uint8_t pressed;
  uint8_t reserved[3];
};
#pragma pack(pop)

#pragma pack(push, 1)
struct McuMaintenancePayload {
  uint16_t magic;
  uint8_t opcode;
  uint8_t arg0;
  uint32_t token;
};

struct McuMaintenanceTuningPayload {
  uint16_t magic;
  uint8_t opcode;
  uint8_t car_type;
  uint32_t token;
  float force_intensity;
  float motion_range;
};
#pragma pack(pop)

static_assert(sizeof(McuPttEventPayload) == 12,
              "McuPttEventPayload size unexpected");
static_assert(sizeof(McuMaintenancePayload) == 8,
              "McuMaintenancePayload size unexpected");
static_assert(sizeof(McuMaintenanceTuningPayload) == 16,
              "McuMaintenanceTuningPayload size unexpected");

} // namespace

class DashboardServiceImpl final : public DashboardService::Service {
public:
  DashboardServiceImpl() {
    default_force_intensity_ = clampf(
        env_float("SLIPSTREAM_MCU_FORCE_INTENSITY", 1.0f),
        kMcuForceIntensityMin, kMcuForceIntensityMax);
    default_motion_range_ = clampf(
        env_float("SLIPSTREAM_MCU_MOTION_RANGE", 1.0f),
        kMcuMotionRangeMin, kMcuMotionRangeMax);
    if (!env_enabled("SLIPSTREAM_MCU_BRIDGE", true)) {
      log_info("MCU bridge disabled via SLIPSTREAM_MCU_BRIDGE");
      return;
    }
    const char *port_env = std::getenv("SLIPSTREAM_MCU_PORT");
    mcu_port_ = (port_env && port_env[0] != '\0') ? port_env : default_mcu_port();
    mcu_baud_ = env_int("SLIPSTREAM_MCU_BAUD", 115200);
    mcu_heartbeat_interval_ms_ = env_int("SLIPSTREAM_MCU_HEARTBEAT_MS", 50);
    if (mcu_heartbeat_interval_ms_ <= 0) {
      mcu_heartbeat_interval_ms_ = 50;
    }
    bridge_running_.store(true);
    bridge_thread_ = std::thread([this] { mcu_bridge_loop(); });
  }

  ~DashboardServiceImpl() override {
    bridge_running_.store(false);
    if (bridge_thread_.joinable()) {
      bridge_thread_.join();
    }
    input_cv_.notify_all();
  }

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
        record.speed_kmh = sample.speed_kmh();
        record.gear = sample.gear();
        record.engine_rpm = sample.engine_rpm();
        record.track_progress = sample.track_progress();
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
    bool bridge_ok = true;
    const uint8_t car_type = infer_car_type(req->profile_id());
    if (status.calibration_state != CalibrationState::Failed) {
      const uint32_t token = static_cast<uint32_t>(now_ns());
      const bool queued_switch = queue_profile_switch(car_type, token);
      const bool queued_tuning = queue_profile_tuning(
          car_type, default_force_intensity_, default_motion_range_, token);
      const bool queued_save = queue_profile_save(car_type, token);
      bridge_ok = !bridge_running_.load() ||
                  (queued_switch && queued_tuning && queued_save);
    }
    log_info("Calibrate profile=" + req->profile_id() + " car_type=" +
             std::to_string(car_type));
    resp->set_ok(status.calibration_state != CalibrationState::Failed && bridge_ok);
    if (!bridge_ok) {
      resp->set_message(status.calibration_message +
                        " (MCU profile command queue unavailable)");
    } else {
      resp->set_message(status.calibration_message);
    }
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
    const uint8_t car_type = infer_car_type(req->profile_id());
    bool queued_switch = true;
    if (!req->profile_id().empty()) {
      const uint32_t token = static_cast<uint32_t>(now_ns());
      queued_switch = queue_profile_switch(car_type, token);
    }
    log_info("SetProfile profile=" + req->profile_id() + " car_type=" +
             std::to_string(car_type));
    resp->set_ok(!bridge_running_.load() || queued_switch);
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

  grpc::Status GetSessionTelemetry(grpc::ServerContext *, const GetSessionTelemetryRequest *req,
                                   GetSessionTelemetryResponse *resp) override {
    std::lock_guard<std::mutex> lock(mu_);
    auto records = store_.read_telemetry(req->session_id(), req->max_samples());
    for (const auto &record : records) {
      auto *out = resp->add_samples();
      out->set_timestamp_ns(record.timestamp_ns);
      out->set_pitch_rad(record.pitch_rad);
      out->set_roll_rad(record.roll_rad);
      out->set_left_target_m(record.left_target_m);
      out->set_right_target_m(record.right_target_m);
      out->set_latency_ms(record.latency_ms);
      out->set_speed_kmh(record.speed_kmh);
      out->set_gear(record.gear);
      out->set_engine_rpm(record.engine_rpm);
      out->set_track_progress(record.track_progress);
    }
    return grpc::Status::OK;
  }

  grpc::Status StreamTelemetry(grpc::ServerContext *ctx,
                               const TelemetryStreamRequest *,
                               grpc::ServerWriter<TelemetrySample> *writer)
      override {
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

  grpc::Status StreamInputEvents(grpc::ServerContext *ctx,
                                 const InputEventStreamRequest *,
                                 grpc::ServerWriter<InputEvent> *writer)
      override {
    log_info("StreamInputEvents start");
    uint64_t cursor = 0;
    while (!ctx->IsCancelled()) {
      std::vector<InputEvent> pending;
      {
        std::unique_lock<std::mutex> lock(input_mu_);
        input_cv_.wait_for(lock, std::chrono::milliseconds(100), [&] {
          return ctx->IsCancelled() ||
                 (!input_events_.empty() &&
                  input_events_.back().sequence() > cursor);
        });
        if (ctx->IsCancelled()) {
          break;
        }
        for (const auto &event : input_events_) {
          if (event.sequence() > cursor) {
            pending.push_back(event);
          }
        }
      }
      for (const auto &event : pending) {
        if (!writer->Write(event)) {
          log_warn("StreamInputEvents write failed");
          return grpc::Status::OK;
        }
        if (event.sequence() > cursor) {
          cursor = event.sequence();
        }
      }
    }
    log_info("StreamInputEvents end");
    return grpc::Status::OK;
  }

private:
  struct OutboundMcuPacket {
    heartbeat::PacketType type = heartbeat::PacketType::Heartbeat;
    std::vector<uint8_t> payload;
  };

  bool queue_mcu_packet(heartbeat::PacketType type, const uint8_t *payload,
                        size_t payload_len) {
    if (!bridge_running_.load()) {
      return false;
    }
    if (payload_len > heartbeat::kMaxPayload) {
      return false;
    }
    OutboundMcuPacket packet;
    packet.type = type;
    if (payload != nullptr && payload_len > 0) {
      packet.payload.assign(payload, payload + payload_len);
    }
    std::lock_guard<std::mutex> lock(mcu_tx_mu_);
    constexpr size_t kMcuTxBacklog = 128;
    if (mcu_tx_queue_.size() >= kMcuTxBacklog) {
      mcu_tx_queue_.pop_front();
    }
    mcu_tx_queue_.push_back(std::move(packet));
    return true;
  }

  bool queue_profile_switch(uint8_t car_type, uint32_t token) {
    McuMaintenancePayload payload{};
    payload.magic = kMcuMaintenanceMagic;
    payload.opcode = static_cast<uint8_t>(McuMaintenanceOp::SwitchProfile);
    payload.arg0 = static_cast<uint8_t>(car_type % kMcuProfileCarTypes);
    payload.token = token;
    return queue_mcu_packet(heartbeat::PacketType::Maintenance,
                            reinterpret_cast<const uint8_t *>(&payload),
                            sizeof(payload));
  }

  bool queue_profile_save(uint8_t car_type, uint32_t token) {
    McuMaintenancePayload payload{};
    payload.magic = kMcuMaintenanceMagic;
    payload.opcode = static_cast<uint8_t>(McuMaintenanceOp::SaveProfile);
    payload.arg0 = static_cast<uint8_t>(car_type % kMcuProfileCarTypes);
    payload.token = token;
    return queue_mcu_packet(heartbeat::PacketType::Maintenance,
                            reinterpret_cast<const uint8_t *>(&payload),
                            sizeof(payload));
  }

  bool queue_profile_tuning(uint8_t car_type, float force_intensity,
                            float motion_range, uint32_t token) {
    McuMaintenanceTuningPayload payload{};
    payload.magic = kMcuMaintenanceMagic;
    payload.opcode = static_cast<uint8_t>(McuMaintenanceOp::SetTuning);
    payload.car_type = static_cast<uint8_t>(car_type % kMcuProfileCarTypes);
    payload.token = token;
    payload.force_intensity =
        clampf(force_intensity, kMcuForceIntensityMin, kMcuForceIntensityMax);
    payload.motion_range =
        clampf(motion_range, kMcuMotionRangeMin, kMcuMotionRangeMax);
    return queue_mcu_packet(heartbeat::PacketType::Maintenance,
                            reinterpret_cast<const uint8_t *>(&payload),
                            sizeof(payload));
  }

  bool flush_mcu_tx_queue(heartbeat::SerialPort &port, uint32_t *tx_seq) {
    if (!tx_seq) {
      return false;
    }
    while (true) {
      OutboundMcuPacket packet;
      {
        std::lock_guard<std::mutex> lock(mcu_tx_mu_);
        if (mcu_tx_queue_.empty()) {
          return true;
        }
        packet = std::move(mcu_tx_queue_.front());
        mcu_tx_queue_.pop_front();
      }

      const uint8_t *payload_ptr = packet.payload.empty()
                                       ? nullptr
                                       : packet.payload.data();
      auto frame = heartbeat::build_frame(packet.type, (*tx_seq)++, payload_ptr,
                                          packet.payload.size());
      if (!port.write(frame.data(), frame.size())) {
        std::lock_guard<std::mutex> lock(mcu_tx_mu_);
        mcu_tx_queue_.push_front(std::move(packet));
        return false;
      }
    }
  }

  void publish_input_event(const McuPttEventPayload &raw) {
    InputEvent event;
    {
      std::lock_guard<std::mutex> lock(input_mu_);
      event.set_sequence(next_input_event_sequence_++);
      if (raw.event == kMcuPttEventDown) {
        event.set_type(InputEvent::INPUT_EVENT_TYPE_PTT_DOWN);
      } else if (raw.event == kMcuPttEventUp) {
        event.set_type(InputEvent::INPUT_EVENT_TYPE_PTT_UP);
      } else {
        event.set_type(InputEvent::INPUT_EVENT_TYPE_UNKNOWN);
      }
      event.set_source(raw.source == 1u
                           ? InputEvent::INPUT_EVENT_SOURCE_STEERING_WHEEL
                           : InputEvent::INPUT_EVENT_SOURCE_UNKNOWN);
      event.set_received_at_ns(now_ns());
      event.set_mcu_uptime_ms(raw.uptime_ms);
      event.set_pressed(raw.pressed != 0u);
      input_events_.push_back(event);
      constexpr size_t kInputEventBacklog = 256;
      if (input_events_.size() > kInputEventBacklog) {
        input_events_.pop_front();
      }
    }
    input_cv_.notify_all();
  }

  void mcu_bridge_loop() {
    heartbeat::SerialPort port;
    uint32_t tx_seq = 0;
    std::vector<uint8_t> rx_buffer;
    auto next_tick = std::chrono::steady_clock::now();
    log_info("MCU bridge starting on port=" + mcu_port_ + " baud=" +
             std::to_string(mcu_baud_));

    while (bridge_running_.load()) {
      if (!port.is_open()) {
        if (!port.open(mcu_port_, mcu_baud_)) {
          std::this_thread::sleep_for(std::chrono::milliseconds(1000));
          continue;
        }
        log_info("MCU bridge connected to " + mcu_port_);
      }

      next_tick += std::chrono::milliseconds(mcu_heartbeat_interval_ms_);
      auto heartbeat_frame =
          heartbeat::build_frame(heartbeat::PacketType::Heartbeat, tx_seq++, nullptr, 0);
      if (!port.write(heartbeat_frame.data(), heartbeat_frame.size())) {
        port.close();
        std::this_thread::sleep_for(std::chrono::milliseconds(250));
        continue;
      }
      if (!flush_mcu_tx_queue(port, &tx_seq)) {
        port.close();
        std::this_thread::sleep_for(std::chrono::milliseconds(250));
        continue;
      }

      uint8_t temp[256];
      const size_t read_n = port.read(temp, sizeof(temp));
      if (read_n > 0) {
        rx_buffer.insert(rx_buffer.end(), temp, temp + read_n);
      }

      while (rx_buffer.size() >= sizeof(heartbeat::Header) + sizeof(uint16_t)) {
        uint32_t magic = read_u32(rx_buffer.data());
        uint8_t version = rx_buffer[4];
        uint16_t length = read_u16(rx_buffer.data() + 6);
        if (magic != heartbeat::kMagic || version != heartbeat::kVersion ||
            length > heartbeat::kMaxPayload) {
          rx_buffer.erase(rx_buffer.begin());
          continue;
        }
        size_t total = sizeof(heartbeat::Header) + length + sizeof(uint16_t);
        if (rx_buffer.size() < total) {
          break;
        }

        heartbeat::Frame frame;
        if (!heartbeat::parse_frame(rx_buffer.data(), total, frame)) {
          rx_buffer.erase(rx_buffer.begin());
          continue;
        }

        if (frame.header.type ==
                static_cast<uint8_t>(heartbeat::PacketType::InputEvent) &&
            frame.payload.size() >= sizeof(McuPttEventPayload)) {
          McuPttEventPayload raw{};
          std::memcpy(&raw, frame.payload.data(), sizeof(McuPttEventPayload));
          if (raw.magic == kMcuPttMagic) {
            publish_input_event(raw);
          }
        }

        rx_buffer.erase(rx_buffer.begin(), rx_buffer.begin() + total);
      }

      std::this_thread::sleep_until(next_tick);
    }

    if (port.is_open()) {
      port.close();
    }
    log_info("MCU bridge stopped");
  }

  std::mutex mu_;
  DashboardStateMachine state_{};
  SessionStore store_{"data/sessions"};

  std::mutex telemetry_mu_;
  TelemetrySample last_sample_{};
  bool telemetry_ready_ = false;

  std::mutex input_mu_;
  std::condition_variable input_cv_;
  std::deque<InputEvent> input_events_;
  uint64_t next_input_event_sequence_ = 1;

  std::mutex mcu_tx_mu_;
  std::deque<OutboundMcuPacket> mcu_tx_queue_;
  float default_force_intensity_ = 1.0f;
  float default_motion_range_ = 1.0f;

  std::atomic<bool> bridge_running_{false};
  std::thread bridge_thread_;
  std::string mcu_port_;
  int mcu_baud_ = 115200;
  int mcu_heartbeat_interval_ms_ = 50;
};

DashboardService::Service *make_dashboard_service() {
  return new DashboardServiceImpl();
}

} // namespace slipstream::dashboard
