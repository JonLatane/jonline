//
//  Generated code. Do not modify.
//  source: ai_model_providers.proto
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

@$core.Deprecated('Use availableAIModelDescriptor instead')
const AvailableAIModel$json = {
  '1': 'AvailableAIModel',
  '2': [
    {'1': 'model_name', '3': 1, '4': 1, '5': 9, '10': 'modelName'},
    {'1': 'capabilities', '3': 2, '4': 3, '5': 14, '6': '.rellm.AIModelCapability', '10': 'capabilities'},
    {'1': 'grant', '3': 3, '4': 1, '5': 11, '6': '.rellm.AIModelProviderGrant', '9': 0, '10': 'grant', '17': true},
    {'1': 'provider', '3': 4, '4': 1, '5': 11, '6': '.rellm.AIModelProvider', '10': 'provider'},
  ],
  '8': [
    {'1': '_grant'},
  ],
};

/// Descriptor for `AvailableAIModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List availableAIModelDescriptor = $convert.base64Decode(
    'ChBBdmFpbGFibGVBSU1vZGVsEh0KCm1vZGVsX25hbWUYASABKAlSCW1vZGVsTmFtZRI8CgxjYX'
    'BhYmlsaXRpZXMYAiADKA4yGC5yZWxsbS5BSU1vZGVsQ2FwYWJpbGl0eVIMY2FwYWJpbGl0aWVz'
    'EjYKBWdyYW50GAMgASgLMhsucmVsbG0uQUlNb2RlbFByb3ZpZGVyR3JhbnRIAFIFZ3JhbnSIAQ'
    'ESMgoIcHJvdmlkZXIYBCABKAsyFi5yZWxsbS5BSU1vZGVsUHJvdmlkZXJSCHByb3ZpZGVyQggK'
    'Bl9ncmFudA==');

@$core.Deprecated('Use generateMediaRequestDescriptor instead')
const GenerateMediaRequest$json = {
  '1': 'GenerateMediaRequest',
  '2': [
    {'1': 'model', '3': 1, '4': 1, '5': 11, '6': '.rellm.AvailableAIModel', '10': 'model'},
    {'1': 'user_prompt', '3': 2, '4': 1, '5': 9, '10': 'userPrompt'},
    {'1': 'media_ids', '3': 3, '4': 3, '5': 9, '10': 'mediaIds'},
    {'1': 'post_id', '3': 5, '4': 1, '5': 9, '9': 0, '10': 'postId'},
    {'1': 'event_instance_id', '3': 6, '4': 1, '5': 9, '9': 0, '10': 'eventInstanceId'},
  ],
  '8': [
    {'1': 'target'},
  ],
};

/// Descriptor for `GenerateMediaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateMediaRequestDescriptor = $convert.base64Decode(
    'ChRHZW5lcmF0ZU1lZGlhUmVxdWVzdBItCgVtb2RlbBgBIAEoCzIXLnJlbGxtLkF2YWlsYWJsZU'
    'FJTW9kZWxSBW1vZGVsEh8KC3VzZXJfcHJvbXB0GAIgASgJUgp1c2VyUHJvbXB0EhsKCW1lZGlh'
    'X2lkcxgDIAMoCVIIbWVkaWFJZHMSGQoHcG9zdF9pZBgFIAEoCUgAUgZwb3N0SWQSLAoRZXZlbn'
    'RfaW5zdGFuY2VfaWQYBiABKAlIAFIPZXZlbnRJbnN0YW5jZUlkQggKBnRhcmdldA==');

