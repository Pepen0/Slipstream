// This is a generated file - do not edit.
//
// Generated from dashboard/v1/dashboard.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'dashboard.pb.dart' as $0;

export 'dashboard.pb.dart';

@$pb.GrpcServiceName('dashboard.v1.DashboardService')
class DashboardServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  DashboardServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.GetStatusResponse> getStatus($0.GetStatusRequest request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$getStatus, request, options: options);
  }

  $grpc.ResponseFuture<$0.CalibrateResponse> calibrate($0.CalibrateRequest request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$calibrate, request, options: options);
  }

  $grpc.ResponseFuture<$0.CancelCalibrationResponse> cancelCalibration($0.CancelCalibrationRequest request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$cancelCalibration, request, options: options);
  }

  $grpc.ResponseFuture<$0.SetProfileResponse> setProfile($0.SetProfileRequest request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$setProfile, request, options: options);
  }

  $grpc.ResponseFuture<$0.EStopResponse> eStop($0.EStopRequest request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$eStop, request, options: options);
  }

  $grpc.ResponseFuture<$0.StartSessionResponse> startSession($0.StartSessionRequest request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$startSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.EndSessionResponse> endSession($0.EndSessionRequest request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$endSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListSessionsResponse> listSessions($0.ListSessionsRequest request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$listSessions, request, options: options);
  }

  $grpc.ResponseStream<$0.TelemetrySample> streamTelemetry($0.TelemetryStreamRequest request, {$grpc.CallOptions? options,}) {
    return $createStreamingCall(_$streamTelemetry, $async.Stream.fromIterable([request]), options: options);
  }

    // method descriptors

  static final _$getStatus = $grpc.ClientMethod<$0.GetStatusRequest, $0.GetStatusResponse>(
      '/dashboard.v1.DashboardService/GetStatus',
      ($0.GetStatusRequest value) => value.writeToBuffer(),
      $0.GetStatusResponse.fromBuffer);
  static final _$calibrate = $grpc.ClientMethod<$0.CalibrateRequest, $0.CalibrateResponse>(
      '/dashboard.v1.DashboardService/Calibrate',
      ($0.CalibrateRequest value) => value.writeToBuffer(),
      $0.CalibrateResponse.fromBuffer);
  static final _$cancelCalibration = $grpc.ClientMethod<$0.CancelCalibrationRequest, $0.CancelCalibrationResponse>(
      '/dashboard.v1.DashboardService/CancelCalibration',
      ($0.CancelCalibrationRequest value) => value.writeToBuffer(),
      $0.CancelCalibrationResponse.fromBuffer);
  static final _$setProfile = $grpc.ClientMethod<$0.SetProfileRequest, $0.SetProfileResponse>(
      '/dashboard.v1.DashboardService/SetProfile',
      ($0.SetProfileRequest value) => value.writeToBuffer(),
      $0.SetProfileResponse.fromBuffer);
  static final _$eStop = $grpc.ClientMethod<$0.EStopRequest, $0.EStopResponse>(
      '/dashboard.v1.DashboardService/EStop',
      ($0.EStopRequest value) => value.writeToBuffer(),
      $0.EStopResponse.fromBuffer);
  static final _$startSession = $grpc.ClientMethod<$0.StartSessionRequest, $0.StartSessionResponse>(
      '/dashboard.v1.DashboardService/StartSession',
      ($0.StartSessionRequest value) => value.writeToBuffer(),
      $0.StartSessionResponse.fromBuffer);
  static final _$endSession = $grpc.ClientMethod<$0.EndSessionRequest, $0.EndSessionResponse>(
      '/dashboard.v1.DashboardService/EndSession',
      ($0.EndSessionRequest value) => value.writeToBuffer(),
      $0.EndSessionResponse.fromBuffer);
  static final _$listSessions = $grpc.ClientMethod<$0.ListSessionsRequest, $0.ListSessionsResponse>(
      '/dashboard.v1.DashboardService/ListSessions',
      ($0.ListSessionsRequest value) => value.writeToBuffer(),
      $0.ListSessionsResponse.fromBuffer);
  static final _$streamTelemetry = $grpc.ClientMethod<$0.TelemetryStreamRequest, $0.TelemetrySample>(
      '/dashboard.v1.DashboardService/StreamTelemetry',
      ($0.TelemetryStreamRequest value) => value.writeToBuffer(),
      $0.TelemetrySample.fromBuffer);
}

@$pb.GrpcServiceName('dashboard.v1.DashboardService')
abstract class DashboardServiceBase extends $grpc.Service {
  $core.String get $name => 'dashboard.v1.DashboardService';

  DashboardServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetStatusRequest, $0.GetStatusResponse>(
        'GetStatus',
        getStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetStatusRequest.fromBuffer(value),
        ($0.GetStatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CalibrateRequest, $0.CalibrateResponse>(
        'Calibrate',
        calibrate_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CalibrateRequest.fromBuffer(value),
        ($0.CalibrateResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CancelCalibrationRequest, $0.CancelCalibrationResponse>(
        'CancelCalibration',
        cancelCalibration_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CancelCalibrationRequest.fromBuffer(value),
        ($0.CancelCalibrationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetProfileRequest, $0.SetProfileResponse>(
        'SetProfile',
        setProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetProfileRequest.fromBuffer(value),
        ($0.SetProfileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EStopRequest, $0.EStopResponse>(
        'EStop',
        eStop_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EStopRequest.fromBuffer(value),
        ($0.EStopResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartSessionRequest, $0.StartSessionResponse>(
        'StartSession',
        startSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StartSessionRequest.fromBuffer(value),
        ($0.StartSessionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EndSessionRequest, $0.EndSessionResponse>(
        'EndSession',
        endSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EndSessionRequest.fromBuffer(value),
        ($0.EndSessionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListSessionsRequest, $0.ListSessionsResponse>(
        'ListSessions',
        listSessions_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListSessionsRequest.fromBuffer(value),
        ($0.ListSessionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TelemetryStreamRequest, $0.TelemetrySample>(
        'StreamTelemetry',
        streamTelemetry_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.TelemetryStreamRequest.fromBuffer(value),
        ($0.TelemetrySample value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetStatusResponse> getStatus_Pre($grpc.ServiceCall $call, $async.Future<$0.GetStatusRequest> $request) async {
    return getStatus($call, await $request);
  }

  $async.Future<$0.GetStatusResponse> getStatus($grpc.ServiceCall call, $0.GetStatusRequest request);

  $async.Future<$0.CalibrateResponse> calibrate_Pre($grpc.ServiceCall $call, $async.Future<$0.CalibrateRequest> $request) async {
    return calibrate($call, await $request);
  }

  $async.Future<$0.CalibrateResponse> calibrate($grpc.ServiceCall call, $0.CalibrateRequest request);

  $async.Future<$0.CancelCalibrationResponse> cancelCalibration_Pre($grpc.ServiceCall $call, $async.Future<$0.CancelCalibrationRequest> $request) async {
    return cancelCalibration($call, await $request);
  }

  $async.Future<$0.CancelCalibrationResponse> cancelCalibration($grpc.ServiceCall call, $0.CancelCalibrationRequest request);

  $async.Future<$0.SetProfileResponse> setProfile_Pre($grpc.ServiceCall $call, $async.Future<$0.SetProfileRequest> $request) async {
    return setProfile($call, await $request);
  }

  $async.Future<$0.SetProfileResponse> setProfile($grpc.ServiceCall call, $0.SetProfileRequest request);

  $async.Future<$0.EStopResponse> eStop_Pre($grpc.ServiceCall $call, $async.Future<$0.EStopRequest> $request) async {
    return eStop($call, await $request);
  }

  $async.Future<$0.EStopResponse> eStop($grpc.ServiceCall call, $0.EStopRequest request);

  $async.Future<$0.StartSessionResponse> startSession_Pre($grpc.ServiceCall $call, $async.Future<$0.StartSessionRequest> $request) async {
    return startSession($call, await $request);
  }

  $async.Future<$0.StartSessionResponse> startSession($grpc.ServiceCall call, $0.StartSessionRequest request);

  $async.Future<$0.EndSessionResponse> endSession_Pre($grpc.ServiceCall $call, $async.Future<$0.EndSessionRequest> $request) async {
    return endSession($call, await $request);
  }

  $async.Future<$0.EndSessionResponse> endSession($grpc.ServiceCall call, $0.EndSessionRequest request);

  $async.Future<$0.ListSessionsResponse> listSessions_Pre($grpc.ServiceCall $call, $async.Future<$0.ListSessionsRequest> $request) async {
    return listSessions($call, await $request);
  }

  $async.Future<$0.ListSessionsResponse> listSessions($grpc.ServiceCall call, $0.ListSessionsRequest request);

  $async.Stream<$0.TelemetrySample> streamTelemetry_Pre($grpc.ServiceCall $call, $async.Future<$0.TelemetryStreamRequest> $request) async* {
    yield* streamTelemetry($call, await $request);
  }

  $async.Stream<$0.TelemetrySample> streamTelemetry($grpc.ServiceCall call, $0.TelemetryStreamRequest request);

}
