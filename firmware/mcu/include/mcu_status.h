#pragma once

#include <stdint.h>

#define MCU_STATUS_FLAG_USB    (1u << 0)
#define MCU_STATUS_FLAG_ESTOP  (1u << 1)
#define MCU_STATUS_FLAG_PWM    (1u << 2)
#define MCU_STATUS_FLAG_DECAY  (1u << 3)

#pragma pack(push, 1)
typedef struct {
  uint32_t uptime_ms;
  uint32_t last_heartbeat_ms;
  uint8_t state;
  uint8_t flags;
  uint16_t reserved;
} mcu_status_t;
#pragma pack(pop)
