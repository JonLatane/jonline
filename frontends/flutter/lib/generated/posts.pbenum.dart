///
//  Generated code. Do not modify.
//  source: posts.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class PostListingType extends $pb.ProtobufEnum {
  static const PostListingType PUBLIC_POSTS = PostListingType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PUBLIC_POSTS');
  static const PostListingType FOLLOWING_POSTS = PostListingType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FOLLOWING_POSTS');
  static const PostListingType MY_GROUPS_POSTS = PostListingType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MY_GROUPS_POSTS');
  static const PostListingType DIRECT_POSTS = PostListingType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DIRECT_POSTS');
  static const PostListingType POSTS_PENDING_MODERATION = PostListingType._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'POSTS_PENDING_MODERATION');
  static const PostListingType GROUP_POSTS = PostListingType._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GROUP_POSTS');
  static const PostListingType GROUP_POSTS_PENDING_MODERATION = PostListingType._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GROUP_POSTS_PENDING_MODERATION');

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
  static const PostContext POST = PostContext._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'POST');
  static const PostContext EVENT = PostContext._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EVENT');

  static const $core.List<PostContext> values = <PostContext> [
    POST,
    EVENT,
  ];

  static final $core.Map<$core.int, PostContext> _byValue = $pb.ProtobufEnum.initByValue(values);
  static PostContext? valueOf($core.int value) => _byValue[value];

  const PostContext._($core.int v, $core.String n) : super(v, n);
}

