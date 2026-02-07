import 'dart:math';

import 'package:flutter/foundation.dart';

import 'event_detection.dart';
import 'telemetry_analysis.dart';

enum CausalitySignal {
  understeer,
  oversteer,
}

String causalitySignalLabel(CausalitySignal signal) {
  switch (signal) {
    case CausalitySignal.understeer:
      return 'Understeer';
    case CausalitySignal.oversteer:
      return 'Oversteer';
  }
}

@immutable
class CausalityInferenceRule {
  const CausalityInferenceRule({
    required this.id,
    required this.signal,
    required this.observationTemplate,
    required this.effectTemplate,
    required this.defaultFixTemplate,
  });

  final String id;
  final CausalitySignal signal;
  final String observationTemplate;
  final String effectTemplate;
  final String defaultFixTemplate;
}

const CausalityInferenceRule understeerInferenceRule = CausalityInferenceRule(
  id: 'understeer_brake_steer_corr',
  signal: CausalitySignal.understeer,
  observationTemplate:
      'Brake+steering coupling stayed high in corner {corner} (corr={corr}).',
  effectTemplate: 'Front push reduced apex rotation and hurt exit speed.',
  defaultFixTemplate:
      'Release brake 5-10m earlier and reduce initial steering lock.',
);

const CausalityInferenceRule oversteerInferenceRule = CausalityInferenceRule(
  id: 'oversteer_countersteer_instability',
  signal: CausalitySignal.oversteer,
  observationTemplate:
      'Counter-steer oscillation detected in corner {corner} ({flips} flips).',
  effectTemplate: 'Rear instability forced corrections and reduced traction.',
  defaultFixTemplate:
      'Soften steering snap and delay throttle pickup until wheel unwind.',
);

const List<CausalityInferenceRule> defaultCausalityInferenceRules = [
  understeerInferenceRule,
  oversteerInferenceRule,
];

@immutable
class CausalityEngineConfig {
  const CausalityEngineConfig({
    this.minCornerSamples = 8,
    this.understeerCorrelationThreshold = 0.44,
    this.understeerBrakeThreshold = 0.26,
    this.understeerLatDeficitThreshold = 0.12,
    this.understeerOverspeedThreshold = 0.16,
    this.oversteerMinCounterSteerFlips = 2,
    this.oversteerSteeringThreshold = 0.62,
    this.oversteerSpeedDropThreshold = 0.11,
    this.oversteerSupportingEventThreshold = 0.32,
    this.minConfidenceToKeep = 0.28,
  });

  final int minCornerSamples;

  final double understeerCorrelationThreshold;
  final double understeerBrakeThreshold;
  final double understeerLatDeficitThreshold;
  final double understeerOverspeedThreshold;

  final int oversteerMinCounterSteerFlips;
  final double oversteerSteeringThreshold;
  final double oversteerSpeedDropThreshold;
  final double oversteerSupportingEventThreshold;

  final double minConfidenceToKeep;
}

@immutable
class CausalityInsight {
  const CausalityInsight({
    required this.signal,
    required this.ruleId,
    required this.startedAt,
    required this.endedAt,
    required this.observation,
    required this.effect,
    required this.fix,
    required this.confidenceScore,
    required this.severityScore,
    required this.metrics,
    this.lapIndex,
    this.cornerIndex,
  });

  final CausalitySignal signal;
  final String ruleId;
  final DateTime startedAt;
  final DateTime endedAt;
  final String observation;
  final String effect;
  final String fix;
  final double confidenceScore;
  final double severityScore;
  final Map<String, double> metrics;
  final int? lapIndex;
  final int? cornerIndex;
}

@immutable
class CausalityInferenceResult {
  const CausalityInferenceResult({
    required this.insights,
    required this.telemetryEvents,
  });

  const CausalityInferenceResult.empty()
      : insights = const [],
        telemetryEvents = const TelemetryEventStream(
          laps: [],
          corners: [],
          events: [],
        );

  final List<CausalityInsight> insights;
  final TelemetryEventStream telemetryEvents;

  bool get isEmpty => insights.isEmpty;
}

@immutable
class CausalityRecommendation {
  const CausalityRecommendation({
    required this.observation,
    required this.effect,
    required this.fix,
  });

  final String observation;
  final String effect;
  final String fix;
}

