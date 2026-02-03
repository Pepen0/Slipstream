#include "filters.h"

namespace slipstream::physics {

static float cutoff_to_rc(float cutoff_hz) {
  if (cutoff_hz <= 0.0f) {
    return 0.0f;
  }
  constexpr float kPi = 3.14159265358979323846f;
  return 1.0f / (2.0f * kPi * cutoff_hz);
}

HighPassFilter::HighPassFilter(float cutoff_hz)
  : rc_(cutoff_to_rc(cutoff_hz)), prev_input_(0.0f), prev_output_(0.0f), initialized_(false) {}

float HighPassFilter::process(float input, float dt_s) {
  if (dt_s <= 0.0f || rc_ == 0.0f) {
    return 0.0f;
  }
  if (!initialized_) {
    prev_input_ = input;
    prev_output_ = 0.0f;
    initialized_ = true;
    return 0.0f;
  }
  float alpha = rc_ / (rc_ + dt_s);
  float output = alpha * (prev_output_ + input - prev_input_);
  prev_input_ = input;
  prev_output_ = output;
  return output;
}

void HighPassFilter::reset(float value) {
  prev_input_ = value;
  prev_output_ = 0.0f;
  initialized_ = true;
}

LowPassFilter::LowPassFilter(float cutoff_hz)
  : rc_(cutoff_to_rc(cutoff_hz)), prev_output_(0.0f), initialized_(false) {}

float LowPassFilter::process(float input, float dt_s) {
  if (dt_s <= 0.0f || rc_ == 0.0f) {
    return input;
  }
  if (!initialized_) {
    prev_output_ = input;
    initialized_ = true;
    return input;
  }
  float alpha = dt_s / (rc_ + dt_s);
  prev_output_ = prev_output_ + alpha * (input - prev_output_);
  return prev_output_;
}

void LowPassFilter::reset(float value) {
  prev_output_ = value;
  initialized_ = true;
}

} // namespace slipstream::physics
