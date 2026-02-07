import 'dart:math';

import 'package:client/gen/dashboard/v1/dashboard.pb.dart';
import 'package:client/main.dart';
import 'package:client/services/dashboard_client.dart';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardClient extends DashboardClient {
  _FakeDashboardClient({
    required this.sessions,
    required this.telemetryBySession,
  }) : super(host: '127.0.0.1', port: 50060);

  final List<SessionMetadata> sessions;
  final Map<String, List<TelemetrySample>> telemetryBySession;
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
  Future<List<SessionMetadata>> listSessions() async => sessions;

  @override
  Future<List<TelemetrySample>> getSessionTelemetry(
    String sessionId, {
    int maxSamples = 240,
  }) async {
    final all = telemetryBySession[sessionId] ?? const <TelemetrySample>[];
    if (all.length <= maxSamples) {
      return List.of(all);
    }
    return all.sublist(all.length - maxSamples);
  }

  @override
  void startTelemetryStream({String sessionId = ''}) {}

  @override
  Future<void> setEStop(bool engaged, {String reason = ''}) async {}
}

SessionMetadata _buildSession(String sessionId) {
  final start = DateTime(2026, 1, 1, 12, 0, 0);
  final end = start.add(const Duration(minutes: 1, seconds: 36));
  return SessionMetadata(
    sessionId: sessionId,
    track: 'Laguna Seca',
    car: 'GT3',
    startTimeNs: fixnum.Int64(start.microsecondsSinceEpoch * 1000),
    endTimeNs: fixnum.Int64(end.microsecondsSinceEpoch * 1000),
    durationMs: fixnum.Int64(end.difference(start).inMilliseconds),
  );
}

List<TelemetrySample> _buildTelemetrySamples({int count = 200}) {
  final t0Ns = DateTime(2026, 1, 1, 12, 0, 0).microsecondsSinceEpoch * 1000;
  return List.generate(count, (i) {
    final progress = i / (count - 1);
    final speed =
        120 + sin(progress * 2 * pi) * 42 + sin(progress * 8 * pi) * 11;
    return TelemetrySample(
      timestampNs: fixnum.Int64(t0Ns + i * 120000000),
      speedKmh: speed,
      gear: (2 + (speed / 42).floor()).clamp(1, 6),
      engineRpm: 2500 + speed * 32,
      trackProgress: progress,
      latencyMs: 3.2,
    );
  });
}

void main() {
  testWidgets(
      'Review mode exposes telemetry analysis tools and interaction controls',
      (WidgetTester tester) async {
    final session = _buildSession('sess-analysis-001');
    final telemetry = _buildTelemetrySamples();
    final fakeClient = _FakeDashboardClient(
      sessions: [session],
      telemetryBySession: {session.sessionId: telemetry},
    );

    await tester.pumpWidget(DashboardApp(clientFactory: () => fakeClient));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session-list')), findsOneWidget);
    final openButton = find.widgetWithText(OutlinedButton, 'Open').first;
    expect(openButton, findsOneWidget);

    await tester.ensureVisible(openButton);
    await tester.pumpAndSettle();
    await tester.tap(openButton);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('telemetry-analysis-panel')), findsOneWidget);
    expect(
        find.byKey(const Key('analysis-multi-signal-graph')), findsOneWidget);
    expect(find.byKey(const Key('analysis-delta-graph')), findsOneWidget);
    expect(find.byKey(const Key('analysis-sector-breakdown')), findsOneWidget);
    expect(find.byKey(const Key('causality-feedback-spine')), findsOneWidget);
    expect(find.byKey(const Key('analysis-compare-switch')), findsOneWidget);
    expect(find.byKey(const Key('analysis-zoom-slider')), findsOneWidget);
    expect(find.byKey(const Key('analysis-pan-slider')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('analysis-zoom-slider')));
    await tester.pumpAndSettle();

    final initialLabel =
        tester.widget<Text>(find.byKey(const Key('analysis-scrub-label'))).data;

    final panSliderBefore =
        tester.widget<Slider>(find.byKey(const Key('analysis-pan-slider')));
    expect(panSliderBefore.onChanged, isNull);

    await tester.drag(
      find.byKey(const Key('analysis-zoom-slider')),
      const Offset(220, 0),
    );
    await tester.pumpAndSettle();

    final panSliderAfter =
        tester.widget<Slider>(find.byKey(const Key('analysis-pan-slider')));
    expect(panSliderAfter.onChanged, isNotNull);

    final trackMapPainterFinder = find
        .descendant(
          of: find.byKey(const Key('track-map')),
          matching: find.byType(CustomPaint),
        )
        .first;
    final trackMapPainterBefore =
        tester.widget<CustomPaint>(trackMapPainterFinder).painter;

    final reviewScrubSlider = find
        .descendant(
          of: find.byKey(const Key('speed-graph')),
          matching: find.byType(Slider),
        )
        .first;
    await tester.ensureVisible(reviewScrubSlider);
    await tester.pumpAndSettle();
    await tester.drag(reviewScrubSlider, const Offset(-220, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    final currentLabel =
        tester.widget<Text>(find.byKey(const Key('analysis-scrub-label'))).data;
    expect(currentLabel, isNot(equals(initialLabel)));
    expect(find.text('Review scrub active'), findsOneWidget);

    final trackMapPainterAfter =
        tester.widget<CustomPaint>(trackMapPainterFinder).painter;
    expect(trackMapPainterAfter, isNot(same(trackMapPainterBefore)));

    final compareSwitch = find.byKey(const Key('analysis-compare-switch'));
    await tester.ensureVisible(compareSwitch);
    await tester.pumpAndSettle();
    await tester.tap(compareSwitch);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('analysis-delta-graph')), findsNothing);
    expect(find.byKey(const Key('analysis-sector-breakdown')), findsOneWidget);
  });
}
