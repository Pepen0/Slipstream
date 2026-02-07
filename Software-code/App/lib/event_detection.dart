import 'dart:math';

import 'package:flutter/foundation.dart';

import 'telemetry_analysis.dart';

enum TelemetryEventType {
  lapBoundary,
  cornerSegment,
  brakeLockUp,
  apexMiss,
  crash,
  spin,
  save,
}

String telemetryEventTypeLabel(TelemetryEventType type) {
  switch (type) {
    case TelemetryEventType.lapBoundary:
      return 'Lap Boundary';
    case TelemetryEventType.cornerSegment:
      return 'Corner Segment';
    case TelemetryEventType.brakeLockUp:
      return 'Brake Lock-up';
    case TelemetryEventType.apexMiss:
      return 'Apex Miss';
    case TelemetryEventType.crash:
      return 'Crash';
    case TelemetryEventType.spin:
      return 'Spin';
    case TelemetryEventType.save:
      return 'Save';
  }
}

@immutable
class EventDetectionConfig {
  const EventDetectionConfig({
    this.lapWrapUpper = 0.88,
    this.lapWrapLower = 0.12,
    this.minLapDurationSeconds = 8.0,
    this.minTurnLoad = 0.23,
    this.cornerEdgeLoad = 0.14,
    this.minCornerDurationSeconds = 0.55,
    this.minCornerProgressSpan = 0.015,
    this.minCornerGapSeconds = 0.8,
    this.lockUpBrakeThreshold = 0.74,
    this.lockUpDecelThreshold = 9.0,
    this.lockUpWheelDeltaThresholdKmh = 12.0,
    this.minLockUpSpeedKmh = 45.0,
    this.minLockUpDurationSeconds = 0.12,
    this.lockUpCriticalDurationSeconds = 0.8,
    this.apexMissMinTurnLoad = 0.34,
    this.apexPositionTolerance = 0.18,
    this.apexMissSpeedDeficitThreshold = 0.06,
    this.apexMissPositionErrorThreshold = 0.06,
    this.apexMissLatGDeficitThreshold = 0.08,
    this.apexExpectedLatGBase = 0.35,
    this.apexExpectedLatGScale = 1.85,
    this.spinSteeringThreshold = 0.78,
    this.spinMinFlips = 2,
    this.spinWindowSeconds = 1.6,
    this.spinMinSpeedKmh = 35.0,
    this.spinProgressStallThreshold = 0.005,
    this.spinSpeedDropRatio = 0.34,
    this.crashDecelThreshold = 14.0,
    this.crashSpeedDropRatio = 0.42,
    this.crashPostImpactSpeedKmh = 28.0,
    this.crashRecoveryWindowSeconds = 2.2,
    this.crashRecoveryRatio = 0.55,
    this.crashProgressStallThreshold = 0.015,
    this.saveSpeedDropRatio = 0.14,
    this.saveRecoveryWindowSeconds = 1.6,
    this.saveRecoveryRatio = 0.95,
    this.mergeGapSeconds = 0.25,
  });

  final double lapWrapUpper;
  final double lapWrapLower;
  final double minLapDurationSeconds;

  final double minTurnLoad;
  final double cornerEdgeLoad;
  final double minCornerDurationSeconds;
  final double minCornerProgressSpan;
  final double minCornerGapSeconds;

  final double lockUpBrakeThreshold;
  final double lockUpDecelThreshold;
  final double lockUpWheelDeltaThresholdKmh;
  final double minLockUpSpeedKmh;
  final double minLockUpDurationSeconds;
  final double lockUpCriticalDurationSeconds;

  final double apexMissMinTurnLoad;
  final double apexPositionTolerance;
  final double apexMissSpeedDeficitThreshold;
  final double apexMissPositionErrorThreshold;
  final double apexMissLatGDeficitThreshold;
  final double apexExpectedLatGBase;
  final double apexExpectedLatGScale;

  final double spinSteeringThreshold;
  final int spinMinFlips;
  final double spinWindowSeconds;
  final double spinMinSpeedKmh;
  final double spinProgressStallThreshold;
  final double spinSpeedDropRatio;

  final double crashDecelThreshold;
  final double crashSpeedDropRatio;
  final double crashPostImpactSpeedKmh;
  final double crashRecoveryWindowSeconds;
  final double crashRecoveryRatio;
  final double crashProgressStallThreshold;

  final double saveSpeedDropRatio;
  final double saveRecoveryWindowSeconds;
  final double saveRecoveryRatio;

