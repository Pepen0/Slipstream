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
  if (active_ && active_->read(out_sample)) {
    return true;
  }
  if (requested_game_ != GameId::Auto) {
    return false;
  }
  return try_failover_read(out_sample);
}

GameId UniversalGameAdapter::selected_game() const {
  return selected_game_;
}

bool UniversalGameAdapter::start_explicit() {
  return try_activate_game(requested_game_, false);
}

bool UniversalGameAdapter::start_auto_detect() {
  const auto games = registry_.ordered_games();
  for (const auto game : games) {
    if (try_activate_game(game, true)) {
      return true;
    }
  }
  return false;
}

bool UniversalGameAdapter::try_activate_game(GameId game, bool require_probe,
                                             TelemetrySample *first_sample) {
  auto adapter = registry_.create(game);
  if (!adapter) {
    return false;
  }
  if (require_probe && !adapter->probe(detect_timeout_)) {
    return false;
  }
  if (!adapter->start()) {
    return false;
  }
  if (first_sample != nullptr && !adapter->read(*first_sample)) {
    return false;
  }

  selected_game_ = adapter->game_id();
  active_ = std::move(adapter);
  return true;
}

bool UniversalGameAdapter::try_failover_read(TelemetrySample &out_sample) {
  const auto games = registry_.ordered_games();
  for (const auto game : games) {
    if (game == selected_game_) {
      continue;
    }
    TelemetrySample candidate_sample{};
    if (!try_activate_game(game, true, &candidate_sample)) {
      continue;
    }
    out_sample = candidate_sample;
    return true;
  }
  return false;
}

} // namespace slipstream::physics
