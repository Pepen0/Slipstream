#include "mcu_maintenance.h"

#include <string.h>

bool mcu_maintenance_decode(const uint8_t *payload, size_t payload_len,
                            mcu_maintenance_command_t *out) {
  if (!payload || !out) {
    return false;
  }
  if (payload_len < sizeof(mcu_maintenance_t)) {
    return false;
  }

  mcu_maintenance_t base = {0};
  memcpy(&base, payload, sizeof(base));
  if (base.magic != MCU_MAINTENANCE_MAGIC) {
    return false;
  }

  out->opcode = (mcu_maintenance_op_t)base.opcode;
  out->car_type = base.arg0;
  out->token = base.token;
  out->force_intensity = 0.0f;
  out->motion_range = 0.0f;
  out->has_tuning_values = false;

  if (base.opcode == MCU_MAINTENANCE_OP_SET_TUNING) {
    if (payload_len < sizeof(mcu_maintenance_tuning_t)) {
      return false;
    }
    mcu_maintenance_tuning_t tuning = {0};
    memcpy(&tuning, payload, sizeof(tuning));
    if (tuning.magic != MCU_MAINTENANCE_MAGIC ||
        tuning.opcode != MCU_MAINTENANCE_OP_SET_TUNING) {
      return false;
    }
    out->car_type = tuning.car_type;
    out->token = tuning.token;
    out->force_intensity = tuning.force_intensity;
    out->motion_range = tuning.motion_range;
    out->has_tuning_values = true;
  }

  return true;
}