class CausalityRecommendationGenerator {
  const CausalityRecommendationGenerator({
    this.rules = defaultCausalityInferenceRules,
  });

  final List<CausalityInferenceRule> rules;

  CausalityRecommendation generate({
    required CausalitySignal signal,
    required int? cornerIndex,
    required Map<String, double> metrics,
  }) {
    final rule = _ruleFor(signal);
    switch (signal) {
      case CausalitySignal.understeer:
        final entryOverspeed = metrics['entryOverspeed'] ?? 0.0;
        final latDeficit = metrics['latDeficit'] ?? 0.0;
        final corr = metrics['brakeSteerCorrelation'] ?? 0.0;
        final corner = cornerIndex?.toString() ?? '?';
        final observation = rule.observationTemplate
            .replaceAll('{corner}', corner)
            .replaceAll('{corr}', corr.toStringAsFixed(2));
        final effect = latDeficit > 0.24
            ? 'Front axle saturated at turn-in; apex speed window collapsed.'
            : rule.effectTemplate;
        final fix = entryOverspeed > 0.2
            ? 'Brake 5-8m earlier, then taper release before apex to free rotation.'
            : latDeficit > 0.2
                ? 'Reduce steering lock on entry and hold lighter trail brake.'
                : rule.defaultFixTemplate;
        return CausalityRecommendation(
          observation: observation,
          effect: effect,
          fix: fix,
        );
      case CausalitySignal.oversteer:
        final flips = (metrics['counterSteerFlips'] ?? 0).round();
        final supporting = metrics['supportingEventScore'] ?? 0.0;
        final corner = cornerIndex?.toString() ?? '?';
        final observation = rule.observationTemplate
            .replaceAll('{corner}', corner)
            .replaceAll('{flips}', flips.toString());
        final effect = supporting > 0.55
            ? 'Rear slip event confirmed; stability corrections cost lap time.'
            : rule.effectTemplate;
        final fix = supporting > 0.65
            ? 'Delay throttle pickup until steering unwinds and avoid snap inputs.'
            : flips >= 3
                ? 'Use one clean steering input and avoid rapid counter-steer flicks.'
                : rule.defaultFixTemplate;
        return CausalityRecommendation(
          observation: observation,
          effect: effect,
          fix: fix,
        );
    }
  }

  CausalityInferenceRule _ruleFor(CausalitySignal signal) {
    for (final rule in rules) {
      if (rule.signal == signal) {
        return rule;
      }
    }
    return signal == CausalitySignal.understeer
        ? understeerInferenceRule
        : oversteerInferenceRule;
  }
}

class CausalityConfidenceModel {
  const CausalityConfidenceModel({this.base = 0.24});

  final double base;

  double score({
    required double ruleEvidence,
    required double signalStrength,
    required double supportingEventScore,
    required int sampleCount,
  }) {
    final sampleQuality =
        ((sampleCount - 6).clamp(0, 22) / 22.0).clamp(0.0, 1.0).toDouble();
    final value = base +
        _clamp01(ruleEvidence) * 0.45 +
        _clamp01(signalStrength) * 0.3 +
        _clamp01(supportingEventScore) * 0.15 +
        sampleQuality * 0.1;
    return _clamp01(value);
  }
}

class CausalityEngine {
  CausalityEngine({
    this.config = const CausalityEngineConfig(),
    this.eventConfig = const EventDetectionConfig(),
    CausalityConfidenceModel? confidenceModel,
    CausalityRecommendationGenerator? recommendationGenerator,
  })  : _confidenceModel = confidenceModel ?? const CausalityConfidenceModel(),
        _recommendationGenerator =
            recommendationGenerator ?? const CausalityRecommendationGenerator();

  final CausalityEngineConfig config;
  final EventDetectionConfig eventConfig;
  final CausalityConfidenceModel _confidenceModel;
  final CausalityRecommendationGenerator _recommendationGenerator;

