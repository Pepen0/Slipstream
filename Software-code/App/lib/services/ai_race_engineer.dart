import 'dart:math';

import 'package:flutter/foundation.dart';

import '../event_detection.dart';

const String raceEngineerSystemPrompt = '''
You are Slipstream AI Race Engineer v1.
Persona: concise race engineer, calm under pressure, precise telemetry language.
Priority: safety first, then pace, then consistency.
Style: short spoken coaching lines for TTS, no fluff, no unsafe instructions.
Policy:
- Never suggest disabling safety systems, E-stop logic, or fault handling.
- If command is not approved, decline and offer approved alternatives.
- When safety/fault/E-stop is active, suppress coaching and acknowledge gate.
''';

enum RaceEngineerIntentKind {
  command,
  question,
  update,
  unknown,
}

enum RaceEngineerDetailLevel {
  brief,
  standard,
  detailed,
}

enum RaceEngineerCommand {
  status,
  paceDelta,
  sectorReview,
  fuelStatus,
  tyreStatus,
  pitWindow,
  coachingLine,
}

String raceEngineerCommandLabel(RaceEngineerCommand command) {
  switch (command) {
    case RaceEngineerCommand.status:
      return 'status';
    case RaceEngineerCommand.paceDelta:
      return 'pace delta';
    case RaceEngineerCommand.sectorReview:
      return 'sector review';
    case RaceEngineerCommand.fuelStatus:
      return 'fuel status';
    case RaceEngineerCommand.tyreStatus:
      return 'tyre status';
    case RaceEngineerCommand.pitWindow:
      return 'pit window';
    case RaceEngineerCommand.coachingLine:
      return 'coaching line';
  }
}

const Set<RaceEngineerCommand> approvedRaceEngineerCommands = {
  RaceEngineerCommand.status,
  RaceEngineerCommand.paceDelta,
  RaceEngineerCommand.sectorReview,
  RaceEngineerCommand.fuelStatus,
  RaceEngineerCommand.tyreStatus,
  RaceEngineerCommand.pitWindow,
  RaceEngineerCommand.coachingLine,
};

@immutable
class RaceEngineerTelemetryContext {
  const RaceEngineerTelemetryContext({
    required this.speedKmh,
    required this.gear,
    required this.rpm,
    required this.trackProgress,
    required this.capturedAt,
    this.lapIndex,
    this.deltaSeconds,
    this.throttle,
    this.brake,
    this.steering,
  });

  final double speedKmh;
  final int gear;
  final double rpm;
  final double trackProgress;
  final DateTime capturedAt;
  final int? lapIndex;
  final double? deltaSeconds;
  final double? throttle;
  final double? brake;
  final double? steering;
}

@immutable
class RaceEngineerTrackContext {
  const RaceEngineerTrackContext({
    this.trackId = 'unknown-track',
    this.sectorLabel = 'sector n/a',
    this.weather = 'unknown',
    this.gripLabel = 'normal',
    this.cornerIndex,
  });

  final String trackId;
  final String sectorLabel;
  final String weather;
  final String gripLabel;
  final int? cornerIndex;
}

@immutable
class RaceEngineerDriverContext {
  const RaceEngineerDriverContext({
    this.level = 'intermediate',
    this.consistency = 0.62,
    this.aggression = 0.54,
  });

  final String level;
  final double consistency;
  final double aggression;
}

@immutable
class RaceEngineerEventContext {
  const RaceEngineerEventContext({
    required this.type,
    required this.severity,
    required this.summary,
    required this.startedAt,
    this.lapIndex,
    this.cornerIndex,
  });

  final TelemetryEventType type;
  final double severity;
  final String summary;
  final DateTime startedAt;
  final int? lapIndex;
  final int? cornerIndex;
}

@immutable
class RaceEngineerContextEnvelope {
  const RaceEngineerContextEnvelope({
    this.telemetry,
    this.track = const RaceEngineerTrackContext(),
    this.driver = const RaceEngineerDriverContext(),
    this.events = const [],
    this.safetyWarningActive = false,
    this.estopActive = false,
    this.faultActive = false,
  });

  final RaceEngineerTelemetryContext? telemetry;
  final RaceEngineerTrackContext track;
  final RaceEngineerDriverContext driver;
  final List<RaceEngineerEventContext> events;
  final bool safetyWarningActive;
  final bool estopActive;
  final bool faultActive;

