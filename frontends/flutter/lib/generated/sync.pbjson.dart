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
    {'1': 'instagram_account', '3': 10, '4': 1, '5': 11, '6': '.jonline.InstagramAccount', '9': 0, '10': 'instagramAccount'},
    {'1': 'mastodon_account', '3': 11, '4': 1, '5': 11, '6': '.jonline.MastodonAccount', '9': 0, '10': 'mastodonAccount'},
    {'1': 'bluesky_account', '3': 12, '4': 1, '5': 11, '6': '.jonline.BlueskyAccount', '9': 0, '10': 'blueskyAccount'},
    {'1': 'x_twitter_account', '3': 13, '4': 1, '5': 11, '6': '.jonline.XTwitterAccount', '9': 0, '10': 'xTwitterAccount'},
    {'1': 'threads_account', '3': 14, '4': 1, '5': 11, '6': '.jonline.ThreadsAccount', '9': 0, '10': 'threadsAccount'},
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
    'KAsyFS5qb25saW5lLkZhY2Vib29rUGFnZUgAUgxmYWNlYm9va1BhZ2USSAoRaW5zdGFncmFtX2'
    'FjY291bnQYCiABKAsyGS5qb25saW5lLkluc3RhZ3JhbUFjY291bnRIAFIQaW5zdGFncmFtQWNj'
    'b3VudBJFChBtYXN0b2Rvbl9hY2NvdW50GAsgASgLMhguam9ubGluZS5NYXN0b2RvbkFjY291bn'
    'RIAFIPbWFzdG9kb25BY2NvdW50EkIKD2JsdWVza3lfYWNjb3VudBgMIAEoCzIXLmpvbmxpbmUu'
    'Qmx1ZXNreUFjY291bnRIAFIOYmx1ZXNreUFjY291bnQSRgoReF90d2l0dGVyX2FjY291bnQYDS'
    'ABKAsyGC5qb25saW5lLlhUd2l0dGVyQWNjb3VudEgAUg94VHdpdHRlckFjY291bnQSQgoPdGhy'
    'ZWFkc19hY2NvdW50GA4gASgLMhcuam9ubGluZS5UaHJlYWRzQWNjb3VudEgAUg50aHJlYWRzQW'
    'Njb3VudEIPCg1jb25maWd1cmF0aW9uQg0KC191cGRhdGVkX2F0Qh4KHF9zeW5jZWRfZXZlbnRf'
    'aW5zdGFuY2VfY291bnRCFAoSX3N5bmNlZF9wb3N0X2NvdW50');

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

@$core.Deprecated('Use instagramAccountDescriptor instead')
const InstagramAccount$json = {
  '1': 'InstagramAccount',
  '2': [
    {'1': 'instagram_business_account_id', '3': 1, '4': 1, '5': 9, '10': 'instagramBusinessAccountId'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'page_id', '3': 3, '4': 1, '5': 9, '10': 'pageId'},
    {'1': 'short_lived_user_access_token', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'shortLivedUserAccessToken', '17': true},
  ],
  '8': [
    {'1': '_short_lived_user_access_token'},
  ],
};

/// Descriptor for `InstagramAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List instagramAccountDescriptor = $convert.base64Decode(
    'ChBJbnN0YWdyYW1BY2NvdW50EkEKHWluc3RhZ3JhbV9idXNpbmVzc19hY2NvdW50X2lkGAEgAS'
    'gJUhppbnN0YWdyYW1CdXNpbmVzc0FjY291bnRJZBIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm5h'
    'bWUSFwoHcGFnZV9pZBgDIAEoCVIGcGFnZUlkEkUKHXNob3J0X2xpdmVkX3VzZXJfYWNjZXNzX3'
    'Rva2VuGAQgASgJSABSGXNob3J0TGl2ZWRVc2VyQWNjZXNzVG9rZW6IAQFCIAoeX3Nob3J0X2xp'
    'dmVkX3VzZXJfYWNjZXNzX3Rva2Vu');

@$core.Deprecated('Use mastodonAccountDescriptor instead')
const MastodonAccount$json = {
  '1': 'MastodonAccount',
  '2': [
    {'1': 'instance_host', '3': 1, '4': 1, '5': 9, '10': 'instanceHost'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'access_token', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'accessToken', '17': true},
  ],
  '8': [
    {'1': '_access_token'},
  ],
};

