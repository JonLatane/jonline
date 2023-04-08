///
//  Generated code. Do not modify.
//  source: authentication.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'users.pb.dart' as $4;
import 'google/protobuf/timestamp.pb.dart' as $8;

class CreateAccountRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateAccountRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'username')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'password')
    ..aOM<$4.ContactMethod>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'email', subBuilder: $4.ContactMethod.create)
    ..aOM<$4.ContactMethod>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'phone', subBuilder: $4.ContactMethod.create)
    ..aOM<$8.Timestamp>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expiresAt', subBuilder: $8.Timestamp.create)
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deviceName')
    ..hasRequiredFields = false
  ;

  CreateAccountRequest._() : super();
  factory CreateAccountRequest({
    $core.String? username,
    $core.String? password,
    $4.ContactMethod? email,
    $4.ContactMethod? phone,
    $8.Timestamp? expiresAt,
    $core.String? deviceName,
  }) {
    final _result = create();
    if (username != null) {
      _result.username = username;
    }
    if (password != null) {
      _result.password = password;
    }
    if (email != null) {
      _result.email = email;
    }
    if (phone != null) {
      _result.phone = phone;
    }
    if (expiresAt != null) {
      _result.expiresAt = expiresAt;
    }
    if (deviceName != null) {
      _result.deviceName = deviceName;
    }
    return _result;
  }
  factory CreateAccountRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateAccountRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateAccountRequest clone() => CreateAccountRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateAccountRequest copyWith(void Function(CreateAccountRequest) updates) => super.copyWith((message) => updates(message as CreateAccountRequest)) as CreateAccountRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateAccountRequest create() => CreateAccountRequest._();
  CreateAccountRequest createEmptyInstance() => create();
  static $pb.PbList<CreateAccountRequest> createRepeated() => $pb.PbList<CreateAccountRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateAccountRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateAccountRequest>(create);
  static CreateAccountRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => clearField(2);

  @$pb.TagNumber(3)
  $4.ContactMethod get email => $_getN(2);
  @$pb.TagNumber(3)
  set email($4.ContactMethod v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmail() => clearField(3);
  @$pb.TagNumber(3)
  $4.ContactMethod ensureEmail() => $_ensure(2);

  @$pb.TagNumber(4)
  $4.ContactMethod get phone => $_getN(3);
  @$pb.TagNumber(4)
  set phone($4.ContactMethod v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasPhone() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhone() => clearField(4);
  @$pb.TagNumber(4)
  $4.ContactMethod ensurePhone() => $_ensure(3);

  @$pb.TagNumber(5)
  $8.Timestamp get expiresAt => $_getN(4);
  @$pb.TagNumber(5)
  set expiresAt($8.Timestamp v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasExpiresAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearExpiresAt() => clearField(5);
  @$pb.TagNumber(5)
  $8.Timestamp ensureExpiresAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get deviceName => $_getSZ(5);
  @$pb.TagNumber(6)
  set deviceName($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasDeviceName() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeviceName() => clearField(6);
}

class LoginRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'LoginRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'username')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'password')
    ..aOM<$8.Timestamp>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expiresAt', subBuilder: $8.Timestamp.create)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deviceName')
    ..hasRequiredFields = false
  ;

  LoginRequest._() : super();
  factory LoginRequest({
    $core.String? username,
    $core.String? password,
    $8.Timestamp? expiresAt,
    $core.String? deviceName,
  }) {
    final _result = create();
    if (username != null) {
      _result.username = username;
    }
    if (password != null) {
      _result.password = password;
    }
    if (expiresAt != null) {
      _result.expiresAt = expiresAt;
    }
    if (deviceName != null) {
      _result.deviceName = deviceName;
    }
    return _result;
  }
  factory LoginRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LoginRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LoginRequest clone() => LoginRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LoginRequest copyWith(void Function(LoginRequest) updates) => super.copyWith((message) => updates(message as LoginRequest)) as LoginRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static LoginRequest create() => LoginRequest._();
  LoginRequest createEmptyInstance() => create();
  static $pb.PbList<LoginRequest> createRepeated() => $pb.PbList<LoginRequest>();
  @$core.pragma('dart2js:noInline')
  static LoginRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoginRequest>(create);
  static LoginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => clearField(2);

  @$pb.TagNumber(3)
  $8.Timestamp get expiresAt => $_getN(2);
  @$pb.TagNumber(3)
  set expiresAt($8.Timestamp v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasExpiresAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresAt() => clearField(3);
  @$pb.TagNumber(3)
  $8.Timestamp ensureExpiresAt() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get deviceName => $_getSZ(3);
  @$pb.TagNumber(4)
  set deviceName($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDeviceName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeviceName() => clearField(4);
}

class RefreshTokenResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RefreshTokenResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<ExpirableToken>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'refreshToken', subBuilder: ExpirableToken.create)
    ..aOM<ExpirableToken>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accessToken', subBuilder: ExpirableToken.create)
    ..aOM<$4.User>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'user', subBuilder: $4.User.create)
    ..hasRequiredFields = false
  ;

  RefreshTokenResponse._() : super();
  factory RefreshTokenResponse({
    ExpirableToken? refreshToken,
    ExpirableToken? accessToken,
    $4.User? user,
  }) {
    final _result = create();
    if (refreshToken != null) {
      _result.refreshToken = refreshToken;
    }
    if (accessToken != null) {
      _result.accessToken = accessToken;
    }
    if (user != null) {
      _result.user = user;
    }
    return _result;
  }
  factory RefreshTokenResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RefreshTokenResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RefreshTokenResponse clone() => RefreshTokenResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RefreshTokenResponse copyWith(void Function(RefreshTokenResponse) updates) => super.copyWith((message) => updates(message as RefreshTokenResponse)) as RefreshTokenResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RefreshTokenResponse create() => RefreshTokenResponse._();
  RefreshTokenResponse createEmptyInstance() => create();
  static $pb.PbList<RefreshTokenResponse> createRepeated() => $pb.PbList<RefreshTokenResponse>();
  @$core.pragma('dart2js:noInline')
  static RefreshTokenResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RefreshTokenResponse>(create);
  static RefreshTokenResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ExpirableToken get refreshToken => $_getN(0);
  @$pb.TagNumber(1)
  set refreshToken(ExpirableToken v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRefreshToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearRefreshToken() => clearField(1);
  @$pb.TagNumber(1)
  ExpirableToken ensureRefreshToken() => $_ensure(0);

  @$pb.TagNumber(2)
  ExpirableToken get accessToken => $_getN(1);
  @$pb.TagNumber(2)
  set accessToken(ExpirableToken v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasAccessToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccessToken() => clearField(2);
  @$pb.TagNumber(2)
  ExpirableToken ensureAccessToken() => $_ensure(1);

  @$pb.TagNumber(3)
  $4.User get user => $_getN(2);
  @$pb.TagNumber(3)
  set user($4.User v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasUser() => $_has(2);
  @$pb.TagNumber(3)
  void clearUser() => clearField(3);
  @$pb.TagNumber(3)
  $4.User ensureUser() => $_ensure(2);
}

class ExpirableToken extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ExpirableToken', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'token')
    ..aOM<$8.Timestamp>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expiresAt', subBuilder: $8.Timestamp.create)
    ..hasRequiredFields = false
  ;

  ExpirableToken._() : super();
  factory ExpirableToken({
    $core.String? token,
    $8.Timestamp? expiresAt,
  }) {
    final _result = create();
    if (token != null) {
      _result.token = token;
    }
    if (expiresAt != null) {
      _result.expiresAt = expiresAt;
    }
    return _result;
  }
  factory ExpirableToken.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExpirableToken.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExpirableToken clone() => ExpirableToken()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExpirableToken copyWith(void Function(ExpirableToken) updates) => super.copyWith((message) => updates(message as ExpirableToken)) as ExpirableToken; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ExpirableToken create() => ExpirableToken._();
  ExpirableToken createEmptyInstance() => create();
  static $pb.PbList<ExpirableToken> createRepeated() => $pb.PbList<ExpirableToken>();
  @$core.pragma('dart2js:noInline')
  static ExpirableToken getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExpirableToken>(create);
  static ExpirableToken? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => clearField(1);

  @$pb.TagNumber(2)
  $8.Timestamp get expiresAt => $_getN(1);
  @$pb.TagNumber(2)
  set expiresAt($8.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasExpiresAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiresAt() => clearField(2);
  @$pb.TagNumber(2)
  $8.Timestamp ensureExpiresAt() => $_ensure(1);
}

class AccessTokenRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AccessTokenRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'refreshToken')
    ..aOM<$8.Timestamp>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expiresAt', subBuilder: $8.Timestamp.create)
    ..hasRequiredFields = false
  ;

  AccessTokenRequest._() : super();
  factory AccessTokenRequest({
    $core.String? refreshToken,
    $8.Timestamp? expiresAt,
  }) {
    final _result = create();
    if (refreshToken != null) {
      _result.refreshToken = refreshToken;
    }
    if (expiresAt != null) {
      _result.expiresAt = expiresAt;
    }
    return _result;
  }
  factory AccessTokenRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AccessTokenRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AccessTokenRequest clone() => AccessTokenRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AccessTokenRequest copyWith(void Function(AccessTokenRequest) updates) => super.copyWith((message) => updates(message as AccessTokenRequest)) as AccessTokenRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AccessTokenRequest create() => AccessTokenRequest._();
  AccessTokenRequest createEmptyInstance() => create();
  static $pb.PbList<AccessTokenRequest> createRepeated() => $pb.PbList<AccessTokenRequest>();
  @$core.pragma('dart2js:noInline')
  static AccessTokenRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AccessTokenRequest>(create);
  static AccessTokenRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get refreshToken => $_getSZ(0);
  @$pb.TagNumber(1)
  set refreshToken($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRefreshToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearRefreshToken() => clearField(1);

  @$pb.TagNumber(2)
  $8.Timestamp get expiresAt => $_getN(1);
  @$pb.TagNumber(2)
  set expiresAt($8.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasExpiresAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiresAt() => clearField(2);
  @$pb.TagNumber(2)
  $8.Timestamp ensureExpiresAt() => $_ensure(1);
}

class AccessTokenResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AccessTokenResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<ExpirableToken>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'refreshToken', subBuilder: ExpirableToken.create)
    ..aOM<ExpirableToken>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accessToken', subBuilder: ExpirableToken.create)
    ..hasRequiredFields = false
  ;

  AccessTokenResponse._() : super();
  factory AccessTokenResponse({
    ExpirableToken? refreshToken,
    ExpirableToken? accessToken,
  }) {
    final _result = create();
    if (refreshToken != null) {
      _result.refreshToken = refreshToken;
    }
    if (accessToken != null) {
      _result.accessToken = accessToken;
    }
    return _result;
  }
  factory AccessTokenResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AccessTokenResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AccessTokenResponse clone() => AccessTokenResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AccessTokenResponse copyWith(void Function(AccessTokenResponse) updates) => super.copyWith((message) => updates(message as AccessTokenResponse)) as AccessTokenResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AccessTokenResponse create() => AccessTokenResponse._();
  AccessTokenResponse createEmptyInstance() => create();
  static $pb.PbList<AccessTokenResponse> createRepeated() => $pb.PbList<AccessTokenResponse>();
  @$core.pragma('dart2js:noInline')
  static AccessTokenResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AccessTokenResponse>(create);
  static AccessTokenResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ExpirableToken get refreshToken => $_getN(0);
  @$pb.TagNumber(1)
  set refreshToken(ExpirableToken v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRefreshToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearRefreshToken() => clearField(1);
  @$pb.TagNumber(1)
  ExpirableToken ensureRefreshToken() => $_ensure(0);

  @$pb.TagNumber(2)
  ExpirableToken get accessToken => $_getN(1);
  @$pb.TagNumber(2)
  set accessToken(ExpirableToken v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasAccessToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccessToken() => clearField(2);
  @$pb.TagNumber(2)
  ExpirableToken ensureAccessToken() => $_ensure(1);
}

