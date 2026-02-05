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
- StreamTelemetry (server streaming)

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
- Logging is timestamped in `logger.cpp`.
