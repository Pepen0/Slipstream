from __future__ import annotations

from typing import Any, AsyncIterator

from .models import LapSliceRequest, OverlayRequest, QueryRequest, SessionListRequest, SessionSummary
from .pipeline import TelemetryIngestionPipeline, utc_now_ns

try:
    import telemetry.v1.telemetry_pb2 as pb  # type: ignore
    import telemetry.v1.telemetry_pb2_grpc as rpc  # type: ignore
except ModuleNotFoundError:  # pragma: no cover - validated in integration environments
    pb = None  # type: ignore
    rpc = None  # type: ignore


def _ensure_stubs() -> None:
    if pb is None or rpc is None:
        raise RuntimeError(
            "Telemetry protobuf stubs are missing. Run scripts/gen_proto_py.sh first.",
        )


def _ack_to_proto(ack: Any) -> Any:
    return pb.StreamAck(
        last_monotonic_ns=ack.last_monotonic_ns,
        status=getattr(pb.StreamAck, ack.status.value),
        message=ack.message,
        buffered_frames=ack.buffered_frames,
    )


class TelemetryIngestGrpcService:
    def __init__(self, pipeline: TelemetryIngestionPipeline) -> None:
        self._pipeline = pipeline

    async def StreamFrames(
        self,
        request_iterator: AsyncIterator[Any],
        context: Any,
    ) -> AsyncIterator[Any]:
        _ensure_stubs()
        async for frame in request_iterator:
            ack = await self._pipeline.ingest_frame(frame)
            yield _ack_to_proto(ack)

    async def CreateSession(self, request: Any, context: Any) -> Any:
        _ensure_stubs()
        session = await self._pipeline.create_session(
            session_id=request.session_id,
            driver_id=request.driver_id,
            track_id=request.track_id,
            car_id=request.car_id,
            started_at_ns=request.started_at_ns or utc_now_ns(),
            tags=dict(request.tags),
        )
        return pb.CreateSessionResponse(
            ok=True,
            message="created",
            session=_session_info(session),
        )

    async def CloseSession(self, request: Any, context: Any) -> Any:
        _ensure_stubs()
        session = await self._pipeline.close_session(
            request.session_id,
            closed_at_ns=request.closed_at_ns or utc_now_ns(),
        )
        return pb.CloseSessionResponse(ok=True, message="closed", session=_session_info(session))

    async def QuerySessionTelemetry(self, request: Any, context: Any) -> Any:
        _ensure_stubs()
        result = await self._pipeline.query_session(
            QueryRequest(
                session_id=request.session_id,
                start_monotonic_ns=request.start_monotonic_ns or None,
                end_monotonic_ns=request.end_monotonic_ns or None,
                target_hz=request.target_hz or 15,
                normalize_distance_axis=request.normalize_distance_axis,
            ),
        )
        return pb.QuerySessionTelemetryResponse(
            source_count=result.source_count,
            returned_count=result.returned_count,
            cached=result.cached,
            points=[_query_point(row) for row in result.rows],
        )

    async def QueryLapSlice(self, request: Any, context: Any) -> Any:
        _ensure_stubs()
        result = await self._pipeline.query_lap_slice(
            LapSliceRequest(
                session_id=request.session_id,
                lap=int(request.lap),
                start_distance_norm=_distance_or_none(
                    getattr(request, "has_start_distance_norm", False),
                    getattr(request, "start_distance_norm", 0.0),
                ),
                end_distance_norm=_distance_or_none(
                    getattr(request, "has_end_distance_norm", False),
                    getattr(request, "end_distance_norm", 0.0),
                ),
                target_hz=getattr(request, "target_hz", 15) or 15,
                normalize_distance_axis=getattr(request, "normalize_distance_axis", True),
            ),
        )
        return pb.QueryLapSliceResponse(
            source_count=result.source_count,
            returned_count=result.returned_count,
            cached=result.cached,
            points=[_query_point(row) for row in result.rows],
        )

    async def GetLapOverlay(self, request: Any, context: Any) -> Any:
        _ensure_stubs()
        result = await self._pipeline.get_lap_overlay(
            OverlayRequest(
                base_session_id=request.base_session_id,
                base_lap=int(request.base_lap),
                compare_session_id=request.compare_session_id,
                compare_lap=int(request.compare_lap),
                start_distance_norm=_distance_or_none(
                    getattr(request, "has_start_distance_norm", False),
                    getattr(request, "start_distance_norm", 0.0),
                ),
                end_distance_norm=_distance_or_none(
                    getattr(request, "has_end_distance_norm", False),
                    getattr(request, "end_distance_norm", 0.0),
                ),
                target_hz=getattr(request, "target_hz", 15) or 15,
            ),
        )
        return pb.GetLapOverlayResponse(
            base_source_count=result.base_source_count,
            compare_source_count=result.compare_source_count,
            returned_count=result.returned_count,
            query_time_ms=result.query_time_ms,
            cached=result.cached,
            points=[_overlay_point(point) for point in result.points],
        )

    async def ListSessions(self, request: Any, context: Any) -> Any:
        _ensure_stubs()
        sessions = await self._pipeline.list_sessions(
            SessionListRequest(
                driver_id=getattr(request, "driver_id", ""),
                track_id=getattr(request, "track_id", ""),
                car_id=getattr(request, "car_id", ""),
                active_only=bool(getattr(request, "active_only", False)),
                started_after_ns=(getattr(request, "started_after_ns", 0) or None),
                started_before_ns=(getattr(request, "started_before_ns", 0) or None),
                limit=(getattr(request, "limit", 0) or 100),
            ),
        )
        return pb.ListSessionsResponse(
            sessions=[_session_info(session) for session in sessions],
            total_count=len(sessions),
        )

    async def GetSessionSummary(self, request: Any, context: Any) -> Any:
        _ensure_stubs()
        try:
            summary = await self._pipeline.get_session_summary(request.session_id)
        except KeyError:
            return pb.GetSessionSummaryResponse(
                ok=False,
                message="session not found",
            )
        return pb.GetSessionSummaryResponse(
            ok=True,
            message="ok",
            summary=_session_summary(summary, include_laps=getattr(request, "include_laps", True)),
        )