  RaceEngineerContextEnvelope copyWith({
    RaceEngineerTelemetryContext? telemetry,
    RaceEngineerTrackContext? track,
    RaceEngineerDriverContext? driver,
    List<RaceEngineerEventContext>? events,
    bool? safetyWarningActive,
    bool? estopActive,
    bool? faultActive,
  }) {
    return RaceEngineerContextEnvelope(
      telemetry: telemetry ?? this.telemetry,
      track: track ?? this.track,
      driver: driver ?? this.driver,
      events: events ?? this.events,
      safetyWarningActive: safetyWarningActive ?? this.safetyWarningActive,
      estopActive: estopActive ?? this.estopActive,
      faultActive: faultActive ?? this.faultActive,
    );
  }
}

@immutable
class RaceEngineerIntent {
  const RaceEngineerIntent({
    required this.kind,
    required this.normalizedTranscript,
    required this.confidence,
    this.command,
    this.unsafeRequested = false,
  });

  final RaceEngineerIntentKind kind;
  final String normalizedTranscript;
  final RaceEngineerCommand? command;
  final double confidence;
  final bool unsafeRequested;
}

class RaceEngineerIntentClassifier {
  const RaceEngineerIntentClassifier();

  static const Map<RaceEngineerCommand, List<String>> _commandPhrases = {
    RaceEngineerCommand.status: [
      'status',
      'car status',
      'system status',
      'how are we',
      'report status',
    ],
    RaceEngineerCommand.paceDelta: [
      'pace delta',
      'delta',
      'time delta',
      'gaining or losing',
      'am i up',
    ],
    RaceEngineerCommand.sectorReview: [
      'sector review',
      'sector',
      'corner review',
      'where did i lose',
      'breakdown',
    ],
    RaceEngineerCommand.fuelStatus: [
      'fuel',
      'fuel status',
      'fuel window',
      'fuel left',
    ],
    RaceEngineerCommand.tyreStatus: [
      'tyre',
      'tires',
      'tyre status',
      'grip',
      'temps',
    ],
    RaceEngineerCommand.pitWindow: [
      'pit window',
      'pit',
      'box this lap',
      'stop window',
    ],
    RaceEngineerCommand.coachingLine: [
      'coaching line',
      'line advice',
      'apex advice',
      'braking point',
      'coaching',
    ],
  };

  static const List<String> _unsafePhrases = [
    'disable safety',
    'disable estop',
    'disable e stop',
    'bypass fault',
    'override estop',
    'ignore fault',
    'shut off safety',
  ];

  static const List<String> _questionLeads = [
    'what',
    'why',
    'how',
    'when',
    'where',
    'should i',
    'can i',
  ];

  RaceEngineerIntent classify(String transcript) {
    final normalized = _normalizeTranscript(transcript);
    if (normalized.isEmpty) {
      return const RaceEngineerIntent(
        kind: RaceEngineerIntentKind.unknown,
        normalizedTranscript: '',
        confidence: 0.0,
      );
    }

    if (_containsAny(normalized, _unsafePhrases)) {
      return RaceEngineerIntent(
        kind: RaceEngineerIntentKind.command,
        normalizedTranscript: normalized,
        confidence: 0.98,
        unsafeRequested: true,
      );
    }

    if (normalized.endsWith('?') || _startsWithAny(normalized, _questionLeads)) {
      return RaceEngineerIntent(
        kind: RaceEngineerIntentKind.question,
        normalizedTranscript: normalized,
        confidence: 0.76,
      );
    }

    for (final entry in _commandPhrases.entries) {
      if (_containsAny(normalized, entry.value)) {
        return RaceEngineerIntent(
          kind: RaceEngineerIntentKind.command,
          normalizedTranscript: normalized,
          command: entry.key,
          confidence: 0.92,
        );
      }
    }

    if (_containsAny(normalized, const ['set ', 'show ', 'give ', 'tell ', 'report '])) {
      return RaceEngineerIntent(
        kind: RaceEngineerIntentKind.command,
        normalizedTranscript: normalized,
        confidence: 0.48,
      );
    }

    return RaceEngineerIntent(
      kind: RaceEngineerIntentKind.update,
      normalizedTranscript: normalized,
      confidence: 0.45,
    );
  }
}

