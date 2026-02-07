import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum VoiceVerbosity {
  low,
  medium,
  high,
}

String voiceVerbosityLabel(VoiceVerbosity verbosity) {
  switch (verbosity) {
    case VoiceVerbosity.low:
      return 'Low';
    case VoiceVerbosity.medium:
      return 'Med';
    case VoiceVerbosity.high:
      return 'High';
  }
}

class CapturedAudio {
  const CapturedAudio({
    required this.bytes,
    required this.sampleRateHz,
    required this.channels,
    required this.duration,
  });

  final Uint8List bytes;
  final int sampleRateHz;
  final int channels;
  final Duration duration;
}

class VoiceResponse {
  const VoiceResponse({
    required this.text,
    this.audioBytes,
    this.mimeType = 'audio/wav',
  });

  final String text;
  final Uint8List? audioBytes;
  final String mimeType;
}

class VoicePipelineState {
  const VoicePipelineState({
    this.recording = false,
    this.processing = false,
    this.duckingEnabled = true,
    this.safetyWarningActive = false,
    this.lastResponseSuppressed = false,
    this.bufferedBytes = 0,
    this.lastTranscript = '',
    this.lastResponseText = '',
    this.status = 'Voice idle',
    this.verbosity = VoiceVerbosity.medium,
  });

  final bool recording;
  final bool processing;
  final bool duckingEnabled;
  final bool safetyWarningActive;
  final bool lastResponseSuppressed;
  final int bufferedBytes;
  final String lastTranscript;
  final String lastResponseText;
  final String status;
  final VoiceVerbosity verbosity;

  VoicePipelineState copyWith({
    bool? recording,
    bool? processing,
    bool? duckingEnabled,
    bool? safetyWarningActive,
    bool? lastResponseSuppressed,
    int? bufferedBytes,
    String? lastTranscript,
    String? lastResponseText,
    String? status,
    VoiceVerbosity? verbosity,
  }) {
    return VoicePipelineState(
      recording: recording ?? this.recording,
      processing: processing ?? this.processing,
      duckingEnabled: duckingEnabled ?? this.duckingEnabled,
      safetyWarningActive: safetyWarningActive ?? this.safetyWarningActive,
      lastResponseSuppressed:
          lastResponseSuppressed ?? this.lastResponseSuppressed,
      bufferedBytes: bufferedBytes ?? this.bufferedBytes,
      lastTranscript: lastTranscript ?? this.lastTranscript,
      lastResponseText: lastResponseText ?? this.lastResponseText,
      status: status ?? this.status,
      verbosity: verbosity ?? this.verbosity,
    );
  }
}

abstract class AudioCapture {
  Future<void> start();

  Future<CapturedAudio?> stop();

  Future<void> cancel();

  Future<void> dispose();
}

abstract class SpeechToTextClient {
  Future<String> transcribe(CapturedAudio audio);
}

abstract class VoiceResponder {
  Future<VoiceResponse> respond(
    String transcript, {
    required VoiceVerbosity verbosity,
  });
}

abstract class LocalTts {
  Future<void> speak(String text, {required VoiceVerbosity verbosity});

  Future<void> stop();

  Future<void> dispose();
}

abstract class AudioPlayback {
  Future<void> playBytes(Uint8List audioBytes, {String mimeType});

  Future<void> stop();

  Future<void> dispose();
}

class VoicePipelineController extends ChangeNotifier {
  VoicePipelineController({
    AudioCapture? capture,
    SpeechToTextClient? sttClient,
    VoiceResponder? responder,
    LocalTts? tts,
    AudioPlayback? playback,
  })  : _capture = capture ?? RecordAudioCapture(),
        _sttClient = sttClient ?? BufferedSttSubmissionClient(),
        _responder = responder ?? RuleBasedVoiceResponder(),
        _tts = tts ?? LocalDesktopTts(),
        _playback = playback ?? LocalAudioPlayback();

  final AudioCapture _capture;
  final SpeechToTextClient _sttClient;
  final VoiceResponder _responder;
  final LocalTts _tts;
  final AudioPlayback _playback;

  VoicePipelineState _state = const VoicePipelineState();

  VoicePipelineState get state => _state;

  void setVerbosity(VoiceVerbosity verbosity) {
    _state = _state.copyWith(verbosity: verbosity);
    notifyListeners();
  }

