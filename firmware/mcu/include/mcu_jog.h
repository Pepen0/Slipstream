#pragma once

#include <stdbool.h>
#include <stdint.h>

#define MCU_JOG_MAGIC 0xC0D3u

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  MCU_JOG_MODE_TORQUE = 0
} mcu_jog_mode_t;

#pragma pack(push, 1)
typedef struct {
  uint16_t magic;
  uint8_t mode;
  uint8_t reserved;
  float left_torque;
  float right_torque;
  uint32_t duration_ms;
} mcu_jog_command_t;
#pragma pack(pop)

#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
_Static_assert(sizeof(mcu_jog_command_t) == 16, "mcu_jog_command_t size must be 16 bytes");
#endif

typedef struct {
  uint8_t active;
  uint8_t mode;
  float left_torque;
  float right_torque;
  uint32_t expires_at_ms;
} mcu_jog_state_t;

void mcu_jog_init(mcu_jog_state_t *state);
bool mcu_jog_start(mcu_jog_state_t *state, const mcu_jog_command_t *cmd, uint32_t now_ms,
                   uint32_t default_duration_ms, uint32_t max_duration_ms);
void mcu_jog_stop(mcu_jog_state_t *state);
bool mcu_jog_update(mcu_jog_state_t *state, uint32_t now_ms);
bool mcu_jog_active(const mcu_jog_state_t *state);
float mcu_jog_left(const mcu_jog_state_t *state);
float mcu_jog_right(const mcu_jog_state_t *state);

#ifdef __cplusplus
}
#endif
