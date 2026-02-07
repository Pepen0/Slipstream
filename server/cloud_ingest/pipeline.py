from __future__ import annotations

import time
from collections import OrderedDict
from datetime import datetime, timezone
from types import SimpleNamespace
from typing import Dict, List, Optional, Tuple

from .batch_writer import AsyncBatchWriter
from .downsampling import clamp_query_hz, downsample_rows, normalize_distance
from .models import (
    AckStatus,
    IngestAck,
    LapSliceRequest,
    OverlayPoint,
    OverlayRequest,
    OverlayResult,
    QueryRequest,
    QueryResult,
    SessionListRequest,
    SessionRecord,
    SessionSummary,
    TelemetryRow,
)
from .storage import TelemetryStore, monotonic_to_session_ts
from .validation import validate_frame


class TelemetryIngestionPipeline:
    def __init__(
        self,
        store: TelemetryStore,
        writer: AsyncBatchWriter,
        *,
        query_cache_ttl_s: float = 5.0,
        query_cache_entries: int = 512,
    ) -> None:
        self._store = store
        self._writer = writer
        self._session_cache: Dict[str, SessionRecord] = {}
        self._query_cache = _QueryCache(
            ttl_s=max(0.1, query_cache_ttl_s),
            max_entries=max(32, query_cache_entries),
        )

    async def start(self) -> None:
        await self._writer.start()

    async def stop(self) -> None:
        await self._writer.stop()

    async def create_session(
        self,
        *,
        session_id: str,
        driver_id: str,
        track_id: str,
        car_id: str = "",
        started_at_ns: Optional[int] = None,
        tags: Optional[Dict[str, str]] = None,
    ) -> SessionRecord:
        started_at = _utc_from_ns(started_at_ns) if started_at_ns else datetime.now(timezone.utc)
        session = SessionRecord(
            session_id=session_id,
            driver_id=driver_id or "unknown",
            track_id=track_id or "unknown",
            car_id=car_id or "",
            started_at=started_at,
            tags=tags or {},
        )
        stored = await self._store.create_session(session)
        self._session_cache[stored.session_id] = stored
        self._query_cache.clear()
        return stored

    async def close_session(self, session_id: str, *, closed_at_ns: Optional[int] = None) -> SessionRecord:
        closed_at = _utc_from_ns(closed_at_ns) if closed_at_ns else datetime.now(timezone.utc)
        session = await self._store.close_session(session_id, closed_at)
        self._session_cache[session_id] = session
        self._query_cache.clear()
        return session

    async def ingest_frame(self, frame: object) -> IngestAck:
        errors = validate_frame(frame)
        monotonic_ns = int(getattr(frame, "monotonic_ns", 0))
        if errors:
            return IngestAck(
                last_monotonic_ns=monotonic_ns,
                status=AckStatus.ACK_INVALID,
                message="; ".join(errors),
                buffered_frames=self._writer.pending,
            )

        session_id = getattr(frame, "session_id")
        session = await self._ensure_session(session_id)
        row = self._frame_to_row(frame, session)

        enqueued = await self._writer.enqueue(row)
        if not enqueued:
            return IngestAck(
                last_monotonic_ns=monotonic_ns,
                status=AckStatus.ACK_DROPPED,
                message="writer queue full; frame dropped",
                buffered_frames=self._writer.pending,
            )
        if self._writer.is_backpressured():
            return IngestAck(
                last_monotonic_ns=monotonic_ns,
                status=AckStatus.ACK_BACKPRESSURE,
                message="server backpressure active",
                buffered_frames=self._writer.pending,
            )
        self._query_cache.invalidate_session(session_id)
        return IngestAck(
            last_monotonic_ns=monotonic_ns,
            status=AckStatus.ACK_OK,
            message="ok",
            buffered_frames=self._writer.pending,
        )

    async def query_session(self, request: QueryRequest) -> QueryResult:
        cache_key = (
            "query_session",
            request.session_id,
            request.start_monotonic_ns,
            request.end_monotonic_ns,
            clamp_query_hz(request.target_hz),
            bool(request.normalize_distance_axis),
        )
        cached = self._query_cache.get(cache_key)
        if isinstance(cached, QueryResult):
            return _as_cached_query_result(cached)

        rows = await self._store.query_rows(request)
        source_count = len(rows)
        downsampled = downsample_rows(rows, clamp_query_hz(request.target_hz))
        if request.normalize_distance_axis:
            downsampled = normalize_distance(downsampled)
        result = QueryResult(
            rows=downsampled,
            source_count=source_count,
            returned_count=len(downsampled),
        )
        self._query_cache.put(cache_key, result)
        return result

    async def query_lap_slice(self, request: LapSliceRequest) -> QueryResult:
        cache_key = (
            "query_lap_slice",
            request.session_id,
            request.lap,
            _float_key(request.start_distance_norm),
            _float_key(request.end_distance_norm),
            clamp_query_hz(request.target_hz),
            bool(request.normalize_distance_axis),
        )
        cached = self._query_cache.get(cache_key)
        if isinstance(cached, QueryResult):
            return _as_cached_query_result(cached)

        rows = await self._store.query_lap_rows(request)
        source_count = len(rows)
        downsampled = downsample_rows(rows, clamp_query_hz(request.target_hz))
        if request.normalize_distance_axis:
            downsampled = normalize_distance(downsampled)
        result = QueryResult(
            rows=downsampled,
            source_count=source_count,
            returned_count=len(downsampled),
        )
        self._query_cache.put(cache_key, result)
        return result

    async def get_lap_overlay(self, request: OverlayRequest) -> OverlayResult:
        started = time.perf_counter()
        cache_key = (
            "lap_overlay",
            request.base_session_id,
            request.base_lap,
            request.compare_session_id,
            request.compare_lap,
            _float_key(request.start_distance_norm),
            _float_key(request.end_distance_norm),
            clamp_query_hz(request.target_hz),
        )
        cached = self._query_cache.get(cache_key)
        if isinstance(cached, OverlayResult):
            return _as_cached_overlay_result(cached, started)

        base_rows = await self._store.query_lap_rows(
            LapSliceRequest(
                session_id=request.base_session_id,
                lap=request.base_lap,
                start_distance_norm=request.start_distance_norm,
                end_distance_norm=request.end_distance_norm,
                target_hz=request.target_hz,
                normalize_distance_axis=True,
            ),
        )
        compare_rows = await self._store.query_lap_rows(
            LapSliceRequest(
                session_id=request.compare_session_id,
                lap=request.compare_lap,
                start_distance_norm=request.start_distance_norm,
                end_distance_norm=request.end_distance_norm,
                target_hz=request.target_hz,
                normalize_distance_axis=True,
            ),
        )
        base_source_count = len(base_rows)
        compare_source_count = len(compare_rows)

        base_downsampled = normalize_distance(
            downsample_rows(base_rows, clamp_query_hz(request.target_hz)),
        )
        compare_downsampled = normalize_distance(
            downsample_rows(compare_rows, clamp_query_hz(request.target_hz)),
        )
        points = _build_overlay_points(
            sorted(base_downsampled, key=lambda row: row.distance_norm),
            sorted(compare_downsampled, key=lambda row: row.distance_norm),
        )
        result = OverlayResult(
            points=points,
            base_source_count=base_source_count,
            compare_source_count=compare_source_count,
            returned_count=len(points),
            query_time_ms=max(0, int((time.perf_counter() - started) * 1000.0)),
            cached=False,
        )
        self._query_cache.put(cache_key, result)
        return result

    async def list_sessions(self, request: SessionListRequest) -> List[SessionRecord]:
        cache_key = (
            "list_sessions",
            request.driver_id,
            request.track_id,
            request.car_id,
            bool(request.active_only),
            request.started_after_ns,
            request.started_before_ns,
            max(1, min(request.limit or 100, 1000)),
        )
        cached = self._query_cache.get(cache_key)
        if isinstance(cached, list):
            return list(cached)
        sessions = await self._store.list_sessions(request)
        self._query_cache.put(cache_key, list(sessions))
        return sessions

    async def get_session_summary(self, session_id: str) -> SessionSummary:
        cache_key = ("session_summary", session_id)
        cached = self._query_cache.get(cache_key)
        if isinstance(cached, SessionSummary):
            return cached
        summary = await self._store.get_session_summary(session_id)
        self._query_cache.put(cache_key, summary)
        return summary

    async def _ensure_session(self, session_id: str) -> SessionRecord:
        session = self._session_cache.get(session_id)
        if session is not None:
            return session
        session = await self._store.get_session(session_id)
        if session is None:
            session = await self.create_session(
                session_id=session_id,
                driver_id="unknown",
                track_id="unknown",
            )
        self._session_cache[session_id] = session
        return session

    def _frame_to_row(self, frame: object, session: SessionRecord) -> TelemetryRow:
        physics = getattr(frame, "physics", SimpleNamespace())
        graphics = getattr(frame, "graphics", SimpleNamespace())
        monotonic_ns = int(getattr(frame, "monotonic_ns"))
        lap = int(getattr(graphics, "completed_laps", 0))
        normalized_car_pos = float(getattr(graphics, "normalized_car_pos", 0.0))
        distance_norm = float(lap) + max(0.0, min(1.0, normalized_car_pos))
        speed_kmh = float(getattr(physics, "speed_kmh", 0.0))
        throttle = float(getattr(physics, "gas", 0.0))
        brake = float(getattr(physics, "brake", 0.0))
        steer = float(getattr(physics, "steer", 0.0))
        gear = int(getattr(physics, "gear", 0))
        engine_rpm = float(getattr(physics, "engine_rpm", 0.0))
        wheel_delta = _wheel_speed_delta_kmh(physics)
        lateral_g = _lateral_g_from_acc(physics)
        ts = monotonic_to_session_ts(session, monotonic_ns)
        return TelemetryRow(
            session_id=session.session_id,
            driver_id=session.driver_id,
            track_id=session.track_id,
            ts=ts,
            monotonic_ns=monotonic_ns,
            lap=lap,
            distance_norm=distance_norm,
            speed_kmh=speed_kmh,
            throttle=throttle,
            brake=brake,
            steer=steer,
            gear=gear,
            engine_rpm=engine_rpm,
            wheel_speed_delta_kmh=wheel_delta,
            lateral_g=lateral_g,
            tags=session.tags,
        )


