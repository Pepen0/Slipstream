import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';

import '../gen/dashboard/v1/dashboard.pbgrpc.dart';

class DashboardSnapshot {
  final Status? status;
  final TelemetrySample? telemetry;
  final InputEvent? inputEvent;
  final bool connected;
  final String? error;

  const DashboardSnapshot({
    this.status,
    this.telemetry,
    this.inputEvent,
    this.connected = false,
    this.error,
  });

  DashboardSnapshot copyWith({
    Status? status,
    TelemetrySample? telemetry,
    InputEvent? inputEvent,
    bool? connected,
    String? error,
  }) {
    return DashboardSnapshot(
      status: status ?? this.status,
      telemetry: telemetry ?? this.telemetry,
      inputEvent: inputEvent ?? this.inputEvent,
      connected: connected ?? this.connected,
      error: error,
    );
  }
}

class DashboardClient {
  DashboardClient({this.host = '127.0.0.1', this.port = 50060});

  final String host;
  final int port;

  final ValueNotifier<DashboardSnapshot> snapshot =
      ValueNotifier(const DashboardSnapshot());

  ClientChannel? _channel;
  DashboardServiceClient? _stub;
  Timer? _pollTimer;
  StreamSubscription<TelemetrySample>? _telemetrySub;
  StreamSubscription<InputEvent>? _inputEventSub;

  Future<void> connect() async {
    if (_channel != null) {
      return;
    }

    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    _stub = DashboardServiceClient(_channel!);

    _pollTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => refreshStatus());
    await refreshStatus();
  }

  Future<void> disconnect() async {
    await _telemetrySub?.cancel();
    _telemetrySub = null;
    await _inputEventSub?.cancel();
    _inputEventSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    await _channel?.shutdown();
    _channel = null;
    _stub = null;
    snapshot.value = snapshot.value.copyWith(connected: false, error: null);
  }

  bool get isConnected {
    final updatedAt = snapshot.value.status?.updatedAtNs.toInt();
    if (updatedAt == null) {
      return false;
    }
    final now = DateTime.now().microsecondsSinceEpoch * 1000;
    return (now - updatedAt) < Duration(seconds: 2).inMicroseconds * 1000;
  }

  Future<void> refreshStatus() async {
    if (_stub == null) {
      return;
    }
    try {
      final resp = await _stub!.getStatus(GetStatusRequest());
      snapshot.value = snapshot.value.copyWith(
        status: resp.status,
        connected: true,
        error: null,
      );
    } catch (err) {
      snapshot.value = snapshot.value.copyWith(
        connected: false,
        error: err.toString(),
      );
    }
  }

  Future<CalibrateResponse?> calibrate(String profileId) async {
    if (_stub == null) return null;
    final resp =
        await _stub!.calibrate(CalibrateRequest()..profileId = profileId);
    await refreshStatus();
    return resp;
  }

  Future<void> setProfile(String profileId) async {
    if (_stub == null) return;
    await _stub!.setProfile(SetProfileRequest()..profileId = profileId);
    await refreshStatus();
  }

  Future<CancelCalibrationResponse?> cancelCalibration() async {
    if (_stub == null) return null;
    final resp = await _stub!.cancelCalibration(CancelCalibrationRequest());
    await refreshStatus();
    return resp;
  }

  Future<void> setEStop(bool engaged, {String reason = ''}) async {
    if (_stub == null) return;
    await _stub!.eStop(EStopRequest()
      ..engaged = engaged
      ..reason = reason);
    await refreshStatus();
  }

  Future<void> startSession(String sessionId,
      {String track = '', String car = ''}) async {
    if (_stub == null) return;
    final req = StartSessionRequest()
      ..sessionId = sessionId
      ..track = track
      ..car = car;
    await _stub!.startSession(req);
    await refreshStatus();
  }

  Future<void> endSession(String sessionId) async {
    if (_stub == null) return;
    await _stub!.endSession(EndSessionRequest()..sessionId = sessionId);
    await refreshStatus();
  }

  Future<List<SessionMetadata>> listSessions() async {
    if (_stub == null) return [];
    final resp = await _stub!.listSessions(ListSessionsRequest());
    return resp.sessions;
  }

  Future<bool> deleteSession(String sessionId) async {
    // Delete RPC is not available yet in dashboard proto; caller may still
    // perform local cascading delete and treat this as remote-unsynced.
    if (sessionId.trim().isEmpty) {
      return false;
    }
    return false;
  }

  Future<List<TelemetrySample>> getSessionTelemetry(String sessionId,
      {int maxSamples = 240}) async {
    if (_stub == null) return [];
    final req = GetSessionTelemetryRequest()
      ..sessionId = sessionId
      ..maxSamples = maxSamples;
    final resp = await _stub!.getSessionTelemetry(req);
    return resp.samples;
  }

  void startTelemetryStream({String sessionId = ''}) {
    if (_stub == null) return;
    _telemetrySub?.cancel();
    final stream =
        _stub!.streamTelemetry(TelemetryStreamRequest()..sessionId = sessionId);
    _telemetrySub = stream.listen((sample) {
      snapshot.value = snapshot.value.copyWith(telemetry: sample, error: null);
    }, onError: (err) {
      snapshot.value = snapshot.value.copyWith(error: err.toString());
    });
  }

  void startInputEventStream() {
    if (_stub == null) return;
    _inputEventSub?.cancel();
    final stream = _stub!.streamInputEvents(InputEventStreamRequest());
    _inputEventSub = stream.listen((event) {
      snapshot.value = snapshot.value.copyWith(inputEvent: event, error: null);
    }, onError: (err) {
      snapshot.value = snapshot.value.copyWith(error: err.toString());
    });
  }
}
