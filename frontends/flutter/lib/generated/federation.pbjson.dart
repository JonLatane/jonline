//
//  Generated code. Do not modify.
//  source: federation.proto
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
  ],
};

/// Descriptor for `FederationInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List federationInfoDescriptor = $convert.base64Decode(
    'Cg5GZWRlcmF0aW9uSW5mbxIyCgdzZXJ2ZXJzGAEgAygLMhguam9ubGluZS5GZWRlcmF0ZWRTZX'
    'J2ZXJSB3NlcnZlcnM=');

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

