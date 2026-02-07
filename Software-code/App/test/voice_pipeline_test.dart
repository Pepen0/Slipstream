import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

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
}
