import asyncio
import grpc
import telemetry.v1.telemetry_pb2 as pb
import telemetry.v1.telemetry_pb2_grpc as rpc
from concurrent import futures
from datetime import datetime

class Ingest(rpc.TelemetryIngestServicer):
    async def StreamFrames(self, request_iterator, context):
        async for frame in request_iterator:
            # Minimal back-ack; in production push to TimescaleDB / Redis
            yield pb.StreamAck(last_monotonic_ns=frame.monotonic_ns)

async def serve():
    server = grpc.aio.server(options=[
        ("grpc.max_receive_message_length", 16*1024*1024),
        ("grpc.http2.max_pings_without_data", 0),
    ])
    rpc.add_TelemetryIngestServicer_to_server(Ingest(), server)
    server.add_insecure_port("[::]:50051")
    await server.start()
    print("Ingest server on :50051")
    await server.wait_for_termination()

if __name__ == "__main__":
    asyncio.run(serve())
