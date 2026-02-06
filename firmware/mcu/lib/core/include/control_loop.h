#pragma once

#include <stdbool.h>
#include <stdint.h>
#include "pid.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  pid_config_t pid;
  float torque_limit;
  float pos_min_m;
  float pos_max_m;
  float homing_target_m;
  uint32_t homing_timeout_ms;
  float setpoint_deadband_m;
} control_config_t;

typedef struct {
  pid_state_t pid;
  float setpoint_m;
  float command;
  bool homed;
} control_axis_t;

typedef struct {
  control_axis_t left;
  control_axis_t right;
  bool homing_active;
  uint32_t homing_start_ms;
  uint32_t last_update_ms;
  uint16_t fault_code;
  float left_pos_m;
  float right_pos_m;
} control_state_t;

void control_init(control_state_t *state, const control_config_t *cfg);
void control_set_setpoints(control_state_t *state, float left_m, float right_m);
void control_start_homing(control_state_t *state, uint32_t now_ms);
void control_tick(control_state_t *state, const control_config_t *cfg,
                  float left_pos_m, float right_pos_m,
                  bool left_limit, bool right_limit,
                  uint32_t now_ms, float torque_scale);

uint16_t control_fault(const control_state_t *state);
bool control_is_homed(const control_state_t *state);
float control_left_command(const control_state_t *state);
float control_right_command(const control_state_t *state);

#ifdef __cplusplus
}
#endif
