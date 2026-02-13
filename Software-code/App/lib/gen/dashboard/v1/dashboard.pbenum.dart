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

class FirmwareUpdateStage extends $pb.ProtobufEnum {
  static const FirmwareUpdateStage FIRMWARE_UPDATE_STAGE_IDLE = FirmwareUpdateStage._(0, _omitEnumNames ? '' : 'FIRMWARE_UPDATE_STAGE_IDLE');
  static const FirmwareUpdateStage FIRMWARE_UPDATE_STAGE_DOWNLOADING = FirmwareUpdateStage._(1, _omitEnumNames ? '' : 'FIRMWARE_UPDATE_STAGE_DOWNLOADING');
  static const FirmwareUpdateStage FIRMWARE_UPDATE_STAGE_VERIFYING = FirmwareUpdateStage._(2, _omitEnumNames ? '' : 'FIRMWARE_UPDATE_STAGE_VERIFYING');
  static const FirmwareUpdateStage FIRMWARE_UPDATE_STAGE_REQUESTING_DFU = FirmwareUpdateStage._(3, _omitEnumNames ? '' : 'FIRMWARE_UPDATE_STAGE_REQUESTING_DFU');
  static const FirmwareUpdateStage FIRMWARE_UPDATE_STAGE_FLASHING = FirmwareUpdateStage._(4, _omitEnumNames ? '' : 'FIRMWARE_UPDATE_STAGE_FLASHING');
  static const FirmwareUpdateStage FIRMWARE_UPDATE_STAGE_VERIFYING_VERSION = FirmwareUpdateStage._(5, _omitEnumNames ? '' : 'FIRMWARE_UPDATE_STAGE_VERIFYING_VERSION');
  static const FirmwareUpdateStage FIRMWARE_UPDATE_STAGE_COMPLETED = FirmwareUpdateStage._(6, _omitEnumNames ? '' : 'FIRMWARE_UPDATE_STAGE_COMPLETED');
  static const FirmwareUpdateStage FIRMWARE_UPDATE_STAGE_FAILED = FirmwareUpdateStage._(7, _omitEnumNames ? '' : 'FIRMWARE_UPDATE_STAGE_FAILED');
  static const FirmwareUpdateStage FIRMWARE_UPDATE_STAGE_ROLLING_BACK = FirmwareUpdateStage._(8, _omitEnumNames ? '' : 'FIRMWARE_UPDATE_STAGE_ROLLING_BACK');
  static const FirmwareUpdateStage FIRMWARE_UPDATE_STAGE_ROLLED_BACK = FirmwareUpdateStage._(9, _omitEnumNames ? '' : 'FIRMWARE_UPDATE_STAGE_ROLLED_BACK');
  static const FirmwareUpdateStage FIRMWARE_UPDATE_STAGE_CANCELED = FirmwareUpdateStage._(10, _omitEnumNames ? '' : 'FIRMWARE_UPDATE_STAGE_CANCELED');

  static const $core.List<FirmwareUpdateStage> values = <FirmwareUpdateStage> [
    FIRMWARE_UPDATE_STAGE_IDLE,
    FIRMWARE_UPDATE_STAGE_DOWNLOADING,
    FIRMWARE_UPDATE_STAGE_VERIFYING,
    FIRMWARE_UPDATE_STAGE_REQUESTING_DFU,
    FIRMWARE_UPDATE_STAGE_FLASHING,
    FIRMWARE_UPDATE_STAGE_VERIFYING_VERSION,
    FIRMWARE_UPDATE_STAGE_COMPLETED,
    FIRMWARE_UPDATE_STAGE_FAILED,
    FIRMWARE_UPDATE_STAGE_ROLLING_BACK,
    FIRMWARE_UPDATE_STAGE_ROLLED_BACK,
    FIRMWARE_UPDATE_STAGE_CANCELED,
  ];

  static final $core.List<FirmwareUpdateStage?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 10);
  static FirmwareUpdateStage? valueOf($core.int value) =>  value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FirmwareUpdateStage._(super.value, super.name);
}

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

class InputEvent_Type extends $pb.ProtobufEnum {
  static const InputEvent_Type INPUT_EVENT_TYPE_UNKNOWN = InputEvent_Type._(0, _omitEnumNames ? '' : 'INPUT_EVENT_TYPE_UNKNOWN');
  static const InputEvent_Type INPUT_EVENT_TYPE_PTT_DOWN = InputEvent_Type._(1, _omitEnumNames ? '' : 'INPUT_EVENT_TYPE_PTT_DOWN');
  static const InputEvent_Type INPUT_EVENT_TYPE_PTT_UP = InputEvent_Type._(2, _omitEnumNames ? '' : 'INPUT_EVENT_TYPE_PTT_UP');

  static const $core.List<InputEvent_Type> values = <InputEvent_Type> [
    INPUT_EVENT_TYPE_UNKNOWN,
    INPUT_EVENT_TYPE_PTT_DOWN,
    INPUT_EVENT_TYPE_PTT_UP,
  ];

  static final $core.List<InputEvent_Type?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static InputEvent_Type? valueOf($core.int value) =>  value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InputEvent_Type._(super.value, super.name);
}

class InputEvent_Source extends $pb.ProtobufEnum {
  static const InputEvent_Source INPUT_EVENT_SOURCE_UNKNOWN = InputEvent_Source._(0, _omitEnumNames ? '' : 'INPUT_EVENT_SOURCE_UNKNOWN');
  static const InputEvent_Source INPUT_EVENT_SOURCE_STEERING_WHEEL = InputEvent_Source._(1, _omitEnumNames ? '' : 'INPUT_EVENT_SOURCE_STEERING_WHEEL');

  static const $core.List<InputEvent_Source> values = <InputEvent_Source> [
    INPUT_EVENT_SOURCE_UNKNOWN,
    INPUT_EVENT_SOURCE_STEERING_WHEEL,
  ];

  static final $core.List<InputEvent_Source?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 1);
  static InputEvent_Source? valueOf($core.int value) =>  value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InputEvent_Source._(super.value, super.name);
}


const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
