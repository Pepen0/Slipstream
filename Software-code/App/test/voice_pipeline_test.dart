import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:client/event_detection.dart';
import 'package:client/services/ai_race_engineer.dart';
import 'package:client/services/voice_pipeline.dart';

class _FakeCapture implements AudioCapture {
  bool started = false;
  bool disposed = false;
  CapturedAudio? nextAudio;
  int startCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;

  @override
  Future<void> start() async {
    started = true;
    startCalls += 1;
  }

  @override
  Future<CapturedAudio?> stop() async {
    started = false;
    stopCalls += 1;
    return nextAudio;
  }

  @override
  Future<void> cancel() async {
    started = false;
    cancelCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _FakeSttClient implements SpeechToTextClient {
  int calls = 0;
  CapturedAudio? lastAudio;
  String transcript = 'driver command';

  @override
  Future<String> transcribe(CapturedAudio audio) async {
    calls += 1;
    lastAudio = audio;
    return transcript;
  }
}

class _FakeResponder implements VoiceResponder {
  int calls = 0;
  String? lastTranscript;
  VoiceVerbosity? lastVerbosity;
  VoiceResponse response = const VoiceResponse(text: 'roger');

  @override
  Future<VoiceResponse> respond(
    String transcript, {
    required VoiceVerbosity verbosity,
  }) async {
    calls += 1;
    lastTranscript = transcript;
    lastVerbosity = verbosity;
    return response;
  }
}

class _FakeTts implements LocalTts {
  int speakCalls = 0;
  int stopCalls = 0;
  String? lastText;
  VoiceVerbosity? lastVerbosity;

  @override
  Future<void> speak(String text, {required VoiceVerbosity verbosity}) async {
    speakCalls += 1;
    lastText = text;
    lastVerbosity = verbosity;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {}
}

class _FakePlayback implements AudioPlayback {
  int playCalls = 0;
  int stopCalls = 0;
  Uint8List? lastBytes;
  String? lastMimeType;

  @override
  Future<void> playBytes(Uint8List audioBytes,
      {String mimeType = 'audio/wav'}) async {
    playCalls += 1;
    lastBytes = audioBytes;
    lastMimeType = mimeType;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  CapturedAudio buildAudio([int bytes = 128]) {
    return CapturedAudio(
      bytes: Uint8List.fromList(List<int>.filled(bytes, 10)),
      sampleRateHz: 16000,
      channels: 1,
      duration: const Duration(milliseconds: 800),
    );
  }

  test('push-to-talk captures, buffers, submits, and speaks response',
      () async {
    final capture = _FakeCapture()..nextAudio = buildAudio(220);
    final stt = _FakeSttClient()..transcript = 'status report';
    final responder = _FakeResponder()
      ..response = const VoiceResponse(text: 'system nominal');
    final tts = _FakeTts();
    final playback = _FakePlayback();
    final controller = VoicePipelineController(
      capture: capture,
      sttClient: stt,
      responder: responder,
      tts: tts,
      playback: playback,
    );

    await controller.pushToTalkStart();
    expect(controller.state.recording, isTrue);
    expect(capture.startCalls, 1);

    await controller.pushToTalkStop();
    expect(controller.state.recording, isFalse);
    expect(controller.state.processing, isFalse);
    expect(controller.state.bufferedBytes, 220);
    expect(controller.state.lastTranscript, 'status report');
    expect(controller.state.lastResponseText, 'system nominal');
    expect(stt.calls, 1);
    expect(responder.calls, 1);
    expect(tts.speakCalls, 1);
    expect(playback.playCalls, 0);
  });

  test('audio response bytes go to playback path', () async {
    final capture = _FakeCapture()..nextAudio = buildAudio(64);
    final stt = _FakeSttClient();
    final responder = _FakeResponder()
      ..response = VoiceResponse(
        text: 'playing response',
        audioBytes: Uint8List.fromList([1, 2, 3, 4]),
      );
    final tts = _FakeTts();
    final playback = _FakePlayback();
    final controller = VoicePipelineController(
      capture: capture,
      sttClient: stt,
      responder: responder,
      tts: tts,
      playback: playback,
    );

    await controller.pushToTalkStart();
    await controller.pushToTalkStop();

    expect(playback.playCalls, 1);
    expect(playback.lastBytes, isNotNull);
    expect(tts.speakCalls, 0);
    expect(controller.state.lastResponseSuppressed, isFalse);
  });

  test('ducking suppresses AI playback during safety warning', () async {
    final capture = _FakeCapture()..nextAudio = buildAudio(96);
    final stt = _FakeSttClient();
    final responder = _FakeResponder()
      ..response = const VoiceResponse(text: 'hazard update');
    final tts = _FakeTts();
    final playback = _FakePlayback();
    final controller = VoicePipelineController(
      capture: capture,
      sttClient: stt,
      responder: responder,
      tts: tts,
      playback: playback,
    );

    controller.setDuckingEnabled(true);
    await controller.setSafetyWarningActive(true);

    await controller.pushToTalkStart();
    await controller.pushToTalkStop();

    expect(controller.state.lastResponseSuppressed, isTrue);
    expect(controller.state.status, contains('suppressed'));
    expect(tts.speakCalls, 0);
    expect(playback.playCalls, 0);
  });

  test('verbosity slider setting is passed to responder and tts', () async {
    final capture = _FakeCapture()..nextAudio = buildAudio(180);
    final stt = _FakeSttClient();
    final responder = _FakeResponder();
    final tts = _FakeTts();
    final playback = _FakePlayback();
    final controller = VoicePipelineController(
      capture: capture,
      sttClient: stt,
      responder: responder,
      tts: tts,
      playback: playback,
    );

    controller.setVerbosity(VoiceVerbosity.high);
    await controller.pushToTalkStart();
    await controller.pushToTalkStop();

    expect(responder.lastVerbosity, VoiceVerbosity.high);
    expect(tts.lastVerbosity, VoiceVerbosity.high);
    expect(controller.state.verbosity, VoiceVerbosity.high);
  });

  test('rate limiting suppresses repeated voice responses', () async {
    final capture = _FakeCapture()..nextAudio = buildAudio(180);
    final stt = _FakeSttClient()..transcript = 'status';
    final responder = _FakeResponder();
    final tts = _FakeTts();
    final playback = _FakePlayback();
    final controller = VoicePipelineController(
      capture: capture,
      sttClient: stt,
      responder: responder,
      tts: tts,
      playback: playback,
      rateLimiter: RaceEngineerRateLimiter(
        burst: 1,
        minGap: const Duration(seconds: 8),
        window: const Duration(seconds: 10),
      ),
    );

    await controller.pushToTalkStart();
    await controller.pushToTalkStop();
    expect(responder.calls, 1);
    expect(controller.state.lastResponseSuppressed, isFalse);

    await controller.pushToTalkStart();
    await controller.pushToTalkStop();
    expect(responder.calls, 1, reason: 'second response should be suppressed');
    expect(controller.state.lastResponseSuppressed, isTrue);
    expect(controller.state.lastPolicyReason, 'silenceRateLimit');
    expect(controller.state.rateLimitedResponses, 1);
  });

  test('safety gating suppresses response during fault even when ducking off',
      () async {
    final capture = _FakeCapture()..nextAudio = buildAudio(120);
    final stt = _FakeSttClient()..transcript = 'pace delta';
    final responder = _FakeResponder();
    final tts = _FakeTts();
    final playback = _FakePlayback();
    final controller = VoicePipelineController(
      capture: capture,
      sttClient: stt,
      responder: responder,
      tts: tts,
      playback: playback,
    );

    controller.setDuckingEnabled(false);
    controller.updateRaceContext(faultActive: true);
    await controller.pushToTalkStart();
    await controller.pushToTalkStop();

    expect(responder.calls, 0);
    expect(controller.state.lastResponseSuppressed, isTrue);
    expect(controller.state.status.toLowerCase(), contains('safety'));
    expect(controller.state.lastPolicyReason, 'silenceSafetyGate');
  });

  test('event detector output is injected into AI prompt context', () async {
    final capture = _FakeCapture()..nextAudio = buildAudio(128);
    final stt = _FakeSttClient()..transcript = 'sector review';
    final responder = _FakeResponder()
      ..response = const VoiceResponse(text: 'sector note');
    final controller = VoicePipelineController(
      capture: capture,
      sttClient: stt,
      responder: responder,
      tts: _FakeTts(),
      playback: _FakePlayback(),
    );

    controller.updateRaceContext(
      speedKmh: 151,
      gear: 4,
      rpm: 6800,
      trackProgress: 0.42,
      trackId: 'spa',
      driverLevel: 'advanced',
      events: [
        TelemetryEvent(
          type: TelemetryEventType.apexMiss,
          startedAt: DateTime(2026, 2, 7, 12, 0, 1),
          endedAt: DateTime(2026, 2, 7, 12, 0, 2),
          startProgress: 0.4,
          endProgress: 0.45,
          severityScore: 0.78,
          summary: 'Late apex at T10',
        ),
      ],
    );

    await controller.pushToTalkStart();
    await controller.pushToTalkStop();

    expect(controller.state.lastIntent, 'command');
    expect(responder.lastTranscript?.toLowerCase(), contains('apex miss'));
    expect(controller.state.lastPromptPreview.toLowerCase(),
        contains('race engineer'));
  });

  test('latency target is flagged when telemetry context is stale', () async {
    final capture = _FakeCapture()..nextAudio = buildAudio(90);
    final stt = _FakeSttClient()..transcript = 'status';
    final responder = _FakeResponder();
    final controller = VoicePipelineController(
      capture: capture,
      sttClient: stt,
      responder: responder,
      tts: _FakeTts(),
      playback: _FakePlayback(),
    );

    controller.updateRaceContext(
      speedKmh: 133,
      gear: 4,
      rpm: 6200,
      trackProgress: 0.31,
      telemetryCapturedAt:
          DateTime.now().subtract(const Duration(milliseconds: 820)),
    );

    await controller.pushToTalkStart();
    await controller.pushToTalkStop();

    expect(controller.state.lastTelemetryToTextLatencyMs, greaterThan(500));
    expect(controller.state.latencyTargetMet, isFalse);
  });
}
