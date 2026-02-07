# Cloud Ingestion Infrastructure (Telemetry Pipeline)

## 1) Deploy TimescaleDB (Docker)

```bash
cd server/timescaledb
docker compose up -d
```

Database defaults:

- host: `localhost`
- port: `5432`
- user: `slipstream`
- password: `slipstream`
- db: `telemetry`

Schema is auto-applied from:

- `server/timescaledb/init/001_hypertable.sql`

## 2) gRPC stubs generation

From repo root:

```bash
bash scripts/gen_proto_py.sh
```

## 3) Run ingestion server

```bash
python server/cloud_ingest_server.py
```

## 4) Production storage wiring

`TelemetryIngestionPipeline` is storage-agnostic. Use:

- `InMemoryTelemetryStore` for tests/dev
- `TimescaleAsyncpgStore` for TimescaleDB

`TimescaleAsyncpgStore` can apply schema with:

```python
store = await TimescaleAsyncpgStore.connect("postgres://slipstream:slipstream@localhost:5432/telemetry", apply_schema=True)
```

## 5) Query behavior

- Time-range filters: `start_monotonic_ns`, `end_monotonic_ns`
- `target_hz` clamped to `10..20`
- Optional `normalize_distance_axis` maps returned `distance_norm` to `[0, 1]`
