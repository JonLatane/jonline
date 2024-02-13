//
//  Generated code. Do not modify.
//  source: posts.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $9;
import 'media.pb.dart' as $5;
import 'posts.pbenum.dart';
import 'users.pb.dart' as $4;
import 'visibility_moderation.pbenum.dart' as $10;

export 'posts.pbenum.dart';

///  Valid GetPostsRequest formats:
///
///  - `{[listing_type: AllAccessiblePosts]}`
///      - Get ServerPublic/GlobalPublic posts you can see based on your authorization (or lack thereof).
///  - `{listing_type:MyGroupsPosts|FollowingPosts}`
///      - Get posts from groups you're a member of or from users you're following. Authorization required.
///  - `{post_id:}`
///      - Get one post ,including preview data/
///  - `{post_id:, reply_depth: 1}`
///      - Get replies to a post - only support for replyDepth=1 is done for now though.
///  - `{listing_type: MyGroupsPosts|`GroupPost`sPendingModeration, group_id:}`
///      - Get posts/posts needing moderation for a group. Authorization may be required depending on group visibility.
///  - `{author_user_id:, group_id:}`
///      - Get posts by a user for a group. (TODO)
///  - `{listing_type: AuthorPosts, author_user_id:}`
///      - Get posts by a user. (TODO)
class GetPostsRequest extends $pb.GeneratedMessage {
  factory GetPostsRequest({
    $core.String? postId,
    $core.String? authorUserId,
    $core.String? groupId,
    $core.int? replyDepth,
    PostContext? context,
    PostListingType? listingType,
    $core.int? page,
  }) {
    final $result = create();
    if (postId != null) {
      $result.postId = postId;
    }
    if (authorUserId != null) {
      $result.authorUserId = authorUserId;
    }
    if (groupId != null) {
      $result.groupId = groupId;
    }
    if (replyDepth != null) {
      $result.replyDepth = replyDepth;
    }
    if (context != null) {
      $result.context = context;
    }
    if (listingType != null) {
      $result.listingType = listingType;
    }
    if (page != null) {
      $result.page = page;
    }
    return $result;
  }
  GetPostsRequest._() : super();
  factory GetPostsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetPostsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetPostsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'postId')
    ..aOS(2, _omitFieldNames ? '' : 'authorUserId')
    ..aOS(3, _omitFieldNames ? '' : 'groupId')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'replyDepth', $pb.PbFieldType.OU3)
    ..e<PostContext>(5, _omitFieldNames ? '' : 'context', $pb.PbFieldType.OE, defaultOrMaker: PostContext.POST, valueOf: PostContext.valueOf, enumValues: PostContext.values)
    ..e<PostListingType>(10, _omitFieldNames ? '' : 'listingType', $pb.PbFieldType.OE, defaultOrMaker: PostListingType.ALL_ACCESSIBLE_POSTS, valueOf: PostListingType.valueOf, enumValues: PostListingType.values)
    ..a<$core.int>(15, _omitFieldNames ? '' : 'page', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetPostsRequest clone() => GetPostsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetPostsRequest copyWith(void Function(GetPostsRequest) updates) => super.copyWith((message) => updates(message as GetPostsRequest)) as GetPostsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetPostsRequest create() => GetPostsRequest._();
  GetPostsRequest createEmptyInstance() => create();
  static $pb.PbList<GetPostsRequest> createRepeated() => $pb.PbList<GetPostsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetPostsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetPostsRequest>(create);
  static GetPostsRequest? _defaultInstance;

  /// Returns the single post with the given ID.
  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => clearField(1);

  /// Limits results to those by the given author user ID.
  @$pb.TagNumber(2)
  $core.String get authorUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set authorUserId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAuthorUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthorUserId() => clearField(2);

  /// Limits results to those in the given group ID.
  @$pb.TagNumber(3)
  $core.String get groupId => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasGroupId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupId() => clearField(3);

  /// Only supported for depth=2 for now.
  @$pb.TagNumber(4)
  $core.int get replyDepth => $_getIZ(3);
  @$pb.TagNumber(4)
  set replyDepth($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasReplyDepth() => $_has(3);
  @$pb.TagNumber(4)
  void clearReplyDepth() => clearField(4);

  /// Only POST and REPLY are supported for now.
  @$pb.TagNumber(5)
  PostContext get context => $_getN(4);
  @$pb.TagNumber(5)
  set context(PostContext v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasContext() => $_has(4);
  @$pb.TagNumber(5)
  void clearContext() => clearField(5);

  /// The listing type of the request. See `PostListingType` for more info.
  @$pb.TagNumber(10)
  PostListingType get listingType => $_getN(5);
  @$pb.TagNumber(10)
  set listingType(PostListingType v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasListingType() => $_has(5);
  @$pb.TagNumber(10)
  void clearListingType() => clearField(10);

  /// The page of results to return. Defaults to 0.
  @$pb.TagNumber(15)
  $core.int get page => $_getIZ(6);
  @$pb.TagNumber(15)
  set page($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(15)
  $core.bool hasPage() => $_has(6);
  @$pb.TagNumber(15)
  void clearPage() => clearField(15);
}

/// Used for getting posts.
class GetPostsResponse extends $pb.GeneratedMessage {
  factory GetPostsResponse({
    $core.Iterable<Post>? posts,
  }) {
    final $result = create();
    if (posts != null) {
      $result.posts.addAll(posts);
    }
    return $result;
  }
  GetPostsResponse._() : super();
  factory GetPostsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetPostsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetPostsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Post>(1, _omitFieldNames ? '' : 'posts', $pb.PbFieldType.PM, subBuilder: Post.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetPostsResponse clone() => GetPostsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetPostsResponse copyWith(void Function(GetPostsResponse) updates) => super.copyWith((message) => updates(message as GetPostsResponse)) as GetPostsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetPostsResponse create() => GetPostsResponse._();
  GetPostsResponse createEmptyInstance() => create();
  static $pb.PbList<GetPostsResponse> createRepeated() => $pb.PbList<GetPostsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetPostsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetPostsResponse>(create);
  static GetPostsResponse? _defaultInstance;

  /// The posts returned by the request.
  @$pb.TagNumber(1)
  $core.List<Post> get posts => $_getList(0);
}

///  A `Post` is a message that can be posted to the server. Its `visibility`
///  as well as any associated `GroupPost`s and `UserPost`s determine what users
///  see it and where.
///
///  `Post`s are also a fundamental unit of the system. They provide a building block
///  of Visibility and Moderation management that is used throughout Posts, Replies, Events,
///  and Event Instances.
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
    $10.Visibility? visibility,
    $10.Moderation? moderation,
    GroupPost? currentGroupPost,
    $core.Iterable<Post>? replies,
    $9.Timestamp? createdAt,
    $9.Timestamp? updatedAt,
    $9.Timestamp? publishedAt,
    $9.Timestamp? lastActivityAt,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (author != null) {
      $result.author = author;
    }
    if (replyToPostId != null) {
      $result.replyToPostId = replyToPostId;
    }
    if (title != null) {
      $result.title = title;
    }
    if (link != null) {
      $result.link = link;
    }
    if (content != null) {
      $result.content = content;
    }
    if (responseCount != null) {
      $result.responseCount = responseCount;
    }
    if (replyCount != null) {
      $result.replyCount = replyCount;
    }
    if (groupCount != null) {
      $result.groupCount = groupCount;
    }
    if (media != null) {
      $result.media.addAll(media);
    }
    if (mediaGenerated != null) {
      $result.mediaGenerated = mediaGenerated;
    }
    if (embedLink != null) {
      $result.embedLink = embedLink;
    }
    if (shareable != null) {
      $result.shareable = shareable;
    }
    if (context != null) {
      $result.context = context;
    }
    if (visibility != null) {
      $result.visibility = visibility;
    }
    if (moderation != null) {
      $result.moderation = moderation;
    }
    if (currentGroupPost != null) {
      $result.currentGroupPost = currentGroupPost;
    }
    if (replies != null) {
      $result.replies.addAll(replies);
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      $result.updatedAt = updatedAt;
    }
    if (publishedAt != null) {
      $result.publishedAt = publishedAt;
    }
    if (lastActivityAt != null) {
      $result.lastActivityAt = lastActivityAt;
    }
    return $result;
  }
  Post._() : super();
  factory Post.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Post.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

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
    ..e<$10.Visibility>(15, _omitFieldNames ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $10.Visibility.VISIBILITY_UNKNOWN, valueOf: $10.Visibility.valueOf, enumValues: $10.Visibility.values)
    ..e<$10.Moderation>(16, _omitFieldNames ? '' : 'moderation', $pb.PbFieldType.OE, defaultOrMaker: $10.Moderation.MODERATION_UNKNOWN, valueOf: $10.Moderation.valueOf, enumValues: $10.Moderation.values)
    ..aOM<GroupPost>(18, _omitFieldNames ? '' : 'currentGroupPost', subBuilder: GroupPost.create)
    ..pc<Post>(19, _omitFieldNames ? '' : 'replies', $pb.PbFieldType.PM, subBuilder: Post.create)
    ..aOM<$9.Timestamp>(20, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(21, _omitFieldNames ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(22, _omitFieldNames ? '' : 'publishedAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(23, _omitFieldNames ? '' : 'lastActivityAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Post clone() => Post()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Post copyWith(void Function(Post) updates) => super.copyWith((message) => updates(message as Post)) as Post;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Post create() => Post._();
  Post createEmptyInstance() => create();
  static $pb.PbList<Post> createRepeated() => $pb.PbList<Post>();
  @$core.pragma('dart2js:noInline')
  static Post getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Post>(create);
  static Post? _defaultInstance;

  /// Unique ID of the post.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// The author of the post. This is a smaller version of User.
  @$pb.TagNumber(2)
  $4.Author get author => $_getN(1);
  @$pb.TagNumber(2)
  set author($4.Author v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasAuthor() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthor() => clearField(2);
  @$pb.TagNumber(2)
  $4.Author ensureAuthor() => $_ensure(1);

  /// If this is a reply, this is the ID of the post it's replying to.
  @$pb.TagNumber(3)
  $core.String get replyToPostId => $_getSZ(2);
  @$pb.TagNumber(3)
  set replyToPostId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasReplyToPostId() => $_has(2);
  @$pb.TagNumber(3)
  void clearReplyToPostId() => clearField(3);

  /// The title of the post. This is invalid for replies.
  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => clearField(4);

  /// The link of the post. This is invalid for replies.
  @$pb.TagNumber(5)
  $core.String get link => $_getSZ(4);
  @$pb.TagNumber(5)
  set link($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasLink() => $_has(4);
  @$pb.TagNumber(5)
  void clearLink() => clearField(5);

  /// The content of the post. This is required for replies.
  @$pb.TagNumber(6)
  $core.String get content => $_getSZ(5);
  @$pb.TagNumber(6)
  set content($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasContent() => $_has(5);
  @$pb.TagNumber(6)
  void clearContent() => clearField(6);

  /// The number of responses (replies *and* replies to replies, etc.) to this post.
  @$pb.TagNumber(7)
  $core.int get responseCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set responseCount($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasResponseCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearResponseCount() => clearField(7);

  /// The number of *direct* replies to this post.
  @$pb.TagNumber(8)
  $core.int get replyCount => $_getIZ(7);
  @$pb.TagNumber(8)
  set replyCount($core.int v) { $_setSignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasReplyCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearReplyCount() => clearField(8);

  /// The number of groups this post is in.
  @$pb.TagNumber(9)
  $core.int get groupCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set groupCount($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasGroupCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearGroupCount() => clearField(9);

  /// List of Media IDs associated with this post. Order is preserved.
  @$pb.TagNumber(10)
  $core.List<$5.MediaReference> get media => $_getList(9);

  /// Flag indicating whether Media has been generated for this Post.
  /// Currently previews are generated for any Link post.
  @$pb.TagNumber(11)
  $core.bool get mediaGenerated => $_getBF(10);
  @$pb.TagNumber(11)
  set mediaGenerated($core.bool v) { $_setBool(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasMediaGenerated() => $_has(10);
  @$pb.TagNumber(11)
  void clearMediaGenerated() => clearField(11);

  /// Flag indicating
  @$pb.TagNumber(12)
  $core.bool get embedLink => $_getBF(11);
  @$pb.TagNumber(12)
  set embedLink($core.bool v) { $_setBool(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasEmbedLink() => $_has(11);
  @$pb.TagNumber(12)
  void clearEmbedLink() => clearField(12);

  /// Flag indicating a `LIMITED` or `SERVER_PUBLIC` post can be shared with groups and individuals,
  /// and a `DIRECT` post can be shared with individuals.
  @$pb.TagNumber(13)
  $core.bool get shareable => $_getBF(12);
  @$pb.TagNumber(13)
  set shareable($core.bool v) { $_setBool(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasShareable() => $_has(12);
  @$pb.TagNumber(13)
  void clearShareable() => clearField(13);

  /// Context of the Post (`POST`, `REPLY`, `EVENT`, or `EVENT_INSTANCE`.)
  @$pb.TagNumber(14)
  PostContext get context => $_getN(13);
  @$pb.TagNumber(14)
  set context(PostContext v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasContext() => $_has(13);
  @$pb.TagNumber(14)
  void clearContext() => clearField(14);

  /// The visibility of the Post.
  @$pb.TagNumber(15)
  $10.Visibility get visibility => $_getN(14);
  @$pb.TagNumber(15)
  set visibility($10.Visibility v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasVisibility() => $_has(14);
  @$pb.TagNumber(15)
  void clearVisibility() => clearField(15);

  /// The moderation of the Post.
  @$pb.TagNumber(16)
  $10.Moderation get moderation => $_getN(15);
  @$pb.TagNumber(16)
  set moderation($10.Moderation v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasModeration() => $_has(15);
  @$pb.TagNumber(16)
  void clearModeration() => clearField(16);

  /// If the Post was retrieved from GetPosts with a group_id, the GroupPost
  /// metadata may be returned along with the Post.
  @$pb.TagNumber(18)
  GroupPost get currentGroupPost => $_getN(16);
  @$pb.TagNumber(18)
  set currentGroupPost(GroupPost v) { setField(18, v); }
  @$pb.TagNumber(18)
  $core.bool hasCurrentGroupPost() => $_has(16);
  @$pb.TagNumber(18)
  void clearCurrentGroupPost() => clearField(18);
  @$pb.TagNumber(18)
  GroupPost ensureCurrentGroupPost() => $_ensure(16);

  /// Hierarchical replies to this post. There will never be more than `reply_count` replies. However,
  /// there may be fewer than `reply_count` replies if some replies are
  /// hidden by moderation or visibility. Replies are not generally loaded by default, but can be added to Posts
  /// in the frontend.
  @$pb.TagNumber(19)
  $core.List<Post> get replies => $_getList(17);

  /// The time the post was created.
  @$pb.TagNumber(20)
  $9.Timestamp get createdAt => $_getN(18);
  @$pb.TagNumber(20)
  set createdAt($9.Timestamp v) { setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedAt() => $_has(18);
  @$pb.TagNumber(20)
  void clearCreatedAt() => clearField(20);
  @$pb.TagNumber(20)
  $9.Timestamp ensureCreatedAt() => $_ensure(18);

  /// The time the post was last updated.
  @$pb.TagNumber(21)
  $9.Timestamp get updatedAt => $_getN(19);
  @$pb.TagNumber(21)
  set updatedAt($9.Timestamp v) { setField(21, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedAt() => $_has(19);
  @$pb.TagNumber(21)
  void clearUpdatedAt() => clearField(21);
  @$pb.TagNumber(21)
  $9.Timestamp ensureUpdatedAt() => $_ensure(19);

  /// The time the post was published (its visibility first changed to `SERVER_PUBLIC` or `GLOBAL_PUBLIC`).
  @$pb.TagNumber(22)
  $9.Timestamp get publishedAt => $_getN(20);
  @$pb.TagNumber(22)
  set publishedAt($9.Timestamp v) { setField(22, v); }
  @$pb.TagNumber(22)
  $core.bool hasPublishedAt() => $_has(20);
  @$pb.TagNumber(22)
  void clearPublishedAt() => clearField(22);
  @$pb.TagNumber(22)
  $9.Timestamp ensurePublishedAt() => $_ensure(20);

  /// The time the post was last interacted with (replied to, etc.)
  @$pb.TagNumber(23)
  $9.Timestamp get lastActivityAt => $_getN(21);
  @$pb.TagNumber(23)
  set lastActivityAt($9.Timestamp v) { setField(23, v); }
  @$pb.TagNumber(23)
  $core.bool hasLastActivityAt() => $_has(21);
  @$pb.TagNumber(23)
  void clearLastActivityAt() => clearField(23);
  @$pb.TagNumber(23)
  $9.Timestamp ensureLastActivityAt() => $_ensure(21);
}

/// A `GroupPost` is a cross-post of a `Post` to a `Group`. It contains
/// information about the moderation of the post in the group, as well as
/// the time it was cross-posted and the user who did the cross-posting.
class GroupPost extends $pb.GeneratedMessage {
  factory GroupPost({
    $core.String? groupId,
    $core.String? postId,
    $core.String? userId,
    $10.Moderation? groupModeration,
    $9.Timestamp? createdAt,
  }) {
    final $result = create();
    if (groupId != null) {
      $result.groupId = groupId;
    }
    if (postId != null) {
      $result.postId = postId;
    }
    if (userId != null) {
      $result.userId = userId;
    }
    if (groupModeration != null) {
      $result.groupModeration = groupModeration;
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    return $result;
  }
  GroupPost._() : super();
  factory GroupPost.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupPost.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GroupPost', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aOS(2, _omitFieldNames ? '' : 'postId')
    ..aOS(3, _omitFieldNames ? '' : 'userId')
    ..e<$10.Moderation>(4, _omitFieldNames ? '' : 'groupModeration', $pb.PbFieldType.OE, defaultOrMaker: $10.Moderation.MODERATION_UNKNOWN, valueOf: $10.Moderation.valueOf, enumValues: $10.Moderation.values)
    ..aOM<$9.Timestamp>(5, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupPost clone() => GroupPost()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupPost copyWith(void Function(GroupPost) updates) => super.copyWith((message) => updates(message as GroupPost)) as GroupPost;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GroupPost create() => GroupPost._();
  GroupPost createEmptyInstance() => create();
  static $pb.PbList<GroupPost> createRepeated() => $pb.PbList<GroupPost>();
  @$core.pragma('dart2js:noInline')
  static GroupPost getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupPost>(create);
  static GroupPost? _defaultInstance;

  /// The ID of the group this post is in.
  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => clearField(1);

  /// The ID of the post.
  @$pb.TagNumber(2)
  $core.String get postId => $_getSZ(1);
  @$pb.TagNumber(2)
  set postId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPostId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPostId() => clearField(2);

  /// The ID of the user who cross-posted the post.
  @$pb.TagNumber(3)
  $core.String get userId => $_getSZ(2);
  @$pb.TagNumber(3)
  set userId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserId() => clearField(3);

  /// The moderation of the post in the group.
  @$pb.TagNumber(4)
  $10.Moderation get groupModeration => $_getN(3);
  @$pb.TagNumber(4)
  set groupModeration($10.Moderation v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasGroupModeration() => $_has(3);
  @$pb.TagNumber(4)
  void clearGroupModeration() => clearField(4);

  /// The time the post was cross-posted.
  @$pb.TagNumber(5)
  $9.Timestamp get createdAt => $_getN(4);
  @$pb.TagNumber(5)
  set createdAt($9.Timestamp v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasCreatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAt() => clearField(5);
  @$pb.TagNumber(5)
  $9.Timestamp ensureCreatedAt() => $_ensure(4);
}

/// A `UserPost` is a "direct share" of a `Post` to a `User`. Currently unused/unimplemented.
/// See also: [`DIRECT` `Visibility`](#jonline-Visibility).
class UserPost extends $pb.GeneratedMessage {
  factory UserPost({
    $core.String? userId,
    $core.String? postId,
    $9.Timestamp? createdAt,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (postId != null) {
      $result.postId = postId;
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    return $result;
  }
  UserPost._() : super();
  factory UserPost.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserPost.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UserPost', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'postId')
    ..aOM<$9.Timestamp>(3, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UserPost clone() => UserPost()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UserPost copyWith(void Function(UserPost) updates) => super.copyWith((message) => updates(message as UserPost)) as UserPost;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserPost create() => UserPost._();
  UserPost createEmptyInstance() => create();
  static $pb.PbList<UserPost> createRepeated() => $pb.PbList<UserPost>();
  @$core.pragma('dart2js:noInline')
  static UserPost getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserPost>(create);
  static UserPost? _defaultInstance;

  /// The ID of the user the post is shared with.
  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  /// The ID of the post shared.
  @$pb.TagNumber(2)
  $core.String get postId => $_getSZ(1);
  @$pb.TagNumber(2)
  set postId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPostId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPostId() => clearField(2);

  /// The time the post was shared.
  @$pb.TagNumber(3)
  $9.Timestamp get createdAt => $_getN(2);
  @$pb.TagNumber(3)
  set createdAt($9.Timestamp v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasCreatedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedAt() => clearField(3);
  @$pb.TagNumber(3)
  $9.Timestamp ensureCreatedAt() => $_ensure(2);
}

/// Used for getting context about `GroupPost`s of an existing `Post`.
class GetGroupPostsRequest extends $pb.GeneratedMessage {
  factory GetGroupPostsRequest({
    $core.String? postId,
    $core.String? groupId,
  }) {
    final $result = create();
    if (postId != null) {
      $result.postId = postId;
    }
    if (groupId != null) {
      $result.groupId = groupId;
    }
    return $result;
  }
  GetGroupPostsRequest._() : super();
  factory GetGroupPostsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetGroupPostsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetGroupPostsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'postId')
    ..aOS(2, _omitFieldNames ? '' : 'groupId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetGroupPostsRequest clone() => GetGroupPostsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetGroupPostsRequest copyWith(void Function(GetGroupPostsRequest) updates) => super.copyWith((message) => updates(message as GetGroupPostsRequest)) as GetGroupPostsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetGroupPostsRequest create() => GetGroupPostsRequest._();
  GetGroupPostsRequest createEmptyInstance() => create();
  static $pb.PbList<GetGroupPostsRequest> createRepeated() => $pb.PbList<GetGroupPostsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetGroupPostsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetGroupPostsRequest>(create);
  static GetGroupPostsRequest? _defaultInstance;

  /// The ID of the post to get `GroupPost`s for.
  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => clearField(1);

  /// The ID of the group to get `GroupPost`s for.
  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupId() => clearField(2);
}

/// Used for getting context about `GroupPost`s of an existing `Post`.
class GetGroupPostsResponse extends $pb.GeneratedMessage {
  factory GetGroupPostsResponse({
    $core.Iterable<GroupPost>? groupPosts,
  }) {
    final $result = create();
    if (groupPosts != null) {
      $result.groupPosts.addAll(groupPosts);
    }
    return $result;
  }
  GetGroupPostsResponse._() : super();
  factory GetGroupPostsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetGroupPostsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetGroupPostsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<GroupPost>(1, _omitFieldNames ? '' : 'groupPosts', $pb.PbFieldType.PM, subBuilder: GroupPost.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetGroupPostsResponse clone() => GetGroupPostsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetGroupPostsResponse copyWith(void Function(GetGroupPostsResponse) updates) => super.copyWith((message) => updates(message as GetGroupPostsResponse)) as GetGroupPostsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetGroupPostsResponse create() => GetGroupPostsResponse._();
  GetGroupPostsResponse createEmptyInstance() => create();
  static $pb.PbList<GetGroupPostsResponse> createRepeated() => $pb.PbList<GetGroupPostsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetGroupPostsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetGroupPostsResponse>(create);
  static GetGroupPostsResponse? _defaultInstance;

  /// The `GroupPost`s for the given `Post` or `Group`.
  @$pb.TagNumber(1)
  $core.List<GroupPost> get groupPosts => $_getList(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
