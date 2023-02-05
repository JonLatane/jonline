///
//  Generated code. Do not modify.
//  source: permissions.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Permission extends $pb.ProtobufEnum {
  static const Permission PERMISSION_UNKNOWN = Permission._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PERMISSION_UNKNOWN');
  static const Permission VIEW_USERS = Permission._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VIEW_USERS');
  static const Permission PUBLISH_USERS_LOCALLY = Permission._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISH_USERS_LOCALLY');
  static const Permission PUBLISH_USERS_GLOBALLY = Permission._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISH_USERS_GLOBALLY');
  static const Permission MODERATE_USERS = Permission._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MODERATE_USERS');
  static const Permission FOLLOW_USERS = Permission._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FOLLOW_USERS');
  static const Permission GRANT_BASIC_PERMISSIONS = Permission._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GRANT_BASIC_PERMISSIONS');
  static const Permission VIEW_GROUPS = Permission._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VIEW_GROUPS');
  static const Permission CREATE_GROUPS = Permission._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CREATE_GROUPS');
  static const Permission PUBLISH_GROUPS_LOCALLY = Permission._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISH_GROUPS_LOCALLY');
  static const Permission PUBLISH_GROUPS_GLOBALLY = Permission._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISH_GROUPS_GLOBALLY');
  static const Permission MODERATE_GROUPS = Permission._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MODERATE_GROUPS');
  static const Permission JOIN_GROUPS = Permission._(15, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'JOIN_GROUPS');
  static const Permission VIEW_POSTS = Permission._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VIEW_POSTS');
  static const Permission CREATE_POSTS = Permission._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CREATE_POSTS');
  static const Permission PUBLISH_POSTS_LOCALLY = Permission._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISH_POSTS_LOCALLY');
  static const Permission PUBLISH_POSTS_GLOBALLY = Permission._(23, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISH_POSTS_GLOBALLY');
  static const Permission MODERATE_POSTS = Permission._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MODERATE_POSTS');
  static const Permission REPLY_TO_POSTS = Permission._(25, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REPLY_TO_POSTS');
  static const Permission VIEW_EVENTS = Permission._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VIEW_EVENTS');
  static const Permission CREATE_EVENTS = Permission._(31, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CREATE_EVENTS');
  static const Permission PUBLISH_EVENTS_LOCALLY = Permission._(32, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISH_EVENTS_LOCALLY');
  static const Permission PUBLISH_EVENTS_GLOBALLY = Permission._(33, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLISH_EVENTS_GLOBALLY');
  static const Permission MODERATE_EVENTS = Permission._(34, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MODERATE_EVENTS');
  static const Permission RUN_BOTS = Permission._(9999, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RUN_BOTS');
  static const Permission ADMIN = Permission._(10000, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ADMIN');
  static const Permission VIEW_PRIVATE_CONTACT_METHODS = Permission._(10001, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VIEW_PRIVATE_CONTACT_METHODS');

  static const $core.List<Permission> values = <Permission> [
    PERMISSION_UNKNOWN,
    VIEW_USERS,
    PUBLISH_USERS_LOCALLY,
    PUBLISH_USERS_GLOBALLY,
    MODERATE_USERS,
    FOLLOW_USERS,
    GRANT_BASIC_PERMISSIONS,
    VIEW_GROUPS,
    CREATE_GROUPS,
    PUBLISH_GROUPS_LOCALLY,
    PUBLISH_GROUPS_GLOBALLY,
    MODERATE_GROUPS,
    JOIN_GROUPS,
    VIEW_POSTS,
    CREATE_POSTS,
    PUBLISH_POSTS_LOCALLY,
    PUBLISH_POSTS_GLOBALLY,
    MODERATE_POSTS,
    REPLY_TO_POSTS,
    VIEW_EVENTS,
    CREATE_EVENTS,
    PUBLISH_EVENTS_LOCALLY,
    PUBLISH_EVENTS_GLOBALLY,
    MODERATE_EVENTS,
    RUN_BOTS,
    ADMIN,
    VIEW_PRIVATE_CONTACT_METHODS,
  ];

  static final $core.Map<$core.int, Permission> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Permission? valueOf($core.int value) => _byValue[value];

  const Permission._($core.int v, $core.String n) : super(v, n);
}

