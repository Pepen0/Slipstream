#include "firmware_manager.h"

#include "logger.h"

#include <algorithm>
#include <array>
#include <chrono>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <regex>
#include <sstream>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#ifndef _WIN32
#include <sys/wait.h>
#endif

namespace slipstream::dashboard {
namespace {

constexpr uint8_t kMaintenanceOpUpdateRequest = 1u;
constexpr uint8_t kMaintenanceOpUpdateArm = 2u;
constexpr uint8_t kMaintenanceOpUpdateAbort = 3u;

uint64_t now_ns() {
  using clock = std::chrono::system_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(
             clock::now().time_since_epoch())
      .count();
}

float clamp01(float value) {
  if (value < 0.0f) {
    return 0.0f;
  }
  if (value > 1.0f) {
    return 1.0f;
  }
  return value;
}

std::string to_lower_copy(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
    return static_cast<char>(std::tolower(c));
  });
  return value;
}

bool starts_with(const std::string &value, const std::string &prefix) {
  return value.rfind(prefix, 0) == 0;
}

bool is_http_uri(const std::string &uri) {
  const auto lower = to_lower_copy(uri);
  return starts_with(lower, "http://") || starts_with(lower, "https://");
}

std::string env_string(const char *name, const std::string &fallback = {}) {
  const char *value = std::getenv(name);
  if (!value || value[0] == '\0') {
    return fallback;
  }
  return std::string(value);
}

int env_int(const char *name, int fallback) {
  const char *value = std::getenv(name);
  if (!value || value[0] == '\0') {
    return fallback;
  }
  try {
    return std::stoi(value);
  } catch (...) {
    return fallback;
  }
}

std::string shell_quote(const std::string &value) {
#ifdef _WIN32
  std::string out = "\"";
  for (char ch : value) {
    if (ch == '"') {
      out += "\\\"";
    } else {
      out.push_back(ch);
    }
  }
  out.push_back('"');
  return out;
#else
  std::string out = "'";
  for (char ch : value) {
    if (ch == '\'') {
      out += "'\\''";
    } else {
      out.push_back(ch);
    }
  }
  out.push_back('\'');
  return out;
#endif
}

std::string replace_all(std::string text, const std::string &needle,
                        const std::string &replacement) {
  std::size_t pos = 0;
  while ((pos = text.find(needle, pos)) != std::string::npos) {
    text.replace(pos, needle.size(), replacement);
    pos += replacement.size();
  }
  return text;
}

std::string render_command_template(std::string templ,
                                    const std::string &file_path,
                                    const std::string &url,
                                    const std::string &output_path) {
  templ = replace_all(templ, "{file}", shell_quote(file_path));
  templ = replace_all(templ, "{url}", shell_quote(url));
  templ = replace_all(templ, "{out}", shell_quote(output_path));
  return templ;
}

bool looks_like_hex64(const std::string &token) {
  if (token.size() != 64) {
    return false;
  }
  for (char ch : token) {
    if (!std::isxdigit(static_cast<unsigned char>(ch))) {
      return false;
    }
  }
  return true;
}

std::string first_hex64_token(const std::vector<std::string> &lines) {
  for (const auto &line : lines) {
    std::stringstream ss(line);
    std::string token;
    while (ss >> token) {
      token = to_lower_copy(token);
      if (looks_like_hex64(token)) {
        return token;
      }
    }

    std::string compact;
    compact.reserve(line.size());
    for (char ch : line) {
      if (std::isxdigit(static_cast<unsigned char>(ch))) {
        compact.push_back(static_cast<char>(std::tolower(static_cast<unsigned char>(ch))));
      }
    }
    if (looks_like_hex64(compact)) {
      return compact;
    }
  }
  return {};
}

