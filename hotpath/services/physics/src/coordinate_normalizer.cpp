#include "coordinate_normalizer.h"

namespace slipstream::physics {

void normalize_vector_to_z_up(const float in_xyz[3], UpAxis source_up_axis, float out_xyz[3]) {
  if (source_up_axis == UpAxis::ZUp) {
    out_xyz[0] = in_xyz[0];
    out_xyz[1] = in_xyz[1];
    out_xyz[2] = in_xyz[2];
    return;
  }

  // Y-up source data gets remapped so vertical ends up on Z.
  out_xyz[0] = in_xyz[0];
  out_xyz[1] = in_xyz[2];
  out_xyz[2] = in_xyz[1];
}

} // namespace slipstream::physics
