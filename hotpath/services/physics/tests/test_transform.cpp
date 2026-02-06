#include "transform.h"

#include <cassert>

using namespace slipstream::physics;

int main() {
  TransformConfig cfg;
  cfg.surge = {0, 1.0f};
  cfg.sway = {1, -1.0f};
  cfg.heave = {2, 1.0f};

  float accel[3] = {1.0f, 2.0f, 3.0f};
  auto rig = transform_accel(accel, cfg);
  assert(rig.surge == 1.0f);
  assert(rig.sway == -2.0f);
  assert(rig.heave == 3.0f);
  return 0;
}
