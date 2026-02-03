#include "motion_loop.h"

#include <thread>

namespace slipstream::physics {

static uint64_t now_ns() {
  using clock = std::chrono::steady_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(clock::now().time_since_epoch()).count();
}

MotionLoop::MotionLoop(int target_hz) : target_hz_(target_hz) {}

void MotionLoop::run(IGameTelemetryProvider &provider, MotionEngine &engine, const MotionCallback &on_cmd) {
  if (!provider.start()) {
    return;
  }

  const auto period = std::chrono::microseconds(1000000 / target_hz_);
  auto next_tick = std::chrono::steady_clock::now();

  while (true) {
    next_tick += period;
    TelemetrySample sample;
    if (provider.read(sample)) {
      auto cmd = engine.process(sample, now_ns());
      on_cmd(cmd);
    }
    std::this_thread::sleep_until(next_tick);
  }
}

} // namespace slipstream::physics
