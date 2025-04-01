//
//  Generated code. Do not modify.
//  source: users.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Ways of listing users.
class UserListingType extends $pb.ProtobufEnum {
  /// Get all users.
  static const UserListingType EVERYONE = UserListingType._(0, _omitEnumNames ? '' : 'EVERYONE');
  /// Get users the current user is following.
  static const UserListingType FOLLOWING = UserListingType._(1, _omitEnumNames ? '' : 'FOLLOWING');
  /// Get users who follow and are followed by the current user.
  static const UserListingType FRIENDS = UserListingType._(2, _omitEnumNames ? '' : 'FRIENDS');
  /// Get users who follow the current user.
  static const UserListingType FOLLOWERS = UserListingType._(3, _omitEnumNames ? '' : 'FOLLOWERS');
  /// Get users who have requested to follow the current user.
  static const UserListingType FOLLOW_REQUESTS = UserListingType._(4, _omitEnumNames ? '' : 'FOLLOW_REQUESTS');
  /// [TODO] Gets admins for a server.
  static const UserListingType ADMINS = UserListingType._(10, _omitEnumNames ? '' : 'ADMINS');

  static const $core.List<UserListingType> values = <UserListingType> [
    EVERYONE,
    FOLLOWING,
    FRIENDS,
    FOLLOWERS,
    FOLLOW_REQUESTS,
    ADMINS,
  ];

  static final $core.Map<$core.int, UserListingType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static UserListingType? valueOf($core.int value) => _byValue[value];

  const UserListingType._(super.v, super.n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
