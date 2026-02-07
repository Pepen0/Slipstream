#include "f1_udp_adapter.h"

#include <cassert>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <vector>

using slipstream::physics::F1UdpAdapter;
using slipstream::physics::TelemetrySample;

namespace {

constexpr float kGravity = 9.80665f;

bool nearly_equal(float a, float b, float eps = 1e-4f) {
  return std::fabs(a - b) <= eps;
}

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

} // namespace

int main() {
  MotionPacketPrefix packet{};
  packet.header.packet_format = 2024;
  packet.header.packet_id = 0;
  packet.header.player_car_index = 7;

  auto &car = packet.cars[7];
  car.world_velocity_x = 10.0f;
  car.world_velocity_y = 2.0f;
  car.world_velocity_z = 30.0f;
  car.g_force_longitudinal = 1.5f;
  car.g_force_lateral = -0.5f;
  car.g_force_vertical = 0.25f;

  std::vector<uint8_t> bytes(sizeof(packet));
  std::memcpy(bytes.data(), &packet, sizeof(packet));

  assert(F1UdpAdapter::looks_like_motion_packet(bytes.data(), bytes.size()));

  TelemetrySample out{};
  assert(F1UdpAdapter::decode_motion_packet(bytes.data(), bytes.size(), out));

  assert(nearly_equal(out.velocity_mps[0], 10.0f));
  assert(nearly_equal(out.velocity_mps[1], 30.0f));
  assert(nearly_equal(out.velocity_mps[2], 2.0f));

  assert(nearly_equal(out.accel_mps2[0], 1.5f * kGravity));
  assert(nearly_equal(out.accel_mps2[1], -0.5f * kGravity));
  assert(nearly_equal(out.accel_mps2[2], 0.25f * kGravity));

  const float expected_speed = std::sqrt((10.0f * 10.0f) + (30.0f * 30.0f) + (2.0f * 2.0f));
  assert(nearly_equal(out.speed_mps, expected_speed));

  packet.header.packet_id = 2;
  std::memcpy(bytes.data(), &packet, sizeof(packet));
  assert(!F1UdpAdapter::looks_like_motion_packet(bytes.data(), bytes.size()));

  return 0;
}
