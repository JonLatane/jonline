//
//  Generated code. Do not modify.
//  source: events.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
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
  '2': [
    {'1': 'allows_rsvps', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'allowsRsvps', '17': true},
    {'1': 'allows_anonymous_rsvps', '3': 2, '4': 1, '5': 8, '9': 1, '10': 'allowsAnonymousRsvps', '17': true},
  ],
  '8': [
    {'1': '_allows_rsvps'},
    {'1': '_allows_anonymous_rsvps'},
  ],
};

/// Descriptor for `EventInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInfoDescriptor = $convert.base64Decode(
    'CglFdmVudEluZm8SJgoMYWxsb3dzX3JzdnBzGAEgASgISABSC2FsbG93c1JzdnBziAEBEjkKFm'
    'FsbG93c19hbm9ueW1vdXNfcnN2cHMYAiABKAhIAVIUYWxsb3dzQW5vbnltb3VzUnN2cHOIAQFC'
    'DwoNX2FsbG93c19yc3Zwc0IZChdfYWxsb3dzX2Fub255bW91c19yc3Zwcw==');

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
    {'1': 'location', '3': 7, '4': 1, '5': 11, '6': '.jonline.Location', '9': 1, '10': 'location', '17': true},
  ],
  '8': [
    {'1': '_post'},
    {'1': '_location'},
  ],
};

/// Descriptor for `EventInstance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInstanceDescriptor = $convert.base64Decode(
    'Cg1FdmVudEluc3RhbmNlEg4KAmlkGAEgASgJUgJpZBIZCghldmVudF9pZBgCIAEoCVIHZXZlbn'
    'RJZBImCgRwb3N0GAMgASgLMg0uam9ubGluZS5Qb3N0SABSBHBvc3SIAQESLgoEaW5mbxgEIAEo'
    'CzIaLmpvbmxpbmUuRXZlbnRJbnN0YW5jZUluZm9SBGluZm8SNwoJc3RhcnRzX2F0GAUgASgLMh'
    'ouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIIc3RhcnRzQXQSMwoHZW5kc19hdBgGIAEoCzIa'
    'Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSBmVuZHNBdBIyCghsb2NhdGlvbhgHIAEoCzIRLm'
    'pvbmxpbmUuTG9jYXRpb25IAVIIbG9jYXRpb26IAQFCBwoFX3Bvc3RCCwoJX2xvY2F0aW9u');

@$core.Deprecated('Use eventInstanceInfoDescriptor instead')
const EventInstanceInfo$json = {
  '1': 'EventInstanceInfo',
};

/// Descriptor for `EventInstanceInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInstanceInfoDescriptor = $convert.base64Decode(
    'ChFFdmVudEluc3RhbmNlSW5mbw==');

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
  ],
};

/// Descriptor for `EventAttendances`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventAttendancesDescriptor = $convert.base64Decode(
    'ChBFdmVudEF0dGVuZGFuY2VzEjoKC2F0dGVuZGFuY2VzGAEgAygLMhguam9ubGluZS5FdmVudE'
    'F0dGVuZGFuY2VSC2F0dGVuZGFuY2Vz');

@$core.Deprecated('Use eventAttendanceDescriptor instead')
const EventAttendance$json = {
  '1': 'EventAttendance',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'event_instance_id', '3': 2, '4': 1, '5': 9, '10': 'eventInstanceId'},
    {'1': 'user_attendee', '3': 3, '4': 1, '5': 11, '6': '.jonline.Author', '9': 0, '10': 'userAttendee'},
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
    'IgASgJUg9ldmVudEluc3RhbmNlSWQSNgoNdXNlcl9hdHRlbmRlZRgDIAEoCzIPLmpvbmxpbmUu'
    'QXV0aG9ySABSDHVzZXJBdHRlbmRlZRJLChJhbm9ueW1vdXNfYXR0ZW5kZWUYBCABKAsyGi5qb2'
    '5saW5lLkFub255bW91c0F0dGVuZGVlSABSEWFub255bW91c0F0dGVuZGVlEigKEG51bWJlcl9v'
    'Zl9ndWVzdHMYBSABKA1SDm51bWJlck9mR3Vlc3RzEjEKBnN0YXR1cxgGIAEoDjIZLmpvbmxpbm'
    'UuQXR0ZW5kYW5jZVN0YXR1c1IGc3RhdHVzEi0KEGludml0aW5nX3VzZXJfaWQYByABKAlIAVIO'
    'aW52aXRpbmdVc2VySWSIAQESIQoMcHJpdmF0ZV9ub3RlGAggASgJUgtwcml2YXRlTm90ZRIfCg'
    'twdWJsaWNfbm90ZRgJIAEoCVIKcHVibGljTm90ZRIzCgptb2RlcmF0aW9uGAogASgOMhMuam9u'
    'bGluZS5Nb2RlcmF0aW9uUgptb2RlcmF0aW9uEjkKCmNyZWF0ZWRfYXQYCyABKAsyGi5nb29nbG'
    'UucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQSPgoKdXBkYXRlZF9hdBgMIAEoCzIaLmdv'
    'b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIAlIJdXBkYXRlZEF0iAEBQgoKCGF0dGVuZGVlQhMKEV'
    '9pbnZpdGluZ191c2VyX2lkQg0KC191cGRhdGVkX2F0');

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

