//
//  Generated code. Do not modify.
//  source: authentication.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use createAccountRequestDescriptor instead')
const CreateAccountRequest$json = {
  '1': 'CreateAccountRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    {'1': 'email', '3': 3, '4': 1, '5': 11, '6': '.rellm.ContactMethod', '9': 0, '10': 'email', '17': true},
    {'1': 'phone', '3': 4, '4': 1, '5': 11, '6': '.rellm.ContactMethod', '9': 1, '10': 'phone', '17': true},
    {'1': 'expires_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 2, '10': 'expiresAt', '17': true},
    {'1': 'device_name', '3': 6, '4': 1, '5': 9, '9': 3, '10': 'deviceName', '17': true},
  ],
  '8': [
    {'1': '_email'},
    {'1': '_phone'},
    {'1': '_expires_at'},
    {'1': '_device_name'},
  ],
};

/// Descriptor for `CreateAccountRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createAccountRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVBY2NvdW50UmVxdWVzdBIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWUSGgoIcG'
    'Fzc3dvcmQYAiABKAlSCHBhc3N3b3JkEi8KBWVtYWlsGAMgASgLMhQucmVsbG0uQ29udGFjdE1l'
    'dGhvZEgAUgVlbWFpbIgBARIvCgVwaG9uZRgEIAEoCzIULnJlbGxtLkNvbnRhY3RNZXRob2RIAV'
    'IFcGhvbmWIAQESPgoKZXhwaXJlc19hdBgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh'
    'bXBIAlIJZXhwaXJlc0F0iAEBEiQKC2RldmljZV9uYW1lGAYgASgJSANSCmRldmljZU5hbWWIAQ'
    'FCCAoGX2VtYWlsQggKBl9waG9uZUINCgtfZXhwaXJlc19hdEIOCgxfZGV2aWNlX25hbWU=');

@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = {
  '1': 'LoginRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    {'1': 'expires_at', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'expiresAt', '17': true},
    {'1': 'device_name', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'deviceName', '17': true},
    {'1': 'user_id', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'userId', '17': true},
  ],
  '8': [
    {'1': '_expires_at'},
    {'1': '_device_name'},
    {'1': '_user_id'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode(
    'CgxMb2dpblJlcXVlc3QSGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEhoKCHBhc3N3b3JkGA'
    'IgASgJUghwYXNzd29yZBI+CgpleHBpcmVzX2F0GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp'
    'bWVzdGFtcEgAUglleHBpcmVzQXSIAQESJAoLZGV2aWNlX25hbWUYBCABKAlIAVIKZGV2aWNlTm'
    'FtZYgBARIcCgd1c2VyX2lkGAUgASgJSAJSBnVzZXJJZIgBAUINCgtfZXhwaXJlc19hdEIOCgxf'
    'ZGV2aWNlX25hbWVCCgoIX3VzZXJfaWQ=');

@$core.Deprecated('Use createThirdPartyRefreshTokenRequestDescriptor instead')
const CreateThirdPartyRefreshTokenRequest$json = {
  '1': 'CreateThirdPartyRefreshTokenRequest',
  '2': [
    {'1': 'expires_at', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'expiresAt', '17': true},
    {'1': 'user_id', '3': 3, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'device_name', '3': 4, '4': 1, '5': 9, '10': 'deviceName'},
  ],
  '8': [
    {'1': '_expires_at'},
  ],
};

/// Descriptor for `CreateThirdPartyRefreshTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createThirdPartyRefreshTokenRequestDescriptor = $convert.base64Decode(
    'CiNDcmVhdGVUaGlyZFBhcnR5UmVmcmVzaFRva2VuUmVxdWVzdBI+CgpleHBpcmVzX2F0GAIgAS'
    'gLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgAUglleHBpcmVzQXSIAQESFwoHdXNlcl9p'
    'ZBgDIAEoCVIGdXNlcklkEh8KC2RldmljZV9uYW1lGAQgASgJUgpkZXZpY2VOYW1lQg0KC19leH'
    'BpcmVzX2F0');

@$core.Deprecated('Use refreshTokenResponseDescriptor instead')
const RefreshTokenResponse$json = {
  '1': 'RefreshTokenResponse',
  '2': [
    {'1': 'refresh_token', '3': 1, '4': 1, '5': 11, '6': '.rellm.ExpirableToken', '10': 'refreshToken'},
    {'1': 'access_token', '3': 2, '4': 1, '5': 11, '6': '.rellm.ExpirableToken', '10': 'accessToken'},
    {'1': 'user', '3': 3, '4': 1, '5': 11, '6': '.rellm.User', '10': 'user'},
  ],
};

/// Descriptor for `RefreshTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshTokenResponseDescriptor = $convert.base64Decode(
    'ChRSZWZyZXNoVG9rZW5SZXNwb25zZRI6Cg1yZWZyZXNoX3Rva2VuGAEgASgLMhUucmVsbG0uRX'
    'hwaXJhYmxlVG9rZW5SDHJlZnJlc2hUb2tlbhI4CgxhY2Nlc3NfdG9rZW4YAiABKAsyFS5yZWxs'
    'bS5FeHBpcmFibGVUb2tlblILYWNjZXNzVG9rZW4SHwoEdXNlchgDIAEoCzILLnJlbGxtLlVzZX'
    'JSBHVzZXI=');

@$core.Deprecated('Use expirableTokenDescriptor instead')
const ExpirableToken$json = {
  '1': 'ExpirableToken',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {'1': 'expires_at', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'expiresAt', '17': true},
  ],
  '8': [
    {'1': '_expires_at'},
  ],
};

