//
//  Generated code. Do not modify.
//  source: sync.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use eventSyncSourceDescriptor instead')
const EventSyncSource$json = {
  '1': 'EventSyncSource',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'owner', '3': 2, '4': 1, '5': 11, '6': '.jonline.Author', '10': 'owner'},
    {'1': 'sync_interval_seconds', '3': 3, '4': 1, '5': 4, '10': 'syncIntervalSeconds'},
    {'1': 'created_at', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 1, '10': 'updatedAt', '17': true},
    {'1': 'last_synced_at', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 2, '10': 'lastSyncedAt', '17': true},
    {'1': 'event_count', '3': 7, '4': 1, '5': 4, '10': 'eventCount'},
    {'1': 'event_instance_count', '3': 8, '4': 1, '5': 4, '10': 'eventInstanceCount'},
    {'1': 'ics_subscription_url', '3': 9, '4': 1, '5': 9, '9': 0, '10': 'icsSubscriptionUrl'},
  ],
  '8': [
    {'1': 'configuration'},
    {'1': '_updated_at'},
    {'1': '_last_synced_at'},
  ],
};

/// Descriptor for `EventSyncSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventSyncSourceDescriptor = $convert.base64Decode(
    'Cg9FdmVudFN5bmNTb3VyY2USDgoCaWQYASABKAlSAmlkEiUKBW93bmVyGAIgASgLMg8uam9ubG'
    'luZS5BdXRob3JSBW93bmVyEjIKFXN5bmNfaW50ZXJ2YWxfc2Vjb25kcxgDIAEoBFITc3luY0lu'
    'dGVydmFsU2Vjb25kcxI5CgpjcmVhdGVkX2F0GAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbW'
    'VzdGFtcFIJY3JlYXRlZEF0Ej4KCnVwZGF0ZWRfYXQYBSABKAsyGi5nb29nbGUucHJvdG9idWYu'
    'VGltZXN0YW1wSAFSCXVwZGF0ZWRBdIgBARJFCg5sYXN0X3N5bmNlZF9hdBgGIAEoCzIaLmdvb2'
    'dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIAlIMbGFzdFN5bmNlZEF0iAEBEh8KC2V2ZW50X2NvdW50'
    'GAcgASgEUgpldmVudENvdW50EjAKFGV2ZW50X2luc3RhbmNlX2NvdW50GAggASgEUhJldmVudE'
    'luc3RhbmNlQ291bnQSMgoUaWNzX3N1YnNjcmlwdGlvbl91cmwYCSABKAlIAFISaWNzU3Vic2Ny'
    'aXB0aW9uVXJsQg8KDWNvbmZpZ3VyYXRpb25CDQoLX3VwZGF0ZWRfYXRCEQoPX2xhc3Rfc3luY2'
    'VkX2F0');

@$core.Deprecated('Use getEventSyncSourcesResponseDescriptor instead')
const GetEventSyncSourcesResponse$json = {
  '1': 'GetEventSyncSourcesResponse',
  '2': [
    {'1': 'sources', '3': 1, '4': 3, '5': 11, '6': '.jonline.EventSyncSource', '10': 'sources'},
  ],
};

/// Descriptor for `GetEventSyncSourcesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEventSyncSourcesResponseDescriptor = $convert.base64Decode(
    'ChtHZXRFdmVudFN5bmNTb3VyY2VzUmVzcG9uc2USMgoHc291cmNlcxgBIAMoCzIYLmpvbmxpbm'
    'UuRXZlbnRTeW5jU291cmNlUgdzb3VyY2Vz');

@$core.Deprecated('Use deleteEventSyncSourceRequestDescriptor instead')
const DeleteEventSyncSourceRequest$json = {
  '1': 'DeleteEventSyncSourceRequest',
  '2': [
    {'1': 'source', '3': 1, '4': 1, '5': 11, '6': '.jonline.EventSyncSource', '10': 'source'},
    {'1': 'delete_synced_events', '3': 2, '4': 1, '5': 8, '10': 'deleteSyncedEvents'},
  ],
};

