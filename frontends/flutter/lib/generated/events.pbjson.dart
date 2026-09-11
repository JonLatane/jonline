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
    {'1': 'ALL_ACCESSIBLE_EVENTS', '2': 0},
    {'1': 'FOLLOWING_EVENTS', '2': 1},
    {'1': 'MY_GROUPS_EVENTS', '2': 2},
    {'1': 'DIRECT_EVENTS', '2': 3},
    {'1': 'EVENTS_PENDING_MODERATION', '2': 4},
    {'1': 'EVENT_TEXT_SEARCH', '2': 5},
    {'1': 'GROUP_EVENTS', '2': 10},
    {'1': 'GROUP_EVENTS_PENDING_MODERATION', '2': 11},
    {'1': 'NEWLY_ADDED_EVENTS', '2': 20},
  ],
};

/// Descriptor for `EventListingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List eventListingTypeDescriptor = $convert.base64Decode(
    'ChBFdmVudExpc3RpbmdUeXBlEhkKFUFMTF9BQ0NFU1NJQkxFX0VWRU5UUxAAEhQKEEZPTExPV0'
    'lOR19FVkVOVFMQARIUChBNWV9HUk9VUFNfRVZFTlRTEAISEQoNRElSRUNUX0VWRU5UUxADEh0K'
    'GUVWRU5UU19QRU5ESU5HX01PREVSQVRJT04QBBIVChFFVkVOVF9URVhUX1NFQVJDSBAFEhAKDE'
    'dST1VQX0VWRU5UUxAKEiMKH0dST1VQX0VWRU5UU19QRU5ESU5HX01PREVSQVRJT04QCxIWChJO'
    'RVdMWV9BRERFRF9FVkVOVFMQFA==');

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
    {'1': 'author_user_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'authorUserId', '17': true},
    {'1': 'group_id', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'groupId', '17': true},
    {'1': 'time_filter', '3': 5, '4': 1, '5': 11, '6': '.rellm.TimeFilter', '9': 2, '10': 'timeFilter', '17': true},
    {'1': 'attendee_id', '3': 6, '4': 1, '5': 9, '9': 3, '10': 'attendeeId', '17': true},
    {'1': 'attendance_statuses', '3': 7, '4': 3, '5': 14, '6': '.rellm.AttendanceStatus', '10': 'attendanceStatuses'},
    {'1': 'post_id', '3': 8, '4': 1, '5': 9, '9': 4, '10': 'postId', '17': true},
    {'1': 'listing_type', '3': 10, '4': 1, '5': 14, '6': '.rellm.EventListingType', '10': 'listingType'},
    {'1': 'search_text', '3': 11, '4': 1, '5': 9, '9': 5, '10': 'searchText', '17': true},
    {'1': 'event_instance_post_ids', '3': 12, '4': 3, '5': 9, '10': 'eventInstancePostIds'},
    {'1': 'anonymous_attendee_auth_token', '3': 13, '4': 1, '5': 9, '9': 6, '10': 'anonymousAttendeeAuthToken', '17': true},
  ],
  '8': [
    {'1': '_author_user_id'},
    {'1': '_group_id'},
    {'1': '_time_filter'},
    {'1': '_attendee_id'},
    {'1': '_post_id'},
    {'1': '_search_text'},
    {'1': '_anonymous_attendee_auth_token'},
  ],
  '9': [
    {'1': 1, '2': 2},
    {'1': 4, '2': 5},
  ],
  '10': ['event_id', 'event_instance_id'],
};

