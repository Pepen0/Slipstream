#!/usr/bin/env python3
import asyncio

import grpc

from server.cloud_ingest.batch_writer import AsyncBatchWriter
from server.cloud_ingest.grpc_service import register_grpc
from server.cloud_ingest.pipeline import TelemetryIngestionPipeline
from server.cloud_ingest.storage import InMemoryTelemetryStore


async def serve(bind: str = "[::]:50051") -> None:
    store = InMemoryTelemetryStore()
    writer = AsyncBatchWriter(store, flush_size=256, flush_interval_s=0.2, max_queue=20000)
    pipeline = TelemetryIngestionPipeline(store, writer)
    await pipeline.start()

    server = grpc.aio.server(
        options=[
            ("grpc.max_receive_message_length", 16 * 1024 * 1024),
            ("grpc.http2.max_pings_without_data", 0),
        ],
    )
    register_grpc(server, pipeline)
    server.add_insecure_port(bind)
    await server.start()
    print(f"Cloud ingest server listening on {bind}")
    try:
        await server.wait_for_termination()
    finally:
        await pipeline.stop()


if __name__ == "__main__":
    asyncio.run(serve())
