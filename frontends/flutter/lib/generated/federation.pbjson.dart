//
//  Generated code. Do not modify.
//  source: federation.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use federationCredentialsDescriptor instead')
const FederationCredentials$json = {
  '1': 'FederationCredentials',
  '2': [
    {'1': 'REFRESH_TOKEN_ONLY', '2': 0},
    {'1': 'REFRESH_TOKEN_AND_PASSWORD', '2': 1},
  ],
};

/// Descriptor for `FederationCredentials`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List federationCredentialsDescriptor = $convert.base64Decode(
    'ChVGZWRlcmF0aW9uQ3JlZGVudGlhbHMSFgoSUkVGUkVTSF9UT0tFTl9PTkxZEAASHgoaUkVGUk'
    'VTSF9UT0tFTl9BTkRfUEFTU1dPUkQQAQ==');

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

@$core.Deprecated('Use federateRequestDescriptor instead')
const FederateRequest$json = {
  '1': 'FederateRequest',
  '2': [
    {'1': 'server', '3': 1, '4': 1, '5': 9, '10': 'server'},
    {'1': 'preexisting_account', '3': 2, '4': 1, '5': 8, '10': 'preexistingAccount'},
    {'1': 'username', '3': 3, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'password', '17': true},
    {'1': 'refresh_token', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'refreshToken', '17': true},
    {'1': 'stored_credentials', '3': 6, '4': 1, '5': 14, '6': '.jonline.FederationCredentials', '10': 'storedCredentials'},
    {'1': 'returned_credentials', '3': 7, '4': 1, '5': 14, '6': '.jonline.FederationCredentials', '9': 2, '10': 'returnedCredentials', '17': true},
  ],
  '8': [
    {'1': '_password'},
    {'1': '_refresh_token'},
    {'1': '_returned_credentials'},
  ],
};

/// Descriptor for `FederateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List federateRequestDescriptor = $convert.base64Decode(
    'Cg9GZWRlcmF0ZVJlcXVlc3QSFgoGc2VydmVyGAEgASgJUgZzZXJ2ZXISLwoTcHJlZXhpc3Rpbm'
    'dfYWNjb3VudBgCIAEoCFIScHJlZXhpc3RpbmdBY2NvdW50EhoKCHVzZXJuYW1lGAMgASgJUgh1'
    'c2VybmFtZRIfCghwYXNzd29yZBgEIAEoCUgAUghwYXNzd29yZIgBARIoCg1yZWZyZXNoX3Rva2'
    'VuGAUgASgJSAFSDHJlZnJlc2hUb2tlbogBARJNChJzdG9yZWRfY3JlZGVudGlhbHMYBiABKA4y'
    'Hi5qb25saW5lLkZlZGVyYXRpb25DcmVkZW50aWFsc1IRc3RvcmVkQ3JlZGVudGlhbHMSVgoUcm'
    'V0dXJuZWRfY3JlZGVudGlhbHMYByABKA4yHi5qb25saW5lLkZlZGVyYXRpb25DcmVkZW50aWFs'
    'c0gCUhNyZXR1cm5lZENyZWRlbnRpYWxziAEBQgsKCV9wYXNzd29yZEIQCg5fcmVmcmVzaF90b2'
    'tlbkIXChVfcmV0dXJuZWRfY3JlZGVudGlhbHM=');

@$core.Deprecated('Use federateResponseDescriptor instead')
const FederateResponse$json = {
  '1': 'FederateResponse',
  '2': [
    {'1': 'refresh_token', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'refreshToken', '17': true},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'password', '17': true},
  ],
  '8': [
    {'1': '_refresh_token'},
    {'1': '_password'},
  ],
};

/// Descriptor for `FederateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List federateResponseDescriptor = $convert.base64Decode(
    'ChBGZWRlcmF0ZVJlc3BvbnNlEigKDXJlZnJlc2hfdG9rZW4YASABKAlIAFIMcmVmcmVzaFRva2'
    'VuiAEBEh8KCHBhc3N3b3JkGAIgASgJSAFSCHBhc3N3b3JkiAEBQhAKDl9yZWZyZXNoX3Rva2Vu'
    'QgsKCV9wYXNzd29yZA==');

@$core.Deprecated('Use getFederatedAccountsRequestDescriptor instead')
const GetFederatedAccountsRequest$json = {
  '1': 'GetFederatedAccountsRequest',
  '2': [
    {'1': 'returned_credentials', '3': 1, '4': 1, '5': 14, '6': '.jonline.FederationCredentials', '9': 0, '10': 'returnedCredentials', '17': true},
  ],
  '8': [
    {'1': '_returned_credentials'},
  ],
};

/// Descriptor for `GetFederatedAccountsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getFederatedAccountsRequestDescriptor = $convert.base64Decode(
    'ChtHZXRGZWRlcmF0ZWRBY2NvdW50c1JlcXVlc3QSVgoUcmV0dXJuZWRfY3JlZGVudGlhbHMYAS'
    'ABKA4yHi5qb25saW5lLkZlZGVyYXRpb25DcmVkZW50aWFsc0gAUhNyZXR1cm5lZENyZWRlbnRp'
    'YWxziAEBQhcKFV9yZXR1cm5lZF9jcmVkZW50aWFscw==');

@$core.Deprecated('Use getFederatedAccountsResponseDescriptor instead')
const GetFederatedAccountsResponse$json = {
  '1': 'GetFederatedAccountsResponse',
  '2': [
    {'1': 'federated_accounts', '3': 1, '4': 3, '5': 11, '6': '.jonline.FederatedAccount', '10': 'federatedAccounts'},
  ],
};

/// Descriptor for `GetFederatedAccountsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getFederatedAccountsResponseDescriptor = $convert.base64Decode(
    'ChxHZXRGZWRlcmF0ZWRBY2NvdW50c1Jlc3BvbnNlEkgKEmZlZGVyYXRlZF9hY2NvdW50cxgBIA'
    'MoCzIZLmpvbmxpbmUuRmVkZXJhdGVkQWNjb3VudFIRZmVkZXJhdGVkQWNjb3VudHM=');

@$core.Deprecated('Use federatedAccountDescriptor instead')
const FederatedAccount$json = {
  '1': 'FederatedAccount',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'server', '3': 2, '4': 1, '5': 9, '10': 'server'},
    {'1': 'username', '3': 3, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'password', '17': true},
    {'1': 'refresh_token', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'refreshToken', '17': true},
  ],
  '8': [
    {'1': '_password'},
    {'1': '_refresh_token'},
  ],
};

/// Descriptor for `FederatedAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List federatedAccountDescriptor = $convert.base64Decode(
    'ChBGZWRlcmF0ZWRBY2NvdW50Eg4KAmlkGAEgASgJUgJpZBIWCgZzZXJ2ZXIYAiABKAlSBnNlcn'
    'ZlchIaCgh1c2VybmFtZRgDIAEoCVIIdXNlcm5hbWUSHwoIcGFzc3dvcmQYBCABKAlIAFIIcGFz'
    'c3dvcmSIAQESKAoNcmVmcmVzaF90b2tlbhgFIAEoCUgBUgxyZWZyZXNoVG9rZW6IAQFCCwoJX3'
    'Bhc3N3b3JkQhAKDl9yZWZyZXNoX3Rva2Vu');

