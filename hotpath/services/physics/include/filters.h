#pragma once

#include <cstdint>

namespace slipstream::physics {

class HighPassFilter {
public:
  explicit HighPassFilter(float cutoff_hz = 0.5f);
  float process(float input, float dt_s);
  void reset(float value = 0.0f);

private:
  float rc_;
  float prev_input_;
  float prev_output_;
  bool initialized_;
};

class LowPassFilter {
public:
  explicit LowPassFilter(float cutoff_hz = 1.0f);
  float process(float input, float dt_s);
  void reset(float value = 0.0f);

private:
  float rc_;
  float prev_output_;
  bool initialized_;
};

} // namespace slipstream::physics
