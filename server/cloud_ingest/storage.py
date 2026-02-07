from __future__ import annotations

import asyncio
import json
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Protocol, Tuple

from .models import (
    LapSliceRequest,
    LapSummary,
    QueryRequest,
    SessionListRequest,
    SessionRecord,
    SessionSummary,
    TelemetryRow,
)

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

CREATE INDEX IF NOT EXISTS idx_frames_session_lap_time
  ON telemetry_frames (session_id, lap, monotonic_ns);

CREATE MATERIALIZED VIEW IF NOT EXISTS telemetry_lap_summary_cagg
WITH (timescaledb.continuous) AS
SELECT
  time_bucket('1 day', ts) AS bucket,
  session_id,
  driver_id,
  track_id,
  lap,
  COUNT(*)::BIGINT AS point_count,
  MIN(ts) AS lap_start_ts,
  MAX(ts) AS lap_end_ts,
  EXTRACT(EPOCH FROM (MAX(ts) - MIN(ts)))::DOUBLE PRECISION AS lap_time_s,
  AVG(speed_kmh)::DOUBLE PRECISION AS avg_speed_kmh,
  MAX(speed_kmh)::DOUBLE PRECISION AS peak_speed_kmh
FROM telemetry_frames
GROUP BY bucket, session_id, driver_id, track_id, lap
WITH NO DATA;

CREATE INDEX IF NOT EXISTS idx_lap_cagg_session_lap
  ON telemetry_lap_summary_cagg (session_id, lap);

CREATE INDEX IF NOT EXISTS idx_lap_cagg_track_driver_best
  ON telemetry_lap_summary_cagg (track_id, driver_id, lap_time_s);

