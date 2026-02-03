#include "protocol.h"
#include "crc16.h"

namespace heartbeat {

static void append_u32(std::vector<uint8_t> &out, uint32_t v) {
  out.push_back(static_cast<uint8_t>(v & 0xFF));
  out.push_back(static_cast<uint8_t>((v >> 8) & 0xFF));
  out.push_back(static_cast<uint8_t>((v >> 16) & 0xFF));
  out.push_back(static_cast<uint8_t>((v >> 24) & 0xFF));
}

static void append_u16(std::vector<uint8_t> &out, uint16_t v) {
  out.push_back(static_cast<uint8_t>(v & 0xFF));
  out.push_back(static_cast<uint8_t>((v >> 8) & 0xFF));
}

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

std::vector<uint8_t> build_frame(PacketType type, uint32_t seq,
                                 const uint8_t *payload, size_t len) {
  if (len > kMaxPayload) {
    len = kMaxPayload;
  }

  std::vector<uint8_t> out;
  out.reserve(sizeof(Header) + len + sizeof(uint16_t));

  append_u32(out, kMagic);
  out.push_back(kVersion);
  out.push_back(static_cast<uint8_t>(type));
  append_u16(out, static_cast<uint16_t>(len));
  append_u32(out, seq);

  if (len > 0 && payload) {
    out.insert(out.end(), payload, payload + len);
  }

  uint16_t crc = crc16_ccitt(out.data(), out.size());
  append_u16(out, crc);
  return out;
}

bool parse_frame(const uint8_t *data, size_t len, Frame &out) {
  if (len < sizeof(Header) + sizeof(uint16_t)) {
    return false;
  }

  Header hdr{};
  hdr.magic = read_u32(data);
  hdr.version = data[4];
  hdr.type = data[5];
  hdr.length = read_u16(data + 6);
  hdr.seq = read_u32(data + 8);

  if (hdr.magic != kMagic || hdr.version != kVersion) {
    return false;
  }
  if (hdr.length > kMaxPayload) {
    return false;
  }

  size_t total = sizeof(Header) + hdr.length + sizeof(uint16_t);
  if (len < total) {
    return false;
  }

  const uint8_t *payload = data + sizeof(Header);
  uint16_t crc_field = read_u16(data + sizeof(Header) + hdr.length);

  uint16_t calc = crc16_ccitt(data, sizeof(Header) + hdr.length);
  if (crc_field != calc) {
    return false;
  }

  out.header = hdr;
  out.payload.assign(payload, payload + hdr.length);
  out.crc = crc_field;
  return true;
}

} // namespace heartbeat
