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

import 'google/protobuf/timestamp.pb.dart' as $9;
import 'posts.pbenum.dart';
import 'visibility_moderation.pbenum.dart' as $11;

export 'posts.pbenum.dart';

class GetPostsRequest extends $pb.GeneratedMessage {
  factory GetPostsRequest() => create();
  GetPostsRequest._() : super();
  factory GetPostsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetPostsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetPostsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'postId')
    ..aOS(2, _omitFieldNames ? '' : 'authorUserId')
    ..aOS(3, _omitFieldNames ? '' : 'groupId')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'replyDepth', $pb.PbFieldType.OU3)
    ..e<PostListingType>(10, _omitFieldNames ? '' : 'listingType', $pb.PbFieldType.OE, defaultOrMaker: PostListingType.PUBLIC_POSTS, valueOf: PostListingType.valueOf, enumValues: PostListingType.values)
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

  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get authorUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set authorUserId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAuthorUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthorUserId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get groupId => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasGroupId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupId() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get replyDepth => $_getIZ(3);
  @$pb.TagNumber(4)
  set replyDepth($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasReplyDepth() => $_has(3);
  @$pb.TagNumber(4)
  void clearReplyDepth() => clearField(4);

  @$pb.TagNumber(10)
  PostListingType get listingType => $_getN(4);
  @$pb.TagNumber(10)
  set listingType(PostListingType v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasListingType() => $_has(4);
  @$pb.TagNumber(10)
  void clearListingType() => clearField(10);

  @$pb.TagNumber(15)
  $core.int get page => $_getIZ(5);
  @$pb.TagNumber(15)
  set page($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(15)
  $core.bool hasPage() => $_has(5);
  @$pb.TagNumber(15)
  void clearPage() => clearField(15);
}

class GetPostsResponse extends $pb.GeneratedMessage {
  factory GetPostsResponse() => create();
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

  @$pb.TagNumber(1)
  $core.List<Post> get posts => $_getList(0);
}

class Post extends $pb.GeneratedMessage {
  factory Post() => create();
  Post._() : super();
  factory Post.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Post.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Post', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<Author>(2, _omitFieldNames ? '' : 'author', subBuilder: Author.create)
    ..aOS(3, _omitFieldNames ? '' : 'replyToPostId')
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'link')
    ..aOS(6, _omitFieldNames ? '' : 'content')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'responseCount', $pb.PbFieldType.O3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'replyCount', $pb.PbFieldType.O3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'groupCount', $pb.PbFieldType.O3)
    ..pPS(10, _omitFieldNames ? '' : 'media')
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

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  Author get author => $_getN(1);
  @$pb.TagNumber(2)
  set author(Author v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasAuthor() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthor() => clearField(2);
  @$pb.TagNumber(2)
  Author ensureAuthor() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get replyToPostId => $_getSZ(2);
  @$pb.TagNumber(3)
  set replyToPostId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasReplyToPostId() => $_has(2);
  @$pb.TagNumber(3)
  void clearReplyToPostId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get link => $_getSZ(4);
  @$pb.TagNumber(5)
  set link($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasLink() => $_has(4);
  @$pb.TagNumber(5)
  void clearLink() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get content => $_getSZ(5);
  @$pb.TagNumber(6)
  set content($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasContent() => $_has(5);
  @$pb.TagNumber(6)
  void clearContent() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get responseCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set responseCount($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasResponseCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearResponseCount() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get replyCount => $_getIZ(7);
  @$pb.TagNumber(8)
  set replyCount($core.int v) { $_setSignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasReplyCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearReplyCount() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get groupCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set groupCount($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasGroupCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearGroupCount() => clearField(9);

  @$pb.TagNumber(10)
  $core.List<$core.String> get media => $_getList(9);

  @$pb.TagNumber(11)
  $core.bool get mediaGenerated => $_getBF(10);
  @$pb.TagNumber(11)
  set mediaGenerated($core.bool v) { $_setBool(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasMediaGenerated() => $_has(10);
  @$pb.TagNumber(11)
  void clearMediaGenerated() => clearField(11);

  @$pb.TagNumber(12)
  $core.bool get embedLink => $_getBF(11);
  @$pb.TagNumber(12)
  set embedLink($core.bool v) { $_setBool(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasEmbedLink() => $_has(11);
  @$pb.TagNumber(12)
  void clearEmbedLink() => clearField(12);

  @$pb.TagNumber(13)
  $core.bool get shareable => $_getBF(12);
  @$pb.TagNumber(13)
  set shareable($core.bool v) { $_setBool(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasShareable() => $_has(12);
  @$pb.TagNumber(13)
  void clearShareable() => clearField(13);

  @$pb.TagNumber(14)
  PostContext get context => $_getN(13);
  @$pb.TagNumber(14)
  set context(PostContext v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasContext() => $_has(13);
  @$pb.TagNumber(14)
  void clearContext() => clearField(14);

  @$pb.TagNumber(15)
  $11.Visibility get visibility => $_getN(14);
  @$pb.TagNumber(15)
  set visibility($11.Visibility v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasVisibility() => $_has(14);
  @$pb.TagNumber(15)
  void clearVisibility() => clearField(15);

  @$pb.TagNumber(16)
  $11.Moderation get moderation => $_getN(15);
  @$pb.TagNumber(16)
  set moderation($11.Moderation v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasModeration() => $_has(15);
  @$pb.TagNumber(16)
  void clearModeration() => clearField(16);

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

  @$pb.TagNumber(19)
  $core.List<Post> get replies => $_getList(17);

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

class Author extends $pb.GeneratedMessage {
  factory Author() => create();
  Author._() : super();
  factory Author.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Author.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Author', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Author clone() => Author()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Author copyWith(void Function(Author) updates) => super.copyWith((message) => updates(message as Author)) as Author;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Author create() => Author._();
  Author createEmptyInstance() => create();
  static $pb.PbList<Author> createRepeated() => $pb.PbList<Author>();
  @$core.pragma('dart2js:noInline')
  static Author getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Author>(create);
  static Author? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => clearField(2);
}

class GroupPost extends $pb.GeneratedMessage {
  factory GroupPost() => create();
  GroupPost._() : super();
  factory GroupPost.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupPost.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GroupPost', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aOS(2, _omitFieldNames ? '' : 'postId')
    ..aOS(3, _omitFieldNames ? '' : 'userId')
    ..e<$11.Moderation>(4, _omitFieldNames ? '' : 'groupModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
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

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get postId => $_getSZ(1);
  @$pb.TagNumber(2)
  set postId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPostId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPostId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get userId => $_getSZ(2);
  @$pb.TagNumber(3)
  set userId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserId() => clearField(3);

  @$pb.TagNumber(4)
  $11.Moderation get groupModeration => $_getN(3);
  @$pb.TagNumber(4)
  set groupModeration($11.Moderation v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasGroupModeration() => $_has(3);
  @$pb.TagNumber(4)
  void clearGroupModeration() => clearField(4);

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

class UserPost extends $pb.GeneratedMessage {
  factory UserPost() => create();
  UserPost._() : super();
  factory UserPost.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserPost.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UserPost', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
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

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => clearField(2);

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

class GetGroupPostsRequest extends $pb.GeneratedMessage {
  factory GetGroupPostsRequest() => create();
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

  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupId() => clearField(2);
}

class GetGroupPostsResponse extends $pb.GeneratedMessage {
  factory GetGroupPostsResponse() => create();
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

  @$pb.TagNumber(1)
  $core.List<GroupPost> get groupPosts => $_getList(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
