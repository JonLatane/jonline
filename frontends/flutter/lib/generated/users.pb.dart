//
//  Generated code. Do not modify.
//  source: users.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'google/protobuf/timestamp.pb.dart' as $9;
import 'permissions.pbenum.dart' as $10;
import 'users.pbenum.dart';
import 'visibility_moderation.pbenum.dart' as $11;

export 'users.pbenum.dart';

class User extends $pb.GeneratedMessage {
  factory User() => create();
  User._() : super();
  factory User.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory User.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'User', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'realName')
    ..aOM<ContactMethod>(4, _omitFieldNames ? '' : 'email', subBuilder: ContactMethod.create)
    ..aOM<ContactMethod>(5, _omitFieldNames ? '' : 'phone', subBuilder: ContactMethod.create)
    ..pc<$10.Permission>(6, _omitFieldNames ? '' : 'permissions', $pb.PbFieldType.KE, valueOf: $10.Permission.valueOf, enumValues: $10.Permission.values, defaultEnumValue: $10.Permission.PERMISSION_UNKNOWN)
    ..aOS(7, _omitFieldNames ? '' : 'avatarMediaId')
    ..aOS(8, _omitFieldNames ? '' : 'bio')
    ..e<$11.Visibility>(20, _omitFieldNames ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $11.Visibility.VISIBILITY_UNKNOWN, valueOf: $11.Visibility.valueOf, enumValues: $11.Visibility.values)
    ..e<$11.Moderation>(21, _omitFieldNames ? '' : 'moderation', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Moderation>(30, _omitFieldNames ? '' : 'defaultFollowModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..a<$core.int>(31, _omitFieldNames ? '' : 'followerCount', $pb.PbFieldType.O3)
    ..a<$core.int>(32, _omitFieldNames ? '' : 'followingCount', $pb.PbFieldType.O3)
    ..a<$core.int>(33, _omitFieldNames ? '' : 'groupCount', $pb.PbFieldType.O3)
    ..a<$core.int>(34, _omitFieldNames ? '' : 'postCount', $pb.PbFieldType.O3)
    ..a<$core.int>(35, _omitFieldNames ? '' : 'responseCount', $pb.PbFieldType.O3)
    ..aOM<Follow>(50, _omitFieldNames ? '' : 'currentUserFollow', subBuilder: Follow.create)
    ..aOM<Follow>(51, _omitFieldNames ? '' : 'targetCurrentUserFollow', subBuilder: Follow.create)
    ..aOM<Membership>(52, _omitFieldNames ? '' : 'currentGroupMembership', subBuilder: Membership.create)
    ..aOM<$9.Timestamp>(100, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(101, _omitFieldNames ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  User clone() => User()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  User copyWith(void Function(User) updates) => super.copyWith((message) => updates(message as User)) as User;

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
  $core.String get realName => $_getSZ(2);
  @$pb.TagNumber(3)
  set realName($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRealName() => $_has(2);
  @$pb.TagNumber(3)
  void clearRealName() => clearField(3);

  @$pb.TagNumber(4)
  ContactMethod get email => $_getN(3);
  @$pb.TagNumber(4)
  set email(ContactMethod v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasEmail() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmail() => clearField(4);
  @$pb.TagNumber(4)
  ContactMethod ensureEmail() => $_ensure(3);

  @$pb.TagNumber(5)
  ContactMethod get phone => $_getN(4);
  @$pb.TagNumber(5)
  set phone(ContactMethod v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasPhone() => $_has(4);
  @$pb.TagNumber(5)
  void clearPhone() => clearField(5);
  @$pb.TagNumber(5)
  ContactMethod ensurePhone() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.List<$10.Permission> get permissions => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get avatarMediaId => $_getSZ(6);
  @$pb.TagNumber(7)
  set avatarMediaId($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasAvatarMediaId() => $_has(6);
  @$pb.TagNumber(7)
  void clearAvatarMediaId() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get bio => $_getSZ(7);
  @$pb.TagNumber(8)
  set bio($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasBio() => $_has(7);
  @$pb.TagNumber(8)
  void clearBio() => clearField(8);

  @$pb.TagNumber(20)
  $11.Visibility get visibility => $_getN(8);
  @$pb.TagNumber(20)
  set visibility($11.Visibility v) { setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasVisibility() => $_has(8);
  @$pb.TagNumber(20)
  void clearVisibility() => clearField(20);

  @$pb.TagNumber(21)
  $11.Moderation get moderation => $_getN(9);
  @$pb.TagNumber(21)
  set moderation($11.Moderation v) { setField(21, v); }
  @$pb.TagNumber(21)
  $core.bool hasModeration() => $_has(9);
  @$pb.TagNumber(21)
  void clearModeration() => clearField(21);

  @$pb.TagNumber(30)
  $11.Moderation get defaultFollowModeration => $_getN(10);
  @$pb.TagNumber(30)
  set defaultFollowModeration($11.Moderation v) { setField(30, v); }
  @$pb.TagNumber(30)
  $core.bool hasDefaultFollowModeration() => $_has(10);
  @$pb.TagNumber(30)
  void clearDefaultFollowModeration() => clearField(30);

  @$pb.TagNumber(31)
  $core.int get followerCount => $_getIZ(11);
  @$pb.TagNumber(31)
  set followerCount($core.int v) { $_setSignedInt32(11, v); }
  @$pb.TagNumber(31)
  $core.bool hasFollowerCount() => $_has(11);
  @$pb.TagNumber(31)
  void clearFollowerCount() => clearField(31);

  @$pb.TagNumber(32)
  $core.int get followingCount => $_getIZ(12);
  @$pb.TagNumber(32)
  set followingCount($core.int v) { $_setSignedInt32(12, v); }
  @$pb.TagNumber(32)
  $core.bool hasFollowingCount() => $_has(12);
  @$pb.TagNumber(32)
  void clearFollowingCount() => clearField(32);

  @$pb.TagNumber(33)
  $core.int get groupCount => $_getIZ(13);
  @$pb.TagNumber(33)
  set groupCount($core.int v) { $_setSignedInt32(13, v); }
  @$pb.TagNumber(33)
  $core.bool hasGroupCount() => $_has(13);
  @$pb.TagNumber(33)
  void clearGroupCount() => clearField(33);

  @$pb.TagNumber(34)
  $core.int get postCount => $_getIZ(14);
  @$pb.TagNumber(34)
  set postCount($core.int v) { $_setSignedInt32(14, v); }
  @$pb.TagNumber(34)
  $core.bool hasPostCount() => $_has(14);
  @$pb.TagNumber(34)
  void clearPostCount() => clearField(34);

  @$pb.TagNumber(35)
  $core.int get responseCount => $_getIZ(15);
  @$pb.TagNumber(35)
  set responseCount($core.int v) { $_setSignedInt32(15, v); }
  @$pb.TagNumber(35)
  $core.bool hasResponseCount() => $_has(15);
  @$pb.TagNumber(35)
  void clearResponseCount() => clearField(35);

  @$pb.TagNumber(50)
  Follow get currentUserFollow => $_getN(16);
  @$pb.TagNumber(50)
  set currentUserFollow(Follow v) { setField(50, v); }
  @$pb.TagNumber(50)
  $core.bool hasCurrentUserFollow() => $_has(16);
  @$pb.TagNumber(50)
  void clearCurrentUserFollow() => clearField(50);
  @$pb.TagNumber(50)
  Follow ensureCurrentUserFollow() => $_ensure(16);

  @$pb.TagNumber(51)
  Follow get targetCurrentUserFollow => $_getN(17);
  @$pb.TagNumber(51)
  set targetCurrentUserFollow(Follow v) { setField(51, v); }
  @$pb.TagNumber(51)
  $core.bool hasTargetCurrentUserFollow() => $_has(17);
  @$pb.TagNumber(51)
  void clearTargetCurrentUserFollow() => clearField(51);
  @$pb.TagNumber(51)
  Follow ensureTargetCurrentUserFollow() => $_ensure(17);

  @$pb.TagNumber(52)
  Membership get currentGroupMembership => $_getN(18);
  @$pb.TagNumber(52)
  set currentGroupMembership(Membership v) { setField(52, v); }
  @$pb.TagNumber(52)
  $core.bool hasCurrentGroupMembership() => $_has(18);
  @$pb.TagNumber(52)
  void clearCurrentGroupMembership() => clearField(52);
  @$pb.TagNumber(52)
  Membership ensureCurrentGroupMembership() => $_ensure(18);

  @$pb.TagNumber(100)
  $9.Timestamp get createdAt => $_getN(19);
  @$pb.TagNumber(100)
  set createdAt($9.Timestamp v) { setField(100, v); }
  @$pb.TagNumber(100)
  $core.bool hasCreatedAt() => $_has(19);
  @$pb.TagNumber(100)
  void clearCreatedAt() => clearField(100);
  @$pb.TagNumber(100)
  $9.Timestamp ensureCreatedAt() => $_ensure(19);

  @$pb.TagNumber(101)
  $9.Timestamp get updatedAt => $_getN(20);
  @$pb.TagNumber(101)
  set updatedAt($9.Timestamp v) { setField(101, v); }
  @$pb.TagNumber(101)
  $core.bool hasUpdatedAt() => $_has(20);
  @$pb.TagNumber(101)
  void clearUpdatedAt() => clearField(101);
  @$pb.TagNumber(101)
  $9.Timestamp ensureUpdatedAt() => $_ensure(20);
}

class Follow extends $pb.GeneratedMessage {
  factory Follow() => create();
  Follow._() : super();
  factory Follow.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Follow.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Follow', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'targetUserId')
    ..e<$11.Moderation>(3, _omitFieldNames ? '' : 'targetUserModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..aOM<$9.Timestamp>(4, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(5, _omitFieldNames ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Follow clone() => Follow()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Follow copyWith(void Function(Follow) updates) => super.copyWith((message) => updates(message as Follow)) as Follow;

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
  $11.Moderation get targetUserModeration => $_getN(2);
  @$pb.TagNumber(3)
  set targetUserModeration($11.Moderation v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasTargetUserModeration() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetUserModeration() => clearField(3);

  @$pb.TagNumber(4)
  $9.Timestamp get createdAt => $_getN(3);
  @$pb.TagNumber(4)
  set createdAt($9.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => clearField(4);
  @$pb.TagNumber(4)
  $9.Timestamp ensureCreatedAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $9.Timestamp get updatedAt => $_getN(4);
  @$pb.TagNumber(5)
  set updatedAt($9.Timestamp v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUpdatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearUpdatedAt() => clearField(5);
  @$pb.TagNumber(5)
  $9.Timestamp ensureUpdatedAt() => $_ensure(4);
}

class Membership extends $pb.GeneratedMessage {
  factory Membership() => create();
  Membership._() : super();
  factory Membership.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Membership.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Membership', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'groupId')
    ..pc<$10.Permission>(3, _omitFieldNames ? '' : 'permissions', $pb.PbFieldType.KE, valueOf: $10.Permission.valueOf, enumValues: $10.Permission.values, defaultEnumValue: $10.Permission.PERMISSION_UNKNOWN)
    ..e<$11.Moderation>(4, _omitFieldNames ? '' : 'groupModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Moderation>(5, _omitFieldNames ? '' : 'userModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..aOM<$9.Timestamp>(6, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(7, _omitFieldNames ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Membership clone() => Membership()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Membership copyWith(void Function(Membership) updates) => super.copyWith((message) => updates(message as Membership)) as Membership;

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
  $core.List<$10.Permission> get permissions => $_getList(2);

  @$pb.TagNumber(4)
  $11.Moderation get groupModeration => $_getN(3);
  @$pb.TagNumber(4)
  set groupModeration($11.Moderation v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasGroupModeration() => $_has(3);
  @$pb.TagNumber(4)
  void clearGroupModeration() => clearField(4);

  @$pb.TagNumber(5)
  $11.Moderation get userModeration => $_getN(4);
  @$pb.TagNumber(5)
  set userModeration($11.Moderation v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUserModeration() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserModeration() => clearField(5);

  @$pb.TagNumber(6)
  $9.Timestamp get createdAt => $_getN(5);
  @$pb.TagNumber(6)
  set createdAt($9.Timestamp v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => clearField(6);
  @$pb.TagNumber(6)
  $9.Timestamp ensureCreatedAt() => $_ensure(5);

  @$pb.TagNumber(7)
  $9.Timestamp get updatedAt => $_getN(6);
  @$pb.TagNumber(7)
  set updatedAt($9.Timestamp v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasUpdatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdatedAt() => clearField(7);
  @$pb.TagNumber(7)
  $9.Timestamp ensureUpdatedAt() => $_ensure(6);
}

class ContactMethod extends $pb.GeneratedMessage {
  factory ContactMethod() => create();
  ContactMethod._() : super();
  factory ContactMethod.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ContactMethod.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ContactMethod', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'value')
    ..e<$11.Visibility>(2, _omitFieldNames ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $11.Visibility.VISIBILITY_UNKNOWN, valueOf: $11.Visibility.valueOf, enumValues: $11.Visibility.values)
    ..aOB(3, _omitFieldNames ? '' : 'supportedByServer')
    ..aOB(4, _omitFieldNames ? '' : 'verified')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ContactMethod clone() => ContactMethod()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ContactMethod copyWith(void Function(ContactMethod) updates) => super.copyWith((message) => updates(message as ContactMethod)) as ContactMethod;

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
  $11.Visibility get visibility => $_getN(1);
  @$pb.TagNumber(2)
  set visibility($11.Visibility v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasVisibility() => $_has(1);
  @$pb.TagNumber(2)
  void clearVisibility() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get supportedByServer => $_getBF(2);
  @$pb.TagNumber(3)
  set supportedByServer($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSupportedByServer() => $_has(2);
  @$pb.TagNumber(3)
  void clearSupportedByServer() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get verified => $_getBF(3);
  @$pb.TagNumber(4)
  set verified($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasVerified() => $_has(3);
  @$pb.TagNumber(4)
  void clearVerified() => clearField(4);
}

class GetUsersRequest extends $pb.GeneratedMessage {
  factory GetUsersRequest() => create();
  GetUsersRequest._() : super();
  factory GetUsersRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetUsersRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetUsersRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..a<$core.int>(99, _omitFieldNames ? '' : 'page', $pb.PbFieldType.O3)
    ..e<UserListingType>(100, _omitFieldNames ? '' : 'listingType', $pb.PbFieldType.OE, defaultOrMaker: UserListingType.EVERYONE, valueOf: UserListingType.valueOf, enumValues: UserListingType.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetUsersRequest clone() => GetUsersRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetUsersRequest copyWith(void Function(GetUsersRequest) updates) => super.copyWith((message) => updates(message as GetUsersRequest)) as GetUsersRequest;

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
  factory GetUsersResponse() => create();
  GetUsersResponse._() : super();
  factory GetUsersResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetUsersResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetUsersResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<User>(1, _omitFieldNames ? '' : 'users', $pb.PbFieldType.PM, subBuilder: User.create)
    ..aOB(2, _omitFieldNames ? '' : 'hasNextPage')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetUsersResponse clone() => GetUsersResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetUsersResponse copyWith(void Function(GetUsersResponse) updates) => super.copyWith((message) => updates(message as GetUsersResponse)) as GetUsersResponse;

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


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
