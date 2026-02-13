#include "game_adapter_plugin.h"
#include "game_adapter_registry.h"

#include <chrono>
#include <cctype>
#include <cstdlib>
#include <iostream>
#include <string>
#include <thread>

#ifdef _WIN32
#define NOMINMAX
#define WIN32_LEAN_AND_MEAN
#include <tlhelp32.h>
#include <windows.h>
#endif

using slipstream::physics::GameAdapterPluginManager;
using slipstream::physics::GameAdapterRegistry;
using slipstream::physics::GameId;

namespace {

int parse_env_int_ms(const char *name, int fallback_ms) {
  const char *value = std::getenv(name);
  if (value == nullptr || value[0] == '\0') {
    return fallback_ms;
  }
  const int parsed = std::atoi(value);
  if (parsed <= 0) {
    return fallback_ms;
  }
  return parsed;
}

std::string parse_env_string(const char *name, const char *fallback) {
  const char *value = std::getenv(name);
  if (value == nullptr || value[0] == '\0') {
    return std::string(fallback);
  }
  return std::string(value);
}

std::string to_lower_copy(std::string value) {
  for (char &ch : value) {
    ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
  }
  return value;
}

#ifdef _WIN32
std::string wide_to_ascii_lower(const wchar_t *text) {
  std::string out;
  if (text == nullptr) {
    return out;
  }
  for (const wchar_t *p = text; *p != L'\0'; ++p) {
    char ch = (*p <= 0x7F) ? static_cast<char>(*p) : '?';
    out.push_back(static_cast<char>(std::tolower(static_cast<unsigned char>(ch))));
  }
  return out;
}

bool is_process_running(const std::string &process_name_lower) {
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) {
    return false;
  }

  PROCESSENTRY32W entry{};
  entry.dwSize = sizeof(entry);
  if (!Process32FirstW(snapshot, &entry)) {
    CloseHandle(snapshot);
    return false;
  }

  bool found = false;
  do {
    if (wide_to_ascii_lower(entry.szExeFile) == process_name_lower) {
      found = true;
      break;
    }
  } while (Process32NextW(snapshot, &entry));

  CloseHandle(snapshot);
  return found;
}
#endif

} // namespace

int main() {
#ifndef _WIN32
  std::cout << "Windows-only smoke test." << std::endl;
  return 125;
#else
#ifndef SLIPSTREAM_IRACING_PLUGIN_PATH
  std::cerr << "SLIPSTREAM_IRACING_PLUGIN_PATH is not defined." << std::endl;
  return 2;
#endif

  const std::string process_name = parse_env_string(
    "SLIPSTREAM_IRACING_SMOKE_PROCESS", "iRacingSim64DX11.exe");
  const int probe_timeout_ms = parse_env_int_ms(
    "SLIPSTREAM_IRACING_SMOKE_PROBE_TIMEOUT_MS", 6000);
  const int poll_slice_ms = parse_env_int_ms(
    "SLIPSTREAM_IRACING_SMOKE_POLL_SLICE_MS", 250);

  const auto process_name_lower = to_lower_copy(process_name);
  if (!is_process_running(process_name_lower)) {
    std::cerr << "iRacing process not running: " << process_name << std::endl;
    return 3;
  }

  GameAdapterPluginManager plugin_manager;
  GameAdapterRegistry registry;

  std::string load_error;
  if (!plugin_manager.load_shared_library(SLIPSTREAM_IRACING_PLUGIN_PATH, registry, &load_error)) {
    std::cerr << "Failed to load plugin: " << load_error << std::endl;
    return 4;
  }

  auto adapter = registry.create(GameId::IRacing);
  if (!adapter) {
    std::cerr << "Plugin did not register IRacing adapter." << std::endl;
    return 5;
  }

  const auto started = std::chrono::steady_clock::now();
  const auto deadline = started + std::chrono::milliseconds(probe_timeout_ms);
  while (std::chrono::steady_clock::now() < deadline) {
    if (adapter->probe(std::chrono::milliseconds(poll_slice_ms))) {
      std::cout << "iRacing live probe succeeded." << std::endl;
      return 0;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(poll_slice_ms));
  }

  std::cerr << "iRacing process detected but probe() did not succeed within "
            << probe_timeout_ms << " ms." << std::endl;
  return 6;
#endif
}

