#include <unity.h>
#include "control_loop.h"
#include "mcu_faults.h"

void test_pid_clamp(void) {
  control_config_t cfg = {0};
  cfg.pid.kp = 15.0f;
  cfg.pid.ki = 0.0f;
  cfg.pid.kd = 0.0f;
  cfg.pid.out_min = -1.0f;
  cfg.pid.out_max = 1.0f;
  cfg.pid.integrator_min = -1.0f;
  cfg.pid.integrator_max = 1.0f;
  cfg.torque_limit = 1.0f;
  cfg.pos_min_m = -0.1f;
  cfg.pos_max_m = 0.1f;
  cfg.homing_timeout_ms = 1000;
  cfg.homing_target_m = -0.1f;
  cfg.setpoint_deadband_m = 0.0f;

  control_state_t state;
  control_init(&state, &cfg);
  control_set_setpoints(&state, 0.1f, 0.1f);
  control_tick(&state, &cfg, 0.0f, 0.0f, false, false, 1, 1.0f);

  TEST_ASSERT_FLOAT_WITHIN(1e-3f, 1.0f, control_left_command(&state));
  TEST_ASSERT_FLOAT_WITHIN(1e-3f, 1.0f, control_right_command(&state));
}

void test_homing_complete(void) {
  control_config_t cfg = {0};
  cfg.pid.kp = 1.0f;
  cfg.pid.ki = 0.0f;
  cfg.pid.kd = 0.0f;
  cfg.pid.out_min = -1.0f;
  cfg.pid.out_max = 1.0f;
  cfg.pid.integrator_min = -1.0f;
  cfg.pid.integrator_max = 1.0f;
  cfg.torque_limit = 1.0f;
  cfg.pos_min_m = -0.1f;
  cfg.pos_max_m = 0.1f;
  cfg.homing_timeout_ms = 1000;
  cfg.homing_target_m = -0.1f;
  cfg.setpoint_deadband_m = 0.0f;

  control_state_t state;
  control_init(&state, &cfg);
  control_start_homing(&state, 0);

  control_tick(&state, &cfg, 0.0f, 0.0f, true, true, 10, 1.0f);
  TEST_ASSERT_TRUE(control_is_homed(&state));
  TEST_ASSERT_FALSE(state.homing_active);
}

void test_sensor_fault(void) {
  control_config_t cfg = {0};
  cfg.pid.kp = 1.0f;
  cfg.pid.out_min = -1.0f;
  cfg.pid.out_max = 1.0f;
  cfg.pid.integrator_min = -1.0f;
  cfg.pid.integrator_max = 1.0f;
  cfg.torque_limit = 1.0f;
  cfg.pos_min_m = -0.05f;
  cfg.pos_max_m = 0.05f;
  cfg.homing_timeout_ms = 1000;
  cfg.homing_target_m = -0.05f;
  cfg.setpoint_deadband_m = 0.0f;

  control_state_t state;
  control_init(&state, &cfg);
  control_set_setpoints(&state, 0.0f, 0.0f);

  control_tick(&state, &cfg, 0.2f, 0.0f, false, false, 5, 1.0f);
  TEST_ASSERT_EQUAL_UINT16(MCU_FAULT_SENSOR_RANGE, control_fault(&state));
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.0f, control_left_command(&state));
}

void test_torque_scale_zero(void) {
  control_config_t cfg = {0};
  cfg.pid.kp = 1.0f;
  cfg.pid.out_min = -1.0f;
  cfg.pid.out_max = 1.0f;
  cfg.pid.integrator_min = -1.0f;
  cfg.pid.integrator_max = 1.0f;
  cfg.torque_limit = 1.0f;
  cfg.pos_min_m = -0.1f;
  cfg.pos_max_m = 0.1f;
  cfg.homing_timeout_ms = 1000;
  cfg.homing_target_m = -0.1f;
  cfg.setpoint_deadband_m = 0.0f;

  control_state_t state;
  control_init(&state, &cfg);
  control_set_setpoints(&state, 0.1f, 0.1f);
  control_tick(&state, &cfg, 0.0f, 0.0f, false, false, 1, 0.0f);

  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.0f, control_left_command(&state));
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.0f, control_right_command(&state));
}
