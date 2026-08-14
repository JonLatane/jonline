//
//  Generated code. Do not modify.
//  source: messages.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class MessageListingType extends $pb.ProtobufEnum {
  static const MessageListingType PERSONAL_MESSAGES = MessageListingType._(0, _omitEnumNames ? '' : 'PERSONAL_MESSAGES');
  static const MessageListingType PERSONAL_MESSAGES_TEXT_SEARCH = MessageListingType._(1, _omitEnumNames ? '' : 'PERSONAL_MESSAGES_TEXT_SEARCH');
  static const MessageListingType ALL_SYSTEM_MESSAGES = MessageListingType._(10, _omitEnumNames ? '' : 'ALL_SYSTEM_MESSAGES');
  static const MessageListingType ALL_SYSTEM_MESSAGES_TEXT_SEARCH = MessageListingType._(11, _omitEnumNames ? '' : 'ALL_SYSTEM_MESSAGES_TEXT_SEARCH');

  static const $core.List<MessageListingType> values = <MessageListingType> [
    PERSONAL_MESSAGES,
    PERSONAL_MESSAGES_TEXT_SEARCH,
    ALL_SYSTEM_MESSAGES,
    ALL_SYSTEM_MESSAGES_TEXT_SEARCH,
  ];

  static final $core.Map<$core.int, MessageListingType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MessageListingType? valueOf($core.int value) => _byValue[value];

  const MessageListingType._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