  final double mergeGapSeconds;
}

@immutable
class LapSegment {
  const LapSegment({
    required this.lapIndex,
    required this.startIndex,
    required this.endIndex,
    required this.startTime,
    required this.endTime,
    required this.complete,
  });

  final int lapIndex;
  final int startIndex;
  final int endIndex;
  final DateTime startTime;
  final DateTime endTime;
  final bool complete;

  double get durationSeconds =>
      max(0.0, endTime.difference(startTime).inMicroseconds / 1e6);
}

@immutable
class CornerSegment {
  const CornerSegment({
    required this.lapIndex,
    required this.cornerIndex,
    required this.startIndex,
    required this.endIndex,
    required this.apexIndex,
    required this.startTime,
    required this.endTime,
    required this.startProgress,
    required this.endProgress,
    required this.apexProgress,
    required this.entrySpeedKmh,
    required this.apexSpeedKmh,
    required this.exitSpeedKmh,
    required this.peakTurnLoad,
  });

  final int lapIndex;
  final int cornerIndex;
  final int startIndex;
  final int endIndex;
  final int apexIndex;
  final DateTime startTime;
  final DateTime endTime;
  final double startProgress;
  final double endProgress;
  final double apexProgress;
  final double entrySpeedKmh;
  final double apexSpeedKmh;
  final double exitSpeedKmh;
  final double peakTurnLoad;

  double get durationSeconds =>
      max(0.0, endTime.difference(startTime).inMicroseconds / 1e6);

  double get apexRatio {
    final span = max(1, endIndex - startIndex);
    return ((apexIndex - startIndex) / span).clamp(0.0, 1.0).toDouble();
  }
}

@immutable
class TelemetryEvent {
  const TelemetryEvent({
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.startProgress,
    required this.endProgress,
    required this.severityScore,
    required this.summary,
    this.lapIndex,
    this.cornerIndex,
    this.metrics = const {},
  });

  final TelemetryEventType type;
  final DateTime startedAt;
  final DateTime endedAt;
  final double startProgress;
  final double endProgress;
  final double severityScore;
  final String summary;
  final int? lapIndex;
  final int? cornerIndex;
  final Map<String, double> metrics;

  double get durationSeconds =>
      max(0.0, endedAt.difference(startedAt).inMicroseconds / 1e6);

  TelemetryEvent copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    double? startProgress,
    double? endProgress,
    double? severityScore,
    String? summary,
    int? lapIndex,
    int? cornerIndex,
    Map<String, double>? metrics,
  }) {
    return TelemetryEvent(
      type: type,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      startProgress: startProgress ?? this.startProgress,
      endProgress: endProgress ?? this.endProgress,
      severityScore: severityScore ?? this.severityScore,
      summary: summary ?? this.summary,
      lapIndex: lapIndex ?? this.lapIndex,
      cornerIndex: cornerIndex ?? this.cornerIndex,
      metrics: metrics ?? this.metrics,
    );
  }
}

@immutable
class TelemetryEventStream {
  const TelemetryEventStream({
    required this.laps,
    required this.corners,
    required this.events,
  });

  final List<LapSegment> laps;
  final List<CornerSegment> corners;
  final List<TelemetryEvent> events;

  bool get isEmpty => events.isEmpty;
}

