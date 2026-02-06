#pragma once

#include <cstdint>
#include <string>

namespace slipstream::dashboard {

enum class DashboardState {
  Init = 0,
  Idle = 1,
  Active = 2,
  Fault = 3
};

enum class CalibrationState {
  Unknown = 0,
  Idle = 1,
  Running = 2,
  Passed = 3,
  Failed = 4
};

struct DashboardStatus {
  DashboardState state = DashboardState::Init;
  bool estop_active = false;
  bool session_active = false;
  std::string active_profile;
  std::string session_id;
  std::string last_error;
  uint64_t updated_at_ns = 0;
  CalibrationState calibration_state = CalibrationState::Idle;
  float calibration_progress = 0.0f;
  std::string calibration_message;
  uint32_t calibration_attempts = 0;
  uint64_t last_calibration_at_ns = 0;
};

class DashboardStateMachine {
public:
  DashboardStateMachine();

  DashboardStatus get_status();
  DashboardStatus calibrate(const std::string &profile_id);
  DashboardStatus cancel_calibration();
  DashboardStatus set_profile(const std::string &profile_id);
  DashboardStatus estop(bool engaged, const std::string &reason);
  DashboardStatus start_session(const std::string &session_id);
  DashboardStatus end_session(const std::string &session_id);

private:
  DashboardStatus status_{};
  uint64_t calibration_start_ns_ = 0;
  void touch();
  void update_calibration(uint64_t now_ns);
};

} // namespace slipstream::dashboard
