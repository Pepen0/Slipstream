import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';

import '../gen/dashboard/v1/dashboard.pbgrpc.dart';

class DashboardSnapshot {
  final Status? status;
  final TelemetrySample? telemetry;
  final bool connected;
  final String? error;

  const DashboardSnapshot({
    this.status,
    this.telemetry,
    this.connected = false,
    this.error,
  });

  DashboardSnapshot copyWith({
    Status? status,
    TelemetrySample? telemetry,
    bool? connected,
    String? error,
  }) {
    return DashboardSnapshot(
      status: status ?? this.status,
      telemetry: telemetry ?? this.telemetry,
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

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => refreshStatus());
    await refreshStatus();
  }

  Future<void> disconnect() async {
    await _telemetrySub?.cancel();
    _telemetrySub = null;
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
    final resp = await _stub!.calibrate(CalibrateRequest()..profileId = profileId);
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

  Future<void> startSession(String sessionId) async {
    if (_stub == null) return;
    await _stub!.startSession(StartSessionRequest()..sessionId = sessionId);
    await refreshStatus();
  }

  Future<void> endSession(String sessionId) async {
    if (_stub == null) return;
    await _stub!.endSession(EndSessionRequest()..sessionId = sessionId);
    await refreshStatus();
  }

  void startTelemetryStream({String sessionId = ''}) {
    if (_stub == null) return;
    _telemetrySub?.cancel();
    final stream = _stub!.streamTelemetry(TelemetryStreamRequest()..sessionId = sessionId);
    _telemetrySub = stream.listen((sample) {
      snapshot.value = snapshot.value.copyWith(telemetry: sample, error: null);
    }, onError: (err) {
      snapshot.value = snapshot.value.copyWith(error: err.toString());
    });
  }
}
