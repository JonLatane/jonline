//
//  Generated code. Do not modify.
//  source: media.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $9;
import 'visibility_moderation.pbenum.dart' as $11;

class Media extends $pb.GeneratedMessage {
  factory Media() => create();
  Media._() : super();
  factory Media.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Media.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Media', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'contentType')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..e<$11.Visibility>(6, _omitFieldNames ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $11.Visibility.VISIBILITY_UNKNOWN, valueOf: $11.Visibility.valueOf, enumValues: $11.Visibility.values)
    ..e<$11.Moderation>(7, _omitFieldNames ? '' : 'moderation', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..aOB(8, _omitFieldNames ? '' : 'generated')
    ..aOB(9, _omitFieldNames ? '' : 'processed')
    ..aOM<$9.Timestamp>(15, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(16, _omitFieldNames ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Media clone() => Media()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Media copyWith(void Function(Media) updates) => super.copyWith((message) => updates(message as Media)) as Media;

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

  @$pb.TagNumber(8)
  $core.bool get generated => $_getBF(7);
  @$pb.TagNumber(8)
  set generated($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasGenerated() => $_has(7);
  @$pb.TagNumber(8)
  void clearGenerated() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get processed => $_getBF(8);
  @$pb.TagNumber(9)
  set processed($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasProcessed() => $_has(8);
  @$pb.TagNumber(9)
  void clearProcessed() => clearField(9);

  @$pb.TagNumber(15)
  $9.Timestamp get createdAt => $_getN(9);
  @$pb.TagNumber(15)
  set createdAt($9.Timestamp v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasCreatedAt() => $_has(9);
  @$pb.TagNumber(15)
  void clearCreatedAt() => clearField(15);
  @$pb.TagNumber(15)
  $9.Timestamp ensureCreatedAt() => $_ensure(9);

  @$pb.TagNumber(16)
  $9.Timestamp get updatedAt => $_getN(10);
  @$pb.TagNumber(16)
  set updatedAt($9.Timestamp v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasUpdatedAt() => $_has(10);
  @$pb.TagNumber(16)
  void clearUpdatedAt() => clearField(16);
  @$pb.TagNumber(16)
  $9.Timestamp ensureUpdatedAt() => $_ensure(10);
}

class GetMediaRequest extends $pb.GeneratedMessage {
  factory GetMediaRequest() => create();
  GetMediaRequest._() : super();
  factory GetMediaRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetMediaRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetMediaRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'mediaId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..a<$core.int>(11, _omitFieldNames ? '' : 'page', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetMediaRequest clone() => GetMediaRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetMediaRequest copyWith(void Function(GetMediaRequest) updates) => super.copyWith((message) => updates(message as GetMediaRequest)) as GetMediaRequest;

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
  factory GetMediaResponse() => create();
  GetMediaResponse._() : super();
  factory GetMediaResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetMediaResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetMediaResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Media>(1, _omitFieldNames ? '' : 'media', $pb.PbFieldType.PM, subBuilder: Media.create)
    ..aOB(2, _omitFieldNames ? '' : 'hasNextPage')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetMediaResponse clone() => GetMediaResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetMediaResponse copyWith(void Function(GetMediaResponse) updates) => super.copyWith((message) => updates(message as GetMediaResponse)) as GetMediaResponse;

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


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
