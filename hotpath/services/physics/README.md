# Physics Engine (Sprint 2)

This module translates game telemetry into stable, low‑latency motion commands for the rig.

## Build & test

```bash
cd hotpath/services/physics
cmake -S . -B build
cmake --build build
ctest --test-dir build
```

## Components

- **IGameTelemetryProvider**: interface for game adapters.
- **AssettoCorsaAdapter**: shared‑memory reader (Windows only).
- **High‑pass washout**: removes sustained acceleration drift.
- **Low‑pass filters**: smooth return‑to‑center.
- **Coordinate transform**: maps game axes → rig axes.
- **Motion engine**: produces pitch/roll + motor targets with latency tracking.

## Latency tracing

`MotionCommand.latency_ms` is the elapsed time from telemetry read to command output.

## Notes

- On non‑Windows platforms, the Assetto Corsa adapter is stubbed (builds, but returns no data).
- Configure axis mapping and gains in `MotionConfig` for your rig.
