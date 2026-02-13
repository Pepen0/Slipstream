# PC ↔ MCU Heartbeat (Sprint 1)

This service sends a binary heartbeat packet over USB CDC to the MCU at a fixed interval (<100 ms) with CRC validation. It detects disconnects on write failure and retries until the port is back.

## Build

```bash
cd hotpath/services/heartbeat
cmake -S . -B build
cmake --build build
```

## Run

```bash
./build/heartbeat_sender --port /dev/ttyACM0 --baud 115200 --interval 50
```

Windows example:

```powershell
.\build\heartbeat_sender.exe --port COM3 --baud 115200 --interval 50
```

Optional: print MCU status frames

```bash
./build/heartbeat_sender --port /dev/ttyACM0 --status
```

Status output includes firmware version, maintenance state, and wheel PTT input events.

Optional: batch heartbeat + command frames into a single USB write

```bash
./build/heartbeat_sender --port /dev/ttyACM0 --batch --command --cmd-left 0.01 --cmd-right 0.01
```

Request the MCU to enter DFU mode:

```bash
./build/heartbeat_sender --port /dev/ttyACM0 --dfu
```

Tune the batch byte budget (default 64 bytes):

```bash
./build/heartbeat_sender --port /dev/ttyACM0 --batch --batch-max 128
```

## Tests

```bash
cd hotpath/services/heartbeat
cmake -S . -B build
cmake --build build
ctest --test-dir build
```

## Packet format

Matches MCU firmware (`protocol.h`):

```
Header (packed)
  uint32 magic   = 0xA5C3F00D
  uint8  version = 2
  uint8  type    = 0x01 heartbeat / 0x02 command / 0x03 jog
                 = 0x10 status / 0x11 input-event
                 = 0x20 maintenance
  uint16 length  = payload bytes
  uint32 seq
Payload
  <length bytes>
CRC16-CCITT over header+payload (init 0xFFFF)
```

## Disconnect recovery

If a write fails, the sender closes the port and retries every 1 second (configurable with `--reconnect`).
