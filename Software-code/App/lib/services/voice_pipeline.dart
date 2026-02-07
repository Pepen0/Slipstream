import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../event_detection.dart';
import 'ai_race_engineer.dart';

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
    this.lastIntent = '',
    this.lastPolicyReason = '',
    this.lastTelemetryToTextLatencyMs = 0,
    this.latencyTargetMet = true,
    this.rateLimitedResponses = 0,
    this.lastPromptPreview = '',
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
  final String lastIntent;
  final String lastPolicyReason;
  final int lastTelemetryToTextLatencyMs;
  final bool latencyTargetMet;
  final int rateLimitedResponses;
  final String lastPromptPreview;

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
    String? lastIntent,
    String? lastPolicyReason,
    int? lastTelemetryToTextLatencyMs,
    bool? latencyTargetMet,
    int? rateLimitedResponses,
    String? lastPromptPreview,
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
      lastIntent: lastIntent ?? this.lastIntent,
      lastPolicyReason: lastPolicyReason ?? this.lastPolicyReason,
      lastTelemetryToTextLatencyMs:
          lastTelemetryToTextLatencyMs ?? this.lastTelemetryToTextLatencyMs,
      latencyTargetMet: latencyTargetMet ?? this.latencyTargetMet,
      rateLimitedResponses: rateLimitedResponses ?? this.rateLimitedResponses,
      lastPromptPreview: lastPromptPreview ?? this.lastPromptPreview,
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
    RaceEngineerIntentClassifier? intentClassifier,
    RaceEngineerContextInjector? contextInjector,
    RaceEngineerDecisionPolicy? decisionPolicy,
    RaceEngineerTokenGenerator? tokenGenerator,
    RaceEngineerRateLimiter? rateLimiter,
    RaceEngineerLatencyTracker? latencyTracker,
  })  : _capture = capture ?? RecordAudioCapture(),
        _sttClient = sttClient ?? WhisperLikeSttSubmissionClient(),
        _responder = responder ?? AiRaceEngineerResponder(),
        _tts = tts ?? LocalDesktopTts(),
        _playback = playback ?? LocalAudioPlayback(),
        _intentClassifier =
            intentClassifier ?? const RaceEngineerIntentClassifier(),
        _contextInjector = contextInjector ?? const RaceEngineerContextInjector(),
        _decisionPolicy = decisionPolicy ?? const RaceEngineerDecisionPolicy(),
        _tokenGenerator =
            tokenGenerator ?? const RaceEngineerTokenGenerator(maxChars: 164),
        _rateLimiter = rateLimiter ?? RaceEngineerRateLimiter(),
        _latencyTracker = latencyTracker ?? RaceEngineerLatencyTracker();

  final AudioCapture _capture;
  final SpeechToTextClient _sttClient;
  final VoiceResponder _responder;
  final LocalTts _tts;
  final AudioPlayback _playback;
  final RaceEngineerIntentClassifier _intentClassifier;
  final RaceEngineerContextInjector _contextInjector;
  final RaceEngineerDecisionPolicy _decisionPolicy;
  final RaceEngineerTokenGenerator _tokenGenerator;
  final RaceEngineerRateLimiter _rateLimiter;
  final RaceEngineerLatencyTracker _latencyTracker;

  VoicePipelineState _state = const VoicePipelineState();
  RaceEngineerContextEnvelope _engineerContext =
      const RaceEngineerContextEnvelope();

  VoicePipelineState get state => _state;

  void updateRaceContext({
    double? speedKmh,
    int? gear,
    double? rpm,
    double? trackProgress,
    int? lapIndex,
    double? deltaSeconds,
    double? throttle,
    double? brake,
    double? steering,
    String? trackId,
    String? sectorLabel,
    String? weather,
    String? gripLabel,
    String? driverLevel,
    double? consistency,
    double? aggression,
    List<TelemetryEvent>? events,
    bool? faultActive,
    bool? estopActive,
    DateTime? telemetryCapturedAt,
  }) {
    var telemetry = _engineerContext.telemetry;
    final nextSpeed = speedKmh ?? telemetry?.speedKmh;
    final nextGear = gear ?? telemetry?.gear;
    final nextRpm = rpm ?? telemetry?.rpm;
    final nextProgress = trackProgress ?? telemetry?.trackProgress;

    if (nextSpeed != null &&
        nextGear != null &&
        nextRpm != null &&
        nextProgress != null) {
      telemetry = RaceEngineerTelemetryContext(
        speedKmh: nextSpeed,
        gear: nextGear,
        rpm: nextRpm,
        trackProgress: nextProgress,
        capturedAt: telemetryCapturedAt ?? DateTime.now(),
        lapIndex: lapIndex ?? telemetry?.lapIndex,
        deltaSeconds: deltaSeconds ?? telemetry?.deltaSeconds,
        throttle: throttle ?? telemetry?.throttle,
        brake: brake ?? telemetry?.brake,
        steering: steering ?? telemetry?.steering,
      );
      _latencyTracker.markTelemetry(telemetry.capturedAt);
    }

    final track = RaceEngineerTrackContext(
      trackId: trackId ?? _engineerContext.track.trackId,
      sectorLabel: sectorLabel ?? _engineerContext.track.sectorLabel,
      weather: weather ?? _engineerContext.track.weather,
      gripLabel: gripLabel ?? _engineerContext.track.gripLabel,
      cornerIndex: _engineerContext.track.cornerIndex,
    );
    final driver = RaceEngineerDriverContext(
      level: driverLevel ?? _engineerContext.driver.level,
      consistency: consistency ?? _engineerContext.driver.consistency,
      aggression: aggression ?? _engineerContext.driver.aggression,
    );
    final injectedEvents = events == null
        ? _engineerContext.events
        : _contextInjector.injectEventContext(events);

    _engineerContext = _engineerContext.copyWith(
      telemetry: telemetry,
      track: track,
      driver: driver,
      events: injectedEvents,
      faultActive: faultActive ?? _engineerContext.faultActive,
      estopActive: estopActive ?? _engineerContext.estopActive,
    );
  }

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
    _engineerContext =
        _engineerContext.copyWith(safetyWarningActive: active);
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
    final intent = _intentClassifier.classify(transcript);
    final detail = _detailLevelFromVerbosity(_state.verbosity);
    final context = _engineerContext.copyWith(
      safetyWarningActive: _state.safetyWarningActive,
    );
    final prompt = _contextInjector.buildPrompt(
      transcript: transcript,
      intent: intent,
      context: context,
      detailLevel: detail,
    );
    final rateAllowed = _rateLimiter.allow();
    final decision = _decisionPolicy.evaluate(
      intent: intent,
      context: context,
      rateLimited: !rateAllowed,
    );
    final engineeredText = _tokenGenerator.buildTokenText(
      intent: intent,
      context: context,
      decision: decision,
      detailLevel: detail,
    );

    final shouldDuck = _state.duckingEnabled && _state.safetyWarningActive;
    if (!decision.shouldSpeak || shouldDuck) {
      await Future.wait<void>([
        _tts.stop(),
        _playback.stop(),
      ]);
      final latencyMs = _latencyTracker.telemetryToTextLatencyMs();
      _state = _state.copyWith(
        processing: false,
        bufferedBytes: captured.bytes.length,
        lastTranscript: transcript,
        lastResponseText: engineeredText,
        status: _suppressedStatus(decision, shouldDuck: shouldDuck),
        lastResponseSuppressed: true,
        lastIntent: intent.kind.name,
        lastPolicyReason: decision.reason.name,
        lastPromptPreview: _trimPromptPreview(prompt),
        lastTelemetryToTextLatencyMs: latencyMs,
        latencyTargetMet: _latencyTracker.meetsTarget(latencyMs),
        rateLimitedResponses: decision.reason ==
                RaceEngineerDecisionReason.silenceRateLimit
            ? _state.rateLimitedResponses + 1
            : _state.rateLimitedResponses,
      );
      notifyListeners();
      return;
    }

    final responderInput = engineeredText.isEmpty ? transcript : engineeredText;
    final response = await _responder.respond(
      responderInput,
      verbosity: _state.verbosity,
    );
    final latencyMs = _latencyTracker.telemetryToTextLatencyMs();
    final targetMet = _latencyTracker.meetsTarget(latencyMs);

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
      status: targetMet
          ? 'Voice response ready.'
          : 'Voice response ready (latency target missed).',
      lastResponseSuppressed: false,
      lastIntent: intent.kind.name,
      lastPolicyReason: decision.reason.name,
      lastPromptPreview: _trimPromptPreview(prompt),
      lastTelemetryToTextLatencyMs: latencyMs,
      latencyTargetMet: targetMet,
    );
    notifyListeners();
  }

  RaceEngineerDetailLevel _detailLevelFromVerbosity(VoiceVerbosity verbosity) {
    switch (verbosity) {
      case VoiceVerbosity.low:
        return RaceEngineerDetailLevel.brief;
      case VoiceVerbosity.medium:
        return RaceEngineerDetailLevel.standard;
      case VoiceVerbosity.high:
        return RaceEngineerDetailLevel.detailed;
    }
  }

  String _suppressedStatus(
    RaceEngineerDecision decision, {
    required bool shouldDuck,
  }) {
    if (shouldDuck) {
      return 'Response suppressed by safety audio ducking.';
    }
    switch (decision.reason) {
      case RaceEngineerDecisionReason.silenceSafetyGate:
        return 'Response suppressed by safety gate.';
      case RaceEngineerDecisionReason.silenceRateLimit:
        return 'Response suppressed by rate limit.';
      case RaceEngineerDecisionReason.rejectUnsafeCommand:
        return 'Response blocked: unsafe command.';
      case RaceEngineerDecisionReason.silenceLowSignal:
        return 'Response suppressed (low signal).';
      case RaceEngineerDecisionReason.speak:
        return 'Response suppressed.';
    }
  }

  String _trimPromptPreview(String prompt) {
    final compact = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 220) {
      return compact;
    }
    final eventsIndex = compact.toLowerCase().indexOf('events:');
    if (eventsIndex >= 0) {
      final start = max(0, eventsIndex - 48);
      final end = min(compact.length, eventsIndex + 172);
      final snippet = compact.substring(start, end);
      return start > 0 ? '…$snippet…' : '$snippet…';
    }
    return '${compact.substring(0, 220)}…';
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

