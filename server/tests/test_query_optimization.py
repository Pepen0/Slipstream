from __future__ import annotations

import asyncio
import time
import unittest

from datetime import datetime, timezone

from server.cloud_ingest.batch_writer import AsyncBatchWriter
from server.cloud_ingest.models import (
    LapSliceRequest,
    OverlayRequest,
    SessionListRequest,
    TelemetryRow,
)
from server.cloud_ingest.pipeline import TelemetryIngestionPipeline
from server.cloud_ingest.storage import InMemoryTelemetryStore
from server.tests._fakes import build_frame


class QueryOptimizationPipelineTests(unittest.IsolatedAsyncioTestCase):
    async def test_lap_slice_overlay_cache_and_summary(self) -> None:
        store = InMemoryTelemetryStore()
        writer = AsyncBatchWriter(store, flush_size=64, flush_interval_s=0.01, max_queue=4096)
        pipeline = TelemetryIngestionPipeline(store, writer)
        await pipeline.start()
        self.addAsyncCleanup(pipeline.stop)

        await pipeline.create_session(
            session_id="sess-a",
            driver_id="driver-a",
            track_id="spa",
            car_id="gt3",
            started_at_ns=1_700_000_000_000_000_000,
        )
        await pipeline.create_session(
            session_id="sess-b",
            driver_id="driver-b",
            track_id="spa",
            car_id="gt3",
            started_at_ns=1_700_000_010_000_000_000,
        )

        t0 = 20_000_000_000
        for i in range(240):  # 2 laps at ~60Hz
            lap = i // 120
            norm = (i % 120) / 120.0
            ns = t0 + i * 16_666_666
            await pipeline.ingest_frame(
                build_frame(
                    session_id="sess-a",
                    monotonic_ns=ns,
                    speed_kmh=145 + norm * 12.0 - lap * 1.2,
                    gas=0.65,
                    brake=0.08 if 0.35 < norm < 0.45 else 0.0,
                    steer=0.1 if 0.25 < norm < 0.55 else -0.06,
                    lap=lap,
                    norm_pos=norm,
                ),
            )
            await pipeline.ingest_frame(
                build_frame(
                    session_id="sess-b",
                    monotonic_ns=ns,
                    speed_kmh=142 + norm * 10.5 - lap * 0.8,
                    gas=0.61,
                    brake=0.10 if 0.36 < norm < 0.47 else 0.0,
                    steer=0.12 if 0.28 < norm < 0.52 else -0.04,
                    lap=lap,
                    norm_pos=norm,
                ),
            )

        await asyncio.sleep(0.1)

        lap_slice_1 = await pipeline.query_lap_slice(
            LapSliceRequest(
                session_id="sess-a",
                lap=1,
                start_distance_norm=1.20,
                end_distance_norm=1.80,
                target_hz=20,
                normalize_distance_axis=True,
            ),
        )
        self.assertGreater(lap_slice_1.source_count, 0)
        self.assertGreater(lap_slice_1.returned_count, 0)
        self.assertFalse(lap_slice_1.cached)
        self.assertGreaterEqual(lap_slice_1.rows[0].distance_norm, 0.0)
        self.assertLessEqual(lap_slice_1.rows[-1].distance_norm, 1.0)

        lap_slice_2 = await pipeline.query_lap_slice(
            LapSliceRequest(
                session_id="sess-a",
                lap=1,
                start_distance_norm=1.20,
                end_distance_norm=1.80,
                target_hz=20,
                normalize_distance_axis=True,
            ),
        )
        self.assertTrue(lap_slice_2.cached)

        overlay_1 = await pipeline.get_lap_overlay(
            OverlayRequest(
                base_session_id="sess-a",
                base_lap=1,
                compare_session_id="sess-b",
                compare_lap=1,
                start_distance_norm=1.05,
                end_distance_norm=1.95,
                target_hz=20,
            ),
        )
        self.assertFalse(overlay_1.cached)
        self.assertGreater(overlay_1.returned_count, 0)
        self.assertGreaterEqual(overlay_1.query_time_ms, 0)

        overlay_2 = await pipeline.get_lap_overlay(
            OverlayRequest(
                base_session_id="sess-a",
                base_lap=1,
                compare_session_id="sess-b",
                compare_lap=1,
                start_distance_norm=1.05,
                end_distance_norm=1.95,
                target_hz=20,
            ),
        )
        self.assertTrue(overlay_2.cached)
        self.assertGreater(overlay_2.returned_count, 0)

        sessions = await pipeline.list_sessions(
            SessionListRequest(track_id="spa", car_id="gt3", limit=10),
        )
        self.assertEqual(len(sessions), 2)

        summary = await pipeline.get_session_summary("sess-a")
        self.assertEqual(summary.session.session_id, "sess-a")
        self.assertEqual(summary.lap_count, 2)
        self.assertGreater(summary.point_count, 0)
        self.assertIsNotNone(summary.best_lap)
        self.assertGreater(summary.best_lap.lap_time_s, 0.0)


