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

import 'package:protobuf/protobuf.dart' as $pb;

class Status_State extends $pb.ProtobufEnum {
  static const Status_State STATE_INIT = Status_State._(0, _omitEnumNames ? '' : 'STATE_INIT');
  static const Status_State STATE_IDLE = Status_State._(1, _omitEnumNames ? '' : 'STATE_IDLE');
  static const Status_State STATE_ACTIVE = Status_State._(2, _omitEnumNames ? '' : 'STATE_ACTIVE');
  static const Status_State STATE_FAULT = Status_State._(3, _omitEnumNames ? '' : 'STATE_FAULT');

  static const $core.List<Status_State> values = <Status_State> [
    STATE_INIT,
    STATE_IDLE,
    STATE_ACTIVE,
    STATE_FAULT,
  ];

  static final $core.List<Status_State?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Status_State? valueOf($core.int value) =>  value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Status_State._(super.value, super.name);
}

class Status_CalibrationState extends $pb.ProtobufEnum {
  static const Status_CalibrationState CALIBRATION_UNKNOWN = Status_CalibrationState._(0, _omitEnumNames ? '' : 'CALIBRATION_UNKNOWN');
  static const Status_CalibrationState CALIBRATION_IDLE = Status_CalibrationState._(1, _omitEnumNames ? '' : 'CALIBRATION_IDLE');
  static const Status_CalibrationState CALIBRATION_RUNNING = Status_CalibrationState._(2, _omitEnumNames ? '' : 'CALIBRATION_RUNNING');
  static const Status_CalibrationState CALIBRATION_PASSED = Status_CalibrationState._(3, _omitEnumNames ? '' : 'CALIBRATION_PASSED');
  static const Status_CalibrationState CALIBRATION_FAILED = Status_CalibrationState._(4, _omitEnumNames ? '' : 'CALIBRATION_FAILED');

  static const $core.List<Status_CalibrationState> values = <Status_CalibrationState> [
    CALIBRATION_UNKNOWN,
    CALIBRATION_IDLE,
    CALIBRATION_RUNNING,
    CALIBRATION_PASSED,
    CALIBRATION_FAILED,
  ];

  static final $core.List<Status_CalibrationState?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Status_CalibrationState? valueOf($core.int value) =>  value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Status_CalibrationState._(super.value, super.name);
}


const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
