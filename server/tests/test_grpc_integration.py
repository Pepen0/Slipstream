from __future__ import annotations

import asyncio
import unittest
from typing import AsyncIterator

from server.cloud_ingest.batch_writer import AsyncBatchWriter
from server.cloud_ingest.pipeline import TelemetryIngestionPipeline
from server.cloud_ingest.storage import InMemoryTelemetryStore

try:
    import grpc
    import telemetry.v1.telemetry_pb2 as pb  # type: ignore
    import telemetry.v1.telemetry_pb2_grpc as rpc  # type: ignore

    from server.cloud_ingest.grpc_service import register_grpc

except ModuleNotFoundError:  # pragma: no cover - exercised in CI with grpc deps
    grpc = None  # type: ignore
    pb = None  # type: ignore
    rpc = None  # type: ignore
    register_grpc = None  # type: ignore


@unittest.skipIf(
    grpc is None or pb is None or rpc is None or register_grpc is None,
    "grpcio/grpc stubs are not available; run scripts/gen_proto_py.sh first",
)
class GrpcIntegrationTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self) -> None:
        store = InMemoryTelemetryStore()
        writer = AsyncBatchWriter(store, flush_size=1, flush_interval_s=0.01, max_queue=2048)
        self.pipeline = TelemetryIngestionPipeline(store, writer)
        await self.pipeline.start()

        self.server = grpc.aio.server()
        register_grpc(self.server, self.pipeline)
        self.port = self.server.add_insecure_port("127.0.0.1:0")
        await self.server.start()

        self.channel = grpc.aio.insecure_channel(f"127.0.0.1:{self.port}")
        await self.channel.channel_ready()
        self.stub = rpc.TelemetryIngestStub(self.channel)

    async def asyncTearDown(self) -> None:
        await self.channel.close()
        await self.server.stop(grace=0)
        await self.pipeline.stop()

    async def test_end_to_end_query_endpoints(self) -> None:
        create_a = await self.stub.CreateSession(
            pb.CreateSessionRequest(
                session_id="grpc-int-a",
                driver_id="driver-a",
                track_id="spa",
                car_id="gt3",
                started_at_ns=1_700_100_000_000_000_000,
                tags={"suite": "integration"},
            ),
        )
        create_b = await self.stub.CreateSession(
            pb.CreateSessionRequest(
                session_id="grpc-int-b",
                driver_id="driver-b",
                track_id="spa",
                car_id="gt3",
                started_at_ns=1_700_100_100_000_000_000,
                tags={"suite": "integration"},
            ),
        )
        self.assertTrue(create_a.ok)
        self.assertTrue(create_b.ok)

        async def stream_frames() -> AsyncIterator[pb.TelemetryFrame]:
            base_ns = 90_000_000_000
            for i in range(120):
                lap = i // 60
                norm = (i % 60) / 60.0
                ns = base_ns + i * 16_666_666
                yield _frame(
                    session_id="grpc-int-a",
                    monotonic_ns=ns,
                    lap=lap,
                    norm_pos=norm,
                    speed_kmh=152.0 + norm * 10.0 - lap * 0.7,
                )
                yield _frame(
                    session_id="grpc-int-b",
                    monotonic_ns=ns,
                    lap=lap,
                    norm_pos=norm,
                    speed_kmh=149.5 + norm * 9.0 - lap * 0.5,
                )

        acks = []
        async for ack in self.stub.StreamFrames(stream_frames()):
            acks.append(ack)
        self.assertEqual(len(acks), 240)
        self.assertEqual(acks[-1].status, pb.StreamAck.ACK_OK)

        await asyncio.sleep(0.05)

        list_resp = await self.stub.ListSessions(
            pb.ListSessionsRequest(track_id="spa", car_id="gt3", limit=10),
        )
        self.assertEqual(list_resp.total_count, 2)

        summary_resp = await self.stub.GetSessionSummary(
            pb.GetSessionSummaryRequest(session_id="grpc-int-a", include_laps=True),
        )
        self.assertTrue(summary_resp.ok)
        self.assertEqual(summary_resp.summary.session.session_id, "grpc-int-a")
        self.assertGreaterEqual(summary_resp.summary.lap_count, 2)

        session_query = await self.stub.QuerySessionTelemetry(
            pb.QuerySessionTelemetryRequest(
                session_id="grpc-int-a",
                target_hz=10,
                normalize_distance_axis=True,
            ),
        )
        self.assertGreater(session_query.returned_count, 0)
        self.assertFalse(session_query.cached)

        lap_slice_1 = await self.stub.QueryLapSlice(
            pb.QueryLapSliceRequest(
                session_id="grpc-int-a",
                lap=1,
                has_start_distance_norm=True,
                start_distance_norm=1.15,
                has_end_distance_norm=True,
                end_distance_norm=1.9,
                target_hz=20,
                normalize_distance_axis=True,
            ),
        )
        lap_slice_2 = await self.stub.QueryLapSlice(
            pb.QueryLapSliceRequest(
                session_id="grpc-int-a",
                lap=1,
                has_start_distance_norm=True,
                start_distance_norm=1.15,
                has_end_distance_norm=True,
                end_distance_norm=1.9,
                target_hz=20,
                normalize_distance_axis=True,
            ),
        )
        self.assertGreater(lap_slice_1.returned_count, 0)
        self.assertFalse(lap_slice_1.cached)
        self.assertTrue(lap_slice_2.cached)

        overlay_1 = await self.stub.GetLapOverlay(
            pb.GetLapOverlayRequest(
                base_session_id="grpc-int-a",
                base_lap=1,
                compare_session_id="grpc-int-b",
                compare_lap=1,
                target_hz=20,
                has_start_distance_norm=False,
                has_end_distance_norm=False,
            ),
        )
        overlay_2 = await self.stub.GetLapOverlay(
            pb.GetLapOverlayRequest(
                base_session_id="grpc-int-a",
                base_lap=1,
                compare_session_id="grpc-int-b",
                compare_lap=1,
                target_hz=20,
                has_start_distance_norm=False,
                has_end_distance_norm=False,
            ),
        )
        self.assertGreater(overlay_1.returned_count, 0)
        self.assertFalse(overlay_1.cached)
        self.assertGreaterEqual(overlay_1.query_time_ms, 0)
        self.assertTrue(overlay_2.cached)

        close_a = await self.stub.CloseSession(
            pb.CloseSessionRequest(
                session_id="grpc-int-a",
                closed_at_ns=1_700_100_400_000_000_000,
            ),
        )
        close_b = await self.stub.CloseSession(
            pb.CloseSessionRequest(
                session_id="grpc-int-b",
                closed_at_ns=1_700_100_400_000_000_000,
            ),
        )
        self.assertTrue(close_a.ok)
        self.assertTrue(close_b.ok)
        self.assertFalse(close_a.session.active)
        self.assertFalse(close_b.session.active)


def _frame(
    *,
    session_id: str,
    monotonic_ns: int,
    lap: int,
    norm_pos: float,
    speed_kmh: float,
) -> pb.TelemetryFrame:
    return pb.TelemetryFrame(
        session_id=session_id,
        monotonic_ns=monotonic_ns,
        game="assetto_corsa",
        physics=pb.Physics(
            speed_kmh=speed_kmh,
            gas=0.62,
            brake=0.09 if 0.35 < norm_pos < 0.42 else 0.0,
            steer=0.11 if 0.2 < norm_pos < 0.6 else -0.05,
            gear=4,
            engine_rpm=6900.0,
            tyre_slip=pb.Wheel4f(fl=1.9, fr=2.1, rl=1.6, rr=1.7),
            acc_g=pb.Vec3f(y=1.2),
        ),
        graphics=pb.Graphics(
            completed_laps=lap,
            normalized_car_pos=norm_pos,
        ),
    )
