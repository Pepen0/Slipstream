#pragma once

#include <cstddef>
#include <cstdint>

namespace heartbeat {

uint16_t crc16_ccitt(const uint8_t *data, size_t len, uint16_t init = 0xFFFF);

} // namespace heartbeat
