from __future__ import annotations

import asyncio
import json
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Protocol

from .models import QueryRequest, SessionRecord, TelemetryRow

try:
    import asyncpg  # type: ignore
except ModuleNotFoundError:  # pragma: no cover
    asyncpg = None  # type: ignore


SCHEMA_SQL = """
CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE IF NOT EXISTS telemetry_sessions (
  session_id TEXT PRIMARY KEY,
  driver_id TEXT NOT NULL,
  track_id TEXT NOT NULL,
  car_id TEXT NOT NULL DEFAULT '',
  started_at TIMESTAMPTZ NOT NULL,
  closed_at TIMESTAMPTZ NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  tags JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS telemetry_frames (
  ts TIMESTAMPTZ NOT NULL,
  session_id TEXT NOT NULL,
  driver_id TEXT NOT NULL,
  track_id TEXT NOT NULL,
  monotonic_ns BIGINT NOT NULL,
  lap INTEGER NOT NULL,
  distance_norm DOUBLE PRECISION NOT NULL,
  speed_kmh DOUBLE PRECISION NOT NULL,
  throttle DOUBLE PRECISION NOT NULL,
  brake DOUBLE PRECISION NOT NULL,
  steer DOUBLE PRECISION NOT NULL,
  gear INTEGER NOT NULL,
  engine_rpm DOUBLE PRECISION NOT NULL,
  wheel_speed_delta_kmh DOUBLE PRECISION NULL,
  lateral_g DOUBLE PRECISION NULL,
  tags JSONB NOT NULL DEFAULT '{}'::jsonb,
  PRIMARY KEY (session_id, monotonic_ns)
);

SELECT create_hypertable(
  'telemetry_frames',
  'ts',
  partitioning_column => 'session_id',
  number_partitions => 8,
  if_not_exists => TRUE
);

CREATE INDEX IF NOT EXISTS idx_frames_session_time
  ON telemetry_frames (session_id, ts DESC);

CREATE INDEX IF NOT EXISTS idx_frames_track_driver_time
  ON telemetry_frames (track_id, driver_id, ts DESC);
"""


class TelemetryStore(Protocol):
    async def create_session(self, session: SessionRecord) -> SessionRecord:
        ...

    async def close_session(self, session_id: str, closed_at: datetime) -> SessionRecord:
        ...

    async def get_session(self, session_id: str) -> Optional[SessionRecord]:
        ...

    async def write_telemetry_batch(self, rows: List[TelemetryRow]) -> int:
        ...

    async def query_rows(self, request: QueryRequest) -> List[TelemetryRow]:
        ...


class TimescaleAsyncpgStore:
    """TimescaleDB-backed store used in production deployments."""

    def __init__(self, pool: "asyncpg.Pool") -> None:
        self._pool = pool

    @classmethod
    async def connect(cls, dsn: str, *, apply_schema: bool = False) -> "TimescaleAsyncpgStore":
        if asyncpg is None:
            raise RuntimeError("asyncpg is required for TimescaleAsyncpgStore")
        pool = await asyncpg.create_pool(dsn=dsn, min_size=1, max_size=8)
        store = cls(pool)
        if apply_schema:
            await store.apply_schema()
        return store

    async def close(self) -> None:
        await self._pool.close()

    async def apply_schema(self) -> None:
        async with self._pool.acquire() as conn:
            await conn.execute(SCHEMA_SQL)

    async def create_session(self, session: SessionRecord) -> SessionRecord:
        query = """
        INSERT INTO telemetry_sessions(session_id, driver_id, track_id, car_id, started_at, active, tags)
        VALUES($1, $2, $3, $4, $5, TRUE, $6::jsonb)
        ON CONFLICT (session_id) DO UPDATE SET
          driver_id = EXCLUDED.driver_id,
          track_id = EXCLUDED.track_id,
          car_id = EXCLUDED.car_id,
          tags = EXCLUDED.tags
        RETURNING session_id, driver_id, track_id, car_id, started_at, closed_at, active, tags
        """
        async with self._pool.acquire() as conn:
            row = await conn.fetchrow(
                query,
                session.session_id,
                session.driver_id,
                session.track_id,
                session.car_id,
                session.started_at,
                json.dumps(session.tags),
            )
        return _session_from_db_row(row)

    async def close_session(self, session_id: str, closed_at: datetime) -> SessionRecord:
        query = """
        INSERT INTO telemetry_sessions(session_id, driver_id, track_id, started_at, closed_at, active)
        VALUES($1, 'unknown', 'unknown', $2, $2, FALSE)
        ON CONFLICT (session_id) DO UPDATE SET
          closed_at = EXCLUDED.closed_at,
          active = FALSE
        RETURNING session_id, driver_id, track_id, car_id, started_at, closed_at, active, tags
        """
        async with self._pool.acquire() as conn:
            row = await conn.fetchrow(query, session_id, closed_at)
        return _session_from_db_row(row)

    async def get_session(self, session_id: str) -> Optional[SessionRecord]:
        query = """
        SELECT session_id, driver_id, track_id, car_id, started_at, closed_at, active, tags
        FROM telemetry_sessions
        WHERE session_id = $1
        """
        async with self._pool.acquire() as conn:
            row = await conn.fetchrow(query, session_id)
        if row is None:
            return None
        return _session_from_db_row(row)

    async def write_telemetry_batch(self, rows: List[TelemetryRow]) -> int:
        if not rows:
            return 0
        query = """
        INSERT INTO telemetry_frames(
          ts, session_id, driver_id, track_id, monotonic_ns, lap, distance_norm,
          speed_kmh, throttle, brake, steer, gear, engine_rpm, wheel_speed_delta_kmh, lateral_g, tags
        )
        VALUES(
          $1, $2, $3, $4, $5, $6, $7,
          $8, $9, $10, $11, $12, $13, $14, $15, $16::jsonb
        )
        ON CONFLICT (session_id, monotonic_ns) DO NOTHING
        """
        payload = [
            (
                row.ts,
                row.session_id,
                row.driver_id,
                row.track_id,
                row.monotonic_ns,
                row.lap,
                row.distance_norm,
                row.speed_kmh,
                row.throttle,
                row.brake,
                row.steer,
                row.gear,
                row.engine_rpm,
                row.wheel_speed_delta_kmh,
                row.lateral_g,
                json.dumps(row.tags),
            )
            for row in rows
        ]
        async with self._pool.acquire() as conn:
            await conn.executemany(query, payload)
        return len(rows)

    async def query_rows(self, request: QueryRequest) -> List[TelemetryRow]:
        conditions = ["session_id = $1"]
        args: List[object] = [request.session_id]
        arg_index = 2
        if request.start_monotonic_ns is not None:
            conditions.append(f"monotonic_ns >= ${arg_index}")
            args.append(request.start_monotonic_ns)
            arg_index += 1
        if request.end_monotonic_ns is not None:
            conditions.append(f"monotonic_ns <= ${arg_index}")
            args.append(request.end_monotonic_ns)
            arg_index += 1
        query = f"""
        SELECT ts, session_id, driver_id, track_id, monotonic_ns, lap, distance_norm,
               speed_kmh, throttle, brake, steer, gear, engine_rpm, wheel_speed_delta_kmh, lateral_g, tags
        FROM telemetry_frames
        WHERE {' AND '.join(conditions)}
        ORDER BY monotonic_ns ASC
        """
        async with self._pool.acquire() as conn:
            db_rows = await conn.fetch(query, *args)
        out: List[TelemetryRow] = []
        for row in db_rows:
            tags = row["tags"] or {}
            if isinstance(tags, str):
                tags = json.loads(tags)
            out.append(
                TelemetryRow(
                    ts=row["ts"],
                    session_id=row["session_id"],
                    driver_id=row["driver_id"],
                    track_id=row["track_id"],
                    monotonic_ns=row["monotonic_ns"],
                    lap=row["lap"],
                    distance_norm=row["distance_norm"],
                    speed_kmh=row["speed_kmh"],
                    throttle=row["throttle"],
                    brake=row["brake"],
                    steer=row["steer"],
                    gear=row["gear"],
                    engine_rpm=row["engine_rpm"],
                    wheel_speed_delta_kmh=row["wheel_speed_delta_kmh"],
                    lateral_g=row["lateral_g"],
                    tags=tags,
                ),
            )
        return out