int default_command_runner(const std::string &command,
                           const FirmwareManager::CommandOutputCallback &on_output) {
  std::string wrapped = command + " 2>&1";
#ifdef _WIN32
  FILE *pipe = _popen(wrapped.c_str(), "r");
#else
  FILE *pipe = popen(wrapped.c_str(), "r");
#endif
  if (!pipe) {
    return -1;
  }

  char buffer[512];
  while (std::fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    std::string line(buffer);
    while (!line.empty() && (line.back() == '\n' || line.back() == '\r')) {
      line.pop_back();
    }
    if (!line.empty() && on_output) {
      on_output(line);
    }
  }

#ifdef _WIN32
  return _pclose(pipe);
#else
  int raw = pclose(pipe);
  if (WIFEXITED(raw)) {
    return WEXITSTATUS(raw);
  }
  return raw;
#endif
}

} // namespace

FirmwareManager::FirmwareManager() : command_runner_(default_command_runner) {
  status_.stage = FirmwareUpdateStage::Idle;
  status_.message = "Idle.";
  status_.updated_at_ns = now_ns();
}

FirmwareManager::~FirmwareManager() {
  cancel_requested_.store(true);
  if (worker_.joinable()) {
    worker_.join();
  }
}

void FirmwareManager::set_command_runner(CommandRunner runner) {
  if (!runner) {
    return;
  }
  std::lock_guard<std::mutex> lock(mu_);
  command_runner_ = std::move(runner);
}

void FirmwareManager::set_maintenance_sender(MaintenanceSender sender) {
  std::lock_guard<std::mutex> lock(mu_);
  maintenance_sender_ = std::move(sender);
}

void FirmwareManager::set_current_mcu_status(uint32_t fw_version_raw,
                                             uint32_t fw_build,
                                             uint8_t update_state,
                                             uint8_t update_result,
                                             bool usb_connected) {
  std::lock_guard<std::mutex> lock(mu_);
  status_.mcu_fw_version_raw = fw_version_raw;
  status_.mcu_fw_build = fw_build;
  status_.mcu_usb_connected = usb_connected;
  status_.mcu_update_state = update_state;
  status_.mcu_update_result = update_result;
  status_.current_version = format_firmware_version(fw_version_raw, fw_build);
  mcu_update_state_ = update_state;
  mcu_update_result_ = update_result;
  mcu_usb_connected_ = usb_connected;
  status_.updated_at_ns = now_ns();
}

bool FirmwareManager::start_update(const FirmwareUpdateRequest &request,
                                   std::string *message_out) {
  FirmwareUpdateRequest effective = request;
  if (effective.artifact_uri.empty()) {
    effective.artifact_uri = env_string("SLIPSTREAM_FIRMWARE_ARTIFACT_URI");
  }
  if (effective.sha256.empty()) {
    effective.sha256 = env_string("SLIPSTREAM_FIRMWARE_SHA256");
  }
  if (effective.target_version.empty()) {
    effective.target_version = env_string("SLIPSTREAM_FIRMWARE_TARGET_VERSION");
  }
  if (effective.rollback_artifact_uri.empty()) {
    effective.rollback_artifact_uri =
        env_string("SLIPSTREAM_FIRMWARE_ROLLBACK_ARTIFACT_URI");
  }
  if (effective.artifact_uri.empty()) {
    if (message_out) {
      *message_out = "No firmware artifact URI configured.";
    }
    return false;
  }

  {
    std::lock_guard<std::mutex> lock(mu_);
    if (worker_active_) {
      if (message_out) {
        *message_out = "Firmware update already in progress.";
      }
      return false;
    }
    worker_active_ = true;
    cancel_requested_.store(false);
    status_.stage = FirmwareUpdateStage::Downloading;
    status_.progress = 0.02f;
    status_.active = true;
    status_.target_version = effective.target_version;
    status_.rollback_available =
        effective.allow_rollback && !effective.rollback_artifact_uri.empty();
    status_.last_error.clear();
    status_.message = "Preparing firmware update.";
    status_.started_at_ns = now_ns();
    status_.updated_at_ns = status_.started_at_ns;
  }

  if (worker_.joinable()) {
    worker_.join();
  }
  worker_ = std::thread([this, effective]() { worker_main(effective); });
  if (message_out) {
    *message_out = "Firmware update started.";
  }
  return true;
}

