///
//  Generated code. Do not modify.
//  source: visibility_moderation.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use visibilityDescriptor instead')
const Visibility$json = const {
  '1': 'Visibility',
  '2': const [
    const {'1': 'VISIBILITY_UNKNOWN', '2': 0},
    const {'1': 'PRIVATE', '2': 1},
    const {'1': 'LIMITED', '2': 2},
    const {'1': 'SERVER_PUBLIC', '2': 3},
    const {'1': 'GLOBAL_PUBLIC', '2': 4},
  ],
};

/// Descriptor for `Visibility`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List visibilityDescriptor = $convert.base64Decode('CgpWaXNpYmlsaXR5EhYKElZJU0lCSUxJVFlfVU5LTk9XThAAEgsKB1BSSVZBVEUQARILCgdMSU1JVEVEEAISEQoNU0VSVkVSX1BVQkxJQxADEhEKDUdMT0JBTF9QVUJMSUMQBA==');
@$core.Deprecated('Use moderationDescriptor instead')
const Moderation$json = const {
  '1': 'Moderation',
  '2': const [
    const {'1': 'MODERATION_UNKNOWN', '2': 0},
    const {'1': 'UNMODERATED', '2': 1},
    const {'1': 'PENDING', '2': 2},
    const {'1': 'APPROVED', '2': 3},
    const {'1': 'REJECTED', '2': 4},
  ],
};

/// Descriptor for `Moderation`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List moderationDescriptor = $convert.base64Decode('CgpNb2RlcmF0aW9uEhYKEk1PREVSQVRJT05fVU5LTk9XThAAEg8KC1VOTU9ERVJBVEVEEAESCwoHUEVORElORxACEgwKCEFQUFJPVkVEEAMSDAoIUkVKRUNURUQQBA==');