TelemetryEventStream detectTelemetryEvents(
  List<TelemetryFrame> frames, {
  EventDetectionConfig config = const EventDetectionConfig(),
}) {
  if (frames.length < 3) {
    return const TelemetryEventStream(laps: [], corners: [], events: []);
  }

  final points = deriveTelemetryPoints(frames);
  final laps = _segmentLaps(frames, config);
  final corners = _segmentCorners(frames, points, laps, config);
  final events = <TelemetryEvent>[];

  for (final lap in laps) {
    if (!lap.complete) {
      continue;
    }
    events.add(TelemetryEvent(
      type: TelemetryEventType.lapBoundary,
      startedAt: lap.startTime,
      endedAt: lap.endTime,
      startProgress: _wrap01(frames[lap.startIndex].trackProgress),
      endProgress: _wrap01(frames[lap.endIndex].trackProgress),
      severityScore: 0.08,
      summary: 'Lap ${lap.lapIndex} complete',
      lapIndex: lap.lapIndex,
      metrics: {'lapDurationSeconds': lap.durationSeconds},
    ));
  }

  for (final corner in corners) {
    events.add(TelemetryEvent(
      type: TelemetryEventType.cornerSegment,
      startedAt: corner.startTime,
      endedAt: corner.endTime,
      startProgress: corner.startProgress,
      endProgress: corner.endProgress,
      severityScore: (corner.peakTurnLoad * 0.4).clamp(0.08, 0.45).toDouble(),
      summary: 'Corner ${corner.cornerIndex} segmented',
      lapIndex: corner.lapIndex,
      cornerIndex: corner.cornerIndex,
      metrics: {
        'entrySpeedKmh': corner.entrySpeedKmh,
        'apexSpeedKmh': corner.apexSpeedKmh,
        'exitSpeedKmh': corner.exitSpeedKmh,
      },
    ));
  }

  events.addAll(_detectBrakeLockUps(
    frames: frames,
    points: points,
    laps: laps,
    corners: corners,
    config: config,
  ));
  events.addAll(_detectApexMisses(
    frames: frames,
    corners: corners,
    config: config,
  ));
  events.addAll(_detectCrashes(
    frames: frames,
    points: points,
    laps: laps,
    corners: corners,
    config: config,
  ));
  events.addAll(_detectSpinsAndSaves(
    frames: frames,
    points: points,
    laps: laps,
    corners: corners,
    config: config,
  ));

  return TelemetryEventStream(
    laps: laps,
    corners: corners,
    events: _cleanEventStream(events, config),
  );
}

List<LapSegment> _segmentLaps(
  List<TelemetryFrame> frames,
  EventDetectionConfig config,
) {
  final laps = <LapSegment>[];
  var lapStart = 0;
  var lapIndex = 1;

  for (var i = 1; i < frames.length; i++) {
    final prevProgress = _wrap01(frames[i - 1].trackProgress);
    final progress = _wrap01(frames[i].trackProgress);
    final wrapped =
        prevProgress >= config.lapWrapUpper && progress <= config.lapWrapLower;
    if (!wrapped) {
      continue;
    }

    final elapsedSeconds = max(
      0.0,
      frames[i - 1]
              .timestamp
              .difference(frames[lapStart].timestamp)
              .inMicroseconds /
          1e6,
    );
    if (elapsedSeconds < config.minLapDurationSeconds) {
      continue;
    }

    laps.add(LapSegment(
      lapIndex: lapIndex,
      startIndex: lapStart,
      endIndex: i - 1,
      startTime: frames[lapStart].timestamp,
      endTime: frames[i - 1].timestamp,
      complete: true,
    ));
    lapStart = i;
    lapIndex++;
  }

  laps.add(LapSegment(
    lapIndex: lapIndex,
    startIndex: lapStart,
    endIndex: frames.length - 1,
    startTime: frames[lapStart].timestamp,
    endTime: frames.last.timestamp,
    complete: false,
  ));

  return laps;
}

List<CornerSegment> _segmentCorners(
  List<TelemetryFrame> frames,
  List<TelemetryPoint> points,
  List<LapSegment> laps,
  EventDetectionConfig config,
) {
  if (points.length < 4) {
    return const [];
  }

  final corners = <CornerSegment>[];
  for (final lap in laps) {
    if (lap.endIndex - lap.startIndex < 4) {
      continue;
    }

    var cornerIndex = 1;
    double? lastCornerElapsed;
    var i = lap.startIndex + 1;
    while (i < lap.endIndex - 1) {
      final load = _turnLoad(points[i]);
      final prevLoad = _turnLoad(points[i - 1]);
      final nextLoad = _turnLoad(points[i + 1]);
      final isPeak =
          load >= config.minTurnLoad && load >= prevLoad && load > nextLoad;
      if (!isPeak) {
        i++;
        continue;
      }

      final at = points[i].elapsedSeconds;
      if (lastCornerElapsed != null) {
        if ((at - lastCornerElapsed) < config.minCornerGapSeconds) {
          i++;
          continue;
        }
      }

      var start = i;
      while (start > lap.startIndex &&
          _turnLoad(points[start]) > config.cornerEdgeLoad) {
        start--;
      }
      var end = i;
      while (end < lap.endIndex &&
          _turnLoad(points[end]) > config.cornerEdgeLoad) {
        end++;
      }

      if (end <= start) {
        i++;
        continue;
      }

      final duration =
          max(0.0, points[end].elapsedSeconds - points[start].elapsedSeconds);
      final span = _progressSpan(
        points[start].trackProgress,
        points[end].trackProgress,
      );
      if (duration < config.minCornerDurationSeconds ||
          span < config.minCornerProgressSpan) {
        i++;
        continue;
      }

      var apex = start;
      var apexSpeed = points[start].speedKmh;
      var peakLoad = 0.0;
      for (var j = start; j <= end; j++) {
        final point = points[j];
        if (point.speedKmh < apexSpeed) {
          apexSpeed = point.speedKmh;
          apex = j;
        }
        peakLoad = max(peakLoad, _turnLoad(point));
      }

      corners.add(CornerSegment(
        lapIndex: lap.lapIndex,
        cornerIndex: cornerIndex,
        startIndex: start,
        endIndex: end,
        apexIndex: apex,
        startTime: frames[start].timestamp,
        endTime: frames[end].timestamp,
        startProgress: _wrap01(points[start].trackProgress),
        endProgress: _wrap01(points[end].trackProgress),
        apexProgress: _wrap01(points[apex].trackProgress),
        entrySpeedKmh: points[start].speedKmh,
        apexSpeedKmh: apexSpeed,
        exitSpeedKmh: points[end].speedKmh,
        peakTurnLoad: peakLoad,
      ));
      cornerIndex++;
      lastCornerElapsed = points[end].elapsedSeconds;
      i = end + 1;
    }
  }

  return corners;
}

