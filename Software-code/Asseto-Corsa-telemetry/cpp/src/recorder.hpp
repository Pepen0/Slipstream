#pragma once
#include <filesystem>
#include <fstream>
#include <mutex>
#include <optional>
#include <string>
#include <vector>
#include <cstdint>
#include <memory>
#include <zlib.h>

// Length-delimited protobuf writer with gzip (gz) container
class FrameRecorder {
public:
  explicit FrameRecorder(const std::filesystem::path& gz_path);
  ~FrameRecorder();

  // Writes length-prefixed payload; thread-safe
  void write(const void* data, size_t size);

private:
  gzFile gz_{nullptr};
  std::mutex mu_;
};
