//
//  Generated code. Do not modify.
//  source: federation.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use getServiceVersionResponseDescriptor instead')
const GetServiceVersionResponse$json = {
  '1': 'GetServiceVersionResponse',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `GetServiceVersionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getServiceVersionResponseDescriptor = $convert.base64Decode(
    'ChlHZXRTZXJ2aWNlVmVyc2lvblJlc3BvbnNlEhgKB3ZlcnNpb24YASABKAlSB3ZlcnNpb24=');

@$core.Deprecated('Use federationInfoDescriptor instead')
const FederationInfo$json = {
  '1': 'FederationInfo',
  '2': [
    {'1': 'servers', '3': 1, '4': 3, '5': 11, '6': '.jonline.FederatedServer', '10': 'servers'},
    {'1': 'facebook_auth_config', '3': 2, '4': 1, '5': 11, '6': '.jonline.FacebookAuthConfig', '9': 0, '10': 'facebookAuthConfig', '17': true},
    {'1': 'x_twitter_auth_config', '3': 3, '4': 1, '5': 11, '6': '.jonline.XTwitterAuthConfig', '9': 1, '10': 'xTwitterAuthConfig', '17': true},
    {'1': 'mastodon_servers', '3': 4, '4': 3, '5': 11, '6': '.jonline.MastodonServer', '10': 'mastodonServers'},
  ],
  '8': [
    {'1': '_facebook_auth_config'},
    {'1': '_x_twitter_auth_config'},
  ],
};

/// Descriptor for `FederationInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List federationInfoDescriptor = $convert.base64Decode(
    'Cg5GZWRlcmF0aW9uSW5mbxIyCgdzZXJ2ZXJzGAEgAygLMhguam9ubGluZS5GZWRlcmF0ZWRTZX'
    'J2ZXJSB3NlcnZlcnMSUgoUZmFjZWJvb2tfYXV0aF9jb25maWcYAiABKAsyGy5qb25saW5lLkZh'
    'Y2Vib29rQXV0aENvbmZpZ0gAUhJmYWNlYm9va0F1dGhDb25maWeIAQESUwoVeF90d2l0dGVyX2'
    'F1dGhfY29uZmlnGAMgASgLMhsuam9ubGluZS5YVHdpdHRlckF1dGhDb25maWdIAVISeFR3aXR0'
    'ZXJBdXRoQ29uZmlniAEBEkIKEG1hc3RvZG9uX3NlcnZlcnMYBCADKAsyFy5qb25saW5lLk1hc3'
    'RvZG9uU2VydmVyUg9tYXN0b2RvblNlcnZlcnNCFwoVX2ZhY2Vib29rX2F1dGhfY29uZmlnQhgK'
    'Fl94X3R3aXR0ZXJfYXV0aF9jb25maWc=');

@$core.Deprecated('Use federatedServerDescriptor instead')
const FederatedServer$json = {
  '1': 'FederatedServer',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'configured_by_default', '3': 2, '4': 1, '5': 8, '9': 0, '10': 'configuredByDefault', '17': true},
    {'1': 'pinned_by_default', '3': 3, '4': 1, '5': 8, '9': 1, '10': 'pinnedByDefault', '17': true},
  ],
  '8': [
    {'1': '_configured_by_default'},
    {'1': '_pinned_by_default'},
  ],
};

/// Descriptor for `FederatedServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List federatedServerDescriptor = $convert.base64Decode(
    'Cg9GZWRlcmF0ZWRTZXJ2ZXISEgoEaG9zdBgBIAEoCVIEaG9zdBI3ChVjb25maWd1cmVkX2J5X2'
    'RlZmF1bHQYAiABKAhIAFITY29uZmlndXJlZEJ5RGVmYXVsdIgBARIvChFwaW5uZWRfYnlfZGVm'
    'YXVsdBgDIAEoCEgBUg9waW5uZWRCeURlZmF1bHSIAQFCGAoWX2NvbmZpZ3VyZWRfYnlfZGVmYX'
    'VsdEIUChJfcGlubmVkX2J5X2RlZmF1bHQ=');

