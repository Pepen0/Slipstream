from __future__ import annotations

from typing import Any, AsyncIterator, Dict, Optional

from .models import QueryRequest
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
            points=[_query_point(row) for row in result.rows],
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