List<TelemetryEvent> _detectBrakeLockUps({
  required List<TelemetryFrame> frames,
  required List<TelemetryPoint> points,
  required List<LapSegment> laps,
  required List<CornerSegment> corners,
  required EventDetectionConfig config,
}) {
  final events = <TelemetryEvent>[];
  if (frames.length < 3 || points.length != frames.length) {
    return events;
  }

  final decel = List<double>.filled(frames.length, 0.0);
  for (var i = 1; i < frames.length; i++) {
    final dtSeconds = max(
      0.02,
      frames[i].timestamp.difference(frames[i - 1].timestamp).inMicroseconds /
          1e6,
    );
    decel[i] = ((frames[i - 1].speedKmh - frames[i].speedKmh) / 3.6) /
        max(1e-6, dtSeconds);
  }

  int? start;
  for (var i = 1; i < frames.length; i++) {
    final wheelDelta = frames[i].wheelSpeedDeltaKmh;
    final wheelEvidence =
        wheelDelta != null && wheelDelta >= config.lockUpWheelDeltaThresholdKmh;
    final brakeEvidence = points[i].brake >= config.lockUpBrakeThreshold;
    final isLocking = decel[i] >= config.lockUpDecelThreshold &&
        points[i].speedKmh >= config.minLockUpSpeedKmh &&
        (wheelEvidence || brakeEvidence);
    if (isLocking) {
      start ??= i;
      continue;
    }
    if (start != null) {
      _emitLockUpEvent(
        events: events,
        frames: frames,
        points: points,
        decel: decel,
        start: start,
        end: i - 1,
        laps: laps,
        corners: corners,
        config: config,
      );
      start = null;
    }
  }
  if (start != null) {
    _emitLockUpEvent(
      events: events,
      frames: frames,
      points: points,
      decel: decel,
      start: start,
      end: frames.length - 1,
      laps: laps,
      corners: corners,
      config: config,
    );
  }

  return events;
}

