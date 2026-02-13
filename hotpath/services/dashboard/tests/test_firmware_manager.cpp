#include "firmware_manager.h"

#include <cassert>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <thread>
#include <vector>

using slipstream::dashboard::FirmwareManager;
using slipstream::dashboard::FirmwareUpdateRequest;
using slipstream::dashboard::FirmwareUpdateStage;

namespace {

uint32_t pack_fw(uint32_t major, uint32_t minor, uint32_t patch, uint32_t build) {
  return ((major & 0xFFu) << 24u) | ((minor & 0xFFu) << 16u) |
         ((patch & 0xFFu) << 8u) | (build & 0xFFu);
}

void write_text_file(const std::filesystem::path &path, const std::string &content) {
  std::ofstream out(path, std::ios::binary);
  out << content;
}

bool set_env_var(const char *key, const char *value) {
#ifdef _WIN32
  return _putenv_s(key, value) == 0;
#else
  return setenv(key, value, 1) == 0;
#endif
}

bool unset_env_var(const char *key) {
#ifdef _WIN32
  return _putenv_s(key, "") == 0;
#else
  return unsetenv(key) == 0;
#endif
}

bool wait_until_done(FirmwareManager &manager, int timeout_ms = 3000) {
  const auto deadline =
      std::chrono::steady_clock::now() + std::chrono::milliseconds(timeout_ms);
  while (std::chrono::steady_clock::now() < deadline) {
    const auto status = manager.status();
    if (!status.active) {
      return true;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }
  return false;
}

} // namespace

int main() {
  assert(set_env_var("SLIPSTREAM_FIRMWARE_DFU_PREPARE_DELAY_MS", "1"));

  {
    FirmwareManager manager;
    manager.set_current_mcu_status(pack_fw(1, 3, 2, 0), 12, 0, 0, true);
    const auto check = manager.check_version("1.3.3.0");
    assert(check.ok);
    assert(check.update_available);
    assert(check.current_version.find("1.3.2.0") == 0);
  }

  auto temp_dir = std::filesystem::temp_directory_path() /
                  "slipstream_dashboard_firmware_manager_test";
  std::filesystem::remove_all(temp_dir);
  std::filesystem::create_directories(temp_dir);
  const auto artifact = temp_dir / "candidate.bin";
  const auto rollback = temp_dir / "rollback.bin";
  write_text_file(artifact, "candidate-image");
  write_text_file(rollback, "rollback-image");

  {
    FirmwareManager manager;
    manager.set_current_mcu_status(pack_fw(1, 3, 2, 0), 12, 0, 0, true);

    std::vector<uint8_t> maintenance_ops;
    manager.set_maintenance_sender(
        [&](uint8_t opcode, uint8_t, uint32_t) {
          maintenance_ops.push_back(opcode);
          return true;
        });

    manager.set_command_runner(
        [&](const std::string &cmd, const FirmwareManager::CommandOutputCallback &out) {
          if (cmd.find("dfu-util") != std::string::npos) {
            if (out) {
              out("Download 10%");
              out("Download 100%");
            }
            manager.set_current_mcu_status(pack_fw(1, 3, 3, 0), 13, 0, 0, true);
            return 0;
          }
          if (out) {
            out("ok");
          }
          return 0;
        });

    FirmwareUpdateRequest req;
    req.artifact_uri = artifact.string();
    req.target_version = "1.3.3.0";
    req.allow_rollback = true;
    req.rollback_artifact_uri = rollback.string();

    std::string start_message;
    assert(manager.start_update(req, &start_message));
    assert(wait_until_done(manager));
    const auto status = manager.status();
    assert(status.stage == FirmwareUpdateStage::Completed);
    assert(status.progress >= 0.99f);
    assert(status.last_error.empty());

    assert(!maintenance_ops.empty());
    assert(maintenance_ops[0] == 1u);
    assert(maintenance_ops.size() >= 2);
    assert(maintenance_ops[1] == 2u);
  }

  {
    FirmwareManager manager;
    manager.set_current_mcu_status(pack_fw(1, 3, 2, 0), 12, 0, 0, true);
    manager.set_maintenance_sender([](uint8_t, uint8_t, uint32_t) { return true; });

    int flash_calls = 0;
    manager.set_command_runner(
        [&](const std::string &cmd, const FirmwareManager::CommandOutputCallback &out) {
          if (cmd.find("dfu-util") != std::string::npos) {
            flash_calls += 1;
            if (out) {
              out("Download 55%");
            }
            return flash_calls == 1 ? 1 : 0;
          }
          return 0;
        });

    FirmwareUpdateRequest req;
    req.artifact_uri = artifact.string();
    req.target_version = "1.3.3.0";
    req.allow_rollback = true;
    req.rollback_artifact_uri = rollback.string();

    std::string start_message;
    assert(manager.start_update(req, &start_message));
    assert(wait_until_done(manager));
    const auto status = manager.status();
    assert(status.stage == FirmwareUpdateStage::RolledBack);
    assert(!status.active);
    assert(flash_calls >= 2);
  }

  std::filesystem::remove_all(temp_dir);
  unset_env_var("SLIPSTREAM_FIRMWARE_DFU_PREPARE_DELAY_MS");
  return 0;
}