class _QueryCache:
    def __init__(self, *, ttl_s: float, max_entries: int) -> None:
        self._ttl_s = ttl_s
        self._max_entries = max_entries
        self._entries: OrderedDict[Tuple[object, ...], Tuple[float, object]] = OrderedDict()

    def get(self, key: Tuple[object, ...]) -> object | None:
        now = time.monotonic()
        entry = self._entries.get(key)
        if entry is None:
            return None
        expires_at, value = entry
        if expires_at < now:
            self._entries.pop(key, None)
            return None
        self._entries.move_to_end(key)
        return value

    def put(self, key: Tuple[object, ...], value: object) -> None:
        now = time.monotonic()
        self._entries[key] = (now + self._ttl_s, value)
        self._entries.move_to_end(key)
        while len(self._entries) > self._max_entries:
            self._entries.popitem(last=False)

    def invalidate_session(self, session_id: str) -> None:
        to_delete = [key for key in self._entries if session_id in key]
        for key in to_delete:
            self._entries.pop(key, None)

    def clear(self) -> None:
        self._entries.clear()


def _as_cached_query_result(result: QueryResult) -> QueryResult:
    return QueryResult(
        rows=list(result.rows),
        source_count=result.source_count,
        returned_count=result.returned_count,
        cached=True,
    )


