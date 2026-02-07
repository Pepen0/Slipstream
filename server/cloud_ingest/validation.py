from __future__ import annotations

import math
from typing import List


def validate_frame(frame: object) -> List[str]:
    errors: List[str] = []

    session_id = getattr(frame, "session_id", "")
    if not isinstance(session_id, str) or not session_id.strip():
        errors.append("session_id is required")

    monotonic_ns = getattr(frame, "monotonic_ns", 0)
    if not isinstance(monotonic_ns, int) or monotonic_ns <= 0:
        errors.append("monotonic_ns must be a positive integer")

    physics = getattr(frame, "physics", None)
    graphics = getattr(frame, "graphics", None)
    if physics is None:
        errors.append("physics payload missing")
    if graphics is None:
        errors.append("graphics payload missing")
    if physics is None or graphics is None:
        return errors

    speed = getattr(physics, "speed_kmh", 0.0)
    if not _is_finite(speed) or speed < 0.0 or speed > 550.0:
        errors.append("physics.speed_kmh out of range")

    gas = getattr(physics, "gas", 0.0)
    if not _is_finite(gas) or gas < 0.0 or gas > 1.0:
        errors.append("physics.gas out of range")

    brake = getattr(physics, "brake", 0.0)
    if not _is_finite(brake) or brake < 0.0 or brake > 1.0:
        errors.append("physics.brake out of range")

    steer = getattr(physics, "steer", 0.0)
    if not _is_finite(steer) or steer < -1.2 or steer > 1.2:
        errors.append("physics.steer out of range")

    gear = getattr(physics, "gear", 0)
    if not isinstance(gear, int) or gear < -1 or gear > 12:
        errors.append("physics.gear out of range")

    norm_pos = getattr(graphics, "normalized_car_pos", 0.0)
    if not _is_finite(norm_pos) or norm_pos < -0.01 or norm_pos > 1.01:
        errors.append("graphics.normalized_car_pos out of range")

    laps = getattr(graphics, "completed_laps", 0)
    if not isinstance(laps, int) or laps < 0 or laps > 100000:
        errors.append("graphics.completed_laps out of range")

    return errors


def _is_finite(value: object) -> bool:
    if not isinstance(value, (int, float)):
        return False
    return math.isfinite(float(value))
