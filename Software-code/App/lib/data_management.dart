import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'gen/dashboard/v1/dashboard.pb.dart';
import 'session_browser.dart';
import 'telemetry_analysis.dart';

enum UnitSystem {
  metric,
  imperial,
}

@immutable
class DataManagementPreferences {
  const DataManagementPreferences({
    this.units = UnitSystem.metric,
    this.storageLimitGb = 8.0,
    this.autoDeleteEnabled = false,
    this.autoDeleteRetentionDays = 30,
  });

  final UnitSystem units;
  final double storageLimitGb;
  final bool autoDeleteEnabled;
  final int autoDeleteRetentionDays;

  DataManagementPreferences copyWith({
    UnitSystem? units,
    double? storageLimitGb,
    bool? autoDeleteEnabled,
    int? autoDeleteRetentionDays,
  }) {
    return DataManagementPreferences(
      units: units ?? this.units,
      storageLimitGb: storageLimitGb ?? this.storageLimitGb,
      autoDeleteEnabled: autoDeleteEnabled ?? this.autoDeleteEnabled,
      autoDeleteRetentionDays:
          autoDeleteRetentionDays ?? this.autoDeleteRetentionDays,
    );
  }
}

@immutable
class SessionShareCard {
  const SessionShareCard({
    required this.sessionId,
    required this.headline,
    required this.summary,
    required this.shareCode,
    required this.peakSpeed,
    required this.averageSpeed,
    required this.lapSeconds,
    required this.generatedAt,
  });

  final String sessionId;
  final String headline;
  final String summary;
  final String shareCode;
  final double peakSpeed;
  final double averageSpeed;
  final double lapSeconds;
  final DateTime generatedAt;
}

enum TelemetryExportKind {
  imageSvg,
  videoManifest,
}

@immutable
class TelemetryExportArtifact {
  const TelemetryExportArtifact({
    required this.sessionId,
    required this.kind,
    required this.fileName,
    required this.mimeType,
    required this.payload,
    required this.createdAt,
  });

  final String sessionId;
  final TelemetryExportKind kind;
  final String fileName;
  final String mimeType;
  final String payload;
  final DateTime createdAt;

  int get sizeBytes => utf8.encode(payload).length;
}

double speedForUnits(double speedKmh, UnitSystem units) {
  if (units == UnitSystem.imperial) {
    return speedKmh * 0.621371;
  }
  return speedKmh;
}

String speedUnitLabel(UnitSystem units) {
  return units == UnitSystem.imperial ? 'mph' : 'km/h';
}

SessionShareCard generateHighlightShareCard({
  required SessionMetadata session,
  required List<TelemetryFrame> frames,
  required UnitSystem units,
  DateTime? now,
}) {
  final generatedAt = now ?? DateTime.now();
  final points = deriveTelemetryPoints(frames);
  final peakKmh = points.fold<double>(
      0.0, (maxValue, point) => max(maxValue, point.speedKmh));
  final avgKmh = points.isEmpty
      ? 0.0
      : points.fold<double>(0.0, (sum, point) => sum + point.speedKmh) /
          points.length;
  final lapSeconds = points.isEmpty ? 0.0 : points.last.elapsedSeconds;
  final peakDisplay = speedForUnits(peakKmh, units);
  final avgDisplay = speedForUnits(avgKmh, units);
  final unitLabel = speedUnitLabel(units);
  final headline =
      '${trackLabelForSession(session)} · ${carLabelForSession(session)}';
  final summary =
      'Peak ${peakDisplay.toStringAsFixed(1)} $unitLabel · Avg ${avgDisplay.toStringAsFixed(1)} $unitLabel · Lap ${lapSeconds.toStringAsFixed(2)}s';
  final shareCode = _shareCodeForSession(session, peakKmh, avgKmh, generatedAt);
  return SessionShareCard(
    sessionId: session.sessionId,
    headline: headline,
    summary: summary,
    shareCode: shareCode,
    peakSpeed: peakDisplay,
    averageSpeed: avgDisplay,
    lapSeconds: lapSeconds,
    generatedAt: generatedAt,
  );
}

