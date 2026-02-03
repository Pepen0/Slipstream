#include "filters.h"

#include <cassert>
#include <cmath>

using slipstream::physics::HighPassFilter;
using slipstream::physics::LowPassFilter;

int main() {
  HighPassFilter hp(0.5f);
  float out1 = hp.process(1.0f, 0.01f);
  float out2 = hp.process(1.0f, 0.01f);
  assert(std::fabs(out1) < 0.2f);
  assert(std::fabs(out2) < 0.2f);

  LowPassFilter lp(1.0f);
  float v1 = lp.process(1.0f, 0.01f);
  float v2 = lp.process(1.0f, 0.01f);
  assert(v2 >= v1);
  return 0;
}
