///
//  Generated code. Do not modify.
//  source: events.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use eventListingTypeDescriptor instead')
const EventListingType$json = const {
  '1': 'EventListingType',
  '2': const [
    const {'1': 'PUBLIC_EVENTS', '2': 0},
    const {'1': 'FOLLOWING_EVENTS', '2': 1},
    const {'1': 'MY_GROUPS_EVENTS', '2': 2},
    const {'1': 'DIRECT_EVENTS', '2': 3},
    const {'1': 'EVENTS_PENDING_MODERATION', '2': 4},
    const {'1': 'GROUP_EVENTS', '2': 10},
    const {'1': 'GROUP_EVENTS_PENDING_MODERATION', '2': 11},
  ],
};

/// Descriptor for `EventListingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List eventListingTypeDescriptor = $convert.base64Decode('ChBFdmVudExpc3RpbmdUeXBlEhEKDVBVQkxJQ19FVkVOVFMQABIUChBGT0xMT1dJTkdfRVZFTlRTEAESFAoQTVlfR1JPVVBTX0VWRU5UUxACEhEKDURJUkVDVF9FVkVOVFMQAxIdChlFVkVOVFNfUEVORElOR19NT0RFUkFUSU9OEAQSEAoMR1JPVVBfRVZFTlRTEAoSIwofR1JPVVBfRVZFTlRTX1BFTkRJTkdfTU9ERVJBVElPThAL');
@$core.Deprecated('Use getEventsRequestDescriptor instead')
const GetEventsRequest$json = const {
  '1': 'GetEventsRequest',
  '2': const [
    const {'1': 'event_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'eventId', '17': true},
    const {'1': 'author_user_id', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'authorUserId', '17': true},
    const {'1': 'group_id', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'groupId', '17': true},
    const {'1': 'event_instance_id', '3': 4, '4': 1, '5': 9, '9': 3, '10': 'eventInstanceId', '17': true},
    const {'1': 'time_filter', '3': 5, '4': 1, '5': 11, '6': '.jonline.TimeFilter', '9': 4, '10': 'timeFilter', '17': true},
    const {'1': 'listing_type', '3': 10, '4': 1, '5': 14, '6': '.jonline.EventListingType', '10': 'listingType'},
  ],
  '8': const [
    const {'1': '_event_id'},
    const {'1': '_author_user_id'},
    const {'1': '_group_id'},
    const {'1': '_event_instance_id'},
    const {'1': '_time_filter'},
  ],
};

/// Descriptor for `GetEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEventsRequestDescriptor = $convert.base64Decode('ChBHZXRFdmVudHNSZXF1ZXN0Eh4KCGV2ZW50X2lkGAEgASgJSABSB2V2ZW50SWSIAQESKQoOYXV0aG9yX3VzZXJfaWQYAiABKAlIAVIMYXV0aG9yVXNlcklkiAEBEh4KCGdyb3VwX2lkGAMgASgJSAJSB2dyb3VwSWSIAQESLwoRZXZlbnRfaW5zdGFuY2VfaWQYBCABKAlIA1IPZXZlbnRJbnN0YW5jZUlkiAEBEjkKC3RpbWVfZmlsdGVyGAUgASgLMhMuam9ubGluZS5UaW1lRmlsdGVySARSCnRpbWVGaWx0ZXKIAQESPAoMbGlzdGluZ190eXBlGAogASgOMhkuam9ubGluZS5FdmVudExpc3RpbmdUeXBlUgtsaXN0aW5nVHlwZUILCglfZXZlbnRfaWRCEQoPX2F1dGhvcl91c2VyX2lkQgsKCV9ncm91cF9pZEIUChJfZXZlbnRfaW5zdGFuY2VfaWRCDgoMX3RpbWVfZmlsdGVy');
@$core.Deprecated('Use timeFilterDescriptor instead')
const TimeFilter$json = const {
  '1': 'TimeFilter',
  '2': const [
    const {'1': 'starts_after', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'startsAfter', '17': true},
    const {'1': 'ends_after', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 1, '10': 'endsAfter', '17': true},
    const {'1': 'starts_before', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 2, '10': 'startsBefore', '17': true},
    const {'1': 'ends_before', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 3, '10': 'endsBefore', '17': true},
  ],
  '8': const [
    const {'1': '_starts_after'},
    const {'1': '_ends_after'},
    const {'1': '_starts_before'},
    const {'1': '_ends_before'},
  ],
};

/// Descriptor for `TimeFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timeFilterDescriptor = $convert.base64Decode('CgpUaW1lRmlsdGVyEkIKDHN0YXJ0c19hZnRlchgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIAFILc3RhcnRzQWZ0ZXKIAQESPgoKZW5kc19hZnRlchgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIAVIJZW5kc0FmdGVyiAEBEkQKDXN0YXJ0c19iZWZvcmUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSAJSDHN0YXJ0c0JlZm9yZYgBARJACgtlbmRzX2JlZm9yZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIA1IKZW5kc0JlZm9yZYgBAUIPCg1fc3RhcnRzX2FmdGVyQg0KC19lbmRzX2FmdGVyQhAKDl9zdGFydHNfYmVmb3JlQg4KDF9lbmRzX2JlZm9yZQ==');
@$core.Deprecated('Use getEventsResponseDescriptor instead')
const GetEventsResponse$json = const {
  '1': 'GetEventsResponse',
  '2': const [
    const {'1': 'events', '3': 1, '4': 3, '5': 11, '6': '.jonline.Event', '10': 'events'},
  ],
};

/// Descriptor for `GetEventsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEventsResponseDescriptor = $convert.base64Decode('ChFHZXRFdmVudHNSZXNwb25zZRImCgZldmVudHMYASADKAsyDi5qb25saW5lLkV2ZW50UgZldmVudHM=');
@$core.Deprecated('Use eventDescriptor instead')
const Event$json = const {
  '1': 'Event',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'post', '3': 2, '4': 1, '5': 11, '6': '.jonline.Post', '10': 'post'},
    const {'1': 'info', '3': 3, '4': 1, '5': 11, '6': '.jonline.EventInfo', '10': 'info'},
    const {'1': 'instances', '3': 4, '4': 3, '5': 11, '6': '.jonline.EventInstance', '10': 'instances'},
  ],
};

