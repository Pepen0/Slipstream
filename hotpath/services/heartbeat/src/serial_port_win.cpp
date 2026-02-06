#include "serial_port.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

namespace heartbeat {

struct SerialPort::Impl {
  HANDLE handle = INVALID_HANDLE_VALUE;
  std::string error;
};

static std::string format_port(const std::string &port) {
  if (port.rfind("\\\\.\\", 0) == 0) {
    return port;
  }
  return "\\\\.\\" + port;
}

SerialPort::SerialPort() : impl_(new Impl()) {}
SerialPort::~SerialPort() {
  close();
  delete impl_;
}

bool SerialPort::open(const std::string &port, int baud) {
  close();
  impl_->error.clear();

  std::string device = format_port(port);
  HANDLE h = CreateFileA(device.c_str(), GENERIC_READ | GENERIC_WRITE, 0, nullptr,
                         OPEN_EXISTING, 0, nullptr);
  if (h == INVALID_HANDLE_VALUE) {
    impl_->error = "CreateFile failed";
    return false;
  }

  DCB dcb = {0};
  dcb.DCBlength = sizeof(DCB);
  if (!GetCommState(h, &dcb)) {
    impl_->error = "GetCommState failed";
    CloseHandle(h);
    return false;
  }

  dcb.BaudRate = baud;
  dcb.ByteSize = 8;
  dcb.Parity = NOPARITY;
  dcb.StopBits = ONESTOPBIT;
  dcb.fOutxCtsFlow = FALSE;
  dcb.fOutxDsrFlow = FALSE;
  dcb.fDtrControl = DTR_CONTROL_ENABLE;
  dcb.fRtsControl = RTS_CONTROL_ENABLE;

  if (!SetCommState(h, &dcb)) {
    impl_->error = "SetCommState failed";
    CloseHandle(h);
    return false;
  }

  COMMTIMEOUTS timeouts = {0};
  timeouts.ReadIntervalTimeout = 50;
  timeouts.ReadTotalTimeoutConstant = 50;
  timeouts.ReadTotalTimeoutMultiplier = 10;
  timeouts.WriteTotalTimeoutConstant = 50;
  timeouts.WriteTotalTimeoutMultiplier = 10;
  SetCommTimeouts(h, &timeouts);

  impl_->handle = h;
  return true;
}

void SerialPort::close() {
  if (impl_->handle != INVALID_HANDLE_VALUE) {
    CloseHandle(impl_->handle);
    impl_->handle = INVALID_HANDLE_VALUE;
  }
}

bool SerialPort::is_open() const {
  return impl_->handle != INVALID_HANDLE_VALUE;
}

bool SerialPort::write(const uint8_t *data, size_t len) {
  if (impl_->handle == INVALID_HANDLE_VALUE) {
    impl_->error = "port not open";
    return false;
  }
  DWORD written = 0;
  if (!WriteFile(impl_->handle, data, static_cast<DWORD>(len), &written, nullptr)) {
    impl_->error = "WriteFile failed";
    return false;
  }
  return written == len;
}

size_t SerialPort::read(uint8_t *data, size_t len) {
  if (impl_->handle == INVALID_HANDLE_VALUE) {
    impl_->error = "port not open";
    return 0;
  }
  DWORD read_bytes = 0;
  if (!ReadFile(impl_->handle, data, static_cast<DWORD>(len), &read_bytes, nullptr)) {
    impl_->error = "ReadFile failed";
    return 0;
  }
  return static_cast<size_t>(read_bytes);
}

std::string SerialPort::last_error() const {
  return impl_->error;
}

} // namespace heartbeat