  CausalityInferenceResult analyze(List<TelemetryFrame> frames) {
    if (frames.length < 4) {
      return CausalityInferenceResult(
        insights: const [],
        telemetryEvents: detectTelemetryEvents(frames, config: eventConfig),
      );
    }

    final points = deriveTelemetryPoints(frames);
    final stream = detectTelemetryEvents(frames, config: eventConfig);
    final insights = <CausalityInsight>[];

    insights.addAll(_detectUndersteer(
      frames: frames,
      points: points,
      stream: stream,
    ));
    insights.addAll(_detectOversteer(
      frames: frames,
      points: points,
      stream: stream,
    ));

    final deduped = _dedupeInsights(insights)
        .where(
            (insight) => insight.confidenceScore >= config.minConfidenceToKeep)
        .toList(growable: false)
      ..sort((a, b) {
        final confidence = b.confidenceScore.compareTo(a.confidenceScore);
        if (confidence != 0) {
          return confidence;
        }
        final severity = b.severityScore.compareTo(a.severityScore);
        if (severity != 0) {
          return severity;
        }
        return a.startedAt.compareTo(b.startedAt);
      });

    return CausalityInferenceResult(
      insights: deduped,
      telemetryEvents: stream,
    );
  }

  List<CausalityInsight> _detectUndersteer({
    required List<TelemetryFrame> frames,
    required List<TelemetryPoint> points,
    required TelemetryEventStream stream,
  }) {
    if (stream.corners.isEmpty) {
      return const [];
    }

    final apexByCorner = _eventEvidenceByCorner(
      stream.events,
      type: TelemetryEventType.apexMiss,
    );

    final findings = <CausalityInsight>[];
    for (final corner in stream.corners) {
      final start = corner.startIndex.clamp(0, points.length - 1);
      final end = corner.endIndex.clamp(start, points.length - 1);
      final sampleCount = end - start + 1;
      if (sampleCount < config.minCornerSamples) {
        continue;
      }

      final brake = <double>[];
      final steerAbs = <double>[];
      var meanLatG = 0.0;
      var latCount = 0;
      var peakSteerAbs = 0.0;
      for (var i = start; i <= end; i++) {
        final point = points[i];
        brake.add(point.brake);
        final steer = point.steering.abs();
        steerAbs.add(steer);
        peakSteerAbs = max(peakSteerAbs, steer);
        final lat = frames[i].lateralG;
        if (lat != null) {
          meanLatG += lat.abs();
          latCount++;
        }
      }

      final meanBrake = _mean(brake);
      final brakeSteerCorrelation = _pearson(brake, steerAbs);
      final measuredLatG = latCount > 0
          ? meanLatG / latCount
          : (corner.peakTurnLoad * 1.65).clamp(0.2, 2.7).toDouble();
      final expectedLatG = (0.35 + peakSteerAbs * 1.9 + meanBrake * 0.24)
          .clamp(0.35, 3.0)
          .toDouble();
      final latDeficit =
          ((expectedLatG - measuredLatG) / max(0.35, expectedLatG))
              .clamp(0.0, 1.0)
              .toDouble();

      final entrySpeed = max(1.0, corner.entrySpeedKmh);
      final speedDropRatio =
          ((corner.entrySpeedKmh - corner.apexSpeedKmh) / entrySpeed)
              .clamp(0.0, 1.0)
              .toDouble();
      final requiredDrop =
          (0.13 + corner.peakTurnLoad * 0.33).clamp(0.14, 0.55).toDouble();
      final entryOverspeed =
          ((requiredDrop - speedDropRatio) / max(0.1, requiredDrop))
              .clamp(0.0, 1.0)
              .toDouble();
      final apexEvidence =
          apexByCorner[_cornerKey(corner.lapIndex, corner.cornerIndex)] ?? 0.0;

      final corrNorm =
          ((brakeSteerCorrelation - config.understeerCorrelationThreshold) /
                  max(1e-6, 1.0 - config.understeerCorrelationThreshold))
              .clamp(0.0, 1.0)
              .toDouble();
      final brakeNorm = ((meanBrake - config.understeerBrakeThreshold) /
              max(1e-6, 1.0 - config.understeerBrakeThreshold))
          .clamp(0.0, 1.0)
          .toDouble();
      final evidence = _clamp01(
        corrNorm * 0.34 +
            brakeNorm * 0.24 +
            latDeficit * 0.22 +
            entryOverspeed * 0.12 +
            apexEvidence * 0.08,
      );
      final severity = _clamp01(
        latDeficit * 0.33 +
            entryOverspeed * 0.25 +
            apexEvidence * 0.2 +
            corrNorm * 0.12 +
            brakeNorm * 0.1,
      );
      final confidence = _confidenceModel.score(
        ruleEvidence: evidence,
        signalStrength: severity,
        supportingEventScore: apexEvidence,
        sampleCount: sampleCount,
      );

      final isUndersteer =
          brakeSteerCorrelation >= config.understeerCorrelationThreshold &&
              meanBrake >= config.understeerBrakeThreshold &&
              (latDeficit >= config.understeerLatDeficitThreshold ||
                  entryOverspeed >= config.understeerOverspeedThreshold ||
                  apexEvidence >= 0.35);
      if (!isUndersteer) {
        continue;
      }

      final metrics = <String, double>{
        'brakeSteerCorrelation': brakeSteerCorrelation,
        'meanBrake': meanBrake,
        'peakSteering': peakSteerAbs,
        'measuredLatG': measuredLatG,
        'expectedLatG': expectedLatG,
        'latDeficit': latDeficit,
        'entryOverspeed': entryOverspeed,
        'apexEvidence': apexEvidence,
        'ruleEvidence': evidence,
      };
      final recommendation = _recommendationGenerator.generate(
        signal: CausalitySignal.understeer,
        cornerIndex: corner.cornerIndex,
        metrics: metrics,
      );

      findings.add(CausalityInsight(
        signal: CausalitySignal.understeer,
        ruleId: understeerInferenceRule.id,
        startedAt: corner.startTime,
        endedAt: corner.endTime,
        observation: recommendation.observation,
        effect: recommendation.effect,
        fix: recommendation.fix,
        confidenceScore: confidence,
        severityScore: severity,
        metrics: metrics,
        lapIndex: corner.lapIndex,
        cornerIndex: corner.cornerIndex,
      ));
    }
    return findings;
  }

