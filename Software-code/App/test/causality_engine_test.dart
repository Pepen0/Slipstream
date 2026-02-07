import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:client/causality_engine.dart';
import 'package:client/telemetry_analysis.dart';

void main() {
  test('designs inference rules for understeer and oversteer', () {
    expect(
      defaultCausalityInferenceRules.any(
        (rule) => rule.id == 'understeer_brake_steer_corr',
      ),
      isTrue,
    );
    expect(
      defaultCausalityInferenceRules.any(
        (rule) => rule.id == 'oversteer_countersteer_instability',
      ),
      isTrue,
    );
  });

  test('detects understeer from brake and steering correlation', () {
    final engine = CausalityEngine();
    final result = engine.analyze(_buildUndersteerSession());
    final understeer = result.insights
        .where((insight) => insight.signal == CausalitySignal.understeer)
        .toList(growable: false);

    expect(understeer, isNotEmpty);
    final top = understeer.first;
    expect(top.metrics['brakeSteerCorrelation'] ?? 0, greaterThan(0.44));
    expect(top.metrics['meanBrake'] ?? 0, greaterThan(0.26));
    expect(top.metrics['latDeficit'] ?? 0, greaterThan(0.10));
    expect(top.confidenceScore, greaterThan(0.4));
  });

  test('detects oversteer from counter-steer dynamics', () {
    final engine = CausalityEngine();
    final result = engine.analyze(_buildOversteerSession());
    final oversteer = result.insights
        .where((insight) => insight.signal == CausalitySignal.oversteer)
        .toList(growable: false);

    expect(oversteer, isNotEmpty);
    final top = oversteer.first;
    expect(top.metrics['counterSteerFlips'] ?? 0, greaterThanOrEqualTo(2));
    expect(
      (top.metrics['speedDropRatio'] ?? 0) > 0.11 ||
          (top.metrics['supportingEventScore'] ?? 0) > 0.25,
      isTrue,
    );
    expect(top.confidenceScore, greaterThan(0.4));
  });

  test('generates observation effect fix recommendations', () {
    const generator = CausalityRecommendationGenerator();
    final recommendation = generator.generate(
      signal: CausalitySignal.understeer,
      cornerIndex: 5,
      metrics: const {
        'entryOverspeed': 0.28,
        'latDeficit': 0.24,
        'brakeSteerCorrelation': 0.66,
      },
    );

    expect(recommendation.observation, contains('corner 5'));
    expect(recommendation.effect, isNotEmpty);
    expect(recommendation.fix.toLowerCase(), contains('brake'));
  });

  test('confidence scoring increases with stronger evidence', () {
    const model = CausalityConfidenceModel();
    final weak = model.score(
      ruleEvidence: 0.22,
      signalStrength: 0.2,
      supportingEventScore: 0.0,
      sampleCount: 8,
    );
    final strong = model.score(
      ruleEvidence: 0.78,
      signalStrength: 0.82,
      supportingEventScore: 0.55,
      sampleCount: 18,
    );

    expect(strong, greaterThan(weak));
    expect(strong, inInclusiveRange(0.0, 1.0));
  });

  test('feedback trigger API emits and rate-limits causal feedback', () {
    final api =
        CausalityFeedbackTriggerApi(cooldown: const Duration(seconds: 5));
    final frames = _buildUndersteerSession();
    final t0 = DateTime(2026, 2, 7, 12, 0, 0);

    final first = api.evaluate(CausalityFeedbackRequest(
      frames: frames,
      now: t0,
      maxTriggers: 2,
      minConfidence: 0.35,
    ));
    expect(first.analysis.insights, isNotEmpty);
    expect(first.triggers, isNotEmpty);
    expect(first.triggers.first.triggerId, contains('understeer'));

    final second = api.evaluate(CausalityFeedbackRequest(
      frames: frames,
      now: t0.add(const Duration(seconds: 2)),
      maxTriggers: 2,
      minConfidence: 0.35,
    ));
    expect(second.triggers, isEmpty);
    expect(second.suppressed, greaterThan(0));

    final third = api.evaluate(CausalityFeedbackRequest(
      frames: frames,
      now: t0.add(const Duration(seconds: 7)),
      maxTriggers: 2,
      minConfidence: 0.35,
    ));
    expect(third.triggers, isNotEmpty);
  });
}

