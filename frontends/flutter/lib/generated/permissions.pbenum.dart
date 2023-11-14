//
//  Generated code. Do not modify.
//  source: permissions.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Permission extends $pb.ProtobufEnum {
  static const Permission PERMISSION_UNKNOWN = Permission._(0, _omitEnumNames ? '' : 'PERMISSION_UNKNOWN');
  static const Permission VIEW_USERS = Permission._(1, _omitEnumNames ? '' : 'VIEW_USERS');
  static const Permission PUBLISH_USERS_LOCALLY = Permission._(2, _omitEnumNames ? '' : 'PUBLISH_USERS_LOCALLY');
  static const Permission PUBLISH_USERS_GLOBALLY = Permission._(3, _omitEnumNames ? '' : 'PUBLISH_USERS_GLOBALLY');
  static const Permission MODERATE_USERS = Permission._(4, _omitEnumNames ? '' : 'MODERATE_USERS');
  static const Permission FOLLOW_USERS = Permission._(5, _omitEnumNames ? '' : 'FOLLOW_USERS');
  static const Permission GRANT_BASIC_PERMISSIONS = Permission._(6, _omitEnumNames ? '' : 'GRANT_BASIC_PERMISSIONS');
  static const Permission VIEW_GROUPS = Permission._(10, _omitEnumNames ? '' : 'VIEW_GROUPS');
  static const Permission CREATE_GROUPS = Permission._(11, _omitEnumNames ? '' : 'CREATE_GROUPS');
  static const Permission PUBLISH_GROUPS_LOCALLY = Permission._(12, _omitEnumNames ? '' : 'PUBLISH_GROUPS_LOCALLY');
  static const Permission PUBLISH_GROUPS_GLOBALLY = Permission._(13, _omitEnumNames ? '' : 'PUBLISH_GROUPS_GLOBALLY');
  static const Permission MODERATE_GROUPS = Permission._(14, _omitEnumNames ? '' : 'MODERATE_GROUPS');
  static const Permission JOIN_GROUPS = Permission._(15, _omitEnumNames ? '' : 'JOIN_GROUPS');
  static const Permission VIEW_POSTS = Permission._(20, _omitEnumNames ? '' : 'VIEW_POSTS');
  static const Permission CREATE_POSTS = Permission._(21, _omitEnumNames ? '' : 'CREATE_POSTS');
  static const Permission PUBLISH_POSTS_LOCALLY = Permission._(22, _omitEnumNames ? '' : 'PUBLISH_POSTS_LOCALLY');
  static const Permission PUBLISH_POSTS_GLOBALLY = Permission._(23, _omitEnumNames ? '' : 'PUBLISH_POSTS_GLOBALLY');
  static const Permission MODERATE_POSTS = Permission._(24, _omitEnumNames ? '' : 'MODERATE_POSTS');
  static const Permission REPLY_TO_POSTS = Permission._(25, _omitEnumNames ? '' : 'REPLY_TO_POSTS');
  static const Permission VIEW_EVENTS = Permission._(30, _omitEnumNames ? '' : 'VIEW_EVENTS');
  static const Permission CREATE_EVENTS = Permission._(31, _omitEnumNames ? '' : 'CREATE_EVENTS');
  static const Permission PUBLISH_EVENTS_LOCALLY = Permission._(32, _omitEnumNames ? '' : 'PUBLISH_EVENTS_LOCALLY');
  static const Permission PUBLISH_EVENTS_GLOBALLY = Permission._(33, _omitEnumNames ? '' : 'PUBLISH_EVENTS_GLOBALLY');
  static const Permission MODERATE_EVENTS = Permission._(34, _omitEnumNames ? '' : 'MODERATE_EVENTS');
  static const Permission RSVP_TO_EVENTS = Permission._(35, _omitEnumNames ? '' : 'RSVP_TO_EVENTS');
  static const Permission VIEW_MEDIA = Permission._(40, _omitEnumNames ? '' : 'VIEW_MEDIA');
  static const Permission CREATE_MEDIA = Permission._(41, _omitEnumNames ? '' : 'CREATE_MEDIA');
  static const Permission PUBLISH_MEDIA_LOCALLY = Permission._(42, _omitEnumNames ? '' : 'PUBLISH_MEDIA_LOCALLY');
  static const Permission PUBLISH_MEDIA_GLOBALLY = Permission._(43, _omitEnumNames ? '' : 'PUBLISH_MEDIA_GLOBALLY');
  static const Permission MODERATE_MEDIA = Permission._(44, _omitEnumNames ? '' : 'MODERATE_MEDIA');
  static const Permission RUN_BOTS = Permission._(9999, _omitEnumNames ? '' : 'RUN_BOTS');
  static const Permission ADMIN = Permission._(10000, _omitEnumNames ? '' : 'ADMIN');
  static const Permission VIEW_PRIVATE_CONTACT_METHODS = Permission._(10001, _omitEnumNames ? '' : 'VIEW_PRIVATE_CONTACT_METHODS');

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
    RSVP_TO_EVENTS,
    VIEW_MEDIA,
    CREATE_MEDIA,
    PUBLISH_MEDIA_LOCALLY,
    PUBLISH_MEDIA_GLOBALLY,
    MODERATE_MEDIA,
    RUN_BOTS,
    ADMIN,
    VIEW_PRIVATE_CONTACT_METHODS,
  ];

  static final $core.Map<$core.int, Permission> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Permission? valueOf($core.int value) => _byValue[value];

  const Permission._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
