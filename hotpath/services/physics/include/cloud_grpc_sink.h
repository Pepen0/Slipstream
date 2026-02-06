#pragma once

#include "cloud_streamer.h"

#include <string>

namespace slipstream::physics {

struct GrpcTelemetryConfig {
  std::string target = "127.0.0.1:50051";
  std::string session_id = "session";
  std::string game = "rig";
};

#ifdef SLIPSTREAM_ENABLE_GRPC
class GrpcTelemetrySink : public CloudTelemetrySink {
public:
  explicit GrpcTelemetrySink(GrpcTelemetryConfig config);
  ~GrpcTelemetrySink() override;

  bool send(const CloudTelemetryFrame &frame) override;

private:
  void ensure_stream();
  void reset_stream();

  GrpcTelemetryConfig config_;

  struct Impl;
  Impl *impl_ = nullptr;
};
#endif

} // namespace slipstream::physics
