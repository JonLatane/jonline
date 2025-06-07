//
//  Generated code. Do not modify.
//  source: posts.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// A high-level enumeration of general ways of requesting posts.
class PostListingType extends $pb.ProtobufEnum {
  /// Gets SERVER_PUBLIC and GLOBAL_PUBLIC posts as is sensible.
  /// Also usable for getting replies anywhere.
  static const PostListingType ALL_ACCESSIBLE_POSTS = PostListingType._(0, _omitEnumNames ? '' : 'ALL_ACCESSIBLE_POSTS');
  /// Returns posts from users the user is following.
  static const PostListingType FOLLOWING_POSTS = PostListingType._(1, _omitEnumNames ? '' : 'FOLLOWING_POSTS');
  /// Returns posts from any group the user is a member of.
  static const PostListingType MY_GROUPS_POSTS = PostListingType._(2, _omitEnumNames ? '' : 'MY_GROUPS_POSTS');
  /// Returns `DIRECT` posts that are directly addressed to the user.
  static const PostListingType DIRECT_POSTS = PostListingType._(3, _omitEnumNames ? '' : 'DIRECT_POSTS');
  /// Returns posts pending moderation by the server-level mods/admins.
  static const PostListingType POSTS_PENDING_MODERATION = PostListingType._(4, _omitEnumNames ? '' : 'POSTS_PENDING_MODERATION');
  /// Returns posts from a specific group. Requires group_id parameter.
  static const PostListingType GROUP_POSTS = PostListingType._(10, _omitEnumNames ? '' : 'GROUP_POSTS');
  /// Returns pending_moderation posts from a specific group. Requires group_id
  /// parameter and user must have group (or server) admin permissions.
  static const PostListingType GROUP_POSTS_PENDING_MODERATION = PostListingType._(11, _omitEnumNames ? '' : 'GROUP_POSTS_PENDING_MODERATION');

  static const $core.List<PostListingType> values = <PostListingType> [
    ALL_ACCESSIBLE_POSTS,
    FOLLOWING_POSTS,
    MY_GROUPS_POSTS,
    DIRECT_POSTS,
    POSTS_PENDING_MODERATION,
    GROUP_POSTS,
    GROUP_POSTS_PENDING_MODERATION,
  ];

  static final $core.Map<$core.int, PostListingType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static PostListingType? valueOf($core.int value) => _byValue[value];

  const PostListingType._(super.value, super.name);
}

/// Differentiates the context of a Post, as in Jonline's data models, Post is the "core" type where Jonline consolidates moderation and visibility data and logic.
class PostContext extends $pb.ProtobufEnum {
  /// "Standard" Post.
  static const PostContext POST = PostContext._(0, _omitEnumNames ? '' : 'POST');
  /// Reply to a `POST`, `REPLY`, `EVENT`, `EVENT_INSTANCE`, `FEDERATED_POST`, or `FEDERATED_EVENT_INSTANCE`.
  /// Does not suport a `link`.
  static const PostContext REPLY = PostContext._(1, _omitEnumNames ? '' : 'REPLY');
  /// An "Event" Post. The Events table should have a row for this Post.
  /// These Posts' `link` and `title` fields are modifiable.
  static const PostContext EVENT = PostContext._(2, _omitEnumNames ? '' : 'EVENT');
  /// An "Event Instance" Post. The EventInstances table should have a row for this Post.
  /// These Posts' `link` and `title` fields are modifiable.
  static const PostContext EVENT_INSTANCE = PostContext._(3, _omitEnumNames ? '' : 'EVENT_INSTANCE');
  /// A "Federated" Post. This is a Post that was created on another server. Its `link`
  /// field *must* be a link to the original Post, i.e. `htttps://jonline.io/post/abcd1234`.
  /// This is enforced by the `CreatePost` PRC.
  static const PostContext FEDERATED_POST = PostContext._(10, _omitEnumNames ? '' : 'FEDERATED_POST');
  /// A "Federated" EventInstance. This is an EventInstance that was created on another server. Its `link`
  /// field *must* be a link to the original EventInstance, i.e. `https://jonline.io/event/abcd1234`.
  static const PostContext FEDERATED_EVENT_INSTANCE = PostContext._(13, _omitEnumNames ? '' : 'FEDERATED_EVENT_INSTANCE');

  static const $core.List<PostContext> values = <PostContext> [
    POST,
    REPLY,
    EVENT,
    EVENT_INSTANCE,
    FEDERATED_POST,
    FEDERATED_EVENT_INSTANCE,
  ];

  static final $core.Map<$core.int, PostContext> _byValue = $pb.ProtobufEnum.initByValue(values);
  static PostContext? valueOf($core.int value) => _byValue[value];

  const PostContext._(super.value, super.name);
}


const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