void _emitLockUpEvent({
  required List<TelemetryEvent> events,
  required List<TelemetryFrame> frames,
  required List<TelemetryPoint> points,
  required List<double> decel,
  required int start,
  required int end,
  required List<LapSegment> laps,
  required List<CornerSegment> corners,
  required EventDetectionConfig config,
}) {
  if (end <= start) {
    return;
  }
  final durationSeconds = max(
    0.0,
    frames[end].timestamp.difference(frames[start].timestamp).inMicroseconds /
        1e6,
  );
  if (durationSeconds < config.minLockUpDurationSeconds) {
    return;
  }

  var peakBrake = 0.0;
  var peakDecel = 0.0;
  var peakWheelDeltaKmh = 0.0;
  for (var i = start; i <= end; i++) {
    peakBrake = max(peakBrake, points[i].brake);
    peakDecel = max(peakDecel, decel[i]);
    peakWheelDeltaKmh =
        max(peakWheelDeltaKmh, frames[i].wheelSpeedDeltaKmh ?? 0);
  }
  final severity = _clamp01(
    ((peakBrake - config.lockUpBrakeThreshold) /
                max(1e-6, 1.0 - config.lockUpBrakeThreshold)) *
            0.25 +
        ((peakDecel - config.lockUpDecelThreshold) / 10.0) * 0.4 +
        (durationSeconds / config.lockUpCriticalDurationSeconds) * 0.2 +
        ((peakWheelDeltaKmh - config.lockUpWheelDeltaThresholdKmh) / 18.0) *
            0.15,
  );

  final mid = (start + end) ~/ 2;
  final lap = _lapAtIndex(laps, mid);
  final corner = _cornerAtIndex(corners, mid);
  events.add(TelemetryEvent(
    type: TelemetryEventType.brakeLockUp,
    startedAt: frames[start].timestamp,
    endedAt: frames[end].timestamp,
    startProgress: _wrap01(points[start].trackProgress),
    endProgress: _wrap01(points[end].trackProgress),
    severityScore: severity,
    summary: corner == null
        ? 'Brake lock-up detected'
        : 'Brake lock-up at corner ${corner.cornerIndex}',
    lapIndex: lap?.lapIndex,
    cornerIndex: corner?.cornerIndex,
    metrics: {
      'peakBrake': peakBrake,
      'peakDecelMps2': peakDecel,
      'peakWheelDeltaKmh': peakWheelDeltaKmh,
      'durationSeconds': durationSeconds,
    },
  ));
}

List<TelemetryEvent> _detectApexMisses({
  required List<TelemetryFrame> frames,
  required List<CornerSegment> corners,
  required EventDetectionConfig config,
}) {
  final events = <TelemetryEvent>[];
  for (final corner in corners) {
    if (corner.peakTurnLoad < config.apexMissMinTurnLoad) {
      continue;
    }

    final dropRatio = max(
      0.0,
      (corner.entrySpeedKmh - corner.apexSpeedKmh) /
          max(1.0, corner.entrySpeedKmh),
    );
    final requiredDrop =
        (0.12 + corner.peakTurnLoad * 0.33).clamp(0.13, 0.5).toDouble();
    final speedDeficit = (requiredDrop - dropRatio).clamp(0.0, 1.0).toDouble();
    final positionError =
        ((corner.apexRatio - 0.5).abs() - config.apexPositionTolerance)
            .clamp(0.0, 1.0)
            .toDouble();
    final measuredLatG = _measuredLateralGAtCorner(corner, frames);
    final expectedLatG = (config.apexExpectedLatGBase +
            (corner.peakTurnLoad * config.apexExpectedLatGScale))
        .clamp(0.25, 3.2)
        .toDouble();
    final latGDeficit =
        ((expectedLatG - measuredLatG) / max(0.25, expectedLatG))
            .clamp(0.0, 1.0)
            .toDouble();

    if (speedDeficit < config.apexMissSpeedDeficitThreshold &&
        positionError < config.apexMissPositionErrorThreshold &&
        latGDeficit < config.apexMissLatGDeficitThreshold) {
      continue;
    }

    final severity = _clamp01(
      speedDeficit * 0.35 +
          positionError * 0.2 +
          latGDeficit * 0.45 +
          max(0.0, corner.peakTurnLoad - config.apexMissMinTurnLoad) * 0.1,
    );

    events.add(TelemetryEvent(
      type: TelemetryEventType.apexMiss,
      startedAt: corner.startTime,
      endedAt: corner.endTime,
      startProgress: corner.startProgress,
      endProgress: corner.endProgress,
      severityScore: severity,
      summary: 'Apex miss in corner ${corner.cornerIndex}',
      lapIndex: corner.lapIndex,
      cornerIndex: corner.cornerIndex,
      metrics: {
        'speedDeficit': speedDeficit,
        'positionError': positionError,
        'measuredLatG': measuredLatG,
        'expectedLatG': expectedLatG,
        'latGDeficit': latGDeficit,
        'apexRatio': corner.apexRatio,
      },
    ));
  }
  return events;
}

double _measuredLateralGAtCorner(
  CornerSegment corner,
  List<TelemetryFrame> frames,
) {
  if (frames.isEmpty) {
    return 0.0;
  }
  final apexIndex = corner.apexIndex.clamp(0, frames.length - 1);
  final apexFrame = frames[apexIndex];
  final lateralG = apexFrame.lateralG;
  if (lateralG != null) {
    return lateralG.abs();
  }

  final i0 = max(0, apexIndex - 1);
  final i1 = min(frames.length - 1, apexIndex + 1);
  final progressSpan = max(
      1e-5, _progressSpan(frames[i0].trackProgress, frames[i1].trackProgress));
  final speedMps = apexFrame.speedKmh / 3.6;
  return (progressSpan * speedMps * 1.8).clamp(0.1, 2.8).toDouble();
}

