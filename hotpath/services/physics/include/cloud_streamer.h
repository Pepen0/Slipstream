#pragma once

#include "telemetry_sample.h"

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <thread>
#include <vector>

namespace slipstream::physics {

struct CloudTelemetryFrame {
  uint64_t monotonic_ns = 0;
  TelemetrySample sample{};
};

enum class DropStrategy {
  DropNewest = 0,
  DropOldest = 1
};

struct CloudTelemetryConfig {
  int target_hz = 60;
  std::size_t queue_capacity = 256;
  DropStrategy drop_strategy = DropStrategy::DropNewest;
};

struct CloudTelemetryStats {
  uint64_t ingested = 0;
  uint64_t downsampled = 0;
  uint64_t dropped = 0;
  uint64_t sent = 0;
};

class CloudTelemetrySink {
public:
  virtual ~CloudTelemetrySink() = default;
  virtual bool send(const CloudTelemetryFrame &frame) = 0;
};

class CloudTelemetryStreamer {
public:
  explicit CloudTelemetryStreamer(const CloudTelemetryConfig &config);
  ~CloudTelemetryStreamer();

  CloudTelemetryStreamer(const CloudTelemetryStreamer &) = delete;
  CloudTelemetryStreamer &operator=(const CloudTelemetryStreamer &) = delete;

  void set_sink(std::shared_ptr<CloudTelemetrySink> sink);
  void start();
  void stop();

  // Non-blocking ingest from hot path.
  void ingest(const TelemetrySample &sample);

  // Drain any queued frames using the configured sink. Returns frames sent.
  std::size_t drain();

  CloudTelemetryStats stats() const;

private:
  struct RingBuffer {
    explicit RingBuffer(std::size_t capacity);
    bool try_push(const CloudTelemetryFrame &frame, DropStrategy strategy, uint64_t &dropped);
    bool try_pop(CloudTelemetryFrame &out);
    std::size_t size() const;

    std::vector<CloudTelemetryFrame> buffer;
    std::atomic<std::size_t> head{0};
    std::atomic<std::size_t> tail{0};
    std::size_t capacity = 0;
  };

  void worker_loop();
  uint64_t period_ns() const;

  CloudTelemetryConfig config_;
  RingBuffer ring_;
  std::atomic<uint64_t> last_emit_ns_{0};

  std::shared_ptr<CloudTelemetrySink> sink_;

  std::atomic<bool> running_{false};
  std::thread worker_;

  std::atomic<uint64_t> ingested_{0};
  std::atomic<uint64_t> downsampled_{0};
  std::atomic<uint64_t> dropped_{0};
  std::atomic<uint64_t> sent_{0};
};

} // namespace slipstream::physics
