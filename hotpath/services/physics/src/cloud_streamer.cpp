#include "cloud_streamer.h"

#include <chrono>

namespace slipstream::physics {

CloudTelemetryStreamer::RingBuffer::RingBuffer(std::size_t capacity_in) {
  if (capacity_in < 4) {
    capacity_in = 4;
  }
  capacity = capacity_in + 1;
  buffer.resize(capacity);
}

bool CloudTelemetryStreamer::RingBuffer::try_push(const CloudTelemetryFrame &frame,
                                                  DropStrategy strategy, uint64_t &dropped) {
  auto head_val = head.load(std::memory_order_relaxed);
  auto tail_val = tail.load(std::memory_order_acquire);
  auto next = (head_val + 1) % capacity;
  if (next == tail_val) {
    if (strategy == DropStrategy::DropOldest) {
      tail_val = (tail_val + 1) % capacity;
      tail.store(tail_val, std::memory_order_release);
      dropped += 1;
    } else {
      dropped += 1;
      return false;
    }
  }
  buffer[head_val] = frame;
  head.store(next, std::memory_order_release);
  return true;
}

bool CloudTelemetryStreamer::RingBuffer::try_pop(CloudTelemetryFrame &out) {
  auto tail_val = tail.load(std::memory_order_relaxed);
  auto head_val = head.load(std::memory_order_acquire);
  if (tail_val == head_val) {
    return false;
  }
  out = buffer[tail_val];
  tail.store((tail_val + 1) % capacity, std::memory_order_release);
  return true;
}

std::size_t CloudTelemetryStreamer::RingBuffer::size() const {
  auto head_val = head.load(std::memory_order_acquire);
  auto tail_val = tail.load(std::memory_order_acquire);
  if (head_val >= tail_val) {
    return head_val - tail_val;
  }
  return capacity - (tail_val - head_val);
}

CloudTelemetryStreamer::CloudTelemetryStreamer(const CloudTelemetryConfig &config)
    : config_(config), ring_(config.queue_capacity) {}

CloudTelemetryStreamer::~CloudTelemetryStreamer() {
  stop();
}

void CloudTelemetryStreamer::set_sink(std::shared_ptr<CloudTelemetrySink> sink) {
  sink_ = std::move(sink);
}

void CloudTelemetryStreamer::start() {
  bool expected = false;
  if (!running_.compare_exchange_strong(expected, true)) {
    return;
  }
  worker_ = std::thread(&CloudTelemetryStreamer::worker_loop, this);
}

void CloudTelemetryStreamer::stop() {
  if (!running_.exchange(false)) {
    return;
  }
  if (worker_.joinable()) {
    worker_.join();
  }
}

uint64_t CloudTelemetryStreamer::period_ns() const {
  if (config_.target_hz <= 0) {
    return 0;
  }
  return static_cast<uint64_t>(1000000000ull / static_cast<uint64_t>(config_.target_hz));
}

void CloudTelemetryStreamer::ingest(const TelemetrySample &sample) {
  ingested_.fetch_add(1, std::memory_order_relaxed);
  const auto interval = period_ns();
  if (interval > 0) {
    while (true) {
      uint64_t last = last_emit_ns_.load(std::memory_order_relaxed);
      if (sample.timestamp_ns <= last || (sample.timestamp_ns - last) < interval) {
        downsampled_.fetch_add(1, std::memory_order_relaxed);
        return;
      }
      if (last_emit_ns_.compare_exchange_weak(last, sample.timestamp_ns, std::memory_order_relaxed)) {
        break;
      }
    }
  }

  CloudTelemetryFrame frame;
  frame.monotonic_ns = sample.timestamp_ns;
  frame.sample = sample;

  uint64_t dropped = 0;
  ring_.try_push(frame, config_.drop_strategy, dropped);
  if (dropped > 0) {
    dropped_.fetch_add(dropped, std::memory_order_relaxed);
  }
}

std::size_t CloudTelemetryStreamer::drain() {
  auto sink = sink_;
  if (!sink) {
    return 0;
  }
  std::size_t sent = 0;
  CloudTelemetryFrame frame;
  while (ring_.try_pop(frame)) {
    if (!sink->send(frame)) {
      break;
    }
    sent += 1;
  }
  if (sent > 0) {
    sent_.fetch_add(sent, std::memory_order_relaxed);
  }
  return sent;
}

CloudTelemetryStats CloudTelemetryStreamer::stats() const {
  CloudTelemetryStats out;
  out.ingested = ingested_.load(std::memory_order_relaxed);
  out.downsampled = downsampled_.load(std::memory_order_relaxed);
  out.dropped = dropped_.load(std::memory_order_relaxed);
  out.sent = sent_.load(std::memory_order_relaxed);
  return out;
}

void CloudTelemetryStreamer::worker_loop() {
  using namespace std::chrono_literals;
  while (running_.load(std::memory_order_relaxed)) {
    if (drain() == 0) {
      std::this_thread::sleep_for(2ms);
    }
  }
  drain();
}

} // namespace slipstream::physics
