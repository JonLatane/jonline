//
//  Generated code. Do not modify.
//  source: groups.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// The type of group listing to get.
class GroupListingType extends $pb.ProtobufEnum {
  /// Get all groups (visible to the current user).
  static const GroupListingType ALL_GROUPS = GroupListingType._(0, _omitEnumNames ? '' : 'ALL_GROUPS');
  /// Get groups the current user is a member of.
  static const GroupListingType MY_GROUPS = GroupListingType._(1, _omitEnumNames ? '' : 'MY_GROUPS');
  /// Get groups the current user has requested to join.
  static const GroupListingType REQUESTED_GROUPS = GroupListingType._(2, _omitEnumNames ? '' : 'REQUESTED_GROUPS');
  /// Get groups the current user has been invited to.
  static const GroupListingType INVITED_GROUPS = GroupListingType._(3, _omitEnumNames ? '' : 'INVITED_GROUPS');

  static const $core.List<GroupListingType> values = <GroupListingType> [
    ALL_GROUPS,
    MY_GROUPS,
    REQUESTED_GROUPS,
    INVITED_GROUPS,
  ];

  static final $core.List<GroupListingType?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 3);
  static GroupListingType? valueOf($core.int value) =>  value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GroupListingType._(super.value, super.name);
}


const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
