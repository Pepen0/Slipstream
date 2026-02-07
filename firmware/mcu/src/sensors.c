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

bool sensors_read_adc(uint16_t *left_raw, uint16_t *right_raw) {
  if (left_raw) *left_raw = 2048u;
  if (right_raw) *right_raw = 2048u;
  return true;
}
