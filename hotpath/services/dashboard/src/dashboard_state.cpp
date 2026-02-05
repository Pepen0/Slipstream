#include "dashboard_state.h"

#include <chrono>

namespace slipstream::dashboard {

static uint64_t now_ns() {
  using clock = std::chrono::steady_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(clock::now().time_since_epoch()).count();
}

DashboardStateMachine::DashboardStateMachine() {
  status_.state = DashboardState::Init;
  touch();
}

void DashboardStateMachine::touch() {
  status_.updated_at_ns = now_ns();
}

DashboardStatus DashboardStateMachine::get_status() const {
  return status_;
}

DashboardStatus DashboardStateMachine::calibrate(const std::string &profile_id) {
  status_.active_profile = profile_id;
  if (status_.state == DashboardState::Init) {
    status_.state = DashboardState::Idle;
  }
  status_.last_error.clear();
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
