#include "sensors.h"

void sensors_init(void) {}

bool sensors_read_position(float *left_m, float *right_m) {
  if (left_m) *left_m = 0.0f;
  if (right_m) *right_m = 0.0f;
  return true;
}

bool sensors_read_limits(bool *left_limit, bool *right_limit) {
  if (left_limit) *left_limit = true;
  if (right_limit) *right_limit = true;
  return true;
}
