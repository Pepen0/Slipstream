# The code that get telemetry data from Asseto-Corsa

Stream live telemetry from Assetto Corsa via a small Windows C++ bridge into a Python gRPC ingest server. Optionally record to disk (gzipped, length‑delimited protobuf stream) and convert to Parquet for analysis and plotting.

---

## Repository layout

```
.
├── cpp/                      # Windows bridge (C++/gRPC) + recorder
│   ├── src/
│   └── CMakeLists.txt
├── proto/
│   └── telemetry/v1/telemetry.proto  # Protobuf + gRPC service
├── server/
│   └── reference_ingest_server.py    # Async Python ingest (gRPC)
├── tools/
│   ├── recorder_reader.py    # .pb.gz -> Parquet converter
│   ├── view_parquet.py       # console viewer / CSV export
│   └── plot_parquet.py       # quick matplotlib plots
├── requirements.txt
└── readme.md
```

---

## Prerequisites

* **OS:** Windows (bridge uses Win32 + Assetto Corsa shared memory)
* **Assetto Corsa:** enable **Shared Memory** in game settings
* **CMake ≥ 3.24**, **Git**, **Python ≥ 3.9**, **vcpkg** (for C++ deps)

---

## Python: setup & codegen

Create/activate a virtualenv (recommended), then:

```powershell
py -m pip install --upgrade pip
py -m pip install -r requirements.txt
```

Generate Python protobuf and gRPC stubs:

```powershell
python -m grpc_tools.protoc -I ./proto --python_out=. --grpc_python_out=. proto/telemetry/v1/telemetry.proto
```

> We had a bunch of issues with protobuf imports, so ensure `telemetry/` and `telemetry/v1/` are Python packages by adding empty `__init__.py` files so imports like `import telemetry.v1.telemetry_pb2` work.

---

## C++: install deps via vcpkg (Windows)

```powershell
git clone https://github.com/microsoft/vcpkg $env:HOMEPATH\vcpkg
& "$env:HOMEPATH\vcpkg\bootstrap-vcpkg.bat"
& "$env:HOMEPATH\vcpkg\vcpkg.exe" install grpc protobuf zlib --triplet x64-windows
```

---

## Build the Windows bridge

```powershell
# From repo root
$VCPKG = "$env:HOMEPATH\vcpkg"
cmake -S cpp -B build `
  -DCMAKE_TOOLCHAIN_FILE="$VCPKG\scripts\buildsystems\vcpkg.cmake" `
  -DVCPKG_TARGET_TRIPLET=x64-windows `
  -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

This produces `build/telemetry_bridge.exe`.

---

## Run the reference ingest server (Python)

```powershell
python server/reference_ingest_server.py
```

Starts an async gRPC server on `:50051` implementing `TelemetryIngest.StreamFrames` (acknowledges frames).

---

## Run the bridge (stream + record)

Start Assetto Corsa and load a session, then:

```powershell
# Default target is 127.0.0.1:50051; pass a different address as arg if needed
.\build\Release\telemetry_bridge.exe 127.0.0.1:50051
```

* Streams `TelemetryFrame` messages ~333 Hz to the server.
* Writes a local gzip file `telemetry_record.pb.gz` (sequence of length‑delimited protobuf frames).

---

## Convert a recording to Parquet

```powershell
python tools/recorder_reader.py telemetry_record.pb.gz out.parquet
```

The converter reads the gzipped length‑delimited stream and writes a tidy Parquet with columns like `t_ns`, `speed_kmh`, `rpm`, `gear`, `gas`, `brake`, `steer`, `ax_g..`, `lap`, `pos`, and more.

---

## Explore the Parquet

### Console view / CSV export

```powershell
# Show first 50 rows and dataset stats
python tools/view_parquet.py out.parquet

# Choose columns and/or export to CSV
python tools/view_parquet.py out.parquet -n 100 -c speed_kmh rpm gear gas brake steer --to-csv out.csv
```

### Quick plots

Each selected column is plotted vs time (`t_s`) if available.

```powershell
# Default set: speed, rpm, gear, inputs, accel Gs, lap/pos
python tools/plot_parquet.py out.parquet

# Custom columns and a row limit for quick viewing
python tools/plot_parquet.py out.parquet --cols speed_kmh rpm gear --limit 5000
```

> Note: Plot windows appear one by one (Matplotlib). Close each to advance.

---

## Requirements

Install with:

```powershell
py -m pip install -r requirements.txt
```

---

## Troubleshooting

### `ModuleNotFoundError: No module named 'telemetry'`

* Regenerate Python stubs (see **Python: setup & codegen**), and make sure you run tools from the **repo root** so `.` is on `sys.path`.
* Ensure `telemetry/` and `telemetry/v1/` have `__init__.py`, or set `PYTHONPATH` to the repo root before invoking scripts.

### `EOFError: Compressed file ended before the end-of-stream marker`

* Your `.pb.gz` is truncated (incomplete final gzip member). The reader is tolerant and will ignore a partial tail, but generate a fresh recording by closing the bridge cleanly for a fully intact file.

### CMake can’t find gRPC/Protobuf

* Confirm vcpkg is installed, triplet is `x64-windows`, and the toolchain file/path is passed to CMake.

### Bridge connects but values look odd

* Ensure the AC session is actually live; some fields depend on game state/version. Steering is normalized roughly from degrees to `[-1, 1]` in the bridge.

---

## Extending

* The Python server is intentionally minimal—extend it to persist telemetry (e.g., Postgres/Timescale, DuckDB, Redis streams).
* The proto includes physics, graphics, and static car/track metadata; add fields as needed and regenerate stubs.

---
