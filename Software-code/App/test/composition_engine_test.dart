import 'package:flutter_test/flutter_test.dart';

import 'package:client/composition_engine.dart';

void main() {
  test('transitions from pre-race to live to post-race', () {
    final engine = BroadcastCompositionEngine();
    final t0 = DateTime(2026, 1, 1, 12, 0, 0);

    expect(engine.phase, BroadcastRacePhase.preRace);

    final live = engine.update(
      sessionActive: true,
      speedKmh: 124,
      now: t0,
    );
    expect(live.phase, BroadcastRacePhase.live);
    expect(live.phaseChanged, isTrue);

    final post = engine.update(
      sessionActive: false,
      speedKmh: 48,
      now: t0.add(const Duration(seconds: 1)),
    );
    expect(post.phase, BroadcastRacePhase.postRace);
    expect(post.phaseChanged, isTrue);
  });

  test('auto-transitions to summary mode after sustained stop', () {
    final engine = BroadcastCompositionEngine(
      summaryStopSpeedKmh: 2.0,
      summaryStopDuration: const Duration(seconds: 3),
    );
    final t0 = DateTime(2026, 1, 1, 12, 0, 0);

    engine.update(sessionActive: true, speedKmh: 95, now: t0);
    engine.update(
      sessionActive: false,
      speedKmh: 20,
      now: t0.add(const Duration(seconds: 1)),
    );
    engine.update(
      sessionActive: false,
      speedKmh: 1.5,
      now: t0.add(const Duration(seconds: 2)),
    );

    final summary = engine.update(
      sessionActive: false,
      speedKmh: 0.4,
      now: t0.add(const Duration(seconds: 5)),
    );
    expect(summary.phase, BroadcastRacePhase.summary);
    expect(summary.summaryAutoTriggered, isTrue);
  });

  test('summary falls back to post-race if movement resumes', () {
    final engine = BroadcastCompositionEngine(
      summaryStopSpeedKmh: 2.0,
      summaryStopDuration: const Duration(seconds: 2),
    );
    final t0 = DateTime(2026, 1, 1, 12, 0, 0);

    engine.update(sessionActive: true, speedKmh: 90, now: t0);
    engine.update(
      sessionActive: false,
      speedKmh: 1.0,
      now: t0.add(const Duration(seconds: 1)),
    );
    engine.update(
      sessionActive: false,
      speedKmh: 0.0,
      now: t0.add(const Duration(seconds: 3)),
    );
    expect(engine.phase, BroadcastRacePhase.summary);

    final resumed = engine.update(
      sessionActive: false,
      speedKmh: 25.0,
      now: t0.add(const Duration(seconds: 4)),
    );
    expect(resumed.phase, BroadcastRacePhase.postRace);
    expect(resumed.phaseChanged, isTrue);
  });

  test('widget visibility varies by race phase', () {
    final engine = BroadcastCompositionEngine();

    expect(
      engine.shouldShow(
        BroadcastWidgetSlot.voicePanel,
        phase: BroadcastRacePhase.preRace,
      ),
      isFalse,
    );
    expect(
      engine.shouldShow(
        BroadcastWidgetSlot.voicePanel,
        phase: BroadcastRacePhase.live,
      ),
      isTrue,
    );
    expect(
      engine.shouldShow(
        BroadcastWidgetSlot.summaryCard,
        phase: BroadcastRacePhase.summary,
      ),
      isTrue,
    );
    expect(
      engine.shouldShow(
        BroadcastWidgetSlot.telemetryHud,
        phase: BroadcastRacePhase.summary,
      ),
      isFalse,
    );
  });
}
