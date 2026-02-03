#include "kinematics.h"

#include <cassert>

using namespace slipstream::physics;

int main() {
  RigKinematics cfg;
  cfg.arm_length_m = 0.3f;
  cfg.max_travel_m = 0.05f;
  cfg.max_pitch_rad = 0.3f;
  cfg.max_roll_rad = 0.3f;

  auto targets = pitch_roll_to_targets(0.1f, -0.1f, cfg);
  assert(targets.left_m <= cfg.max_travel_m);
  assert(targets.right_m <= cfg.max_travel_m);
  return 0;
}
