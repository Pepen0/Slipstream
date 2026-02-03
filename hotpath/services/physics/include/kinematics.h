#pragma once

namespace slipstream::physics {

struct RigKinematics {
  float arm_length_m = 0.3f;
  float max_travel_m = 0.08f;
  float max_pitch_rad = 0.35f;
  float max_roll_rad = 0.35f;
};

struct MotorTargets {
  float left_m = 0.0f;
  float right_m = 0.0f;
};

MotorTargets pitch_roll_to_targets(float pitch_rad, float roll_rad, const RigKinematics &cfg);

} // namespace slipstream::physics