class QueryOptimizationPerformanceTests(unittest.IsolatedAsyncioTestCase):
    async def test_overlay_query_completes_under_two_seconds(self) -> None:
        store = InMemoryTelemetryStore()
        writer = AsyncBatchWriter(store, flush_size=1024, flush_interval_s=1.0, max_queue=2048)
        pipeline = TelemetryIngestionPipeline(store, writer, query_cache_ttl_s=30.0)

        created_a = await pipeline.create_session(
            session_id="sess-fast-a",
            driver_id="driver-a",
            track_id="monza",
            car_id="f3",
            started_at_ns=1_700_000_100_000_000_000,
        )
        created_b = await pipeline.create_session(
            session_id="sess-fast-b",
            driver_id="driver-b",
            track_id="monza",
            car_id="f3",
            started_at_ns=1_700_000_200_000_000_000,
        )

        lap = 4
        sample_count = 12000
        rows = []
        for i in range(sample_count):
            distance = lap + (i / (sample_count - 1))
            ns = 9_000_000_000 + i * 16_666_666
            rows.append(
                TelemetryRow(
                    session_id=created_a.session_id,
                    driver_id=created_a.driver_id,
                    track_id=created_a.track_id,
                    ts=datetime.now(timezone.utc),
                    monotonic_ns=ns,
                    lap=lap,
                    distance_norm=distance,
                    speed_kmh=210.0 + (i % 200) * 0.05,
                    throttle=0.75,
                    brake=0.03 if 3000 < i < 4200 else 0.0,
                    steer=0.07,
                    gear=6,
                    engine_rpm=9200.0,
                ),
            )
            rows.append(
                TelemetryRow(
                    session_id=created_b.session_id,
                    driver_id=created_b.driver_id,
                    track_id=created_b.track_id,
                    ts=datetime.now(timezone.utc),
                    monotonic_ns=ns,
                    lap=lap,
                    distance_norm=distance,
                    speed_kmh=208.0 + (i % 180) * 0.05,
                    throttle=0.73,
                    brake=0.04 if 3100 < i < 4300 else 0.0,
                    steer=0.06,
                    gear=6,
                    engine_rpm=9100.0,
                ),
            )
        await store.write_telemetry_batch(rows)

        started = time.perf_counter()
        overlay = await pipeline.get_lap_overlay(
            OverlayRequest(
                base_session_id="sess-fast-a",
                base_lap=lap,
                compare_session_id="sess-fast-b",
                compare_lap=lap,
                target_hz=20,
            ),
        )
        elapsed_s = time.perf_counter() - started

        self.assertGreater(overlay.returned_count, 0)
        self.assertLess(elapsed_s, 2.0)
        self.assertLess(overlay.query_time_ms, 2000)
