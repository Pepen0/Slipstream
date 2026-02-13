// This is a generated file - do not edit.
//
// Generated from dashboard/v1/dashboard.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use firmwareUpdateStageDescriptor instead')
const FirmwareUpdateStage$json = {
  '1': 'FirmwareUpdateStage',
  '2': [
    {'1': 'FIRMWARE_UPDATE_STAGE_IDLE', '2': 0},
    {'1': 'FIRMWARE_UPDATE_STAGE_DOWNLOADING', '2': 1},
    {'1': 'FIRMWARE_UPDATE_STAGE_VERIFYING', '2': 2},
    {'1': 'FIRMWARE_UPDATE_STAGE_REQUESTING_DFU', '2': 3},
    {'1': 'FIRMWARE_UPDATE_STAGE_FLASHING', '2': 4},
    {'1': 'FIRMWARE_UPDATE_STAGE_VERIFYING_VERSION', '2': 5},
    {'1': 'FIRMWARE_UPDATE_STAGE_COMPLETED', '2': 6},
    {'1': 'FIRMWARE_UPDATE_STAGE_FAILED', '2': 7},
    {'1': 'FIRMWARE_UPDATE_STAGE_ROLLING_BACK', '2': 8},
    {'1': 'FIRMWARE_UPDATE_STAGE_ROLLED_BACK', '2': 9},
    {'1': 'FIRMWARE_UPDATE_STAGE_CANCELED', '2': 10},
  ],
};

/// Descriptor for `FirmwareUpdateStage`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List firmwareUpdateStageDescriptor = $convert.base64Decode(
    'ChNGaXJtd2FyZVVwZGF0ZVN0YWdlEh4KGkZJUk1XQVJFX1VQREFURV9TVEFHRV9JRExFEAASJQ'
    'ohRklSTVdBUkVfVVBEQVRFX1NUQUdFX0RPV05MT0FESU5HEAESIwofRklSTVdBUkVfVVBEQVRF'
    'X1NUQUdFX1ZFUklGWUlORxACEigKJEZJUk1XQVJFX1VQREFURV9TVEFHRV9SRVFVRVNUSU5HX0'
    'RGVRADEiIKHkZJUk1XQVJFX1VQREFURV9TVEFHRV9GTEFTSElORxAEEisKJ0ZJUk1XQVJFX1VQ'
    'REFURV9TVEFHRV9WRVJJRllJTkdfVkVSU0lPThAFEiMKH0ZJUk1XQVJFX1VQREFURV9TVEFHRV'
    '9DT01QTEVURUQQBhIgChxGSVJNV0FSRV9VUERBVEVfU1RBR0VfRkFJTEVEEAcSJgoiRklSTVdB'
    'UkVfVVBEQVRFX1NUQUdFX1JPTExJTkdfQkFDSxAIEiUKIUZJUk1XQVJFX1VQREFURV9TVEFHRV'
    '9ST0xMRURfQkFDSxAJEiIKHkZJUk1XQVJFX1VQREFURV9TVEFHRV9DQU5DRUxFRBAK');