/// Descriptor for `GetEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEventsRequestDescriptor = $convert.base64Decode(
    'ChBHZXRFdmVudHNSZXF1ZXN0EikKDmF1dGhvcl91c2VyX2lkGAIgASgJSABSDGF1dGhvclVzZX'
    'JJZIgBARIeCghncm91cF9pZBgDIAEoCUgBUgdncm91cElkiAEBEjcKC3RpbWVfZmlsdGVyGAUg'
    'ASgLMhEucmVsbG0uVGltZUZpbHRlckgCUgp0aW1lRmlsdGVyiAEBEiQKC2F0dGVuZGVlX2lkGA'
    'YgASgJSANSCmF0dGVuZGVlSWSIAQESSAoTYXR0ZW5kYW5jZV9zdGF0dXNlcxgHIAMoDjIXLnJl'
    'bGxtLkF0dGVuZGFuY2VTdGF0dXNSEmF0dGVuZGFuY2VTdGF0dXNlcxIcCgdwb3N0X2lkGAggAS'
    'gJSARSBnBvc3RJZIgBARI6CgxsaXN0aW5nX3R5cGUYCiABKA4yFy5yZWxsbS5FdmVudExpc3Rp'
    'bmdUeXBlUgtsaXN0aW5nVHlwZRIkCgtzZWFyY2hfdGV4dBgLIAEoCUgFUgpzZWFyY2hUZXh0iA'
    'EBEjUKF2V2ZW50X2luc3RhbmNlX3Bvc3RfaWRzGAwgAygJUhRldmVudEluc3RhbmNlUG9zdElk'
    'cxJGCh1hbm9ueW1vdXNfYXR0ZW5kZWVfYXV0aF90b2tlbhgNIAEoCUgGUhphbm9ueW1vdXNBdH'
    'RlbmRlZUF1dGhUb2tlbogBAUIRCg9fYXV0aG9yX3VzZXJfaWRCCwoJX2dyb3VwX2lkQg4KDF90'
    'aW1lX2ZpbHRlckIOCgxfYXR0ZW5kZWVfaWRCCgoIX3Bvc3RfaWRCDgoMX3NlYXJjaF90ZXh0Qi'
    'AKHl9hbm9ueW1vdXNfYXR0ZW5kZWVfYXV0aF90b2tlbkoECAEQAkoECAQQBVIIZXZlbnRfaWRS'
    'EWV2ZW50X2luc3RhbmNlX2lk');

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
    {'1': 'events', '3': 1, '4': 3, '5': 11, '6': '.rellm.Event', '10': 'events'},
  ],
};

/// Descriptor for `GetEventsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEventsResponseDescriptor = $convert.base64Decode(
    'ChFHZXRFdmVudHNSZXNwb25zZRIkCgZldmVudHMYASADKAsyDC5yZWxsbS5FdmVudFIGZXZlbn'
    'Rz');

@$core.Deprecated('Use eventDescriptor instead')
const Event$json = {
  '1': 'Event',
  '2': [
    {'1': 'post', '3': 2, '4': 1, '5': 11, '6': '.rellm.Post', '10': 'post'},
    {'1': 'info', '3': 3, '4': 1, '5': 11, '6': '.rellm.EventInfo', '10': 'info'},
    {'1': 'instances', '3': 4, '4': 3, '5': 11, '6': '.rellm.EventInstance', '10': 'instances'},
  ],
  '9': [
    {'1': 5, '2': 6},
  ],
  '10': ['sync_source'],
};

/// Descriptor for `Event`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventDescriptor = $convert.base64Decode(
    'CgVFdmVudBIfCgRwb3N0GAIgASgLMgsucmVsbG0uUG9zdFIEcG9zdBIkCgRpbmZvGAMgASgLMh'
    'AucmVsbG0uRXZlbnRJbmZvUgRpbmZvEjIKCWluc3RhbmNlcxgEIAMoCzIULnJlbGxtLkV2ZW50'
    'SW5zdGFuY2VSCWluc3RhbmNlc0oECAUQBlILc3luY19zb3VyY2U=');

@$core.Deprecated('Use syncEventInstanceRequestDescriptor instead')
const SyncEventInstanceRequest$json = {
  '1': 'SyncEventInstanceRequest',
  '2': [
    {'1': 'event_instance_id', '3': 1, '4': 1, '5': 9, '10': 'eventInstanceId'},
    {'1': 'sync_destination_id', '3': 2, '4': 1, '5': 9, '10': 'syncDestinationId'},
  ],
};

/// Descriptor for `SyncEventInstanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncEventInstanceRequestDescriptor = $convert.base64Decode(
    'ChhTeW5jRXZlbnRJbnN0YW5jZVJlcXVlc3QSKgoRZXZlbnRfaW5zdGFuY2VfaWQYASABKAlSD2'
    'V2ZW50SW5zdGFuY2VJZBIuChNzeW5jX2Rlc3RpbmF0aW9uX2lkGAIgASgJUhFzeW5jRGVzdGlu'
    'YXRpb25JZA==');

@$core.Deprecated('Use deleteEventInstanceSyncDestinationRequestDescriptor instead')
const DeleteEventInstanceSyncDestinationRequest$json = {
  '1': 'DeleteEventInstanceSyncDestinationRequest',
  '2': [
    {'1': 'event_instance_id', '3': 1, '4': 1, '5': 9, '10': 'eventInstanceId'},
    {'1': 'sync_destination_id', '3': 2, '4': 1, '5': 9, '10': 'syncDestinationId'},
  ],
};

