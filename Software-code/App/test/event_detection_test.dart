import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:client/event_detection.dart';
import 'package:client/telemetry_analysis.dart';

void main() {
  test('segments laps and corners into a clean event stream', () {
    final stream = detectTelemetryEvents(_buildSmoothSession(laps: 3));

    final completedLaps = stream.laps.where((lap) => lap.complete).length;
    expect(completedLaps, greaterThanOrEqualTo(2));
    expect(stream.corners.length, greaterThanOrEqualTo(6));

    expect(
      stream.events.any((e) => e.type == TelemetryEventType.lapBoundary),
      isTrue,
    );
    expect(
      stream.events.any((e) => e.type == TelemetryEventType.cornerSegment),
      isTrue,
    );
    expect(
      stream.events.every((e) => e.severityScore >= 0 && e.severityScore <= 1),
      isTrue,
    );
  });

  test('detects brake lock-ups with severity scoring', () {
    final stream = detectTelemetryEvents(_buildLockupSession());
    final lockUps = stream.events
        .where((event) => event.type == TelemetryEventType.brakeLockUp)
        .toList(growable: false);

    expect(lockUps, isNotEmpty);
    expect(lockUps.first.severityScore, greaterThan(0.45));
    expect(
      lockUps.any((event) => (event.metrics['peakWheelDeltaKmh'] ?? 0) > 12.0),
      isTrue,
    );
  });

  test('detects apex misses from overspeed/late-apex corners', () {
    final stream = detectTelemetryEvents(_buildApexMissSession());
    final misses = stream.events
        .where((event) => event.type == TelemetryEventType.apexMiss)
        .toList(growable: false);

    expect(misses, isNotEmpty);
    expect(
      misses.any((event) => event.severityScore > 0.3),
      isTrue,
    );
    expect(
      misses.any((event) => (event.metrics['latGDeficit'] ?? 0) > 0.08),
      isTrue,
    );
  });

  test('detects spins and saves as separate event classes', () {
    final spinStream = detectTelemetryEvents(_buildSpinSession());
    final saveStream = detectTelemetryEvents(_buildSaveSession());

    expect(
      spinStream.events.any((e) => e.type == TelemetryEventType.spin),
      isTrue,
    );
    expect(
      saveStream.events.any((e) => e.type == TelemetryEventType.save),
      isTrue,
    );
  });

  test('detects crash / impact events', () {
    final stream = detectTelemetryEvents(_buildCrashSession());
    final crashes = stream.events
        .where((event) => event.type == TelemetryEventType.crash)
        .toList(growable: false);

    expect(crashes, isNotEmpty);
    expect(crashes.first.severityScore, greaterThan(0.6));
    expect(
      (crashes.first.metrics['impactDecelMps2'] ?? 0) > 14.0,
      isTrue,
    );
  });
}

List<TelemetryFrame> _buildSmoothSession({required int laps}) {
  final frames = <TelemetryFrame>[];
  var timestamp = DateTime(2026, 2, 7, 12, 0, 0);
  const samplesPerLap = 220;
  const step = Duration(milliseconds: 120);

  for (var lap = 0; lap < laps; lap++) {
    for (var i = 0; i < samplesPerLap; i++) {
      final progress = i / samplesPerLap;
      final speed = _baseLapSpeed(progress);
      frames.add(_frameAt(
        timestamp: timestamp,
        progress: progress,
        speedKmh: speed,
      ));
      timestamp = timestamp.add(step);
    }
  }
  return frames;
}

List<TelemetryFrame> _buildLockupSession() {
  final source = _buildSmoothSession(laps: 1);
  return source.map((frame) {
    final p = frame.trackProgress;
    var speed = frame.speedKmh;
    var wheelDelta = 0.0;
    if (p >= 0.165 && p < 0.175) {
      speed -= (p - 0.165) * 1800;
      wheelDelta = 10;
    } else if (p >= 0.175 && p < 0.205) {
      speed -= 24;
      wheelDelta = 22;
    } else if (p >= 0.205 && p < 0.225) {
      speed -= max(0.0, 24 - (p - 0.205) * 640);
      wheelDelta = 14;
    }
    return _copyWithSignals(frame,
        speedKmh: speed, wheelSpeedDeltaKmh: wheelDelta);
  }).toList(growable: false);
}

List<TelemetryFrame> _buildApexMissSession() {
  final frames = <TelemetryFrame>[];
  var timestamp = DateTime(2026, 2, 7, 13, 0, 0);
  const samples = 220;
  const step = Duration(milliseconds: 120);

  for (var i = 0; i < samples; i++) {
    final baseProgress = i / samples;
    final cornerWeave = sin(baseProgress * 26 * pi) *
        _gaussian(baseProgress, center: 0.58, width: 0.08) *
        0.011;
    final progress = (baseProgress + cornerWeave).clamp(0.0, 0.999).toDouble();
    final speed = _baseLapSpeed(baseProgress) -
        (_gaussian(baseProgress, center: 0.67, width: 0.05) * 12) +
        (_gaussian(baseProgress, center: 0.52, width: 0.06) * 30);
    var lateralG =
        0.55 + _gaussian(baseProgress, center: 0.52, width: 0.06) * 0.95;
    lateralG -= _gaussian(baseProgress, center: 0.58, width: 0.035) * 0.95;
    frames.add(_frameAt(
      timestamp: timestamp,
      progress: progress,
      speedKmh: speed,
      lateralG: lateralG,
    ));
    timestamp = timestamp.add(step);
  }
  return frames;
}

