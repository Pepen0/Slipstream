// This is a generated file - do not edit.
//
// Generated from dashboard/v1/dashboard.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'dashboard.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'dashboard.pbenum.dart';

class FirmwareUpdateStatus extends $pb.GeneratedMessage {
  factory FirmwareUpdateStatus({
    FirmwareUpdateStage? stage,
    $core.double? progress,
    $core.String? message,
    $core.bool? active,
    $core.String? currentVersion,
    $core.String? targetVersion,
    $core.String? lastError,
    $core.bool? rollbackAvailable,
    $fixnum.Int64? startedAtNs,
    $fixnum.Int64? updatedAtNs,
    $core.int? mcuFwVersionRaw,
    $core.int? mcuFwBuild,
  }) {
    final result = create();
    if (stage != null) result.stage = stage;
    if (progress != null) result.progress = progress;
    if (message != null) result.message = message;
    if (active != null) result.active = active;
    if (currentVersion != null) result.currentVersion = currentVersion;
    if (targetVersion != null) result.targetVersion = targetVersion;
    if (lastError != null) result.lastError = lastError;
    if (rollbackAvailable != null) result.rollbackAvailable = rollbackAvailable;
    if (startedAtNs != null) result.startedAtNs = startedAtNs;
    if (updatedAtNs != null) result.updatedAtNs = updatedAtNs;
    if (mcuFwVersionRaw != null) result.mcuFwVersionRaw = mcuFwVersionRaw;
    if (mcuFwBuild != null) result.mcuFwBuild = mcuFwBuild;
    return result;
  }

  FirmwareUpdateStatus._();

  factory FirmwareUpdateStatus.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory FirmwareUpdateStatus.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FirmwareUpdateStatus', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..e<FirmwareUpdateStage>(1, _omitFieldNames ? '' : 'stage', $pb.PbFieldType.OE, defaultOrMaker: FirmwareUpdateStage.FIRMWARE_UPDATE_STAGE_IDLE, valueOf: FirmwareUpdateStage.valueOf, enumValues: FirmwareUpdateStage.values)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'progress', $pb.PbFieldType.OF)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aOB(4, _omitFieldNames ? '' : 'active')
    ..aOS(5, _omitFieldNames ? '' : 'currentVersion')
    ..aOS(6, _omitFieldNames ? '' : 'targetVersion')
    ..aOS(7, _omitFieldNames ? '' : 'lastError')
    ..aOB(8, _omitFieldNames ? '' : 'rollbackAvailable')
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'startedAtNs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(10, _omitFieldNames ? '' : 'updatedAtNs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'mcuFwVersionRaw', $pb.PbFieldType.OU3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'mcuFwBuild', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FirmwareUpdateStatus clone() => FirmwareUpdateStatus()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FirmwareUpdateStatus copyWith(void Function(FirmwareUpdateStatus) updates) => super.copyWith((message) => updates(message as FirmwareUpdateStatus)) as FirmwareUpdateStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FirmwareUpdateStatus create() => FirmwareUpdateStatus._();
  @$core.override
  FirmwareUpdateStatus createEmptyInstance() => create();
  static $pb.PbList<FirmwareUpdateStatus> createRepeated() => $pb.PbList<FirmwareUpdateStatus>();
  @$core.pragma('dart2js:noInline')
  static FirmwareUpdateStatus getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FirmwareUpdateStatus>(create);
  static FirmwareUpdateStatus? _defaultInstance;

