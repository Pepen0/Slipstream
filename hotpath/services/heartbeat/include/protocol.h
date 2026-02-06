#pragma once

#include <cstdint>
#include <vector>

namespace heartbeat {

constexpr uint32_t kMagic = 0xA5C3F00Du;
constexpr uint8_t kVersion = 2u;
constexpr size_t kMaxPayload = 64u;

enum class PacketType : uint8_t {
  Heartbeat = 0x01,
  Command = 0x02,
  Status = 0x10,
  Maintenance = 0x20
};

#pragma pack(push, 1)
struct Header {
  uint32_t magic;
  uint8_t version;
  uint8_t type;
  uint16_t length;
  uint32_t seq;
};
#pragma pack(pop)

struct Frame {
  Header header{};
  std::vector<uint8_t> payload;
  uint16_t crc = 0;
};

std::vector<uint8_t> build_frame(PacketType type, uint32_t seq,
                                 const uint8_t *payload, size_t len);

bool parse_frame(const uint8_t *data, size_t len, Frame &out);

} // namespace heartbeat
