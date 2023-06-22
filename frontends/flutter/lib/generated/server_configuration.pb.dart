//
//  Generated code. Do not modify.
//  source: server_configuration.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'permissions.pbenum.dart' as $10;
import 'server_configuration.pbenum.dart';
import 'visibility_moderation.pbenum.dart' as $11;

export 'server_configuration.pbenum.dart';

class ServerConfiguration extends $pb.GeneratedMessage {
  factory ServerConfiguration() => create();
  ServerConfiguration._() : super();
  factory ServerConfiguration.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ServerConfiguration.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ServerConfiguration', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<ServerInfo>(1, _omitFieldNames ? '' : 'serverInfo', subBuilder: ServerInfo.create)
    ..pc<$10.Permission>(10, _omitFieldNames ? '' : 'anonymousUserPermissions', $pb.PbFieldType.KE, valueOf: $10.Permission.valueOf, enumValues: $10.Permission.values, defaultEnumValue: $10.Permission.PERMISSION_UNKNOWN)
    ..pc<$10.Permission>(11, _omitFieldNames ? '' : 'defaultUserPermissions', $pb.PbFieldType.KE, valueOf: $10.Permission.valueOf, enumValues: $10.Permission.values, defaultEnumValue: $10.Permission.PERMISSION_UNKNOWN)
    ..pc<$10.Permission>(12, _omitFieldNames ? '' : 'basicUserPermissions', $pb.PbFieldType.KE, valueOf: $10.Permission.valueOf, enumValues: $10.Permission.values, defaultEnumValue: $10.Permission.PERMISSION_UNKNOWN)
    ..aOM<FeatureSettings>(20, _omitFieldNames ? '' : 'peopleSettings', subBuilder: FeatureSettings.create)
    ..aOM<FeatureSettings>(21, _omitFieldNames ? '' : 'groupSettings', subBuilder: FeatureSettings.create)
    ..aOM<PostSettings>(22, _omitFieldNames ? '' : 'postSettings', subBuilder: PostSettings.create)
    ..aOM<FeatureSettings>(23, _omitFieldNames ? '' : 'eventSettings', subBuilder: FeatureSettings.create)
    ..aOM<FeatureSettings>(24, _omitFieldNames ? '' : 'mediaSettings', subBuilder: FeatureSettings.create)
    ..aOM<ExternalCDNConfig>(90, _omitFieldNames ? '' : 'externalCdnConfig', subBuilder: ExternalCDNConfig.create)
    ..e<PrivateUserStrategy>(100, _omitFieldNames ? '' : 'privateUserStrategy', $pb.PbFieldType.OE, defaultOrMaker: PrivateUserStrategy.ACCOUNT_IS_FROZEN, valueOf: PrivateUserStrategy.valueOf, enumValues: PrivateUserStrategy.values)
    ..pc<AuthenticationFeature>(101, _omitFieldNames ? '' : 'authenticationFeatures', $pb.PbFieldType.KE, valueOf: AuthenticationFeature.valueOf, enumValues: AuthenticationFeature.values, defaultEnumValue: AuthenticationFeature.AUTHENTICATION_FEATURE_UNKNOWN)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ServerConfiguration clone() => ServerConfiguration()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ServerConfiguration copyWith(void Function(ServerConfiguration) updates) => super.copyWith((message) => updates(message as ServerConfiguration)) as ServerConfiguration;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerConfiguration create() => ServerConfiguration._();
  ServerConfiguration createEmptyInstance() => create();
  static $pb.PbList<ServerConfiguration> createRepeated() => $pb.PbList<ServerConfiguration>();
  @$core.pragma('dart2js:noInline')
  static ServerConfiguration getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ServerConfiguration>(create);
  static ServerConfiguration? _defaultInstance;

