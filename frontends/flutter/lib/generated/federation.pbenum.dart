//
//  Generated code. Do not modify.
//  source: federation.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class FederationCredentials extends $pb.ProtobufEnum {
  static const FederationCredentials REFRESH_TOKEN_ONLY = FederationCredentials._(0, _omitEnumNames ? '' : 'REFRESH_TOKEN_ONLY');
  static const FederationCredentials REFRESH_TOKEN_AND_PASSWORD = FederationCredentials._(1, _omitEnumNames ? '' : 'REFRESH_TOKEN_AND_PASSWORD');

  static const $core.List<FederationCredentials> values = <FederationCredentials> [
    REFRESH_TOKEN_ONLY,
    REFRESH_TOKEN_AND_PASSWORD,
  ];

  static final $core.Map<$core.int, FederationCredentials> _byValue = $pb.ProtobufEnum.initByValue(values);
  static FederationCredentials? valueOf($core.int value) => _byValue[value];

  const FederationCredentials._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
