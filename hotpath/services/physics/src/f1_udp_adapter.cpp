#include "f1_udp_adapter.h"

#include "coordinate_normalizer.h"

#include <array>
#include <chrono>
#include <cmath>
#include <cstring>

#ifdef _WIN32
#define NOMINMAX
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <unistd.h>
#endif

namespace slipstream::physics {
namespace {

static uint64_t now_ns() {
  using clock = std::chrono::steady_clock;
  return std::chrono::duration_cast<std::chrono::nanoseconds>(clock::now().time_since_epoch()).count();
}

constexpr float kGravity = 9.80665f;
constexpr std::size_t kMaxPacketSize = 2048;

#pragma pack(push, 1)
struct PacketHeader {
  uint16_t packet_format;
  uint8_t game_year;
  uint8_t game_major_version;
  uint8_t game_minor_version;
  uint8_t packet_version;
  uint8_t packet_id;
  uint64_t session_uid;
  float session_time;
  uint32_t frame_identifier;
  uint32_t overall_frame_identifier;
  uint8_t player_car_index;
  uint8_t secondary_player_car_index;
};

struct CarMotionData {
  float world_position_x;
  float world_position_y;
  float world_position_z;
  float world_velocity_x;
  float world_velocity_y;
  float world_velocity_z;
  int16_t world_forward_dir_x;
  int16_t world_forward_dir_y;
  int16_t world_forward_dir_z;
  int16_t world_right_dir_x;
  int16_t world_right_dir_y;
  int16_t world_right_dir_z;
  float g_force_lateral;
  float g_force_longitudinal;
  float g_force_vertical;
  float yaw;
  float pitch;
  float roll;
};

struct MotionPacketPrefix {
  PacketHeader header;
  CarMotionData cars[22];
};
#pragma pack(pop)

#ifdef _WIN32
using SocketType = SOCKET;
constexpr SocketType kInvalidSocket = INVALID_SOCKET;
void close_socket(SocketType s) {
  closesocket(s);
}

bool ensure_winsock() {
  static bool initialized = false;
  static bool ok = false;
  if (initialized) {
    return ok;
  }
  initialized = true;
  WSADATA wsa_data{};
  ok = WSAStartup(MAKEWORD(2, 2), &wsa_data) == 0;
  return ok;
}
#else
using SocketType = int;
constexpr SocketType kInvalidSocket = -1;
void close_socket(SocketType s) {
  close(s);
}
#endif

} // namespace

struct F1UdpAdapter::Impl {
  SocketType socket = kInvalidSocket;
  bool has_cached = false;
  TelemetrySample cached{};
};

F1UdpAdapter::F1UdpAdapter(F1UdpAdapterConfig config) : impl_(new Impl()), config_(config) {}

F1UdpAdapter::~F1UdpAdapter() {
  if (impl_->socket != kInvalidSocket) {
    close_socket(impl_->socket);
    impl_->socket = kInvalidSocket;
  }
  delete impl_;
}

GameId F1UdpAdapter::game_id() const {
  return GameId::F1_23_24;
}

bool F1UdpAdapter::start() {
  return ensure_socket_open();
}

bool F1UdpAdapter::probe(std::chrono::milliseconds timeout) {
  if (impl_->has_cached) {
    return true;
  }
  if (!ensure_socket_open()) {
    return false;
  }

  auto effective_timeout = timeout;
  if (effective_timeout.count() <= 0) {
    effective_timeout = std::chrono::milliseconds(config_.detect_timeout_ms);
  }

  auto deadline = std::chrono::steady_clock::now() + effective_timeout;
  while (std::chrono::steady_clock::now() < deadline) {
    TelemetrySample sample{};
    auto remaining = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - std::chrono::steady_clock::now());
    auto slice = remaining > std::chrono::milliseconds(20) ? std::chrono::milliseconds(20) : remaining;
    if (slice.count() < 0) {
      slice = std::chrono::milliseconds(0);
    }
    if (read_with_timeout(slice, &sample)) {
      impl_->cached = sample;
      impl_->has_cached = true;
      return true;
    }
  }
  return false;
}

bool F1UdpAdapter::read(TelemetrySample &out_sample) {
  if (impl_->has_cached) {
    out_sample = impl_->cached;
    impl_->has_cached = false;
    return true;
  }
  if (!ensure_socket_open()) {
    return false;
  }
  return read_with_timeout(std::chrono::milliseconds(config_.poll_timeout_ms), &out_sample);
}

