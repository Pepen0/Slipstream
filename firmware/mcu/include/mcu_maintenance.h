#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MCU_MAINTENANCE_MAGIC 0xB007u

typedef enum {
  MCU_MAINTENANCE_OP_NONE = 0,
  MCU_MAINTENANCE_OP_UPDATE_REQUEST = 1,
  MCU_MAINTENANCE_OP_UPDATE_ARM = 2,
  MCU_MAINTENANCE_OP_UPDATE_ABORT = 3,
  MCU_MAINTENANCE_OP_SET_TUNING = 0x10,
  MCU_MAINTENANCE_OP_SAVE_PROFILE = 0x11,
  MCU_MAINTENANCE_OP_SWITCH_PROFILE = 0x12,
  MCU_MAINTENANCE_OP_LOAD_PROFILE = 0x13
} mcu_maintenance_op_t;

#ifdef __cplusplus
extern "C" {
#endif

#pragma pack(push, 1)
typedef struct {
  uint16_t magic;
  uint8_t opcode;
  uint8_t arg0;
  uint32_t token;
} mcu_maintenance_t;

typedef struct {
  uint16_t magic;
  uint8_t opcode;
  uint8_t car_type;
  uint32_t token;
  float force_intensity;
  float motion_range;
} mcu_maintenance_tuning_t;
#pragma pack(pop)

#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
_Static_assert(sizeof(mcu_maintenance_t) == 8, "mcu_maintenance_t size must be 8 bytes");
_Static_assert(sizeof(mcu_maintenance_tuning_t) == 16,
               "mcu_maintenance_tuning_t size must be 16 bytes");
#endif

typedef struct {
  mcu_maintenance_op_t opcode;
  uint8_t car_type;
  uint32_t token;
  float force_intensity;
  float motion_range;
  bool has_tuning_values;
} mcu_maintenance_command_t;

bool mcu_maintenance_decode(const uint8_t *payload, size_t payload_len,
                            mcu_maintenance_command_t *out);

#ifdef __cplusplus
}
#endif
