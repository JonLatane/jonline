// This is a generated file - do not edit.
//
// Generated from server_configuration.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'federation.pb.dart' as $0;
import 'permissions.pbenum.dart' as $1;
import 'server_configuration.pbenum.dart';
import 'visibility_moderation.pbenum.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'server_configuration.pbenum.dart';

/// Configuration for a Jonline server instance.
class ServerConfiguration extends $pb.GeneratedMessage {
  factory ServerConfiguration({
    ServerInfo? serverInfo,
    $0.FederationInfo? federationInfo,
    $core.Iterable<$1.Permission>? anonymousUserPermissions,
    $core.Iterable<$1.Permission>? defaultUserPermissions,
    $core.Iterable<$1.Permission>? basicUserPermissions,
    FeatureSettings? peopleSettings,
    FeatureSettings? groupSettings,
    PostSettings? postSettings,
    EventSettings? eventSettings,
    MediaSettings? mediaSettings,
    ExternalCDNConfig? externalCdnConfig,
    PrivateUserStrategy? privateUserStrategy,
    $core.Iterable<AuthenticationFeature>? authenticationFeatures,
    WebPushConfig? webPushConfig,
  }) {
    final result = create();
    if (serverInfo != null) result.serverInfo = serverInfo;
    if (federationInfo != null) result.federationInfo = federationInfo;
    if (anonymousUserPermissions != null)
      result.anonymousUserPermissions.addAll(anonymousUserPermissions);
    if (defaultUserPermissions != null)
      result.defaultUserPermissions.addAll(defaultUserPermissions);
    if (basicUserPermissions != null)
      result.basicUserPermissions.addAll(basicUserPermissions);
    if (peopleSettings != null) result.peopleSettings = peopleSettings;
    if (groupSettings != null) result.groupSettings = groupSettings;
    if (postSettings != null) result.postSettings = postSettings;
    if (eventSettings != null) result.eventSettings = eventSettings;
    if (mediaSettings != null) result.mediaSettings = mediaSettings;
    if (externalCdnConfig != null) result.externalCdnConfig = externalCdnConfig;
    if (privateUserStrategy != null)
      result.privateUserStrategy = privateUserStrategy;
    if (authenticationFeatures != null)
      result.authenticationFeatures.addAll(authenticationFeatures);
    if (webPushConfig != null) result.webPushConfig = webPushConfig;
    return result;
  }

  ServerConfiguration._();