bool FirmwareManager::cancel_update(std::string *message_out) {
  bool active = false;
  {
    std::lock_guard<std::mutex> lock(mu_);
    active = worker_active_;
  }
  if (!active) {
    if (message_out) {
      *message_out = "No active firmware update.";
    }
    return false;
  }
  cancel_requested_.store(true);

  MaintenanceSender sender;
  {
    std::lock_guard<std::mutex> lock(mu_);
    sender = maintenance_sender_;
  }
  if (sender) {
    sender(kMaintenanceOpUpdateAbort, 0u, static_cast<uint32_t>(now_ns()));
  }
  if (message_out) {
    *message_out = "Cancel requested.";
  }
  return true;
}

FirmwareUpdateStatus FirmwareManager::status() const {
  std::lock_guard<std::mutex> lock(mu_);
  return status_;
}

FirmwareVersionCheckResult
FirmwareManager::check_version(const std::string &latest_version) const {
  FirmwareVersionCheckResult result;
  std::lock_guard<std::mutex> lock(mu_);
  result.current_version = status_.current_version;
  result.latest_version = latest_version.empty()
                              ? env_string("SLIPSTREAM_FIRMWARE_LATEST_VERSION")
                              : latest_version;
  result.mcu_connected = mcu_usb_connected_;
  if (result.current_version.empty()) {
    result.ok = false;
    result.message = "MCU firmware version is unavailable.";
    return result;
  }
  if (result.latest_version.empty()) {
    result.ok = true;
    result.update_available = false;
    result.message = "No latest firmware version provided.";
    return result;
  }

  result.update_available =
      compare_versions(result.latest_version, result.current_version) > 0;
  result.message = result.update_available
                       ? "Update available."
                       : "Firmware is up to date.";
  return result;
}

std::string FirmwareManager::format_firmware_version(uint32_t raw_version,
                                                     uint32_t build) {
  if (raw_version == 0 && build == 0) {
    return "";
  }
  const uint32_t major = (raw_version >> 24u) & 0xFFu;
  const uint32_t minor = (raw_version >> 16u) & 0xFFu;
  const uint32_t patch = (raw_version >> 8u) & 0xFFu;
  const uint32_t tweak = raw_version & 0xFFu;
  std::ostringstream ss;
  ss << major << "." << minor << "." << patch << "." << tweak;
  if (build > 0) {
    ss << "+b" << build;
  }
  return ss.str();
}

int FirmwareManager::compare_versions(const std::string &lhs,
                                      const std::string &rhs) {
  static const std::regex number_re(R"((\d+))");

  auto parse = [&](const std::string &value) {
    std::array<int, 4> parts{0, 0, 0, 0};
    int idx = 0;
    for (std::sregex_iterator it(value.begin(), value.end(), number_re),
         end;
         it != end && idx < static_cast<int>(parts.size()); ++it, ++idx) {
      parts[static_cast<std::size_t>(idx)] = std::stoi((*it)[1].str());
    }
    return parts;
  };

  const auto a = parse(lhs);
  const auto b = parse(rhs);
  for (std::size_t i = 0; i < a.size(); ++i) {
    if (a[i] < b[i]) {
      return -1;
    }
    if (a[i] > b[i]) {
      return 1;
    }
  }
  return 0;
}

void FirmwareManager::set_status(FirmwareUpdateStage stage, float progress,
                                 const std::string &message, bool active) {
  std::lock_guard<std::mutex> lock(mu_);
  status_.stage = stage;
  status_.progress = clamp01(progress);
  status_.message = message;
  status_.active = active;
  if (stage != FirmwareUpdateStage::Failed) {
    status_.last_error.clear();
  }
  status_.updated_at_ns = now_ns();
}

