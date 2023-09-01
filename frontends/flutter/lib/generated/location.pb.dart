//
//  Generated code. Do not modify.
//  source: location.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Locations
class Location extends $pb.GeneratedMessage {
  factory Location({
    $core.String? id,
    $core.String? creatorId,
    $core.String? uniformlyFormattedAddress,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (creatorId != null) {
      $result.creatorId = creatorId;
    }
    if (uniformlyFormattedAddress != null) {
      $result.uniformlyFormattedAddress = uniformlyFormattedAddress;
    }
    return $result;
  }
  Location._() : super();
  factory Location.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Location.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Location', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'creatorId')
    ..aOS(3, _omitFieldNames ? '' : 'uniformlyFormattedAddress')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Location clone() => Location()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Location copyWith(void Function(Location) updates) => super.copyWith((message) => updates(message as Location)) as Location;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Location create() => Location._();
  Location createEmptyInstance() => create();
  static $pb.PbList<Location> createRepeated() => $pb.PbList<Location>();
  @$core.pragma('dart2js:noInline')
  static Location getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Location>(create);
  static Location? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get creatorId => $_getSZ(1);
  @$pb.TagNumber(2)
  set creatorId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCreatorId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCreatorId() => clearField(2);

  /// This should probably come from OpenStreetMap APIs, with an option for Google Maps.
  /// Ideally both the Flutter and React apps, and any others, should prefer OpenStreetMap
  /// but give the user the option to use Google Maps.
  @$pb.TagNumber(3)
  $core.String get uniformlyFormattedAddress => $_getSZ(2);
  @$pb.TagNumber(3)
  set uniformlyFormattedAddress($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUniformlyFormattedAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearUniformlyFormattedAddress() => clearField(3);
}

class LocationAlias extends $pb.GeneratedMessage {
  factory LocationAlias({
    $core.String? id,
    $core.String? alias,
    $core.String? creatorId,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (alias != null) {
      $result.alias = alias;
    }
    if (creatorId != null) {
      $result.creatorId = creatorId;
    }
    return $result;
  }
  LocationAlias._() : super();
  factory LocationAlias.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LocationAlias.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LocationAlias', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'alias')
    ..aOS(3, _omitFieldNames ? '' : 'creatorId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LocationAlias clone() => LocationAlias()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LocationAlias copyWith(void Function(LocationAlias) updates) => super.copyWith((message) => updates(message as LocationAlias)) as LocationAlias;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocationAlias create() => LocationAlias._();
  LocationAlias createEmptyInstance() => create();
  static $pb.PbList<LocationAlias> createRepeated() => $pb.PbList<LocationAlias>();
  @$core.pragma('dart2js:noInline')
  static LocationAlias getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LocationAlias>(create);
  static LocationAlias? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get alias => $_getSZ(1);
  @$pb.TagNumber(2)
  set alias($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAlias() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlias() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get creatorId => $_getSZ(2);
  @$pb.TagNumber(3)
  set creatorId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCreatorId() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatorId() => clearField(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
