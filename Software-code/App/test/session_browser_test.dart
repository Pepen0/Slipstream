import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/gen/dashboard/v1/dashboard.pb.dart';
import 'package:client/session_browser.dart';

SessionMetadata _session({
  required String id,
  required DateTime start,
  DateTime? end,
  String track = '',
  String car = '',
}) {
  final startNs = start.toUtc().microsecondsSinceEpoch * 1000;
  final endNs = end == null ? 0 : end.toUtc().microsecondsSinceEpoch * 1000;
  final durationMs = end == null ? 0 : end.difference(start).inMilliseconds;

  return SessionMetadata()
    ..sessionId = id
    ..track = track
    ..car = car
    ..startTimeNs = Int64(startNs)
    ..endTimeNs = Int64(endNs)
    ..durationMs = Int64(durationMs);
}

void main() {
  test('track options include all and unique values', () {
    final sessions = <SessionMetadata>[
      _session(id: 's1', start: DateTime(2026, 2, 1), track: ''),
      _session(id: 's2', start: DateTime(2026, 2, 2), track: 'Monza'),
      _session(id: 's3', start: DateTime(2026, 2, 3), track: 'Spa'),
      _session(id: 's4', start: DateTime(2026, 2, 4), track: 'Monza'),
    ];

    final options = trackFilterOptions(sessions);
    expect(options.first, kAllTracksFilter);
    expect(options, contains('Monza'));
    expect(options, contains('Spa'));
    expect(options, contains(kUnknownTrackLabel));
  });

  test('car options include all and unique values', () {
    final sessions = <SessionMetadata>[
      _session(id: 's1', start: DateTime(2026, 2, 1), car: ''),
      _session(id: 's2', start: DateTime(2026, 2, 2), car: 'GT3'),
      _session(id: 's3', start: DateTime(2026, 2, 3), car: 'F4'),
      _session(id: 's4', start: DateTime(2026, 2, 4), car: 'GT3'),
    ];

    final options = carFilterOptions(sessions);
    expect(options.first, kAllCarsFilter);
    expect(options, contains('GT3'));
    expect(options, contains('F4'));
    expect(options, contains(kUnknownCarLabel));
  });

  test('session filters apply date, track, car, and type together', () {
    final now = DateTime(2026, 2, 7, 12, 0, 0);
    final sessions = <SessionMetadata>[
      _session(
        id: 'race-101',
        start: now.subtract(const Duration(days: 2)),
        end:
            now.subtract(const Duration(days: 2)).add(const Duration(hours: 1)),
        track: 'Monza',
        car: 'GT3',
      ),
      _session(
        id: 'practice-7',
        start: now.subtract(const Duration(days: 12)),
        end: now
            .subtract(const Duration(days: 12))
            .add(const Duration(hours: 1)),
        track: 'Monza',
        car: 'F4',
      ),
      _session(
        id: 'race-102',
        start: now.subtract(const Duration(days: 1)),
        end:
            now.subtract(const Duration(days: 1)).add(const Duration(hours: 1)),
        track: 'Spa',
        car: 'GT3',
      ),
    ];

    final filtered = applySessionFilters(
      sessions,
      const SessionBrowserFilters(
        date: SessionDateFilter.last7Days,
        track: 'Monza',
        car: 'GT3',
        type: SessionTypeFilter.race,
      ),
      now: now,
    );

    expect(filtered.length, 1);
    expect(filtered.first.sessionId, 'race-101');
  });

  test('session type classification is inferred from session id and car', () {
    expect(
      classifySessionType(_session(
          id: 'qualifying-a', start: DateTime(2026, 2, 1), car: 'GT3')),
      SessionTypeFilter.qualifying,
    );
    expect(
      classifySessionType(
          _session(id: 'fp2-monza', start: DateTime(2026, 2, 1), car: 'F1')),
      SessionTypeFilter.practice,
    );
    expect(
      classifySessionType(_session(
          id: 'test-run', start: DateTime(2026, 2, 1), car: 'Prototype')),
      SessionTypeFilter.test,
    );
    expect(
      classifySessionType(
          _session(id: 'race-night', start: DateTime(2026, 2, 1), car: 'GT3')),
      SessionTypeFilter.race,
    );
    expect(
      classifySessionType(
          _session(id: 'session-22', start: DateTime(2026, 2, 1), car: 'road')),
      SessionTypeFilter.unknown,
    );
  });

  test('cloud sync state reflects connectivity and session age', () {
    final now = DateTime(2026, 2, 7, 12, 0, 0);
    final baseStart = now.subtract(const Duration(minutes: 8));

    final pending = _session(id: 'pending', start: baseStart, end: null);
    final syncing = _session(
      id: 'syncing',
      start: baseStart,
      end: now.subtract(const Duration(seconds: 10)),
    );
    final synced = _session(
      id: 'synced',
      start: baseStart,
      end: now.subtract(const Duration(minutes: 3)),
    );

    expect(
      inferCloudSyncState(pending, connected: true, now: now),
      CloudSyncState.pending,
    );
    expect(
      inferCloudSyncState(syncing, connected: true, now: now),
      CloudSyncState.syncing,
    );
    expect(
      inferCloudSyncState(synced, connected: true, now: now),
      CloudSyncState.synced,
    );
    expect(
      inferCloudSyncState(synced, connected: false, now: now),
      CloudSyncState.offline,
    );
  });
}
