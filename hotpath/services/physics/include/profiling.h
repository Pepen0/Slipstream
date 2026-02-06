#pragma once

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <iomanip>
#include <sstream>
#include <string>

namespace slipstream::physics {

struct MotionProfile {
  uint64_t sample_timestamp_ns = 0;
  uint64_t read_start_ns = 0;
  uint64_t read_end_ns = 0;
  uint64_t process_start_ns = 0;
  uint64_t process_end_ns = 0;
  uint64_t dispatch_start_ns = 0;
  uint64_t dispatch_end_ns = 0;
  float read_ms = 0.0f;
  float process_ms = 0.0f;
  float dispatch_ms = 0.0f;
  float end_to_end_ms = 0.0f;
  float loop_slip_ms = 0.0f;
};

struct StatSummary {
  std::size_t count = 0;
  double mean = 0.0;
  double min = 0.0;
  double max = 0.0;
  double stddev = 0.0;
};

class RollingStats {
public:
  void reset() {
    count_ = 0;
    mean_ = 0.0;
    m2_ = 0.0;
    min_ = 0.0;
    max_ = 0.0;
  }

  void add(double value) {
    if (count_ == 0) {
      min_ = value;
      max_ = value;
    } else {
      if (value < min_) min_ = value;
      if (value > max_) max_ = value;
    }
    ++count_;
    double delta = value - mean_;
    mean_ += delta / static_cast<double>(count_);
    double delta2 = value - mean_;
    m2_ += delta * delta2;
  }

  StatSummary summary() const {
    StatSummary out;
    out.count = count_;
    out.mean = mean_;
    out.min = min_;
    out.max = max_;
    out.stddev = stddev();
    return out;
  }

private:
  double variance() const {
    if (count_ < 2) {
      return 0.0;
    }
    return m2_ / static_cast<double>(count_ - 1);
  }

  double stddev() const {
    return std::sqrt(variance());
  }

  std::size_t count_ = 0;
  double mean_ = 0.0;
  double m2_ = 0.0;
  double min_ = 0.0;
  double max_ = 0.0;
};

class MotionProfiler {
public:
  void reset() {
    last_ = MotionProfile{};
    end_to_end_.reset();
    read_.reset();
    process_.reset();
    dispatch_.reset();
    loop_slip_.reset();
  }

  void record(const MotionProfile &profile) {
    last_ = profile;
    end_to_end_.add(profile.end_to_end_ms);
    read_.add(profile.read_ms);
    process_.add(profile.process_ms);
    dispatch_.add(profile.dispatch_ms);
    loop_slip_.add(profile.loop_slip_ms);
  }

  const MotionProfile &last() const { return last_; }
  StatSummary end_to_end() const { return end_to_end_.summary(); }
  StatSummary read() const { return read_.summary(); }
  StatSummary process() const { return process_.summary(); }
  StatSummary dispatch() const { return dispatch_.summary(); }
  StatSummary loop_slip() const { return loop_slip_.summary(); }

  std::string report() const {
    std::ostringstream out;
    out << std::fixed << std::setprecision(3);
    append_stat(out, "end_to_end_ms", end_to_end());
    append_stat(out, "read_ms", read());
    append_stat(out, "process_ms", process());
    append_stat(out, "dispatch_ms", dispatch());
    append_stat(out, "loop_slip_ms", loop_slip());
    return out.str();
  }

private:
  static void append_stat(std::ostringstream &out, const char *label, const StatSummary &s) {
    out << label << ": count=" << s.count
        << " mean=" << s.mean
        << " min=" << s.min
        << " max=" << s.max
        << " stddev=" << s.stddev << '\n';
  }

  MotionProfile last_{};
  RollingStats end_to_end_{};
  RollingStats read_{};
  RollingStats process_{};
  RollingStats dispatch_{};
  RollingStats loop_slip_{};
};

} // namespace slipstream::physics
