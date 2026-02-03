#pragma once

#include "telemetry_sample.h"

namespace slipstream::physics {

class IGameTelemetryProvider {
public:
  virtual ~IGameTelemetryProvider() = default;
  virtual bool start() = 0;
  virtual bool read(TelemetrySample &out_sample) = 0;
};

} // namespace slipstream::physics
