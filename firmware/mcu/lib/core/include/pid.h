#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  float kp;
  float ki;
  float kd;
  float out_min;
  float out_max;
  float integrator_min;
  float integrator_max;
} pid_config_t;

typedef struct {
  float integrator;
  float prev_error;
  bool initialized;
} pid_state_t;

void pid_init(pid_state_t *state);
void pid_reset(pid_state_t *state);
float pid_step(const pid_config_t *cfg, pid_state_t *state,
               float setpoint, float measurement, float dt_s);

#ifdef __cplusplus
}
#endif
