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
    {'1': 'visibility', '3': 6, '4': 1, '5': 14, '6': '.rellm.Visibility', '10': 'visibility'},
    {'1': 'moderation', '3': 7, '4': 1, '5': 14, '6': '.rellm.Moderation', '10': 'moderation'},
    {'1': 'generated', '3': 8, '4': 1, '5': 8, '10': 'generated'},
    {'1': 'processed', '3': 9, '4': 1, '5': 8, '10': 'processed'},
    {'1': 'aspect_ratio', '3': 10, '4': 1, '5': 2, '9': 3, '10': 'aspectRatio', '17': true},
    {'1': 'created_at', '3': 15, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 16, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'updatedAt'},
    {'1': 'metadata', '3': 17, '4': 1, '5': 11, '6': '.rellm.MediaMetadata', '10': 'metadata'},
    {'1': 'url', '3': 18, '4': 1, '5': 9, '9': 4, '10': 'url', '17': true},
  ],
  '8': [
    {'1': '_user_id'},
    {'1': '_name'},
    {'1': '_description'},
    {'1': '_aspect_ratio'},
    {'1': '_url'},
  ],
};

/// Descriptor for `Media`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaDescriptor = $convert.base64Decode(
    'CgVNZWRpYRIOCgJpZBgBIAEoCVICaWQSHAoHdXNlcl9pZBgCIAEoCUgAUgZ1c2VySWSIAQESIQ'
    'oMY29udGVudF90eXBlGAMgASgJUgtjb250ZW50VHlwZRIXCgRuYW1lGAQgASgJSAFSBG5hbWWI'
    'AQESJQoLZGVzY3JpcHRpb24YBSABKAlIAlILZGVzY3JpcHRpb26IAQESMQoKdmlzaWJpbGl0eR'
    'gGIAEoDjIRLnJlbGxtLlZpc2liaWxpdHlSCnZpc2liaWxpdHkSMQoKbW9kZXJhdGlvbhgHIAEo'
    'DjIRLnJlbGxtLk1vZGVyYXRpb25SCm1vZGVyYXRpb24SHAoJZ2VuZXJhdGVkGAggASgIUglnZW'
    '5lcmF0ZWQSHAoJcHJvY2Vzc2VkGAkgASgIUglwcm9jZXNzZWQSJgoMYXNwZWN0X3JhdGlvGAog'
    'ASgCSANSC2FzcGVjdFJhdGlviAEBEjkKCmNyZWF0ZWRfYXQYDyABKAsyGi5nb29nbGUucHJvdG'
    '9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQSOQoKdXBkYXRlZF9hdBgQIAEoCzIaLmdvb2dsZS5w'
    'cm90b2J1Zi5UaW1lc3RhbXBSCXVwZGF0ZWRBdBIwCghtZXRhZGF0YRgRIAEoCzIULnJlbGxtLk'
    '1lZGlhTWV0YWRhdGFSCG1ldGFkYXRhEhUKA3VybBgSIAEoCUgEUgN1cmyIAQFCCgoIX3VzZXJf'
    'aWRCBwoFX25hbWVCDgoMX2Rlc2NyaXB0aW9uQg8KDV9hc3BlY3RfcmF0aW9CBgoEX3VybA==');

@$core.Deprecated('Use mediaMetadataDescriptor instead')
const MediaMetadata$json = {
  '1': 'MediaMetadata',
  '2': [
    {'1': 'video_preview_time_ms', '3': 1, '4': 1, '5': 13, '9': 0, '10': 'videoPreviewTimeMs', '17': true},
  ],
  '8': [
    {'1': '_video_preview_time_ms'},
  ],
};

/// Descriptor for `MediaMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaMetadataDescriptor = $convert.base64Decode(
    'Cg1NZWRpYU1ldGFkYXRhEjYKFXZpZGVvX3ByZXZpZXdfdGltZV9tcxgBIAEoDUgAUhJ2aWRlb1'
    'ByZXZpZXdUaW1lTXOIAQFCGAoWX3ZpZGVvX3ByZXZpZXdfdGltZV9tcw==');

@$core.Deprecated('Use mediaReferenceDescriptor instead')
const MediaReference$json = {
  '1': 'MediaReference',
  '2': [
    {'1': 'content_type', '3': 1, '4': 1, '5': 9, '10': 'contentType'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {'1': 'generated', '3': 4, '4': 1, '5': 8, '10': 'generated'},
    {'1': 'metadata', '3': 5, '4': 1, '5': 11, '6': '.rellm.MediaMetadata', '10': 'metadata'},
    {'1': 'aspect_ratio', '3': 10, '4': 1, '5': 2, '9': 1, '10': 'aspectRatio', '17': true},
    {'1': 'url', '3': 11, '4': 1, '5': 9, '9': 2, '10': 'url', '17': true},
  ],
  '8': [
    {'1': '_name'},
    {'1': '_aspect_ratio'},
    {'1': '_url'},
  ],
};

/// Descriptor for `MediaReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaReferenceDescriptor = $convert.base64Decode(
    'Cg5NZWRpYVJlZmVyZW5jZRIhCgxjb250ZW50X3R5cGUYASABKAlSC2NvbnRlbnRUeXBlEg4KAm'
    'lkGAIgASgJUgJpZBIXCgRuYW1lGAMgASgJSABSBG5hbWWIAQESHAoJZ2VuZXJhdGVkGAQgASgI'
    'UglnZW5lcmF0ZWQSMAoIbWV0YWRhdGEYBSABKAsyFC5yZWxsbS5NZWRpYU1ldGFkYXRhUghtZX'
    'RhZGF0YRImCgxhc3BlY3RfcmF0aW8YCiABKAJIAVILYXNwZWN0UmF0aW+IAQESFQoDdXJsGAsg'
    'ASgJSAJSA3VybIgBAUIHCgVfbmFtZUIPCg1fYXNwZWN0X3JhdGlvQgYKBF91cmw=');

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
    {'1': 'media', '3': 1, '4': 3, '5': 11, '6': '.rellm.Media', '10': 'media'},
    {'1': 'has_next_page', '3': 2, '4': 1, '5': 8, '10': 'hasNextPage'},
  ],
};

/// Descriptor for `GetMediaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMediaResponseDescriptor = $convert.base64Decode(
    'ChBHZXRNZWRpYVJlc3BvbnNlEiIKBW1lZGlhGAEgAygLMgwucmVsbG0uTWVkaWFSBW1lZGlhEi'
    'IKDWhhc19uZXh0X3BhZ2UYAiABKAhSC2hhc05leHRQYWdl');

