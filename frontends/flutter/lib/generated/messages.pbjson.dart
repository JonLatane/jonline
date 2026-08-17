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
    {'1': 'sender', '3': 2, '4': 1, '5': 11, '6': '.jonline.Author', '9': 0, '10': 'sender', '17': true},
    {'1': 'messaging_group', '3': 3, '4': 1, '5': 11, '6': '.jonline.MessagingGroup', '9': 1, '10': 'messagingGroup', '17': true},
    {'1': 'body_text', '3': 4, '4': 1, '5': 9, '10': 'bodyText'},
    {'1': 'subject', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'subject', '17': true},
    {'1': 'email_message_id', '3': 6, '4': 1, '5': 9, '9': 3, '10': 'emailMessageId', '17': true},
    {'1': 'from', '3': 7, '4': 1, '5': 9, '9': 4, '10': 'from', '17': true},
    {'1': 'to', '3': 8, '4': 1, '5': 9, '9': 5, '10': 'to', '17': true},
    {'1': 'cc', '3': 9, '4': 1, '5': 9, '9': 6, '10': 'cc', '17': true},
    {'1': 'bcc', '3': 10, '4': 1, '5': 9, '9': 7, '10': 'bcc', '17': true},
    {'1': 'current_user_read', '3': 19, '4': 1, '5': 11, '6': '.jonline.MessageRead', '9': 8, '10': 'currentUserRead', '17': true},
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
    'CgdNZXNzYWdlEg4KAmlkGAEgASgJUgJpZBIsCgZzZW5kZXIYAiABKAsyDy5qb25saW5lLkF1dG'
    'hvckgAUgZzZW5kZXKIAQESRQoPbWVzc2FnaW5nX2dyb3VwGAMgASgLMhcuam9ubGluZS5NZXNz'
    'YWdpbmdHcm91cEgBUg5tZXNzYWdpbmdHcm91cIgBARIbCglib2R5X3RleHQYBCABKAlSCGJvZH'
    'lUZXh0Eh0KB3N1YmplY3QYBSABKAlIAlIHc3ViamVjdIgBARItChBlbWFpbF9tZXNzYWdlX2lk'
    'GAYgASgJSANSDmVtYWlsTWVzc2FnZUlkiAEBEhcKBGZyb20YByABKAlIBFIEZnJvbYgBARITCg'
    'J0bxgIIAEoCUgFUgJ0b4gBARITCgJjYxgJIAEoCUgGUgJjY4gBARIVCgNiY2MYCiABKAlIB1ID'
    'YmNjiAEBEkUKEWN1cnJlbnRfdXNlcl9yZWFkGBMgASgLMhQuam9ubGluZS5NZXNzYWdlUmVhZE'
    'gIUg9jdXJyZW50VXNlclJlYWSIAQESOQoKY3JlYXRlZF9hdBgUIAEoCzIaLmdvb2dsZS5wcm90'
    'b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdEIJCgdfc2VuZGVyQhIKEF9tZXNzYWdpbmdfZ3JvdX'
    'BCCgoIX3N1YmplY3RCEwoRX2VtYWlsX21lc3NhZ2VfaWRCBwoFX2Zyb21CBQoDX3RvQgUKA19j'
    'Y0IGCgRfYmNjQhQKEl9jdXJyZW50X3VzZXJfcmVhZA==');

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
    {'1': 'members', '3': 2, '4': 3, '5': 11, '6': '.jonline.Author', '10': 'members'},
    {'1': 'created_at', '3': 10, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
  ],
};

/// Descriptor for `MessagingGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messagingGroupDescriptor = $convert.base64Decode(
    'Cg5NZXNzYWdpbmdHcm91cBIOCgJpZBgBIAEoCVICaWQSKQoHbWVtYmVycxgCIAMoCzIPLmpvbm'
    'xpbmUuQXV0aG9yUgdtZW1iZXJzEjkKCmNyZWF0ZWRfYXQYCiABKAsyGi5nb29nbGUucHJvdG9i'
    'dWYuVGltZXN0YW1wUgljcmVhdGVkQXQ=');

@$core.Deprecated('Use getMessagesRequestDescriptor instead')
const GetMessagesRequest$json = {
  '1': 'GetMessagesRequest',
  '2': [
    {'1': 'listing_type', '3': 1, '4': 1, '5': 14, '6': '.jonline.MessageListingType', '10': 'listingType'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'messageId', '17': true},
    {'1': 'message_group_id', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'messageGroupId', '17': true},
    {'1': 'search_text', '3': 7, '4': 1, '5': 9, '9': 2, '10': 'searchText', '17': true},
    {'1': 'sent_before', '3': 8, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 3, '10': 'sentBefore', '17': true},
  ],
  '8': [
    {'1': '_message_id'},
    {'1': '_message_group_id'},
    {'1': '_search_text'},
    {'1': '_sent_before'},
  ],
};

/// Descriptor for `GetMessagesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMessagesRequestDescriptor = $convert.base64Decode(
    'ChJHZXRNZXNzYWdlc1JlcXVlc3QSPgoMbGlzdGluZ190eXBlGAEgASgOMhsuam9ubGluZS5NZX'
    'NzYWdlTGlzdGluZ1R5cGVSC2xpc3RpbmdUeXBlEiIKCm1lc3NhZ2VfaWQYAiABKAlIAFIJbWVz'
    'c2FnZUlkiAEBEi0KEG1lc3NhZ2VfZ3JvdXBfaWQYAyABKAlIAVIObWVzc2FnZUdyb3VwSWSIAQ'
    'ESJAoLc2VhcmNoX3RleHQYByABKAlIAlIKc2VhcmNoVGV4dIgBARJACgtzZW50X2JlZm9yZRgI'
    'IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIA1IKc2VudEJlZm9yZYgBAUINCgtfbW'
    'Vzc2FnZV9pZEITChFfbWVzc2FnZV9ncm91cF9pZEIOCgxfc2VhcmNoX3RleHRCDgoMX3NlbnRf'
    'YmVmb3Jl');

@$core.Deprecated('Use getMessagesResponseDescriptor instead')
const GetMessagesResponse$json = {
  '1': 'GetMessagesResponse',
  '2': [
    {'1': 'messages', '3': 1, '4': 3, '5': 11, '6': '.jonline.Message', '10': 'messages'},
  ],
};

/// Descriptor for `GetMessagesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMessagesResponseDescriptor = $convert.base64Decode(
    'ChNHZXRNZXNzYWdlc1Jlc3BvbnNlEiwKCG1lc3NhZ2VzGAEgAygLMhAuam9ubGluZS5NZXNzYW'
    'dlUghtZXNzYWdlcw==');

