#include "pid.h"

static float clampf(float v, float lo, float hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

void pid_init(pid_state_t *state) {
  if (!state) return;
  state->integrator = 0.0f;
  state->prev_error = 0.0f;
  state->initialized = false;
}

void pid_reset(pid_state_t *state) {
  if (!state) return;
  state->integrator = 0.0f;
  state->prev_error = 0.0f;
  state->initialized = false;
}

float pid_step(const pid_config_t *cfg, pid_state_t *state,
               float setpoint, float measurement, float dt_s) {
  if (!cfg || !state) return 0.0f;
  if (dt_s <= 0.0f) dt_s = 1e-3f;

  float error = setpoint - measurement;
  if (!state->initialized) {
    state->prev_error = error;
    state->initialized = true;
  }

  state->integrator += error * dt_s;
  state->integrator = clampf(state->integrator, cfg->integrator_min, cfg->integrator_max);

  float derivative = (error - state->prev_error) / dt_s;
  state->prev_error = error;

  float output = (cfg->kp * error) + (cfg->ki * state->integrator) + (cfg->kd * derivative);
  return clampf(output, cfg->out_min, cfg->out_max);
}
