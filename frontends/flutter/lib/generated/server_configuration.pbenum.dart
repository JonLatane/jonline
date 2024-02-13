//
//  Generated code. Do not modify.
//  source: server_configuration.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Authentication features that can be enabled/disabled by the server admin.
class AuthenticationFeature extends $pb.ProtobufEnum {
  static const AuthenticationFeature AUTHENTICATION_FEATURE_UNKNOWN = AuthenticationFeature._(0, _omitEnumNames ? '' : 'AUTHENTICATION_FEATURE_UNKNOWN');
  static const AuthenticationFeature CREATE_ACCOUNT = AuthenticationFeature._(1, _omitEnumNames ? '' : 'CREATE_ACCOUNT');
  static const AuthenticationFeature LOGIN = AuthenticationFeature._(2, _omitEnumNames ? '' : 'LOGIN');

  static const $core.List<AuthenticationFeature> values = <AuthenticationFeature> [
    AUTHENTICATION_FEATURE_UNKNOWN,
    CREATE_ACCOUNT,
    LOGIN,
  ];

  static final $core.Map<$core.int, AuthenticationFeature> _byValue = $pb.ProtobufEnum.initByValue(values);
  static AuthenticationFeature? valueOf($core.int value) => _byValue[value];

  const AuthenticationFeature._($core.int v, $core.String n) : super(v, n);
}

/// Strategy when a user sets their visibility to `PRIVATE`.
class PrivateUserStrategy extends $pb.ProtobufEnum {
  static const PrivateUserStrategy ACCOUNT_IS_FROZEN = PrivateUserStrategy._(0, _omitEnumNames ? '' : 'ACCOUNT_IS_FROZEN');
  static const PrivateUserStrategy LIMITED_CREEPINESS = PrivateUserStrategy._(1, _omitEnumNames ? '' : 'LIMITED_CREEPINESS');
  static const PrivateUserStrategy LET_ME_CREEP_ON_PPL = PrivateUserStrategy._(2, _omitEnumNames ? '' : 'LET_ME_CREEP_ON_PPL');

  static const $core.List<PrivateUserStrategy> values = <PrivateUserStrategy> [
    ACCOUNT_IS_FROZEN,
    LIMITED_CREEPINESS,
    LET_ME_CREEP_ON_PPL,
  ];

  static final $core.Map<$core.int, PrivateUserStrategy> _byValue = $pb.ProtobufEnum.initByValue(values);
  static PrivateUserStrategy? valueOf($core.int value) => _byValue[value];

  const PrivateUserStrategy._($core.int v, $core.String n) : super(v, n);
}

/// Offers a choice of web UIs. Generally though, React/Tamagui is
/// a century ahead of Flutter Web, so it's the default.
class WebUserInterface extends $pb.ProtobufEnum {
  static const WebUserInterface FLUTTER_WEB = WebUserInterface._(0, _omitEnumNames ? '' : 'FLUTTER_WEB');
  static const WebUserInterface HANDLEBARS_TEMPLATES = WebUserInterface._(1, _omitEnumNames ? '' : 'HANDLEBARS_TEMPLATES');
  static const WebUserInterface REACT_TAMAGUI = WebUserInterface._(2, _omitEnumNames ? '' : 'REACT_TAMAGUI');

  static const $core.List<WebUserInterface> values = <WebUserInterface> [
    FLUTTER_WEB,
    HANDLEBARS_TEMPLATES,
    REACT_TAMAGUI,
  ];

  static final $core.Map<$core.int, WebUserInterface> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WebUserInterface? valueOf($core.int value) => _byValue[value];

  const WebUserInterface._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
