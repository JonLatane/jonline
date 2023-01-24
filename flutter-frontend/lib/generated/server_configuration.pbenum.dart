///
//  Generated code. Do not modify.
//  source: server_configuration.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class AuthenticationFeature extends $pb.ProtobufEnum {
  static const AuthenticationFeature AUTHENTICATION_FEATURE_UNKNOWN = AuthenticationFeature._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AUTHENTICATION_FEATURE_UNKNOWN');
  static const AuthenticationFeature CREATE_ACCOUNT = AuthenticationFeature._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CREATE_ACCOUNT');
  static const AuthenticationFeature LOGIN = AuthenticationFeature._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'LOGIN');

  static const $core.List<AuthenticationFeature> values = <AuthenticationFeature> [
    AUTHENTICATION_FEATURE_UNKNOWN,
    CREATE_ACCOUNT,
    LOGIN,
  ];

  static final $core.Map<$core.int, AuthenticationFeature> _byValue = $pb.ProtobufEnum.initByValue(values);
  static AuthenticationFeature? valueOf($core.int value) => _byValue[value];

  const AuthenticationFeature._($core.int v, $core.String n) : super(v, n);
}

class PrivateUserStrategy extends $pb.ProtobufEnum {
  static const PrivateUserStrategy ACCOUNT_IS_FROZEN = PrivateUserStrategy._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ACCOUNT_IS_FROZEN');
  static const PrivateUserStrategy LIMITED_CREEPINESS = PrivateUserStrategy._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'LIMITED_CREEPINESS');
  static const PrivateUserStrategy LET_ME_CREEP_ON_PPL = PrivateUserStrategy._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'LET_ME_CREEP_ON_PPL');

  static const $core.List<PrivateUserStrategy> values = <PrivateUserStrategy> [
    ACCOUNT_IS_FROZEN,
    LIMITED_CREEPINESS,
    LET_ME_CREEP_ON_PPL,
  ];

  static final $core.Map<$core.int, PrivateUserStrategy> _byValue = $pb.ProtobufEnum.initByValue(values);
  static PrivateUserStrategy? valueOf($core.int value) => _byValue[value];

  const PrivateUserStrategy._($core.int v, $core.String n) : super(v, n);
}

class WebUserInterface extends $pb.ProtobufEnum {
  static const WebUserInterface FLUTTER_WEB = WebUserInterface._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FLUTTER_WEB');
  static const WebUserInterface HANDLEBARS_TEMPLATES = WebUserInterface._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'HANDLEBARS_TEMPLATES');
  static const WebUserInterface REACT_TAMAGUI = WebUserInterface._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REACT_TAMAGUI');

  static const $core.List<WebUserInterface> values = <WebUserInterface> [
    FLUTTER_WEB,
    HANDLEBARS_TEMPLATES,
    REACT_TAMAGUI,
  ];

  static final $core.Map<$core.int, WebUserInterface> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WebUserInterface? valueOf($core.int value) => _byValue[value];

  const WebUserInterface._($core.int v, $core.String n) : super(v, n);
}

