#include "iracing_adapter.h"

namespace slipstream::physics {

IRacingAdapter::IRacingAdapter() = default;
IRacingAdapter::~IRacingAdapter() = default;

GameId IRacingAdapter::game_id() const {
  return GameId::IRacing;
}

bool IRacingAdapter::probe(std::chrono::milliseconds) {
  return false;
}

bool IRacingAdapter::start() {
  return false;
}

bool IRacingAdapter::read(TelemetrySample &) {
  return false;
}

} // namespace slipstream::physics
