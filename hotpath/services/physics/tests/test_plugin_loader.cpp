#include "game_adapter_plugin.h"

#include <cassert>
#include <cstdlib>
#include <string>
#include <vector>

using slipstream::physics::GameAdapterPluginManager;
using slipstream::physics::GameAdapterRegistry;

namespace {

bool set_env_var(const char *key, const char *value) {
#ifdef _WIN32
  return _putenv_s(key, value) == 0;
#else
  return setenv(key, value, 1) == 0;
#endif
}

bool unset_env_var(const char *key) {
#ifdef _WIN32
  return _putenv_s(key, "") == 0;
#else
  return unsetenv(key) == 0;
#endif
}

} // namespace

int main() {
  auto defaults = GameAdapterRegistry::create_default();
  auto iracing = defaults.create(slipstream::physics::GameId::IRacing);
  assert(iracing != nullptr);
  assert(iracing->game_id() == slipstream::physics::GameId::IRacing);

  GameAdapterRegistry registry;
  GameAdapterPluginManager plugin_manager;

  std::string error;
  assert(!plugin_manager.load_shared_library("", registry, &error));
  assert(!error.empty());
  assert(plugin_manager.loaded_count() == 0);

  assert(unset_env_var(GameAdapterPluginManager::kDefaultEnvVar));
  assert(plugin_manager.load_from_env(registry) == 0);
  assert(plugin_manager.loaded_count() == 0);

#ifdef _WIN32
  const char *missing_plugin = "Z:\\\\slipstream\\\\missing\\\\adapter_plugin.dll";
#else
  const char *missing_plugin = "/tmp/slipstream_missing_adapter_plugin.so";
#endif
  assert(set_env_var(GameAdapterPluginManager::kDefaultEnvVar, missing_plugin));

  std::vector<std::string> errors;
  assert(plugin_manager.load_from_env(
           registry, GameAdapterPluginManager::kDefaultEnvVar, &errors) == 0);
  assert(!errors.empty());
  assert(plugin_manager.loaded_count() == 0);
  assert(plugin_manager.loaded_plugin_paths().empty());

  assert(unset_env_var(GameAdapterPluginManager::kDefaultEnvVar));
  return 0;
}
