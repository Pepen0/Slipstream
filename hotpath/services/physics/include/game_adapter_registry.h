#pragma once

#include "game_adapter.h"

#include <functional>
#include <memory>
#include <vector>

namespace slipstream::physics {

class GameAdapterRegistry {
public:
  using Factory = std::function<std::unique_ptr<IGameTelemetryAdapter>()>;

  void register_adapter(GameId id, Factory factory);
  std::unique_ptr<IGameTelemetryAdapter> create(GameId id) const;
  std::vector<GameId> ordered_games() const;

  static GameAdapterRegistry create_default();

private:
  struct Entry {
    GameId id = GameId::Auto;
    Factory factory;
  };

  std::vector<Entry> entries_;
};

} // namespace slipstream::physics
