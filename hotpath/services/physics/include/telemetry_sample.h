#pragma once

#include <cstdint>

namespace slipstream::physics {

struct TelemetrySample {
  uint64_t timestamp_ns = 0;
  float accel_mps2[3] = {0.0f, 0.0f, 0.0f};
  float velocity_mps[3] = {0.0f, 0.0f, 0.0f};
  float angular_vel_rad[3] = {0.0f, 0.0f, 0.0f};
  float speed_mps = 0.0f;
};

} // namespace slipstream::physics
