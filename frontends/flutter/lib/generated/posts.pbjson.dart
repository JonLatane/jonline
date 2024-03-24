//
//  Generated code. Do not modify.
//  source: posts.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use postListingTypeDescriptor instead')
const PostListingType$json = {
  '1': 'PostListingType',
  '2': [
    {'1': 'ALL_ACCESSIBLE_POSTS', '2': 0},
    {'1': 'FOLLOWING_POSTS', '2': 1},
    {'1': 'MY_GROUPS_POSTS', '2': 2},
    {'1': 'DIRECT_POSTS', '2': 3},
    {'1': 'POSTS_PENDING_MODERATION', '2': 4},
    {'1': 'GROUP_POSTS', '2': 10},
    {'1': 'GROUP_POSTS_PENDING_MODERATION', '2': 11},
  ],
};

/// Descriptor for `PostListingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List postListingTypeDescriptor = $convert.base64Decode(
    'Cg9Qb3N0TGlzdGluZ1R5cGUSGAoUQUxMX0FDQ0VTU0lCTEVfUE9TVFMQABITCg9GT0xMT1dJTk'
    'dfUE9TVFMQARITCg9NWV9HUk9VUFNfUE9TVFMQAhIQCgxESVJFQ1RfUE9TVFMQAxIcChhQT1NU'
    'U19QRU5ESU5HX01PREVSQVRJT04QBBIPCgtHUk9VUF9QT1NUUxAKEiIKHkdST1VQX1BPU1RTX1'
    'BFTkRJTkdfTU9ERVJBVElPThAL');

@$core.Deprecated('Use postContextDescriptor instead')
const PostContext$json = {
  '1': 'PostContext',
  '2': [
    {'1': 'POST', '2': 0},
    {'1': 'REPLY', '2': 1},
    {'1': 'EVENT', '2': 2},
    {'1': 'EVENT_INSTANCE', '2': 3},
    {'1': 'FEDERATED_POST', '2': 10},
    {'1': 'FEDERATED_EVENT_INSTANCE', '2': 13},
  ],
};

/// Descriptor for `PostContext`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List postContextDescriptor = $convert.base64Decode(
    'CgtQb3N0Q29udGV4dBIICgRQT1NUEAASCQoFUkVQTFkQARIJCgVFVkVOVBACEhIKDkVWRU5UX0'
    'lOU1RBTkNFEAMSEgoORkVERVJBVEVEX1BPU1QQChIcChhGRURFUkFURURfRVZFTlRfSU5TVEFO'
    'Q0UQDQ==');

@$core.Deprecated('Use getPostsRequestDescriptor instead')
const GetPostsRequest$json = {
  '1': 'GetPostsRequest',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'postId', '17': true},
    {'1': 'author_user_id', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'authorUserId', '17': true},
    {'1': 'group_id', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'groupId', '17': true},
    {'1': 'reply_depth', '3': 4, '4': 1, '5': 13, '9': 3, '10': 'replyDepth', '17': true},
    {'1': 'context', '3': 5, '4': 1, '5': 14, '6': '.jonline.PostContext', '9': 4, '10': 'context', '17': true},
    {'1': 'post_ids', '3': 9, '4': 1, '5': 9, '9': 5, '10': 'postIds', '17': true},
    {'1': 'listing_type', '3': 10, '4': 1, '5': 14, '6': '.jonline.PostListingType', '10': 'listingType'},
    {'1': 'page', '3': 15, '4': 1, '5': 13, '10': 'page'},
  ],
  '8': [
    {'1': '_post_id'},
    {'1': '_author_user_id'},
    {'1': '_group_id'},
    {'1': '_reply_depth'},
    {'1': '_context'},
    {'1': '_post_ids'},
  ],
};

/// Descriptor for `GetPostsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPostsRequestDescriptor = $convert.base64Decode(
    'Cg9HZXRQb3N0c1JlcXVlc3QSHAoHcG9zdF9pZBgBIAEoCUgAUgZwb3N0SWSIAQESKQoOYXV0aG'
    '9yX3VzZXJfaWQYAiABKAlIAVIMYXV0aG9yVXNlcklkiAEBEh4KCGdyb3VwX2lkGAMgASgJSAJS'
    'B2dyb3VwSWSIAQESJAoLcmVwbHlfZGVwdGgYBCABKA1IA1IKcmVwbHlEZXB0aIgBARIzCgdjb2'
    '50ZXh0GAUgASgOMhQuam9ubGluZS5Qb3N0Q29udGV4dEgEUgdjb250ZXh0iAEBEh4KCHBvc3Rf'
    'aWRzGAkgASgJSAVSB3Bvc3RJZHOIAQESOwoMbGlzdGluZ190eXBlGAogASgOMhguam9ubGluZS'
    '5Qb3N0TGlzdGluZ1R5cGVSC2xpc3RpbmdUeXBlEhIKBHBhZ2UYDyABKA1SBHBhZ2VCCgoIX3Bv'
    'c3RfaWRCEQoPX2F1dGhvcl91c2VyX2lkQgsKCV9ncm91cF9pZEIOCgxfcmVwbHlfZGVwdGhCCg'
    'oIX2NvbnRleHRCCwoJX3Bvc3RfaWRz');

