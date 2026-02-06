#include "session_store.h"

#include <cassert>
#include <filesystem>
#include <fstream>

using slipstream::dashboard::SessionMetadata;
using slipstream::dashboard::SessionStore;
using slipstream::dashboard::TelemetryRecord;

int main() {
  auto temp_dir = std::filesystem::temp_directory_path() / "slipstream_sessions_test";
  std::filesystem::remove_all(temp_dir);
  std::filesystem::create_directories(temp_dir);

  SessionStore store(temp_dir.string());

  SessionMetadata meta;
  meta.session_id = "sess-test";
  meta.track = "track";
  meta.car = "car";
  meta.start_time_ns = 1'000'000'000ULL;

  assert(store.start_session(meta));

  TelemetryRecord rec;
  rec.timestamp_ns = 1'000'000'500ULL;
  rec.pitch_rad = 0.1f;
  rec.roll_rad = -0.1f;
  rec.left_target_m = 0.02f;
  rec.right_target_m = 0.03f;
  rec.latency_ms = 5.0f;
  assert(store.append_telemetry(meta.session_id, rec));

  assert(store.end_session(meta.session_id, 1'010'000'000ULL));

  auto sessions = store.list_sessions();
  assert(!sessions.empty());
  assert(sessions.front().session_id == meta.session_id);
  assert(sessions.front().duration_ms >= 10);

  auto telemetry_path = temp_dir / "sess-test_telemetry.jsonl";
  std::ifstream tel(telemetry_path);
  assert(tel.good());

  std::filesystem::remove_all(temp_dir);
  return 0;
}
