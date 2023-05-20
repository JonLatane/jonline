///
//  Generated code. Do not modify.
//  source: groups.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'users.pb.dart' as $4;
import 'google/protobuf/timestamp.pb.dart' as $9;

import 'permissions.pbenum.dart' as $10;
import 'visibility_moderation.pbenum.dart' as $11;
import 'groups.pbenum.dart';

export 'groups.pbenum.dart';

class Group extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Group', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'shortname')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'description')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'avatarMediaId')
    ..pc<$10.Permission>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'defaultMembershipPermissions', $pb.PbFieldType.KE, valueOf: $10.Permission.valueOf, enumValues: $10.Permission.values, defaultEnumValue: $10.Permission.PERMISSION_UNKNOWN)
    ..e<$11.Moderation>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'defaultMembershipModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Moderation>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'defaultPostModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Moderation>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'defaultEventModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Visibility>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $11.Visibility.VISIBILITY_UNKNOWN, valueOf: $11.Visibility.valueOf, enumValues: $11.Visibility.values)
    ..a<$core.int>(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'memberCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(12, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'postCount', $pb.PbFieldType.OU3)
    ..aOM<$4.Membership>(13, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'currentUserMembership', subBuilder: $4.Membership.create)
    ..aOM<$9.Timestamp>(14, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(15, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  Group._() : super();
  factory Group({
    $core.String? id,
    $core.String? name,
    $core.String? shortname,
    $core.String? description,
    $core.String? avatarMediaId,
    $core.Iterable<$10.Permission>? defaultMembershipPermissions,
    $11.Moderation? defaultMembershipModeration,
    $11.Moderation? defaultPostModeration,
    $11.Moderation? defaultEventModeration,
    $11.Visibility? visibility,
    $core.int? memberCount,
    $core.int? postCount,
    $4.Membership? currentUserMembership,
    $9.Timestamp? createdAt,
    $9.Timestamp? updatedAt,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (shortname != null) {
      _result.shortname = shortname;
    }
    if (description != null) {
      _result.description = description;
    }
    if (avatarMediaId != null) {
      _result.avatarMediaId = avatarMediaId;
    }
    if (defaultMembershipPermissions != null) {
      _result.defaultMembershipPermissions.addAll(defaultMembershipPermissions);
    }
    if (defaultMembershipModeration != null) {
      _result.defaultMembershipModeration = defaultMembershipModeration;
    }
    if (defaultPostModeration != null) {
      _result.defaultPostModeration = defaultPostModeration;
    }
    if (defaultEventModeration != null) {
      _result.defaultEventModeration = defaultEventModeration;
    }
    if (visibility != null) {
      _result.visibility = visibility;
    }
    if (memberCount != null) {
      _result.memberCount = memberCount;
    }
    if (postCount != null) {
      _result.postCount = postCount;
    }
    if (currentUserMembership != null) {
      _result.currentUserMembership = currentUserMembership;
    }
    if (createdAt != null) {
      _result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      _result.updatedAt = updatedAt;
    }
    return _result;
  }
  factory Group.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Group.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Group clone() => Group()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Group copyWith(void Function(Group) updates) => super.copyWith((message) => updates(message as Group)) as Group; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Group create() => Group._();
  Group createEmptyInstance() => create();
  static $pb.PbList<Group> createRepeated() => $pb.PbList<Group>();
  @$core.pragma('dart2js:noInline')
  static Group getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Group>(create);
  static Group? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get shortname => $_getSZ(2);
  @$pb.TagNumber(3)
  set shortname($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasShortname() => $_has(2);
  @$pb.TagNumber(3)
  void clearShortname() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(3);
  @$pb.TagNumber(4)
  set description($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearDescription() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get avatarMediaId => $_getSZ(4);
  @$pb.TagNumber(5)
  set avatarMediaId($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasAvatarMediaId() => $_has(4);
  @$pb.TagNumber(5)
  void clearAvatarMediaId() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<$10.Permission> get defaultMembershipPermissions => $_getList(5);

  @$pb.TagNumber(7)
  $11.Moderation get defaultMembershipModeration => $_getN(6);
  @$pb.TagNumber(7)
  set defaultMembershipModeration($11.Moderation v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasDefaultMembershipModeration() => $_has(6);
  @$pb.TagNumber(7)
  void clearDefaultMembershipModeration() => clearField(7);

  @$pb.TagNumber(8)
  $11.Moderation get defaultPostModeration => $_getN(7);
  @$pb.TagNumber(8)
  set defaultPostModeration($11.Moderation v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasDefaultPostModeration() => $_has(7);
  @$pb.TagNumber(8)
  void clearDefaultPostModeration() => clearField(8);

  @$pb.TagNumber(9)
  $11.Moderation get defaultEventModeration => $_getN(8);
  @$pb.TagNumber(9)
  set defaultEventModeration($11.Moderation v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasDefaultEventModeration() => $_has(8);
  @$pb.TagNumber(9)
  void clearDefaultEventModeration() => clearField(9);

  @$pb.TagNumber(10)
  $11.Visibility get visibility => $_getN(9);
  @$pb.TagNumber(10)
  set visibility($11.Visibility v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasVisibility() => $_has(9);
  @$pb.TagNumber(10)
  void clearVisibility() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get memberCount => $_getIZ(10);
  @$pb.TagNumber(11)
  set memberCount($core.int v) { $_setUnsignedInt32(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasMemberCount() => $_has(10);
  @$pb.TagNumber(11)
  void clearMemberCount() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get postCount => $_getIZ(11);
  @$pb.TagNumber(12)
  set postCount($core.int v) { $_setUnsignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasPostCount() => $_has(11);
  @$pb.TagNumber(12)
  void clearPostCount() => clearField(12);

  @$pb.TagNumber(13)
  $4.Membership get currentUserMembership => $_getN(12);
  @$pb.TagNumber(13)
  set currentUserMembership($4.Membership v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasCurrentUserMembership() => $_has(12);
  @$pb.TagNumber(13)
  void clearCurrentUserMembership() => clearField(13);
  @$pb.TagNumber(13)
  $4.Membership ensureCurrentUserMembership() => $_ensure(12);

  @$pb.TagNumber(14)
  $9.Timestamp get createdAt => $_getN(13);
  @$pb.TagNumber(14)
  set createdAt($9.Timestamp v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasCreatedAt() => $_has(13);
  @$pb.TagNumber(14)
  void clearCreatedAt() => clearField(14);
  @$pb.TagNumber(14)
  $9.Timestamp ensureCreatedAt() => $_ensure(13);

  @$pb.TagNumber(15)
  $9.Timestamp get updatedAt => $_getN(14);
  @$pb.TagNumber(15)
  set updatedAt($9.Timestamp v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasUpdatedAt() => $_has(14);
  @$pb.TagNumber(15)
  void clearUpdatedAt() => clearField(15);
  @$pb.TagNumber(15)
  $9.Timestamp ensureUpdatedAt() => $_ensure(14);
}

class GetGroupsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetGroupsRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupName')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupShortname')
    ..e<GroupListingType>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'listingType', $pb.PbFieldType.OE, defaultOrMaker: GroupListingType.ALL_GROUPS, valueOf: GroupListingType.valueOf, enumValues: GroupListingType.values)
    ..a<$core.int>(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'page', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  GetGroupsRequest._() : super();
  factory GetGroupsRequest({
    $core.String? groupId,
    $core.String? groupName,
    $core.String? groupShortname,
    GroupListingType? listingType,
    $core.int? page,
  }) {
    final _result = create();
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (groupName != null) {
      _result.groupName = groupName;
    }
    if (groupShortname != null) {
      _result.groupShortname = groupShortname;
    }
    if (listingType != null) {
      _result.listingType = listingType;
    }
    if (page != null) {
      _result.page = page;
    }
    return _result;
  }
  factory GetGroupsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetGroupsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetGroupsRequest clone() => GetGroupsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetGroupsRequest copyWith(void Function(GetGroupsRequest) updates) => super.copyWith((message) => updates(message as GetGroupsRequest)) as GetGroupsRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetGroupsRequest create() => GetGroupsRequest._();
  GetGroupsRequest createEmptyInstance() => create();
  static $pb.PbList<GetGroupsRequest> createRepeated() => $pb.PbList<GetGroupsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetGroupsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetGroupsRequest>(create);
  static GetGroupsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get groupName => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroupName() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get groupShortname => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupShortname($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasGroupShortname() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupShortname() => clearField(3);

  @$pb.TagNumber(10)
  GroupListingType get listingType => $_getN(3);
  @$pb.TagNumber(10)
  set listingType(GroupListingType v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasListingType() => $_has(3);
  @$pb.TagNumber(10)
  void clearListingType() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get page => $_getIZ(4);
  @$pb.TagNumber(11)
  set page($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(11)
  $core.bool hasPage() => $_has(4);
  @$pb.TagNumber(11)
  void clearPage() => clearField(11);
}

class GetGroupsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetGroupsResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Group>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groups', $pb.PbFieldType.PM, subBuilder: Group.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hasNextPage')
    ..hasRequiredFields = false
  ;

  GetGroupsResponse._() : super();
  factory GetGroupsResponse({
    $core.Iterable<Group>? groups,
    $core.bool? hasNextPage,
  }) {
    final _result = create();
    if (groups != null) {
      _result.groups.addAll(groups);
    }
    if (hasNextPage != null) {
      _result.hasNextPage = hasNextPage;
    }
    return _result;
  }
  factory GetGroupsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetGroupsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetGroupsResponse clone() => GetGroupsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetGroupsResponse copyWith(void Function(GetGroupsResponse) updates) => super.copyWith((message) => updates(message as GetGroupsResponse)) as GetGroupsResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetGroupsResponse create() => GetGroupsResponse._();
  GetGroupsResponse createEmptyInstance() => create();
  static $pb.PbList<GetGroupsResponse> createRepeated() => $pb.PbList<GetGroupsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetGroupsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetGroupsResponse>(create);
  static GetGroupsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Group> get groups => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get hasNextPage => $_getBF(1);
  @$pb.TagNumber(2)
  set hasNextPage($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasHasNextPage() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasNextPage() => clearField(2);
}

class Member extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Member', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<$4.User>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'user', subBuilder: $4.User.create)
    ..aOM<$4.Membership>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'membership', subBuilder: $4.Membership.create)
    ..hasRequiredFields = false
  ;

  Member._() : super();
  factory Member({
    $4.User? user,
    $4.Membership? membership,
  }) {
    final _result = create();
    if (user != null) {
      _result.user = user;
    }
    if (membership != null) {
      _result.membership = membership;
    }
    return _result;
  }
  factory Member.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Member.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Member clone() => Member()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Member copyWith(void Function(Member) updates) => super.copyWith((message) => updates(message as Member)) as Member; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Member create() => Member._();
  Member createEmptyInstance() => create();
  static $pb.PbList<Member> createRepeated() => $pb.PbList<Member>();
  @$core.pragma('dart2js:noInline')
  static Member getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Member>(create);
  static Member? _defaultInstance;

  @$pb.TagNumber(1)
  $4.User get user => $_getN(0);
  @$pb.TagNumber(1)
  set user($4.User v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => clearField(1);
  @$pb.TagNumber(1)
  $4.User ensureUser() => $_ensure(0);

  @$pb.TagNumber(2)
  $4.Membership get membership => $_getN(1);
  @$pb.TagNumber(2)
  set membership($4.Membership v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasMembership() => $_has(1);
  @$pb.TagNumber(2)
  void clearMembership() => clearField(2);
  @$pb.TagNumber(2)
  $4.Membership ensureMembership() => $_ensure(1);
}

class GetMembersRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetMembersRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'username')
    ..e<$11.Moderation>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..a<$core.int>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'page', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  GetMembersRequest._() : super();
  factory GetMembersRequest({
    $core.String? groupId,
    $core.String? username,
    $11.Moderation? groupModeration,
    $core.int? page,
  }) {
    final _result = create();
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (username != null) {
      _result.username = username;
    }
    if (groupModeration != null) {
      _result.groupModeration = groupModeration;
    }
    if (page != null) {
      _result.page = page;
    }
    return _result;
  }
  factory GetMembersRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetMembersRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetMembersRequest clone() => GetMembersRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetMembersRequest copyWith(void Function(GetMembersRequest) updates) => super.copyWith((message) => updates(message as GetMembersRequest)) as GetMembersRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetMembersRequest create() => GetMembersRequest._();
  GetMembersRequest createEmptyInstance() => create();
  static $pb.PbList<GetMembersRequest> createRepeated() => $pb.PbList<GetMembersRequest>();
  @$core.pragma('dart2js:noInline')
  static GetMembersRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetMembersRequest>(create);
  static GetMembersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => clearField(2);

  @$pb.TagNumber(3)
  $11.Moderation get groupModeration => $_getN(2);
  @$pb.TagNumber(3)
  set groupModeration($11.Moderation v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasGroupModeration() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupModeration() => clearField(3);

  @$pb.TagNumber(10)
  $core.int get page => $_getIZ(3);
  @$pb.TagNumber(10)
  set page($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(10)
  $core.bool hasPage() => $_has(3);
  @$pb.TagNumber(10)
  void clearPage() => clearField(10);
}

class GetMembersResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetMembersResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Member>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'members', $pb.PbFieldType.PM, subBuilder: Member.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hasNextPage')
    ..hasRequiredFields = false
  ;

  GetMembersResponse._() : super();
  factory GetMembersResponse({
    $core.Iterable<Member>? members,
    $core.bool? hasNextPage,
  }) {
    final _result = create();
    if (members != null) {
      _result.members.addAll(members);
    }
    if (hasNextPage != null) {
      _result.hasNextPage = hasNextPage;
    }
    return _result;
  }
  factory GetMembersResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetMembersResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetMembersResponse clone() => GetMembersResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetMembersResponse copyWith(void Function(GetMembersResponse) updates) => super.copyWith((message) => updates(message as GetMembersResponse)) as GetMembersResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetMembersResponse create() => GetMembersResponse._();
  GetMembersResponse createEmptyInstance() => create();
  static $pb.PbList<GetMembersResponse> createRepeated() => $pb.PbList<GetMembersResponse>();
  @$core.pragma('dart2js:noInline')
  static GetMembersResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetMembersResponse>(create);
  static GetMembersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Member> get members => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get hasNextPage => $_getBF(1);
  @$pb.TagNumber(2)
  set hasNextPage($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasHasNextPage() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasNextPage() => clearField(2);
}

