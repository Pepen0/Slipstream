#pragma once

#include <atomic>
#include <cstdint>
#include <functional>
#include <mutex>
#include <string>
#include <thread>

namespace slipstream::dashboard {

enum class FirmwareUpdateStage {
  Idle = 0,
  Downloading = 1,
  Verifying = 2,
  RequestingDfu = 3,
  Flashing = 4,
  VerifyingVersion = 5,
  Completed = 6,
  Failed = 7,
  RollingBack = 8,
  RolledBack = 9,
  Canceled = 10
};

struct FirmwareUpdateRequest {
  std::string artifact_uri;
  std::string sha256;
  std::string target_version;
  bool allow_rollback = true;
  std::string rollback_artifact_uri;
};

struct FirmwareUpdateStatus {
  FirmwareUpdateStage stage = FirmwareUpdateStage::Idle;
  float progress = 0.0f;
  std::string message;
  bool active = false;
  std::string current_version;
  std::string target_version;
  std::string last_error;
  bool rollback_available = false;
  uint64_t started_at_ns = 0;
  uint64_t updated_at_ns = 0;
  uint32_t mcu_fw_version_raw = 0;
  uint32_t mcu_fw_build = 0;
  bool mcu_usb_connected = false;
  uint8_t mcu_update_state = 0;
  uint8_t mcu_update_result = 0;
};

struct FirmwareVersionCheckResult {
  bool ok = true;
  bool update_available = false;
  std::string current_version;
  std::string latest_version;
  std::string message;
  bool mcu_connected = false;
};

class FirmwareManager {
public:
  using CommandOutputCallback = std::function<void(const std::string &)>;
  using CommandRunner =
      std::function<int(const std::string &, const CommandOutputCallback &)>;
  using MaintenanceSender = std::function<bool(uint8_t opcode, uint8_t arg0, uint32_t token)>;

  FirmwareManager();
  ~FirmwareManager();

  void set_command_runner(CommandRunner runner);
  void set_maintenance_sender(MaintenanceSender sender);

  void set_current_mcu_status(uint32_t fw_version_raw, uint32_t fw_build,
                              uint8_t update_state, uint8_t update_result,
                              bool usb_connected);

  bool start_update(const FirmwareUpdateRequest &request, std::string *message_out = nullptr);
  bool cancel_update(std::string *message_out = nullptr);

  FirmwareUpdateStatus status() const;
  FirmwareVersionCheckResult check_version(const std::string &latest_version) const;

private:
  static std::string format_firmware_version(uint32_t raw_version, uint32_t build);
  static int compare_versions(const std::string &lhs, const std::string &rhs);

  void worker_main(FirmwareUpdateRequest request);
  void set_status(FirmwareUpdateStage stage, float progress,
                  const std::string &message, bool active);
  void finish_with_failure(const FirmwareUpdateRequest &request, const std::string &error);
  bool prepare_artifact(const FirmwareUpdateRequest &request,
                        std::string *artifact_path, std::string *error_out);
  bool verify_artifact(const FirmwareUpdateRequest &request,
                       const std::string &artifact_path, std::string *error_out);
  bool request_dfu(std::string *error_out);
  bool flash_artifact(const std::string &artifact_path,
                      FirmwareUpdateStage stage, float base_progress,
                      float span_progress, std::string *error_out);
  bool rollback_artifact(const FirmwareUpdateRequest &request, std::string *error_out);
  bool verify_target_version(const FirmwareUpdateRequest &request, std::string *error_out);
  bool is_canceled() const;

  CommandRunner command_runner_;
  MaintenanceSender maintenance_sender_;

  mutable std::mutex mu_;
  FirmwareUpdateStatus status_{};
  bool worker_active_ = false;
  bool mcu_usb_connected_ = false;
  uint8_t mcu_update_state_ = 0;
  uint8_t mcu_update_result_ = 0;

  std::thread worker_;
  std::atomic<bool> cancel_requested_{false};
};

} // namespace slipstream::dashboard
