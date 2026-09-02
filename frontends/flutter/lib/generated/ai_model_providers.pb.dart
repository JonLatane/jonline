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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'authors.pb.dart' as $15;
import 'google/protobuf/timestamp.pb.dart' as $12;

/// One specific model a user may call right now, and how -- via an [`AIModelProvider`](#jonline-AIModelProvider)
/// they own outright (`grant` unset), or via an [`AIModelProviderGrant`](#jonline-AIModelProviderGrant) someone else
/// granted them (`grant` set). Only ever defined relative to a user -- see
/// [`User.available_ai_models`](#jonline-User)/[`GetAIModelProvidersResponse.available_ai_models`](#jonline-GetAIModelProvidersResponse).
/// One `AvailableAIModel` exists per (provider, model) pair: an owner gets one row per model their
/// provider supports (see the server's own model catalog per provider type); a grantee gets one row
/// per model their grant actually covers -- expanded from `AIModelProviderGrant.model_names`, or
/// every model the provider supports if that list is empty.
class AvailableAIModel extends $pb.GeneratedMessage {
  factory AvailableAIModel({
    $core.String? modelName,
    AIModelProviderGrant? grant,
    AIModelProvider? provider,
  }) {
    final $result = create();
    if (modelName != null) {
      $result.modelName = modelName;
    }
    if (grant != null) {
      $result.grant = grant;
    }
    if (provider != null) {
      $result.provider = provider;
    }
    return $result;
  }
  AvailableAIModel._() : super();
  factory AvailableAIModel.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AvailableAIModel.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AvailableAIModel', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelName')
    ..aOM<AIModelProviderGrant>(2, _omitFieldNames ? '' : 'grant', subBuilder: AIModelProviderGrant.create)
    ..aOM<AIModelProvider>(3, _omitFieldNames ? '' : 'provider', subBuilder: AIModelProvider.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AvailableAIModel clone() => AvailableAIModel()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AvailableAIModel copyWith(void Function(AvailableAIModel) updates) => super.copyWith((message) => updates(message as AvailableAIModel)) as AvailableAIModel;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AvailableAIModel create() => AvailableAIModel._();
  AvailableAIModel createEmptyInstance() => create();
  static $pb.PbList<AvailableAIModel> createRepeated() => $pb.PbList<AvailableAIModel>();
  @$core.pragma('dart2js:noInline')
  static AvailableAIModel getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AvailableAIModel>(create);
  static AvailableAIModel? _defaultInstance;

  /// The exact model name to use when calling the provider (e.g. `"gemini-3.1-flash-image"`).
  @$pb.TagNumber(1)
  $core.String get modelName => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelName($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasModelName() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelName() => clearField(1);

  /// The grant that allows this access, when the current user isn't `provider.owner` themselves.
  /// Unset when the current user owns `provider` outright (full, ungated access -- no grant needed).
  @$pb.TagNumber(2)
  AIModelProviderGrant get grant => $_getN(1);
  @$pb.TagNumber(2)
  set grant(AIModelProviderGrant v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGrant() => $_has(1);
  @$pb.TagNumber(2)
  void clearGrant() => clearField(2);
  @$pb.TagNumber(2)
  AIModelProviderGrant ensureGrant() => $_ensure(1);

  /// The provider this model belongs to. Its own `grants` list is only populated when the current
  /// user is `provider.owner` (or an Admin) -- see [`GetAIModelProviders`](#grpc-api-GetAIModelProviders)'s own doc; a
  /// mere grantee never sees who else has been granted access to a provider they don't own.
  @$pb.TagNumber(3)
  AIModelProvider get provider => $_getN(2);
  @$pb.TagNumber(3)
  set provider(AIModelProvider v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasProvider() => $_has(2);
  @$pb.TagNumber(3)
  void clearProvider() => clearField(3);
  @$pb.TagNumber(3)
  AIModelProvider ensureProvider() => $_ensure(2);
}

enum AIModelProvider_Provider {
  geminiCredentials, 
  openaiCredentials, 
  anthropicCredentials, 
  notSet
}

///  An AIModelProvider is a user-owned connection to an external AI model API (e.g. a Gemini API
///  key), which its owner can grant other users of this server metered, budgeted access to. Mirrors
///  [`SyncDestination`](#jonline-SyncDestination)/[`EventSyncSource`](#jonline-EventSyncSource) (also user-owned integrations
///  with an [`Author`](#jonline-Author) `owner` and a `oneof` naming which external system is configured), but where
///  those push/pull content, an AIModelProvider is metered *access* to a third-party LLM API -- shared out to
///  other users via [`AIModelProviderGrant`](#jonline-AIModelProviderGrant)s rather than posted-to/subscribed-from.
///
///  Providers are managed via [`GetAIModelProviders`](#grpc-api-GetAIModelProviders),
///  [`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider) (requires `CREATE_AI_MODEL_PROVIDERS`, or Admin),
///  [`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider) (owner, or Admin for any user's), and
///  [`DeleteAIModelProvider`](#grpc-api-DeleteAIModelProvider) (owner, or Admin) -- the same self-or-Admin shape as
///  [`SyncDestination`](#jonline-SyncDestination)'s RPCs. Access to a provider is granted/revoked to other users via
///  [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider)/[`RevokeAIModelProvider`](#grpc-api-RevokeAIModelProvider) which,
///  unlike every other RPC pair here, are **owner-only with no Admin override**: an Admin can manage the provider
///  record itself (rename it, rotate its key, delete it), but handing out access to *someone else's* API budget is a
///  call only its owner should be able to make.
///
///  Currently only the [`GeminiCredentials`](#jonline-GeminiCredentials) variant has a working connection flow;
///  [`OpenAICredentials`](#jonline-OpenAICredentials)/[`AnthropicCredentials`](#jonline-AnthropicCredentials) are defined for
///  forward compatibility but are not yet accepted by [`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider).
class AIModelProvider extends $pb.GeneratedMessage {
  factory AIModelProvider({
    $core.String? id,
    $15.Author? owner,
    $core.String? name,
    GeminiCredentials? geminiCredentials,
    OpenAICredentials? openaiCredentials,
    AnthropicCredentials? anthropicCredentials,
    $core.Iterable<AIModelProviderGrant>? grants,
    $12.Timestamp? createdAt,
    $12.Timestamp? updatedAt,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (owner != null) {
      $result.owner = owner;
    }
    if (name != null) {
      $result.name = name;
    }
    if (geminiCredentials != null) {
      $result.geminiCredentials = geminiCredentials;
    }
    if (openaiCredentials != null) {
      $result.openaiCredentials = openaiCredentials;
    }
    if (anthropicCredentials != null) {
      $result.anthropicCredentials = anthropicCredentials;
    }
    if (grants != null) {
      $result.grants.addAll(grants);
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      $result.updatedAt = updatedAt;
    }
    return $result;
  }
  AIModelProvider._() : super();
  factory AIModelProvider.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AIModelProvider.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, AIModelProvider_Provider> _AIModelProvider_ProviderByTag = {
    4 : AIModelProvider_Provider.geminiCredentials,
    5 : AIModelProvider_Provider.openaiCredentials,
    6 : AIModelProvider_Provider.anthropicCredentials,
    0 : AIModelProvider_Provider.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AIModelProvider', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..oo(0, [4, 5, 6])
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<$15.Author>(2, _omitFieldNames ? '' : 'owner', subBuilder: $15.Author.create)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOM<GeminiCredentials>(4, _omitFieldNames ? '' : 'geminiCredentials', subBuilder: GeminiCredentials.create)
    ..aOM<OpenAICredentials>(5, _omitFieldNames ? '' : 'openaiCredentials', subBuilder: OpenAICredentials.create)
    ..aOM<AnthropicCredentials>(6, _omitFieldNames ? '' : 'anthropicCredentials', subBuilder: AnthropicCredentials.create)
    ..pc<AIModelProviderGrant>(14, _omitFieldNames ? '' : 'grants', $pb.PbFieldType.PM, subBuilder: AIModelProviderGrant.create)
    ..aOM<$12.Timestamp>(15, _omitFieldNames ? '' : 'createdAt', subBuilder: $12.Timestamp.create)
    ..aOM<$12.Timestamp>(16, _omitFieldNames ? '' : 'updatedAt', subBuilder: $12.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AIModelProvider clone() => AIModelProvider()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AIModelProvider copyWith(void Function(AIModelProvider) updates) => super.copyWith((message) => updates(message as AIModelProvider)) as AIModelProvider;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AIModelProvider create() => AIModelProvider._();
  AIModelProvider createEmptyInstance() => create();
  static $pb.PbList<AIModelProvider> createRepeated() => $pb.PbList<AIModelProvider>();
  @$core.pragma('dart2js:noInline')
  static AIModelProvider getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AIModelProvider>(create);
  static AIModelProvider? _defaultInstance;

  AIModelProvider_Provider whichProvider() => _AIModelProvider_ProviderByTag[$_whichOneof(0)]!;
  void clearProvider() => clearField($_whichOneof(0));

  /// Unique ID for the AIModelProvider.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// The user information for the owner of this AIModelProvider -- the only user (besides Admins) who may
  /// rename it or change its credentials/provider, and the *only* user (not even Admins) who may grant/revoke other
  /// users' access to it.
  @$pb.TagNumber(2)
  $15.Author get owner => $_getN(1);
  @$pb.TagNumber(2)
  set owner($15.Author v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasOwner() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwner() => clearField(2);
  @$pb.TagNumber(2)
  $15.Author ensureOwner() => $_ensure(1);

  /// A display name for the provider, chosen by its owner (e.g. "My Gemini Key", "Team OpenAI Account"). Purely
  /// cosmetic -- has no effect on behavior.
  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  /// A Google Gemini API connection (see `ai.google.dev/gemini-api` -- planned use is its image generation
  /// endpoint, for generating Event posters). The only variant currently creatable.
  @$pb.TagNumber(4)
  GeminiCredentials get geminiCredentials => $_getN(3);
  @$pb.TagNumber(4)
  set geminiCredentials(GeminiCredentials v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasGeminiCredentials() => $_has(3);
  @$pb.TagNumber(4)
  void clearGeminiCredentials() => clearField(4);
  @$pb.TagNumber(4)
  GeminiCredentials ensureGeminiCredentials() => $_ensure(3);

  /// An OpenAI API connection. *Not yet creatable.*
  @$pb.TagNumber(5)
  OpenAICredentials get openaiCredentials => $_getN(4);
  @$pb.TagNumber(5)
  set openaiCredentials(OpenAICredentials v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasOpenaiCredentials() => $_has(4);
  @$pb.TagNumber(5)
  void clearOpenaiCredentials() => clearField(5);
  @$pb.TagNumber(5)
  OpenAICredentials ensureOpenaiCredentials() => $_ensure(4);

  /// An Anthropic API connection. *Not yet creatable.*
  @$pb.TagNumber(6)
  AnthropicCredentials get anthropicCredentials => $_getN(5);
  @$pb.TagNumber(6)
  set anthropicCredentials(AnthropicCredentials v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasAnthropicCredentials() => $_has(5);
  @$pb.TagNumber(6)
  void clearAnthropicCredentials() => clearField(6);
  @$pb.TagNumber(6)
  AnthropicCredentials ensureAnthropicCredentials() => $_ensure(5);

  /// Other users this provider's owner has granted metered access to, via
  /// [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider). Only ever populated for the owner (or an Admin) --
  /// see [`GetAIModelProviders`](#grpc-api-GetAIModelProviders).
  @$pb.TagNumber(14)
  $core.List<AIModelProviderGrant> get grants => $_getList(6);

  /// The time the provider was created.
  @$pb.TagNumber(15)
  $12.Timestamp get createdAt => $_getN(7);
  @$pb.TagNumber(15)
  set createdAt($12.Timestamp v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasCreatedAt() => $_has(7);
  @$pb.TagNumber(15)
  void clearCreatedAt() => clearField(15);
  @$pb.TagNumber(15)
  $12.Timestamp ensureCreatedAt() => $_ensure(7);

  /// The time the provider was last updated (renamed, or had its provider/credentials changed).
  @$pb.TagNumber(16)
  $12.Timestamp get updatedAt => $_getN(8);
  @$pb.TagNumber(16)
  set updatedAt($12.Timestamp v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasUpdatedAt() => $_has(8);
  @$pb.TagNumber(16)
  void clearUpdatedAt() => clearField(16);
  @$pb.TagNumber(16)
  $12.Timestamp ensureUpdatedAt() => $_ensure(8);
}

/// A grant of metered access to someone else's [`AIModelProvider`](#jonline-AIModelProvider), created/reset via
/// [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider) and removed via
/// [`RevokeAIModelProvider`](#grpc-api-RevokeAIModelProvider). Upserted on the unique
/// `(ai_model_provider_id, ai_model_grantee)` pair -- calling [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider)
/// again for a user who already has a grant *resets* `tokens_remaining` to the newly-requested amount, it does not
/// add to it.
class AIModelProviderGrant extends $pb.GeneratedMessage {
  factory AIModelProviderGrant({
    $core.String? aiModelProviderId,
    $15.Author? aiModelGrantee,
    $core.Iterable<$core.String>? modelNames,
    $fixnum.Int64? tokensRemaining,
    $12.Timestamp? createdAt,
    $12.Timestamp? updatedAt,
  }) {
    final $result = create();
    if (aiModelProviderId != null) {
      $result.aiModelProviderId = aiModelProviderId;
    }
    if (aiModelGrantee != null) {
      $result.aiModelGrantee = aiModelGrantee;
    }
    if (modelNames != null) {
      $result.modelNames.addAll(modelNames);
    }
    if (tokensRemaining != null) {
      $result.tokensRemaining = tokensRemaining;
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      $result.updatedAt = updatedAt;
    }
    return $result;
  }
  AIModelProviderGrant._() : super();
  factory AIModelProviderGrant.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AIModelProviderGrant.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AIModelProviderGrant', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'aiModelProviderId')
    ..aOM<$15.Author>(2, _omitFieldNames ? '' : 'aiModelGrantee', subBuilder: $15.Author.create)
    ..pPS(3, _omitFieldNames ? '' : 'modelNames')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'tokensRemaining', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$12.Timestamp>(15, _omitFieldNames ? '' : 'createdAt', subBuilder: $12.Timestamp.create)
    ..aOM<$12.Timestamp>(16, _omitFieldNames ? '' : 'updatedAt', subBuilder: $12.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AIModelProviderGrant clone() => AIModelProviderGrant()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AIModelProviderGrant copyWith(void Function(AIModelProviderGrant) updates) => super.copyWith((message) => updates(message as AIModelProviderGrant)) as AIModelProviderGrant;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AIModelProviderGrant create() => AIModelProviderGrant._();
  AIModelProviderGrant createEmptyInstance() => create();
  static $pb.PbList<AIModelProviderGrant> createRepeated() => $pb.PbList<AIModelProviderGrant>();
  @$core.pragma('dart2js:noInline')
  static AIModelProviderGrant getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AIModelProviderGrant>(create);
  static AIModelProviderGrant? _defaultInstance;

  /// The ID of the [`AIModelProvider`](#jonline-AIModelProvider) this grant is for.
  @$pb.TagNumber(1)
  $core.String get aiModelProviderId => $_getSZ(0);
  @$pb.TagNumber(1)
  set aiModelProviderId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAiModelProviderId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAiModelProviderId() => clearField(1);

  /// The user this access was granted to.
  @$pb.TagNumber(2)
  $15.Author get aiModelGrantee => $_getN(1);
  @$pb.TagNumber(2)
  set aiModelGrantee($15.Author v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasAiModelGrantee() => $_has(1);
  @$pb.TagNumber(2)
  void clearAiModelGrantee() => clearField(2);
  @$pb.TagNumber(2)
  $15.Author ensureAiModelGrantee() => $_ensure(1);

  /// The model name (that will be used to call the provider) that the grantee is allowed to use by this grant.
  /// If blank, allows access to any models the provider supports. If non-blank, the grantee is only allowed to use the model(s) specified here.
  /// Allows granters to set per-model (or per-model-group) token budgets, e.g. "gpt-4" vs "gpt-3.5-turbo".
  @$pb.TagNumber(3)
  $core.List<$core.String> get modelNames => $_getList(2);

  /// The number of tokens the grantee may still spend against this provider. Set (and reset) by the owner via
  /// [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider).
  @$pb.TagNumber(4)
  $fixnum.Int64 get tokensRemaining => $_getI64(3);
  @$pb.TagNumber(4)
  set tokensRemaining($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTokensRemaining() => $_has(3);
  @$pb.TagNumber(4)
  void clearTokensRemaining() => clearField(4);

  /// The time the grant was first created.
  @$pb.TagNumber(15)
  $12.Timestamp get createdAt => $_getN(4);
  @$pb.TagNumber(15)
  set createdAt($12.Timestamp v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasCreatedAt() => $_has(4);
  @$pb.TagNumber(15)
  void clearCreatedAt() => clearField(15);
  @$pb.TagNumber(15)
  $12.Timestamp ensureCreatedAt() => $_ensure(4);

  /// The time the grant was last updated (i.e. last reset by another
  /// [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider) call).
  @$pb.TagNumber(16)
  $12.Timestamp get updatedAt => $_getN(5);
  @$pb.TagNumber(16)
  set updatedAt($12.Timestamp v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasUpdatedAt() => $_has(5);
  @$pb.TagNumber(16)
  void clearUpdatedAt() => clearField(16);
  @$pb.TagNumber(16)
  $12.Timestamp ensureUpdatedAt() => $_ensure(5);
}

/// Response to a request for a user's [`AIModelProvider`](#jonline-AIModelProvider)s.
class GetAIModelProvidersResponse extends $pb.GeneratedMessage {
  factory GetAIModelProvidersResponse({
    $core.Iterable<AIModelProvider>? providers,
    $core.Iterable<AvailableAIModel>? availableAiModels,
  }) {
    final $result = create();
    if (providers != null) {
      $result.providers.addAll(providers);
    }
    if (availableAiModels != null) {
      $result.availableAiModels.addAll(availableAiModels);
    }
    return $result;
  }
  GetAIModelProvidersResponse._() : super();
  factory GetAIModelProvidersResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetAIModelProvidersResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetAIModelProvidersResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<AIModelProvider>(1, _omitFieldNames ? '' : 'providers', $pb.PbFieldType.PM, subBuilder: AIModelProvider.create)
    ..pc<AvailableAIModel>(2, _omitFieldNames ? '' : 'availableAiModels', $pb.PbFieldType.PM, subBuilder: AvailableAIModel.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetAIModelProvidersResponse clone() => GetAIModelProvidersResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetAIModelProvidersResponse copyWith(void Function(GetAIModelProvidersResponse) updates) => super.copyWith((message) => updates(message as GetAIModelProvidersResponse)) as GetAIModelProvidersResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAIModelProvidersResponse create() => GetAIModelProvidersResponse._();
  GetAIModelProvidersResponse createEmptyInstance() => create();
  static $pb.PbList<GetAIModelProvidersResponse> createRepeated() => $pb.PbList<GetAIModelProvidersResponse>();
  @$core.pragma('dart2js:noInline')
  static GetAIModelProvidersResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAIModelProvidersResponse>(create);
  static GetAIModelProvidersResponse? _defaultInstance;

  /// The requested user's own AIModelProviders (those they own) -- exactly the distinct `provider`s
  /// in `available_ai_models` whose `owner` is the requested user, each with its own `grants`
  /// populated (who else can use it). A convenience duplicate of data already in
  /// `available_ai_models`, so callers managing a user's own providers (rename/rekey/delete/grant/
  /// revoke) don't have to de-duplicate that list themselves.
  @$pb.TagNumber(1)
  $core.List<AIModelProvider> get providers => $_getList(0);

  /// Every model the requested user may currently call -- their own providers' models, plus any
  /// models granted to them on other users' providers. See [`AvailableAIModel`](#jonline-AvailableAIModel)'s own doc.
  @$pb.TagNumber(2)
  $core.List<AvailableAIModel> get availableAiModels => $_getList(1);
}

/// Request to delete an AIModelProvider. Also deletes any of its [`AIModelProviderGrant`](#jonline-AIModelProviderGrant)s.
class DeleteAIModelProviderRequest extends $pb.GeneratedMessage {
  factory DeleteAIModelProviderRequest({
    AIModelProvider? provider,
  }) {
    final $result = create();
    if (provider != null) {
      $result.provider = provider;
    }
    return $result;
  }
  DeleteAIModelProviderRequest._() : super();
  factory DeleteAIModelProviderRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteAIModelProviderRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteAIModelProviderRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<AIModelProvider>(1, _omitFieldNames ? '' : 'provider', subBuilder: AIModelProvider.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteAIModelProviderRequest clone() => DeleteAIModelProviderRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteAIModelProviderRequest copyWith(void Function(DeleteAIModelProviderRequest) updates) => super.copyWith((message) => updates(message as DeleteAIModelProviderRequest)) as DeleteAIModelProviderRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteAIModelProviderRequest create() => DeleteAIModelProviderRequest._();
  DeleteAIModelProviderRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteAIModelProviderRequest> createRepeated() => $pb.PbList<DeleteAIModelProviderRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteAIModelProviderRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteAIModelProviderRequest>(create);
  static DeleteAIModelProviderRequest? _defaultInstance;

  /// The provider to be deleted.
  @$pb.TagNumber(1)
  AIModelProvider get provider => $_getN(0);
  @$pb.TagNumber(1)
  set provider(AIModelProvider v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => clearField(1);
  @$pb.TagNumber(1)
  AIModelProvider ensureProvider() => $_ensure(0);
}

/// Request to grant (or reset) another user's metered access to one of the current user's
/// [`AIModelProvider`](#jonline-AIModelProvider)s. *Authenticated, owner-only -- no Admin override.*
class GrantAIModelProviderRequest extends $pb.GeneratedMessage {
  factory GrantAIModelProviderRequest({
    $core.String? userId,
    $core.String? aiModelProviderId,
    $fixnum.Int64? tokens,
    $core.Iterable<$core.String>? modelNames,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (aiModelProviderId != null) {
      $result.aiModelProviderId = aiModelProviderId;
    }
    if (tokens != null) {
      $result.tokens = tokens;
    }
    if (modelNames != null) {
      $result.modelNames.addAll(modelNames);
    }
    return $result;
  }
  GrantAIModelProviderRequest._() : super();
  factory GrantAIModelProviderRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GrantAIModelProviderRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GrantAIModelProviderRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'aiModelProviderId')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'tokens', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPS(4, _omitFieldNames ? '' : 'modelNames')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GrantAIModelProviderRequest clone() => GrantAIModelProviderRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GrantAIModelProviderRequest copyWith(void Function(GrantAIModelProviderRequest) updates) => super.copyWith((message) => updates(message as GrantAIModelProviderRequest)) as GrantAIModelProviderRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrantAIModelProviderRequest create() => GrantAIModelProviderRequest._();
  GrantAIModelProviderRequest createEmptyInstance() => create();
  static $pb.PbList<GrantAIModelProviderRequest> createRepeated() => $pb.PbList<GrantAIModelProviderRequest>();
  @$core.pragma('dart2js:noInline')
  static GrantAIModelProviderRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GrantAIModelProviderRequest>(create);
  static GrantAIModelProviderRequest? _defaultInstance;

  /// The user to grant access to.
  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  /// The AIModelProvider to grant access to. Must be owned by the caller.
  @$pb.TagNumber(2)
  $core.String get aiModelProviderId => $_getSZ(1);
  @$pb.TagNumber(2)
  set aiModelProviderId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAiModelProviderId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAiModelProviderId() => clearField(2);

  /// The number of tokens the grantee may spend. Calling this RPC again for the same
  /// (`ai_model_provider_id`, `user_id`) pair *replaces*, rather than adds to, this value.
  @$pb.TagNumber(3)
  $fixnum.Int64 get tokens => $_getI64(2);
  @$pb.TagNumber(3)
  set tokens($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTokens() => $_has(2);
  @$pb.TagNumber(3)
  void clearTokens() => clearField(3);

  /// The models the grantee is allowed to use, mirroring [`AIModelProviderGrant.model_names`](#jonline-AIModelProviderGrant)
  /// -- if empty, allows access to any model the provider supports. Also replaced (not merged)
  /// on a repeat call, same as `tokens`.
  @$pb.TagNumber(4)
  $core.List<$core.String> get modelNames => $_getList(3);
}

/// Request to revoke another user's access to one of the current user's
/// [`AIModelProvider`](#jonline-AIModelProvider)s, the reverse of
/// [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider). *Authenticated, owner-only -- no Admin override.*
class RevokeAIModelProviderRequest extends $pb.GeneratedMessage {
  factory RevokeAIModelProviderRequest({
    $core.String? userId,
    $core.String? aiModelProviderId,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (aiModelProviderId != null) {
      $result.aiModelProviderId = aiModelProviderId;
    }
    return $result;
  }
  RevokeAIModelProviderRequest._() : super();
  factory RevokeAIModelProviderRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RevokeAIModelProviderRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RevokeAIModelProviderRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'aiModelProviderId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RevokeAIModelProviderRequest clone() => RevokeAIModelProviderRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RevokeAIModelProviderRequest copyWith(void Function(RevokeAIModelProviderRequest) updates) => super.copyWith((message) => updates(message as RevokeAIModelProviderRequest)) as RevokeAIModelProviderRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RevokeAIModelProviderRequest create() => RevokeAIModelProviderRequest._();
  RevokeAIModelProviderRequest createEmptyInstance() => create();
  static $pb.PbList<RevokeAIModelProviderRequest> createRepeated() => $pb.PbList<RevokeAIModelProviderRequest>();
  @$core.pragma('dart2js:noInline')
  static RevokeAIModelProviderRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RevokeAIModelProviderRequest>(create);
  static RevokeAIModelProviderRequest? _defaultInstance;

  /// The user whose access should be revoked.
  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  /// The AIModelProvider to revoke access to. Must be owned by the caller.
  @$pb.TagNumber(2)
  $core.String get aiModelProviderId => $_getSZ(1);
  @$pb.TagNumber(2)
  set aiModelProviderId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAiModelProviderId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAiModelProviderId() => clearField(2);
}

/// Credentials for a Google Gemini API connection (`ai.google.dev/gemini-api`) -- the only
/// [`AIModelProvider.provider`](#jonline-AIModelProvider) variant currently accepted by
/// [`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider)/[`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider).
/// Planned use is the Gemini image generation/editing endpoint (`ai.google.dev/gemini-api/docs/image-generation`),
/// to generate/edit Event posters from an Event's own content.
class GeminiCredentials extends $pb.GeneratedMessage {
  factory GeminiCredentials({
    $core.String? geminiApiKey,
  }) {
    final $result = create();
    if (geminiApiKey != null) {
      $result.geminiApiKey = geminiApiKey;
    }
    return $result;
  }
  GeminiCredentials._() : super();
  factory GeminiCredentials.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GeminiCredentials.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GeminiCredentials', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'geminiApiKey')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GeminiCredentials clone() => GeminiCredentials()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GeminiCredentials copyWith(void Function(GeminiCredentials) updates) => super.copyWith((message) => updates(message as GeminiCredentials)) as GeminiCredentials;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GeminiCredentials create() => GeminiCredentials._();
  GeminiCredentials createEmptyInstance() => create();
  static $pb.PbList<GeminiCredentials> createRepeated() => $pb.PbList<GeminiCredentials>();
  @$core.pragma('dart2js:noInline')
  static GeminiCredentials getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GeminiCredentials>(create);
  static GeminiCredentials? _defaultInstance;

  /// The Gemini API key. Required (and only used) on
  /// [`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider)/[`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider) --
  /// **never populated in responses**, the same write-only convention as e.g.
  /// [`MastodonAccount.access_token`](#jonline-MastodonAccount) in `sync.proto`.
  @$pb.TagNumber(1)
  $core.String get geminiApiKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set geminiApiKey($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGeminiApiKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearGeminiApiKey() => clearField(1);
}

/// Credentials for an OpenAI API connection. *Not yet creatable* -- defined for forward compatibility only.
class OpenAICredentials extends $pb.GeneratedMessage {
  factory OpenAICredentials({
    $core.String? openaiApiKey,
  }) {
    final $result = create();
    if (openaiApiKey != null) {
      $result.openaiApiKey = openaiApiKey;
    }
    return $result;
  }
  OpenAICredentials._() : super();
  factory OpenAICredentials.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OpenAICredentials.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'OpenAICredentials', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'openaiApiKey')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OpenAICredentials clone() => OpenAICredentials()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OpenAICredentials copyWith(void Function(OpenAICredentials) updates) => super.copyWith((message) => updates(message as OpenAICredentials)) as OpenAICredentials;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenAICredentials create() => OpenAICredentials._();
  OpenAICredentials createEmptyInstance() => create();
  static $pb.PbList<OpenAICredentials> createRepeated() => $pb.PbList<OpenAICredentials>();
  @$core.pragma('dart2js:noInline')
  static OpenAICredentials getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OpenAICredentials>(create);
  static OpenAICredentials? _defaultInstance;

  /// The OpenAI API key. Never populated in responses (see
  /// [`GeminiCredentials.gemini_api_key`](#jonline-GeminiCredentials)).
  @$pb.TagNumber(1)
  $core.String get openaiApiKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set openaiApiKey($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOpenaiApiKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearOpenaiApiKey() => clearField(1);
}

/// Credentials for an Anthropic API connection. *Not yet creatable* -- defined for forward compatibility only.
class AnthropicCredentials extends $pb.GeneratedMessage {
  factory AnthropicCredentials({
    $core.String? anthropicApiKey,
  }) {
    final $result = create();
    if (anthropicApiKey != null) {
      $result.anthropicApiKey = anthropicApiKey;
    }
    return $result;
  }
  AnthropicCredentials._() : super();
  factory AnthropicCredentials.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AnthropicCredentials.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AnthropicCredentials', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'anthropicApiKey')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AnthropicCredentials clone() => AnthropicCredentials()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AnthropicCredentials copyWith(void Function(AnthropicCredentials) updates) => super.copyWith((message) => updates(message as AnthropicCredentials)) as AnthropicCredentials;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AnthropicCredentials create() => AnthropicCredentials._();
  AnthropicCredentials createEmptyInstance() => create();
  static $pb.PbList<AnthropicCredentials> createRepeated() => $pb.PbList<AnthropicCredentials>();
  @$core.pragma('dart2js:noInline')
  static AnthropicCredentials getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AnthropicCredentials>(create);
  static AnthropicCredentials? _defaultInstance;

  /// The Anthropic API key. Never populated in responses (see
  /// [`GeminiCredentials.gemini_api_key`](#jonline-GeminiCredentials)).
  @$pb.TagNumber(1)
  $core.String get anthropicApiKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set anthropicApiKey($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAnthropicApiKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnthropicApiKey() => clearField(1);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
