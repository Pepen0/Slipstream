# Dashboard Backbone (Sprint 3)

Local gRPC server that exposes dashboard control and telemetry streaming endpoints.

## Proto

`shared/protos/dashboard/v1/dashboard.proto`

RPCs:
- GetStatus
- Calibrate
- SetProfile
- EStop
- StartSession / EndSession
- ListSessions
- StreamTelemetry (server streaming)
- StreamInputEvents (server streaming, hardware PTT)
- StartFirmwareUpdate / CancelFirmwareUpdate
- CheckFirmwareVersion

## Build & test (core)

```bash
cd hotpath/services/dashboard
cmake -S . -B build
cmake --build build
ctest --test-dir build
```

## Build server (requires gRPC + protobuf)

If gRPC is installed (e.g. via vcpkg):

```bash
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=path/to/vcpkg.cmake
cmake --build build
./build/dashboard_server 127.0.0.1:50060
```

## Notes

- Core state machine is independent of gRPC for easy testing.
- `StreamTelemetry` currently replays the latest sample; integrate a real feed by calling `update_telemetry`.
- The server includes an optional MCU USB bridge that sends heartbeats and forwards
  incoming `INPUT_EVENT` packets to `StreamInputEvents`.
- The bridge also queues maintenance/profile packets from UI RPCs:
  - `SetProfile` -> `SWITCH_PROFILE` maintenance opcode
  - `Calibrate` -> `SWITCH_PROFILE`, `SET_TUNING`, `SAVE_PROFILE`
  - `StartFirmwareUpdate` -> `UPDATE_REQUEST`, `UPDATE_ARM`
  - `CancelFirmwareUpdate` -> `UPDATE_ABORT`
- `GetStatus` now includes MCU firmware/update fields and host-side firmware
  update workflow progress for Flutter.
- Bridge environment variables:
  - `SLIPSTREAM_MCU_BRIDGE` (`1` default, set `0` to disable)
  - `SLIPSTREAM_MCU_PORT` (default `/dev/ttyACM0` on POSIX, `COM3` on Windows)
  - `SLIPSTREAM_MCU_BAUD` (default `115200`)
  - `SLIPSTREAM_MCU_HEARTBEAT_MS` (default `50`)
  - `SLIPSTREAM_MCU_FORCE_INTENSITY` (default `1.0`, clamped to MCU limits)
  - `SLIPSTREAM_MCU_MOTION_RANGE` (default `1.0`, clamped to MCU limits)
- Firmware manager environment variables:
  - `SLIPSTREAM_FIRMWARE_ARTIFACT_URI` (default update image path/URL)
  - `SLIPSTREAM_FIRMWARE_SHA256` (optional expected SHA-256)
  - `SLIPSTREAM_FIRMWARE_TARGET_VERSION` (optional target semver for verification)
  - `SLIPSTREAM_FIRMWARE_ROLLBACK_ARTIFACT_URI` (optional rollback image path/URL)
  - `SLIPSTREAM_FIRMWARE_DOWNLOAD_CMD` (download command template, supports `{url}` + `{out}`)
  - `SLIPSTREAM_FIRMWARE_SHA256_CMD` (hash command template, supports `{file}`)
  - `SLIPSTREAM_DFU_FLASH_CMD` (DFU flash command template, supports `{file}`)
  - `SLIPSTREAM_FIRMWARE_DFU_PREPARE_DELAY_MS` (default `900`)
  - `SLIPSTREAM_FIRMWARE_VERIFY_TIMEOUT_MS` (default `5000`)
  - `SLIPSTREAM_FIRMWARE_WORKDIR` (default `data/firmware`)
- Logging is timestamped in `logger.cpp`.
- Sessions are stored locally under `hotpath/services/dashboard/data/sessions` as JSON + JSONL telemetry.
