#include "cloud_streamer.h"

#include <cassert>
#include <vector>

using slipstream::physics::CloudTelemetryConfig;
using slipstream::physics::CloudTelemetryFrame;
using slipstream::physics::CloudTelemetrySink;
using slipstream::physics::CloudTelemetryStreamer;
using slipstream::physics::DropStrategy;
using slipstream::physics::TelemetrySample;

namespace {

class FakeSink : public CloudTelemetrySink {
public:
  bool send(const CloudTelemetryFrame &frame) override {
    frames.push_back(frame);
    return true;
  }

  std::vector<CloudTelemetryFrame> frames;
};

TelemetrySample make_sample(uint64_t ts_ns, float speed_mps) {
  TelemetrySample sample{};
  sample.timestamp_ns = ts_ns;
  sample.speed_mps = speed_mps;
  return sample;
}

} // namespace

int main() {
  {
    CloudTelemetryConfig config;
    config.target_hz = 60;
    config.queue_capacity = 256;
    config.drop_strategy = DropStrategy::DropNewest;
    CloudTelemetryStreamer streamer(config);
    auto sink = std::make_shared<FakeSink>();
    streamer.set_sink(sink);

    uint64_t ts = 0;
    for (int i = 0; i < 1000; ++i) {
      streamer.ingest(make_sample(ts, 10.0f));
      ts += 1000000ull; // 1 ms
    }
    streamer.drain();
    auto count = sink->frames.size();
    assert(count >= 55 && count <= 65);
  }

  {
    CloudTelemetryConfig config;
    config.target_hz = 1000;
    config.queue_capacity = 3;
    config.drop_strategy = DropStrategy::DropNewest;
    CloudTelemetryStreamer streamer(config);
    auto sink = std::make_shared<FakeSink>();
    streamer.set_sink(sink);

    uint64_t ts = 0;
    for (int i = 0; i < 10; ++i) {
      streamer.ingest(make_sample(ts, static_cast<float>(i)));
      ts += 1000000ull;
    }
    streamer.drain();
    assert(sink->frames.size() == 3);
    assert(sink->frames[0].sample.speed_mps == 0.0f);
    assert(sink->frames[1].sample.speed_mps == 1.0f);
    assert(sink->frames[2].sample.speed_mps == 2.0f);
  }

  {
    CloudTelemetryConfig config;
    config.target_hz = 1000;
    config.queue_capacity = 3;
    config.drop_strategy = DropStrategy::DropOldest;
    CloudTelemetryStreamer streamer(config);
    auto sink = std::make_shared<FakeSink>();
    streamer.set_sink(sink);

    uint64_t ts = 0;
    for (int i = 0; i < 10; ++i) {
      streamer.ingest(make_sample(ts, static_cast<float>(i)));
      ts += 1000000ull;
    }
    streamer.drain();
    assert(sink->frames.size() == 3);
    assert(sink->frames[0].sample.speed_mps == 7.0f);
    assert(sink->frames[1].sample.speed_mps == 8.0f);
    assert(sink->frames[2].sample.speed_mps == 9.0f);
  }

  return 0;
}
