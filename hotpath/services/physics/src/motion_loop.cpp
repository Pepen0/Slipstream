#include "motion_loop.h"

#include "profiling.h"

#include <thread>

namespace slipstream::physics {

static uint64_t now_ns() {
  using clock = std::chrono::steady_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(clock::now().time_since_epoch()).count();
}

MotionLoop::MotionLoop(int target_hz) : target_hz_(target_hz) {}

void MotionLoop::run(IGameTelemetryProvider &provider, MotionEngine &engine, const MotionCallback &on_cmd,
                     const TelemetryCallback &on_sample, MotionProfiler *profiler) {
  if (!provider.start()) {
    return;
  }

  const auto period = std::chrono::microseconds(1000000 / target_hz_);
  auto next_tick = std::chrono::steady_clock::now();

  while (true) {
    next_tick += period;
    TelemetrySample sample;
    MotionProfile profile{};
    if (profiler) {
      profile.read_start_ns = now_ns();
    }
    bool got_sample = provider.read(sample);
    if (profiler) {
      profile.read_end_ns = now_ns();
      profile.read_ms = static_cast<float>(profile.read_end_ns - profile.read_start_ns) / 1e6f;
    }
    if (got_sample) {
      if (on_sample) {
        on_sample(sample);
      }
      uint64_t process_start_ns = now_ns();
      auto cmd = engine.process(sample, process_start_ns);
      uint64_t process_end_ns = now_ns();
      cmd.timestamp_ns = process_end_ns;
      cmd.latency_ms = static_cast<float>(process_end_ns - sample.timestamp_ns) / 1e6f;

      uint64_t dispatch_start_ns = now_ns();
      on_cmd(cmd);
      uint64_t dispatch_end_ns = now_ns();

      if (profiler) {
        profile.sample_timestamp_ns = sample.timestamp_ns;
        profile.process_start_ns = process_start_ns;
        profile.process_end_ns = process_end_ns;
        profile.dispatch_start_ns = dispatch_start_ns;
        profile.dispatch_end_ns = dispatch_end_ns;
        profile.process_ms = static_cast<float>(process_end_ns - process_start_ns) / 1e6f;
        profile.dispatch_ms = static_cast<float>(dispatch_end_ns - dispatch_start_ns) / 1e6f;
        profile.end_to_end_ms = static_cast<float>(dispatch_end_ns - sample.timestamp_ns) / 1e6f;
        auto pre_sleep = std::chrono::steady_clock::now();
        if (pre_sleep > next_tick) {
          profile.loop_slip_ms =
            std::chrono::duration_cast<std::chrono::duration<float, std::milli>>(pre_sleep - next_tick).count();
        }
        profiler->record(profile);
      }
    }
    std::this_thread::sleep_until(next_tick);
  }
}

} // namespace slipstream::physics
