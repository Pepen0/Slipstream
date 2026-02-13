#include "mcu_ptt.h"

void mcu_ptt_init(mcu_ptt_state_t *state, uint32_t debounce_ms, bool initial_pressed) {
  if (!state) {
    return;
  }
  state->pressed = initial_pressed ? 1u : 0u;
  state->raw_state = initial_pressed ? 1u : 0u;
  state->initialized = 1u;
  state->reserved = 0u;
  state->debounce_ms = debounce_ms;
  state->last_edge_ms = 0u;
}

void mcu_ptt_resync(mcu_ptt_state_t *state, bool raw_pressed, uint32_t now_ms) {
  if (!state) {
    return;
  }
  if (!state->initialized) {
    mcu_ptt_init(state, 0u, raw_pressed);
  }
  state->pressed = raw_pressed ? 1u : 0u;
  state->raw_state = raw_pressed ? 1u : 0u;
  state->last_edge_ms = now_ms;
}

mcu_ptt_event_type_t mcu_ptt_update(mcu_ptt_state_t *state, bool raw_pressed, uint32_t now_ms) {
  if (!state) {
    return MCU_PTT_EVENT_NONE;
  }
  if (!state->initialized) {
    mcu_ptt_init(state, 0u, raw_pressed);
    state->last_edge_ms = now_ms;
    return MCU_PTT_EVENT_NONE;
  }

  uint8_t raw = raw_pressed ? 1u : 0u;
  if (raw != state->raw_state) {
    state->raw_state = raw;
    state->last_edge_ms = now_ms;
  }

  if (state->raw_state == state->pressed) {
    return MCU_PTT_EVENT_NONE;
  }

  if (state->debounce_ms > 0u &&
      (uint32_t)(now_ms - state->last_edge_ms) < state->debounce_ms) {
    return MCU_PTT_EVENT_NONE;
  }

  state->pressed = state->raw_state;
  return state->pressed ? MCU_PTT_EVENT_DOWN : MCU_PTT_EVENT_UP;
}

bool mcu_ptt_is_pressed(const mcu_ptt_state_t *state) {
  return state && state->pressed;
}