/// Descriptor for `DeleteEventSyncSourceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteEventSyncSourceRequestDescriptor = $convert.base64Decode(
    'ChxEZWxldGVFdmVudFN5bmNTb3VyY2VSZXF1ZXN0EjAKBnNvdXJjZRgBIAEoCzIYLmpvbmxpbm'
    'UuRXZlbnRTeW5jU291cmNlUgZzb3VyY2USMAoUZGVsZXRlX3N5bmNlZF9ldmVudHMYAiABKAhS'
    'EmRlbGV0ZVN5bmNlZEV2ZW50cw==');

@$core.Deprecated('Use syncDestinationDescriptor instead')
const SyncDestination$json = {
  '1': 'SyncDestination',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'owner', '3': 2, '4': 1, '5': 11, '6': '.jonline.Author', '10': 'owner'},
    {'1': 'created_at', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 1, '10': 'updatedAt', '17': true},
    {'1': 'synced_event_instance_count', '3': 6, '4': 1, '5': 4, '9': 2, '10': 'syncedEventInstanceCount', '17': true},
    {'1': 'synced_post_count', '3': 7, '4': 1, '5': 4, '9': 3, '10': 'syncedPostCount', '17': true},
    {'1': 'facebook_page', '3': 9, '4': 1, '5': 11, '6': '.jonline.FacebookPage', '9': 0, '10': 'facebookPage'},
  ],
  '8': [
    {'1': 'configuration'},
    {'1': '_updated_at'},
    {'1': '_synced_event_instance_count'},
    {'1': '_synced_post_count'},
  ],
};

/// Descriptor for `SyncDestination`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncDestinationDescriptor = $convert.base64Decode(
    'Cg9TeW5jRGVzdGluYXRpb24SDgoCaWQYASABKAlSAmlkEiUKBW93bmVyGAIgASgLMg8uam9ubG'
    'luZS5BdXRob3JSBW93bmVyEjkKCmNyZWF0ZWRfYXQYBCABKAsyGi5nb29nbGUucHJvdG9idWYu'
    'VGltZXN0YW1wUgljcmVhdGVkQXQSPgoKdXBkYXRlZF9hdBgFIAEoCzIaLmdvb2dsZS5wcm90b2'
    'J1Zi5UaW1lc3RhbXBIAVIJdXBkYXRlZEF0iAEBEkIKG3N5bmNlZF9ldmVudF9pbnN0YW5jZV9j'
    'b3VudBgGIAEoBEgCUhhzeW5jZWRFdmVudEluc3RhbmNlQ291bnSIAQESLwoRc3luY2VkX3Bvc3'
    'RfY291bnQYByABKARIA1IPc3luY2VkUG9zdENvdW50iAEBEjwKDWZhY2Vib29rX3BhZ2UYCSAB'
    'KAsyFS5qb25saW5lLkZhY2Vib29rUGFnZUgAUgxmYWNlYm9va1BhZ2VCDwoNY29uZmlndXJhdG'
    'lvbkINCgtfdXBkYXRlZF9hdEIeChxfc3luY2VkX2V2ZW50X2luc3RhbmNlX2NvdW50QhQKEl9z'
    'eW5jZWRfcG9zdF9jb3VudA==');

@$core.Deprecated('Use getSyncDestinationsResponseDescriptor instead')
const GetSyncDestinationsResponse$json = {
  '1': 'GetSyncDestinationsResponse',
  '2': [
    {'1': 'destinations', '3': 1, '4': 3, '5': 11, '6': '.jonline.SyncDestination', '10': 'destinations'},
  ],
};

/// Descriptor for `GetSyncDestinationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSyncDestinationsResponseDescriptor = $convert.base64Decode(
    'ChtHZXRTeW5jRGVzdGluYXRpb25zUmVzcG9uc2USPAoMZGVzdGluYXRpb25zGAEgAygLMhguam'
    '9ubGluZS5TeW5jRGVzdGluYXRpb25SDGRlc3RpbmF0aW9ucw==');

