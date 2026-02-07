import 'dart:convert';
import 'dart:math';

import 'package:client/data_management.dart';
import 'package:client/gen/dashboard/v1/dashboard.pb.dart';
import 'package:client/telemetry_analysis.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

SessionMetadata _session({
  required String id,
  required DateTime start,
  DateTime? end,
  String track = 'Monza',
  String car = 'GT3',
}) {
  return SessionMetadata()
    ..sessionId = id
    ..track = track
    ..car = car
    ..startTimeNs = Int64(start.toUtc().microsecondsSinceEpoch * 1000)
    ..endTimeNs = Int64((end ?? start).toUtc().microsecondsSinceEpoch * 1000)
    ..durationMs = Int64(
        ((end ?? start).difference(start)).inMilliseconds.clamp(0, 9999999));
}

List<TelemetryFrame> _frames({int count = 80}) {
  final t0 = DateTime(2026, 1, 1, 12, 0, 0);
  return List.generate(count, (i) {
    final progress = i / (count - 1);
    final speed =
        110 + sin(progress * pi * 2) * 35 + sin(progress * pi * 8) * 9;
    return TelemetryFrame(
      timestamp: t0.add(Duration(milliseconds: i * 110)),
      trackProgress: progress,
      speedKmh: speed,
      gear: (2 + (speed / 45).floor()).clamp(1, 6),
      rpm: 2600 + speed * 31,
    );
  });
}

void main() {
  test('share card generation produces track/car summary and code', () {
    final session = _session(id: 'sess-01', start: DateTime(2026, 1, 1));
    final card = generateHighlightShareCard(
      session: session,
      frames: _frames(),
      units: UnitSystem.metric,
      now: DateTime(2026, 2, 1, 10, 0, 0),
    );
    expect(card.headline, contains('Monza'));
    expect(card.headline, contains('GT3'));
    expect(card.summary, contains('Peak'));
    expect(card.summary, contains('Lap'));
    expect(card.shareCode.length, greaterThanOrEqualTo(7));
  });

  test('image export produces svg payload', () {
    final session = _session(id: 'sess-02', start: DateTime(2026, 1, 1));
    final artifact = generateImageExportArtifact(
      session: session,
      frames: _frames(),
      now: DateTime(2026, 2, 1, 10, 0, 0),
    );
    expect(artifact.kind, TelemetryExportKind.imageSvg);
    expect(artifact.fileName, endsWith('.svg'));
    expect(artifact.mimeType, 'image/svg+xml');
    expect(artifact.payload, contains('<svg'));
    expect(artifact.payload, contains(session.sessionId));
  });

  test('video export produces manifest payload', () {
    final session = _session(id: 'sess-03', start: DateTime(2026, 1, 1));
    final artifact = generateVideoExportArtifact(
      session: session,
      frames: _frames(count: 120),
      now: DateTime(2026, 2, 1, 10, 0, 0),
    );
    final decoded = jsonDecode(artifact.payload) as Map<String, dynamic>;
    expect(artifact.kind, TelemetryExportKind.videoManifest);
    expect(artifact.fileName, endsWith('.json'));
    expect(decoded['format'], 'telemetry-video-manifest/v1');
    expect(decoded['sessionId'], 'sess-03');
    expect((decoded['frames'] as List<dynamic>).isNotEmpty, isTrue);
  });

  test('storage helpers estimate usage and enforce limit', () {
    final image = generateImageExportArtifact(
      session: _session(id: 'sess-04', start: DateTime(2026, 1, 1)),
      frames: _frames(count: 60),
      now: DateTime(2026, 2, 1, 10, 0, 0),
    );
    final usage = estimatedArchiveStorageMb(
      sessionSampleCounts: const {'sess-04': 60, 'sess-05': 200},
      exports: [image],
    );
    expect(usage, greaterThan(0));
    expect(
      wouldExceedStorageLimit(
        currentUsageMb: usage,
        nextArtifactBytes: 420 * 1024 * 1024,
        storageLimitGb: 0.01,
      ),
      isTrue,
    );
  });

  test('auto-delete candidates include only sessions older than retention', () {
    final now = DateTime(2026, 2, 7, 12, 0, 0);
    final fresh = _session(
      id: 'fresh',
      start: now.subtract(const Duration(days: 4)),
      end: now
          .subtract(const Duration(days: 4))
          .add(const Duration(minutes: 10)),
    );
    final old = _session(
      id: 'old',
      start: now.subtract(const Duration(days: 40)),
      end: now
          .subtract(const Duration(days: 40))
          .add(const Duration(minutes: 10)),
    );
    final out = autoDeleteCandidates(
      [fresh, old],
      now: now,
      retentionDays: 30,
    );
    expect(out.map((s) => s.sessionId), contains('old'));
    expect(out.map((s) => s.sessionId), isNot(contains('fresh')));
  });
}
