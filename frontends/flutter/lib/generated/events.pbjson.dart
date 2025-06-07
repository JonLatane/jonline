//
//  Generated code. Do not modify.
//  source: events.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use eventListingTypeDescriptor instead')
const EventListingType$json = {
  '1': 'EventListingType',
  '2': [
    {'1': 'ALL_ACCESSIBLE_EVENTS', '2': 0},
    {'1': 'FOLLOWING_EVENTS', '2': 1},
    {'1': 'MY_GROUPS_EVENTS', '2': 2},
    {'1': 'DIRECT_EVENTS', '2': 3},
    {'1': 'EVENTS_PENDING_MODERATION', '2': 4},
    {'1': 'GROUP_EVENTS', '2': 10},
    {'1': 'GROUP_EVENTS_PENDING_MODERATION', '2': 11},
    {'1': 'NEWLY_ADDED_EVENTS', '2': 20},
  ],
};

/// Descriptor for `EventListingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List eventListingTypeDescriptor = $convert.base64Decode(
    'ChBFdmVudExpc3RpbmdUeXBlEhkKFUFMTF9BQ0NFU1NJQkxFX0VWRU5UUxAAEhQKEEZPTExPV0'
    'lOR19FVkVOVFMQARIUChBNWV9HUk9VUFNfRVZFTlRTEAISEQoNRElSRUNUX0VWRU5UUxADEh0K'
    'GUVWRU5UU19QRU5ESU5HX01PREVSQVRJT04QBBIQCgxHUk9VUF9FVkVOVFMQChIjCh9HUk9VUF'
    '9FVkVOVFNfUEVORElOR19NT0RFUkFUSU9OEAsSFgoSTkVXTFlfQURERURfRVZFTlRTEBQ=');

@$core.Deprecated('Use attendanceStatusDescriptor instead')
const AttendanceStatus$json = {
  '1': 'AttendanceStatus',
  '2': [
    {'1': 'INTERESTED', '2': 0},
    {'1': 'REQUESTED', '2': 1},
    {'1': 'GOING', '2': 2},
    {'1': 'NOT_GOING', '2': 3},
  ],
};

/// Descriptor for `AttendanceStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List attendanceStatusDescriptor = $convert.base64Decode(
    'ChBBdHRlbmRhbmNlU3RhdHVzEg4KCklOVEVSRVNURUQQABINCglSRVFVRVNURUQQARIJCgVHT0'
    'lORxACEg0KCU5PVF9HT0lORxAD');

