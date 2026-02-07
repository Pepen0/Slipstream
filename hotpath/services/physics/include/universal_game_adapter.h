#pragma once

#include "game_adapter_registry.h"

#include <chrono>
#include <memory>

namespace slipstream::physics {

class UniversalGameAdapter final : public IGameTelemetryProvider {
public:
  explicit UniversalGameAdapter(GameId requested_game = GameId::Auto,
                                GameAdapterRegistry registry = GameAdapterRegistry::create_default(),
                                std::chrono::milliseconds detect_timeout = std::chrono::milliseconds(250));

  bool start() override;
  bool read(TelemetrySample &out_sample) override;

  GameId selected_game() const;

private:
  bool start_explicit();
  bool start_auto_detect();

  GameId requested_game_;
  GameId selected_game_ = GameId::Auto;
  GameAdapterRegistry registry_;
  std::chrono::milliseconds detect_timeout_;
  std::unique_ptr<IGameTelemetryAdapter> active_;
};

} // namespace slipstream::physics
