#include "motion_engine.h"

#include <cmath>

namespace slipstream::physics {

static float clamp(float v, float lo, float hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

MotionEngine::MotionEngine(const MotionConfig &config)
  : config_(config),
    hp_surge_(config.hp_cutoff_hz),
    hp_sway_(config.hp_cutoff_hz),
    lp_pitch_(config.lp_cutoff_hz),
    lp_roll_(config.lp_cutoff_hz) {}

MotionCommand MotionEngine::process(const TelemetrySample &sample, uint64_t now_ns) {
  float dt_s = 0.0f;
  if (last_sample_ns_ > 0 && sample.timestamp_ns > last_sample_ns_) {
    dt_s = static_cast<float>(sample.timestamp_ns - last_sample_ns_) * 1e-9f;
  } else {
    dt_s = 1.0f / 200.0f;
  }
  last_sample_ns_ = sample.timestamp_ns;

  auto rig = transform_accel(sample.accel_mps2, config_.transform);

  float surge_hp = hp_surge_.process(rig.surge, dt_s);
  float sway_hp = hp_sway_.process(rig.sway, dt_s);

  float pitch_raw = clamp(surge_hp * config_.pitch_gain,
                          -config_.kinematics.max_pitch_rad,
                          config_.kinematics.max_pitch_rad);
  float roll_raw = clamp(sway_hp * config_.roll_gain,
                         -config_.kinematics.max_roll_rad,
                         config_.kinematics.max_roll_rad);

  float pitch = lp_pitch_.process(pitch_raw, dt_s);
  float roll = lp_roll_.process(roll_raw, dt_s);

  MotorTargets targets = pitch_roll_to_targets(pitch, roll, config_.kinematics);

  MotionCommand cmd;
  cmd.timestamp_ns = now_ns;
  cmd.pitch_rad = pitch;
  cmd.roll_rad = roll;
  cmd.targets = targets;
  cmd.latency_ms = static_cast<float>(now_ns - sample.timestamp_ns) / 1e6f;
  return cmd;
}

} // namespace slipstream::physics
