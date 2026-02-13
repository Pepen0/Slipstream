#pragma once

#include "game_adapter_registry.h"

#include <cstddef>
#include <string>
#include <vector>

namespace slipstream::physics {

// Symbol exported by adapter plugins.
// Signature: extern "C" void slipstream_register_game_adapters(GameAdapterRegistry *registry);
using RegisterGameAdaptersFn = void (*)(GameAdapterRegistry *registry);

class GameAdapterPluginManager {
public:
  static constexpr const char *kDefaultEnvVar = "SLIPSTREAM_GAME_ADAPTER_PLUGINS";
  static constexpr const char *kRegisterSymbol = "slipstream_register_game_adapters";

  bool load_shared_library(const std::string &path, GameAdapterRegistry &registry,
                           std::string *error_out = nullptr);
  std::size_t load_from_env(GameAdapterRegistry &registry,
                            const char *env_var = kDefaultEnvVar,
                            std::vector<std::string> *errors_out = nullptr);

  std::size_t loaded_count() const;
  std::vector<std::string> loaded_plugin_paths() const;
  void unload_all();

  ~GameAdapterPluginManager();

private:
  struct LoadedPlugin {
    std::string path;
    void *native_handle = nullptr;
    RegisterGameAdaptersFn register_fn = nullptr;
  };

  std::vector<LoadedPlugin> loaded_;
};

} // namespace slipstream::physics
