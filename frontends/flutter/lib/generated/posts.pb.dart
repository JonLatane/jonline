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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $9;
import 'media.pb.dart' as $5;
import 'posts.pbenum.dart';
import 'users.pb.dart' as $4;
import 'visibility_moderation.pbenum.dart' as $11;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'posts.pbenum.dart';

/// Valid GetPostsRequest formats:
///
/// - `{[listing_type: AllAccessiblePosts]}`
///     - Get ServerPublic/GlobalPublic posts you can see based on your authorization (or lack thereof).
/// - `{listing_type:MyGroupsPosts|FollowingPosts}`
///     - Get posts from groups you're a member of or from users you're following. Authorization required.
/// - `{post_id:}`
///     - Get one post ,including preview data/
/// - `{post_id:, reply_depth: 1}`
///     - Get replies to a post - only support for replyDepth=1 is done for now though.
/// - `{listing_type: MyGroupsPosts|`GroupPost`sPendingModeration, group_id:}`
///     - Get posts/posts needing moderation for a group. Authorization may be required depending on group visibility.
/// - `{author_user_id:, group_id:}`
///     - Get posts by a user for a group. (TODO)
/// - `{listing_type: AuthorPosts, author_user_id:}`
///     - Get posts by a user. (TODO)
class GetPostsRequest extends $pb.GeneratedMessage {
  factory GetPostsRequest({
    $core.String? postId,
    $core.String? authorUserId,
    $core.String? groupId,
    $core.int? replyDepth,
    PostContext? context,
    $core.String? postIds,
    PostListingType? listingType,
    $core.int? page,
  }) {
    final result = create();
    if (postId != null) result.postId = postId;
    if (authorUserId != null) result.authorUserId = authorUserId;
    if (groupId != null) result.groupId = groupId;
    if (replyDepth != null) result.replyDepth = replyDepth;
    if (context != null) result.context = context;
    if (postIds != null) result.postIds = postIds;
    if (listingType != null) result.listingType = listingType;
    if (page != null) result.page = page;
    return result;
  }

  GetPostsRequest._();