@$core.Deprecated('Use getEventsRequestDescriptor instead')
const GetEventsRequest$json = {
  '1': 'GetEventsRequest',
  '2': [
    {'1': 'event_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'eventId', '17': true},
    {'1': 'author_user_id', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'authorUserId', '17': true},
    {'1': 'group_id', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'groupId', '17': true},
    {'1': 'event_instance_id', '3': 4, '4': 1, '5': 9, '9': 3, '10': 'eventInstanceId', '17': true},
    {'1': 'time_filter', '3': 5, '4': 1, '5': 11, '6': '.jonline.TimeFilter', '9': 4, '10': 'timeFilter', '17': true},
    {'1': 'attendee_id', '3': 6, '4': 1, '5': 9, '9': 5, '10': 'attendeeId', '17': true},
    {'1': 'attendance_statuses', '3': 7, '4': 3, '5': 14, '6': '.jonline.AttendanceStatus', '10': 'attendanceStatuses'},
    {'1': 'post_id', '3': 8, '4': 1, '5': 9, '9': 6, '10': 'postId', '17': true},
    {'1': 'listing_type', '3': 10, '4': 1, '5': 14, '6': '.jonline.EventListingType', '10': 'listingType'},
  ],
  '8': [
    {'1': '_event_id'},
    {'1': '_author_user_id'},
    {'1': '_group_id'},
    {'1': '_event_instance_id'},
    {'1': '_time_filter'},
    {'1': '_attendee_id'},
    {'1': '_post_id'},
  ],
};

/// Descriptor for `GetEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEventsRequestDescriptor = $convert.base64Decode(
    'ChBHZXRFdmVudHNSZXF1ZXN0Eh4KCGV2ZW50X2lkGAEgASgJSABSB2V2ZW50SWSIAQESKQoOYX'
    'V0aG9yX3VzZXJfaWQYAiABKAlIAVIMYXV0aG9yVXNlcklkiAEBEh4KCGdyb3VwX2lkGAMgASgJ'
    'SAJSB2dyb3VwSWSIAQESLwoRZXZlbnRfaW5zdGFuY2VfaWQYBCABKAlIA1IPZXZlbnRJbnN0YW'
    '5jZUlkiAEBEjkKC3RpbWVfZmlsdGVyGAUgASgLMhMuam9ubGluZS5UaW1lRmlsdGVySARSCnRp'
    'bWVGaWx0ZXKIAQESJAoLYXR0ZW5kZWVfaWQYBiABKAlIBVIKYXR0ZW5kZWVJZIgBARJKChNhdH'
    'RlbmRhbmNlX3N0YXR1c2VzGAcgAygOMhkuam9ubGluZS5BdHRlbmRhbmNlU3RhdHVzUhJhdHRl'
    'bmRhbmNlU3RhdHVzZXMSHAoHcG9zdF9pZBgIIAEoCUgGUgZwb3N0SWSIAQESPAoMbGlzdGluZ1'
    '90eXBlGAogASgOMhkuam9ubGluZS5FdmVudExpc3RpbmdUeXBlUgtsaXN0aW5nVHlwZUILCglf'
    'ZXZlbnRfaWRCEQoPX2F1dGhvcl91c2VyX2lkQgsKCV9ncm91cF9pZEIUChJfZXZlbnRfaW5zdG'
    'FuY2VfaWRCDgoMX3RpbWVfZmlsdGVyQg4KDF9hdHRlbmRlZV9pZEIKCghfcG9zdF9pZA==');

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
  '2': [
    {'1': 'allows_rsvps', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'allowsRsvps', '17': true},
    {'1': 'allows_anonymous_rsvps', '3': 2, '4': 1, '5': 8, '9': 1, '10': 'allowsAnonymousRsvps', '17': true},
    {'1': 'max_attendees', '3': 3, '4': 1, '5': 13, '9': 2, '10': 'maxAttendees', '17': true},
    {'1': 'hide_location_until_rsvp_approved', '3': 4, '4': 1, '5': 8, '9': 3, '10': 'hideLocationUntilRsvpApproved', '17': true},
    {'1': 'default_rsvp_moderation', '3': 5, '4': 1, '5': 14, '6': '.jonline.Moderation', '9': 4, '10': 'defaultRsvpModeration', '17': true},
  ],
  '8': [
    {'1': '_allows_rsvps'},
    {'1': '_allows_anonymous_rsvps'},
    {'1': '_max_attendees'},
    {'1': '_hide_location_until_rsvp_approved'},
    {'1': '_default_rsvp_moderation'},
  ],
};

/// Descriptor for `EventInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInfoDescriptor = $convert.base64Decode(
    'CglFdmVudEluZm8SJgoMYWxsb3dzX3JzdnBzGAEgASgISABSC2FsbG93c1JzdnBziAEBEjkKFm'
    'FsbG93c19hbm9ueW1vdXNfcnN2cHMYAiABKAhIAVIUYWxsb3dzQW5vbnltb3VzUnN2cHOIAQES'
    'KAoNbWF4X2F0dGVuZGVlcxgDIAEoDUgCUgxtYXhBdHRlbmRlZXOIAQESTQohaGlkZV9sb2NhdG'
    'lvbl91bnRpbF9yc3ZwX2FwcHJvdmVkGAQgASgISANSHWhpZGVMb2NhdGlvblVudGlsUnN2cEFw'
    'cHJvdmVkiAEBElAKF2RlZmF1bHRfcnN2cF9tb2RlcmF0aW9uGAUgASgOMhMuam9ubGluZS5Nb2'
    'RlcmF0aW9uSARSFWRlZmF1bHRSc3ZwTW9kZXJhdGlvbogBAUIPCg1fYWxsb3dzX3JzdnBzQhkK'
    'F19hbGxvd3NfYW5vbnltb3VzX3JzdnBzQhAKDl9tYXhfYXR0ZW5kZWVzQiQKIl9oaWRlX2xvY2'
    'F0aW9uX3VudGlsX3JzdnBfYXBwcm92ZWRCGgoYX2RlZmF1bHRfcnN2cF9tb2RlcmF0aW9u');

