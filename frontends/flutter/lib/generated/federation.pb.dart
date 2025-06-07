//
//  Generated code. Do not modify.
//  source: federation.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Version information for the Jonline server.
class GetServiceVersionResponse extends $pb.GeneratedMessage {
  factory GetServiceVersionResponse({
    $core.String? version,
  }) {
    final result = create();
    if (version != null) result.version = version;
    return result;
  }

  GetServiceVersionResponse._();

  factory GetServiceVersionResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetServiceVersionResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetServiceVersionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServiceVersionResponse clone() => GetServiceVersionResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServiceVersionResponse copyWith(void Function(GetServiceVersionResponse) updates) => super.copyWith((message) => updates(message as GetServiceVersionResponse)) as GetServiceVersionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetServiceVersionResponse create() => GetServiceVersionResponse._();
  @$core.override
  GetServiceVersionResponse createEmptyInstance() => create();
  static $pb.PbList<GetServiceVersionResponse> createRepeated() => $pb.PbList<GetServiceVersionResponse>();
  @$core.pragma('dart2js:noInline')
  static GetServiceVersionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetServiceVersionResponse>(create);
  static GetServiceVersionResponse? _defaultInstance;

  /// The version of the Jonline server. May be suffixed with the GitHub SHA of the commit
  /// that generated the binary for the server.
  @$pb.TagNumber(1)
  $core.String get version => $_getSZ(0);
  @$pb.TagNumber(1)
  set version($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);
}

/// The federation configuration for a Jonline server.
class FederationInfo extends $pb.GeneratedMessage {
  factory FederationInfo({
    $core.Iterable<FederatedServer>? servers,
  }) {
    final result = create();
    if (servers != null) result.servers.addAll(servers);
    return result;
  }

  FederationInfo._();

  factory FederationInfo.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory FederationInfo.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FederationInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<FederatedServer>(1, _omitFieldNames ? '' : 'servers', $pb.PbFieldType.PM, subBuilder: FederatedServer.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FederationInfo clone() => FederationInfo()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FederationInfo copyWith(void Function(FederationInfo) updates) => super.copyWith((message) => updates(message as FederationInfo)) as FederationInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FederationInfo create() => FederationInfo._();
  @$core.override
  FederationInfo createEmptyInstance() => create();
  static $pb.PbList<FederationInfo> createRepeated() => $pb.PbList<FederationInfo>();
  @$core.pragma('dart2js:noInline')
  static FederationInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FederationInfo>(create);
  static FederationInfo? _defaultInstance;

  /// A list of servers that this server will federate with.
  @$pb.TagNumber(1)
  $pb.PbList<FederatedServer> get servers => $_getList(0);
}

/// A server that this server will federate with.
class FederatedServer extends $pb.GeneratedMessage {
  factory FederatedServer({
    $core.String? host,
    $core.bool? configuredByDefault,
    $core.bool? pinnedByDefault,
  }) {
    final result = create();
    if (host != null) result.host = host;
    if (configuredByDefault != null) result.configuredByDefault = configuredByDefault;
    if (pinnedByDefault != null) result.pinnedByDefault = pinnedByDefault;
    return result;
  }

  FederatedServer._();

  factory FederatedServer.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory FederatedServer.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FederatedServer', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aOB(2, _omitFieldNames ? '' : 'configuredByDefault')
    ..aOB(3, _omitFieldNames ? '' : 'pinnedByDefault')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FederatedServer clone() => FederatedServer()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FederatedServer copyWith(void Function(FederatedServer) updates) => super.copyWith((message) => updates(message as FederatedServer)) as FederatedServer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FederatedServer create() => FederatedServer._();
  @$core.override
  FederatedServer createEmptyInstance() => create();
  static $pb.PbList<FederatedServer> createRepeated() => $pb.PbList<FederatedServer>();
  @$core.pragma('dart2js:noInline')
  static FederatedServer getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FederatedServer>(create);
  static FederatedServer? _defaultInstance;

  /// The DNS hostname of the server to federate with.
  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => $_clearField(1);

  /// Indicates to UI clients that they should enable/configure the indicated server by default.
  @$pb.TagNumber(2)
  $core.bool get configuredByDefault => $_getBF(1);
  @$pb.TagNumber(2)
  set configuredByDefault($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConfiguredByDefault() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfiguredByDefault() => $_clearField(2);

  /// Indicates to UI clients that they should pin the indicated server by default
  /// (showing its Events and Posts alongside the "main" server).
  @$pb.TagNumber(3)
  $core.bool get pinnedByDefault => $_getBF(2);
  @$pb.TagNumber(3)
  set pinnedByDefault($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPinnedByDefault() => $_has(2);
  @$pb.TagNumber(3)
  void clearPinnedByDefault() => $_clearField(3);
}

/// Some user on a Jonline server.
/// Most commonly a different server than the one serving up FederatedAccount data,
/// but users may also federate multiple accounts on the same server.
class FederatedAccount extends $pb.GeneratedMessage {
  factory FederatedAccount({
    $core.String? host,
    $core.String? userId,
  }) {
    final result = create();
    if (host != null) result.host = host;
    if (userId != null) result.userId = userId;
    return result;
  }

  FederatedAccount._();

  factory FederatedAccount.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory FederatedAccount.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FederatedAccount', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FederatedAccount clone() => FederatedAccount()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FederatedAccount copyWith(void Function(FederatedAccount) updates) => super.copyWith((message) => updates(message as FederatedAccount)) as FederatedAccount;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FederatedAccount create() => FederatedAccount._();
  @$core.override
  FederatedAccount createEmptyInstance() => create();
  static $pb.PbList<FederatedAccount> createRepeated() => $pb.PbList<FederatedAccount>();
  @$core.pragma('dart2js:noInline')
  static FederatedAccount getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FederatedAccount>(create);
  static FederatedAccount? _defaultInstance;

  /// The DNS hostname of the server that this user is on.
  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => $_clearField(1);

  /// The user ID of the user on the server.
  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);
}


const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