List<TelemetryEvent> _detectCrashes({
  required List<TelemetryFrame> frames,
  required List<TelemetryPoint> points,
  required List<LapSegment> laps,
  required List<CornerSegment> corners,
  required EventDetectionConfig config,
}) {
  final events = <TelemetryEvent>[];
  if (frames.length < 4 || points.length != frames.length) {
    return events;
  }

  final unwrapped = _buildUnwrappedProgress(frames);
  var i = 1;
  while (i < frames.length) {
    final prevSpeed = max(1.0, frames[i - 1].speedKmh);
    final currentSpeed = frames[i].speedKmh;
    final dt = max(
      0.02,
      frames[i].timestamp.difference(frames[i - 1].timestamp).inMicroseconds /
          1e6,
    );
    final decelMps2 = ((prevSpeed - currentSpeed) / 3.6) / dt;
    final immediateDropRatio =
        ((prevSpeed - currentSpeed) / prevSpeed).clamp(0.0, 1.0).toDouble();

    final impactCandidate = decelMps2 >= config.crashDecelThreshold &&
        immediateDropRatio >= config.crashSpeedDropRatio;
    if (!impactCandidate) {
      i++;
      continue;
    }

    var end = i;
    while (end + 1 < frames.length) {
      final horizonSeconds = max(
        0.0,
        frames[end + 1]
                .timestamp
                .difference(frames[i].timestamp)
                .inMicroseconds /
            1e6,
      );
      if (horizonSeconds > config.crashRecoveryWindowSeconds) {
        break;
      }
      end++;
    }

    var minSpeed = currentSpeed;
    var maxRecovery = currentSpeed;
    for (var j = i; j <= end; j++) {
      minSpeed = min(minSpeed, frames[j].speedKmh);
      maxRecovery = max(maxRecovery, frames[j].speedKmh);
    }
    final recoveryRatio = (maxRecovery / prevSpeed).clamp(0.0, 2.0).toDouble();
    final progressGain = unwrapped[end] - unwrapped[i - 1];
    final severeStall = progressGain <= config.crashProgressStallThreshold;
    final lowPostImpactSpeed = minSpeed <= config.crashPostImpactSpeedKmh;
    final weakRecovery = recoveryRatio < config.crashRecoveryRatio;

    if (!lowPostImpactSpeed && !weakRecovery && !severeStall) {
      i = end + 1;
      continue;
    }

    final mid = ((i - 1) + end) ~/ 2;
    final lap = _lapAtIndex(laps, mid);
    final corner = _cornerAtIndex(corners, mid);
    final severity = _clamp01(
      (decelMps2 - config.crashDecelThreshold) / 16.0 * 0.35 +
          immediateDropRatio * 0.3 +
          (1.0 - recoveryRatio).clamp(0.0, 1.0) * 0.2 +
          (lowPostImpactSpeed ? 0.1 : 0.0) +
          (severeStall ? 0.1 : 0.0),
    );

    events.add(TelemetryEvent(
      type: TelemetryEventType.crash,
      startedAt: frames[i - 1].timestamp,
      endedAt: frames[end].timestamp,
      startProgress: _wrap01(frames[i - 1].trackProgress),
      endProgress: _wrap01(frames[end].trackProgress),
      severityScore: severity,
      summary: corner == null
          ? 'Crash / impact detected'
          : 'Crash / impact at corner ${corner.cornerIndex}',
      lapIndex: lap?.lapIndex,
      cornerIndex: corner?.cornerIndex,
      metrics: {
        'impactDecelMps2': decelMps2,
        'speedDropRatio': immediateDropRatio,
        'postImpactSpeedKmh': minSpeed,
        'recoveryRatio': recoveryRatio,
        'progressGain': progressGain,
      },
    ));

    i = end + 1;
  }

  return events;
}

