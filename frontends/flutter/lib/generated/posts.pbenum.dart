//
//  Generated code. Do not modify.
//  source: posts.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PostListingType extends $pb.ProtobufEnum {
  static const PostListingType PUBLIC_POSTS = PostListingType._(0, _omitEnumNames ? '' : 'PUBLIC_POSTS');
  static const PostListingType FOLLOWING_POSTS = PostListingType._(1, _omitEnumNames ? '' : 'FOLLOWING_POSTS');
  static const PostListingType MY_GROUPS_POSTS = PostListingType._(2, _omitEnumNames ? '' : 'MY_GROUPS_POSTS');
  static const PostListingType DIRECT_POSTS = PostListingType._(3, _omitEnumNames ? '' : 'DIRECT_POSTS');
  static const PostListingType POSTS_PENDING_MODERATION = PostListingType._(4, _omitEnumNames ? '' : 'POSTS_PENDING_MODERATION');
  static const PostListingType GROUP_POSTS = PostListingType._(10, _omitEnumNames ? '' : 'GROUP_POSTS');
  static const PostListingType GROUP_POSTS_PENDING_MODERATION = PostListingType._(11, _omitEnumNames ? '' : 'GROUP_POSTS_PENDING_MODERATION');

  static const $core.List<PostListingType> values = <PostListingType> [
    PUBLIC_POSTS,
    FOLLOWING_POSTS,
    MY_GROUPS_POSTS,
    DIRECT_POSTS,
    POSTS_PENDING_MODERATION,
    GROUP_POSTS,
    GROUP_POSTS_PENDING_MODERATION,
  ];

  static final $core.Map<$core.int, PostListingType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static PostListingType? valueOf($core.int value) => _byValue[value];

  const PostListingType._($core.int v, $core.String n) : super(v, n);
}

class PostContext extends $pb.ProtobufEnum {
  static const PostContext POST = PostContext._(0, _omitEnumNames ? '' : 'POST');
  static const PostContext REPLY = PostContext._(1, _omitEnumNames ? '' : 'REPLY');
  static const PostContext EVENT = PostContext._(2, _omitEnumNames ? '' : 'EVENT');
  static const PostContext EVENT_INSTANCE = PostContext._(3, _omitEnumNames ? '' : 'EVENT_INSTANCE');

  static const $core.List<PostContext> values = <PostContext> [
    POST,
    REPLY,
    EVENT,
    EVENT_INSTANCE,
  ];

  static final $core.Map<$core.int, PostContext> _byValue = $pb.ProtobufEnum.initByValue(values);
  static PostContext? valueOf($core.int value) => _byValue[value];

  const PostContext._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