/// Descriptor for `DeleteEventInstanceSyncDestinationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteEventInstanceSyncDestinationRequestDescriptor = $convert.base64Decode(
    'CilEZWxldGVFdmVudEluc3RhbmNlU3luY0Rlc3RpbmF0aW9uUmVxdWVzdBIqChFldmVudF9pbn'
    'N0YW5jZV9pZBgBIAEoCVIPZXZlbnRJbnN0YW5jZUlkEi4KE3N5bmNfZGVzdGluYXRpb25faWQY'
    'AiABKAlSEXN5bmNEZXN0aW5hdGlvbklk');

@$core.Deprecated('Use eventInfoDescriptor instead')
const EventInfo$json = {
  '1': 'EventInfo',
  '2': [
    {'1': 'allows_rsvps', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'allowsRsvps', '17': true},
    {'1': 'allows_anonymous_rsvps', '3': 2, '4': 1, '5': 8, '9': 1, '10': 'allowsAnonymousRsvps', '17': true},
    {'1': 'max_attendees', '3': 3, '4': 1, '5': 13, '9': 2, '10': 'maxAttendees', '17': true},
    {'1': 'hide_location_until_rsvp_approved', '3': 4, '4': 1, '5': 8, '9': 3, '10': 'hideLocationUntilRsvpApproved', '17': true},
    {'1': 'default_rsvp_moderation', '3': 5, '4': 1, '5': 14, '6': '.rellm.Moderation', '9': 4, '10': 'defaultRsvpModeration', '17': true},
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
    'cHJvdmVkiAEBEk4KF2RlZmF1bHRfcnN2cF9tb2RlcmF0aW9uGAUgASgOMhEucmVsbG0uTW9kZX'
    'JhdGlvbkgEUhVkZWZhdWx0UnN2cE1vZGVyYXRpb26IAQFCDwoNX2FsbG93c19yc3Zwc0IZChdf'
    'YWxsb3dzX2Fub255bW91c19yc3Zwc0IQCg5fbWF4X2F0dGVuZGVlc0IkCiJfaGlkZV9sb2NhdG'
    'lvbl91bnRpbF9yc3ZwX2FwcHJvdmVkQhoKGF9kZWZhdWx0X3JzdnBfbW9kZXJhdGlvbg==');

@$core.Deprecated('Use eventInstanceDescriptor instead')
const EventInstance$json = {
  '1': 'EventInstance',
  '2': [
    {'1': 'event_id', '3': 2, '4': 1, '5': 9, '10': 'eventId'},
    {'1': 'post', '3': 3, '4': 1, '5': 11, '6': '.rellm.Post', '10': 'post'},
    {'1': 'info', '3': 4, '4': 1, '5': 11, '6': '.rellm.EventInstanceInfo', '10': 'info'},
    {'1': 'starts_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'startsAt'},
    {'1': 'ends_at', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'endsAt'},
    {'1': 'location', '3': 7, '4': 1, '5': 11, '6': '.rellm.Location', '9': 0, '10': 'location', '17': true},
    {'1': 'sync_missing_since', '3': 9, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 1, '10': 'syncMissingSince', '17': true},
    {'1': 'attendances', '3': 10, '4': 1, '5': 11, '6': '.rellm.EventAttendances', '9': 2, '10': 'attendances', '17': true},
    {'1': 'current_user_attendance', '3': 11, '4': 1, '5': 11, '6': '.rellm.EventAttendance', '9': 3, '10': 'currentUserAttendance', '17': true},
    {'1': 'sync_destinations', '3': 12, '4': 3, '5': 11, '6': '.rellm.SyncDestinationStatus', '10': 'syncDestinations'},
    {'1': 'timezone', '3': 13, '4': 1, '5': 9, '9': 4, '10': 'timezone', '17': true},
  ],
  '8': [
    {'1': '_location'},
    {'1': '_sync_missing_since'},
    {'1': '_attendances'},
    {'1': '_current_user_attendance'},
    {'1': '_timezone'},
  ],
  '9': [
    {'1': 8, '2': 9},
  ],
  '10': ['sync_source_instance_id'],
};

/// Descriptor for `EventInstance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInstanceDescriptor = $convert.base64Decode(
    'Cg1FdmVudEluc3RhbmNlEhkKCGV2ZW50X2lkGAIgASgJUgdldmVudElkEh8KBHBvc3QYAyABKA'
    'syCy5yZWxsbS5Qb3N0UgRwb3N0EiwKBGluZm8YBCABKAsyGC5yZWxsbS5FdmVudEluc3RhbmNl'
    'SW5mb1IEaW5mbxI3CglzdGFydHNfYXQYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW'
    '1wUghzdGFydHNBdBIzCgdlbmRzX2F0GAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt'
    'cFIGZW5kc0F0EjAKCGxvY2F0aW9uGAcgASgLMg8ucmVsbG0uTG9jYXRpb25IAFIIbG9jYXRpb2'
    '6IAQESTQoSc3luY19taXNzaW5nX3NpbmNlGAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
    'dGFtcEgBUhBzeW5jTWlzc2luZ1NpbmNliAEBEj4KC2F0dGVuZGFuY2VzGAogASgLMhcucmVsbG'
    '0uRXZlbnRBdHRlbmRhbmNlc0gCUgthdHRlbmRhbmNlc4gBARJTChdjdXJyZW50X3VzZXJfYXR0'
    'ZW5kYW5jZRgLIAEoCzIWLnJlbGxtLkV2ZW50QXR0ZW5kYW5jZUgDUhVjdXJyZW50VXNlckF0dG'
    'VuZGFuY2WIAQESSQoRc3luY19kZXN0aW5hdGlvbnMYDCADKAsyHC5yZWxsbS5TeW5jRGVzdGlu'
    'YXRpb25TdGF0dXNSEHN5bmNEZXN0aW5hdGlvbnMSHwoIdGltZXpvbmUYDSABKAlIBFIIdGltZX'
    'pvbmWIAQFCCwoJX2xvY2F0aW9uQhUKE19zeW5jX21pc3Npbmdfc2luY2VCDgoMX2F0dGVuZGFu'
    'Y2VzQhoKGF9jdXJyZW50X3VzZXJfYXR0ZW5kYW5jZUILCglfdGltZXpvbmVKBAgIEAlSF3N5bm'
    'Nfc291cmNlX2luc3RhbmNlX2lk');

@$core.Deprecated('Use eventInstanceInfoDescriptor instead')
const EventInstanceInfo$json = {
  '1': 'EventInstanceInfo',
  '2': [
    {'1': 'rsvp_info', '3': 1, '4': 1, '5': 11, '6': '.rellm.EventInstanceRsvpInfo', '9': 0, '10': 'rsvpInfo', '17': true},
  ],
  '8': [
    {'1': '_rsvp_info'},
  ],
};

/// Descriptor for `EventInstanceInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInstanceInfoDescriptor = $convert.base64Decode(
    'ChFFdmVudEluc3RhbmNlSW5mbxI+Cglyc3ZwX2luZm8YASABKAsyHC5yZWxsbS5FdmVudEluc3'
    'RhbmNlUnN2cEluZm9IAFIIcnN2cEluZm+IAQFCDAoKX3JzdnBfaW5mbw==');

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
    {'1': 'attendances', '3': 1, '4': 3, '5': 11, '6': '.rellm.EventAttendance', '10': 'attendances'},
    {'1': 'hidden_location', '3': 2, '4': 1, '5': 11, '6': '.rellm.Location', '9': 0, '10': 'hiddenLocation', '17': true},
  ],
  '8': [
    {'1': '_hidden_location'},
  ],
};

