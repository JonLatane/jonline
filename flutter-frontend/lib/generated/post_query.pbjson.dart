///
//  Generated code. Do not modify.
//  source: post_query.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use postQueryDescriptor instead')
const PostQuery$json = const {
  '1': 'PostQuery',
  '2': const [
    const {'1': 'single_post', '3': 1, '4': 1, '5': 11, '6': '.jonline.PostQuery.SinglePostQuery', '9': 0, '10': 'singlePost'},
    const {'1': 'post_replies', '3': 2, '4': 1, '5': 11, '6': '.jonline.PostQuery.PostRepliesQuery', '9': 0, '10': 'postReplies'},
    const {'1': 'author', '3': 3, '4': 1, '5': 11, '6': '.jonline.PostQuery.AuthorQuery', '9': 0, '10': 'author'},
  ],
  '3': const [PostQuery_SinglePostQuery$json, PostQuery_PostRepliesQuery$json, PostQuery_AuthorQuery$json],
  '8': const [
    const {'1': 'query'},
  ],
};

@$core.Deprecated('Use postQueryDescriptor instead')
const PostQuery_SinglePostQuery$json = const {
  '1': 'SinglePostQuery',
  '2': const [
    const {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
    const {'1': 'include_preview', '3': 2, '4': 1, '5': 8, '10': 'includePreview'},
    const {'1': 'response_depth', '3': 3, '4': 1, '5': 13, '10': 'responseDepth'},
    const {'1': 'response_limit', '3': 4, '4': 1, '5': 13, '10': 'responseLimit'},
  ],
};

@$core.Deprecated('Use postQueryDescriptor instead')
const PostQuery_PostRepliesQuery$json = const {
  '1': 'PostRepliesQuery',
  '2': const [
    const {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
    const {'1': 'depth', '3': 2, '4': 1, '5': 13, '10': 'depth'},
    const {'1': 'limit', '3': 3, '4': 1, '5': 13, '10': 'limit'},
  ],
};

@$core.Deprecated('Use postQueryDescriptor instead')
const PostQuery_AuthorQuery$json = const {
  '1': 'AuthorQuery',
  '2': const [
    const {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'limit', '3': 2, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `PostQuery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List postQueryDescriptor = $convert.base64Decode('CglQb3N0UXVlcnkSRQoLc2luZ2xlX3Bvc3QYASABKAsyIi5qb25saW5lLlBvc3RRdWVyeS5TaW5nbGVQb3N0UXVlcnlIAFIKc2luZ2xlUG9zdBJICgxwb3N0X3JlcGxpZXMYAiABKAsyIy5qb25saW5lLlBvc3RRdWVyeS5Qb3N0UmVwbGllc1F1ZXJ5SABSC3Bvc3RSZXBsaWVzEjgKBmF1dGhvchgDIAEoCzIeLmpvbmxpbmUuUG9zdFF1ZXJ5LkF1dGhvclF1ZXJ5SABSBmF1dGhvchqhAQoPU2luZ2xlUG9zdFF1ZXJ5EhcKB3Bvc3RfaWQYASABKAlSBnBvc3RJZBInCg9pbmNsdWRlX3ByZXZpZXcYAiABKAhSDmluY2x1ZGVQcmV2aWV3EiUKDnJlc3BvbnNlX2RlcHRoGAMgASgNUg1yZXNwb25zZURlcHRoEiUKDnJlc3BvbnNlX2xpbWl0GAQgASgNUg1yZXNwb25zZUxpbWl0GlcKEFBvc3RSZXBsaWVzUXVlcnkSFwoHcG9zdF9pZBgBIAEoCVIGcG9zdElkEhQKBWRlcHRoGAIgASgNUgVkZXB0aBIUCgVsaW1pdBgDIAEoDVIFbGltaXQaPAoLQXV0aG9yUXVlcnkSFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEhQKBWxpbWl0GAIgASgNUgVsaW1pdEIHCgVxdWVyeQ==');
