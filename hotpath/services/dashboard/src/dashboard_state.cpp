#include "dashboard_state.h"

#include <chrono>

namespace slipstream::dashboard {

static uint64_t now_ns() {
  using clock = std::chrono::system_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(clock::now().time_since_epoch()).count();
}

static constexpr uint64_t kCalibrationDurationNs = 3'000'000'000ULL;

DashboardStateMachine::DashboardStateMachine() {
  status_.state = DashboardState::Init;
  status_.calibration_state = CalibrationState::Idle;
  status_.calibration_progress = 0.0f;
  touch();
}

void DashboardStateMachine::touch() {
  status_.updated_at_ns = now_ns();
}

void DashboardStateMachine::update_calibration(uint64_t now_ns) {
  if (status_.calibration_state != CalibrationState::Running) {
    return;
  }

  if (status_.estop_active || status_.state == DashboardState::Fault) {
    status_.calibration_state = CalibrationState::Failed;
    status_.calibration_progress = 0.0f;
    status_.calibration_message = "Calibration interrupted by safety fault.";
    status_.last_calibration_at_ns = now_ns;
    return;
  }

  uint64_t elapsed = now_ns - calibration_start_ns_;
  float progress = static_cast<float>(elapsed) / static_cast<float>(kCalibrationDurationNs);
  if (progress >= 1.0f) {
    status_.calibration_state = CalibrationState::Passed;
    status_.calibration_progress = 1.0f;
    status_.calibration_message = "Calibration complete.";
    status_.last_calibration_at_ns = now_ns;
  } else {
    if (progress < 0.0f) progress = 0.0f;
    status_.calibration_progress = progress;
    status_.calibration_message = "Zeroing sensors.";
  }
}

DashboardStatus DashboardStateMachine::get_status() {
  auto now = now_ns();
  update_calibration(now);
  status_.updated_at_ns = now;
  return status_;
}

DashboardStatus DashboardStateMachine::calibrate(const std::string &profile_id) {
  if (profile_id.empty()) {
    status_.calibration_attempts += 1;
    status_.calibration_state = CalibrationState::Failed;
    status_.calibration_progress = 0.0f;
    status_.calibration_message = "Profile ID required.";
    status_.last_error = status_.calibration_message;
    status_.last_calibration_at_ns = now_ns();
    touch();
    return status_;
  }
  status_.active_profile = profile_id;
  if (status_.state == DashboardState::Init) {
    status_.state = DashboardState::Idle;
  }
  status_.last_error.clear();
  status_.calibration_attempts += 1;
  status_.calibration_state = CalibrationState::Running;
  status_.calibration_progress = 0.0f;
  status_.calibration_message = "Zeroing sensors.";
  calibration_start_ns_ = now_ns();
  touch();
  return status_;
}

DashboardStatus DashboardStateMachine::cancel_calibration() {
  status_.calibration_state = CalibrationState::Failed;
  status_.calibration_progress = 0.0f;
  status_.calibration_message = "Calibration canceled.";
  status_.last_error = status_.calibration_message;
  status_.last_calibration_at_ns = now_ns();
  touch();
  return status_;
}

DashboardStatus DashboardStateMachine::set_profile(const std::string &profile_id) {
  status_.active_profile = profile_id;
  status_.last_error.clear();
  touch();
  return status_;
}

DashboardStatus DashboardStateMachine::estop(bool engaged, const std::string &reason) {
  status_.estop_active = engaged;
  if (engaged) {
    status_.state = DashboardState::Fault;
    status_.last_error = reason;
  } else {
    if (status_.session_active) {
      status_.state = DashboardState::Active;
    } else {
      status_.state = DashboardState::Idle;
    }
    status_.last_error.clear();
  }
  touch();
  return status_;
}

DashboardStatus DashboardStateMachine::start_session(const std::string &session_id) {
  status_.session_active = true;
  status_.session_id = session_id;
  if (!status_.estop_active) {
    status_.state = DashboardState::Active;
  }
  status_.last_error.clear();
  touch();
  return status_;
}

DashboardStatus DashboardStateMachine::end_session(const std::string &session_id) {
  (void)session_id;
  status_.session_active = false;
  status_.session_id.clear();
  if (!status_.estop_active) {
    status_.state = DashboardState::Idle;
  }
  status_.last_error.clear();
  touch();
  return status_;
}

} // namespace slipstream::dashboard
