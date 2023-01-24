///
//  Generated code. Do not modify.
//  source: federation.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'federation.pbenum.dart';

export 'federation.pbenum.dart';

class GetServiceVersionResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetServiceVersionResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'version')
    ..hasRequiredFields = false
  ;

  GetServiceVersionResponse._() : super();
  factory GetServiceVersionResponse({
    $core.String? version,
  }) {
    final _result = create();
    if (version != null) {
      _result.version = version;
    }
    return _result;
  }
  factory GetServiceVersionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetServiceVersionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetServiceVersionResponse clone() => GetServiceVersionResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetServiceVersionResponse copyWith(void Function(GetServiceVersionResponse) updates) => super.copyWith((message) => updates(message as GetServiceVersionResponse)) as GetServiceVersionResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetServiceVersionResponse create() => GetServiceVersionResponse._();
  GetServiceVersionResponse createEmptyInstance() => create();
  static $pb.PbList<GetServiceVersionResponse> createRepeated() => $pb.PbList<GetServiceVersionResponse>();
  @$core.pragma('dart2js:noInline')
  static GetServiceVersionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetServiceVersionResponse>(create);
  static GetServiceVersionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get version => $_getSZ(0);
  @$pb.TagNumber(1)
  set version($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => clearField(1);
}

class FederateRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FederateRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'server')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'preexistingAccount')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'username')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'password')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'refreshToken')
    ..e<FederationCredentials>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'storedCredentials', $pb.PbFieldType.OE, defaultOrMaker: FederationCredentials.REFRESH_TOKEN_ONLY, valueOf: FederationCredentials.valueOf, enumValues: FederationCredentials.values)
    ..e<FederationCredentials>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'returnedCredentials', $pb.PbFieldType.OE, defaultOrMaker: FederationCredentials.REFRESH_TOKEN_ONLY, valueOf: FederationCredentials.valueOf, enumValues: FederationCredentials.values)
    ..hasRequiredFields = false
  ;

  FederateRequest._() : super();
  factory FederateRequest({
    $core.String? server,
    $core.bool? preexistingAccount,
    $core.String? username,
    $core.String? password,
    $core.String? refreshToken,
    FederationCredentials? storedCredentials,
    FederationCredentials? returnedCredentials,
  }) {
    final _result = create();
    if (server != null) {
      _result.server = server;
    }
    if (preexistingAccount != null) {
      _result.preexistingAccount = preexistingAccount;
    }
    if (username != null) {
      _result.username = username;
    }
    if (password != null) {
      _result.password = password;
    }
    if (refreshToken != null) {
      _result.refreshToken = refreshToken;
    }
    if (storedCredentials != null) {
      _result.storedCredentials = storedCredentials;
    }
    if (returnedCredentials != null) {
      _result.returnedCredentials = returnedCredentials;
    }
    return _result;
  }
  factory FederateRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FederateRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FederateRequest clone() => FederateRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FederateRequest copyWith(void Function(FederateRequest) updates) => super.copyWith((message) => updates(message as FederateRequest)) as FederateRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FederateRequest create() => FederateRequest._();
  FederateRequest createEmptyInstance() => create();
  static $pb.PbList<FederateRequest> createRepeated() => $pb.PbList<FederateRequest>();
  @$core.pragma('dart2js:noInline')
  static FederateRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FederateRequest>(create);
  static FederateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get server => $_getSZ(0);
  @$pb.TagNumber(1)
  set server($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasServer() => $_has(0);
  @$pb.TagNumber(1)
  void clearServer() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get preexistingAccount => $_getBF(1);
  @$pb.TagNumber(2)
  set preexistingAccount($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPreexistingAccount() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreexistingAccount() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get username => $_getSZ(2);
  @$pb.TagNumber(3)
  set username($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUsername() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsername() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get password => $_getSZ(3);
  @$pb.TagNumber(4)
  set password($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPassword() => $_has(3);
  @$pb.TagNumber(4)
  void clearPassword() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get refreshToken => $_getSZ(4);
  @$pb.TagNumber(5)
  set refreshToken($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasRefreshToken() => $_has(4);
  @$pb.TagNumber(5)
  void clearRefreshToken() => clearField(5);

  @$pb.TagNumber(6)
  FederationCredentials get storedCredentials => $_getN(5);
  @$pb.TagNumber(6)
  set storedCredentials(FederationCredentials v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasStoredCredentials() => $_has(5);
  @$pb.TagNumber(6)
  void clearStoredCredentials() => clearField(6);

  @$pb.TagNumber(7)
  FederationCredentials get returnedCredentials => $_getN(6);
  @$pb.TagNumber(7)
  set returnedCredentials(FederationCredentials v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasReturnedCredentials() => $_has(6);
  @$pb.TagNumber(7)
  void clearReturnedCredentials() => clearField(7);
}

class FederateResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FederateResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'refreshToken')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'password')
    ..hasRequiredFields = false
  ;

  FederateResponse._() : super();
  factory FederateResponse({
    $core.String? refreshToken,
    $core.String? password,
  }) {
    final _result = create();
    if (refreshToken != null) {
      _result.refreshToken = refreshToken;
    }
    if (password != null) {
      _result.password = password;
    }
    return _result;
  }
  factory FederateResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FederateResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FederateResponse clone() => FederateResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FederateResponse copyWith(void Function(FederateResponse) updates) => super.copyWith((message) => updates(message as FederateResponse)) as FederateResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FederateResponse create() => FederateResponse._();
  FederateResponse createEmptyInstance() => create();
  static $pb.PbList<FederateResponse> createRepeated() => $pb.PbList<FederateResponse>();
  @$core.pragma('dart2js:noInline')
  static FederateResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FederateResponse>(create);
  static FederateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get refreshToken => $_getSZ(0);
  @$pb.TagNumber(1)
  set refreshToken($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRefreshToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearRefreshToken() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => clearField(2);
}

class GetFederatedAccountsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetFederatedAccountsRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..e<FederationCredentials>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'returnedCredentials', $pb.PbFieldType.OE, defaultOrMaker: FederationCredentials.REFRESH_TOKEN_ONLY, valueOf: FederationCredentials.valueOf, enumValues: FederationCredentials.values)
    ..hasRequiredFields = false
  ;

  GetFederatedAccountsRequest._() : super();
  factory GetFederatedAccountsRequest({
    FederationCredentials? returnedCredentials,
  }) {
    final _result = create();
    if (returnedCredentials != null) {
      _result.returnedCredentials = returnedCredentials;
    }
    return _result;
  }
  factory GetFederatedAccountsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetFederatedAccountsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetFederatedAccountsRequest clone() => GetFederatedAccountsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetFederatedAccountsRequest copyWith(void Function(GetFederatedAccountsRequest) updates) => super.copyWith((message) => updates(message as GetFederatedAccountsRequest)) as GetFederatedAccountsRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetFederatedAccountsRequest create() => GetFederatedAccountsRequest._();
  GetFederatedAccountsRequest createEmptyInstance() => create();
  static $pb.PbList<GetFederatedAccountsRequest> createRepeated() => $pb.PbList<GetFederatedAccountsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetFederatedAccountsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetFederatedAccountsRequest>(create);
  static GetFederatedAccountsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  FederationCredentials get returnedCredentials => $_getN(0);
  @$pb.TagNumber(1)
  set returnedCredentials(FederationCredentials v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasReturnedCredentials() => $_has(0);
  @$pb.TagNumber(1)
  void clearReturnedCredentials() => clearField(1);
}

class GetFederatedAccountsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetFederatedAccountsResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<FederatedAccount>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'federatedAccounts', $pb.PbFieldType.PM, subBuilder: FederatedAccount.create)
    ..hasRequiredFields = false
  ;

  GetFederatedAccountsResponse._() : super();
  factory GetFederatedAccountsResponse({
    $core.Iterable<FederatedAccount>? federatedAccounts,
  }) {
    final _result = create();
    if (federatedAccounts != null) {
      _result.federatedAccounts.addAll(federatedAccounts);
    }
    return _result;
  }
  factory GetFederatedAccountsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetFederatedAccountsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetFederatedAccountsResponse clone() => GetFederatedAccountsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetFederatedAccountsResponse copyWith(void Function(GetFederatedAccountsResponse) updates) => super.copyWith((message) => updates(message as GetFederatedAccountsResponse)) as GetFederatedAccountsResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetFederatedAccountsResponse create() => GetFederatedAccountsResponse._();
  GetFederatedAccountsResponse createEmptyInstance() => create();
  static $pb.PbList<GetFederatedAccountsResponse> createRepeated() => $pb.PbList<GetFederatedAccountsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetFederatedAccountsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetFederatedAccountsResponse>(create);
  static GetFederatedAccountsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<FederatedAccount> get federatedAccounts => $_getList(0);
}

class FederatedAccount extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FederatedAccount', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'server')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'username')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'password')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'refreshToken')
    ..hasRequiredFields = false
  ;

  FederatedAccount._() : super();
  factory FederatedAccount({
    $core.String? id,
    $core.String? server,
    $core.String? username,
    $core.String? password,
    $core.String? refreshToken,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (server != null) {
      _result.server = server;
    }
    if (username != null) {
      _result.username = username;
    }
    if (password != null) {
      _result.password = password;
    }
    if (refreshToken != null) {
      _result.refreshToken = refreshToken;
    }
    return _result;
  }
  factory FederatedAccount.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FederatedAccount.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FederatedAccount clone() => FederatedAccount()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FederatedAccount copyWith(void Function(FederatedAccount) updates) => super.copyWith((message) => updates(message as FederatedAccount)) as FederatedAccount; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FederatedAccount create() => FederatedAccount._();
  FederatedAccount createEmptyInstance() => create();
  static $pb.PbList<FederatedAccount> createRepeated() => $pb.PbList<FederatedAccount>();
  @$core.pragma('dart2js:noInline')
  static FederatedAccount getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FederatedAccount>(create);
  static FederatedAccount? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get server => $_getSZ(1);
  @$pb.TagNumber(2)
  set server($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasServer() => $_has(1);
  @$pb.TagNumber(2)
  void clearServer() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get username => $_getSZ(2);
  @$pb.TagNumber(3)
  set username($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUsername() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsername() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get password => $_getSZ(3);
  @$pb.TagNumber(4)
  set password($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPassword() => $_has(3);
  @$pb.TagNumber(4)
  void clearPassword() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get refreshToken => $_getSZ(4);
  @$pb.TagNumber(5)
  set refreshToken($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasRefreshToken() => $_has(4);
  @$pb.TagNumber(5)
  void clearRefreshToken() => clearField(5);
}