@$core.Deprecated('Use eventInstanceDescriptor instead')
const EventInstance$json = {
  '1': 'EventInstance',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'event_id', '3': 2, '4': 1, '5': 9, '10': 'eventId'},
    {'1': 'post', '3': 3, '4': 1, '5': 11, '6': '.jonline.Post', '10': 'post'},
    {'1': 'info', '3': 4, '4': 1, '5': 11, '6': '.jonline.EventInstanceInfo', '10': 'info'},
    {'1': 'starts_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'startsAt'},
    {'1': 'ends_at', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'endsAt'},
    {'1': 'location', '3': 7, '4': 1, '5': 11, '6': '.jonline.Location', '9': 0, '10': 'location', '17': true},
  ],
  '8': [
    {'1': '_location'},
  ],
};

/// Descriptor for `EventInstance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInstanceDescriptor = $convert.base64Decode(
    'Cg1FdmVudEluc3RhbmNlEg4KAmlkGAEgASgJUgJpZBIZCghldmVudF9pZBgCIAEoCVIHZXZlbn'
    'RJZBIhCgRwb3N0GAMgASgLMg0uam9ubGluZS5Qb3N0UgRwb3N0Ei4KBGluZm8YBCABKAsyGi5q'
    'b25saW5lLkV2ZW50SW5zdGFuY2VJbmZvUgRpbmZvEjcKCXN0YXJ0c19hdBgFIAEoCzIaLmdvb2'
    'dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCHN0YXJ0c0F0EjMKB2VuZHNfYXQYBiABKAsyGi5nb29n'
    'bGUucHJvdG9idWYuVGltZXN0YW1wUgZlbmRzQXQSMgoIbG9jYXRpb24YByABKAsyES5qb25saW'
    '5lLkxvY2F0aW9uSABSCGxvY2F0aW9uiAEBQgsKCV9sb2NhdGlvbg==');

@$core.Deprecated('Use eventInstanceInfoDescriptor instead')
const EventInstanceInfo$json = {
  '1': 'EventInstanceInfo',
  '2': [
    {'1': 'rsvp_info', '3': 1, '4': 1, '5': 11, '6': '.jonline.EventInstanceRsvpInfo', '9': 0, '10': 'rsvpInfo', '17': true},
  ],
  '8': [
    {'1': '_rsvp_info'},
  ],
};

/// Descriptor for `EventInstanceInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInstanceInfoDescriptor = $convert.base64Decode(
    'ChFFdmVudEluc3RhbmNlSW5mbxJACglyc3ZwX2luZm8YASABKAsyHi5qb25saW5lLkV2ZW50SW'
    '5zdGFuY2VSc3ZwSW5mb0gAUghyc3ZwSW5mb4gBAUIMCgpfcnN2cF9pbmZv');

