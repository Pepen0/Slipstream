#pragma once

#include <cstddef>
#include <cstdint>
#include <string>

namespace heartbeat {

class SerialPort {
public:
  SerialPort();
  ~SerialPort();

  bool open(const std::string &port, int baud);
  void close();
  bool is_open() const;
  bool write(const uint8_t *data, size_t len);
  size_t read(uint8_t *data, size_t len);

  std::string last_error() const;

private:
  struct Impl;
  Impl *impl_;
};

} // namespace heartbeat
