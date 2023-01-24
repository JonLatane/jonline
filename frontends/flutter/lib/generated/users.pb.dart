///
//  Generated code. Do not modify.
//  source: users.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $7;

import 'permissions.pbenum.dart' as $8;
import 'visibility_moderation.pbenum.dart' as $9;
import 'users.pbenum.dart';

export 'users.pbenum.dart';

class User extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'User', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'username')
    ..aOM<ContactMethod>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'email', subBuilder: ContactMethod.create)
    ..aOM<ContactMethod>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'phone', subBuilder: ContactMethod.create)
    ..pc<$8.Permission>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'permissions', $pb.PbFieldType.KE, valueOf: $8.Permission.valueOf, enumValues: $8.Permission.values, defaultEnumValue: $8.Permission.PERMISSION_UNKNOWN)
    ..a<$core.List<$core.int>>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'avatar', $pb.PbFieldType.OY)
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'bio')
    ..e<$9.Visibility>(20, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $9.Visibility.VISIBILITY_UNKNOWN, valueOf: $9.Visibility.valueOf, enumValues: $9.Visibility.values)
    ..e<$9.Moderation>(21, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'moderation', $pb.PbFieldType.OE, defaultOrMaker: $9.Moderation.MODERATION_UNKNOWN, valueOf: $9.Moderation.valueOf, enumValues: $9.Moderation.values)
    ..e<$9.Moderation>(30, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'defaultFollowModeration', $pb.PbFieldType.OE, defaultOrMaker: $9.Moderation.MODERATION_UNKNOWN, valueOf: $9.Moderation.valueOf, enumValues: $9.Moderation.values)
    ..a<$core.int>(31, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'followerCount', $pb.PbFieldType.O3)
    ..a<$core.int>(32, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'followingCount', $pb.PbFieldType.O3)
    ..a<$core.int>(33, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupCount', $pb.PbFieldType.O3)
    ..a<$core.int>(34, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'postCount', $pb.PbFieldType.O3)
    ..a<$core.int>(35, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'responseCount', $pb.PbFieldType.O3)
    ..aOM<Follow>(50, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'currentUserFollow', subBuilder: Follow.create)
    ..aOM<Follow>(51, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'targetCurrentUserFollow', subBuilder: Follow.create)
    ..aOM<Membership>(52, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'currentGroupMembership', subBuilder: Membership.create)
    ..aOM<$7.Timestamp>(100, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createdAt', subBuilder: $7.Timestamp.create)
    ..aOM<$7.Timestamp>(101, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updatedAt', subBuilder: $7.Timestamp.create)
    ..hasRequiredFields = false
  ;

  User._() : super();
  factory User({
    $core.String? id,
    $core.String? username,
    ContactMethod? email,
    ContactMethod? phone,
    $core.Iterable<$8.Permission>? permissions,
    $core.List<$core.int>? avatar,
    $core.String? bio,
    $9.Visibility? visibility,
    $9.Moderation? moderation,
    $9.Moderation? defaultFollowModeration,
    $core.int? followerCount,
    $core.int? followingCount,
    $core.int? groupCount,
    $core.int? postCount,
    $core.int? responseCount,
    Follow? currentUserFollow,
    Follow? targetCurrentUserFollow,
    Membership? currentGroupMembership,
    $7.Timestamp? createdAt,
    $7.Timestamp? updatedAt,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (username != null) {
      _result.username = username;
    }
    if (email != null) {
      _result.email = email;
    }
    if (phone != null) {
      _result.phone = phone;
    }
    if (permissions != null) {
      _result.permissions.addAll(permissions);
    }
    if (avatar != null) {
      _result.avatar = avatar;
    }
    if (bio != null) {
      _result.bio = bio;
    }
    if (visibility != null) {
      _result.visibility = visibility;
    }
    if (moderation != null) {
      _result.moderation = moderation;
    }
    if (defaultFollowModeration != null) {
      _result.defaultFollowModeration = defaultFollowModeration;
    }
    if (followerCount != null) {
      _result.followerCount = followerCount;
    }
    if (followingCount != null) {
      _result.followingCount = followingCount;
    }
    if (groupCount != null) {
      _result.groupCount = groupCount;
    }
    if (postCount != null) {
      _result.postCount = postCount;
    }
    if (responseCount != null) {
      _result.responseCount = responseCount;
    }
    if (currentUserFollow != null) {
      _result.currentUserFollow = currentUserFollow;
    }
    if (targetCurrentUserFollow != null) {
      _result.targetCurrentUserFollow = targetCurrentUserFollow;
    }
    if (currentGroupMembership != null) {
      _result.currentGroupMembership = currentGroupMembership;
    }
    if (createdAt != null) {
      _result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      _result.updatedAt = updatedAt;
    }
    return _result;
  }
  factory User.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory User.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  User clone() => User()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  User copyWith(void Function(User) updates) => super.copyWith((message) => updates(message as User)) as User; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static User create() => User._();
  User createEmptyInstance() => create();
  static $pb.PbList<User> createRepeated() => $pb.PbList<User>();
  @$core.pragma('dart2js:noInline')
  static User getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<User>(create);
  static User? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => clearField(2);

  @$pb.TagNumber(3)
  ContactMethod get email => $_getN(2);
  @$pb.TagNumber(3)
  set email(ContactMethod v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmail() => clearField(3);
  @$pb.TagNumber(3)
  ContactMethod ensureEmail() => $_ensure(2);

  @$pb.TagNumber(4)
  ContactMethod get phone => $_getN(3);
  @$pb.TagNumber(4)
  set phone(ContactMethod v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasPhone() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhone() => clearField(4);
  @$pb.TagNumber(4)
  ContactMethod ensurePhone() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.List<$8.Permission> get permissions => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<$core.int> get avatar => $_getN(5);
  @$pb.TagNumber(6)
  set avatar($core.List<$core.int> v) { $_setBytes(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasAvatar() => $_has(5);
  @$pb.TagNumber(6)
  void clearAvatar() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get bio => $_getSZ(6);
  @$pb.TagNumber(7)
  set bio($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasBio() => $_has(6);
  @$pb.TagNumber(7)
  void clearBio() => clearField(7);

  @$pb.TagNumber(20)
  $9.Visibility get visibility => $_getN(7);
  @$pb.TagNumber(20)
  set visibility($9.Visibility v) { setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasVisibility() => $_has(7);
  @$pb.TagNumber(20)
  void clearVisibility() => clearField(20);

  @$pb.TagNumber(21)
  $9.Moderation get moderation => $_getN(8);
  @$pb.TagNumber(21)
  set moderation($9.Moderation v) { setField(21, v); }
  @$pb.TagNumber(21)
  $core.bool hasModeration() => $_has(8);
  @$pb.TagNumber(21)
  void clearModeration() => clearField(21);

  @$pb.TagNumber(30)
  $9.Moderation get defaultFollowModeration => $_getN(9);
  @$pb.TagNumber(30)
  set defaultFollowModeration($9.Moderation v) { setField(30, v); }
  @$pb.TagNumber(30)
  $core.bool hasDefaultFollowModeration() => $_has(9);
  @$pb.TagNumber(30)
  void clearDefaultFollowModeration() => clearField(30);

  @$pb.TagNumber(31)
  $core.int get followerCount => $_getIZ(10);
  @$pb.TagNumber(31)
  set followerCount($core.int v) { $_setSignedInt32(10, v); }
  @$pb.TagNumber(31)
  $core.bool hasFollowerCount() => $_has(10);
  @$pb.TagNumber(31)
  void clearFollowerCount() => clearField(31);

  @$pb.TagNumber(32)
  $core.int get followingCount => $_getIZ(11);
  @$pb.TagNumber(32)
  set followingCount($core.int v) { $_setSignedInt32(11, v); }
  @$pb.TagNumber(32)
  $core.bool hasFollowingCount() => $_has(11);
  @$pb.TagNumber(32)
  void clearFollowingCount() => clearField(32);

  @$pb.TagNumber(33)
  $core.int get groupCount => $_getIZ(12);
  @$pb.TagNumber(33)
  set groupCount($core.int v) { $_setSignedInt32(12, v); }
  @$pb.TagNumber(33)
  $core.bool hasGroupCount() => $_has(12);
  @$pb.TagNumber(33)
  void clearGroupCount() => clearField(33);

  @$pb.TagNumber(34)
  $core.int get postCount => $_getIZ(13);
  @$pb.TagNumber(34)
  set postCount($core.int v) { $_setSignedInt32(13, v); }
  @$pb.TagNumber(34)
  $core.bool hasPostCount() => $_has(13);
  @$pb.TagNumber(34)
  void clearPostCount() => clearField(34);

  @$pb.TagNumber(35)
  $core.int get responseCount => $_getIZ(14);
  @$pb.TagNumber(35)
  set responseCount($core.int v) { $_setSignedInt32(14, v); }
  @$pb.TagNumber(35)
  $core.bool hasResponseCount() => $_has(14);
  @$pb.TagNumber(35)
  void clearResponseCount() => clearField(35);

  @$pb.TagNumber(50)
  Follow get currentUserFollow => $_getN(15);
  @$pb.TagNumber(50)
  set currentUserFollow(Follow v) { setField(50, v); }
  @$pb.TagNumber(50)
  $core.bool hasCurrentUserFollow() => $_has(15);
  @$pb.TagNumber(50)
  void clearCurrentUserFollow() => clearField(50);
  @$pb.TagNumber(50)
  Follow ensureCurrentUserFollow() => $_ensure(15);

  @$pb.TagNumber(51)
  Follow get targetCurrentUserFollow => $_getN(16);
  @$pb.TagNumber(51)
  set targetCurrentUserFollow(Follow v) { setField(51, v); }
  @$pb.TagNumber(51)
  $core.bool hasTargetCurrentUserFollow() => $_has(16);
  @$pb.TagNumber(51)
  void clearTargetCurrentUserFollow() => clearField(51);
  @$pb.TagNumber(51)
  Follow ensureTargetCurrentUserFollow() => $_ensure(16);

  @$pb.TagNumber(52)
  Membership get currentGroupMembership => $_getN(17);
  @$pb.TagNumber(52)
  set currentGroupMembership(Membership v) { setField(52, v); }
  @$pb.TagNumber(52)
  $core.bool hasCurrentGroupMembership() => $_has(17);
  @$pb.TagNumber(52)
  void clearCurrentGroupMembership() => clearField(52);
  @$pb.TagNumber(52)
  Membership ensureCurrentGroupMembership() => $_ensure(17);

  @$pb.TagNumber(100)
  $7.Timestamp get createdAt => $_getN(18);
  @$pb.TagNumber(100)
  set createdAt($7.Timestamp v) { setField(100, v); }
  @$pb.TagNumber(100)
  $core.bool hasCreatedAt() => $_has(18);
  @$pb.TagNumber(100)
  void clearCreatedAt() => clearField(100);
  @$pb.TagNumber(100)
  $7.Timestamp ensureCreatedAt() => $_ensure(18);

  @$pb.TagNumber(101)
  $7.Timestamp get updatedAt => $_getN(19);
  @$pb.TagNumber(101)
  set updatedAt($7.Timestamp v) { setField(101, v); }
  @$pb.TagNumber(101)
  $core.bool hasUpdatedAt() => $_has(19);
  @$pb.TagNumber(101)
  void clearUpdatedAt() => clearField(101);
  @$pb.TagNumber(101)
  $7.Timestamp ensureUpdatedAt() => $_ensure(19);
}

class Follow extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Follow', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'targetUserId')
    ..e<$9.Moderation>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'targetUserModeration', $pb.PbFieldType.OE, defaultOrMaker: $9.Moderation.MODERATION_UNKNOWN, valueOf: $9.Moderation.valueOf, enumValues: $9.Moderation.values)
    ..aOM<$7.Timestamp>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createdAt', subBuilder: $7.Timestamp.create)
    ..aOM<$7.Timestamp>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updatedAt', subBuilder: $7.Timestamp.create)
    ..hasRequiredFields = false
  ;

  Follow._() : super();
  factory Follow({
    $core.String? userId,
    $core.String? targetUserId,
    $9.Moderation? targetUserModeration,
    $7.Timestamp? createdAt,
    $7.Timestamp? updatedAt,
  }) {
    final _result = create();
    if (userId != null) {
      _result.userId = userId;
    }
    if (targetUserId != null) {
      _result.targetUserId = targetUserId;
    }
    if (targetUserModeration != null) {
      _result.targetUserModeration = targetUserModeration;
    }
    if (createdAt != null) {
      _result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      _result.updatedAt = updatedAt;
    }
    return _result;
  }
  factory Follow.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Follow.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Follow clone() => Follow()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Follow copyWith(void Function(Follow) updates) => super.copyWith((message) => updates(message as Follow)) as Follow; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Follow create() => Follow._();
  Follow createEmptyInstance() => create();
  static $pb.PbList<Follow> createRepeated() => $pb.PbList<Follow>();
  @$core.pragma('dart2js:noInline')
  static Follow getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Follow>(create);
  static Follow? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get targetUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set targetUserId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTargetUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetUserId() => clearField(2);

  @$pb.TagNumber(3)
  $9.Moderation get targetUserModeration => $_getN(2);
  @$pb.TagNumber(3)
  set targetUserModeration($9.Moderation v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasTargetUserModeration() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetUserModeration() => clearField(3);

  @$pb.TagNumber(4)
  $7.Timestamp get createdAt => $_getN(3);
  @$pb.TagNumber(4)
  set createdAt($7.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => clearField(4);
  @$pb.TagNumber(4)
  $7.Timestamp ensureCreatedAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $7.Timestamp get updatedAt => $_getN(4);
  @$pb.TagNumber(5)
  set updatedAt($7.Timestamp v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUpdatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearUpdatedAt() => clearField(5);
  @$pb.TagNumber(5)
  $7.Timestamp ensureUpdatedAt() => $_ensure(4);
}

class Membership extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Membership', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..pc<$8.Permission>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'permissions', $pb.PbFieldType.KE, valueOf: $8.Permission.valueOf, enumValues: $8.Permission.values, defaultEnumValue: $8.Permission.PERMISSION_UNKNOWN)
    ..e<$9.Moderation>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupModeration', $pb.PbFieldType.OE, defaultOrMaker: $9.Moderation.MODERATION_UNKNOWN, valueOf: $9.Moderation.valueOf, enumValues: $9.Moderation.values)
    ..e<$9.Moderation>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userModeration', $pb.PbFieldType.OE, defaultOrMaker: $9.Moderation.MODERATION_UNKNOWN, valueOf: $9.Moderation.valueOf, enumValues: $9.Moderation.values)
    ..aOM<$7.Timestamp>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createdAt', subBuilder: $7.Timestamp.create)
    ..aOM<$7.Timestamp>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updatedAt', subBuilder: $7.Timestamp.create)
    ..hasRequiredFields = false
  ;

  Membership._() : super();
  factory Membership({
    $core.String? userId,
    $core.String? groupId,
    $core.Iterable<$8.Permission>? permissions,
    $9.Moderation? groupModeration,
    $9.Moderation? userModeration,
    $7.Timestamp? createdAt,
    $7.Timestamp? updatedAt,
  }) {
    final _result = create();
    if (userId != null) {
      _result.userId = userId;
    }
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (permissions != null) {
      _result.permissions.addAll(permissions);
    }
    if (groupModeration != null) {
      _result.groupModeration = groupModeration;
    }
    if (userModeration != null) {
      _result.userModeration = userModeration;
    }
    if (createdAt != null) {
      _result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      _result.updatedAt = updatedAt;
    }
    return _result;
  }
  factory Membership.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Membership.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Membership clone() => Membership()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Membership copyWith(void Function(Membership) updates) => super.copyWith((message) => updates(message as Membership)) as Membership; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Membership create() => Membership._();
  Membership createEmptyInstance() => create();
  static $pb.PbList<Membership> createRepeated() => $pb.PbList<Membership>();
  @$core.pragma('dart2js:noInline')
  static Membership getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Membership>(create);
  static Membership? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupId() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$8.Permission> get permissions => $_getList(2);

  @$pb.TagNumber(4)
  $9.Moderation get groupModeration => $_getN(3);
  @$pb.TagNumber(4)
  set groupModeration($9.Moderation v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasGroupModeration() => $_has(3);
  @$pb.TagNumber(4)
  void clearGroupModeration() => clearField(4);

  @$pb.TagNumber(5)
  $9.Moderation get userModeration => $_getN(4);
  @$pb.TagNumber(5)
  set userModeration($9.Moderation v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUserModeration() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserModeration() => clearField(5);

  @$pb.TagNumber(6)
  $7.Timestamp get createdAt => $_getN(5);
  @$pb.TagNumber(6)
  set createdAt($7.Timestamp v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => clearField(6);
  @$pb.TagNumber(6)
  $7.Timestamp ensureCreatedAt() => $_ensure(5);

  @$pb.TagNumber(7)
  $7.Timestamp get updatedAt => $_getN(6);
  @$pb.TagNumber(7)
  set updatedAt($7.Timestamp v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasUpdatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdatedAt() => clearField(7);
  @$pb.TagNumber(7)
  $7.Timestamp ensureUpdatedAt() => $_ensure(6);
}

class ContactMethod extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ContactMethod', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..e<$9.Visibility>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $9.Visibility.VISIBILITY_UNKNOWN, valueOf: $9.Visibility.valueOf, enumValues: $9.Visibility.values)
    ..hasRequiredFields = false
  ;

  ContactMethod._() : super();
  factory ContactMethod({
    $core.String? value,
    $9.Visibility? visibility,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    if (visibility != null) {
      _result.visibility = visibility;
    }
    return _result;
  }
  factory ContactMethod.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ContactMethod.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ContactMethod clone() => ContactMethod()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ContactMethod copyWith(void Function(ContactMethod) updates) => super.copyWith((message) => updates(message as ContactMethod)) as ContactMethod; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ContactMethod create() => ContactMethod._();
  ContactMethod createEmptyInstance() => create();
  static $pb.PbList<ContactMethod> createRepeated() => $pb.PbList<ContactMethod>();
  @$core.pragma('dart2js:noInline')
  static ContactMethod getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContactMethod>(create);
  static ContactMethod? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);

  @$pb.TagNumber(2)
  $9.Visibility get visibility => $_getN(1);
  @$pb.TagNumber(2)
  set visibility($9.Visibility v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasVisibility() => $_has(1);
  @$pb.TagNumber(2)
  void clearVisibility() => clearField(2);
}

class GetUsersRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetUsersRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'username')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..a<$core.int>(99, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'page', $pb.PbFieldType.O3)
    ..e<UserListingType>(100, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'listingType', $pb.PbFieldType.OE, defaultOrMaker: UserListingType.EVERYONE, valueOf: UserListingType.valueOf, enumValues: UserListingType.values)
    ..hasRequiredFields = false
  ;

  GetUsersRequest._() : super();
  factory GetUsersRequest({
    $core.String? username,
    $core.String? userId,
    $core.int? page,
    UserListingType? listingType,
  }) {
    final _result = create();
    if (username != null) {
      _result.username = username;
    }
    if (userId != null) {
      _result.userId = userId;
    }
    if (page != null) {
      _result.page = page;
    }
    if (listingType != null) {
      _result.listingType = listingType;
    }
    return _result;
  }
  factory GetUsersRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetUsersRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetUsersRequest clone() => GetUsersRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetUsersRequest copyWith(void Function(GetUsersRequest) updates) => super.copyWith((message) => updates(message as GetUsersRequest)) as GetUsersRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetUsersRequest create() => GetUsersRequest._();
  GetUsersRequest createEmptyInstance() => create();
  static $pb.PbList<GetUsersRequest> createRepeated() => $pb.PbList<GetUsersRequest>();
  @$core.pragma('dart2js:noInline')
  static GetUsersRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetUsersRequest>(create);
  static GetUsersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => clearField(2);

  @$pb.TagNumber(99)
  $core.int get page => $_getIZ(2);
  @$pb.TagNumber(99)
  set page($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(99)
  $core.bool hasPage() => $_has(2);
  @$pb.TagNumber(99)
  void clearPage() => clearField(99);

  @$pb.TagNumber(100)
  UserListingType get listingType => $_getN(3);
  @$pb.TagNumber(100)
  set listingType(UserListingType v) { setField(100, v); }
  @$pb.TagNumber(100)
  $core.bool hasListingType() => $_has(3);
  @$pb.TagNumber(100)
  void clearListingType() => clearField(100);
}

class GetUsersResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetUsersResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<User>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'users', $pb.PbFieldType.PM, subBuilder: User.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hasNextPage')
    ..hasRequiredFields = false
  ;

  GetUsersResponse._() : super();
  factory GetUsersResponse({
    $core.Iterable<User>? users,
    $core.bool? hasNextPage,
  }) {
    final _result = create();
    if (users != null) {
      _result.users.addAll(users);
    }
    if (hasNextPage != null) {
      _result.hasNextPage = hasNextPage;
    }
    return _result;
  }
  factory GetUsersResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetUsersResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetUsersResponse clone() => GetUsersResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetUsersResponse copyWith(void Function(GetUsersResponse) updates) => super.copyWith((message) => updates(message as GetUsersResponse)) as GetUsersResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetUsersResponse create() => GetUsersResponse._();
  GetUsersResponse createEmptyInstance() => create();
  static $pb.PbList<GetUsersResponse> createRepeated() => $pb.PbList<GetUsersResponse>();
  @$core.pragma('dart2js:noInline')
  static GetUsersResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetUsersResponse>(create);
  static GetUsersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<User> get users => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get hasNextPage => $_getBF(1);
  @$pb.TagNumber(2)
  set hasNextPage($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasHasNextPage() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasNextPage() => clearField(2);
}

