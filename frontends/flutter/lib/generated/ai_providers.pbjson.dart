//
//  Generated code. Do not modify.
//  source: ai_providers.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use aIModelCapabilityDescriptor instead')
const AIModelCapability$json = {
  '1': 'AIModelCapability',
  '2': [
    {'1': 'AI_MODEL_CAPABILITY_UNKNOWN', '2': 0},
    {'1': 'AI_MODEL_CAPABILITY_TEXT_GENERATION', '2': 1},
    {'1': 'AI_MODEL_CAPABILITY_IMAGE_GENERATION', '2': 2},
    {'1': 'AI_MODEL_CAPABILITY_IMAGE_EDITING', '2': 3},
  ],
};

/// Descriptor for `AIModelCapability`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List aIModelCapabilityDescriptor = $convert.base64Decode(
    'ChFBSU1vZGVsQ2FwYWJpbGl0eRIfChtBSV9NT0RFTF9DQVBBQklMSVRZX1VOS05PV04QABInCi'
    'NBSV9NT0RFTF9DQVBBQklMSVRZX1RFWFRfR0VORVJBVElPThABEigKJEFJX01PREVMX0NBUEFC'
    'SUxJVFlfSU1BR0VfR0VORVJBVElPThACEiUKIUFJX01PREVMX0NBUEFCSUxJVFlfSU1BR0VfRU'
    'RJVElORxAD');

@$core.Deprecated('Use aIModelDescriptor instead')
const AIModel$json = {
  '1': 'AIModel',
  '2': [
    {'1': 'model_name', '3': 1, '4': 1, '5': 9, '10': 'modelName'},
    {'1': 'capabilities', '3': 2, '4': 3, '5': 14, '6': '.rellm.AIModelCapability', '10': 'capabilities'},
    {'1': 'grant', '3': 3, '4': 1, '5': 11, '6': '.rellm.AIProviderGrant', '9': 0, '10': 'grant', '17': true},
    {'1': 'provider', '3': 4, '4': 1, '5': 11, '6': '.rellm.AIProvider', '10': 'provider'},
  ],
  '8': [
    {'1': '_grant'},
  ],
};

/// Descriptor for `AIModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aIModelDescriptor = $convert.base64Decode(
    'CgdBSU1vZGVsEh0KCm1vZGVsX25hbWUYASABKAlSCW1vZGVsTmFtZRI8CgxjYXBhYmlsaXRpZX'
    'MYAiADKA4yGC5yZWxsbS5BSU1vZGVsQ2FwYWJpbGl0eVIMY2FwYWJpbGl0aWVzEjEKBWdyYW50'
    'GAMgASgLMhYucmVsbG0uQUlQcm92aWRlckdyYW50SABSBWdyYW50iAEBEi0KCHByb3ZpZGVyGA'
    'QgASgLMhEucmVsbG0uQUlQcm92aWRlclIIcHJvdmlkZXJCCAoGX2dyYW50');

@$core.Deprecated('Use generateMediaRequestDescriptor instead')
const GenerateMediaRequest$json = {
  '1': 'GenerateMediaRequest',
  '2': [
    {'1': 'model', '3': 1, '4': 1, '5': 11, '6': '.rellm.AIModel', '10': 'model'},
    {'1': 'user_prompt', '3': 2, '4': 1, '5': 9, '10': 'userPrompt'},
    {'1': 'media_ids', '3': 3, '4': 3, '5': 9, '10': 'mediaIds'},
    {'1': 'post_id', '3': 5, '4': 1, '5': 9, '9': 0, '10': 'postId'},
    {'1': 'occasion_id', '3': 6, '4': 1, '5': 9, '9': 0, '10': 'occasionId'},
  ],
  '8': [
    {'1': 'target'},
  ],
};