abstract class WhisperTranscriber {
  Future<String> transcribePcm(
    Uint8List audioBytes, {
    required int sampleRateHz,
    required int channels,
  });
}

class WhisperLikeSttSubmissionClient implements SpeechToTextClient {
  WhisperLikeSttSubmissionClient({WhisperTranscriber? transcriber})
      : _transcriber = transcriber;

  final WhisperTranscriber? _transcriber;

  @override
  Future<String> transcribe(CapturedAudio audio) async {
    final transcriber = _transcriber;
    if (transcriber != null) {
      final transcript = await transcriber.transcribePcm(
        audio.bytes,
        sampleRateHz: audio.sampleRateHz,
        channels: audio.channels,
      );
      if (transcript.trim().isNotEmpty) {
        return transcript.trim();
      }
    }
    final kb = (audio.bytes.length / 1024.0).toStringAsFixed(1);
    final seconds = audio.duration.inMilliseconds / 1000.0;
    return 'captured ${kb}KB voice sample (${seconds.toStringAsFixed(1)}s)';
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

class AiRaceEngineerResponder implements VoiceResponder {
  @override
  Future<VoiceResponse> respond(
    String transcript, {
    required VoiceVerbosity verbosity,
  }) async {
    final compact = transcript.trim();
    if (compact.isEmpty) {
      return const VoiceResponse(text: '');
    }

    final wantsTone = verbosity == VoiceVerbosity.high &&
        compact.toLowerCase().contains('playback');
    if (!wantsTone) {
      return VoiceResponse(text: compact);
    }

    return VoiceResponse(
      text: compact,
      audioBytes: _buildToneWav(
        frequencyHz: 680.0,
        durationMs: 420,
      ),
      mimeType: 'audio/wav',
    );
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
          (sin(2 * pi * frequencyHz * t) * 0.34 * envelope * 32767).round();
      data.setInt16(44 + i * 2, value, Endian.little);
    }
    return data.buffer.asUint8List();
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
