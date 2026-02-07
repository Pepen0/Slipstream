from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Dict, List, Optional


class AckStatus(str, Enum):
    ACK_OK = "ACK_OK"
    ACK_INVALID = "ACK_INVALID"
    ACK_BACKPRESSURE = "ACK_BACKPRESSURE"
    ACK_DROPPED = "ACK_DROPPED"
    ACK_ERROR = "ACK_ERROR"


@dataclass(slots=True)
class IngestAck:
    last_monotonic_ns: int
    status: AckStatus
    message: str = ""
    buffered_frames: int = 0


@dataclass(slots=True)
class SessionRecord:
    session_id: str
    driver_id: str
    track_id: str
    car_id: str = ""
    started_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    closed_at: Optional[datetime] = None
    active: bool = True
    tags: Dict[str, str] = field(default_factory=dict)
    monotonic_origin_ns: Optional[int] = None


@dataclass(slots=True)
class TelemetryRow:
    session_id: str
    driver_id: str
    track_id: str
    ts: datetime
    monotonic_ns: int
    lap: int
    distance_norm: float
    speed_kmh: float
    throttle: float
    brake: float
    steer: float
    gear: int
    engine_rpm: float
    wheel_speed_delta_kmh: Optional[float] = None
    lateral_g: Optional[float] = None
    tags: Dict[str, str] = field(default_factory=dict)


@dataclass(slots=True)
class QueryRequest:
    session_id: str
    start_monotonic_ns: Optional[int] = None
    end_monotonic_ns: Optional[int] = None
    target_hz: int = 15
    normalize_distance_axis: bool = False


@dataclass(slots=True)
class QueryResult:
    rows: List[TelemetryRow]
    source_count: int
    returned_count: int
    cached: bool = False


@dataclass(slots=True)
class LapSliceRequest:
    session_id: str
    lap: int
    start_distance_norm: Optional[float] = None
    end_distance_norm: Optional[float] = None
    target_hz: int = 15
    normalize_distance_axis: bool = True


@dataclass(slots=True)
class LapSummary:
    lap: int
    point_count: int
    lap_time_s: float
    avg_speed_kmh: float
    peak_speed_kmh: float


@dataclass(slots=True)
class SessionSummary:
    session: SessionRecord
    point_count: int
    lap_count: int
    best_lap: Optional[LapSummary] = None
    laps: List[LapSummary] = field(default_factory=list)


@dataclass(slots=True)
class SessionListRequest:
    driver_id: str = ""
    track_id: str = ""
    car_id: str = ""
    active_only: bool = False
    started_after_ns: Optional[int] = None
    started_before_ns: Optional[int] = None
    limit: int = 100


@dataclass(slots=True)
class OverlayRequest:
    base_session_id: str
    base_lap: int
    compare_session_id: str
    compare_lap: int
    start_distance_norm: Optional[float] = None
    end_distance_norm: Optional[float] = None
    target_hz: int = 15


@dataclass(slots=True)
class OverlayPoint:
    distance_norm: float
    base_speed_kmh: float
    compare_speed_kmh: float
    speed_delta_kmh: float
    base_throttle: float
    compare_throttle: float
    throttle_delta: float
    base_brake: float
    compare_brake: float
    brake_delta: float
    base_steer: float
    compare_steer: float
    steer_delta: float


@dataclass(slots=True)
class OverlayResult:
    points: List[OverlayPoint]
    base_source_count: int
    compare_source_count: int
    returned_count: int
    query_time_ms: int
    cached: bool = False
