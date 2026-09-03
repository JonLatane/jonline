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
    {'1': 'capabilities', '3': 2, '4': 3, '5': 14, '6': '.jonline.AIModelCapability', '10': 'capabilities'},
    {'1': 'grant', '3': 3, '4': 1, '5': 11, '6': '.jonline.AIModelProviderGrant', '9': 0, '10': 'grant', '17': true},
    {'1': 'provider', '3': 4, '4': 1, '5': 11, '6': '.jonline.AIModelProvider', '10': 'provider'},
  ],
  '8': [
    {'1': '_grant'},
  ],
};

/// Descriptor for `AvailableAIModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List availableAIModelDescriptor = $convert.base64Decode(
    'ChBBdmFpbGFibGVBSU1vZGVsEh0KCm1vZGVsX25hbWUYASABKAlSCW1vZGVsTmFtZRI+CgxjYX'
    'BhYmlsaXRpZXMYAiADKA4yGi5qb25saW5lLkFJTW9kZWxDYXBhYmlsaXR5UgxjYXBhYmlsaXRp'
    'ZXMSOAoFZ3JhbnQYAyABKAsyHS5qb25saW5lLkFJTW9kZWxQcm92aWRlckdyYW50SABSBWdyYW'
    '50iAEBEjQKCHByb3ZpZGVyGAQgASgLMhguam9ubGluZS5BSU1vZGVsUHJvdmlkZXJSCHByb3Zp'
    'ZGVyQggKBl9ncmFudA==');

@$core.Deprecated('Use generateMediaRequestDescriptor instead')
const GenerateMediaRequest$json = {
  '1': 'GenerateMediaRequest',
  '2': [
    {'1': 'model', '3': 1, '4': 1, '5': 11, '6': '.jonline.AvailableAIModel', '10': 'model'},
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
    'ChRHZW5lcmF0ZU1lZGlhUmVxdWVzdBIvCgVtb2RlbBgBIAEoCzIZLmpvbmxpbmUuQXZhaWxhYm'
    'xlQUlNb2RlbFIFbW9kZWwSHwoLdXNlcl9wcm9tcHQYAiABKAlSCnVzZXJQcm9tcHQSGwoJbWVk'
    'aWFfaWRzGAMgAygJUghtZWRpYUlkcxIZCgdwb3N0X2lkGAUgASgJSABSBnBvc3RJZBIsChFldm'
    'VudF9pbnN0YW5jZV9pZBgGIAEoCUgAUg9ldmVudEluc3RhbmNlSWRCCAoGdGFyZ2V0');

@$core.Deprecated('Use aIModelProviderDescriptor instead')
const AIModelProvider$json = {
  '1': 'AIModelProvider',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'owner', '3': 2, '4': 1, '5': 11, '6': '.jonline.Author', '10': 'owner'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'gemini_credentials', '3': 4, '4': 1, '5': 11, '6': '.jonline.GeminiCredentials', '9': 0, '10': 'geminiCredentials'},
    {'1': 'openai_credentials', '3': 5, '4': 1, '5': 11, '6': '.jonline.OpenAICredentials', '9': 0, '10': 'openaiCredentials'},
    {'1': 'anthropic_credentials', '3': 6, '4': 1, '5': 11, '6': '.jonline.AnthropicCredentials', '9': 0, '10': 'anthropicCredentials'},
    {'1': 'digitalocean_credentials', '3': 7, '4': 1, '5': 11, '6': '.jonline.DigitalOceanCredentials', '9': 0, '10': 'digitaloceanCredentials'},
    {'1': 'grants', '3': 14, '4': 3, '5': 11, '6': '.jonline.AIModelProviderGrant', '10': 'grants'},
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
    'Cg9BSU1vZGVsUHJvdmlkZXISDgoCaWQYASABKAlSAmlkEiUKBW93bmVyGAIgASgLMg8uam9ubG'
    'luZS5BdXRob3JSBW93bmVyEhIKBG5hbWUYAyABKAlSBG5hbWUSSwoSZ2VtaW5pX2NyZWRlbnRp'
    'YWxzGAQgASgLMhouam9ubGluZS5HZW1pbmlDcmVkZW50aWFsc0gAUhFnZW1pbmlDcmVkZW50aW'
    'FscxJLChJvcGVuYWlfY3JlZGVudGlhbHMYBSABKAsyGi5qb25saW5lLk9wZW5BSUNyZWRlbnRp'
    'YWxzSABSEW9wZW5haUNyZWRlbnRpYWxzElQKFWFudGhyb3BpY19jcmVkZW50aWFscxgGIAEoCz'
    'IdLmpvbmxpbmUuQW50aHJvcGljQ3JlZGVudGlhbHNIAFIUYW50aHJvcGljQ3JlZGVudGlhbHMS'
    'XQoYZGlnaXRhbG9jZWFuX2NyZWRlbnRpYWxzGAcgASgLMiAuam9ubGluZS5EaWdpdGFsT2NlYW'
    '5DcmVkZW50aWFsc0gAUhdkaWdpdGFsb2NlYW5DcmVkZW50aWFscxI1CgZncmFudHMYDiADKAsy'
    'HS5qb25saW5lLkFJTW9kZWxQcm92aWRlckdyYW50UgZncmFudHMSOQoKY3JlYXRlZF9hdBgPIA'
    'EoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI+Cgp1cGRhdGVkX2F0'
    'GBAgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEgBUgl1cGRhdGVkQXSIAQFCCgoIcH'
    'JvdmlkZXJCDQoLX3VwZGF0ZWRfYXQ=');

