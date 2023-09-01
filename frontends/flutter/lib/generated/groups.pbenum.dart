//
//  Generated code. Do not modify.
//  source: groups.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class GroupListingType extends $pb.ProtobufEnum {
  static const GroupListingType ALL_GROUPS = GroupListingType._(0, _omitEnumNames ? '' : 'ALL_GROUPS');
  static const GroupListingType MY_GROUPS = GroupListingType._(1, _omitEnumNames ? '' : 'MY_GROUPS');
  static const GroupListingType REQUESTED_GROUPS = GroupListingType._(2, _omitEnumNames ? '' : 'REQUESTED_GROUPS');
  static const GroupListingType INVITED_GROUPS = GroupListingType._(3, _omitEnumNames ? '' : 'INVITED_GROUPS');

  static const $core.List<GroupListingType> values = <GroupListingType> [
    ALL_GROUPS,
    MY_GROUPS,
    REQUESTED_GROUPS,
    INVITED_GROUPS,
  ];

  static final $core.Map<$core.int, GroupListingType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static GroupListingType? valueOf($core.int value) => _byValue[value];

  const GroupListingType._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
