///
//  Generated code. Do not modify.
//  source: users.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class UserListingType extends $pb.ProtobufEnum {
  static const UserListingType EVERYONE = UserListingType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EVERYONE');
  static const UserListingType FOLLOWING = UserListingType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FOLLOWING');
  static const UserListingType FRIENDS = UserListingType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FRIENDS');
  static const UserListingType FOLLOWERS = UserListingType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FOLLOWERS');
  static const UserListingType FOLLOW_REQUESTS = UserListingType._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FOLLOW_REQUESTS');

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

