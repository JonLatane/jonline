// This is a generated file - do not edit.
//
// Generated from users.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Ways of listing users.
class UserListingType extends $pb.ProtobufEnum {
  /// Get all users.
  static const UserListingType EVERYONE =
      UserListingType._(0, _omitEnumNames ? '' : 'EVERYONE');

  /// Get users the current user is following.
  static const UserListingType FOLLOWING =
      UserListingType._(1, _omitEnumNames ? '' : 'FOLLOWING');

  /// Get users who follow and are followed by the current user.
  static const UserListingType FRIENDS =
      UserListingType._(2, _omitEnumNames ? '' : 'FRIENDS');

  /// Get users who follow the current user.
  static const UserListingType FOLLOWERS =
      UserListingType._(3, _omitEnumNames ? '' : 'FOLLOWERS');

  /// Get users who have requested to follow the current user.
  static const UserListingType FOLLOW_REQUESTS =
      UserListingType._(4, _omitEnumNames ? '' : 'FOLLOW_REQUESTS');

  /// Returns users matching the full-text `search_text` query, scoped the same way
  /// `EVERYONE` is. Requires `search_text` parameter.
  ///
  /// Named `USERS_TEXT_SEARCH` (not the bare `TEXT_SEARCH` used by `PostListingType`) because
  /// proto3 enum values share a single namespace across the whole `jonline` package (C++ scoping
  /// rules) - `PostListingType` already claimed `TEXT_SEARCH`.
  static const UserListingType USERS_TEXT_SEARCH =
      UserListingType._(5, _omitEnumNames ? '' : 'USERS_TEXT_SEARCH');

  /// Scopes `TEXT_SEARCH` to users following `user_id`. Requires `search_text` and `user_id`.
  static const UserListingType FOLLOWERS_TEXT_SEARCH =
      UserListingType._(6, _omitEnumNames ? '' : 'FOLLOWERS_TEXT_SEARCH');

  /// Scopes `TEXT_SEARCH` to users `user_id` follows. Requires `search_text` and `user_id`.
  static const UserListingType FOLLOWING_TEXT_SEARCH =
      UserListingType._(7, _omitEnumNames ? '' : 'FOLLOWING_TEXT_SEARCH');

  /// Scopes `TEXT_SEARCH` to `user_id`'s friends (mutual follows). Requires `search_text` and `user_id`.
  static const UserListingType FRIENDS_TEXT_SEARCH =
      UserListingType._(8, _omitEnumNames ? '' : 'FRIENDS_TEXT_SEARCH');

  /// Scopes `TEXT_SEARCH` to the signed-in caller's pending follow requests. Requires `search_text`.
  static const UserListingType FOLLOW_REQUESTS_TEXT_SEARCH =
      UserListingType._(9, _omitEnumNames ? '' : 'FOLLOW_REQUESTS_TEXT_SEARCH');

  /// [TODO] Gets admins for a server.
  static const UserListingType ADMINS =
      UserListingType._(10, _omitEnumNames ? '' : 'ADMINS');

  static const $core.List<UserListingType> values = <UserListingType>[
    EVERYONE,
    FOLLOWING,
    FRIENDS,
    FOLLOWERS,
    FOLLOW_REQUESTS,
    USERS_TEXT_SEARCH,
    FOLLOWERS_TEXT_SEARCH,
    FOLLOWING_TEXT_SEARCH,
    FRIENDS_TEXT_SEARCH,
    FOLLOW_REQUESTS_TEXT_SEARCH,
    ADMINS,
  ];

  static final $core.List<UserListingType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static UserListingType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const UserListingType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
