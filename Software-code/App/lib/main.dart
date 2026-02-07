import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'composition_engine.dart';
import 'data_management.dart';
import 'gen/dashboard/v1/dashboard.pb.dart';
import 'session_browser.dart';
import 'services/dashboard_client.dart';
import 'services/voice_pipeline.dart';
import 'telemetry_analysis.dart';

const Color _kBackground = Color(0xFF0B0B0B);
const Color _kSurface = Color(0xFF141414);
const Color _kSurfaceRaised = Color(0xFF1B1B1B);
const Color _kSurfaceGlow = Color(0xFF2A2A2A);
const Color _kAccent = Color(0xFFFFFFFF);
const Color _kAccentAlt = Color(0xFFCDCDCD);
const Color _kWarning = Color(0xFFE1B866);
const Color _kDanger = Color(0xFFE6392F);
const Color _kOk = Color(0xFF74C77A);
const Color _kMuted = Color(0xFFB3B3B3);
const double _kPanelRadius = 8;
const double _kControlRadius = 4;

void main() {
  runApp(const DashboardApp());
}

DashboardClient _defaultDashboardClientFactory() => DashboardClient();
VoicePipelineController _defaultVoicePipelineFactory() =>
    VoicePipelineController();

class DashboardApp extends StatelessWidget {
  const DashboardApp({
    super.key,
    this.clientFactory = _defaultDashboardClientFactory,
    this.voicePipelineFactory = _defaultVoicePipelineFactory,
  });

  final DashboardClient Function() clientFactory;
  final VoicePipelineController Function() voicePipelineFactory;

