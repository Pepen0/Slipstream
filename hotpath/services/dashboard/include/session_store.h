#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace slipstream::dashboard {

struct SessionMetadata {
  std::string session_id;
  std::string track;
  std::string car;
  uint64_t start_time_ns = 0;
  uint64_t end_time_ns = 0;
  uint64_t duration_ms = 0;
};

struct TelemetryRecord {
  uint64_t timestamp_ns = 0;
  float pitch_rad = 0.0f;
  float roll_rad = 0.0f;
  float left_target_m = 0.0f;
  float right_target_m = 0.0f;
  float latency_ms = 0.0f;
  float speed_kmh = 0.0f;
  int32_t gear = 0;
  float engine_rpm = 0.0f;
  float track_progress = 0.0f;
};

class SessionStore {
public:
  explicit SessionStore(std::string base_dir);

  bool start_session(const SessionMetadata &metadata);
  bool end_session(const std::string &session_id, uint64_t end_time_ns);
  bool append_telemetry(const std::string &session_id, const TelemetryRecord &sample);
  std::vector<SessionMetadata> list_sessions() const;
  std::vector<TelemetryRecord> read_telemetry(const std::string &session_id,
                                              std::size_t max_samples = 0) const;

private:
  std::string base_dir_;
};

} // namespace slipstream::dashboard
