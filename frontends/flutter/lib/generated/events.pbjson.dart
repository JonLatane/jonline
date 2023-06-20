//
//  Generated code. Do not modify.
//  source: events.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use eventListingTypeDescriptor instead')
const EventListingType$json = {
  '1': 'EventListingType',
  '2': [
    {'1': 'PUBLIC_EVENTS', '2': 0},
    {'1': 'FOLLOWING_EVENTS', '2': 1},
    {'1': 'MY_GROUPS_EVENTS', '2': 2},
    {'1': 'DIRECT_EVENTS', '2': 3},
    {'1': 'EVENTS_PENDING_MODERATION', '2': 4},
    {'1': 'GROUP_EVENTS', '2': 10},
    {'1': 'GROUP_EVENTS_PENDING_MODERATION', '2': 11},
  ],
};

/// Descriptor for `EventListingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List eventListingTypeDescriptor = $convert.base64Decode(
    'ChBFdmVudExpc3RpbmdUeXBlEhEKDVBVQkxJQ19FVkVOVFMQABIUChBGT0xMT1dJTkdfRVZFTl'
    'RTEAESFAoQTVlfR1JPVVBTX0VWRU5UUxACEhEKDURJUkVDVF9FVkVOVFMQAxIdChlFVkVOVFNf'
    'UEVORElOR19NT0RFUkFUSU9OEAQSEAoMR1JPVVBfRVZFTlRTEAoSIwofR1JPVVBfRVZFTlRTX1'
    'BFTkRJTkdfTU9ERVJBVElPThAL');

@$core.Deprecated('Use attendanceStatusDescriptor instead')
const AttendanceStatus$json = {
  '1': 'AttendanceStatus',
  '2': [
    {'1': 'INTERESTED', '2': 0},
    {'1': 'GOING', '2': 1},
    {'1': 'NOT_GOING', '2': 2},
    {'1': 'REQUESTED', '2': 3},
    {'1': 'WENT', '2': 10},
    {'1': 'DID_NOT_GO', '2': 11},
  ],
};

/// Descriptor for `AttendanceStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List attendanceStatusDescriptor = $convert.base64Decode(
    'ChBBdHRlbmRhbmNlU3RhdHVzEg4KCklOVEVSRVNURUQQABIJCgVHT0lORxABEg0KCU5PVF9HT0'
    'lORxACEg0KCVJFUVVFU1RFRBADEggKBFdFTlQQChIOCgpESURfTk9UX0dPEAs=');

@$core.Deprecated('Use getEventsRequestDescriptor instead')
const GetEventsRequest$json = {
  '1': 'GetEventsRequest',
  '2': [
    {'1': 'event_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'eventId', '17': true},
    {'1': 'author_user_id', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'authorUserId', '17': true},
    {'1': 'group_id', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'groupId', '17': true},
    {'1': 'event_instance_id', '3': 4, '4': 1, '5': 9, '9': 3, '10': 'eventInstanceId', '17': true},
    {'1': 'time_filter', '3': 5, '4': 1, '5': 11, '6': '.jonline.TimeFilter', '9': 4, '10': 'timeFilter', '17': true},
    {'1': 'listing_type', '3': 10, '4': 1, '5': 14, '6': '.jonline.EventListingType', '10': 'listingType'},
  ],
  '8': [
    {'1': '_event_id'},
    {'1': '_author_user_id'},
    {'1': '_group_id'},
    {'1': '_event_instance_id'},
    {'1': '_time_filter'},
  ],
};

/// Descriptor for `GetEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEventsRequestDescriptor = $convert.base64Decode(
    'ChBHZXRFdmVudHNSZXF1ZXN0Eh4KCGV2ZW50X2lkGAEgASgJSABSB2V2ZW50SWSIAQESKQoOYX'
    'V0aG9yX3VzZXJfaWQYAiABKAlIAVIMYXV0aG9yVXNlcklkiAEBEh4KCGdyb3VwX2lkGAMgASgJ'
    'SAJSB2dyb3VwSWSIAQESLwoRZXZlbnRfaW5zdGFuY2VfaWQYBCABKAlIA1IPZXZlbnRJbnN0YW'
    '5jZUlkiAEBEjkKC3RpbWVfZmlsdGVyGAUgASgLMhMuam9ubGluZS5UaW1lRmlsdGVySARSCnRp'
    'bWVGaWx0ZXKIAQESPAoMbGlzdGluZ190eXBlGAogASgOMhkuam9ubGluZS5FdmVudExpc3Rpbm'
    'dUeXBlUgtsaXN0aW5nVHlwZUILCglfZXZlbnRfaWRCEQoPX2F1dGhvcl91c2VyX2lkQgsKCV9n'
    'cm91cF9pZEIUChJfZXZlbnRfaW5zdGFuY2VfaWRCDgoMX3RpbWVfZmlsdGVy');

