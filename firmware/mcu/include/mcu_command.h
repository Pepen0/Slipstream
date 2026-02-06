#pragma once

#include <stdint.h>

#pragma pack(push, 1)
typedef struct {
  float left_m;
  float right_m;
  uint64_t host_timestamp_ns;
} mcu_command_t;
#pragma pack(pop)

#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
_Static_assert(sizeof(mcu_command_t) == 16, "mcu_command_t size must be 16 bytes");
#endif
