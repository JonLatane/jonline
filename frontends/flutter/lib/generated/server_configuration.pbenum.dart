// This is a generated file - do not edit.
//
// Generated from server_configuration.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Authentication features that can be enabled/disabled by the server admin.
class AuthenticationFeature extends $pb.ProtobufEnum {
  /// An authentication feature that is not known to the server. (Likely, the client and server use different versions of the Jonline protocol.)
  static const AuthenticationFeature AUTHENTICATION_FEATURE_UNKNOWN = AuthenticationFeature._(0, _omitEnumNames ? '' : 'AUTHENTICATION_FEATURE_UNKNOWN');
  /// Users can sign up for an account.
  static const AuthenticationFeature CREATE_ACCOUNT = AuthenticationFeature._(1, _omitEnumNames ? '' : 'CREATE_ACCOUNT');
  /// Users can sign in with an existing account.
  static const AuthenticationFeature LOGIN = AuthenticationFeature._(2, _omitEnumNames ? '' : 'LOGIN');

  static const $core.List<AuthenticationFeature> values = <AuthenticationFeature> [
    AUTHENTICATION_FEATURE_UNKNOWN,
    CREATE_ACCOUNT,
    LOGIN,
  ];

  static final $core.List<AuthenticationFeature?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static AuthenticationFeature? valueOf($core.int value) =>  value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AuthenticationFeature._(super.value, super.name);
}

/// Strategy when a user sets their visibility to `PRIVATE`.
class PrivateUserStrategy extends $pb.ProtobufEnum {
  /// `PRIVATE` Users can't see other Users (only `PUBLIC_GLOBAL` Visilibity Users/Posts/Events).
  /// Other users can't see them.
  static const PrivateUserStrategy ACCOUNT_IS_FROZEN = PrivateUserStrategy._(0, _omitEnumNames ? '' : 'ACCOUNT_IS_FROZEN');
  /// Users can see other users they follow, but only `PUBLIC_GLOBAL` Visilibity Posts/Events.
  /// Other users can't see them.
  static const PrivateUserStrategy LIMITED_CREEPINESS = PrivateUserStrategy._(1, _omitEnumNames ? '' : 'LIMITED_CREEPINESS');
  /// Users can see other users they follow, including their `PUBLIC_SERVER` Posts/Events.
  /// Other users can't see them.
  static const PrivateUserStrategy LET_ME_CREEP_ON_PPL = PrivateUserStrategy._(2, _omitEnumNames ? '' : 'LET_ME_CREEP_ON_PPL');

  static const $core.List<PrivateUserStrategy> values = <PrivateUserStrategy> [
    ACCOUNT_IS_FROZEN,
    LIMITED_CREEPINESS,
    LET_ME_CREEP_ON_PPL,
  ];

  static final $core.List<PrivateUserStrategy?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PrivateUserStrategy? valueOf($core.int value) =>  value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PrivateUserStrategy._(super.value, super.name);
}

/// Offers a choice of web UIs. Generally though, React/Tamagui is
/// a century ahead of Flutter Web, so it's the default.
class WebUserInterface extends $pb.ProtobufEnum {
  /// Uses Flutter Web. Loaded from /app.
  static const WebUserInterface FLUTTER_WEB = WebUserInterface._(0, _omitEnumNames ? '' : 'FLUTTER_WEB');
  /// Uses Handlebars templates. Deprecated; will revert to Tamagui UI if chosen.
  @$core.Deprecated('This enum value is deprecated')
  static const WebUserInterface HANDLEBARS_TEMPLATES = WebUserInterface._(1, _omitEnumNames ? '' : 'HANDLEBARS_TEMPLATES');
  /// React UI using Tamagui (a React Native UI library).
  static const WebUserInterface REACT_TAMAGUI = WebUserInterface._(2, _omitEnumNames ? '' : 'REACT_TAMAGUI');

  static const $core.List<WebUserInterface> values = <WebUserInterface> [
    FLUTTER_WEB,
    HANDLEBARS_TEMPLATES,
    REACT_TAMAGUI,
  ];

  static final $core.List<WebUserInterface?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static WebUserInterface? valueOf($core.int value) =>  value < 0 || value >= _byValue.length ? null : _byValue[value];

  const WebUserInterface._(super.value, super.name);
}


const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
