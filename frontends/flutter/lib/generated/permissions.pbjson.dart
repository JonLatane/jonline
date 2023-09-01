//
//  Generated code. Do not modify.
//  source: permissions.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use permissionDescriptor instead')
const Permission$json = {
  '1': 'Permission',
  '2': [
    {'1': 'PERMISSION_UNKNOWN', '2': 0},
    {'1': 'VIEW_USERS', '2': 1},
    {'1': 'PUBLISH_USERS_LOCALLY', '2': 2},
    {'1': 'PUBLISH_USERS_GLOBALLY', '2': 3},
    {'1': 'MODERATE_USERS', '2': 4},
    {'1': 'FOLLOW_USERS', '2': 5},
    {'1': 'GRANT_BASIC_PERMISSIONS', '2': 6},
    {'1': 'VIEW_GROUPS', '2': 10},
    {'1': 'CREATE_GROUPS', '2': 11},
    {'1': 'PUBLISH_GROUPS_LOCALLY', '2': 12},
    {'1': 'PUBLISH_GROUPS_GLOBALLY', '2': 13},
    {'1': 'MODERATE_GROUPS', '2': 14},
    {'1': 'JOIN_GROUPS', '2': 15},
    {'1': 'VIEW_POSTS', '2': 20},
    {'1': 'CREATE_POSTS', '2': 21},
    {'1': 'PUBLISH_POSTS_LOCALLY', '2': 22},
    {'1': 'PUBLISH_POSTS_GLOBALLY', '2': 23},
    {'1': 'MODERATE_POSTS', '2': 24},
    {'1': 'REPLY_TO_POSTS', '2': 25},
    {'1': 'VIEW_EVENTS', '2': 30},
    {'1': 'CREATE_EVENTS', '2': 31},
    {'1': 'PUBLISH_EVENTS_LOCALLY', '2': 32},
    {'1': 'PUBLISH_EVENTS_GLOBALLY', '2': 33},
    {'1': 'MODERATE_EVENTS', '2': 34},
    {'1': 'VIEW_MEDIA', '2': 40},
    {'1': 'CREATE_MEDIA', '2': 41},
    {'1': 'PUBLISH_MEDIA_LOCALLY', '2': 42},
    {'1': 'PUBLISH_MEDIA_GLOBALLY', '2': 43},
    {'1': 'MODERATE_MEDIA', '2': 44},
    {'1': 'RUN_BOTS', '2': 9999},
    {'1': 'ADMIN', '2': 10000},
    {'1': 'VIEW_PRIVATE_CONTACT_METHODS', '2': 10001},
  ],
};

/// Descriptor for `Permission`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List permissionDescriptor = $convert.base64Decode(
    'CgpQZXJtaXNzaW9uEhYKElBFUk1JU1NJT05fVU5LTk9XThAAEg4KClZJRVdfVVNFUlMQARIZCh'
    'VQVUJMSVNIX1VTRVJTX0xPQ0FMTFkQAhIaChZQVUJMSVNIX1VTRVJTX0dMT0JBTExZEAMSEgoO'
    'TU9ERVJBVEVfVVNFUlMQBBIQCgxGT0xMT1dfVVNFUlMQBRIbChdHUkFOVF9CQVNJQ19QRVJNSV'
    'NTSU9OUxAGEg8KC1ZJRVdfR1JPVVBTEAoSEQoNQ1JFQVRFX0dST1VQUxALEhoKFlBVQkxJU0hf'
    'R1JPVVBTX0xPQ0FMTFkQDBIbChdQVUJMSVNIX0dST1VQU19HTE9CQUxMWRANEhMKD01PREVSQV'
    'RFX0dST1VQUxAOEg8KC0pPSU5fR1JPVVBTEA8SDgoKVklFV19QT1NUUxAUEhAKDENSRUFURV9Q'
    'T1NUUxAVEhkKFVBVQkxJU0hfUE9TVFNfTE9DQUxMWRAWEhoKFlBVQkxJU0hfUE9TVFNfR0xPQk'
    'FMTFkQFxISCg5NT0RFUkFURV9QT1NUUxAYEhIKDlJFUExZX1RPX1BPU1RTEBkSDwoLVklFV19F'
    'VkVOVFMQHhIRCg1DUkVBVEVfRVZFTlRTEB8SGgoWUFVCTElTSF9FVkVOVFNfTE9DQUxMWRAgEh'
    'sKF1BVQkxJU0hfRVZFTlRTX0dMT0JBTExZECESEwoPTU9ERVJBVEVfRVZFTlRTECISDgoKVklF'
    'V19NRURJQRAoEhAKDENSRUFURV9NRURJQRApEhkKFVBVQkxJU0hfTUVESUFfTE9DQUxMWRAqEh'
    'oKFlBVQkxJU0hfTUVESUFfR0xPQkFMTFkQKxISCg5NT0RFUkFURV9NRURJQRAsEg0KCFJVTl9C'
    'T1RTEI9OEgoKBUFETUlOEJBOEiEKHFZJRVdfUFJJVkFURV9DT05UQUNUX01FVEhPRFMQkU4=');

