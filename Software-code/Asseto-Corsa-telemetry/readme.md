# The code that get telemetry data from Asseto-Corsa


Stream live telemetry from Assetto Corsa via a small Windows C++ bridge into a gRPC ingest server, optionally recording to disk and converting recordings to Parquet for analysis. The proto lives at `proto/telemetry/v1/telemetry.proto`, and both C++ and Python stubs are generated from it. 

## What’s in this repo

* **C++ bridge (Windows):** reads Assetto Corsa shared memory and streams `TelemetryFrame` messages over gRPC; also writes a gzipped length-delimited protobuf file locally. Sources under `cpp/` with a CMake build. 
* **gRPC definitions:** `TelemetryFrame`, `TelemetryIngest` service, etc. at `proto/telemetry/v1/telemetry.proto`. 
* **Reference Python ingest server:** minimal async gRPC server at `server/reference_ingest_server.py`. 
* **Recording reader:** `tools/recorder_reader.py` converts `telemetry_record.pb.gz` to Parquet. 

---

## Prerequisites

* **OS:** The bridge runs on **Windows** (it uses Win32 APIs and Assetto Corsa’s Windows shared memory). 
* **Assetto Corsa:** Enable “Shared Memory” in game settings.
* **CMake 3.24+**, **Git**, **Python 3.9+**, and **vcpkg** (for C++ dependencies).

---

## 1) Install CMake

### Windows (PowerShell)

```powershell
winget install Kitware.CMake
cmake --version
```

---

## 2) Python environment (server + tools)

Create/activate a virtual environment (recommended), then install packages:

### Windows (PowerShell)

```powershell
py -m pip install --upgrade pip
py -m pip install grpcio grpcio-tools pandas pyarrow
```

Generate Python stubs from the proto (creates `telemetry/v1/*_pb2*.py`). Paths match this repo’s proto layout. 

```bash
python -m grpc_tools.protoc -I ./proto --python_out=. --grpc_python_out=. proto/telemetry/v1/telemetry.proto
```

> Tip: Ensure `telemetry/` and `telemetry/v1/` are Python packages (add empty `__init__.py` files if they don’t exist) so `import telemetry.v1.telemetry_pb2` works for the server and tools. The reader imports `telemetry.v1.telemetry_pb2` directly. 

---

## 3) C++ dependencies via vcpkg (Windows)

```powershell
git clone https://github.com/microsoft/vcpkg $env:HOMEPATH\vcpkg
& "$env:HOMEPATH\vcpkg\bootstrap-vcpkg.bat"
& "$env:HOMEPATH\vcpkg\vcpkg.exe" install grpc protobuf zlib --triplet x64-windows
```

---

## 4) Build the C++ bridge (Windows)

The CMake project is in `cpp/` and expects gRPC/Protobuf via `find_package`, which works seamlessly with the vcpkg toolchain file. The code links to Win32 and reads AC shared memory structures from `cpp/src/ac_shmem.hpp`. 

```powershell
# From repo root
$VCPKG="$env:HOMEPATH\vcpkg"
cmake -S cpp -B build `
  -DCMAKE_TOOLCHAIN_FILE="$VCPKG\scripts\buildsystems\vcpkg.cmake" `
  -DVCPKG_TARGET_TRIPLET=x64-windows `
  -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

This produces `build/telemetry_bridge.exe`. The bridge sources are at `cpp/src/*.cpp` and `cpp/src/*.hpp`; CMake uses `proto/telemetry/v1/telemetry.proto` for codegen. 

---

## 5) Run the reference ingest server (Python)

From repo root:

```bash
python server/reference_ingest_server.py
```

It starts an async gRPC server on `:50051` implementing `TelemetryIngest.StreamFrames` and acknowledging frames. In production, you’d push frames to storage from here. 

---

## 6) Run the bridge and stream telemetry (Windows)

1. Start Assetto Corsa and load a session (shared memory must be available).
2. In a terminal, run:

```powershell
# Default target is 127.0.0.1:50051; pass a different address as the first arg if needed
.\build\Release\telemetry_bridge.exe 127.0.0.1:50051
```

* The bridge opens AC shared memory pages and sends `TelemetryFrame` messages ~333 Hz. It also writes a local gzip file `telemetry_record.pb.gz` with length-delimited `TelemetryFrame` payloads. 

---

## 7) Converting a recording to Parquet

The tool `tools/recorder_reader.py` parses `telemetry_record.pb.gz` and writes a Parquet file with useful columns (timestamps, speed, inputs, lap/position, etc.). 

```bash
python tools/recorder_reader.py telemetry_record.pb.gz out.parquet
```

You’ll see output like `Wrote out.parquet with N rows`. The script uses the generated Python protobufs (`telemetry.v1.telemetry_pb2`) and `pandas/pyarrow`. 

---

## Project layout

```
.
├── cpp/
│   ├── src/                # bridge sources (Win32 + gRPC client + recorder)
│   └── CMakeLists.txt
├── proto/
│   └── telemetry/v1/telemetry.proto
├── server/
│   └── reference_ingest_server.py
├── tools/
│   └── recorder_reader.py
└── readme.md
```



---

## Troubleshooting

* **Cannot import `telemetry.v1.telemetry_pb2` in Python:** Regenerate stubs and ensure `telemetry/` and `telemetry/v1/` have `__init__.py`. 
* **Bridge can’t connect:** Verify the server is running on `:50051` and that Windows Firewall allows outbound/inbound for the bridge/server.
* **CMake can’t find gRPC/Protobuf:** Confirm you passed vcpkg toolchain arguments and installed `grpc`, `protobuf`, and `zlib` for `x64-windows`. 
* **Assetto Corsa values look off:** Ensure a live session is running; some fields (e.g., clutch) may be unavailable in certain AC versions and are set conservatively in the bridge. 

---

## Notes

* The gRPC service is `TelemetryIngest.StreamFrames` (bidirectional); the reference server only sends minimal acks. Extend it to persist to your DB/queue. Proto options for Go/Java/C# packages are already set. 
* The bridge writes normalized steering and includes tyre, load, temp, suspension, velocities, lap timing, and more as defined in the proto. 

---

## License

Choose and add a license file (e.g., MIT/Apache-2.0) if you plan to distribute.

---

### Quick commands recap

```bash
# Generate Python stubs
python -m grpc_tools.protoc -I ./proto --python_out=. --grpc_python_out=. proto/telemetry/v1/telemetry.proto

# Start server
python server/reference_ingest_server.py

# Build (Windows + vcpkg)
cmake -S cpp -B build -DCMAKE_TOOLCHAIN_FILE="%HOMEPATH%\vcpkg\scripts\buildsystems\vcpkg.cmake" -DVCPKG_TARGET_TRIPLET=x64-windows -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release

# Run bridge
.\build\Release\telemetry_bridge.exe 127.0.0.1:50051

# Convert recording
python tools/recorder_reader.py telemetry_record.pb.gz out.parquet
```

---