TelemetryExportArtifact generateImageExportArtifact({
  required SessionMetadata session,
  required List<TelemetryFrame> frames,
  DateTime? now,
}) {
  final createdAt = now ?? DateTime.now();
  final svg = buildTelemetrySnapshotSvg(
    session: session,
    frames: frames,
    generatedAt: createdAt,
  );
  return TelemetryExportArtifact(
    sessionId: session.sessionId,
    kind: TelemetryExportKind.imageSvg,
    fileName: '${session.sessionId}_telemetry_snapshot.svg',
    mimeType: 'image/svg+xml',
    payload: svg,
    createdAt: createdAt,
  );
}

TelemetryExportArtifact generateVideoExportArtifact({
  required SessionMetadata session,
  required List<TelemetryFrame> frames,
  DateTime? now,
}) {
  final createdAt = now ?? DateTime.now();
  final manifest = buildTelemetryVideoManifest(
    session: session,
    frames: frames,
    generatedAt: createdAt,
  );
  return TelemetryExportArtifact(
    sessionId: session.sessionId,
    kind: TelemetryExportKind.videoManifest,
    fileName: '${session.sessionId}_telemetry_replay.json',
    mimeType: 'application/json',
    payload: manifest,
    createdAt: createdAt,
  );
}

String buildTelemetrySnapshotSvg({
  required SessionMetadata session,
  required List<TelemetryFrame> frames,
  required DateTime generatedAt,
  int width = 960,
  int height = 420,
}) {
  final safeWidth = max(320, width);
  final safeHeight = max(200, height);
  final left = 52.0;
  final right = safeWidth - 36.0;
  final top = 44.0;
  final bottom = safeHeight - 54.0;
  final plotWidth = max(12.0, right - left);
  final plotHeight = max(12.0, bottom - top);

  if (frames.length < 2) {
    return '''
<svg xmlns="http://www.w3.org/2000/svg" width="$safeWidth" height="$safeHeight" viewBox="0 0 $safeWidth $safeHeight">
  <rect x="0" y="0" width="$safeWidth" height="$safeHeight" fill="#121923"/>
  <text x="24" y="30" fill="#44D9FF" font-size="18" font-family="monospace">Telemetry Snapshot · ${session.sessionId}</text>
  <text x="24" y="90" fill="#9FB3C8" font-size="14" font-family="monospace">No telemetry samples available</text>
  <text x="24" y="${safeHeight - 18}" fill="#9FB3C8" font-size="12" font-family="monospace">Generated ${generatedAt.toIso8601String()}</text>
</svg>
''';
  }

  final sampled = _sampleFrames(frames, maxPoints: 260);
  var minSpeed = sampled.first.speedKmh;
  var maxSpeed = sampled.first.speedKmh;
  for (final frame in sampled) {
    minSpeed = min(minSpeed, frame.speedKmh);
    maxSpeed = max(maxSpeed, frame.speedKmh);
  }
  final span = max(1.0, maxSpeed - minSpeed);
  final path = StringBuffer();
  for (var i = 0; i < sampled.length; i++) {
    final frame = sampled[i];
    final t = sampled.length > 1 ? (i / (sampled.length - 1)) : 0.0;
    final x = left + plotWidth * t;
    final normalized = (frame.speedKmh - minSpeed) / span;
    final y = bottom - plotHeight * normalized;
    path.write(i == 0
        ? 'M${x.toStringAsFixed(2)} ${y.toStringAsFixed(2)}'
        : ' L${x.toStringAsFixed(2)} ${y.toStringAsFixed(2)}');
  }

  return '''
<svg xmlns="http://www.w3.org/2000/svg" width="$safeWidth" height="$safeHeight" viewBox="0 0 $safeWidth $safeHeight">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#121923"/>
      <stop offset="100%" stop-color="#1A2431"/>
    </linearGradient>
  </defs>
  <rect x="0" y="0" width="$safeWidth" height="$safeHeight" fill="url(#bg)"/>
  <text x="24" y="28" fill="#44D9FF" font-size="18" font-family="monospace">Telemetry Snapshot · ${session.sessionId}</text>
  <text x="24" y="48" fill="#9FB3C8" font-size="12" font-family="monospace">${trackLabelForSession(session)} · ${carLabelForSession(session)}</text>
  <line x1="$left" y1="$top" x2="$left" y2="$bottom" stroke="#243344" stroke-width="1"/>
  <line x1="$left" y1="$bottom" x2="$right" y2="$bottom" stroke="#243344" stroke-width="1"/>
  <path d="${path.toString()}" fill="none" stroke="#44D9FF" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round"/>
  <text x="$left" y="${safeHeight - 24}" fill="#9FB3C8" font-size="11" font-family="monospace">min ${minSpeed.toStringAsFixed(1)} km/h</text>
  <text x="${right - 120}" y="${safeHeight - 24}" fill="#9FB3C8" font-size="11" font-family="monospace">max ${maxSpeed.toStringAsFixed(1)} km/h</text>
  <text x="24" y="${safeHeight - 8}" fill="#9FB3C8" font-size="11" font-family="monospace">Generated ${generatedAt.toIso8601String()}</text>
</svg>
''';
}