class InMemoryTelemetryStore:
    """Test-friendly store that mirrors Timescale table semantics in memory."""

    def __init__(self) -> None:
        self._sessions: Dict[str, SessionRecord] = {}
        self._rows: List[TelemetryRow] = []
        self._lock = asyncio.Lock()

    async def create_session(self, session: SessionRecord) -> SessionRecord:
        async with self._lock:
            existing = self._sessions.get(session.session_id)
            if existing is not None:
                return existing
            self._sessions[session.session_id] = session
            return session

    async def close_session(self, session_id: str, closed_at: datetime) -> SessionRecord:
        async with self._lock:
            session = self._sessions.get(session_id)
            if session is None:
                session = SessionRecord(
                    session_id=session_id,
                    driver_id="unknown",
                    track_id="unknown",
                    started_at=closed_at,
                )
                self._sessions[session_id] = session
            session.active = False
            session.closed_at = closed_at
            return session

    async def get_session(self, session_id: str) -> Optional[SessionRecord]:
        async with self._lock:
            return self._sessions.get(session_id)

    async def write_telemetry_batch(self, rows: List[TelemetryRow]) -> int:
        if not rows:
            return 0
        async with self._lock:
            existing_keys = {(row.session_id, row.monotonic_ns) for row in self._rows}
            inserted = 0
            for row in rows:
                key = (row.session_id, row.monotonic_ns)
                if key in existing_keys:
                    continue
                existing_keys.add(key)
                self._rows.append(row)
                inserted += 1
            self._rows.sort(key=lambda row: (row.session_id, row.monotonic_ns))
            return inserted

    async def query_rows(self, request: QueryRequest) -> List[TelemetryRow]:
        async with self._lock:
            out = [row for row in self._rows if row.session_id == request.session_id]
            if request.start_monotonic_ns is not None:
                out = [row for row in out if row.monotonic_ns >= request.start_monotonic_ns]
            if request.end_monotonic_ns is not None:
                out = [row for row in out if row.monotonic_ns <= request.end_monotonic_ns]
            out.sort(key=lambda row: row.monotonic_ns)
            return out


def monotonic_to_session_ts(session: SessionRecord, monotonic_ns: int) -> datetime:
    base_ns = session.monotonic_origin_ns or monotonic_ns
    if session.monotonic_origin_ns is None:
        session.monotonic_origin_ns = monotonic_ns
    delta_ns = max(0, monotonic_ns - base_ns)
    return session.started_at + _duration_from_ns(delta_ns)


def _duration_from_ns(delta_ns: int):
    return timedelta(microseconds=delta_ns / 1000.0)


def _session_from_db_row(row: object) -> SessionRecord:
    tags = row["tags"] or {}
    if isinstance(tags, str):
        tags = json.loads(tags)
    return SessionRecord(
        session_id=row["session_id"],
        driver_id=row["driver_id"],
        track_id=row["track_id"],
        car_id=row["car_id"] or "",
        started_at=row["started_at"],
        closed_at=row["closed_at"],
        active=row["active"],
        tags=tags,
    )
