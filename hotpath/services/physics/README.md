# Physics Engine (Sprint 2)

This module translates game telemetry into stable, low‑latency motion commands for the rig.

## Build & test

```bash
cd hotpath/services/physics
cmake -S . -B build
cmake --build build
ctest --test-dir build
```

## Multi-game adapter usage

```cpp
#include "universal_game_adapter.h"

using namespace slipstream::physics;

UniversalGameAdapter provider(GameId::Auto); // Auto-detect AC or F1 23/24.
MotionLoop loop(200);
loop.run(provider, engine, on_command, on_sample);
```

## Components

- **IGameTelemetryProvider**: motion loop input interface.
- **IGameTelemetryAdapter**: game adapter contract (`start/read/probe` + game id).
- **GameAdapterRegistry**: adapter factory/registry for supported games.
- **UniversalGameAdapter**: explicit or auto game selection.
- **AssettoCorsaAdapter**: AC shared‑memory reader (Windows only).
- **F1UdpAdapter**: F1 23/24 UDP motion reader.
- **High‑pass washout**: removes sustained acceleration drift.
- **Low‑pass filters**: smooth return‑to‑center.
- **Coordinate normalization**: harmonizes source axes (Y‑up/Z‑up) into Z‑up.
- **Coordinate transform**: maps normalized axes → rig axes.
- **Motion engine**: produces pitch/roll + motor targets with latency tracking.

## Latency tracing

`MotionCommand.latency_ms` is the elapsed time from telemetry read to command output.

For end‑to‑end profiling, pass a `MotionProfiler` into `MotionLoop::run(...)` to
capture read/process/dispatch timing and loop slip.

## Jitter reduction

`MotionConfig.jitter` applies a deadband + slew‑rate limiter on pitch/roll to
reduce small oscillations without delaying large corrections.

## Notes

- On non‑Windows platforms, the Assetto Corsa adapter is stubbed (builds, but returns no data).
- Configure axis mapping and gains in `MotionConfig` for your rig.
