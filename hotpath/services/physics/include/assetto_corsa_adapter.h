#pragma once

#include "igame_telemetry_provider.h"

namespace slipstream::physics {

class AssettoCorsaAdapter final : public IGameTelemetryProvider {
public:
  AssettoCorsaAdapter();
  ~AssettoCorsaAdapter() override;

  bool start() override;
  bool read(TelemetrySample &out_sample) override;

private:
  struct Impl;
  Impl *impl_;
};

} // namespace slipstream::physics