bool F1UdpAdapter::ensure_socket_open() {
  if (impl_->socket != kInvalidSocket) {
    return true;
  }

#ifdef _WIN32
  if (!ensure_winsock()) {
    return false;
  }
#endif

  auto sock = ::socket(AF_INET, SOCK_DGRAM, 0);
  if (sock == kInvalidSocket) {
    return false;
  }

  sockaddr_in addr{};
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_ANY);
  addr.sin_port = htons(config_.port);

  if (::bind(sock, reinterpret_cast<const sockaddr *>(&addr), sizeof(addr)) < 0) {
    close_socket(sock);
    return false;
  }

  impl_->socket = sock;
  return true;
}

bool F1UdpAdapter::read_with_timeout(std::chrono::milliseconds timeout, TelemetrySample *out_sample) {
  if (impl_->socket == kInvalidSocket) {
    return false;
  }

  fd_set readfds;
  FD_ZERO(&readfds);
  FD_SET(impl_->socket, &readfds);

  timeval tv{};
  auto timeout_ms = timeout.count();
  if (timeout_ms < 0) {
    timeout_ms = 0;
  }
  tv.tv_sec = static_cast<long>(timeout_ms / 1000);
  tv.tv_usec = static_cast<long>((timeout_ms % 1000) * 1000);

#ifdef _WIN32
  int ready = ::select(0, &readfds, nullptr, nullptr, &tv);
#else
  int ready = ::select(impl_->socket + 1, &readfds, nullptr, nullptr, &tv);
#endif
  if (ready <= 0) {
    return false;
  }

  std::array<uint8_t, kMaxPacketSize> buffer{};
  sockaddr_in src{};
#ifdef _WIN32
  int src_len = sizeof(src);
  int recv_len = ::recvfrom(impl_->socket,
                            reinterpret_cast<char *>(buffer.data()),
                            static_cast<int>(buffer.size()),
                            0,
                            reinterpret_cast<sockaddr *>(&src),
                            &src_len);
#else
  socklen_t src_len = sizeof(src);
  int recv_len =
    ::recvfrom(impl_->socket, buffer.data(), buffer.size(), 0, reinterpret_cast<sockaddr *>(&src), &src_len);
#endif
  if (recv_len <= 0) {
    return false;
  }

  TelemetrySample sample{};
  if (!decode_motion_packet(buffer.data(), static_cast<std::size_t>(recv_len), sample)) {
    return false;
  }

  sample.timestamp_ns = now_ns();
  if (out_sample) {
    *out_sample = sample;
  }
  return true;
}

bool F1UdpAdapter::looks_like_motion_packet(const uint8_t *data, std::size_t size) {
  if (!data || size < sizeof(MotionPacketPrefix)) {
    return false;
  }

  PacketHeader header{};
  std::memcpy(&header, data, sizeof(header));
  if (header.packet_id != 0) {
    return false;
  }
  if (header.packet_format != 2023 && header.packet_format != 2024) {
    return false;
  }
  if (header.player_car_index >= 22) {
    return false;
  }
  return true;
}

bool F1UdpAdapter::decode_motion_packet(const uint8_t *data, std::size_t size, TelemetrySample &out_sample) {
  if (!looks_like_motion_packet(data, size)) {
    return false;
  }

  MotionPacketPrefix packet{};
  std::memcpy(&packet, data, sizeof(packet));
  const auto player_index = packet.header.player_car_index;
  const auto &car = packet.cars[player_index];

  float raw_velocity_y_up[3] = {car.world_velocity_x, car.world_velocity_y, car.world_velocity_z};
  normalize_vector_to_z_up(raw_velocity_y_up, UpAxis::YUp, out_sample.velocity_mps);

  out_sample.accel_mps2[0] = car.g_force_longitudinal * kGravity;
  out_sample.accel_mps2[1] = car.g_force_lateral * kGravity;
  out_sample.accel_mps2[2] = car.g_force_vertical * kGravity;

  out_sample.angular_vel_rad[0] = 0.0f;
  out_sample.angular_vel_rad[1] = 0.0f;
  out_sample.angular_vel_rad[2] = 0.0f;

  const float vx = out_sample.velocity_mps[0];
  const float vy = out_sample.velocity_mps[1];
  const float vz = out_sample.velocity_mps[2];
  out_sample.speed_mps = std::sqrt((vx * vx) + (vy * vy) + (vz * vz));

  return true;
}

} // namespace slipstream::physics
