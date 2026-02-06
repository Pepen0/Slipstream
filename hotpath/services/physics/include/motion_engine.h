#pragma once

#include "filters.h"
#include "jitter_filter.h"
#include "kinematics.h"
#include "telemetry_sample.h"
#include "transform.h"

#include <cstdint>

namespace slipstream::physics {

struct MotionConfig {
  float hp_cutoff_hz = 0.5f;
  float lp_cutoff_hz = 1.0f;
  float pitch_gain = 0.015f; // rad per m/s^2
  float roll_gain = 0.015f;
  TransformConfig transform{};
  RigKinematics kinematics{};
  JitterFilterConfig jitter{};
};

struct MotionCommand {
  uint64_t timestamp_ns = 0;
  float pitch_rad = 0.0f;
  float roll_rad = 0.0f;
  MotorTargets targets{};
  float latency_ms = 0.0f;
};

class MotionEngine {
public:
  explicit MotionEngine(const MotionConfig &config);
  MotionCommand process(const TelemetrySample &sample, uint64_t now_ns);

private:
  MotionConfig config_;
  HighPassFilter hp_surge_;
  HighPassFilter hp_sway_;
  LowPassFilter lp_pitch_;
  LowPassFilter lp_roll_;
  JitterFilter jitter_;
  uint64_t last_sample_ns_ = 0;
};

} // namespace slipstream::physics
