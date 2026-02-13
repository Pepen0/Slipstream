#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  MCU_STATE_INIT = 0,
  MCU_STATE_IDLE,
  MCU_STATE_ACTIVE,
  MCU_STATE_FAULT,
  MCU_STATE_MAINTENANCE
} mcu_state_t;

typedef enum {
  MCU_UPDATE_STATE_IDLE = 0,
  MCU_UPDATE_STATE_REQUESTED,
  MCU_UPDATE_STATE_ARMED
} mcu_update_state_t;

typedef enum {
  MCU_UPDATE_RESULT_NONE = 0,
  MCU_UPDATE_RESULT_ABORT_TIMEOUT,
  MCU_UPDATE_RESULT_ABORT_ESTOP,
  MCU_UPDATE_RESULT_ABORT_USB,
  MCU_UPDATE_RESULT_ABORT_BAD_TOKEN,
  MCU_UPDATE_RESULT_ABORT_HOST
} mcu_update_result_t;

typedef struct {
  mcu_state_t state;
  bool usb_connected;
  bool estop_active;
  bool heartbeat_seen;
  uint32_t last_heartbeat_ms;
  uint32_t last_fault_ms;
  uint16_t fault_code;
  bool decay_active;
  uint32_t decay_start_ms;
  uint32_t heartbeat_timeout_ms;
  uint32_t decay_duration_ms;
  mcu_update_state_t update_state;
  mcu_update_result_t update_result;
  uint32_t update_token;
  uint32_t update_requested_ms;
  uint32_t update_armed_ms;
  uint32_t update_deadline_ms;
  uint32_t update_request_timeout_ms;
  uint32_t update_arm_timeout_ms;
  uint32_t update_dfu_delay_ms;
} mcu_core_t;

void mcu_core_init(mcu_core_t *ctx, uint32_t now_ms, uint32_t heartbeat_timeout_ms,
                   uint32_t decay_duration_ms, uint32_t update_request_timeout_ms,
                   uint32_t update_arm_timeout_ms, uint32_t update_dfu_delay_ms);
void mcu_core_on_usb(mcu_core_t *ctx, bool connected, uint32_t now_ms);
void mcu_core_on_estop(mcu_core_t *ctx, bool active, uint32_t now_ms);
void mcu_core_on_heartbeat(mcu_core_t *ctx, uint32_t now_ms);
void mcu_core_tick(mcu_core_t *ctx, uint32_t now_ms);
void mcu_core_set_fault(mcu_core_t *ctx, uint16_t fault_code, uint32_t now_ms);
void mcu_core_request_update(mcu_core_t *ctx, uint32_t token, uint32_t now_ms);
bool mcu_core_arm_update(mcu_core_t *ctx, uint32_t token, uint32_t now_ms);
void mcu_core_abort_update(mcu_core_t *ctx, mcu_update_result_t reason);
bool mcu_core_update_ready(const mcu_core_t *ctx, uint32_t now_ms);
mcu_update_state_t mcu_core_update_state(const mcu_core_t *ctx);
mcu_update_result_t mcu_core_update_result(const mcu_core_t *ctx);

mcu_state_t mcu_core_state(const mcu_core_t *ctx);
uint16_t mcu_core_fault(const mcu_core_t *ctx);
bool mcu_core_allow_ptt(const mcu_core_t *ctx);
bool mcu_core_should_energize(const mcu_core_t *ctx, uint32_t now_ms);
float mcu_core_torque_scale(const mcu_core_t *ctx, uint32_t now_ms);

#ifdef __cplusplus
}
#endif
