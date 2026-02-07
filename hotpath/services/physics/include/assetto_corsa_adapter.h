#pragma once

#include "game_adapter.h"

namespace slipstream::physics {

class AssettoCorsaAdapter final : public IGameTelemetryAdapter {
public:
  AssettoCorsaAdapter();
  ~AssettoCorsaAdapter() override;

  GameId game_id() const override;
  bool probe(std::chrono::milliseconds timeout) override;
  bool start() override;
  bool read(TelemetrySample &out_sample) override;

private:
  struct Impl;
  Impl *impl_;
};

} // namespace slipstream::physics
