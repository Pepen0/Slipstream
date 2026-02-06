#pragma once

#include <string>

namespace slipstream::dashboard {

void log_info(const std::string &msg);
void log_warn(const std::string &msg);
void log_error(const std::string &msg);

} // namespace slipstream::dashboard