@$core.Deprecated('Use eventInstanceRsvpInfoDescriptor instead')
const EventInstanceRsvpInfo$json = {
  '1': 'EventInstanceRsvpInfo',
  '2': [
    {'1': 'allows_rsvps', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'allowsRsvps', '17': true},
    {'1': 'allows_anonymous_rsvps', '3': 2, '4': 1, '5': 8, '9': 1, '10': 'allowsAnonymousRsvps', '17': true},
    {'1': 'max_attendees', '3': 3, '4': 1, '5': 13, '9': 2, '10': 'maxAttendees', '17': true},
    {'1': 'going_rsvps', '3': 4, '4': 1, '5': 13, '9': 3, '10': 'goingRsvps', '17': true},
    {'1': 'going_attendees', '3': 5, '4': 1, '5': 13, '9': 4, '10': 'goingAttendees', '17': true},
    {'1': 'interested_rsvps', '3': 6, '4': 1, '5': 13, '9': 5, '10': 'interestedRsvps', '17': true},
    {'1': 'interested_attendees', '3': 7, '4': 1, '5': 13, '9': 6, '10': 'interestedAttendees', '17': true},
    {'1': 'invited_rsvps', '3': 8, '4': 1, '5': 13, '9': 7, '10': 'invitedRsvps', '17': true},
    {'1': 'invited_attendees', '3': 9, '4': 1, '5': 13, '9': 8, '10': 'invitedAttendees', '17': true},
  ],
  '8': [
    {'1': '_allows_rsvps'},
    {'1': '_allows_anonymous_rsvps'},
    {'1': '_max_attendees'},
    {'1': '_going_rsvps'},
    {'1': '_going_attendees'},
    {'1': '_interested_rsvps'},
    {'1': '_interested_attendees'},
    {'1': '_invited_rsvps'},
    {'1': '_invited_attendees'},
  ],
};

/// Descriptor for `EventInstanceRsvpInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInstanceRsvpInfoDescriptor = $convert.base64Decode(
    'ChVFdmVudEluc3RhbmNlUnN2cEluZm8SJgoMYWxsb3dzX3JzdnBzGAEgASgISABSC2FsbG93c1'
    'JzdnBziAEBEjkKFmFsbG93c19hbm9ueW1vdXNfcnN2cHMYAiABKAhIAVIUYWxsb3dzQW5vbnlt'
    'b3VzUnN2cHOIAQESKAoNbWF4X2F0dGVuZGVlcxgDIAEoDUgCUgxtYXhBdHRlbmRlZXOIAQESJA'
    'oLZ29pbmdfcnN2cHMYBCABKA1IA1IKZ29pbmdSc3Zwc4gBARIsCg9nb2luZ19hdHRlbmRlZXMY'
    'BSABKA1IBFIOZ29pbmdBdHRlbmRlZXOIAQESLgoQaW50ZXJlc3RlZF9yc3ZwcxgGIAEoDUgFUg'
    '9pbnRlcmVzdGVkUnN2cHOIAQESNgoUaW50ZXJlc3RlZF9hdHRlbmRlZXMYByABKA1IBlITaW50'
    'ZXJlc3RlZEF0dGVuZGVlc4gBARIoCg1pbnZpdGVkX3JzdnBzGAggASgNSAdSDGludml0ZWRSc3'
    'Zwc4gBARIwChFpbnZpdGVkX2F0dGVuZGVlcxgJIAEoDUgIUhBpbnZpdGVkQXR0ZW5kZWVziAEB'
    'Qg8KDV9hbGxvd3NfcnN2cHNCGQoXX2FsbG93c19hbm9ueW1vdXNfcnN2cHNCEAoOX21heF9hdH'
    'RlbmRlZXNCDgoMX2dvaW5nX3JzdnBzQhIKEF9nb2luZ19hdHRlbmRlZXNCEwoRX2ludGVyZXN0'
    'ZWRfcnN2cHNCFwoVX2ludGVyZXN0ZWRfYXR0ZW5kZWVzQhAKDl9pbnZpdGVkX3JzdnBzQhQKEl'
    '9pbnZpdGVkX2F0dGVuZGVlcw==');

@$core.Deprecated('Use getEventAttendancesRequestDescriptor instead')
const GetEventAttendancesRequest$json = {
  '1': 'GetEventAttendancesRequest',
  '2': [
    {'1': 'event_instance_id', '3': 1, '4': 1, '5': 9, '10': 'eventInstanceId'},
    {'1': 'anonymous_attendee_auth_token', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'anonymousAttendeeAuthToken', '17': true},
  ],
  '8': [
    {'1': '_anonymous_attendee_auth_token'},
  ],
};