String buildTelemetryVideoManifest({
  required SessionMetadata session,
  required List<TelemetryFrame> frames,
  required DateTime generatedAt,
  int frameRate = 12,
}) {
  final sampled = _sampleFrames(frames, maxPoints: 320);
  final payload = <String, Object>{
    'format': 'telemetry-video-manifest/v1',
    'sessionId': session.sessionId,
    'track': trackLabelForSession(session),
    'car': carLabelForSession(session),
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'frameRate': max(1, frameRate),
    'frames': sampled
        .map((frame) => <String, Object>{
              'timestampNs':
                  frame.timestamp.toUtc().microsecondsSinceEpoch * 1000,
              'speedKmh': double.parse(frame.speedKmh.toStringAsFixed(3)),
              'trackProgress':
                  double.parse(frame.trackProgress.toStringAsFixed(6)),
              'gear': frame.gear,
              'rpm': double.parse(frame.rpm.toStringAsFixed(1)),
            })
        .toList(growable: false),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

double estimateTelemetryStorageMb({required int sampleCount}) {
  if (sampleCount <= 0) {
    return 0.0;
  }
  const bytesPerSample = 72.0;
  return (sampleCount * bytesPerSample) / (1024 * 1024);
}

double estimatedArchiveStorageMb({
  required Map<String, int> sessionSampleCounts,
  required List<TelemetryExportArtifact> exports,
}) {
  var total = 0.0;
  for (final count in sessionSampleCounts.values) {
    total += estimateTelemetryStorageMb(sampleCount: count);
  }
  for (final export in exports) {
    total += export.sizeBytes / (1024 * 1024);
  }
  return total;
}

bool wouldExceedStorageLimit({
  required double currentUsageMb,
  required int nextArtifactBytes,
  required double storageLimitGb,
}) {
  final limitMb = max(0.25, storageLimitGb) * 1024;
  final projected = currentUsageMb + (nextArtifactBytes / (1024 * 1024));
  return projected > limitMb;
}

List<SessionMetadata> autoDeleteCandidates(
  List<SessionMetadata> sessions, {
  required DateTime now,
  required int retentionDays,
}) {
  final safeRetention = max(1, retentionDays);
  final cutoff = now.toLocal().subtract(Duration(days: safeRetention));
  return sessions.where((session) {
    final timestamp = sessionTimestamp(session);
    if (timestamp == null) {
      return false;
    }
    return timestamp.isBefore(cutoff);
  }).toList(growable: false);
}

List<TelemetryFrame> _sampleFrames(List<TelemetryFrame> frames,
    {required int maxPoints}) {
  if (frames.isEmpty || frames.length <= maxPoints) {
    return frames;
  }
  final stride = max(1, frames.length ~/ maxPoints);
  final sampled = <TelemetryFrame>[];
  for (var i = 0; i < frames.length; i += stride) {
    sampled.add(frames[i]);
  }
  if (sampled.last != frames.last) {
    sampled.add(frames.last);
  }
  return sampled;
}

String _shareCodeForSession(
  SessionMetadata session,
  double peakKmh,
  double avgKmh,
  DateTime generatedAt,
) {
  final seed = '${session.sessionId}|${session.startTimeNs}|'
      '${peakKmh.toStringAsFixed(3)}|${avgKmh.toStringAsFixed(3)}|'
      '${generatedAt.microsecondsSinceEpoch}';
  final checksum = seed.codeUnits
      .fold<int>(7, (value, code) => ((value * 131) + code) & 0x7fffffff);
  return checksum.toRadixString(36).toUpperCase().padLeft(7, '0');
}
