///
//  Generated code. Do not modify.
//  source: media.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use mediaDescriptor instead')
const Media$json = const {
  '1': 'Media',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'content_type', '3': 3, '4': 1, '5': 9, '10': 'contentType'},
    const {'1': 'user_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'userId', '17': true},
    const {'1': 'name', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'name', '17': true},
    const {'1': 'description', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'description', '17': true},
    const {'1': 'visibility', '3': 6, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'visibility'},
    const {'1': 'moderation', '3': 7, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'moderation'},
    const {'1': 'generated', '3': 8, '4': 1, '5': 8, '10': 'generated'},
    const {'1': 'processed', '3': 9, '4': 1, '5': 8, '10': 'processed'},
    const {'1': 'created_at', '3': 15, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    const {'1': 'updated_at', '3': 16, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'updatedAt'},
  ],
  '8': const [
    const {'1': '_user_id'},
    const {'1': '_name'},
    const {'1': '_description'},
  ],
};

/// Descriptor for `Media`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaDescriptor = $convert.base64Decode('CgVNZWRpYRIOCgJpZBgBIAEoCVICaWQSIQoMY29udGVudF90eXBlGAMgASgJUgtjb250ZW50VHlwZRIcCgd1c2VyX2lkGAIgASgJSABSBnVzZXJJZIgBARIXCgRuYW1lGAQgASgJSAFSBG5hbWWIAQESJQoLZGVzY3JpcHRpb24YBSABKAlIAlILZGVzY3JpcHRpb26IAQESMwoKdmlzaWJpbGl0eRgGIAEoDjITLmpvbmxpbmUuVmlzaWJpbGl0eVIKdmlzaWJpbGl0eRIzCgptb2RlcmF0aW9uGAcgASgOMhMuam9ubGluZS5Nb2RlcmF0aW9uUgptb2RlcmF0aW9uEhwKCWdlbmVyYXRlZBgIIAEoCFIJZ2VuZXJhdGVkEhwKCXByb2Nlc3NlZBgJIAEoCFIJcHJvY2Vzc2VkEjkKCmNyZWF0ZWRfYXQYDyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQSOQoKdXBkYXRlZF9hdBgQIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXVwZGF0ZWRBdEIKCghfdXNlcl9pZEIHCgVfbmFtZUIOCgxfZGVzY3JpcHRpb24=');
@$core.Deprecated('Use getMediaRequestDescriptor instead')
const GetMediaRequest$json = const {
  '1': 'GetMediaRequest',
  '2': const [
    const {'1': 'media_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'mediaId', '17': true},
    const {'1': 'user_id', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'userId', '17': true},
    const {'1': 'page', '3': 11, '4': 1, '5': 13, '10': 'page'},
  ],
  '8': const [
    const {'1': '_media_id'},
    const {'1': '_user_id'},
  ],
};

/// Descriptor for `GetMediaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMediaRequestDescriptor = $convert.base64Decode('Cg9HZXRNZWRpYVJlcXVlc3QSHgoIbWVkaWFfaWQYASABKAlIAFIHbWVkaWFJZIgBARIcCgd1c2VyX2lkGAIgASgJSAFSBnVzZXJJZIgBARISCgRwYWdlGAsgASgNUgRwYWdlQgsKCV9tZWRpYV9pZEIKCghfdXNlcl9pZA==');
@$core.Deprecated('Use getMediaResponseDescriptor instead')
const GetMediaResponse$json = const {
  '1': 'GetMediaResponse',
  '2': const [
    const {'1': 'media', '3': 1, '4': 3, '5': 11, '6': '.jonline.Media', '10': 'media'},
    const {'1': 'has_next_page', '3': 2, '4': 1, '5': 8, '10': 'hasNextPage'},
  ],
};

/// Descriptor for `GetMediaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMediaResponseDescriptor = $convert.base64Decode('ChBHZXRNZWRpYVJlc3BvbnNlEiQKBW1lZGlhGAEgAygLMg4uam9ubGluZS5NZWRpYVIFbWVkaWESIgoNaGFzX25leHRfcGFnZRgCIAEoCFILaGFzTmV4dFBhZ2U=');
