#include "kinematics.h"

#include <cmath>

namespace slipstream::physics {

static float clamp(float v, float lo, float hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

MotorTargets pitch_roll_to_targets(float pitch_rad, float roll_rad, const RigKinematics &cfg) {
  float pitch = clamp(pitch_rad, -cfg.max_pitch_rad, cfg.max_pitch_rad);
  float roll = clamp(roll_rad, -cfg.max_roll_rad, cfg.max_roll_rad);

  float left = cfg.arm_length_m * (std::sin(pitch) - std::sin(roll));
  float right = cfg.arm_length_m * (std::sin(pitch) + std::sin(roll));

  left = clamp(left, -cfg.max_travel_m, cfg.max_travel_m);
  right = clamp(right, -cfg.max_travel_m, cfg.max_travel_m);

  return MotorTargets{left, right};
}

} // namespace slipstream::physics
