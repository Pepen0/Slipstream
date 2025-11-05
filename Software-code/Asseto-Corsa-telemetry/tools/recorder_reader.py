import gzip
import io
import struct
import sys
from pathlib import Path
import telemetry.v1.telemetry_pb2 as pb

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

def read_varint(stream):
    shift = 0
    result = 0
    while True:
        b = stream.read(1)
        if not b:
            return None
        b = b[0]
        result |= ((b & 0x7F) << shift)
        if not (b & 0x80):
            return result
        shift += 7

def main(in_gz: Path, out_parquet: Path):
    rows = []
    with gzip.open(in_gz, "rb") as f:
        while True:
            n = read_varint(f)
            if n is None: break
            payload = f.read(n)
            if len(payload) != n: break
            msg = pb.TelemetryFrame()
            msg.ParseFromString(payload)
            rows.append({
                "t_ns": msg.monotonic_ns,
                "game": msg.game,
                "session": msg.session_id,
                "speed_kmh": msg.physics.speed_kmh,
                "gas": msg.physics.gas,
                "brake": msg.physics.brake,
                "gear": msg.physics.gear,
                "steer": msg.physics.steer,
                "rpm": msg.physics.engine_rpm,
                "ax_g": msg.physics.acc_g.x,
                "ay_g": msg.physics.acc_g.y,
                "az_g": msg.physics.acc_g.z,
                "lap": msg.graphics.completed_laps,
                "pos": msg.graphics.position,
            })
    df = pd.DataFrame(rows).sort_values("t_ns")
    table = pa.Table.from_pandas(df)
    pq.write_table(table, out_parquet)
    print(f"Wrote {out_parquet} with {len(df)} rows")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: recorder_reader.py telemetry_record.pb.gz out.parquet")
        sys.exit(2)
    main(Path(sys.argv[1]), Path(sys.argv[2]))
