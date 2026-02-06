#include "jitter_filter.h"

#include <cassert>
#include <cmath>

using namespace slipstream::physics;

int main() {
  JitterFilterConfig cfg;
  cfg.deadband_rad = 0.01f;
  cfg.max_pitch_rate_rad_s = 1.0f;
  cfg.max_roll_rate_rad_s = 1.0f;

  JitterFilter filter(cfg);

  float pitch = 0.0f;
  float roll = 0.0f;
  filter.apply(pitch, roll, 0.01f);
  assert(std::fabs(pitch) < 1e-6f);
  assert(std::fabs(roll) < 1e-6f);

  pitch = 1.0f;
  roll = -1.0f;
  filter.apply(pitch, roll, 0.1f);
  assert(std::fabs(pitch - 0.1f) < 1e-4f);
  assert(std::fabs(roll + 0.1f) < 1e-4f);

  float prev_pitch = pitch;
  float prev_roll = roll;
  pitch = prev_pitch + 0.005f;
  roll = prev_roll - 0.005f;
  filter.apply(pitch, roll, 0.1f);
  assert(std::fabs(pitch - prev_pitch) < 1e-4f);
  assert(std::fabs(roll - prev_roll) < 1e-4f);

  return 0;
}
