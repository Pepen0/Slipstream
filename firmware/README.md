# Firmware

This directory contains the STM32 MCU firmware (PlatformIO + STM32Cube HAL) and a host-testable core safety/state-machine library.

## Layout

```
firmware/
  mcu/
    platformio.ini
    include/            # MCU headers (HAL config, app_config, USB, etc.)
    src/                # STM32 HAL + USB CDC application
    lib/core/           # Platform-agnostic safety/state machine + protocol
    test/               # Unity unit tests (native)
```

## Quick start (STM32F103 default)

> Update pin mappings in `firmware/mcu/include/app_config.h` for your board.

```bash
cd firmware/mcu
pio run -e bluepill_f103c8
```

## Unit tests (host)

```bash
cd firmware/mcu
pio test -e native
```

## Safety behavior (Sprint-1)

The core logic guarantees a non-energized state on:
- USB disconnect
- Heartbeat loss (>100 ms)
- E-Stop asserted

Tests in `firmware/mcu/test` exercise these paths and are run in CI.