  factory GetPostsRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetPostsRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetPostsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'postId')
    ..aOS(2, _omitFieldNames ? '' : 'authorUserId')
    ..aOS(3, _omitFieldNames ? '' : 'groupId')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'replyDepth', $pb.PbFieldType.OU3)
    ..e<PostContext>(5, _omitFieldNames ? '' : 'context', $pb.PbFieldType.OE, defaultOrMaker: PostContext.POST, valueOf: PostContext.valueOf, enumValues: PostContext.values)
    ..aOS(9, _omitFieldNames ? '' : 'postIds')
    ..e<PostListingType>(10, _omitFieldNames ? '' : 'listingType', $pb.PbFieldType.OE, defaultOrMaker: PostListingType.ALL_ACCESSIBLE_POSTS, valueOf: PostListingType.valueOf, enumValues: PostListingType.values)
    ..a<$core.int>(15, _omitFieldNames ? '' : 'page', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPostsRequest clone() => GetPostsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPostsRequest copyWith(void Function(GetPostsRequest) updates) => super.copyWith((message) => updates(message as GetPostsRequest)) as GetPostsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetPostsRequest create() => GetPostsRequest._();
  @$core.override
  GetPostsRequest createEmptyInstance() => create();
  static $pb.PbList<GetPostsRequest> createRepeated() => $pb.PbList<GetPostsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetPostsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetPostsRequest>(create);
  static GetPostsRequest? _defaultInstance;

  /// Returns the single post with the given ID.
  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => $_clearField(1);

  /// Limits results to those by the given author user ID.
  @$pb.TagNumber(2)
  $core.String get authorUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set authorUserId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuthorUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthorUserId() => $_clearField(2);

  /// Limits results to those in the given group ID.
  @$pb.TagNumber(3)
  $core.String get groupId => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGroupId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupId() => $_clearField(3);

  /// Only supported for depth=2 for now.
  @$pb.TagNumber(4)
  $core.int get replyDepth => $_getIZ(3);
  @$pb.TagNumber(4)
  set replyDepth($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReplyDepth() => $_has(3);
  @$pb.TagNumber(4)
  void clearReplyDepth() => $_clearField(4);

  /// Only POST and REPLY are supported for now.
  @$pb.TagNumber(5)
  PostContext get context => $_getN(4);
  @$pb.TagNumber(5)
  set context(PostContext value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasContext() => $_has(4);
  @$pb.TagNumber(5)
  void clearContext() => $_clearField(5);

  /// Returns expanded posts with the given IDs.
  @$pb.TagNumber(9)
  $core.String get postIds => $_getSZ(5);
  @$pb.TagNumber(9)
  set postIds($core.String value) => $_setString(5, value);
  @$pb.TagNumber(9)
  $core.bool hasPostIds() => $_has(5);
  @$pb.TagNumber(9)
  void clearPostIds() => $_clearField(9);

  /// The listing type of the request. See `PostListingType` for more info.
  @$pb.TagNumber(10)
  PostListingType get listingType => $_getN(6);
  @$pb.TagNumber(10)
  set listingType(PostListingType value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasListingType() => $_has(6);
  @$pb.TagNumber(10)
  void clearListingType() => $_clearField(10);

  /// The page of results to return. Defaults to 0.
  @$pb.TagNumber(15)
  $core.int get page => $_getIZ(7);
  @$pb.TagNumber(15)
  set page($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(15)
  $core.bool hasPage() => $_has(7);
  @$pb.TagNumber(15)
  void clearPage() => $_clearField(15);
}

/// Used for getting posts.
class GetPostsResponse extends $pb.GeneratedMessage {
  factory GetPostsResponse({
    $core.Iterable<Post>? posts,
  }) {
    final result = create();
    if (posts != null) result.posts.addAll(posts);
    return result;
  }

  GetPostsResponse._();

  factory GetPostsResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetPostsResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetPostsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Post>(1, _omitFieldNames ? '' : 'posts', $pb.PbFieldType.PM, subBuilder: Post.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPostsResponse clone() => GetPostsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPostsResponse copyWith(void Function(GetPostsResponse) updates) => super.copyWith((message) => updates(message as GetPostsResponse)) as GetPostsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetPostsResponse create() => GetPostsResponse._();
  @$core.override
  GetPostsResponse createEmptyInstance() => create();
  static $pb.PbList<GetPostsResponse> createRepeated() => $pb.PbList<GetPostsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetPostsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetPostsResponse>(create);
  static GetPostsResponse? _defaultInstance;

  /// The posts returned by the request.
  @$pb.TagNumber(1)
  $pb.PbList<Post> get posts => $_getList(0);
}

/// A `Post` is a message that can be posted to the server. Its `visibility`
/// as well as any associated `GroupPost`s and `UserPost`s determine what users
/// see it and where.
///
/// `Post`s are also a fundamental unit of the system. They provide a building block
/// of Visibility and Moderation management that is used throughout Posts, Replies, Events,
/// and Event Instances.
class Post extends $pb.GeneratedMessage {
  factory Post({
    $core.String? id,
    $4.Author? author,
    $core.String? replyToPostId,
    $core.String? title,
    $core.String? link,
    $core.String? content,
    $core.int? responseCount,
    $core.int? replyCount,
    $core.int? groupCount,
    $core.Iterable<$5.MediaReference>? media,
    $core.bool? mediaGenerated,
    $core.bool? embedLink,
    $core.bool? shareable,
    PostContext? context,
    $11.Visibility? visibility,
    $11.Moderation? moderation,
    GroupPost? currentGroupPost,
    $core.Iterable<Post>? replies,
    $9.Timestamp? createdAt,
    $9.Timestamp? updatedAt,
    $9.Timestamp? publishedAt,
    $9.Timestamp? lastActivityAt,
    $fixnum.Int64? unauthenticatedStarCount,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (author != null) result.author = author;
    if (replyToPostId != null) result.replyToPostId = replyToPostId;
    if (title != null) result.title = title;
    if (link != null) result.link = link;
    if (content != null) result.content = content;
    if (responseCount != null) result.responseCount = responseCount;
    if (replyCount != null) result.replyCount = replyCount;
    if (groupCount != null) result.groupCount = groupCount;
    if (media != null) result.media.addAll(media);
    if (mediaGenerated != null) result.mediaGenerated = mediaGenerated;
    if (embedLink != null) result.embedLink = embedLink;
    if (shareable != null) result.shareable = shareable;
    if (context != null) result.context = context;
    if (visibility != null) result.visibility = visibility;
    if (moderation != null) result.moderation = moderation;
    if (currentGroupPost != null) result.currentGroupPost = currentGroupPost;
    if (replies != null) result.replies.addAll(replies);
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (publishedAt != null) result.publishedAt = publishedAt;
    if (lastActivityAt != null) result.lastActivityAt = lastActivityAt;
    if (unauthenticatedStarCount != null) result.unauthenticatedStarCount = unauthenticatedStarCount;
    return result;
  }

  Post._();

  factory Post.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory Post.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Post', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<$4.Author>(2, _omitFieldNames ? '' : 'author', subBuilder: $4.Author.create)
    ..aOS(3, _omitFieldNames ? '' : 'replyToPostId')
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'link')
    ..aOS(6, _omitFieldNames ? '' : 'content')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'responseCount', $pb.PbFieldType.O3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'replyCount', $pb.PbFieldType.O3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'groupCount', $pb.PbFieldType.O3)
    ..pc<$5.MediaReference>(10, _omitFieldNames ? '' : 'media', $pb.PbFieldType.PM, subBuilder: $5.MediaReference.create)
    ..aOB(11, _omitFieldNames ? '' : 'mediaGenerated')
    ..aOB(12, _omitFieldNames ? '' : 'embedLink')
    ..aOB(13, _omitFieldNames ? '' : 'shareable')
    ..e<PostContext>(14, _omitFieldNames ? '' : 'context', $pb.PbFieldType.OE, defaultOrMaker: PostContext.POST, valueOf: PostContext.valueOf, enumValues: PostContext.values)
    ..e<$11.Visibility>(15, _omitFieldNames ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $11.Visibility.VISIBILITY_UNKNOWN, valueOf: $11.Visibility.valueOf, enumValues: $11.Visibility.values)
    ..e<$11.Moderation>(16, _omitFieldNames ? '' : 'moderation', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..aOM<GroupPost>(18, _omitFieldNames ? '' : 'currentGroupPost', subBuilder: GroupPost.create)
    ..pc<Post>(19, _omitFieldNames ? '' : 'replies', $pb.PbFieldType.PM, subBuilder: Post.create)
    ..aOM<$9.Timestamp>(20, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(21, _omitFieldNames ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(22, _omitFieldNames ? '' : 'publishedAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(23, _omitFieldNames ? '' : 'lastActivityAt', subBuilder: $9.Timestamp.create)
    ..aInt64(24, _omitFieldNames ? '' : 'unauthenticatedStarCount')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Post clone() => Post()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Post copyWith(void Function(Post) updates) => super.copyWith((message) => updates(message as Post)) as Post;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Post create() => Post._();
  @$core.override
  Post createEmptyInstance() => create();
  static $pb.PbList<Post> createRepeated() => $pb.PbList<Post>();
  @$core.pragma('dart2js:noInline')
  static Post getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Post>(create);
  static Post? _defaultInstance;

  /// Unique ID of the post.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// The author of the post. This is a smaller version of User.
  @$pb.TagNumber(2)
  $4.Author get author => $_getN(1);
  @$pb.TagNumber(2)
  set author($4.Author value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAuthor() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthor() => $_clearField(2);
  @$pb.TagNumber(2)
  $4.Author ensureAuthor() => $_ensure(1);

  /// If this is a reply, this is the ID of the post it's replying to.
  @$pb.TagNumber(3)
  $core.String get replyToPostId => $_getSZ(2);
  @$pb.TagNumber(3)
  set replyToPostId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReplyToPostId() => $_has(2);
  @$pb.TagNumber(3)
  void clearReplyToPostId() => $_clearField(3);

  /// The title of the post. This is invalid for replies.
  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => $_clearField(4);

  /// The link of the post. This is invalid for replies.
  @$pb.TagNumber(5)
  $core.String get link => $_getSZ(4);
  @$pb.TagNumber(5)
  set link($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLink() => $_has(4);
  @$pb.TagNumber(5)
  void clearLink() => $_clearField(5);

  /// The content of the post. This is required for replies.
  @$pb.TagNumber(6)
  $core.String get content => $_getSZ(5);
  @$pb.TagNumber(6)
  set content($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasContent() => $_has(5);
  @$pb.TagNumber(6)
  void clearContent() => $_clearField(6);

  /// The number of responses (replies *and* replies to replies, etc.) to this post.
  @$pb.TagNumber(7)
  $core.int get responseCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set responseCount($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasResponseCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearResponseCount() => $_clearField(7);

  /// The number of *direct* replies to this post.
  @$pb.TagNumber(8)
  $core.int get replyCount => $_getIZ(7);
  @$pb.TagNumber(8)
  set replyCount($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasReplyCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearReplyCount() => $_clearField(8);

  /// The number of groups this post is in.
  @$pb.TagNumber(9)
  $core.int get groupCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set groupCount($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasGroupCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearGroupCount() => $_clearField(9);

  /// List of Media IDs associated with this post. Order is preserved.
  @$pb.TagNumber(10)
  $pb.PbList<$5.MediaReference> get media => $_getList(9);

  /// Flag indicating whether Media has been generated for this Post.
  /// Currently previews are generated for any Link post.
  @$pb.TagNumber(11)
  $core.bool get mediaGenerated => $_getBF(10);
  @$pb.TagNumber(11)
  set mediaGenerated($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasMediaGenerated() => $_has(10);
  @$pb.TagNumber(11)
  void clearMediaGenerated() => $_clearField(11);

  /// Flag indicating
  @$pb.TagNumber(12)
  $core.bool get embedLink => $_getBF(11);
  @$pb.TagNumber(12)
  set embedLink($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasEmbedLink() => $_has(11);
  @$pb.TagNumber(12)
  void clearEmbedLink() => $_clearField(12);

  /// Flag indicating a `LIMITED` or `SERVER_PUBLIC` post can be shared with groups and individuals,
  /// and a `DIRECT` post can be shared with individuals.
  @$pb.TagNumber(13)
  $core.bool get shareable => $_getBF(12);
  @$pb.TagNumber(13)
  set shareable($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasShareable() => $_has(12);
  @$pb.TagNumber(13)
  void clearShareable() => $_clearField(13);

  /// Context of the Post (`POST`, `REPLY`, `EVENT`, or `EVENT_INSTANCE`.)
  @$pb.TagNumber(14)
  PostContext get context => $_getN(13);
  @$pb.TagNumber(14)
  set context(PostContext value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasContext() => $_has(13);
  @$pb.TagNumber(14)
  void clearContext() => $_clearField(14);

  /// The visibility of the Post.
  @$pb.TagNumber(15)
  $11.Visibility get visibility => $_getN(14);
  @$pb.TagNumber(15)
  set visibility($11.Visibility value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasVisibility() => $_has(14);
  @$pb.TagNumber(15)
  void clearVisibility() => $_clearField(15);

  /// The moderation of the Post.
  @$pb.TagNumber(16)
  $11.Moderation get moderation => $_getN(15);
  @$pb.TagNumber(16)
  set moderation($11.Moderation value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasModeration() => $_has(15);
  @$pb.TagNumber(16)
  void clearModeration() => $_clearField(16);

  /// If the Post was retrieved from GetPosts with a group_id, the GroupPost
  /// metadata may be returned along with the Post.
  @$pb.TagNumber(18)
  GroupPost get currentGroupPost => $_getN(16);
  @$pb.TagNumber(18)
  set currentGroupPost(GroupPost value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasCurrentGroupPost() => $_has(16);
  @$pb.TagNumber(18)
  void clearCurrentGroupPost() => $_clearField(18);
  @$pb.TagNumber(18)
  GroupPost ensureCurrentGroupPost() => $_ensure(16);

  /// Hierarchical replies to this post. There will never be more than `reply_count` replies. However,
  /// there may be fewer than `reply_count` replies if some replies are
  /// hidden by moderation or visibility. Replies are not generally loaded by default, but can be added to Posts
  /// in the frontend.
  @$pb.TagNumber(19)
  $pb.PbList<Post> get replies => $_getList(17);

  /// The time the post was created.
  @$pb.TagNumber(20)
  $9.Timestamp get createdAt => $_getN(18);
  @$pb.TagNumber(20)
  set createdAt($9.Timestamp value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedAt() => $_has(18);
  @$pb.TagNumber(20)
  void clearCreatedAt() => $_clearField(20);
  @$pb.TagNumber(20)
  $9.Timestamp ensureCreatedAt() => $_ensure(18);

  /// The time the post was last updated.
  @$pb.TagNumber(21)
  $9.Timestamp get updatedAt => $_getN(19);
  @$pb.TagNumber(21)
  set updatedAt($9.Timestamp value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedAt() => $_has(19);
  @$pb.TagNumber(21)
  void clearUpdatedAt() => $_clearField(21);
  @$pb.TagNumber(21)
  $9.Timestamp ensureUpdatedAt() => $_ensure(19);

  /// The time the post was published (its visibility first changed to `SERVER_PUBLIC` or `GLOBAL_PUBLIC`).
  @$pb.TagNumber(22)
  $9.Timestamp get publishedAt => $_getN(20);
  @$pb.TagNumber(22)
  set publishedAt($9.Timestamp value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasPublishedAt() => $_has(20);
  @$pb.TagNumber(22)
  void clearPublishedAt() => $_clearField(22);
  @$pb.TagNumber(22)
  $9.Timestamp ensurePublishedAt() => $_ensure(20);

  /// The time the post was last interacted with (replied to, etc.)
  @$pb.TagNumber(23)
  $9.Timestamp get lastActivityAt => $_getN(21);
  @$pb.TagNumber(23)
  set lastActivityAt($9.Timestamp value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasLastActivityAt() => $_has(21);
  @$pb.TagNumber(23)
  void clearLastActivityAt() => $_clearField(23);
  @$pb.TagNumber(23)
  $9.Timestamp ensureLastActivityAt() => $_ensure(21);

  /// The number of unauthenticated stars on the post.
  @$pb.TagNumber(24)
  $fixnum.Int64 get unauthenticatedStarCount => $_getI64(22);
  @$pb.TagNumber(24)
  set unauthenticatedStarCount($fixnum.Int64 value) => $_setInt64(22, value);
  @$pb.TagNumber(24)
  $core.bool hasUnauthenticatedStarCount() => $_has(22);
  @$pb.TagNumber(24)
  void clearUnauthenticatedStarCount() => $_clearField(24);
}

/// A `GroupPost` is a cross-post of a `Post` to a `Group`. It contains
/// information about the moderation of the post in the group, as well as
/// the time it was cross-posted and the user who did the cross-posting.
class GroupPost extends $pb.GeneratedMessage {
  factory GroupPost({
    $core.String? groupId,
    $core.String? postId,
  @$core.Deprecated('This field is deprecated.')
    $core.String? userId,
    $11.Moderation? groupModeration,
    $9.Timestamp? createdAt,
    $4.Author? sharedBy,
  }) {
    final result = create();
    if (groupId != null) result.groupId = groupId;
    if (postId != null) result.postId = postId;
    if (userId != null) result.userId = userId;
    if (groupModeration != null) result.groupModeration = groupModeration;
    if (createdAt != null) result.createdAt = createdAt;
    if (sharedBy != null) result.sharedBy = sharedBy;
    return result;
  }

  GroupPost._();

  factory GroupPost.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GroupPost.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GroupPost', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aOS(2, _omitFieldNames ? '' : 'postId')
    ..aOS(3, _omitFieldNames ? '' : 'userId')
    ..e<$11.Moderation>(4, _omitFieldNames ? '' : 'groupModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..aOM<$9.Timestamp>(5, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$4.Author>(6, _omitFieldNames ? '' : 'sharedBy', subBuilder: $4.Author.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupPost clone() => GroupPost()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupPost copyWith(void Function(GroupPost) updates) => super.copyWith((message) => updates(message as GroupPost)) as GroupPost;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GroupPost create() => GroupPost._();
  @$core.override
  GroupPost createEmptyInstance() => create();
  static $pb.PbList<GroupPost> createRepeated() => $pb.PbList<GroupPost>();
  @$core.pragma('dart2js:noInline')
  static GroupPost getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupPost>(create);
  static GroupPost? _defaultInstance;

  /// The ID of the group this post is in.
  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => $_clearField(1);

  /// The ID of the post.
  @$pb.TagNumber(2)
  $core.String get postId => $_getSZ(1);
  @$pb.TagNumber(2)
  set postId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPostId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPostId() => $_clearField(2);

  /// **Deprecated.** Prefer to use `shared_by`. The ID of the user who cross-posted the post.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  $core.String get userId => $_getSZ(2);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  set userId($core.String value) => $_setString(2, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  $core.bool hasUserId() => $_has(2);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  void clearUserId() => $_clearField(3);

  /// The moderation of the post in the group.
  @$pb.TagNumber(4)
  $11.Moderation get groupModeration => $_getN(3);
  @$pb.TagNumber(4)
  set groupModeration($11.Moderation value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasGroupModeration() => $_has(3);
  @$pb.TagNumber(4)
  void clearGroupModeration() => $_clearField(4);

  /// The time the post was cross-posted.
  @$pb.TagNumber(5)
  $9.Timestamp get createdAt => $_getN(4);
  @$pb.TagNumber(5)
  set createdAt($9.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $9.Timestamp ensureCreatedAt() => $_ensure(4);

  /// Author info for the user who cross-posted the post.
  @$pb.TagNumber(6)
  $4.Author get sharedBy => $_getN(5);
  @$pb.TagNumber(6)
  set sharedBy($4.Author value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSharedBy() => $_has(5);
  @$pb.TagNumber(6)
  void clearSharedBy() => $_clearField(6);
  @$pb.TagNumber(6)
  $4.Author ensureSharedBy() => $_ensure(5);
}

/// A `UserPost` is a "direct share" of a `Post` to a `User`. Currently unused/unimplemented.
/// See also: [`DIRECT` `Visibility`](#jonline-Visibility).
class UserPost extends $pb.GeneratedMessage {
  factory UserPost({
    $core.String? userId,
    $core.String? postId,
    $9.Timestamp? createdAt,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (postId != null) result.postId = postId;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  UserPost._();

  factory UserPost.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory UserPost.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UserPost', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'postId')
    ..aOM<$9.Timestamp>(3, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserPost clone() => UserPost()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserPost copyWith(void Function(UserPost) updates) => super.copyWith((message) => updates(message as UserPost)) as UserPost;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserPost create() => UserPost._();
  @$core.override
  UserPost createEmptyInstance() => create();
  static $pb.PbList<UserPost> createRepeated() => $pb.PbList<UserPost>();
  @$core.pragma('dart2js:noInline')
  static UserPost getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserPost>(create);
  static UserPost? _defaultInstance;

  /// The ID of the user the post is shared with.
  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  /// The ID of the post shared.
  @$pb.TagNumber(2)
  $core.String get postId => $_getSZ(1);
  @$pb.TagNumber(2)
  set postId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPostId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPostId() => $_clearField(2);

  /// The time the post was shared.
  @$pb.TagNumber(3)
  $9.Timestamp get createdAt => $_getN(2);
  @$pb.TagNumber(3)
  set createdAt($9.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $9.Timestamp ensureCreatedAt() => $_ensure(2);
}

/// Used for getting context about `GroupPost`s of an existing `Post`.
class GetGroupPostsRequest extends $pb.GeneratedMessage {
  factory GetGroupPostsRequest({
    $core.String? postId,
    $core.String? groupId,
  }) {
    final result = create();
    if (postId != null) result.postId = postId;
    if (groupId != null) result.groupId = groupId;
    return result;
  }

  GetGroupPostsRequest._();

  factory GetGroupPostsRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetGroupPostsRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetGroupPostsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'postId')
    ..aOS(2, _omitFieldNames ? '' : 'groupId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupPostsRequest clone() => GetGroupPostsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupPostsRequest copyWith(void Function(GetGroupPostsRequest) updates) => super.copyWith((message) => updates(message as GetGroupPostsRequest)) as GetGroupPostsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetGroupPostsRequest create() => GetGroupPostsRequest._();
  @$core.override
  GetGroupPostsRequest createEmptyInstance() => create();
  static $pb.PbList<GetGroupPostsRequest> createRepeated() => $pb.PbList<GetGroupPostsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetGroupPostsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetGroupPostsRequest>(create);
  static GetGroupPostsRequest? _defaultInstance;

  /// The ID of the post to get `GroupPost`s for.
  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => $_clearField(1);

  /// The ID of the group to get `GroupPost`s for.
  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupId() => $_clearField(2);
}

/// Used for getting context about `GroupPost`s of an existing `Post`.
class GetGroupPostsResponse extends $pb.GeneratedMessage {
  factory GetGroupPostsResponse({
    $core.Iterable<GroupPost>? groupPosts,
  }) {
    final result = create();
    if (groupPosts != null) result.groupPosts.addAll(groupPosts);
    return result;
  }

  GetGroupPostsResponse._();

  factory GetGroupPostsResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetGroupPostsResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetGroupPostsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<GroupPost>(1, _omitFieldNames ? '' : 'groupPosts', $pb.PbFieldType.PM, subBuilder: GroupPost.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupPostsResponse clone() => GetGroupPostsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupPostsResponse copyWith(void Function(GetGroupPostsResponse) updates) => super.copyWith((message) => updates(message as GetGroupPostsResponse)) as GetGroupPostsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetGroupPostsResponse create() => GetGroupPostsResponse._();
  @$core.override
  GetGroupPostsResponse createEmptyInstance() => create();
  static $pb.PbList<GetGroupPostsResponse> createRepeated() => $pb.PbList<GetGroupPostsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetGroupPostsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetGroupPostsResponse>(create);
  static GetGroupPostsResponse? _defaultInstance;

  /// The `GroupPost`s for the given `Post` or `Group`.
  @$pb.TagNumber(1)
  $pb.PbList<GroupPost> get groupPosts => $_getList(0);
}


const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
