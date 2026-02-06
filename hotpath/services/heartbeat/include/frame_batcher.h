#pragma once

#include <cstddef>
#include <cstdint>
#include <vector>

namespace heartbeat {

class FrameBatcher {
public:
  explicit FrameBatcher(std::size_t max_bytes = 64) : max_bytes_(max_bytes) {}

  bool append(const uint8_t *data, std::size_t len) {
    if (len > max_bytes_) {
      return false;
    }
    if (buffer_.size() + len > max_bytes_) {
      return false;
    }
    buffer_.insert(buffer_.end(), data, data + len);
    return true;
  }

  bool append(const std::vector<uint8_t> &frame) {
    return append(frame.data(), frame.size());
  }

  bool empty() const { return buffer_.empty(); }
  std::size_t size() const { return buffer_.size(); }
  const uint8_t *data() const { return buffer_.data(); }
  void clear() { buffer_.clear(); }
  std::size_t max_bytes() const { return max_bytes_; }

private:
  std::size_t max_bytes_;
  std::vector<uint8_t> buffer_;
};

} // namespace heartbeat