@$core.Deprecated('Use firmwareUpdateStatusDescriptor instead')
const FirmwareUpdateStatus$json = {
  '1': 'FirmwareUpdateStatus',
  '2': [
    {'1': 'stage', '3': 1, '4': 1, '5': 14, '6': '.dashboard.v1.FirmwareUpdateStage', '10': 'stage'},
    {'1': 'progress', '3': 2, '4': 1, '5': 2, '10': 'progress'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {'1': 'active', '3': 4, '4': 1, '5': 8, '10': 'active'},
    {'1': 'current_version', '3': 5, '4': 1, '5': 9, '10': 'currentVersion'},
    {'1': 'target_version', '3': 6, '4': 1, '5': 9, '10': 'targetVersion'},
    {'1': 'last_error', '3': 7, '4': 1, '5': 9, '10': 'lastError'},
    {'1': 'rollback_available', '3': 8, '4': 1, '5': 8, '10': 'rollbackAvailable'},
    {'1': 'started_at_ns', '3': 9, '4': 1, '5': 4, '10': 'startedAtNs'},
    {'1': 'updated_at_ns', '3': 10, '4': 1, '5': 4, '10': 'updatedAtNs'},
    {'1': 'mcu_fw_version_raw', '3': 11, '4': 1, '5': 13, '10': 'mcuFwVersionRaw'},
    {'1': 'mcu_fw_build', '3': 12, '4': 1, '5': 13, '10': 'mcuFwBuild'},
  ],
};

/// Descriptor for `FirmwareUpdateStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List firmwareUpdateStatusDescriptor = $convert.base64Decode(
    'ChRGaXJtd2FyZVVwZGF0ZVN0YXR1cxI3CgVzdGFnZRgBIAEoDjIhLmRhc2hib2FyZC52MS5GaX'
    'Jtd2FyZVVwZGF0ZVN0YWdlUgVzdGFnZRIaCghwcm9ncmVzcxgCIAEoAlIIcHJvZ3Jlc3MSGAoH'
    'bWVzc2FnZRgDIAEoCVIHbWVzc2FnZRIWCgZhY3RpdmUYBCABKAhSBmFjdGl2ZRInCg9jdXJyZW'
    '50X3ZlcnNpb24YBSABKAlSDmN1cnJlbnRWZXJzaW9uEiUKDnRhcmdldF92ZXJzaW9uGAYgASgJ'
    'Ug10YXJnZXRWZXJzaW9uEh0KCmxhc3RfZXJyb3IYByABKAlSCWxhc3RFcnJvchItChJyb2xsYm'
    'Fja19hdmFpbGFibGUYCCABKAhSEXJvbGxiYWNrQXZhaWxhYmxlEiIKDXN0YXJ0ZWRfYXRfbnMY'
    'CSABKARSC3N0YXJ0ZWRBdE5zEiIKDXVwZGF0ZWRfYXRfbnMYCiABKARSC3VwZGF0ZWRBdE5zEi'
    'sKEm1jdV9md192ZXJzaW9uX3JhdxgLIAEoDVIPbWN1RndWZXJzaW9uUmF3EiAKDG1jdV9md19i'
    'dWlsZBgMIAEoDVIKbWN1RndCdWlsZA==');

@$core.Deprecated('Use statusDescriptor instead')
const Status$json = {
  '1': 'Status',
  '2': [
    {'1': 'state', '3': 1, '4': 1, '5': 14, '6': '.dashboard.v1.Status.State', '10': 'state'},
    {'1': 'estop_active', '3': 2, '4': 1, '5': 8, '10': 'estopActive'},
    {'1': 'session_active', '3': 3, '4': 1, '5': 8, '10': 'sessionActive'},
    {'1': 'active_profile', '3': 4, '4': 1, '5': 9, '10': 'activeProfile'},
    {'1': 'session_id', '3': 5, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'last_error', '3': 6, '4': 1, '5': 9, '10': 'lastError'},
    {'1': 'updated_at_ns', '3': 7, '4': 1, '5': 4, '10': 'updatedAtNs'},
    {'1': 'calibration_state', '3': 8, '4': 1, '5': 14, '6': '.dashboard.v1.Status.CalibrationState', '10': 'calibrationState'},
    {'1': 'calibration_progress', '3': 9, '4': 1, '5': 2, '10': 'calibrationProgress'},
    {'1': 'calibration_message', '3': 10, '4': 1, '5': 9, '10': 'calibrationMessage'},
    {'1': 'calibration_attempts', '3': 11, '4': 1, '5': 13, '10': 'calibrationAttempts'},
    {'1': 'last_calibration_at_ns', '3': 12, '4': 1, '5': 4, '10': 'lastCalibrationAtNs'},
    {'1': 'firmware_update', '3': 13, '4': 1, '5': 11, '6': '.dashboard.v1.FirmwareUpdateStatus', '10': 'firmwareUpdate'},
    {'1': 'mcu_firmware_version', '3': 14, '4': 1, '5': 9, '10': 'mcuFirmwareVersion'},
    {'1': 'mcu_firmware_build', '3': 15, '4': 1, '5': 13, '10': 'mcuFirmwareBuild'},
    {'1': 'mcu_update_state', '3': 16, '4': 1, '5': 13, '10': 'mcuUpdateState'},
    {'1': 'mcu_update_result', '3': 17, '4': 1, '5': 13, '10': 'mcuUpdateResult'},
  ],
  '4': [Status_State$json, Status_CalibrationState$json],
};

@$core.Deprecated('Use statusDescriptor instead')
const Status_State$json = {
  '1': 'State',
  '2': [
    {'1': 'STATE_INIT', '2': 0},
    {'1': 'STATE_IDLE', '2': 1},
    {'1': 'STATE_ACTIVE', '2': 2},
    {'1': 'STATE_FAULT', '2': 3},
  ],
};