  List<CausalityInsight> _detectOversteer({
    required List<TelemetryFrame> frames,
    required List<TelemetryPoint> points,
    required TelemetryEventStream stream,
  }) {
    if (stream.corners.isEmpty || points.length < 3) {
      return const [];
    }

    final findings = <CausalityInsight>[];
    for (final corner in stream.corners) {
      final start = corner.startIndex.clamp(0, points.length - 2);
      final end = corner.endIndex.clamp(start + 1, points.length - 1);
      final sampleCount = end - start + 1;
      if (sampleCount < config.minCornerSamples) {
        continue;
      }

      var flips = 0;
      var peakSteer = 0.0;
      var steerPowerSum = 0.0;
      for (var i = start + 1; i <= end; i++) {
        final prev = points[i - 1].steering;
        final current = points[i].steering;
        final prevAbs = prev.abs();
        final currAbs = current.abs();
        peakSteer = max(peakSteer, max(prevAbs, currAbs));
        steerPowerSum += current * current;
        if (prevAbs >= config.oversteerSteeringThreshold &&
            currAbs >= config.oversteerSteeringThreshold &&
            prev.sign != current.sign) {
          flips++;
        }
      }
      final steerRms = sqrt(steerPowerSum / sampleCount);

      final speedStart = max(1.0, points[start].speedKmh);
      final speedEnd = points[end].speedKmh;
      final speedDropRatio =
          ((speedStart - speedEnd) / speedStart).clamp(0.0, 1.0).toDouble();
      final spinEvidence = _supportingEventScore(
        events: stream.events,
        corner: corner,
        type: TelemetryEventType.spin,
      );
      final saveEvidence = _supportingEventScore(
        events: stream.events,
        corner: corner,
        type: TelemetryEventType.save,
      );
      final supportingEventScore = max(spinEvidence, saveEvidence * 0.88);

      final flipNorm = ((flips - config.oversteerMinCounterSteerFlips) / 4.0)
          .clamp(0.0, 1.0);
      final steerNorm = ((steerRms - config.oversteerSteeringThreshold) / 0.35)
          .clamp(0.0, 1.0);
      final speedNorm = ((speedDropRatio - config.oversteerSpeedDropThreshold) /
              max(1e-6, 1.0 - config.oversteerSpeedDropThreshold))
          .clamp(0.0, 1.0)
          .toDouble();
      final evidence = _clamp01(
        flipNorm * 0.36 +
            steerNorm * 0.24 +
            speedNorm * 0.2 +
            supportingEventScore * 0.2,
      );
      final severity = _clamp01(
        speedNorm * 0.3 +
            flipNorm * 0.25 +
            steerNorm * 0.2 +
            supportingEventScore * 0.25,
      );
      final confidence = _confidenceModel.score(
        ruleEvidence: evidence,
        signalStrength: severity,
        supportingEventScore: supportingEventScore,
        sampleCount: sampleCount,
      );

      final counterSteerDetected =
          flips >= config.oversteerMinCounterSteerFlips &&
              peakSteer >= config.oversteerSteeringThreshold;
      final balanceLossDetected =
          speedDropRatio >= config.oversteerSpeedDropThreshold ||
              supportingEventScore >= config.oversteerSupportingEventThreshold;
      final isOversteer = (counterSteerDetected && balanceLossDetected) ||
          supportingEventScore >= 0.7;
      if (!isOversteer) {
        continue;
      }

      final metrics = <String, double>{
        'counterSteerFlips': flips.toDouble(),
        'steerRms': steerRms,
        'peakSteering': peakSteer,
        'speedDropRatio': speedDropRatio,
        'spinEvidence': spinEvidence,
        'saveEvidence': saveEvidence,
        'supportingEventScore': supportingEventScore,
        'ruleEvidence': evidence,
      };
      final recommendation = _recommendationGenerator.generate(
        signal: CausalitySignal.oversteer,
        cornerIndex: corner.cornerIndex,
        metrics: metrics,
      );

      findings.add(CausalityInsight(
        signal: CausalitySignal.oversteer,
        ruleId: oversteerInferenceRule.id,
        startedAt: corner.startTime,
        endedAt: corner.endTime,
        observation: recommendation.observation,
        effect: recommendation.effect,
        fix: recommendation.fix,
        confidenceScore: confidence,
        severityScore: severity,
        metrics: metrics,
        lapIndex: corner.lapIndex,
        cornerIndex: corner.cornerIndex,
      ));
    }

    return findings;
  }