@$core.Deprecated('Use aIModelProviderGrantDescriptor instead')
const AIModelProviderGrant$json = {
  '1': 'AIModelProviderGrant',
  '2': [
    {'1': 'ai_model_provider_id', '3': 1, '4': 1, '5': 9, '10': 'aiModelProviderId'},
    {'1': 'ai_model_grantee', '3': 2, '4': 1, '5': 11, '6': '.jonline.Author', '10': 'aiModelGrantee'},
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
    'lNb2RlbFByb3ZpZGVySWQSOQoQYWlfbW9kZWxfZ3JhbnRlZRgCIAEoCzIPLmpvbmxpbmUuQXV0'
    'aG9yUg5haU1vZGVsR3JhbnRlZRIfCgttb2RlbF9uYW1lcxgDIAMoCVIKbW9kZWxOYW1lcxIpCh'
    'B0b2tlbnNfcmVtYWluaW5nGAQgASgEUg90b2tlbnNSZW1haW5pbmcSGAoHb3ZlcmFnZRgFIAEo'
    'BFIHb3ZlcmFnZRI5CgpjcmVhdGVkX2F0GA8gASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdG'
    'FtcFIJY3JlYXRlZEF0Ej4KCnVwZGF0ZWRfYXQYECABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt'
    'ZXN0YW1wSABSCXVwZGF0ZWRBdIgBAUINCgtfdXBkYXRlZF9hdA==');

@$core.Deprecated('Use getAIModelProvidersResponseDescriptor instead')
const GetAIModelProvidersResponse$json = {
  '1': 'GetAIModelProvidersResponse',
  '2': [
    {'1': 'providers', '3': 1, '4': 3, '5': 11, '6': '.jonline.AIModelProvider', '10': 'providers'},
    {'1': 'available_ai_models', '3': 2, '4': 3, '5': 11, '6': '.jonline.AvailableAIModel', '10': 'availableAiModels'},
  ],
};

/// Descriptor for `GetAIModelProvidersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAIModelProvidersResponseDescriptor = $convert.base64Decode(
    'ChtHZXRBSU1vZGVsUHJvdmlkZXJzUmVzcG9uc2USNgoJcHJvdmlkZXJzGAEgAygLMhguam9ubG'
    'luZS5BSU1vZGVsUHJvdmlkZXJSCXByb3ZpZGVycxJJChNhdmFpbGFibGVfYWlfbW9kZWxzGAIg'
    'AygLMhkuam9ubGluZS5BdmFpbGFibGVBSU1vZGVsUhFhdmFpbGFibGVBaU1vZGVscw==');

@$core.Deprecated('Use deleteAIModelProviderRequestDescriptor instead')
const DeleteAIModelProviderRequest$json = {
  '1': 'DeleteAIModelProviderRequest',
  '2': [
    {'1': 'provider', '3': 1, '4': 1, '5': 11, '6': '.jonline.AIModelProvider', '10': 'provider'},
  ],
};

/// Descriptor for `DeleteAIModelProviderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteAIModelProviderRequestDescriptor = $convert.base64Decode(
    'ChxEZWxldGVBSU1vZGVsUHJvdmlkZXJSZXF1ZXN0EjQKCHByb3ZpZGVyGAEgASgLMhguam9ubG'
    'luZS5BSU1vZGVsUHJvdmlkZXJSCHByb3ZpZGVy');

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

