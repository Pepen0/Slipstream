#include "frame_batcher.h"
#include "protocol.h"
#include "serial_port.h"

#include <atomic>
#include <chrono>
#include <csignal>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#endif

using namespace heartbeat;

namespace {
std::atomic<bool> running{true};

void on_signal(int) {
  running = false;
}

#ifdef _WIN32
BOOL WINAPI on_console_ctrl(DWORD) {
  running = false;
  return TRUE;
}
#endif

struct Options {
  std::string port;
  int baud = 115200;
  int interval_ms = 50;
  int reconnect_ms = 1000;
  bool print_status = false;
  bool batch = false;
  size_t batch_max_bytes = 64;
  bool send_command = false;
  float cmd_left_m = 0.0f;
  float cmd_right_m = 0.0f;
  bool enter_dfu = false;
};

Options parse_args(int argc, char **argv) {
  Options opt;
#ifdef _WIN32
  opt.port = "COM3";
#else
  opt.port = "/dev/ttyACM0";
#endif

  for (int i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    if (arg == "--port" && i + 1 < argc) {
      opt.port = argv[++i];
    } else if (arg == "--baud" && i + 1 < argc) {
      opt.baud = std::stoi(argv[++i]);
    } else if (arg == "--interval" && i + 1 < argc) {
      opt.interval_ms = std::stoi(argv[++i]);
    } else if (arg == "--reconnect" && i + 1 < argc) {
      opt.reconnect_ms = std::stoi(argv[++i]);
    } else if (arg == "--status") {
      opt.print_status = true;
    } else if (arg == "--batch") {
      opt.batch = true;
    } else if (arg == "--batch-max" && i + 1 < argc) {
      opt.batch = true;
      opt.batch_max_bytes = static_cast<size_t>(std::stoul(argv[++i]));
    } else if (arg == "--command") {
      opt.send_command = true;
    } else if (arg == "--cmd-left" && i + 1 < argc) {
      opt.send_command = true;
      opt.cmd_left_m = std::stof(argv[++i]);
    } else if (arg == "--cmd-right" && i + 1 < argc) {
      opt.send_command = true;
      opt.cmd_right_m = std::stof(argv[++i]);
    } else if (arg == "--dfu") {
      opt.enter_dfu = true;
    } else if (arg == "--help") {
      std::cout << "Usage: heartbeat_sender [--port COM3] [--baud 115200] [--interval 50] [--reconnect 1000]\n"
                   "                         [--status] [--batch] [--batch-max 64]\n"
                   "                         [--command] [--cmd-left 0.0] [--cmd-right 0.0]\n"
                   "                         [--dfu]\n";
      std::exit(0);
    }
  }
  return opt;
}

} // namespace

static uint32_t read_u32(const uint8_t *data) {
  return static_cast<uint32_t>(data[0]) |
         (static_cast<uint32_t>(data[1]) << 8) |
         (static_cast<uint32_t>(data[2]) << 16) |
         (static_cast<uint32_t>(data[3]) << 24);
}

static uint16_t read_u16(const uint8_t *data) {
  return static_cast<uint16_t>(data[0]) |
         (static_cast<uint16_t>(data[1]) << 8);
}

#pragma pack(push, 1)
struct McuStatus {
  uint32_t uptime_ms;
  uint32_t last_heartbeat_ms;
  uint32_t last_cmd_rx_ms;
  uint64_t last_cmd_host_ns;
  float left_setpoint_m;
  float right_setpoint_m;
  float left_pos_m;
  float right_pos_m;
  float left_cmd;
  float right_cmd;
  uint8_t state;
  uint8_t flags;
  uint16_t fault_code;
  uint32_t fw_version;
  uint32_t fw_build;
  uint8_t update_state;
  uint8_t update_result;
  uint16_t update_reserved;
};
#pragma pack(pop)

static_assert(sizeof(McuStatus) <= 64, "McuStatus payload exceeds protocol limit");

#pragma pack(push, 1)
struct McuPttEvent {
  uint16_t magic;
  uint8_t event;
  uint8_t source;
  uint32_t uptime_ms;
  uint8_t pressed;
  uint8_t reserved[3];
};
#pragma pack(pop)

static_assert(sizeof(McuPttEvent) == 12, "McuPttEvent size unexpected");
constexpr uint16_t kPttEventMagic = 0x5054u;

