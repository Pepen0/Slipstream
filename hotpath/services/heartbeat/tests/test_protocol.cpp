#include "protocol.h"

#include <cassert>
#include <cstdint>
#include <iostream>
#include <vector>

using namespace heartbeat;

static void test_roundtrip_empty() {
  auto bytes = build_frame(PacketType::Heartbeat, 42, nullptr, 0);
  Frame frame;
  bool ok = parse_frame(bytes.data(), bytes.size(), frame);
  assert(ok);
  assert(frame.header.magic == kMagic);
  assert(frame.header.version == kVersion);
  assert(frame.header.type == static_cast<uint8_t>(PacketType::Heartbeat));
  assert(frame.header.length == 0);
  assert(frame.header.seq == 42);
  assert(frame.payload.empty());
}

static void test_roundtrip_payload() {
  const uint8_t payload[] = {0x10, 0x20, 0x30, 0x40};
  auto bytes = build_frame(PacketType::Command, 7, payload, sizeof(payload));
  Frame frame;
  bool ok = parse_frame(bytes.data(), bytes.size(), frame);
  assert(ok);
  assert(frame.header.type == static_cast<uint8_t>(PacketType::Command));
  assert(frame.payload.size() == sizeof(payload));
  for (size_t i = 0; i < sizeof(payload); ++i) {
    assert(frame.payload[i] == payload[i]);
  }
}

static void test_crc_fail() {
  auto bytes = build_frame(PacketType::Heartbeat, 1, nullptr, 0);
  bytes[2] ^= 0xFF; // flip type byte
  Frame frame;
  bool ok = parse_frame(bytes.data(), bytes.size(), frame);
  assert(!ok);
}

static void test_bad_magic() {
  auto bytes = build_frame(PacketType::Heartbeat, 1, nullptr, 0);
  bytes[0] = 0x00;
  Frame frame;
  bool ok = parse_frame(bytes.data(), bytes.size(), frame);
  assert(!ok);
}

int main() {
  test_roundtrip_empty();
  test_roundtrip_payload();
  test_crc_fail();
  test_bad_magic();
  std::cout << "All protocol tests passed.\n";
  return 0;
}
