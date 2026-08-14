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

class MessageListingType extends $pb.ProtobufEnum {
  /// Gets messages sent to the current user, and messages (purportedly) sent by the user.
  static const MessageListingType PERSONAL_MESSAGES =
      MessageListingType._(0, _omitEnumNames ? '' : 'PERSONAL_MESSAGES');

  /// Gets messages sent to the current user, and messages (purportedly) sent by the user, that match the given search text.
  /// Returns results in order of relevance to the search text.
  static const MessageListingType PERSONAL_MESSAGES_TEXT_SEARCH =
      MessageListingType._(
          1, _omitEnumNames ? '' : 'PERSONAL_MESSAGES_TEXT_SEARCH');

  /// Gets all messages on the server (to a limit), including those sent to other users. Requires admin privileges.
  static const MessageListingType ALL_SYSTEM_MESSAGES =
      MessageListingType._(10, _omitEnumNames ? '' : 'ALL_SYSTEM_MESSAGES');
  static const MessageListingType ALL_SYSTEM_MESSAGES_TEXT_SEARCH =
      MessageListingType._(
          11, _omitEnumNames ? '' : 'ALL_SYSTEM_MESSAGES_TEXT_SEARCH');

  static const $core.List<MessageListingType> values = <MessageListingType>[
    PERSONAL_MESSAGES,
    PERSONAL_MESSAGES_TEXT_SEARCH,
    ALL_SYSTEM_MESSAGES,
    ALL_SYSTEM_MESSAGES_TEXT_SEARCH,
  ];

  static final $core.Map<$core.int, MessageListingType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static MessageListingType? valueOf($core.int value) => _byValue[value];

  const MessageListingType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
