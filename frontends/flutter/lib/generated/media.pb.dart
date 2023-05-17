///
//  Generated code. Do not modify.
//  source: media.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $9;

import 'visibility_moderation.pbenum.dart' as $11;

class Media extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Media', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'contentType')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'description')
    ..e<$11.Visibility>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $11.Visibility.VISIBILITY_UNKNOWN, valueOf: $11.Visibility.valueOf, enumValues: $11.Visibility.values)
    ..e<$11.Moderation>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'moderation', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..aOM<$9.Timestamp>(15, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(16, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  Media._() : super();
  factory Media({
    $core.String? id,
    $core.String? userId,
    $core.String? contentType,
    $core.String? name,
    $core.String? description,
    $11.Visibility? visibility,
    $11.Moderation? moderation,
    $9.Timestamp? createdAt,
    $9.Timestamp? updatedAt,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (userId != null) {
      _result.userId = userId;
    }
    if (contentType != null) {
      _result.contentType = contentType;
    }
    if (name != null) {
      _result.name = name;
    }
    if (description != null) {
      _result.description = description;
    }
    if (visibility != null) {
      _result.visibility = visibility;
    }
    if (moderation != null) {
      _result.moderation = moderation;
    }
    if (createdAt != null) {
      _result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      _result.updatedAt = updatedAt;
    }
    return _result;
  }
  factory Media.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Media.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Media clone() => Media()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Media copyWith(void Function(Media) updates) => super.copyWith((message) => updates(message as Media)) as Media; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Media create() => Media._();
  Media createEmptyInstance() => create();
  static $pb.PbList<Media> createRepeated() => $pb.PbList<Media>();
  @$core.pragma('dart2js:noInline')
  static Media getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Media>(create);
  static Media? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get contentType => $_getSZ(2);
  @$pb.TagNumber(3)
  set contentType($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasContentType() => $_has(2);
  @$pb.TagNumber(3)
  void clearContentType() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => clearField(5);

  @$pb.TagNumber(6)
  $11.Visibility get visibility => $_getN(5);
  @$pb.TagNumber(6)
  set visibility($11.Visibility v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasVisibility() => $_has(5);
  @$pb.TagNumber(6)
  void clearVisibility() => clearField(6);

  @$pb.TagNumber(7)
  $11.Moderation get moderation => $_getN(6);
  @$pb.TagNumber(7)
  set moderation($11.Moderation v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasModeration() => $_has(6);
  @$pb.TagNumber(7)
  void clearModeration() => clearField(7);

  @$pb.TagNumber(15)
  $9.Timestamp get createdAt => $_getN(7);
  @$pb.TagNumber(15)
  set createdAt($9.Timestamp v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasCreatedAt() => $_has(7);
  @$pb.TagNumber(15)
  void clearCreatedAt() => clearField(15);
  @$pb.TagNumber(15)
  $9.Timestamp ensureCreatedAt() => $_ensure(7);

  @$pb.TagNumber(16)
  $9.Timestamp get updatedAt => $_getN(8);
  @$pb.TagNumber(16)
  set updatedAt($9.Timestamp v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasUpdatedAt() => $_has(8);
  @$pb.TagNumber(16)
  void clearUpdatedAt() => clearField(16);
  @$pb.TagNumber(16)
  $9.Timestamp ensureUpdatedAt() => $_ensure(8);
}

class GetMediaRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetMediaRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mediaId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..a<$core.int>(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'page', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  GetMediaRequest._() : super();
  factory GetMediaRequest({
    $core.String? mediaId,
    $core.String? userId,
    $core.int? page,
  }) {
    final _result = create();
    if (mediaId != null) {
      _result.mediaId = mediaId;
    }
    if (userId != null) {
      _result.userId = userId;
    }
    if (page != null) {
      _result.page = page;
    }
    return _result;
  }
  factory GetMediaRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetMediaRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetMediaRequest clone() => GetMediaRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetMediaRequest copyWith(void Function(GetMediaRequest) updates) => super.copyWith((message) => updates(message as GetMediaRequest)) as GetMediaRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetMediaRequest create() => GetMediaRequest._();
  GetMediaRequest createEmptyInstance() => create();
  static $pb.PbList<GetMediaRequest> createRepeated() => $pb.PbList<GetMediaRequest>();
  @$core.pragma('dart2js:noInline')
  static GetMediaRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetMediaRequest>(create);
  static GetMediaRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mediaId => $_getSZ(0);
  @$pb.TagNumber(1)
  set mediaId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMediaId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMediaId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => clearField(2);

  @$pb.TagNumber(11)
  $core.int get page => $_getIZ(2);
  @$pb.TagNumber(11)
  set page($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(11)
  $core.bool hasPage() => $_has(2);
  @$pb.TagNumber(11)
  void clearPage() => clearField(11);
}

class GetMediaResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetMediaResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Media>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'media', $pb.PbFieldType.PM, subBuilder: Media.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hasNextPage')
    ..hasRequiredFields = false
  ;

  GetMediaResponse._() : super();
  factory GetMediaResponse({
    $core.Iterable<Media>? media,
    $core.bool? hasNextPage,
  }) {
    final _result = create();
    if (media != null) {
      _result.media.addAll(media);
    }
    if (hasNextPage != null) {
      _result.hasNextPage = hasNextPage;
    }
    return _result;
  }
  factory GetMediaResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetMediaResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetMediaResponse clone() => GetMediaResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetMediaResponse copyWith(void Function(GetMediaResponse) updates) => super.copyWith((message) => updates(message as GetMediaResponse)) as GetMediaResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetMediaResponse create() => GetMediaResponse._();
  GetMediaResponse createEmptyInstance() => create();
  static $pb.PbList<GetMediaResponse> createRepeated() => $pb.PbList<GetMediaResponse>();
  @$core.pragma('dart2js:noInline')
  static GetMediaResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetMediaResponse>(create);
  static GetMediaResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Media> get media => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get hasNextPage => $_getBF(1);
  @$pb.TagNumber(2)
  set hasNextPage($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasHasNextPage() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasNextPage() => clearField(2);
}