  List<CausalityInsight> _dedupeInsights(List<CausalityInsight> input) {
    if (input.length <= 1) {
      return input;
    }
    final byKey = <String, CausalityInsight>{};
    for (final insight in input) {
      final key =
          '${insight.signal.name}:${insight.lapIndex ?? -1}:${insight.cornerIndex ?? -1}';
      final current = byKey[key];
      if (current == null ||
          insight.confidenceScore > current.confidenceScore ||
          (insight.confidenceScore == current.confidenceScore &&
              insight.severityScore > current.severityScore)) {
        byKey[key] = insight;
      }
    }
    return byKey.values.toList(growable: false);
  }

  Map<String, double> _eventEvidenceByCorner(
    List<TelemetryEvent> events, {
    required TelemetryEventType type,
  }) {
    final out = <String, double>{};
    for (final event in events) {
      if (event.type != type ||
          event.lapIndex == null ||
          event.cornerIndex == null) {
        continue;
      }
      final key = _cornerKey(event.lapIndex!, event.cornerIndex!);
      final existing = out[key] ?? 0.0;
      out[key] = max(existing, _clamp01(event.severityScore));
    }
    return out;
  }

  double _supportingEventScore({
    required List<TelemetryEvent> events,
    required CornerSegment corner,
    required TelemetryEventType type,
  }) {
    var best = 0.0;
    for (final event in events) {
      if (event.type != type) {
        continue;
      }
      if (event.lapIndex != null && event.lapIndex != corner.lapIndex) {
        continue;
      }

      var weight = 0.0;
      if (event.cornerIndex != null &&
          event.cornerIndex == corner.cornerIndex) {
        weight = 1.0;
      } else {
        final overlapsTime = !event.endedAt.isBefore(corner.startTime) &&
            !event.startedAt.isAfter(corner.endTime);
        final overlapsProgress = _progressOverlaps(
          corner.startProgress,
          corner.endProgress,
          event.startProgress,
          event.endProgress,
        );
        if (overlapsTime || overlapsProgress) {
          weight = 0.78;
        } else {
          final gap = (event.startProgress - corner.apexProgress).abs();
          if (gap <= 0.08) {
            weight = 0.55;
          }
        }
      }
      if (weight <= 0) {
        continue;
      }
      best = max(best, _clamp01(event.severityScore) * weight);
    }
    return best.clamp(0.0, 1.0).toDouble();
  }
}

@immutable
class CausalityFeedbackRequest {
  const CausalityFeedbackRequest({
    required this.frames,
    this.now,
    this.maxTriggers = 3,
    this.minConfidence = 0.44,
  });

