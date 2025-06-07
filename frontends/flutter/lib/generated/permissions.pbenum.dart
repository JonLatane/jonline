//
//  Generated code. Do not modify.
//  source: permissions.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Jonline Permissions are a set of permissions that can be granted directly to [`User`](#jonline-User)s and [`Membership`](#jonline-Membership)s.
/// (A `Membership` is the link between a [`Group`](#jonline-Group) and a `User`.)
///
/// Subsets of these permissions are also applicable to anonymous users via [`anonymous_user_permissions` in `ServerConfiguration`](#jonline-ServerConfiguration),
/// and to Group non-members via [`non_member_permissions` in `Group`](#jonline-Group), as well as others documented there.
class Permission extends $pb.ProtobufEnum {
  /// A permission that could not be read using the Jonline protocol. (Perhaps, a permission from a newer Jonline version.)
  static const Permission PERMISSION_UNKNOWN = Permission._(0, _omitEnumNames ? '' : 'PERMISSION_UNKNOWN');
  /// Allow the user to view profiles with `SERVER_PUBLIC` Visbility.
  /// Allow anonymous users to view profiles with `GLOBAL_PUBLIC` Visbility (when configured as an anonymous user permission).
  static const Permission VIEW_USERS = Permission._(1, _omitEnumNames ? '' : 'VIEW_USERS');
  /// Allow the user to publish profiles with `SERVER_PUBLIC` Visbility.
  /// This generally only applies to the user's own profile, except for Admins.
  static const Permission PUBLISH_USERS_LOCALLY = Permission._(2, _omitEnumNames ? '' : 'PUBLISH_USERS_LOCALLY');
  /// Allow the user to publish profiles with `GLOBAL_PUBLIC` Visbility.
  /// This generally only applies to the user's own profile, except for Admins.
  static const Permission PUBLISH_USERS_GLOBALLY = Permission._(3, _omitEnumNames ? '' : 'PUBLISH_USERS_GLOBALLY');
  /// Allow the user to grant `VIEW_POSTS`, `CREATE_POSTS`, `VIEW_EVENTS`
  /// and `CREATE_EVENTS` permissions to users.
  static const Permission MODERATE_USERS = Permission._(4, _omitEnumNames ? '' : 'MODERATE_USERS');
  /// Allow the user to follow other users.
  static const Permission FOLLOW_USERS = Permission._(5, _omitEnumNames ? '' : 'FOLLOW_USERS');
  /// Allow the user to grant Basic Permissions to other users. "Basic Permissions"
  /// are defined by your `ServerConfiguration`'s `basic_user_permissions`.
  static const Permission GRANT_BASIC_PERMISSIONS = Permission._(6, _omitEnumNames ? '' : 'GRANT_BASIC_PERMISSIONS');
  /// Allow the user to view groups with `SERVER_PUBLIC` visibility.
  /// Allow anonymous users to view groups with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission).
  static const Permission VIEW_GROUPS = Permission._(10, _omitEnumNames ? '' : 'VIEW_GROUPS');
  /// Allow the user to create groups.
  static const Permission CREATE_GROUPS = Permission._(11, _omitEnumNames ? '' : 'CREATE_GROUPS');
  /// Allow the user to give groups `SERVER_PUBLIC` visibility.
  static const Permission PUBLISH_GROUPS_LOCALLY = Permission._(12, _omitEnumNames ? '' : 'PUBLISH_GROUPS_LOCALLY');
  /// Allow the user to give groups `GLOBAL_PUBLIC` visibility.
  static const Permission PUBLISH_GROUPS_GLOBALLY = Permission._(13, _omitEnumNames ? '' : 'PUBLISH_GROUPS_GLOBALLY');
  /// The Moderate Groups permission makes a user effectively an admin of *any* group.
  static const Permission MODERATE_GROUPS = Permission._(14, _omitEnumNames ? '' : 'MODERATE_GROUPS');
  /// Allow the user to (potentially request to) join groups of `SERVER_PUBLIC` or higher
  /// visibility.
  static const Permission JOIN_GROUPS = Permission._(15, _omitEnumNames ? '' : 'JOIN_GROUPS');
  /// Allow the user to invite other users to groups. Only applicable as a Group permission (not at the User level).
  static const Permission INVITE_GROUP_MEMBERS = Permission._(16, _omitEnumNames ? '' : 'INVITE_GROUP_MEMBERS');
  /// As a user permission, allow the user to view posts with `SERVER_PUBLIC` or higher visibility.
  /// As a group permission, allow the user to view `GroupPost`s whose `Post`s have `LIMITED` or higher visibility.
  /// Allow anonymous users to view posts with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission).
  static const Permission VIEW_POSTS = Permission._(20, _omitEnumNames ? '' : 'VIEW_POSTS');
  /// As a user permission, allow the user to create `Post`s of `PRIVATE` and `LIMITED` visibility.
  /// As a group permission, allow the user to create `GroupPost`s for `POST` and `FEDERATED_POST` `PostContext`s..
  static const Permission CREATE_POSTS = Permission._(21, _omitEnumNames ? '' : 'CREATE_POSTS');
  /// Allow the user to publish posts with `SERVER_PUBLIC` visibility.
  static const Permission PUBLISH_POSTS_LOCALLY = Permission._(22, _omitEnumNames ? '' : 'PUBLISH_POSTS_LOCALLY');
  /// Allow the user to publish posts with `GLOBAL_PUBLIC` visibility.
  static const Permission PUBLISH_POSTS_GLOBALLY = Permission._(23, _omitEnumNames ? '' : 'PUBLISH_POSTS_GLOBALLY');
  /// Allow the user to moderate posts.
  static const Permission MODERATE_POSTS = Permission._(24, _omitEnumNames ? '' : 'MODERATE_POSTS');
  /// Allow the user to reply to posts.
  static const Permission REPLY_TO_POSTS = Permission._(25, _omitEnumNames ? '' : 'REPLY_TO_POSTS');
  /// As a user permission, allow the user to view posts with `SERVER_PUBLIC` or higher visibility.
  /// As a group permission, allow the user to view `GroupPost`s whose `Event` `Post`s have `LIMITED` or higher visibility.
  /// Allow anonymous users to view events with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission).
  static const Permission VIEW_EVENTS = Permission._(30, _omitEnumNames ? '' : 'VIEW_EVENTS');
  /// As a user permission, allow the user to create `Event`s of `PRIVATE` and `LIMITED` visibility.
  /// As a group permission, allow the user to create `GroupPost`s for `EVENT` and `FEDERATED_EVENT_INSTANCE` `PostContext`s..
  static const Permission CREATE_EVENTS = Permission._(31, _omitEnumNames ? '' : 'CREATE_EVENTS');
  /// Allow the user to publish events with `SERVER_PUBLIC` visibility.
  static const Permission PUBLISH_EVENTS_LOCALLY = Permission._(32, _omitEnumNames ? '' : 'PUBLISH_EVENTS_LOCALLY');
  /// Allow the user to publish events with `GLOBAL_PUBLIC` visibility.
  static const Permission PUBLISH_EVENTS_GLOBALLY = Permission._(33, _omitEnumNames ? '' : 'PUBLISH_EVENTS_GLOBALLY');
  /// Allow the user to moderate events.
  static const Permission MODERATE_EVENTS = Permission._(34, _omitEnumNames ? '' : 'MODERATE_EVENTS');
  /// Allow the user to RSVP to events that allow RSVPs.
  static const Permission RSVP_TO_EVENTS = Permission._(35, _omitEnumNames ? '' : 'RSVP_TO_EVENTS');
  /// Allow the user to view media with `SERVER_PUBLIC` or higher visibility. *Not currently enforced.*
  /// Allow anonymous users to view media with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission). *Not currently enforced.*
  static const Permission VIEW_MEDIA = Permission._(40, _omitEnumNames ? '' : 'VIEW_MEDIA');
  /// Allow the user to create media of `PRIVATE` and `LIMITED` visibility. *Not currently enforced.*
  static const Permission CREATE_MEDIA = Permission._(41, _omitEnumNames ? '' : 'CREATE_MEDIA');
  /// Allow the user to publish media with `SERVER_PUBLIC` visibility. *Not currently enforced.*
  static const Permission PUBLISH_MEDIA_LOCALLY = Permission._(42, _omitEnumNames ? '' : 'PUBLISH_MEDIA_LOCALLY');
  /// Allow the user to publish media with `GLOBAL_PUBLIC` visibility. *Not currently enforced.*
  static const Permission PUBLISH_MEDIA_GLOBALLY = Permission._(43, _omitEnumNames ? '' : 'PUBLISH_MEDIA_GLOBALLY');
  /// Allow the user to moderate events.
  static const Permission MODERATE_MEDIA = Permission._(44, _omitEnumNames ? '' : 'MODERATE_MEDIA');
  /// Indicates the user is a business. Used purely for display purposes.
  static const Permission BUSINESS = Permission._(9998, _omitEnumNames ? '' : 'BUSINESS');
  /// Allow the user to run bots. There is no enforcement of this permission (yet),
  /// but it lets other users know that the user is allowed to run bots.
  static const Permission RUN_BOTS = Permission._(9999, _omitEnumNames ? '' : 'RUN_BOTS');
  /// Marks the user as an admin. In the context of user permissions, allows the user to configure the server,
  /// moderate/update visibility/permissions to any `User`, `Group`, `Post` or `Event`. In the context of group permissions, allows the user to configure the group,
  /// modify members and member permissions, and moderate `GroupPost`s and `GroupEvent`s.
  static const Permission ADMIN = Permission._(10000, _omitEnumNames ? '' : 'ADMIN');
  /// Allow the user to view the private contact methods of other users.
  /// Kept separate from `ADMIN` to allow for more fine-grained privacy control.
  static const Permission VIEW_PRIVATE_CONTACT_METHODS = Permission._(10001, _omitEnumNames ? '' : 'VIEW_PRIVATE_CONTACT_METHODS');

