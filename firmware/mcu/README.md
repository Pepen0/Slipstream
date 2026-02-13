# MCU Firmware (STM32)

This firmware implements the Sprint-1 safety requirements: the MCU always enters a non‑energized state on USB disconnect, heartbeat loss, or E‑Stop.

## Configuration

Update pin mappings, timing, and control settings in `firmware/mcu/include/app_config.h`:
- `ESTOP_PIN` (active low by default)
- `PWM_EN_PIN` (gate/driver enable)
- `LED_PIN`
- `APP_HEARTBEAT_TIMEOUT_MS`
- `APP_TORQUE_DECAY_MS`
- `APP_STATUS_PERIOD_MS`
- `APP_CONTROL_LOOP_HZ` (PID loop)
- `APP_PID_KP/KI/KD`
- `APP_TORQUE_LIMIT`
- `APP_POS_MIN_M` / `APP_POS_MAX_M`
- `APP_HOMING_ENABLED`
- `APP_WHEEL_PTT_ENABLED`
- `APP_WHEEL_PTT_DEBOUNCE_MS`
- `WHEEL_PTT_PIN` (active low by default)

> If you change the E‑Stop pin, update `EXTI` IRQ selection in `firmware/mcu/src/safety.c`.

## Packet format

```
Header (packed)
  uint32 magic   = 0xA5C3F00D
  uint8  version = 2
  uint8  type    = 0x01 heartbeat
                 = 0x02 command
                 = 0x03 jog
                 = 0x10 status
                 = 0x11 input event
                 = 0x20 maintenance
                 = 0x30 diagnostic
  uint16 length  = payload bytes
  uint32 seq
Payload
  <length bytes>
CRC16-CCITT over header+payload (init 0xFFFF)
```

Send a heartbeat packet at least every 100 ms to keep the MCU in **Active**.

### Command payload (PC → MCU)

The `COMMAND` frame carries actuator setpoints and a host timestamp for latency tracking:

```
struct mcu_command_t {
  float  left_m;
  float  right_m;
  uint64 host_timestamp_ns;
}
```

### Jog/test payload (PC → MCU)

Use a `JOG` frame to apply a short open-loop torque for calibration/tuning. The command
auto-expires after `duration_ms` (clamped to `APP_JOG_MAX_DURATION_MS`). Send both torques
as zero to stop a jog immediately. A `duration_ms` of 0 uses `APP_JOG_DEFAULT_DURATION_MS`.

```
struct mcu_jog_command_t {
  uint16 magic = 0xC0D3;
  uint8  mode = 0;          // MCU_JOG_MODE_TORQUE
  uint8  reserved;
  float  left_torque;
  float  right_torque;
  uint32 duration_ms;
}
```

## Torque decay ramp

On heartbeat loss, the MCU enters **Fault** and applies a linear torque‑decay ramp over `APP_TORQUE_DECAY_MS`, then disables PWM. E‑Stop and USB disconnect still force an immediate cutoff.

## Control loop (PID)

The control loop runs at `APP_CONTROL_LOOP_HZ` and applies a PID controller per actuator.
Torque outputs are clamped to `APP_TORQUE_LIMIT` and scaled by the heartbeat decay ramp.

## Homing + sensor safety

- Homing drives toward `APP_HOMING_TARGET_M` until limit switches trip (per axis).
- Out‑of‑range sensor readings raise a fault and zero outputs.

> `sensors.c` and `actuators.c` are currently stubbed (limits default to “triggered” so homing completes); wire in ADC/encoder and motor driver outputs for real hardware.

## Status telemetry (MCU → PC)

The MCU sends a `STATUS` frame every `APP_STATUS_PERIOD_MS` with this payload:

```
struct mcu_status_t {
  uint32 uptime_ms;
  uint32 last_heartbeat_ms;
  uint32 last_cmd_rx_ms;
  uint64 last_cmd_host_ns;
  float  left_setpoint_m;
  float  right_setpoint_m;
  float  left_pos_m;
  float  right_pos_m;
  float  left_cmd;
  float  right_cmd;
  uint8  state;
  uint8  flags;      // bit0 USB, bit1 E‑Stop, bit2 PWM, bit3 Decay, bit4 Homing, bit5 Sensor OK, bit6 PTT held
  uint16 fault_code;
  uint32 fw_version; // packed: major.minor.patch.build (8 bits each)
  uint32 fw_build;   // optional build identifier
  uint8  update_state;
  uint8  update_result;
  uint8  active_car_type;
  uint8  profile_flags;  // bit0 active profile valid, bit1 profile storage loaded
  uint16 status_reserved;
}
```

