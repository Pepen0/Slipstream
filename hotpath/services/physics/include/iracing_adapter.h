#pragma once

#include "game_adapter.h"

namespace slipstream::physics {

// Optional iRacing adapter scaffold.
// The default implementation is a stub until a telemetry transport is wired.
class IRacingAdapter final : public IGameTelemetryAdapter {
public:
  IRacingAdapter();
  ~IRacingAdapter() override;

  GameId game_id() const override;
  bool probe(std::chrono::milliseconds timeout) override;
  bool start() override;
  bool read(TelemetrySample &out_sample) override;
};

} // namespace slipstream::physics