@$core.Deprecated('Use federatedAccountDescriptor instead')
const FederatedAccount$json = {
  '1': 'FederatedAccount',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
  ],
};

/// Descriptor for `FederatedAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List federatedAccountDescriptor = $convert.base64Decode(
    'ChBGZWRlcmF0ZWRBY2NvdW50EhIKBGhvc3QYASABKAlSBGhvc3QSFwoHdXNlcl9pZBgCIAEoCV'
    'IGdXNlcklk');

@$core.Deprecated('Use facebookAuthConfigDescriptor instead')
const FacebookAuthConfig$json = {
  '1': 'FacebookAuthConfig',
  '2': [
    {'1': 'app_id', '3': 1, '4': 1, '5': 9, '10': 'appId'},
    {'1': 'app_secret', '3': 2, '4': 1, '5': 9, '10': 'appSecret'},
  ],
};

/// Descriptor for `FacebookAuthConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List facebookAuthConfigDescriptor = $convert.base64Decode(
    'ChJGYWNlYm9va0F1dGhDb25maWcSFQoGYXBwX2lkGAEgASgJUgVhcHBJZBIdCgphcHBfc2Vjcm'
    'V0GAIgASgJUglhcHBTZWNyZXQ=');

@$core.Deprecated('Use xTwitterAuthConfigDescriptor instead')
const XTwitterAuthConfig$json = {
  '1': 'XTwitterAuthConfig',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
    {'1': 'client_secret', '3': 2, '4': 1, '5': 9, '10': 'clientSecret'},
  ],
};

/// Descriptor for `XTwitterAuthConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List xTwitterAuthConfigDescriptor = $convert.base64Decode(
    'ChJYVHdpdHRlckF1dGhDb25maWcSGwoJY2xpZW50X2lkGAEgASgJUghjbGllbnRJZBIjCg1jbG'
    'llbnRfc2VjcmV0GAIgASgJUgxjbGllbnRTZWNyZXQ=');

@$core.Deprecated('Use mastodonServerDescriptor instead')
const MastodonServer$json = {
  '1': 'MastodonServer',
  '2': [
    {'1': 'domain', '3': 1, '4': 1, '5': 9, '10': 'domain'},
    {'1': 'app_id', '3': 2, '4': 1, '5': 9, '10': 'appId'},
    {'1': 'app_secret', '3': 3, '4': 1, '5': 9, '10': 'appSecret'},
    {'1': 'configured_by_default', '3': 4, '4': 1, '5': 8, '9': 0, '10': 'configuredByDefault', '17': true},
    {'1': 'pinned_by_default', '3': 5, '4': 1, '5': 8, '9': 1, '10': 'pinnedByDefault', '17': true},
  ],
  '8': [
    {'1': '_configured_by_default'},
    {'1': '_pinned_by_default'},
  ],
};

/// Descriptor for `MastodonServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mastodonServerDescriptor = $convert.base64Decode(
    'Cg5NYXN0b2RvblNlcnZlchIWCgZkb21haW4YASABKAlSBmRvbWFpbhIVCgZhcHBfaWQYAiABKA'
    'lSBWFwcElkEh0KCmFwcF9zZWNyZXQYAyABKAlSCWFwcFNlY3JldBI3ChVjb25maWd1cmVkX2J5'
    'X2RlZmF1bHQYBCABKAhIAFITY29uZmlndXJlZEJ5RGVmYXVsdIgBARIvChFwaW5uZWRfYnlfZG'
    'VmYXVsdBgFIAEoCEgBUg9waW5uZWRCeURlZmF1bHSIAQFCGAoWX2NvbmZpZ3VyZWRfYnlfZGVm'
    'YXVsdEIUChJfcGlubmVkX2J5X2RlZmF1bHQ=');

