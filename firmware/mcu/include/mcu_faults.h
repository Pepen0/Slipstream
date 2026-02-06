#pragma once

#include <stdint.h>

#define MCU_FAULT_NONE              0u
#define MCU_FAULT_USB_DISCONNECT    1u
#define MCU_FAULT_ESTOP             2u
#define MCU_FAULT_HEARTBEAT_TIMEOUT 3u
#define MCU_FAULT_SENSOR_RANGE      4u
#define MCU_FAULT_HOMING_TIMEOUT    5u
#define MCU_FAULT_COMMAND_INVALID   6u
