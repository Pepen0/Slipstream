# MCU Firmware (STM32)

This firmware implements the Sprint-1 safety requirements: the MCU always enters a non‑energized state on USB disconnect, heartbeat loss, or E‑Stop.

## Configuration

Update pin mappings and timing in `firmware/mcu/include/app_config.h`:
- `ESTOP_PIN` (active low by default)
- `PWM_EN_PIN` (gate/driver enable)
- `LED_PIN`
- `APP_HEARTBEAT_TIMEOUT_MS`
- `APP_TORQUE_DECAY_MS`
- `APP_STATUS_PERIOD_MS`

> If you change the E‑Stop pin, update `EXTI` IRQ selection in `firmware/mcu/src/safety.c`.

## Packet format

```
Header (packed)
  uint32 magic   = 0xA5C3F00D
  uint8  version = 1
  uint8  type    = 0x01 heartbeat
  uint16 length  = payload bytes
  uint32 seq
Payload
  <length bytes>
CRC16-CCITT over header+payload (init 0xFFFF)
```

Send a heartbeat packet at least every 100 ms to keep the MCU in **Active**.

## Torque decay ramp

On heartbeat loss, the MCU enters **Fault** and applies a linear torque‑decay ramp over `APP_TORQUE_DECAY_MS`, then disables PWM. E‑Stop and USB disconnect still force an immediate cutoff.

## Status telemetry (MCU → PC)

The MCU sends a `STATUS` frame every `APP_STATUS_PERIOD_MS` with this payload:

```
struct mcu_status_t {
  uint32 uptime_ms;
  uint32 last_heartbeat_ms;
  uint8  state;
  uint8  flags;   // bit0 USB, bit1 E-Stop, bit2 PWM, bit3 Decay
  uint16 reserved;
}
```

## LED states

- **Idle**: 1 Hz blink
- **Active**: solid ON
- **Fault**: 5 Hz blink

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