@$core.Deprecated('Use timeFilterDescriptor instead')
const TimeFilter$json = {
  '1': 'TimeFilter',
  '2': [
    {'1': 'starts_after', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'startsAfter', '17': true},
    {'1': 'ends_after', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 1, '10': 'endsAfter', '17': true},
    {'1': 'starts_before', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 2, '10': 'startsBefore', '17': true},
    {'1': 'ends_before', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 3, '10': 'endsBefore', '17': true},
  ],
  '8': [
    {'1': '_starts_after'},
    {'1': '_ends_after'},
    {'1': '_starts_before'},
    {'1': '_ends_before'},
  ],
};

/// Descriptor for `TimeFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timeFilterDescriptor = $convert.base64Decode(
    'CgpUaW1lRmlsdGVyEkIKDHN0YXJ0c19hZnRlchgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW'
    '1lc3RhbXBIAFILc3RhcnRzQWZ0ZXKIAQESPgoKZW5kc19hZnRlchgCIAEoCzIaLmdvb2dsZS5w'
    'cm90b2J1Zi5UaW1lc3RhbXBIAVIJZW5kc0FmdGVyiAEBEkQKDXN0YXJ0c19iZWZvcmUYAyABKA'
    'syGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSAJSDHN0YXJ0c0JlZm9yZYgBARJACgtlbmRz'
    'X2JlZm9yZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIA1IKZW5kc0JlZm9yZY'
    'gBAUIPCg1fc3RhcnRzX2FmdGVyQg0KC19lbmRzX2FmdGVyQhAKDl9zdGFydHNfYmVmb3JlQg4K'
    'DF9lbmRzX2JlZm9yZQ==');

@$core.Deprecated('Use getEventsResponseDescriptor instead')
const GetEventsResponse$json = {
  '1': 'GetEventsResponse',
  '2': [
    {'1': 'events', '3': 1, '4': 3, '5': 11, '6': '.jonline.Event', '10': 'events'},
  ],
};

/// Descriptor for `GetEventsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEventsResponseDescriptor = $convert.base64Decode(
    'ChFHZXRFdmVudHNSZXNwb25zZRImCgZldmVudHMYASADKAsyDi5qb25saW5lLkV2ZW50UgZldm'
    'VudHM=');

@$core.Deprecated('Use eventDescriptor instead')
const Event$json = {
  '1': 'Event',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'post', '3': 2, '4': 1, '5': 11, '6': '.jonline.Post', '10': 'post'},
    {'1': 'info', '3': 3, '4': 1, '5': 11, '6': '.jonline.EventInfo', '10': 'info'},
    {'1': 'instances', '3': 4, '4': 3, '5': 11, '6': '.jonline.EventInstance', '10': 'instances'},
  ],
};

/// Descriptor for `Event`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventDescriptor = $convert.base64Decode(
    'CgVFdmVudBIOCgJpZBgBIAEoCVICaWQSIQoEcG9zdBgCIAEoCzINLmpvbmxpbmUuUG9zdFIEcG'
    '9zdBImCgRpbmZvGAMgASgLMhIuam9ubGluZS5FdmVudEluZm9SBGluZm8SNAoJaW5zdGFuY2Vz'
    'GAQgAygLMhYuam9ubGluZS5FdmVudEluc3RhbmNlUglpbnN0YW5jZXM=');