List<TelemetryEvent> _detectSpinsAndSaves({
  required List<TelemetryFrame> frames,
  required List<TelemetryPoint> points,
  required List<LapSegment> laps,
  required List<CornerSegment> corners,
  required EventDetectionConfig config,
}) {
  final events = <TelemetryEvent>[];
  if (frames.length < 4 || points.length != frames.length) {
    return events;
  }

  final unwrapped = _buildUnwrappedProgress(frames);
  int? activeStart;
  var activeFlips = 0;
  var lastFlipAt = -1;

  void closeWindow(int endIndex) {
    if (activeStart == null || lastFlipAt < 0) {
      activeStart = null;
      activeFlips = 0;
      lastFlipAt = -1;
      return;
    }
    final start = max(0, activeStart! - 1);
    final end = min(frames.length - 1, endIndex + 1);
    final durationSeconds = max(
      0.0,
      frames[end].timestamp.difference(frames[start].timestamp).inMicroseconds /
          1e6,
    );
    if (activeFlips < config.spinMinFlips || durationSeconds <= 0) {
      activeStart = null;
      activeFlips = 0;
      lastFlipAt = -1;
      return;
    }

    var speedSum = 0.0;
    var maxSteering = 0.0;
    var minStepProgress = double.infinity;
    for (var i = start; i <= end; i++) {
      speedSum += frames[i].speedKmh;
      maxSteering = max(maxSteering, points[i].steering.abs());
      if (i > start) {
        minStepProgress = min(minStepProgress, unwrapped[i] - unwrapped[i - 1]);
      }
    }
    final meanSpeed = speedSum / (end - start + 1);
    if (meanSpeed < config.spinMinSpeedKmh) {
      activeStart = null;
      activeFlips = 0;
      lastFlipAt = -1;
      return;
    }

    final netProgress = unwrapped[end] - unwrapped[start];
    final speedStart = max(1.0, frames[start].speedKmh);
    final speedEnd = frames[end].speedKmh;
    final speedDropRatio =
        ((speedStart - speedEnd) / speedStart).clamp(0.0, 1.0).toDouble();
    final recoverySpeed = _maxSpeedInWindow(
      frames: frames,
      startIndex: end,
      horizonSeconds: config.saveRecoveryWindowSeconds,
    );
    final recoveryRatio = (recoverySpeed / speedStart).clamp(0.0, 2.0);

    final isSpin = netProgress <= config.spinProgressStallThreshold ||
        speedDropRatio >= config.spinSpeedDropRatio ||
        minStepProgress < -0.02;
    final isSave = !isSpin &&
        (speedDropRatio >= config.saveSpeedDropRatio ||
            recoveryRatio >= config.saveRecoveryRatio ||
            maxSteering >= 0.95);
    if (!isSpin && !isSave) {
      activeStart = null;
      activeFlips = 0;
      lastFlipAt = -1;
      return;
    }

    final mid = (start + end) ~/ 2;
    final lap = _lapAtIndex(laps, mid);
    final corner = _cornerAtIndex(corners, mid);
    final severity = isSpin
        ? _clamp01(
            0.55 +
                max(0.0, speedDropRatio - config.spinSpeedDropRatio) * 0.35 +
                max(0, activeFlips - config.spinMinFlips) * 0.08,
          )
        : _clamp01(
            0.30 +
                max(0.0, speedDropRatio - config.saveSpeedDropRatio) * 0.35 +
                max(0.0, maxSteering - config.spinSteeringThreshold) * 0.25,
          );

    events.add(TelemetryEvent(
      type: isSpin ? TelemetryEventType.spin : TelemetryEventType.save,
      startedAt: frames[start].timestamp,
      endedAt: frames[end].timestamp,
      startProgress: _wrap01(frames[start].trackProgress),
      endProgress: _wrap01(frames[end].trackProgress),
      severityScore: severity,
      summary:
          '${isSpin ? 'Spin' : 'Save'} detected (${activeFlips.toString()} counter-steers)',
      lapIndex: lap?.lapIndex,
      cornerIndex: corner?.cornerIndex,
      metrics: {
        'flipCount': activeFlips.toDouble(),
        'speedDropRatio': speedDropRatio,
        'netProgress': netProgress,
        'recoveryRatio': recoveryRatio,
      },
    ));

    activeStart = null;
    activeFlips = 0;
    lastFlipAt = -1;
  }

  for (var i = 1; i < points.length; i++) {
    final previous = points[i - 1].steering;
    final current = points[i].steering;
    final flip = previous.abs() >= config.spinSteeringThreshold &&
        current.abs() >= config.spinSteeringThreshold &&
        previous.sign != current.sign;

    if (flip) {
      if (activeStart == null) {
        activeStart = i - 1;
        activeFlips = 1;
        lastFlipAt = i;
      } else {
        final gap = max(
          0.0,
          frames[i]
                  .timestamp
                  .difference(frames[lastFlipAt].timestamp)
                  .inMicroseconds /
              1e6,
        );
        if (gap <= config.spinWindowSeconds) {
          activeFlips++;
          lastFlipAt = i;
        } else {
          closeWindow(lastFlipAt);
          activeStart = i - 1;
          activeFlips = 1;
          lastFlipAt = i;
        }
      }
    }

    if (activeStart != null && lastFlipAt >= 0) {
      final sinceLastFlip = max(
        0.0,
        frames[i]
                .timestamp
                .difference(frames[lastFlipAt].timestamp)
                .inMicroseconds /
            1e6,
      );
      if (sinceLastFlip > config.spinWindowSeconds) {
        closeWindow(lastFlipAt);
      }
    }
  }

  if (activeStart != null && lastFlipAt >= 0) {
    closeWindow(lastFlipAt);
  }

  return events;
}

