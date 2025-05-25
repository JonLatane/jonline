//
//  Generated code. Do not modify.
//  source: users.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'federation.pb.dart' as $1;
import 'google/protobuf/timestamp.pb.dart' as $9;
import 'media.pb.dart' as $5;
import 'permissions.pbenum.dart' as $12;
import 'users.pbenum.dart';
import 'visibility_moderation.pbenum.dart' as $11;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'users.pbenum.dart';

/// Model for a Jonline user. This user may have [`Media`](#jonline-Media), [`Group`](#jonline-Group) [`Membership`](#jonline-Membership)s,
/// [`Post`](#jonline-Post)s, [`Event`](#jonline-Event)s, and other objects associated with them.
class User extends $pb.GeneratedMessage {
  factory User({
    $core.String? id,
    $core.String? username,
    $core.String? realName,
    ContactMethod? email,
    ContactMethod? phone,
    $core.Iterable<$12.Permission>? permissions,
    $5.MediaReference? avatar,
    $core.String? bio,
    $11.Visibility? visibility,
    $11.Moderation? moderation,
    $11.Moderation? defaultFollowModeration,
    $core.int? followerCount,
    $core.int? followingCount,
    $core.int? groupCount,
    $core.int? postCount,
    $core.int? responseCount,
    $core.int? eventCount,
    Follow? currentUserFollow,
    Follow? targetCurrentUserFollow,
    Membership? currentGroupMembership,
    $core.bool? hasAdvancedData,
    $core.Iterable<$1.FederatedAccount>? federatedProfiles,
    $9.Timestamp? createdAt,
    $9.Timestamp? updatedAt,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (username != null) {
      $result.username = username;
    }
    if (realName != null) {
      $result.realName = realName;
    }
    if (email != null) {
      $result.email = email;
    }
    if (phone != null) {
      $result.phone = phone;
    }
    if (permissions != null) {
      $result.permissions.addAll(permissions);
    }
    if (avatar != null) {
      $result.avatar = avatar;
    }
    if (bio != null) {
      $result.bio = bio;
    }
    if (visibility != null) {
      $result.visibility = visibility;
    }
    if (moderation != null) {
      $result.moderation = moderation;
    }
    if (defaultFollowModeration != null) {
      $result.defaultFollowModeration = defaultFollowModeration;
    }
    if (followerCount != null) {
      $result.followerCount = followerCount;
    }
    if (followingCount != null) {
      $result.followingCount = followingCount;
    }
    if (groupCount != null) {
      $result.groupCount = groupCount;
    }
    if (postCount != null) {
      $result.postCount = postCount;
    }
    if (responseCount != null) {
      $result.responseCount = responseCount;
    }
    if (eventCount != null) {
      $result.eventCount = eventCount;
    }
    if (currentUserFollow != null) {
      $result.currentUserFollow = currentUserFollow;
    }
    if (targetCurrentUserFollow != null) {
      $result.targetCurrentUserFollow = targetCurrentUserFollow;
    }
    if (currentGroupMembership != null) {
      $result.currentGroupMembership = currentGroupMembership;
    }
    if (hasAdvancedData != null) {
      $result.hasAdvancedData = hasAdvancedData;
    }
    if (federatedProfiles != null) {
      $result.federatedProfiles.addAll(federatedProfiles);
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      $result.updatedAt = updatedAt;
    }
    return $result;
  }
  User._() : super();
  factory User.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory User.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'User', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'realName')
    ..aOM<ContactMethod>(4, _omitFieldNames ? '' : 'email', subBuilder: ContactMethod.create)
    ..aOM<ContactMethod>(5, _omitFieldNames ? '' : 'phone', subBuilder: ContactMethod.create)
    ..pc<$12.Permission>(6, _omitFieldNames ? '' : 'permissions', $pb.PbFieldType.KE, valueOf: $12.Permission.valueOf, enumValues: $12.Permission.values, defaultEnumValue: $12.Permission.PERMISSION_UNKNOWN)
    ..aOM<$5.MediaReference>(7, _omitFieldNames ? '' : 'avatar', subBuilder: $5.MediaReference.create)
    ..aOS(8, _omitFieldNames ? '' : 'bio')
    ..e<$11.Visibility>(20, _omitFieldNames ? '' : 'visibility', $pb.PbFieldType.OE, defaultOrMaker: $11.Visibility.VISIBILITY_UNKNOWN, valueOf: $11.Visibility.valueOf, enumValues: $11.Visibility.values)
    ..e<$11.Moderation>(21, _omitFieldNames ? '' : 'moderation', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Moderation>(30, _omitFieldNames ? '' : 'defaultFollowModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..a<$core.int>(31, _omitFieldNames ? '' : 'followerCount', $pb.PbFieldType.O3)
    ..a<$core.int>(32, _omitFieldNames ? '' : 'followingCount', $pb.PbFieldType.O3)
    ..a<$core.int>(33, _omitFieldNames ? '' : 'groupCount', $pb.PbFieldType.O3)
    ..a<$core.int>(34, _omitFieldNames ? '' : 'postCount', $pb.PbFieldType.O3)
    ..a<$core.int>(35, _omitFieldNames ? '' : 'responseCount', $pb.PbFieldType.O3)
    ..a<$core.int>(36, _omitFieldNames ? '' : 'eventCount', $pb.PbFieldType.O3)
    ..aOM<Follow>(50, _omitFieldNames ? '' : 'currentUserFollow', subBuilder: Follow.create)
    ..aOM<Follow>(51, _omitFieldNames ? '' : 'targetCurrentUserFollow', subBuilder: Follow.create)
    ..aOM<Membership>(52, _omitFieldNames ? '' : 'currentGroupMembership', subBuilder: Membership.create)
    ..aOB(80, _omitFieldNames ? '' : 'hasAdvancedData')
    ..pc<$1.FederatedAccount>(81, _omitFieldNames ? '' : 'federatedProfiles', $pb.PbFieldType.PM, subBuilder: $1.FederatedAccount.create)
    ..aOM<$9.Timestamp>(100, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(101, _omitFieldNames ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User clone() => User()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User copyWith(void Function(User) updates) => super.copyWith((message) => updates(message as User)) as User;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static User create() => User._();
  User createEmptyInstance() => create();
  static $pb.PbList<User> createRepeated() => $pb.PbList<User>();
  @$core.pragma('dart2js:noInline')
  static User getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<User>(create);
  static User? _defaultInstance;

  /// Permanent string ID for the user. Will never contain a `@` symbol.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Impermanent string username for the user. Will never contain a `@` symbol.
  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  /// The user's real name.
  @$pb.TagNumber(3)
  $core.String get realName => $_getSZ(2);
  @$pb.TagNumber(3)
  set realName($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRealName() => $_has(2);
  @$pb.TagNumber(3)
  void clearRealName() => $_clearField(3);

  /// The user's email address.
  @$pb.TagNumber(4)
  ContactMethod get email => $_getN(3);
  @$pb.TagNumber(4)
  set email(ContactMethod v) { $_setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasEmail() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmail() => $_clearField(4);
  @$pb.TagNumber(4)
  ContactMethod ensureEmail() => $_ensure(3);

  /// The user's phone number.
  @$pb.TagNumber(5)
  ContactMethod get phone => $_getN(4);
  @$pb.TagNumber(5)
  set phone(ContactMethod v) { $_setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasPhone() => $_has(4);
  @$pb.TagNumber(5)
  void clearPhone() => $_clearField(5);
  @$pb.TagNumber(5)
  ContactMethod ensurePhone() => $_ensure(4);

  /// The user's permissions. See [`Permission`](#jonline-Permission) for details.
  @$pb.TagNumber(6)
  $pb.PbList<$12.Permission> get permissions => $_getList(5);

  /// The user's avatar. Note that its visibility is managed by the User and thus
  /// it may not be accessible to the current user.
  @$pb.TagNumber(7)
  $5.MediaReference get avatar => $_getN(6);
  @$pb.TagNumber(7)
  set avatar($5.MediaReference v) { $_setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasAvatar() => $_has(6);
  @$pb.TagNumber(7)
  void clearAvatar() => $_clearField(7);
  @$pb.TagNumber(7)
  $5.MediaReference ensureAvatar() => $_ensure(6);

  /// The user's bio.
  @$pb.TagNumber(8)
  $core.String get bio => $_getSZ(7);
  @$pb.TagNumber(8)
  set bio($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasBio() => $_has(7);
  @$pb.TagNumber(8)
  void clearBio() => $_clearField(8);

  /// User visibility is a bit different from Post visibility.
  /// LIMITED means the user can only be seen by users they follow
  /// (as opposed to Posts' individualized visibilities).
  /// PRIVATE visibility means no one can see the user.
  /// See server_configuration.proto for details about PRIVATE
  /// users' ability to creep.
  @$pb.TagNumber(20)
  $11.Visibility get visibility => $_getN(8);
  @$pb.TagNumber(20)
  set visibility($11.Visibility v) { $_setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasVisibility() => $_has(8);
  @$pb.TagNumber(20)
  void clearVisibility() => $_clearField(20);

  /// The user's moderation status. See [`Moderation`](#jonline-Moderation) for details.
  @$pb.TagNumber(21)
  $11.Moderation get moderation => $_getN(9);
  @$pb.TagNumber(21)
  set moderation($11.Moderation v) { $_setField(21, v); }
  @$pb.TagNumber(21)
  $core.bool hasModeration() => $_has(9);
  @$pb.TagNumber(21)
  void clearModeration() => $_clearField(21);

  /// Only PENDING or UNMODERATED are valid.
  @$pb.TagNumber(30)
  $11.Moderation get defaultFollowModeration => $_getN(10);
  @$pb.TagNumber(30)
  set defaultFollowModeration($11.Moderation v) { $_setField(30, v); }
  @$pb.TagNumber(30)
  $core.bool hasDefaultFollowModeration() => $_has(10);
  @$pb.TagNumber(30)
  void clearDefaultFollowModeration() => $_clearField(30);

  /// The number of users following this user.
  @$pb.TagNumber(31)
  $core.int get followerCount => $_getIZ(11);
  @$pb.TagNumber(31)
  set followerCount($core.int v) { $_setSignedInt32(11, v); }
  @$pb.TagNumber(31)
  $core.bool hasFollowerCount() => $_has(11);
  @$pb.TagNumber(31)
  void clearFollowerCount() => $_clearField(31);

  /// The number of users this user is following.
  @$pb.TagNumber(32)
  $core.int get followingCount => $_getIZ(12);
  @$pb.TagNumber(32)
  set followingCount($core.int v) { $_setSignedInt32(12, v); }
  @$pb.TagNumber(32)
  $core.bool hasFollowingCount() => $_has(12);
  @$pb.TagNumber(32)
  void clearFollowingCount() => $_clearField(32);

  /// The number of groups this user is a member of.
  @$pb.TagNumber(33)
  $core.int get groupCount => $_getIZ(13);
  @$pb.TagNumber(33)
  set groupCount($core.int v) { $_setSignedInt32(13, v); }
  @$pb.TagNumber(33)
  $core.bool hasGroupCount() => $_has(13);
  @$pb.TagNumber(33)
  void clearGroupCount() => $_clearField(33);

  /// The number of posts this user has made.
  @$pb.TagNumber(34)
  $core.int get postCount => $_getIZ(14);
  @$pb.TagNumber(34)
  set postCount($core.int v) { $_setSignedInt32(14, v); }
  @$pb.TagNumber(34)
  $core.bool hasPostCount() => $_has(14);
  @$pb.TagNumber(34)
  void clearPostCount() => $_clearField(34);

  /// The number of responses to `Post`s and `Event`s this user has made.
  @$pb.TagNumber(35)
  $core.int get responseCount => $_getIZ(15);
  @$pb.TagNumber(35)
  set responseCount($core.int v) { $_setSignedInt32(15, v); }
  @$pb.TagNumber(35)
  $core.bool hasResponseCount() => $_has(15);
  @$pb.TagNumber(35)
  void clearResponseCount() => $_clearField(35);

  /// The number of events this user has created.
  @$pb.TagNumber(36)
  $core.int get eventCount => $_getIZ(16);
  @$pb.TagNumber(36)
  set eventCount($core.int v) { $_setSignedInt32(16, v); }
  @$pb.TagNumber(36)
  $core.bool hasEventCount() => $_has(16);
  @$pb.TagNumber(36)
  void clearEventCount() => $_clearField(36);

  /// Presence indicates the current user is following
  /// or has a pending follow request for this user.
  @$pb.TagNumber(50)
  Follow get currentUserFollow => $_getN(17);
  @$pb.TagNumber(50)
  set currentUserFollow(Follow v) { $_setField(50, v); }
  @$pb.TagNumber(50)
  $core.bool hasCurrentUserFollow() => $_has(17);
  @$pb.TagNumber(50)
  void clearCurrentUserFollow() => $_clearField(50);
  @$pb.TagNumber(50)
  Follow ensureCurrentUserFollow() => $_ensure(17);

  /// Presence indicates this user is following or has
  /// a pending follow request for the current user.
  @$pb.TagNumber(51)
  Follow get targetCurrentUserFollow => $_getN(18);
  @$pb.TagNumber(51)
  set targetCurrentUserFollow(Follow v) { $_setField(51, v); }
  @$pb.TagNumber(51)
  $core.bool hasTargetCurrentUserFollow() => $_has(18);
  @$pb.TagNumber(51)
  void clearTargetCurrentUserFollow() => $_clearField(51);
  @$pb.TagNumber(51)
  Follow ensureTargetCurrentUserFollow() => $_ensure(18);

  /// Returned by `GetMembers` calls, for use when managing [`Group`](#jonline-Group) [`Membership`](#jonline-Membership)s.
  /// The `Membership` should match the `Group` from the originating [`GetMembersRequest`](#jonline-GetMembersRequest),
  /// providing whether the user is a member of that `Group`, has been invited, requested to join, etc..
  @$pb.TagNumber(52)
  Membership get currentGroupMembership => $_getN(19);
  @$pb.TagNumber(52)
  set currentGroupMembership(Membership v) { $_setField(52, v); }
  @$pb.TagNumber(52)
  $core.bool hasCurrentGroupMembership() => $_has(19);
  @$pb.TagNumber(52)
  void clearCurrentGroupMembership() => $_clearField(52);
  @$pb.TagNumber(52)
  Membership ensureCurrentGroupMembership() => $_ensure(19);

  /// Indicates that `federated_profiles` has been loaded.
  @$pb.TagNumber(80)
  $core.bool get hasAdvancedData => $_getBF(20);
  @$pb.TagNumber(80)
  set hasAdvancedData($core.bool v) { $_setBool(20, v); }
  @$pb.TagNumber(80)
  $core.bool hasHasAdvancedData() => $_has(20);
  @$pb.TagNumber(80)
  void clearHasAdvancedData() => $_clearField(80);

  /// Federated profiles for the user. *Not always loaded.* This is a list of profiles from other servers
  /// that the user has connected to their account. Managed by the user via
  /// `Federate`
  @$pb.TagNumber(81)
  $pb.PbList<$1.FederatedAccount> get federatedProfiles => $_getList(21);

  /// The time the user was created.
  @$pb.TagNumber(100)
  $9.Timestamp get createdAt => $_getN(22);
  @$pb.TagNumber(100)
  set createdAt($9.Timestamp v) { $_setField(100, v); }
  @$pb.TagNumber(100)
  $core.bool hasCreatedAt() => $_has(22);
  @$pb.TagNumber(100)
  void clearCreatedAt() => $_clearField(100);
  @$pb.TagNumber(100)
  $9.Timestamp ensureCreatedAt() => $_ensure(22);

  /// The time the user was last updated.
  @$pb.TagNumber(101)
  $9.Timestamp get updatedAt => $_getN(23);
  @$pb.TagNumber(101)
  set updatedAt($9.Timestamp v) { $_setField(101, v); }
  @$pb.TagNumber(101)
  $core.bool hasUpdatedAt() => $_has(23);
  @$pb.TagNumber(101)
  void clearUpdatedAt() => $_clearField(101);
  @$pb.TagNumber(101)
  $9.Timestamp ensureUpdatedAt() => $_ensure(23);
}

/// Post/authorship-centric version of User. UI can cross-reference user details
/// from its own cache (for things like admin/bot icons).
class Author extends $pb.GeneratedMessage {
  factory Author({
    $core.String? userId,
    $core.String? username,
    $5.MediaReference? avatar,
    $core.String? realName,
    $core.Iterable<$12.Permission>? permissions,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (username != null) {
      $result.username = username;
    }
    if (avatar != null) {
      $result.avatar = avatar;
    }
    if (realName != null) {
      $result.realName = realName;
    }
    if (permissions != null) {
      $result.permissions.addAll(permissions);
    }
    return $result;
  }
  Author._() : super();
  factory Author.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Author.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Author', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOM<$5.MediaReference>(3, _omitFieldNames ? '' : 'avatar', subBuilder: $5.MediaReference.create)
    ..aOS(4, _omitFieldNames ? '' : 'realName')
    ..pc<$12.Permission>(5, _omitFieldNames ? '' : 'permissions', $pb.PbFieldType.KE, valueOf: $12.Permission.valueOf, enumValues: $12.Permission.values, defaultEnumValue: $12.Permission.PERMISSION_UNKNOWN)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Author clone() => Author()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Author copyWith(void Function(Author) updates) => super.copyWith((message) => updates(message as Author)) as Author;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Author create() => Author._();
  Author createEmptyInstance() => create();
  static $pb.PbList<Author> createRepeated() => $pb.PbList<Author>();
  @$core.pragma('dart2js:noInline')
  static Author getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Author>(create);
  static Author? _defaultInstance;

  /// Permanent string ID for the user. Will never contain a `@` symbol.
  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  /// Impermanent string username for the user. Will never contain a `@` symbol.
  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  /// The user's avatar.
  @$pb.TagNumber(3)
  $5.MediaReference get avatar => $_getN(2);
  @$pb.TagNumber(3)
  set avatar($5.MediaReference v) { $_setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasAvatar() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatar() => $_clearField(3);
  @$pb.TagNumber(3)
  $5.MediaReference ensureAvatar() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get realName => $_getSZ(3);
  @$pb.TagNumber(4)
  set realName($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRealName() => $_has(3);
  @$pb.TagNumber(4)
  void clearRealName() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$12.Permission> get permissions => $_getList(4);
}

/// Model for a user's follow of another user.
class Follow extends $pb.GeneratedMessage {
  factory Follow({
    $core.String? userId,
    $core.String? targetUserId,
    $11.Moderation? targetUserModeration,
    $9.Timestamp? createdAt,
    $9.Timestamp? updatedAt,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (targetUserId != null) {
      $result.targetUserId = targetUserId;
    }
    if (targetUserModeration != null) {
      $result.targetUserModeration = targetUserModeration;
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      $result.updatedAt = updatedAt;
    }
    return $result;
  }
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

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Follow clone() => Follow()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Follow copyWith(void Function(Follow) updates) => super.copyWith((message) => updates(message as Follow)) as Follow;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Follow create() => Follow._();
  Follow createEmptyInstance() => create();
  static $pb.PbList<Follow> createRepeated() => $pb.PbList<Follow>();
  @$core.pragma('dart2js:noInline')
  static Follow getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Follow>(create);
  static Follow? _defaultInstance;

  /// The follower in the relationship.
  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  /// The user being followed.
  @$pb.TagNumber(2)
  $core.String get targetUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set targetUserId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTargetUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetUserId() => $_clearField(2);

  /// Tracks whether the target user needs to approve the follow.
  @$pb.TagNumber(3)
  $11.Moderation get targetUserModeration => $_getN(2);
  @$pb.TagNumber(3)
  set targetUserModeration($11.Moderation v) { $_setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasTargetUserModeration() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetUserModeration() => $_clearField(3);

  /// The time the follow was created.
  @$pb.TagNumber(4)
  $9.Timestamp get createdAt => $_getN(3);
  @$pb.TagNumber(4)
  set createdAt($9.Timestamp v) { $_setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $9.Timestamp ensureCreatedAt() => $_ensure(3);

  /// The time the follow was last updated.
  @$pb.TagNumber(5)
  $9.Timestamp get updatedAt => $_getN(4);
  @$pb.TagNumber(5)
  set updatedAt($9.Timestamp v) { $_setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUpdatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearUpdatedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $9.Timestamp ensureUpdatedAt() => $_ensure(4);
}

/// Model for a user's membership in a group. Memberships are generically
/// included as part of User models when relevant in Jonline, but UIs should use the group_id
/// to reconcile memberships with groups.
class Membership extends $pb.GeneratedMessage {
  factory Membership({
    $core.String? userId,
    $core.String? groupId,
    $core.Iterable<$12.Permission>? permissions,
    $11.Moderation? groupModeration,
    $11.Moderation? userModeration,
    $9.Timestamp? createdAt,
    $9.Timestamp? updatedAt,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (groupId != null) {
      $result.groupId = groupId;
    }
    if (permissions != null) {
      $result.permissions.addAll(permissions);
    }
    if (groupModeration != null) {
      $result.groupModeration = groupModeration;
    }
    if (userModeration != null) {
      $result.userModeration = userModeration;
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    if (updatedAt != null) {
      $result.updatedAt = updatedAt;
    }
    return $result;
  }
  Membership._() : super();
  factory Membership.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Membership.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Membership', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'groupId')
    ..pc<$12.Permission>(3, _omitFieldNames ? '' : 'permissions', $pb.PbFieldType.KE, valueOf: $12.Permission.valueOf, enumValues: $12.Permission.values, defaultEnumValue: $12.Permission.PERMISSION_UNKNOWN)
    ..e<$11.Moderation>(4, _omitFieldNames ? '' : 'groupModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..e<$11.Moderation>(5, _omitFieldNames ? '' : 'userModeration', $pb.PbFieldType.OE, defaultOrMaker: $11.Moderation.MODERATION_UNKNOWN, valueOf: $11.Moderation.valueOf, enumValues: $11.Moderation.values)
    ..aOM<$9.Timestamp>(6, _omitFieldNames ? '' : 'createdAt', subBuilder: $9.Timestamp.create)
    ..aOM<$9.Timestamp>(7, _omitFieldNames ? '' : 'updatedAt', subBuilder: $9.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Membership clone() => Membership()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Membership copyWith(void Function(Membership) updates) => super.copyWith((message) => updates(message as Membership)) as Membership;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Membership create() => Membership._();
  Membership createEmptyInstance() => create();
  static $pb.PbList<Membership> createRepeated() => $pb.PbList<Membership>();
  @$core.pragma('dart2js:noInline')
  static Membership getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Membership>(create);
  static Membership? _defaultInstance;

  /// The member (or requested/invited member).
  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  /// The group the membership pertains to.
  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupId() => $_clearField(2);

  /// Valid Membership Permissions are:  `VIEW_POSTS`, `CREATE_POSTS`, `MODERATE_POSTS`, `VIEW_EVENTS`, CREATE_EVENTS, `MODERATE_EVENTS`, `ADMIN`, `RUN_BOTS`, and `MODERATE_USERS`
  @$pb.TagNumber(3)
  $pb.PbList<$12.Permission> get permissions => $_getList(2);

  /// Tracks whether group moderators need to approve the membership.
  @$pb.TagNumber(4)
  $11.Moderation get groupModeration => $_getN(3);
  @$pb.TagNumber(4)
  set groupModeration($11.Moderation v) { $_setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasGroupModeration() => $_has(3);
  @$pb.TagNumber(4)
  void clearGroupModeration() => $_clearField(4);

  /// Tracks whether the user needs to approve the membership.
  @$pb.TagNumber(5)
  $11.Moderation get userModeration => $_getN(4);
  @$pb.TagNumber(5)
  set userModeration($11.Moderation v) { $_setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUserModeration() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserModeration() => $_clearField(5);

  /// The time the membership was created.
  @$pb.TagNumber(6)
  $9.Timestamp get createdAt => $_getN(5);
  @$pb.TagNumber(6)
  set createdAt($9.Timestamp v) { $_setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $9.Timestamp ensureCreatedAt() => $_ensure(5);

  /// The time the membership was last updated.
  @$pb.TagNumber(7)
  $9.Timestamp get updatedAt => $_getN(6);
  @$pb.TagNumber(7)
  set updatedAt($9.Timestamp v) { $_setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasUpdatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdatedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $9.Timestamp ensureUpdatedAt() => $_ensure(6);
}

/// A contact method for a user. Models designed to support verification,
/// but verification RPCs are not yet implemented.
class ContactMethod extends $pb.GeneratedMessage {
  factory ContactMethod({
    $core.String? value,
    $11.Visibility? visibility,
    $core.bool? supportedByServer,
    $core.bool? verified,
  }) {
    final $result = create();
    if (value != null) {
      $result.value = value;
    }
    if (visibility != null) {
      $result.visibility = visibility;
    }
    if (supportedByServer != null) {
      $result.supportedByServer = supportedByServer;
    }
    if (verified != null) {
      $result.verified = verified;
    }
    return $result;
  }
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

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContactMethod clone() => ContactMethod()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContactMethod copyWith(void Function(ContactMethod) updates) => super.copyWith((message) => updates(message as ContactMethod)) as ContactMethod;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContactMethod create() => ContactMethod._();
  ContactMethod createEmptyInstance() => create();
  static $pb.PbList<ContactMethod> createRepeated() => $pb.PbList<ContactMethod>();
  @$core.pragma('dart2js:noInline')
  static ContactMethod getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContactMethod>(create);
  static ContactMethod? _defaultInstance;

  /// Either a `mailto:` or `tel:` URL.
  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);

  /// The visibility of the contact method.
  @$pb.TagNumber(2)
  $11.Visibility get visibility => $_getN(1);
  @$pb.TagNumber(2)
  set visibility($11.Visibility v) { $_setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasVisibility() => $_has(1);
  @$pb.TagNumber(2)
  void clearVisibility() => $_clearField(2);

  /// Server-side flag indicating whether the server can verify
  /// (and otherwise interact via) the contact method.
  @$pb.TagNumber(3)
  $core.bool get supportedByServer => $_getBF(2);
  @$pb.TagNumber(3)
  set supportedByServer($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSupportedByServer() => $_has(2);
  @$pb.TagNumber(3)
  void clearSupportedByServer() => $_clearField(3);

  /// Indicates the user has completed verification of the contact method.
  /// Verification requires `supported_by_server` to be `true`.
  @$pb.TagNumber(4)
  $core.bool get verified => $_getBF(3);
  @$pb.TagNumber(4)
  set verified($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasVerified() => $_has(3);
  @$pb.TagNumber(4)
  void clearVerified() => $_clearField(4);
}

/// Request to get one or more users by a variety of parameters.
/// Supported parameters depend on `listing_type`.
class GetUsersRequest extends $pb.GeneratedMessage {
  factory GetUsersRequest({
    $core.String? username,
    $core.String? userId,
    $core.int? page,
    UserListingType? listingType,
  }) {
    final $result = create();
    if (username != null) {
      $result.username = username;
    }
    if (userId != null) {
      $result.userId = userId;
    }
    if (page != null) {
      $result.page = page;
    }
    if (listingType != null) {
      $result.listingType = listingType;
    }
    return $result;
  }
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

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUsersRequest clone() => GetUsersRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUsersRequest copyWith(void Function(GetUsersRequest) updates) => super.copyWith((message) => updates(message as GetUsersRequest)) as GetUsersRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetUsersRequest create() => GetUsersRequest._();
  GetUsersRequest createEmptyInstance() => create();
  static $pb.PbList<GetUsersRequest> createRepeated() => $pb.PbList<GetUsersRequest>();
  @$core.pragma('dart2js:noInline')
  static GetUsersRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetUsersRequest>(create);
  static GetUsersRequest? _defaultInstance;

  /// The username to search for. Substrings are supported.
  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  /// The user ID to search for.
  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  /// The page of results to return. Pages are 0-indexed.
  @$pb.TagNumber(99)
  $core.int get page => $_getIZ(2);
  @$pb.TagNumber(99)
  set page($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(99)
  $core.bool hasPage() => $_has(2);
  @$pb.TagNumber(99)
  void clearPage() => $_clearField(99);

  /// The number of results to return per page.
  @$pb.TagNumber(100)
  UserListingType get listingType => $_getN(3);
  @$pb.TagNumber(100)
  set listingType(UserListingType v) { $_setField(100, v); }
  @$pb.TagNumber(100)
  $core.bool hasListingType() => $_has(3);
  @$pb.TagNumber(100)
  void clearListingType() => $_clearField(100);
}

/// Response to a `GetUsersRequest`.
class GetUsersResponse extends $pb.GeneratedMessage {
  factory GetUsersResponse({
    $core.Iterable<User>? users,
    $core.bool? hasNextPage,
  }) {
    final $result = create();
    if (users != null) {
      $result.users.addAll(users);
    }
    if (hasNextPage != null) {
      $result.hasNextPage = hasNextPage;
    }
    return $result;
  }
  GetUsersResponse._() : super();
  factory GetUsersResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetUsersResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetUsersResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'jonline'), createEmptyInstance: create)
    ..pc<User>(1, _omitFieldNames ? '' : 'users', $pb.PbFieldType.PM, subBuilder: User.create)
    ..aOB(2, _omitFieldNames ? '' : 'hasNextPage')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUsersResponse clone() => GetUsersResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUsersResponse copyWith(void Function(GetUsersResponse) updates) => super.copyWith((message) => updates(message as GetUsersResponse)) as GetUsersResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetUsersResponse create() => GetUsersResponse._();
  GetUsersResponse createEmptyInstance() => create();
  static $pb.PbList<GetUsersResponse> createRepeated() => $pb.PbList<GetUsersResponse>();
  @$core.pragma('dart2js:noInline')
  static GetUsersResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetUsersResponse>(create);
  static GetUsersResponse? _defaultInstance;

  /// The users matching the request.
  @$pb.TagNumber(1)
  $pb.PbList<User> get users => $_getList(0);

  /// Whether there are more pages of results.
  @$pb.TagNumber(2)
  $core.bool get hasNextPage => $_getBF(1);
  @$pb.TagNumber(2)
  set hasNextPage($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasHasNextPage() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasNextPage() => $_clearField(2);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
