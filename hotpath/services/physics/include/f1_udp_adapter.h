#pragma once

#include "game_adapter.h"

#include <cstddef>
#include <cstdint>

namespace slipstream::physics {

struct F1UdpAdapterConfig {
  uint16_t port = 20777;
  uint32_t poll_timeout_ms = 5;
  uint32_t detect_timeout_ms = 250;
};

class F1UdpAdapter final : public IGameTelemetryAdapter {
public:
  explicit F1UdpAdapter(F1UdpAdapterConfig config = {});
  ~F1UdpAdapter() override;

  GameId game_id() const override;
  bool probe(std::chrono::milliseconds timeout) override;
  bool start() override;
  bool read(TelemetrySample &out_sample) override;

  static bool looks_like_motion_packet(const uint8_t *data, std::size_t size);
  static bool decode_motion_packet(const uint8_t *data, std::size_t size, TelemetrySample &out_sample);

private:
  bool ensure_socket_open();
  bool read_with_timeout(std::chrono::milliseconds timeout, TelemetrySample *out_sample);

  struct Impl;
  Impl *impl_;
  F1UdpAdapterConfig config_;
};

} // namespace slipstream::physics