  static const $core.List<Permission> values = <Permission> [
    PERMISSION_UNKNOWN,
    VIEW_USERS,
    PUBLISH_USERS_LOCALLY,
    PUBLISH_USERS_GLOBALLY,
    MODERATE_USERS,
    FOLLOW_USERS,
    GRANT_BASIC_PERMISSIONS,
    VIEW_GROUPS,
    CREATE_GROUPS,
    PUBLISH_GROUPS_LOCALLY,
    PUBLISH_GROUPS_GLOBALLY,
    MODERATE_GROUPS,
    JOIN_GROUPS,
    INVITE_GROUP_MEMBERS,
    VIEW_POSTS,
    CREATE_POSTS,
    PUBLISH_POSTS_LOCALLY,
    PUBLISH_POSTS_GLOBALLY,
    MODERATE_POSTS,
    REPLY_TO_POSTS,
    VIEW_EVENTS,
    CREATE_EVENTS,
    PUBLISH_EVENTS_LOCALLY,
    PUBLISH_EVENTS_GLOBALLY,
    MODERATE_EVENTS,
    RSVP_TO_EVENTS,
    VIEW_MEDIA,
    CREATE_MEDIA,
    PUBLISH_MEDIA_LOCALLY,
    PUBLISH_MEDIA_GLOBALLY,
    MODERATE_MEDIA,
    BUSINESS,
    RUN_BOTS,
    ADMIN,
    VIEW_PRIVATE_CONTACT_METHODS,
  ];

  static final $core.Map<$core.int, Permission> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Permission? valueOf($core.int value) => _byValue[value];

  const Permission._(super.value, super.name);
}


const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
