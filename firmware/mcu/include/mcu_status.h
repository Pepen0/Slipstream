#pragma once

#include <stdint.h>

#define MCU_STATUS_FLAG_USB       (1u << 0)
#define MCU_STATUS_FLAG_ESTOP     (1u << 1)
#define MCU_STATUS_FLAG_PWM       (1u << 2)
#define MCU_STATUS_FLAG_DECAY     (1u << 3)
#define MCU_STATUS_FLAG_HOMING    (1u << 4)
#define MCU_STATUS_FLAG_SENSOR_OK (1u << 5)
#define MCU_STATUS_FLAG_PTT_HELD  (1u << 6)

#define MCU_STATUS_PROFILE_FLAG_ACTIVE_VALID  (1u << 0)
#define MCU_STATUS_PROFILE_FLAG_STORAGE_LOADED (1u << 1)

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
  uint32_t fw_version;
  uint32_t fw_build;
  uint8_t update_state;
  uint8_t update_result;
  uint8_t active_car_type;
  uint8_t profile_flags;
  uint16_t status_reserved;
} mcu_status_t;
#pragma pack(pop)

#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
_Static_assert(sizeof(mcu_status_t) <= 64, "mcu_status_t exceeds protocol payload budget");
#endif
