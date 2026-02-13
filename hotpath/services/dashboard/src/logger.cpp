#include "logger.h"

#include <chrono>
#include <iomanip>
#include <iostream>
#include <mutex>
#include <sstream>

namespace slipstream::dashboard {

static std::mutex log_mu;

static std::string timestamp_now() {
  using clock = std::chrono::system_clock;
  auto now = clock::now();
  auto tt = clock::to_time_t(now);
  auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;

  std::tm tm{};
#ifdef _WIN32
  localtime_s(&tm, &tt);
#else
  localtime_r(&tt, &tm);
#endif

  std::ostringstream oss;
  oss << std::put_time(&tm, "%Y-%m-%d %H:%M:%S")
      << '.' << std::setw(3) << std::setfill('0') << ms.count();
  return oss.str();
}

static void log_line(const char *level, const std::string &msg) {
  std::lock_guard<std::mutex> lock(log_mu);
  std::cout << '[' << timestamp_now() << "] [" << level << "] " << msg << '\n';
}

void log_info(const std::string &msg) {
  log_line("INFO", msg);
}

void log_warn(const std::string &msg) {
  log_line("WARN", msg);
}

void log_error(const std::string &msg) {
  log_line("ERROR", msg);
}

} // namespace slipstream::dashboard
