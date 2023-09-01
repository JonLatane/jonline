//
//  Generated code. Do not modify.
//  source: authentication.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $9;
import 'users.pb.dart' as $4;

/// Request to create a new account.
class CreateAccountRequest extends $pb.GeneratedMessage {
  factory CreateAccountRequest({
    $core.String? username,
    $core.String? password,
    $4.ContactMethod? email,
    $4.ContactMethod? phone,
    $9.Timestamp? expiresAt,
    $core.String? deviceName,
  }) {
    final $result = create();
    if (username != null) {
      $result.username = username;
    }
    if (password != null) {
      $result.password = password;
    }
    if (email != null) {
      $result.email = email;
    }
    if (phone != null) {
      $result.phone = phone;
    }
    if (expiresAt != null) {
      $result.expiresAt = expiresAt;
    }
    if (deviceName != null) {
      $result.deviceName = deviceName;
    }
    return $result;
  }
  CreateAccountRequest._() : super();
  factory CreateAccountRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateAccountRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CreateAccountRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..aOM<$4.ContactMethod>(3, _omitFieldNames ? '' : 'email', subBuilder: $4.ContactMethod.create)
    ..aOM<$4.ContactMethod>(4, _omitFieldNames ? '' : 'phone', subBuilder: $4.ContactMethod.create)
    ..aOM<$9.Timestamp>(5, _omitFieldNames ? '' : 'expiresAt', subBuilder: $9.Timestamp.create)
    ..aOS(6, _omitFieldNames ? '' : 'deviceName')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateAccountRequest clone() => CreateAccountRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateAccountRequest copyWith(void Function(CreateAccountRequest) updates) => super.copyWith((message) => updates(message as CreateAccountRequest)) as CreateAccountRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateAccountRequest create() => CreateAccountRequest._();
  CreateAccountRequest createEmptyInstance() => create();
  static $pb.PbList<CreateAccountRequest> createRepeated() => $pb.PbList<CreateAccountRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateAccountRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateAccountRequest>(create);
  static CreateAccountRequest? _defaultInstance;

  /// Username for the account to be created. Must not exist.
  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => clearField(1);

  /// Password for the account to be created. Must be at least 8 characters.
  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => clearField(2);

  /// Email to be used as a contact method.
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

  /// Phone number to be used as a contact method.
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

