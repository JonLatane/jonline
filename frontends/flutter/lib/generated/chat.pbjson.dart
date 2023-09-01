//
//  Generated code. Do not modify.
//  source: chat.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use conversationDescriptor instead')
const Conversation$json = {
  '1': 'Conversation',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {'1': 'user_ids', '3': 3, '4': 3, '5': 9, '10': 'userIds'},
  ],
  '8': [
    {'1': '_name'},
  ],
};

/// Descriptor for `Conversation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationDescriptor = $convert.base64Decode(
    'CgxDb252ZXJzYXRpb24SDgoCaWQYASABKAlSAmlkEhcKBG5hbWUYAiABKAlIAFIEbmFtZYgBAR'
    'IZCgh1c2VyX2lkcxgDIAMoCVIHdXNlcklkc0IHCgVfbmFtZQ==');

@$core.Deprecated('Use conversationPostDescriptor instead')
const ConversationPost$json = {
  '1': 'ConversationPost',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'post_id', '3': 2, '4': 1, '5': 9, '10': 'postId'},
  ],
};

/// Descriptor for `ConversationPost`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationPostDescriptor = $convert.base64Decode(
    'ChBDb252ZXJzYXRpb25Qb3N0EicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udmVyc2F0aW'
    '9uSWQSFwoHcG9zdF9pZBgCIAEoCVIGcG9zdElk');

@$core.Deprecated('Use groupConversationDescriptor instead')
const GroupConversation$json = {
  '1': 'GroupConversation',
  '2': [
    {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
  ],
};

/// Descriptor for `GroupConversation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupConversationDescriptor = $convert.base64Decode(
    'ChFHcm91cENvbnZlcnNhdGlvbhIZCghncm91cF9pZBgBIAEoCVIHZ3JvdXBJZA==');

@$core.Deprecated('Use groupConversationPostDescriptor instead')
const GroupConversationPost$json = {
  '1': 'GroupConversationPost',
  '2': [
    {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    {'1': 'post_id', '3': 2, '4': 1, '5': 9, '10': 'postId'},
  ],
};

/// Descriptor for `GroupConversationPost`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupConversationPostDescriptor = $convert.base64Decode(
    'ChVHcm91cENvbnZlcnNhdGlvblBvc3QSGQoIZ3JvdXBfaWQYASABKAlSB2dyb3VwSWQSFwoHcG'
    '9zdF9pZBgCIAEoCVIGcG9zdElk');

@$core.Deprecated('Use createConversationPostRequestDescriptor instead')
const CreateConversationPostRequest$json = {
  '1': 'CreateConversationPostRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'post', '3': 2, '4': 1, '5': 11, '6': '.jonline.Post', '10': 'post'},
  ],
};

/// Descriptor for `CreateConversationPostRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createConversationPostRequestDescriptor = $convert.base64Decode(
    'Ch1DcmVhdGVDb252ZXJzYXRpb25Qb3N0UmVxdWVzdBInCg9jb252ZXJzYXRpb25faWQYASABKA'
    'lSDmNvbnZlcnNhdGlvbklkEiEKBHBvc3QYAiABKAsyDS5qb25saW5lLlBvc3RSBHBvc3Q=');

@$core.Deprecated('Use createGroupConversationPostRequestDescriptor instead')
const CreateGroupConversationPostRequest$json = {
  '1': 'CreateGroupConversationPostRequest',
  '2': [
    {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    {'1': 'post', '3': 2, '4': 1, '5': 11, '6': '.jonline.Post', '10': 'post'},
  ],
};

/// Descriptor for `CreateGroupConversationPostRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createGroupConversationPostRequestDescriptor = $convert.base64Decode(
    'CiJDcmVhdGVHcm91cENvbnZlcnNhdGlvblBvc3RSZXF1ZXN0EhkKCGdyb3VwX2lkGAEgASgJUg'
    'dncm91cElkEiEKBHBvc3QYAiABKAsyDS5qb25saW5lLlBvc3RSBHBvc3Q=');

@$core.Deprecated('Use getConversationsRequestDescriptor instead')
const GetConversationsRequest$json = {
  '1': 'GetConversationsRequest',
  '2': [
    {'1': 'page', '3': 10, '4': 1, '5': 13, '10': 'page'},
  ],
};

/// Descriptor for `GetConversationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConversationsRequestDescriptor = $convert.base64Decode(
    'ChdHZXRDb252ZXJzYXRpb25zUmVxdWVzdBISCgRwYWdlGAogASgNUgRwYWdl');

@$core.Deprecated('Use getConversationsResponseDescriptor instead')
const GetConversationsResponse$json = {
  '1': 'GetConversationsResponse',
  '2': [
    {'1': 'conversations', '3': 1, '4': 3, '5': 11, '6': '.jonline.Conversation', '10': 'conversations'},
  ],
};

/// Descriptor for `GetConversationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConversationsResponseDescriptor = $convert.base64Decode(
    'ChhHZXRDb252ZXJzYXRpb25zUmVzcG9uc2USOwoNY29udmVyc2F0aW9ucxgBIAMoCzIVLmpvbm'
    'xpbmUuQ29udmVyc2F0aW9uUg1jb252ZXJzYXRpb25z');

@$core.Deprecated('Use getConversationRequestDescriptor instead')
const GetConversationRequest$json = {
  '1': 'GetConversationRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'conversationId'},
    {'1': 'group_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'groupId'},
    {'1': 'page', '3': 10, '4': 1, '5': 13, '10': 'page'},
  ],
  '8': [
    {'1': 'requested_id'},
  ],
};

/// Descriptor for `GetConversationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConversationRequestDescriptor = $convert.base64Decode(
    'ChZHZXRDb252ZXJzYXRpb25SZXF1ZXN0EikKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCUgAUg5jb2'
    '52ZXJzYXRpb25JZBIbCghncm91cF9pZBgCIAEoCUgAUgdncm91cElkEhIKBHBhZ2UYCiABKA1S'
    'BHBhZ2VCDgoMcmVxdWVzdGVkX2lk');

@$core.Deprecated('Use getConversationResponseDescriptor instead')
const GetConversationResponse$json = {
  '1': 'GetConversationResponse',
  '2': [
    {'1': 'conversation', '3': 1, '4': 3, '5': 11, '6': '.jonline.Post', '10': 'conversation'},
  ],
};

/// Descriptor for `GetConversationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConversationResponseDescriptor = $convert.base64Decode(
    'ChdHZXRDb252ZXJzYXRpb25SZXNwb25zZRIxCgxjb252ZXJzYXRpb24YASADKAsyDS5qb25saW'
    '5lLlBvc3RSDGNvbnZlcnNhdGlvbg==');

