CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE IF NOT EXISTS telemetry_sessions (
  session_id TEXT PRIMARY KEY,
  driver_id TEXT NOT NULL,
  track_id TEXT NOT NULL,
  car_id TEXT NOT NULL DEFAULT '',
  started_at TIMESTAMPTZ NOT NULL,
  closed_at TIMESTAMPTZ NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  tags JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS telemetry_frames (
  ts TIMESTAMPTZ NOT NULL,
  driver_id TEXT NOT NULL,
  track_id TEXT NOT NULL,
  session_id TEXT NOT NULL,
  lap INTEGER NOT NULL,
  monotonic_ns BIGINT NOT NULL,
  distance_norm DOUBLE PRECISION NOT NULL,
  speed_kmh DOUBLE PRECISION NOT NULL,
  throttle DOUBLE PRECISION NOT NULL,
  brake DOUBLE PRECISION NOT NULL,
  steer DOUBLE PRECISION NOT NULL,
  gear INTEGER NOT NULL,
  engine_rpm DOUBLE PRECISION NOT NULL,
  wheel_speed_delta_kmh DOUBLE PRECISION NULL,
  lateral_g DOUBLE PRECISION NULL,
  tags JSONB NOT NULL DEFAULT '{}'::jsonb,
  PRIMARY KEY (session_id, monotonic_ns),
  FOREIGN KEY (session_id) REFERENCES telemetry_sessions(session_id)
);

SELECT create_hypertable(
  'telemetry_frames',
  'ts',
  partitioning_column => 'session_id',
  number_partitions => 8,
  if_not_exists => TRUE
);

CREATE INDEX IF NOT EXISTS idx_frames_session_time
  ON telemetry_frames (session_id, ts DESC);

CREATE INDEX IF NOT EXISTS idx_frames_track_driver_time
  ON telemetry_frames (track_id, driver_id, ts DESC);

CREATE MATERIALIZED VIEW IF NOT EXISTS telemetry_frames_10hz
WITH (timescaledb.continuous) AS
SELECT
  session_id,
  time_bucket('100 milliseconds', ts) AS bucket,
  avg(speed_kmh) AS speed_kmh,
  avg(throttle) AS throttle,
  avg(brake) AS brake,
  avg(steer) AS steer,
  avg(engine_rpm) AS engine_rpm,
  avg(distance_norm) AS distance_norm
FROM telemetry_frames
GROUP BY session_id, bucket;

CREATE MATERIALIZED VIEW IF NOT EXISTS telemetry_frames_20hz
WITH (timescaledb.continuous) AS
SELECT
  session_id,
  time_bucket('50 milliseconds', ts) AS bucket,
  avg(speed_kmh) AS speed_kmh,
  avg(throttle) AS throttle,
  avg(brake) AS brake,
  avg(steer) AS steer,
  avg(engine_rpm) AS engine_rpm,
  avg(distance_norm) AS distance_norm
FROM telemetry_frames
GROUP BY session_id, bucket;
