///
//  Generated code. Do not modify.
//  source: chat.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'posts.pb.dart' as $7;

class Conversation extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Conversation', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..pPS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userIds')
    ..hasRequiredFields = false
  ;

  Conversation._() : super();
  factory Conversation({
    $core.String? id,
    $core.String? name,
    $core.Iterable<$core.String>? userIds,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (userIds != null) {
      _result.userIds.addAll(userIds);
    }
    return _result;
  }
  factory Conversation.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Conversation.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Conversation clone() => Conversation()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Conversation copyWith(void Function(Conversation) updates) => super.copyWith((message) => updates(message as Conversation)) as Conversation; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ConversationPost', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'conversationId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'postId')
    ..hasRequiredFields = false
  ;

  ConversationPost._() : super();
  factory ConversationPost({
    $core.String? conversationId,
    $core.String? postId,
  }) {
    final _result = create();
    if (conversationId != null) {
      _result.conversationId = conversationId;
    }
    if (postId != null) {
      _result.postId = postId;
    }
    return _result;
  }
  factory ConversationPost.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConversationPost.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConversationPost clone() => ConversationPost()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConversationPost copyWith(void Function(ConversationPost) updates) => super.copyWith((message) => updates(message as ConversationPost)) as ConversationPost; // ignore: deprecated_member_use
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

class GroupConversation extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GroupConversation', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..hasRequiredFields = false
  ;

  GroupConversation._() : super();
  factory GroupConversation({
    $core.String? groupId,
  }) {
    final _result = create();
    if (groupId != null) {
      _result.groupId = groupId;
    }
    return _result;
  }
  factory GroupConversation.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupConversation.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupConversation clone() => GroupConversation()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupConversation copyWith(void Function(GroupConversation) updates) => super.copyWith((message) => updates(message as GroupConversation)) as GroupConversation; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GroupConversationPost', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'postId')
    ..hasRequiredFields = false
  ;

  GroupConversationPost._() : super();
  factory GroupConversationPost({
    $core.String? groupId,
    $core.String? postId,
  }) {
    final _result = create();
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (postId != null) {
      _result.postId = postId;
    }
    return _result;
  }
  factory GroupConversationPost.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupConversationPost.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupConversationPost clone() => GroupConversationPost()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupConversationPost copyWith(void Function(GroupConversationPost) updates) => super.copyWith((message) => updates(message as GroupConversationPost)) as GroupConversationPost; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateConversationPostRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'conversationId')
    ..aOM<$7.Post>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'post', subBuilder: $7.Post.create)
    ..hasRequiredFields = false
  ;

  CreateConversationPostRequest._() : super();
  factory CreateConversationPostRequest({
    $core.String? conversationId,
    $7.Post? post,
  }) {
    final _result = create();
    if (conversationId != null) {
      _result.conversationId = conversationId;
    }
    if (post != null) {
      _result.post = post;
    }
    return _result;
  }
  factory CreateConversationPostRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateConversationPostRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateConversationPostRequest clone() => CreateConversationPostRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateConversationPostRequest copyWith(void Function(CreateConversationPostRequest) updates) => super.copyWith((message) => updates(message as CreateConversationPostRequest)) as CreateConversationPostRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateGroupConversationPostRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..aOM<$7.Post>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'post', subBuilder: $7.Post.create)
    ..hasRequiredFields = false
  ;

  CreateGroupConversationPostRequest._() : super();
  factory CreateGroupConversationPostRequest({
    $core.String? groupId,
    $7.Post? post,
  }) {
    final _result = create();
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (post != null) {
      _result.post = post;
    }
    return _result;
  }
  factory CreateGroupConversationPostRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateGroupConversationPostRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateGroupConversationPostRequest clone() => CreateGroupConversationPostRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateGroupConversationPostRequest copyWith(void Function(CreateGroupConversationPostRequest) updates) => super.copyWith((message) => updates(message as CreateGroupConversationPostRequest)) as CreateGroupConversationPostRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetConversationsRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..a<$core.int>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'page', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  GetConversationsRequest._() : super();
  factory GetConversationsRequest({
    $core.int? page,
  }) {
    final _result = create();
    if (page != null) {
      _result.page = page;
    }
    return _result;
  }
  factory GetConversationsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetConversationsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetConversationsRequest clone() => GetConversationsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetConversationsRequest copyWith(void Function(GetConversationsRequest) updates) => super.copyWith((message) => updates(message as GetConversationsRequest)) as GetConversationsRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetConversationsResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Conversation>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'conversations', $pb.PbFieldType.PM, subBuilder: Conversation.create)
    ..hasRequiredFields = false
  ;

  GetConversationsResponse._() : super();
  factory GetConversationsResponse({
    $core.Iterable<Conversation>? conversations,
  }) {
    final _result = create();
    if (conversations != null) {
      _result.conversations.addAll(conversations);
    }
    return _result;
  }
  factory GetConversationsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetConversationsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetConversationsResponse clone() => GetConversationsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetConversationsResponse copyWith(void Function(GetConversationsResponse) updates) => super.copyWith((message) => updates(message as GetConversationsResponse)) as GetConversationsResponse; // ignore: deprecated_member_use
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
  static const $core.Map<$core.int, GetConversationRequest_RequestedId> _GetConversationRequest_RequestedIdByTag = {
    1 : GetConversationRequest_RequestedId.conversationId,
    2 : GetConversationRequest_RequestedId.groupId,
    0 : GetConversationRequest_RequestedId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetConversationRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'conversationId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..a<$core.int>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'page', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  GetConversationRequest._() : super();
  factory GetConversationRequest({
    $core.String? conversationId,
    $core.String? groupId,
    $core.int? page,
  }) {
    final _result = create();
    if (conversationId != null) {
      _result.conversationId = conversationId;
    }
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (page != null) {
      _result.page = page;
    }
    return _result;
  }
  factory GetConversationRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetConversationRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetConversationRequest clone() => GetConversationRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetConversationRequest copyWith(void Function(GetConversationRequest) updates) => super.copyWith((message) => updates(message as GetConversationRequest)) as GetConversationRequest; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetConversationResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<$7.Post>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'conversation', $pb.PbFieldType.PM, subBuilder: $7.Post.create)
    ..hasRequiredFields = false
  ;

  GetConversationResponse._() : super();
  factory GetConversationResponse({
    $core.Iterable<$7.Post>? conversation,
  }) {
    final _result = create();
    if (conversation != null) {
      _result.conversation.addAll(conversation);
    }
    return _result;
  }
  factory GetConversationResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetConversationResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetConversationResponse clone() => GetConversationResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetConversationResponse copyWith(void Function(GetConversationResponse) updates) => super.copyWith((message) => updates(message as GetConversationResponse)) as GetConversationResponse; // ignore: deprecated_member_use
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

