///
//  Generated code. Do not modify.
//  source: server_configuration.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'permissions.pbenum.dart' as $8;
import 'server_configuration.pbenum.dart';
import 'visibility_moderation.pbenum.dart' as $9;

export 'server_configuration.pbenum.dart';

class ServerConfiguration extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ServerConfiguration', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<ServerInfo>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'serverInfo', subBuilder: ServerInfo.create)
    ..pc<$8.Permission>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'anonymousUserPermissions', $pb.PbFieldType.KE, valueOf: $8.Permission.valueOf, enumValues: $8.Permission.values, defaultEnumValue: $8.Permission.PERMISSION_UNKNOWN)
    ..pc<$8.Permission>(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'defaultUserPermissions', $pb.PbFieldType.KE, valueOf: $8.Permission.valueOf, enumValues: $8.Permission.values, defaultEnumValue: $8.Permission.PERMISSION_UNKNOWN)
    ..pc<$8.Permission>(12, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'basicUserPermissions', $pb.PbFieldType.KE, valueOf: $8.Permission.valueOf, enumValues: $8.Permission.values, defaultEnumValue: $8.Permission.PERMISSION_UNKNOWN)
    ..aOM<FeatureSettings>(20, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'peopleSettings', subBuilder: FeatureSettings.create)
    ..aOM<FeatureSettings>(21, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupSettings', subBuilder: FeatureSettings.create)
    ..aOM<FeatureSettings>(22, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'postSettings', subBuilder: FeatureSettings.create)
    ..aOM<FeatureSettings>(23, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'eventSettings', subBuilder: FeatureSettings.create)
    ..e<PrivateUserStrategy>(100, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'privateUserStrategy', $pb.PbFieldType.OE, defaultOrMaker: PrivateUserStrategy.ACCOUNT_IS_FROZEN, valueOf: PrivateUserStrategy.valueOf, enumValues: PrivateUserStrategy.values)
    ..pc<AuthenticationFeature>(101, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'authenticationFeatures', $pb.PbFieldType.KE, valueOf: AuthenticationFeature.valueOf, enumValues: AuthenticationFeature.values, defaultEnumValue: AuthenticationFeature.AUTHENTICATION_FEATURE_UNKNOWN)
    ..hasRequiredFields = false
  ;

  ServerConfiguration._() : super();
  factory ServerConfiguration({
    ServerInfo? serverInfo,
    $core.Iterable<$8.Permission>? anonymousUserPermissions,
    $core.Iterable<$8.Permission>? defaultUserPermissions,
    $core.Iterable<$8.Permission>? basicUserPermissions,
    FeatureSettings? peopleSettings,
    FeatureSettings? groupSettings,
    FeatureSettings? postSettings,
    FeatureSettings? eventSettings,
    PrivateUserStrategy? privateUserStrategy,
    $core.Iterable<AuthenticationFeature>? authenticationFeatures,
  }) {
    final _result = create();
    if (serverInfo != null) {
      _result.serverInfo = serverInfo;
    }
    if (anonymousUserPermissions != null) {
      _result.anonymousUserPermissions.addAll(anonymousUserPermissions);
    }
    if (defaultUserPermissions != null) {
      _result.defaultUserPermissions.addAll(defaultUserPermissions);
    }
    if (basicUserPermissions != null) {
      _result.basicUserPermissions.addAll(basicUserPermissions);
    }
    if (peopleSettings != null) {
      _result.peopleSettings = peopleSettings;
    }
    if (groupSettings != null) {
      _result.groupSettings = groupSettings;
    }
    if (postSettings != null) {
      _result.postSettings = postSettings;
    }
    if (eventSettings != null) {
      _result.eventSettings = eventSettings;
    }
    if (privateUserStrategy != null) {
      _result.privateUserStrategy = privateUserStrategy;
    }
    if (authenticationFeatures != null) {
      _result.authenticationFeatures.addAll(authenticationFeatures);
    }
    return _result;
  }
  factory ServerConfiguration.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ServerConfiguration.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ServerConfiguration clone() => ServerConfiguration()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ServerConfiguration copyWith(void Function(ServerConfiguration) updates) => super.copyWith((message) => updates(message as ServerConfiguration)) as ServerConfiguration; // ignore: deprecated_member_use
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
  $core.List<$8.Permission> get anonymousUserPermissions => $_getList(1);

  @$pb.TagNumber(11)
  $core.List<$8.Permission> get defaultUserPermissions => $_getList(2);

  @$pb.TagNumber(12)
  $core.List<$8.Permission> get basicUserPermissions => $_getList(3);

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
  FeatureSettings get postSettings => $_getN(6);
  @$pb.TagNumber(22)
  set postSettings(FeatureSettings v) { setField(22, v); }
  @$pb.TagNumber(22)
  $core.bool hasPostSettings() => $_has(6);
  @$pb.TagNumber(22)
  void clearPostSettings() => clearField(22);
  @$pb.TagNumber(22)
  FeatureSettings ensurePostSettings() => $_ensure(6);

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

  @$pb.TagNumber(100)
  PrivateUserStrategy get privateUserStrategy => $_getN(8);
  @$pb.TagNumber(100)
  set privateUserStrategy(PrivateUserStrategy v) { setField(100, v); }
  @$pb.TagNumber(100)
  $core.bool hasPrivateUserStrategy() => $_has(8);
  @$pb.TagNumber(100)
  void clearPrivateUserStrategy() => clearField(100);

  @$pb.TagNumber(101)
  $core.List<AuthenticationFeature> get authenticationFeatures => $_getList(9);
}