List<TelemetryFrame> _buildSpinSession() {
  final frames = <TelemetryFrame>[];
  var timestamp = DateTime(2026, 2, 7, 14, 0, 0);
  const samples = 210;
  const step = Duration(milliseconds: 120);

  const oscillation = <double>[
    0.000,
    0.014,
    -0.012,
    0.015,
    -0.013,
    0.016,
    -0.014,
    0.017,
    -0.015,
    0.018,
    -0.014,
    0.016,
    -0.013,
  ];

  for (var i = 0; i < samples; i++) {
    var progress = i / samples;
    var speed = _baseLapSpeed(progress);

    if (i >= 135 && i < 135 + oscillation.length) {
      final k = i - 135;
      progress = 0.67 + oscillation[k];
      speed = 110 - k * 4.4;
    } else if (i >= 148 && i < 162) {
      speed = 58 + (i - 148) * 1.3;
    }

    frames.add(_frameAt(
      timestamp: timestamp,
      progress: progress,
      speedKmh: speed,
    ));
    timestamp = timestamp.add(step);
  }
  return frames;
}

List<TelemetryFrame> _buildSaveSession() {
  final frames = <TelemetryFrame>[];
  var timestamp = DateTime(2026, 2, 7, 15, 0, 0);
  const samples = 210;
  const step = Duration(milliseconds: 120);

  for (var i = 0; i < samples; i++) {
    var progress = i / samples;
    var speed = _baseLapSpeed(progress);
    if (i >= 132 && i <= 142) {
      final k = i - 132;
      final weave = k.isEven ? 0.010 : -0.010;
      progress = 0.63 + k * 0.005 + weave;
      speed = 116 - k * 2.1;
    } else if (i > 142 && i < 160) {
      speed += min(20.0, (i - 142) * 1.2);
    }

    frames.add(_frameAt(
      timestamp: timestamp,
      progress: progress,
      speedKmh: speed,
    ));
    timestamp = timestamp.add(step);
  }
  return frames;
}

List<TelemetryFrame> _buildCrashSession() {
  final frames = <TelemetryFrame>[];
  var timestamp = DateTime(2026, 2, 7, 16, 0, 0);
  const samples = 220;
  const step = Duration(milliseconds: 120);

  for (var i = 0; i < samples; i++) {
    var progress = i / samples;
    var speed = _baseLapSpeed(progress);
    var wheelDelta = 0.0;
    if (i == 150) {
      speed = 34;
      wheelDelta = 34;
    } else if (i > 150 && i < 176) {
      progress = 0.68 + (i - 150) * 0.00035;
      speed = 22 + (i - 151) * 0.32;
      wheelDelta = 20;
    }
    frames.add(_frameAt(
      timestamp: timestamp,
      progress: progress,
      speedKmh: speed,
      wheelSpeedDeltaKmh: wheelDelta,
    ));
    timestamp = timestamp.add(step);
  }
  return frames;
}

TelemetryFrame _frameAt({
  required DateTime timestamp,
  required double progress,
  required double speedKmh,
  double? wheelSpeedDeltaKmh,
  double? lateralG,
}) {
  final speed = speedKmh.clamp(20.0, 260.0).toDouble();
  final gear = max(1, min(6, (1 + speed / 38).floor()));
  final rpm = 2200 + speed * 32;
  return TelemetryFrame(
    timestamp: timestamp,
    trackProgress: progress.clamp(0.0, 0.999).toDouble(),
    speedKmh: speed,
    gear: gear,
    rpm: rpm,
    wheelSpeedDeltaKmh: wheelSpeedDeltaKmh,
    lateralG: lateralG,
  );
}

TelemetryFrame _copyWithSignals(
  TelemetryFrame frame, {
  required double speedKmh,
  double? wheelSpeedDeltaKmh,
  double? lateralG,
}) {
  return _frameAt(
    timestamp: frame.timestamp,
    progress: frame.trackProgress,
    speedKmh: speedKmh,
    wheelSpeedDeltaKmh: wheelSpeedDeltaKmh ?? frame.wheelSpeedDeltaKmh,
    lateralG: lateralG ?? frame.lateralG,
  );
}

double _baseLapSpeed(double progress) {
  final corner1 = _gaussian(progress, center: 0.18, width: 0.045) * 52;
  final corner2 = _gaussian(progress, center: 0.52, width: 0.055) * 44;
  final corner3 = _gaussian(progress, center: 0.79, width: 0.045) * 58;
  return 166 - corner1 - corner2 - corner3;
}

double _gaussian(
  double x, {
  required double center,
  required double width,
}) {
  final normalized = (x - center) / max(1e-6, width);
  return exp(-normalized * normalized);
}