bool FirmwareManager::is_canceled() const {
  return cancel_requested_.load();
}

bool FirmwareManager::prepare_artifact(const FirmwareUpdateRequest &request,
                                       std::string *artifact_path,
                                       std::string *error_out) {
  const auto work_dir =
      std::filesystem::path(env_string("SLIPSTREAM_FIRMWARE_WORKDIR", "data/firmware"));
  std::error_code ec;
  std::filesystem::create_directories(work_dir, ec);
  if (ec) {
    if (error_out) {
      *error_out = "Unable to create firmware work directory: " + ec.message();
    }
    return false;
  }

  std::filesystem::path input_path(request.artifact_uri);
  std::filesystem::path output =
      work_dir / ("candidate_" + std::to_string(now_ns()) + input_path.extension().string());
  if (output.extension().empty()) {
    output += ".bin";
  }

  if (is_http_uri(request.artifact_uri)) {
    const std::string templ = env_string(
        "SLIPSTREAM_FIRMWARE_DOWNLOAD_CMD",
        "curl -L --fail --silent --show-error -o {out} {url}");
    const std::string cmd = render_command_template(
        templ, output.string(), request.artifact_uri, output.string());

    std::vector<std::string> output_lines;
    const int rc = command_runner_(cmd, [&](const std::string &line) {
      output_lines.push_back(line);
    });
    if (rc != 0) {
      if (error_out) {
        *error_out =
            "Firmware download failed (rc=" + std::to_string(rc) + ").";
      }
      return false;
    }
  } else {
    std::error_code copy_ec;
    std::filesystem::copy_file(input_path, output,
                               std::filesystem::copy_options::overwrite_existing,
                               copy_ec);
    if (copy_ec) {
      if (error_out) {
        *error_out = "Unable to stage firmware artifact: " + copy_ec.message();
      }
      return false;
    }
  }

  if (artifact_path) {
    *artifact_path = output.string();
  }
  return true;
}

bool FirmwareManager::verify_artifact(const FirmwareUpdateRequest &request,
                                      const std::string &artifact_path,
                                      std::string *error_out) {
  std::string expected = request.sha256;
  if (expected.empty()) {
    expected = env_string("SLIPSTREAM_FIRMWARE_SHA256");
  }
  if (expected.empty()) {
    return true;
  }

  expected = to_lower_copy(expected);
  expected.erase(
      std::remove_if(expected.begin(), expected.end(),
                     [](unsigned char c) { return std::isspace(c) != 0; }),
      expected.end());

  const std::string templ =
#ifdef _WIN32
      env_string("SLIPSTREAM_FIRMWARE_SHA256_CMD",
                 "certutil -hashfile {file} SHA256");
#else
      env_string("SLIPSTREAM_FIRMWARE_SHA256_CMD",
                 "shasum -a 256 {file}");
#endif
  const std::string cmd = render_command_template(templ, artifact_path, "", "");

  std::vector<std::string> lines;
  const int rc = command_runner_(cmd, [&](const std::string &line) {
    lines.push_back(line);
  });
  if (rc != 0) {
    if (error_out) {
      *error_out = "SHA-256 command failed (rc=" + std::to_string(rc) + ").";
    }
    return false;
  }

  const std::string actual = first_hex64_token(lines);
  if (actual.empty()) {
    if (error_out) {
      *error_out = "Unable to parse SHA-256 output.";
    }
    return false;
  }
  if (actual != expected) {
    if (error_out) {
      *error_out = "SHA-256 mismatch.";
    }
    return false;
  }
  return true;
}

