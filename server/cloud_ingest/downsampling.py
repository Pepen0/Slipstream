from __future__ import annotations

from dataclasses import replace
from typing import List

from .models import TelemetryRow


def clamp_query_hz(target_hz: int) -> int:
    if target_hz <= 0:
        return 15
    return max(10, min(20, target_hz))


def downsample_rows(rows: List[TelemetryRow], target_hz: int) -> List[TelemetryRow]:
    if len(rows) <= 2:
        return list(rows)
    hz = clamp_query_hz(target_hz)
    bucket_ns = int(1_000_000_000 / hz)
    if bucket_ns <= 0:
        return list(rows)

    sampled: List[TelemetryRow] = []
    last_bucket = None
    for row in rows:
        bucket = row.monotonic_ns // bucket_ns
        if bucket != last_bucket:
            sampled.append(row)
            last_bucket = bucket
    return sampled


def normalize_distance(rows: List[TelemetryRow]) -> List[TelemetryRow]:
    if len(rows) <= 1:
        return list(rows)
    first = rows[0].distance_norm
    last = rows[-1].distance_norm
    span = last - first
    if span <= 1e-9:
        return [replace(row, distance_norm=0.0) for row in rows]
    out: List[TelemetryRow] = []
    for row in rows:
        normalized = (row.distance_norm - first) / span
        out.append(replace(row, distance_norm=max(0.0, min(1.0, normalized))))
    return out
