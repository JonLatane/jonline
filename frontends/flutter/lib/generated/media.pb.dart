//
//  Generated code. Do not modify.
//  source: media.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $9;
import 'visibility_moderation.pbenum.dart' as $10;

///  A Jonline `Media` message represents a single media item, such as a photo or video.
///  Media data is deliberately *not returnable from the gRPC API*. Instead, the client
///  should fetch media from `http[s]://my.jonline.instance/media/{id}`.
///
///  Media items may be created with a HTTP POST to `http[s]://my.jonline.instance/media`
///  along with an "Authorization" header (your access token) and a "Content-Type" header.
///  On success, the endpoint will return the media ID in plaintext.
///
///  `POST /media` supports the following headers:
///  - `Content-Type` - The MIME content type of the media item.
///  - `Filename` - An optional title for the media item.
///  - `Authorization` - Jonline Access Token for the user. Required, but may be supplied in `Cookies`.
///  - `Cookies` - Standard web cookies. The `jonline_access_token` cookie may be used for authentication.
///
///  `GET /media` supports the following:
///  - **Headers**:
///      - `Authorization` - Jonline Access Token for the user. May also be supplied in `Cookies` or via query parameter.
///      - `Cookies` - Standard web cookies. The `jonline_access_token` cookie may be used for authentication.
///  - **Query Parameters**:
///      - `authorization` - Jonline Access Token for the user. May also be supplied in the `Cookies` or `Authorization` headers.
///  - Fetching media without authentication requires that it has `GLOBAL_PUBLIC` visibility.
class Media extends $pb.GeneratedMessage {
  factory Media({
    $core.String? id,
    $core.String? userId,
    $core.String? contentType,
    $core.String? name,
    $core.String? description,
    $10.Visibility? visibility,
    $10.Moderation? moderation,
    $core.bool? generated,
    $core.bool? processed,
    $9.Timestamp? createdAt,
    $9.Timestamp? updatedAt,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (userId != null) {
      $result.userId = userId;
    }
    if (contentType != null) {
      $result.contentType = contentType;
    }
    if (name != null) {
      $result.name = name;
    }
    if (description != null) {
      $result.description = description;
    }
    if (visibility != null) {
      $result.visibility = visibility;
    }
    if (moderation != null) {
      $result.moderation = moderation;
    }
    if (generated != null) {
      $result.generated = generated;
    }
    if (processed != null) {
      $result.processed = processed;
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      $result.updatedAt = updatedAt;
    }
    return $result;
  }
  Media._() : super();
  factory Media.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Media.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Media', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'contentType')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..e<$10.Visibility>(6, _omitFieldNames ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $10.Visibility.VISIBILITY_UNKNOWN, valueOf: $10.Visibility.valueOf, enumValues: $10.Visibility.values)
    ..e<$10.Moderation>(7, _omitFieldNames ? '' : 'moderation', $pb.PbFieldType.OE, defaultOrMaker: $10.Moderation.MODERATION_UNKNOWN, valueOf: $10.Moderation.valueOf, enumValues: $10.Moderation.values)
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

  /// The ID of the media item.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// The ID of the user who created the media item.
  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => clearField(2);

  /// The MIME content type of the media item.
  @$pb.TagNumber(3)
  $core.String get contentType => $_getSZ(2);
  @$pb.TagNumber(3)
  set contentType($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasContentType() => $_has(2);
  @$pb.TagNumber(3)
  void clearContentType() => clearField(3);

  /// An optional title for the media item.
  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => clearField(4);

  /// An optional description for the media item.
  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => clearField(5);

  /// Visibility of the media item.
  @$pb.TagNumber(6)
  $10.Visibility get visibility => $_getN(5);
  @$pb.TagNumber(6)
  set visibility($10.Visibility v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasVisibility() => $_has(5);
  @$pb.TagNumber(6)
  void clearVisibility() => clearField(6);

  /// Moderation of the media item.
  @$pb.TagNumber(7)
  $10.Moderation get moderation => $_getN(6);
  @$pb.TagNumber(7)
  set moderation($10.Moderation v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasModeration() => $_has(6);
  @$pb.TagNumber(7)
  void clearModeration() => clearField(7);

  /// Indicates the media was generated by the server rather than uploaded manually by a user.
  @$pb.TagNumber(8)
  $core.bool get generated => $_getBF(7);
  @$pb.TagNumber(8)
  set generated($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasGenerated() => $_has(7);
  @$pb.TagNumber(8)
  void clearGenerated() => clearField(8);

  /// Media is generally stored as-is on upload.
  /// When background jobs process and compress the media, this flag is set to true.
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

/// A reference to a media item, designed to be included in other messages as a reference.
/// Contains the bare minimum data needed to fetch media via the HTTP API and render it,
/// and the media item's name (for alt text usage).
class MediaReference extends $pb.GeneratedMessage {
  factory MediaReference({
    $core.String? contentType,
    $core.String? id,
    $core.String? name,
    $core.bool? generated,
  }) {
    final $result = create();
    if (contentType != null) {
      $result.contentType = contentType;
    }
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    if (generated != null) {
      $result.generated = generated;
    }
    return $result;
  }
  MediaReference._() : super();
  factory MediaReference.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MediaReference.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MediaReference', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'contentType')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOB(4, _omitFieldNames ? '' : 'generated')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MediaReference clone() => MediaReference()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MediaReference copyWith(void Function(MediaReference) updates) => super.copyWith((message) => updates(message as MediaReference)) as MediaReference;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MediaReference create() => MediaReference._();
  MediaReference createEmptyInstance() => create();
  static $pb.PbList<MediaReference> createRepeated() => $pb.PbList<MediaReference>();
  @$core.pragma('dart2js:noInline')
  static MediaReference getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MediaReference>(create);
  static MediaReference? _defaultInstance;

  /// The MIME content type of the media item.
  @$pb.TagNumber(1)
  $core.String get contentType => $_getSZ(0);
  @$pb.TagNumber(1)
  set contentType($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasContentType() => $_has(0);
  @$pb.TagNumber(1)
  void clearContentType() => clearField(1);

  /// The ID of the media item.
  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);

  /// An optional title for the media item.
  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  /// Indicates the media was generated by the server rather than uploaded manually by a user.
  @$pb.TagNumber(4)
  $core.bool get generated => $_getBF(3);
  @$pb.TagNumber(4)
  set generated($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasGenerated() => $_has(3);
  @$pb.TagNumber(4)
  void clearGenerated() => clearField(4);
}

/// Valid GetMediaRequest formats:
/// - `{user_id: abc123}` - Gets the media of the given user that the current user can see. IE:
///     - *all* of the current user's own media
///     - `GLOBAL_PUBLIC` media for the user if the current user is not logged in.
///     - `SERVER_PUBLIC` media for the user if the current user is logged in.
///     - `LIMITED` media for the user if the current user is following the user.
/// - `{media_id: abc123}` - Gets the media with the given ID, if visible to the current user.
class GetMediaRequest extends $pb.GeneratedMessage {
  factory GetMediaRequest({
    $core.String? mediaId,
    $core.String? userId,
    $core.int? page,
  }) {
    final $result = create();
    if (mediaId != null) {
      $result.mediaId = mediaId;
    }
    if (userId != null) {
      $result.userId = userId;
    }
    if (page != null) {
      $result.page = page;
    }
    return $result;
  }
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

  /// Returns the single media item with the given ID.
  @$pb.TagNumber(1)
  $core.String get mediaId => $_getSZ(0);
  @$pb.TagNumber(1)
  set mediaId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMediaId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMediaId() => clearField(1);

  /// Returns all media items for the given user.
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
  factory GetMediaResponse({
    $core.Iterable<Media>? media,
    $core.bool? hasNextPage,
  }) {
    final $result = create();
    if (media != null) {
      $result.media.addAll(media);
    }
    if (hasNextPage != null) {
      $result.hasNextPage = hasNextPage;
    }
    return $result;
  }
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