/// Descriptor for `GenerateMediaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateMediaRequestDescriptor = $convert.base64Decode(
    'ChRHZW5lcmF0ZU1lZGlhUmVxdWVzdBIkCgVtb2RlbBgBIAEoCzIOLnJlbGxtLkFJTW9kZWxSBW'
    '1vZGVsEh8KC3VzZXJfcHJvbXB0GAIgASgJUgp1c2VyUHJvbXB0EhsKCW1lZGlhX2lkcxgDIAMo'
    'CVIIbWVkaWFJZHMSGQoHcG9zdF9pZBgFIAEoCUgAUgZwb3N0SWQSIQoLb2NjYXNpb25faWQYBi'
    'ABKAlIAFIKb2NjYXNpb25JZEIICgZ0YXJnZXQ=');

@$core.Deprecated('Use aIProviderDescriptor instead')
const AIProvider$json = {
  '1': 'AIProvider',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'owner', '3': 2, '4': 1, '5': 11, '6': '.rellm.Author', '10': 'owner'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'gemini_credentials', '3': 4, '4': 1, '5': 11, '6': '.rellm.GeminiCredentials', '9': 0, '10': 'geminiCredentials'},
    {'1': 'openai_credentials', '3': 5, '4': 1, '5': 11, '6': '.rellm.OpenAICredentials', '9': 0, '10': 'openaiCredentials'},
    {'1': 'anthropic_credentials', '3': 6, '4': 1, '5': 11, '6': '.rellm.AnthropicCredentials', '9': 0, '10': 'anthropicCredentials'},
    {'1': 'digitalocean_credentials', '3': 7, '4': 1, '5': 11, '6': '.rellm.DigitalOceanCredentials', '9': 0, '10': 'digitaloceanCredentials'},
    {'1': 'grants', '3': 14, '4': 3, '5': 11, '6': '.rellm.AIProviderGrant', '10': 'grants'},
    {'1': 'created_at', '3': 15, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 16, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 1, '10': 'updatedAt', '17': true},
  ],
  '8': [
    {'1': 'provider'},
    {'1': '_updated_at'},
  ],
};

/// Descriptor for `AIProvider`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aIProviderDescriptor = $convert.base64Decode(
    'CgpBSVByb3ZpZGVyEg4KAmlkGAEgASgJUgJpZBIjCgVvd25lchgCIAEoCzINLnJlbGxtLkF1dG'
    'hvclIFb3duZXISEgoEbmFtZRgDIAEoCVIEbmFtZRJJChJnZW1pbmlfY3JlZGVudGlhbHMYBCAB'
    'KAsyGC5yZWxsbS5HZW1pbmlDcmVkZW50aWFsc0gAUhFnZW1pbmlDcmVkZW50aWFscxJJChJvcG'
    'VuYWlfY3JlZGVudGlhbHMYBSABKAsyGC5yZWxsbS5PcGVuQUlDcmVkZW50aWFsc0gAUhFvcGVu'
    'YWlDcmVkZW50aWFscxJSChVhbnRocm9waWNfY3JlZGVudGlhbHMYBiABKAsyGy5yZWxsbS5Bbn'
    'Rocm9waWNDcmVkZW50aWFsc0gAUhRhbnRocm9waWNDcmVkZW50aWFscxJbChhkaWdpdGFsb2Nl'
    'YW5fY3JlZGVudGlhbHMYByABKAsyHi5yZWxsbS5EaWdpdGFsT2NlYW5DcmVkZW50aWFsc0gAUh'
    'dkaWdpdGFsb2NlYW5DcmVkZW50aWFscxIuCgZncmFudHMYDiADKAsyFi5yZWxsbS5BSVByb3Zp'
    'ZGVyR3JhbnRSBmdyYW50cxI5CgpjcmVhdGVkX2F0GA8gASgLMhouZ29vZ2xlLnByb3RvYnVmLl'
    'RpbWVzdGFtcFIJY3JlYXRlZEF0Ej4KCnVwZGF0ZWRfYXQYECABKAsyGi5nb29nbGUucHJvdG9i'
    'dWYuVGltZXN0YW1wSAFSCXVwZGF0ZWRBdIgBAUIKCghwcm92aWRlckINCgtfdXBkYXRlZF9hdA'
    '==');

