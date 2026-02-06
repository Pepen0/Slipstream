#include "session_store.h"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <sstream>

namespace slipstream::dashboard {

namespace {
std::string sanitize_id(const std::string &input) {
  std::string out;
  out.reserve(input.size());
  for (char c : input) {
    if ((c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') ||
        (c >= '0' && c <= '9') ||
        c == '_' || c == '-') {
      out.push_back(c);
    } else {
      out.push_back('_');
    }
  }
  if (out.empty()) {
    out = "session";
  }
  return out;
}

std::string metadata_path(const std::string &base_dir, const std::string &session_id) {
  return (std::filesystem::path(base_dir) / (sanitize_id(session_id) + ".json")).string();
}

std::string telemetry_path(const std::string &base_dir, const std::string &session_id) {
  return (std::filesystem::path(base_dir) / (sanitize_id(session_id) + "_telemetry.jsonl")).string();
}

bool write_metadata(const std::string &path, const SessionMetadata &metadata) {
  std::ofstream out(path, std::ios::trunc);
  if (!out.is_open()) {
    return false;
  }
  out << "{\n";
  out << "  \"session_id\": \"" << metadata.session_id << "\",\n";
  out << "  \"track\": \"" << metadata.track << "\",\n";
  out << "  \"car\": \"" << metadata.car << "\",\n";
  out << "  \"start_time_ns\": " << metadata.start_time_ns << ",\n";
  out << "  \"end_time_ns\": " << metadata.end_time_ns << ",\n";
  out << "  \"duration_ms\": " << metadata.duration_ms << "\n";
  out << "}\n";
  return true;
}

std::string read_file(const std::string &path) {
  std::ifstream in(path);
  if (!in.is_open()) {
    return {};
  }
  std::ostringstream out;
  out << in.rdbuf();
  return out.str();
}

std::string find_string_field(const std::string &content, const std::string &key) {
  auto needle = "\"" + key + "\"";
  auto pos = content.find(needle);
  if (pos == std::string::npos) return {};
  pos = content.find(':', pos);
  if (pos == std::string::npos) return {};
  pos = content.find('"', pos);
  if (pos == std::string::npos) return {};
  auto end = content.find('"', pos + 1);
  if (end == std::string::npos) return {};
  return content.substr(pos + 1, end - pos - 1);
}

uint64_t find_uint_field(const std::string &content, const std::string &key) {
  auto needle = "\"" + key + "\"";
  auto pos = content.find(needle);
  if (pos == std::string::npos) return 0;
  pos = content.find(':', pos);
  if (pos == std::string::npos) return 0;
  pos += 1;
  while (pos < content.size() && (content[pos] == ' ' || content[pos] == '\t')) {
    pos += 1;
  }
  uint64_t value = 0;
  while (pos < content.size() && content[pos] >= '0' && content[pos] <= '9') {
    value = value * 10 + static_cast<uint64_t>(content[pos] - '0');
    pos += 1;
  }
  return value;
}

SessionMetadata parse_metadata(const std::string &content) {
  SessionMetadata metadata;
  metadata.session_id = find_string_field(content, "session_id");
  metadata.track = find_string_field(content, "track");
  metadata.car = find_string_field(content, "car");
  metadata.start_time_ns = find_uint_field(content, "start_time_ns");
  metadata.end_time_ns = find_uint_field(content, "end_time_ns");
  metadata.duration_ms = find_uint_field(content, "duration_ms");
  return metadata;
}

} // namespace

SessionStore::SessionStore(std::string base_dir) : base_dir_(std::move(base_dir)) {
  std::filesystem::create_directories(base_dir_);
}

bool SessionStore::start_session(const SessionMetadata &metadata) {
  if (metadata.session_id.empty()) {
    return false;
  }
  std::filesystem::create_directories(base_dir_);
  auto meta_path = metadata_path(base_dir_, metadata.session_id);
  if (!write_metadata(meta_path, metadata)) {
    return false;
  }
  auto tel_path = telemetry_path(base_dir_, metadata.session_id);
  std::ofstream tel(tel_path, std::ios::trunc);
  return tel.is_open();
}

bool SessionStore::end_session(const std::string &session_id, uint64_t end_time_ns) {
  if (session_id.empty()) {
    return false;
  }
  auto meta_path = metadata_path(base_dir_, session_id);
  auto content = read_file(meta_path);
  if (content.empty()) {
    return false;
  }
  auto metadata = parse_metadata(content);
  metadata.end_time_ns = end_time_ns;
  if (metadata.start_time_ns > 0 && end_time_ns >= metadata.start_time_ns) {
    metadata.duration_ms = (end_time_ns - metadata.start_time_ns) / 1000000ULL;
  }
  return write_metadata(meta_path, metadata);
}

bool SessionStore::append_telemetry(const std::string &session_id, const TelemetryRecord &sample) {
  if (session_id.empty()) {
    return false;
  }
  auto tel_path = telemetry_path(base_dir_, session_id);
  std::ofstream out(tel_path, std::ios::app);
  if (!out.is_open()) {
    return false;
  }
  out << "{";
  out << "\"timestamp_ns\":" << sample.timestamp_ns << ",";
  out << "\"pitch_rad\":" << sample.pitch_rad << ",";
  out << "\"roll_rad\":" << sample.roll_rad << ",";
  out << "\"left_target_m\":" << sample.left_target_m << ",";
  out << "\"right_target_m\":" << sample.right_target_m << ",";
  out << "\"latency_ms\":" << sample.latency_ms;
  out << "}\n";
  return true;
}

std::vector<SessionMetadata> SessionStore::list_sessions() const {
  std::vector<SessionMetadata> sessions;
  if (!std::filesystem::exists(base_dir_)) {
    return sessions;
  }
  for (const auto &entry : std::filesystem::directory_iterator(base_dir_)) {
    if (!entry.is_regular_file()) {
      continue;
    }
    auto path = entry.path();
    if (path.extension() != ".json") {
      continue;
    }
    auto content = read_file(path.string());
    if (content.empty()) {
      continue;
    }
    sessions.push_back(parse_metadata(content));
  }
  std::sort(sessions.begin(), sessions.end(), [](const SessionMetadata &a, const SessionMetadata &b) {
    return a.start_time_ns > b.start_time_ns;
  });
  return sessions;
}

} // namespace slipstream::dashboard
