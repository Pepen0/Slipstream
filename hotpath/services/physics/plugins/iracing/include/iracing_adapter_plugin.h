#pragma once

#include "game_adapter.h"
#include "game_adapter_registry.h"

#include <cstddef>
#include <cstdint>
#include <memory>

namespace slipstream::physics {

class IIRacingSharedMemoryTransport {
public:
  virtual ~IIRacingSharedMemoryTransport() = default;

  virtual bool open() = 0;
  virtual const uint8_t *data() const = 0;
  virtual std::size_t size() const = 0;
};

class IRacingSharedMemoryAdapter final : public IGameTelemetryAdapter {
public:
  IRacingSharedMemoryAdapter();
  explicit IRacingSharedMemoryAdapter(std::unique_ptr<IIRacingSharedMemoryTransport> transport);
  ~IRacingSharedMemoryAdapter() override;

  GameId game_id() const override;
  bool probe(std::chrono::milliseconds timeout) override;
  bool start() override;
  bool read(TelemetrySample &out_sample) override;

private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};

std::unique_ptr<IGameTelemetryAdapter>
make_iracing_shared_memory_adapter_for_testing(std::unique_ptr<IIRacingSharedMemoryTransport> transport);

} // namespace slipstream::physics

#ifdef _WIN32
#define SLIPSTREAM_GAME_ADAPTER_PLUGIN_EXPORT extern "C" __declspec(dllexport)
#else
#define SLIPSTREAM_GAME_ADAPTER_PLUGIN_EXPORT extern "C"
#endif

SLIPSTREAM_GAME_ADAPTER_PLUGIN_EXPORT void
slipstream_register_game_adapters(slipstream::physics::GameAdapterRegistry *registry);

