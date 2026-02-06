#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  LED_STATE_IDLE = 0,
  LED_STATE_ACTIVE,
  LED_STATE_FAULT,
  LED_STATE_MAINTENANCE
} led_state_t;

void led_init(void);
void led_set_state(led_state_t state);
void led_tick(uint32_t now_ms);

#ifdef __cplusplus
}
#endif
