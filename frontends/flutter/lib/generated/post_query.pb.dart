///
//  Generated code. Do not modify.
//  source: post_query.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PostQuery_SinglePostQuery extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PostQuery.SinglePostQuery', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'postId')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'includePreview')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'responseDepth', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'responseLimit', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  PostQuery_SinglePostQuery._() : super();
  factory PostQuery_SinglePostQuery({
    $core.String? postId,
    $core.bool? includePreview,
    $core.int? responseDepth,
    $core.int? responseLimit,
  }) {
    final _result = create();
    if (postId != null) {
      _result.postId = postId;
    }
    if (includePreview != null) {
      _result.includePreview = includePreview;
    }
    if (responseDepth != null) {
      _result.responseDepth = responseDepth;
    }
    if (responseLimit != null) {
      _result.responseLimit = responseLimit;
    }
    return _result;
  }
  factory PostQuery_SinglePostQuery.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PostQuery_SinglePostQuery.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PostQuery_SinglePostQuery clone() => PostQuery_SinglePostQuery()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PostQuery_SinglePostQuery copyWith(void Function(PostQuery_SinglePostQuery) updates) => super.copyWith((message) => updates(message as PostQuery_SinglePostQuery)) as PostQuery_SinglePostQuery; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PostQuery_SinglePostQuery create() => PostQuery_SinglePostQuery._();
  PostQuery_SinglePostQuery createEmptyInstance() => create();
  static $pb.PbList<PostQuery_SinglePostQuery> createRepeated() => $pb.PbList<PostQuery_SinglePostQuery>();
  @$core.pragma('dart2js:noInline')
  static PostQuery_SinglePostQuery getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PostQuery_SinglePostQuery>(create);
  static PostQuery_SinglePostQuery? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get includePreview => $_getBF(1);
  @$pb.TagNumber(2)
  set includePreview($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIncludePreview() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncludePreview() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get responseDepth => $_getIZ(2);
  @$pb.TagNumber(3)
  set responseDepth($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasResponseDepth() => $_has(2);
  @$pb.TagNumber(3)
  void clearResponseDepth() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get responseLimit => $_getIZ(3);
  @$pb.TagNumber(4)
  set responseLimit($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasResponseLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearResponseLimit() => clearField(4);
}

class PostQuery_PostRepliesQuery extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PostQuery.PostRepliesQuery', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'postId')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'depth', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'limit', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  PostQuery_PostRepliesQuery._() : super();
  factory PostQuery_PostRepliesQuery({
    $core.String? postId,
    $core.int? depth,
    $core.int? limit,
  }) {
    final _result = create();
    if (postId != null) {
      _result.postId = postId;
    }
    if (depth != null) {
      _result.depth = depth;
    }
    if (limit != null) {
      _result.limit = limit;
    }
    return _result;
  }
  factory PostQuery_PostRepliesQuery.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PostQuery_PostRepliesQuery.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PostQuery_PostRepliesQuery clone() => PostQuery_PostRepliesQuery()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PostQuery_PostRepliesQuery copyWith(void Function(PostQuery_PostRepliesQuery) updates) => super.copyWith((message) => updates(message as PostQuery_PostRepliesQuery)) as PostQuery_PostRepliesQuery; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PostQuery_PostRepliesQuery create() => PostQuery_PostRepliesQuery._();
  PostQuery_PostRepliesQuery createEmptyInstance() => create();
  static $pb.PbList<PostQuery_PostRepliesQuery> createRepeated() => $pb.PbList<PostQuery_PostRepliesQuery>();
  @$core.pragma('dart2js:noInline')
  static PostQuery_PostRepliesQuery getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PostQuery_PostRepliesQuery>(create);
  static PostQuery_PostRepliesQuery? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get depth => $_getIZ(1);
  @$pb.TagNumber(2)
  set depth($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDepth() => $_has(1);
  @$pb.TagNumber(2)
  void clearDepth() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => clearField(3);
}

class PostQuery_AuthorQuery extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PostQuery.AuthorQuery', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'limit', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  PostQuery_AuthorQuery._() : super();
  factory PostQuery_AuthorQuery({
    $core.String? userId,
    $core.int? limit,
  }) {
    final _result = create();
    if (userId != null) {
      _result.userId = userId;
    }
    if (limit != null) {
      _result.limit = limit;
    }
    return _result;
  }
  factory PostQuery_AuthorQuery.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PostQuery_AuthorQuery.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PostQuery_AuthorQuery clone() => PostQuery_AuthorQuery()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PostQuery_AuthorQuery copyWith(void Function(PostQuery_AuthorQuery) updates) => super.copyWith((message) => updates(message as PostQuery_AuthorQuery)) as PostQuery_AuthorQuery; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PostQuery_AuthorQuery create() => PostQuery_AuthorQuery._();
  PostQuery_AuthorQuery createEmptyInstance() => create();
  static $pb.PbList<PostQuery_AuthorQuery> createRepeated() => $pb.PbList<PostQuery_AuthorQuery>();
  @$core.pragma('dart2js:noInline')
  static PostQuery_AuthorQuery getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PostQuery_AuthorQuery>(create);
  static PostQuery_AuthorQuery? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => clearField(2);
}

enum PostQuery_Query {
  singlePost, 
  postReplies, 
  author, 
  notSet
}

class PostQuery extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, PostQuery_Query> _PostQuery_QueryByTag = {
    1 : PostQuery_Query.singlePost,
    2 : PostQuery_Query.postReplies,
    3 : PostQuery_Query.author,
    0 : PostQuery_Query.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PostQuery', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<PostQuery_SinglePostQuery>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'singlePost', subBuilder: PostQuery_SinglePostQuery.create)
    ..aOM<PostQuery_PostRepliesQuery>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'postReplies', subBuilder: PostQuery_PostRepliesQuery.create)
    ..aOM<PostQuery_AuthorQuery>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'author', subBuilder: PostQuery_AuthorQuery.create)
    ..hasRequiredFields = false
  ;

  PostQuery._() : super();
  factory PostQuery({
    PostQuery_SinglePostQuery? singlePost,
    PostQuery_PostRepliesQuery? postReplies,
    PostQuery_AuthorQuery? author,
  }) {
    final _result = create();
    if (singlePost != null) {
      _result.singlePost = singlePost;
    }
    if (postReplies != null) {
      _result.postReplies = postReplies;
    }
    if (author != null) {
      _result.author = author;
    }
    return _result;
  }
  factory PostQuery.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PostQuery.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PostQuery clone() => PostQuery()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PostQuery copyWith(void Function(PostQuery) updates) => super.copyWith((message) => updates(message as PostQuery)) as PostQuery; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PostQuery create() => PostQuery._();
  PostQuery createEmptyInstance() => create();
  static $pb.PbList<PostQuery> createRepeated() => $pb.PbList<PostQuery>();
  @$core.pragma('dart2js:noInline')
  static PostQuery getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PostQuery>(create);
  static PostQuery? _defaultInstance;

  PostQuery_Query whichQuery() => _PostQuery_QueryByTag[$_whichOneof(0)]!;
  void clearQuery() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  PostQuery_SinglePostQuery get singlePost => $_getN(0);
  @$pb.TagNumber(1)
  set singlePost(PostQuery_SinglePostQuery v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSinglePost() => $_has(0);
  @$pb.TagNumber(1)
  void clearSinglePost() => clearField(1);
  @$pb.TagNumber(1)
  PostQuery_SinglePostQuery ensureSinglePost() => $_ensure(0);

  @$pb.TagNumber(2)
  PostQuery_PostRepliesQuery get postReplies => $_getN(1);
  @$pb.TagNumber(2)
  set postReplies(PostQuery_PostRepliesQuery v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasPostReplies() => $_has(1);
  @$pb.TagNumber(2)
  void clearPostReplies() => clearField(2);
  @$pb.TagNumber(2)
  PostQuery_PostRepliesQuery ensurePostReplies() => $_ensure(1);

  @$pb.TagNumber(3)
  PostQuery_AuthorQuery get author => $_getN(2);
  @$pb.TagNumber(3)
  set author(PostQuery_AuthorQuery v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasAuthor() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthor() => clearField(3);
  @$pb.TagNumber(3)
  PostQuery_AuthorQuery ensureAuthor() => $_ensure(2);
}

