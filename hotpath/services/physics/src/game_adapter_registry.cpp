#include "game_adapter_registry.h"

#include "assetto_corsa_adapter.h"
#include "f1_udp_adapter.h"

#include <utility>

namespace slipstream::physics {

void GameAdapterRegistry::register_adapter(GameId id, Factory factory) {
  if (!factory || id == GameId::Auto) {
    return;
  }

  for (auto &entry : entries_) {
    if (entry.id == id) {
      entry.factory = std::move(factory);
      return;
    }
  }

  entries_.push_back(Entry{id, std::move(factory)});
}

std::unique_ptr<IGameTelemetryAdapter> GameAdapterRegistry::create(GameId id) const {
  for (const auto &entry : entries_) {
    if (entry.id == id && entry.factory) {
      return entry.factory();
    }
  }
  return nullptr;
}

std::vector<GameId> GameAdapterRegistry::ordered_games() const {
  std::vector<GameId> ids;
  ids.reserve(entries_.size());
  for (const auto &entry : entries_) {
    ids.push_back(entry.id);
  }
  return ids;
}

GameAdapterRegistry GameAdapterRegistry::create_default() {
  GameAdapterRegistry registry;
  registry.register_adapter(GameId::AssettoCorsa, []() { return std::make_unique<AssettoCorsaAdapter>(); });
  registry.register_adapter(GameId::F1_23_24, []() { return std::make_unique<F1UdpAdapter>(); });
  return registry;
}

} // namespace slipstream::physics
