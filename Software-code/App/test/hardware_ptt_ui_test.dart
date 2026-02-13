import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fixnum/fixnum.dart';

import 'package:client/gen/dashboard/v1/dashboard.pb.dart';
import 'package:client/main.dart';
import 'package:client/services/dashboard_client.dart';
import 'package:client/services/voice_pipeline.dart';

class _FakeDashboardClient extends DashboardClient {
  _FakeDashboardClient();

  @override
  Future<void> connect() async {
    final status = Status()
      ..state = Status_State.STATE_IDLE
      ..updatedAtNs = Int64(DateTime.now().microsecondsSinceEpoch * 1000);
    snapshot.value = DashboardSnapshot(
      status: status,
      connected: true,
    );
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> refreshStatus() async {}

  @override
  void startTelemetryStream({String sessionId = ''}) {}

  @override
  void startInputEventStream() {}

  void emitPtt({
    required int sequence,
    required InputEvent_Type type,
  }) {
    final status = (snapshot.value.status?.deepCopy() ?? Status())
      ..updatedAtNs = Int64(DateTime.now().microsecondsSinceEpoch * 1000);
    final event = InputEvent()
      ..sequence = Int64(sequence)
      ..type = type
      ..source = InputEvent_Source.INPUT_EVENT_SOURCE_STEERING_WHEEL
      ..receivedAtNs = Int64(DateTime.now().microsecondsSinceEpoch * 1000);
    snapshot.value = snapshot.value.copyWith(
      status: status,
      inputEvent: event,
      connected: true,
      error: null,
    );
  }
}

class _NoopCapture implements AudioCapture {
  @override
  Future<void> start() async {}

  @override
  Future<CapturedAudio?> stop() async {
    return CapturedAudio(
      bytes: Uint8List(0),
      sampleRateHz: 16000,
      channels: 1,
      duration: Duration.zero,
    );
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

class _NoopSttClient implements SpeechToTextClient {
  @override
  Future<String> transcribe(CapturedAudio audio) async => '';
}

class _NoopResponder implements VoiceResponder {
  @override
  Future<VoiceResponse> respond(String transcript,
      {required VoiceVerbosity verbosity}) async {
    return const VoiceResponse(text: '');
  }
}

class _NoopTts implements LocalTts {
  @override
  Future<void> speak(String text, {required VoiceVerbosity verbosity}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _NoopPlayback implements AudioPlayback {
  @override
  Future<void> playBytes(Uint8List audioBytes,
      {String mimeType = 'audio/wav'}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeVoicePipelineController extends VoicePipelineController {
  _FakeVoicePipelineController()
      : super(
          capture: _NoopCapture(),
          sttClient: _NoopSttClient(),
          responder: _NoopResponder(),
          tts: _NoopTts(),
          playback: _NoopPlayback(),
        );

  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> pushToTalkStart() async {
    startCalls += 1;
  }

  @override
  Future<void> pushToTalkStop() async {
    stopCalls += 1;
  }
}

void main() {
  testWidgets('hardware PTT input events trigger voice start and stop',
      (WidgetTester tester) async {
    final client = _FakeDashboardClient();
    final voice = _FakeVoicePipelineController();

    await tester.pumpWidget(
      DashboardApp(
        clientFactory: () => client,
        voicePipelineFactory: () => voice,
      ),
    );
    await tester.pump();

    client.emitPtt(
      sequence: 1,
      type: InputEvent_Type.INPUT_EVENT_TYPE_PTT_DOWN,
    );
    await tester.pump();
    expect(voice.startCalls, 1);
    expect(voice.stopCalls, 0);

    client.emitPtt(
      sequence: 2,
      type: InputEvent_Type.INPUT_EVENT_TYPE_PTT_UP,
    );
    await tester.pump();
    expect(voice.startCalls, 1);
    expect(voice.stopCalls, 1);

    client.emitPtt(
      sequence: 2,
      type: InputEvent_Type.INPUT_EVENT_TYPE_PTT_UP,
    );
    await tester.pump();
    expect(voice.stopCalls, 1);
  });
}
