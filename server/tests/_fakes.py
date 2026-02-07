from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List


@dataclass
class Wheel4f:
    fl: float = 0.0
    fr: float = 0.0
    rl: float = 0.0
    rr: float = 0.0


@dataclass
class Vec3f:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0


@dataclass
class Physics:
    speed_kmh: float = 0.0
    gas: float = 0.0
    brake: float = 0.0
    clutch: float = 0.0
    gear: int = 0
    steer: float = 0.0
    engine_rpm: float = 0.0
    tyre_slip: Wheel4f = field(default_factory=Wheel4f)
    acc_g: Vec3f = field(default_factory=Vec3f)


@dataclass
class Graphics:
    status: int = 2
    completed_laps: int = 0
    normalized_car_pos: float = 0.0


@dataclass
class TelemetryFrame:
    monotonic_ns: int
    session_id: str
    game: str = "assetto_corsa"
    physics: Physics = field(default_factory=Physics)
    graphics: Graphics = field(default_factory=Graphics)


def build_frame(
    *,
    session_id: str,
    monotonic_ns: int,
    speed_kmh: float = 120.0,
    gas: float = 0.4,
    brake: float = 0.1,
    steer: float = 0.0,
    gear: int = 4,
    rpm: float = 5200.0,
    lap: int = 0,
    norm_pos: float = 0.0,
    wheel_slip: float = 0.0,
    lateral_g: float = 0.0,
) -> TelemetryFrame:
    return TelemetryFrame(
        session_id=session_id,
        monotonic_ns=monotonic_ns,
        physics=Physics(
            speed_kmh=speed_kmh,
            gas=gas,
            brake=brake,
            steer=steer,
            gear=gear,
            engine_rpm=rpm,
            tyre_slip=Wheel4f(fl=wheel_slip, fr=wheel_slip, rl=wheel_slip, rr=wheel_slip),
            acc_g=Vec3f(y=lateral_g),
        ),
        graphics=Graphics(completed_laps=lap, normalized_car_pos=norm_pos),
    )


class FakePbNamespace:
    class StreamAck:
        ACK_OK = 1
        ACK_INVALID = 2
        ACK_BACKPRESSURE = 3
        ACK_DROPPED = 4
        ACK_ERROR = 5

        def __init__(self, **kwargs):
            self.__dict__.update(kwargs)

    class SessionInfo:
        def __init__(self, **kwargs):
            self.__dict__.update(kwargs)

    class CreateSessionResponse:
        def __init__(self, **kwargs):
            self.__dict__.update(kwargs)

    class CloseSessionResponse:
        def __init__(self, **kwargs):
            self.__dict__.update(kwargs)

    class QueryPoint:
        def __init__(self, **kwargs):
            self.__dict__.update(kwargs)

    class QuerySessionTelemetryResponse:
        def __init__(self, **kwargs):
            self.__dict__.update(kwargs)


class FakeRpcNamespace:
    @staticmethod
    def add_TelemetryIngestServicer_to_server(servicer, server) -> None:
        server.servicer = servicer


class ListAsyncIterator:
    def __init__(self, values: List[object]):
        self._values = values
        self._index = 0

    def __aiter__(self):
        return self

    async def __anext__(self):
        if self._index >= len(self._values):
            raise StopAsyncIteration
        value = self._values[self._index]
        self._index += 1
        return value


class FakeRequest:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)
        if "tags" not in kwargs:
            self.tags = {}

