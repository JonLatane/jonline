///
//  Generated code. Do not modify.
//  source: groups.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class GroupListingType extends $pb.ProtobufEnum {
  static const GroupListingType ALL_GROUPS = GroupListingType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ALL_GROUPS');
  static const GroupListingType MY_GROUPS = GroupListingType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MY_GROUPS');
  static const GroupListingType REQUESTED_GROUPS = GroupListingType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REQUESTED_GROUPS');
  static const GroupListingType INVITED_GROUPS = GroupListingType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'INVITED_GROUPS');

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

