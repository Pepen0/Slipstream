#pragma once

namespace slipstream::physics {

enum class UpAxis {
  ZUp = 0,
  YUp = 1
};

// Normalizes vectors into a shared Z-up basis.
void normalize_vector_to_z_up(const float in_xyz[3], UpAxis source_up_axis, float out_xyz[3]);

} // namespace slipstream::physics