  @$pb.TagNumber(1)
  ServerInfo get serverInfo => $_getN(0);
  @$pb.TagNumber(1)
  set serverInfo(ServerInfo v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasServerInfo() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerInfo() => clearField(1);
  @$pb.TagNumber(1)
  ServerInfo ensureServerInfo() => $_ensure(0);

  @$pb.TagNumber(10)
  $core.List<$10.Permission> get anonymousUserPermissions => $_getList(1);

  @$pb.TagNumber(11)
  $core.List<$10.Permission> get defaultUserPermissions => $_getList(2);

  @$pb.TagNumber(12)
  $core.List<$10.Permission> get basicUserPermissions => $_getList(3);

  @$pb.TagNumber(20)
  FeatureSettings get peopleSettings => $_getN(4);
  @$pb.TagNumber(20)
  set peopleSettings(FeatureSettings v) { setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasPeopleSettings() => $_has(4);
  @$pb.TagNumber(20)
  void clearPeopleSettings() => clearField(20);
  @$pb.TagNumber(20)
  FeatureSettings ensurePeopleSettings() => $_ensure(4);

  @$pb.TagNumber(21)
  FeatureSettings get groupSettings => $_getN(5);
  @$pb.TagNumber(21)
  set groupSettings(FeatureSettings v) { setField(21, v); }
  @$pb.TagNumber(21)
  $core.bool hasGroupSettings() => $_has(5);
  @$pb.TagNumber(21)
  void clearGroupSettings() => clearField(21);
  @$pb.TagNumber(21)
  FeatureSettings ensureGroupSettings() => $_ensure(5);

  @$pb.TagNumber(22)
  PostSettings get postSettings => $_getN(6);
  @$pb.TagNumber(22)
  set postSettings(PostSettings v) { setField(22, v); }
  @$pb.TagNumber(22)
  $core.bool hasPostSettings() => $_has(6);
  @$pb.TagNumber(22)
  void clearPostSettings() => clearField(22);
  @$pb.TagNumber(22)
  PostSettings ensurePostSettings() => $_ensure(6);

  @$pb.TagNumber(23)
  FeatureSettings get eventSettings => $_getN(7);
  @$pb.TagNumber(23)
  set eventSettings(FeatureSettings v) { setField(23, v); }
  @$pb.TagNumber(23)
  $core.bool hasEventSettings() => $_has(7);
  @$pb.TagNumber(23)
  void clearEventSettings() => clearField(23);
  @$pb.TagNumber(23)
  FeatureSettings ensureEventSettings() => $_ensure(7);

  @$pb.TagNumber(24)
  FeatureSettings get mediaSettings => $_getN(8);
  @$pb.TagNumber(24)
  set mediaSettings(FeatureSettings v) { setField(24, v); }
  @$pb.TagNumber(24)
  $core.bool hasMediaSettings() => $_has(8);
  @$pb.TagNumber(24)
  void clearMediaSettings() => clearField(24);
  @$pb.TagNumber(24)
  FeatureSettings ensureMediaSettings() => $_ensure(8);

  @$pb.TagNumber(90)
  ExternalCDNConfig get externalCdnConfig => $_getN(9);
  @$pb.TagNumber(90)
  set externalCdnConfig(ExternalCDNConfig v) { setField(90, v); }
  @$pb.TagNumber(90)
  $core.bool hasExternalCdnConfig() => $_has(9);
  @$pb.TagNumber(90)
  void clearExternalCdnConfig() => clearField(90);
  @$pb.TagNumber(90)
  ExternalCDNConfig ensureExternalCdnConfig() => $_ensure(9);

  @$pb.TagNumber(100)
  PrivateUserStrategy get privateUserStrategy => $_getN(10);
  @$pb.TagNumber(100)
  set privateUserStrategy(PrivateUserStrategy v) { setField(100, v); }
  @$pb.TagNumber(100)
  $core.bool hasPrivateUserStrategy() => $_has(10);
  @$pb.TagNumber(100)
  void clearPrivateUserStrategy() => clearField(100);

  @$pb.TagNumber(101)
  $core.List<AuthenticationFeature> get authenticationFeatures => $_getList(11);
}

class ExternalCDNConfig extends $pb.GeneratedMessage {
  factory ExternalCDNConfig() => create();
  ExternalCDNConfig._() : super();
  factory ExternalCDNConfig.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExternalCDNConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExternalCDNConfig', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'frontendHost')
    ..aOS(2, _omitFieldNames ? '' : 'backendHost')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExternalCDNConfig clone() => ExternalCDNConfig()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExternalCDNConfig copyWith(void Function(ExternalCDNConfig) updates) => super.copyWith((message) => updates(message as ExternalCDNConfig)) as ExternalCDNConfig;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExternalCDNConfig create() => ExternalCDNConfig._();
  ExternalCDNConfig createEmptyInstance() => create();
  static $pb.PbList<ExternalCDNConfig> createRepeated() => $pb.PbList<ExternalCDNConfig>();
  @$core.pragma('dart2js:noInline')
  static ExternalCDNConfig getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExternalCDNConfig>(create);
  static ExternalCDNConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get frontendHost => $_getSZ(0);
  @$pb.TagNumber(1)
  set frontendHost($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFrontendHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearFrontendHost() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get backendHost => $_getSZ(1);
  @$pb.TagNumber(2)
  set backendHost($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBackendHost() => $_has(1);
  @$pb.TagNumber(2)
  void clearBackendHost() => clearField(2);
}

class FeatureSettings extends $pb.GeneratedMessage {
  factory FeatureSettings() => create();
  FeatureSettings._() : super();
  factory FeatureSettings.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FeatureSettings.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FeatureSettings', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'visible')
    ..e<$11.Moderation>(2, _omitFieldNames ? '' : 'defaultModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Visibility>(3, _omitFieldNames ? '' : 'defaultVisibility', $pb.PbFieldType.OE, defaultOrMaker: $11.Visibility.VISIBILITY_UNKNOWN, valueOf: $11.Visibility.valueOf, enumValues: $11.Visibility.values)
    ..aOS(4, _omitFieldNames ? '' : 'customTitle')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FeatureSettings clone() => FeatureSettings()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FeatureSettings copyWith(void Function(FeatureSettings) updates) => super.copyWith((message) => updates(message as FeatureSettings)) as FeatureSettings;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FeatureSettings create() => FeatureSettings._();
  FeatureSettings createEmptyInstance() => create();
  static $pb.PbList<FeatureSettings> createRepeated() => $pb.PbList<FeatureSettings>();
  @$core.pragma('dart2js:noInline')
  static FeatureSettings getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FeatureSettings>(create);
  static FeatureSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get visible => $_getBF(0);
  @$pb.TagNumber(1)
  set visible($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVisible() => $_has(0);
  @$pb.TagNumber(1)
  void clearVisible() => clearField(1);

  @$pb.TagNumber(2)
  $11.Moderation get defaultModeration => $_getN(1);
  @$pb.TagNumber(2)
  set defaultModeration($11.Moderation v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasDefaultModeration() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefaultModeration() => clearField(2);

  @$pb.TagNumber(3)
  $11.Visibility get defaultVisibility => $_getN(2);
  @$pb.TagNumber(3)
  set defaultVisibility($11.Visibility v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasDefaultVisibility() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefaultVisibility() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get customTitle => $_getSZ(3);
  @$pb.TagNumber(4)
  set customTitle($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCustomTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearCustomTitle() => clearField(4);
}

class PostSettings extends $pb.GeneratedMessage {
  factory PostSettings() => create();
  PostSettings._() : super();
  factory PostSettings.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PostSettings.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PostSettings', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'visible')
    ..e<$11.Moderation>(2, _omitFieldNames ? '' : 'defaultModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Visibility>(3, _omitFieldNames ? '' : 'defaultVisibility', $pb.PbFieldType.OE, defaultOrMaker: $11.Visibility.VISIBILITY_UNKNOWN, valueOf: $11.Visibility.valueOf, enumValues: $11.Visibility.values)
    ..aOS(4, _omitFieldNames ? '' : 'customTitle')
    ..aOB(5, _omitFieldNames ? '' : 'enableReplies')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PostSettings clone() => PostSettings()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PostSettings copyWith(void Function(PostSettings) updates) => super.copyWith((message) => updates(message as PostSettings)) as PostSettings;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PostSettings create() => PostSettings._();
  PostSettings createEmptyInstance() => create();
  static $pb.PbList<PostSettings> createRepeated() => $pb.PbList<PostSettings>();
  @$core.pragma('dart2js:noInline')
  static PostSettings getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PostSettings>(create);
  static PostSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get visible => $_getBF(0);
  @$pb.TagNumber(1)
  set visible($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVisible() => $_has(0);
  @$pb.TagNumber(1)
  void clearVisible() => clearField(1);

  @$pb.TagNumber(2)
  $11.Moderation get defaultModeration => $_getN(1);
  @$pb.TagNumber(2)
  set defaultModeration($11.Moderation v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasDefaultModeration() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefaultModeration() => clearField(2);

  @$pb.TagNumber(3)
  $11.Visibility get defaultVisibility => $_getN(2);
  @$pb.TagNumber(3)
  set defaultVisibility($11.Visibility v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasDefaultVisibility() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefaultVisibility() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get customTitle => $_getSZ(3);
  @$pb.TagNumber(4)
  set customTitle($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCustomTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearCustomTitle() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get enableReplies => $_getBF(4);
  @$pb.TagNumber(5)
  set enableReplies($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasEnableReplies() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnableReplies() => clearField(5);
}

class ServerInfo extends $pb.GeneratedMessage {
  factory ServerInfo() => create();
  ServerInfo._() : super();
  factory ServerInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ServerInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ServerInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'shortName')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aOS(4, _omitFieldNames ? '' : 'privacyPolicyLink')
    ..aOS(5, _omitFieldNames ? '' : 'aboutLink')
    ..e<WebUserInterface>(6, _omitFieldNames ? '' : 'webUserInterface', $pb.PbFieldType.OE, defaultOrMaker: WebUserInterface.FLUTTER_WEB, valueOf: WebUserInterface.valueOf, enumValues: WebUserInterface.values)
    ..aOM<ServerColors>(7, _omitFieldNames ? '' : 'colors', subBuilder: ServerColors.create)
    ..a<$core.List<$core.int>>(8, _omitFieldNames ? '' : 'logo', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ServerInfo clone() => ServerInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ServerInfo copyWith(void Function(ServerInfo) updates) => super.copyWith((message) => updates(message as ServerInfo)) as ServerInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerInfo create() => ServerInfo._();
  ServerInfo createEmptyInstance() => create();
  static $pb.PbList<ServerInfo> createRepeated() => $pb.PbList<ServerInfo>();
  @$core.pragma('dart2js:noInline')
  static ServerInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ServerInfo>(create);
  static ServerInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get shortName => $_getSZ(1);
  @$pb.TagNumber(2)
  set shortName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasShortName() => $_has(1);
  @$pb.TagNumber(2)
  void clearShortName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get privacyPolicyLink => $_getSZ(3);
  @$pb.TagNumber(4)
  set privacyPolicyLink($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPrivacyPolicyLink() => $_has(3);
  @$pb.TagNumber(4)
  void clearPrivacyPolicyLink() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get aboutLink => $_getSZ(4);
  @$pb.TagNumber(5)
  set aboutLink($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasAboutLink() => $_has(4);
  @$pb.TagNumber(5)
  void clearAboutLink() => clearField(5);

  @$pb.TagNumber(6)
  WebUserInterface get webUserInterface => $_getN(5);
  @$pb.TagNumber(6)
  set webUserInterface(WebUserInterface v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasWebUserInterface() => $_has(5);
  @$pb.TagNumber(6)
  void clearWebUserInterface() => clearField(6);

  @$pb.TagNumber(7)
  ServerColors get colors => $_getN(6);
  @$pb.TagNumber(7)
  set colors(ServerColors v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasColors() => $_has(6);
  @$pb.TagNumber(7)
  void clearColors() => clearField(7);
  @$pb.TagNumber(7)
  ServerColors ensureColors() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.List<$core.int> get logo => $_getN(7);
  @$pb.TagNumber(8)
  set logo($core.List<$core.int> v) { $_setBytes(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasLogo() => $_has(7);
  @$pb.TagNumber(8)
  void clearLogo() => clearField(8);
}

class ServerColors extends $pb.GeneratedMessage {
  factory ServerColors() => create();
  ServerColors._() : super();
  factory ServerColors.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ServerColors.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ServerColors', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'primary', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'navigation', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'author', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'admin', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'moderator', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ServerColors clone() => ServerColors()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ServerColors copyWith(void Function(ServerColors) updates) => super.copyWith((message) => updates(message as ServerColors)) as ServerColors;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerColors create() => ServerColors._();
  ServerColors createEmptyInstance() => create();
  static $pb.PbList<ServerColors> createRepeated() => $pb.PbList<ServerColors>();
  @$core.pragma('dart2js:noInline')
  static ServerColors getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ServerColors>(create);
  static ServerColors? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get primary => $_getIZ(0);
  @$pb.TagNumber(1)
  set primary($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPrimary() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrimary() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get navigation => $_getIZ(1);
  @$pb.TagNumber(2)
  set navigation($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNavigation() => $_has(1);
  @$pb.TagNumber(2)
  void clearNavigation() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get author => $_getIZ(2);
  @$pb.TagNumber(3)
  set author($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAuthor() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthor() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get admin => $_getIZ(3);
  @$pb.TagNumber(4)
  set admin($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAdmin() => $_has(3);
  @$pb.TagNumber(4)
  void clearAdmin() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get moderator => $_getIZ(4);
  @$pb.TagNumber(5)
  set moderator($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasModerator() => $_has(4);
  @$pb.TagNumber(5)
  void clearModerator() => clearField(5);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