@$core.Deprecated('Use statusDescriptor instead')
const Status_CalibrationState$json = {
  '1': 'CalibrationState',
  '2': [
    {'1': 'CALIBRATION_UNKNOWN', '2': 0},
    {'1': 'CALIBRATION_IDLE', '2': 1},
    {'1': 'CALIBRATION_RUNNING', '2': 2},
    {'1': 'CALIBRATION_PASSED', '2': 3},
    {'1': 'CALIBRATION_FAILED', '2': 4},
  ],
};

/// Descriptor for `Status`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusDescriptor = $convert.base64Decode(
    'CgZTdGF0dXMSMAoFc3RhdGUYASABKA4yGi5kYXNoYm9hcmQudjEuU3RhdHVzLlN0YXRlUgVzdG'
    'F0ZRIhCgxlc3RvcF9hY3RpdmUYAiABKAhSC2VzdG9wQWN0aXZlEiUKDnNlc3Npb25fYWN0aXZl'
    'GAMgASgIUg1zZXNzaW9uQWN0aXZlEiUKDmFjdGl2ZV9wcm9maWxlGAQgASgJUg1hY3RpdmVQcm'
    '9maWxlEh0KCnNlc3Npb25faWQYBSABKAlSCXNlc3Npb25JZBIdCgpsYXN0X2Vycm9yGAYgASgJ'
    'UglsYXN0RXJyb3ISIgoNdXBkYXRlZF9hdF9ucxgHIAEoBFILdXBkYXRlZEF0TnMSUgoRY2FsaW'
    'JyYXRpb25fc3RhdGUYCCABKA4yJS5kYXNoYm9hcmQudjEuU3RhdHVzLkNhbGlicmF0aW9uU3Rh'
    'dGVSEGNhbGlicmF0aW9uU3RhdGUSMQoUY2FsaWJyYXRpb25fcHJvZ3Jlc3MYCSABKAJSE2NhbG'
    'licmF0aW9uUHJvZ3Jlc3MSLwoTY2FsaWJyYXRpb25fbWVzc2FnZRgKIAEoCVISY2FsaWJyYXRp'
    'b25NZXNzYWdlEjEKFGNhbGlicmF0aW9uX2F0dGVtcHRzGAsgASgNUhNjYWxpYnJhdGlvbkF0dG'
    'VtcHRzEjMKFmxhc3RfY2FsaWJyYXRpb25fYXRfbnMYDCABKARSE2xhc3RDYWxpYnJhdGlvbkF0'
    'TnMSSwoPZmlybXdhcmVfdXBkYXRlGA0gASgLMiIuZGFzaGJvYXJkLnYxLkZpcm13YXJlVXBkYX'
    'RlU3RhdHVzUg5maXJtd2FyZVVwZGF0ZRIwChRtY3VfZmlybXdhcmVfdmVyc2lvbhgOIAEoCVIS'
    'bWN1RmlybXdhcmVWZXJzaW9uEiwKEm1jdV9maXJtd2FyZV9idWlsZBgPIAEoDVIQbWN1RmlybX'
    'dhcmVCdWlsZBIoChBtY3VfdXBkYXRlX3N0YXRlGBAgASgNUg5tY3VVcGRhdGVTdGF0ZRIqChFt'
    'Y3VfdXBkYXRlX3Jlc3VsdBgRIAEoDVIPbWN1VXBkYXRlUmVzdWx0IkoKBVN0YXRlEg4KClNUQV'
    'RFX0lOSVQQABIOCgpTVEFURV9JRExFEAESEAoMU1RBVEVfQUNUSVZFEAISDwoLU1RBVEVfRkFV'
    'TFQQAyKKAQoQQ2FsaWJyYXRpb25TdGF0ZRIXChNDQUxJQlJBVElPTl9VTktOT1dOEAASFAoQQ0'
    'FMSUJSQVRJT05fSURMRRABEhcKE0NBTElCUkFUSU9OX1JVTk5JTkcQAhIWChJDQUxJQlJBVElP'
    'Tl9QQVNTRUQQAxIWChJDQUxJQlJBVElPTl9GQUlMRUQQBA==');

@$core.Deprecated('Use getStatusRequestDescriptor instead')
const GetStatusRequest$json = {
  '1': 'GetStatusRequest',
};

/// Descriptor for `GetStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatusRequestDescriptor = $convert.base64Decode(
    'ChBHZXRTdGF0dXNSZXF1ZXN0');

