#include "dashboard_state.h"

#include <cassert>

using slipstream::dashboard::DashboardState;
using slipstream::dashboard::DashboardStateMachine;

int main() {
  DashboardStateMachine state;
  auto status = state.get_status();
  assert(status.state == DashboardState::Init);

  status = state.set_profile("default");
  assert(status.active_profile == "default");

  status = state.calibrate("default");
  assert(status.state == DashboardState::Idle || status.state == DashboardState::Active);

  status = state.start_session("sess1");
  assert(status.session_active);
  assert(status.state == DashboardState::Active);

  status = state.estop(true, "test");
  assert(status.estop_active);
  assert(status.state == DashboardState::Fault);

  status = state.estop(false, "");
  assert(!status.estop_active);
  assert(status.state == DashboardState::Active);

  status = state.end_session("sess1");
  assert(!status.session_active);
  assert(status.state == DashboardState::Idle);

  return 0;
}