  /// Request an expiration time for the Auth Token returned. By default it will not expire.
  @$pb.TagNumber(5)
  $9.Timestamp get expiresAt => $_getN(4);
  @$pb.TagNumber(5)
  set expiresAt($9.Timestamp v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasExpiresAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearExpiresAt() => clearField(5);
  @$pb.TagNumber(5)
  $9.Timestamp ensureExpiresAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get deviceName => $_getSZ(5);
  @$pb.TagNumber(6)
  set deviceName($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasDeviceName() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeviceName() => clearField(6);
}

/// Request to login to an existing account.
class LoginRequest extends $pb.GeneratedMessage {
  factory LoginRequest({
    $core.String? username,
    $core.String? password,
    $9.Timestamp? expiresAt,
    $core.String? deviceName,
    $core.String? userId,
  }) {
    final $result = create();
    if (username != null) {
      $result.username = username;
    }
    if (password != null) {
      $result.password = password;
    }
    if (expiresAt != null) {
      $result.expiresAt = expiresAt;
    }
    if (deviceName != null) {
      $result.deviceName = deviceName;
    }
    if (userId != null) {
      $result.userId = userId;
    }
    return $result;
  }
  LoginRequest._() : super();
  factory LoginRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LoginRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LoginRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..aOM<$9.Timestamp>(3, _omitFieldNames ? '' : 'expiresAt', subBuilder: $9.Timestamp.create)
    ..aOS(4, _omitFieldNames ? '' : 'deviceName')
    ..aOS(5, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LoginRequest clone() => LoginRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LoginRequest copyWith(void Function(LoginRequest) updates) => super.copyWith((message) => updates(message as LoginRequest)) as LoginRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginRequest create() => LoginRequest._();
  LoginRequest createEmptyInstance() => create();
  static $pb.PbList<LoginRequest> createRepeated() => $pb.PbList<LoginRequest>();
  @$core.pragma('dart2js:noInline')
  static LoginRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoginRequest>(create);
  static LoginRequest? _defaultInstance;

  /// Username for the account to be logged into. Must exist.
  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => clearField(1);

  /// Password for the account to be logged into.
  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => clearField(2);

  /// Request an expiration time for the Auth Token returned. By default it will not expire.
  @$pb.TagNumber(3)
  $9.Timestamp get expiresAt => $_getN(2);
  @$pb.TagNumber(3)
  set expiresAt($9.Timestamp v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasExpiresAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresAt() => clearField(3);
  @$pb.TagNumber(3)
  $9.Timestamp ensureExpiresAt() => $_ensure(2);

  /// (Not yet implemented.)
  @$pb.TagNumber(4)
  $core.String get deviceName => $_getSZ(3);
  @$pb.TagNumber(4)
  set deviceName($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDeviceName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeviceName() => clearField(4);

  /// (TODO) If provided, username is ignored and login is initiated via user_id instead.
  @$pb.TagNumber(5)
  $core.String get userId => $_getSZ(4);
  @$pb.TagNumber(5)
  set userId($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasUserId() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserId() => clearField(5);
}

/// Returned when creating an account or logging in.
class RefreshTokenResponse extends $pb.GeneratedMessage {
  factory RefreshTokenResponse({
    ExpirableToken? refreshToken,
    ExpirableToken? accessToken,
    $4.User? user,
  }) {
    final $result = create();
    if (refreshToken != null) {
      $result.refreshToken = refreshToken;
    }
    if (accessToken != null) {
      $result.accessToken = accessToken;
    }
    if (user != null) {
      $result.user = user;
    }
    return $result;
  }
  RefreshTokenResponse._() : super();
  factory RefreshTokenResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RefreshTokenResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RefreshTokenResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<ExpirableToken>(1, _omitFieldNames ? '' : 'refreshToken', subBuilder: ExpirableToken.create)
    ..aOM<ExpirableToken>(2, _omitFieldNames ? '' : 'accessToken', subBuilder: ExpirableToken.create)
    ..aOM<$4.User>(3, _omitFieldNames ? '' : 'user', subBuilder: $4.User.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RefreshTokenResponse clone() => RefreshTokenResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RefreshTokenResponse copyWith(void Function(RefreshTokenResponse) updates) => super.copyWith((message) => updates(message as RefreshTokenResponse)) as RefreshTokenResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshTokenResponse create() => RefreshTokenResponse._();
  RefreshTokenResponse createEmptyInstance() => create();
  static $pb.PbList<RefreshTokenResponse> createRepeated() => $pb.PbList<RefreshTokenResponse>();
  @$core.pragma('dart2js:noInline')
  static RefreshTokenResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RefreshTokenResponse>(create);
  static RefreshTokenResponse? _defaultInstance;

  /// The persisted token the device should store and associate with the account.
  /// Used to request new access tokens.
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

  /// An initial access token provided for convenience.
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

  /// The user associated with the account that was created/logged into.
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

/// Generic type for refresh and access tokens.
class ExpirableToken extends $pb.GeneratedMessage {
  factory ExpirableToken({
    $core.String? token,
    $9.Timestamp? expiresAt,
  }) {
    final $result = create();
    if (token != null) {
      $result.token = token;
    }
    if (expiresAt != null) {
      $result.expiresAt = expiresAt;
    }
    return $result;
  }
  ExpirableToken._() : super();
  factory ExpirableToken.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExpirableToken.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExpirableToken', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOM<$9.Timestamp>(2, _omitFieldNames ? '' : 'expiresAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExpirableToken clone() => ExpirableToken()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExpirableToken copyWith(void Function(ExpirableToken) updates) => super.copyWith((message) => updates(message as ExpirableToken)) as ExpirableToken;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExpirableToken create() => ExpirableToken._();
  ExpirableToken createEmptyInstance() => create();
  static $pb.PbList<ExpirableToken> createRepeated() => $pb.PbList<ExpirableToken>();
  @$core.pragma('dart2js:noInline')
  static ExpirableToken getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExpirableToken>(create);
  static ExpirableToken? _defaultInstance;

  /// The secure token value.
  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => clearField(1);

  /// Optional expiration time for the token. If not set, the token will not expire.
  @$pb.TagNumber(2)
  $9.Timestamp get expiresAt => $_getN(1);
  @$pb.TagNumber(2)
  set expiresAt($9.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasExpiresAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiresAt() => clearField(2);
  @$pb.TagNumber(2)
  $9.Timestamp ensureExpiresAt() => $_ensure(1);
}

/// Request for a new access token using a refresh token.
class AccessTokenRequest extends $pb.GeneratedMessage {
  factory AccessTokenRequest({
    $core.String? refreshToken,
    $9.Timestamp? expiresAt,
  }) {
    final $result = create();
    if (refreshToken != null) {
      $result.refreshToken = refreshToken;
    }
    if (expiresAt != null) {
      $result.expiresAt = expiresAt;
    }
    return $result;
  }
  AccessTokenRequest._() : super();
  factory AccessTokenRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AccessTokenRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AccessTokenRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'refreshToken')
    ..aOM<$9.Timestamp>(2, _omitFieldNames ? '' : 'expiresAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AccessTokenRequest clone() => AccessTokenRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AccessTokenRequest copyWith(void Function(AccessTokenRequest) updates) => super.copyWith((message) => updates(message as AccessTokenRequest)) as AccessTokenRequest;

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

  /// Optional *requested* expiration time for the token. Server may ignore this.
  @$pb.TagNumber(2)
  $9.Timestamp get expiresAt => $_getN(1);
  @$pb.TagNumber(2)
  set expiresAt($9.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasExpiresAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiresAt() => clearField(2);
  @$pb.TagNumber(2)
  $9.Timestamp ensureExpiresAt() => $_ensure(1);
}

/// Returned when requesting access tokens.
class AccessTokenResponse extends $pb.GeneratedMessage {
  factory AccessTokenResponse({
    ExpirableToken? refreshToken,
    ExpirableToken? accessToken,
  }) {
    final $result = create();
    if (refreshToken != null) {
      $result.refreshToken = refreshToken;
    }
    if (accessToken != null) {
      $result.accessToken = accessToken;
    }
    return $result;
  }
  AccessTokenResponse._() : super();
  factory AccessTokenResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AccessTokenResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AccessTokenResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<ExpirableToken>(1, _omitFieldNames ? '' : 'refreshToken', subBuilder: ExpirableToken.create)
    ..aOM<ExpirableToken>(2, _omitFieldNames ? '' : 'accessToken', subBuilder: ExpirableToken.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AccessTokenResponse clone() => AccessTokenResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AccessTokenResponse copyWith(void Function(AccessTokenResponse) updates) => super.copyWith((message) => updates(message as AccessTokenResponse)) as AccessTokenResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AccessTokenResponse create() => AccessTokenResponse._();
  AccessTokenResponse createEmptyInstance() => create();
  static $pb.PbList<AccessTokenResponse> createRepeated() => $pb.PbList<AccessTokenResponse>();
  @$core.pragma('dart2js:noInline')
  static AccessTokenResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AccessTokenResponse>(create);
  static AccessTokenResponse? _defaultInstance;

  /// If a refresh token is returned, it should be stored. Old refresh tokens may expire *before*
  /// their indicated expiration.
  /// See: https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation
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


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
