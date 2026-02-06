#include "actuators.h"

static float last_left = 0.0f;
static float last_right = 0.0f;

void actuators_init(void) {
  last_left = 0.0f;
  last_right = 0.0f;
}

void actuators_set_torque(float left, float right) {
  last_left = left;
  last_right = right;
}

void actuators_get_torque(float *left, float *right) {
  if (left) *left = last_left;
  if (right) *right = last_right;
}
