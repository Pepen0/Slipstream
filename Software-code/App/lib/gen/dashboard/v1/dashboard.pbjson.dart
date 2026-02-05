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
  ],
  '4': [Status_State$json],
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

/// Descriptor for `Status`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusDescriptor = $convert.base64Decode(
    'CgZTdGF0dXMSMAoFc3RhdGUYASABKA4yGi5kYXNoYm9hcmQudjEuU3RhdHVzLlN0YXRlUgVzdG'
    'F0ZRIhCgxlc3RvcF9hY3RpdmUYAiABKAhSC2VzdG9wQWN0aXZlEiUKDnNlc3Npb25fYWN0aXZl'
    'GAMgASgIUg1zZXNzaW9uQWN0aXZlEiUKDmFjdGl2ZV9wcm9maWxlGAQgASgJUg1hY3RpdmVQcm'
    '9maWxlEh0KCnNlc3Npb25faWQYBSABKAlSCXNlc3Npb25JZBIdCgpsYXN0X2Vycm9yGAYgASgJ'
    'UglsYXN0RXJyb3ISIgoNdXBkYXRlZF9hdF9ucxgHIAEoBFILdXBkYXRlZEF0TnMiSgoFU3RhdG'
    'USDgoKU1RBVEVfSU5JVBAAEg4KClNUQVRFX0lETEUQARIQCgxTVEFURV9BQ1RJVkUQAhIPCgtT'
    'VEFURV9GQVVMVBAD');

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
  ],
};

/// Descriptor for `StartSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startSessionRequestDescriptor = $convert.base64Decode(
    'ChNTdGFydFNlc3Npb25SZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZA==');

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
  ],
};

/// Descriptor for `TelemetrySample`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List telemetrySampleDescriptor = $convert.base64Decode(
    'Cg9UZWxlbWV0cnlTYW1wbGUSIQoMdGltZXN0YW1wX25zGAEgASgEUgt0aW1lc3RhbXBOcxIbCg'
    'lwaXRjaF9yYWQYAiABKAJSCHBpdGNoUmFkEhkKCHJvbGxfcmFkGAMgASgCUgdyb2xsUmFkEiIK'
    'DWxlZnRfdGFyZ2V0X20YBCABKAJSC2xlZnRUYXJnZXRNEiQKDnJpZ2h0X3RhcmdldF9tGAUgAS'
    'gCUgxyaWdodFRhcmdldE0SHQoKbGF0ZW5jeV9tcxgGIAEoAlIJbGF0ZW5jeU1z');

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

