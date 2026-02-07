#pragma once

#include "igame_telemetry_provider.h"
#include "motion_engine.h"

#include <chrono>
#include <functional>

namespace slipstream::physics {

using MotionCallback = std::function<void(const MotionCommand &cmd)>;
using TelemetryCallback = std::function<void(const TelemetrySample &sample)>;
class MotionProfiler;

class MotionLoop {
public:
  explicit MotionLoop(int target_hz = 200);
  void run(IGameTelemetryProvider &provider, MotionEngine &engine, const MotionCallback &on_cmd,
           const TelemetryCallback &on_sample = nullptr, MotionProfiler *profiler = nullptr);

private:
  int target_hz_;
};

} // namespace slipstream::physics
