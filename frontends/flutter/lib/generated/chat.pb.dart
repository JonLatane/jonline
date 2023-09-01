//
//  Generated code. Do not modify.
//  source: chat.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'posts.pb.dart' as $7;

/// User-to-user (or multi-user) conversation.
class Conversation extends $pb.GeneratedMessage {
  factory Conversation({
    $core.String? id,
    $core.String? name,
    $core.Iterable<$core.String>? userIds,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    if (userIds != null) {
      $result.userIds.addAll(userIds);
    }
    return $result;
  }
  Conversation._() : super();
  factory Conversation.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Conversation.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Conversation', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..pPS(3, _omitFieldNames ? '' : 'userIds')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Conversation clone() => Conversation()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Conversation copyWith(void Function(Conversation) updates) => super.copyWith((message) => updates(message as Conversation)) as Conversation;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Conversation create() => Conversation._();
  Conversation createEmptyInstance() => create();
  static $pb.PbList<Conversation> createRepeated() => $pb.PbList<Conversation>();
  @$core.pragma('dart2js:noInline')
  static Conversation getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Conversation>(create);
  static Conversation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get userIds => $_getList(2);
}

class ConversationPost extends $pb.GeneratedMessage {
  factory ConversationPost({
    $core.String? conversationId,
    $core.String? postId,
  }) {
    final $result = create();
    if (conversationId != null) {
      $result.conversationId = conversationId;
    }
    if (postId != null) {
      $result.postId = postId;
    }
    return $result;
  }
  ConversationPost._() : super();
  factory ConversationPost.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConversationPost.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConversationPost', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOS(2, _omitFieldNames ? '' : 'postId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConversationPost clone() => ConversationPost()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConversationPost copyWith(void Function(ConversationPost) updates) => super.copyWith((message) => updates(message as ConversationPost)) as ConversationPost;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConversationPost create() => ConversationPost._();
  ConversationPost createEmptyInstance() => create();
  static $pb.PbList<ConversationPost> createRepeated() => $pb.PbList<ConversationPost>();
  @$core.pragma('dart2js:noInline')
  static ConversationPost getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConversationPost>(create);
  static ConversationPost? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get postId => $_getSZ(1);
  @$pb.TagNumber(2)
  set postId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPostId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPostId() => clearField(2);
}

/// Conversation for a Group. Functionally 1:1 with its Group, and not actually
/// stored in the database. Just presented as an API type for clarity and consistency.
class GroupConversation extends $pb.GeneratedMessage {
  factory GroupConversation({
    $core.String? groupId,
  }) {
    final $result = create();
    if (groupId != null) {
      $result.groupId = groupId;
    }
    return $result;
  }
  GroupConversation._() : super();
  factory GroupConversation.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupConversation.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GroupConversation', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupConversation clone() => GroupConversation()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupConversation copyWith(void Function(GroupConversation) updates) => super.copyWith((message) => updates(message as GroupConversation)) as GroupConversation;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GroupConversation create() => GroupConversation._();
  GroupConversation createEmptyInstance() => create();
  static $pb.PbList<GroupConversation> createRepeated() => $pb.PbList<GroupConversation>();
  @$core.pragma('dart2js:noInline')
  static GroupConversation getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupConversation>(create);
  static GroupConversation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => clearField(1);
}

class GroupConversationPost extends $pb.GeneratedMessage {
  factory GroupConversationPost({
    $core.String? groupId,
    $core.String? postId,
  }) {
    final $result = create();
    if (groupId != null) {
      $result.groupId = groupId;
    }
    if (postId != null) {
      $result.postId = postId;
    }
    return $result;
  }
  GroupConversationPost._() : super();
  factory GroupConversationPost.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupConversationPost.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GroupConversationPost', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aOS(2, _omitFieldNames ? '' : 'postId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupConversationPost clone() => GroupConversationPost()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupConversationPost copyWith(void Function(GroupConversationPost) updates) => super.copyWith((message) => updates(message as GroupConversationPost)) as GroupConversationPost;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GroupConversationPost create() => GroupConversationPost._();
  GroupConversationPost createEmptyInstance() => create();
  static $pb.PbList<GroupConversationPost> createRepeated() => $pb.PbList<GroupConversationPost>();
  @$core.pragma('dart2js:noInline')
  static GroupConversationPost getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupConversationPost>(create);
  static GroupConversationPost? _defaultInstance;

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
}

class CreateConversationPostRequest extends $pb.GeneratedMessage {
  factory CreateConversationPostRequest({
    $core.String? conversationId,
    $7.Post? post,
  }) {
    final $result = create();
    if (conversationId != null) {
      $result.conversationId = conversationId;
    }
    if (post != null) {
      $result.post = post;
    }
    return $result;
  }
  CreateConversationPostRequest._() : super();
  factory CreateConversationPostRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateConversationPostRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CreateConversationPostRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOM<$7.Post>(2, _omitFieldNames ? '' : 'post', subBuilder: $7.Post.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateConversationPostRequest clone() => CreateConversationPostRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateConversationPostRequest copyWith(void Function(CreateConversationPostRequest) updates) => super.copyWith((message) => updates(message as CreateConversationPostRequest)) as CreateConversationPostRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateConversationPostRequest create() => CreateConversationPostRequest._();
  CreateConversationPostRequest createEmptyInstance() => create();
  static $pb.PbList<CreateConversationPostRequest> createRepeated() => $pb.PbList<CreateConversationPostRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateConversationPostRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateConversationPostRequest>(create);
  static CreateConversationPostRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => clearField(1);

  @$pb.TagNumber(2)
  $7.Post get post => $_getN(1);
  @$pb.TagNumber(2)
  set post($7.Post v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasPost() => $_has(1);
  @$pb.TagNumber(2)
  void clearPost() => clearField(2);
  @$pb.TagNumber(2)
  $7.Post ensurePost() => $_ensure(1);
}

class CreateGroupConversationPostRequest extends $pb.GeneratedMessage {
  factory CreateGroupConversationPostRequest({
    $core.String? groupId,
    $7.Post? post,
  }) {
    final $result = create();
    if (groupId != null) {
      $result.groupId = groupId;
    }
    if (post != null) {
      $result.post = post;
    }
    return $result;
  }
  CreateGroupConversationPostRequest._() : super();
  factory CreateGroupConversationPostRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateGroupConversationPostRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CreateGroupConversationPostRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aOM<$7.Post>(2, _omitFieldNames ? '' : 'post', subBuilder: $7.Post.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateGroupConversationPostRequest clone() => CreateGroupConversationPostRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateGroupConversationPostRequest copyWith(void Function(CreateGroupConversationPostRequest) updates) => super.copyWith((message) => updates(message as CreateGroupConversationPostRequest)) as CreateGroupConversationPostRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateGroupConversationPostRequest create() => CreateGroupConversationPostRequest._();
  CreateGroupConversationPostRequest createEmptyInstance() => create();
  static $pb.PbList<CreateGroupConversationPostRequest> createRepeated() => $pb.PbList<CreateGroupConversationPostRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateGroupConversationPostRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateGroupConversationPostRequest>(create);
  static CreateGroupConversationPostRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => clearField(1);

  @$pb.TagNumber(2)
  $7.Post get post => $_getN(1);
  @$pb.TagNumber(2)
  set post($7.Post v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasPost() => $_has(1);
  @$pb.TagNumber(2)
  void clearPost() => clearField(2);
  @$pb.TagNumber(2)
  $7.Post ensurePost() => $_ensure(1);
}

class GetConversationsRequest extends $pb.GeneratedMessage {
  factory GetConversationsRequest({
    $core.int? page,
  }) {
    final $result = create();
    if (page != null) {
      $result.page = page;
    }
    return $result;
  }
  GetConversationsRequest._() : super();
  factory GetConversationsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetConversationsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetConversationsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'page', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetConversationsRequest clone() => GetConversationsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetConversationsRequest copyWith(void Function(GetConversationsRequest) updates) => super.copyWith((message) => updates(message as GetConversationsRequest)) as GetConversationsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetConversationsRequest create() => GetConversationsRequest._();
  GetConversationsRequest createEmptyInstance() => create();
  static $pb.PbList<GetConversationsRequest> createRepeated() => $pb.PbList<GetConversationsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetConversationsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetConversationsRequest>(create);
  static GetConversationsRequest? _defaultInstance;

  @$pb.TagNumber(10)
  $core.int get page => $_getIZ(0);
  @$pb.TagNumber(10)
  set page($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(10)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(10)
  void clearPage() => clearField(10);
}

class GetConversationsResponse extends $pb.GeneratedMessage {
  factory GetConversationsResponse({
    $core.Iterable<Conversation>? conversations,
  }) {
    final $result = create();
    if (conversations != null) {
      $result.conversations.addAll(conversations);
    }
    return $result;
  }
  GetConversationsResponse._() : super();
  factory GetConversationsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetConversationsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetConversationsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Conversation>(1, _omitFieldNames ? '' : 'conversations', $pb.PbFieldType.PM, subBuilder: Conversation.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetConversationsResponse clone() => GetConversationsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetConversationsResponse copyWith(void Function(GetConversationsResponse) updates) => super.copyWith((message) => updates(message as GetConversationsResponse)) as GetConversationsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetConversationsResponse create() => GetConversationsResponse._();
  GetConversationsResponse createEmptyInstance() => create();
  static $pb.PbList<GetConversationsResponse> createRepeated() => $pb.PbList<GetConversationsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetConversationsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetConversationsResponse>(create);
  static GetConversationsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Conversation> get conversations => $_getList(0);
}

enum GetConversationRequest_RequestedId {
  conversationId, 
  groupId, 
  notSet
}

class GetConversationRequest extends $pb.GeneratedMessage {
  factory GetConversationRequest({
    $core.String? conversationId,
    $core.String? groupId,
    $core.int? page,
  }) {
    final $result = create();
    if (conversationId != null) {
      $result.conversationId = conversationId;
    }
    if (groupId != null) {
      $result.groupId = groupId;
    }
    if (page != null) {
      $result.page = page;
    }
    return $result;
  }
  GetConversationRequest._() : super();
  factory GetConversationRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetConversationRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, GetConversationRequest_RequestedId> _GetConversationRequest_RequestedIdByTag = {
    1 : GetConversationRequest_RequestedId.conversationId,
    2 : GetConversationRequest_RequestedId.groupId,
    0 : GetConversationRequest_RequestedId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetConversationRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOS(2, _omitFieldNames ? '' : 'groupId')
    ..a<$core.int>(10, _omitFieldNames ? '' : 'page', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetConversationRequest clone() => GetConversationRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetConversationRequest copyWith(void Function(GetConversationRequest) updates) => super.copyWith((message) => updates(message as GetConversationRequest)) as GetConversationRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetConversationRequest create() => GetConversationRequest._();
  GetConversationRequest createEmptyInstance() => create();
  static $pb.PbList<GetConversationRequest> createRepeated() => $pb.PbList<GetConversationRequest>();
  @$core.pragma('dart2js:noInline')
  static GetConversationRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetConversationRequest>(create);
  static GetConversationRequest? _defaultInstance;

  GetConversationRequest_RequestedId whichRequestedId() => _GetConversationRequest_RequestedIdByTag[$_whichOneof(0)]!;
  void clearRequestedId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupId() => clearField(2);

  @$pb.TagNumber(10)
  $core.int get page => $_getIZ(2);
  @$pb.TagNumber(10)
  set page($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(10)
  $core.bool hasPage() => $_has(2);
  @$pb.TagNumber(10)
  void clearPage() => clearField(10);
}

class GetConversationResponse extends $pb.GeneratedMessage {
  factory GetConversationResponse({
    $core.Iterable<$7.Post>? conversation,
  }) {
    final $result = create();
    if (conversation != null) {
      $result.conversation.addAll(conversation);
    }
    return $result;
  }
  GetConversationResponse._() : super();
  factory GetConversationResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetConversationResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetConversationResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<$7.Post>(1, _omitFieldNames ? '' : 'conversation', $pb.PbFieldType.PM, subBuilder: $7.Post.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetConversationResponse clone() => GetConversationResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetConversationResponse copyWith(void Function(GetConversationResponse) updates) => super.copyWith((message) => updates(message as GetConversationResponse)) as GetConversationResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetConversationResponse create() => GetConversationResponse._();
  GetConversationResponse createEmptyInstance() => create();
  static $pb.PbList<GetConversationResponse> createRepeated() => $pb.PbList<GetConversationResponse>();
  @$core.pragma('dart2js:noInline')
  static GetConversationResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetConversationResponse>(create);
  static GetConversationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$7.Post> get conversation => $_getList(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
