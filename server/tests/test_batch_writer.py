from __future__ import annotations

import asyncio
import unittest
from datetime import datetime, timezone

from server.cloud_ingest.batch_writer import AsyncBatchWriter
from server.cloud_ingest.models import QueryRequest, SessionRecord, TelemetryRow


class _CountingStore:
    def __init__(self) -> None:
        self.calls = []
        self.rows = []

    async def create_session(self, session: SessionRecord) -> SessionRecord:
        return session

    async def close_session(self, session_id, closed_at):
        return SessionRecord(
            session_id=session_id,
            driver_id="x",
            track_id="y",
            started_at=closed_at,
            closed_at=closed_at,
            active=False,
        )

    async def get_session(self, session_id):
        return None

    async def write_telemetry_batch(self, rows):
        self.calls.append(len(rows))
        self.rows.extend(rows)
        await asyncio.sleep(0)
        return len(rows)

    async def query_rows(self, request: QueryRequest):
        return [row for row in self.rows if row.session_id == request.session_id]


def _row(i: int) -> TelemetryRow:
    return TelemetryRow(
        session_id="sess-batch",
        driver_id="driver",
        track_id="track",
        ts=datetime.now(timezone.utc),
        monotonic_ns=1_000_000_000 + i * 20_000_000,
        lap=0,
        distance_norm=i / 100.0,
        speed_kmh=100 + i,
        throttle=0.4,
        brake=0.1,
        steer=0.0,
        gear=4,
        engine_rpm=4500.0,
    )


class BatchWriterTests(unittest.IsolatedAsyncioTestCase):
    async def test_async_batch_writer_flushes(self) -> None:
        store = _CountingStore()
        writer = AsyncBatchWriter(
            store,
            flush_size=5,
            flush_interval_s=0.05,
            max_queue=256,
            enqueue_timeout_s=0.02,
        )
        await writer.start()
        self.addAsyncCleanup(writer.stop)

        for i in range(12):
            enqueued = await writer.enqueue(_row(i))
            self.assertTrue(enqueued)

        await asyncio.sleep(0.2)
        await writer.stop()

        self.assertEqual(len(store.rows), 12)
        self.assertGreaterEqual(writer.stats.flushes, 3)
        self.assertEqual(writer.stats.dropped, 0)
        self.assertEqual(sum(store.calls), 12)