def register_grpc(server: Any, pipeline: TelemetryIngestionPipeline) -> None:
    _ensure_stubs()
    rpc.add_TelemetryIngestServicer_to_server(TelemetryIngestGrpcService(pipeline), server)


def _session_info(session: Any) -> Any:
    return pb.SessionInfo(
        session_id=session.session_id,
        driver_id=session.driver_id,
        track_id=session.track_id,
        car_id=session.car_id,
        started_at_ns=int(session.started_at.timestamp() * 1_000_000_000),
        closed_at_ns=(
            int(session.closed_at.timestamp() * 1_000_000_000)
            if session.closed_at is not None
            else 0
        ),
        active=session.active,
        tags=session.tags,
    )


def _query_point(row: Any) -> Any:
    return pb.QueryPoint(
        session_id=row.session_id,
        monotonic_ns=row.monotonic_ns,
        timestamp_ns=int(row.ts.timestamp() * 1_000_000_000),
        lap=row.lap,
        distance_norm=row.distance_norm,
        speed_kmh=row.speed_kmh,
        throttle=row.throttle,
        brake=row.brake,
        steer=row.steer,
        gear=row.gear,
        engine_rpm=row.engine_rpm,
        wheel_speed_delta_kmh=row.wheel_speed_delta_kmh or 0.0,
        lateral_g=row.lateral_g or 0.0,
    )


def _overlay_point(point: Any) -> Any:
    return pb.OverlayPoint(
        distance_norm=point.distance_norm,
        base_speed_kmh=point.base_speed_kmh,
        compare_speed_kmh=point.compare_speed_kmh,
        speed_delta_kmh=point.speed_delta_kmh,
        base_throttle=point.base_throttle,
        compare_throttle=point.compare_throttle,
        throttle_delta=point.throttle_delta,
        base_brake=point.base_brake,
        compare_brake=point.compare_brake,
        brake_delta=point.brake_delta,
        base_steer=point.base_steer,
        compare_steer=point.compare_steer,
        steer_delta=point.steer_delta,
    )


def _session_summary(summary: SessionSummary, *, include_laps: bool) -> Any:
    payload = {
        "session": _session_info(summary.session),
        "point_count": summary.point_count,
        "lap_count": summary.lap_count,
        "laps": [_lap_summary(lap) for lap in summary.laps] if include_laps else [],
    }
    if summary.best_lap is not None:
        payload["best_lap"] = _lap_summary(summary.best_lap)
    return pb.SessionSummary(**payload)


def _lap_summary(lap: Any) -> Any:
    return pb.LapSummary(
        lap=lap.lap,
        point_count=lap.point_count,
        lap_time_s=lap.lap_time_s,
        avg_speed_kmh=lap.avg_speed_kmh,
        peak_speed_kmh=lap.peak_speed_kmh,
    )


def _distance_or_none(has_value: bool, value: float) -> float | None:
    if not has_value:
        return None
    return float(value)
