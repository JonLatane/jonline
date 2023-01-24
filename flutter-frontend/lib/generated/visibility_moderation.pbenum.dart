///
//  Generated code. Do not modify.
//  source: visibility_moderation.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Visibility extends $pb.ProtobufEnum {
  static const Visibility VISIBILITY_UNKNOWN = Visibility._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VISIBILITY_UNKNOWN');
  static const Visibility PRIVATE = Visibility._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PRIVATE');
  static const Visibility LIMITED = Visibility._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'LIMITED');
  static const Visibility SERVER_PUBLIC = Visibility._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SERVER_PUBLIC');
  static const Visibility GLOBAL_PUBLIC = Visibility._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GLOBAL_PUBLIC');

  static const $core.List<Visibility> values = <Visibility> [
    VISIBILITY_UNKNOWN,
    PRIVATE,
    LIMITED,
    SERVER_PUBLIC,
    GLOBAL_PUBLIC,
  ];

  static final $core.Map<$core.int, Visibility> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Visibility? valueOf($core.int value) => _byValue[value];

  const Visibility._($core.int v, $core.String n) : super(v, n);
}

class Moderation extends $pb.ProtobufEnum {
  static const Moderation MODERATION_UNKNOWN = Moderation._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MODERATION_UNKNOWN');
  static const Moderation UNMODERATED = Moderation._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UNMODERATED');
  static const Moderation PENDING = Moderation._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PENDING');
  static const Moderation APPROVED = Moderation._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'APPROVED');
  static const Moderation REJECTED = Moderation._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REJECTED');

  static const $core.List<Moderation> values = <Moderation> [
    MODERATION_UNKNOWN,
    UNMODERATED,
    PENDING,
    APPROVED,
    REJECTED,
  ];

  static final $core.Map<$core.int, Moderation> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Moderation? valueOf($core.int value) => _byValue[value];

  const Moderation._($core.int v, $core.String n) : super(v, n);
}

