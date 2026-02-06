#include "mcu_core.h"
#include "mcu_faults.h"

static bool heartbeat_ok(const mcu_core_t *ctx, uint32_t now_ms) {
  if (!ctx->heartbeat_seen) {
    return false;
  }
  return (now_ms - ctx->last_heartbeat_ms) <= ctx->heartbeat_timeout_ms;
}

void mcu_core_init(mcu_core_t *ctx, uint32_t now_ms, uint32_t heartbeat_timeout_ms,
                   uint32_t decay_duration_ms, uint32_t update_request_timeout_ms,
                   uint32_t update_arm_timeout_ms, uint32_t update_dfu_delay_ms) {
  ctx->state = MCU_STATE_INIT;
  ctx->usb_connected = false;
  ctx->estop_active = false;
  ctx->heartbeat_seen = false;
  ctx->last_heartbeat_ms = 0;
  ctx->last_fault_ms = 0;
  ctx->fault_code = MCU_FAULT_NONE;
  ctx->heartbeat_timeout_ms = heartbeat_timeout_ms;
  ctx->decay_active = false;
  ctx->decay_start_ms = 0;
  ctx->decay_duration_ms = decay_duration_ms;
  ctx->update_state = MCU_UPDATE_STATE_IDLE;
  ctx->update_result = MCU_UPDATE_RESULT_NONE;
  ctx->update_token = 0;
  ctx->update_requested_ms = 0;
  ctx->update_armed_ms = 0;
  ctx->update_deadline_ms = 0;
  ctx->update_request_timeout_ms = update_request_timeout_ms;
  ctx->update_arm_timeout_ms = update_arm_timeout_ms;
  ctx->update_dfu_delay_ms = update_dfu_delay_ms;
  (void)now_ms;
}

void mcu_core_on_usb(mcu_core_t *ctx, bool connected, uint32_t now_ms) {
  ctx->usb_connected = connected;
  if (!connected) {
    ctx->state = MCU_STATE_FAULT;
    ctx->last_fault_ms = now_ms;
    ctx->fault_code = MCU_FAULT_USB_DISCONNECT;
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
    ctx->fault_code = MCU_FAULT_ESTOP;
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
  if (ctx->update_state != MCU_UPDATE_STATE_IDLE) {
    return;
  }
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
  if (ctx->update_state != MCU_UPDATE_STATE_IDLE) {
    if (ctx->estop_active) {
      mcu_core_abort_update(ctx, MCU_UPDATE_RESULT_ABORT_ESTOP);
    } else if (!ctx->usb_connected) {
      mcu_core_abort_update(ctx, MCU_UPDATE_RESULT_ABORT_USB);
    } else if (ctx->update_deadline_ms > 0 && now_ms > ctx->update_deadline_ms) {
      mcu_core_abort_update(ctx, MCU_UPDATE_RESULT_ABORT_TIMEOUT);
    }
    if (ctx->update_state != MCU_UPDATE_STATE_IDLE) {
      return;
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
      ctx->fault_code = MCU_FAULT_HEARTBEAT_TIMEOUT;
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
  if (ctx->update_state != MCU_UPDATE_STATE_IDLE) {
    return MCU_STATE_MAINTENANCE;
  }
  return ctx->state;
}

uint16_t mcu_core_fault(const mcu_core_t *ctx) {
  return ctx->fault_code;
}

void mcu_core_set_fault(mcu_core_t *ctx, uint16_t fault_code, uint32_t now_ms) {
  ctx->state = MCU_STATE_FAULT;
  ctx->last_fault_ms = now_ms;
  ctx->fault_code = fault_code;
  ctx->decay_active = false;
}

void mcu_core_request_update(mcu_core_t *ctx, uint32_t token, uint32_t now_ms) {
  if (!ctx) return;
  if (ctx->update_state != MCU_UPDATE_STATE_IDLE) {
    return;
  }
  if (!ctx->usb_connected) {
    ctx->update_result = MCU_UPDATE_RESULT_ABORT_USB;
    return;
  }
  if (ctx->estop_active) {
    ctx->update_result = MCU_UPDATE_RESULT_ABORT_ESTOP;
    return;
  }
  ctx->update_state = MCU_UPDATE_STATE_REQUESTED;
  ctx->update_result = MCU_UPDATE_RESULT_NONE;
  ctx->update_token = token;
  ctx->update_requested_ms = now_ms;
  ctx->update_deadline_ms = (ctx->update_request_timeout_ms > 0)
    ? (now_ms + ctx->update_request_timeout_ms)
    : 0;
  ctx->decay_active = false;
}

bool mcu_core_arm_update(mcu_core_t *ctx, uint32_t token, uint32_t now_ms) {
  if (!ctx) return false;
  if (ctx->update_state != MCU_UPDATE_STATE_REQUESTED) {
    return false;
  }
  if (ctx->update_deadline_ms > 0 && now_ms > ctx->update_deadline_ms) {
    mcu_core_abort_update(ctx, MCU_UPDATE_RESULT_ABORT_TIMEOUT);
    return false;
  }
  if (token != ctx->update_token) {
    mcu_core_abort_update(ctx, MCU_UPDATE_RESULT_ABORT_BAD_TOKEN);
    return false;
  }
  ctx->update_state = MCU_UPDATE_STATE_ARMED;
  ctx->update_armed_ms = now_ms;
  ctx->update_deadline_ms = (ctx->update_arm_timeout_ms > 0)
    ? (now_ms + ctx->update_arm_timeout_ms)
    : 0;
  ctx->decay_active = false;
  return true;
}

void mcu_core_abort_update(mcu_core_t *ctx, mcu_update_result_t reason) {
  if (!ctx) return;
  ctx->update_state = MCU_UPDATE_STATE_IDLE;
  ctx->update_result = reason;
  ctx->update_token = 0;
  ctx->update_requested_ms = 0;
  ctx->update_armed_ms = 0;
  ctx->update_deadline_ms = 0;
}

bool mcu_core_update_ready(const mcu_core_t *ctx, uint32_t now_ms) {
  if (!ctx) return false;
  if (ctx->update_state != MCU_UPDATE_STATE_ARMED) {
    return false;
  }
  if (ctx->update_dfu_delay_ms == 0) {
    return true;
  }
  return (now_ms - ctx->update_armed_ms) >= ctx->update_dfu_delay_ms;
}

mcu_update_state_t mcu_core_update_state(const mcu_core_t *ctx) {
  return ctx ? ctx->update_state : MCU_UPDATE_STATE_IDLE;
}

mcu_update_result_t mcu_core_update_result(const mcu_core_t *ctx) {
  return ctx ? ctx->update_result : MCU_UPDATE_RESULT_NONE;
}

bool mcu_core_should_energize(const mcu_core_t *ctx, uint32_t now_ms) {
  if (!ctx->usb_connected || ctx->estop_active) {
    return false;
  }
  if (ctx->update_state != MCU_UPDATE_STATE_IDLE) {
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
  if (ctx->update_state != MCU_UPDATE_STATE_IDLE) {
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
