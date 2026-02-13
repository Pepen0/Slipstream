#include "game_adapter_plugin.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <utility>

#ifdef _WIN32
#define NOMINMAX
#include <windows.h>
#else
#include <dlfcn.h>
#endif

namespace slipstream::physics {
namespace {

static std::string trim_copy(std::string value) {
  auto is_space = [](unsigned char c) { return std::isspace(c) != 0; };
  value.erase(value.begin(), std::find_if(value.begin(), value.end(),
                                          [&](char c) { return !is_space(static_cast<unsigned char>(c)); }));
  value.erase(std::find_if(value.rbegin(), value.rend(),
                           [&](char c) { return !is_space(static_cast<unsigned char>(c)); })
                  .base(),
              value.end());
  return value;
}

static std::vector<std::string> split_plugin_paths(const std::string &input) {
  std::vector<std::string> parts;
  std::string current;
  for (char ch : input) {
#ifdef _WIN32
    const bool is_sep = (ch == ';');
#else
    const bool is_sep = (ch == ':' || ch == ';');
#endif
    if (!is_sep) {
      current.push_back(ch);
      continue;
    }
    auto trimmed = trim_copy(current);
    if (!trimmed.empty()) {
      parts.push_back(std::move(trimmed));
    }
    current.clear();
  }
  auto trimmed = trim_copy(current);
  if (!trimmed.empty()) {
    parts.push_back(std::move(trimmed));
  }
  return parts;
}

} // namespace

bool GameAdapterPluginManager::load_shared_library(const std::string &path,
                                                   GameAdapterRegistry &registry,
                                                   std::string *error_out) {
  if (path.empty()) {
    if (error_out) {
      *error_out = "empty plugin path";
    }
    return false;
  }
  for (const auto &plugin : loaded_) {
    if (plugin.path == path) {
      if (plugin.register_fn != nullptr) {
        plugin.register_fn(&registry);
      }
      return true;
    }
  }

#ifdef _WIN32
  HMODULE handle = LoadLibraryA(path.c_str());
  if (handle == nullptr) {
    if (error_out) {
      *error_out = "LoadLibrary failed for " + path;
    }
    return false;
  }

  auto symbol = GetProcAddress(handle, kRegisterSymbol);
  if (symbol == nullptr) {
    if (error_out) {
      *error_out = "symbol not found: " + std::string(kRegisterSymbol);
    }
    FreeLibrary(handle);
    return false;
  }

  auto register_fn = reinterpret_cast<RegisterGameAdaptersFn>(symbol);
#else
  void *handle = dlopen(path.c_str(), RTLD_NOW | RTLD_LOCAL);
  if (handle == nullptr) {
    if (error_out) {
      const char *dl_error = dlerror();
      *error_out = dl_error ? dl_error : ("dlopen failed for " + path);
    }
    return false;
  }

  dlerror();
  void *symbol = dlsym(handle, kRegisterSymbol);
  const char *symbol_error = dlerror();
  if (symbol_error != nullptr || symbol == nullptr) {
    if (error_out) {
      *error_out = symbol_error ? symbol_error
                                : ("symbol not found: " + std::string(kRegisterSymbol));
    }
    dlclose(handle);
    return false;
  }

  auto register_fn = reinterpret_cast<RegisterGameAdaptersFn>(symbol);
#endif

  if (register_fn == nullptr) {
    if (error_out) {
      *error_out = "invalid plugin registration function";
    }
#ifdef _WIN32
    FreeLibrary(handle);
#else
    dlclose(handle);
#endif
    return false;
  }

  register_fn(&registry);
  loaded_.push_back(LoadedPlugin{path, reinterpret_cast<void *>(handle), register_fn});
  return true;
}

std::size_t GameAdapterPluginManager::load_from_env(
    GameAdapterRegistry &registry, const char *env_var,
    std::vector<std::string> *errors_out) {
  if (!env_var || env_var[0] == '\0') {
    return 0;
  }
  const char *value = std::getenv(env_var);
  if (!value || value[0] == '\0') {
    return 0;
  }

  const auto paths = split_plugin_paths(value);
  std::size_t loaded = 0;
  for (const auto &path : paths) {
    std::string error;
    if (load_shared_library(path, registry, &error)) {
      loaded += 1;
      continue;
    }
    if (errors_out != nullptr) {
      errors_out->push_back(path + ": " + error);
    }
  }
  return loaded;
}

std::size_t GameAdapterPluginManager::loaded_count() const {
  return loaded_.size();
}

std::vector<std::string> GameAdapterPluginManager::loaded_plugin_paths() const {
  std::vector<std::string> paths;
  paths.reserve(loaded_.size());
  for (const auto &plugin : loaded_) {
    paths.push_back(plugin.path);
  }
  return paths;
}

void GameAdapterPluginManager::unload_all() {
  for (auto it = loaded_.rbegin(); it != loaded_.rend(); ++it) {
    if (it->native_handle == nullptr) {
      continue;
    }
#ifdef _WIN32
    FreeLibrary(reinterpret_cast<HMODULE>(it->native_handle));
#else
    dlclose(it->native_handle);
#endif
  }
  loaded_.clear();
}

GameAdapterPluginManager::~GameAdapterPluginManager() {
  unload_all();
}

} // namespace slipstream::physics