enum RaceEngineerDecisionReason {
  speak,
  silenceSafetyGate,
  silenceRateLimit,
  silenceLowSignal,
  rejectUnsafeCommand,
}

@immutable
class RaceEngineerDecision {
  const RaceEngineerDecision({
    required this.shouldSpeak,
    required this.reason,
    required this.rationale,
    this.commandApproved = true,
  });

  final bool shouldSpeak;
  final RaceEngineerDecisionReason reason;
  final String rationale;
  final bool commandApproved;
}

class RaceEngineerDecisionPolicy {
  const RaceEngineerDecisionPolicy({
    this.eventSpeakSeverity = 0.72,
  });

  final double eventSpeakSeverity;

  RaceEngineerDecision evaluate({
    required RaceEngineerIntent intent,
    required RaceEngineerContextEnvelope context,
    required bool rateLimited,
  }) {
    if (intent.unsafeRequested) {
      return const RaceEngineerDecision(
        shouldSpeak: false,
        reason: RaceEngineerDecisionReason.rejectUnsafeCommand,
        rationale: 'unsafe command request blocked',
        commandApproved: false,
      );
    }

    final safetyGate =
        context.safetyWarningActive || context.estopActive || context.faultActive;
    if (safetyGate) {
      return const RaceEngineerDecision(
        shouldSpeak: false,
        reason: RaceEngineerDecisionReason.silenceSafetyGate,
        rationale: 'safety gate active',
      );
    }

    if (rateLimited) {
      return const RaceEngineerDecision(
        shouldSpeak: false,
        reason: RaceEngineerDecisionReason.silenceRateLimit,
        rationale: 'rate limiter active',
      );
    }

    final peakEventSeverity = context.events.fold<double>(
      0.0,
      (best, event) => max(best, event.severity),
    );

    final hasLiveSignal = context.telemetry != null;
    if (intent.kind == RaceEngineerIntentKind.unknown &&
        peakEventSeverity < eventSpeakSeverity &&
        !hasLiveSignal) {
      return const RaceEngineerDecision(
        shouldSpeak: false,
        reason: RaceEngineerDecisionReason.silenceLowSignal,
        rationale: 'no intent and no meaningful context',
      );
    }

    return RaceEngineerDecision(
      shouldSpeak: true,
      reason: RaceEngineerDecisionReason.speak,
      rationale: 'policy allows response',
      commandApproved:
          intent.command == null || approvedRaceEngineerCommands.contains(intent.command),
    );
  }
}

class RaceEngineerRateLimiter {
  RaceEngineerRateLimiter({
    this.burst = 3,
    this.window = const Duration(seconds: 8),
    this.minGap = const Duration(milliseconds: 700),
  });

  final int burst;
  final Duration window;
  final Duration minGap;
  final List<DateTime> _history = <DateTime>[];
  DateTime? _lastAllowed;

  bool allow({DateTime? at}) {
    final now = at ?? DateTime.now();
    _history.removeWhere((stamp) => now.difference(stamp) > window);
    final lastAllowed = _lastAllowed;
    if (lastAllowed != null && now.difference(lastAllowed) < minGap) {
      return false;
    }
    if (_history.length >= burst) {
      return false;
    }
    _history.add(now);
    _lastAllowed = now;
    return true;
  }

  Duration retryAfter({DateTime? at}) {
    final now = at ?? DateTime.now();
    _history.removeWhere((stamp) => now.difference(stamp) > window);
    var wait = Duration.zero;
    if (_lastAllowed != null) {
      final gapRemaining = minGap - now.difference(_lastAllowed!);
      if (gapRemaining > wait) {
        wait = gapRemaining;
      }
    }
    if (_history.length >= burst) {
      final oldest = _history.first;
      final windowRemaining = window - now.difference(oldest);
      if (windowRemaining > wait) {
        wait = windowRemaining;
      }
    }
    return wait.isNegative ? Duration.zero : wait;
  }

  void reset() {
    _history.clear();
    _lastAllowed = null;
  }
}

class RaceEngineerTokenGenerator {
  const RaceEngineerTokenGenerator({this.maxChars = 160});

  final int maxChars;