@$core.Deprecated('Use getStatusResponseDescriptor instead')
const GetStatusResponse$json = {
  '1': 'GetStatusResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 11, '6': '.dashboard.v1.Status', '10': 'status'},
  ],
};

/// Descriptor for `GetStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatusResponseDescriptor = $convert.base64Decode(
    'ChFHZXRTdGF0dXNSZXNwb25zZRIsCgZzdGF0dXMYASABKAsyFC5kYXNoYm9hcmQudjEuU3RhdH'
    'VzUgZzdGF0dXM=');

@$core.Deprecated('Use calibrateRequestDescriptor instead')
const CalibrateRequest$json = {
  '1': 'CalibrateRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `CalibrateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List calibrateRequestDescriptor = $convert.base64Decode(
    'ChBDYWxpYnJhdGVSZXF1ZXN0Eh0KCnByb2ZpbGVfaWQYASABKAlSCXByb2ZpbGVJZA==');

@$core.Deprecated('Use calibrateResponseDescriptor instead')
const CalibrateResponse$json = {
  '1': 'CalibrateResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `CalibrateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List calibrateResponseDescriptor = $convert.base64Decode(
    'ChFDYWxpYnJhdGVSZXNwb25zZRIOCgJvaxgBIAEoCFICb2sSGAoHbWVzc2FnZRgCIAEoCVIHbW'
    'Vzc2FnZQ==');

@$core.Deprecated('Use cancelCalibrationRequestDescriptor instead')
const CancelCalibrationRequest$json = {
  '1': 'CancelCalibrationRequest',
};

/// Descriptor for `CancelCalibrationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelCalibrationRequestDescriptor = $convert.base64Decode(
    'ChhDYW5jZWxDYWxpYnJhdGlvblJlcXVlc3Q=');

@$core.Deprecated('Use cancelCalibrationResponseDescriptor instead')
const CancelCalibrationResponse$json = {
  '1': 'CancelCalibrationResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `CancelCalibrationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelCalibrationResponseDescriptor = $convert.base64Decode(
    'ChlDYW5jZWxDYWxpYnJhdGlvblJlc3BvbnNlEg4KAm9rGAEgASgIUgJvaxIYCgdtZXNzYWdlGA'
    'IgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use setProfileRequestDescriptor instead')
const SetProfileRequest$json = {
  '1': 'SetProfileRequest',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `SetProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setProfileRequestDescriptor = $convert.base64Decode(
    'ChFTZXRQcm9maWxlUmVxdWVzdBIdCgpwcm9maWxlX2lkGAEgASgJUglwcm9maWxlSWQ=');

@$core.Deprecated('Use setProfileResponseDescriptor instead')
const SetProfileResponse$json = {
  '1': 'SetProfileResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'active_profile', '3': 2, '4': 1, '5': 9, '10': 'activeProfile'},
  ],
};

/// Descriptor for `SetProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setProfileResponseDescriptor = $convert.base64Decode(
    'ChJTZXRQcm9maWxlUmVzcG9uc2USDgoCb2sYASABKAhSAm9rEiUKDmFjdGl2ZV9wcm9maWxlGA'
    'IgASgJUg1hY3RpdmVQcm9maWxl');

@$core.Deprecated('Use eStopRequestDescriptor instead')
const EStopRequest$json = {
  '1': 'EStopRequest',
  '2': [
    {'1': 'engaged', '3': 1, '4': 1, '5': 8, '10': 'engaged'},
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `EStopRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eStopRequestDescriptor = $convert.base64Decode(
    'CgxFU3RvcFJlcXVlc3QSGAoHZW5nYWdlZBgBIAEoCFIHZW5nYWdlZBIWCgZyZWFzb24YAiABKA'
    'lSBnJlYXNvbg==');

@$core.Deprecated('Use eStopResponseDescriptor instead')
const EStopResponse$json = {
  '1': 'EStopResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `EStopResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eStopResponseDescriptor = $convert.base64Decode(
    'Cg1FU3RvcFJlc3BvbnNlEg4KAm9rGAEgASgIUgJvaw==');

@$core.Deprecated('Use startSessionRequestDescriptor instead')
const StartSessionRequest$json = {
  '1': 'StartSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'track', '3': 2, '4': 1, '5': 9, '10': 'track'},
    {'1': 'car', '3': 3, '4': 1, '5': 9, '10': 'car'},
    {'1': 'start_time_ns', '3': 4, '4': 1, '5': 4, '10': 'startTimeNs'},
  ],
};

/// Descriptor for `StartSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startSessionRequestDescriptor = $convert.base64Decode(
    'ChNTdGFydFNlc3Npb25SZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIUCg'
    'V0cmFjaxgCIAEoCVIFdHJhY2sSEAoDY2FyGAMgASgJUgNjYXISIgoNc3RhcnRfdGltZV9ucxgE'
    'IAEoBFILc3RhcnRUaW1lTnM=');

@$core.Deprecated('Use startSessionResponseDescriptor instead')
const StartSessionResponse$json = {
  '1': 'StartSessionResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `StartSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startSessionResponseDescriptor = $convert.base64Decode(
    'ChRTdGFydFNlc3Npb25SZXNwb25zZRIOCgJvaxgBIAEoCFICb2s=');

@$core.Deprecated('Use endSessionRequestDescriptor instead')
const EndSessionRequest$json = {
  '1': 'EndSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `EndSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List endSessionRequestDescriptor = $convert.base64Decode(
    'ChFFbmRTZXNzaW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQ=');

@$core.Deprecated('Use endSessionResponseDescriptor instead')
const EndSessionResponse$json = {
  '1': 'EndSessionResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `EndSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List endSessionResponseDescriptor = $convert.base64Decode(
    'ChJFbmRTZXNzaW9uUmVzcG9uc2USDgoCb2sYASABKAhSAm9r');

@$core.Deprecated('Use sessionMetadataDescriptor instead')
const SessionMetadata$json = {
  '1': 'SessionMetadata',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'track', '3': 2, '4': 1, '5': 9, '10': 'track'},
    {'1': 'car', '3': 3, '4': 1, '5': 9, '10': 'car'},
    {'1': 'start_time_ns', '3': 4, '4': 1, '5': 4, '10': 'startTimeNs'},
    {'1': 'end_time_ns', '3': 5, '4': 1, '5': 4, '10': 'endTimeNs'},
    {'1': 'duration_ms', '3': 6, '4': 1, '5': 4, '10': 'durationMs'},
  ],
};

