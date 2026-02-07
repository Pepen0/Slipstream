import 'dart:math';

import 'package:flutter/foundation.dart';

@immutable
class TelemetryFrame {
  const TelemetryFrame({
    required this.timestamp,
    required this.trackProgress,
    required this.speedKmh,
    required this.gear,
    required this.rpm,
    this.wheelSpeedDeltaKmh,
    this.lateralG,
  });

  final DateTime timestamp;
  final double trackProgress;
  final double speedKmh;
  final int gear;
  final double rpm;
  final double? wheelSpeedDeltaKmh;
  final double? lateralG;
}

@immutable
class TelemetryPoint {
  const TelemetryPoint({
    required this.elapsedSeconds,
    required this.trackProgress,
    required this.speedKmh,
    required this.throttle,
    required this.brake,
    required this.steering,
  });

  final double elapsedSeconds;
  final double trackProgress;
  final double speedKmh;
  final double throttle;
  final double brake;
  final double steering;
}

@immutable
class TimeDeltaPoint {
  const TimeDeltaPoint({
    required this.progress,
    required this.deltaSeconds,
  });

  final double progress;
  final double deltaSeconds;
}

@immutable
class SectorSplit {
  const SectorSplit({
    required this.sector,
    required this.primarySeconds,
    required this.referenceSeconds,
  });

  final int sector;
  final double primarySeconds;
  final double referenceSeconds;

  double get deltaSeconds => primarySeconds - referenceSeconds;
}

@immutable
class SectorBreakdown {
  const SectorBreakdown({
    required this.sectors,
    required this.totalPrimarySeconds,
    required this.totalReferenceSeconds,
  });

  final List<SectorSplit> sectors;
  final double totalPrimarySeconds;
  final double totalReferenceSeconds;

  double get totalDeltaSeconds => totalPrimarySeconds - totalReferenceSeconds;
}

@immutable
class GraphViewport {
  const GraphViewport({
    required this.startIndex,
    required this.endIndex,
    required this.startProgress,
    required this.endProgress,
  });

  final int startIndex;
  final int endIndex;
  final double startProgress;
  final double endProgress;
}

List<TelemetryPoint> deriveTelemetryPoints(List<TelemetryFrame> frames) {
  if (frames.isEmpty) {
    return const [];
  }
  final first = frames.first.timestamp;
  final points = <TelemetryPoint>[];
  var prevSpeed = frames.first.speedKmh;
  var prevProgress = _wrap01(frames.first.trackProgress);
  var prevDelta = 0.0;

  for (var i = 0; i < frames.length; i++) {
    final frame = frames[i];
    final progress = _wrap01(frame.trackProgress);
    final elapsedMs = frame.timestamp.difference(first).inMilliseconds;
    final elapsed = max(0.0, elapsedMs / 1000.0);
    final dt = i == 0
        ? 0.05
        : max(
            0.02,
            (frame.timestamp
                    .difference(frames[i - 1].timestamp)
                    .inMilliseconds) /
                1000.0);
    final accel = (frame.speedKmh - prevSpeed) / 3.6 / dt;
    var progressDelta = progress - prevProgress;
    if (progressDelta > 0.5) {
      progressDelta -= 1.0;
    } else if (progressDelta < -0.5) {
      progressDelta += 1.0;
    }
    final curvature = (progressDelta - prevDelta) / dt;

    final throttle = ((accel * 0.45) + 0.42 + (frame.rpm / 12000))
        .clamp(0.0, 1.0)
        .toDouble();
    final brake = ((-accel * 0.35) + (frame.speedKmh > 35 ? 0.03 : 0.0))
        .clamp(0.0, 1.0)
        .toDouble();
    final steering = ((curvature * 260) + sin(progress * 2 * pi) * 0.25)
        .clamp(-1.0, 1.0)
        .toDouble();

    points.add(TelemetryPoint(
      elapsedSeconds: elapsed,
      trackProgress: progress,
      speedKmh: frame.speedKmh.clamp(0.0, 420.0).toDouble(),
      throttle: throttle,
      brake: brake,
      steering: steering,
    ));

    prevSpeed = frame.speedKmh;
    prevProgress = progress;
    prevDelta = progressDelta;
  }
  return points;
}

List<TelemetryPoint> buildReferenceLapOverlay(
  List<TelemetryPoint> source, {
  double paceGain = 0.972,
}) {
  if (source.isEmpty) {
    return const [];
  }
  final normalized = normalizedProgresses(source);
  final out = <TelemetryPoint>[];
  for (var i = 0; i < source.length; i++) {
    final point = source[i];
    final progress = normalized[i];
    final pulse = sin(progress * 6 * pi) * 0.018;
    final speedBoost = 1.015 + sin(progress * 2 * pi) * 0.01;
    out.add(TelemetryPoint(
      elapsedSeconds: max(0.0, point.elapsedSeconds * paceGain + pulse),
      trackProgress: progress,
      speedKmh: (point.speedKmh * speedBoost).clamp(0.0, 420.0).toDouble(),
      throttle: (point.throttle + 0.03).clamp(0.0, 1.0).toDouble(),
      brake: (point.brake * 0.92).clamp(0.0, 1.0).toDouble(),
      steering: point.steering * 0.95,
    ));
  }
  return out;
}