List<TelemetryEvent> _cleanEventStream(
  List<TelemetryEvent> raw,
  EventDetectionConfig config,
) {
  if (raw.isEmpty) {
    return const [];
  }
  final sorted = List<TelemetryEvent>.of(raw)
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  final merged = <TelemetryEvent>[];
  for (final event in sorted) {
    final clamped =
        event.copyWith(severityScore: _clamp01(event.severityScore));
    if (merged.isEmpty) {
      merged.add(clamped);
      continue;
    }

    final last = merged.last;
    final gapSeconds = max(
      0.0,
      clamped.startedAt.difference(last.endedAt).inMicroseconds / 1e6,
    );
    final sameClass = last.type == clamped.type &&
        last.lapIndex == clamped.lapIndex &&
        last.cornerIndex == clamped.cornerIndex &&
        gapSeconds <= config.mergeGapSeconds;
    if (!sameClass) {
      merged.add(clamped);
      continue;
    }

    final mergedMetrics = <String, double>{}
      ..addAll(last.metrics)
      ..addAll(clamped.metrics);
    merged[merged.length - 1] = last.copyWith(
      endedAt: clamped.endedAt.isAfter(last.endedAt)
          ? clamped.endedAt
          : last.endedAt,
      endProgress: clamped.endProgress,
      severityScore: max(last.severityScore, clamped.severityScore),
      metrics: mergedMetrics,
    );
  }
  return merged;
}

double _turnLoad(TelemetryPoint point) {
  return (point.steering.abs() * 0.72 + point.brake * 0.28)
      .clamp(0.0, 1.0)
      .toDouble();
}

double _progressSpan(double start, double end) {
  var span = _wrap01(end) - _wrap01(start);
  if (span < 0) {
    span += 1.0;
  }
  return span;
}

double _maxSpeedInWindow({
  required List<TelemetryFrame> frames,
  required int startIndex,
  required double horizonSeconds,
}) {
  final startAt = frames[startIndex].timestamp;
  var maxSpeed = frames[startIndex].speedKmh;
  for (var i = startIndex; i < frames.length; i++) {
    final dt = max(
      0.0,
      frames[i].timestamp.difference(startAt).inMicroseconds / 1e6,
    );
    if (dt > horizonSeconds) {
      break;
    }
    maxSpeed = max(maxSpeed, frames[i].speedKmh);
  }
  return maxSpeed;
}

List<double> _buildUnwrappedProgress(List<TelemetryFrame> frames) {
  if (frames.isEmpty) {
    return const [];
  }
  final out = <double>[0.0];
  var accumulator = 0.0;
  var previous = _wrap01(frames.first.trackProgress);
  for (var i = 1; i < frames.length; i++) {
    final current = _wrap01(frames[i].trackProgress);
    var delta = current - previous;
    if (delta > 0.5) {
      delta -= 1.0;
    } else if (delta < -0.5) {
      delta += 1.0;
    }
    accumulator += delta;
    out.add(accumulator);
    previous = current;
  }
  return out;
}

LapSegment? _lapAtIndex(List<LapSegment> laps, int index) {
  for (final lap in laps) {
    if (index >= lap.startIndex && index <= lap.endIndex) {
      return lap;
    }
  }
  return null;
}

CornerSegment? _cornerAtIndex(List<CornerSegment> corners, int index) {
  for (final corner in corners) {
    if (index >= corner.startIndex && index <= corner.endIndex) {
      return corner;
    }
  }
  return null;
}

double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

double _wrap01(double value) {
  final wrapped = value % 1.0;
  return wrapped < 0 ? wrapped + 1.0 : wrapped;
}
