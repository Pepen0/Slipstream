#include "game_adapter.h"

namespace slipstream::physics {

const char *game_id_name(GameId id) {
  switch (id) {
  case GameId::Auto:
    return "auto";
  case GameId::AssettoCorsa:
    return "assetto_corsa";
  case GameId::F1_23_24:
    return "f1_23_24";
  case GameId::IRacing:
    return "iracing";
  default:
    return "unknown";
  }
}

} // namespace slipstream::physics