/// Descriptor for `EventAttendances`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventAttendancesDescriptor = $convert.base64Decode(
    'ChBFdmVudEF0dGVuZGFuY2VzEjgKC2F0dGVuZGFuY2VzGAEgAygLMhYucmVsbG0uRXZlbnRBdH'
    'RlbmRhbmNlUgthdHRlbmRhbmNlcxI9Cg9oaWRkZW5fbG9jYXRpb24YAiABKAsyDy5yZWxsbS5M'
    'b2NhdGlvbkgAUg5oaWRkZW5Mb2NhdGlvbogBAUISChBfaGlkZGVuX2xvY2F0aW9u');

@$core.Deprecated('Use eventAttendanceDescriptor instead')
const EventAttendance$json = {
  '1': 'EventAttendance',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'event_instance_id', '3': 2, '4': 1, '5': 9, '10': 'eventInstanceId'},
    {'1': 'user_attendee', '3': 3, '4': 1, '5': 11, '6': '.rellm.UserAttendee', '9': 0, '10': 'userAttendee'},
    {'1': 'anonymous_attendee', '3': 4, '4': 1, '5': 11, '6': '.rellm.AnonymousAttendee', '9': 0, '10': 'anonymousAttendee'},
    {'1': 'number_of_guests', '3': 5, '4': 1, '5': 13, '10': 'numberOfGuests'},
    {'1': 'status', '3': 6, '4': 1, '5': 14, '6': '.rellm.AttendanceStatus', '10': 'status'},
    {'1': 'inviting_user_id', '3': 7, '4': 1, '5': 9, '9': 1, '10': 'invitingUserId', '17': true},
    {'1': 'private_note', '3': 8, '4': 1, '5': 9, '10': 'privateNote'},
    {'1': 'public_note', '3': 9, '4': 1, '5': 9, '10': 'publicNote'},
    {'1': 'moderation', '3': 10, '4': 1, '5': 14, '6': '.rellm.Moderation', '10': 'moderation'},
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
    'IgASgJUg9ldmVudEluc3RhbmNlSWQSOgoNdXNlcl9hdHRlbmRlZRgDIAEoCzITLnJlbGxtLlVz'
    'ZXJBdHRlbmRlZUgAUgx1c2VyQXR0ZW5kZWUSSQoSYW5vbnltb3VzX2F0dGVuZGVlGAQgASgLMh'
    'gucmVsbG0uQW5vbnltb3VzQXR0ZW5kZWVIAFIRYW5vbnltb3VzQXR0ZW5kZWUSKAoQbnVtYmVy'
    'X29mX2d1ZXN0cxgFIAEoDVIObnVtYmVyT2ZHdWVzdHMSLwoGc3RhdHVzGAYgASgOMhcucmVsbG'
    '0uQXR0ZW5kYW5jZVN0YXR1c1IGc3RhdHVzEi0KEGludml0aW5nX3VzZXJfaWQYByABKAlIAVIO'
    'aW52aXRpbmdVc2VySWSIAQESIQoMcHJpdmF0ZV9ub3RlGAggASgJUgtwcml2YXRlTm90ZRIfCg'
    'twdWJsaWNfbm90ZRgJIAEoCVIKcHVibGljTm90ZRIxCgptb2RlcmF0aW9uGAogASgOMhEucmVs'
    'bG0uTW9kZXJhdGlvblIKbW9kZXJhdGlvbhI5CgpjcmVhdGVkX2F0GAsgASgLMhouZ29vZ2xlLn'
    'Byb3RvYnVmLlRpbWVzdGFtcFIJY3JlYXRlZEF0Ej4KCnVwZGF0ZWRfYXQYDCABKAsyGi5nb29n'
    'bGUucHJvdG9idWYuVGltZXN0YW1wSAJSCXVwZGF0ZWRBdIgBAUIKCghhdHRlbmRlZUITChFfaW'
    '52aXRpbmdfdXNlcl9pZEINCgtfdXBkYXRlZF9hdA==');