/// Descriptor for `GetEventAttendancesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEventAttendancesRequestDescriptor = $convert.base64Decode(
    'ChpHZXRFdmVudEF0dGVuZGFuY2VzUmVxdWVzdBIqChFldmVudF9pbnN0YW5jZV9pZBgBIAEoCV'
    'IPZXZlbnRJbnN0YW5jZUlkEkYKHWFub255bW91c19hdHRlbmRlZV9hdXRoX3Rva2VuGAIgASgJ'
    'SABSGmFub255bW91c0F0dGVuZGVlQXV0aFRva2VuiAEBQiAKHl9hbm9ueW1vdXNfYXR0ZW5kZW'
    'VfYXV0aF90b2tlbg==');

@$core.Deprecated('Use eventAttendancesDescriptor instead')
const EventAttendances$json = {
  '1': 'EventAttendances',
  '2': [
    {'1': 'attendances', '3': 1, '4': 3, '5': 11, '6': '.jonline.EventAttendance', '10': 'attendances'},
    {'1': 'hidden_location', '3': 2, '4': 1, '5': 11, '6': '.jonline.Location', '9': 0, '10': 'hiddenLocation', '17': true},
  ],
  '8': [
    {'1': '_hidden_location'},
  ],
};

/// Descriptor for `EventAttendances`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventAttendancesDescriptor = $convert.base64Decode(
    'ChBFdmVudEF0dGVuZGFuY2VzEjoKC2F0dGVuZGFuY2VzGAEgAygLMhguam9ubGluZS5FdmVudE'
    'F0dGVuZGFuY2VSC2F0dGVuZGFuY2VzEj8KD2hpZGRlbl9sb2NhdGlvbhgCIAEoCzIRLmpvbmxp'
    'bmUuTG9jYXRpb25IAFIOaGlkZGVuTG9jYXRpb26IAQFCEgoQX2hpZGRlbl9sb2NhdGlvbg==');

@$core.Deprecated('Use eventAttendanceDescriptor instead')
const EventAttendance$json = {
  '1': 'EventAttendance',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'event_instance_id', '3': 2, '4': 1, '5': 9, '10': 'eventInstanceId'},
    {'1': 'user_attendee', '3': 3, '4': 1, '5': 11, '6': '.jonline.UserAttendee', '9': 0, '10': 'userAttendee'},
    {'1': 'anonymous_attendee', '3': 4, '4': 1, '5': 11, '6': '.jonline.AnonymousAttendee', '9': 0, '10': 'anonymousAttendee'},
    {'1': 'number_of_guests', '3': 5, '4': 1, '5': 13, '10': 'numberOfGuests'},
    {'1': 'status', '3': 6, '4': 1, '5': 14, '6': '.jonline.AttendanceStatus', '10': 'status'},
    {'1': 'inviting_user_id', '3': 7, '4': 1, '5': 9, '9': 1, '10': 'invitingUserId', '17': true},
    {'1': 'private_note', '3': 8, '4': 1, '5': 9, '10': 'privateNote'},
    {'1': 'public_note', '3': 9, '4': 1, '5': 9, '10': 'publicNote'},
    {'1': 'moderation', '3': 10, '4': 1, '5': 14, '6': '.jonline.Moderation', '10': 'moderation'},
    {'1': 'created_at', '3': 11, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 12, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 2, '10': 'updatedAt', '17': true},
  ],
  '8': [
    {'1': 'attendee'},
    {'1': '_inviting_user_id'},
    {'1': '_updated_at'},
  ],
};