@$core.Deprecated('Use deleteSyncDestinationRequestDescriptor instead')
const DeleteSyncDestinationRequest$json = {
  '1': 'DeleteSyncDestinationRequest',
  '2': [
    {'1': 'destination', '3': 1, '4': 1, '5': 11, '6': '.jonline.SyncDestination', '10': 'destination'},
    {'1': 'delete_synced_posts', '3': 2, '4': 1, '5': 8, '10': 'deleteSyncedPosts'},
  ],
};

/// Descriptor for `DeleteSyncDestinationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSyncDestinationRequestDescriptor = $convert.base64Decode(
    'ChxEZWxldGVTeW5jRGVzdGluYXRpb25SZXF1ZXN0EjoKC2Rlc3RpbmF0aW9uGAEgASgLMhguam'
    '9ubGluZS5TeW5jRGVzdGluYXRpb25SC2Rlc3RpbmF0aW9uEi4KE2RlbGV0ZV9zeW5jZWRfcG9z'
    'dHMYAiABKAhSEWRlbGV0ZVN5bmNlZFBvc3Rz');

@$core.Deprecated('Use facebookPageDescriptor instead')
const FacebookPage$json = {
  '1': 'FacebookPage',
  '2': [
    {'1': 'page_id', '3': 1, '4': 1, '5': 9, '10': 'pageId'},
    {'1': 'page_name', '3': 2, '4': 1, '5': 9, '10': 'pageName'},
    {'1': 'short_lived_user_access_token', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'shortLivedUserAccessToken', '17': true},
  ],
  '8': [
    {'1': '_short_lived_user_access_token'},
  ],
};

/// Descriptor for `FacebookPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List facebookPageDescriptor = $convert.base64Decode(
    'CgxGYWNlYm9va1BhZ2USFwoHcGFnZV9pZBgBIAEoCVIGcGFnZUlkEhsKCXBhZ2VfbmFtZRgCIA'
    'EoCVIIcGFnZU5hbWUSRQodc2hvcnRfbGl2ZWRfdXNlcl9hY2Nlc3NfdG9rZW4YAyABKAlIAFIZ'
    'c2hvcnRMaXZlZFVzZXJBY2Nlc3NUb2tlbogBAUIgCh5fc2hvcnRfbGl2ZWRfdXNlcl9hY2Nlc3'
    'NfdG9rZW4=');

@$core.Deprecated('Use syncDestinationStatusDescriptor instead')
const SyncDestinationStatus$json = {
  '1': 'SyncDestinationStatus',
  '2': [
    {'1': 'sync_destination_id', '3': 1, '4': 1, '5': 9, '10': 'syncDestinationId'},
    {'1': 'destination_instance_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'destinationInstanceId', '17': true},
    {'1': 'destination_url', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'destinationUrl', '17': true},
    {'1': 'synced_at', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 2, '10': 'syncedAt', '17': true},
  ],
  '8': [
    {'1': '_destination_instance_id'},
    {'1': '_destination_url'},
    {'1': '_synced_at'},
  ],
};

/// Descriptor for `SyncDestinationStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncDestinationStatusDescriptor = $convert.base64Decode(
    'ChVTeW5jRGVzdGluYXRpb25TdGF0dXMSLgoTc3luY19kZXN0aW5hdGlvbl9pZBgBIAEoCVIRc3'
    'luY0Rlc3RpbmF0aW9uSWQSOwoXZGVzdGluYXRpb25faW5zdGFuY2VfaWQYAiABKAlIAFIVZGVz'
    'dGluYXRpb25JbnN0YW5jZUlkiAEBEiwKD2Rlc3RpbmF0aW9uX3VybBgDIAEoCUgBUg5kZXN0aW'
    '5hdGlvblVybIgBARI8CglzeW5jZWRfYXQYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0'
    'YW1wSAJSCHN5bmNlZEF0iAEBQhoKGF9kZXN0aW5hdGlvbl9pbnN0YW5jZV9pZEISChBfZGVzdG'
    'luYXRpb25fdXJsQgwKCl9zeW5jZWRfYXQ=');

