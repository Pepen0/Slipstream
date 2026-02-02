#include "mcu_core.h"

static bool heartbeat_ok(const mcu_core_t *ctx, uint32_t now_ms) {
  if (!ctx->heartbeat_seen) {
    return false;
  }
  return (now_ms - ctx->last_heartbeat_ms) <= ctx->heartbeat_timeout_ms;
}

void mcu_core_init(mcu_core_t *ctx, uint32_t now_ms, uint32_t heartbeat_timeout_ms) {
  ctx->state = MCU_STATE_INIT;
  ctx->usb_connected = false;
  ctx->estop_active = false;
  ctx->heartbeat_seen = false;
  ctx->last_heartbeat_ms = 0;
  ctx->last_fault_ms = 0;
  ctx->heartbeat_timeout_ms = heartbeat_timeout_ms;
  (void)now_ms;
}

void mcu_core_on_usb(mcu_core_t *ctx, bool connected, uint32_t now_ms) {
  ctx->usb_connected = connected;
  if (!connected) {
    ctx->state = MCU_STATE_FAULT;
    ctx->last_fault_ms = now_ms;
  } else if (ctx->state == MCU_STATE_INIT) {
    ctx->state = MCU_STATE_IDLE;
  }
  (void)now_ms;
}

void mcu_core_on_estop(mcu_core_t *ctx, bool active, uint32_t now_ms) {
  ctx->estop_active = active;
  if (active) {
    ctx->state = MCU_STATE_FAULT;
    ctx->last_fault_ms = now_ms;
  } else if (ctx->state == MCU_STATE_INIT) {
    ctx->state = MCU_STATE_IDLE;
  }
  (void)now_ms;
}

void mcu_core_on_heartbeat(mcu_core_t *ctx, uint32_t now_ms) {
  ctx->heartbeat_seen = true;
  ctx->last_heartbeat_ms = now_ms;
  if (ctx->state == MCU_STATE_IDLE && ctx->usb_connected && !ctx->estop_active) {
    ctx->state = MCU_STATE_ACTIVE;
  }
}

void mcu_core_tick(mcu_core_t *ctx, uint32_t now_ms) {
  if (ctx->estop_active || !ctx->usb_connected) {
    ctx->state = MCU_STATE_FAULT;
    return;
  }

  if (ctx->state == MCU_STATE_ACTIVE) {
    if (!heartbeat_ok(ctx, now_ms)) {
      ctx->state = MCU_STATE_FAULT;
      ctx->last_fault_ms = now_ms;
    }
  } else if (ctx->state == MCU_STATE_FAULT) {
    if (!ctx->estop_active && ctx->usb_connected) {
      if (heartbeat_ok(ctx, now_ms) && ctx->last_heartbeat_ms > ctx->last_fault_ms) {
        ctx->state = MCU_STATE_ACTIVE;
      } else {
        ctx->state = MCU_STATE_IDLE;
      }
    }
  } else if (ctx->state == MCU_STATE_INIT) {
    if (ctx->usb_connected && !ctx->estop_active) {
      ctx->state = MCU_STATE_IDLE;
    }
  }
}

mcu_state_t mcu_core_state(const mcu_core_t *ctx) {
  return ctx->state;
}

bool mcu_core_should_energize(const mcu_core_t *ctx, uint32_t now_ms) {
  if (ctx->state != MCU_STATE_ACTIVE) {
    return false;
  }
  if (!ctx->usb_connected || ctx->estop_active) {
    return false;
  }
  return heartbeat_ok(ctx, now_ms);
}