SELECT add_continuous_aggregate_policy(
  'telemetry_lap_summary_cagg',
  start_offset => INTERVAL '7 days',
  end_offset => INTERVAL '10 seconds',
  schedule_interval => INTERVAL '30 seconds',
  if_not_exists => TRUE
);
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

    async def query_lap_rows(self, request: LapSliceRequest) -> List[TelemetryRow]:
        ...

    async def list_sessions(self, request: SessionListRequest) -> List[SessionRecord]:
        ...

    async def get_session_summary(self, session_id: str) -> SessionSummary:
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
        return [_telemetry_row_from_db_row(row) for row in db_rows]

    async def query_lap_rows(self, request: LapSliceRequest) -> List[TelemetryRow]:
        conditions = ["session_id = $1", "lap = $2"]
        args: List[object] = [request.session_id, request.lap]
        arg_index = 3
        if request.start_distance_norm is not None:
            conditions.append(f"distance_norm >= ${arg_index}")
            args.append(request.start_distance_norm)
            arg_index += 1
        if request.end_distance_norm is not None:
            conditions.append(f"distance_norm <= ${arg_index}")
            args.append(request.end_distance_norm)
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
        return [_telemetry_row_from_db_row(row) for row in db_rows]

    async def list_sessions(self, request: SessionListRequest) -> List[SessionRecord]:
        conditions = []
        args: List[object] = []
        arg_index = 1

        if request.driver_id:
            conditions.append(f"driver_id = ${arg_index}")
            args.append(request.driver_id)
            arg_index += 1
        if request.track_id:
            conditions.append(f"track_id = ${arg_index}")
            args.append(request.track_id)
            arg_index += 1
        if request.car_id:
            conditions.append(f"car_id = ${arg_index}")
            args.append(request.car_id)
            arg_index += 1
        if request.active_only:
            conditions.append("active = TRUE")
        if request.started_after_ns is not None:
            conditions.append(f"started_at >= ${arg_index}")
            args.append(_utc_from_ns(request.started_after_ns))
            arg_index += 1
        if request.started_before_ns is not None:
            conditions.append(f"started_at <= ${arg_index}")
            args.append(_utc_from_ns(request.started_before_ns))
            arg_index += 1

        where_clause = ""
        if conditions:
            where_clause = f"WHERE {' AND '.join(conditions)}"

        limit = max(1, min(request.limit or 100, 1000))
        query = f"""
        SELECT session_id, driver_id, track_id, car_id, started_at, closed_at, active, tags
        FROM telemetry_sessions
        {where_clause}
        ORDER BY started_at DESC
        LIMIT {limit}
        """
        async with self._pool.acquire() as conn:
            rows = await conn.fetch(query, *args)
        return [_session_from_db_row(row) for row in rows]

    async def get_session_summary(self, session_id: str) -> SessionSummary:
        session = await self.get_session(session_id)
        if session is None:
            raise KeyError(f"session not found: {session_id}")

        async with self._pool.acquire() as conn:
            counts = await conn.fetchrow(
                """
                SELECT COUNT(*)::BIGINT AS point_count, COUNT(DISTINCT lap)::BIGINT AS lap_count
                FROM telemetry_frames
                WHERE session_id = $1
                """,
                session_id,
            )
            lap_rows = await conn.fetch(
                """
                SELECT lap,
                       SUM(point_count)::BIGINT AS point_count,
                       MIN(lap_time_s)::DOUBLE PRECISION AS lap_time_s,
                       AVG(avg_speed_kmh)::DOUBLE PRECISION AS avg_speed_kmh,
                       MAX(peak_speed_kmh)::DOUBLE PRECISION AS peak_speed_kmh
                FROM telemetry_lap_summary_cagg
                WHERE session_id = $1
                GROUP BY lap
                ORDER BY lap ASC
                """,
                session_id,
            )
            # Continuous aggregates can lag slightly; fallback to raw query if empty.
            if not lap_rows:
                lap_rows = await conn.fetch(
                    """
                    SELECT lap,
                           COUNT(*)::BIGINT AS point_count,
                           EXTRACT(EPOCH FROM (MAX(ts) - MIN(ts)))::DOUBLE PRECISION AS lap_time_s,
                           AVG(speed_kmh)::DOUBLE PRECISION AS avg_speed_kmh,
                           MAX(speed_kmh)::DOUBLE PRECISION AS peak_speed_kmh
                    FROM telemetry_frames
                    WHERE session_id = $1
                    GROUP BY lap
                    ORDER BY lap ASC
                    """,
                    session_id,
                )

        laps = [_lap_summary_from_db_row(row) for row in lap_rows]
        return SessionSummary(
            session=session,
            point_count=int(counts["point_count"] if counts else 0),
            lap_count=int(counts["lap_count"] if counts else 0),
            best_lap=_best_lap(laps),
            laps=laps,
        )