  String buildTokenText({
    required RaceEngineerIntent intent,
    required RaceEngineerContextEnvelope context,
    required RaceEngineerDecision decision,
    required RaceEngineerDetailLevel detailLevel,
  }) {
    if (decision.reason == RaceEngineerDecisionReason.rejectUnsafeCommand) {
      return 'Command blocked. Safety-critical actions are not voice-enabled.';
    }
    if (decision.reason == RaceEngineerDecisionReason.silenceRateLimit) {
      return 'Stand by. Rate limit active.';
    }
    if (decision.reason == RaceEngineerDecisionReason.silenceSafetyGate) {
      return 'Safety gate active. Coaching muted.';
    }
    if (!decision.shouldSpeak) {
      return '';
    }

    final telemetry = context.telemetry;
    final speed = telemetry?.speedKmh.round();
    final gear = telemetry?.gear;
    final delta = telemetry?.deltaSeconds;
    final topEvent = context.events.isEmpty ? null : context.events.first;

    String base;
    switch (intent.command) {
      case RaceEngineerCommand.status:
        base = 'Status green.'
            '${speed == null ? '' : ' ${speed} kph.'}'
            '${gear == null ? '' : ' Gear $gear.'}'
            '${delta == null ? '' : ' Delta ${_signed(delta)}s.'}';
        break;
      case RaceEngineerCommand.paceDelta:
        base = delta == null
            ? 'Delta unavailable. Keep current rhythm.'
            : 'Delta ${_signed(delta)}s. Focus smooth exits.';
        break;
      case RaceEngineerCommand.sectorReview:
        if (topEvent != null) {
          base = '${_eventVoiceLabel(topEvent.type)} ${_percent(topEvent.severity)}.'
              ' Adjust entry and release brake earlier.';
        } else {
          base = 'Sector trend stable. Brake release and early throttle.';
        }
        break;
      case RaceEngineerCommand.fuelStatus:
        base = 'Fuel strategy nominal. No critical change required.';
        break;
      case RaceEngineerCommand.tyreStatus:
        base = 'Tyre load stable. Protect fronts on turn-in.';
        break;
      case RaceEngineerCommand.pitWindow:
        base = 'Pit window opens soon. Hold pace, avoid lock-up.';
        break;
      case RaceEngineerCommand.coachingLine:
        base = 'Late apex. Straighten exit, throttle progressively.';
        break;
      case null:
        if (intent.kind == RaceEngineerIntentKind.command) {
          base =
              'Approved commands: status, pace delta, sector review, fuel, tyres, pit window.';
        } else if (intent.kind == RaceEngineerIntentKind.question) {
          base = 'Answer: '
              '${speed == null ? 'pace stable' : '$speed kph current pace'}, '
              'focus consistency and clean exits.';
        } else {
          base = topEvent == null
              ? 'Copy. Keep the line tidy and inputs smooth.'
              : '${_eventVoiceLabel(topEvent.type)} noted. Manage entry speed.';
        }
        break;
    }

    if (detailLevel == RaceEngineerDetailLevel.brief) {
      return optimizeForTts(base, maxChars: min(maxChars, 110));
    }
    if (detailLevel == RaceEngineerDetailLevel.detailed && topEvent != null) {
      final extra = '${_eventVoiceLabel(topEvent.type)} severity ${_percent(topEvent.severity)}.';
      return optimizeForTts('$base $extra');
    }
    return optimizeForTts(base);
  }

  String optimizeForTts(String text, {int? maxChars}) {
    final limit = maxChars ?? this.maxChars;
    if (text.trim().isEmpty) {
      return '';
    }
    var compact = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    const replacements = {
      'approximately ': '~',
      'kilometers per hour': 'kph',
      'kilometer per hour': 'kph',
      ' seconds': 's',
      ' second': 's',
    };
    replacements.forEach((from, to) {
      compact = compact.replaceAll(from, to);
    });
    if (compact.length <= limit) {
      return compact;
    }
    var clipped = compact.substring(0, limit).trimRight();
    final lastSpace = clipped.lastIndexOf(' ');
    if (lastSpace > 36) {
      clipped = clipped.substring(0, lastSpace);
    }
    return '$clipped…';
  }

  String _signed(double value) {
    final rounded = value.toStringAsFixed(2);
    return value > 0 ? '+$rounded' : rounded;
  }

  String _percent(double value) {
    return '${(value.clamp(0.0, 1.0) * 100).round()}%';
  }
}

class RaceEngineerContextInjector {
  const RaceEngineerContextInjector({this.maxEvents = 4});

