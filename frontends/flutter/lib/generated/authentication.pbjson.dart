///
//  Generated code. Do not modify.
//  source: authentication.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use createAccountRequestDescriptor instead')
const CreateAccountRequest$json = const {
  '1': 'CreateAccountRequest',
  '2': const [
    const {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    const {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    const {'1': 'email', '3': 3, '4': 1, '5': 11, '6': '.jonline.ContactMethod', '9': 0, '10': 'email', '17': true},
    const {'1': 'phone', '3': 4, '4': 1, '5': 11, '6': '.jonline.ContactMethod', '9': 1, '10': 'phone', '17': true},
    const {'1': 'expires_at', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 2, '10': 'expiresAt', '17': true},
    const {'1': 'device_name', '3': 6, '4': 1, '5': 9, '9': 3, '10': 'deviceName', '17': true},
  ],
  '8': const [
    const {'1': '_email'},
    const {'1': '_phone'},
    const {'1': '_expires_at'},
    const {'1': '_device_name'},
  ],
};

/// Descriptor for `CreateAccountRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createAccountRequestDescriptor = $convert.base64Decode('ChRDcmVhdGVBY2NvdW50UmVxdWVzdBIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWUSGgoIcGFzc3dvcmQYAiABKAlSCHBhc3N3b3JkEjEKBWVtYWlsGAMgASgLMhYuam9ubGluZS5Db250YWN0TWV0aG9kSABSBWVtYWlsiAEBEjEKBXBob25lGAQgASgLMhYuam9ubGluZS5Db250YWN0TWV0aG9kSAFSBXBob25liAEBEj4KCmV4cGlyZXNfYXQYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSAJSCWV4cGlyZXNBdIgBARIkCgtkZXZpY2VfbmFtZRgGIAEoCUgDUgpkZXZpY2VOYW1liAEBQggKBl9lbWFpbEIICgZfcGhvbmVCDQoLX2V4cGlyZXNfYXRCDgoMX2RldmljZV9uYW1l');
@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = const {
  '1': 'LoginRequest',
  '2': const [
    const {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    const {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    const {'1': 'expires_at', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'expiresAt', '17': true},
    const {'1': 'device_name', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'deviceName', '17': true},
  ],
  '8': const [
    const {'1': '_expires_at'},
    const {'1': '_device_name'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode('CgxMb2dpblJlcXVlc3QSGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEhoKCHBhc3N3b3JkGAIgASgJUghwYXNzd29yZBI+CgpleHBpcmVzX2F0GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgAUglleHBpcmVzQXSIAQESJAoLZGV2aWNlX25hbWUYBCABKAlIAVIKZGV2aWNlTmFtZYgBAUINCgtfZXhwaXJlc19hdEIOCgxfZGV2aWNlX25hbWU=');
@$core.Deprecated('Use refreshTokenResponseDescriptor instead')
const RefreshTokenResponse$json = const {
  '1': 'RefreshTokenResponse',
  '2': const [
    const {'1': 'refresh_token', '3': 1, '4': 1, '5': 11, '6': '.jonline.ExpirableToken', '10': 'refreshToken'},
    const {'1': 'access_token', '3': 2, '4': 1, '5': 11, '6': '.jonline.ExpirableToken', '10': 'accessToken'},
    const {'1': 'user', '3': 3, '4': 1, '5': 11, '6': '.jonline.User', '10': 'user'},
  ],
};

/// Descriptor for `RefreshTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshTokenResponseDescriptor = $convert.base64Decode('ChRSZWZyZXNoVG9rZW5SZXNwb25zZRI8Cg1yZWZyZXNoX3Rva2VuGAEgASgLMhcuam9ubGluZS5FeHBpcmFibGVUb2tlblIMcmVmcmVzaFRva2VuEjoKDGFjY2Vzc190b2tlbhgCIAEoCzIXLmpvbmxpbmUuRXhwaXJhYmxlVG9rZW5SC2FjY2Vzc1Rva2VuEiEKBHVzZXIYAyABKAsyDS5qb25saW5lLlVzZXJSBHVzZXI=');
@$core.Deprecated('Use expirableTokenDescriptor instead')
const ExpirableToken$json = const {
  '1': 'ExpirableToken',
  '2': const [
    const {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    const {'1': 'expires_at', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'expiresAt', '17': true},
  ],
  '8': const [
    const {'1': '_expires_at'},
  ],
};

/// Descriptor for `ExpirableToken`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List expirableTokenDescriptor = $convert.base64Decode('Cg5FeHBpcmFibGVUb2tlbhIUCgV0b2tlbhgBIAEoCVIFdG9rZW4SPgoKZXhwaXJlc19hdBgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIAFIJZXhwaXJlc0F0iAEBQg0KC19leHBpcmVzX2F0');
@$core.Deprecated('Use accessTokenRequestDescriptor instead')
const AccessTokenRequest$json = const {
  '1': 'AccessTokenRequest',
  '2': const [
    const {'1': 'refresh_token', '3': 1, '4': 1, '5': 9, '10': 'refreshToken'},
    const {'1': 'expires_at', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'expiresAt', '17': true},
  ],
  '8': const [
    const {'1': '_expires_at'},
  ],
};

/// Descriptor for `AccessTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accessTokenRequestDescriptor = $convert.base64Decode('ChJBY2Nlc3NUb2tlblJlcXVlc3QSIwoNcmVmcmVzaF90b2tlbhgBIAEoCVIMcmVmcmVzaFRva2VuEj4KCmV4cGlyZXNfYXQYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSABSCWV4cGlyZXNBdIgBAUINCgtfZXhwaXJlc19hdA==');
@$core.Deprecated('Use accessTokenResponseDescriptor instead')
const AccessTokenResponse$json = const {
  '1': 'AccessTokenResponse',
  '2': const [
    const {'1': 'access_token', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'accessToken', '17': true},
    const {'1': 'expires_at', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 1, '10': 'expiresAt', '17': true},
  ],
  '8': const [
    const {'1': '_access_token'},
    const {'1': '_expires_at'},
  ],
};

/// Descriptor for `AccessTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accessTokenResponseDescriptor = $convert.base64Decode('ChNBY2Nlc3NUb2tlblJlc3BvbnNlEiYKDGFjY2Vzc190b2tlbhgCIAEoCUgAUgthY2Nlc3NUb2tlbogBARI+CgpleHBpcmVzX2F0GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgBUglleHBpcmVzQXSIAQFCDwoNX2FjY2Vzc190b2tlbkINCgtfZXhwaXJlc19hdA==');