class InMemoryTelemetryStore:
    """Test-friendly store that mirrors Timescale table semantics in memory."""

    def __init__(self) -> None:
        self._sessions: Dict[str, SessionRecord] = {}
        self._rows: List[TelemetryRow] = []
        self._rows_by_session: Dict[str, List[TelemetryRow]] = {}
        self._row_keys: set[Tuple[str, int]] = set()
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
            inserted = 0
            for row in rows:
                key = (row.session_id, row.monotonic_ns)
                if key in self._row_keys:
                    continue
                self._row_keys.add(key)
                self._rows.append(row)
                self._rows_by_session.setdefault(row.session_id, []).append(row)
                inserted += 1
            self._rows.sort(key=lambda row: (row.session_id, row.monotonic_ns))
            for session_id in {row.session_id for row in rows}:
                session_rows = self._rows_by_session.get(session_id, [])
                session_rows.sort(key=lambda row: row.monotonic_ns)
            return inserted

    async def query_rows(self, request: QueryRequest) -> List[TelemetryRow]:
        async with self._lock:
            out = list(self._rows_by_session.get(request.session_id, []))
            if request.start_monotonic_ns is not None:
                out = [row for row in out if row.monotonic_ns >= request.start_monotonic_ns]
            if request.end_monotonic_ns is not None:
                out = [row for row in out if row.monotonic_ns <= request.end_monotonic_ns]
            out.sort(key=lambda row: row.monotonic_ns)
            return out

    async def query_lap_rows(self, request: LapSliceRequest) -> List[TelemetryRow]:
        async with self._lock:
            out = [
                row
                for row in self._rows_by_session.get(request.session_id, [])
                if row.lap == request.lap
            ]
            if request.start_distance_norm is not None:
                out = [row for row in out if row.distance_norm >= request.start_distance_norm]
            if request.end_distance_norm is not None:
                out = [row for row in out if row.distance_norm <= request.end_distance_norm]
            out.sort(key=lambda row: row.monotonic_ns)
            return out

    async def list_sessions(self, request: SessionListRequest) -> List[SessionRecord]:
        async with self._lock:
            sessions = list(self._sessions.values())
            if request.driver_id:
                sessions = [session for session in sessions if session.driver_id == request.driver_id]
            if request.track_id:
                sessions = [session for session in sessions if session.track_id == request.track_id]
            if request.car_id:
                sessions = [session for session in sessions if session.car_id == request.car_id]
            if request.active_only:
                sessions = [session for session in sessions if session.active]
            if request.started_after_ns is not None:
                after = _utc_from_ns(request.started_after_ns)
                sessions = [session for session in sessions if session.started_at >= after]
            if request.started_before_ns is not None:
                before = _utc_from_ns(request.started_before_ns)
                sessions = [session for session in sessions if session.started_at <= before]
            sessions.sort(key=lambda session: session.started_at, reverse=True)
            limit = max(1, min(request.limit or 100, 1000))
            return sessions[:limit]

    async def get_session_summary(self, session_id: str) -> SessionSummary:
        async with self._lock:
            session = self._sessions.get(session_id)
            if session is None:
                raise KeyError(f"session not found: {session_id}")
            rows = list(self._rows_by_session.get(session_id, []))
            rows.sort(key=lambda row: row.monotonic_ns)

        laps = _build_lap_summaries(rows)
        unique_laps = {row.lap for row in rows}
        return SessionSummary(
            session=session,
            point_count=len(rows),
            lap_count=len(unique_laps),
            best_lap=_best_lap(laps),
            laps=laps,
        )


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


def _telemetry_row_from_db_row(row: object) -> TelemetryRow:
    tags = row["tags"] or {}
    if isinstance(tags, str):
        tags = json.loads(tags)
    return TelemetryRow(
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
    )


def _lap_summary_from_db_row(row: object) -> LapSummary:
    return LapSummary(
        lap=int(row["lap"]),
        point_count=int(row["point_count"] or 0),
        lap_time_s=float(row["lap_time_s"] or 0.0),
        avg_speed_kmh=float(row["avg_speed_kmh"] or 0.0),
        peak_speed_kmh=float(row["peak_speed_kmh"] or 0.0),
    )


def _build_lap_summaries(rows: List[TelemetryRow]) -> List[LapSummary]:
    by_lap: Dict[int, List[TelemetryRow]] = {}
    for row in rows:
        by_lap.setdefault(row.lap, []).append(row)

    summaries: List[LapSummary] = []
    for lap, lap_rows in by_lap.items():
        lap_rows.sort(key=lambda row: row.monotonic_ns)
        lap_time_s = 0.0
        if len(lap_rows) >= 2:
            lap_time_s = (lap_rows[-1].monotonic_ns - lap_rows[0].monotonic_ns) / 1_000_000_000.0
        speeds = [row.speed_kmh for row in lap_rows]
        avg_speed = (sum(speeds) / len(speeds)) if speeds else 0.0
        peak_speed = max(speeds) if speeds else 0.0
        summaries.append(
            LapSummary(
                lap=lap,
                point_count=len(lap_rows),
                lap_time_s=lap_time_s,
                avg_speed_kmh=avg_speed,
                peak_speed_kmh=peak_speed,
            ),
        )
    summaries.sort(key=lambda summary: summary.lap)
    return summaries


def _best_lap(laps: List[LapSummary]) -> Optional[LapSummary]:
    valid = [lap for lap in laps if lap.lap_time_s > 0.0]
    if not valid:
        return None
    return min(valid, key=lambda lap: lap.lap_time_s)


def _utc_from_ns(ns: int) -> datetime:
    return datetime.fromtimestamp(max(0, ns) / 1_000_000_000, tz=timezone.utc)