  final int maxEvents;

  List<RaceEngineerEventContext> injectEventContext(List<TelemetryEvent> events) {
    if (events.isEmpty) {
      return const [];
    }
    final sorted = [...events]..sort((a, b) {
        final severityOrder = b.severityScore.compareTo(a.severityScore);
        if (severityOrder != 0) {
          return severityOrder;
        }
        return b.startedAt.compareTo(a.startedAt);
      });
    return sorted.take(maxEvents).map((event) {
      return RaceEngineerEventContext(
        type: event.type,
        severity: event.severityScore.clamp(0.0, 1.0).toDouble(),
        summary: event.summary,
        startedAt: event.startedAt,
        lapIndex: event.lapIndex,
        cornerIndex: event.cornerIndex,
      );
    }).toList(growable: false);
  }

  String buildPrompt({
    required String transcript,
    required RaceEngineerIntent intent,
    required RaceEngineerContextEnvelope context,
    RaceEngineerDetailLevel detailLevel = RaceEngineerDetailLevel.standard,
  }) {
    final telemetry = context.telemetry;
    final telemetryBlock = telemetry == null
        ? 'telemetry: unavailable'
        : 'telemetry: speed=${telemetry.speedKmh.toStringAsFixed(1)}kph '
            'gear=${telemetry.gear} rpm=${telemetry.rpm.toStringAsFixed(0)} '
            'progress=${(telemetry.trackProgress * 100).toStringAsFixed(1)}% '
            '${telemetry.deltaSeconds == null ? '' : 'delta=${telemetry.deltaSeconds!.toStringAsFixed(2)}s'}';
    final eventsBlock = context.events.isEmpty
        ? 'events: none'
        : context.events
            .map((event) =>
                '${_eventVoiceLabel(event.type)}(${(event.severity * 100).round()}%): ${event.summary}')
            .join(' | ');

    return '''
$raceEngineerSystemPrompt
driver-level: ${context.driver.level}, consistency=${context.driver.consistency.toStringAsFixed(2)}, aggression=${context.driver.aggression.toStringAsFixed(2)}
track: ${context.track.trackId}, ${context.track.sectorLabel}, weather=${context.track.weather}, grip=${context.track.gripLabel}
$telemetryBlock
$eventsBlock
safety-gate: warning=${context.safetyWarningActive} fault=${context.faultActive} estop=${context.estopActive}
intent: ${intent.kind.name}, approved-command=${intent.command?.name ?? 'none'}, detail=${detailLevel.name}
approved-commands: ${approvedRaceEngineerCommands.map((c) => raceEngineerCommandLabel(c)).join(', ')}
driver-input: $transcript
''';
  }
}

class RaceEngineerLatencyTracker {
  RaceEngineerLatencyTracker({this.targetMs = 500});

  final int targetMs;
  DateTime? _lastTelemetryAt;

  void markTelemetry([DateTime? capturedAt]) {
    _lastTelemetryAt = capturedAt ?? DateTime.now();
  }

  int telemetryToTextLatencyMs([DateTime? completedAt]) {
    final at = completedAt ?? DateTime.now();
    final lastTelemetryAt = _lastTelemetryAt;
    if (lastTelemetryAt == null) {
      return 0;
    }
    return max(0, at.difference(lastTelemetryAt).inMilliseconds);
  }

  bool meetsTarget(int latencyMs) => latencyMs <= targetMs;
}

String _normalizeTranscript(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s\?]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _containsAny(String source, List<String> patterns) {
  for (final pattern in patterns) {
    if (source.contains(pattern)) {
      return true;
    }
  }
  return false;
}

bool _startsWithAny(String source, List<String> prefixes) {
  for (final prefix in prefixes) {
    if (source.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

String _eventVoiceLabel(TelemetryEventType type) {
  switch (type) {
    case TelemetryEventType.lapBoundary:
      return 'Lap';
    case TelemetryEventType.cornerSegment:
      return 'Corner';
    case TelemetryEventType.brakeLockUp:
      return 'Lock-up';
    case TelemetryEventType.apexMiss:
      return 'Apex miss';
    case TelemetryEventType.crash:
      return 'Crash';
    case TelemetryEventType.spin:
      return 'Spin';
    case TelemetryEventType.save:
      return 'Save';
  }
}