/// Descriptor for `SessionMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionMetadataDescriptor = $convert.base64Decode(
    'Cg9TZXNzaW9uTWV0YWRhdGESHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhQKBXRyYW'
    'NrGAIgASgJUgV0cmFjaxIQCgNjYXIYAyABKAlSA2NhchIiCg1zdGFydF90aW1lX25zGAQgASgE'
    'UgtzdGFydFRpbWVOcxIeCgtlbmRfdGltZV9ucxgFIAEoBFIJZW5kVGltZU5zEh8KC2R1cmF0aW'
    '9uX21zGAYgASgEUgpkdXJhdGlvbk1z');

@$core.Deprecated('Use listSessionsRequestDescriptor instead')
const ListSessionsRequest$json = {
  '1': 'ListSessionsRequest',
};

/// Descriptor for `ListSessionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSessionsRequestDescriptor = $convert.base64Decode(
    'ChNMaXN0U2Vzc2lvbnNSZXF1ZXN0');

@$core.Deprecated('Use listSessionsResponseDescriptor instead')
const ListSessionsResponse$json = {
  '1': 'ListSessionsResponse',
  '2': [
    {'1': 'sessions', '3': 1, '4': 3, '5': 11, '6': '.dashboard.v1.SessionMetadata', '10': 'sessions'},
  ],
};

/// Descriptor for `ListSessionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSessionsResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0U2Vzc2lvbnNSZXNwb25zZRI5CghzZXNzaW9ucxgBIAMoCzIdLmRhc2hib2FyZC52MS'
    '5TZXNzaW9uTWV0YWRhdGFSCHNlc3Npb25z');

@$core.Deprecated('Use telemetrySampleDescriptor instead')
const TelemetrySample$json = {
  '1': 'TelemetrySample',
  '2': [
    {'1': 'timestamp_ns', '3': 1, '4': 1, '5': 4, '10': 'timestampNs'},
    {'1': 'pitch_rad', '3': 2, '4': 1, '5': 2, '10': 'pitchRad'},
    {'1': 'roll_rad', '3': 3, '4': 1, '5': 2, '10': 'rollRad'},
    {'1': 'left_target_m', '3': 4, '4': 1, '5': 2, '10': 'leftTargetM'},
    {'1': 'right_target_m', '3': 5, '4': 1, '5': 2, '10': 'rightTargetM'},
    {'1': 'latency_ms', '3': 6, '4': 1, '5': 2, '10': 'latencyMs'},
    {'1': 'speed_kmh', '3': 7, '4': 1, '5': 2, '10': 'speedKmh'},
    {'1': 'gear', '3': 8, '4': 1, '5': 5, '10': 'gear'},
    {'1': 'engine_rpm', '3': 9, '4': 1, '5': 2, '10': 'engineRpm'},
    {'1': 'track_progress', '3': 10, '4': 1, '5': 2, '10': 'trackProgress'},
  ],
};

