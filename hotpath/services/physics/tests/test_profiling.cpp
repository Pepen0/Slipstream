#include "profiling.h"

#include <cassert>
#include <cmath>

using namespace slipstream::physics;

static bool nearly_equal(double a, double b, double eps = 1e-6) {
  return std::fabs(a - b) < eps;
}

int main() {
  MotionProfiler profiler;

  MotionProfile p1;
  p1.read_ms = 0.5f;
  p1.process_ms = 1.0f;
  p1.dispatch_ms = 0.2f;
  p1.end_to_end_ms = 1.7f;
  p1.loop_slip_ms = 0.0f;

  MotionProfile p2 = p1;
  p2.end_to_end_ms = 2.7f;
  p2.process_ms = 1.2f;

  profiler.record(p1);
  profiler.record(p2);

  auto end_to_end = profiler.end_to_end();
  auto process = profiler.process();
  assert(end_to_end.count == 2);
  assert(nearly_equal(end_to_end.mean, 2.2));
  assert(nearly_equal(end_to_end.min, 1.7));
  assert(nearly_equal(end_to_end.max, 2.7));

  assert(process.count == 2);
  assert(nearly_equal(process.mean, 1.1));

  return 0;
}