@$core.Deprecated('Use aIModelProviderDescriptor instead')
const AIModelProvider$json = {
  '1': 'AIModelProvider',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'owner', '3': 2, '4': 1, '5': 11, '6': '.rellm.Author', '10': 'owner'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'gemini_credentials', '3': 4, '4': 1, '5': 11, '6': '.rellm.GeminiCredentials', '9': 0, '10': 'geminiCredentials'},
    {'1': 'openai_credentials', '3': 5, '4': 1, '5': 11, '6': '.rellm.OpenAICredentials', '9': 0, '10': 'openaiCredentials'},
    {'1': 'anthropic_credentials', '3': 6, '4': 1, '5': 11, '6': '.rellm.AnthropicCredentials', '9': 0, '10': 'anthropicCredentials'},
    {'1': 'digitalocean_credentials', '3': 7, '4': 1, '5': 11, '6': '.rellm.DigitalOceanCredentials', '9': 0, '10': 'digitaloceanCredentials'},
    {'1': 'grants', '3': 14, '4': 3, '5': 11, '6': '.rellm.AIModelProviderGrant', '10': 'grants'},
    {'1': 'created_at', '3': 15, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'createdAt'},
    {'1': 'updated_at', '3': 16, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '9': 1, '10': 'updatedAt', '17': true},
  ],
  '8': [
    {'1': 'provider'},
    {'1': '_updated_at'},
  ],
};

/// Descriptor for `AIModelProvider`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aIModelProviderDescriptor = $convert.base64Decode(
    'Cg9BSU1vZGVsUHJvdmlkZXISDgoCaWQYASABKAlSAmlkEiMKBW93bmVyGAIgASgLMg0ucmVsbG'
    '0uQXV0aG9yUgVvd25lchISCgRuYW1lGAMgASgJUgRuYW1lEkkKEmdlbWluaV9jcmVkZW50aWFs'
    'cxgEIAEoCzIYLnJlbGxtLkdlbWluaUNyZWRlbnRpYWxzSABSEWdlbWluaUNyZWRlbnRpYWxzEk'
    'kKEm9wZW5haV9jcmVkZW50aWFscxgFIAEoCzIYLnJlbGxtLk9wZW5BSUNyZWRlbnRpYWxzSABS'
    'EW9wZW5haUNyZWRlbnRpYWxzElIKFWFudGhyb3BpY19jcmVkZW50aWFscxgGIAEoCzIbLnJlbG'
    'xtLkFudGhyb3BpY0NyZWRlbnRpYWxzSABSFGFudGhyb3BpY0NyZWRlbnRpYWxzElsKGGRpZ2l0'
    'YWxvY2Vhbl9jcmVkZW50aWFscxgHIAEoCzIeLnJlbGxtLkRpZ2l0YWxPY2VhbkNyZWRlbnRpYW'
    'xzSABSF2RpZ2l0YWxvY2VhbkNyZWRlbnRpYWxzEjMKBmdyYW50cxgOIAMoCzIbLnJlbGxtLkFJ'
    'TW9kZWxQcm92aWRlckdyYW50UgZncmFudHMSOQoKY3JlYXRlZF9hdBgPIAEoCzIaLmdvb2dsZS'
    '5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI+Cgp1cGRhdGVkX2F0GBAgASgLMhouZ29v'
    'Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEgBUgl1cGRhdGVkQXSIAQFCCgoIcHJvdmlkZXJCDQoLX3'
    'VwZGF0ZWRfYXQ=');

