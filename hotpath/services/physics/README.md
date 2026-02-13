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

`GameId::Auto` also supports runtime failover: if the active adapter stops producing
samples, `UniversalGameAdapter` probes other registered adapters and switches to
the first one that can read telemetry.

## Components

- **IGameTelemetryProvider**: motion loop input interface.
- **IGameTelemetryAdapter**: game adapter contract (`start/read/probe` + game id).
- **GameAdapterRegistry**: adapter factory/registry for supported games.
- **UniversalGameAdapter**: explicit or auto game selection.
- **AssettoCorsaAdapter**: AC shared‑memory reader (Windows only).
- **F1UdpAdapter**: F1 23/24 UDP motion reader.
- **IRacingAdapter**: optional scaffold (currently a stub unless replaced by plugin).
- **GameAdapterPluginManager**: runtime loader for external adapter shared libraries.
- **High‑pass washout**: removes sustained acceleration drift.
- **Low‑pass filters**: smooth return‑to‑center.
- **Coordinate normalization**: harmonizes source axes (Y‑up/Z‑up) into Z‑up.
- **Coordinate transform**: maps normalized axes → rig axes.
- **Motion engine**: produces pitch/roll + motor targets with latency tracking.

## Adapter plugins

`GameAdapterRegistry::create_default()` loads plugins from
`SLIPSTREAM_GAME_ADAPTER_PLUGINS`.

- Unix-like: separate paths with `:` (or `;`)
- Windows: separate paths with `;`
- Required symbol: `slipstream_register_game_adapters(GameAdapterRegistry*)`

Example:

```bash
export SLIPSTREAM_GAME_ADAPTER_PLUGINS="/opt/slipstream/libmy_adapter.so"
```

Built-in plugin target:

```bash
cmake --build build --target iracing_game_adapter_plugin
```

- Windows output: `build/iracing_game_adapter_plugin.dll`
- macOS/Linux output: `build/iracing_game_adapter_plugin.so` (stub transport)

## Latency tracing

`MotionCommand.latency_ms` is the elapsed time from telemetry read to command output.

For end‑to‑end profiling, pass a `MotionProfiler` into `MotionLoop::run(...)` to
capture read/process/dispatch timing and loop slip.

## Jitter reduction

`MotionConfig.jitter` applies a deadband + slew‑rate limiter on pitch/roll to
reduce small oscillations without delaying large corrections.

## Notes

- On non‑Windows platforms, the Assetto Corsa adapter is stubbed (builds, but returns no data).
- iRacing is registered as a stub by default; loading `iracing_game_adapter_plugin`
  replaces it with a Windows shared-memory (IRSDK) transport.
- Configure axis mapping and gains in `MotionConfig` for your rig.
