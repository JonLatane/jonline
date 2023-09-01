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
    {'1': 'email', '3': 3, '4': 1, '5': 11, '6': '.jonline.ContactMethod', '9': 0, '10': 'email', '17': true},
    {'1': 'phone', '3': 4, '4': 1, '5': 11, '6': '.jonline.ContactMethod', '9': 1, '10': 'phone', '17': true},
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
    'Fzc3dvcmQYAiABKAlSCHBhc3N3b3JkEjEKBWVtYWlsGAMgASgLMhYuam9ubGluZS5Db250YWN0'
    'TWV0aG9kSABSBWVtYWlsiAEBEjEKBXBob25lGAQgASgLMhYuam9ubGluZS5Db250YWN0TWV0aG'
    '9kSAFSBXBob25liAEBEj4KCmV4cGlyZXNfYXQYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt'
    'ZXN0YW1wSAJSCWV4cGlyZXNBdIgBARIkCgtkZXZpY2VfbmFtZRgGIAEoCUgDUgpkZXZpY2VOYW'
    '1liAEBQggKBl9lbWFpbEIICgZfcGhvbmVCDQoLX2V4cGlyZXNfYXRCDgoMX2RldmljZV9uYW1l');

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

@$core.Deprecated('Use refreshTokenResponseDescriptor instead')
const RefreshTokenResponse$json = {
  '1': 'RefreshTokenResponse',
  '2': [
    {'1': 'refresh_token', '3': 1, '4': 1, '5': 11, '6': '.jonline.ExpirableToken', '10': 'refreshToken'},
    {'1': 'access_token', '3': 2, '4': 1, '5': 11, '6': '.jonline.ExpirableToken', '10': 'accessToken'},
    {'1': 'user', '3': 3, '4': 1, '5': 11, '6': '.jonline.User', '10': 'user'},
  ],
};

/// Descriptor for `RefreshTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshTokenResponseDescriptor = $convert.base64Decode(
    'ChRSZWZyZXNoVG9rZW5SZXNwb25zZRI8Cg1yZWZyZXNoX3Rva2VuGAEgASgLMhcuam9ubGluZS'
    '5FeHBpcmFibGVUb2tlblIMcmVmcmVzaFRva2VuEjoKDGFjY2Vzc190b2tlbhgCIAEoCzIXLmpv'
    'bmxpbmUuRXhwaXJhYmxlVG9rZW5SC2FjY2Vzc1Rva2VuEiEKBHVzZXIYAyABKAsyDS5qb25saW'
    '5lLlVzZXJSBHVzZXI=');

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
    {'1': 'refresh_token', '3': 1, '4': 1, '5': 11, '6': '.jonline.ExpirableToken', '9': 0, '10': 'refreshToken', '17': true},
    {'1': 'access_token', '3': 2, '4': 1, '5': 11, '6': '.jonline.ExpirableToken', '10': 'accessToken'},
  ],
  '8': [
    {'1': '_refresh_token'},
  ],
};

/// Descriptor for `AccessTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accessTokenResponseDescriptor = $convert.base64Decode(
    'ChNBY2Nlc3NUb2tlblJlc3BvbnNlEkEKDXJlZnJlc2hfdG9rZW4YASABKAsyFy5qb25saW5lLk'
    'V4cGlyYWJsZVRva2VuSABSDHJlZnJlc2hUb2tlbogBARI6CgxhY2Nlc3NfdG9rZW4YAiABKAsy'
    'Fy5qb25saW5lLkV4cGlyYWJsZVRva2VuUgthY2Nlc3NUb2tlbkIQCg5fcmVmcmVzaF90b2tlbg'
    '==');

