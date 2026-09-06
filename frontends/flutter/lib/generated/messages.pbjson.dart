//
//  Generated code. Do not modify.
//  source: messages.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use messageListingTypeDescriptor instead')
const MessageListingType$json = {
  '1': 'MessageListingType',
  '2': [
    {'1': 'PERSONAL_MESSAGES', '2': 0},
    {'1': 'PERSONAL_MESSAGES_TEXT_SEARCH', '2': 1},
    {'1': 'ALL_SYSTEM_MESSAGES', '2': 10},
    {'1': 'ALL_SYSTEM_MESSAGES_TEXT_SEARCH', '2': 11},
  ],
};

/// Descriptor for `MessageListingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageListingTypeDescriptor = $convert.base64Decode(
    'ChJNZXNzYWdlTGlzdGluZ1R5cGUSFQoRUEVSU09OQUxfTUVTU0FHRVMQABIhCh1QRVJTT05BTF'
    '9NRVNTQUdFU19URVhUX1NFQVJDSBABEhcKE0FMTF9TWVNURU1fTUVTU0FHRVMQChIjCh9BTExf'
    'U1lTVEVNX01FU1NBR0VTX1RFWFRfU0VBUkNIEAs=');

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'sender', '3': 2, '4': 1, '5': 11, '6': '.rellm.Author', '9': 0, '10': 'sender', '17': true},
    {'1': 'messaging_group', '3': 3, '4': 1, '5': 11, '6': '.rellm.MessagingGroup', '9': 1, '10': 'messagingGroup', '17': true},
    {'1': 'body_text', '3': 4, '4': 1, '5': 9, '10': 'bodyText'},
    {'1': 'subject', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'subject', '17': true},
    {'1': 'email_message_id', '3': 6, '4': 1, '5': 9, '9': 3, '10': 'emailMessageId', '17': true},
    {'1': 'from', '3': 7, '4': 1, '5': 9, '9': 4, '10': 'from', '17': true},
    {'1': 'to', '3': 8, '4': 1, '5': 9, '9': 5, '10': 'to', '17': true},
    {'1': 'cc', '3': 9, '4': 1, '5': 9, '9': 6, '10': 'cc', '17': true},
    {'1': 'bcc', '3': 10, '4': 1, '5': 9, '9': 7, '10': 'bcc', '17': true},
    {'1': 'current_user_read', '3': 19, '4': 1, '5': 11, '6': '.rellm.MessageRead', '9': 8, '10': 'currentUserRead', '17': true},
    {'1': 'created_at', '3': 20, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
  ],
  '8': [
    {'1': '_sender'},
    {'1': '_messaging_group'},
    {'1': '_subject'},
    {'1': '_email_message_id'},
    {'1': '_from'},
    {'1': '_to'},
    {'1': '_cc'},
    {'1': '_bcc'},
    {'1': '_current_user_read'},
  ],
};

/// Descriptor for `Message`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDescriptor = $convert.base64Decode(
    'CgdNZXNzYWdlEg4KAmlkGAEgASgJUgJpZBIqCgZzZW5kZXIYAiABKAsyDS5yZWxsbS5BdXRob3'
    'JIAFIGc2VuZGVyiAEBEkMKD21lc3NhZ2luZ19ncm91cBgDIAEoCzIVLnJlbGxtLk1lc3NhZ2lu'
    'Z0dyb3VwSAFSDm1lc3NhZ2luZ0dyb3VwiAEBEhsKCWJvZHlfdGV4dBgEIAEoCVIIYm9keVRleH'
    'QSHQoHc3ViamVjdBgFIAEoCUgCUgdzdWJqZWN0iAEBEi0KEGVtYWlsX21lc3NhZ2VfaWQYBiAB'
    'KAlIA1IOZW1haWxNZXNzYWdlSWSIAQESFwoEZnJvbRgHIAEoCUgEUgRmcm9tiAEBEhMKAnRvGA'
    'ggASgJSAVSAnRviAEBEhMKAmNjGAkgASgJSAZSAmNjiAEBEhUKA2JjYxgKIAEoCUgHUgNiY2OI'
    'AQESQwoRY3VycmVudF91c2VyX3JlYWQYEyABKAsyEi5yZWxsbS5NZXNzYWdlUmVhZEgIUg9jdX'
    'JyZW50VXNlclJlYWSIAQESOQoKY3JlYXRlZF9hdBgUIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U'
    'aW1lc3RhbXBSCWNyZWF0ZWRBdEIJCgdfc2VuZGVyQhIKEF9tZXNzYWdpbmdfZ3JvdXBCCgoIX3'
    'N1YmplY3RCEwoRX2VtYWlsX21lc3NhZ2VfaWRCBwoFX2Zyb21CBQoDX3RvQgUKA19jY0IGCgRf'
    'YmNjQhQKEl9jdXJyZW50X3VzZXJfcmVhZA==');