@$core.Deprecated('Use aIModelProviderGrantDescriptor instead')
const AIModelProviderGrant$json = {
  '1': 'AIModelProviderGrant',
  '2': [
    {'1': 'ai_model_provider_id', '3': 1, '4': 1, '5': 9, '10': 'aiModelProviderId'},
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

/// Descriptor for `AIModelProviderGrant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aIModelProviderGrantDescriptor = $convert.base64Decode(
    'ChRBSU1vZGVsUHJvdmlkZXJHcmFudBIvChRhaV9tb2RlbF9wcm92aWRlcl9pZBgBIAEoCVIRYW'
    'lNb2RlbFByb3ZpZGVySWQSNwoQYWlfbW9kZWxfZ3JhbnRlZRgCIAEoCzINLnJlbGxtLkF1dGhv'
    'clIOYWlNb2RlbEdyYW50ZWUSHwoLbW9kZWxfbmFtZXMYAyADKAlSCm1vZGVsTmFtZXMSKQoQdG'
    '9rZW5zX3JlbWFpbmluZxgEIAEoBFIPdG9rZW5zUmVtYWluaW5nEhgKB292ZXJhZ2UYBSABKARS'
    'B292ZXJhZ2USOQoKY3JlYXRlZF9hdBgPIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbX'
    'BSCWNyZWF0ZWRBdBI+Cgp1cGRhdGVkX2F0GBAgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
    'dGFtcEgAUgl1cGRhdGVkQXSIAQFCDQoLX3VwZGF0ZWRfYXQ=');

@$core.Deprecated('Use getAIModelProvidersResponseDescriptor instead')
const GetAIModelProvidersResponse$json = {
  '1': 'GetAIModelProvidersResponse',
  '2': [
    {'1': 'providers', '3': 1, '4': 3, '5': 11, '6': '.rellm.AIModelProvider', '10': 'providers'},
    {'1': 'available_ai_models', '3': 2, '4': 3, '5': 11, '6': '.rellm.AvailableAIModel', '10': 'availableAiModels'},
  ],
};

/// Descriptor for `GetAIModelProvidersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAIModelProvidersResponseDescriptor = $convert.base64Decode(
    'ChtHZXRBSU1vZGVsUHJvdmlkZXJzUmVzcG9uc2USNAoJcHJvdmlkZXJzGAEgAygLMhYucmVsbG'
    '0uQUlNb2RlbFByb3ZpZGVyUglwcm92aWRlcnMSRwoTYXZhaWxhYmxlX2FpX21vZGVscxgCIAMo'
    'CzIXLnJlbGxtLkF2YWlsYWJsZUFJTW9kZWxSEWF2YWlsYWJsZUFpTW9kZWxz');

@$core.Deprecated('Use deleteAIModelProviderRequestDescriptor instead')
const DeleteAIModelProviderRequest$json = {
  '1': 'DeleteAIModelProviderRequest',
  '2': [
    {'1': 'provider', '3': 1, '4': 1, '5': 11, '6': '.rellm.AIModelProvider', '10': 'provider'},
  ],
};

/// Descriptor for `DeleteAIModelProviderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteAIModelProviderRequestDescriptor = $convert.base64Decode(
    'ChxEZWxldGVBSU1vZGVsUHJvdmlkZXJSZXF1ZXN0EjIKCHByb3ZpZGVyGAEgASgLMhYucmVsbG'
    '0uQUlNb2RlbFByb3ZpZGVyUghwcm92aWRlcg==');

@$core.Deprecated('Use grantAIModelProviderRequestDescriptor instead')
const GrantAIModelProviderRequest$json = {
  '1': 'GrantAIModelProviderRequest',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'ai_model_provider_id', '3': 2, '4': 1, '5': 9, '10': 'aiModelProviderId'},
    {'1': 'tokens', '3': 3, '4': 1, '5': 4, '10': 'tokens'},
    {'1': 'model_names', '3': 4, '4': 3, '5': 9, '10': 'modelNames'},
  ],
};

/// Descriptor for `GrantAIModelProviderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grantAIModelProviderRequestDescriptor = $convert.base64Decode(
    'ChtHcmFudEFJTW9kZWxQcm92aWRlclJlcXVlc3QSFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEi'
    '8KFGFpX21vZGVsX3Byb3ZpZGVyX2lkGAIgASgJUhFhaU1vZGVsUHJvdmlkZXJJZBIWCgZ0b2tl'
    'bnMYAyABKARSBnRva2VucxIfCgttb2RlbF9uYW1lcxgEIAMoCVIKbW9kZWxOYW1lcw==');

@$core.Deprecated('Use revokeAIModelProviderRequestDescriptor instead')
const RevokeAIModelProviderRequest$json = {
  '1': 'RevokeAIModelProviderRequest',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'ai_model_provider_id', '3': 2, '4': 1, '5': 9, '10': 'aiModelProviderId'},
  ],
};

/// Descriptor for `RevokeAIModelProviderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeAIModelProviderRequestDescriptor = $convert.base64Decode(
    'ChxSZXZva2VBSU1vZGVsUHJvdmlkZXJSZXF1ZXN0EhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZB'
    'IvChRhaV9tb2RlbF9wcm92aWRlcl9pZBgCIAEoCVIRYWlNb2RlbFByb3ZpZGVySWQ=');

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

