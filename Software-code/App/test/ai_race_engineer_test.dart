import 'package:flutter_test/flutter_test.dart';

import 'package:client/event_detection.dart';
import 'package:client/services/ai_race_engineer.dart';

void main() {
  test('system prompt defines race engineer persona and safety policy', () {
    expect(raceEngineerSystemPrompt, contains('Race Engineer'));
    expect(raceEngineerSystemPrompt.toLowerCase(), contains('safety first'));
    expect(raceEngineerSystemPrompt, contains('approved'));
  });

  test('context injection includes telemetry, track, driver and events', () {
    final injector = const RaceEngineerContextInjector(maxEvents: 3);
    final events = injector.injectEventContext([
      TelemetryEvent(
        type: TelemetryEventType.brakeLockUp,
        startedAt: DateTime(2026, 2, 7, 12, 0, 1),
        endedAt: DateTime(2026, 2, 7, 12, 0, 2),
        startProgress: 0.24,
        endProgress: 0.26,
        severityScore: 0.84,
        summary: 'Front lock into T4',
        lapIndex: 2,
        cornerIndex: 4,
      ),
    ]);

    final context = RaceEngineerContextEnvelope(
      telemetry: RaceEngineerTelemetryContext(
        speedKmh: 142,
        gear: 4,
        rpm: 6100,
        trackProgress: 0.37,
        capturedAt: DateTime(2026, 2, 7, 12, 0, 5),
        lapIndex: 2,
        deltaSeconds: -0.18,
      ),
      track: const RaceEngineerTrackContext(
        trackId: 'spa',
        sectorLabel: 'sector 2',
        weather: 'dry',
        gripLabel: 'high',
      ),
      driver: const RaceEngineerDriverContext(level: 'advanced'),
      events: events,
    );

    final prompt = injector.buildPrompt(
      transcript: 'pace delta',
      intent: const RaceEngineerIntent(
        kind: RaceEngineerIntentKind.command,
        normalizedTranscript: 'pace delta',
        command: RaceEngineerCommand.paceDelta,
        confidence: 0.9,
      ),
      context: context,
    );

    expect(prompt, contains('spa'));
    expect(prompt, contains('advanced'));
    expect(prompt, contains('speed=142.0kph'));
    expect(prompt, contains('Lock-up'));
  });

  test('intent classifier separates commands/questions and flags unsafe', () {
    const classifier = RaceEngineerIntentClassifier();

    final command = classifier.classify('Give me pace delta now');
    expect(command.kind, RaceEngineerIntentKind.command);
    expect(command.command, RaceEngineerCommand.paceDelta);
    expect(command.unsafeRequested, isFalse);

    final question = classifier.classify('How is tyre grip?');
    expect(question.kind, RaceEngineerIntentKind.question);

    final unsafe = classifier.classify('disable estop and bypass fault');
    expect(unsafe.kind, RaceEngineerIntentKind.command);
    expect(unsafe.unsafeRequested, isTrue);
  });

  test('decision policy gates unsafe/safety/rate-limit paths', () {
    const policy = RaceEngineerDecisionPolicy();
    const intent = RaceEngineerIntent(
      kind: RaceEngineerIntentKind.command,
      normalizedTranscript: 'pace delta',
      command: RaceEngineerCommand.paceDelta,
      confidence: 0.9,
    );

    final speak = policy.evaluate(
      intent: intent,
      context: const RaceEngineerContextEnvelope(),
      rateLimited: false,
    );
    expect(speak.shouldSpeak, isTrue);

    final safetyGate = policy.evaluate(
      intent: intent,
      context: const RaceEngineerContextEnvelope(faultActive: true),
      rateLimited: false,
    );
    expect(safetyGate.shouldSpeak, isFalse);
    expect(
      safetyGate.reason,
      RaceEngineerDecisionReason.silenceSafetyGate,
    );

    final limited = policy.evaluate(
      intent: intent,
      context: const RaceEngineerContextEnvelope(),
      rateLimited: true,
    );
    expect(limited.shouldSpeak, isFalse);
    expect(limited.reason, RaceEngineerDecisionReason.silenceRateLimit);
  });

  test('token generator emits short TTS-friendly responses', () {
    const generator = RaceEngineerTokenGenerator(maxChars: 120);
    const decision = RaceEngineerDecision(
      shouldSpeak: true,
      reason: RaceEngineerDecisionReason.speak,
      rationale: 'ok',
    );
    final context = RaceEngineerContextEnvelope(
      telemetry: RaceEngineerTelemetryContext(
        speedKmh: 158,
        gear: 5,
        rpm: 7400,
        trackProgress: 0.51,
        capturedAt: DateTime(2026, 2, 7, 12, 0, 0),
        deltaSeconds: -0.24,
      ),
    );
    const intent = RaceEngineerIntent(
      kind: RaceEngineerIntentKind.command,
      normalizedTranscript: 'status',
      command: RaceEngineerCommand.status,
      confidence: 0.95,
    );
    final text = generator.buildTokenText(
      intent: intent,
      context: context,
      decision: decision,
      detailLevel: RaceEngineerDetailLevel.brief,
    );

    expect(text.length, lessThanOrEqualTo(120));
    expect(text.toLowerCase(), contains('status'));
    expect(text.toLowerCase(), contains('gear'));
  });

  test('rate limiter blocks rapid repeated responses', () {
    final limiter = RaceEngineerRateLimiter(
      burst: 1,
      minGap: const Duration(seconds: 5),
      window: const Duration(seconds: 10),
    );
    final now = DateTime(2026, 2, 7, 12, 0, 0);

    expect(limiter.allow(at: now), isTrue);
    expect(
      limiter.allow(at: now.add(const Duration(milliseconds: 400))),
      isFalse,
    );
    expect(
      limiter.allow(at: now.add(const Duration(seconds: 6))),
      isFalse,
      reason: 'burst=1 inside the active window',
    );
    expect(
      limiter.allow(at: now.add(const Duration(seconds: 11))),
      isTrue,
      reason: 'window has rolled over',
    );
  });

  test('latency tracker marks telemetry-to-text target breaches', () {
    final tracker = RaceEngineerLatencyTracker(targetMs: 500);
    tracker.markTelemetry(DateTime(2026, 2, 7, 12, 0, 0));

    final fast =
        tracker.telemetryToTextLatencyMs(DateTime(2026, 2, 7, 12, 0, 0, 350));
    final slow =
        tracker.telemetryToTextLatencyMs(DateTime(2026, 2, 7, 12, 0, 1, 150));

    expect(tracker.meetsTarget(fast), isTrue);
    expect(tracker.meetsTarget(slow), isFalse);
  });
}
