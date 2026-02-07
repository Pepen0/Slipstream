from __future__ import annotations

import asyncio
from contextlib import suppress
from dataclasses import dataclass
from typing import List, Optional

from .models import TelemetryRow
from .storage import TelemetryStore


@dataclass(slots=True)
class BatchWriterStats:
    enqueued: int = 0
    inserted: int = 0
    dropped: int = 0
    flushes: int = 0
    write_errors: int = 0


class AsyncBatchWriter:
    def __init__(
        self,
        store: TelemetryStore,
        *,
        flush_size: int = 256,
        flush_interval_s: float = 0.20,
        max_queue: int = 20000,
        enqueue_timeout_s: float = 0.01,
    ) -> None:
        self._store = store
        self._flush_size = max(1, flush_size)
        self._flush_interval_s = max(0.01, flush_interval_s)
        self._enqueue_timeout_s = max(0.0, enqueue_timeout_s)
        self._queue: asyncio.Queue[TelemetryRow] = asyncio.Queue(maxsize=max_queue)
        self._shutdown = asyncio.Event()
        self._task: Optional[asyncio.Task] = None
        self.stats = BatchWriterStats()

    @property
    def max_queue(self) -> int:
        return self._queue.maxsize

    @property
    def pending(self) -> int:
        return self._queue.qsize()

    def is_backpressured(self) -> bool:
        if self._queue.maxsize <= 0:
            return False
        return self.pending >= int(self._queue.maxsize * 0.80)

    async def start(self) -> None:
        if self._task is not None and not self._task.done():
            return
        self._shutdown.clear()
        self._task = asyncio.create_task(self._run(), name="telemetry-batch-writer")

    async def stop(self) -> None:
        self._shutdown.set()
        if self._task is not None:
            with suppress(asyncio.CancelledError):
                await self._task
        self._task = None

    async def enqueue(self, row: TelemetryRow) -> bool:
        try:
            await asyncio.wait_for(self._queue.put(row), timeout=self._enqueue_timeout_s)
            self.stats.enqueued += 1
            return True
        except asyncio.TimeoutError:
            self.stats.dropped += 1
            return False

    async def _run(self) -> None:
        buffer: List[TelemetryRow] = []
        while not self._shutdown.is_set() or not self._queue.empty() or buffer:
            timeout = self._flush_interval_s
            row: Optional[TelemetryRow] = None
            try:
                row = await asyncio.wait_for(self._queue.get(), timeout=timeout)
            except asyncio.TimeoutError:
                row = None

            if row is not None:
                buffer.append(row)
            should_flush = bool(buffer) and (
                len(buffer) >= self._flush_size
                or row is None
                or (self._shutdown.is_set() and self._queue.empty())
            )
            if should_flush:
                await self._flush(buffer)
                buffer.clear()

    async def _flush(self, rows: List[TelemetryRow]) -> None:
        if not rows:
            return
        try:
            inserted = await self._store.write_telemetry_batch(rows)
            self.stats.inserted += inserted
            self.stats.flushes += 1
        except Exception:
            self.stats.write_errors += 1