class FeatureSettings extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FeatureSettings', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visible')
    ..e<$9.Moderation>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'defaultModeration', $pb.PbFieldType.OE, defaultOrMaker: $9.Moderation.MODERATION_UNKNOWN, valueOf: $9.Moderation.valueOf, enumValues: $9.Moderation.values)
    ..e<$9.Visibility>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'defaultVisibility', $pb.PbFieldType.OE, defaultOrMaker: $9.Visibility.VISIBILITY_UNKNOWN, valueOf: $9.Visibility.valueOf, enumValues: $9.Visibility.values)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'customTitle')
    ..hasRequiredFields = false
  ;

  FeatureSettings._() : super();
  factory FeatureSettings({
    $core.bool? visible,
    $9.Moderation? defaultModeration,
    $9.Visibility? defaultVisibility,
    $core.String? customTitle,
  }) {
    final _result = create();
    if (visible != null) {
      _result.visible = visible;
    }
    if (defaultModeration != null) {
      _result.defaultModeration = defaultModeration;
    }
    if (defaultVisibility != null) {
      _result.defaultVisibility = defaultVisibility;
    }
    if (customTitle != null) {
      _result.customTitle = customTitle;
    }
    return _result;
  }
  factory FeatureSettings.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FeatureSettings.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FeatureSettings clone() => FeatureSettings()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FeatureSettings copyWith(void Function(FeatureSettings) updates) => super.copyWith((message) => updates(message as FeatureSettings)) as FeatureSettings; // ignore: deprecated_member_use
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
  $9.Moderation get defaultModeration => $_getN(1);
  @$pb.TagNumber(2)
  set defaultModeration($9.Moderation v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasDefaultModeration() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefaultModeration() => clearField(2);

  @$pb.TagNumber(3)
  $9.Visibility get defaultVisibility => $_getN(2);
  @$pb.TagNumber(3)
  set defaultVisibility($9.Visibility v) { setField(3, v); }
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

class ServerInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ServerInfo', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'shortName')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'description')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'privacyPolicyLink')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'aboutLink')
    ..e<WebUserInterface>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'webUserInterface', $pb.PbFieldType.OE, defaultOrMaker: WebUserInterface.FLUTTER_WEB, valueOf: WebUserInterface.valueOf, enumValues: WebUserInterface.values)
    ..aOM<ServerColors>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'colors', subBuilder: ServerColors.create)
    ..a<$core.List<$core.int>>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'logo', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  ServerInfo._() : super();
  factory ServerInfo({
    $core.String? name,
    $core.String? shortName,
    $core.String? description,
    $core.String? privacyPolicyLink,
    $core.String? aboutLink,
    WebUserInterface? webUserInterface,
    ServerColors? colors,
    $core.List<$core.int>? logo,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (shortName != null) {
      _result.shortName = shortName;
    }
    if (description != null) {
      _result.description = description;
    }
    if (privacyPolicyLink != null) {
      _result.privacyPolicyLink = privacyPolicyLink;
    }
    if (aboutLink != null) {
      _result.aboutLink = aboutLink;
    }
    if (webUserInterface != null) {
      _result.webUserInterface = webUserInterface;
    }
    if (colors != null) {
      _result.colors = colors;
    }
    if (logo != null) {
      _result.logo = logo;
    }
    return _result;
  }
  factory ServerInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ServerInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ServerInfo clone() => ServerInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ServerInfo copyWith(void Function(ServerInfo) updates) => super.copyWith((message) => updates(message as ServerInfo)) as ServerInfo; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ServerColors', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'primary', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'navigation', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'author', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'admin', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'moderator', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  ServerColors._() : super();
  factory ServerColors({
    $core.int? primary,
    $core.int? navigation,
    $core.int? author,
    $core.int? admin,
    $core.int? moderator,
  }) {
    final _result = create();
    if (primary != null) {
      _result.primary = primary;
    }
    if (navigation != null) {
      _result.navigation = navigation;
    }
    if (author != null) {
      _result.author = author;
    }
    if (admin != null) {
      _result.admin = admin;
    }
    if (moderator != null) {
      _result.moderator = moderator;
    }
    return _result;
  }
  factory ServerColors.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ServerColors.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ServerColors clone() => ServerColors()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ServerColors copyWith(void Function(ServerColors) updates) => super.copyWith((message) => updates(message as ServerColors)) as ServerColors; // ignore: deprecated_member_use
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

