#include "transform.h"

namespace slipstream::physics {

static float pick_axis(const float accel[3], const AxisConfig &cfg) {
  int idx = cfg.index;
  if (idx < 0) idx = 0;
  if (idx > 2) idx = 2;
  return accel[idx] * cfg.sign;
}

RigAccel transform_accel(const float accel_mps2[3], const TransformConfig &cfg) {
  RigAccel out;
  out.surge = pick_axis(accel_mps2, cfg.surge);
  out.sway = pick_axis(accel_mps2, cfg.sway);
  out.heave = pick_axis(accel_mps2, cfg.heave);
  return out;
}

} // namespace slipstream::physics