@$core.Deprecated('Use anonymousAttendeeDescriptor instead')
const AnonymousAttendee$json = {
  '1': 'AnonymousAttendee',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'contact_methods', '3': 2, '4': 3, '5': 11, '6': '.rellm.ContactMethod', '10': 'contactMethods'},
    {'1': 'auth_token', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'authToken', '17': true},
  ],
  '8': [
    {'1': '_auth_token'},
  ],
};

/// Descriptor for `AnonymousAttendee`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List anonymousAttendeeDescriptor = $convert.base64Decode(
    'ChFBbm9ueW1vdXNBdHRlbmRlZRISCgRuYW1lGAEgASgJUgRuYW1lEj0KD2NvbnRhY3RfbWV0aG'
    '9kcxgCIAMoCzIULnJlbGxtLkNvbnRhY3RNZXRob2RSDmNvbnRhY3RNZXRob2RzEiIKCmF1dGhf'
    'dG9rZW4YAyABKAlIAFIJYXV0aFRva2VuiAEBQg0KC19hdXRoX3Rva2Vu');

@$core.Deprecated('Use userAttendeeDescriptor instead')
const UserAttendee$json = {
  '1': 'UserAttendee',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'username', '17': true},
    {'1': 'avatar', '3': 3, '4': 1, '5': 11, '6': '.rellm.MediaReference', '9': 1, '10': 'avatar', '17': true},
    {'1': 'real_name', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'realName', '17': true},
    {'1': 'permissions', '3': 5, '4': 3, '5': 14, '6': '.rellm.Permission', '10': 'permissions'},
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
    'gJSABSCHVzZXJuYW1liAEBEjIKBmF2YXRhchgDIAEoCzIVLnJlbGxtLk1lZGlhUmVmZXJlbmNl'
    'SAFSBmF2YXRhcogBARIgCglyZWFsX25hbWUYBCABKAlIAlIIcmVhbE5hbWWIAQESMwoLcGVybW'
    'lzc2lvbnMYBSADKA4yES5yZWxsbS5QZXJtaXNzaW9uUgtwZXJtaXNzaW9uc0ILCglfdXNlcm5h'
    'bWVCCQoHX2F2YXRhckIMCgpfcmVhbF9uYW1l');

