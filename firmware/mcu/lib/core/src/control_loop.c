#include "control_loop.h"
#include "mcu_faults.h"

static float clampf(float v, float lo, float hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

void control_init(control_state_t *state, const control_config_t *cfg) {
  if (!state || !cfg) return;
  pid_init(&state->left.pid);
  pid_init(&state->right.pid);
  state->left.setpoint_m = 0.0f;
  state->right.setpoint_m = 0.0f;
  state->left.command = 0.0f;
  state->right.command = 0.0f;
  state->left.homed = false;
  state->right.homed = false;
  state->homing_active = false;
  state->homing_start_ms = 0;
  state->last_update_ms = 0;
  state->fault_code = MCU_FAULT_NONE;
  state->left_pos_m = 0.0f;
  state->right_pos_m = 0.0f;
  (void)cfg;
}

void control_set_setpoints(control_state_t *state, float left_m, float right_m) {
  if (!state) return;
  state->left.setpoint_m = left_m;
  state->right.setpoint_m = right_m;
}

void control_start_homing(control_state_t *state, uint32_t now_ms) {
  if (!state) return;
  state->homing_active = true;
  state->homing_start_ms = now_ms;
  state->left.homed = false;
  state->right.homed = false;
  pid_reset(&state->left.pid);
  pid_reset(&state->right.pid);
}

static float apply_deadband(float error, float deadband) {
  if (error > -deadband && error < deadband) {
    return 0.0f;
  }
  return error;
}

void control_tick(control_state_t *state, const control_config_t *cfg,
                  float left_pos_m, float right_pos_m,
                  bool left_limit, bool right_limit,
                  uint32_t now_ms, float torque_scale) {
  if (!state || !cfg) return;

  state->left_pos_m = left_pos_m;
  state->right_pos_m = right_pos_m;

  if (left_pos_m < cfg->pos_min_m || left_pos_m > cfg->pos_max_m ||
      right_pos_m < cfg->pos_min_m || right_pos_m > cfg->pos_max_m) {
    state->fault_code = MCU_FAULT_SENSOR_RANGE;
  }

  if (state->fault_code != MCU_FAULT_NONE) {
    state->left.command = 0.0f;
    state->right.command = 0.0f;
    return;
  }

  if (state->homing_active) {
    if (left_limit) {
      state->left.homed = true;
      state->left.setpoint_m = left_pos_m;
      pid_reset(&state->left.pid);
    }
    if (right_limit) {
      state->right.homed = true;
      state->right.setpoint_m = right_pos_m;
      pid_reset(&state->right.pid);
    }

    if (!state->left.homed) {
      state->left.setpoint_m = cfg->homing_target_m;
    }
    if (!state->right.homed) {
      state->right.setpoint_m = cfg->homing_target_m;
    }

    if ((now_ms - state->homing_start_ms) >= cfg->homing_timeout_ms) {
      state->fault_code = MCU_FAULT_HOMING_TIMEOUT;
      state->homing_active = false;
    }

    if (state->left.homed && state->right.homed) {
      state->homing_active = false;
    }
  }

  float dt_s;
  if (state->last_update_ms == 0) {
    dt_s = 1.0f / 1000.0f;
  } else {
    uint32_t dt_ms = now_ms - state->last_update_ms;
    if (dt_ms == 0) dt_ms = 1;
    dt_s = (float)dt_ms / 1000.0f;
  }
  state->last_update_ms = now_ms;

  float left_sp = clampf(state->left.setpoint_m, cfg->pos_min_m, cfg->pos_max_m);
  float right_sp = clampf(state->right.setpoint_m, cfg->pos_min_m, cfg->pos_max_m);

  float left_error = apply_deadband(left_sp - left_pos_m, cfg->setpoint_deadband_m);
  float right_error = apply_deadband(right_sp - right_pos_m, cfg->setpoint_deadband_m);

  float left_cmd = pid_step(&cfg->pid, &state->left.pid,
                            left_pos_m + left_error, left_pos_m, dt_s);
  float right_cmd = pid_step(&cfg->pid, &state->right.pid,
                             right_pos_m + right_error, right_pos_m, dt_s);

  left_cmd = clampf(left_cmd, -cfg->torque_limit, cfg->torque_limit);
  right_cmd = clampf(right_cmd, -cfg->torque_limit, cfg->torque_limit);

  if (torque_scale <= 0.0f) {
    state->left.command = 0.0f;
    state->right.command = 0.0f;
    pid_reset(&state->left.pid);
    pid_reset(&state->right.pid);
    return;
  }

  left_cmd *= torque_scale;
  right_cmd *= torque_scale;

  state->left.command = left_cmd;
  state->right.command = right_cmd;
}

uint16_t control_fault(const control_state_t *state) {
  return state ? state->fault_code : MCU_FAULT_COMMAND_INVALID;
}

bool control_is_homed(const control_state_t *state) {
  return state && state->left.homed && state->right.homed;
}

float control_left_command(const control_state_t *state) {
  return state ? state->left.command : 0.0f;
}

float control_right_command(const control_state_t *state) {
  return state ? state->right.command : 0.0f;
}
