from __future__ import annotations

import asyncio
import unittest

from server.cloud_ingest.batch_writer import AsyncBatchWriter
from server.cloud_ingest.models import AckStatus, QueryRequest
from server.cloud_ingest.pipeline import TelemetryIngestionPipeline
from server.cloud_ingest.storage import InMemoryTelemetryStore
from server.tests._fakes import build_frame


class PipelineTests(unittest.IsolatedAsyncioTestCase):
    async def test_session_lifecycle_create_and_close(self) -> None:
        store = InMemoryTelemetryStore()
        writer = AsyncBatchWriter(store, flush_size=8, flush_interval_s=1.0, max_queue=32)
        pipeline = TelemetryIngestionPipeline(store, writer)

        created = await pipeline.create_session(
            session_id="sess-1",
            driver_id="driver-7",
            track_id="spa",
            car_id="gt3",
            started_at_ns=1_700_000_000_000_000_000,
            tags={"weather": "dry"},
        )
        self.assertEqual(created.session_id, "sess-1")
        self.assertTrue(created.active)
        self.assertEqual(created.driver_id, "driver-7")

        closed = await pipeline.close_session("sess-1", closed_at_ns=1_700_000_300_000_000_000)
        self.assertFalse(closed.active)
        self.assertIsNotNone(closed.closed_at)

    async def test_validation_and_backpressure_ack(self) -> None:
        store = InMemoryTelemetryStore()
        # Keep writer stopped to force queue buildup and deterministic backpressure.
        writer = AsyncBatchWriter(
            store,
            flush_size=64,
            flush_interval_s=2.0,
            max_queue=2,
            enqueue_timeout_s=0.001,
        )
        pipeline = TelemetryIngestionPipeline(store, writer)

        invalid = build_frame(session_id="", monotonic_ns=0)
        invalid_ack = await pipeline.ingest_frame(invalid)
        self.assertEqual(invalid_ack.status, AckStatus.ACK_INVALID)

        await pipeline.create_session(session_id="sess-bp", driver_id="d1", track_id="track-a")
        ok1 = await pipeline.ingest_frame(
            build_frame(session_id="sess-bp", monotonic_ns=1_000_000_000, norm_pos=0.05),
        )
        ok2 = await pipeline.ingest_frame(
            build_frame(session_id="sess-bp", monotonic_ns=1_016_000_000, norm_pos=0.06),
        )
        dropped = await pipeline.ingest_frame(
            build_frame(session_id="sess-bp", monotonic_ns=1_032_000_000, norm_pos=0.07),
        )

        self.assertIn(ok1.status, {AckStatus.ACK_OK, AckStatus.ACK_BACKPRESSURE})
        self.assertIn(ok2.status, {AckStatus.ACK_OK, AckStatus.ACK_BACKPRESSURE})
        self.assertEqual(dropped.status, AckStatus.ACK_DROPPED)

    async def test_query_downsample_and_distance_normalization(self) -> None:
        store = InMemoryTelemetryStore()
        writer = AsyncBatchWriter(store, flush_size=64, flush_interval_s=0.01, max_queue=2048)
        pipeline = TelemetryIngestionPipeline(store, writer)
        await pipeline.start()
        self.addAsyncCleanup(pipeline.stop)

        await pipeline.create_session(session_id="sess-q", driver_id="driver", track_id="monza")
        t0 = 2_000_000_000
        for i in range(120):  # ~60Hz over ~2s
            ns = t0 + i * 16_666_666
            lap = i // 60
            norm = (i % 60) / 60.0
            ack = await pipeline.ingest_frame(
                build_frame(
                    session_id="sess-q",
                    monotonic_ns=ns,
                    speed_kmh=110 + i * 0.2,
                    lap=lap,
                    norm_pos=norm,
                ),
            )
            self.assertIn(ack.status, {AckStatus.ACK_OK, AckStatus.ACK_BACKPRESSURE})

        await asyncio.sleep(0.1)
        result = await pipeline.query_session(
            QueryRequest(
                session_id="sess-q",
                start_monotonic_ns=t0,
                end_monotonic_ns=t0 + 120 * 16_666_666,
                target_hz=10,
                normalize_distance_axis=True,
            ),
        )

        self.assertGreater(result.source_count, result.returned_count)
        self.assertLessEqual(result.returned_count, 25)
        self.assertGreaterEqual(result.rows[0].distance_norm, 0.0)
        self.assertLessEqual(result.rows[-1].distance_norm, 1.0)

