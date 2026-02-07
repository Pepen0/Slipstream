import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'gen/dashboard/v1/dashboard.pb.dart';
import 'session_browser.dart';
import 'services/dashboard_client.dart';

const Color _kBackground = Color(0xFF0A0F14);
const Color _kSurface = Color(0xFF121923);
const Color _kSurfaceRaised = Color(0xFF1A2431);
const Color _kSurfaceGlow = Color(0xFF243344);
const Color _kAccent = Color(0xFF35F4C7);
const Color _kAccentAlt = Color(0xFF44D9FF);
const Color _kWarning = Color(0xFFFFC857);
const Color _kDanger = Color(0xFFFF4D5A);
const Color _kOk = Color(0xFF4CE4A3);
const Color _kMuted = Color(0xFF9FB3C8);

void main() {
  runApp(const DashboardApp());
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  ThemeData _buildTheme() {
    final scheme = const ColorScheme.dark(
      primary: _kAccent,
      secondary: _kAccentAlt,
      surface: _kSurface,
      background: _kBackground,
      error: _kDanger,
    );

    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: _kBackground,
      useMaterial3: true,
      fontFamily: 'SpaceGrotesk',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        displayMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 0.8),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.4),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        bodyLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardTheme(
        color: _kSurface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: _kBackground,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _kSurfaceRaised,
        hintStyle: TextStyle(color: _kMuted.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kSurfaceGlow),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kSurfaceGlow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kAccent, width: 1.2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: _kSurfaceGlow, thickness: 1),
      sliderTheme: const SliderThemeData(
        thumbColor: _kAccent,
        activeTrackColor: _kAccentAlt,
        inactiveTrackColor: _kSurfaceGlow,
      ),
    );

    return base;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slipstream Dashboard',
      theme: _buildTheme(),
      darkTheme: _buildTheme(),
      themeMode: ThemeMode.dark,
      home: const DashboardHome(),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final DashboardClient client = DashboardClient();
  final TextEditingController profileController =
      TextEditingController(text: 'default');
  final TextEditingController sessionController =
      TextEditingController(text: 'session-001');
  final TextEditingController trackController =
      TextEditingController(text: 'Laguna Seca');
  final TextEditingController carController =
      TextEditingController(text: 'GT3');

  bool estopEngaged = false;
  bool profileReady = false;
  bool safetyCentered = false;
  bool safetyClear = false;
  bool safetyEstop = false;
  final List<_CalibrationAttempt> calibrationHistory = [];
  int _lastCalibrationAtNs = 0;

  static const int _reviewMaxSamples = 240;

  final Map<String, List<_SpeedSample>> _sessionHistory = {};
  List<_SpeedSample> _liveHistory = [];
  List<_SpeedSample> _reviewSamples = [];
  List<SessionMetadata> _sessions = [];
  bool _sessionsLoading = false;
  String? _sessionsError;
  String? _selectedSessionId;
  SessionDateFilter _sessionDateFilter = SessionDateFilter.all;
  SessionTypeFilter _sessionTypeFilter = SessionTypeFilter.all;
  String _sessionTrackFilter = kAllTracksFilter;
  String? _activeSessionId;
  bool _lastSessionActive = false;
  bool _reviewMode = false;
  bool _reviewSimulated = false;
  bool _reviewFetching = false;
  String? _reviewNotice;
  SessionMetadata? _reviewSession;
  double _reviewProgress = 1.0;
  DateTime? _lastSampleAt;
  Timer? _sessionsTimer;
  Timer? _dfuTimer;
  bool _dfuActive = false;
  double _dfuProgress = 0.0;

  @override
  void initState() {
    super.initState();
    client.snapshot.addListener(_onSnapshotUpdate);
    client.connect().then((_) {
      client.startTelemetryStream();
      _refreshSessions();
    });
    _sessionsTimer = Timer.periodic(
        const Duration(seconds: 8), (_) => _refreshSessions(silent: true));
  }

  @override
  void dispose() {
    client.snapshot.removeListener(_onSnapshotUpdate);
    client.disconnect();
    profileController.dispose();
    sessionController.dispose();
    trackController.dispose();
    carController.dispose();
    _sessionsTimer?.cancel();
    _dfuTimer?.cancel();
    super.dispose();
  }

  bool get safetyReady => safetyCentered && safetyClear && safetyEstop;

  void _onSnapshotUpdate() {
    final snapshot = client.snapshot.value;
    final status = snapshot.status;
    if (status != null) {
      final lastAt = status.lastCalibrationAtNs.toInt();
      if (lastAt > 0 && lastAt != _lastCalibrationAtNs) {
        _lastCalibrationAtNs = lastAt;
        final success = status.calibrationState ==
            Status_CalibrationState.CALIBRATION_PASSED;
        final message = status.calibrationMessage.isNotEmpty
            ? status.calibrationMessage
            : (success ? 'Calibration complete.' : 'Calibration failed.');
        final timestamp =
            DateTime.fromMillisecondsSinceEpoch(lastAt ~/ 1000000);
        setState(() {
          calibrationHistory.insert(
            0,
            _CalibrationAttempt(
              timestamp: timestamp,
              success: success,
              message: message,
            ),
          );
        });
      }

      _trackSessionTransition(status);
    }

    _appendSpeedSample(snapshot);
  }

  void _trackSessionTransition(Status status) {
    final active = status.sessionActive;
    final sessionId = status.sessionId;
    if (active && sessionId.isNotEmpty) {
      if (_activeSessionId != sessionId) {
        _activeSessionId = sessionId;
        _liveHistory = _sessionHistory.putIfAbsent(sessionId, () => []);
      }
    }
    if (_lastSessionActive && !active) {
      _refreshSessions();
    }
    _lastSessionActive = active;
  }

  void _appendSpeedSample(DashboardSnapshot snapshot) {
    final status = snapshot.status;
    if (!(status?.sessionActive ?? false)) {
      return;
    }
    final sessionId = status?.sessionId ?? '';
    if (sessionId.isEmpty) {
      return;
    }
    final now = DateTime.now();
    if (_lastSampleAt != null &&
        now.difference(_lastSampleAt!) < const Duration(milliseconds: 180)) {
      return;
    }
    _lastSampleAt = now;
    final derived = _deriveTelemetry(snapshot, forceLive: true);
    final sample = _SpeedSample(
      timestamp: now,
      speedKmh: derived.speedKmh,
      trackProgress: derived.trackProgress,
      gear: derived.gear,
      rpm: derived.rpm,
    );
    final list = _sessionHistory.putIfAbsent(sessionId, () => []);
    list.add(sample);
    if (list.length > _reviewMaxSamples) {
      list.removeRange(0, list.length - _reviewMaxSamples);
    }
    if (!_reviewMode) {
      _liveHistory = list;
    }
  }

  Future<void> _refreshSessions({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _sessionsLoading = true;
        _sessionsError = null;
      });
    }
    try {
      final sessions = await client.listSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _sessionsLoading = false;
        _sessionsError = null;
        if (_selectedSessionId != null &&
            !_sessions.any((s) => s.sessionId == _selectedSessionId)) {
          _selectedSessionId = null;
        }
        if (_sessionTrackFilter != kAllTracksFilter &&
            !trackFilterOptions(_sessions).contains(_sessionTrackFilter)) {
          _sessionTrackFilter = kAllTracksFilter;
        }
      });
    } catch (_) {
      if (!mounted) return;
      if (silent && _sessions.isNotEmpty) {
        return;
      }
      setState(() {
        _sessionsLoading = false;
        _sessionsError = 'Unable to fetch sessions.';
      });
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleSetProfile() async {
    final profileId = profileController.text.trim();
    if (profileId.isEmpty) {
      _showSnack('Enter a profile ID before continuing.');
      return;
    }
    await client.setProfile(profileId);
    setState(() {
      profileReady = true;
    });
  }

  Future<void> _startCalibration() async {
    if (!profileReady) {
      _showSnack('Set a profile before starting calibration.');
      return;
    }
    if (!safetyReady) {
      _showSnack('Complete the safety checklist before calibrating.');
      return;
    }
    try {
      final resp = await client.calibrate(profileController.text.trim());
      if (resp?.ok == false) {
        _showSnack(resp?.message ?? 'Calibration failed.');
      }
    } catch (err) {
      _showSnack(err.toString());
    }
  }

  void _cancelCalibration() {
    client.cancelCalibration().then((resp) {
      if (resp?.ok == false) {
        _showSnack(resp?.message ?? 'Unable to cancel calibration.');
      }
    });
  }

  void _enterReview(SessionMetadata session) {
    final fallback = _fallbackReviewSamples(session);
    setState(() {
      _reviewMode = true;
      _reviewSession = session;
      _reviewSimulated = fallback.simulated;
      _reviewSamples = fallback.samples;
      _reviewProgress = 1.0;
      _reviewNotice = 'Fetching session telemetry…';
    });
    _fetchSessionTelemetry(session);
  }

  void _exitReview() {
    setState(() {
      _reviewMode = false;
      _reviewSession = null;
      _reviewSimulated = false;
      _reviewSamples = [];
      _reviewProgress = 1.0;
      _reviewNotice = null;
      _reviewFetching = false;
      if (_activeSessionId != null) {
        _liveHistory = _sessionHistory[_activeSessionId!] ?? _liveHistory;
      }
    });
  }

  _ReviewFallback _fallbackReviewSamples(SessionMetadata session) {
    final stored = _sessionHistory[session.sessionId];
    if (stored != null && stored.isNotEmpty) {
      return _ReviewFallback(samples: List.of(stored), simulated: false);
    }
    return _ReviewFallback(
        samples: _generateSyntheticSamples(session), simulated: true);
  }

  Future<void> _fetchSessionTelemetry(SessionMetadata session) async {
    if (_reviewFetching) return;
    setState(() {
      _reviewFetching = true;
    });
    try {
      final samples = await client.getSessionTelemetry(
        session.sessionId,
        maxSamples: _reviewMaxSamples,
      );
      if (!mounted) return;
      if (samples.isEmpty) {
        setState(() {
          _reviewNotice = 'No session telemetry returned. Using fallback data.';
        });
        return;
      }
      final mapped = _mapTelemetrySamples(samples);
      final hasReal = mapped.any((s) {
        final rpm = s.rpm ?? 0.0;
        final gear = s.gear ?? 0;
        return s.speedKmh > 0 || rpm > 0 || s.trackProgress > 0 || gear != 0;
      });
      if (!hasReal) {
        setState(() {
          _reviewNotice =
              'Session telemetry missing speed/track fields. Using fallback data.';
        });
        return;
      }
      setState(() {
        _reviewSamples = mapped;
        _reviewSimulated = false;
        _reviewNotice = null;
        _reviewProgress = 1.0;
      });
    } catch (_) {
      if (!mounted ||
          !_reviewMode ||
          _reviewSession?.sessionId != session.sessionId) return;
      setState(() {
        _reviewNotice = 'Telemetry fetch failed. Using fallback data.';
      });
    } finally {
      if (!mounted ||
          !_reviewMode ||
          _reviewSession?.sessionId != session.sessionId) return;
      setState(() {
        _reviewFetching = false;
      });
    }
  }

  void _startDfu() {
    if (!client.isConnected) {
      _showSnack('Connect to the MCU before entering DFU mode.');
      return;
    }
    _dfuTimer?.cancel();
    setState(() {
      _dfuActive = true;
      _dfuProgress = 0.04;
    });
    _dfuTimer = Timer.periodic(const Duration(milliseconds: 260), (timer) {
      if (!mounted) return;
      setState(() {
        _dfuProgress += 0.08;
        if (_dfuProgress >= 1.0) {
          _dfuProgress = 1.0;
          _dfuActive = false;
          timer.cancel();
        }
      });
    });
  }

  void _cancelDfu() {
    _dfuTimer?.cancel();
    setState(() {
      _dfuActive = false;
      _dfuProgress = 0.0;
    });
  }

  _DerivedTelemetry _deriveTelemetry(DashboardSnapshot snapshot,
      {bool forceLive = false}) {
    if (!forceLive && _reviewMode && _reviewSamples.isNotEmpty) {
      final idx = (_reviewProgress * (_reviewSamples.length - 1))
          .round()
          .clamp(0, _reviewSamples.length - 1);
      final sample = _reviewSamples[idx];
      final gear = sample.gear ?? _gearForSpeed(sample.speedKmh, active: true);
      final rpm = sample.rpm ?? _rpmForSpeed(sample.speedKmh, gear);
      return _DerivedTelemetry(
        speedKmh: sample.speedKmh,
        gear: gear,
        rpm: rpm,
        latencyMs: snapshot.telemetry?.latencyMs ?? 0,
        trackProgress: sample.trackProgress,
      );
    }

    final real = _deriveFromRealTelemetry(snapshot);
    if (real != null) {
      return real;
    }

    return _deriveSyntheticTelemetry(snapshot);
  }

  _DerivedTelemetry? _deriveFromRealTelemetry(DashboardSnapshot snapshot) {
    final telemetry = snapshot.telemetry;
    if (telemetry == null) {
      return null;
    }
    final speed = telemetry.speedKmh;
    final rpm = telemetry.engineRpm;
    final trackProgress = telemetry.trackProgress;
    final gearRaw = telemetry.gear;
    final hasReal = speed > 0 || rpm > 0 || trackProgress > 0 || gearRaw != 0;
    if (!hasReal) {
      return null;
    }
    final active = snapshot.status?.sessionActive ?? false;
    final gear = gearRaw != 0
        ? gearRaw
        : (speed > 1 ? _gearForSpeed(speed, active: active) : 0);
    final derivedRpm = rpm > 0 ? rpm : _rpmForSpeed(speed, gear);
    return _DerivedTelemetry(
      speedKmh: speed,
      gear: gear,
      rpm: derivedRpm,
      latencyMs: telemetry.latencyMs,
      trackProgress: trackProgress,
    );
  }

  _DerivedTelemetry _deriveSyntheticTelemetry(DashboardSnapshot snapshot) {
    final status = snapshot.status;
    final telemetry = snapshot.telemetry;
    final nowNs = telemetry?.timestampNs.toInt() ??
        DateTime.now().microsecondsSinceEpoch * 1000;
    final seconds = nowNs / 1e9;
    final base = telemetry == null
        ? 0.0
        : (telemetry.leftTargetM.abs() + telemetry.rightTargetM.abs()) * 55.0;
    final wave = (sin(seconds * 1.6) + 1.0) * 8.0;
    double speed = (base + wave).clamp(0.0, 320.0);
    if (!(status?.sessionActive ?? false)) {
      speed *= 0.2;
    }
    final gear = _gearForSpeed(speed, active: status?.sessionActive ?? false);
    final rpm = _rpmForSpeed(speed, gear);
    final progress = (seconds / 82.0) % 1.0;
    return _DerivedTelemetry(
      speedKmh: speed,
      gear: gear,
      rpm: rpm,
      latencyMs: telemetry?.latencyMs ?? 0,
      trackProgress: progress,
    );
  }

  List<_SpeedSample> _mapTelemetrySamples(List<TelemetrySample> samples) {
    return samples.map((sample) {
      final timestampNs = sample.timestampNs.toInt();
      final timestamp = timestampNs > 0
          ? DateTime.fromMillisecondsSinceEpoch(timestampNs ~/ 1000000)
          : DateTime.now();
      return _SpeedSample(
        timestamp: timestamp,
        speedKmh: sample.speedKmh,
        trackProgress: sample.trackProgress,
        gear: sample.gear,
        rpm: sample.engineRpm,
      );
    }).toList();
  }

  List<_SpeedSample> _generateSyntheticSamples(SessionMetadata session) {
    final durationMs =
        session.durationMs.toInt() > 0 ? session.durationMs.toInt() : 90000;
    final totalSamples = 160;
    final step = durationMs / totalSamples;
    final start =
        DateTime.now().subtract(Duration(milliseconds: durationMs.toInt()));
    return List.generate(totalSamples, (index) {
      final t = index / totalSamples;
      final speed = 80 + 60 * sin(t * pi * 2) + 30 * sin(t * pi * 6);
      final progress = (t * 1.2) % 1.0;
      final gear = _gearForSpeed(speed, active: true);
      final rpm = _rpmForSpeed(speed, gear);
      return _SpeedSample(
        timestamp: start.add(Duration(milliseconds: (step * index).toInt())),
        speedKmh: speed.clamp(10, 220),
        trackProgress: progress,
        gear: gear,
        rpm: rpm,
      );
    });
  }

  int _gearForSpeed(double speed, {required bool active}) {
    if (!active) return 0;
    if (speed < 8) return 1;
    if (speed < 32) return 2;
    if (speed < 70) return 3;
    if (speed < 110) return 4;
    if (speed < 160) return 5;
    return 6;
  }

  double _rpmForSpeed(double speed, int gear) {
    if (gear == 0) return 900;
    final ratio = (speed / 220).clamp(0.0, 1.0);
    final gearFactor = 1.2 - (gear - 1) * 0.12;
    return (1000 + ratio * 7000 * gearFactor).clamp(900, 9200);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Slipstream Dashboard'),
          actions: [
            ValueListenableBuilder<DashboardSnapshot>(
              valueListenable: client.snapshot,
              builder: (context, snapshot, _) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _ConnectionPill(snapshot: snapshot),
                );
              },
            ),
            IconButton(
              onPressed: () async {
                await client.refreshStatus();
                await _refreshSessions();
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Live Dashboard'),
              Tab(text: 'System Status'),
            ],
          ),
        ),
        floatingActionButton: ValueListenableBuilder<DashboardSnapshot>(
          valueListenable: client.snapshot,
          builder: (context, snapshot, _) => _buildEStopFab(snapshot),
        ),
        body: ValueListenableBuilder<DashboardSnapshot>(
          valueListenable: client.snapshot,
          builder: (context, snapshot, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1100;
                return TabBarView(
                  children: [
                    _buildLiveDashboard(snapshot, isWide),
                    _buildSystemStatus(snapshot, isWide),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiveDashboard(DashboardSnapshot snapshot, bool isWide) {
    final derived = _deriveTelemetry(snapshot);
    final samples = _reviewMode ? _reviewSamples : _liveHistory;
    final sessionActive = snapshot.status?.sessionActive ?? false;
    final sessionId = snapshot.status?.sessionId ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewBanner(sessionActive, sessionId),
          const SizedBox(height: 16),
          _buildOverviewStrip(snapshot, derived),
          const SizedBox(height: 16),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTelemetryHud(derived)),
                const SizedBox(width: 16),
                Expanded(child: _buildTrackMap(derived)),
              ],
            )
          else
            Column(
              children: [
                _buildTelemetryHud(derived),
                const SizedBox(height: 16),
                _buildTrackMap(derived),
              ],
            ),
          const SizedBox(height: 16),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSpeedGraph(samples, derived)),
                const SizedBox(width: 16),
                Expanded(child: _buildSessionList(snapshot)),
              ],
            )
          else
            Column(
              children: [
                _buildSpeedGraph(samples, derived),
                const SizedBox(height: 16),
                _buildSessionList(snapshot),
              ],
            ),
          const SizedBox(height: 16),
          _buildSessionControl(snapshot),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(DashboardSnapshot snapshot, bool isWide) {
    final faults = _buildFaults(snapshot);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemHeader(snapshot),
          const SizedBox(height: 16),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSystemStatusCard(snapshot)),
                const SizedBox(width: 16),
                Expanded(child: _buildFaultPanel(faults)),
              ],
            )
          else
            Column(
              children: [
                _buildSystemStatusCard(snapshot),
                const SizedBox(height: 16),
                _buildFaultPanel(faults),
              ],
            ),
          const SizedBox(height: 16),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSafetyZones(snapshot)),
                const SizedBox(width: 16),
                Expanded(child: _buildFirmwareManager(snapshot)),
              ],
            )
          else
            Column(
              children: [
                _buildSafetyZones(snapshot),
                const SizedBox(height: 16),
                _buildFirmwareManager(snapshot),
              ],
            ),
          const SizedBox(height: 16),
          _buildCalibrationConsole(snapshot),
        ],
      ),
    );
  }

  Widget _buildOverviewStrip(
      DashboardSnapshot snapshot, _DerivedTelemetry derived) {
    final status = snapshot.status;
    final activeProfile = status?.activeProfile.isNotEmpty == true
        ? status!.activeProfile
        : profileController.text.trim();
    final latency = derived.latencyMs.toStringAsFixed(1);
    final connected = client.isConnected && snapshot.connected;

    return _HudCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _StatusPill(
                label: 'USB LINK',
                value: connected ? 'ONLINE' : 'OFFLINE',
                color: connected ? _kOk : _kDanger,
              ),
              _StatusPill(
                label: 'PROFILE',
                value: activeProfile.isEmpty ? 'UNSET' : activeProfile,
                color: activeProfile.isEmpty ? _kWarning : _kAccent,
              ),
              _StatusPill(
                label: 'LATENCY',
                value: '${latency}ms',
                color: derived.latencyMs > 20 ? _kWarning : _kAccentAlt,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _reviewMode ? 'REVIEW MODE' : 'LIVE FEED',
              style: TextStyle(
                color: _reviewMode ? _kWarning : _kAccent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBanner(bool sessionActive, String sessionId) {
    if (!_reviewMode) {
      return _HudCard(
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.hub, color: _kAccentAlt),
            Text(
              sessionActive
                  ? 'Session $sessionId live telemetry streaming.'
                  : 'Session idle. Select a run to review.',
              style: const TextStyle(color: _kMuted),
            ),
            if (!sessionActive)
              Text(
                'POST-SESSION REVIEW READY',
                style: TextStyle(
                    color: _kAccent.withOpacity(0.8),
                    fontWeight: FontWeight.w600),
              ),
          ],
        ),
      );
    }

    return _HudCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill, color: _kWarning),
              Text(
                _reviewSession == null
                    ? 'Reviewing latest session capture.'
                    : 'Reviewing ${_reviewSession!.sessionId}',
                style: const TextStyle(color: Colors.white),
              ),
              if (_reviewSimulated)
                Text(
                  'SIMULATED REPLAY',
                  style: TextStyle(
                      color: _kWarning.withOpacity(0.9),
                      fontWeight: FontWeight.w700),
                ),
              FilledButton(
                onPressed: _exitReview,
                child: const Text('Exit Review'),
              ),
            ],
          ),
          if (_reviewNotice != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _reviewFetching ? Icons.hourglass_top : Icons.info_outline,
                  color: _reviewFetching ? _kAccentAlt : _kWarning,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _reviewNotice!,
                    style: const TextStyle(color: _kMuted),
                  ),
                ),
                TextButton(
                  onPressed: _reviewFetching || _reviewSession == null
                      ? null
                      : () => _fetchSessionTelemetry(_reviewSession!),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryHud(_DerivedTelemetry derived) {
    return _HudCard(
      key: const Key('telemetry-hud'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Telemetry HUD', subtitle: 'FLT-012 · Speed, Gear, RPM'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HudMetric(
                  label: 'SPEED',
                  value: derived.speedKmh.toStringAsFixed(0),
                  unit: 'km/h',
                  glow: _kAccentAlt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HudMetric(
                  label: 'GEAR',
                  value: derived.gear == 0 ? 'N' : derived.gear.toString(),
                  unit: '',
                  glow: _kAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HudMetric(
                  label: 'RPM',
                  value: derived.rpm.toStringAsFixed(0),
                  unit: 'rpm',
                  glow: _kWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                  label: 'Track Progress',
                  value:
                      '${(derived.trackProgress * 100).toStringAsFixed(1)}%'),
              const SizedBox(width: 16),
              _MiniStat(
                  label: 'Stream', value: _reviewMode ? 'Playback' : 'Live'),
              const SizedBox(width: 16),
              _MiniStat(
                  label: 'Latency',
                  value: '${derived.latencyMs.toStringAsFixed(1)}ms'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackMap(_DerivedTelemetry derived) {
    return _HudCard(
      key: const Key('track-map'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Track Map',
              subtitle: 'FLT-013 · Driver position overlay'),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.4,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: derived.trackProgress),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CustomPaint(
                  painter: _TrackMapPainter(
                    progress: value,
                    trackColor: _kSurfaceGlow,
                    dotColor: _reviewMode ? _kWarning : _kAccentAlt,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _reviewMode
                ? 'Review scrub active'
                : 'Live position smoothing enabled',
            style: const TextStyle(color: _kMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedGraph(
      List<_SpeedSample> samples, _DerivedTelemetry derived) {
    return _HudCard(
      key: const Key('speed-graph'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Speed vs Time',
              subtitle: 'FLT-016 · Session velocity trend'),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _SpeedGraphPainter(
                samples: samples,
                lineColor: _reviewMode ? _kWarning : _kAccentAlt,
                accentColor: _kSurfaceGlow,
                cursorPercent: _reviewMode ? _reviewProgress : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_reviewMode && _reviewSamples.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scrub Timeline',
                    style: Theme.of(context).textTheme.titleMedium),
                Slider(
                  value: _reviewProgress,
                  onChanged: (value) {
                    setState(() {
                      _reviewProgress = value;
                    });
                  },
                ),
              ],
            )
          else
            Text(
              'Peak ${_maxSpeed(samples).toStringAsFixed(0)} km/h · Current ${derived.speedKmh.toStringAsFixed(0)} km/h',
              style: const TextStyle(color: _kMuted),
            ),
        ],
      ),
    );
  }

  double _maxSpeed(List<_SpeedSample> samples) {
    if (samples.isEmpty) return 0;
    return samples.map((e) => e.speedKmh).reduce(max);
  }

  List<SessionMetadata> _filteredSessions() {
    return applySessionFilters(
      _sessions,
      SessionBrowserFilters(
        date: _sessionDateFilter,
        track: _sessionTrackFilter,
        type: _sessionTypeFilter,
      ),
    );
  }

  SessionMetadata? _selectedSessionFrom(List<SessionMetadata> sessions) {
    final selectedId = _selectedSessionId;
    if (selectedId == null) {
      return null;
    }
    for (final session in sessions) {
      if (session.sessionId == selectedId) {
        return session;
      }
    }
    return null;
  }

  String _dateFilterLabel(SessionDateFilter filter) {
    switch (filter) {
      case SessionDateFilter.all:
        return 'All dates';
      case SessionDateFilter.today:
        return 'Today';
      case SessionDateFilter.last7Days:
        return 'Last 7 days';
      case SessionDateFilter.last30Days:
        return 'Last 30 days';
    }
  }

  Widget _buildSessionList(DashboardSnapshot snapshot) {
    final sessionActive = snapshot.status?.sessionActive ?? false;
    final activeId = snapshot.status?.sessionId ?? '';
    final connected = client.isConnected && snapshot.connected;
    final filtered = _filteredSessions();
    final visibleSelected = _selectedSessionFrom(filtered);
    final selectedSession = visibleSelected ?? _selectedSessionFrom(_sessions);
    final tracks = trackFilterOptions(_sessions);
    final syncedCount = filtered
        .where((session) =>
            inferCloudSyncState(session, connected: connected) ==
            CloudSyncState.synced)
        .length;

    Widget body;
    if (_sessionsLoading && _sessions.isEmpty) {
      body = _SessionBrowserState(
        key: const Key('session-loading-state'),
        icon: Icons.hourglass_top_rounded,
        message: 'Loading session history…',
      );
    } else if (_sessionsError != null && _sessions.isEmpty) {
      body = _SessionBrowserState(
        key: const Key('session-error-state'),
        icon: Icons.cloud_off_rounded,
        message: _sessionsError!,
        actionLabel: 'Retry',
        onAction: () => _refreshSessions(),
      );
    } else if (filtered.isEmpty) {
      body = _SessionBrowserState(
        key: const Key('session-empty-state'),
        icon: _sessions.isEmpty
            ? Icons.route_rounded
            : Icons.filter_alt_off_rounded,
        message: _sessions.isEmpty
            ? 'No sessions recorded yet.'
            : 'No sessions match the active filters.',
      );
    } else {
      final rows = filtered.map((session) {
        final isActive = session.sessionId == activeId && sessionActive;
        final isSelected = _selectedSessionId == session.sessionId;
        final type = classifySessionType(session);
        final startedAt = sessionTimestamp(session);
        final startedLabel =
            startedAt == null ? '--' : _formatTimestamp(startedAt);
        final syncState = inferCloudSyncState(session, connected: connected);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: _SessionRow(
            session: session,
            active: isActive,
            selected: isSelected,
            syncState: syncState,
            typeLabel: sessionTypeLabel(type),
            startedAtLabel: startedLabel,
            onSelect: () {
              setState(() {
                _selectedSessionId = session.sessionId;
              });
            },
            onReview: () {
              setState(() {
                _selectedSessionId = session.sessionId;
              });
              _enterReview(session);
            },
          ),
        );
      }).toList();

      body = filtered.length > 5
          ? SizedBox(
              height: 360,
              child: ListView(
                children: rows,
              ),
            )
          : Column(children: rows);
    }

    return _HudCard(
      key: const Key('session-list'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionHeader(
                  title: 'Session Browser',
                  subtitle: 'FLT-015 · Data access and replay selection',
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: selectedSession == null
                    ? null
                    : () => _enterReview(selectedSession),
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Review Selected'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _refreshSessions,
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${filtered.length} shown · ${_sessions.length} total',
                style: const TextStyle(color: _kMuted, fontSize: 12),
              ),
              const SizedBox(width: 10),
              Text(
                '$syncedCount cloud synced',
                style: TextStyle(
                    color: _kAccentAlt.withOpacity(0.85), fontSize: 12),
              ),
              const Spacer(),
              if (_sessionsLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<SessionDateFilter>(
                  key: const Key('session-filter-date'),
                  isExpanded: true,
                  value: _sessionDateFilter,
                  items: SessionDateFilter.values
                      .map((filter) => DropdownMenuItem(
                            value: filter,
                            child: Text(_dateFilterLabel(filter)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _sessionDateFilter = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  key: const Key('session-filter-track'),
                  isExpanded: true,
                  value: tracks.contains(_sessionTrackFilter)
                      ? _sessionTrackFilter
                      : kAllTracksFilter,
                  items: tracks
                      .map((track) => DropdownMenuItem(
                            value: track,
                            child: Text(track == kAllTracksFilter
                                ? 'All tracks'
                                : track),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _sessionTrackFilter = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Track',
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<SessionTypeFilter>(
                  key: const Key('session-filter-type'),
                  isExpanded: true,
                  value: _sessionTypeFilter,
                  items: SessionTypeFilter.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(sessionTypeLabel(type)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _sessionTypeFilter = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: body,
          ),
          if (visibleSelected != null) ...[
            const SizedBox(height: 10),
            Text(
              'Selected: ${visibleSelected.sessionId}',
              key: const Key('session-selected-label'),
              style: TextStyle(
                  color: _kAccent.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionControl(DashboardSnapshot snapshot) {
    final sessionActive = snapshot.status?.sessionActive ?? false;

    return _HudCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Session Control',
              subtitle: 'FLT-017 · Run control & post-session review'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: sessionController,
                  decoration: const InputDecoration(labelText: 'Session ID'),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: trackController,
                  decoration: const InputDecoration(labelText: 'Track'),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: carController,
                  decoration: const InputDecoration(labelText: 'Car'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: sessionActive
                    ? null
                    : () async {
                        await client.startSession(
                          sessionController.text.trim(),
                          track: trackController.text.trim(),
                          car: carController.text.trim(),
                        );
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Session'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: sessionActive
                    ? () async {
                        await client.endSession(sessionController.text.trim());
                      }
                    : null,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('End Session'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _reviewMode
                      ? Text(
                          "Reviewing ${_reviewSession?.sessionId ?? 'Session'}",
                          style: const TextStyle(color: _kWarning),
                          textAlign: TextAlign.right,
                        )
                      : sessionActive
                          ? Text(
                              "Live: ${snapshot.status?.sessionId ?? 'Session'}",
                              style: const TextStyle(color: _kAccent),
                              textAlign: TextAlign.right,
                            )
                          : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHeader(DashboardSnapshot snapshot) {
    return _HudCard(
      child: Row(
        children: [
          const Icon(Icons.security, color: _kAccentAlt),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('System Status & Safety',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (snapshot.status?.state == Status_State.STATE_FAULT)
            Text(
              'FAULT ACTIVE',
              style: TextStyle(
                  color: _kDanger.withOpacity(0.9),
                  fontWeight: FontWeight.w700),
            )
          else
            Text(
              'SYSTEM NOMINAL',
              style: TextStyle(
                  color: _kOk.withOpacity(0.9), fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard(DashboardSnapshot snapshot) {
    final status = snapshot.status;
    final state = status?.state.name.replaceAll('STATE_', '') ?? 'UNKNOWN';
    final connected = client.isConnected && snapshot.connected;
    final updatedAt = status?.updatedAtNs.toInt() ?? 0;
    final updatedText = updatedAt == 0
        ? '--'
        : _formatTimestamp(
            DateTime.fromMillisecondsSinceEpoch(updatedAt ~/ 1000000));

    return _HudCard(
      key: const Key('system-status'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'System Status',
              subtitle: 'FLT-019 · MCU state, faults, USB'),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusTile(
                label: 'MCU State',
                value: state,
                color: status?.state == Status_State.STATE_FAULT
                    ? _kDanger
                    : _kAccent,
              ),
              const SizedBox(width: 12),
              _StatusTile(
                label: 'USB Link',
                value: connected ? 'Online' : 'Offline',
                color: connected ? _kOk : _kDanger,
              ),
              const SizedBox(width: 12),
              _StatusTile(
                label: 'Session',
                value: status?.sessionActive == true ? 'Active' : 'Idle',
                color: status?.sessionActive == true ? _kAccentAlt : _kMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Last update: $updatedText',
              style: const TextStyle(color: _kMuted)),
        ],
      ),
    );
  }

  Widget _buildFaultPanel(List<_Fault> faults) {
    return _HudCard(
      key: const Key('fault-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Faults & Recovery',
              subtitle: 'FLT-020 · Actionable recovery steps'),
          const SizedBox(height: 12),
          if (faults.isEmpty)
            const Text('No active faults detected.',
                style: TextStyle(color: _kOk))
          else
            Column(
              children: faults.map((fault) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FaultCard(fault: fault),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  List<_Fault> _buildFaults(DashboardSnapshot snapshot) {
    final status = snapshot.status;
    final faults = <_Fault>[];

    if (snapshot.error != null) {
      faults.add(
        _Fault(
          title: 'Dashboard Link Down',
          detail: snapshot.error!,
          color: _kDanger,
          steps: const [
            'Verify USB tether and power to the MCU.',
            'Restart the dashboard client and reconnect.',
          ],
        ),
      );
    }

    if (status?.state == Status_State.STATE_FAULT) {
      faults.add(
        _Fault(
          title: 'MCU Fault State',
          detail: status?.lastError.isNotEmpty == true
              ? status!.lastError
              : 'Fault flag asserted.',
          color: _kDanger,
          steps: const [
            'Ensure the vehicle is safe and stationary.',
            'Release E-Stop only when safe.',
            'Re-run calibration after clearing the fault.',
          ],
        ),
      );
    }

    if (status?.estopActive == true) {
      faults.add(
        _Fault(
          title: 'E-Stop Engaged',
          detail: 'Emergency stop circuit is active.',
          color: _kWarning,
          steps: const [
            'Confirm the track is clear.',
            'Twist and release the E-Stop switch.',
          ],
        ),
      );
    }

    if ((snapshot.telemetry?.latencyMs ?? 0) > 25) {
      faults.add(
        _Fault(
          title: 'Telemetry Lag',
          detail: 'Latency exceeded 25 ms.',
          color: _kWarning,
          steps: const [
            'Check cable routing for interference.',
            'Reduce non-essential network traffic.',
          ],
        ),
      );
    }

    return faults;
  }

  Widget _buildSafetyZones(DashboardSnapshot snapshot) {
    final estopActive = snapshot.status?.estopActive ?? estopEngaged;

    return _HudCard(
      key: const Key('safety-zones'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Safety Zones',
              subtitle: 'FLT-021 · Visual safety coverage'),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _SafetyZonePainter(
                operatorClear: safetyCentered,
                trackClear: safetyClear,
                estopReady: safetyEstop && !estopActive,
              ),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: safetyCentered,
            onChanged: (value) {
              setState(() {
                safetyCentered = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('Operator zone clear'),
          ),
          CheckboxListTile(
            value: safetyClear,
            onChanged: (value) {
              setState(() {
                safetyClear = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('Track perimeter clear'),
          ),
          CheckboxListTile(
            value: safetyEstop,
            onChanged: (value) {
              setState(() {
                safetyEstop = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('E-Stop accessible'),
          ),
        ],
      ),
    );
  }

  Widget _buildFirmwareManager(DashboardSnapshot snapshot) {
    final connected = client.isConnected && snapshot.connected;
    final firmwareStatus = _dfuActive ? 'DFU ACTIVE' : 'Ready';

    return _HudCard(
      key: const Key('firmware-manager'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Firmware Manager', subtitle: 'FLT-023 · DFU operations'),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusTile(
                label: 'MCU Firmware',
                value: 'v1.3.2',
                color: _kAccentAlt,
              ),
              const SizedBox(width: 12),
              _StatusTile(
                label: 'DFU Mode',
                value: firmwareStatus,
                color: _dfuActive ? _kWarning : _kOk,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _dfuActive ? _dfuProgress : 0.0,
            minHeight: 6,
            backgroundColor: _kSurfaceGlow,
            valueColor:
                AlwaysStoppedAnimation(_dfuActive ? _kWarning : _kAccentAlt),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: connected && !_dfuActive ? _startDfu : null,
                icon: const Icon(Icons.usb_rounded),
                label: const Text('Enter DFU'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _dfuActive ? _cancelDfu : null,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
              ),
              const Spacer(),
              Text(
                connected ? 'USB connected' : 'USB offline',
                style: TextStyle(color: connected ? _kOk : _kDanger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationConsole(DashboardSnapshot snapshot) {
    final status = snapshot.status;
    final calibrationState =
        status?.calibrationState ?? Status_CalibrationState.CALIBRATION_UNKNOWN;
    final calibrationProgress =
        (status?.calibrationProgress ?? 0.0).clamp(0.0, 1.0);
    final calibrationMessage =
        status?.calibrationMessage ?? 'Awaiting calibration.';
    final attempts = status?.calibrationAttempts ?? calibrationHistory.length;

    return _HudCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Calibration Console',
              subtitle: 'Profile + sensor zeroing'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: profileController,
                  decoration: const InputDecoration(labelText: 'Profile ID'),
                ),
              ),
              FilledButton(
                onPressed: _handleSetProfile,
                child: const Text('Set Profile'),
              ),
              if (profileReady)
                Chip(
                  label: Text(
                      'Active: ${status?.activeProfile ?? profileController.text.trim()}'),
                  backgroundColor: _kSurfaceGlow,
                ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: calibrationProgress,
            minHeight: 6,
            backgroundColor: _kSurfaceGlow,
            valueColor: AlwaysStoppedAnimation(
              calibrationState == Status_CalibrationState.CALIBRATION_FAILED
                  ? _kDanger
                  : _kAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(calibrationMessage, style: const TextStyle(color: _kMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _startCalibration,
                icon: const Icon(Icons.tune),
                label: const Text('Start Calibration'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _cancelCalibration,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
              ),
              const Spacer(),
              Text('Attempts: $attempts',
                  style: const TextStyle(color: _kMuted)),
            ],
          ),
          if (calibrationHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Recent Events',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Column(
              children: calibrationHistory.take(3).map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        entry.success
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: entry.success ? _kOk : _kWarning,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              '${_formatTimestamp(entry.timestamp)} — ${entry.message}')),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEStopFab(DashboardSnapshot snapshot) {
    final engaged = snapshot.status?.estopActive ?? estopEngaged;
    final color = engaged ? _kDanger : _kWarning;

    return FloatingActionButton.extended(
      key: const Key('estop-control'),
      onPressed: () async {
        final next = !engaged;
        setState(() {
          estopEngaged = next;
        });
        await client.setEStop(next, reason: next ? 'UI' : 'UI clear');
      },
      backgroundColor: color,
      icon: const Icon(Icons.warning_amber_rounded),
      label: Text(engaged ? 'E-STOP ENGAGED' : 'E-STOP READY'),
    );
  }
}

class _HudCard extends StatelessWidget {
  const _HudCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kSurface, _kSurfaceRaised],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kSurfaceGlow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: _kMuted, fontSize: 12)),
      ],
    );
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric(
      {required this.label,
      required this.value,
      required this.unit,
      required this.glow});

  final String label;
  final String value;
  final String unit;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurfaceGlow.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glow.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: _kMuted, fontSize: 11, letterSpacing: 1.4)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.w700, color: glow),
          ),
          if (unit.isNotEmpty)
            Text(unit,
                style: const TextStyle(
                    color: _kMuted, fontSize: 11, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kSurfaceGlow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kSurfaceGlow.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SessionBrowserState extends StatelessWidget {
  const _SessionBrowserState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: _kSurfaceGlow.withOpacity(0.24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kSurfaceGlow),
      ),
      child: Column(
        children: [
          Icon(icon, color: _kMuted),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kMuted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _CloudSyncBadge extends StatelessWidget {
  const _CloudSyncBadge({
    super.key,
    required this.state,
  });

  final CloudSyncState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      CloudSyncState.synced => _kOk,
      CloudSyncState.syncing => _kAccentAlt,
      CloudSyncState.pending => _kWarning,
      CloudSyncState.offline => _kMuted,
    };
    final icon = switch (state) {
      CloudSyncState.synced => Icons.cloud_done_rounded,
      CloudSyncState.syncing => Icons.cloud_sync_rounded,
      CloudSyncState.pending => Icons.cloud_upload_rounded,
      CloudSyncState.offline => Icons.cloud_off_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _kSurfaceGlow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            cloudSyncLabel(state),
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.active,
    required this.selected,
    required this.syncState,
    required this.typeLabel,
    required this.startedAtLabel,
    required this.onSelect,
    required this.onReview,
  });

  final SessionMetadata session;
  final bool active;
  final bool selected;
  final CloudSyncState syncState;
  final String typeLabel;
  final String startedAtLabel;
  final VoidCallback onSelect;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final duration = session.durationMs > 0
        ? Duration(milliseconds: session.durationMs.toInt())
        : null;
    final durationLabel = duration == null ? '--' : _formatDuration(duration);
    final accent = selected ? _kAccent : (active ? _kAccentAlt : _kSurfaceGlow);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _kSurfaceGlow.withOpacity(0.75)
                : (active
                    ? _kSurfaceGlow.withOpacity(0.55)
                    : _kSurfaceGlow.withOpacity(0.28)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.sessionId.isEmpty ? 'Session' : session.sessionId,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track: ${trackLabelForSession(session)} · $typeLabel',
                      style: const TextStyle(color: _kMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Started: $startedAtLabel',
                      style: const TextStyle(color: _kMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(durationLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    active ? 'LIVE' : (selected ? 'SELECTED' : 'COMPLETE'),
                    style: TextStyle(
                        color: active
                            ? _kAccent
                            : (selected ? _kAccentAlt : _kMuted),
                        fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  _CloudSyncBadge(
                    key: Key('session-cloud-${session.sessionId}'),
                    state: syncState,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onReview,
                child: const Text('Open'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaultCard extends StatelessWidget {
  const _FaultCard({required this.fault});

  final _Fault fault;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurfaceGlow.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fault.color.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fault.title,
              style:
                  TextStyle(color: fault.color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(fault.detail, style: const TextStyle(color: _kMuted)),
          const SizedBox(height: 8),
          for (final step in fault.steps)
            Text('• $step',
                style: const TextStyle(color: _kMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final connected = snapshot.connected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kSurfaceGlow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: connected ? _kOk : _kDanger),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.check_circle : Icons.error_outline,
            color: connected ? _kOk : _kDanger,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'Connected' : 'Disconnected',
            style: TextStyle(
                color: connected ? _kOk : _kDanger,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TrackMapPainter extends CustomPainter {
  _TrackMapPainter(
      {required this.progress,
      required this.trackColor,
      required this.dotColor});

  final double progress;
  final Color trackColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = 16.0;
    final rect = Rect.fromLTWH(
        inset, inset, size.width - inset * 2, size.height - inset * 2);

    final path = Path()
      ..moveTo(rect.left + rect.width * 0.1, rect.top + rect.height * 0.2)
      ..quadraticBezierTo(rect.left + rect.width * 0.5, rect.top,
          rect.right - rect.width * 0.1, rect.top + rect.height * 0.2)
      ..lineTo(rect.right, rect.center.dy - rect.height * 0.1)
      ..quadraticBezierTo(
          rect.right + rect.width * 0.05,
          rect.center.dy + rect.height * 0.15,
          rect.right - rect.width * 0.05,
          rect.bottom - rect.height * 0.2)
      ..lineTo(rect.center.dx + rect.width * 0.1, rect.bottom)
      ..quadraticBezierTo(
          rect.center.dx - rect.width * 0.25,
          rect.bottom - rect.height * 0.1,
          rect.left + rect.width * 0.1,
          rect.bottom - rect.height * 0.25)
      ..lineTo(rect.left, rect.center.dy + rect.height * 0.05)
      ..quadraticBezierTo(
          rect.left - rect.width * 0.05,
          rect.center.dy - rect.height * 0.2,
          rect.left + rect.width * 0.05,
          rect.top + rect.height * 0.3)
      ..close();

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = trackColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, trackPaint);

    final metric =
        path.computeMetrics().isEmpty ? null : path.computeMetrics().first;
    if (metric != null) {
      final distance = metric.length * progress.clamp(0.0, 1.0);
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        final dotPaint = Paint()..color = dotColor;
        canvas.drawCircle(
            tangent.position, 6.5, Paint()..color = dotColor.withOpacity(0.3));
        canvas.drawCircle(tangent.position, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrackMapPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.dotColor != dotColor;
  }
}

class _SpeedGraphPainter extends CustomPainter {
  _SpeedGraphPainter(
      {required this.samples,
      required this.lineColor,
      required this.accentColor,
      this.cursorPercent});

  final List<_SpeedSample> samples;
  final Color lineColor;
  final Color accentColor;
  final double? cursorPercent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paintGrid = Paint()
      ..color = accentColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 1; i < 4; i++) {
      final dy = rect.top + rect.height * (i / 4);
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), paintGrid);
    }

    if (samples.isEmpty) {
      final textPainter = TextPainter(
        text: const TextSpan(
            text: 'Awaiting telemetry', style: TextStyle(color: _kMuted)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width);
      textPainter.paint(
          canvas,
          Offset(rect.center.dx - textPainter.width / 2,
              rect.center.dy - textPainter.height / 2));
      return;
    }

    final maxSpeed =
        samples.map((e) => e.speedKmh).reduce(max).clamp(1, 260).toDouble();
    final path = Path();
    final denom = samples.length > 1 ? (samples.length - 1) : 1;
    for (var i = 0; i < samples.length; i++) {
      final t = i / denom;
      final speed = samples[i].speedKmh;
      final dx = rect.left + rect.width * t;
      final dy = rect.bottom - (speed / maxSpeed) * rect.height;
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    if (cursorPercent != null) {
      final cx = rect.left + rect.width * cursorPercent!.clamp(0.0, 1.0);
      canvas.drawLine(
          Offset(cx, rect.top),
          Offset(cx, rect.bottom),
          Paint()
            ..color = lineColor.withOpacity(0.6)
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedGraphPainter oldDelegate) {
    return true;
  }
}

class _SafetyZonePainter extends CustomPainter {
  _SafetyZonePainter(
      {required this.operatorClear,
      required this.trackClear,
      required this.estopReady});

  final bool operatorClear;
  final bool trackClear;
  final bool estopReady;

  @override
  void paint(Canvas canvas, Size size) {
    final zonePaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _kSurfaceGlow;

    final operatorRect =
        Rect.fromLTWH(0, 0, size.width * 0.45, size.height * 0.45);
    final trackRect = Rect.fromLTWH(
        size.width * 0.55, 0, size.width * 0.45, size.height * 0.65);
    final estopRect = Rect.fromLTWH(
        0, size.height * 0.55, size.width * 0.6, size.height * 0.4);

    zonePaint.color =
        operatorClear ? _kOk.withOpacity(0.4) : _kWarning.withOpacity(0.4);
    canvas.drawRRect(
        RRect.fromRectAndRadius(operatorRect, const Radius.circular(12)),
        zonePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(operatorRect, const Radius.circular(12)),
        borderPaint);

    zonePaint.color =
        trackClear ? _kOk.withOpacity(0.4) : _kDanger.withOpacity(0.4);
    canvas.drawRRect(
        RRect.fromRectAndRadius(trackRect, const Radius.circular(12)),
        zonePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(trackRect, const Radius.circular(12)),
        borderPaint);

    zonePaint.color =
        estopReady ? _kOk.withOpacity(0.4) : _kWarning.withOpacity(0.4);
    canvas.drawRRect(
        RRect.fromRectAndRadius(estopRect, const Radius.circular(12)),
        zonePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(estopRect, const Radius.circular(12)),
        borderPaint);

    _drawZoneLabel(canvas, operatorRect, 'Operator');
    _drawZoneLabel(canvas, trackRect, 'Track');
    _drawZoneLabel(canvas, estopRect, 'Control');
  }

  void _drawZoneLabel(Canvas canvas, Rect rect, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    textPainter.paint(canvas, Offset(rect.left + 12, rect.top + 10));
  }

  @override
  bool shouldRepaint(covariant _SafetyZonePainter oldDelegate) {
    return oldDelegate.operatorClear != operatorClear ||
        oldDelegate.trackClear != trackClear ||
        oldDelegate.estopReady != estopReady;
  }
}

class _DerivedTelemetry {
  const _DerivedTelemetry({
    required this.speedKmh,
    required this.gear,
    required this.rpm,
    required this.latencyMs,
    required this.trackProgress,
  });

  final double speedKmh;
  final int gear;
  final double rpm;
  final double latencyMs;
  final double trackProgress;
}

class _ReviewFallback {
  const _ReviewFallback({required this.samples, required this.simulated});

  final List<_SpeedSample> samples;
  final bool simulated;
}

class _SpeedSample {
  const _SpeedSample({
    required this.timestamp,
    required this.speedKmh,
    required this.trackProgress,
    this.gear,
    this.rpm,
  });

  final DateTime timestamp;
  final double speedKmh;
  final double trackProgress;
  final int? gear;
  final double? rpm;
}

class _CalibrationAttempt {
  const _CalibrationAttempt(
      {required this.timestamp, required this.success, required this.message});

  final DateTime timestamp;
  final bool success;
  final String message;
}

class _Fault {
  const _Fault(
      {required this.title,
      required this.detail,
      required this.steps,
      required this.color});

  final String title;
  final String detail;
  final List<String> steps;
  final Color color;
}

String _formatTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final value = local.toIso8601String();
  return value.replaceFirst('T', ' ').split('.').first;
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
