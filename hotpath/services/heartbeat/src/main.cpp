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
    } else if (arg == "--help") {
      std::cout << "Usage: heartbeat_sender [--port COM3] [--baud 115200] [--interval 50] [--reconnect 1000] [--status]\n";
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

struct McuStatus {
  uint32_t uptime_ms;
  uint32_t last_heartbeat_ms;
  uint8_t state;
  uint8_t flags;
  uint16_t reserved;
};

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

    auto frame = build_frame(PacketType::Heartbeat, seq++, nullptr, 0);
    if (!port.write(frame.data(), frame.size())) {
      std::cerr << "Write failed: " << port.last_error() << "\n";
      port.close();
      continue;
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
          std::cout << "MCU status: uptime=" << status.uptime_ms
                    << " last_hb=" << status.last_heartbeat_ms
                    << " state=" << static_cast<int>(status.state)
                    << " flags=0x" << std::hex << static_cast<int>(status.flags)
                    << std::dec << "\n";
        }
        rx_buffer.erase(rx_buffer.begin(), rx_buffer.begin() + total);
      }
    }

    std::this_thread::sleep_until(next_tick);
  }

  port.close();
  return 0;
}
