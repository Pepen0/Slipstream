#include "mcu_core.h"

static bool heartbeat_ok(const mcu_core_t *ctx, uint32_t now_ms) {
  if (!ctx->heartbeat_seen) {
    return false;
  }
  return (now_ms - ctx->last_heartbeat_ms) <= ctx->heartbeat_timeout_ms;
}

void mcu_core_init(mcu_core_t *ctx, uint32_t now_ms, uint32_t heartbeat_timeout_ms,
                   uint32_t decay_duration_ms) {
  ctx->state = MCU_STATE_INIT;
  ctx->usb_connected = false;
  ctx->estop_active = false;
  ctx->heartbeat_seen = false;
  ctx->last_heartbeat_ms = 0;
  ctx->last_fault_ms = 0;
  ctx->heartbeat_timeout_ms = heartbeat_timeout_ms;
  ctx->decay_active = false;
  ctx->decay_start_ms = 0;
  ctx->decay_duration_ms = decay_duration_ms;
  (void)now_ms;
}

void mcu_core_on_usb(mcu_core_t *ctx, bool connected, uint32_t now_ms) {
  ctx->usb_connected = connected;
  if (!connected) {
    ctx->state = MCU_STATE_FAULT;
    ctx->last_fault_ms = now_ms;
    ctx->decay_active = false;
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
    ctx->decay_active = false;
  } else if (ctx->state == MCU_STATE_INIT) {
    ctx->state = MCU_STATE_IDLE;
  }
  (void)now_ms;
}

void mcu_core_on_heartbeat(mcu_core_t *ctx, uint32_t now_ms) {
  ctx->heartbeat_seen = true;
  ctx->last_heartbeat_ms = now_ms;
  ctx->decay_active = false;
  if (ctx->state == MCU_STATE_IDLE && ctx->usb_connected && !ctx->estop_active) {
    ctx->state = MCU_STATE_ACTIVE;
  }
}

void mcu_core_tick(mcu_core_t *ctx, uint32_t now_ms) {
  if (ctx->decay_active && ctx->decay_duration_ms > 0) {
    if ((now_ms - ctx->decay_start_ms) >= ctx->decay_duration_ms) {
      ctx->decay_active = false;
    }
  }
  if (ctx->estop_active || !ctx->usb_connected) {
    ctx->state = MCU_STATE_FAULT;
    return;
  }

  if (ctx->state == MCU_STATE_ACTIVE) {
    if (!heartbeat_ok(ctx, now_ms)) {
      ctx->state = MCU_STATE_FAULT;
      ctx->last_fault_ms = now_ms;
      if (ctx->decay_duration_ms > 0) {
        ctx->decay_active = true;
        ctx->decay_start_ms = now_ms;
      } else {
        ctx->decay_active = false;
      }
    }
  } else if (ctx->state == MCU_STATE_FAULT) {
    if (!ctx->estop_active && ctx->usb_connected) {
      if (heartbeat_ok(ctx, now_ms) && ctx->last_heartbeat_ms > ctx->last_fault_ms) {
        ctx->state = MCU_STATE_ACTIVE;
        ctx->decay_active = false;
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
  if (!ctx->usb_connected || ctx->estop_active) {
    return false;
  }
  if (ctx->decay_active) {
    return (now_ms - ctx->decay_start_ms) < ctx->decay_duration_ms;
  }
  if (ctx->state != MCU_STATE_ACTIVE) {
    return false;
  }
  return heartbeat_ok(ctx, now_ms);
}

float mcu_core_torque_scale(const mcu_core_t *ctx, uint32_t now_ms) {
  if (!ctx->usb_connected || ctx->estop_active) {
    return 0.0f;
  }
  if (ctx->decay_active) {
    uint32_t elapsed = now_ms - ctx->decay_start_ms;
    if (elapsed >= ctx->decay_duration_ms || ctx->decay_duration_ms == 0) {
      return 0.0f;
    }
    float t = (float)elapsed / (float)ctx->decay_duration_ms;
    float scale = 1.0f - t;
    if (scale < 0.0f) {
      scale = 0.0f;
    }
    return scale;
  }
  if (ctx->state != MCU_STATE_ACTIVE) {
    return 0.0f;
  }
  return heartbeat_ok(ctx, now_ms) ? 1.0f : 0.0f;
}