@$core.Deprecated('Use aIProviderGrantDescriptor instead')
const AIProviderGrant$json = {
  '1': 'AIProviderGrant',
  '2': [
    {'1': 'ai_provider_id', '3': 1, '4': 1, '5': 9, '10': 'aiProviderId'},
    {'1': 'ai_model_grantee', '3': 2, '4': 1, '5': 11, '6': '.rellm.Author', '10': 'aiModelGrantee'},
    {'1': 'model_names', '3': 3, '4': 3, '5': 9, '10': 'modelNames'},
    {'1': 'tokens_remaining', '3': 4, '4': 1, '5': 4, '10': 'tokensRemaining'},
    {'1': 'overage', '3': 5, '4': 1, '5': 4, '10': 'overage'},
    {'1': 'created_at', '3': 15, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 16, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 0, '10': 'updatedAt', '17': true},
  ],
  '8': [
    {'1': '_updated_at'},
  ],
};

/// Descriptor for `AIProviderGrant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aIProviderGrantDescriptor = $convert.base64Decode(
    'Cg9BSVByb3ZpZGVyR3JhbnQSJAoOYWlfcHJvdmlkZXJfaWQYASABKAlSDGFpUHJvdmlkZXJJZB'
    'I3ChBhaV9tb2RlbF9ncmFudGVlGAIgASgLMg0ucmVsbG0uQXV0aG9yUg5haU1vZGVsR3JhbnRl'
    'ZRIfCgttb2RlbF9uYW1lcxgDIAMoCVIKbW9kZWxOYW1lcxIpChB0b2tlbnNfcmVtYWluaW5nGA'
    'QgASgEUg90b2tlbnNSZW1haW5pbmcSGAoHb3ZlcmFnZRgFIAEoBFIHb3ZlcmFnZRI5CgpjcmVh'
    'dGVkX2F0GA8gASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJY3JlYXRlZEF0Ej4KCn'
    'VwZGF0ZWRfYXQYECABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wSABSCXVwZGF0ZWRB'
    'dIgBAUINCgtfdXBkYXRlZF9hdA==');

@$core.Deprecated('Use getAIProvidersResponseDescriptor instead')
const GetAIProvidersResponse$json = {
  '1': 'GetAIProvidersResponse',
  '2': [
    {'1': 'providers', '3': 1, '4': 3, '5': 11, '6': '.rellm.AIProvider', '10': 'providers'},
    {'1': 'ai_models', '3': 2, '4': 3, '5': 11, '6': '.rellm.AIModel', '10': 'aiModels'},
  ],
};

/// Descriptor for `GetAIProvidersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAIProvidersResponseDescriptor = $convert.base64Decode(
    'ChZHZXRBSVByb3ZpZGVyc1Jlc3BvbnNlEi8KCXByb3ZpZGVycxgBIAMoCzIRLnJlbGxtLkFJUH'
    'JvdmlkZXJSCXByb3ZpZGVycxIrCglhaV9tb2RlbHMYAiADKAsyDi5yZWxsbS5BSU1vZGVsUghh'
    'aU1vZGVscw==');

@$core.Deprecated('Use deleteAIProviderRequestDescriptor instead')
const DeleteAIProviderRequest$json = {
  '1': 'DeleteAIProviderRequest',
  '2': [
    {'1': 'provider', '3': 1, '4': 1, '5': 11, '6': '.rellm.AIProvider', '10': 'provider'},
  ],
};

/// Descriptor for `DeleteAIProviderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteAIProviderRequestDescriptor = $convert.base64Decode(
    'ChdEZWxldGVBSVByb3ZpZGVyUmVxdWVzdBItCghwcm92aWRlchgBIAEoCzIRLnJlbGxtLkFJUH'
    'JvdmlkZXJSCHByb3ZpZGVy');

@$core.Deprecated('Use grantAIProviderRequestDescriptor instead')
const GrantAIProviderRequest$json = {
  '1': 'GrantAIProviderRequest',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'ai_provider_id', '3': 2, '4': 1, '5': 9, '10': 'aiProviderId'},
    {'1': 'tokens', '3': 3, '4': 1, '5': 4, '10': 'tokens'},
    {'1': 'model_names', '3': 4, '4': 3, '5': 9, '10': 'modelNames'},
  ],
};