/// Descriptor for `MastodonAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mastodonAccountDescriptor = $convert.base64Decode(
    'Cg9NYXN0b2RvbkFjY291bnQSIwoNaW5zdGFuY2VfaG9zdBgBIAEoCVIMaW5zdGFuY2VIb3N0Eh'
    'oKCHVzZXJuYW1lGAIgASgJUgh1c2VybmFtZRImCgxhY2Nlc3NfdG9rZW4YAyABKAlIAFILYWNj'
    'ZXNzVG9rZW6IAQFCDwoNX2FjY2Vzc190b2tlbg==');

@$core.Deprecated('Use blueskyAccountDescriptor instead')
const BlueskyAccount$json = {
  '1': 'BlueskyAccount',
  '2': [
    {'1': 'handle', '3': 1, '4': 1, '5': 9, '10': 'handle'},
    {'1': 'did', '3': 2, '4': 1, '5': 9, '10': 'did'},
    {'1': 'app_password', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'appPassword', '17': true},
  ],
  '8': [
    {'1': '_app_password'},
  ],
};

/// Descriptor for `BlueskyAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blueskyAccountDescriptor = $convert.base64Decode(
    'Cg5CbHVlc2t5QWNjb3VudBIWCgZoYW5kbGUYASABKAlSBmhhbmRsZRIQCgNkaWQYAiABKAlSA2'
    'RpZBImCgxhcHBfcGFzc3dvcmQYAyABKAlIAFILYXBwUGFzc3dvcmSIAQFCDwoNX2FwcF9wYXNz'
    'd29yZA==');

@$core.Deprecated('Use xTwitterAccountDescriptor instead')
const XTwitterAccount$json = {
  '1': 'XTwitterAccount',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'x_user_id', '3': 3, '4': 1, '5': 9, '10': 'xUserId'},
    {'1': 'authorization_code', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'authorizationCode', '17': true},
    {'1': 'code_verifier', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'codeVerifier', '17': true},
  ],
  '8': [
    {'1': '_authorization_code'},
    {'1': '_code_verifier'},
  ],
  '9': [
    {'1': 2, '2': 3},
  ],
  '10': ['short_lived_user_access_token'],
};

/// Descriptor for `XTwitterAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List xTwitterAccountDescriptor = $convert.base64Decode(
    'Cg9YVHdpdHRlckFjY291bnQSGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEhoKCXhfdXNlcl'
    '9pZBgDIAEoCVIHeFVzZXJJZBIyChJhdXRob3JpemF0aW9uX2NvZGUYBCABKAlIAFIRYXV0aG9y'
    'aXphdGlvbkNvZGWIAQESKAoNY29kZV92ZXJpZmllchgFIAEoCUgBUgxjb2RlVmVyaWZpZXKIAQ'
    'FCFQoTX2F1dGhvcml6YXRpb25fY29kZUIQCg5fY29kZV92ZXJpZmllckoECAIQA1Idc2hvcnRf'
    'bGl2ZWRfdXNlcl9hY2Nlc3NfdG9rZW4=');

@$core.Deprecated('Use threadsAccountDescriptor instead')
const ThreadsAccount$json = {
  '1': 'ThreadsAccount',
  '2': [
    {'1': 'threads_user_id', '3': 1, '4': 1, '5': 9, '10': 'threadsUserId'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'authorization_code', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'authorizationCode', '17': true},
  ],
  '8': [
    {'1': '_authorization_code'},
  ],
};

/// Descriptor for `ThreadsAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List threadsAccountDescriptor = $convert.base64Decode(
    'Cg5UaHJlYWRzQWNjb3VudBImCg90aHJlYWRzX3VzZXJfaWQYASABKAlSDXRocmVhZHNVc2VySW'
    'QSGgoIdXNlcm5hbWUYAiABKAlSCHVzZXJuYW1lEjIKEmF1dGhvcml6YXRpb25fY29kZRgDIAEo'
    'CUgAUhFhdXRob3JpemF0aW9uQ29kZYgBAUIVChNfYXV0aG9yaXphdGlvbl9jb2Rl');

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

