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

/// The Events Calendar's default UI granularity.
class CalendarDisplayMode extends $pb.ProtobufEnum {
  static const CalendarDisplayMode CALENDAR_DISPLAY_WEEK = CalendarDisplayMode._(0, _omitEnumNames ? '' : 'CALENDAR_DISPLAY_WEEK');
  static const CalendarDisplayMode CALENDAR_DISPLAY_MONTH = CalendarDisplayMode._(1, _omitEnumNames ? '' : 'CALENDAR_DISPLAY_MONTH');
  static const CalendarDisplayMode CALENDAR_DISPLAY_DAY = CalendarDisplayMode._(3, _omitEnumNames ? '' : 'CALENDAR_DISPLAY_DAY');

  static const $core.List<CalendarDisplayMode> values = <CalendarDisplayMode> [
    CALENDAR_DISPLAY_WEEK,
    CALENDAR_DISPLAY_MONTH,
    CALENDAR_DISPLAY_DAY,
  ];

  static final $core.Map<$core.int, CalendarDisplayMode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static CalendarDisplayMode? valueOf($core.int value) => _byValue[value];

  const CalendarDisplayMode._($core.int v, $core.String n) : super(v, n);
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
  static const WebUserInterface ELM_SPA = WebUserInterface._(3, _omitEnumNames ? '' : 'ELM_SPA');

  static const $core.List<WebUserInterface> values = <WebUserInterface> [
    FLUTTER_WEB,
    HANDLEBARS_TEMPLATES,
    REACT_TAMAGUI,
    ELM_SPA,
  ];

  static final $core.Map<$core.int, WebUserInterface> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WebUserInterface? valueOf($core.int value) => _byValue[value];

  const WebUserInterface._($core.int v, $core.String n) : super(v, n);
}

/// The default navigation tabs in Jonline's Elm UI.
class NavigationTab extends $pb.ProtobufEnum {
  static const NavigationTab HOME_TAB = NavigationTab._(0, _omitEnumNames ? '' : 'HOME_TAB');
  static const NavigationTab EVENTS_TAB = NavigationTab._(10, _omitEnumNames ? '' : 'EVENTS_TAB');
  static const NavigationTab POSTS_TAB = NavigationTab._(11, _omitEnumNames ? '' : 'POSTS_TAB');
  static const NavigationTab PEOPLE_TAB = NavigationTab._(12, _omitEnumNames ? '' : 'PEOPLE_TAB');
  static const NavigationTab ABOUT_TAB = NavigationTab._(15, _omitEnumNames ? '' : 'ABOUT_TAB');

  static const $core.List<NavigationTab> values = <NavigationTab> [
    HOME_TAB,
    EVENTS_TAB,
    POSTS_TAB,
    PEOPLE_TAB,
    ABOUT_TAB,
  ];

  static final $core.Map<$core.int, NavigationTab> _byValue = $pb.ProtobufEnum.initByValue(values);
  static NavigationTab? valueOf($core.int value) => _byValue[value];

  const NavigationTab._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
