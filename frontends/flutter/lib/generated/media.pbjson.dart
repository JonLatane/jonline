//
//  Generated code. Do not modify.
//  source: media.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use mediaDescriptor instead')
const Media$json = {
  '1': 'Media',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'userId', '17': true},
    {'1': 'content_type', '3': 3, '4': 1, '5': 9, '10': 'contentType'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'name', '17': true},
    {'1': 'description', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'description', '17': true},
    {'1': 'visibility', '3': 6, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'visibility'},
    {'1': 'moderation', '3': 7, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'moderation'},
    {'1': 'generated', '3': 8, '4': 1, '5': 8, '10': 'generated'},
    {'1': 'processed', '3': 9, '4': 1, '5': 8, '10': 'processed'},
    {'1': 'created_at', '3': 15, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 16, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'updatedAt'},
  ],
  '8': [
    {'1': '_user_id'},
    {'1': '_name'},
    {'1': '_description'},
  ],
};

/// Descriptor for `Media`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaDescriptor = $convert.base64Decode(
    'CgVNZWRpYRIOCgJpZBgBIAEoCVICaWQSHAoHdXNlcl9pZBgCIAEoCUgAUgZ1c2VySWSIAQESIQ'
    'oMY29udGVudF90eXBlGAMgASgJUgtjb250ZW50VHlwZRIXCgRuYW1lGAQgASgJSAFSBG5hbWWI'
    'AQESJQoLZGVzY3JpcHRpb24YBSABKAlIAlILZGVzY3JpcHRpb26IAQESMwoKdmlzaWJpbGl0eR'
    'gGIAEoDjITLmpvbmxpbmUuVmlzaWJpbGl0eVIKdmlzaWJpbGl0eRIzCgptb2RlcmF0aW9uGAcg'
    'ASgOMhMuam9ubGluZS5Nb2RlcmF0aW9uUgptb2RlcmF0aW9uEhwKCWdlbmVyYXRlZBgIIAEoCF'
    'IJZ2VuZXJhdGVkEhwKCXByb2Nlc3NlZBgJIAEoCFIJcHJvY2Vzc2VkEjkKCmNyZWF0ZWRfYXQY'
    'DyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQSOQoKdXBkYXRlZF'
    '9hdBgQIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXVwZGF0ZWRBdEIKCghfdXNl'
    'cl9pZEIHCgVfbmFtZUIOCgxfZGVzY3JpcHRpb24=');

@$core.Deprecated('Use mediaReferenceDescriptor instead')
const MediaReference$json = {
  '1': 'MediaReference',
  '2': [
    {'1': 'content_type', '3': 1, '4': 1, '5': 9, '10': 'contentType'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {'1': 'generated', '3': 4, '4': 1, '5': 8, '10': 'generated'},
  ],
  '8': [
    {'1': '_name'},
  ],
};

/// Descriptor for `MediaReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaReferenceDescriptor = $convert.base64Decode(
    'Cg5NZWRpYVJlZmVyZW5jZRIhCgxjb250ZW50X3R5cGUYASABKAlSC2NvbnRlbnRUeXBlEg4KAm'
    'lkGAIgASgJUgJpZBIXCgRuYW1lGAMgASgJSABSBG5hbWWIAQESHAoJZ2VuZXJhdGVkGAQgASgI'
    'UglnZW5lcmF0ZWRCBwoFX25hbWU=');

@$core.Deprecated('Use getMediaRequestDescriptor instead')
const GetMediaRequest$json = {
  '1': 'GetMediaRequest',
  '2': [
    {'1': 'media_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'mediaId', '17': true},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'userId', '17': true},
    {'1': 'page', '3': 11, '4': 1, '5': 13, '10': 'page'},
  ],
  '8': [
    {'1': '_media_id'},
    {'1': '_user_id'},
  ],
};

/// Descriptor for `GetMediaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMediaRequestDescriptor = $convert.base64Decode(
    'Cg9HZXRNZWRpYVJlcXVlc3QSHgoIbWVkaWFfaWQYASABKAlIAFIHbWVkaWFJZIgBARIcCgd1c2'
    'VyX2lkGAIgASgJSAFSBnVzZXJJZIgBARISCgRwYWdlGAsgASgNUgRwYWdlQgsKCV9tZWRpYV9p'
    'ZEIKCghfdXNlcl9pZA==');

@$core.Deprecated('Use getMediaResponseDescriptor instead')
const GetMediaResponse$json = {
  '1': 'GetMediaResponse',
  '2': [
    {'1': 'media', '3': 1, '4': 3, '5': 11, '6': '.jonline.Media', '10': 'media'},
    {'1': 'has_next_page', '3': 2, '4': 1, '5': 8, '10': 'hasNextPage'},
  ],
};

/// Descriptor for `GetMediaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMediaResponseDescriptor = $convert.base64Decode(
    'ChBHZXRNZWRpYVJlc3BvbnNlEiQKBW1lZGlhGAEgAygLMg4uam9ubGluZS5NZWRpYVIFbWVkaW'
    'ESIgoNaGFzX25leHRfcGFnZRgCIAEoCFILaGFzTmV4dFBhZ2U=');

