#include "motion_engine.h"

#include <cassert>
#include <chrono>

using namespace slipstream::physics;

static uint64_t now_ns() {
  using clock = std::chrono::steady_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(clock::now().time_since_epoch()).count();
}

int main() {
  MotionConfig cfg;
  cfg.hp_cutoff_hz = 0.5f;
  cfg.lp_cutoff_hz = 1.0f;
  cfg.pitch_gain = 0.02f;
  cfg.roll_gain = 0.02f;
  cfg.transform = {{0, 1.0f}, {1, 1.0f}, {2, 1.0f}};

  MotionEngine engine(cfg);
  TelemetrySample sample;
  sample.timestamp_ns = now_ns();
  sample.accel_mps2[0] = 1.0f;
  sample.accel_mps2[1] = -1.0f;

  auto cmd = engine.process(sample, now_ns());
  assert(cmd.latency_ms >= 0.0f);
  assert(cmd.targets.left_m <= cfg.kinematics.max_travel_m);
  assert(cmd.targets.right_m <= cfg.kinematics.max_travel_m);
  return 0;
}
