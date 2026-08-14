// This is a generated file - do not edit.
//
// Generated from messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'messages.pbenum.dart';
import 'users.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'messages.pbenum.dart';

/// A Jonline `Message` represents a single message/email sent to one or more recipients
/// (really, "zero or more", as the design incorporates undeliverable messages).
class Message extends $pb.GeneratedMessage {
  factory Message({
    $core.String? id,
    $0.Author? sender,
    MessagingGroup? messagingGroup,
    $core.String? bodyText,
    $core.String? subject,
    $core.String? emailMessageId,
    $core.String? from,
    $core.String? to,
    $core.String? cc,
    $core.String? bcc,
    $1.Timestamp? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (sender != null) result.sender = sender;
    if (messagingGroup != null) result.messagingGroup = messagingGroup;
    if (bodyText != null) result.bodyText = bodyText;
    if (subject != null) result.subject = subject;
    if (emailMessageId != null) result.emailMessageId = emailMessageId;
    if (from != null) result.from = from;
    if (to != null) result.to = to;
    if (cc != null) result.cc = cc;
    if (bcc != null) result.bcc = bcc;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  Message._();

  factory Message.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Message.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Message',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<$0.Author>(2, _omitFieldNames ? '' : 'sender',
        subBuilder: $0.Author.create)
    ..aOM<MessagingGroup>(3, _omitFieldNames ? '' : 'messagingGroup',
        subBuilder: MessagingGroup.create)
    ..aOS(4, _omitFieldNames ? '' : 'bodyText')
    ..aOS(5, _omitFieldNames ? '' : 'subject')
    ..aOS(6, _omitFieldNames ? '' : 'emailMessageId')
    ..aOS(7, _omitFieldNames ? '' : 'from')
    ..aOS(8, _omitFieldNames ? '' : 'to')
    ..aOS(9, _omitFieldNames ? '' : 'cc')
    ..aOS(10, _omitFieldNames ? '' : 'bcc')
    ..aOM<$1.Timestamp>(20, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message copyWith(void Function(Message) updates) =>
      super.copyWith((message) => updates(message as Message)) as Message;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Message create() => Message._();
  @$core.override
  Message createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Message getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Message>(create);
  static Message? _defaultInstance;

  /// The ID of the message.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// The sender of the message. Note that this is *purported* (we don't protect against spoofing).
  @$pb.TagNumber(2)
  $0.Author get sender => $_getN(1);
  @$pb.TagNumber(2)
  set sender($0.Author value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSender() => $_has(1);
  @$pb.TagNumber(2)
  void clearSender() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Author ensureSender() => $_ensure(1);

  /// Note that, on the backend, every message actually has a messaging group.
  /// From the client's perspective, if messaging_group is not set, you
  /// were BCC'ed on the message and don't have access to the messaging group.
  @$pb.TagNumber(3)
  MessagingGroup get messagingGroup => $_getN(2);
  @$pb.TagNumber(3)
  set messagingGroup(MessagingGroup value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMessagingGroup() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessagingGroup() => $_clearField(3);
  @$pb.TagNumber(3)
  MessagingGroup ensureMessagingGroup() => $_ensure(2);

  /// The body text of the message. For email messages, this is the email body.
  @$pb.TagNumber(4)
  $core.String get bodyText => $_getSZ(3);
  @$pb.TagNumber(4)
  set bodyText($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBodyText() => $_has(3);
  @$pb.TagNumber(4)
  void clearBodyText() => $_clearField(4);

  /// Subject of the message. For email messages, this is the email subject.
  @$pb.TagNumber(5)
  $core.String get subject => $_getSZ(4);
  @$pb.TagNumber(5)
  set subject($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSubject() => $_has(4);
  @$pb.TagNumber(5)
  void clearSubject() => $_clearField(5);

  /// If this message derived from an email, the original email's message ID (RFC 5322). Used to prevent duplicate messages from being created when the same email is sent multiple times.
  @$pb.TagNumber(6)
  $core.String get emailMessageId => $_getSZ(5);
  @$pb.TagNumber(6)
  set emailMessageId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEmailMessageId() => $_has(5);
  @$pb.TagNumber(6)
  void clearEmailMessageId() => $_clearField(6);

  /// If this message derived from an email, the original email's "from" address.
  @$pb.TagNumber(7)
  $core.String get from => $_getSZ(6);
  @$pb.TagNumber(7)
  set from($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFrom() => $_has(6);
  @$pb.TagNumber(7)
  void clearFrom() => $_clearField(7);

  /// If this message derived from an email, the original email's "to" address.
  @$pb.TagNumber(8)
  $core.String get to => $_getSZ(7);
  @$pb.TagNumber(8)
  set to($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTo() => $_has(7);
  @$pb.TagNumber(8)
  void clearTo() => $_clearField(8);

  /// If this message derived from an email, the original email's "cc" address.
  @$pb.TagNumber(9)
  $core.String get cc => $_getSZ(8);
  @$pb.TagNumber(9)
  set cc($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCc() => $_has(8);
  @$pb.TagNumber(9)
  void clearCc() => $_clearField(9);

  /// If this message derived from an email, the original email's "bcc" address.
  @$pb.TagNumber(10)
  $core.String get bcc => $_getSZ(9);
  @$pb.TagNumber(10)
  set bcc($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasBcc() => $_has(9);
  @$pb.TagNumber(10)
  void clearBcc() => $_clearField(10);

  /// The time the message was created.
  @$pb.TagNumber(20)
  $1.Timestamp get createdAt => $_getN(10);
  @$pb.TagNumber(20)
  set createdAt($1.Timestamp value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedAt() => $_has(10);
  @$pb.TagNumber(20)
  void clearCreatedAt() => $_clearField(20);
  @$pb.TagNumber(20)
  $1.Timestamp ensureCreatedAt() => $_ensure(10);
}

/// Request to create a new message.
/// The server will create a new messaging group for the message, and send it to the given recipients.
class SendMessageRequest extends $pb.GeneratedMessage {
  factory SendMessageRequest({
    $core.Iterable<$core.String>? toUserIds,
    $core.String? subject,
    $core.String? bodyText,
  }) {
    final result = create();
    if (toUserIds != null) result.toUserIds.addAll(toUserIds);
    if (subject != null) result.subject = subject;
    if (bodyText != null) result.bodyText = bodyText;
    return result;
  }

  SendMessageRequest._();

  factory SendMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SendMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'toUserIds')
    ..aOS(2, _omitFieldNames ? '' : 'subject')
    ..aOS(3, _omitFieldNames ? '' : 'bodyText')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageRequest copyWith(void Function(SendMessageRequest) updates) =>
      super.copyWith((message) => updates(message as SendMessageRequest))
          as SendMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SendMessageRequest create() => SendMessageRequest._();
  @$core.override
  SendMessageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SendMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendMessageRequest>(create);
  static SendMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get toUserIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get subject => $_getSZ(1);
  @$pb.TagNumber(2)
  set subject($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubject() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubject() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get bodyText => $_getSZ(2);
  @$pb.TagNumber(3)
  set bodyText($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBodyText() => $_has(2);
  @$pb.TagNumber(3)
  void clearBodyText() => $_clearField(3);
}

/// A group of users who are participating in a conversation.
/// Most servers will probably have a (dynamically created) "empty group" for an email like
/// `not_a_user@my_jonline_instance.com`.
class MessagingGroup extends $pb.GeneratedMessage {
  factory MessagingGroup({
    $core.String? id,
    $core.Iterable<$0.Author>? members,
    $1.Timestamp? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (members != null) result.members.addAll(members);
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  MessagingGroup._();

  factory MessagingGroup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessagingGroup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessagingGroup',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..pPM<$0.Author>(2, _omitFieldNames ? '' : 'members',
        subBuilder: $0.Author.create)
    ..aOM<$1.Timestamp>(10, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagingGroup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagingGroup copyWith(void Function(MessagingGroup) updates) =>
      super.copyWith((message) => updates(message as MessagingGroup))
          as MessagingGroup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessagingGroup create() => MessagingGroup._();
  @$core.override
  MessagingGroup createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MessagingGroup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessagingGroup>(create);
  static MessagingGroup? _defaultInstance;

  /// The ID of the messaging group.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// The users who are members of the group. Note that this is a superset of the users who are
  @$pb.TagNumber(2)
  $pb.PbList<$0.Author> get members => $_getList(1);

  /// The time the group was created.
  @$pb.TagNumber(10)
  $1.Timestamp get createdAt => $_getN(2);
  @$pb.TagNumber(10)
  set createdAt($1.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasCreatedAt() => $_has(2);
  @$pb.TagNumber(10)
  void clearCreatedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.Timestamp ensureCreatedAt() => $_ensure(2);
}

/// Request to get messages from the server. The request may be filtered by message ID, search text, or creation time.
/// All non-text-search requests return messages in reverse chronological order (newest first).
/// Text search requests return messages in order of relevance to the search text.
class GetMessagesRequest extends $pb.GeneratedMessage {
  factory GetMessagesRequest({
    MessageListingType? listingType,
    $core.String? messageId,
    $core.String? messageGroupId,
    $core.String? searchText,
    $1.Timestamp? sentBefore,
  }) {
    final result = create();
    if (listingType != null) result.listingType = listingType;
    if (messageId != null) result.messageId = messageId;
    if (messageGroupId != null) result.messageGroupId = messageGroupId;
    if (searchText != null) result.searchText = searchText;
    if (sentBefore != null) result.sentBefore = sentBefore;
    return result;
  }

  GetMessagesRequest._();

  factory GetMessagesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetMessagesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMessagesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..aE<MessageListingType>(1, _omitFieldNames ? '' : 'listingType',
        enumValues: MessageListingType.values)
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..aOS(3, _omitFieldNames ? '' : 'messageGroupId')
    ..aOS(7, _omitFieldNames ? '' : 'searchText')
    ..aOM<$1.Timestamp>(8, _omitFieldNames ? '' : 'sentBefore',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMessagesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMessagesRequest copyWith(void Function(GetMessagesRequest) updates) =>
      super.copyWith((message) => updates(message as GetMessagesRequest))
          as GetMessagesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetMessagesRequest create() => GetMessagesRequest._();
  @$core.override
  GetMessagesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetMessagesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMessagesRequest>(create);
  static GetMessagesRequest? _defaultInstance;

  /// The type of message listing to return. Required.
  @$pb.TagNumber(1)
  MessageListingType get listingType => $_getN(0);
  @$pb.TagNumber(1)
  set listingType(MessageListingType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasListingType() => $_has(0);
  @$pb.TagNumber(1)
  void clearListingType() => $_clearField(1);

  /// Returns the single message with the given ID (assuming the user has access to it).
  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);

  /// Returns messages that are part of the given messaging group (assuming the user has access to it).
  @$pb.TagNumber(3)
  $core.String get messageGroupId => $_getSZ(2);
  @$pb.TagNumber(3)
  set messageGroupId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessageGroupId() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessageGroupId() => $_clearField(3);

  /// Full-text search query, matched against the sender's username/real name and the message's
  /// subject and body. Required (and only used) when `listing_type` is `TEXT_SEARCH`.
  @$pb.TagNumber(7)
  $core.String get searchText => $_getSZ(3);
  @$pb.TagNumber(7)
  set searchText($core.String value) => $_setString(3, value);
  @$pb.TagNumber(7)
  $core.bool hasSearchText() => $_has(3);
  @$pb.TagNumber(7)
  void clearSearchText() => $_clearField(7);

  /// Request to only return posts that were published or created before the given timestamp.
  @$pb.TagNumber(8)
  $1.Timestamp get sentBefore => $_getN(4);
  @$pb.TagNumber(8)
  set sentBefore($1.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasSentBefore() => $_has(4);
  @$pb.TagNumber(8)
  void clearSentBefore() => $_clearField(8);
  @$pb.TagNumber(8)
  $1.Timestamp ensureSentBefore() => $_ensure(4);
}

/// Response to a `GetMessagesRequest`, containing the requested messages.
class GetMessagesResponse extends $pb.GeneratedMessage {
  factory GetMessagesResponse({
    $core.Iterable<Message>? messages,
  }) {
    final result = create();
    if (messages != null) result.messages.addAll(messages);
    return result;
  }

  GetMessagesResponse._();

  factory GetMessagesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetMessagesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMessagesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'),
      createEmptyInstance: create)
    ..pPM<Message>(1, _omitFieldNames ? '' : 'messages',
        subBuilder: Message.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMessagesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMessagesResponse copyWith(void Function(GetMessagesResponse) updates) =>
      super.copyWith((message) => updates(message as GetMessagesResponse))
          as GetMessagesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetMessagesResponse create() => GetMessagesResponse._();
  @$core.override
  GetMessagesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetMessagesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMessagesResponse>(create);
  static GetMessagesResponse? _defaultInstance;

  /// The messages that match the request. May be empty if no messages match.
  /// May be shortened to a server-defined limit, dependent on service version,
  /// configuration, load, etc.
  @$pb.TagNumber(1)
  $pb.PbList<Message> get messages => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