@$core.Deprecated('Use messageReadDescriptor instead')
const MessageRead$json = {
  '1': 'MessageRead',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'read_at', '3': 20, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'readAt'},
  ],
};

/// Descriptor for `MessageRead`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageReadDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlUmVhZBIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSFwoHdXNlcl9pZB'
    'gCIAEoCVIGdXNlcklkEjMKB3JlYWRfYXQYFCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0'
    'YW1wUgZyZWFkQXQ=');

@$core.Deprecated('Use markMessagesReadRequestDescriptor instead')
const MarkMessagesReadRequest$json = {
  '1': 'MarkMessagesReadRequest',
  '2': [
    {'1': 'unread', '3': 1, '4': 1, '5': 8, '10': 'unread'},
    {'1': 'message_ids', '3': 2, '4': 3, '5': 9, '10': 'messageIds'},
  ],
};

/// Descriptor for `MarkMessagesReadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markMessagesReadRequestDescriptor = $convert.base64Decode(
    'ChdNYXJrTWVzc2FnZXNSZWFkUmVxdWVzdBIWCgZ1bnJlYWQYASABKAhSBnVucmVhZBIfCgttZX'
    'NzYWdlX2lkcxgCIAMoCVIKbWVzc2FnZUlkcw==');

@$core.Deprecated('Use markMessagesReadResponseDescriptor instead')
const MarkMessagesReadResponse$json = {
  '1': 'MarkMessagesReadResponse',
  '2': [
    {'1': 'message_reads', '3': 1, '4': 3, '5': 11, '6': '.rellm.MessageRead', '10': 'messageReads'},
  ],
};

/// Descriptor for `MarkMessagesReadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markMessagesReadResponseDescriptor = $convert.base64Decode(
    'ChhNYXJrTWVzc2FnZXNSZWFkUmVzcG9uc2USNwoNbWVzc2FnZV9yZWFkcxgBIAMoCzISLnJlbG'
    'xtLk1lc3NhZ2VSZWFkUgxtZXNzYWdlUmVhZHM=');

@$core.Deprecated('Use sendMessageRequestDescriptor instead')
const SendMessageRequest$json = {
  '1': 'SendMessageRequest',
  '2': [
    {'1': 'to_user_ids', '3': 1, '4': 3, '5': 9, '10': 'toUserIds'},
    {'1': 'subject', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'subject', '17': true},
    {'1': 'body_text', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'bodyText', '17': true},
  ],
  '8': [
    {'1': '_subject'},
    {'1': '_body_text'},
  ],
};

/// Descriptor for `SendMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendMessageRequestDescriptor = $convert.base64Decode(
    'ChJTZW5kTWVzc2FnZVJlcXVlc3QSHgoLdG9fdXNlcl9pZHMYASADKAlSCXRvVXNlcklkcxIdCg'
    'dzdWJqZWN0GAIgASgJSABSB3N1YmplY3SIAQESIAoJYm9keV90ZXh0GAMgASgJSAFSCGJvZHlU'
    'ZXh0iAEBQgoKCF9zdWJqZWN0QgwKCl9ib2R5X3RleHQ=');