GraphViewport computeGraphViewport({
  required int sampleCount,
  required double zoom,
  required double pan,
}) {
  if (sampleCount <= 1) {
    return const GraphViewport(
      startIndex: 0,
      endIndex: 0,
      startProgress: 0,
      endProgress: 1,
    );
  }
  final safeZoom = zoom.clamp(1.0, 12.0).toDouble();
  final desired = (sampleCount / safeZoom).round();
  final windowCount = desired.clamp(2, sampleCount).toInt();
  final maxStart = sampleCount - windowCount;
  final start = (pan.clamp(0.0, 1.0).toDouble() * maxStart).round();
  final end = start + windowCount - 1;
  final denom = sampleCount - 1;
  return GraphViewport(
    startIndex: start,
    endIndex: end,
    startProgress: start / denom,
    endProgress: end / denom,
  );
}

List<TimeDeltaPoint> buildTimeDeltaSeries(
  List<TelemetryPoint> primary,
  List<TelemetryPoint> reference,
) {
  if (primary.length < 2 || reference.length < 2) {
    return const [];
  }
  final primaryProgress = normalizedProgresses(primary);
  final referenceProgress = normalizedProgresses(reference);
  final deltas = <TimeDeltaPoint>[];
  for (var i = 0; i < primary.length; i++) {
    final progress = primaryProgress[i];
    final pTime = primary[i].elapsedSeconds;
    final rTime =
        interpolateElapsedAtProgress(reference, referenceProgress, progress);
    deltas.add(TimeDeltaPoint(progress: progress, deltaSeconds: pTime - rTime));
  }
  return deltas;
}

SectorBreakdown buildSectorBreakdown(
  List<TelemetryPoint> primary, {
  List<TelemetryPoint>? reference,
}) {
  if (primary.length < 2) {
    return const SectorBreakdown(
      sectors: [],
      totalPrimarySeconds: 0,
      totalReferenceSeconds: 0,
    );
  }
  final primaryProgress = normalizedProgresses(primary);
  final ref = reference ?? buildReferenceLapOverlay(primary);
  final refProgress = normalizedProgresses(ref);
  final cuts = <double>[0.0, 1 / 3, 2 / 3, 1.0];
  final sectors = <SectorSplit>[];
  for (var i = 0; i < 3; i++) {
    final start = cuts[i];
    final end = cuts[i + 1];
    final pStart =
        interpolateElapsedAtProgress(primary, primaryProgress, start);
    final pEnd = interpolateElapsedAtProgress(primary, primaryProgress, end);
    final rStart = interpolateElapsedAtProgress(ref, refProgress, start);
    final rEnd = interpolateElapsedAtProgress(ref, refProgress, end);
    sectors.add(SectorSplit(
      sector: i + 1,
      primarySeconds: max(0.0, pEnd - pStart),
      referenceSeconds: max(0.0, rEnd - rStart),
    ));
  }
  final totalPrimary =
      sectors.fold<double>(0.0, (sum, s) => sum + s.primarySeconds);
  final totalReference =
      sectors.fold<double>(0.0, (sum, s) => sum + s.referenceSeconds);
  return SectorBreakdown(
    sectors: sectors,
    totalPrimarySeconds: totalPrimary,
    totalReferenceSeconds: totalReference,
  );
}

List<double> normalizedProgresses(List<TelemetryPoint> points) {
  if (points.isEmpty) {
    return const [];
  }
  final unwrapped = <double>[0.0];
  var accum = 0.0;
  var prev = _wrap01(points.first.trackProgress);
  for (var i = 1; i < points.length; i++) {
    final current = _wrap01(points[i].trackProgress);
    var delta = current - prev;
    if (delta > 0.5) {
      delta -= 1.0;
    } else if (delta < -0.5) {
      delta += 1.0;
    }
    accum += max(0.0, delta);
    unwrapped.add(accum);
    prev = current;
  }
  final span = max(unwrapped.last, 1e-6);
  return unwrapped.map((v) => (v / span).clamp(0.0, 1.0).toDouble()).toList();
}

double interpolateElapsedAtProgress(
  List<TelemetryPoint> points,
  List<double> normalized,
  double progress,
) {
  if (points.isEmpty) {
    return 0.0;
  }
  final target = progress.clamp(0.0, 1.0).toDouble();
  if (normalized.length != points.length || points.length == 1) {
    return points.last.elapsedSeconds;
  }
  if (target <= normalized.first) {
    return points.first.elapsedSeconds;
  }
  if (target >= normalized.last) {
    return points.last.elapsedSeconds;
  }
  for (var i = 1; i < normalized.length; i++) {
    final prev = normalized[i - 1];
    final next = normalized[i];
    if (target <= next) {
      final span = max(next - prev, 1e-6);
      final local = (target - prev) / span;
      final a = points[i - 1].elapsedSeconds;
      final b = points[i].elapsedSeconds;
      return a + (b - a) * local;
    }
  }
  return points.last.elapsedSeconds;
}

double _wrap01(double value) {
  final wrapped = value % 1.0;
  return wrapped < 0 ? wrapped + 1.0 : wrapped;
}
