///
//  Generated code. Do not modify.
//  source: posts.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use postListingTypeDescriptor instead')
const PostListingType$json = const {
  '1': 'PostListingType',
  '2': const [
    const {'1': 'PUBLIC_POSTS', '2': 0},
    const {'1': 'FOLLOWING_POSTS', '2': 1},
    const {'1': 'MY_GROUPS_POSTS', '2': 2},
    const {'1': 'DIRECT_POSTS', '2': 3},
    const {'1': 'POSTS_PENDING_MODERATION', '2': 4},
    const {'1': 'GROUP_POSTS', '2': 10},
    const {'1': 'GROUP_POSTS_PENDING_MODERATION', '2': 11},
  ],
};

/// Descriptor for `PostListingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List postListingTypeDescriptor = $convert.base64Decode('Cg9Qb3N0TGlzdGluZ1R5cGUSEAoMUFVCTElDX1BPU1RTEAASEwoPRk9MTE9XSU5HX1BPU1RTEAESEwoPTVlfR1JPVVBTX1BPU1RTEAISEAoMRElSRUNUX1BPU1RTEAMSHAoYUE9TVFNfUEVORElOR19NT0RFUkFUSU9OEAQSDwoLR1JPVVBfUE9TVFMQChIiCh5HUk9VUF9QT1NUU19QRU5ESU5HX01PREVSQVRJT04QCw==');
@$core.Deprecated('Use postContextDescriptor instead')
const PostContext$json = const {
  '1': 'PostContext',
  '2': const [
    const {'1': 'POST', '2': 0},
    const {'1': 'REPLY', '2': 1},
    const {'1': 'EVENT', '2': 2},
    const {'1': 'EVENT_INSTANCE', '2': 3},
  ],
};

/// Descriptor for `PostContext`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List postContextDescriptor = $convert.base64Decode('CgtQb3N0Q29udGV4dBIICgRQT1NUEAASCQoFUkVQTFkQARIJCgVFVkVOVBACEhIKDkVWRU5UX0lOU1RBTkNFEAM=');
@$core.Deprecated('Use getPostsRequestDescriptor instead')
const GetPostsRequest$json = const {
  '1': 'GetPostsRequest',
  '2': const [
    const {'1': 'post_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'postId', '17': true},
    const {'1': 'author_user_id', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'authorUserId', '17': true},
    const {'1': 'group_id', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'groupId', '17': true},
    const {'1': 'reply_depth', '3': 4, '4': 1, '5': 13, '9': 3, '10': 'replyDepth', '17': true},
    const {'1': 'listing_type', '3': 10, '4': 1, '5': 14, '6': '.jonline.PostListingType', '10': 'listingType'},
    const {'1': 'page', '3': 15, '4': 1, '5': 13, '10': 'page'},
  ],
  '8': const [
    const {'1': '_post_id'},
    const {'1': '_author_user_id'},
    const {'1': '_group_id'},
    const {'1': '_reply_depth'},
  ],
};

/// Descriptor for `GetPostsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPostsRequestDescriptor = $convert.base64Decode('Cg9HZXRQb3N0c1JlcXVlc3QSHAoHcG9zdF9pZBgBIAEoCUgAUgZwb3N0SWSIAQESKQoOYXV0aG9yX3VzZXJfaWQYAiABKAlIAVIMYXV0aG9yVXNlcklkiAEBEh4KCGdyb3VwX2lkGAMgASgJSAJSB2dyb3VwSWSIAQESJAoLcmVwbHlfZGVwdGgYBCABKA1IA1IKcmVwbHlEZXB0aIgBARI7CgxsaXN0aW5nX3R5cGUYCiABKA4yGC5qb25saW5lLlBvc3RMaXN0aW5nVHlwZVILbGlzdGluZ1R5cGUSEgoEcGFnZRgPIAEoDVIEcGFnZUIKCghfcG9zdF9pZEIRCg9fYXV0aG9yX3VzZXJfaWRCCwoJX2dyb3VwX2lkQg4KDF9yZXBseV9kZXB0aA==');
@$core.Deprecated('Use getPostsResponseDescriptor instead')
const GetPostsResponse$json = const {
  '1': 'GetPostsResponse',
  '2': const [
    const {'1': 'posts', '3': 1, '4': 3, '5': 11, '6': '.jonline.Post', '10': 'posts'},
  ],
};

/// Descriptor for `GetPostsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPostsResponseDescriptor = $convert.base64Decode('ChBHZXRQb3N0c1Jlc3BvbnNlEiMKBXBvc3RzGAEgAygLMg0uam9ubGluZS5Qb3N0UgVwb3N0cw==');
@$core.Deprecated('Use postDescriptor instead')
const Post$json = const {
  '1': 'Post',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'author', '3': 2, '4': 1, '5': 11, '6': '.jonline.Author', '9': 0, '10': 'author', '17': true},
    const {'1': 'reply_to_post_id', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'replyToPostId', '17': true},
    const {'1': 'title', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'title', '17': true},
    const {'1': 'link', '3': 5, '4': 1, '5': 9, '9': 3, '10': 'link', '17': true},
    const {'1': 'content', '3': 6, '4': 1, '5': 9, '9': 4, '10': 'content', '17': true},
    const {'1': 'response_count', '3': 7, '4': 1, '5': 5, '10': 'responseCount'},
    const {'1': 'reply_count', '3': 8, '4': 1, '5': 5, '10': 'replyCount'},
    const {'1': 'group_count', '3': 9, '4': 1, '5': 5, '10': 'groupCount'},
    const {'1': 'media', '3': 10, '4': 3, '5': 9, '10': 'media'},
    const {'1': 'media_generated', '3': 11, '4': 1, '5': 8, '10': 'mediaGenerated'},
    const {'1': 'embed_link', '3': 12, '4': 1, '5': 8, '10': 'embedLink'},
    const {'1': 'shareable', '3': 13, '4': 1, '5': 8, '10': 'shareable'},
    const {'1': 'context', '3': 14, '4': 1, '5': 14, '6': '.jonline.PostContext', '10': 'context'},
    const {'1': 'visibility', '3': 15, '4': 1, '5': 14, '6': '.jonline.Visibility', '10': 'visibility'},
    const {'1': 'moderation', '3': 16, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'moderation'},
    const {'1': 'current_group_post', '3': 18, '4': 1, '5': 11, '6': '.jonline.GroupPost', '9': 5, '10': 'currentGroupPost', '17': true},
    const {'1': 'replies', '3': 19, '4': 3, '5': 11, '6': '.jonline.Post', '10': 'replies'},
    const {'1': 'created_at', '3': 20, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    const {'1': 'updated_at', '3': 21, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 6, '10': 'updatedAt', '17': true},
    const {'1': 'published_at', '3': 22, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 7, '10': 'publishedAt', '17': true},
    const {'1': 'last_activity_at', '3': 23, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'lastActivityAt'},
  ],
  '8': const [
    const {'1': '_author'},
    const {'1': '_reply_to_post_id'},
    const {'1': '_title'},
    const {'1': '_link'},
    const {'1': '_content'},
    const {'1': '_current_group_post'},
    const {'1': '_updated_at'},
    const {'1': '_published_at'},
  ],
};

