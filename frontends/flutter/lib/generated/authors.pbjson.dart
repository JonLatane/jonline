//
//  Generated code. Do not modify.
//  source: authors.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use authorDescriptor instead')
const Author$json = {
  '1': 'Author',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'username', '17': true},
    {'1': 'avatar', '3': 3, '4': 1, '5': 11, '6': '.jonline.MediaReference', '9': 1, '10': 'avatar', '17': true},
    {'1': 'real_name', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'realName', '17': true},
    {'1': 'permissions', '3': 5, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'permissions'},
  ],
  '8': [
    {'1': '_username'},
    {'1': '_avatar'},
    {'1': '_real_name'},
  ],
};

/// Descriptor for `Author`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authorDescriptor = $convert.base64Decode(
    'CgZBdXRob3ISFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEh8KCHVzZXJuYW1lGAIgASgJSABSCH'
    'VzZXJuYW1liAEBEjQKBmF2YXRhchgDIAEoCzIXLmpvbmxpbmUuTWVkaWFSZWZlcmVuY2VIAVIG'
    'YXZhdGFyiAEBEiAKCXJlYWxfbmFtZRgEIAEoCUgCUghyZWFsTmFtZYgBARI1CgtwZXJtaXNzaW'
    '9ucxgFIAMoDjITLmpvbmxpbmUuUGVybWlzc2lvblILcGVybWlzc2lvbnNCCwoJX3VzZXJuYW1l'
    'QgkKB19hdmF0YXJCDAoKX3JlYWxfbmFtZQ==');