@$core.Deprecated('Use syncSourceDescriptor instead')
const SyncSource$json = {
  '1': 'SyncSource',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'owner', '3': 2, '4': 1, '5': 11, '6': '.jonline.Author', '10': 'owner'},
    {'1': 'sync_interval_seconds', '3': 3, '4': 1, '5': 4, '10': 'syncIntervalSeconds'},
    {'1': 'created_at', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 1, '10': 'updatedAt', '17': true},
    {'1': 'last_synced_at', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 2, '10': 'lastSyncedAt', '17': true},
    {'1': 'event_count', '3': 7, '4': 1, '5': 4, '10': 'eventCount'},
    {'1': 'event_instance_count', '3': 8, '4': 1, '5': 4, '10': 'eventInstanceCount'},
    {'1': 'post_count', '3': 10, '4': 1, '5': 4, '10': 'postCount'},
    {'1': 'ics_subscription_url', '3': 9, '4': 1, '5': 9, '9': 0, '10': 'icsSubscriptionUrl'},
  ],
  '8': [
    {'1': 'configuration'},
    {'1': '_updated_at'},
    {'1': '_last_synced_at'},
  ],
};

/// Descriptor for `SyncSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncSourceDescriptor = $convert.base64Decode(
    'CgpTeW5jU291cmNlEg4KAmlkGAEgASgJUgJpZBIlCgVvd25lchgCIAEoCzIPLmpvbmxpbmUuQX'
    'V0aG9yUgVvd25lchIyChVzeW5jX2ludGVydmFsX3NlY29uZHMYAyABKARSE3N5bmNJbnRlcnZh'
    'bFNlY29uZHMSOQoKY3JlYXRlZF9hdBgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbX'
    'BSCWNyZWF0ZWRBdBI+Cgp1cGRhdGVkX2F0GAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
    'dGFtcEgBUgl1cGRhdGVkQXSIAQESRQoObGFzdF9zeW5jZWRfYXQYBiABKAsyGi5nb29nbGUucH'
    'JvdG9idWYuVGltZXN0YW1wSAJSDGxhc3RTeW5jZWRBdIgBARIfCgtldmVudF9jb3VudBgHIAEo'
    'BFIKZXZlbnRDb3VudBIwChRldmVudF9pbnN0YW5jZV9jb3VudBgIIAEoBFISZXZlbnRJbnN0YW'
    '5jZUNvdW50Eh0KCnBvc3RfY291bnQYCiABKARSCXBvc3RDb3VudBIyChRpY3Nfc3Vic2NyaXB0'
    'aW9uX3VybBgJIAEoCUgAUhJpY3NTdWJzY3JpcHRpb25VcmxCDwoNY29uZmlndXJhdGlvbkINCg'
    'tfdXBkYXRlZF9hdEIRCg9fbGFzdF9zeW5jZWRfYXQ=');

@$core.Deprecated('Use getSyncSourcesResponseDescriptor instead')
const GetSyncSourcesResponse$json = {
  '1': 'GetSyncSourcesResponse',
  '2': [
    {'1': 'sources', '3': 1, '4': 3, '5': 11, '6': '.jonline.SyncSource', '10': 'sources'},
  ],
};

/// Descriptor for `GetSyncSourcesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSyncSourcesResponseDescriptor = $convert.base64Decode(
    'ChZHZXRTeW5jU291cmNlc1Jlc3BvbnNlEi0KB3NvdXJjZXMYASADKAsyEy5qb25saW5lLlN5bm'
    'NTb3VyY2VSB3NvdXJjZXM=');

@$core.Deprecated('Use deleteSyncSourceRequestDescriptor instead')
const DeleteSyncSourceRequest$json = {
  '1': 'DeleteSyncSourceRequest',
  '2': [
    {'1': 'source', '3': 1, '4': 1, '5': 11, '6': '.jonline.SyncSource', '10': 'source'},
    {'1': 'delete_synced_events', '3': 2, '4': 1, '5': 8, '10': 'deleteSyncedEvents'},
  ],
};

/// Descriptor for `DeleteSyncSourceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSyncSourceRequestDescriptor = $convert.base64Decode(
    'ChdEZWxldGVTeW5jU291cmNlUmVxdWVzdBIrCgZzb3VyY2UYASABKAsyEy5qb25saW5lLlN5bm'
    'NTb3VyY2VSBnNvdXJjZRIwChRkZWxldGVfc3luY2VkX2V2ZW50cxgCIAEoCFISZGVsZXRlU3lu'
    'Y2VkRXZlbnRz');