@$core.Deprecated('Use getPostsResponseDescriptor instead')
const GetPostsResponse$json = {
  '1': 'GetPostsResponse',
  '2': [
    {'1': 'posts', '3': 1, '4': 3, '5': 11, '6': '.jonline.Post', '10': 'posts'},
  ],
};

/// Descriptor for `GetPostsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPostsResponseDescriptor = $convert.base64Decode(
    'ChBHZXRQb3N0c1Jlc3BvbnNlEiMKBXBvc3RzGAEgAygLMg0uam9ubGluZS5Qb3N0UgVwb3N0cw'
    '==');

@$core.Deprecated('Use postDescriptor instead')
const Post$json = {
  '1': 'Post',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'author', '3': 2, '4': 1, '5': 11, '6': '.jonline.Author', '9': 0, '10': 'author', '17': true},
    {'1': 'reply_to_post_id', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'replyToPostId', '17': true},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'title', '17': true},
    {'1': 'link', '3': 5, '4': 1, '5': 9, '9': 3, '10': 'link', '17': true},
    {'1': 'content', '3': 6, '4': 1, '5': 9, '9': 4, '10': 'content', '17': true},
    {'1': 'response_count', '3': 7, '4': 1, '5': 5, '10': 'responseCount'},
    {'1': 'reply_count', '3': 8, '4': 1, '5': 5, '10': 'replyCount'},
    {'1': 'group_count', '3': 9, '4': 1, '5': 5, '10': 'groupCount'},
    {'1': 'media', '3': 10, '4': 3, '5': 11, '6': '.jonline.MediaReference', '10': 'media'},
    {'1': 'media_generated', '3': 11, '4': 1, '5': 8, '10': 'mediaGenerated'},
    {'1': 'embed_link', '3': 12, '4': 1, '5': 8, '10': 'embedLink'},
    {'1': 'shareable', '3': 13, '4': 1, '5': 8, '10': 'shareable'},
    {'1': 'context', '3': 14, '4': 1, '5': 14, '6': '.jonline.PostContext', '10': 'context'},
    {'1': 'visibility', '3': 15, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'visibility'},
    {'1': 'moderation', '3': 16, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'moderation'},
    {'1': 'current_group_post', '3': 18, '4': 1, '5': 11, '6': '.jonline.GroupPost', '9': 5, '10': 'currentGroupPost', '17': true},
    {'1': 'replies', '3': 19, '4': 3, '5': 11, '6': '.jonline.Post', '10': 'replies'},
    {'1': 'created_at', '3': 20, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 21, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 6, '10': 'updatedAt', '17': true},
    {'1': 'published_at', '3': 22, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 7, '10': 'publishedAt', '17': true},
    {'1': 'last_activity_at', '3': 23, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'lastActivityAt'},
    {'1': 'unauthenticated_star_count', '3': 24, '4': 1, '5': 3, '10': 'unauthenticatedStarCount'},
  ],
  '8': [
    {'1': '_author'},
    {'1': '_reply_to_post_id'},
    {'1': '_title'},
    {'1': '_link'},
    {'1': '_content'},
    {'1': '_current_group_post'},
    {'1': '_updated_at'},
    {'1': '_published_at'},
  ],
};