### Steering-wheel PTT input events (MCU → PC)

When enabled, the MCU debounces the wheel PTT button and emits an `INPUT_EVENT` frame on
state transitions:

```
struct mcu_ptt_event_t {
  uint16 magic = 0x5054;
  uint8  event;      // 1 = PTT_DOWN, 2 = PTT_UP
  uint8  source;     // 1 = steering wheel
  uint32 uptime_ms;
  uint8  pressed;    // debounced current state
  uint8  reserved[3];
}
```

PTT events are safety-gated and suppressed while the MCU is in fault, E-Stop, or maintenance state.

### Diagnostic telemetry (MCU → PC, on demand)

Send a `DIAGNOSTIC` frame with a `REQUEST` payload to receive high‑resolution sensor
readouts and raw ADC values for diagnostics.

```
struct mcu_diag_request_t {
  uint16 magic = 0xD1A6;
  uint8  opcode = 0x01; // MCU_DIAG_OP_REQUEST
  uint8  reserved;
  uint32 token;
}

struct mcu_diag_response_t {
  uint16 magic = 0xD1A6;
  uint8  opcode = 0x81; // MCU_DIAG_OP_RESPONSE
  uint8  reserved;
  uint32 token;
  uint32 uptime_ms;
  float  left_pos_m;
  float  right_pos_m;
  uint16 left_adc_raw;
  uint16 right_adc_raw;
  uint8  left_limit;
  uint8  right_limit;
  float  left_cmd;
  float  right_cmd;
  float  torque_scale;
}
```

### Firmware update / DFU

The MCU accepts a maintenance packet to request DFU entry. The update flow is a two‑step
handshake to avoid accidental resets:

1. Send `MAINTENANCE` with opcode `UPDATE_REQUEST` and a token.
2. Send `MAINTENANCE` with opcode `UPDATE_ARM` and the same token within
   `APP_UPDATE_REQUEST_TIMEOUT_MS`.
3. The MCU disables outputs and reboots into the system DFU bootloader after
   `APP_UPDATE_DFU_DELAY_MS`.

The maintenance payload is:

```
struct mcu_maintenance_t {
  uint16 magic = 0xB007;
  uint8  opcode;
  uint8  arg0;
  uint32 token;
}
```

For hardware-manager profile/tuning operations, use the extended maintenance payload:

```
struct mcu_maintenance_tuning_t {
  uint16 magic = 0xB007;
  uint8  opcode;          // 0x10 SET_TUNING
  uint8  car_type;
  uint32 token;           // reserved for host correlation
  float  force_intensity; // clamped to [0.10, 1.00]
  float  motion_range;    // clamped to [0.20, 1.00]
}
```

Supported maintenance opcodes:
- `0x01` `UPDATE_REQUEST`
- `0x02` `UPDATE_ARM`
- `0x03` `UPDATE_ABORT`
- `0x10` `SET_TUNING` (set force intensity + motion range for `car_type`)
- `0x11` `SAVE_PROFILE` (persist profile table to flash; `arg0 = car_type`)
- `0x12` `SWITCH_PROFILE` (activate profile for `arg0 = car_type`)
- `0x13` `LOAD_PROFILE` (reload profile table from flash, then activate `arg0 = car_type`)

> Configure `APP_DFU_BOOTLOADER_ADDR` if your STM32 variant uses a different system memory base.

## LED states

- **Idle**: 1 Hz blink
- **Active**: solid ON
- **Fault**: 5 Hz blink
- **Maintenance**: 2 Hz blink

## Build

```bash
cd firmware/mcu
pio run -e bluepill_f103c8
```

## Unit tests (CI)

```bash
cd firmware/mcu
pio test -e native
```

## Manual E‑Stop integration test

1. Power the MCU and ensure USB CDC enumerates.
2. Stream heartbeat packets (<=100 ms). LED should turn **solid ON**.
3. Press E‑Stop: PWM gate should drop immediately; LED should **fast blink**.
4. Release E‑Stop and resume heartbeat: LED should return **solid ON**.
5. Unplug USB: PWM gate should drop immediately; LED should **fast blink**.