#pragma pack(push, 1)
struct CommandPayload {
  float left_m;
  float right_m;
  uint64_t send_timestamp_ns;
};
#pragma pack(pop)

static_assert(sizeof(CommandPayload) == 16, "CommandPayload size unexpected");

#pragma pack(push, 1)
struct MaintenancePayload {
  uint16_t magic;
  uint8_t opcode;
  uint8_t reserved;
  uint32_t token;
};
#pragma pack(pop)

static_assert(sizeof(MaintenancePayload) == 8, "MaintenancePayload size unexpected");

constexpr uint16_t kMaintenanceMagic = 0xB007u;
enum class MaintenanceOp : uint8_t {
  UpdateRequest = 1,
  UpdateArm = 2,
  UpdateAbort = 3
};

static uint64_t now_ns() {
  using clock = std::chrono::steady_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(clock::now().time_since_epoch()).count();
}

int main(int argc, char **argv) {
  auto opt = parse_args(argc, argv);

  if (opt.interval_ms > 100) {
    std::cerr << "Warning: heartbeat interval > 100 ms may violate MCU safety timeout.\n";
  }

#ifdef _WIN32
  SetConsoleCtrlHandler(on_console_ctrl, TRUE);
#else
  std::signal(SIGINT, on_signal);
  std::signal(SIGTERM, on_signal);
#endif

  SerialPort port;
  uint32_t seq = 0;
  std::vector<uint8_t> rx_buffer;
  FrameBatcher batcher(opt.batch_max_bytes);

  if (opt.enter_dfu) {
    if (!port.open(opt.port, opt.baud)) {
      std::cerr << "Connect failed: " << port.last_error() << "\n";
      return 1;
    }
    uint32_t token = static_cast<uint32_t>(now_ns());
    MaintenancePayload payload{ kMaintenanceMagic,
                                static_cast<uint8_t>(MaintenanceOp::UpdateRequest),
                                0,
                                token };
    auto req = build_frame(PacketType::Maintenance, seq++,
                           reinterpret_cast<const uint8_t *>(&payload),
                           sizeof(payload));
    if (!port.write(req.data(), req.size())) {
      std::cerr << "Write failed: " << port.last_error() << "\n";
      return 1;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    payload.opcode = static_cast<uint8_t>(MaintenanceOp::UpdateArm);
    auto arm = build_frame(PacketType::Maintenance, seq++,
                           reinterpret_cast<const uint8_t *>(&payload),
                           sizeof(payload));
    if (!port.write(arm.data(), arm.size())) {
      std::cerr << "Write failed: " << port.last_error() << "\n";
      return 1;
    }
    std::cout << "DFU request sent (token=" << token << ").\n";
    return 0;
  }

  auto next_tick = std::chrono::steady_clock::now();

  while (running) {
    if (!port.is_open()) {
      if (port.open(opt.port, opt.baud)) {
        std::cout << "Connected to " << opt.port << " @ " << opt.baud << " baud\n";
      } else {
        std::cerr << "Connect failed: " << port.last_error() << "\n";
        std::this_thread::sleep_for(std::chrono::milliseconds(opt.reconnect_ms));
        continue;
      }
    }

    next_tick += std::chrono::milliseconds(opt.interval_ms);

    auto heartbeat = build_frame(PacketType::Heartbeat, seq++, nullptr, 0);
    if (opt.batch) {
      batcher.clear();
      if (!batcher.append(heartbeat)) {
        std::cerr << "Batch buffer too small for heartbeat frame. Sending directly.\n";
        if (!port.write(heartbeat.data(), heartbeat.size())) {
          std::cerr << "Write failed: " << port.last_error() << "\n";
          port.close();
          continue;
        }
      }
      if (opt.send_command) {
        CommandPayload payload{opt.cmd_left_m, opt.cmd_right_m, now_ns()};
        auto cmd_frame = build_frame(PacketType::Command, seq++,
                                     reinterpret_cast<const uint8_t *>(&payload),
                                     sizeof(payload));
        if (!batcher.append(cmd_frame)) {
          if (!batcher.empty() && !port.write(batcher.data(), batcher.size())) {
            std::cerr << "Write failed: " << port.last_error() << "\n";
            port.close();
            continue;
          }
          batcher.clear();
          if (!batcher.append(cmd_frame)) {
            if (!port.write(cmd_frame.data(), cmd_frame.size())) {
              std::cerr << "Write failed: " << port.last_error() << "\n";
              port.close();
              continue;
            }
          }
        }
      }
      if (!batcher.empty() && !port.write(batcher.data(), batcher.size())) {
        std::cerr << "Write failed: " << port.last_error() << "\n";
        port.close();
        continue;
      }
    } else {
      if (!port.write(heartbeat.data(), heartbeat.size())) {
        std::cerr << "Write failed: " << port.last_error() << "\n";
        port.close();
        continue;
      }
      if (opt.send_command) {
        CommandPayload payload{opt.cmd_left_m, opt.cmd_right_m, now_ns()};
        auto cmd_frame = build_frame(PacketType::Command, seq++,
                                     reinterpret_cast<const uint8_t *>(&payload),
                                     sizeof(payload));
        if (!port.write(cmd_frame.data(), cmd_frame.size())) {
          std::cerr << "Write failed: " << port.last_error() << "\n";
          port.close();
          continue;
        }
      }
    }

    if (opt.print_status) {
      uint8_t temp[256];
      size_t n = port.read(temp, sizeof(temp));
      if (n > 0) {
        rx_buffer.insert(rx_buffer.end(), temp, temp + n);
      }

      while (rx_buffer.size() >= sizeof(Header) + sizeof(uint16_t)) {
        uint32_t magic = read_u32(rx_buffer.data());
        uint8_t version = rx_buffer[4];
        uint16_t length = read_u16(rx_buffer.data() + 6);
        if (magic != kMagic || version != kVersion || length > kMaxPayload) {
          rx_buffer.erase(rx_buffer.begin());
          continue;
        }
        size_t total = sizeof(Header) + length + sizeof(uint16_t);
        if (rx_buffer.size() < total) {
          break;
        }
        Frame parsed;
        if (!parse_frame(rx_buffer.data(), total, parsed)) {
          rx_buffer.erase(rx_buffer.begin());
          continue;
        }
        if (parsed.header.type == static_cast<uint8_t>(PacketType::Status) &&
            parsed.payload.size() >= sizeof(McuStatus)) {
          McuStatus status{};
          std::memcpy(&status, parsed.payload.data(), sizeof(McuStatus));
          uint8_t fw_major = static_cast<uint8_t>((status.fw_version >> 24) & 0xFFu);
          uint8_t fw_minor = static_cast<uint8_t>((status.fw_version >> 16) & 0xFFu);
          uint8_t fw_patch = static_cast<uint8_t>((status.fw_version >> 8) & 0xFFu);
          uint8_t fw_build = static_cast<uint8_t>(status.fw_version & 0xFFu);
          std::cout << "MCU status: uptime=" << status.uptime_ms
                    << " last_hb=" << status.last_heartbeat_ms
                    << " last_cmd_rx=" << status.last_cmd_rx_ms
                    << " state=" << static_cast<int>(status.state)
                    << " fault=" << status.fault_code
                    << " flags=0x" << std::hex << static_cast<int>(status.flags)
                    << std::dec
                    << " fw=" << static_cast<int>(fw_major) << "."
                    << static_cast<int>(fw_minor) << "."
                    << static_cast<int>(fw_patch) << "+"
                    << static_cast<int>(fw_build)
                    << " build_id=" << status.fw_build
                    << " update_state=" << static_cast<int>(status.update_state)
                    << " update_result=" << static_cast<int>(status.update_result)
                    << "\n";
        } else if (parsed.header.type == static_cast<uint8_t>(PacketType::InputEvent) &&
                   parsed.payload.size() >= sizeof(McuPttEvent)) {
          McuPttEvent event{};
          std::memcpy(&event, parsed.payload.data(), sizeof(McuPttEvent));
          if (event.magic == kPttEventMagic) {
            const char *name = "UNKNOWN";
            if (event.event == 1u) {
              name = "PTT_DOWN";
            } else if (event.event == 2u) {
              name = "PTT_UP";
            }
            std::cout << "MCU input: " << name
                      << " source=" << static_cast<int>(event.source)
                      << " uptime=" << event.uptime_ms
                      << " pressed=" << static_cast<int>(event.pressed)
                      << "\n";
          }
        }
        rx_buffer.erase(rx_buffer.begin(), rx_buffer.begin() + total);
      }
    }

    std::this_thread::sleep_until(next_tick);
  }

  port.close();
  return 0;
}