  @$pb.TagNumber(1)
  FirmwareUpdateStage get stage => $_getN(0);
  @$pb.TagNumber(1)
  set stage(FirmwareUpdateStage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStage() => $_has(0);
  @$pb.TagNumber(1)
  void clearStage() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get progress => $_getN(1);
  @$pb.TagNumber(2)
  set progress($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProgress() => $_has(1);
  @$pb.TagNumber(2)
  void clearProgress() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get active => $_getBF(3);
  @$pb.TagNumber(4)
  set active($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasActive() => $_has(3);
  @$pb.TagNumber(4)
  void clearActive() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get currentVersion => $_getSZ(4);
  @$pb.TagNumber(5)
  set currentVersion($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCurrentVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearCurrentVersion() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get targetVersion => $_getSZ(5);
  @$pb.TagNumber(6)
  set targetVersion($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTargetVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearTargetVersion() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get lastError => $_getSZ(6);
  @$pb.TagNumber(7)
  set lastError($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLastError() => $_has(6);
  @$pb.TagNumber(7)
  void clearLastError() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get rollbackAvailable => $_getBF(7);
  @$pb.TagNumber(8)
  set rollbackAvailable($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRollbackAvailable() => $_has(7);
  @$pb.TagNumber(8)
  void clearRollbackAvailable() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get startedAtNs => $_getI64(8);
  @$pb.TagNumber(9)
  set startedAtNs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasStartedAtNs() => $_has(8);
  @$pb.TagNumber(9)
  void clearStartedAtNs() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get updatedAtNs => $_getI64(9);
  @$pb.TagNumber(10)
  set updatedAtNs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUpdatedAtNs() => $_has(9);
  @$pb.TagNumber(10)
  void clearUpdatedAtNs() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get mcuFwVersionRaw => $_getIZ(10);
  @$pb.TagNumber(11)
  set mcuFwVersionRaw($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasMcuFwVersionRaw() => $_has(10);
  @$pb.TagNumber(11)
  void clearMcuFwVersionRaw() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get mcuFwBuild => $_getIZ(11);
  @$pb.TagNumber(12)
  set mcuFwBuild($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasMcuFwBuild() => $_has(11);
  @$pb.TagNumber(12)
  void clearMcuFwBuild() => $_clearField(12);
}

class Status extends $pb.GeneratedMessage {
  factory Status({
    Status_State? state,
    $core.bool? estopActive,
    $core.bool? sessionActive,
    $core.String? activeProfile,
    $core.String? sessionId,
    $core.String? lastError,
    $fixnum.Int64? updatedAtNs,
    Status_CalibrationState? calibrationState,
    $core.double? calibrationProgress,
    $core.String? calibrationMessage,
    $core.int? calibrationAttempts,
    $fixnum.Int64? lastCalibrationAtNs,
    FirmwareUpdateStatus? firmwareUpdate,
    $core.String? mcuFirmwareVersion,
    $core.int? mcuFirmwareBuild,
    $core.int? mcuUpdateState,
    $core.int? mcuUpdateResult,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (estopActive != null) result.estopActive = estopActive;
    if (sessionActive != null) result.sessionActive = sessionActive;
    if (activeProfile != null) result.activeProfile = activeProfile;
    if (sessionId != null) result.sessionId = sessionId;
    if (lastError != null) result.lastError = lastError;
    if (updatedAtNs != null) result.updatedAtNs = updatedAtNs;
    if (calibrationState != null) result.calibrationState = calibrationState;
    if (calibrationProgress != null) result.calibrationProgress = calibrationProgress;
    if (calibrationMessage != null) result.calibrationMessage = calibrationMessage;
    if (calibrationAttempts != null) result.calibrationAttempts = calibrationAttempts;
    if (lastCalibrationAtNs != null) result.lastCalibrationAtNs = lastCalibrationAtNs;
    if (firmwareUpdate != null) result.firmwareUpdate = firmwareUpdate;
    if (mcuFirmwareVersion != null) result.mcuFirmwareVersion = mcuFirmwareVersion;
    if (mcuFirmwareBuild != null) result.mcuFirmwareBuild = mcuFirmwareBuild;
    if (mcuUpdateState != null) result.mcuUpdateState = mcuUpdateState;
    if (mcuUpdateResult != null) result.mcuUpdateResult = mcuUpdateResult;
    return result;
  }

  Status._();

  factory Status.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory Status.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Status', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..e<Status_State>(1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE, defaultOrMaker: Status_State.STATE_INIT, valueOf: Status_State.valueOf, enumValues: Status_State.values)
    ..aOB(2, _omitFieldNames ? '' : 'estopActive')
    ..aOB(3, _omitFieldNames ? '' : 'sessionActive')
    ..aOS(4, _omitFieldNames ? '' : 'activeProfile')
    ..aOS(5, _omitFieldNames ? '' : 'sessionId')
    ..aOS(6, _omitFieldNames ? '' : 'lastError')
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'updatedAtNs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<Status_CalibrationState>(8, _omitFieldNames ? '' : 'calibrationState', $pb.PbFieldType.OE, defaultOrMaker: Status_CalibrationState.CALIBRATION_UNKNOWN, valueOf: Status_CalibrationState.valueOf, enumValues: Status_CalibrationState.values)
    ..a<$core.double>(9, _omitFieldNames ? '' : 'calibrationProgress', $pb.PbFieldType.OF)
    ..aOS(10, _omitFieldNames ? '' : 'calibrationMessage')
    ..a<$core.int>(11, _omitFieldNames ? '' : 'calibrationAttempts', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(12, _omitFieldNames ? '' : 'lastCalibrationAtNs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<FirmwareUpdateStatus>(13, _omitFieldNames ? '' : 'firmwareUpdate', subBuilder: FirmwareUpdateStatus.create)
    ..aOS(14, _omitFieldNames ? '' : 'mcuFirmwareVersion')
    ..a<$core.int>(15, _omitFieldNames ? '' : 'mcuFirmwareBuild', $pb.PbFieldType.OU3)
    ..a<$core.int>(16, _omitFieldNames ? '' : 'mcuUpdateState', $pb.PbFieldType.OU3)
    ..a<$core.int>(17, _omitFieldNames ? '' : 'mcuUpdateResult', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Status clone() => Status()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Status copyWith(void Function(Status) updates) => super.copyWith((message) => updates(message as Status)) as Status;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Status create() => Status._();
  @$core.override
  Status createEmptyInstance() => create();
  static $pb.PbList<Status> createRepeated() => $pb.PbList<Status>();
  @$core.pragma('dart2js:noInline')
  static Status getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Status>(create);
  static Status? _defaultInstance;

  @$pb.TagNumber(1)
  Status_State get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(Status_State value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get estopActive => $_getBF(1);
  @$pb.TagNumber(2)
  set estopActive($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEstopActive() => $_has(1);
  @$pb.TagNumber(2)
  void clearEstopActive() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get sessionActive => $_getBF(2);
  @$pb.TagNumber(3)
  set sessionActive($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionActive() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionActive() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get activeProfile => $_getSZ(3);
  @$pb.TagNumber(4)
  set activeProfile($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasActiveProfile() => $_has(3);
  @$pb.TagNumber(4)
  void clearActiveProfile() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get sessionId => $_getSZ(4);
  @$pb.TagNumber(5)
  set sessionId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSessionId() => $_has(4);
  @$pb.TagNumber(5)
  void clearSessionId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get lastError => $_getSZ(5);
  @$pb.TagNumber(6)
  set lastError($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLastError() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastError() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get updatedAtNs => $_getI64(6);
  @$pb.TagNumber(7)
  set updatedAtNs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUpdatedAtNs() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdatedAtNs() => $_clearField(7);

  @$pb.TagNumber(8)
  Status_CalibrationState get calibrationState => $_getN(7);
  @$pb.TagNumber(8)
  set calibrationState(Status_CalibrationState value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasCalibrationState() => $_has(7);
  @$pb.TagNumber(8)
  void clearCalibrationState() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get calibrationProgress => $_getN(8);
  @$pb.TagNumber(9)
  set calibrationProgress($core.double value) => $_setFloat(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCalibrationProgress() => $_has(8);
  @$pb.TagNumber(9)
  void clearCalibrationProgress() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get calibrationMessage => $_getSZ(9);
  @$pb.TagNumber(10)
  set calibrationMessage($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCalibrationMessage() => $_has(9);
  @$pb.TagNumber(10)
  void clearCalibrationMessage() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get calibrationAttempts => $_getIZ(10);
  @$pb.TagNumber(11)
  set calibrationAttempts($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCalibrationAttempts() => $_has(10);
  @$pb.TagNumber(11)
  void clearCalibrationAttempts() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get lastCalibrationAtNs => $_getI64(11);
  @$pb.TagNumber(12)
  set lastCalibrationAtNs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasLastCalibrationAtNs() => $_has(11);
  @$pb.TagNumber(12)
  void clearLastCalibrationAtNs() => $_clearField(12);

  @$pb.TagNumber(13)
  FirmwareUpdateStatus get firmwareUpdate => $_getN(12);
  @$pb.TagNumber(13)
  set firmwareUpdate(FirmwareUpdateStatus value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasFirmwareUpdate() => $_has(12);
  @$pb.TagNumber(13)
  void clearFirmwareUpdate() => $_clearField(13);
  @$pb.TagNumber(13)
  FirmwareUpdateStatus ensureFirmwareUpdate() => $_ensure(12);

  @$pb.TagNumber(14)
  $core.String get mcuFirmwareVersion => $_getSZ(13);
  @$pb.TagNumber(14)
  set mcuFirmwareVersion($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasMcuFirmwareVersion() => $_has(13);
  @$pb.TagNumber(14)
  void clearMcuFirmwareVersion() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.int get mcuFirmwareBuild => $_getIZ(14);
  @$pb.TagNumber(15)
  set mcuFirmwareBuild($core.int value) => $_setUnsignedInt32(14, value);
  @$pb.TagNumber(15)
  $core.bool hasMcuFirmwareBuild() => $_has(14);
  @$pb.TagNumber(15)
  void clearMcuFirmwareBuild() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.int get mcuUpdateState => $_getIZ(15);
  @$pb.TagNumber(16)
  set mcuUpdateState($core.int value) => $_setUnsignedInt32(15, value);
  @$pb.TagNumber(16)
  $core.bool hasMcuUpdateState() => $_has(15);
  @$pb.TagNumber(16)
  void clearMcuUpdateState() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.int get mcuUpdateResult => $_getIZ(16);
  @$pb.TagNumber(17)
  set mcuUpdateResult($core.int value) => $_setUnsignedInt32(16, value);
  @$pb.TagNumber(17)
  $core.bool hasMcuUpdateResult() => $_has(16);
  @$pb.TagNumber(17)
  void clearMcuUpdateResult() => $_clearField(17);
}

class GetStatusRequest extends $pb.GeneratedMessage {
  factory GetStatusRequest() => create();

  GetStatusRequest._();

  factory GetStatusRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetStatusRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatusRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusRequest clone() => GetStatusRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusRequest copyWith(void Function(GetStatusRequest) updates) => super.copyWith((message) => updates(message as GetStatusRequest)) as GetStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatusRequest create() => GetStatusRequest._();
  @$core.override
  GetStatusRequest createEmptyInstance() => create();
  static $pb.PbList<GetStatusRequest> createRepeated() => $pb.PbList<GetStatusRequest>();
  @$core.pragma('dart2js:noInline')
  static GetStatusRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatusRequest>(create);
  static GetStatusRequest? _defaultInstance;
}

class GetStatusResponse extends $pb.GeneratedMessage {
  factory GetStatusResponse({
    Status? status,
  }) {
    final result = create();
    if (status != null) result.status = status;
    return result;
  }

  GetStatusResponse._();

  factory GetStatusResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetStatusResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatusResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOM<Status>(1, _omitFieldNames ? '' : 'status', subBuilder: Status.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusResponse clone() => GetStatusResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusResponse copyWith(void Function(GetStatusResponse) updates) => super.copyWith((message) => updates(message as GetStatusResponse)) as GetStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatusResponse create() => GetStatusResponse._();
  @$core.override
  GetStatusResponse createEmptyInstance() => create();
  static $pb.PbList<GetStatusResponse> createRepeated() => $pb.PbList<GetStatusResponse>();
  @$core.pragma('dart2js:noInline')
  static GetStatusResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatusResponse>(create);
  static GetStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Status get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(Status value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  Status ensureStatus() => $_ensure(0);
}

class CalibrateRequest extends $pb.GeneratedMessage {
  factory CalibrateRequest({
    $core.String? profileId,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  CalibrateRequest._();

  factory CalibrateRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CalibrateRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CalibrateRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateRequest clone() => CalibrateRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateRequest copyWith(void Function(CalibrateRequest) updates) => super.copyWith((message) => updates(message as CalibrateRequest)) as CalibrateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CalibrateRequest create() => CalibrateRequest._();
  @$core.override
  CalibrateRequest createEmptyInstance() => create();
  static $pb.PbList<CalibrateRequest> createRepeated() => $pb.PbList<CalibrateRequest>();
  @$core.pragma('dart2js:noInline')
  static CalibrateRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CalibrateRequest>(create);
  static CalibrateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);
}

class CalibrateResponse extends $pb.GeneratedMessage {
  factory CalibrateResponse({
    $core.bool? ok,
    $core.String? message,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    if (message != null) result.message = message;
    return result;
  }

  CalibrateResponse._();

  factory CalibrateResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CalibrateResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CalibrateResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateResponse clone() => CalibrateResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateResponse copyWith(void Function(CalibrateResponse) updates) => super.copyWith((message) => updates(message as CalibrateResponse)) as CalibrateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CalibrateResponse create() => CalibrateResponse._();
  @$core.override
  CalibrateResponse createEmptyInstance() => create();
  static $pb.PbList<CalibrateResponse> createRepeated() => $pb.PbList<CalibrateResponse>();
  @$core.pragma('dart2js:noInline')
  static CalibrateResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CalibrateResponse>(create);
  static CalibrateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class CancelCalibrationRequest extends $pb.GeneratedMessage {
  factory CancelCalibrationRequest() => create();

  CancelCalibrationRequest._();

  factory CancelCalibrationRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CancelCalibrationRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CancelCalibrationRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelCalibrationRequest clone() => CancelCalibrationRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelCalibrationRequest copyWith(void Function(CancelCalibrationRequest) updates) => super.copyWith((message) => updates(message as CancelCalibrationRequest)) as CancelCalibrationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelCalibrationRequest create() => CancelCalibrationRequest._();
  @$core.override
  CancelCalibrationRequest createEmptyInstance() => create();
  static $pb.PbList<CancelCalibrationRequest> createRepeated() => $pb.PbList<CancelCalibrationRequest>();
  @$core.pragma('dart2js:noInline')
  static CancelCalibrationRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CancelCalibrationRequest>(create);
  static CancelCalibrationRequest? _defaultInstance;
}

class CancelCalibrationResponse extends $pb.GeneratedMessage {
  factory CancelCalibrationResponse({
    $core.bool? ok,
    $core.String? message,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    if (message != null) result.message = message;
    return result;
  }

  CancelCalibrationResponse._();

  factory CancelCalibrationResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CancelCalibrationResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CancelCalibrationResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelCalibrationResponse clone() => CancelCalibrationResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelCalibrationResponse copyWith(void Function(CancelCalibrationResponse) updates) => super.copyWith((message) => updates(message as CancelCalibrationResponse)) as CancelCalibrationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelCalibrationResponse create() => CancelCalibrationResponse._();
  @$core.override
  CancelCalibrationResponse createEmptyInstance() => create();
  static $pb.PbList<CancelCalibrationResponse> createRepeated() => $pb.PbList<CancelCalibrationResponse>();
  @$core.pragma('dart2js:noInline')
  static CancelCalibrationResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CancelCalibrationResponse>(create);
  static CancelCalibrationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class SetProfileRequest extends $pb.GeneratedMessage {
  factory SetProfileRequest({
    $core.String? profileId,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  SetProfileRequest._();

  factory SetProfileRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory SetProfileRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetProfileRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProfileRequest clone() => SetProfileRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProfileRequest copyWith(void Function(SetProfileRequest) updates) => super.copyWith((message) => updates(message as SetProfileRequest)) as SetProfileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetProfileRequest create() => SetProfileRequest._();
  @$core.override
  SetProfileRequest createEmptyInstance() => create();
  static $pb.PbList<SetProfileRequest> createRepeated() => $pb.PbList<SetProfileRequest>();
  @$core.pragma('dart2js:noInline')
  static SetProfileRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetProfileRequest>(create);
  static SetProfileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);
}

class SetProfileResponse extends $pb.GeneratedMessage {
  factory SetProfileResponse({
    $core.bool? ok,
    $core.String? activeProfile,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    if (activeProfile != null) result.activeProfile = activeProfile;
    return result;
  }

  SetProfileResponse._();

  factory SetProfileResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory SetProfileResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetProfileResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'activeProfile')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProfileResponse clone() => SetProfileResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProfileResponse copyWith(void Function(SetProfileResponse) updates) => super.copyWith((message) => updates(message as SetProfileResponse)) as SetProfileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetProfileResponse create() => SetProfileResponse._();
  @$core.override
  SetProfileResponse createEmptyInstance() => create();
  static $pb.PbList<SetProfileResponse> createRepeated() => $pb.PbList<SetProfileResponse>();
  @$core.pragma('dart2js:noInline')
  static SetProfileResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetProfileResponse>(create);
  static SetProfileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get activeProfile => $_getSZ(1);
  @$pb.TagNumber(2)
  set activeProfile($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasActiveProfile() => $_has(1);
  @$pb.TagNumber(2)
  void clearActiveProfile() => $_clearField(2);
}

class EStopRequest extends $pb.GeneratedMessage {
  factory EStopRequest({
    $core.bool? engaged,
    $core.String? reason,
  }) {
    final result = create();
    if (engaged != null) result.engaged = engaged;
    if (reason != null) result.reason = reason;
    return result;
  }

  EStopRequest._();

  factory EStopRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory EStopRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EStopRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'engaged')
    ..aOS(2, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EStopRequest clone() => EStopRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EStopRequest copyWith(void Function(EStopRequest) updates) => super.copyWith((message) => updates(message as EStopRequest)) as EStopRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EStopRequest create() => EStopRequest._();
  @$core.override
  EStopRequest createEmptyInstance() => create();
  static $pb.PbList<EStopRequest> createRepeated() => $pb.PbList<EStopRequest>();
  @$core.pragma('dart2js:noInline')
  static EStopRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EStopRequest>(create);
  static EStopRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get engaged => $_getBF(0);
  @$pb.TagNumber(1)
  set engaged($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEngaged() => $_has(0);
  @$pb.TagNumber(1)
  void clearEngaged() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get reason => $_getSZ(1);
  @$pb.TagNumber(2)
  set reason($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);
}

class EStopResponse extends $pb.GeneratedMessage {
  factory EStopResponse({
    $core.bool? ok,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    return result;
  }

  EStopResponse._();

  factory EStopResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory EStopResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EStopResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EStopResponse clone() => EStopResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EStopResponse copyWith(void Function(EStopResponse) updates) => super.copyWith((message) => updates(message as EStopResponse)) as EStopResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EStopResponse create() => EStopResponse._();
  @$core.override
  EStopResponse createEmptyInstance() => create();
  static $pb.PbList<EStopResponse> createRepeated() => $pb.PbList<EStopResponse>();
  @$core.pragma('dart2js:noInline')
  static EStopResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EStopResponse>(create);
  static EStopResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);
}

class StartSessionRequest extends $pb.GeneratedMessage {
  factory StartSessionRequest({
    $core.String? sessionId,
    $core.String? track,
    $core.String? car,
    $fixnum.Int64? startTimeNs,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (track != null) result.track = track;
    if (car != null) result.car = car;
    if (startTimeNs != null) result.startTimeNs = startTimeNs;
    return result;
  }

  StartSessionRequest._();

  factory StartSessionRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory StartSessionRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartSessionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'track')
    ..aOS(3, _omitFieldNames ? '' : 'car')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'startTimeNs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartSessionRequest clone() => StartSessionRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartSessionRequest copyWith(void Function(StartSessionRequest) updates) => super.copyWith((message) => updates(message as StartSessionRequest)) as StartSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartSessionRequest create() => StartSessionRequest._();
  @$core.override
  StartSessionRequest createEmptyInstance() => create();
  static $pb.PbList<StartSessionRequest> createRepeated() => $pb.PbList<StartSessionRequest>();
  @$core.pragma('dart2js:noInline')
  static StartSessionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartSessionRequest>(create);
  static StartSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get track => $_getSZ(1);
  @$pb.TagNumber(2)
  set track($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTrack() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrack() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get car => $_getSZ(2);
  @$pb.TagNumber(3)
  set car($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCar() => $_has(2);
  @$pb.TagNumber(3)
  void clearCar() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get startTimeNs => $_getI64(3);
  @$pb.TagNumber(4)
  set startTimeNs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStartTimeNs() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartTimeNs() => $_clearField(4);
}

class StartSessionResponse extends $pb.GeneratedMessage {
  factory StartSessionResponse({
    $core.bool? ok,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    return result;
  }

  StartSessionResponse._();

  factory StartSessionResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory StartSessionResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartSessionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartSessionResponse clone() => StartSessionResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartSessionResponse copyWith(void Function(StartSessionResponse) updates) => super.copyWith((message) => updates(message as StartSessionResponse)) as StartSessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartSessionResponse create() => StartSessionResponse._();
  @$core.override
  StartSessionResponse createEmptyInstance() => create();
  static $pb.PbList<StartSessionResponse> createRepeated() => $pb.PbList<StartSessionResponse>();
  @$core.pragma('dart2js:noInline')
  static StartSessionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartSessionResponse>(create);
  static StartSessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);
}

class EndSessionRequest extends $pb.GeneratedMessage {
  factory EndSessionRequest({
    $core.String? sessionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  EndSessionRequest._();

  factory EndSessionRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory EndSessionRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EndSessionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndSessionRequest clone() => EndSessionRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndSessionRequest copyWith(void Function(EndSessionRequest) updates) => super.copyWith((message) => updates(message as EndSessionRequest)) as EndSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EndSessionRequest create() => EndSessionRequest._();
  @$core.override
  EndSessionRequest createEmptyInstance() => create();
  static $pb.PbList<EndSessionRequest> createRepeated() => $pb.PbList<EndSessionRequest>();
  @$core.pragma('dart2js:noInline')
  static EndSessionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EndSessionRequest>(create);
  static EndSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class EndSessionResponse extends $pb.GeneratedMessage {
  factory EndSessionResponse({
    $core.bool? ok,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    return result;
  }

  EndSessionResponse._();

  factory EndSessionResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory EndSessionResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EndSessionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndSessionResponse clone() => EndSessionResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndSessionResponse copyWith(void Function(EndSessionResponse) updates) => super.copyWith((message) => updates(message as EndSessionResponse)) as EndSessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EndSessionResponse create() => EndSessionResponse._();
  @$core.override
  EndSessionResponse createEmptyInstance() => create();
  static $pb.PbList<EndSessionResponse> createRepeated() => $pb.PbList<EndSessionResponse>();
  @$core.pragma('dart2js:noInline')
  static EndSessionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EndSessionResponse>(create);
  static EndSessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);
}

class SessionMetadata extends $pb.GeneratedMessage {
  factory SessionMetadata({
    $core.String? sessionId,
    $core.String? track,
    $core.String? car,
    $fixnum.Int64? startTimeNs,
    $fixnum.Int64? endTimeNs,
    $fixnum.Int64? durationMs,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (track != null) result.track = track;
    if (car != null) result.car = car;
    if (startTimeNs != null) result.startTimeNs = startTimeNs;
    if (endTimeNs != null) result.endTimeNs = endTimeNs;
    if (durationMs != null) result.durationMs = durationMs;
    return result;
  }

  SessionMetadata._();

  factory SessionMetadata.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory SessionMetadata.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SessionMetadata', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'track')
    ..aOS(3, _omitFieldNames ? '' : 'car')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'startTimeNs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'endTimeNs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'durationMs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionMetadata clone() => SessionMetadata()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionMetadata copyWith(void Function(SessionMetadata) updates) => super.copyWith((message) => updates(message as SessionMetadata)) as SessionMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionMetadata create() => SessionMetadata._();
  @$core.override
  SessionMetadata createEmptyInstance() => create();
  static $pb.PbList<SessionMetadata> createRepeated() => $pb.PbList<SessionMetadata>();
  @$core.pragma('dart2js:noInline')
  static SessionMetadata getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SessionMetadata>(create);
  static SessionMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get track => $_getSZ(1);
  @$pb.TagNumber(2)
  set track($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTrack() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrack() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get car => $_getSZ(2);
  @$pb.TagNumber(3)
  set car($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCar() => $_has(2);
  @$pb.TagNumber(3)
  void clearCar() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get startTimeNs => $_getI64(3);
  @$pb.TagNumber(4)
  set startTimeNs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStartTimeNs() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartTimeNs() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get endTimeNs => $_getI64(4);
  @$pb.TagNumber(5)
  set endTimeNs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEndTimeNs() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndTimeNs() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get durationMs => $_getI64(5);
  @$pb.TagNumber(6)
  set durationMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDurationMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearDurationMs() => $_clearField(6);
}

class ListSessionsRequest extends $pb.GeneratedMessage {
  factory ListSessionsRequest() => create();

  ListSessionsRequest._();

  factory ListSessionsRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory ListSessionsRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListSessionsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsRequest clone() => ListSessionsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsRequest copyWith(void Function(ListSessionsRequest) updates) => super.copyWith((message) => updates(message as ListSessionsRequest)) as ListSessionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSessionsRequest create() => ListSessionsRequest._();
  @$core.override
  ListSessionsRequest createEmptyInstance() => create();
  static $pb.PbList<ListSessionsRequest> createRepeated() => $pb.PbList<ListSessionsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListSessionsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListSessionsRequest>(create);
  static ListSessionsRequest? _defaultInstance;
}

class ListSessionsResponse extends $pb.GeneratedMessage {
  factory ListSessionsResponse({
    $core.Iterable<SessionMetadata>? sessions,
  }) {
    final result = create();
    if (sessions != null) result.sessions.addAll(sessions);
    return result;
  }

  ListSessionsResponse._();

  factory ListSessionsResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory ListSessionsResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListSessionsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..pc<SessionMetadata>(1, _omitFieldNames ? '' : 'sessions', $pb.PbFieldType.PM, subBuilder: SessionMetadata.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsResponse clone() => ListSessionsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsResponse copyWith(void Function(ListSessionsResponse) updates) => super.copyWith((message) => updates(message as ListSessionsResponse)) as ListSessionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSessionsResponse create() => ListSessionsResponse._();
  @$core.override
  ListSessionsResponse createEmptyInstance() => create();
  static $pb.PbList<ListSessionsResponse> createRepeated() => $pb.PbList<ListSessionsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListSessionsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListSessionsResponse>(create);
  static ListSessionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SessionMetadata> get sessions => $_getList(0);
}

class TelemetrySample extends $pb.GeneratedMessage {
  factory TelemetrySample({
    $fixnum.Int64? timestampNs,
    $core.double? pitchRad,
    $core.double? rollRad,
    $core.double? leftTargetM,
    $core.double? rightTargetM,
    $core.double? latencyMs,
    $core.double? speedKmh,
    $core.int? gear,
    $core.double? engineRpm,
    $core.double? trackProgress,
  }) {
    final result = create();
    if (timestampNs != null) result.timestampNs = timestampNs;
    if (pitchRad != null) result.pitchRad = pitchRad;
    if (rollRad != null) result.rollRad = rollRad;
    if (leftTargetM != null) result.leftTargetM = leftTargetM;
    if (rightTargetM != null) result.rightTargetM = rightTargetM;
    if (latencyMs != null) result.latencyMs = latencyMs;
    if (speedKmh != null) result.speedKmh = speedKmh;
    if (gear != null) result.gear = gear;
    if (engineRpm != null) result.engineRpm = engineRpm;
    if (trackProgress != null) result.trackProgress = trackProgress;
    return result;
  }

  TelemetrySample._();

  factory TelemetrySample.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory TelemetrySample.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TelemetrySample', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'timestampNs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'pitchRad', $pb.PbFieldType.OF)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'rollRad', $pb.PbFieldType.OF)
    ..a<$core.double>(4, _omitFieldNames ? '' : 'leftTargetM', $pb.PbFieldType.OF)
    ..a<$core.double>(5, _omitFieldNames ? '' : 'rightTargetM', $pb.PbFieldType.OF)
    ..a<$core.double>(6, _omitFieldNames ? '' : 'latencyMs', $pb.PbFieldType.OF)
    ..a<$core.double>(7, _omitFieldNames ? '' : 'speedKmh', $pb.PbFieldType.OF)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'gear', $pb.PbFieldType.O3)
    ..a<$core.double>(9, _omitFieldNames ? '' : 'engineRpm', $pb.PbFieldType.OF)
    ..a<$core.double>(10, _omitFieldNames ? '' : 'trackProgress', $pb.PbFieldType.OF)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TelemetrySample clone() => TelemetrySample()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TelemetrySample copyWith(void Function(TelemetrySample) updates) => super.copyWith((message) => updates(message as TelemetrySample)) as TelemetrySample;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TelemetrySample create() => TelemetrySample._();
  @$core.override
  TelemetrySample createEmptyInstance() => create();
  static $pb.PbList<TelemetrySample> createRepeated() => $pb.PbList<TelemetrySample>();
  @$core.pragma('dart2js:noInline')
  static TelemetrySample getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TelemetrySample>(create);
  static TelemetrySample? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestampNs => $_getI64(0);
  @$pb.TagNumber(1)
  set timestampNs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestampNs() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestampNs() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get pitchRad => $_getN(1);
  @$pb.TagNumber(2)
  set pitchRad($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPitchRad() => $_has(1);
  @$pb.TagNumber(2)
  void clearPitchRad() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get rollRad => $_getN(2);
  @$pb.TagNumber(3)
  set rollRad($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRollRad() => $_has(2);
  @$pb.TagNumber(3)
  void clearRollRad() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get leftTargetM => $_getN(3);
  @$pb.TagNumber(4)
  set leftTargetM($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLeftTargetM() => $_has(3);
  @$pb.TagNumber(4)
  void clearLeftTargetM() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get rightTargetM => $_getN(4);
  @$pb.TagNumber(5)
  set rightTargetM($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRightTargetM() => $_has(4);
  @$pb.TagNumber(5)
  void clearRightTargetM() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get latencyMs => $_getN(5);
  @$pb.TagNumber(6)
  set latencyMs($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLatencyMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearLatencyMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get speedKmh => $_getN(6);
  @$pb.TagNumber(7)
  set speedKmh($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSpeedKmh() => $_has(6);
  @$pb.TagNumber(7)
  void clearSpeedKmh() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get gear => $_getIZ(7);
  @$pb.TagNumber(8)
  set gear($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasGear() => $_has(7);
  @$pb.TagNumber(8)
  void clearGear() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get engineRpm => $_getN(8);
  @$pb.TagNumber(9)
  set engineRpm($core.double value) => $_setFloat(8, value);
  @$pb.TagNumber(9)
  $core.bool hasEngineRpm() => $_has(8);
  @$pb.TagNumber(9)
  void clearEngineRpm() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.double get trackProgress => $_getN(9);
  @$pb.TagNumber(10)
  set trackProgress($core.double value) => $_setFloat(9, value);
  @$pb.TagNumber(10)
  $core.bool hasTrackProgress() => $_has(9);
  @$pb.TagNumber(10)
  void clearTrackProgress() => $_clearField(10);
}

class TelemetryStreamRequest extends $pb.GeneratedMessage {
  factory TelemetryStreamRequest({
    $core.String? sessionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  TelemetryStreamRequest._();

  factory TelemetryStreamRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory TelemetryStreamRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TelemetryStreamRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TelemetryStreamRequest clone() => TelemetryStreamRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TelemetryStreamRequest copyWith(void Function(TelemetryStreamRequest) updates) => super.copyWith((message) => updates(message as TelemetryStreamRequest)) as TelemetryStreamRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TelemetryStreamRequest create() => TelemetryStreamRequest._();
  @$core.override
  TelemetryStreamRequest createEmptyInstance() => create();
  static $pb.PbList<TelemetryStreamRequest> createRepeated() => $pb.PbList<TelemetryStreamRequest>();
  @$core.pragma('dart2js:noInline')
  static TelemetryStreamRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TelemetryStreamRequest>(create);
  static TelemetryStreamRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class InputEventStreamRequest extends $pb.GeneratedMessage {
  factory InputEventStreamRequest() => create();

  InputEventStreamRequest._();

  factory InputEventStreamRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory InputEventStreamRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputEventStreamRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InputEventStreamRequest clone() => InputEventStreamRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InputEventStreamRequest copyWith(void Function(InputEventStreamRequest) updates) => super.copyWith((message) => updates(message as InputEventStreamRequest)) as InputEventStreamRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InputEventStreamRequest create() => InputEventStreamRequest._();
  @$core.override
  InputEventStreamRequest createEmptyInstance() => create();
  static $pb.PbList<InputEventStreamRequest> createRepeated() => $pb.PbList<InputEventStreamRequest>();
  @$core.pragma('dart2js:noInline')
  static InputEventStreamRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputEventStreamRequest>(create);
  static InputEventStreamRequest? _defaultInstance;
}

class InputEvent extends $pb.GeneratedMessage {
  factory InputEvent({
    $fixnum.Int64? sequence,
    InputEvent_Type? type,
    InputEvent_Source? source,
    $fixnum.Int64? receivedAtNs,
    $core.int? mcuUptimeMs,
    $core.bool? pressed,
  }) {
    final result = create();
    if (sequence != null) result.sequence = sequence;
    if (type != null) result.type = type;
    if (source != null) result.source = source;
    if (receivedAtNs != null) result.receivedAtNs = receivedAtNs;
    if (mcuUptimeMs != null) result.mcuUptimeMs = mcuUptimeMs;
    if (pressed != null) result.pressed = pressed;
    return result;
  }

  InputEvent._();

  factory InputEvent.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory InputEvent.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputEvent', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..e<InputEvent_Type>(2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: InputEvent_Type.INPUT_EVENT_TYPE_UNKNOWN, valueOf: InputEvent_Type.valueOf, enumValues: InputEvent_Type.values)
    ..e<InputEvent_Source>(3, _omitFieldNames ? '' : 'source', $pb.PbFieldType.OE, defaultOrMaker: InputEvent_Source.INPUT_EVENT_SOURCE_UNKNOWN, valueOf: InputEvent_Source.valueOf, enumValues: InputEvent_Source.values)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'receivedAtNs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'mcuUptimeMs', $pb.PbFieldType.OU3)
    ..aOB(6, _omitFieldNames ? '' : 'pressed')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InputEvent clone() => InputEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InputEvent copyWith(void Function(InputEvent) updates) => super.copyWith((message) => updates(message as InputEvent)) as InputEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InputEvent create() => InputEvent._();
  @$core.override
  InputEvent createEmptyInstance() => create();
  static $pb.PbList<InputEvent> createRepeated() => $pb.PbList<InputEvent>();
  @$core.pragma('dart2js:noInline')
  static InputEvent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputEvent>(create);
  static InputEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sequence => $_getI64(0);
  @$pb.TagNumber(1)
  set sequence($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSequence() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequence() => $_clearField(1);

  @$pb.TagNumber(2)
  InputEvent_Type get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(InputEvent_Type value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  InputEvent_Source get source => $_getN(2);
  @$pb.TagNumber(3)
  set source(InputEvent_Source value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get receivedAtNs => $_getI64(3);
  @$pb.TagNumber(4)
  set receivedAtNs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReceivedAtNs() => $_has(3);
  @$pb.TagNumber(4)
  void clearReceivedAtNs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get mcuUptimeMs => $_getIZ(4);
  @$pb.TagNumber(5)
  set mcuUptimeMs($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMcuUptimeMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearMcuUptimeMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get pressed => $_getBF(5);
  @$pb.TagNumber(6)
  set pressed($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPressed() => $_has(5);
  @$pb.TagNumber(6)
  void clearPressed() => $_clearField(6);
}

class GetSessionTelemetryRequest extends $pb.GeneratedMessage {
  factory GetSessionTelemetryRequest({
    $core.String? sessionId,
    $core.int? maxSamples,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (maxSamples != null) result.maxSamples = maxSamples;
    return result;
  }

  GetSessionTelemetryRequest._();

  factory GetSessionTelemetryRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetSessionTelemetryRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetSessionTelemetryRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'maxSamples', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionTelemetryRequest clone() => GetSessionTelemetryRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionTelemetryRequest copyWith(void Function(GetSessionTelemetryRequest) updates) => super.copyWith((message) => updates(message as GetSessionTelemetryRequest)) as GetSessionTelemetryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSessionTelemetryRequest create() => GetSessionTelemetryRequest._();
  @$core.override
  GetSessionTelemetryRequest createEmptyInstance() => create();
  static $pb.PbList<GetSessionTelemetryRequest> createRepeated() => $pb.PbList<GetSessionTelemetryRequest>();
  @$core.pragma('dart2js:noInline')
  static GetSessionTelemetryRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetSessionTelemetryRequest>(create);
  static GetSessionTelemetryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get maxSamples => $_getIZ(1);
  @$pb.TagNumber(2)
  set maxSamples($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxSamples() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxSamples() => $_clearField(2);
}

class GetSessionTelemetryResponse extends $pb.GeneratedMessage {
  factory GetSessionTelemetryResponse({
    $core.Iterable<TelemetrySample>? samples,
  }) {
    final result = create();
    if (samples != null) result.samples.addAll(samples);
    return result;
  }

  GetSessionTelemetryResponse._();

  factory GetSessionTelemetryResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetSessionTelemetryResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetSessionTelemetryResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..pc<TelemetrySample>(1, _omitFieldNames ? '' : 'samples', $pb.PbFieldType.PM, subBuilder: TelemetrySample.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionTelemetryResponse clone() => GetSessionTelemetryResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionTelemetryResponse copyWith(void Function(GetSessionTelemetryResponse) updates) => super.copyWith((message) => updates(message as GetSessionTelemetryResponse)) as GetSessionTelemetryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSessionTelemetryResponse create() => GetSessionTelemetryResponse._();
  @$core.override
  GetSessionTelemetryResponse createEmptyInstance() => create();
  static $pb.PbList<GetSessionTelemetryResponse> createRepeated() => $pb.PbList<GetSessionTelemetryResponse>();
  @$core.pragma('dart2js:noInline')
  static GetSessionTelemetryResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetSessionTelemetryResponse>(create);
  static GetSessionTelemetryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<TelemetrySample> get samples => $_getList(0);
}

class StartFirmwareUpdateRequest extends $pb.GeneratedMessage {
  factory StartFirmwareUpdateRequest({
    $core.String? artifactUri,
    $core.String? sha256,
    $core.String? targetVersion,
    $core.bool? allowRollback,
    $core.String? rollbackArtifactUri,
  }) {
    final result = create();
    if (artifactUri != null) result.artifactUri = artifactUri;
    if (sha256 != null) result.sha256 = sha256;
    if (targetVersion != null) result.targetVersion = targetVersion;
    if (allowRollback != null) result.allowRollback = allowRollback;
    if (rollbackArtifactUri != null) result.rollbackArtifactUri = rollbackArtifactUri;
    return result;
  }

  StartFirmwareUpdateRequest._();

  factory StartFirmwareUpdateRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory StartFirmwareUpdateRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartFirmwareUpdateRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'artifactUri')
    ..aOS(2, _omitFieldNames ? '' : 'sha256')
    ..aOS(3, _omitFieldNames ? '' : 'targetVersion')
    ..aOB(4, _omitFieldNames ? '' : 'allowRollback')
    ..aOS(5, _omitFieldNames ? '' : 'rollbackArtifactUri')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartFirmwareUpdateRequest clone() => StartFirmwareUpdateRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartFirmwareUpdateRequest copyWith(void Function(StartFirmwareUpdateRequest) updates) => super.copyWith((message) => updates(message as StartFirmwareUpdateRequest)) as StartFirmwareUpdateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartFirmwareUpdateRequest create() => StartFirmwareUpdateRequest._();
  @$core.override
  StartFirmwareUpdateRequest createEmptyInstance() => create();
  static $pb.PbList<StartFirmwareUpdateRequest> createRepeated() => $pb.PbList<StartFirmwareUpdateRequest>();
  @$core.pragma('dart2js:noInline')
  static StartFirmwareUpdateRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartFirmwareUpdateRequest>(create);
  static StartFirmwareUpdateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get artifactUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set artifactUri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasArtifactUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearArtifactUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sha256 => $_getSZ(1);
  @$pb.TagNumber(2)
  set sha256($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSha256() => $_has(1);
  @$pb.TagNumber(2)
  void clearSha256() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get targetVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set targetVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get allowRollback => $_getBF(3);
  @$pb.TagNumber(4)
  set allowRollback($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAllowRollback() => $_has(3);
  @$pb.TagNumber(4)
  void clearAllowRollback() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get rollbackArtifactUri => $_getSZ(4);
  @$pb.TagNumber(5)
  set rollbackArtifactUri($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRollbackArtifactUri() => $_has(4);
  @$pb.TagNumber(5)
  void clearRollbackArtifactUri() => $_clearField(5);
}

class StartFirmwareUpdateResponse extends $pb.GeneratedMessage {
  factory StartFirmwareUpdateResponse({
    $core.bool? ok,
    $core.String? message,
    FirmwareUpdateStatus? status,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    if (message != null) result.message = message;
    if (status != null) result.status = status;
    return result;
  }

  StartFirmwareUpdateResponse._();

  factory StartFirmwareUpdateResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory StartFirmwareUpdateResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartFirmwareUpdateResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<FirmwareUpdateStatus>(3, _omitFieldNames ? '' : 'status', subBuilder: FirmwareUpdateStatus.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartFirmwareUpdateResponse clone() => StartFirmwareUpdateResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartFirmwareUpdateResponse copyWith(void Function(StartFirmwareUpdateResponse) updates) => super.copyWith((message) => updates(message as StartFirmwareUpdateResponse)) as StartFirmwareUpdateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartFirmwareUpdateResponse create() => StartFirmwareUpdateResponse._();
  @$core.override
  StartFirmwareUpdateResponse createEmptyInstance() => create();
  static $pb.PbList<StartFirmwareUpdateResponse> createRepeated() => $pb.PbList<StartFirmwareUpdateResponse>();
  @$core.pragma('dart2js:noInline')
  static StartFirmwareUpdateResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartFirmwareUpdateResponse>(create);
  static StartFirmwareUpdateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  FirmwareUpdateStatus get status => $_getN(2);
  @$pb.TagNumber(3)
  set status(FirmwareUpdateStatus value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);
  @$pb.TagNumber(3)
  FirmwareUpdateStatus ensureStatus() => $_ensure(2);
}

class CancelFirmwareUpdateRequest extends $pb.GeneratedMessage {
  factory CancelFirmwareUpdateRequest() => create();

  CancelFirmwareUpdateRequest._();

  factory CancelFirmwareUpdateRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CancelFirmwareUpdateRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CancelFirmwareUpdateRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelFirmwareUpdateRequest clone() => CancelFirmwareUpdateRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelFirmwareUpdateRequest copyWith(void Function(CancelFirmwareUpdateRequest) updates) => super.copyWith((message) => updates(message as CancelFirmwareUpdateRequest)) as CancelFirmwareUpdateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelFirmwareUpdateRequest create() => CancelFirmwareUpdateRequest._();
  @$core.override
  CancelFirmwareUpdateRequest createEmptyInstance() => create();
  static $pb.PbList<CancelFirmwareUpdateRequest> createRepeated() => $pb.PbList<CancelFirmwareUpdateRequest>();
  @$core.pragma('dart2js:noInline')
  static CancelFirmwareUpdateRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CancelFirmwareUpdateRequest>(create);
  static CancelFirmwareUpdateRequest? _defaultInstance;
}

class CancelFirmwareUpdateResponse extends $pb.GeneratedMessage {
  factory CancelFirmwareUpdateResponse({
    $core.bool? ok,
    $core.String? message,
    FirmwareUpdateStatus? status,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    if (message != null) result.message = message;
    if (status != null) result.status = status;
    return result;
  }

  CancelFirmwareUpdateResponse._();

  factory CancelFirmwareUpdateResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CancelFirmwareUpdateResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CancelFirmwareUpdateResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<FirmwareUpdateStatus>(3, _omitFieldNames ? '' : 'status', subBuilder: FirmwareUpdateStatus.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelFirmwareUpdateResponse clone() => CancelFirmwareUpdateResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelFirmwareUpdateResponse copyWith(void Function(CancelFirmwareUpdateResponse) updates) => super.copyWith((message) => updates(message as CancelFirmwareUpdateResponse)) as CancelFirmwareUpdateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelFirmwareUpdateResponse create() => CancelFirmwareUpdateResponse._();
  @$core.override
  CancelFirmwareUpdateResponse createEmptyInstance() => create();
  static $pb.PbList<CancelFirmwareUpdateResponse> createRepeated() => $pb.PbList<CancelFirmwareUpdateResponse>();
  @$core.pragma('dart2js:noInline')
  static CancelFirmwareUpdateResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CancelFirmwareUpdateResponse>(create);
  static CancelFirmwareUpdateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  FirmwareUpdateStatus get status => $_getN(2);
  @$pb.TagNumber(3)
  set status(FirmwareUpdateStatus value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);
  @$pb.TagNumber(3)
  FirmwareUpdateStatus ensureStatus() => $_ensure(2);
}

class CheckFirmwareVersionRequest extends $pb.GeneratedMessage {
  factory CheckFirmwareVersionRequest({
    $core.String? latestVersion,
  }) {
    final result = create();
    if (latestVersion != null) result.latestVersion = latestVersion;
    return result;
  }

  CheckFirmwareVersionRequest._();

  factory CheckFirmwareVersionRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CheckFirmwareVersionRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CheckFirmwareVersionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'latestVersion')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckFirmwareVersionRequest clone() => CheckFirmwareVersionRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckFirmwareVersionRequest copyWith(void Function(CheckFirmwareVersionRequest) updates) => super.copyWith((message) => updates(message as CheckFirmwareVersionRequest)) as CheckFirmwareVersionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckFirmwareVersionRequest create() => CheckFirmwareVersionRequest._();
  @$core.override
  CheckFirmwareVersionRequest createEmptyInstance() => create();
  static $pb.PbList<CheckFirmwareVersionRequest> createRepeated() => $pb.PbList<CheckFirmwareVersionRequest>();
  @$core.pragma('dart2js:noInline')
  static CheckFirmwareVersionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckFirmwareVersionRequest>(create);
  static CheckFirmwareVersionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get latestVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set latestVersion($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLatestVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearLatestVersion() => $_clearField(1);
}

class CheckFirmwareVersionResponse extends $pb.GeneratedMessage {
  factory CheckFirmwareVersionResponse({
    $core.bool? ok,
    $core.bool? updateAvailable,
    $core.String? currentVersion,
    $core.String? latestVersion,
    $core.String? message,
    $core.bool? mcuConnected,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    if (updateAvailable != null) result.updateAvailable = updateAvailable;
    if (currentVersion != null) result.currentVersion = currentVersion;
    if (latestVersion != null) result.latestVersion = latestVersion;
    if (message != null) result.message = message;
    if (mcuConnected != null) result.mcuConnected = mcuConnected;
    return result;
  }

  CheckFirmwareVersionResponse._();

  factory CheckFirmwareVersionResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory CheckFirmwareVersionResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CheckFirmwareVersionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOB(2, _omitFieldNames ? '' : 'updateAvailable')
    ..aOS(3, _omitFieldNames ? '' : 'currentVersion')
    ..aOS(4, _omitFieldNames ? '' : 'latestVersion')
    ..aOS(5, _omitFieldNames ? '' : 'message')
    ..aOB(6, _omitFieldNames ? '' : 'mcuConnected')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckFirmwareVersionResponse clone() => CheckFirmwareVersionResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckFirmwareVersionResponse copyWith(void Function(CheckFirmwareVersionResponse) updates) => super.copyWith((message) => updates(message as CheckFirmwareVersionResponse)) as CheckFirmwareVersionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckFirmwareVersionResponse create() => CheckFirmwareVersionResponse._();
  @$core.override
  CheckFirmwareVersionResponse createEmptyInstance() => create();
  static $pb.PbList<CheckFirmwareVersionResponse> createRepeated() => $pb.PbList<CheckFirmwareVersionResponse>();
  @$core.pragma('dart2js:noInline')
  static CheckFirmwareVersionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckFirmwareVersionResponse>(create);
  static CheckFirmwareVersionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get updateAvailable => $_getBF(1);
  @$pb.TagNumber(2)
  set updateAvailable($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUpdateAvailable() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdateAvailable() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get currentVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set currentVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrentVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrentVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get latestVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set latestVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLatestVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearLatestVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get message => $_getSZ(4);
  @$pb.TagNumber(5)
  set message($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMessage() => $_has(4);
  @$pb.TagNumber(5)
  void clearMessage() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get mcuConnected => $_getBF(5);
  @$pb.TagNumber(6)
  set mcuConnected($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMcuConnected() => $_has(5);
  @$pb.TagNumber(6)
  void clearMcuConnected() => $_clearField(6);
}


const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