/// Descriptor for `Event`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventDescriptor = $convert.base64Decode('CgVFdmVudBIOCgJpZBgBIAEoCVICaWQSIQoEcG9zdBgCIAEoCzINLmpvbmxpbmUuUG9zdFIEcG9zdBImCgRpbmZvGAMgASgLMhIuam9ubGluZS5FdmVudEluZm9SBGluZm8SNAoJaW5zdGFuY2VzGAQgAygLMhYuam9ubGluZS5FdmVudEluc3RhbmNlUglpbnN0YW5jZXM=');
@$core.Deprecated('Use eventInfoDescriptor instead')
const EventInfo$json = const {
  '1': 'EventInfo',
};

/// Descriptor for `EventInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInfoDescriptor = $convert.base64Decode('CglFdmVudEluZm8=');
@$core.Deprecated('Use eventInstanceDescriptor instead')
const EventInstance$json = const {
  '1': 'EventInstance',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'event_id', '3': 2, '4': 1, '5': 9, '10': 'eventId'},
    const {'1': 'post', '3': 3, '4': 1, '5': 11, '6': '.jonline.Post', '9': 0, '10': 'post', '17': true},
    const {'1': 'info', '3': 4, '4': 1, '5': 11, '6': '.jonline.EventInstanceInfo', '10': 'info'},
    const {'1': 'starts_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'startsAt'},
    const {'1': 'ends_at', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'endsAt'},
  ],
  '8': const [
    const {'1': '_post'},
  ],
};

/// Descriptor for `EventInstance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInstanceDescriptor = $convert.base64Decode('Cg1FdmVudEluc3RhbmNlEg4KAmlkGAEgASgJUgJpZBIZCghldmVudF9pZBgCIAEoCVIHZXZlbnRJZBImCgRwb3N0GAMgASgLMg0uam9ubGluZS5Qb3N0SABSBHBvc3SIAQESLgoEaW5mbxgEIAEoCzIaLmpvbmxpbmUuRXZlbnRJbnN0YW5jZUluZm9SBGluZm8SNwoJc3RhcnRzX2F0GAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIIc3RhcnRzQXQSMwoHZW5kc19hdBgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSBmVuZHNBdEIHCgVfcG9zdA==');
@$core.Deprecated('Use eventInstanceInfoDescriptor instead')
const EventInstanceInfo$json = const {
  '1': 'EventInstanceInfo',
};

/// Descriptor for `EventInstanceInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventInstanceInfoDescriptor = $convert.base64Decode('ChFFdmVudEluc3RhbmNlSW5mbw==');
