//
//  Generated code. Do not modify.
//  source: groups.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $9;
import 'groups.pbenum.dart';
import 'permissions.pbenum.dart' as $10;
import 'users.pb.dart' as $4;
import 'visibility_moderation.pbenum.dart' as $11;

export 'groups.pbenum.dart';

class Group extends $pb.GeneratedMessage {
  factory Group() => create();
  Group._() : super();
  factory Group.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Group.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Group', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'shortname')
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..aOS(5, _omitFieldNames ? '' : 'avatarMediaId')
    ..pc<$10.Permission>(6, _omitFieldNames ? '' : 'defaultMembershipPermissions', $pb.PbFieldType.KE, valueOf: $10.Permission.valueOf, enumValues: $10.Permission.values, defaultEnumValue: $10.Permission.PERMISSION_UNKNOWN)
    ..e<$11.Moderation>(7, _omitFieldNames ? '' : 'defaultMembershipModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Moderation>(8, _omitFieldNames ? '' : 'defaultPostModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Moderation>(9, _omitFieldNames ? '' : 'defaultEventModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Visibility>(10, _omitFieldNames ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $11.Visibility.VISIBILITY_UNKNOWN, valueOf: $11.Visibility.valueOf, enumValues: $11.Visibility.values)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'memberCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'postCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'eventCount', $pb.PbFieldType.OU3)
    ..aOM<$4.Membership>(19, _omitFieldNames ? '' : 'currentUserMembership', subBuilder: $4.Membership.create)
    ..aOM<$9.Timestamp>(20, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(21, _omitFieldNames ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Group clone() => Group()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Group copyWith(void Function(Group) updates) => super.copyWith((message) => updates(message as Group)) as Group;

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
  $core.int get eventCount => $_getIZ(12);
  @$pb.TagNumber(13)
  set eventCount($core.int v) { $_setUnsignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasEventCount() => $_has(12);
  @$pb.TagNumber(13)
  void clearEventCount() => clearField(13);

  @$pb.TagNumber(19)
  $4.Membership get currentUserMembership => $_getN(13);
  @$pb.TagNumber(19)
  set currentUserMembership($4.Membership v) { setField(19, v); }
  @$pb.TagNumber(19)
  $core.bool hasCurrentUserMembership() => $_has(13);
  @$pb.TagNumber(19)
  void clearCurrentUserMembership() => clearField(19);
  @$pb.TagNumber(19)
  $4.Membership ensureCurrentUserMembership() => $_ensure(13);

  @$pb.TagNumber(20)
  $9.Timestamp get createdAt => $_getN(14);
  @$pb.TagNumber(20)
  set createdAt($9.Timestamp v) { setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedAt() => $_has(14);
  @$pb.TagNumber(20)
  void clearCreatedAt() => clearField(20);
  @$pb.TagNumber(20)
  $9.Timestamp ensureCreatedAt() => $_ensure(14);

  @$pb.TagNumber(21)
  $9.Timestamp get updatedAt => $_getN(15);
  @$pb.TagNumber(21)
  set updatedAt($9.Timestamp v) { setField(21, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedAt() => $_has(15);
  @$pb.TagNumber(21)
  void clearUpdatedAt() => clearField(21);
  @$pb.TagNumber(21)
  $9.Timestamp ensureUpdatedAt() => $_ensure(15);
}

class GetGroupsRequest extends $pb.GeneratedMessage {
  factory GetGroupsRequest() => create();
  GetGroupsRequest._() : super();
  factory GetGroupsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetGroupsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetGroupsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aOS(2, _omitFieldNames ? '' : 'groupName')
    ..aOS(3, _omitFieldNames ? '' : 'groupShortname')
    ..e<GroupListingType>(10, _omitFieldNames ? '' : 'listingType', $pb.PbFieldType.OE, defaultOrMaker: GroupListingType.ALL_GROUPS, valueOf: GroupListingType.valueOf, enumValues: GroupListingType.values)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'page', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetGroupsRequest clone() => GetGroupsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetGroupsRequest copyWith(void Function(GetGroupsRequest) updates) => super.copyWith((message) => updates(message as GetGroupsRequest)) as GetGroupsRequest;

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
  factory GetGroupsResponse() => create();
  GetGroupsResponse._() : super();
  factory GetGroupsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetGroupsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetGroupsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Group>(1, _omitFieldNames ? '' : 'groups', $pb.PbFieldType.PM, subBuilder: Group.create)
    ..aOB(2, _omitFieldNames ? '' : 'hasNextPage')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetGroupsResponse clone() => GetGroupsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetGroupsResponse copyWith(void Function(GetGroupsResponse) updates) => super.copyWith((message) => updates(message as GetGroupsResponse)) as GetGroupsResponse;

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
  factory Member() => create();
  Member._() : super();
  factory Member.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Member.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Member', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<$4.User>(1, _omitFieldNames ? '' : 'user', subBuilder: $4.User.create)
    ..aOM<$4.Membership>(2, _omitFieldNames ? '' : 'membership', subBuilder: $4.Membership.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Member clone() => Member()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Member copyWith(void Function(Member) updates) => super.copyWith((message) => updates(message as Member)) as Member;

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
  factory GetMembersRequest() => create();
  GetMembersRequest._() : super();
  factory GetMembersRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetMembersRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetMembersRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..e<$11.Moderation>(3, _omitFieldNames ? '' : 'groupModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'page', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetMembersRequest clone() => GetMembersRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetMembersRequest copyWith(void Function(GetMembersRequest) updates) => super.copyWith((message) => updates(message as GetMembersRequest)) as GetMembersRequest;

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
  factory GetMembersResponse() => create();
  GetMembersResponse._() : super();
  factory GetMembersResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetMembersResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetMembersResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Member>(1, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PM, subBuilder: Member.create)
    ..aOB(2, _omitFieldNames ? '' : 'hasNextPage')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetMembersResponse clone() => GetMembersResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetMembersResponse copyWith(void Function(GetMembersResponse) updates) => super.copyWith((message) => updates(message as GetMembersResponse)) as GetMembersResponse;

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


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
