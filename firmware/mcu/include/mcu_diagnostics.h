#pragma once

#include <stdint.h>

#define MCU_DIAG_MAGIC 0xD1A6u

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  MCU_DIAG_OP_REQUEST = 1,
  MCU_DIAG_OP_RESPONSE = 0x81
} mcu_diag_opcode_t;

#pragma pack(push, 1)
typedef struct {
  uint16_t magic;
  uint8_t opcode;
  uint8_t reserved;
  uint32_t token;
} mcu_diag_request_t;

typedef struct {
  uint16_t magic;
  uint8_t opcode;
  uint8_t reserved;
  uint32_t token;
  uint32_t uptime_ms;
  float left_pos_m;
  float right_pos_m;
  uint16_t left_adc_raw;
  uint16_t right_adc_raw;
  uint8_t left_limit;
  uint8_t right_limit;
  float left_cmd;
  float right_cmd;
  float torque_scale;
} mcu_diag_response_t;
#pragma pack(pop)

#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
_Static_assert(sizeof(mcu_diag_request_t) <= 16, "mcu_diag_request_t size must be <= 16 bytes");
_Static_assert(sizeof(mcu_diag_response_t) <= 64, "mcu_diag_response_t exceeds protocol payload budget");
#endif

#ifdef __cplusplus
}
#endif