def _as_cached_overlay_result(result: OverlayResult, started: float) -> OverlayResult:
    return OverlayResult(
        points=list(result.points),
        base_source_count=result.base_source_count,
        compare_source_count=result.compare_source_count,
        returned_count=result.returned_count,
        query_time_ms=max(0, int((time.perf_counter() - started) * 1000.0)),
        cached=True,
    )


def _build_overlay_points(base_rows: List[TelemetryRow], compare_rows: List[TelemetryRow]) -> List[OverlayPoint]:
    if not base_rows or not compare_rows:
        return []

    points: List[OverlayPoint] = []
    compare_idx = 0
    last_compare_index = len(compare_rows) - 1

    for base_row in base_rows:
        target_distance = base_row.distance_norm
        while (
            compare_idx < last_compare_index
            and compare_rows[compare_idx + 1].distance_norm <= target_distance
        ):
            compare_idx += 1

        compare_row = compare_rows[compare_idx]
        if compare_idx < last_compare_index:
            next_row = compare_rows[compare_idx + 1]
            if abs(next_row.distance_norm - target_distance) < abs(
                compare_row.distance_norm - target_distance,
            ):
                compare_row = next_row

        points.append(
            OverlayPoint(
                distance_norm=target_distance,
                base_speed_kmh=base_row.speed_kmh,
                compare_speed_kmh=compare_row.speed_kmh,
                speed_delta_kmh=base_row.speed_kmh - compare_row.speed_kmh,
                base_throttle=base_row.throttle,
                compare_throttle=compare_row.throttle,
                throttle_delta=base_row.throttle - compare_row.throttle,
                base_brake=base_row.brake,
                compare_brake=compare_row.brake,
                brake_delta=base_row.brake - compare_row.brake,
                base_steer=base_row.steer,
                compare_steer=compare_row.steer,
                steer_delta=base_row.steer - compare_row.steer,
            ),
        )
    return points


def _float_key(value: float | None) -> object:
    if value is None:
        return None
    return round(float(value), 6)


def _wheel_speed_delta_kmh(physics: object) -> Optional[float]:
    tyre_slip = getattr(physics, "tyre_slip", None)
    if tyre_slip is None:
        return None
    values = []
    for attr in ("fl", "fr", "rl", "rr"):
        value = getattr(tyre_slip, attr, None)
        if isinstance(value, (int, float)):
            values.append(abs(float(value)))
    if not values:
        return None
    return max(values) * 6.0


def _lateral_g_from_acc(physics: object) -> Optional[float]:
    acc = getattr(physics, "acc_g", None)
    if acc is None:
        return None
    value = getattr(acc, "y", None)
    if isinstance(value, (int, float)):
        return abs(float(value))
    return None


def _utc_from_ns(ns: int) -> datetime:
    return datetime.fromtimestamp(max(0, ns) / 1_000_000_000, tz=timezone.utc)


def utc_now_ns() -> int:
    return int(time.time() * 1_000_000_000)
