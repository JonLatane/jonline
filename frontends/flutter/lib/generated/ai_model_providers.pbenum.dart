//
//  Generated code. Do not modify.
//  source: ai_model_providers.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// What an [`AvailableAIModel`](#jonline-AvailableAIModel) can actually do -- drives feature gating
/// (e.g. [`GenerateMedia`](#grpc-api-GenerateMedia)'s "Generate Media…" buttons/panel only offer
/// models carrying `AI_MODEL_CAPABILITY_IMAGE_EDITING`) without the gated feature needing its own
/// hardcoded list of model names to check against. A model may carry more than one -- e.g. an
/// image-editing model can also usually do plain text-to-image generation.
class AIModelCapability extends $pb.ProtobufEnum {
  static const AIModelCapability AI_MODEL_CAPABILITY_UNKNOWN = AIModelCapability._(0, _omitEnumNames ? '' : 'AI_MODEL_CAPABILITY_UNKNOWN');
  static const AIModelCapability AI_MODEL_CAPABILITY_TEXT_GENERATION = AIModelCapability._(1, _omitEnumNames ? '' : 'AI_MODEL_CAPABILITY_TEXT_GENERATION');
  static const AIModelCapability AI_MODEL_CAPABILITY_IMAGE_GENERATION = AIModelCapability._(2, _omitEnumNames ? '' : 'AI_MODEL_CAPABILITY_IMAGE_GENERATION');
  static const AIModelCapability AI_MODEL_CAPABILITY_IMAGE_EDITING = AIModelCapability._(3, _omitEnumNames ? '' : 'AI_MODEL_CAPABILITY_IMAGE_EDITING');

  static const $core.List<AIModelCapability> values = <AIModelCapability> [
    AI_MODEL_CAPABILITY_UNKNOWN,
    AI_MODEL_CAPABILITY_TEXT_GENERATION,
    AI_MODEL_CAPABILITY_IMAGE_GENERATION,
    AI_MODEL_CAPABILITY_IMAGE_EDITING,
  ];

  static final $core.Map<$core.int, AIModelCapability> _byValue = $pb.ProtobufEnum.initByValue(values);
  static AIModelCapability? valueOf($core.int value) => _byValue[value];

  const AIModelCapability._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
