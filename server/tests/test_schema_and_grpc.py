from __future__ import annotations

import asyncio
import unittest

from pathlib import Path

from server.cloud_ingest.batch_writer import AsyncBatchWriter
from server.cloud_ingest.grpc_service import TelemetryIngestGrpcService
from server.cloud_ingest.pipeline import TelemetryIngestionPipeline
from server.cloud_ingest.storage import InMemoryTelemetryStore, SCHEMA_SQL
from server.tests import _fakes


class SchemaAndGrpcTests(unittest.IsolatedAsyncioTestCase):
    async def test_schema_contains_hypertable_and_required_columns(self) -> None:
        self.assertIn("CREATE EXTENSION IF NOT EXISTS timescaledb", SCHEMA_SQL)
        self.assertIn("create_hypertable", SCHEMA_SQL.lower())
        for required in ("driver_id", "track_id", "session_id", "lap", "monotonic_ns", "ts"):
            self.assertIn(required, SCHEMA_SQL)
        self.assertIn("telemetry_lap_summary_cagg", SCHEMA_SQL)
        self.assertIn("timescaledb.continuous", SCHEMA_SQL)
        self.assertIn("add_continuous_aggregate_policy", SCHEMA_SQL)

    async def test_timescaledb_compose_manifest_exists(self) -> None:
        compose_path = Path("server/timescaledb/docker-compose.yml")
        self.assertTrue(compose_path.exists())
        compose = compose_path.read_text(encoding="utf-8")
        self.assertIn("timescale/timescaledb", compose)
        self.assertIn("/docker-entrypoint-initdb.d", compose)

    async def test_grpc_session_stream_and_query_endpoints(self) -> None:
        import server.cloud_ingest.grpc_service as grpc_service

        # Patch protobuf modules with in-test fakes to keep this test hermetic.
        grpc_service.pb = _fakes.FakePbNamespace
        grpc_service.rpc = _fakes.FakeRpcNamespace

        store = InMemoryTelemetryStore()
        writer = AsyncBatchWriter(store, flush_size=1, flush_interval_s=0.01, max_queue=256)
        pipeline = TelemetryIngestionPipeline(store, writer)
        await pipeline.start()
        self.addAsyncCleanup(pipeline.stop)

        service = TelemetryIngestGrpcService(pipeline)

        create_resp = await service.CreateSession(
            _fakes.FakeRequest(
                session_id="sess-grpc",
                driver_id="driver-1",
                track_id="track-1",
                car_id="gt3",
                started_at_ns=1_700_000_000_000_000_000,
                tags={"team": "alpha"},
            ),
            None,
        )
        self.assertTrue(create_resp.ok)
        self.assertEqual(create_resp.session.session_id, "sess-grpc")

        frames = [
            _fakes.build_frame(
                session_id="sess-grpc",
                monotonic_ns=5_000_000_000 + i * 16_666_666,
                speed_kmh=120 + i,
                lap=i // 30,
                norm_pos=(i % 30) / 30.0,
                wheel_slip=2.4,
                lateral_g=1.3,
            )
            for i in range(60)
        ]
        acks = []
        async for ack in service.StreamFrames(_fakes.ListAsyncIterator(frames), None):
            acks.append(ack)
        self.assertEqual(len(acks), 60)
        self.assertEqual(acks[-1].status, _fakes.FakePbNamespace.StreamAck.ACK_OK)

        await asyncio.sleep(0.05)
        query_resp = await service.QuerySessionTelemetry(
            _fakes.FakeRequest(
                session_id="sess-grpc",
                start_monotonic_ns=5_000_000_000,
                end_monotonic_ns=5_000_000_000 + 60 * 16_666_666,
                target_hz=10,
                normalize_distance_axis=True,
            ),
            None,
        )
        self.assertGreater(query_resp.source_count, query_resp.returned_count)
        self.assertGreater(len(query_resp.points), 0)
        self.assertGreaterEqual(query_resp.points[0].distance_norm, 0.0)
        self.assertLessEqual(query_resp.points[-1].distance_norm, 1.0)
        self.assertFalse(query_resp.cached)

        lap_resp = await service.QueryLapSlice(
            _fakes.FakeRequest(
                session_id="sess-grpc",
                lap=1,
                start_distance_norm=1.2,
                has_start_distance_norm=True,
                end_distance_norm=1.8,
                has_end_distance_norm=True,
                target_hz=20,
                normalize_distance_axis=True,
            ),
            None,
        )
        self.assertGreater(lap_resp.source_count, 0)
        self.assertGreater(lap_resp.returned_count, 0)

        overlay_resp = await service.GetLapOverlay(
            _fakes.FakeRequest(
                base_session_id="sess-grpc",
                base_lap=0,
                compare_session_id="sess-grpc",
                compare_lap=1,
                target_hz=20,
                has_start_distance_norm=False,
                has_end_distance_norm=False,
            ),
            None,
        )
        self.assertGreater(overlay_resp.returned_count, 0)
        self.assertGreaterEqual(overlay_resp.query_time_ms, 0)
        self.assertFalse(overlay_resp.cached)

        list_resp = await service.ListSessions(
            _fakes.FakeRequest(track_id="track-1", limit=10),
            None,
        )
        self.assertEqual(list_resp.total_count, 1)
        self.assertEqual(list_resp.sessions[0].session_id, "sess-grpc")

        summary_resp = await service.GetSessionSummary(
            _fakes.FakeRequest(session_id="sess-grpc", include_laps=True),
            None,
        )
        self.assertTrue(summary_resp.ok)
        self.assertEqual(summary_resp.summary.session.session_id, "sess-grpc")
        self.assertGreater(summary_resp.summary.point_count, 0)
        self.assertGreaterEqual(summary_resp.summary.lap_count, 2)
        self.assertGreaterEqual(len(summary_resp.summary.laps), 2)

        close_resp = await service.CloseSession(
            _fakes.FakeRequest(session_id="sess-grpc", closed_at_ns=1_700_000_003_000_000_000),
            None,
        )
        self.assertTrue(close_resp.ok)
        self.assertFalse(close_resp.session.active)