/// Descriptor for `Post`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List postDescriptor = $convert.base64Decode('CgRQb3N0Eg4KAmlkGAEgASgJUgJpZBIsCgZhdXRob3IYAiABKAsyDy5qb25saW5lLkF1dGhvckgAUgZhdXRob3KIAQESLAoQcmVwbHlfdG9fcG9zdF9pZBgDIAEoCUgBUg1yZXBseVRvUG9zdElkiAEBEhkKBXRpdGxlGAQgASgJSAJSBXRpdGxliAEBEhcKBGxpbmsYBSABKAlIA1IEbGlua4gBARIdCgdjb250ZW50GAYgASgJSARSB2NvbnRlbnSIAQESJQoOcmVzcG9uc2VfY291bnQYByABKAVSDXJlc3BvbnNlQ291bnQSHwoLcmVwbHlfY291bnQYCCABKAVSCnJlcGx5Q291bnQSHwoLZ3JvdXBfY291bnQYCSABKAVSCmdyb3VwQ291bnQSFAoFbWVkaWEYCiADKAlSBW1lZGlhEicKD21lZGlhX2dlbmVyYXRlZBgLIAEoCFIObWVkaWFHZW5lcmF0ZWQSHQoKZW1iZWRfbGluaxgMIAEoCFIJZW1iZWRMaW5rEhwKCXNoYXJlYWJsZRgNIAEoCFIJc2hhcmVhYmxlEi4KB2NvbnRleHQYDiABKA4yFC5qb25saW5lLlBvc3RDb250ZXh0Ugdjb250ZXh0EjMKCnZpc2liaWxpdHkYDyABKA4yEy5qb25saW5lLlZpc2liaWxpdHlSCnZpc2liaWxpdHkSMwoKbW9kZXJhdGlvbhgQIAEoDjITLmpvbmxpbmUuTW9kZXJhdGlvblIKbW9kZXJhdGlvbhJFChJjdXJyZW50X2dyb3VwX3Bvc3QYEiABKAsyEi5qb25saW5lLkdyb3VwUG9zdEgFUhBjdXJyZW50R3JvdXBQb3N0iAEBEicKB3JlcGxpZXMYEyADKAsyDS5qb25saW5lLlBvc3RSB3JlcGxpZXMSOQoKY3JlYXRlZF9hdBgUIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI+Cgp1cGRhdGVkX2F0GBUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgGUgl1cGRhdGVkQXSIAQESQgoMcHVibGlzaGVkX2F0GBYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgHUgtwdWJsaXNoZWRBdIgBARJEChBsYXN0X2FjdGl2aXR5X2F0GBcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIObGFzdEFjdGl2aXR5QXRCCQoHX2F1dGhvckITChFfcmVwbHlfdG9fcG9zdF9pZEIICgZfdGl0bGVCBwoFX2xpbmtCCgoIX2NvbnRlbnRCFQoTX2N1cnJlbnRfZ3JvdXBfcG9zdEINCgtfdXBkYXRlZF9hdEIPCg1fcHVibGlzaGVkX2F0');
@$core.Deprecated('Use authorDescriptor instead')
const Author$json = const {
  '1': 'Author',
  '2': const [
    const {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'username', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'username', '17': true},
  ],
  '8': const [
    const {'1': '_username'},
  ],
};

