#pragma once

#include "igame_telemetry_provider.h"

#include <chrono>

namespace slipstream::physics {

enum class GameId {
  Auto = 0,
  AssettoCorsa = 1,
  F1_23_24 = 2
};

const char *game_id_name(GameId id);

class IGameTelemetryAdapter : public IGameTelemetryProvider {
public:
  ~IGameTelemetryAdapter() override = default;

  virtual GameId game_id() const = 0;
  virtual bool probe(std::chrono::milliseconds timeout) = 0;
};

} // namespace slipstream::physics
