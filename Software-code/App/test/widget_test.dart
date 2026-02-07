// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/main.dart';

void main() {
  testWidgets('Dashboard renders live and system status views',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DashboardApp());
    expect(find.text('Slipstream Dashboard'), findsOneWidget);
    expect(find.text('Live Dashboard'), findsOneWidget);
    expect(find.byKey(const Key('telemetry-hud')), findsOneWidget);
    expect(find.byKey(const Key('track-map')), findsOneWidget);
    expect(find.byKey(const Key('speed-graph')), findsOneWidget);
    expect(find.byKey(const Key('session-list')), findsOneWidget);
    expect(find.byKey(const Key('session-filter-date')), findsOneWidget);
    expect(find.byKey(const Key('session-filter-track')), findsOneWidget);
    expect(find.byKey(const Key('session-filter-type')), findsOneWidget);
    expect(find.byKey(const Key('voice-console')), findsOneWidget);
    expect(find.byKey(const Key('voice-ptt-button')), findsOneWidget);
    expect(find.byKey(const Key('voice-verbosity-slider')), findsOneWidget);
    expect(find.byKey(const Key('voice-ducking-switch')), findsOneWidget);
    expect(find.byKey(const Key('estop-control')), findsOneWidget);

    await tester.tap(find.text('System Status'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('system-status')), findsOneWidget);
    expect(find.byKey(const Key('fault-panel')), findsOneWidget);
    expect(find.byKey(const Key('safety-zones')), findsOneWidget);
    expect(find.byKey(const Key('firmware-manager')), findsOneWidget);
  });
}
