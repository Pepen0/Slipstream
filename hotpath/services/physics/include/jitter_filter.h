#pragma once

#include <cmath>

namespace slipstream::physics {

struct JitterFilterConfig {
  float deadband_rad = 0.0005f;
  float max_pitch_rate_rad_s = 2.0f;
  float max_roll_rate_rad_s = 2.0f;
};

class JitterFilter {
public:
  explicit JitterFilter(const JitterFilterConfig &config = {}) : config_(config) {}

  void reset(float pitch_rad = 0.0f, float roll_rad = 0.0f) {
    last_pitch_ = pitch_rad;
    last_roll_ = roll_rad;
    initialized_ = true;
  }

  void apply(float &pitch_rad, float &roll_rad, float dt_s) {
    if (!initialized_) {
      reset(pitch_rad, roll_rad);
      return;
    }

    if (dt_s <= 0.0f) {
      dt_s = 1e-3f;
    }

    pitch_rad = apply_axis(pitch_rad, last_pitch_, config_.deadband_rad,
                           config_.max_pitch_rate_rad_s, dt_s);
    roll_rad = apply_axis(roll_rad, last_roll_, config_.deadband_rad,
                          config_.max_roll_rate_rad_s, dt_s);

    last_pitch_ = pitch_rad;
    last_roll_ = roll_rad;
  }

private:
  static float apply_axis(float value, float last, float deadband,
                          float max_rate, float dt_s) {
    float delta = value - last;
    if (std::fabs(delta) < deadband) {
      return last;
    }
    float max_delta = max_rate * dt_s;
    if (delta > max_delta) {
      return last + max_delta;
    }
    if (delta < -max_delta) {
      return last - max_delta;
    }
    return value;
  }

  JitterFilterConfig config_;
  bool initialized_ = false;
  float last_pitch_ = 0.0f;
  float last_roll_ = 0.0f;
};

} // namespace slipstream::physics