List<TelemetryFrame> _buildUndersteerSession() {
  final frames = <TelemetryFrame>[];
  var timestamp = DateTime(2026, 2, 7, 11, 0, 0);
  const samples = 220;
  const step = Duration(milliseconds: 120);

  for (var i = 0; i < samples; i++) {
    final p = i / samples;
    final weave =
        sin(p * 32 * pi) * _gaussian(p, center: 0.47, width: 0.075) * 0.012;
    final progress = (p + weave).clamp(0.0, 0.999).toDouble();

    double speed = _baseLapSpeed(p);
    if (p >= 0.40 && p <= 0.48) {
      final ratio = (p - 0.40) / 0.08;
      speed = 168 - ratio * 62;
    } else if (p > 0.48 && p <= 0.56) {
      final ratio = (p - 0.48) / 0.08;
      speed = 106 + ratio * 36;
    }
    speed += sin(p * 10 * pi) * 2.0;

    var lateralG = 0.62 + _gaussian(p, center: 0.47, width: 0.08) * 0.58;
    if (p >= 0.44 && p <= 0.51) {
      lateralG = 0.21 + _gaussian(p, center: 0.47, width: 0.03) * 0.12;
    }

    frames.add(_frameAt(
      timestamp: timestamp,
      progress: progress,
      speedKmh: speed,
      lateralG: lateralG,
    ));
    timestamp = timestamp.add(step);
  }

  return frames;
}

List<TelemetryFrame> _buildOversteerSession() {
  final frames = <TelemetryFrame>[];
  var timestamp = DateTime(2026, 2, 7, 11, 30, 0);
  const samples = 220;
  const step = Duration(milliseconds: 120);
  const oscillation = <double>[
    0.000,
    0.014,
    -0.013,
    0.015,
    -0.014,
    0.016,
    -0.015,
    0.017,
    -0.016,
    0.017,
    -0.015,
    0.016,
  ];

  for (var i = 0; i < samples; i++) {
    final p = i / samples;
    var progress = p;
    var speed = _baseLapSpeed(p);
    var lateralG = 0.72 + _gaussian(p, center: 0.63, width: 0.06) * 0.45;

    if (i >= 130 && i < 130 + oscillation.length) {
      final k = i - 130;
      progress = 0.63 + oscillation[k];
      speed = 124 - k * 3.8;
      lateralG = 0.95;
    } else if (i >= 142 && i < 166) {
      speed = 79 + (i - 142) * 1.35;
      lateralG = 0.58;
    }

    frames.add(_frameAt(
      timestamp: timestamp,
      progress: progress.clamp(0.0, 0.999).toDouble(),
      speedKmh: speed,
      lateralG: lateralG,
    ));
    timestamp = timestamp.add(step);
  }

  return frames;
}

TelemetryFrame _frameAt({
  required DateTime timestamp,
  required double progress,
  required double speedKmh,
  required double lateralG,
}) {
  final speed = speedKmh.clamp(22.0, 260.0).toDouble();
  final gear = max(1, min(6, (1 + speed / 38).floor()));
  final rpm = 2300 + speed * 31;
  return TelemetryFrame(
    timestamp: timestamp,
    trackProgress: progress,
    speedKmh: speed,
    gear: gear,
    rpm: rpm,
    lateralG: lateralG,
  );
}

double _baseLapSpeed(double progress) {
  final corner1 = _gaussian(progress, center: 0.18, width: 0.05) * 52;
  final corner2 = _gaussian(progress, center: 0.52, width: 0.055) * 42;
  final corner3 = _gaussian(progress, center: 0.80, width: 0.045) * 56;
  return 170 - corner1 - corner2 - corner3;
}

double _gaussian(
  double x, {
  required double center,
  required double width,
}) {
  final normalized = (x - center) / max(1e-6, width);
  return exp(-normalized * normalized);
}
