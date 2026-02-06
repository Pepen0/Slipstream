#pragma once

#include <stdint.h>

#define MCU_STATUS_FLAG_USB       (1u << 0)
#define MCU_STATUS_FLAG_ESTOP     (1u << 1)
#define MCU_STATUS_FLAG_PWM       (1u << 2)
#define MCU_STATUS_FLAG_DECAY     (1u << 3)
#define MCU_STATUS_FLAG_HOMING    (1u << 4)
#define MCU_STATUS_FLAG_SENSOR_OK (1u << 5)

#pragma pack(push, 1)
typedef struct {
  uint32_t uptime_ms;
  uint32_t last_heartbeat_ms;
  uint32_t last_cmd_rx_ms;
  uint64_t last_cmd_host_ns;
  float left_setpoint_m;
  float right_setpoint_m;
  float left_pos_m;
  float right_pos_m;
  float left_cmd;
  float right_cmd;
  uint8_t state;
  uint8_t flags;
  uint16_t fault_code;
} mcu_status_t;
#pragma pack(pop)

#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
_Static_assert(sizeof(mcu_status_t) <= 48, "mcu_status_t exceeds protocol payload budget");
#endif