  void setDuckingEnabled(bool enabled) {
    _state = _state.copyWith(duckingEnabled: enabled);
    notifyListeners();
  }

  Future<void> setSafetyWarningActive(bool active) async {
    if (_state.safetyWarningActive == active) {
      return;
    }
    _state = _state.copyWith(safetyWarningActive: active);
    if (active && _state.duckingEnabled) {
      await Future.wait<void>([
        _tts.stop(),
        _playback.stop(),
      ]);
      _state = _state.copyWith(
        status: 'AI audio suppressed due to safety warning.',
        lastResponseSuppressed: true,
      );
    }
    notifyListeners();
  }

  Future<void> pushToTalkStart() async {
    if (_state.recording || _state.processing) {
      return;
    }
    try {
      await _capture.start();
      _state = _state.copyWith(
        recording: true,
        status: 'Recording command…',
      );
    } catch (error) {
      _state = _state.copyWith(
        recording: false,
        status: 'Microphone unavailable: $error',
      );
    }
    notifyListeners();
  }

  Future<void> pushToTalkStop() async {
    if (!_state.recording) {
      return;
    }

    _state = _state.copyWith(
      recording: false,
      processing: true,
      status: 'Submitting audio for STT…',
    );
    notifyListeners();

    CapturedAudio? captured;
    try {
      captured = await _capture.stop();
    } catch (error) {
      _state = _state.copyWith(
        processing: false,
        status: 'Audio capture failed: $error',
      );
      notifyListeners();
      return;
    }

    if (captured == null || captured.bytes.isEmpty) {
      _state = _state.copyWith(
        processing: false,
        bufferedBytes: 0,
        status: 'No audio captured.',
      );
      notifyListeners();
      return;
    }

    final transcript = await _sttClient.transcribe(captured);
    final response = await _responder.respond(
      transcript,
      verbosity: _state.verbosity,
    );

    final shouldDuck = _state.duckingEnabled && _state.safetyWarningActive;
    if (shouldDuck) {
      await Future.wait<void>([
        _tts.stop(),
        _playback.stop(),
      ]);
      _state = _state.copyWith(
        processing: false,
        bufferedBytes: captured.bytes.length,
        lastTranscript: transcript,
        lastResponseText: response.text,
        status: 'Response suppressed by safety audio ducking.',
        lastResponseSuppressed: true,
      );
      notifyListeners();
      return;
    }

    if (response.audioBytes != null && response.audioBytes!.isNotEmpty) {
      await _playback.playBytes(
        response.audioBytes!,
        mimeType: response.mimeType,
      );
    } else {
      await _tts.speak(
        response.text,
        verbosity: _state.verbosity,
      );
    }

    _state = _state.copyWith(
      processing: false,
      bufferedBytes: captured.bytes.length,
      lastTranscript: transcript,
      lastResponseText: response.text,
      status: 'Voice response ready.',
      lastResponseSuppressed: false,
    );
    notifyListeners();
  }

  Future<void> cancelCapture() async {
    if (!_state.recording) {
      return;
    }
    await _capture.cancel();
    _state = _state.copyWith(
      recording: false,
      processing: false,
      status: 'Recording canceled.',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_capture.dispose());
    unawaited(_tts.dispose());
    unawaited(_playback.dispose());
    super.dispose();
  }
}

class RecordAudioCapture implements AudioCapture {
  RecordAudioCapture({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  DateTime? _startedAt;
  String? _path;
  static const int _sampleRate = 16000;
  static const int _channels = 1;

  @override
  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      throw StateError('microphone permission denied');
    }
    final dir = await getTemporaryDirectory();
    _path =
        '${dir.path}/slipstream_voice_${DateTime.now().microsecondsSinceEpoch}.wav';
    _startedAt = DateTime.now();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: _sampleRate,
        numChannels: _channels,
      ),
      path: _path!,
    );
  }

  @override
  Future<CapturedAudio?> stop() async {
    final path = await _recorder.stop();
    final audioPath = path ?? _path;
    _path = null;
    if (audioPath == null) {
      return null;
    }
    final file = File(audioPath);
    if (!await file.exists()) {
      return null;
    }
    final bytes = await file.readAsBytes();
    final startedAt = _startedAt;
    _startedAt = null;
    final duration = startedAt == null
        ? Duration.zero
        : DateTime.now().difference(startedAt);

    return CapturedAudio(
      bytes: bytes,
      sampleRateHz: _sampleRate,
      channels: _channels,
      duration: duration,
    );
  }

  @override
  Future<void> cancel() async {
    _startedAt = null;
    _path = null;
    await _recorder.stop();
  }

  @override
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

