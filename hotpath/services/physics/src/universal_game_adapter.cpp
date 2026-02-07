#include "universal_game_adapter.h"

#include <utility>

namespace slipstream::physics {

UniversalGameAdapter::UniversalGameAdapter(GameId requested_game,
                                           GameAdapterRegistry registry,
                                           std::chrono::milliseconds detect_timeout)
    : requested_game_(requested_game), registry_(std::move(registry)), detect_timeout_(detect_timeout) {}

bool UniversalGameAdapter::start() {
  if (active_) {
    return true;
  }
  if (requested_game_ == GameId::Auto) {
    return start_auto_detect();
  }
  return start_explicit();
}

bool UniversalGameAdapter::read(TelemetrySample &out_sample) {
  if (!active_ && !start()) {
    return false;
  }
  return active_ ? active_->read(out_sample) : false;
}

GameId UniversalGameAdapter::selected_game() const {
  return selected_game_;
}

bool UniversalGameAdapter::start_explicit() {
  auto adapter = registry_.create(requested_game_);
  if (!adapter || !adapter->start()) {
    return false;
  }

  selected_game_ = adapter->game_id();
  active_ = std::move(adapter);
  return true;
}

bool UniversalGameAdapter::start_auto_detect() {
  const auto games = registry_.ordered_games();
  for (const auto game : games) {
    auto adapter = registry_.create(game);
    if (!adapter) {
      continue;
    }
    if (!adapter->probe(detect_timeout_)) {
      continue;
    }
    if (!adapter->start()) {
      continue;
    }
    selected_game_ = adapter->game_id();
    active_ = std::move(adapter);
    return true;
  }
  return false;
}

} // namespace slipstream::physics