/// Descriptor for `TelemetrySample`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List telemetrySampleDescriptor = $convert.base64Decode(
    'Cg9UZWxlbWV0cnlTYW1wbGUSIQoMdGltZXN0YW1wX25zGAEgASgEUgt0aW1lc3RhbXBOcxIbCg'
    'lwaXRjaF9yYWQYAiABKAJSCHBpdGNoUmFkEhkKCHJvbGxfcmFkGAMgASgCUgdyb2xsUmFkEiIK'
    'DWxlZnRfdGFyZ2V0X20YBCABKAJSC2xlZnRUYXJnZXRNEiQKDnJpZ2h0X3RhcmdldF9tGAUgAS'
    'gCUgxyaWdodFRhcmdldE0SHQoKbGF0ZW5jeV9tcxgGIAEoAlIJbGF0ZW5jeU1zEhsKCXNwZWVk'
    'X2ttaBgHIAEoAlIIc3BlZWRLbWgSEgoEZ2VhchgIIAEoBVIEZ2VhchIdCgplbmdpbmVfcnBtGA'
    'kgASgCUgllbmdpbmVScG0SJQoOdHJhY2tfcHJvZ3Jlc3MYCiABKAJSDXRyYWNrUHJvZ3Jlc3M=');

@$core.Deprecated('Use telemetryStreamRequestDescriptor instead')
const TelemetryStreamRequest$json = {
  '1': 'TelemetryStreamRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `TelemetryStreamRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List telemetryStreamRequestDescriptor = $convert.base64Decode(
    'ChZUZWxlbWV0cnlTdHJlYW1SZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZA'
    '==');

@$core.Deprecated('Use inputEventStreamRequestDescriptor instead')
const InputEventStreamRequest$json = {
  '1': 'InputEventStreamRequest',
};

/// Descriptor for `InputEventStreamRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inputEventStreamRequestDescriptor = $convert.base64Decode(
    'ChdJbnB1dEV2ZW50U3RyZWFtUmVxdWVzdA==');

@$core.Deprecated('Use inputEventDescriptor instead')
const InputEvent$json = {
  '1': 'InputEvent',
  '2': [
    {'1': 'sequence', '3': 1, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.dashboard.v1.InputEvent.Type', '10': 'type'},
    {'1': 'source', '3': 3, '4': 1, '5': 14, '6': '.dashboard.v1.InputEvent.Source', '10': 'source'},
    {'1': 'received_at_ns', '3': 4, '4': 1, '5': 4, '10': 'receivedAtNs'},
    {'1': 'mcu_uptime_ms', '3': 5, '4': 1, '5': 13, '10': 'mcuUptimeMs'},
    {'1': 'pressed', '3': 6, '4': 1, '5': 8, '10': 'pressed'},
  ],
  '4': [InputEvent_Type$json, InputEvent_Source$json],
};

@$core.Deprecated('Use inputEventDescriptor instead')
const InputEvent_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'INPUT_EVENT_TYPE_UNKNOWN', '2': 0},
    {'1': 'INPUT_EVENT_TYPE_PTT_DOWN', '2': 1},
    {'1': 'INPUT_EVENT_TYPE_PTT_UP', '2': 2},
  ],
};

@$core.Deprecated('Use inputEventDescriptor instead')
const InputEvent_Source$json = {
  '1': 'Source',
  '2': [
    {'1': 'INPUT_EVENT_SOURCE_UNKNOWN', '2': 0},
    {'1': 'INPUT_EVENT_SOURCE_STEERING_WHEEL', '2': 1},
  ],
};

