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
- Bridge environment variables:
  - `SLIPSTREAM_MCU_BRIDGE` (`1` default, set `0` to disable)
  - `SLIPSTREAM_MCU_PORT` (default `/dev/ttyACM0` on POSIX, `COM3` on Windows)
  - `SLIPSTREAM_MCU_BAUD` (default `115200`)
  - `SLIPSTREAM_MCU_HEARTBEAT_MS` (default `50`)
  - `SLIPSTREAM_MCU_FORCE_INTENSITY` (default `1.0`, clamped to MCU limits)
  - `SLIPSTREAM_MCU_MOTION_RANGE` (default `1.0`, clamped to MCU limits)
- Logging is timestamped in `logger.cpp`.
- Sessions are stored locally under `hotpath/services/dashboard/data/sessions` as JSON + JSONL telemetry.
