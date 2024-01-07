//
//  Generated code. Do not modify.
//  source: federation.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class GetServiceVersionResponse extends $pb.GeneratedMessage {
  factory GetServiceVersionResponse({
    $core.String? version,
  }) {
    final $result = create();
    if (version != null) {
      $result.version = version;
    }
    return $result;
  }
  GetServiceVersionResponse._() : super();
  factory GetServiceVersionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetServiceVersionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetServiceVersionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetServiceVersionResponse clone() => GetServiceVersionResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetServiceVersionResponse copyWith(void Function(GetServiceVersionResponse) updates) => super.copyWith((message) => updates(message as GetServiceVersionResponse)) as GetServiceVersionResponse;

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

/// The federation configuration for a Jonline server.
class FederationInfo extends $pb.GeneratedMessage {
  factory FederationInfo({
    $core.Iterable<FederatedServer>? servers,
  }) {
    final $result = create();
    if (servers != null) {
      $result.servers.addAll(servers);
    }
    return $result;
  }
  FederationInfo._() : super();
  factory FederationInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FederationInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FederationInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<FederatedServer>(1, _omitFieldNames ? '' : 'servers', $pb.PbFieldType.PM, subBuilder: FederatedServer.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FederationInfo clone() => FederationInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FederationInfo copyWith(void Function(FederationInfo) updates) => super.copyWith((message) => updates(message as FederationInfo)) as FederationInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FederationInfo create() => FederationInfo._();
  FederationInfo createEmptyInstance() => create();
  static $pb.PbList<FederationInfo> createRepeated() => $pb.PbList<FederationInfo>();
  @$core.pragma('dart2js:noInline')
  static FederationInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FederationInfo>(create);
  static FederationInfo? _defaultInstance;

  /// A list of servers that this server will federate with.
  @$pb.TagNumber(1)
  $core.List<FederatedServer> get servers => $_getList(0);
}

/// A server that this server will federate with.
class FederatedServer extends $pb.GeneratedMessage {
  factory FederatedServer({
    $core.String? host,
    $core.bool? configuredByDefault,
    $core.bool? pinnedByDefault,
  }) {
    final $result = create();
    if (host != null) {
      $result.host = host;
    }
    if (configuredByDefault != null) {
      $result.configuredByDefault = configuredByDefault;
    }
    if (pinnedByDefault != null) {
      $result.pinnedByDefault = pinnedByDefault;
    }
    return $result;
  }
  FederatedServer._() : super();
  factory FederatedServer.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FederatedServer.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FederatedServer', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aOB(2, _omitFieldNames ? '' : 'configuredByDefault')
    ..aOB(3, _omitFieldNames ? '' : 'pinnedByDefault')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FederatedServer clone() => FederatedServer()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FederatedServer copyWith(void Function(FederatedServer) updates) => super.copyWith((message) => updates(message as FederatedServer)) as FederatedServer;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FederatedServer create() => FederatedServer._();
  FederatedServer createEmptyInstance() => create();
  static $pb.PbList<FederatedServer> createRepeated() => $pb.PbList<FederatedServer>();
  @$core.pragma('dart2js:noInline')
  static FederatedServer getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FederatedServer>(create);
  static FederatedServer? _defaultInstance;

  /// The DNS hostname of the server to federate with.
  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => clearField(1);

  /// Indicates to UI clients that they should enable/configure the indicated server by default.
  @$pb.TagNumber(2)
  $core.bool get configuredByDefault => $_getBF(1);
  @$pb.TagNumber(2)
  set configuredByDefault($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasConfiguredByDefault() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfiguredByDefault() => clearField(2);

  /// Indicates to UI clients that they should pin the indicated server by default
  /// (showing its Events and Posts alongside the "main" server).
  @$pb.TagNumber(3)
  $core.bool get pinnedByDefault => $_getBF(2);
  @$pb.TagNumber(3)
  set pinnedByDefault($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPinnedByDefault() => $_has(2);
  @$pb.TagNumber(3)
  void clearPinnedByDefault() => clearField(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