@$core.Deprecated('Use messagingGroupDescriptor instead')
const MessagingGroup$json = {
  '1': 'MessagingGroup',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'members', '3': 2, '4': 3, '5': 11, '6': '.rellm.Author', '10': 'members'},
    {'1': 'created_at', '3': 10, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
  ],
};

/// Descriptor for `MessagingGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messagingGroupDescriptor = $convert.base64Decode(
    'Cg5NZXNzYWdpbmdHcm91cBIOCgJpZBgBIAEoCVICaWQSJwoHbWVtYmVycxgCIAMoCzINLnJlbG'
    'xtLkF1dGhvclIHbWVtYmVycxI5CgpjcmVhdGVkX2F0GAogASgLMhouZ29vZ2xlLnByb3RvYnVm'
    'LlRpbWVzdGFtcFIJY3JlYXRlZEF0');

@$core.Deprecated('Use getMessagesRequestDescriptor instead')
const GetMessagesRequest$json = {
  '1': 'GetMessagesRequest',
  '2': [
    {'1': 'listing_type', '3': 1, '4': 1, '5': 14, '6': '.rellm.MessageListingType', '10': 'listingType'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'messageId', '17': true},
    {'1': 'message_group_id', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'messageGroupId', '17': true},
    {'1': 'search_text', '3': 7, '4': 1, '5': 9, '9': 2, '10': 'searchText', '17': true},
    {'1': 'sent_before', '3': 8, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 3, '10': 'sentBefore', '17': true},
    {'1': 'from_email', '3': 9, '4': 1, '5': 9, '9': 4, '10': 'fromEmail', '17': true},
  ],
  '8': [
    {'1': '_message_id'},
    {'1': '_message_group_id'},
    {'1': '_search_text'},
    {'1': '_sent_before'},
    {'1': '_from_email'},
  ],
};

/// Descriptor for `GetMessagesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMessagesRequestDescriptor = $convert.base64Decode(
    'ChJHZXRNZXNzYWdlc1JlcXVlc3QSPAoMbGlzdGluZ190eXBlGAEgASgOMhkucmVsbG0uTWVzc2'
    'FnZUxpc3RpbmdUeXBlUgtsaXN0aW5nVHlwZRIiCgptZXNzYWdlX2lkGAIgASgJSABSCW1lc3Nh'
    'Z2VJZIgBARItChBtZXNzYWdlX2dyb3VwX2lkGAMgASgJSAFSDm1lc3NhZ2VHcm91cElkiAEBEi'
    'QKC3NlYXJjaF90ZXh0GAcgASgJSAJSCnNlYXJjaFRleHSIAQESQAoLc2VudF9iZWZvcmUYCCAB'
    'KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSANSCnNlbnRCZWZvcmWIAQESIgoKZnJvbV'
    '9lbWFpbBgJIAEoCUgEUglmcm9tRW1haWyIAQFCDQoLX21lc3NhZ2VfaWRCEwoRX21lc3NhZ2Vf'
    'Z3JvdXBfaWRCDgoMX3NlYXJjaF90ZXh0Qg4KDF9zZW50X2JlZm9yZUINCgtfZnJvbV9lbWFpbA'
    '==');

@$core.Deprecated('Use getMessagesResponseDescriptor instead')
const GetMessagesResponse$json = {
  '1': 'GetMessagesResponse',
  '2': [
    {'1': 'messages', '3': 1, '4': 3, '5': 11, '6': '.rellm.Message', '10': 'messages'},
  ],
};

/// Descriptor for `GetMessagesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMessagesResponseDescriptor = $convert.base64Decode(
    'ChNHZXRNZXNzYWdlc1Jlc3BvbnNlEioKCG1lc3NhZ2VzGAEgAygLMg4ucmVsbG0uTWVzc2FnZV'
    'IIbWVzc2FnZXM=');