/// Descriptor for `InputEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inputEventDescriptor = $convert.base64Decode(
    'CgpJbnB1dEV2ZW50EhoKCHNlcXVlbmNlGAEgASgEUghzZXF1ZW5jZRIxCgR0eXBlGAIgASgOMh'
    '0uZGFzaGJvYXJkLnYxLklucHV0RXZlbnQuVHlwZVIEdHlwZRI3CgZzb3VyY2UYAyABKA4yHy5k'
    'YXNoYm9hcmQudjEuSW5wdXRFdmVudC5Tb3VyY2VSBnNvdXJjZRIkCg5yZWNlaXZlZF9hdF9ucx'
    'gEIAEoBFIMcmVjZWl2ZWRBdE5zEiIKDW1jdV91cHRpbWVfbXMYBSABKA1SC21jdVVwdGltZU1z'
    'EhgKB3ByZXNzZWQYBiABKAhSB3ByZXNzZWQiYAoEVHlwZRIcChhJTlBVVF9FVkVOVF9UWVBFX1'
    'VOS05PV04QABIdChlJTlBVVF9FVkVOVF9UWVBFX1BUVF9ET1dOEAESGwoXSU5QVVRfRVZFTlRf'
    'VFlQRV9QVFRfVVAQAiJPCgZTb3VyY2USHgoaSU5QVVRfRVZFTlRfU09VUkNFX1VOS05PV04QAB'
    'IlCiFJTlBVVF9FVkVOVF9TT1VSQ0VfU1RFRVJJTkdfV0hFRUwQAQ==');

@$core.Deprecated('Use getSessionTelemetryRequestDescriptor instead')
const GetSessionTelemetryRequest$json = {
  '1': 'GetSessionTelemetryRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'max_samples', '3': 2, '4': 1, '5': 13, '10': 'maxSamples'},
  ],
};

/// Descriptor for `GetSessionTelemetryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSessionTelemetryRequestDescriptor = $convert.base64Decode(
    'ChpHZXRTZXNzaW9uVGVsZW1ldHJ5UmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW'
    '9uSWQSHwoLbWF4X3NhbXBsZXMYAiABKA1SCm1heFNhbXBsZXM=');

@$core.Deprecated('Use getSessionTelemetryResponseDescriptor instead')
const GetSessionTelemetryResponse$json = {
  '1': 'GetSessionTelemetryResponse',
  '2': [
    {'1': 'samples', '3': 1, '4': 3, '5': 11, '6': '.dashboard.v1.TelemetrySample', '10': 'samples'},
  ],
};

/// Descriptor for `GetSessionTelemetryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSessionTelemetryResponseDescriptor = $convert.base64Decode(
    'ChtHZXRTZXNzaW9uVGVsZW1ldHJ5UmVzcG9uc2USNwoHc2FtcGxlcxgBIAMoCzIdLmRhc2hib2'
    'FyZC52MS5UZWxlbWV0cnlTYW1wbGVSB3NhbXBsZXM=');

@$core.Deprecated('Use startFirmwareUpdateRequestDescriptor instead')
const StartFirmwareUpdateRequest$json = {
  '1': 'StartFirmwareUpdateRequest',
  '2': [
    {'1': 'artifact_uri', '3': 1, '4': 1, '5': 9, '10': 'artifactUri'},
    {'1': 'sha256', '3': 2, '4': 1, '5': 9, '10': 'sha256'},
    {'1': 'target_version', '3': 3, '4': 1, '5': 9, '10': 'targetVersion'},
    {'1': 'allow_rollback', '3': 4, '4': 1, '5': 8, '10': 'allowRollback'},
    {'1': 'rollback_artifact_uri', '3': 5, '4': 1, '5': 9, '10': 'rollbackArtifactUri'},
  ],
};

/// Descriptor for `StartFirmwareUpdateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startFirmwareUpdateRequestDescriptor = $convert.base64Decode(
    'ChpTdGFydEZpcm13YXJlVXBkYXRlUmVxdWVzdBIhCgxhcnRpZmFjdF91cmkYASABKAlSC2FydG'
    'lmYWN0VXJpEhYKBnNoYTI1NhgCIAEoCVIGc2hhMjU2EiUKDnRhcmdldF92ZXJzaW9uGAMgASgJ'
    'Ug10YXJnZXRWZXJzaW9uEiUKDmFsbG93X3JvbGxiYWNrGAQgASgIUg1hbGxvd1JvbGxiYWNrEj'
    'IKFXJvbGxiYWNrX2FydGlmYWN0X3VyaRgFIAEoCVITcm9sbGJhY2tBcnRpZmFjdFVyaQ==');

@$core.Deprecated('Use startFirmwareUpdateResponseDescriptor instead')
const StartFirmwareUpdateResponse$json = {
  '1': 'StartFirmwareUpdateResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'status', '3': 3, '4': 1, '5': 11, '6': '.dashboard.v1.FirmwareUpdateStatus', '10': 'status'},
  ],
};

