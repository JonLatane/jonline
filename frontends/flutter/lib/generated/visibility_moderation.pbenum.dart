//
//  Generated code. Do not modify.
//  source: visibility_moderation.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Visibility extends $pb.ProtobufEnum {
  static const Visibility VISIBILITY_UNKNOWN = Visibility._(0, _omitEnumNames ? '' : 'VISIBILITY_UNKNOWN');
  static const Visibility PRIVATE = Visibility._(1, _omitEnumNames ? '' : 'PRIVATE');
  static const Visibility LIMITED = Visibility._(2, _omitEnumNames ? '' : 'LIMITED');
  static const Visibility SERVER_PUBLIC = Visibility._(3, _omitEnumNames ? '' : 'SERVER_PUBLIC');
  static const Visibility GLOBAL_PUBLIC = Visibility._(4, _omitEnumNames ? '' : 'GLOBAL_PUBLIC');
  static const Visibility DIRECT = Visibility._(5, _omitEnumNames ? '' : 'DIRECT');

  static const $core.List<Visibility> values = <Visibility> [
    VISIBILITY_UNKNOWN,
    PRIVATE,
    LIMITED,
    SERVER_PUBLIC,
    GLOBAL_PUBLIC,
    DIRECT,
  ];

  static final $core.Map<$core.int, Visibility> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Visibility? valueOf($core.int value) => _byValue[value];

  const Visibility._($core.int v, $core.String n) : super(v, n);
}

class Moderation extends $pb.ProtobufEnum {
  static const Moderation MODERATION_UNKNOWN = Moderation._(0, _omitEnumNames ? '' : 'MODERATION_UNKNOWN');
  static const Moderation UNMODERATED = Moderation._(1, _omitEnumNames ? '' : 'UNMODERATED');
  static const Moderation PENDING = Moderation._(2, _omitEnumNames ? '' : 'PENDING');
  static const Moderation APPROVED = Moderation._(3, _omitEnumNames ? '' : 'APPROVED');
  static const Moderation REJECTED = Moderation._(4, _omitEnumNames ? '' : 'REJECTED');

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


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