/// Descriptor for `EventAttendance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventAttendanceDescriptor = $convert.base64Decode(
    'Cg9FdmVudEF0dGVuZGFuY2USDgoCaWQYASABKAlSAmlkEioKEWV2ZW50X2luc3RhbmNlX2lkGA'
    'IgASgJUg9ldmVudEluc3RhbmNlSWQSPAoNdXNlcl9hdHRlbmRlZRgDIAEoCzIVLmpvbmxpbmUu'
    'VXNlckF0dGVuZGVlSABSDHVzZXJBdHRlbmRlZRJLChJhbm9ueW1vdXNfYXR0ZW5kZWUYBCABKA'
    'syGi5qb25saW5lLkFub255bW91c0F0dGVuZGVlSABSEWFub255bW91c0F0dGVuZGVlEigKEG51'
    'bWJlcl9vZl9ndWVzdHMYBSABKA1SDm51bWJlck9mR3Vlc3RzEjEKBnN0YXR1cxgGIAEoDjIZLm'
    'pvbmxpbmUuQXR0ZW5kYW5jZVN0YXR1c1IGc3RhdHVzEi0KEGludml0aW5nX3VzZXJfaWQYByAB'
    'KAlIAVIOaW52aXRpbmdVc2VySWSIAQESIQoMcHJpdmF0ZV9ub3RlGAggASgJUgtwcml2YXRlTm'
    '90ZRIfCgtwdWJsaWNfbm90ZRgJIAEoCVIKcHVibGljTm90ZRIzCgptb2RlcmF0aW9uGAogASgO'
    'MhMuam9ubGluZS5Nb2RlcmF0aW9uUgptb2RlcmF0aW9uEjkKCmNyZWF0ZWRfYXQYCyABKAsyGi'
    '5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQSPgoKdXBkYXRlZF9hdBgMIAEo'
    'CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIAlIJdXBkYXRlZEF0iAEBQgoKCGF0dGVuZG'
    'VlQhMKEV9pbnZpdGluZ191c2VyX2lkQg0KC191cGRhdGVkX2F0');

@$core.Deprecated('Use anonymousAttendeeDescriptor instead')
const AnonymousAttendee$json = {
  '1': 'AnonymousAttendee',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'contact_methods', '3': 2, '4': 3, '5': 11, '6': '.jonline.ContactMethod', '10': 'contactMethods'},
    {'1': 'auth_token', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'authToken', '17': true},
  ],
  '8': [
    {'1': '_auth_token'},
  ],
};

/// Descriptor for `AnonymousAttendee`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List anonymousAttendeeDescriptor = $convert.base64Decode(
    'ChFBbm9ueW1vdXNBdHRlbmRlZRISCgRuYW1lGAEgASgJUgRuYW1lEj8KD2NvbnRhY3RfbWV0aG'
    '9kcxgCIAMoCzIWLmpvbmxpbmUuQ29udGFjdE1ldGhvZFIOY29udGFjdE1ldGhvZHMSIgoKYXV0'
    'aF90b2tlbhgDIAEoCUgAUglhdXRoVG9rZW6IAQFCDQoLX2F1dGhfdG9rZW4=');

@$core.Deprecated('Use userAttendeeDescriptor instead')
const UserAttendee$json = {
  '1': 'UserAttendee',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'username', '17': true},
    {'1': 'avatar', '3': 3, '4': 1, '5': 11, '6': '.jonline.MediaReference', '9': 1, '10': 'avatar', '17': true},
    {'1': 'real_name', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'realName', '17': true},
    {'1': 'permissions', '3': 5, '4': 3, '5': 14, '6': '.jonline.Permission', '10': 'permissions'},
  ],
  '8': [
    {'1': '_username'},
    {'1': '_avatar'},
    {'1': '_real_name'},
  ],
};

/// Descriptor for `UserAttendee`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userAttendeeDescriptor = $convert.base64Decode(
    'CgxVc2VyQXR0ZW5kZWUSFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEh8KCHVzZXJuYW1lGAIgAS'
    'gJSABSCHVzZXJuYW1liAEBEjQKBmF2YXRhchgDIAEoCzIXLmpvbmxpbmUuTWVkaWFSZWZlcmVu'
    'Y2VIAVIGYXZhdGFyiAEBEiAKCXJlYWxfbmFtZRgEIAEoCUgCUghyZWFsTmFtZYgBARI1CgtwZX'
    'JtaXNzaW9ucxgFIAMoDjITLmpvbmxpbmUuUGVybWlzc2lvblILcGVybWlzc2lvbnNCCwoJX3Vz'
    'ZXJuYW1lQgkKB19hdmF0YXJCDAoKX3JlYWxfbmFtZQ==');

