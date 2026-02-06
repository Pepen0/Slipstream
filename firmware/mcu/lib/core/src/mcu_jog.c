#include "mcu_jog.h"

void mcu_jog_init(mcu_jog_state_t *state) {
  if (!state) return;
  state->active = 0;
  state->mode = MCU_JOG_MODE_TORQUE;
  state->left_torque = 0.0f;
  state->right_torque = 0.0f;
  state->expires_at_ms = 0;
}

static bool is_stop_command(const mcu_jog_command_t *cmd) {
  return (cmd->left_torque == 0.0f && cmd->right_torque == 0.0f);
}

bool mcu_jog_start(mcu_jog_state_t *state, const mcu_jog_command_t *cmd, uint32_t now_ms,
                   uint32_t default_duration_ms, uint32_t max_duration_ms) {
  if (!state || !cmd) return false;
  if (cmd->magic != MCU_JOG_MAGIC) {
    return false;
  }
  if (cmd->mode != MCU_JOG_MODE_TORQUE) {
    return false;
  }
  if (is_stop_command(cmd)) {
    mcu_jog_stop(state);
    return true;
  }
  uint32_t duration = cmd->duration_ms;
  if (duration == 0) {
    duration = default_duration_ms;
  }
  if (max_duration_ms > 0 && duration > max_duration_ms) {
    duration = max_duration_ms;
  }
  state->active = 1;
  state->mode = cmd->mode;
  state->left_torque = cmd->left_torque;
  state->right_torque = cmd->right_torque;
  state->expires_at_ms = now_ms + duration;
  return true;
}

void mcu_jog_stop(mcu_jog_state_t *state) {
  if (!state) return;
  state->active = 0;
  state->left_torque = 0.0f;
  state->right_torque = 0.0f;
  state->expires_at_ms = 0;
}

bool mcu_jog_update(mcu_jog_state_t *state, uint32_t now_ms) {
  if (!state) return false;
  if (!state->active) return false;
  if (state->expires_at_ms != 0 && now_ms >= state->expires_at_ms) {
    mcu_jog_stop(state);
    return false;
  }
  return true;
}

bool mcu_jog_active(const mcu_jog_state_t *state) {
  return state && state->active;
}

float mcu_jog_left(const mcu_jog_state_t *state) {
  return state ? state->left_torque : 0.0f;
}

float mcu_jog_right(const mcu_jog_state_t *state) {
  return state ? state->right_torque : 0.0f;
}