  factory ServerConfiguration.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerConfiguration.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerConfiguration',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOM<ServerInfo>(1, _omitFieldNames ? '' : 'serverInfo',
        subBuilder: ServerInfo.create)
    ..aOM<$0.FederationInfo>(2, _omitFieldNames ? '' : 'federationInfo',
        subBuilder: $0.FederationInfo.create)
    ..pc<$1.Permission>(10, _omitFieldNames ? '' : 'anonymousUserPermissions',
        $pb.PbFieldType.KE,
        valueOf: $1.Permission.valueOf,
        enumValues: $1.Permission.values,
        defaultEnumValue: $1.Permission.PERMISSION_UNKNOWN)
    ..pc<$1.Permission>(
        11, _omitFieldNames ? '' : 'defaultUserPermissions', $pb.PbFieldType.KE,
        valueOf: $1.Permission.valueOf,
        enumValues: $1.Permission.values,
        defaultEnumValue: $1.Permission.PERMISSION_UNKNOWN)
    ..pc<$1.Permission>(
        12, _omitFieldNames ? '' : 'basicUserPermissions', $pb.PbFieldType.KE,
        valueOf: $1.Permission.valueOf,
        enumValues: $1.Permission.values,
        defaultEnumValue: $1.Permission.PERMISSION_UNKNOWN)
    ..aOM<FeatureSettings>(20, _omitFieldNames ? '' : 'peopleSettings',
        subBuilder: FeatureSettings.create)
    ..aOM<FeatureSettings>(21, _omitFieldNames ? '' : 'groupSettings',
        subBuilder: FeatureSettings.create)
    ..aOM<PostSettings>(22, _omitFieldNames ? '' : 'postSettings',
        subBuilder: PostSettings.create)
    ..aOM<EventSettings>(23, _omitFieldNames ? '' : 'eventSettings',
        subBuilder: EventSettings.create)
    ..aOM<MediaSettings>(24, _omitFieldNames ? '' : 'mediaSettings',
        subBuilder: MediaSettings.create)
    ..aOM<ExternalCDNConfig>(90, _omitFieldNames ? '' : 'externalCdnConfig',
        subBuilder: ExternalCDNConfig.create)
    ..aE<PrivateUserStrategy>(100, _omitFieldNames ? '' : 'privateUserStrategy',
        enumValues: PrivateUserStrategy.values)
    ..pc<AuthenticationFeature>(101,
        _omitFieldNames ? '' : 'authenticationFeatures', $pb.PbFieldType.KE,
        valueOf: AuthenticationFeature.valueOf,
        enumValues: AuthenticationFeature.values,
        defaultEnumValue: AuthenticationFeature.AUTHENTICATION_FEATURE_UNKNOWN)
    ..aOM<WebPushConfig>(110, _omitFieldNames ? '' : 'webPushConfig',
        subBuilder: WebPushConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerConfiguration clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerConfiguration copyWith(void Function(ServerConfiguration) updates) =>
      super.copyWith((message) => updates(message as ServerConfiguration))
          as ServerConfiguration;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerConfiguration create() => ServerConfiguration._();
  @$core.override
  ServerConfiguration createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerConfiguration getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerConfiguration>(create);
  static ServerConfiguration? _defaultInstance;

  /// The name, description, logo, color scheme, etc. of the server.
  @$pb.TagNumber(1)
  ServerInfo get serverInfo => $_getN(0);
  @$pb.TagNumber(1)
  set serverInfo(ServerInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasServerInfo() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerInfo() => $_clearField(1);
  @$pb.TagNumber(1)
  ServerInfo ensureServerInfo() => $_ensure(0);

  /// The federation configuration for the server.
  @$pb.TagNumber(2)
  $0.FederationInfo get federationInfo => $_getN(1);
  @$pb.TagNumber(2)
  set federationInfo($0.FederationInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFederationInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearFederationInfo() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.FederationInfo ensureFederationInfo() => $_ensure(1);

  /// Permissions for a user who isn't logged in to the server. Allows
  /// admins to disable certain features for anonymous users. Valid values are
  /// `VIEW_USERS`, `VIEW_GROUPS`, `VIEW_POSTS`, and `VIEW_EVENTS`.
  @$pb.TagNumber(10)
  $pb.PbList<$1.Permission> get anonymousUserPermissions => $_getList(2);

  /// Default user permissions given to a new user. Users with `MODERATE_USERS` permission can also
  /// grant/revoke these permissions for others. Valid values are
  /// `VIEW_USERS`, `PUBLISH_USERS_LOCALLY`, `PUBLISH_USERS_GLOBALLY`,
  /// `VIEW_GROUPS`, `CREATE_GROUPS`, `PUBLISH_GROUPS_LOCALLY`, `PUBLISH_GROUPS_GLOBALLY`, `JOIN_GROUPS`,
  /// `VIEW_POSTS`, `CREATE_POSTS`, `PUBLISH_POSTS_LOCALLY`, `PUBLISH_POSTS_GLOBALLY`,
  /// `VIEW_EVENTS`, `CREATE_EVENTS`, `PUBLISH_EVENTS_LOCALLY`, and `PUBLISH_EVENTS_GLOBALLY`.
  @$pb.TagNumber(11)
  $pb.PbList<$1.Permission> get defaultUserPermissions => $_getList(3);

  /// Permissions grantable by a user with the `GRANT_BASIC_PERMISSIONS` permission. Valid values are
  /// `VIEW_USERS`, `PUBLISH_USERS_LOCALLY`, `PUBLISH_USERS_GLOBALLY`,
  /// `VIEW_GROUPS`, `CREATE_GROUPS`, `PUBLISH_GROUPS_LOCALLY`, `PUBLISH_GROUPS_GLOBALLY`, `JOIN_GROUPS`,
  /// `VIEW_POSTS`, `CREATE_POSTS`, `PUBLISH_POSTS_LOCALLY`, `PUBLISH_POSTS_GLOBALLY`,
  /// `VIEW_EVENTS`, `CREATE_EVENTS`, `PUBLISH_EVENTS_LOCALLY`, and `PUBLISH_EVENTS_GLOBALLY`.
  @$pb.TagNumber(12)
  $pb.PbList<$1.Permission> get basicUserPermissions => $_getList(4);

  /// Configuration for users on the server.
  /// If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must*
  /// contain `PUBLISH_USERS_GLOBALLY`.
  @$pb.TagNumber(20)
  FeatureSettings get peopleSettings => $_getN(5);
  @$pb.TagNumber(20)
  set peopleSettings(FeatureSettings value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasPeopleSettings() => $_has(5);
  @$pb.TagNumber(20)
  void clearPeopleSettings() => $_clearField(20);
  @$pb.TagNumber(20)
  FeatureSettings ensurePeopleSettings() => $_ensure(5);

  /// Configuration for groups on the server.
  /// If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must*
  /// contain `PUBLISH_GROUPS_GLOBALLY`.
  @$pb.TagNumber(21)
  FeatureSettings get groupSettings => $_getN(6);
  @$pb.TagNumber(21)
  set groupSettings(FeatureSettings value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasGroupSettings() => $_has(6);
  @$pb.TagNumber(21)
  void clearGroupSettings() => $_clearField(21);
  @$pb.TagNumber(21)
  FeatureSettings ensureGroupSettings() => $_ensure(6);

  /// Configuration for posts on the server.
  /// If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must*
  /// contain `PUBLISH_POSTS_GLOBALLY`.
  @$pb.TagNumber(22)
  PostSettings get postSettings => $_getN(7);
  @$pb.TagNumber(22)
  set postSettings(PostSettings value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasPostSettings() => $_has(7);
  @$pb.TagNumber(22)
  void clearPostSettings() => $_clearField(22);
  @$pb.TagNumber(22)
  PostSettings ensurePostSettings() => $_ensure(7);

  /// Configuration for events on the server.
  /// If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must*
  /// contain `PUBLISH_EVENTS_GLOBALLY`.
  @$pb.TagNumber(23)
  EventSettings get eventSettings => $_getN(8);
  @$pb.TagNumber(23)
  set eventSettings(EventSettings value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasEventSettings() => $_has(8);
  @$pb.TagNumber(23)
  void clearEventSettings() => $_clearField(23);
  @$pb.TagNumber(23)
  EventSettings ensureEventSettings() => $_ensure(8);

  /// Configuration for media on the server.
  /// If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must*
  /// contain `PUBLISH_MEDIA_GLOBALLY`.
  @$pb.TagNumber(24)
  MediaSettings get mediaSettings => $_getN(9);
  @$pb.TagNumber(24)
  set mediaSettings(MediaSettings value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasMediaSettings() => $_has(9);
  @$pb.TagNumber(24)
  void clearMediaSettings() => $_clearField(24);
  @$pb.TagNumber(24)
  MediaSettings ensureMediaSettings() => $_ensure(9);

  /// If set, enables External CDN support for the server. This means that the
  /// non-secure HTTP server (on port 80) will *not* redirect to the secure server,
  /// and instead serve up Tamagui Web/Flutter clients directly. This allows you
  /// to point Cloudflare's "CNAME HTTPS Proxy" feature at your Jonline server to serve
  /// up HTML/CS/JS and Media files with caching from Cloudflare's CDN.
  /// See ExternalCDNConfig for more details on securing this setup.
  @$pb.TagNumber(90)
  ExternalCDNConfig get externalCdnConfig => $_getN(10);
  @$pb.TagNumber(90)
  set externalCdnConfig(ExternalCDNConfig value) => $_setField(90, value);
  @$pb.TagNumber(90)
  $core.bool hasExternalCdnConfig() => $_has(10);
  @$pb.TagNumber(90)
  void clearExternalCdnConfig() => $_clearField(90);
  @$pb.TagNumber(90)
  ExternalCDNConfig ensureExternalCdnConfig() => $_ensure(10);

  /// Strategy when a user sets their visibility to `PRIVATE`. Defaults to `ACCOUNT_IS_FROZEN`.
  @$pb.TagNumber(100)
  PrivateUserStrategy get privateUserStrategy => $_getN(11);
  @$pb.TagNumber(100)
  set privateUserStrategy(PrivateUserStrategy value) => $_setField(100, value);
  @$pb.TagNumber(100)
  $core.bool hasPrivateUserStrategy() => $_has(11);
  @$pb.TagNumber(100)
  void clearPrivateUserStrategy() => $_clearField(100);

  /// (TODO) Allows admins to enable/disable creating accounts and logging in.
  /// Eventually, external auth too hopefully!
  @$pb.TagNumber(101)
  $pb.PbList<AuthenticationFeature> get authenticationFeatures => $_getList(12);

  /// Web Push (VAPID) configuration for the server.
  @$pb.TagNumber(110)
  WebPushConfig get webPushConfig => $_getN(13);
  @$pb.TagNumber(110)
  set webPushConfig(WebPushConfig value) => $_setField(110, value);
  @$pb.TagNumber(110)
  $core.bool hasWebPushConfig() => $_has(13);
  @$pb.TagNumber(110)
  void clearWebPushConfig() => $_clearField(110);
  @$pb.TagNumber(110)
  WebPushConfig ensureWebPushConfig() => $_ensure(13);
}

/// Useful for setting your Jonline instance up to run underneath a CDN.
/// By default, the web client uses `window.location.hostname` to determine the backend server.
/// If set, the web client will use this value instead. NOTE: Only applies to Tamagui web client for now.
class ExternalCDNConfig extends $pb.GeneratedMessage {
  factory ExternalCDNConfig({
    $core.String? frontendHost,
    $core.String? backendHost,
    $core.bool? secureMedia,
    $core.String? mediaIpv4Allowlist,
    $core.String? mediaIpv6Allowlist,
    $core.bool? cdnGrpc,
  }) {
    final result = create();
    if (frontendHost != null) result.frontendHost = frontendHost;
    if (backendHost != null) result.backendHost = backendHost;
    if (secureMedia != null) result.secureMedia = secureMedia;
    if (mediaIpv4Allowlist != null)
      result.mediaIpv4Allowlist = mediaIpv4Allowlist;
    if (mediaIpv6Allowlist != null)
      result.mediaIpv6Allowlist = mediaIpv6Allowlist;
    if (cdnGrpc != null) result.cdnGrpc = cdnGrpc;
    return result;
  }

  ExternalCDNConfig._();

  factory ExternalCDNConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExternalCDNConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExternalCDNConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'frontendHost')
    ..aOS(2, _omitFieldNames ? '' : 'backendHost')
    ..aOB(3, _omitFieldNames ? '' : 'secureMedia')
    ..aOS(4, _omitFieldNames ? '' : 'mediaIpv4Allowlist')
    ..aOS(5, _omitFieldNames ? '' : 'mediaIpv6Allowlist')
    ..aOB(6, _omitFieldNames ? '' : 'cdnGrpc')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExternalCDNConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExternalCDNConfig copyWith(void Function(ExternalCDNConfig) updates) =>
      super.copyWith((message) => updates(message as ExternalCDNConfig))
          as ExternalCDNConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExternalCDNConfig create() => ExternalCDNConfig._();
  @$core.override
  ExternalCDNConfig createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExternalCDNConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExternalCDNConfig>(create);
  static ExternalCDNConfig? _defaultInstance;

  /// The domain where the frontend is hosted. For example, jonline.io. Typically
  /// your CDN (like Cloudflare) should own the DNS for this domain.
  @$pb.TagNumber(1)
  $core.String get frontendHost => $_getSZ(0);
  @$pb.TagNumber(1)
  set frontendHost($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFrontendHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearFrontendHost() => $_clearField(1);

  /// The domain where the backend is hosted. For example, jonline.io.itsj.online.
  /// Typically your Kubernetes provider should own DNS for this domain.
  @$pb.TagNumber(2)
  $core.String get backendHost => $_getSZ(1);
  @$pb.TagNumber(2)
  set backendHost($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBackendHost() => $_has(1);
  @$pb.TagNumber(2)
  void clearBackendHost() => $_clearField(2);

  /// (TODO) When set, the HTTP `GET /media/<id>?<authorization>` endpoint will be disabled by default on the
  /// HTTP (non-secure) server that sends data to the CDN. Only requests from IPs in
  /// `media_ipv4_allowlist` and `media_ipv6_allowlist` will be allowed.
  @$pb.TagNumber(3)
  $core.bool get secureMedia => $_getBF(2);
  @$pb.TagNumber(3)
  set secureMedia($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSecureMedia() => $_has(2);
  @$pb.TagNumber(3)
  void clearSecureMedia() => $_clearField(3);

  /// Whitespace- and/or comma- separated list of IPv4 addresses/ranges
  /// to whom media data may be served. Only applicable if `secure_media` is `true`.
  /// For reference, Cloudflare's are at https://www.cloudflare.com/ips-v4.
  @$pb.TagNumber(4)
  $core.String get mediaIpv4Allowlist => $_getSZ(3);
  @$pb.TagNumber(4)
  set mediaIpv4Allowlist($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMediaIpv4Allowlist() => $_has(3);
  @$pb.TagNumber(4)
  void clearMediaIpv4Allowlist() => $_clearField(4);

  /// Whitespace- and/or comma- separated list of IPv6 addresses/ranges
  /// to whom media data may be served. Only applicable if `secure_media` is `true`.
  /// For reference, Cloudflare's are at https://www.cloudflare.com/ips-v6.
  @$pb.TagNumber(5)
  $core.String get mediaIpv6Allowlist => $_getSZ(4);
  @$pb.TagNumber(5)
  set mediaIpv6Allowlist($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMediaIpv6Allowlist() => $_has(4);
  @$pb.TagNumber(5)
  void clearMediaIpv6Allowlist() => $_clearField(5);

  /// (TODO) When implemented, this actually changes the whole Jonline protocol (in terms of ports).
  /// When enabled, Jonline should *not* server a secure site on HTTPS, and instead serve
  /// the Tonic gRPC server there (on port 443). Jonine clients will need to be updated to
  /// always seek out a secure client on port 443 when this feature is enabled.
  /// This would let Jonline leverage Cloudflare's DDOS protection and performance on gRPC as well as HTTP.
  /// (This is a Cloudflare-specific feature requirement.)
  @$pb.TagNumber(6)
  $core.bool get cdnGrpc => $_getBF(5);
  @$pb.TagNumber(6)
  set cdnGrpc($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCdnGrpc() => $_has(5);
  @$pb.TagNumber(6)
  void clearCdnGrpc() => $_clearField(6);
}

/// Media is a special type and less customizable than "Features."
class MediaSettings extends $pb.GeneratedMessage {
  factory MediaSettings({
    $core.bool? visible,
    $2.Moderation? defaultModeration,
    $2.Visibility? defaultVisibility,
  }) {
    final result = create();
    if (visible != null) result.visible = visible;
    if (defaultModeration != null) result.defaultModeration = defaultModeration;
    if (defaultVisibility != null) result.defaultVisibility = defaultVisibility;
    return result;
  }

  MediaSettings._();

  factory MediaSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MediaSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MediaSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'visible')
    ..aE<$2.Moderation>(2, _omitFieldNames ? '' : 'defaultModeration',
        enumValues: $2.Moderation.values)
    ..aE<$2.Visibility>(3, _omitFieldNames ? '' : 'defaultVisibility',
        enumValues: $2.Visibility.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaSettings copyWith(void Function(MediaSettings) updates) =>
      super.copyWith((message) => updates(message as MediaSettings))
          as MediaSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MediaSettings create() => MediaSettings._();
  @$core.override
  MediaSettings createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MediaSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MediaSettings>(create);
  static MediaSettings? _defaultInstance;

  /// Hide the Posts or Events tab from the user with this flag.
  @$pb.TagNumber(1)
  $core.bool get visible => $_getBF(0);
  @$pb.TagNumber(1)
  set visible($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVisible() => $_has(0);
  @$pb.TagNumber(1)
  void clearVisible() => $_clearField(1);

  /// Only `UNMODERATED` and `PENDING` are valid.
  /// When `UNMODERATED`, user reports may transition status to `PENDING`.
  /// When `PENDING`, users' SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not
  /// be visible until a moderator approves them. `LIMITED` visiblity
  /// posts are always visible to targeted users (who have not blocked
  /// the author) regardless of default_moderation.
  @$pb.TagNumber(2)
  $2.Moderation get defaultModeration => $_getN(1);
  @$pb.TagNumber(2)
  set defaultModeration($2.Moderation value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDefaultModeration() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefaultModeration() => $_clearField(2);

  /// Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid
  /// if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]`
  /// as appropriate.
  @$pb.TagNumber(3)
  $2.Visibility get defaultVisibility => $_getN(2);
  @$pb.TagNumber(3)
  set defaultVisibility($2.Visibility value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDefaultVisibility() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefaultVisibility() => $_clearField(3);
}

/// Settings for a feature (e.g. People, Groups, Posts, Events, Media).
/// Encompasses both the feature's visibility and moderation settings.
class FeatureSettings extends $pb.GeneratedMessage {
  factory FeatureSettings({
    $core.bool? visible,
    $2.Moderation? defaultModeration,
    $2.Visibility? defaultVisibility,
    $core.String? aliasSingular,
    $core.String? aliasPlural,
  }) {
    final result = create();
    if (visible != null) result.visible = visible;
    if (defaultModeration != null) result.defaultModeration = defaultModeration;
    if (defaultVisibility != null) result.defaultVisibility = defaultVisibility;
    if (aliasSingular != null) result.aliasSingular = aliasSingular;
    if (aliasPlural != null) result.aliasPlural = aliasPlural;
    return result;
  }

  FeatureSettings._();

  factory FeatureSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FeatureSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FeatureSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'visible')
    ..aE<$2.Moderation>(2, _omitFieldNames ? '' : 'defaultModeration',
        enumValues: $2.Moderation.values)
    ..aE<$2.Visibility>(3, _omitFieldNames ? '' : 'defaultVisibility',
        enumValues: $2.Visibility.values)
    ..aOS(4, _omitFieldNames ? '' : 'aliasSingular')
    ..aOS(5, _omitFieldNames ? '' : 'aliasPlural')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeatureSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeatureSettings copyWith(void Function(FeatureSettings) updates) =>
      super.copyWith((message) => updates(message as FeatureSettings))
          as FeatureSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FeatureSettings create() => FeatureSettings._();
  @$core.override
  FeatureSettings createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FeatureSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FeatureSettings>(create);
  static FeatureSettings? _defaultInstance;

  /// Hide the Posts or Events tab from the user with this flag.
  @$pb.TagNumber(1)
  $core.bool get visible => $_getBF(0);
  @$pb.TagNumber(1)
  set visible($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVisible() => $_has(0);
  @$pb.TagNumber(1)
  void clearVisible() => $_clearField(1);

  /// Only `UNMODERATED` and `PENDING` are valid.
  /// When `UNMODERATED`, user reports may transition status to `PENDING`.
  /// When `PENDING`, users' SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not
  /// be visible until a moderator approves them. `LIMITED` visiblity
  /// posts are always visible to targeted users (who have not blocked
  /// the author) regardless of default_moderation.
  @$pb.TagNumber(2)
  $2.Moderation get defaultModeration => $_getN(1);
  @$pb.TagNumber(2)
  set defaultModeration($2.Moderation value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDefaultModeration() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefaultModeration() => $_clearField(2);

  /// Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid
  /// if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]`
  /// as appropriate.
  @$pb.TagNumber(3)
  $2.Visibility get defaultVisibility => $_getN(2);
  @$pb.TagNumber(3)
  set defaultVisibility($2.Visibility value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDefaultVisibility() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefaultVisibility() => $_clearField(3);

  /// Can be used to rename, e.g., "Person" to "Contributor" or "Group" to "Community"
  @$pb.TagNumber(4)
  $core.String get aliasSingular => $_getSZ(3);
  @$pb.TagNumber(4)
  set aliasSingular($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAliasSingular() => $_has(3);
  @$pb.TagNumber(4)
  void clearAliasSingular() => $_clearField(4);

  /// Can be used to rename, e.g. "Groups" to "Subtwaddits" or "People" to "Folks"
  @$pb.TagNumber(5)
  $core.String get aliasPlural => $_getSZ(4);
  @$pb.TagNumber(5)
  set aliasPlural($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAliasPlural() => $_has(4);
  @$pb.TagNumber(5)
  void clearAliasPlural() => $_clearField(5);
}

/// Specific settings for Posts.
class PostSettings extends $pb.GeneratedMessage {
  factory PostSettings({
    $core.bool? visible,
    $2.Moderation? defaultModeration,
    $2.Visibility? defaultVisibility,
    $core.String? aliasSingular,
    $core.String? aliasPlural,
    $core.bool? enableReplies,
  }) {
    final result = create();
    if (visible != null) result.visible = visible;
    if (defaultModeration != null) result.defaultModeration = defaultModeration;
    if (defaultVisibility != null) result.defaultVisibility = defaultVisibility;
    if (aliasSingular != null) result.aliasSingular = aliasSingular;
    if (aliasPlural != null) result.aliasPlural = aliasPlural;
    if (enableReplies != null) result.enableReplies = enableReplies;
    return result;
  }

  PostSettings._();

  factory PostSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PostSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PostSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'visible')
    ..aE<$2.Moderation>(2, _omitFieldNames ? '' : 'defaultModeration',
        enumValues: $2.Moderation.values)
    ..aE<$2.Visibility>(3, _omitFieldNames ? '' : 'defaultVisibility',
        enumValues: $2.Visibility.values)
    ..aOS(4, _omitFieldNames ? '' : 'aliasSingular')
    ..aOS(5, _omitFieldNames ? '' : 'aliasPlural')
    ..aOB(6, _omitFieldNames ? '' : 'enableReplies')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PostSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PostSettings copyWith(void Function(PostSettings) updates) =>
      super.copyWith((message) => updates(message as PostSettings))
          as PostSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PostSettings create() => PostSettings._();
  @$core.override
  PostSettings createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PostSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PostSettings>(create);
  static PostSettings? _defaultInstance;

  /// Hide the Posts tab from the user with this flag.
  @$pb.TagNumber(1)
  $core.bool get visible => $_getBF(0);
  @$pb.TagNumber(1)
  set visible($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVisible() => $_has(0);
  @$pb.TagNumber(1)
  void clearVisible() => $_clearField(1);

  /// Only `UNMODERATED` and `PENDING` are valid.
  /// When `UNMODERATED`, user reports may transition status to `PENDING`.
  /// When `PENDING`, users' SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not
  /// be visible until a moderator approves them. `LIMITED` visiblity
  /// posts are always visible to targeted users (who have not blocked
  /// the author) regardless of default_moderation.
  @$pb.TagNumber(2)
  $2.Moderation get defaultModeration => $_getN(1);
  @$pb.TagNumber(2)
  set defaultModeration($2.Moderation value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDefaultModeration() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefaultModeration() => $_clearField(2);

  /// Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid
  /// if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]`
  /// as appropriate.
  @$pb.TagNumber(3)
  $2.Visibility get defaultVisibility => $_getN(2);
  @$pb.TagNumber(3)
  set defaultVisibility($2.Visibility value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDefaultVisibility() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefaultVisibility() => $_clearField(3);

  /// Can be used to rename, e.g., "Post" "Highlight" or "Squirt"
  @$pb.TagNumber(4)
  $core.String get aliasSingular => $_getSZ(3);
  @$pb.TagNumber(4)
  set aliasSingular($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAliasSingular() => $_has(3);
  @$pb.TagNumber(4)
  void clearAliasSingular() => $_clearField(4);

  /// Can be used to rename, e.g. "Posts" to "Splurts" or "Memories"
  @$pb.TagNumber(5)
  $core.String get aliasPlural => $_getSZ(4);
  @$pb.TagNumber(5)
  set aliasPlural($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAliasPlural() => $_has(4);
  @$pb.TagNumber(5)
  void clearAliasPlural() => $_clearField(5);

  /// Controls whether replies are shown in the UI. Note that users' ability to reply
  /// is controlled by the `REPLY_TO_POSTS` permission.
  @$pb.TagNumber(6)
  $core.bool get enableReplies => $_getBF(5);
  @$pb.TagNumber(6)
  set enableReplies($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEnableReplies() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnableReplies() => $_clearField(6);
}

/// Specific settings for Events.
class EventSettings extends $pb.GeneratedMessage {
  factory EventSettings({
    $core.bool? visible,
    $2.Moderation? defaultModeration,
    $2.Visibility? defaultVisibility,
    $core.String? aliasSingular,
    $core.String? aliasPlural,
    $core.bool? enableReplies,
    $core.int? calendarLookbackDays,
    CalendarDisplayMode? defaultCalendarDisplayMode,
  }) {
    final result = create();
    if (visible != null) result.visible = visible;
    if (defaultModeration != null) result.defaultModeration = defaultModeration;
    if (defaultVisibility != null) result.defaultVisibility = defaultVisibility;
    if (aliasSingular != null) result.aliasSingular = aliasSingular;
    if (aliasPlural != null) result.aliasPlural = aliasPlural;
    if (enableReplies != null) result.enableReplies = enableReplies;
    if (calendarLookbackDays != null)
      result.calendarLookbackDays = calendarLookbackDays;
    if (defaultCalendarDisplayMode != null)
      result.defaultCalendarDisplayMode = defaultCalendarDisplayMode;
    return result;
  }

  EventSettings._();

  factory EventSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EventSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EventSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'visible')
    ..aE<$2.Moderation>(2, _omitFieldNames ? '' : 'defaultModeration',
        enumValues: $2.Moderation.values)
    ..aE<$2.Visibility>(3, _omitFieldNames ? '' : 'defaultVisibility',
        enumValues: $2.Visibility.values)
    ..aOS(4, _omitFieldNames ? '' : 'aliasSingular')
    ..aOS(5, _omitFieldNames ? '' : 'aliasPlural')
    ..aOB(6, _omitFieldNames ? '' : 'enableReplies')
    ..aI(7, _omitFieldNames ? '' : 'calendarLookbackDays',
        fieldType: $pb.PbFieldType.OU3)
    ..aE<CalendarDisplayMode>(
        8, _omitFieldNames ? '' : 'defaultCalendarDisplayMode',
        enumValues: CalendarDisplayMode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventSettings copyWith(void Function(EventSettings) updates) =>
      super.copyWith((message) => updates(message as EventSettings))
          as EventSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventSettings create() => EventSettings._();
  @$core.override
  EventSettings createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EventSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EventSettings>(create);
  static EventSettings? _defaultInstance;

  /// Hide the Events tab from the user with this flag.
  @$pb.TagNumber(1)
  $core.bool get visible => $_getBF(0);
  @$pb.TagNumber(1)
  set visible($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVisible() => $_has(0);
  @$pb.TagNumber(1)
  void clearVisible() => $_clearField(1);

  /// Only `UNMODERATED` and `PENDING` are valid.
  /// When `UNMODERATED`, user reports may transition status to `PENDING`.
  /// When `PENDING`, users' SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not
  /// be visible until a moderator approves them. `LIMITED` visiblity
  /// posts are always visible to targeted users (who have not blocked
  /// the author) regardless of default_moderation.
  @$pb.TagNumber(2)
  $2.Moderation get defaultModeration => $_getN(1);
  @$pb.TagNumber(2)
  set defaultModeration($2.Moderation value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDefaultModeration() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefaultModeration() => $_clearField(2);

  /// Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid
  /// if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]`
  /// as appropriate.
  @$pb.TagNumber(3)
  $2.Visibility get defaultVisibility => $_getN(2);
  @$pb.TagNumber(3)
  set defaultVisibility($2.Visibility value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDefaultVisibility() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefaultVisibility() => $_clearField(3);

  /// Can be used to rename, e.g., "Event" to "Gig" or "Performance"
  @$pb.TagNumber(4)
  $core.String get aliasSingular => $_getSZ(3);
  @$pb.TagNumber(4)
  set aliasSingular($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAliasSingular() => $_has(3);
  @$pb.TagNumber(4)
  void clearAliasSingular() => $_clearField(4);

  /// Can be used to rename, e.g. "Events" to "Show," "Game," "Competition"
  @$pb.TagNumber(5)
  $core.String get aliasPlural => $_getSZ(4);
  @$pb.TagNumber(5)
  set aliasPlural($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAliasPlural() => $_has(4);
  @$pb.TagNumber(5)
  void clearAliasPlural() => $_clearField(5);

  /// Works the same as for Posts.
  @$pb.TagNumber(6)
  $core.bool get enableReplies => $_getBF(5);
  @$pb.TagNumber(6)
  set enableReplies($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEnableReplies() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnableReplies() => $_clearField(6);

  /// How far to look back for the "Upcoming Events" tab in the server's UI. Defaults to `14`.
  /// Servers with fewer events may want to set to a higher value.
  @$pb.TagNumber(7)
  $core.int get calendarLookbackDays => $_getIZ(6);
  @$pb.TagNumber(7)
  set calendarLookbackDays($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCalendarLookbackDays() => $_has(6);
  @$pb.TagNumber(7)
  void clearCalendarLookbackDays() => $_clearField(7);

  /// What the Events Calendar's default UI mode will be. Defaults to `CALENDAR_DISPLAY_WEEK`.
  /// Servers with fewer events may want to set `CALENDAR_DISPLAY_MONTH`,
  /// or with more to `CALENDAR_DISPLAY_DAY`.
  @$pb.TagNumber(8)
  CalendarDisplayMode get defaultCalendarDisplayMode => $_getN(7);
  @$pb.TagNumber(8)
  set defaultCalendarDisplayMode(CalendarDisplayMode value) =>
      $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasDefaultCalendarDisplayMode() => $_has(7);
  @$pb.TagNumber(8)
  void clearDefaultCalendarDisplayMode() => $_clearField(8);
}

/// User-facing information about the server displayed on the "about" page.
class ServerInfo extends $pb.GeneratedMessage {
  factory ServerInfo({
    $core.String? name,
    $core.String? shortName,
    $core.String? description,
    $core.String? privacyPolicy,
    ServerLogo? logo,
    WebUserInterface? webUserInterface,
    ServerColors? colors,
    $core.String? mediaPolicy,
    @$core.Deprecated('This field is deprecated.')
    $core.Iterable<$core.String>? recommendedServerHosts,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (shortName != null) result.shortName = shortName;
    if (description != null) result.description = description;
    if (privacyPolicy != null) result.privacyPolicy = privacyPolicy;
    if (logo != null) result.logo = logo;
    if (webUserInterface != null) result.webUserInterface = webUserInterface;
    if (colors != null) result.colors = colors;
    if (mediaPolicy != null) result.mediaPolicy = mediaPolicy;
    if (recommendedServerHosts != null)
      result.recommendedServerHosts.addAll(recommendedServerHosts);
    return result;
  }

  ServerInfo._();

  factory ServerInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'shortName')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aOS(4, _omitFieldNames ? '' : 'privacyPolicy')
    ..aOM<ServerLogo>(5, _omitFieldNames ? '' : 'logo',
        subBuilder: ServerLogo.create)
    ..aE<WebUserInterface>(6, _omitFieldNames ? '' : 'webUserInterface',
        enumValues: WebUserInterface.values)
    ..aOM<ServerColors>(7, _omitFieldNames ? '' : 'colors',
        subBuilder: ServerColors.create)
    ..aOS(8, _omitFieldNames ? '' : 'mediaPolicy')
    ..pPS(9, _omitFieldNames ? '' : 'recommendedServerHosts')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerInfo copyWith(void Function(ServerInfo) updates) =>
      super.copyWith((message) => updates(message as ServerInfo)) as ServerInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerInfo create() => ServerInfo._();
  @$core.override
  ServerInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerInfo>(create);
  static ServerInfo? _defaultInstance;

  /// Name of the server.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Short name of the server. Used in URLs, etc. (Currently unused.)
  @$pb.TagNumber(2)
  $core.String get shortName => $_getSZ(1);
  @$pb.TagNumber(2)
  set shortName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasShortName() => $_has(1);
  @$pb.TagNumber(2)
  void clearShortName() => $_clearField(2);

  /// Description of the server.
  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  /// The server's privacy policy. Will be displayed during account creation
  /// and on the `/about` page.
  @$pb.TagNumber(4)
  $core.String get privacyPolicy => $_getSZ(3);
  @$pb.TagNumber(4)
  set privacyPolicy($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPrivacyPolicy() => $_has(3);
  @$pb.TagNumber(4)
  void clearPrivacyPolicy() => $_clearField(4);

  /// Multi-size logo data for the server.
  @$pb.TagNumber(5)
  ServerLogo get logo => $_getN(4);
  @$pb.TagNumber(5)
  set logo(ServerLogo value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLogo() => $_has(4);
  @$pb.TagNumber(5)
  void clearLogo() => $_clearField(5);
  @$pb.TagNumber(5)
  ServerLogo ensureLogo() => $_ensure(4);

  /// The web UI to use (React/Tamagui (default) vs. Flutter Web)
  @$pb.TagNumber(6)
  WebUserInterface get webUserInterface => $_getN(5);
  @$pb.TagNumber(6)
  set webUserInterface(WebUserInterface value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasWebUserInterface() => $_has(5);
  @$pb.TagNumber(6)
  void clearWebUserInterface() => $_clearField(6);

  /// The color scheme for the server.
  @$pb.TagNumber(7)
  ServerColors get colors => $_getN(6);
  @$pb.TagNumber(7)
  set colors(ServerColors value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasColors() => $_has(6);
  @$pb.TagNumber(7)
  void clearColors() => $_clearField(7);
  @$pb.TagNumber(7)
  ServerColors ensureColors() => $_ensure(6);

  /// The media policy for the server. Will be displayed during account creation
  /// and on the `/about` page.
  @$pb.TagNumber(8)
  $core.String get mediaPolicy => $_getSZ(7);
  @$pb.TagNumber(8)
  set mediaPolicy($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMediaPolicy() => $_has(7);
  @$pb.TagNumber(8)
  void clearMediaPolicy() => $_clearField(8);

  /// This will be replaced with FederationInfo soon.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get recommendedServerHosts => $_getList(8);
}

/// Logo data for the server. Built atop Jonline [`Media` APIs](#jonline-Media).
class ServerLogo extends $pb.GeneratedMessage {
  factory ServerLogo({
    $core.String? squareMediaId,
    $core.String? squareMediaIdDark,
    $core.String? wideMediaId,
    $core.String? wideMediaIdDark,
  }) {
    final result = create();
    if (squareMediaId != null) result.squareMediaId = squareMediaId;
    if (squareMediaIdDark != null) result.squareMediaIdDark = squareMediaIdDark;
    if (wideMediaId != null) result.wideMediaId = wideMediaId;
    if (wideMediaIdDark != null) result.wideMediaIdDark = wideMediaIdDark;
    return result;
  }

  ServerLogo._();

  factory ServerLogo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerLogo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerLogo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'squareMediaId', protoName: 'squareMediaId')
    ..aOS(2, _omitFieldNames ? '' : 'squareMediaIdDark',
        protoName: 'squareMediaIdDark')
    ..aOS(3, _omitFieldNames ? '' : 'wideMediaId', protoName: 'wideMediaId')
    ..aOS(4, _omitFieldNames ? '' : 'wideMediaIdDark',
        protoName: 'wideMediaIdDark')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerLogo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerLogo copyWith(void Function(ServerLogo) updates) =>
      super.copyWith((message) => updates(message as ServerLogo)) as ServerLogo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerLogo create() => ServerLogo._();
  @$core.override
  ServerLogo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerLogo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerLogo>(create);
  static ServerLogo? _defaultInstance;

  /// The media ID for the square logo.
  @$pb.TagNumber(1)
  $core.String get squareMediaId => $_getSZ(0);
  @$pb.TagNumber(1)
  set squareMediaId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSquareMediaId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSquareMediaId() => $_clearField(1);

  /// The media ID for the square logo in dark mode.
  @$pb.TagNumber(2)
  $core.String get squareMediaIdDark => $_getSZ(1);
  @$pb.TagNumber(2)
  set squareMediaIdDark($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSquareMediaIdDark() => $_has(1);
  @$pb.TagNumber(2)
  void clearSquareMediaIdDark() => $_clearField(2);

  /// The media ID for the wide logo.
  @$pb.TagNumber(3)
  $core.String get wideMediaId => $_getSZ(2);
  @$pb.TagNumber(3)
  set wideMediaId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWideMediaId() => $_has(2);
  @$pb.TagNumber(3)
  void clearWideMediaId() => $_clearField(3);

  /// The media ID for the wide logo in dark mode.
  @$pb.TagNumber(4)
  $core.String get wideMediaIdDark => $_getSZ(3);
  @$pb.TagNumber(4)
  set wideMediaIdDark($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasWideMediaIdDark() => $_has(3);
  @$pb.TagNumber(4)
  void clearWideMediaIdDark() => $_clearField(4);
}

/// If set, should override the default tab set for the Elm navigation on a Jonline instance.
class CustomNavigationTabSet extends $pb.GeneratedMessage {
  factory CustomNavigationTabSet({
    CustomNavigationTab? home,
    $core.Iterable<CustomNavigationTabWithPath>? tabs,
  }) {
    final result = create();
    if (home != null) result.home = home;
    if (tabs != null) result.tabs.addAll(tabs);
    return result;
  }

  CustomNavigationTabSet._();

  factory CustomNavigationTabSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CustomNavigationTabSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CustomNavigationTabSet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOM<CustomNavigationTab>(1, _omitFieldNames ? '' : 'home',
        subBuilder: CustomNavigationTab.create)
    ..pPM<CustomNavigationTabWithPath>(2, _omitFieldNames ? '' : 'tabs',
        subBuilder: CustomNavigationTabWithPath.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomNavigationTabSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomNavigationTabSet copyWith(
          void Function(CustomNavigationTabSet) updates) =>
      super.copyWith((message) => updates(message as CustomNavigationTabSet))
          as CustomNavigationTabSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CustomNavigationTabSet create() => CustomNavigationTabSet._();
  @$core.override
  CustomNavigationTabSet createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CustomNavigationTabSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CustomNavigationTabSet>(create);
  static CustomNavigationTabSet? _defaultInstance;

  /// Overrides the default `HOME_TAB` entry. If unset, the default Home tab is used.
  @$pb.TagNumber(1)
  CustomNavigationTab get home => $_getN(0);
  @$pb.TagNumber(1)
  set home(CustomNavigationTab value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHome() => $_has(0);
  @$pb.TagNumber(1)
  void clearHome() => $_clearField(1);
  @$pb.TagNumber(1)
  CustomNavigationTab ensureHome() => $_ensure(0);

  /// Overrides the default tab set (`EVENTS_TAB`, `POSTS_TAB`, `PEOPLE_TAB`, `ABOUT_TAB`) entirely.
  /// Note: existing `/events`, `/posts/`, `/people`, and `/about` paths are not modifiable.
  /// `/` is modified via `CustomNavigationTabSet`.home instead.
  @$pb.TagNumber(2)
  $pb.PbList<CustomNavigationTabWithPath> get tabs => $_getList(1);
}

enum CustomNavigationTab_Target { tab, postId, notSet }

enum CustomNavigationTab_Icon { emojiIcon, iconMediaId, notSet }

/// Either one of the app's predefined tabs, or a Post
class CustomNavigationTab extends $pb.GeneratedMessage {
  factory CustomNavigationTab({
    NavigationTab? tab,
    $core.String? postId,
    $core.String? emojiIcon,
    $core.String? iconMediaId,
    $core.String? title,
  }) {
    final result = create();
    if (tab != null) result.tab = tab;
    if (postId != null) result.postId = postId;
    if (emojiIcon != null) result.emojiIcon = emojiIcon;
    if (iconMediaId != null) result.iconMediaId = iconMediaId;
    if (title != null) result.title = title;
    return result;
  }

  CustomNavigationTab._();

  factory CustomNavigationTab.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CustomNavigationTab.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, CustomNavigationTab_Target>
      _CustomNavigationTab_TargetByTag = {
    1: CustomNavigationTab_Target.tab,
    2: CustomNavigationTab_Target.postId,
    0: CustomNavigationTab_Target.notSet
  };
  static const $core.Map<$core.int, CustomNavigationTab_Icon>
      _CustomNavigationTab_IconByTag = {
    10: CustomNavigationTab_Icon.emojiIcon,
    11: CustomNavigationTab_Icon.iconMediaId,
    0: CustomNavigationTab_Icon.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CustomNavigationTab',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..oo(1, [10, 11])
    ..aE<NavigationTab>(1, _omitFieldNames ? '' : 'tab',
        enumValues: NavigationTab.values)
    ..aOS(2, _omitFieldNames ? '' : 'postId')
    ..aOS(10, _omitFieldNames ? '' : 'emojiIcon')
    ..aOS(11, _omitFieldNames ? '' : 'iconMediaId')
    ..aOS(12, _omitFieldNames ? '' : 'title')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomNavigationTab clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomNavigationTab copyWith(void Function(CustomNavigationTab) updates) =>
      super.copyWith((message) => updates(message as CustomNavigationTab))
          as CustomNavigationTab;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CustomNavigationTab create() => CustomNavigationTab._();
  @$core.override
  CustomNavigationTab createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CustomNavigationTab getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CustomNavigationTab>(create);
  static CustomNavigationTab? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  CustomNavigationTab_Target whichTarget() =>
      _CustomNavigationTab_TargetByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearTarget() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  CustomNavigationTab_Icon whichIcon() =>
      _CustomNavigationTab_IconByTag[$_whichOneof(1)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  void clearIcon() => $_clearField($_whichOneof(1));

  /// Links to one of the app's predefined tabs/pages.
  @$pb.TagNumber(1)
  NavigationTab get tab => $_getN(0);
  @$pb.TagNumber(1)
  set tab(NavigationTab value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTab() => $_has(0);
  @$pb.TagNumber(1)
  void clearTab() => $_clearField(1);

  /// Links to a specific Post (e.g. for a custom business site's page).
  @$pb.TagNumber(2)
  $core.String get postId => $_getSZ(1);
  @$pb.TagNumber(2)
  set postId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPostId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPostId() => $_clearField(2);

  /// Emoji shown as the tab's icon (e.g. "🎪").
  @$pb.TagNumber(10)
  $core.String get emojiIcon => $_getSZ(2);
  @$pb.TagNumber(10)
  set emojiIcon($core.String value) => $_setString(2, value);
  @$pb.TagNumber(10)
  $core.bool hasEmojiIcon() => $_has(2);
  @$pb.TagNumber(10)
  void clearEmojiIcon() => $_clearField(10);

  /// Media ID (see `Media` APIs) of an image shown as the tab's icon.
  @$pb.TagNumber(11)
  $core.String get iconMediaId => $_getSZ(3);
  @$pb.TagNumber(11)
  set iconMediaId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(11)
  $core.bool hasIconMediaId() => $_has(3);
  @$pb.TagNumber(11)
  void clearIconMediaId() => $_clearField(11);

  /// Title shown for the tab. Defaults to the predefined tab's/Post's title if unset.
  @$pb.TagNumber(12)
  $core.String get title => $_getSZ(4);
  @$pb.TagNumber(12)
  set title($core.String value) => $_setString(4, value);
  @$pb.TagNumber(12)
  $core.bool hasTitle() => $_has(4);
  @$pb.TagNumber(12)
  void clearTitle() => $_clearField(12);
}

/// A custom navigation tab with an associated path.
/// Note: existing `/events`, `/posts/``, `/people`, and `/about` paths are not modifiable.
/// `/` is modified via `CustomNavigationTabSet`.home instead.
class CustomNavigationTabWithPath extends $pb.GeneratedMessage {
  factory CustomNavigationTabWithPath({
    CustomNavigationTab? customTab,
    $core.String? path,
  }) {
    final result = create();
    if (customTab != null) result.customTab = customTab;
    if (path != null) result.path = path;
    return result;
  }

  CustomNavigationTabWithPath._();

  factory CustomNavigationTabWithPath.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CustomNavigationTabWithPath.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CustomNavigationTabWithPath',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOM<CustomNavigationTab>(1, _omitFieldNames ? '' : 'customTab',
        subBuilder: CustomNavigationTab.create)
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomNavigationTabWithPath clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomNavigationTabWithPath copyWith(
          void Function(CustomNavigationTabWithPath) updates) =>
      super.copyWith(
              (message) => updates(message as CustomNavigationTabWithPath))
          as CustomNavigationTabWithPath;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CustomNavigationTabWithPath create() =>
      CustomNavigationTabWithPath._();
  @$core.override
  CustomNavigationTabWithPath createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CustomNavigationTabWithPath getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CustomNavigationTabWithPath>(create);
  static CustomNavigationTabWithPath? _defaultInstance;

  /// The tab to show at this path.
  @$pb.TagNumber(1)
  CustomNavigationTab get customTab => $_getN(0);
  @$pb.TagNumber(1)
  set customTab(CustomNavigationTab value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCustomTab() => $_has(0);
  @$pb.TagNumber(1)
  void clearCustomTab() => $_clearField(1);
  @$pb.TagNumber(1)
  CustomNavigationTab ensureCustomTab() => $_ensure(0);

  /// e.g. link `/gigs` or `/shows` for a band to the "Events" page.
  /// Or, /weddings to a Post about wedding offerings for a custom business site.
  /// Note: existing `/events`, `/posts/``, `/people`, and `/about` paths are not modifiable.
  /// `/` is modified via `CustomNavigationTabSet`.home instead.
  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
}

/// Color in ARGB hex format (i.e `0xAARRGGBB`).
class ServerColors extends $pb.GeneratedMessage {
  factory ServerColors({
    $core.int? primary,
    $core.int? navigation,
    $core.int? author,
    $core.int? admin,
    $core.int? moderator,
  }) {
    final result = create();
    if (primary != null) result.primary = primary;
    if (navigation != null) result.navigation = navigation;
    if (author != null) result.author = author;
    if (admin != null) result.admin = admin;
    if (moderator != null) result.moderator = moderator;
    return result;
  }

  ServerColors._();

  factory ServerColors.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerColors.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerColors',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'primary', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'navigation', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'author', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'admin', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'moderator', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerColors clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerColors copyWith(void Function(ServerColors) updates) =>
      super.copyWith((message) => updates(message as ServerColors))
          as ServerColors;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerColors create() => ServerColors._();
  @$core.override
  ServerColors createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerColors getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerColors>(create);
  static ServerColors? _defaultInstance;

  /// App Bar/primary accent color.
  @$pb.TagNumber(1)
  $core.int get primary => $_getIZ(0);
  @$pb.TagNumber(1)
  set primary($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPrimary() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrimary() => $_clearField(1);

  /// Nav/secondary accent color.
  @$pb.TagNumber(2)
  $core.int get navigation => $_getIZ(1);
  @$pb.TagNumber(2)
  set navigation($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNavigation() => $_has(1);
  @$pb.TagNumber(2)
  void clearNavigation() => $_clearField(2);

  /// Color used on author of a post in discussion threads for it.
  @$pb.TagNumber(3)
  $core.int get author => $_getIZ(2);
  @$pb.TagNumber(3)
  set author($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthor() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthor() => $_clearField(3);

  /// Color used on author for admin posts.
  @$pb.TagNumber(4)
  $core.int get admin => $_getIZ(3);
  @$pb.TagNumber(4)
  set admin($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAdmin() => $_has(3);
  @$pb.TagNumber(4)
  void clearAdmin() => $_clearField(4);

  /// Color used on author for moderator posts.
  @$pb.TagNumber(5)
  $core.int get moderator => $_getIZ(4);
  @$pb.TagNumber(5)
  set moderator($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModerator() => $_has(4);
  @$pb.TagNumber(5)
  void clearModerator() => $_clearField(5);
}

/// Web Push (VAPID) configuration for the server.
class WebPushConfig extends $pb.GeneratedMessage {
  factory WebPushConfig({
    $core.String? publicVapidKey,
    $core.String? privateVapidKey,
  }) {
    final result = create();
    if (publicVapidKey != null) result.publicVapidKey = publicVapidKey;
    if (privateVapidKey != null) result.privateVapidKey = privateVapidKey;
    return result;
  }

  WebPushConfig._();

  factory WebPushConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebPushConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebPushConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'publicVapidKey')
    ..aOS(2, _omitFieldNames ? '' : 'privateVapidKey')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebPushConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebPushConfig copyWith(void Function(WebPushConfig) updates) =>
      super.copyWith((message) => updates(message as WebPushConfig))
          as WebPushConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebPushConfig create() => WebPushConfig._();
  @$core.override
  WebPushConfig createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WebPushConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebPushConfig>(create);
  static WebPushConfig? _defaultInstance;

  /// Public VAPID key for the server.
  @$pb.TagNumber(1)
  $core.String get publicVapidKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set publicVapidKey($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPublicVapidKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearPublicVapidKey() => $_clearField(1);

  /// Private VAPID key for the server. *Never serialized to the client.*
  /// Admins: Edit this in the database's JSONB column directly.
  @$pb.TagNumber(2)
  $core.String get privateVapidKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set privateVapidKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPrivateVapidKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrivateVapidKey() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
