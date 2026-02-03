#pragma once

namespace slipstream::physics {

struct AxisConfig {
  int index = 0;  // 0=x,1=y,2=z
  float sign = 1.0f;
};

struct TransformConfig {
  AxisConfig surge; // forward/back
  AxisConfig sway;  // left/right
  AxisConfig heave; // up/down
};

struct RigAccel {
  float surge = 0.0f;
  float sway = 0.0f;
  float heave = 0.0f;
};

RigAccel transform_accel(const float accel_mps2[3], const TransformConfig &cfg);

} // namespace slipstream::physics
