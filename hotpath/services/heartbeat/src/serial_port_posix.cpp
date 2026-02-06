#include "serial_port.h"

#include <cerrno>
#include <cstring>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>

namespace heartbeat {

struct SerialPort::Impl {
  int fd = -1;
  std::string error;
};

static speed_t to_speed(int baud) {
  switch (baud) {
    case 9600: return B9600;
    case 19200: return B19200;
    case 38400: return B38400;
    case 57600: return B57600;
    case 115200: return B115200;
    case 230400: return B230400;
    default: return B115200;
  }
}

SerialPort::SerialPort() : impl_(new Impl()) {}
SerialPort::~SerialPort() {
  close();
  delete impl_;
}

bool SerialPort::open(const std::string &port, int baud) {
  close();
  impl_->error.clear();

  int fd = ::open(port.c_str(), O_RDWR | O_NOCTTY | O_SYNC);
  if (fd < 0) {
    impl_->error = std::strerror(errno);
    return false;
  }

  termios tty;
  if (tcgetattr(fd, &tty) != 0) {
    impl_->error = std::strerror(errno);
    ::close(fd);
    return false;
  }

  speed_t speed = to_speed(baud);
  cfsetospeed(&tty, speed);
  cfsetispeed(&tty, speed);

  tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;
  tty.c_cflag |= (CLOCAL | CREAD);
  tty.c_cflag &= ~(PARENB | PARODD);
  tty.c_cflag &= ~CSTOPB;
  tty.c_cflag &= ~CRTSCTS;

  tty.c_iflag &= ~(IXON | IXOFF | IXANY);
  tty.c_lflag = 0;
  tty.c_oflag = 0;
  tty.c_cc[VMIN] = 0;
  tty.c_cc[VTIME] = 5;

  if (tcsetattr(fd, TCSANOW, &tty) != 0) {
    impl_->error = std::strerror(errno);
    ::close(fd);
    return false;
  }

  impl_->fd = fd;
  return true;
}

void SerialPort::close() {
  if (impl_->fd >= 0) {
    ::close(impl_->fd);
    impl_->fd = -1;
  }
}

bool SerialPort::is_open() const {
  return impl_->fd >= 0;
}

bool SerialPort::write(const uint8_t *data, size_t len) {
  if (impl_->fd < 0) {
    impl_->error = "port not open";
    return false;
  }
  size_t total = 0;
  while (total < len) {
    ssize_t n = ::write(impl_->fd, data + total, len - total);
    if (n < 0) {
      impl_->error = std::strerror(errno);
      return false;
    }
    total += static_cast<size_t>(n);
  }
  return true;
}

size_t SerialPort::read(uint8_t *data, size_t len) {
  if (impl_->fd < 0) {
    impl_->error = "port not open";
    return 0;
  }
  ssize_t n = ::read(impl_->fd, data, len);
  if (n < 0) {
    if (errno == EAGAIN || errno == EWOULDBLOCK) {
      return 0;
    }
    impl_->error = std::strerror(errno);
    return 0;
  }
  return static_cast<size_t>(n);
}

std::string SerialPort::last_error() const {
  return impl_->error;
}

} // namespace heartbeat
