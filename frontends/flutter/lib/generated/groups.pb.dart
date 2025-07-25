// This is a generated file - do not edit.
//
// Generated from groups.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $2;
import 'groups.pbenum.dart';
import 'media.pb.dart' as $0;
import 'permissions.pbenum.dart' as $3;
import 'users.pb.dart' as $1;
import 'visibility_moderation.pbenum.dart' as $4;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'groups.pbenum.dart';

/// `Group`s are a way to organize users and posts (and thus events). They can be used for many purposes,
class Group extends $pb.GeneratedMessage {
  factory Group({
    $core.String? id,
    $core.String? name,
    $core.String? shortname,
    $core.String? description,
    $0.MediaReference? avatar,
    $core.Iterable<$3.Permission>? defaultMembershipPermissions,
    $4.Moderation? defaultMembershipModeration,
    $4.Moderation? defaultPostModeration,
    $4.Moderation? defaultEventModeration,
    $4.Visibility? visibility,
    $core.int? memberCount,
    $core.int? postCount,
    $core.int? eventCount,
    $core.Iterable<$3.Permission>? nonMemberPermissions,
    $1.Membership? currentUserMembership,
    $2.Timestamp? createdAt,
    $2.Timestamp? updatedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (shortname != null) result.shortname = shortname;
    if (description != null) result.description = description;
    if (avatar != null) result.avatar = avatar;
    if (defaultMembershipPermissions != null) result.defaultMembershipPermissions.addAll(defaultMembershipPermissions);
    if (defaultMembershipModeration != null) result.defaultMembershipModeration = defaultMembershipModeration;
    if (defaultPostModeration != null) result.defaultPostModeration = defaultPostModeration;
    if (defaultEventModeration != null) result.defaultEventModeration = defaultEventModeration;
    if (visibility != null) result.visibility = visibility;
    if (memberCount != null) result.memberCount = memberCount;
    if (postCount != null) result.postCount = postCount;
    if (eventCount != null) result.eventCount = eventCount;
    if (nonMemberPermissions != null) result.nonMemberPermissions.addAll(nonMemberPermissions);
    if (currentUserMembership != null) result.currentUserMembership = currentUserMembership;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  Group._();

  factory Group.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory Group.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Group', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'shortname')
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..aOM<$0.MediaReference>(5, _omitFieldNames ? '' : 'avatar', subBuilder: $0.MediaReference.create)
    ..pc<$3.Permission>(6, _omitFieldNames ? '' : 'defaultMembershipPermissions', $pb.PbFieldType.KE, valueOf: $3.Permission.valueOf, enumValues: $3.Permission.values, defaultEnumValue: $3.Permission.PERMISSION_UNKNOWN)
    ..e<$4.Moderation>(7, _omitFieldNames ? '' : 'defaultMembershipModeration', $pb.PbFieldType.OE, defaultOrMaker: $4.Moderation.MODERATION_UNKNOWN, valueOf: $4.Moderation.valueOf, enumValues: $4.Moderation.values)
    ..e<$4.Moderation>(8, _omitFieldNames ? '' : 'defaultPostModeration', $pb.PbFieldType.OE, defaultOrMaker: $4.Moderation.MODERATION_UNKNOWN, valueOf: $4.Moderation.valueOf, enumValues: $4.Moderation.values)
    ..e<$4.Moderation>(9, _omitFieldNames ? '' : 'defaultEventModeration', $pb.PbFieldType.OE, defaultOrMaker: $4.Moderation.MODERATION_UNKNOWN, valueOf: $4.Moderation.valueOf, enumValues: $4.Moderation.values)
    ..e<$4.Visibility>(10, _omitFieldNames ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $4.Visibility.VISIBILITY_UNKNOWN, valueOf: $4.Visibility.valueOf, enumValues: $4.Visibility.values)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'memberCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'postCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'eventCount', $pb.PbFieldType.OU3)
    ..pc<$3.Permission>(18, _omitFieldNames ? '' : 'nonMemberPermissions', $pb.PbFieldType.KE, valueOf: $3.Permission.valueOf, enumValues: $3.Permission.values, defaultEnumValue: $3.Permission.PERMISSION_UNKNOWN)
    ..aOM<$1.Membership>(19, _omitFieldNames ? '' : 'currentUserMembership', subBuilder: $1.Membership.create)
    ..aOM<$2.Timestamp>(20, _omitFieldNames ? '' : 'createdAt', subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(21, _omitFieldNames ? '' : 'updatedAt', subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Group clone() => Group()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Group copyWith(void Function(Group) updates) => super.copyWith((message) => updates(message as Group)) as Group;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Group create() => Group._();
  @$core.override
  Group createEmptyInstance() => create();
  static $pb.PbList<Group> createRepeated() => $pb.PbList<Group>();
  @$core.pragma('dart2js:noInline')
  static Group getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Group>(create);
  static Group? _defaultInstance;

  /// The group's unique ID.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Mutable name of the group. Must be unique, such that the derived `shortname` is also unique.
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// Immutable shortname of the group. Derived from changes to `name` when the `Group` is updated.
  @$pb.TagNumber(3)
  $core.String get shortname => $_getSZ(2);
  @$pb.TagNumber(3)
  set shortname($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasShortname() => $_has(2);
  @$pb.TagNumber(3)
  void clearShortname() => $_clearField(3);

  /// A description of the group.
  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(3);
  @$pb.TagNumber(4)
  set description($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearDescription() => $_clearField(4);

  /// An avatar for the group.
  @$pb.TagNumber(5)
  $0.MediaReference get avatar => $_getN(4);
  @$pb.TagNumber(5)
  set avatar($0.MediaReference value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAvatar() => $_has(4);
  @$pb.TagNumber(5)
  void clearAvatar() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.MediaReference ensureAvatar() => $_ensure(4);

  /// The default permissions for new members of the group.
  @$pb.TagNumber(6)
  $pb.PbList<$3.Permission> get defaultMembershipPermissions => $_getList(5);

  /// The default moderation for new members of the group.
  /// Valid values are PENDING (requires a moderator to let you join) and UNMODERATED.
  @$pb.TagNumber(7)
  $4.Moderation get defaultMembershipModeration => $_getN(6);
  @$pb.TagNumber(7)
  set defaultMembershipModeration($4.Moderation value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasDefaultMembershipModeration() => $_has(6);
  @$pb.TagNumber(7)
  void clearDefaultMembershipModeration() => $_clearField(7);

  /// The default moderation for new posts in the group.
  @$pb.TagNumber(8)
  $4.Moderation get defaultPostModeration => $_getN(7);
  @$pb.TagNumber(8)
  set defaultPostModeration($4.Moderation value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasDefaultPostModeration() => $_has(7);
  @$pb.TagNumber(8)
  void clearDefaultPostModeration() => $_clearField(8);

  /// The default moderation for new events in the group.
  @$pb.TagNumber(9)
  $4.Moderation get defaultEventModeration => $_getN(8);
  @$pb.TagNumber(9)
  set defaultEventModeration($4.Moderation value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasDefaultEventModeration() => $_has(8);
  @$pb.TagNumber(9)
  void clearDefaultEventModeration() => $_clearField(9);

  /// LIMITED visibility groups are only visible to members. PRIVATE groups are only
  /// visibile to users with the ADMIN group permission.
  @$pb.TagNumber(10)
  $4.Visibility get visibility => $_getN(9);
  @$pb.TagNumber(10)
  set visibility($4.Visibility value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasVisibility() => $_has(9);
  @$pb.TagNumber(10)
  void clearVisibility() => $_clearField(10);

  /// The number of members in the group.
  @$pb.TagNumber(11)
  $core.int get memberCount => $_getIZ(10);
  @$pb.TagNumber(11)
  set memberCount($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasMemberCount() => $_has(10);
  @$pb.TagNumber(11)
  void clearMemberCount() => $_clearField(11);

  /// The number of posts in the group.
  @$pb.TagNumber(12)
  $core.int get postCount => $_getIZ(11);
  @$pb.TagNumber(12)
  set postCount($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPostCount() => $_has(11);
  @$pb.TagNumber(12)
  void clearPostCount() => $_clearField(12);

  /// The number of events in the group.
  @$pb.TagNumber(13)
  $core.int get eventCount => $_getIZ(12);
  @$pb.TagNumber(13)
  set eventCount($core.int value) => $_setUnsignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasEventCount() => $_has(12);
  @$pb.TagNumber(13)
  void clearEventCount() => $_clearField(13);

  /// The permissions given to non-members of the group.
  @$pb.TagNumber(18)
  $pb.PbList<$3.Permission> get nonMemberPermissions => $_getList(13);

  /// The membership for the current user, if any.
  @$pb.TagNumber(19)
  $1.Membership get currentUserMembership => $_getN(14);
  @$pb.TagNumber(19)
  set currentUserMembership($1.Membership value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasCurrentUserMembership() => $_has(14);
  @$pb.TagNumber(19)
  void clearCurrentUserMembership() => $_clearField(19);
  @$pb.TagNumber(19)
  $1.Membership ensureCurrentUserMembership() => $_ensure(14);

  /// The time the group was created.
  @$pb.TagNumber(20)
  $2.Timestamp get createdAt => $_getN(15);
  @$pb.TagNumber(20)
  set createdAt($2.Timestamp value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedAt() => $_has(15);
  @$pb.TagNumber(20)
  void clearCreatedAt() => $_clearField(20);
  @$pb.TagNumber(20)
  $2.Timestamp ensureCreatedAt() => $_ensure(15);

  /// The time the group was last updated.
  @$pb.TagNumber(21)
  $2.Timestamp get updatedAt => $_getN(16);
  @$pb.TagNumber(21)
  set updatedAt($2.Timestamp value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedAt() => $_has(16);
  @$pb.TagNumber(21)
  void clearUpdatedAt() => $_clearField(21);
  @$pb.TagNumber(21)
  $2.Timestamp ensureUpdatedAt() => $_ensure(16);
}

/// Request to get a group or groups by name or ID.
class GetGroupsRequest extends $pb.GeneratedMessage {
  factory GetGroupsRequest({
    $core.String? groupId,
    $core.String? groupName,
    $core.String? groupShortname,
    GroupListingType? listingType,
    $core.int? page,
  }) {
    final result = create();
    if (groupId != null) result.groupId = groupId;
    if (groupName != null) result.groupName = groupName;
    if (groupShortname != null) result.groupShortname = groupShortname;
    if (listingType != null) result.listingType = listingType;
    if (page != null) result.page = page;
    return result;
  }

  GetGroupsRequest._();

  factory GetGroupsRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetGroupsRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetGroupsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aOS(2, _omitFieldNames ? '' : 'groupName')
    ..aOS(3, _omitFieldNames ? '' : 'groupShortname')
    ..e<GroupListingType>(10, _omitFieldNames ? '' : 'listingType', $pb.PbFieldType.OE, defaultOrMaker: GroupListingType.ALL_GROUPS, valueOf: GroupListingType.valueOf, enumValues: GroupListingType.values)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'page', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupsRequest clone() => GetGroupsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupsRequest copyWith(void Function(GetGroupsRequest) updates) => super.copyWith((message) => updates(message as GetGroupsRequest)) as GetGroupsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetGroupsRequest create() => GetGroupsRequest._();
  @$core.override
  GetGroupsRequest createEmptyInstance() => create();
  static $pb.PbList<GetGroupsRequest> createRepeated() => $pb.PbList<GetGroupsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetGroupsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetGroupsRequest>(create);
  static GetGroupsRequest? _defaultInstance;

  /// The ID of the group to get.
  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => $_clearField(1);

  /// The name of the group to get.
  @$pb.TagNumber(2)
  $core.String get groupName => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGroupName() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupName() => $_clearField(2);

  /// The shortname of the group to get.
  /// Group shortname search is case-insensitive.
  @$pb.TagNumber(3)
  $core.String get groupShortname => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupShortname($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGroupShortname() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupShortname() => $_clearField(3);

  /// The group listing type.
  @$pb.TagNumber(10)
  GroupListingType get listingType => $_getN(3);
  @$pb.TagNumber(10)
  set listingType(GroupListingType value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasListingType() => $_has(3);
  @$pb.TagNumber(10)
  void clearListingType() => $_clearField(10);

  /// The page of results to get.
  @$pb.TagNumber(11)
  $core.int get page => $_getIZ(4);
  @$pb.TagNumber(11)
  set page($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(11)
  $core.bool hasPage() => $_has(4);
  @$pb.TagNumber(11)
  void clearPage() => $_clearField(11);
}

/// Response to a GetGroupsRequest.
class GetGroupsResponse extends $pb.GeneratedMessage {
  factory GetGroupsResponse({
    $core.Iterable<Group>? groups,
    $core.bool? hasNextPage,
  }) {
    final result = create();
    if (groups != null) result.groups.addAll(groups);
    if (hasNextPage != null) result.hasNextPage = hasNextPage;
    return result;
  }

  GetGroupsResponse._();

  factory GetGroupsResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetGroupsResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetGroupsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Group>(1, _omitFieldNames ? '' : 'groups', $pb.PbFieldType.PM, subBuilder: Group.create)
    ..aOB(2, _omitFieldNames ? '' : 'hasNextPage')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupsResponse clone() => GetGroupsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupsResponse copyWith(void Function(GetGroupsResponse) updates) => super.copyWith((message) => updates(message as GetGroupsResponse)) as GetGroupsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetGroupsResponse create() => GetGroupsResponse._();
  @$core.override
  GetGroupsResponse createEmptyInstance() => create();
  static $pb.PbList<GetGroupsResponse> createRepeated() => $pb.PbList<GetGroupsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetGroupsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetGroupsResponse>(create);
  static GetGroupsResponse? _defaultInstance;

  /// The groups that matched the request.
  @$pb.TagNumber(1)
  $pb.PbList<Group> get groups => $_getList(0);

  /// Whether there are more groups to get.
  @$pb.TagNumber(2)
  $core.bool get hasNextPage => $_getBF(1);
  @$pb.TagNumber(2)
  set hasNextPage($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHasNextPage() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasNextPage() => $_clearField(2);
}

/// Used when fetching group members using the `GetMembers` RPC.
class Member extends $pb.GeneratedMessage {
  factory Member({
    $1.User? user,
    $1.Membership? membership,
  }) {
    final result = create();
    if (user != null) result.user = user;
    if (membership != null) result.membership = membership;
    return result;
  }

  Member._();

  factory Member.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory Member.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Member', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOM<$1.User>(1, _omitFieldNames ? '' : 'user', subBuilder: $1.User.create)
    ..aOM<$1.Membership>(2, _omitFieldNames ? '' : 'membership', subBuilder: $1.Membership.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Member clone() => Member()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Member copyWith(void Function(Member) updates) => super.copyWith((message) => updates(message as Member)) as Member;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Member create() => Member._();
  @$core.override
  Member createEmptyInstance() => create();
  static $pb.PbList<Member> createRepeated() => $pb.PbList<Member>();
  @$core.pragma('dart2js:noInline')
  static Member getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Member>(create);
  static Member? _defaultInstance;

  /// The user.
  @$pb.TagNumber(1)
  $1.User get user => $_getN(0);
  @$pb.TagNumber(1)
  set user($1.User value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.User ensureUser() => $_ensure(0);

  /// The user's membership (or join request, or invitation, or both) in the group.
  @$pb.TagNumber(2)
  $1.Membership get membership => $_getN(1);
  @$pb.TagNumber(2)
  set membership($1.Membership value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMembership() => $_has(1);
  @$pb.TagNumber(2)
  void clearMembership() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Membership ensureMembership() => $_ensure(1);
}

/// Request to get members of a group.
class GetMembersRequest extends $pb.GeneratedMessage {
  factory GetMembersRequest({
    $core.String? groupId,
    $core.String? username,
    $4.Moderation? groupModeration,
    $core.int? page,
  }) {
    final result = create();
    if (groupId != null) result.groupId = groupId;
    if (username != null) result.username = username;
    if (groupModeration != null) result.groupModeration = groupModeration;
    if (page != null) result.page = page;
    return result;
  }

  GetMembersRequest._();

  factory GetMembersRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetMembersRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetMembersRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..e<$4.Moderation>(3, _omitFieldNames ? '' : 'groupModeration', $pb.PbFieldType.OE, defaultOrMaker: $4.Moderation.MODERATION_UNKNOWN, valueOf: $4.Moderation.valueOf, enumValues: $4.Moderation.values)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'page', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMembersRequest clone() => GetMembersRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMembersRequest copyWith(void Function(GetMembersRequest) updates) => super.copyWith((message) => updates(message as GetMembersRequest)) as GetMembersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetMembersRequest create() => GetMembersRequest._();
  @$core.override
  GetMembersRequest createEmptyInstance() => create();
  static $pb.PbList<GetMembersRequest> createRepeated() => $pb.PbList<GetMembersRequest>();
  @$core.pragma('dart2js:noInline')
  static GetMembersRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetMembersRequest>(create);
  static GetMembersRequest? _defaultInstance;

  /// The ID of the group to get members of.
  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => $_clearField(1);

  /// The username of the members to search for.
  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  /// The membership status to filter members by.
  /// If not specified, all members are returned.
  @$pb.TagNumber(3)
  $4.Moderation get groupModeration => $_getN(2);
  @$pb.TagNumber(3)
  set groupModeration($4.Moderation value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGroupModeration() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupModeration() => $_clearField(3);

  /// The page of results to get.
  @$pb.TagNumber(10)
  $core.int get page => $_getIZ(3);
  @$pb.TagNumber(10)
  set page($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(10)
  $core.bool hasPage() => $_has(3);
  @$pb.TagNumber(10)
  void clearPage() => $_clearField(10);
}

/// Response to a GetMembersRequest.
class GetMembersResponse extends $pb.GeneratedMessage {
  factory GetMembersResponse({
    $core.Iterable<Member>? members,
    $core.bool? hasNextPage,
  }) {
    final result = create();
    if (members != null) result.members.addAll(members);
    if (hasNextPage != null) result.hasNextPage = hasNextPage;
    return result;
  }

  GetMembersResponse._();

  factory GetMembersResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory GetMembersResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetMembersResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<Member>(1, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PM, subBuilder: Member.create)
    ..aOB(2, _omitFieldNames ? '' : 'hasNextPage')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMembersResponse clone() => GetMembersResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMembersResponse copyWith(void Function(GetMembersResponse) updates) => super.copyWith((message) => updates(message as GetMembersResponse)) as GetMembersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetMembersResponse create() => GetMembersResponse._();
  @$core.override
  GetMembersResponse createEmptyInstance() => create();
  static $pb.PbList<GetMembersResponse> createRepeated() => $pb.PbList<GetMembersResponse>();
  @$core.pragma('dart2js:noInline')
  static GetMembersResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetMembersResponse>(create);
  static GetMembersResponse? _defaultInstance;

  /// The members that matched the request.
  @$pb.TagNumber(1)
  $pb.PbList<Member> get members => $_getList(0);

  /// Whether there are more members to get.
  @$pb.TagNumber(2)
  $core.bool get hasNextPage => $_getBF(1);
  @$pb.TagNumber(2)
  set hasNextPage($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHasNextPage() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasNextPage() => $_clearField(2);
}


const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
