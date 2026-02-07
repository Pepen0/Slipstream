#include "universal_game_adapter.h"

#include <cassert>
#include <chrono>
#include <memory>

using slipstream::physics::GameAdapterRegistry;
using slipstream::physics::GameId;
using slipstream::physics::IGameTelemetryAdapter;
using slipstream::physics::TelemetrySample;
using slipstream::physics::UniversalGameAdapter;

namespace {

class FakeAdapter final : public IGameTelemetryAdapter {
public:
  FakeAdapter(GameId id, bool probe_ok, bool start_ok, float speed_mps)
      : id_(id), probe_ok_(probe_ok), start_ok_(start_ok), speed_mps_(speed_mps) {}

  GameId game_id() const override {
    return id_;
  }

  bool probe(std::chrono::milliseconds) override {
    return probe_ok_;
  }

  bool start() override {
    started_ = start_ok_;
    return started_;
  }

  bool read(TelemetrySample &out_sample) override {
    if (!started_) {
      return false;
    }
    out_sample.speed_mps = speed_mps_;
    return true;
  }

private:
  GameId id_;
  bool probe_ok_;
  bool start_ok_;
  bool started_ = false;
  float speed_mps_;
};

} // namespace

int main() {
  {
    GameAdapterRegistry registry;
    registry.register_adapter(
      GameId::AssettoCorsa,
      []() { return std::make_unique<FakeAdapter>(GameId::AssettoCorsa, false, true, 15.0f); });
    registry.register_adapter(
      GameId::F1_23_24,
      []() { return std::make_unique<FakeAdapter>(GameId::F1_23_24, true, true, 42.0f); });

    UniversalGameAdapter adapter(GameId::Auto, std::move(registry), std::chrono::milliseconds(5));
    assert(adapter.start());
    assert(adapter.selected_game() == GameId::F1_23_24);

    TelemetrySample sample{};
    assert(adapter.read(sample));
    assert(sample.speed_mps == 42.0f);
  }

  {
    GameAdapterRegistry registry;
    registry.register_adapter(
      GameId::AssettoCorsa,
      []() { return std::make_unique<FakeAdapter>(GameId::AssettoCorsa, false, true, 7.0f); });
    registry.register_adapter(
      GameId::F1_23_24,
      []() { return std::make_unique<FakeAdapter>(GameId::F1_23_24, true, true, 9.0f); });

    UniversalGameAdapter adapter(GameId::AssettoCorsa, std::move(registry), std::chrono::milliseconds(5));
    assert(adapter.start());
    assert(adapter.selected_game() == GameId::AssettoCorsa);

    TelemetrySample sample{};
    assert(adapter.read(sample));
    assert(sample.speed_mps == 7.0f);
  }

  return 0;
}