bool FirmwareManager::request_dfu(std::string *error_out) {
  MaintenanceSender sender;
  {
    std::lock_guard<std::mutex> lock(mu_);
    sender = maintenance_sender_;
  }
  if (!sender) {
    return true;
  }

  const uint32_t token = static_cast<uint32_t>(now_ns());
  if (!sender(kMaintenanceOpUpdateRequest, 0u, token)) {
    if (error_out) {
      *error_out = "Failed to queue UPDATE_REQUEST.";
    }
    return false;
  }
  std::this_thread::sleep_for(std::chrono::milliseconds(60));
  if (!sender(kMaintenanceOpUpdateArm, 0u, token)) {
    if (error_out) {
      *error_out = "Failed to queue UPDATE_ARM.";
    }
    return false;
  }

  const int delay_ms = std::max(0, env_int("SLIPSTREAM_FIRMWARE_DFU_PREPARE_DELAY_MS", 900));
  if (delay_ms > 0) {
    std::this_thread::sleep_for(std::chrono::milliseconds(delay_ms));
  }
  return true;
}

bool FirmwareManager::flash_artifact(const std::string &artifact_path,
                                     FirmwareUpdateStage stage,
                                     float base_progress,
                                     float span_progress,
                                     std::string *error_out) {
  const std::string templ = env_string(
      "SLIPSTREAM_DFU_FLASH_CMD",
      "dfu-util -a 0 -s 0x08000000:leave -D {file}");
  const std::string cmd =
      render_command_template(templ, artifact_path, "", artifact_path);
  std::regex percent_re(R"((\d{1,3})%)");

  const int rc = command_runner_(cmd, [&](const std::string &line) {
    std::smatch m;
    if (std::regex_search(line, m, percent_re)) {
      int pct = std::stoi(m[1].str());
      if (pct < 0) {
        pct = 0;
      }
      if (pct > 100) {
        pct = 100;
      }
      const float progress =
          base_progress + span_progress * (static_cast<float>(pct) / 100.0f);
      set_status(stage, progress, "Flashing firmware...", true);
    }
  });
  if (rc != 0) {
    if (error_out) {
      *error_out = "DFU flash command failed (rc=" + std::to_string(rc) + ").";
    }
    return false;
  }
  return true;
}

bool FirmwareManager::rollback_artifact(const FirmwareUpdateRequest &request,
                                        std::string *error_out) {
  std::string rollback_uri = request.rollback_artifact_uri;
  if (rollback_uri.empty()) {
    rollback_uri = env_string("SLIPSTREAM_FIRMWARE_ROLLBACK_ARTIFACT_URI");
  }
  if (rollback_uri.empty()) {
    if (error_out) {
      *error_out = "Rollback artifact URI is unavailable.";
    }
    return false;
  }

  FirmwareUpdateRequest rollback_req;
  rollback_req.artifact_uri = rollback_uri;
  rollback_req.allow_rollback = false;

  std::string rollback_file;
  if (!prepare_artifact(rollback_req, &rollback_file, error_out)) {
    return false;
  }
  return flash_artifact(rollback_file, FirmwareUpdateStage::RollingBack, 0.35f,
                        0.55f, error_out);
}