class BufferedSttSubmissionClient implements SpeechToTextClient {
  @override
  Future<String> transcribe(CapturedAudio audio) async {
    final kb = (audio.bytes.length / 1024.0).toStringAsFixed(1);
    final seconds = audio.duration.inMilliseconds / 1000.0;
    return 'captured ${kb}KB voice sample (${seconds.toStringAsFixed(1)}s)';
  }
}

class RuleBasedVoiceResponder implements VoiceResponder {
  @override
  Future<VoiceResponse> respond(
    String transcript, {
    required VoiceVerbosity verbosity,
  }) async {
    final compact = _buildSummary(transcript: transcript, verbosity: verbosity);
    final wantsAudio = verbosity == VoiceVerbosity.high ||
        transcript.toLowerCase().contains('playback');
    if (!wantsAudio) {
      return VoiceResponse(text: compact);
    }

    return VoiceResponse(
      text: compact,
      audioBytes: _buildToneWav(
        frequencyHz: 620.0,
        durationMs: 520,
      ),
      mimeType: 'audio/wav',
    );
  }

  String _buildSummary({
    required String transcript,
    required VoiceVerbosity verbosity,
  }) {
    switch (verbosity) {
      case VoiceVerbosity.low:
        return 'Command received. $transcript';
      case VoiceVerbosity.medium:
        return 'Command received. I buffered the sample, parsed intent, and queued guidance: $transcript';
      case VoiceVerbosity.high:
        return 'Command received. I buffered client audio, submitted it to the STT stage, interpreted intent, and prepared a detailed response. Transcript: $transcript';
    }
  }

  Uint8List _buildToneWav({
    required double frequencyHz,
    required int durationMs,
  }) {
    const sampleRate = 16000;
    const channels = 1;
    const bitsPerSample = 16;
    final sampleCount = (sampleRate * durationMs) ~/ 1000;
    final byteCount = sampleCount * (bitsPerSample ~/ 8) * channels;
    final totalSize = 44 + byteCount;

    final data = ByteData(totalSize);
    void writeAscii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        data.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    data.setUint32(4, totalSize - 8, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, channels, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * channels * 2, Endian.little);
    data.setUint16(32, channels * 2, Endian.little);
    data.setUint16(34, bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    data.setUint32(40, byteCount, Endian.little);

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final envelope = (1.0 - (i / sampleCount)).clamp(0.0, 1.0);
      final value =
          (sin(2 * pi * frequencyHz * t) * 0.35 * envelope * 32767).round();
      data.setInt16(44 + i * 2, value, Endian.little);
    }

    return data.buffer.asUint8List();
  }
}

class LocalDesktopTts implements LocalTts {
  LocalDesktopTts({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

  bool get _supported => !kIsWeb && (Platform.isWindows || Platform.isMacOS);

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }
    await _tts.awaitSpeakCompletion(true);
    _configured = true;
  }

  @override
  Future<void> speak(String text, {required VoiceVerbosity verbosity}) async {
    if (!_supported || text.trim().isEmpty) {
      return;
    }
    await _ensureConfigured();
    final speechRate = switch (verbosity) {
      VoiceVerbosity.low => 0.54,
      VoiceVerbosity.medium => 0.46,
      VoiceVerbosity.high => 0.40,
    };
    await _tts.setSpeechRate(speechRate);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    if (!_supported) {
      return;
    }
    await _tts.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}

class LocalAudioPlayback implements AudioPlayback {
  LocalAudioPlayback({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> playBytes(Uint8List audioBytes,
      {String mimeType = 'audio/wav'}) async {
    if (audioBytes.isEmpty) {
      return;
    }
    final extension = mimeType.contains('wav') ? 'wav' : 'bin';
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/slipstream_voice_response_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final file = File(path);
    await file.writeAsBytes(audioBytes, flush: true);
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}
