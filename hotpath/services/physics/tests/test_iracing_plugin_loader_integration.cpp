#include "game_adapter_plugin.h"
#include "game_adapter_registry.h"

#include <cassert>
#include <memory>
#include <string>

using slipstream::physics::GameAdapterPluginManager;
using slipstream::physics::GameAdapterRegistry;
using slipstream::physics::GameId;
using slipstream::physics::IGameTelemetryAdapter;
using slipstream::physics::TelemetrySample;

namespace {

class DummyAdapter final : public IGameTelemetryAdapter {
public:
  GameId game_id() const override {
    return GameId::AssettoCorsa;
  }

  bool probe(std::chrono::milliseconds) override {
    return false;
  }

  bool start() override {
    return false;
  }

  bool read(TelemetrySample &) override {
    return false;
  }
};

} // namespace

int main() {
#ifndef SLIPSTREAM_IRACING_PLUGIN_PATH
  return 1;
#else
  GameAdapterPluginManager plugin_manager;
  GameAdapterRegistry registry;
  registry.register_adapter(GameId::IRacing, []() { return std::make_unique<DummyAdapter>(); });

  auto before = registry.create(GameId::IRacing);
  assert(before != nullptr);
  assert(before->game_id() == GameId::AssettoCorsa);

  std::string error;
  assert(plugin_manager.load_shared_library(SLIPSTREAM_IRACING_PLUGIN_PATH, registry, &error));
  assert(plugin_manager.loaded_count() == 1);

  auto after = registry.create(GameId::IRacing);
  assert(after != nullptr);
  assert(after->game_id() == GameId::IRacing);
  return 0;
#endif
}