/// Descriptor for `ExpirableToken`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List expirableTokenDescriptor = $convert.base64Decode(
    'Cg5FeHBpcmFibGVUb2tlbhIUCgV0b2tlbhgBIAEoCVIFdG9rZW4SPgoKZXhwaXJlc19hdBgCIA'
    'EoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIAFIJZXhwaXJlc0F0iAEBQg0KC19leHBp'
    'cmVzX2F0');

@$core.Deprecated('Use accessTokenRequestDescriptor instead')
const AccessTokenRequest$json = {
  '1': 'AccessTokenRequest',
  '2': [
    {'1': 'refresh_token', '3': 1, '4': 1, '5': 9, '10': 'refreshToken'},
    {'1': 'expires_at', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'expiresAt', '17': true},
  ],
  '8': [
    {'1': '_expires_at'},
  ],
};

/// Descriptor for `AccessTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accessTokenRequestDescriptor = $convert.base64Decode(
    'ChJBY2Nlc3NUb2tlblJlcXVlc3QSIwoNcmVmcmVzaF90b2tlbhgBIAEoCVIMcmVmcmVzaFRva2'
    'VuEj4KCmV4cGlyZXNfYXQYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSABSCWV4'
    'cGlyZXNBdIgBAUINCgtfZXhwaXJlc19hdA==');

@$core.Deprecated('Use accessTokenResponseDescriptor instead')
const AccessTokenResponse$json = {
  '1': 'AccessTokenResponse',
  '2': [
    {'1': 'refresh_token', '3': 1, '4': 1, '5': 11, '6': '.rellm.ExpirableToken', '9': 0, '10': 'refreshToken', '17': true},
    {'1': 'access_token', '3': 2, '4': 1, '5': 11, '6': '.rellm.ExpirableToken', '10': 'accessToken'},
  ],
  '8': [
    {'1': '_refresh_token'},
  ],
};

/// Descriptor for `AccessTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accessTokenResponseDescriptor = $convert.base64Decode(
    'ChNBY2Nlc3NUb2tlblJlc3BvbnNlEj8KDXJlZnJlc2hfdG9rZW4YASABKAsyFS5yZWxsbS5FeH'
    'BpcmFibGVUb2tlbkgAUgxyZWZyZXNoVG9rZW6IAQESOAoMYWNjZXNzX3Rva2VuGAIgASgLMhUu'
    'cmVsbG0uRXhwaXJhYmxlVG9rZW5SC2FjY2Vzc1Rva2VuQhAKDl9yZWZyZXNoX3Rva2Vu');

@$core.Deprecated('Use resetPasswordRequestDescriptor instead')
const ResetPasswordRequest$json = {
  '1': 'ResetPasswordRequest',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'userId', '17': true},
    {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
  ],
  '8': [
    {'1': '_user_id'},
  ],
};

/// Descriptor for `ResetPasswordRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetPasswordRequestDescriptor = $convert.base64Decode(
    'ChRSZXNldFBhc3N3b3JkUmVxdWVzdBIcCgd1c2VyX2lkGAEgASgJSABSBnVzZXJJZIgBARIaCg'
    'hwYXNzd29yZBgDIAEoCVIIcGFzc3dvcmRCCgoIX3VzZXJfaWQ=');

@$core.Deprecated('Use userRefreshTokensResponseDescriptor instead')
const UserRefreshTokensResponse$json = {
  '1': 'UserRefreshTokensResponse',
  '2': [
    {'1': 'refresh_tokens', '3': 1, '4': 3, '5': 11, '6': '.rellm.RefreshTokenMetadata', '10': 'refreshTokens'},
  ],
};

/// Descriptor for `UserRefreshTokensResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userRefreshTokensResponseDescriptor = $convert.base64Decode(
    'ChlVc2VyUmVmcmVzaFRva2Vuc1Jlc3BvbnNlEkIKDnJlZnJlc2hfdG9rZW5zGAEgAygLMhsucm'
    'VsbG0uUmVmcmVzaFRva2VuTWV0YWRhdGFSDXJlZnJlc2hUb2tlbnM=');

@$core.Deprecated('Use refreshTokenMetadataDescriptor instead')
const RefreshTokenMetadata$json = {
  '1': 'RefreshTokenMetadata',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    {'1': 'expires_at', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'expiresAt', '17': true},
    {'1': 'device_name', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'deviceName', '17': true},
    {'1': 'is_this_device', '3': 4, '4': 1, '5': 8, '10': 'isThisDevice'},
    {'1': 'third_party', '3': 5, '4': 1, '5': 8, '10': 'thirdParty'},
  ],
  '8': [
    {'1': '_expires_at'},
    {'1': '_device_name'},
  ],
};

/// Descriptor for `RefreshTokenMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshTokenMetadataDescriptor = $convert.base64Decode(
    'ChRSZWZyZXNoVG9rZW5NZXRhZGF0YRIOCgJpZBgBIAEoBFICaWQSPgoKZXhwaXJlc19hdBgCIA'
    'EoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIAFIJZXhwaXJlc0F0iAEBEiQKC2Rldmlj'
    'ZV9uYW1lGAMgASgJSAFSCmRldmljZU5hbWWIAQESJAoOaXNfdGhpc19kZXZpY2UYBCABKAhSDG'
    'lzVGhpc0RldmljZRIfCgt0aGlyZF9wYXJ0eRgFIAEoCFIKdGhpcmRQYXJ0eUINCgtfZXhwaXJl'
    'c19hdEIOCgxfZGV2aWNlX25hbWU=');