/// Descriptor for `Post`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List postDescriptor = $convert.base64Decode(
    'CgRQb3N0Eg4KAmlkGAEgASgJUgJpZBIsCgZhdXRob3IYAiABKAsyDy5qb25saW5lLkF1dGhvck'
    'gAUgZhdXRob3KIAQESLAoQcmVwbHlfdG9fcG9zdF9pZBgDIAEoCUgBUg1yZXBseVRvUG9zdElk'
    'iAEBEhkKBXRpdGxlGAQgASgJSAJSBXRpdGxliAEBEhcKBGxpbmsYBSABKAlIA1IEbGlua4gBAR'
    'IdCgdjb250ZW50GAYgASgJSARSB2NvbnRlbnSIAQESJQoOcmVzcG9uc2VfY291bnQYByABKAVS'
    'DXJlc3BvbnNlQ291bnQSHwoLcmVwbHlfY291bnQYCCABKAVSCnJlcGx5Q291bnQSHwoLZ3JvdX'
    'BfY291bnQYCSABKAVSCmdyb3VwQ291bnQSLQoFbWVkaWEYCiADKAsyFy5qb25saW5lLk1lZGlh'
    'UmVmZXJlbmNlUgVtZWRpYRInCg9tZWRpYV9nZW5lcmF0ZWQYCyABKAhSDm1lZGlhR2VuZXJhdG'
    'VkEh0KCmVtYmVkX2xpbmsYDCABKAhSCWVtYmVkTGluaxIcCglzaGFyZWFibGUYDSABKAhSCXNo'
    'YXJlYWJsZRIuCgdjb250ZXh0GA4gASgOMhQuam9ubGluZS5Qb3N0Q29udGV4dFIHY29udGV4dB'
    'IzCgp2aXNpYmlsaXR5GA8gASgOMhMuam9ubGluZS5WaXNpYmlsaXR5Ugp2aXNpYmlsaXR5EjMK'
    'Cm1vZGVyYXRpb24YECABKA4yEy5qb25saW5lLk1vZGVyYXRpb25SCm1vZGVyYXRpb24SRQoSY3'
    'VycmVudF9ncm91cF9wb3N0GBIgASgLMhIuam9ubGluZS5Hcm91cFBvc3RIBVIQY3VycmVudEdy'
    'b3VwUG9zdIgBARInCgdyZXBsaWVzGBMgAygLMg0uam9ubGluZS5Qb3N0UgdyZXBsaWVzEjkKCm'
    'NyZWF0ZWRfYXQYFCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQS'
    'PgoKdXBkYXRlZF9hdBgVIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIBlIJdXBkYX'
    'RlZEF0iAEBEkIKDHB1Ymxpc2hlZF9hdBgWIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh'
    'bXBIB1ILcHVibGlzaGVkQXSIAQESRAoQbGFzdF9hY3Rpdml0eV9hdBgXIAEoCzIaLmdvb2dsZS'
    '5wcm90b2J1Zi5UaW1lc3RhbXBSDmxhc3RBY3Rpdml0eUF0EjwKGnVuYXV0aGVudGljYXRlZF9z'
    'dGFyX2NvdW50GBggASgDUhh1bmF1dGhlbnRpY2F0ZWRTdGFyQ291bnRCCQoHX2F1dGhvckITCh'
    'FfcmVwbHlfdG9fcG9zdF9pZEIICgZfdGl0bGVCBwoFX2xpbmtCCgoIX2NvbnRlbnRCFQoTX2N1'
    'cnJlbnRfZ3JvdXBfcG9zdEINCgtfdXBkYXRlZF9hdEIPCg1fcHVibGlzaGVkX2F0');

@$core.Deprecated('Use groupPostDescriptor instead')
const GroupPost$json = {
  '1': 'GroupPost',
  '2': [
    {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    {'1': 'post_id', '3': 2, '4': 1, '5': 9, '10': 'postId'},
    {'1': 'user_id', '3': 3, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'group_moderation', '3': 4, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'groupModeration'},
    {'1': 'created_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
  ],
};

/// Descriptor for `GroupPost`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupPostDescriptor = $convert.base64Decode(
    'CglHcm91cFBvc3QSGQoIZ3JvdXBfaWQYASABKAlSB2dyb3VwSWQSFwoHcG9zdF9pZBgCIAEoCV'
    'IGcG9zdElkEhcKB3VzZXJfaWQYAyABKAlSBnVzZXJJZBI+ChBncm91cF9tb2RlcmF0aW9uGAQg'
    'ASgOMhMuam9ubGluZS5Nb2RlcmF0aW9uUg9ncm91cE1vZGVyYXRpb24SOQoKY3JlYXRlZF9hdB'
    'gFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdA==');

@$core.Deprecated('Use userPostDescriptor instead')
const UserPost$json = {
  '1': 'UserPost',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'post_id', '3': 2, '4': 1, '5': 9, '10': 'postId'},
    {'1': 'created_at', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
  ],
};

/// Descriptor for `UserPost`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPostDescriptor = $convert.base64Decode(
    'CghVc2VyUG9zdBIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSFwoHcG9zdF9pZBgCIAEoCVIGcG'
    '9zdElkEjkKCmNyZWF0ZWRfYXQYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglj'
    'cmVhdGVkQXQ=');

@$core.Deprecated('Use getGroupPostsRequestDescriptor instead')
const GetGroupPostsRequest$json = {
  '1': 'GetGroupPostsRequest',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
    {'1': 'group_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'groupId', '17': true},
  ],
  '8': [
    {'1': '_group_id'},
  ],
};

/// Descriptor for `GetGroupPostsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGroupPostsRequestDescriptor = $convert.base64Decode(
    'ChRHZXRHcm91cFBvc3RzUmVxdWVzdBIXCgdwb3N0X2lkGAEgASgJUgZwb3N0SWQSHgoIZ3JvdX'
    'BfaWQYAiABKAlIAFIHZ3JvdXBJZIgBAUILCglfZ3JvdXBfaWQ=');

@$core.Deprecated('Use getGroupPostsResponseDescriptor instead')
const GetGroupPostsResponse$json = {
  '1': 'GetGroupPostsResponse',
  '2': [
    {'1': 'group_posts', '3': 1, '4': 3, '5': 11, '6': '.jonline.GroupPost', '10': 'groupPosts'},
  ],
};

/// Descriptor for `GetGroupPostsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGroupPostsResponseDescriptor = $convert.base64Decode(
    'ChVHZXRHcm91cFBvc3RzUmVzcG9uc2USMwoLZ3JvdXBfcG9zdHMYASADKAsyEi5qb25saW5lLk'
    'dyb3VwUG9zdFIKZ3JvdXBQb3N0cw==');