/// Descriptor for `GrantAIProviderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grantAIProviderRequestDescriptor = $convert.base64Decode(
    'ChZHcmFudEFJUHJvdmlkZXJSZXF1ZXN0EhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIkCg5haV'
    '9wcm92aWRlcl9pZBgCIAEoCVIMYWlQcm92aWRlcklkEhYKBnRva2VucxgDIAEoBFIGdG9rZW5z'
    'Eh8KC21vZGVsX25hbWVzGAQgAygJUgptb2RlbE5hbWVz');

@$core.Deprecated('Use revokeAIProviderRequestDescriptor instead')
const RevokeAIProviderRequest$json = {
  '1': 'RevokeAIProviderRequest',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'ai_provider_id', '3': 2, '4': 1, '5': 9, '10': 'aiProviderId'},
  ],
};

/// Descriptor for `RevokeAIProviderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeAIProviderRequestDescriptor = $convert.base64Decode(
    'ChdSZXZva2VBSVByb3ZpZGVyUmVxdWVzdBIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSJAoOYW'
    'lfcHJvdmlkZXJfaWQYAiABKAlSDGFpUHJvdmlkZXJJZA==');

@$core.Deprecated('Use geminiCredentialsDescriptor instead')
const GeminiCredentials$json = {
  '1': 'GeminiCredentials',
  '2': [
    {'1': 'gemini_api_key', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'geminiApiKey', '17': true},
  ],
  '8': [
    {'1': '_gemini_api_key'},
  ],
};

/// Descriptor for `GeminiCredentials`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List geminiCredentialsDescriptor = $convert.base64Decode(
    'ChFHZW1pbmlDcmVkZW50aWFscxIpCg5nZW1pbmlfYXBpX2tleRgBIAEoCUgAUgxnZW1pbmlBcG'
    'lLZXmIAQFCEQoPX2dlbWluaV9hcGlfa2V5');

@$core.Deprecated('Use openAICredentialsDescriptor instead')
const OpenAICredentials$json = {
  '1': 'OpenAICredentials',
  '2': [
    {'1': 'openai_api_key', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'openaiApiKey', '17': true},
  ],
  '8': [
    {'1': '_openai_api_key'},
  ],
};

/// Descriptor for `OpenAICredentials`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openAICredentialsDescriptor = $convert.base64Decode(
    'ChFPcGVuQUlDcmVkZW50aWFscxIpCg5vcGVuYWlfYXBpX2tleRgBIAEoCUgAUgxvcGVuYWlBcG'
    'lLZXmIAQFCEQoPX29wZW5haV9hcGlfa2V5');

@$core.Deprecated('Use digitalOceanCredentialsDescriptor instead')
const DigitalOceanCredentials$json = {
  '1': 'DigitalOceanCredentials',
  '2': [
    {'1': 'digitalocean_api_key', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'digitaloceanApiKey', '17': true},
  ],
  '8': [
    {'1': '_digitalocean_api_key'},
  ],
};

/// Descriptor for `DigitalOceanCredentials`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List digitalOceanCredentialsDescriptor = $convert.base64Decode(
    'ChdEaWdpdGFsT2NlYW5DcmVkZW50aWFscxI1ChRkaWdpdGFsb2NlYW5fYXBpX2tleRgBIAEoCU'
    'gAUhJkaWdpdGFsb2NlYW5BcGlLZXmIAQFCFwoVX2RpZ2l0YWxvY2Vhbl9hcGlfa2V5');

@$core.Deprecated('Use anthropicCredentialsDescriptor instead')
const AnthropicCredentials$json = {
  '1': 'AnthropicCredentials',
  '2': [
    {'1': 'anthropic_api_key', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'anthropicApiKey', '17': true},
  ],
  '8': [
    {'1': '_anthropic_api_key'},
  ],
};

/// Descriptor for `AnthropicCredentials`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List anthropicCredentialsDescriptor = $convert.base64Decode(
    'ChRBbnRocm9waWNDcmVkZW50aWFscxIvChFhbnRocm9waWNfYXBpX2tleRgBIAEoCUgAUg9hbn'
    'Rocm9waWNBcGlLZXmIAQFCFAoSX2FudGhyb3BpY19hcGlfa2V5');