/// Descriptor for `StartFirmwareUpdateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startFirmwareUpdateResponseDescriptor = $convert.base64Decode(
    'ChtTdGFydEZpcm13YXJlVXBkYXRlUmVzcG9uc2USDgoCb2sYASABKAhSAm9rEhgKB21lc3NhZ2'
    'UYAiABKAlSB21lc3NhZ2USOgoGc3RhdHVzGAMgASgLMiIuZGFzaGJvYXJkLnYxLkZpcm13YXJl'
    'VXBkYXRlU3RhdHVzUgZzdGF0dXM=');

@$core.Deprecated('Use cancelFirmwareUpdateRequestDescriptor instead')
const CancelFirmwareUpdateRequest$json = {
  '1': 'CancelFirmwareUpdateRequest',
};

/// Descriptor for `CancelFirmwareUpdateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelFirmwareUpdateRequestDescriptor = $convert.base64Decode(
    'ChtDYW5jZWxGaXJtd2FyZVVwZGF0ZVJlcXVlc3Q=');

@$core.Deprecated('Use cancelFirmwareUpdateResponseDescriptor instead')
const CancelFirmwareUpdateResponse$json = {
  '1': 'CancelFirmwareUpdateResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'status', '3': 3, '4': 1, '5': 11, '6': '.dashboard.v1.FirmwareUpdateStatus', '10': 'status'},
  ],
};

/// Descriptor for `CancelFirmwareUpdateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelFirmwareUpdateResponseDescriptor = $convert.base64Decode(
    'ChxDYW5jZWxGaXJtd2FyZVVwZGF0ZVJlc3BvbnNlEg4KAm9rGAEgASgIUgJvaxIYCgdtZXNzYW'
    'dlGAIgASgJUgdtZXNzYWdlEjoKBnN0YXR1cxgDIAEoCzIiLmRhc2hib2FyZC52MS5GaXJtd2Fy'
    'ZVVwZGF0ZVN0YXR1c1IGc3RhdHVz');

@$core.Deprecated('Use checkFirmwareVersionRequestDescriptor instead')
const CheckFirmwareVersionRequest$json = {
  '1': 'CheckFirmwareVersionRequest',
  '2': [
    {'1': 'latest_version', '3': 1, '4': 1, '5': 9, '10': 'latestVersion'},
  ],
};

/// Descriptor for `CheckFirmwareVersionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkFirmwareVersionRequestDescriptor = $convert.base64Decode(
    'ChtDaGVja0Zpcm13YXJlVmVyc2lvblJlcXVlc3QSJQoObGF0ZXN0X3ZlcnNpb24YASABKAlSDW'
    'xhdGVzdFZlcnNpb24=');

@$core.Deprecated('Use checkFirmwareVersionResponseDescriptor instead')
const CheckFirmwareVersionResponse$json = {
  '1': 'CheckFirmwareVersionResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'update_available', '3': 2, '4': 1, '5': 8, '10': 'updateAvailable'},
    {'1': 'current_version', '3': 3, '4': 1, '5': 9, '10': 'currentVersion'},
    {'1': 'latest_version', '3': 4, '4': 1, '5': 9, '10': 'latestVersion'},
    {'1': 'message', '3': 5, '4': 1, '5': 9, '10': 'message'},
    {'1': 'mcu_connected', '3': 6, '4': 1, '5': 8, '10': 'mcuConnected'},
  ],
};

/// Descriptor for `CheckFirmwareVersionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkFirmwareVersionResponseDescriptor = $convert.base64Decode(
    'ChxDaGVja0Zpcm13YXJlVmVyc2lvblJlc3BvbnNlEg4KAm9rGAEgASgIUgJvaxIpChB1cGRhdG'
    'VfYXZhaWxhYmxlGAIgASgIUg91cGRhdGVBdmFpbGFibGUSJwoPY3VycmVudF92ZXJzaW9uGAMg'
    'ASgJUg5jdXJyZW50VmVyc2lvbhIlCg5sYXRlc3RfdmVyc2lvbhgEIAEoCVINbGF0ZXN0VmVyc2'
    'lvbhIYCgdtZXNzYWdlGAUgASgJUgdtZXNzYWdlEiMKDW1jdV9jb25uZWN0ZWQYBiABKAhSDG1j'
    'dUNvbm5lY3RlZA==');

