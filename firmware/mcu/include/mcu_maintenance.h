#pragma once

#include <stdint.h>

#define MCU_MAINTENANCE_MAGIC 0xB007u

typedef enum {
  MCU_MAINTENANCE_OP_NONE = 0,
  MCU_MAINTENANCE_OP_UPDATE_REQUEST = 1,
  MCU_MAINTENANCE_OP_UPDATE_ARM = 2,
  MCU_MAINTENANCE_OP_UPDATE_ABORT = 3
} mcu_maintenance_op_t;

#pragma pack(push, 1)
typedef struct {
  uint16_t magic;
  uint8_t opcode;
  uint8_t reserved;
  uint32_t token;
} mcu_maintenance_t;
#pragma pack(pop)

#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
_Static_assert(sizeof(mcu_maintenance_t) == 8, "mcu_maintenance_t size must be 8 bytes");
#endif
