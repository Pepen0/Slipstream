import 'dart:math';

import 'package:client/gen/dashboard/v1/dashboard.pb.dart';
import 'package:client/main.dart';
import 'package:client/services/dashboard_client.dart';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardClient extends DashboardClient {
  _FakeDashboardClient({
    required List<SessionMetadata> sessions,
    required this.telemetryBySession,
  })  : _sessions = List<SessionMetadata>.of(sessions),
        super(host: '127.0.0.1', port: 50060);

  final Map<String, List<TelemetrySample>> telemetryBySession;
  final List<SessionMetadata> _sessions;
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _connected = true;
    snapshot.value = DashboardSnapshot(
      status: Status()
        ..sessionActive = false
        ..sessionId = ''
        ..updatedAtNs =
            fixnum.Int64(DateTime.now().microsecondsSinceEpoch * 1000),
      connected: true,
    );
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    snapshot.value = snapshot.value.copyWith(connected: false, error: null);
  }

  @override
  Future<void> refreshStatus() async {}

  @override
  Future<List<SessionMetadata>> listSessions() async =>
      List<SessionMetadata>.of(_sessions);

  @override
  Future<List<TelemetrySample>> getSessionTelemetry(
    String sessionId, {
    int maxSamples = 240,
  }) async {
    final all = telemetryBySession[sessionId] ?? const <TelemetrySample>[];
    if (all.length <= maxSamples) {
      return List<TelemetrySample>.of(all);
    }
    return all.sublist(all.length - maxSamples);
  }

  @override
  Future<bool> deleteSession(String sessionId) async {
    _sessions.removeWhere((session) => session.sessionId == sessionId);
    telemetryBySession.remove(sessionId);
    return true;
  }

  @override
  Future<void> setEStop(bool engaged, {String reason = ''}) async {}

  @override
  void startTelemetryStream({String sessionId = ''}) {}
}

SessionMetadata _session({
  required String id,
  required DateTime start,
  String track = 'Monza',
  String car = 'GT3',
}) {
  final end = start.add(const Duration(minutes: 12));
  return SessionMetadata(
    sessionId: id,
    track: track,
    car: car,
    startTimeNs: fixnum.Int64(start.microsecondsSinceEpoch * 1000),
    endTimeNs: fixnum.Int64(end.microsecondsSinceEpoch * 1000),
    durationMs: fixnum.Int64(end.difference(start).inMilliseconds),
  );
}

List<TelemetrySample> _telemetry({int count = 150}) {
  final t0Ns = DateTime(2026, 2, 1, 12, 0, 0).microsecondsSinceEpoch * 1000;
  return List.generate(count, (i) {
    final progress = i / (count - 1);
    final speed =
        105 + sin(progress * 2 * pi) * 32 + sin(progress * 8 * pi) * 10;
    return TelemetrySample(
      timestampNs: fixnum.Int64(t0Ns + i * 100000000),
      speedKmh: speed,
      gear: (2 + (speed / 40).floor()).clamp(1, 6),
      engineRpm: 2500 + speed * 30,
      trackProgress: progress,
      latencyMs: 3.0,
    );
  });
}

void main() {
  testWidgets('data management supports share/export/delete and auto-delete',
      (WidgetTester tester) async {
    final now = DateTime(2026, 2, 7, 12, 0, 0);
    final oldSession =
        _session(id: 'sess-old', start: now.subtract(const Duration(days: 75)));
    final newSession =
        _session(id: 'sess-new', start: now.subtract(const Duration(days: 3)));

    final client = _FakeDashboardClient(
      sessions: [oldSession, newSession],
      telemetryBySession: {
        oldSession.sessionId: _telemetry(),
        newSession.sessionId: _telemetry(),
      },
    );

    await tester.pumpWidget(DashboardApp(clientFactory: () => client));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('sess-old'), findsOneWidget);
    expect(find.text('sess-new'), findsOneWidget);

    await tester.tap(find.text('Data & Sharing'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('data-management-screen')), findsOneWidget);
    final sessionNewInData = find
        .descendant(
          of: find.byKey(const Key('data-management-screen')),
          matching: find.text('sess-new'),
        )
        .first;
    await tester.ensureVisible(sessionNewInData);
    await tester.pumpAndSettle();
    await tester.tap(sessionNewInData);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('share-card-generate')), findsOneWidget);
    expect(find.byKey(const Key('export-image-button')), findsOneWidget);
    expect(find.byKey(const Key('export-video-button')), findsOneWidget);

    final shareCardButton = find.byKey(const Key('share-card-generate'));
    await tester.ensureVisible(shareCardButton);
    await tester.pumpAndSettle();
    await tester.tap(shareCardButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('share-card-preview')), findsOneWidget);

    final exportImageButton = find.byKey(const Key('export-image-button'));
    await tester.ensureVisible(exportImageButton);
    await tester.pumpAndSettle();
    await tester.tap(exportImageButton);
    await tester.pumpAndSettle();
    final exportVideoButton = find.byKey(const Key('export-video-button'));
    await tester.ensureVisible(exportVideoButton);
    await tester.pumpAndSettle();
    await tester.tap(exportVideoButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('export-history')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('export-history')),
        matching: find.textContaining('_telemetry_snapshot.svg'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('export-history')),
        matching: find.textContaining('_telemetry_replay.json'),
      ),
      findsOneWidget,
    );

    final autoDeleteSwitch =
        find.byKey(const Key('preferences-autodelete-switch'));
    await tester.ensureVisible(autoDeleteSwitch);
    await tester.pumpAndSettle();
    await tester.tap(autoDeleteSwitch);
    await tester.pumpAndSettle();
    expect(find.text('sess-old'), findsNothing);

    final deleteSelected = find.byKey(const Key('archive-delete-sess-new'));
    await tester.ensureVisible(deleteSelected);
    await tester.pumpAndSettle();
    await tester.tap(deleteSelected);
    await tester.pumpAndSettle();
    expect(find.text('sess-new'), findsNothing);
    expect(find.byKey(const Key('share-card-preview')), findsNothing);
  });
}
