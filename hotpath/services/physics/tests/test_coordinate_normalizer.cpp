#include "coordinate_normalizer.h"

#include <cassert>

using slipstream::physics::UpAxis;
using slipstream::physics::normalize_vector_to_z_up;

int main() {
  {
    float in[3] = {1.0f, 2.0f, 3.0f};
    float out[3] = {0.0f, 0.0f, 0.0f};
    normalize_vector_to_z_up(in, UpAxis::ZUp, out);
    assert(out[0] == 1.0f);
    assert(out[1] == 2.0f);
    assert(out[2] == 3.0f);
  }

  {
    float in[3] = {1.0f, 2.0f, 3.0f};
    float out[3] = {0.0f, 0.0f, 0.0f};
    normalize_vector_to_z_up(in, UpAxis::YUp, out);
    assert(out[0] == 1.0f);
    assert(out[1] == 3.0f);
    assert(out[2] == 2.0f);
  }

  return 0;
}