  final List<TelemetryFrame> frames;
  final DateTime? now;
  final int maxTriggers;
  final double minConfidence;
}

@immutable
class CausalityFeedbackTrigger {
  const CausalityFeedbackTrigger({
    required this.triggerId,
    required this.triggeredAt,
    required this.insight,
  });

  final String triggerId;
  final DateTime triggeredAt;
  final CausalityInsight insight;
}

@immutable
class CausalityFeedbackResponse {
  const CausalityFeedbackResponse({
    required this.analysis,
    required this.triggers,
    required this.suppressed,
  });

  final CausalityInferenceResult analysis;
  final List<CausalityFeedbackTrigger> triggers;
  final int suppressed;
}

class CausalityFeedbackTriggerApi {
  CausalityFeedbackTriggerApi({
    CausalityEngine? engine,
    this.cooldown = const Duration(seconds: 12),
  }) : _engine = engine ?? CausalityEngine();

  final CausalityEngine _engine;
  final Duration cooldown;
  final Map<String, DateTime> _lastTriggeredBySignature = <String, DateTime>{};

  CausalityFeedbackResponse evaluate(CausalityFeedbackRequest request) {
    final now = request.now ?? DateTime.now();
    final analysis = _engine.analyze(request.frames);
    final eligible = analysis.insights
        .where((insight) => insight.confidenceScore >= request.minConfidence)
        .toList(growable: false);

    final triggers = <CausalityFeedbackTrigger>[];
    var suppressed = 0;
    for (final insight in eligible) {
      if (triggers.length >= request.maxTriggers) {
        break;
      }
      final signature = _signature(insight);
      final previous = _lastTriggeredBySignature[signature];
      if (previous != null && now.difference(previous) < cooldown) {
        suppressed++;
        continue;
      }
      _lastTriggeredBySignature[signature] = now;
      triggers.add(CausalityFeedbackTrigger(
        triggerId: '${signature}:${insight.startedAt.microsecondsSinceEpoch}',
        triggeredAt: now,
        insight: insight,
      ));
    }

    _lastTriggeredBySignature.removeWhere(
      (_, at) => now.difference(at) > cooldown * 10,
    );

    return CausalityFeedbackResponse(
      analysis: analysis,
      triggers: triggers,
      suppressed: suppressed,
    );
  }

  void reset() {
    _lastTriggeredBySignature.clear();
  }
}

String _signature(CausalityInsight insight) {
  return '${insight.signal.name}:${insight.ruleId}:${insight.lapIndex ?? -1}:${insight.cornerIndex ?? -1}';
}

String _cornerKey(int lap, int corner) => '$lap:$corner';

double _mean(List<double> values) {
  if (values.isEmpty) {
    return 0.0;
  }
  var sum = 0.0;
  for (final value in values) {
    sum += value;
  }
  return sum / values.length;
}

double _pearson(List<double> a, List<double> b) {
  if (a.length != b.length || a.length < 3) {
    return 0.0;
  }
  final meanA = _mean(a);
  final meanB = _mean(b);
  var numerator = 0.0;
  var denA = 0.0;
  var denB = 0.0;
  for (var i = 0; i < a.length; i++) {
    final da = a[i] - meanA;
    final db = b[i] - meanB;
    numerator += da * db;
    denA += da * da;
    denB += db * db;
  }
  final denominator = sqrt(denA * denB);
  if (denominator <= 1e-9) {
    return 0.0;
  }
  return (numerator / denominator).clamp(-1.0, 1.0).toDouble();
}

bool _progressOverlaps(
  double aStart,
  double aEnd,
  double bStart,
  double bEnd,
) {
  final a0 = _wrap01(aStart);
  final a1 = _wrap01(aEnd);
  final b0 = _wrap01(bStart);
  final b1 = _wrap01(bEnd);
  final aSpan = _spanWithWrap(a0, a1);
  final bSpan = _spanWithWrap(b0, b1);
  final overlapStart = max(aSpan.$1, bSpan.$1);
  final overlapEnd = min(aSpan.$2, bSpan.$2);
  return overlapEnd >= overlapStart;
}

(double, double) _spanWithWrap(double start, double end) {
  if (end >= start) {
    return (start, end);
  }
  return (start, end + 1.0);
}

double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

double _wrap01(double value) {
  final wrapped = value % 1.0;
  return wrapped < 0 ? wrapped + 1.0 : wrapped;
}
