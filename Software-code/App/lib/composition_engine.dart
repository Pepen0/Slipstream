import 'package:flutter/foundation.dart';

enum BroadcastRacePhase {
  preRace,
  live,
  postRace,
  summary,
}

String broadcastRacePhaseLabel(BroadcastRacePhase phase) {
  switch (phase) {
    case BroadcastRacePhase.preRace:
      return 'Pre-Race';
    case BroadcastRacePhase.live:
      return 'Live';
    case BroadcastRacePhase.postRace:
      return 'Post-Race';
    case BroadcastRacePhase.summary:
      return 'Summary';
  }
}

enum BroadcastWidgetSlot {
  overviewStrip,
  reviewBanner,
  telemetryHud,
  trackMap,
  speedGraph,
  sessionBrowser,
  voicePanel,
  sessionControl,
  leaderboard,
  summaryCard,
}

@immutable
class BroadcastPhaseUpdate {
  const BroadcastPhaseUpdate({
    required this.phase,
    required this.phaseChanged,
    required this.changedAt,
    required this.summaryAutoTriggered,
  });

  final BroadcastRacePhase phase;
  final bool phaseChanged;
  final DateTime changedAt;
  final bool summaryAutoTriggered;
}

class BroadcastCompositionEngine {
  BroadcastCompositionEngine({
    this.summaryStopSpeedKmh = 3.0,
    this.summaryStopDuration = const Duration(seconds: 4),
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        _phaseChangedAt = (now ?? DateTime.now)();

  final double summaryStopSpeedKmh;
  final Duration summaryStopDuration;
  final DateTime Function() _now;

  BroadcastRacePhase _phase = BroadcastRacePhase.preRace;
  DateTime _phaseChangedAt;
  DateTime? _stoppedSince;
  bool _seenLiveSession = false;

  BroadcastRacePhase get phase => _phase;
  DateTime get phaseChangedAt => _phaseChangedAt;

  BroadcastPhaseUpdate update({
    required bool sessionActive,
    required double speedKmh,
    DateTime? now,
  }) {
    final timestamp = now ?? _now();
    var phaseChanged = false;
    var summaryAutoTriggered = false;

    if (sessionActive) {
      _seenLiveSession = true;
      _stoppedSince = null;
      phaseChanged = _setPhase(BroadcastRacePhase.live, timestamp);
      return BroadcastPhaseUpdate(
        phase: _phase,
        phaseChanged: phaseChanged,
        changedAt: _phaseChangedAt,
        summaryAutoTriggered: false,
      );
    }

    if (!_seenLiveSession) {
      _stoppedSince = null;
      phaseChanged = _setPhase(BroadcastRacePhase.preRace, timestamp);
      return BroadcastPhaseUpdate(
        phase: _phase,
        phaseChanged: phaseChanged,
        changedAt: _phaseChangedAt,
        summaryAutoTriggered: false,
      );
    }

    if (_phase == BroadcastRacePhase.live ||
        _phase == BroadcastRacePhase.preRace) {
      phaseChanged =
          _setPhase(BroadcastRacePhase.postRace, timestamp) || phaseChanged;
    }

    final speed = speedKmh.abs();
    if (speed <= summaryStopSpeedKmh) {
      _stoppedSince ??= timestamp;
      if (timestamp.difference(_stoppedSince!) >= summaryStopDuration) {
        summaryAutoTriggered = _phase != BroadcastRacePhase.summary;
        phaseChanged =
            _setPhase(BroadcastRacePhase.summary, timestamp) || phaseChanged;
      }
    } else {
      _stoppedSince = null;
      if (_phase == BroadcastRacePhase.summary) {
        phaseChanged =
            _setPhase(BroadcastRacePhase.postRace, timestamp) || phaseChanged;
      }
    }

    return BroadcastPhaseUpdate(
      phase: _phase,
      phaseChanged: phaseChanged,
      changedAt: _phaseChangedAt,
      summaryAutoTriggered: summaryAutoTriggered,
    );
  }

  bool shouldShow(BroadcastWidgetSlot slot, {BroadcastRacePhase? phase}) {
    final target = phase ?? _phase;
    switch (target) {
      case BroadcastRacePhase.preRace:
        return switch (slot) {
          BroadcastWidgetSlot.overviewStrip => true,
          BroadcastWidgetSlot.reviewBanner => true,
          BroadcastWidgetSlot.telemetryHud => true,
          BroadcastWidgetSlot.trackMap => true,
          BroadcastWidgetSlot.speedGraph => false,
          BroadcastWidgetSlot.sessionBrowser => true,
          BroadcastWidgetSlot.voicePanel => false,
          BroadcastWidgetSlot.sessionControl => true,
          BroadcastWidgetSlot.leaderboard => false,
          BroadcastWidgetSlot.summaryCard => false,
        };
      case BroadcastRacePhase.live:
        return switch (slot) {
          BroadcastWidgetSlot.overviewStrip => true,
          BroadcastWidgetSlot.reviewBanner => true,
          BroadcastWidgetSlot.telemetryHud => true,
          BroadcastWidgetSlot.trackMap => true,
          BroadcastWidgetSlot.speedGraph => true,
          BroadcastWidgetSlot.sessionBrowser => true,
          BroadcastWidgetSlot.voicePanel => true,
          BroadcastWidgetSlot.sessionControl => true,
          BroadcastWidgetSlot.leaderboard => true,
          BroadcastWidgetSlot.summaryCard => false,
        };
      case BroadcastRacePhase.postRace:
        return switch (slot) {
          BroadcastWidgetSlot.overviewStrip => true,
          BroadcastWidgetSlot.reviewBanner => true,
          BroadcastWidgetSlot.telemetryHud => false,
          BroadcastWidgetSlot.trackMap => true,
          BroadcastWidgetSlot.speedGraph => true,
          BroadcastWidgetSlot.sessionBrowser => true,
          BroadcastWidgetSlot.voicePanel => false,
          BroadcastWidgetSlot.sessionControl => true,
          BroadcastWidgetSlot.leaderboard => true,
          BroadcastWidgetSlot.summaryCard => false,
        };
      case BroadcastRacePhase.summary:
        return switch (slot) {
          BroadcastWidgetSlot.overviewStrip => true,
          BroadcastWidgetSlot.reviewBanner => true,
          BroadcastWidgetSlot.telemetryHud => false,
          BroadcastWidgetSlot.trackMap => false,
          BroadcastWidgetSlot.speedGraph => true,
          BroadcastWidgetSlot.sessionBrowser => true,
          BroadcastWidgetSlot.voicePanel => false,
          BroadcastWidgetSlot.sessionControl => true,
          BroadcastWidgetSlot.leaderboard => true,
          BroadcastWidgetSlot.summaryCard => true,
        };
    }
  }

  bool _setPhase(BroadcastRacePhase next, DateTime timestamp) {
    if (_phase == next) {
      return false;
    }
    _phase = next;
    _phaseChangedAt = timestamp;
    return true;
  }
}
