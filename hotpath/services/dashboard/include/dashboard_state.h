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

struct DashboardStatus {
  DashboardState state = DashboardState::Init;
  bool estop_active = false;
  bool session_active = false;
  std::string active_profile;
  std::string session_id;
  std::string last_error;
  uint64_t updated_at_ns = 0;
};

class DashboardStateMachine {
public:
  DashboardStateMachine();

  DashboardStatus get_status() const;
  DashboardStatus calibrate(const std::string &profile_id);
  DashboardStatus set_profile(const std::string &profile_id);
  DashboardStatus estop(bool engaged, const std::string &reason);
  DashboardStatus start_session(const std::string &session_id);
  DashboardStatus end_session(const std::string &session_id);

private:
  DashboardStatus status_{};
  void touch();
};

} // namespace slipstream::dashboard
