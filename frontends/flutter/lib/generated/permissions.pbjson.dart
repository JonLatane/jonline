///
//  Generated code. Do not modify.
//  source: permissions.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use permissionDescriptor instead')
const Permission$json = const {
  '1': 'Permission',
  '2': const [
    const {'1': 'PERMISSION_UNKNOWN', '2': 0},
    const {'1': 'VIEW_USERS', '2': 1},
    const {'1': 'PUBLISH_USERS_LOCALLY', '2': 2},
    const {'1': 'PUBLISH_USERS_GLOBALLY', '2': 3},
    const {'1': 'MODERATE_USERS', '2': 4},
    const {'1': 'FOLLOW_USERS', '2': 5},
    const {'1': 'GRANT_BASIC_PERMISSIONS', '2': 6},
    const {'1': 'VIEW_GROUPS', '2': 10},
    const {'1': 'CREATE_GROUPS', '2': 11},
    const {'1': 'PUBLISH_GROUPS_LOCALLY', '2': 12},
    const {'1': 'PUBLISH_GROUPS_GLOBALLY', '2': 13},
    const {'1': 'MODERATE_GROUPS', '2': 14},
    const {'1': 'JOIN_GROUPS', '2': 15},
    const {'1': 'VIEW_POSTS', '2': 20},
    const {'1': 'CREATE_POSTS', '2': 21},
    const {'1': 'PUBLISH_POSTS_LOCALLY', '2': 22},
    const {'1': 'PUBLISH_POSTS_GLOBALLY', '2': 23},
    const {'1': 'MODERATE_POSTS', '2': 24},
    const {'1': 'VIEW_EVENTS', '2': 30},
    const {'1': 'CREATE_EVENTS', '2': 31},
    const {'1': 'PUBLISH_EVENTS_LOCALLY', '2': 32},
    const {'1': 'PUBLISH_EVENTS_GLOBALLY', '2': 33},
    const {'1': 'MODERATE_EVENTS', '2': 34},
    const {'1': 'RUN_BOTS', '2': 9999},
    const {'1': 'ADMIN', '2': 10000},
    const {'1': 'VIEW_PRIVATE_CONTACT_METHODS', '2': 10001},
  ],
};

/// Descriptor for `Permission`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List permissionDescriptor = $convert.base64Decode('CgpQZXJtaXNzaW9uEhYKElBFUk1JU1NJT05fVU5LTk9XThAAEg4KClZJRVdfVVNFUlMQARIZChVQVUJMSVNIX1VTRVJTX0xPQ0FMTFkQAhIaChZQVUJMSVNIX1VTRVJTX0dMT0JBTExZEAMSEgoOTU9ERVJBVEVfVVNFUlMQBBIQCgxGT0xMT1dfVVNFUlMQBRIbChdHUkFOVF9CQVNJQ19QRVJNSVNTSU9OUxAGEg8KC1ZJRVdfR1JPVVBTEAoSEQoNQ1JFQVRFX0dST1VQUxALEhoKFlBVQkxJU0hfR1JPVVBTX0xPQ0FMTFkQDBIbChdQVUJMSVNIX0dST1VQU19HTE9CQUxMWRANEhMKD01PREVSQVRFX0dST1VQUxAOEg8KC0pPSU5fR1JPVVBTEA8SDgoKVklFV19QT1NUUxAUEhAKDENSRUFURV9QT1NUUxAVEhkKFVBVQkxJU0hfUE9TVFNfTE9DQUxMWRAWEhoKFlBVQkxJU0hfUE9TVFNfR0xPQkFMTFkQFxISCg5NT0RFUkFURV9QT1NUUxAYEg8KC1ZJRVdfRVZFTlRTEB4SEQoNQ1JFQVRFX0VWRU5UUxAfEhoKFlBVQkxJU0hfRVZFTlRTX0xPQ0FMTFkQIBIbChdQVUJMSVNIX0VWRU5UU19HTE9CQUxMWRAhEhMKD01PREVSQVRFX0VWRU5UUxAiEg0KCFJVTl9CT1RTEI9OEgoKBUFETUlOEJBOEiEKHFZJRVdfUFJJVkFURV9DT05UQUNUX01FVEhPRFMQkU4=');
