//
//  Generated code. Do not modify.
//  source: users.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Ways of listing users.
class UserListingType extends $pb.ProtobufEnum {
  static const UserListingType EVERYONE = UserListingType._(0, _omitEnumNames ? '' : 'EVERYONE');
  static const UserListingType FOLLOWING = UserListingType._(1, _omitEnumNames ? '' : 'FOLLOWING');
  static const UserListingType FRIENDS = UserListingType._(2, _omitEnumNames ? '' : 'FRIENDS');
  static const UserListingType FOLLOWERS = UserListingType._(3, _omitEnumNames ? '' : 'FOLLOWERS');
  static const UserListingType FOLLOW_REQUESTS = UserListingType._(4, _omitEnumNames ? '' : 'FOLLOW_REQUESTS');

  static const $core.List<UserListingType> values = <UserListingType> [
    EVERYONE,
    FOLLOWING,
    FRIENDS,
    FOLLOWERS,
    FOLLOW_REQUESTS,
  ];

  static final $core.Map<$core.int, UserListingType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static UserListingType? valueOf($core.int value) => _byValue[value];

  const UserListingType._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
