///
//  Generated code. Do not modify.
//  source: federation.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class FederationCredentials extends $pb.ProtobufEnum {
  static const FederationCredentials REFRESH_TOKEN_ONLY = FederationCredentials._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REFRESH_TOKEN_ONLY');
  static const FederationCredentials REFRESH_TOKEN_AND_PASSWORD = FederationCredentials._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REFRESH_TOKEN_AND_PASSWORD');

  static const $core.List<FederationCredentials> values = <FederationCredentials> [
    REFRESH_TOKEN_ONLY,
    REFRESH_TOKEN_AND_PASSWORD,
  ];

  static final $core.Map<$core.int, FederationCredentials> _byValue = $pb.ProtobufEnum.initByValue(values);
  static FederationCredentials? valueOf($core.int value) => _byValue[value];

  const FederationCredentials._($core.int v, $core.String n) : super(v, n);
}