/// Descriptor for `Author`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authorDescriptor = $convert.base64Decode('CgZBdXRob3ISFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEh8KCHVzZXJuYW1lGAIgASgJSABSCHVzZXJuYW1liAEBQgsKCV91c2VybmFtZQ==');
@$core.Deprecated('Use groupPostDescriptor instead')
const GroupPost$json = const {
  '1': 'GroupPost',
  '2': const [
    const {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    const {'1': 'post_id', '3': 2, '4': 1, '5': 9, '10': 'postId'},
    const {'1': 'user_id', '3': 3, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'group_moderation', '3': 4, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'groupModeration'},
    const {'1': 'created_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
  ],
};

/// Descriptor for `GroupPost`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupPostDescriptor = $convert.base64Decode('CglHcm91cFBvc3QSGQoIZ3JvdXBfaWQYASABKAlSB2dyb3VwSWQSFwoHcG9zdF9pZBgCIAEoCVIGcG9zdElkEhcKB3VzZXJfaWQYAyABKAlSBnVzZXJJZBI+ChBncm91cF9tb2RlcmF0aW9uGAQgASgOMhMuam9ubGluZS5Nb2RlcmF0aW9uUg9ncm91cE1vZGVyYXRpb24SOQoKY3JlYXRlZF9hdBgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdA==');
@$core.Deprecated('Use userPostDescriptor instead')
const UserPost$json = const {
  '1': 'UserPost',
  '2': const [
    const {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    const {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'created_at', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
  ],
};

/// Descriptor for `UserPost`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPostDescriptor = $convert.base64Decode('CghVc2VyUG9zdBIZCghncm91cF9pZBgBIAEoCVIHZ3JvdXBJZBIXCgd1c2VyX2lkGAIgASgJUgZ1c2VySWQSOQoKY3JlYXRlZF9hdBgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdA==');
@$core.Deprecated('Use getGroupPostsRequestDescriptor instead')
const GetGroupPostsRequest$json = const {
  '1': 'GetGroupPostsRequest',
  '2': const [
    const {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
    const {'1': 'group_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'groupId', '17': true},
  ],
  '8': const [
    const {'1': '_group_id'},
  ],
};

/// Descriptor for `GetGroupPostsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGroupPostsRequestDescriptor = $convert.base64Decode('ChRHZXRHcm91cFBvc3RzUmVxdWVzdBIXCgdwb3N0X2lkGAEgASgJUgZwb3N0SWQSHgoIZ3JvdXBfaWQYAiABKAlIAFIHZ3JvdXBJZIgBAUILCglfZ3JvdXBfaWQ=');
@$core.Deprecated('Use getGroupPostsResponseDescriptor instead')
const GetGroupPostsResponse$json = const {
  '1': 'GetGroupPostsResponse',
  '2': const [
    const {'1': 'group_posts', '3': 1, '4': 3, '5': 11, '6': '.jonline.GroupPost', '10': 'groupPosts'},
  ],
};

/// Descriptor for `GetGroupPostsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGroupPostsResponseDescriptor = $convert.base64Decode('ChVHZXRHcm91cFBvc3RzUmVzcG9uc2USMwoLZ3JvdXBfcG9zdHMYASADKAsyEi5qb25saW5lLkdyb3VwUG9zdFIKZ3JvdXBQb3N0cw==');