@$core.Deprecated('Use eventInfoDescriptor instead')
const EventInfo$json = {
  '1': 'EventInfo',
};

/// Descriptor for `EventInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInfoDescriptor = $convert.base64Decode(
    'CglFdmVudEluZm8=');

@$core.Deprecated('Use eventInstanceDescriptor instead')
const EventInstance$json = {
  '1': 'EventInstance',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'event_id', '3': 2, '4': 1, '5': 9, '10': 'eventId'},
    {'1': 'post', '3': 3, '4': 1, '5': 11, '6': '.jonline.Post', '9': 0, '10': 'post', '17': true},
    {'1': 'info', '3': 4, '4': 1, '5': 11, '6': '.jonline.EventInstanceInfo', '10': 'info'},
    {'1': 'starts_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'startsAt'},
    {'1': 'ends_at', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'endsAt'},
  ],
  '8': [
    {'1': '_post'},
  ],
};

/// Descriptor for `EventInstance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInstanceDescriptor = $convert.base64Decode(
    'Cg1FdmVudEluc3RhbmNlEg4KAmlkGAEgASgJUgJpZBIZCghldmVudF9pZBgCIAEoCVIHZXZlbn'
    'RJZBImCgRwb3N0GAMgASgLMg0uam9ubGluZS5Qb3N0SABSBHBvc3SIAQESLgoEaW5mbxgEIAEo'
    'CzIaLmpvbmxpbmUuRXZlbnRJbnN0YW5jZUluZm9SBGluZm8SNwoJc3RhcnRzX2F0GAUgASgLMh'
    'ouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIIc3RhcnRzQXQSMwoHZW5kc19hdBgGIAEoCzIa'
    'Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSBmVuZHNBdEIHCgVfcG9zdA==');

@$core.Deprecated('Use eventInstanceInfoDescriptor instead')
const EventInstanceInfo$json = {
  '1': 'EventInstanceInfo',
};

/// Descriptor for `EventInstanceInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInstanceInfoDescriptor = $convert.base64Decode(
    'ChFFdmVudEluc3RhbmNlSW5mbw==');

@$core.Deprecated('Use eventAttendanceDescriptor instead')
const EventAttendance$json = {
  '1': 'EventAttendance',
  '2': [
    {'1': 'event_instance_id', '3': 1, '4': 1, '5': 9, '10': 'eventInstanceId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'status', '3': 3, '4': 1, '5': 14, '6': '.jonline.AttendanceStatus', '10': 'status'},
    {'1': 'inviting_user_id', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'invitingUserId', '17': true},
    {'1': 'created_at', '3': 10, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 11, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 1, '10': 'updatedAt', '17': true},
  ],
  '8': [
    {'1': '_inviting_user_id'},
    {'1': '_updated_at'},
  ],
};

/// Descriptor for `EventAttendance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventAttendanceDescriptor = $convert.base64Decode(
    'Cg9FdmVudEF0dGVuZGFuY2USKgoRZXZlbnRfaW5zdGFuY2VfaWQYASABKAlSD2V2ZW50SW5zdG'
    'FuY2VJZBIXCgd1c2VyX2lkGAIgASgJUgZ1c2VySWQSMQoGc3RhdHVzGAMgASgOMhkuam9ubGlu'
    'ZS5BdHRlbmRhbmNlU3RhdHVzUgZzdGF0dXMSLQoQaW52aXRpbmdfdXNlcl9pZBgEIAEoCUgAUg'
    '5pbnZpdGluZ1VzZXJJZIgBARI5CgpjcmVhdGVkX2F0GAogASgLMhouZ29vZ2xlLnByb3RvYnVm'
    'LlRpbWVzdGFtcFIJY3JlYXRlZEF0Ej4KCnVwZGF0ZWRfYXQYCyABKAsyGi5nb29nbGUucHJvdG'
    '9idWYuVGltZXN0YW1wSAFSCXVwZGF0ZWRBdIgBAUITChFfaW52aXRpbmdfdXNlcl9pZEINCgtf'
    'dXBkYXRlZF9hdA==');

