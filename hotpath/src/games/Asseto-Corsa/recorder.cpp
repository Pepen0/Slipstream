#include "recorder.hpp"
#include <stdexcept>

FrameRecorder::FrameRecorder(const std::filesystem::path& gz_path) {
  gz_ = gzopen(gz_path.string().c_str(), "wb6"); // compression level 6
  if (!gz_) throw std::runtime_error("Failed to open recorder gzip file");
}

FrameRecorder::~FrameRecorder() {
  if (gz_) gzclose(gz_);
}

void FrameRecorder::write(const void* data, size_t size) {
  std::lock_guard<std::mutex> lk(mu_);
  // write varint length (protobuf-style)
  uint8_t buf[10];
  size_t  n = 0;
  uint64_t len = static_cast<uint64_t>(size);
  while (true) {
    uint8_t byte = len & 0x7F;
    len >>= 7;
    if (len) byte |= 0x80;
    buf[n++] = byte;
    if (!len) break;
  }
  if (gzwrite(gz_, buf, static_cast<unsigned>(n)) != (int)n)
    throw std::runtime_error("gzwrite length failed");
  if (gzwrite(gz_, data, (unsigned)size) != (int)size)
    throw std::runtime_error("gzwrite payload failed");
}