bool FirmwareManager::verify_target_version(const FirmwareUpdateRequest &request,
                                            std::string *error_out) {
  if (request.target_version.empty()) {
    return true;
  }

  uint32_t raw = 0;
  std::string current;
  {
    std::lock_guard<std::mutex> lock(mu_);
    raw = status_.mcu_fw_version_raw;
    current = status_.current_version;
  }
  if (raw == 0 || current.empty()) {
    return true;
  }

  const int timeout_ms =
      std::max(0, env_int("SLIPSTREAM_FIRMWARE_VERIFY_TIMEOUT_MS", 5000));
  const auto deadline =
      std::chrono::steady_clock::now() + std::chrono::milliseconds(timeout_ms);

  while (std::chrono::steady_clock::now() < deadline) {
    {
      std::lock_guard<std::mutex> lock(mu_);
      current = status_.current_version;
    }
    if (!current.empty() &&
        compare_versions(current, request.target_version) >= 0) {
      return true;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
  }

  if (error_out) {
    *error_out = "Target firmware version not observed after flash.";
  }
  return false;
}

void FirmwareManager::finish_with_failure(const FirmwareUpdateRequest &request,
                                          const std::string &error) {
  {
    std::lock_guard<std::mutex> lock(mu_);
    status_.last_error = error;
    status_.message = error;
    status_.stage = FirmwareUpdateStage::Failed;
    status_.active = false;
    status_.updated_at_ns = now_ns();
  }

  MaintenanceSender sender;
  {
    std::lock_guard<std::mutex> lock(mu_);
    sender = maintenance_sender_;
  }
  if (sender) {
    sender(kMaintenanceOpUpdateAbort, 0u, static_cast<uint32_t>(now_ns()));
  }

  const std::string rollback_uri = request.rollback_artifact_uri.empty()
                                       ? env_string("SLIPSTREAM_FIRMWARE_ROLLBACK_ARTIFACT_URI")
                                       : request.rollback_artifact_uri;
  if (!(request.allow_rollback && !rollback_uri.empty())) {
    return;
  }

  set_status(FirmwareUpdateStage::RollingBack, 0.25f,
             "Update failed. Attempting rollback...", true);
  std::string rollback_error;
  if (rollback_artifact(request, &rollback_error)) {
    set_status(FirmwareUpdateStage::RolledBack, 1.0f,
               "Rollback completed after update failure.", false);
    return;
  }

  std::lock_guard<std::mutex> lock(mu_);
  status_.stage = FirmwareUpdateStage::Failed;
  status_.active = false;
  status_.last_error = error + " Rollback failed: " + rollback_error;
  status_.message = status_.last_error;
  status_.updated_at_ns = now_ns();
}

void FirmwareManager::worker_main(FirmwareUpdateRequest request) {
  auto mark_finished = [this]() {
    std::lock_guard<std::mutex> lock(mu_);
    worker_active_ = false;
    status_.updated_at_ns = now_ns();
  };

  auto canceled_exit = [&]() {
    set_status(FirmwareUpdateStage::Canceled, status_.progress,
               "Firmware update canceled.", false);
    mark_finished();
  };

  if (is_canceled()) {
    canceled_exit();
    return;
  }

  std::string artifact_path;
  std::string error;

  set_status(FirmwareUpdateStage::Downloading, 0.08f,
             "Downloading firmware artifact...", true);
  if (!prepare_artifact(request, &artifact_path, &error)) {
    finish_with_failure(request, error);
    mark_finished();
    return;
  }

  if (is_canceled()) {
    canceled_exit();
    return;
  }

  set_status(FirmwareUpdateStage::Verifying, 0.32f,
             "Verifying firmware artifact...", true);
  if (!verify_artifact(request, artifact_path, &error)) {
    finish_with_failure(request, error);
    mark_finished();
    return;
  }

  if (is_canceled()) {
    canceled_exit();
    return;
  }

  set_status(FirmwareUpdateStage::RequestingDfu, 0.52f,
             "Requesting MCU DFU mode...", true);
  if (!request_dfu(&error)) {
    finish_with_failure(request, error);
    mark_finished();
    return;
  }

  if (is_canceled()) {
    canceled_exit();
    return;
  }

  set_status(FirmwareUpdateStage::Flashing, 0.60f, "Flashing firmware...", true);
  if (!flash_artifact(artifact_path, FirmwareUpdateStage::Flashing, 0.60f,
                      0.33f, &error)) {
    finish_with_failure(request, error);
    mark_finished();
    return;
  }

  if (is_canceled()) {
    canceled_exit();
    return;
  }

  set_status(FirmwareUpdateStage::VerifyingVersion, 0.95f,
             "Verifying firmware version...", true);
  if (!verify_target_version(request, &error)) {
    finish_with_failure(request, error);
    mark_finished();
    return;
  }

  set_status(FirmwareUpdateStage::Completed, 1.0f,
             "Firmware update complete.", false);
  mark_finished();
}

} // namespace slipstream::dashboard