  ThemeData _buildTheme() {
    final scheme = const ColorScheme.dark(
      primary: _kDanger,
      secondary: _kAccentAlt,
      surface: _kSurface,
      error: _kDanger,
    );

    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: _kBackground,
      useMaterial3: true,
      fontFamily: 'Inter',
      fontFamilyFallback: const [
        'SF Pro Text',
        'SF Pro Display',
        'Roboto',
        'Arial',
        'sans-serif',
      ],
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.4,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.05,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.05,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          height: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: _kSurface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kPanelRadius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _kSurfaceRaised,
        labelStyle: const TextStyle(
          color: _kMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kControlRadius),
          borderSide: const BorderSide(color: _kSurfaceGlow),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kControlRadius),
          borderSide: const BorderSide(color: _kSurfaceGlow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kControlRadius),
          borderSide: const BorderSide(color: _kDanger, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _kDanger,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kControlRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: _kSurfaceGlow),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kControlRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kControlRadius),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _kSurfaceRaised,
        selectedColor: _kSurfaceRaised,
        disabledColor: _kSurface,
        side: const BorderSide(color: _kSurfaceGlow),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kControlRadius),
        ),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(color: _kSurfaceGlow, thickness: 1),
      sliderTheme: const SliderThemeData(
        thumbColor: _kDanger,
        activeTrackColor: _kDanger,
        inactiveTrackColor: _kSurfaceGlow,
      ),
      tabBarTheme: const TabBarThemeData(
        dividerColor: _kSurfaceGlow,
        indicatorColor: _kDanger,
        labelColor: Colors.white,
        unselectedLabelColor: _kMuted,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.4),
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.2),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _kDanger,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kControlRadius),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _kDanger,
        linearTrackColor: _kSurfaceGlow,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _kDanger;
          }
          return _kMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _kDanger.withValues(alpha: 0.35);
          }
          return _kSurfaceGlow;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kControlRadius),
        ),
        side: const BorderSide(color: _kSurfaceGlow),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _kDanger;
          }
          return Colors.transparent;
        }),
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
      home: DashboardHome(
        clientFactory: clientFactory,
        voicePipelineFactory: voicePipelineFactory,
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({
    super.key,
    this.clientFactory = _defaultDashboardClientFactory,
    this.voicePipelineFactory = _defaultVoicePipelineFactory,
  });

  final DashboardClient Function() clientFactory;
  final VoicePipelineController Function() voicePipelineFactory;

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  late final DashboardClient client;
  late final VoicePipelineController _voice;
  final BroadcastCompositionEngine _composition = BroadcastCompositionEngine();
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
  String _sessionCarFilter = kAllCarsFilter;
  final Set<String> _deletedSessionIds = <String>{};
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
  bool _voicePointerDown = false;
  bool _analysisCompareMode = true;
  double _analysisZoom = 1.0;
  double _analysisPan = 0.0;
  DataManagementPreferences _dataPreferences =
      const DataManagementPreferences();
  SessionShareCard? _latestShareCard;
  final List<TelemetryExportArtifact> _exportArtifacts = [];
  bool _dataTaskRunning = false;
  String? _dataNotice;
  double _smoothedTrackProgress = 0.0;
  double _lastTrackProgressRaw = 0.0;
  bool _trackProgressInitialized = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    client = widget.clientFactory();
    _voice = widget.voicePipelineFactory();
    client.snapshot.addListener(_onSnapshotUpdate);
    _voice.addListener(_onVoiceUpdate);
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
    _voice.removeListener(_onVoiceUpdate);
    unawaited(_voice.cancelCapture());
    _voice.dispose();
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

  void _onVoiceUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _onSnapshotUpdate() {
    final snapshot = client.snapshot.value;
    final liveDerived = _deriveTelemetry(snapshot, forceLive: true);
    _updateTrackSmoothing(liveDerived.trackProgress);
    _updateBroadcastPhase(snapshot, liveDerived);
    unawaited(_voice.setSafetyWarningActive(_hasSafetyWarning(snapshot)));
    final status = snapshot.status;
    _voice.updateRaceContext(
      estopActive: status?.estopActive ?? estopEngaged,
      faultActive: status?.state == Status_State.STATE_FAULT,
    );
    final telemetry = snapshot.telemetry;
    if (telemetry != null) {
      final inferredTrack = trackController.text.trim().isEmpty
          ? (status?.sessionId.isNotEmpty == true
              ? status!.sessionId
              : 'track-unknown')
          : trackController.text.trim();
      final inferredDriver = profileController.text.trim().isEmpty
          ? 'intermediate'
          : profileController.text.trim();
      _voice.updateRaceContext(
        speedKmh: telemetry.speedKmh,
        gear: telemetry.gear,
        rpm: telemetry.engineRpm,
        trackProgress: telemetry.trackProgress,
        trackId: inferredTrack,
        driverLevel: inferredDriver,
      );
    }
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

    _appendSpeedSample(snapshot, liveDerived);
  }

  bool _hasSafetyWarning(DashboardSnapshot snapshot) {
    final status = snapshot.status;
    return snapshot.error != null ||
        status?.state == Status_State.STATE_FAULT ||
        status?.estopActive == true ||
        ((snapshot.telemetry?.latencyMs ?? 0) > 25);
  }

  Future<void> _startPushToTalk(DashboardSnapshot snapshot) async {
    if (_voicePointerDown) {
      return;
    }
    _voicePointerDown = true;
    await _voice.setSafetyWarningActive(_hasSafetyWarning(snapshot));
    await _voice.pushToTalkStart();
  }

  Future<void> _stopPushToTalk(DashboardSnapshot snapshot) async {
    if (!_voicePointerDown) {
      return;
    }
    _voicePointerDown = false;
    await _voice.setSafetyWarningActive(_hasSafetyWarning(snapshot));
    await _voice.pushToTalkStop();
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

  void _updateBroadcastPhase(
      DashboardSnapshot snapshot, _DerivedTelemetry liveDerived) {
    final status = snapshot.status;
    final speedKmh = _phaseSpeedKmh(snapshot, liveDerived);
    final update = _composition.update(
      sessionActive: status?.sessionActive ?? false,
      speedKmh: speedKmh,
    );
    if (update.phaseChanged && mounted) {
      setState(() {});
    }
  }

  double _phaseSpeedKmh(DashboardSnapshot snapshot, _DerivedTelemetry live) {
    final telemetry = snapshot.telemetry;
    if (telemetry != null) {
      final hasLiveSignal = telemetry.speedKmh > 0 ||
          telemetry.engineRpm > 0 ||
          telemetry.gear != 0 ||
          telemetry.trackProgress > 0;
      if (hasLiveSignal) {
        return telemetry.speedKmh;
      }
    }
    if (snapshot.status?.sessionActive == true) {
      return live.speedKmh;
    }
    return 0.0;
  }

  void _updateTrackSmoothing(double rawProgress) {
    final progress = rawProgress.clamp(0.0, 1.0);
    if (!_trackProgressInitialized) {
      _trackProgressInitialized = true;
      _lastTrackProgressRaw = progress;
      _smoothedTrackProgress = progress;
      return;
    }
    var delta = progress - _lastTrackProgressRaw;
    if (delta > 0.5) {
      delta -= 1.0;
    } else if (delta < -0.5) {
      delta += 1.0;
    }
    final target = _smoothedTrackProgress + delta;
    _smoothedTrackProgress =
        _smoothedTrackProgress + (target - _smoothedTrackProgress) * 0.38;
    _lastTrackProgressRaw = progress;
  }

  void _appendSpeedSample(
      DashboardSnapshot snapshot, _DerivedTelemetry liveDerived) {
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
    final sample = _SpeedSample(
      timestamp: now,
      speedKmh: liveDerived.speedKmh,
      trackProgress: liveDerived.trackProgress,
      gear: liveDerived.gear,
      rpm: liveDerived.rpm,
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
      var visible = sessions
          .where((session) => !_deletedSessionIds.contains(session.sessionId))
          .toList();
      final autoDelete = _dataPreferences.autoDeleteEnabled
          ? autoDeleteCandidates(
              visible,
              now: DateTime.now(),
              retentionDays: _dataPreferences.autoDeleteRetentionDays,
            )
          : const <SessionMetadata>[];
      final autoDeletedIds = autoDelete
          .map((session) => session.sessionId)
          .where((id) => id.trim().isNotEmpty)
          .toSet();
      if (autoDeletedIds.isNotEmpty) {
        _deletedSessionIds.addAll(autoDeletedIds);
        _pruneSessionCaches(autoDeletedIds);
        visible = visible
            .where((session) => !autoDeletedIds.contains(session.sessionId))
            .toList();
      }

      setState(() {
        _sessions = visible;
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
        if (_sessionCarFilter != kAllCarsFilter &&
            !carFilterOptions(_sessions).contains(_sessionCarFilter)) {
          _sessionCarFilter = kAllCarsFilter;
        }
        if (autoDeletedIds.isNotEmpty) {
          _dataNotice =
              'Auto-delete removed ${autoDeletedIds.length} archived session${autoDeletedIds.length == 1 ? '' : 's'}.';
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

  void _pruneSessionCaches(Iterable<String> sessionIds) {
    final ids = sessionIds.where((id) => id.trim().isNotEmpty).toSet();
    if (ids.isEmpty) {
      return;
    }
    for (final id in ids) {
      _sessionHistory.remove(id);
    }
    _exportArtifacts
        .removeWhere((artifact) => ids.contains(artifact.sessionId));
    if (_latestShareCard != null && ids.contains(_latestShareCard!.sessionId)) {
      _latestShareCard = null;
    }
    if (_selectedSessionId != null && ids.contains(_selectedSessionId)) {
      _selectedSessionId = null;
    }
    if (_activeSessionId != null && ids.contains(_activeSessionId)) {
      _activeSessionId = null;
      _liveHistory = [];
    }
    if (_reviewSession != null && ids.contains(_reviewSession!.sessionId)) {
      _reviewMode = false;
      _reviewSession = null;
      _reviewSimulated = false;
      _reviewSamples = [];
      _reviewProgress = 1.0;
      _reviewNotice = null;
      _reviewFetching = false;
      _analysisCompareMode = true;
      _analysisZoom = 1.0;
      _analysisPan = 0.0;
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
      _analysisCompareMode = true;
      _analysisZoom = 1.0;
      _analysisPan = 0.0;
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
      _analysisZoom = 1.0;
      _analysisPan = 0.0;
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
          _reviewSession?.sessionId != session.sessionId) {
        return;
      }
      setState(() {
        _reviewNotice = 'Telemetry fetch failed. Using fallback data.';
      });
    } finally {
      if (mounted &&
          _reviewMode &&
          _reviewSession?.sessionId == session.sessionId) {
        setState(() {
          _reviewFetching = false;
        });
      }
    }
  }

  Future<void> _deleteSessionCascade(
    SessionMetadata session, {
    bool autoTriggered = false,
  }) async {
    final sessionId = session.sessionId.trim();
    if (sessionId.isEmpty) {
      return;
    }
    if (!autoTriggered) {
      setState(() {
        _dataTaskRunning = true;
      });
    }
    var remoteDeleted = false;
    try {
      remoteDeleted = await client.deleteSession(sessionId);
    } catch (_) {
      remoteDeleted = false;
    }
    if (!mounted) return;
    setState(() {
      _deletedSessionIds.add(sessionId);
      _pruneSessionCaches(<String>[sessionId]);
      _sessions.removeWhere((item) => item.sessionId == sessionId);
      if (_sessionTrackFilter != kAllTracksFilter &&
          !trackFilterOptions(_sessions).contains(_sessionTrackFilter)) {
        _sessionTrackFilter = kAllTracksFilter;
      }
      if (_sessionCarFilter != kAllCarsFilter &&
          !carFilterOptions(_sessions).contains(_sessionCarFilter)) {
        _sessionCarFilter = kAllCarsFilter;
      }
      _dataNotice = autoTriggered
          ? 'Auto-deleted $sessionId due to retention policy.'
          : remoteDeleted
              ? 'Deleted $sessionId and synced with server.'
              : 'Deleted $sessionId locally (server delete unavailable).';
      _dataTaskRunning = false;
    });
  }

  void _applyAutoDeletePolicy() {
    if (!_dataPreferences.autoDeleteEnabled) {
      return;
    }
    final candidates = autoDeleteCandidates(
      _sessions,
      now: DateTime.now(),
      retentionDays: _dataPreferences.autoDeleteRetentionDays,
    );
    if (candidates.isEmpty) {
      return;
    }
    final ids = candidates
        .map((session) => session.sessionId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    if (ids.isEmpty) {
      return;
    }
    setState(() {
      _deletedSessionIds.addAll(ids);
      _pruneSessionCaches(ids);
      _sessions.removeWhere((session) => ids.contains(session.sessionId));
      if (_sessionTrackFilter != kAllTracksFilter &&
          !trackFilterOptions(_sessions).contains(_sessionTrackFilter)) {
        _sessionTrackFilter = kAllTracksFilter;
      }
      if (_sessionCarFilter != kAllCarsFilter &&
          !carFilterOptions(_sessions).contains(_sessionCarFilter)) {
        _sessionCarFilter = kAllCarsFilter;
      }
      _dataNotice =
          'Auto-delete removed ${ids.length} session${ids.length == 1 ? '' : 's'}.';
    });
  }

  Future<List<_SpeedSample>> _loadSessionSamples(
      SessionMetadata session) async {
    final sessionId = session.sessionId;
    final cached = _sessionHistory[sessionId];
    if (cached != null && cached.isNotEmpty) {
      return List<_SpeedSample>.of(cached);
    }
    final samples = await client.getSessionTelemetry(
      sessionId,
      maxSamples: _reviewMaxSamples,
    );
    final mapped = _mapTelemetrySamples(samples);
    final hasReal = mapped.any((sample) {
      final rpm = sample.rpm ?? 0.0;
      final gear = sample.gear ?? 0;
      return sample.speedKmh > 0 ||
          rpm > 0 ||
          sample.trackProgress > 0 ||
          gear != 0;
    });
    if (hasReal) {
      _sessionHistory[sessionId] = mapped;
      return mapped;
    }
    final fallback = _generateSyntheticSamples(session);
    _sessionHistory[sessionId] = fallback;
    return fallback;
  }

  Future<void> _generateShareCardFor(SessionMetadata session) async {
    if (_dataTaskRunning) {
      return;
    }
    setState(() {
      _dataTaskRunning = true;
    });
    try {
      final samples = await _loadSessionSamples(session);
      final frames = _analysisFramesFromSamples(samples);
      final card = generateHighlightShareCard(
        session: session,
        frames: frames,
        units: _dataPreferences.units,
      );
      if (!mounted) return;
      setState(() {
        _latestShareCard = card;
        _dataNotice = 'Generated highlight share card ${card.shareCode}.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dataNotice = 'Unable to generate share card.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _dataTaskRunning = false;
        });
      }
    }
  }

  Future<void> _generateExportFor(
    SessionMetadata session,
    TelemetryExportKind kind,
  ) async {
    if (_dataTaskRunning) {
      return;
    }
    setState(() {
      _dataTaskRunning = true;
    });
    try {
      final samples = await _loadSessionSamples(session);
      final frames = _analysisFramesFromSamples(samples);
      final artifact = switch (kind) {
        TelemetryExportKind.imageSvg =>
          generateImageExportArtifact(session: session, frames: frames),
        TelemetryExportKind.videoManifest =>
          generateVideoExportArtifact(session: session, frames: frames),
      };
      final usageMb = _estimatedStorageUsageMb();
      final wouldOverflow = wouldExceedStorageLimit(
        currentUsageMb: usageMb,
        nextArtifactBytes: artifact.sizeBytes,
        storageLimitGb: _dataPreferences.storageLimitGb,
      );
      if (!mounted) return;
      if (wouldOverflow) {
        setState(() {
          _dataNotice =
              'Storage limit reached. Increase limit or delete old exports.';
        });
        return;
      }
      setState(() {
        _exportArtifacts.insert(0, artifact);
        if (_exportArtifacts.length > 24) {
          _exportArtifacts.removeRange(24, _exportArtifacts.length);
        }
        _dataNotice = 'Generated ${artifact.fileName}.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dataNotice = 'Unable to generate export artifact.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _dataTaskRunning = false;
        });
      }
    }
  }

  double _estimatedStorageUsageMb() {
    final sampleCounts = <String, int>{};
    for (final session in _sessions) {
      final sessionId = session.sessionId;
      if (sessionId.trim().isEmpty) {
        continue;
      }
      final cached = _sessionHistory[sessionId];
      if (cached != null && cached.isNotEmpty) {
        sampleCounts[sessionId] = cached.length;
      } else {
        final durationMs = session.durationMs.toInt();
        final estimated =
            durationMs > 0 ? (durationMs / 220).round().clamp(90, 1500) : 180;
        sampleCounts[sessionId] = estimated;
      }
    }
    return estimatedArchiveStorageMb(
      sessionSampleCounts: sampleCounts,
      exports: _exportArtifacts,
    );
  }

  SessionMetadata? _selectedArchiveSession() {
    final filtered = _filteredSessions();
    return _selectedSessionFrom(filtered) ?? _selectedSessionFrom(_sessions);
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
      length: 3,
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
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            tabs: [
              Tab(text: 'Live Dashboard'),
              Tab(text: 'System Status'),
              Tab(text: 'Data & Sharing'),
            ],
          ),
        ),
        floatingActionButton: _selectedTabIndex == 2
            ? null
            : ValueListenableBuilder<DashboardSnapshot>(
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
                    _buildDataManagement(snapshot, isWide),
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
    final phase =
        _reviewMode ? BroadcastRacePhase.postRace : _composition.phase;
    final showTelemetry =
        _composition.shouldShow(BroadcastWidgetSlot.telemetryHud, phase: phase);
    final showTrackMap =
        _composition.shouldShow(BroadcastWidgetSlot.trackMap, phase: phase);
    final showSpeedGraph =
        _composition.shouldShow(BroadcastWidgetSlot.speedGraph, phase: phase);
    final showSessionBrowser = _composition
        .shouldShow(BroadcastWidgetSlot.sessionBrowser, phase: phase);
    final showVoice =
        _composition.shouldShow(BroadcastWidgetSlot.voicePanel, phase: phase);
    final showSessionControl = _composition
        .shouldShow(BroadcastWidgetSlot.sessionControl, phase: phase);
    final showLeaderboard =
        _composition.shouldShow(BroadcastWidgetSlot.leaderboard, phase: phase);
    final showSummary =
        _composition.shouldShow(BroadcastWidgetSlot.summaryCard, phase: phase);

    final topPanels = <Widget>[];
    if (showTelemetry) {
      topPanels.add(_buildTelemetryHud(derived));
    }
    if (showTrackMap) {
      topPanels.add(_buildTrackMap(derived));
    }
    if (showSummary) {
      topPanels.add(_buildSummaryModeCard(snapshot, derived, samples));
    }

    final middlePanels = <Widget>[];
    if (showSpeedGraph) {
      middlePanels.add(_buildSpeedGraph(samples, derived));
    }
    if (showSessionBrowser) {
      middlePanels.add(_buildSessionList(snapshot));
    }
    if (showLeaderboard) {
      middlePanels.add(_buildLeaderboardStack(snapshot, derived, samples));
    }

    final lowerPanels = <Widget>[];
    final showAnalysis = _reviewMode && samples.length > 8;
    if (showVoice) {
      lowerPanels.add(_buildVoiceInterface(snapshot));
    }
    if (showSessionControl) {
      lowerPanels.add(_buildSessionControl(snapshot));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewBanner(snapshot.status?.sessionActive ?? false,
              snapshot.status?.sessionId ?? ''),
          const SizedBox(height: 16),
          _buildRacePhaseIndicator(phase),
          const SizedBox(height: 16),
          _buildOverviewStrip(snapshot, derived),
          const SizedBox(height: 16),
          _buildPanelStack(topPanels, isWide: isWide),
          if (middlePanels.isNotEmpty) const SizedBox(height: 16),
          _buildPanelStack(middlePanels, isWide: isWide),
          if (showAnalysis) const SizedBox(height: 16),
          if (showAnalysis) _buildTelemetryAnalysisPanel(samples),
          if (lowerPanels.isNotEmpty) const SizedBox(height: 16),
          _buildPanelStack(lowerPanels, isWide: isWide),
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

  Widget _buildDataManagement(DashboardSnapshot snapshot, bool isWide) {
    final selected = _selectedArchiveSession();
    final usageMb = _estimatedStorageUsageMb();
    final limitMb = _dataPreferences.storageLimitGb * 1024;
    final overLimit = usageMb > limitMb;

    return SingleChildScrollView(
      key: const Key('data-management-screen'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionList(snapshot),
          const SizedBox(height: 16),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildShareAndExportCard(
                    selectedSession: selected,
                    usageMb: usageMb,
                    limitMb: limitMb,
                    overLimit: overLimit,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDataPreferencesCard(
                    usageMb: usageMb,
                    limitMb: limitMb,
                    overLimit: overLimit,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildShareAndExportCard(
                  selectedSession: selected,
                  usageMb: usageMb,
                  limitMb: limitMb,
                  overLimit: overLimit,
                ),
                const SizedBox(height: 16),
                _buildDataPreferencesCard(
                  usageMb: usageMb,
                  limitMb: limitMb,
                  overLimit: overLimit,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildShareAndExportCard({
    required SessionMetadata? selectedSession,
    required double usageMb,
    required double limitMb,
    required bool overLimit,
  }) {
    final recentExports = _exportArtifacts.take(5).toList(growable: false);

    return _HudCard(
      key: const Key('share-export-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Sharing & Export',
            subtitle: 'FLT-053~055 · Delete cascade + highlight + media export',
          ),
          const SizedBox(height: 12),
          if (selectedSession == null)
            const Text(
              'Select an archived session to generate share cards and exports.',
              style: TextStyle(color: _kMuted),
            )
          else ...[
            Text(
              'Selected: ${selectedSession.sessionId}',
              key: const Key('sharing-selected-session'),
              style: const TextStyle(
                color: _kAccentAlt,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: const Key('share-card-generate'),
                  onPressed: _dataTaskRunning
                      ? null
                      : () => _generateShareCardFor(selectedSession),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Generate Share Card'),
                ),
                OutlinedButton.icon(
                  key: const Key('export-image-button'),
                  onPressed: _dataTaskRunning
                      ? null
                      : () => _generateExportFor(
                          selectedSession, TelemetryExportKind.imageSvg),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Export Image'),
                ),
                OutlinedButton.icon(
                  key: const Key('export-video-button'),
                  onPressed: _dataTaskRunning
                      ? null
                      : () => _generateExportFor(
                          selectedSession, TelemetryExportKind.videoManifest),
                  icon: const Icon(Icons.movie_creation_outlined, size: 18),
                  label: const Text('Export Video'),
                ),
                OutlinedButton.icon(
                  key: Key('archive-delete-${selectedSession.sessionId}'),
                  onPressed: _dataTaskRunning
                      ? null
                      : () => _deleteSessionCascade(selectedSession),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete Session'),
                ),
              ],
            ),
          ],
          if (_dataNotice != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  overLimit ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: overLimit ? _kWarning : _kAccentAlt,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _dataNotice!,
                    key: const Key('data-management-notice'),
                    style: const TextStyle(color: _kMuted),
                  ),
                ),
              ],
            ),
          ],
          if (_latestShareCard != null) ...[
            const SizedBox(height: 14),
            Container(
              key: const Key('share-card-preview'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kSurfaceGlow.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(_kPanelRadius),
                border: Border.all(color: _kAccentAlt.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _latestShareCard!.headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _latestShareCard!.summary,
                    style: const TextStyle(color: _kMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share code: ${_latestShareCard!.shareCode}',
                    style: const TextStyle(
                      color: _kAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            key: const Key('export-history'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kSurfaceGlow.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(_kPanelRadius),
              border: Border.all(color: _kSurfaceGlow),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export History',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (_exportArtifacts.isEmpty)
                  const Text(
                    'No exports generated yet.',
                    style: TextStyle(color: _kMuted),
                  )
                else
                  for (var i = 0; i < recentExports.length; i++) ...[
                    Text(
                      '${recentExports[i].fileName} · ${(recentExports[i].sizeBytes / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(color: _kMuted, fontSize: 12),
                    ),
                    if (i < recentExports.length - 1) const SizedBox(height: 4),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Usage ${(usageMb / 1024).toStringAsFixed(2)} GB / ${(limitMb / 1024).toStringAsFixed(2)} GB',
            style: TextStyle(
              color: overLimit ? _kWarning : _kMuted,
              fontWeight: overLimit ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPreferencesCard({
    required double usageMb,
    required double limitMb,
    required bool overLimit,
  }) {
    return _HudCard(
      key: const Key('user-preferences-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'User Preferences',
            subtitle: 'FLT-056~057 · Units, storage budget, auto-delete policy',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<UnitSystem>(
            key: const Key('preferences-units-dropdown'),
            value: _dataPreferences.units,
            items: const [
              DropdownMenuItem(
                value: UnitSystem.metric,
                child: Text('Metric (km/h)'),
              ),
              DropdownMenuItem(
                value: UnitSystem.imperial,
                child: Text('Imperial (mph)'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _dataPreferences = _dataPreferences.copyWith(units: value);
              });
            },
            decoration: const InputDecoration(
              labelText: 'Display Units',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Storage Limit (${_dataPreferences.storageLimitGb.toStringAsFixed(1)} GB)',
            style: const TextStyle(color: _kMuted),
          ),
          Slider(
            key: const Key('preferences-storage-slider'),
            min: 1.0,
            max: 24.0,
            divisions: 46,
            value: _dataPreferences.storageLimitGb.clamp(1.0, 24.0).toDouble(),
            onChanged: (value) {
              setState(() {
                _dataPreferences =
                    _dataPreferences.copyWith(storageLimitGb: value);
              });
            },
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            key: const Key('preferences-autodelete-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-delete old sessions'),
            subtitle: Text(
              _dataPreferences.autoDeleteEnabled
                  ? 'Enabled: keep ${_dataPreferences.autoDeleteRetentionDays} days'
                  : 'Disabled',
              style: const TextStyle(color: _kMuted, fontSize: 12),
            ),
            value: _dataPreferences.autoDeleteEnabled,
            onChanged: (value) {
              setState(() {
                _dataPreferences =
                    _dataPreferences.copyWith(autoDeleteEnabled: value);
              });
              if (value) {
                _applyAutoDeletePolicy();
              }
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Retention (${_dataPreferences.autoDeleteRetentionDays} days)',
            style: const TextStyle(color: _kMuted),
          ),
          Slider(
            key: const Key('preferences-retention-slider'),
            min: 1,
            max: 120,
            divisions: 119,
            value: _dataPreferences.autoDeleteRetentionDays
                .clamp(1, 120)
                .toDouble(),
            onChanged: _dataPreferences.autoDeleteEnabled
                ? (value) {
                    setState(() {
                      _dataPreferences = _dataPreferences.copyWith(
                        autoDeleteRetentionDays: value.round().clamp(1, 120),
                      );
                    });
                    _applyAutoDeletePolicy();
                  }
                : null,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: limitMb <= 0 ? 0.0 : (usageMb / limitMb).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: _kSurfaceGlow,
            valueColor: AlwaysStoppedAnimation(
              overLimit ? _kWarning : _kAccentAlt,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estimated archive usage ${(usageMb / 1024).toStringAsFixed(2)} GB / ${(limitMb / 1024).toStringAsFixed(2)} GB',
            key: const Key('storage-usage-label'),
            style: TextStyle(
              color: overLimit ? _kWarning : _kMuted,
              fontWeight: overLimit ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
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

  Widget _buildPanelStack(List<Widget> panels, {required bool isWide}) {
    if (panels.isEmpty) {
      return const SizedBox.shrink();
    }
    if (!isWide) {
      return Column(
        children: [
          for (var i = 0; i < panels.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            panels[i],
          ],
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < panels.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: panels[i]),
              const SizedBox(width: 16),
              Expanded(
                child: i + 1 < panels.length
                    ? panels[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRacePhaseIndicator(BroadcastRacePhase phase) {
    final phaseLabel = broadcastRacePhaseLabel(phase);
    final changedAt = _formatTimestamp(_composition.phaseChangedAt);
    final subtitle = switch (phase) {
      BroadcastRacePhase.preRace => 'Waiting for the session start signal.',
      BroadcastRacePhase.live =>
        'Live overlays and voice controls are enabled.',
      BroadcastRacePhase.postRace =>
        'Race ended. Broadcast layout favors review tools.',
      BroadcastRacePhase.summary =>
        'Car stopped. Auto-switched to summary mode.',
    };
    final phaseColor = switch (phase) {
      BroadcastRacePhase.preRace => _kAccentAlt,
      BroadcastRacePhase.live => _kAccent,
      BroadcastRacePhase.postRace => _kWarning,
      BroadcastRacePhase.summary => _kOk,
    };

    return _HudCard(
      key: const Key('race-phase-indicator'),
      child: Row(
        children: [
          Icon(Icons.video_settings_rounded, color: phaseColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broadcast Phase: $phaseLabel',
                  key: const Key('race-phase-label'),
                  style:
                      TextStyle(color: phaseColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _reviewMode ? 'Review mode override active.' : subtitle,
                  style: const TextStyle(color: _kMuted),
                ),
              ],
            ),
          ),
          Text(
            'since $changedAt',
            style: const TextStyle(color: _kMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryModeCard(
    DashboardSnapshot snapshot,
    _DerivedTelemetry derived,
    List<_SpeedSample> samples,
  ) {
    final peakSpeed = samples.isEmpty ? derived.speedKmh : _maxSpeed(samples);
    final avgSpeed = samples.isEmpty
        ? derived.speedKmh
        : samples.map((e) => e.speedKmh).reduce((a, b) => a + b) /
            samples.length;
    final sessionId = snapshot.status?.sessionId ?? _activeSessionId ?? '--';

    return _HudCard(
      key: const Key('summary-mode-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Race Summary',
            subtitle: 'FLT-044 · Auto summary after stop detection',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _StatusPill(
                label: 'SESSION',
                value: sessionId.isEmpty ? '--' : sessionId,
                color: _kAccent,
              ),
              _StatusPill(
                label: 'PEAK',
                value:
                    '${_displaySpeed(peakSpeed).toStringAsFixed(0)} ${_speedUnitLabel()}',
                color: _kAccentAlt,
              ),
              _StatusPill(
                label: 'AVERAGE',
                value:
                    '${_displaySpeed(avgSpeed).toStringAsFixed(0)} ${_speedUnitLabel()}',
                color: _kWarning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Summary mode triggers when speed stays below '
            '${_displaySpeed(_composition.summaryStopSpeedKmh).toStringAsFixed(1)} ${_speedUnitLabel()} '
            'for ${_composition.summaryStopDuration.inSeconds}s.',
            style: const TextStyle(color: _kMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardStack(
    DashboardSnapshot snapshot,
    _DerivedTelemetry derived,
    List<_SpeedSample> samples,
  ) {
    final entries = _buildLeaderboardEntries(snapshot, derived, samples);
    final leaderSpeed = entries.first.speedKmh;

    return _HudCard(
      key: const Key('leaderboard-stack'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Leaderboard Stack',
            subtitle: 'FLT-043 · Broadcast-ready race order',
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Transform.translate(
              offset: Offset(0, -i * 3.0),
              child: _buildLeaderboardRow(
                entry: entries[i],
                rank: i + 1,
                gapLabel: i == 0
                    ? 'LEAD'
                    : '+${((leaderSpeed - entries[i].speedKmh).abs() / 22.0).clamp(0.12, 9.9).toStringAsFixed(3)}s',
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_LeaderboardEntry> _buildLeaderboardEntries(
    DashboardSnapshot snapshot,
    _DerivedTelemetry derived,
    List<_SpeedSample> samples,
  ) {
    final seedTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final driver = snapshot.status?.activeProfile.isNotEmpty == true
        ? snapshot.status!.activeProfile
        : profileController.text.trim();
    final peakSpeed = samples.isEmpty ? derived.speedKmh : _maxSpeed(samples);
    final userSpeed = derived.speedKmh.clamp(0.0, 320.0).toDouble();
    final paceSpeed = (derived.speedKmh + 11 + 7 * sin(seedTime * 1.3))
        .clamp(5.0, 320.0)
        .toDouble();
    final ghostSpeed =
        max(10.0, (peakSpeed * 0.94) + 3 * cos(seedTime * 0.7)).toDouble();

    final entries = <_LeaderboardEntry>[
      _LeaderboardEntry(
        label: driver.isEmpty ? 'DRIVER' : driver.toUpperCase(),
        tag: 'YOU',
        speedKmh: userSpeed,
        progress: _wrapProgress(derived.trackProgress),
        color: _kAccent,
      ),
      _LeaderboardEntry(
        label: 'PACE BOT',
        tag: 'SIM',
        speedKmh: paceSpeed,
        progress: _wrapProgress(derived.trackProgress + 0.02),
        color: _kAccentAlt,
      ),
      _LeaderboardEntry(
        label: 'BEST LAP GHOST',
        tag: 'GHOST',
        speedKmh: ghostSpeed,
        progress: _wrapProgress(derived.trackProgress + 0.05),
        color: _kWarning,
      ),
    ];
    entries.sort((a, b) => b.speedKmh.compareTo(a.speedKmh));
    return entries;
  }

  Widget _buildLeaderboardRow({
    required _LeaderboardEntry entry,
    required int rank,
    required String gapLabel,
  }) {
    return Container(
      key: Key('leaderboard-row-$rank'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurfaceGlow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(_kPanelRadius),
        border: Border.all(color: entry.color.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(color: entry.color, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              '${entry.label} · ${entry.tag}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${_displaySpeed(entry.speedKmh).toStringAsFixed(0)} ${_speedUnitLabel()}',
            style: TextStyle(color: entry.color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(gapLabel, style: const TextStyle(color: _kMuted, fontSize: 12)),
        ],
      ),
    );
  }

  double _wrapProgress(double value) {
    final wrapped = value % 1.0;
    return wrapped < 0 ? wrapped + 1.0 : wrapped;
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
                    color: _kAccent.withValues(alpha: 0.8),
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
                      color: _kWarning.withValues(alpha: 0.9),
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
                  value: _displaySpeed(derived.speedKmh).toStringAsFixed(0),
                  unit: _speedUnitLabel(),
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
    final displayProgress = derived.trackProgress;
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
              tween: Tween<double>(end: displayProgress),
              duration: const Duration(milliseconds: 150),
              curve: Curves.linear,
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
              'Peak ${_displaySpeed(_maxSpeed(samples)).toStringAsFixed(0)} ${_speedUnitLabel()} · '
              'Current ${_displaySpeed(derived.speedKmh).toStringAsFixed(0)} ${_speedUnitLabel()}',
              style: const TextStyle(color: _kMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildTelemetryAnalysisPanel(List<_SpeedSample> samples) {
    final frames = _analysisFramesFromSamples(samples);
    final primary = deriveTelemetryPoints(frames);
    final reference = _analysisCompareMode
        ? buildReferenceLapOverlay(primary)
        : const <TelemetryPoint>[];
    final deltas = _analysisCompareMode
        ? buildTimeDeltaSeries(primary, reference)
        : const <TimeDeltaPoint>[];
    final sectors = buildSectorBreakdown(
      primary,
      reference: _analysisCompareMode ? reference : null,
    );
    final viewport = computeGraphViewport(
      sampleCount: primary.length,
      zoom: _analysisZoom,
      pan: _analysisPan,
    );
    final speedMax = primary
        .map((point) => point.speedKmh)
        .fold<double>(1.0, (maxValue, value) => max(maxValue, value))
        .clamp(1.0, 420.0)
        .toDouble();
    final speedSeries = primary
        .map((point) => (point.speedKmh / speedMax).clamp(0.0, 1.0))
        .toList();
    final throttleSeries = primary.map((point) => point.throttle).toList();
    final brakeSeries = primary.map((point) => point.brake).toList();
    final steeringSeries = primary
        .map((point) => ((point.steering + 1.0) / 2.0).clamp(0.0, 1.0))
        .toList();
    final referenceSpeedSeries = reference
        .map((point) => (point.speedKmh / speedMax).clamp(0.0, 1.0))
        .toList();
    final maxDelta = deltas
        .map((point) => point.deltaSeconds.abs())
        .fold<double>(0.1, (maxValue, value) => max(maxValue, value))
        .clamp(0.1, 20.0)
        .toDouble();
    final deltaSeries = deltas
        .map((point) => ((point.deltaSeconds / maxDelta) + 1.0) / 2.0)
        .toList();
    final currentDelta = _analysisCompareMode && deltas.isNotEmpty
        ? _deltaAtProgress(deltas, _reviewProgress)
        : 0.0;

    return _HudCard(
      key: const Key('telemetry-analysis-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Telemetry Analysis',
            subtitle: 'FLT-045~051 · Multi-signal deep review tools',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: _kAccentAlt),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Scrub sync: ${(100 * _reviewProgress).toStringAsFixed(1)}% track position',
                  key: const Key('analysis-scrub-label'),
                  style: const TextStyle(color: _kMuted),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Compare', style: TextStyle(color: _kMuted)),
              Switch(
                key: const Key('analysis-compare-switch'),
                value: _analysisCompareMode,
                onChanged: (value) {
                  setState(() {
                    _analysisCompareMode = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: Row(
                  children: [
                    const Text('Zoom', style: TextStyle(color: _kMuted)),
                    Expanded(
                      child: Slider(
                        key: const Key('analysis-zoom-slider'),
                        min: 1,
                        max: 6,
                        divisions: 20,
                        value: _analysisZoom,
                        label: '${_analysisZoom.toStringAsFixed(1)}x',
                        onChanged: (value) {
                          setState(() {
                            _analysisZoom = value;
                            if (_analysisZoom <= 1.02) {
                              _analysisPan = 0;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 300,
                child: Row(
                  children: [
                    const Text('Pan', style: TextStyle(color: _kMuted)),
                    Expanded(
                      child: Slider(
                        key: const Key('analysis-pan-slider'),
                        min: 0,
                        max: 1,
                        value: _analysisPan,
                        onChanged: _analysisZoom <= 1.02
                            ? null
                            : (value) {
                                setState(() {
                                  _analysisPan = value;
                                });
                              },
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _analysisZoom = 1;
                    _analysisPan = 0;
                  });
                },
                icon: const Icon(Icons.center_focus_strong, size: 16),
                label: const Text('Reset View'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => _onAnalysisScrub(
                    details.localPosition.dx,
                    width,
                    viewport,
                  ),
                  onHorizontalDragStart: (details) => _onAnalysisScrub(
                    details.localPosition.dx,
                    width,
                    viewport,
                  ),
                  onHorizontalDragUpdate: (details) => _onAnalysisScrub(
                    details.localPosition.dx,
                    width,
                    viewport,
                  ),
                  child: CustomPaint(
                    key: const Key('analysis-multi-signal-graph'),
                    painter: _HiPerfLineChartPainter(
                      series: [
                        _ChartSeries(
                          id: 'speed',
                          values: speedSeries,
                          color: _kAccentAlt,
                          strokeWidth: 2.4,
                        ),
                        _ChartSeries(
                          id: 'throttle',
                          values: throttleSeries,
                          color: _kOk,
                          strokeWidth: 1.7,
                        ),
                        _ChartSeries(
                          id: 'brake',
                          values: brakeSeries,
                          color: _kDanger,
                          strokeWidth: 1.7,
                        ),
                        _ChartSeries(
                          id: 'steering',
                          values: steeringSeries,
                          color: _kWarning,
                          strokeWidth: 1.7,
                        ),
                        if (_analysisCompareMode &&
                            referenceSpeedSeries.length == speedSeries.length)
                          _ChartSeries(
                            id: 'reference-speed',
                            values: referenceSpeedSeries,
                            color: Colors.white70,
                            strokeWidth: 1.6,
                          ),
                      ],
                      startIndex: viewport.startIndex,
                      endIndex: viewport.endIndex,
                      accentColor: _kSurfaceGlow,
                      cursorProgress: _reviewProgress,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: const [
              _SignalLegendDot(label: 'Speed', color: _kAccentAlt),
              _SignalLegendDot(label: 'Throttle', color: _kOk),
              _SignalLegendDot(label: 'Brake', color: _kDanger),
              _SignalLegendDot(label: 'Steering', color: _kWarning),
              _SignalLegendDot(label: 'Ref Speed', color: Colors.white70),
            ],
          ),
          if (_analysisCompareMode && deltaSeries.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Time Delta (${_signedSeconds(currentDelta)})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: CustomPaint(
                key: const Key('analysis-delta-graph'),
                painter: _HiPerfLineChartPainter(
                  series: [
                    _ChartSeries(
                      id: 'delta',
                      values: deltaSeries,
                      color: currentDelta > 0 ? _kDanger : _kOk,
                      strokeWidth: 2.0,
                    ),
                  ],
                  startIndex: viewport.startIndex
                      .clamp(0, deltaSeries.length - 1)
                      .toInt(),
                  endIndex: viewport.endIndex
                      .clamp(0, deltaSeries.length - 1)
                      .toInt(),
                  accentColor: _kSurfaceGlow,
                  cursorProgress: _reviewProgress,
                  midline: true,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          _buildSectorBreakdownVisualization(sectors),
        ],
      ),
    );
  }

  Widget _buildSectorBreakdownVisualization(SectorBreakdown breakdown) {
    final primaryTotal = breakdown.totalPrimarySeconds;
    final refTotal = max(0.01, breakdown.totalReferenceSeconds);
    return Container(
      key: const Key('analysis-sector-breakdown'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurfaceGlow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(_kPanelRadius),
        border: Border.all(color: _kSurfaceGlow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sector Breakdown',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final sector in breakdown.sectors) ...[
            _SectorBreakdownRow(
              sector: sector,
              baseline: refTotal / 3,
            ),
            if (sector.sector != breakdown.sectors.last.sector)
              const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          Text(
            'Total ${primaryTotal.toStringAsFixed(3)}s vs ${breakdown.totalReferenceSeconds.toStringAsFixed(3)}s '
            '(${_signedSeconds(breakdown.totalDeltaSeconds)})',
            style: TextStyle(
              color: breakdown.totalDeltaSeconds > 0 ? _kDanger : _kOk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _onAnalysisScrub(
    double localX,
    double width,
    GraphViewport viewport,
  ) {
    if (!_reviewMode || width <= 0) {
      return;
    }
    final x = (localX / width).clamp(0.0, 1.0).toDouble();
    final progress = viewport.startProgress +
        (viewport.endProgress - viewport.startProgress) * x;
    setState(() {
      _reviewProgress = progress.clamp(0.0, 1.0).toDouble();
    });
  }

  List<TelemetryFrame> _analysisFramesFromSamples(List<_SpeedSample> samples) {
    return samples
        .map((sample) => TelemetryFrame(
              timestamp: sample.timestamp,
              trackProgress: sample.trackProgress,
              speedKmh: sample.speedKmh,
              gear: sample.gear ?? 0,
              rpm: sample.rpm ?? 0,
            ))
        .toList();
  }

  double _deltaAtProgress(List<TimeDeltaPoint> deltas, double progress) {
    if (deltas.isEmpty) {
      return 0.0;
    }
    if (deltas.length == 1) {
      return deltas.first.deltaSeconds;
    }
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    if (clamped <= deltas.first.progress) {
      return deltas.first.deltaSeconds;
    }
    if (clamped >= deltas.last.progress) {
      return deltas.last.deltaSeconds;
    }
    for (var i = 1; i < deltas.length; i++) {
      final prev = deltas[i - 1];
      final next = deltas[i];
      if (clamped <= next.progress) {
        final span = max(1e-6, next.progress - prev.progress);
        final ratio = (clamped - prev.progress) / span;
        return prev.deltaSeconds +
            (next.deltaSeconds - prev.deltaSeconds) * ratio;
      }
    }
    return deltas.last.deltaSeconds;
  }

  String _signedSeconds(double seconds) {
    final sign = seconds >= 0 ? '+' : '-';
    return '$sign${seconds.abs().toStringAsFixed(3)}s';
  }

  Widget _buildVoiceInterface(DashboardSnapshot snapshot) {
    final voice = _voice.state;
    final warningActive = _hasSafetyWarning(snapshot);
    final recording = voice.recording;
    final processing = voice.processing;
    final primaryLabel = recording
        ? 'Listening... release to submit'
        : (processing ? 'Processing...' : 'Hold to Talk');
    final buttonColor =
        recording ? _kDanger : (processing ? _kWarning : _kAccentAlt);

    return _HudCard(
      key: const Key('voice-console'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Voice Interface',
            subtitle: 'FLT-028~033 · PTT, STT buffer, TTS, playback, ducking',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  voice.status,
                  style: TextStyle(
                    color: warningActive && voice.duckingEnabled
                        ? _kWarning
                        : _kMuted,
                  ),
                ),
              ),
              if (processing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Listener(
            onPointerDown: (_) => _startPushToTalk(snapshot),
            onPointerUp: (_) => _stopPushToTalk(snapshot),
            onPointerCancel: (_) => _stopPushToTalk(snapshot),
            child: AnimatedContainer(
              key: const Key('voice-ptt-button'),
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                color: buttonColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(_kControlRadius),
                border: Border.all(color: buttonColor),
              ),
              child: Row(
                children: [
                  Icon(
                    recording ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: buttonColor,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      primaryLabel,
                      style: TextStyle(
                        color: buttonColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${(voice.bufferedBytes / 1024).toStringAsFixed(1)}KB',
                    style: const TextStyle(color: _kMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Audio Ducking', style: TextStyle(color: _kMuted)),
              const SizedBox(width: 8),
              Switch(
                key: const Key('voice-ducking-switch'),
                value: voice.duckingEnabled,
                onChanged: _voice.setDuckingEnabled,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warningActive
                      ? 'Safety warning active: AI audio suppressed'
                      : 'No safety warning',
                  style: TextStyle(
                    color: warningActive ? _kWarning : _kMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Verbosity', style: TextStyle(color: _kMuted)),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  key: const Key('voice-verbosity-slider'),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  value: _verbosityToSlider(voice.verbosity),
                  label: voiceVerbosityLabel(voice.verbosity),
                  onChanged: (value) {
                    _voice.setVerbosity(_sliderToVerbosity(value));
                  },
                ),
              ),
              Text(
                voiceVerbosityLabel(voice.verbosity),
                style: const TextStyle(color: _kAccentAlt),
              ),
            ],
          ),
          if (voice.lastTranscript.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'STT: ${voice.lastTranscript}',
              key: const Key('voice-last-transcript'),
              style: const TextStyle(color: _kMuted, fontSize: 12),
            ),
          ],
          if (voice.lastResponseText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'AI: ${voice.lastResponseText}',
              key: const Key('voice-last-response'),
              style: TextStyle(
                color: voice.lastResponseSuppressed ? _kWarning : _kAccent,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _maxSpeed(List<_SpeedSample> samples) {
    if (samples.isEmpty) return 0;
    return samples.map((e) => e.speedKmh).reduce(max);
  }

  double _displaySpeed(double speedKmh) {
    return speedForUnits(speedKmh, _dataPreferences.units);
  }

  String _speedUnitLabel() {
    return speedUnitLabel(_dataPreferences.units);
  }

  double _verbosityToSlider(VoiceVerbosity verbosity) {
    switch (verbosity) {
      case VoiceVerbosity.low:
        return 0;
      case VoiceVerbosity.medium:
        return 1;
      case VoiceVerbosity.high:
        return 2;
    }
  }

  VoiceVerbosity _sliderToVerbosity(double value) {
    final step = value.round().clamp(0, 2);
    switch (step) {
      case 0:
        return VoiceVerbosity.low;
      case 1:
        return VoiceVerbosity.medium;
      default:
        return VoiceVerbosity.high;
    }
  }

  List<SessionMetadata> _filteredSessions() {
    final filtered = applySessionFilters(
      _sessions,
      SessionBrowserFilters(
        date: _sessionDateFilter,
        track: _sessionTrackFilter,
        car: _sessionCarFilter,
        type: _sessionTypeFilter,
      ),
    );
    filtered.sort((a, b) {
      final aTs = sessionTimestamp(a)?.millisecondsSinceEpoch ?? 0;
      final bTs = sessionTimestamp(b)?.millisecondsSinceEpoch ?? 0;
      return bTs.compareTo(aTs);
    });
    return filtered;
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
    final cars = carFilterOptions(_sessions);
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
            onDelete: () => _deleteSessionCascade(session),
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
                  title: 'Session Archive Browser',
                  subtitle: 'FLT-052 · Date/track/car filters and replay',
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
                    color: _kAccentAlt.withValues(alpha: 0.85), fontSize: 12),
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
                child: DropdownButtonFormField<String>(
                  key: const Key('session-filter-car'),
                  isExpanded: true,
                  value: cars.contains(_sessionCarFilter)
                      ? _sessionCarFilter
                      : kAllCarsFilter,
                  items: cars
                      .map((car) => DropdownMenuItem(
                            value: car,
                            child:
                                Text(car == kAllCarsFilter ? 'All cars' : car),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _sessionCarFilter = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Car',
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
                  color: _kAccent.withValues(alpha: 0.9),
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
      key: const Key('session-control'),
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
                  color: _kDanger.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700),
            )
          else
            Text(
              'SYSTEM NOMINAL',
              style: TextStyle(
                  color: _kOk.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700),
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
    final background = engaged ? _kDanger : _kSurfaceRaised;
    final foreground = engaged ? Colors.white : _kAccent;

    return FloatingActionButton.extended(
      key: const Key('estop-control'),
      onPressed: () async {
        final next = !engaged;
        setState(() {
          estopEngaged = next;
        });
        await client.setEStop(next, reason: next ? 'UI' : 'UI clear');
      },
      backgroundColor: background,
      foregroundColor: foreground,
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
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kPanelRadius),
        border: Border.all(color: _kSurfaceGlow),
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
    final titleStyle =
        Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 0.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
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
        color: _kSurfaceRaised,
        borderRadius: BorderRadius.circular(_kPanelRadius),
        border: Border.all(color: glow.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: _kMuted,
                fontSize: 11,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'RobotoMono',
              letterSpacing: 0.3,
            ),
          ),
          if (unit.isNotEmpty)
            Text(unit,
                style: const TextStyle(
                  color: _kMuted,
                  fontSize: 11,
                  letterSpacing: 0.8,
                )),
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
        color: _kSurfaceRaised,
        borderRadius: BorderRadius.circular(_kControlRadius),
        border: Border.all(color: color.withValues(alpha: 0.55)),
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
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
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
          color: _kSurfaceRaised,
          borderRadius: BorderRadius.circular(_kPanelRadius),
          border: Border.all(color: color.withValues(alpha: 0.5)),
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
        color: _kSurfaceRaised,
        borderRadius: BorderRadius.circular(_kPanelRadius),
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
        color: _kSurfaceRaised,
        borderRadius: BorderRadius.circular(_kControlRadius),
        border: Border.all(color: color.withValues(alpha: 0.55)),
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
    required this.onDelete,
  });

  final SessionMetadata session;
  final bool active;
  final bool selected;
  final CloudSyncState syncState;
  final String typeLabel;
  final String startedAtLabel;
  final VoidCallback onSelect;
  final VoidCallback onReview;
  final VoidCallback onDelete;

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
        borderRadius: BorderRadius.circular(_kPanelRadius),
        onTap: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _kSurfaceRaised
                : (active
                    ? _kSurfaceRaised.withValues(alpha: 0.85)
                    : _kSurface.withValues(alpha: 0.95)),
            borderRadius: BorderRadius.circular(_kPanelRadius),
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
                      'Track: ${trackLabelForSession(session)} · Car: ${carLabelForSession(session)} · $typeLabel',
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
                      color:
                          active ? _kDanger : (selected ? _kAccent : _kMuted),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CloudSyncBadge(
                    key: Key('session-cloud-${session.sessionId}'),
                    state: syncState,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  OutlinedButton(
                    onPressed: onReview,
                    child: const Text('Open'),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    key: Key('session-delete-${session.sessionId}'),
                    onPressed: active ? null : onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalLegendDot extends StatelessWidget {
  const _SignalLegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _kMuted, fontSize: 12)),
      ],
    );
  }
}

class _SectorBreakdownRow extends StatelessWidget {
  const _SectorBreakdownRow({
    required this.sector,
    required this.baseline,
  });

  final SectorSplit sector;
  final double baseline;

  @override
  Widget build(BuildContext context) {
    final primaryRatio = (sector.primarySeconds / max(0.1, baseline))
        .clamp(0.05, 1.0)
        .toDouble();
    final refRatio = (sector.referenceSeconds / max(0.1, baseline))
        .clamp(0.05, 1.0)
        .toDouble();
    final deltaPositive = sector.deltaSeconds > 0;
    final deltaColor = deltaPositive ? _kDanger : _kOk;
    final deltaLabel =
        '${deltaPositive ? '+' : '-'}${sector.deltaSeconds.abs().toStringAsFixed(3)}s';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('S${sector.sector}',
                style: const TextStyle(
                    color: _kAccentAlt, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: _kSurfaceRaised,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: refRatio,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: primaryRatio,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: _kAccentAlt.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 72,
              child: Text(
                deltaLabel,
                textAlign: TextAlign.right,
                style:
                    TextStyle(color: deltaColor, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'Run ${sector.primarySeconds.toStringAsFixed(3)}s · Ref ${sector.referenceSeconds.toStringAsFixed(3)}s',
          style: const TextStyle(color: _kMuted, fontSize: 11),
        ),
      ],
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
        color: _kSurfaceRaised,
        borderRadius: BorderRadius.circular(_kPanelRadius),
        border: Border.all(color: fault.color.withValues(alpha: 0.6)),
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
        color: _kSurfaceRaised,
        borderRadius: BorderRadius.circular(_kControlRadius),
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
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, trackPaint);

    final metric =
        path.computeMetrics().isEmpty ? null : path.computeMetrics().first;
    if (metric != null) {
      final distance = metric.length * progress.clamp(0.0, 1.0).toDouble();
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          4,
          Paint()..color = dotColor,
        );
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

class _ChartSeries {
  const _ChartSeries({
    required this.id,
    required this.values,
    required this.color,
    required this.strokeWidth,
  });

  final String id;
  final List<double> values;
  final Color color;
  final double strokeWidth;
}

class _HiPerfLineChartPainter extends CustomPainter {
  _HiPerfLineChartPainter({
    required this.series,
    required this.startIndex,
    required this.endIndex,
    required this.accentColor,
    required this.cursorProgress,
    this.midline = false,
  });

  final List<_ChartSeries> series;
  final int startIndex;
  final int endIndex;
  final Color accentColor;
  final double cursorProgress;
  final bool midline;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final safeStart = max(0, startIndex);
    final safeEnd = max(safeStart, endIndex);
    final span = max(1, safeEnd - safeStart);

    final gridPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final dy = rect.top + rect.height * (i / 5);
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), gridPaint);
    }
    if (midline) {
      canvas.drawLine(
        Offset(rect.left, rect.center.dy),
        Offset(rect.right, rect.center.dy),
        Paint()
          ..color = Colors.white30
          ..strokeWidth = 1.2,
      );
    }

    for (final signal in series) {
      if (signal.values.length < 2) {
        continue;
      }
      final cappedEnd = min(safeEnd, signal.values.length - 1);
      final cappedStart = min(safeStart, cappedEnd);
      final visibleCount = max(2, cappedEnd - cappedStart + 1);
      final targetPoints = max(24, rect.width.floor());
      final stride = max(1, visibleCount ~/ targetPoints);
      final path = Path();
      var started = false;
      for (var i = cappedStart; i <= cappedEnd; i += stride) {
        final xNorm = (i - safeStart) / span;
        final yNorm = signal.values[i].clamp(0.0, 1.0).toDouble();
        final dx = rect.left + rect.width * xNorm.clamp(0.0, 1.0).toDouble();
        final dy = rect.bottom - rect.height * yNorm;
        if (!started) {
          path.moveTo(dx, dy);
          started = true;
        } else {
          path.lineTo(dx, dy);
        }
      }
      final lastIndex = cappedEnd;
      final lastXNorm = (lastIndex - safeStart) / span;
      final lastDy = rect.bottom -
          rect.height * signal.values[lastIndex].clamp(0.0, 1.0).toDouble();
      path.lineTo(rect.left + rect.width * lastXNorm.clamp(0.0, 1.0).toDouble(),
          lastDy);
      canvas.drawPath(
        path,
        Paint()
          ..color = signal.color
          ..strokeWidth = signal.strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    final cursorX =
        rect.left + rect.width * cursorProgress.clamp(0.0, 1.0).toDouble();
    canvas.drawLine(
      Offset(cursorX, rect.top),
      Offset(cursorX, rect.bottom),
      Paint()
        ..color = _kWarning.withValues(alpha: 0.75)
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _HiPerfLineChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.startIndex != startIndex ||
        oldDelegate.endIndex != endIndex ||
        oldDelegate.cursorProgress != cursorProgress ||
        oldDelegate.midline != midline ||
        oldDelegate.accentColor != accentColor;
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
      ..color = accentColor.withValues(alpha: 0.4)
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
            ..color = lineColor.withValues(alpha: 0.6)
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

    zonePaint.color = operatorClear
        ? _kOk.withValues(alpha: 0.4)
        : _kWarning.withValues(alpha: 0.4);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            operatorRect, const Radius.circular(_kControlRadius)),
        zonePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            operatorRect, const Radius.circular(_kControlRadius)),
        borderPaint);

    zonePaint.color = trackClear
        ? _kOk.withValues(alpha: 0.4)
        : _kDanger.withValues(alpha: 0.4);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            trackRect, const Radius.circular(_kControlRadius)),
        zonePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            trackRect, const Radius.circular(_kControlRadius)),
        borderPaint);

    zonePaint.color = estopReady
        ? _kOk.withValues(alpha: 0.4)
        : _kWarning.withValues(alpha: 0.4);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            estopRect, const Radius.circular(_kControlRadius)),
        zonePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            estopRect, const Radius.circular(_kControlRadius)),
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

class _LeaderboardEntry {
  const _LeaderboardEntry({
    required this.label,
    required this.tag,
    required this.speedKmh,
    required this.progress,
    required this.color,
  });

  final String label;
  final String tag;
  final double speedKmh;
  final double progress;
  final Color color;
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