@$core.Deprecated('Use pushSubscriptionDescriptor instead')
const PushSubscription$json = {
  '1': 'PushSubscription',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'endpoint', '3': 2, '4': 1, '5': 9, '10': 'endpoint'},
    {'1': 'created_at', '3': 20, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
  ],
};

/// Descriptor for `PushSubscription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushSubscriptionDescriptor = $convert.base64Decode(
    'ChBQdXNoU3Vic2NyaXB0aW9uEg4KAmlkGAEgASgJUgJpZBIaCghlbmRwb2ludBgCIAEoCVIIZW'
    '5kcG9pbnQSOQoKY3JlYXRlZF9hdBgUIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS'
    'CWNyZWF0ZWRBdA==');

@$core.Deprecated('Use registerPushSubscriptionRequestDescriptor instead')
const RegisterPushSubscriptionRequest$json = {
  '1': 'RegisterPushSubscriptionRequest',
  '2': [
    {'1': 'endpoint', '3': 1, '4': 1, '5': 9, '10': 'endpoint'},
    {'1': 'p256dh_key', '3': 2, '4': 1, '5': 9, '10': 'p256dhKey'},
    {'1': 'auth_key', '3': 3, '4': 1, '5': 9, '10': 'authKey'},
  ],
};

/// Descriptor for `RegisterPushSubscriptionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerPushSubscriptionRequestDescriptor = $convert.base64Decode(
    'Ch9SZWdpc3RlclB1c2hTdWJzY3JpcHRpb25SZXF1ZXN0EhoKCGVuZHBvaW50GAEgASgJUghlbm'
    'Rwb2ludBIdCgpwMjU2ZGhfa2V5GAIgASgJUglwMjU2ZGhLZXkSGQoIYXV0aF9rZXkYAyABKAlS'
    'B2F1dGhLZXk=');

@$core.Deprecated('Use unregisterPushSubscriptionRequestDescriptor instead')
const UnregisterPushSubscriptionRequest$json = {
  '1': 'UnregisterPushSubscriptionRequest',
  '2': [
    {'1': 'endpoint', '3': 1, '4': 1, '5': 9, '10': 'endpoint'},
  ],
};

/// Descriptor for `UnregisterPushSubscriptionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unregisterPushSubscriptionRequestDescriptor = $convert.base64Decode(
    'CiFVbnJlZ2lzdGVyUHVzaFN1YnNjcmlwdGlvblJlcXVlc3QSGgoIZW5kcG9pbnQYASABKAlSCG'
    'VuZHBvaW50');

@$core.Deprecated('Use getPushSubscriptionStatusRequestDescriptor instead')
const GetPushSubscriptionStatusRequest$json = {
  '1': 'GetPushSubscriptionStatusRequest',
  '2': [
    {'1': 'endpoint', '3': 1, '4': 1, '5': 9, '10': 'endpoint'},
  ],
};

/// Descriptor for `GetPushSubscriptionStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPushSubscriptionStatusRequestDescriptor = $convert.base64Decode(
    'CiBHZXRQdXNoU3Vic2NyaXB0aW9uU3RhdHVzUmVxdWVzdBIaCghlbmRwb2ludBgBIAEoCVIIZW'
    '5kcG9pbnQ=');

@$core.Deprecated('Use getPushSubscriptionStatusResponseDescriptor instead')
const GetPushSubscriptionStatusResponse$json = {
  '1': 'GetPushSubscriptionStatusResponse',
  '2': [
    {'1': 'registered', '3': 1, '4': 1, '5': 8, '10': 'registered'},
  ],
};

/// Descriptor for `GetPushSubscriptionStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPushSubscriptionStatusResponseDescriptor = $convert.base64Decode(
    'CiFHZXRQdXNoU3Vic2NyaXB0aW9uU3RhdHVzUmVzcG9uc2USHgoKcmVnaXN0ZXJlZBgBIAEoCF'
    'IKcmVnaXN0ZXJlZA==');

