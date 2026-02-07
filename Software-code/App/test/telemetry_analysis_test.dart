import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:client/telemetry_analysis.dart';

void main() {
  List<TelemetryFrame> buildFrames({int count = 80}) {
    final t0 = DateTime(2026, 1, 1, 12, 0, 0);
    return List.generate(count, (i) {
      final progress = i / (count - 1);
      final speed =
          120 + sin(progress * 2 * pi) * 40 + sin(progress * 8 * pi) * 12;
      return TelemetryFrame(
        timestamp: t0.add(Duration(milliseconds: i * 120)),
        trackProgress: progress,
        speedKmh: speed,
        gear: (2 + (speed / 45).floor()).clamp(1, 6),
        rpm: 2500 + speed * 32,
      );
    });
  }

  test('deriveTelemetryPoints computes normalized derived signals', () {
    final points = deriveTelemetryPoints(buildFrames(count: 50));
    expect(points, hasLength(50));
    expect(points.first.elapsedSeconds, 0);
    expect(
        points.last.elapsedSeconds, greaterThan(points.first.elapsedSeconds));
    expect(points.every((p) => p.throttle >= 0 && p.throttle <= 1), isTrue);
    expect(points.every((p) => p.brake >= 0 && p.brake <= 1), isTrue);
    expect(points.every((p) => p.steering >= -1 && p.steering <= 1), isTrue);
  });

  test('computeGraphViewport honors zoom and pan bounds', () {
    final full = computeGraphViewport(sampleCount: 120, zoom: 1, pan: 0);
    expect(full.startIndex, 0);
    expect(full.endIndex, 119);

    final zoomed = computeGraphViewport(sampleCount: 120, zoom: 4, pan: 0.5);
    expect(zoomed.endIndex - zoomed.startIndex, lessThan(119));
    expect(zoomed.startProgress, greaterThan(0));
    expect(zoomed.endProgress, lessThan(1));
  });

  test('time delta and sector breakdown are generated for compare mode', () {
    final primary = deriveTelemetryPoints(buildFrames(count: 90));
    final reference = buildReferenceLapOverlay(primary, paceGain: 0.97);
    final deltas = buildTimeDeltaSeries(primary, reference);
    final sectors = buildSectorBreakdown(primary, reference: reference);

    expect(deltas, hasLength(primary.length));
    expect(deltas.last.deltaSeconds, greaterThan(0));
    expect(sectors.sectors, hasLength(3));
    expect(sectors.totalPrimarySeconds, greaterThan(0));
    expect(sectors.totalReferenceSeconds, greaterThan(0));
  });

  test('interpolateElapsedAtProgress returns monotonic values', () {
    final points = deriveTelemetryPoints(buildFrames(count: 40));
    final progress = normalizedProgresses(points);
    final t25 = interpolateElapsedAtProgress(points, progress, 0.25);
    final t50 = interpolateElapsedAtProgress(points, progress, 0.50);
    final t75 = interpolateElapsedAtProgress(points, progress, 0.75);

    expect(t25, lessThan(t50));
    expect(t50, lessThan(t75));
  });
}
