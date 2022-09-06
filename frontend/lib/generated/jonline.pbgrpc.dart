///
//  Generated code. Do not modify.
//  source: jonline.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'google/protobuf/empty.pb.dart' as $0;
import 'federation.pb.dart' as $1;
import 'authentication.pb.dart' as $2;
import 'users.pb.dart' as $3;
export 'jonline.pb.dart';

class JonlineClient extends $grpc.Client {
  static final _$getServiceVersion =
      $grpc.ClientMethod<$0.Empty, $1.GetServiceVersionResponse>(
          '/jonline.Jonline/GetServiceVersion',
          ($0.Empty value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $1.GetServiceVersionResponse.fromBuffer(value));
  static final _$createAccount =
      $grpc.ClientMethod<$2.CreateAccountRequest, $2.AuthTokenResponse>(
          '/jonline.Jonline/CreateAccount',
          ($2.CreateAccountRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.AuthTokenResponse.fromBuffer(value));
  static final _$login =
      $grpc.ClientMethod<$2.LoginRequest, $2.AuthTokenResponse>(
          '/jonline.Jonline/Login',
          ($2.LoginRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.AuthTokenResponse.fromBuffer(value));
  static final _$refreshToken =
      $grpc.ClientMethod<$2.RefreshTokenRequest, $2.ExpirableToken>(
          '/jonline.Jonline/RefreshToken',
          ($2.RefreshTokenRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $2.ExpirableToken.fromBuffer(value));
  static final _$getCurrentUser = $grpc.ClientMethod<$0.Empty, $3.User>(
      '/jonline.Jonline/GetCurrentUser',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.User.fromBuffer(value));

  JonlineClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$1.GetServiceVersionResponse> getServiceVersion(
      $0.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getServiceVersion, request, options: options);
  }

  $grpc.ResponseFuture<$2.AuthTokenResponse> createAccount(
      $2.CreateAccountRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createAccount, request, options: options);
  }

  $grpc.ResponseFuture<$2.AuthTokenResponse> login($2.LoginRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$login, request, options: options);
  }

  $grpc.ResponseFuture<$2.ExpirableToken> refreshToken(
      $2.RefreshTokenRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$refreshToken, request, options: options);
  }

  $grpc.ResponseFuture<$3.User> getCurrentUser($0.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getCurrentUser, request, options: options);
  }
}

abstract class JonlineServiceBase extends $grpc.Service {
  $core.String get $name => 'jonline.Jonline';

  JonlineServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GetServiceVersionResponse>(
        'GetServiceVersion',
        getServiceVersion_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GetServiceVersionResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$2.CreateAccountRequest, $2.AuthTokenResponse>(
            'CreateAccount',
            createAccount_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $2.CreateAccountRequest.fromBuffer(value),
            ($2.AuthTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.LoginRequest, $2.AuthTokenResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.LoginRequest.fromBuffer(value),
        ($2.AuthTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.RefreshTokenRequest, $2.ExpirableToken>(
        'RefreshToken',
        refreshToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.RefreshTokenRequest.fromBuffer(value),
        ($2.ExpirableToken value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $3.User>(
        'GetCurrentUser',
        getCurrentUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($3.User value) => value.writeToBuffer()));
  }

  $async.Future<$1.GetServiceVersionResponse> getServiceVersion_Pre(
      $grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return getServiceVersion(call, await request);
  }

  $async.Future<$2.AuthTokenResponse> createAccount_Pre($grpc.ServiceCall call,
      $async.Future<$2.CreateAccountRequest> request) async {
    return createAccount(call, await request);
  }

  $async.Future<$2.AuthTokenResponse> login_Pre(
      $grpc.ServiceCall call, $async.Future<$2.LoginRequest> request) async {
    return login(call, await request);
  }

  $async.Future<$2.ExpirableToken> refreshToken_Pre($grpc.ServiceCall call,
      $async.Future<$2.RefreshTokenRequest> request) async {
    return refreshToken(call, await request);
  }

  $async.Future<$3.User> getCurrentUser_Pre(
      $grpc.ServiceCall call, $async.Future<$0.Empty> request) async {
    return getCurrentUser(call, await request);
  }

  $async.Future<$1.GetServiceVersionResponse> getServiceVersion(
      $grpc.ServiceCall call, $0.Empty request);
  $async.Future<$2.AuthTokenResponse> createAccount(
      $grpc.ServiceCall call, $2.CreateAccountRequest request);
  $async.Future<$2.AuthTokenResponse> login(
      $grpc.ServiceCall call, $2.LoginRequest request);
  $async.Future<$2.ExpirableToken> refreshToken(
      $grpc.ServiceCall call, $2.RefreshTokenRequest request);
  $async.Future<$3.User> getCurrentUser(
      $grpc.ServiceCall call, $0.Empty request);
}
