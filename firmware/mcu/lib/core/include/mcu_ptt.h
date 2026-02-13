#pragma once

#include <stdbool.h>
#include <stdint.h>

#define MCU_PTT_EVENT_MAGIC 0x5054u

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  MCU_PTT_EVENT_NONE = 0,
  MCU_PTT_EVENT_DOWN = 1,
  MCU_PTT_EVENT_UP   = 2
} mcu_ptt_event_type_t;

typedef enum {
  MCU_PTT_SOURCE_STEERING_WHEEL = 1
} mcu_ptt_source_t;

#pragma pack(push, 1)
typedef struct {
  uint16_t magic;
  uint8_t event;
  uint8_t source;
  uint32_t uptime_ms;
  uint8_t pressed;
  uint8_t reserved[3];
} mcu_ptt_event_t;
#pragma pack(pop)

#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
_Static_assert(sizeof(mcu_ptt_event_t) == 12, "mcu_ptt_event_t size must be 12 bytes");
#endif

typedef struct {
  uint8_t pressed;
  uint8_t raw_state;
  uint8_t initialized;
  uint8_t reserved;
  uint32_t debounce_ms;
  uint32_t last_edge_ms;
} mcu_ptt_state_t;

void mcu_ptt_init(mcu_ptt_state_t *state, uint32_t debounce_ms, bool initial_pressed);
void mcu_ptt_resync(mcu_ptt_state_t *state, bool raw_pressed, uint32_t now_ms);
mcu_ptt_event_type_t mcu_ptt_update(mcu_ptt_state_t *state, bool raw_pressed, uint32_t now_ms);
bool mcu_ptt_is_pressed(const mcu_ptt_state_t *state);

#ifdef __cplusplus
}
#endif
