# Game Adapter Plugin Interface

This document defines the runtime plugin contract for external game telemetry
adapters used by `hotpath/services/physics`.

## Goal

Allow community or internal teams to add new game adapters without editing
`physics_core` sources.

## Loader behavior

`GameAdapterRegistry::create_default()`:

1. Registers built-in adapters (AC, F1, iRacing stub).
2. Loads plugin libraries from `SLIPSTREAM_GAME_ADAPTER_PLUGINS`.
3. Invokes each plugin registration function against the new registry.

The same plugin can be reused across multiple registry instances in one process.

## Environment variable

- Name: `SLIPSTREAM_GAME_ADAPTER_PLUGINS`
- Windows separator: `;`
- Unix-like separator: `:` (also accepts `;`)

Example:

```bash
export SLIPSTREAM_GAME_ADAPTER_PLUGINS="/opt/slipstream/libmy_adapter.so:/opt/slipstream/libother.so"
```

## Required exported symbol

Each shared library must export this exact C symbol:

```cpp
extern "C" void slipstream_register_game_adapters(
    slipstream::physics::GameAdapterRegistry *registry);
```

Inside this function, register one or more adapter factories:

```cpp
registry->register_adapter(
    slipstream::physics::GameId::F1_23_24,
    []() { return std::make_unique<MyAdapter>(); });
```

## Adapter contract

Plugin adapters must implement `IGameTelemetryAdapter`:

- `game_id()`: stable adapter identity.
- `probe(timeout)`: lightweight game-presence detection.
- `start()`: initialize transport/resources.
- `read(out_sample)`: publish a `TelemetrySample`.

## Notes

- Prefer `GameId` values not already used by built-ins.
- `probe()` should be fast and non-blocking beyond the provided timeout.
- `read()` should return `false` for "no sample available yet" or disconnected state.

## Reference plugin

`hotpath/services/physics/plugins/iracing` provides a reference plugin that
registers `GameId::IRacing` and reads iRacing IRSDK shared memory on Windows.
On non-Windows hosts it compiles with a transport stub so CI can still build/test.

The repository also includes a Windows-only live smoke test
(`test_iracing_live_probe_smoke_win`) that verifies `probe()` against a running
iRacing process on a self-hosted runner.
