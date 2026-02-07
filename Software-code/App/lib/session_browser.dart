import 'gen/dashboard/v1/dashboard.pb.dart';

const String kAllTracksFilter = '__all_tracks__';
const String kUnknownTrackLabel = 'Unknown track';
const String kAllCarsFilter = '__all_cars__';
const String kUnknownCarLabel = 'Unknown car';

enum SessionDateFilter {
  all,
  today,
  last7Days,
  last30Days,
}

enum SessionTypeFilter {
  all,
  race,
  qualifying,
  practice,
  test,
  unknown,
}

enum CloudSyncState {
  synced,
  syncing,
  pending,
  offline,
}

class SessionBrowserFilters {
  const SessionBrowserFilters({
    this.date = SessionDateFilter.all,
    this.track = kAllTracksFilter,
    this.car = kAllCarsFilter,
    this.type = SessionTypeFilter.all,
  });

  final SessionDateFilter date;
  final String track;
  final String car;
  final SessionTypeFilter type;
}

List<SessionMetadata> applySessionFilters(
  List<SessionMetadata> sessions,
  SessionBrowserFilters filters, {
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  return sessions.where((session) {
    if (!_matchesDateFilter(session, filters.date, effectiveNow)) {
      return false;
    }

    final track = trackLabelForSession(session);
    if (filters.track != kAllTracksFilter && track != filters.track) {
      return false;
    }

    final car = carLabelForSession(session);
    if (filters.car != kAllCarsFilter && car != filters.car) {
      return false;
    }

    final sessionType = classifySessionType(session);
    if (filters.type != SessionTypeFilter.all && sessionType != filters.type) {
      return false;
    }

    return true;
  }).toList();
}

List<String> trackFilterOptions(List<SessionMetadata> sessions) {
  final tracks = <String>{};
  for (final session in sessions) {
    tracks.add(trackLabelForSession(session));
  }
  final sortedTracks = tracks.toList()..sort();
  return <String>[kAllTracksFilter, ...sortedTracks];
}

List<String> carFilterOptions(List<SessionMetadata> sessions) {
  final cars = <String>{};
  for (final session in sessions) {
    cars.add(carLabelForSession(session));
  }
  final sortedCars = cars.toList()..sort();
  return <String>[kAllCarsFilter, ...sortedCars];
}

String trackLabelForSession(SessionMetadata session) {
  final track = session.track.trim();
  if (track.isEmpty) {
    return kUnknownTrackLabel;
  }
  return track;
}

String carLabelForSession(SessionMetadata session) {
  final car = session.car.trim();
  if (car.isEmpty) {
    return kUnknownCarLabel;
  }
  return car;
}

SessionTypeFilter classifySessionType(SessionMetadata session) {
  final text = '${session.sessionId} ${session.car}'.toLowerCase();
  if (text.contains('qual')) {
    return SessionTypeFilter.qualifying;
  }
  if (text.contains('practice') ||
      text.contains('prac') ||
      text.contains('fp')) {
    return SessionTypeFilter.practice;
  }
  if (text.contains('test') ||
      text.contains('benchmark') ||
      text.contains('warmup')) {
    return SessionTypeFilter.test;
  }
  if (text.contains('race') || text.contains('sprint')) {
    return SessionTypeFilter.race;
  }
  return SessionTypeFilter.unknown;
}

String sessionTypeLabel(SessionTypeFilter type) {
  switch (type) {
    case SessionTypeFilter.all:
      return 'All types';
    case SessionTypeFilter.race:
      return 'Race';
    case SessionTypeFilter.qualifying:
      return 'Qualifying';
    case SessionTypeFilter.practice:
      return 'Practice';
    case SessionTypeFilter.test:
      return 'Test';
    case SessionTypeFilter.unknown:
      return 'Unknown';
  }
}

CloudSyncState inferCloudSyncState(
  SessionMetadata session, {
  required bool connected,
  DateTime? now,
}) {
  if (!connected) {
    return CloudSyncState.offline;
  }
  if (session.endTimeNs.toInt() <= 0) {
    return CloudSyncState.pending;
  }
  final effectiveNow = now ?? DateTime.now();
  final endTime = _sessionEndTime(session);
  if (endTime == null) {
    return CloudSyncState.pending;
  }
  if (effectiveNow.difference(endTime).inSeconds < 45) {
    return CloudSyncState.syncing;
  }
  return CloudSyncState.synced;
}

String cloudSyncLabel(CloudSyncState state) {
  switch (state) {
    case CloudSyncState.synced:
      return 'Cloud Synced';
    case CloudSyncState.syncing:
      return 'Syncing';
    case CloudSyncState.pending:
      return 'Pending';
    case CloudSyncState.offline:
      return 'Offline';
  }
}

DateTime? sessionTimestamp(SessionMetadata session) {
  final startNs = session.startTimeNs.toInt();
  if (startNs > 0) {
    return DateTime.fromMicrosecondsSinceEpoch(startNs ~/ 1000).toLocal();
  }
  final endNs = session.endTimeNs.toInt();
  if (endNs > 0) {
    return DateTime.fromMicrosecondsSinceEpoch(endNs ~/ 1000).toLocal();
  }
  return null;
}

DateTime? _sessionEndTime(SessionMetadata session) {
  final endNs = session.endTimeNs.toInt();
  if (endNs <= 0) {
    return null;
  }
  return DateTime.fromMicrosecondsSinceEpoch(endNs ~/ 1000).toLocal();
}

bool _matchesDateFilter(
  SessionMetadata session,
  SessionDateFilter filter,
  DateTime now,
) {
  if (filter == SessionDateFilter.all) {
    return true;
  }
  final timestamp = sessionTimestamp(session);
  if (timestamp == null) {
    return false;
  }

  final nowLocal = now.toLocal();
  final startToday = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

  switch (filter) {
    case SessionDateFilter.all:
      return true;
    case SessionDateFilter.today:
      return !timestamp.isBefore(startToday);
    case SessionDateFilter.last7Days:
      final startWindow = startToday.subtract(const Duration(days: 6));
      return !timestamp.isBefore(startWindow);
    case SessionDateFilter.last30Days:
      final startWindow = startToday.subtract(const Duration(days: 29));
      return !timestamp.isBefore(startWindow);
  }
}
