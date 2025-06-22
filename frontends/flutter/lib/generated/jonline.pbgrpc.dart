//
//  Generated code. Do not modify.
//  source: jonline.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'authentication.pb.dart' as $3;
import 'events.pb.dart' as $8;
import 'federation.pb.dart' as $1;
import 'google/protobuf/empty.pb.dart' as $0;
import 'groups.pb.dart' as $6;
import 'media.pb.dart' as $5;
import 'posts.pb.dart' as $7;
import 'server_configuration.pb.dart' as $2;
import 'users.pb.dart' as $4;

export 'jonline.pb.dart';

/// A Jonline server is generally expected to run a gRPC server on port 27707 and/or 443, and an HTTP server on port 80 and/or 443.
/// The bulk of these docs involve the gRPC APIs (the "protocol"), while the HTTP server is expected to serve up web apps (React and, previously, Flutter),
/// [media files](#jonline-Media), and a [`backend_host` resource for client/host negotiation](#http-based-client-host-negotiation-for-external-cdns).
///
/// ##### Authentication
/// Jonline uses a standard OAuth2 flow (over gRPC) for authentication, with rotating `access_token`s and `refresh_token`s.
/// Authenticated calls require an `access_token` in request metadata to be included / directly as the value of the
/// `authorization` header (no `Bearer ` prefix).
///
/// First, use the `CreateAccount` or `Login` RPCs to fetch (and store) an initial
/// `refresh_token` and `access_token`. Clients should use the `access_token` until it expires,
/// then use the `refresh_token` to call the `AccessToken` RPC for a new one. (The `AccessToken` RPC
/// may, at random, also return a new `refresh_token`. If so, it should immediately replace the old
/// one in client storage.)
///
/// ##### Dumfederation
/// Whereas other federated social networks (e.g. ActivityPub) have both client-server and server-server APIs,
/// Jonline only has client-server APIs. The idea is that *all* of the federation data for a given Jonline server is simply the value of
/// [`federation_info` in `ServerConfiguration`](#jonline-ServerConfiguration).
///
/// That is to say: Servers can recommend other hosts. Clients can do what they will with that information.
/// (Eventually, this will affect CORS policies for added security.)
/// The aim here is to optimize for ease of server administration, and ease of understanding how the system works for users.
///
/// Notably, Jonline's design certainly *does* facilitate server-to-server communication (for instance, it could be used to serve
/// Post titles for posts from other servers in HTTP `meta` tags), but it does not require it for core user functionality.
///
/// ##### HTTP-based client host negotiation (for external CDNs)
/// When first negotiating the gRPC connection to a host, say, `jonline.io`, before attempting
/// to connect to `jonline.io` via gRPC on 27707/443, the client
/// is expected to first attempt to `GET jonline.io/backend_host` over HTTP (port 80) or HTTPS (port 443)
/// (depending upon whether the gRPC server is expected to have TLS). If the `backend_host` string resource
/// is a valid domain, say, `jonline.io.itsj.online`, the client is expected to connect
/// to `jonline.io.itsj.online` on port 27707/443 instead. To users, the server should still *generally* appear to
/// be `jonline.io`. The client can trust `jonline.io/backend_host` to always point to the correct backend host for
/// `jonline.io`.
///
/// This negotiation enables support for external CDNs as frontends. See https://jonline.io/about?section=cdn for
/// more information about external CDN setup. Developers may wish to review the [React/Tamagui](https://github.com/JonLatane/jonline/blob/main/frontends/tamagui/packages/app/store/clients.ts#L116)
/// and [Flutter](https://github.com/JonLatane/jonline/blob/main/frontends/flutter/lib/models/jonline_clients.dart#L26)
/// client implementations of this negotiation.
///
/// In the works to be released soon, Jonline will also support a "fully behind CDN" mode, where gRPC is served over port 443 and HTTP over port
/// 80, with no HTTPS web page/media serving (other than the HTTPS that naturally underpins gRPC-Web). This is designed to use Cloudflare's gRPC
/// proxy support. With this, both web and gRPC resources can live behind a CDN.
///
/// ##### API Design Notes
/// ###### Moderation and Visibility
/// Jonline APIs are designed to support `Moderation` and `Visibility` controls at the level of individual entities. However, to keep things
/// DRY, moderation and visibility controls are only implemented for `User`s, `Media`, `Group`s, and `Post`s.
///
/// `Event`s and future `Post`-like types simply use the same implementation as their contained `Post`s. The intent here is to maximize
/// both shared code and implementation robustness.
///
/// ###### Composition Over Inheritance
/// Jonline's APIs are designed using composition over inheritance. For instance, an `Event` contains
/// a `Post` rather than extending it. This pattern fits well all the way from the data model (very boring, safe, and normalized),
/// through Rust code implementing APIs, to both functional React code and more-OOP Flutter code equally well.
///
/// ###### Predictable Atomicity
/// The use of composition over inheritance also means that Jonline APIs can be *predictably* non-atomic based on their compositional structure.
/// For instance, `UpdatePost` is fully atomic.
///
/// `UpdateEvent`, however, is non-atomic. Given that an `Event` has a `Post` and many `EventInstance`s,
/// `UpdateEvent` will first update the `Post` atomically (literally calling the `UpdatePost` RPC),
/// then the `Event` atomically, and then finally process updates to its `EventInstance`s in a final atomic operation.
///
/// Because moderation/visibility lives at the `Post` level, this means that a developer error in `UpdateEvents` cannot prevent
/// visibility and moderation changes from being made in Events, even if there are errors elsewhere.
/// This should prove a robust pattern for any future entities intended to be shareable at a Group level with visibility and
/// moderation controls (for instance, `Sheet`, `SharedExpenseReport`, `SharedCalendar`, etc.). The entire architecture should promote this
/// approach to predictable atomicity.
///
/// #### gRPC API
@$pb.GrpcServiceName('jonline.Jonline')
class JonlineClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  static final _$getServiceVersion = $grpc.ClientMethod<$0.Empty, $1.GetServiceVersionResponse>(
      '/jonline.Jonline/GetServiceVersion',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.GetServiceVersionResponse.fromBuffer(value));
  static final _$getServerConfiguration = $grpc.ClientMethod<$0.Empty, $2.ServerConfiguration>(
      '/jonline.Jonline/GetServerConfiguration',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.ServerConfiguration.fromBuffer(value));
  static final _$createAccount = $grpc.ClientMethod<$3.CreateAccountRequest, $3.RefreshTokenResponse>(
      '/jonline.Jonline/CreateAccount',
      ($3.CreateAccountRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.RefreshTokenResponse.fromBuffer(value));
  static final _$login = $grpc.ClientMethod<$3.LoginRequest, $3.RefreshTokenResponse>(
      '/jonline.Jonline/Login',
      ($3.LoginRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.RefreshTokenResponse.fromBuffer(value));
  static final _$accessToken = $grpc.ClientMethod<$3.AccessTokenRequest, $3.AccessTokenResponse>(
      '/jonline.Jonline/AccessToken',
      ($3.AccessTokenRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.AccessTokenResponse.fromBuffer(value));
  static final _$getCurrentUser = $grpc.ClientMethod<$0.Empty, $4.User>(
      '/jonline.Jonline/GetCurrentUser',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.User.fromBuffer(value));
  static final _$resetPassword = $grpc.ClientMethod<$3.ResetPasswordRequest, $0.Empty>(
      '/jonline.Jonline/ResetPassword',
      ($3.ResetPasswordRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getMedia = $grpc.ClientMethod<$5.GetMediaRequest, $5.GetMediaResponse>(
      '/jonline.Jonline/GetMedia',
      ($5.GetMediaRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $5.GetMediaResponse.fromBuffer(value));
  static final _$deleteMedia = $grpc.ClientMethod<$5.Media, $0.Empty>(
      '/jonline.Jonline/DeleteMedia',
      ($5.Media value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getUsers = $grpc.ClientMethod<$4.GetUsersRequest, $4.GetUsersResponse>(
      '/jonline.Jonline/GetUsers',
      ($4.GetUsersRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.GetUsersResponse.fromBuffer(value));
  static final _$updateUser = $grpc.ClientMethod<$4.User, $4.User>(
      '/jonline.Jonline/UpdateUser',
      ($4.User value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.User.fromBuffer(value));
  static final _$deleteUser = $grpc.ClientMethod<$4.User, $0.Empty>(
      '/jonline.Jonline/DeleteUser',
      ($4.User value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$createFollow = $grpc.ClientMethod<$4.Follow, $4.Follow>(
      '/jonline.Jonline/CreateFollow',
      ($4.Follow value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.Follow.fromBuffer(value));
  static final _$updateFollow = $grpc.ClientMethod<$4.Follow, $4.Follow>(
      '/jonline.Jonline/UpdateFollow',
      ($4.Follow value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.Follow.fromBuffer(value));
  static final _$deleteFollow = $grpc.ClientMethod<$4.Follow, $0.Empty>(
      '/jonline.Jonline/DeleteFollow',
      ($4.Follow value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getGroups = $grpc.ClientMethod<$6.GetGroupsRequest, $6.GetGroupsResponse>(
      '/jonline.Jonline/GetGroups',
      ($6.GetGroupsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.GetGroupsResponse.fromBuffer(value));
  static final _$createGroup = $grpc.ClientMethod<$6.Group, $6.Group>(
      '/jonline.Jonline/CreateGroup',
      ($6.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.Group.fromBuffer(value));
  static final _$updateGroup = $grpc.ClientMethod<$6.Group, $6.Group>(
      '/jonline.Jonline/UpdateGroup',
      ($6.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.Group.fromBuffer(value));
  static final _$deleteGroup = $grpc.ClientMethod<$6.Group, $0.Empty>(
      '/jonline.Jonline/DeleteGroup',
      ($6.Group value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getMembers = $grpc.ClientMethod<$6.GetMembersRequest, $6.GetMembersResponse>(
      '/jonline.Jonline/GetMembers',
      ($6.GetMembersRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $6.GetMembersResponse.fromBuffer(value));
  static final _$createMembership = $grpc.ClientMethod<$4.Membership, $4.Membership>(
      '/jonline.Jonline/CreateMembership',
      ($4.Membership value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.Membership.fromBuffer(value));
  static final _$updateMembership = $grpc.ClientMethod<$4.Membership, $4.Membership>(
      '/jonline.Jonline/UpdateMembership',
      ($4.Membership value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $4.Membership.fromBuffer(value));
  static final _$deleteMembership = $grpc.ClientMethod<$4.Membership, $0.Empty>(
      '/jonline.Jonline/DeleteMembership',
      ($4.Membership value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getPosts = $grpc.ClientMethod<$7.GetPostsRequest, $7.GetPostsResponse>(
      '/jonline.Jonline/GetPosts',
      ($7.GetPostsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.GetPostsResponse.fromBuffer(value));
  static final _$createPost = $grpc.ClientMethod<$7.Post, $7.Post>(
      '/jonline.Jonline/CreatePost',
      ($7.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Post.fromBuffer(value));
  static final _$updatePost = $grpc.ClientMethod<$7.Post, $7.Post>(
      '/jonline.Jonline/UpdatePost',
      ($7.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Post.fromBuffer(value));
  static final _$deletePost = $grpc.ClientMethod<$7.Post, $7.Post>(
      '/jonline.Jonline/DeletePost',
      ($7.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Post.fromBuffer(value));
  static final _$starPost = $grpc.ClientMethod<$7.Post, $7.Post>(
      '/jonline.Jonline/StarPost',
      ($7.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Post.fromBuffer(value));
  static final _$unstarPost = $grpc.ClientMethod<$7.Post, $7.Post>(
      '/jonline.Jonline/UnstarPost',
      ($7.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Post.fromBuffer(value));
  static final _$getGroupPosts = $grpc.ClientMethod<$7.GetGroupPostsRequest, $7.GetGroupPostsResponse>(
      '/jonline.Jonline/GetGroupPosts',
      ($7.GetGroupPostsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.GetGroupPostsResponse.fromBuffer(value));
  static final _$createGroupPost = $grpc.ClientMethod<$7.GroupPost, $7.GroupPost>(
      '/jonline.Jonline/CreateGroupPost',
      ($7.GroupPost value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.GroupPost.fromBuffer(value));
  static final _$updateGroupPost = $grpc.ClientMethod<$7.GroupPost, $7.GroupPost>(
      '/jonline.Jonline/UpdateGroupPost',
      ($7.GroupPost value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.GroupPost.fromBuffer(value));
  static final _$deleteGroupPost = $grpc.ClientMethod<$7.GroupPost, $0.Empty>(
      '/jonline.Jonline/DeleteGroupPost',
      ($7.GroupPost value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$getEvents = $grpc.ClientMethod<$8.GetEventsRequest, $8.GetEventsResponse>(
      '/jonline.Jonline/GetEvents',
      ($8.GetEventsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.GetEventsResponse.fromBuffer(value));
  static final _$createEvent = $grpc.ClientMethod<$8.Event, $8.Event>(
      '/jonline.Jonline/CreateEvent',
      ($8.Event value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.Event.fromBuffer(value));
  static final _$updateEvent = $grpc.ClientMethod<$8.Event, $8.Event>(
      '/jonline.Jonline/UpdateEvent',
      ($8.Event value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.Event.fromBuffer(value));
  static final _$deleteEvent = $grpc.ClientMethod<$8.Event, $8.Event>(
      '/jonline.Jonline/DeleteEvent',
      ($8.Event value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.Event.fromBuffer(value));
  static final _$getEventAttendances = $grpc.ClientMethod<$8.GetEventAttendancesRequest, $8.EventAttendances>(
      '/jonline.Jonline/GetEventAttendances',
      ($8.GetEventAttendancesRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.EventAttendances.fromBuffer(value));
  static final _$upsertEventAttendance = $grpc.ClientMethod<$8.EventAttendance, $8.EventAttendance>(
      '/jonline.Jonline/UpsertEventAttendance',
      ($8.EventAttendance value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $8.EventAttendance.fromBuffer(value));
  static final _$deleteEventAttendance = $grpc.ClientMethod<$8.EventAttendance, $0.Empty>(
      '/jonline.Jonline/DeleteEventAttendance',
      ($8.EventAttendance value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$federateProfile = $grpc.ClientMethod<$1.FederatedAccount, $1.FederatedAccount>(
      '/jonline.Jonline/FederateProfile',
      ($1.FederatedAccount value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.FederatedAccount.fromBuffer(value));
  static final _$defederateProfile = $grpc.ClientMethod<$1.FederatedAccount, $0.Empty>(
      '/jonline.Jonline/DefederateProfile',
      ($1.FederatedAccount value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$configureServer = $grpc.ClientMethod<$2.ServerConfiguration, $2.ServerConfiguration>(
      '/jonline.Jonline/ConfigureServer',
      ($2.ServerConfiguration value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.ServerConfiguration.fromBuffer(value));
  static final _$resetData = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/jonline.Jonline/ResetData',
      ($0.Empty value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Empty.fromBuffer(value));
  static final _$streamReplies = $grpc.ClientMethod<$7.Post, $7.Post>(
      '/jonline.Jonline/StreamReplies',
      ($7.Post value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $7.Post.fromBuffer(value));

  JonlineClient(super.channel, {super.options, super.interceptors});

  /// Get the version (from Cargo) of the Jonline service. *Publicly accessible.*
  $grpc.ResponseFuture<$1.GetServiceVersionResponse> getServiceVersion($0.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getServiceVersion, request, options: options);
  }

  /// Gets the Jonline server's configuration. *Publicly accessible.*
  $grpc.ResponseFuture<$2.ServerConfiguration> getServerConfiguration($0.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getServerConfiguration, request, options: options);
  }

  /// Creates a user account and provides a `refresh_token` (along with an `access_token`). *Publicly accessible.*
  $grpc.ResponseFuture<$3.RefreshTokenResponse> createAccount($3.CreateAccountRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createAccount, request, options: options);
  }

  /// Logs in a user and provides a `refresh_token` (along with an `access_token`). *Publicly accessible.*
  $grpc.ResponseFuture<$3.RefreshTokenResponse> login($3.LoginRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$login, request, options: options);
  }

  /// Gets a new `access_token` (and possibly a new `refresh_token`, which should replace the old one in client storage), given a `refresh_token`. *Publicly accessible.*
  $grpc.ResponseFuture<$3.AccessTokenResponse> accessToken($3.AccessTokenRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$accessToken, request, options: options);
  }

  /// Gets the current user. *Authenticated.*
  $grpc.ResponseFuture<$4.User> getCurrentUser($0.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getCurrentUser, request, options: options);
  }

  /// Resets the current user's - or, for admins, a given user's - password. *Authenticated.*
  $grpc.ResponseFuture<$0.Empty> resetPassword($3.ResetPasswordRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$resetPassword, request, options: options);
  }

  /// Gets Media (Images, Videos, etc) uploaded/owned by the current user. *Authenticated.* To upload/download actual Media blob/binary data, use the [HTTP Media APIs](#media).
  $grpc.ResponseFuture<$5.GetMediaResponse> getMedia($5.GetMediaRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getMedia, request, options: options);
  }

  /// Deletes a media item by ID. *Authenticated.* Note that media may still be accessible for 12 hours after deletes are requested, as separate jobs clean it up from S3/MinIO.
  /// Deleting other users' media requires `ADMIN` permissions.
  $grpc.ResponseFuture<$0.Empty> deleteMedia($5.Media request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteMedia, request, options: options);
  }

  /// Gets Users. *Publicly accessible **or** Authenticated.*
  /// Unauthenticated calls only return Users of `GLOBAL_PUBLIC` visibility.
  $grpc.ResponseFuture<$4.GetUsersResponse> getUsers($4.GetUsersRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getUsers, request, options: options);
  }

  /// Update a user by ID. *Authenticated.*
  /// Updating other users requires `ADMIN` permissions.
  $grpc.ResponseFuture<$4.User> updateUser($4.User request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateUser, request, options: options);
  }

  /// Deletes a user by ID. *Authenticated.*
  /// Deleting other users requires `ADMIN` permissions.
  $grpc.ResponseFuture<$0.Empty> deleteUser($4.User request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteUser, request, options: options);
  }

  /// Follow (or request to follow) a user. *Authenticated.*
  $grpc.ResponseFuture<$4.Follow> createFollow($4.Follow request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createFollow, request, options: options);
  }

  /// Used to approve follow requests. *Authenticated.*
  $grpc.ResponseFuture<$4.Follow> updateFollow($4.Follow request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateFollow, request, options: options);
  }

  /// Unfollow (or unrequest) a user. *Authenticated.*
  $grpc.ResponseFuture<$0.Empty> deleteFollow($4.Follow request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteFollow, request, options: options);
  }

  /// Gets Groups. *Publicly accessible **or** Authenticated.*
  /// Unauthenticated calls only return Groups of `GLOBAL_PUBLIC` visibility.
  $grpc.ResponseFuture<$6.GetGroupsResponse> getGroups($6.GetGroupsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getGroups, request, options: options);
  }

  /// Creates a group with the current user as its admin. *Authenticated.*
  /// Requires the `CREATE_GROUPS` permission.
  $grpc.ResponseFuture<$6.Group> createGroup($6.Group request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createGroup, request, options: options);
  }

  /// Update a Groups's information, default membership permissions or moderation. *Authenticated.*
  /// Requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user.
  $grpc.ResponseFuture<$6.Group> updateGroup($6.Group request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateGroup, request, options: options);
  }

  /// Delete a Group. *Authenticated.*
  /// Requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user.
  $grpc.ResponseFuture<$0.Empty> deleteGroup($6.Group request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteGroup, request, options: options);
  }

  /// Get Members (User+Membership) of a Group. *Publicly accessible **or** Authenticated.*
  $grpc.ResponseFuture<$6.GetMembersResponse> getMembers($6.GetMembersRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getMembers, request, options: options);
  }

  /// Requests to join a group (or joins it), or sends an invite to the user. *Authenticated.*
  /// Memberships and moderations are set to their defaults.
  $grpc.ResponseFuture<$4.Membership> createMembership($4.Membership request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createMembership, request, options: options);
  }

  /// Update aspects of a user's membership. *Authenticated.*
  /// Updating permissions requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user.
  /// Updating moderation (approving/denying/banning) requires the same, or `MODERATE_USERS` permissions within the group.
  $grpc.ResponseFuture<$4.Membership> updateMembership($4.Membership request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateMembership, request, options: options);
  }

  /// Leave a group (or cancel membership request). *Authenticated.*
  $grpc.ResponseFuture<$0.Empty> deleteMembership($4.Membership request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteMembership, request, options: options);
  }

  /// Gets Posts. *Publicly accessible **or** Authenticated.*
  /// Unauthenticated calls only return Posts of `GLOBAL_PUBLIC` visibility.
  $grpc.ResponseFuture<$7.GetPostsResponse> getPosts($7.GetPostsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getPosts, request, options: options);
  }

  /// Creates a Post. *Authenticated.*
  $grpc.ResponseFuture<$7.Post> createPost($7.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createPost, request, options: options);
  }

  /// Updates a Post. *Authenticated.*
  $grpc.ResponseFuture<$7.Post> updatePost($7.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updatePost, request, options: options);
  }

  /// (TODO) (Soft) deletes a Post. Returns the deleted version of the Post. *Authenticated.*
  $grpc.ResponseFuture<$7.Post> deletePost($7.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deletePost, request, options: options);
  }

  /// Star a Post. *Unauthenticated.*
  $grpc.ResponseFuture<$7.Post> starPost($7.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$starPost, request, options: options);
  }

  /// Unstar a Post. *Unauthenticated.*
  $grpc.ResponseFuture<$7.Post> unstarPost($7.Post request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$unstarPost, request, options: options);
  }

  /// Get GroupPosts for a Post (and optional group). *Publicly accessible **or** Authenticated.*
  $grpc.ResponseFuture<$7.GetGroupPostsResponse> getGroupPosts($7.GetGroupPostsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getGroupPosts, request, options: options);
  }

  /// Cross-post a Post to a Group. *Authenticated.*
  $grpc.ResponseFuture<$7.GroupPost> createGroupPost($7.GroupPost request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createGroupPost, request, options: options);
  }

  /// Group Moderators: Approve/Reject a GroupPost. *Authenticated.*
  $grpc.ResponseFuture<$7.GroupPost> updateGroupPost($7.GroupPost request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateGroupPost, request, options: options);
  }

  /// Delete a GroupPost. *Authenticated.*
  $grpc.ResponseFuture<$0.Empty> deleteGroupPost($7.GroupPost request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteGroupPost, request, options: options);
  }

  /// Gets Events. *Publicly accessible **or** Authenticated.*
  /// Unauthenticated calls only return Events of `GLOBAL_PUBLIC` visibility.
  $grpc.ResponseFuture<$8.GetEventsResponse> getEvents($8.GetEventsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getEvents, request, options: options);
  }

  /// Creates an Event. *Authenticated.*
  $grpc.ResponseFuture<$8.Event> createEvent($8.Event request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createEvent, request, options: options);
  }

  /// Updates an Event. *Authenticated.*
  $grpc.ResponseFuture<$8.Event> updateEvent($8.Event request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateEvent, request, options: options);
  }

  /// (TODO) (Soft) deletes a Event. Returns the deleted version of the Event. *Authenticated.*
  $grpc.ResponseFuture<$8.Event> deleteEvent($8.Event request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteEvent, request, options: options);
  }

  /// Gets EventAttendances for an EventInstance. *Publicly accessible **or** Authenticated.*
  $grpc.ResponseFuture<$8.EventAttendances> getEventAttendances($8.GetEventAttendancesRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getEventAttendances, request, options: options);
  }

  /// Upsert an EventAttendance. *Publicly accessible **or** Authenticated, with anonymous RSVP support.*
  /// See [EventAttendance](#jonline-EventAttendance) and [AnonymousAttendee](#jonline-AnonymousAttendee)
  /// for details. tl;dr: Anonymous RSVPs may updated/deleted with the `AnonymousAttendee.auth_token`
  /// returned by this RPC (the client should save this for the user, and ideally, offer a link
  /// with the token).
  $grpc.ResponseFuture<$8.EventAttendance> upsertEventAttendance($8.EventAttendance request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$upsertEventAttendance, request, options: options);
  }

  /// Delete an EventAttendance.  *Publicly accessible **or** Authenticated, with anonymous RSVP support.*
  $grpc.ResponseFuture<$0.Empty> deleteEventAttendance($8.EventAttendance request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteEventAttendance, request, options: options);
  }

  /// Federate the current user's profile with another user profile. *Authenticated*.
  $grpc.ResponseFuture<$1.FederatedAccount> federateProfile($1.FederatedAccount request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$federateProfile, request, options: options);
  }

  /// *Authenticated*.
  $grpc.ResponseFuture<$0.Empty> defederateProfile($1.FederatedAccount request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$defederateProfile, request, options: options);
  }

  /// Configure the server (i.e. the response to GetServerConfiguration). *Authenticated.*
  /// Requires `ADMIN` permissions.
  $grpc.ResponseFuture<$2.ServerConfiguration> configureServer($2.ServerConfiguration request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$configureServer, request, options: options);
  }

  /// Delete ALL Media, Posts, Groups and Users except the user who performed the RPC. *Authenticated.*
  /// Requires `ADMIN` permissions.
  /// Note: Server Configuration is not deleted.
  $grpc.ResponseFuture<$0.Empty> resetData($0.Empty request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$resetData, request, options: options);
  }

  /// (TODO) Reply streaming interface. Currently just streams fake example data.
  $grpc.ResponseStream<$7.Post> streamReplies($7.Post request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$streamReplies, $async.Stream.fromIterable([request]), options: options);
  }
}

@$pb.GrpcServiceName('jonline.Jonline')
abstract class JonlineServiceBase extends $grpc.Service {
  $core.String get $name => 'jonline.Jonline';

  JonlineServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GetServiceVersionResponse>(
        'GetServiceVersion',
        getServiceVersion_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GetServiceVersionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $2.ServerConfiguration>(
        'GetServerConfiguration',
        getServerConfiguration_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($2.ServerConfiguration value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.CreateAccountRequest, $3.RefreshTokenResponse>(
        'CreateAccount',
        createAccount_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.CreateAccountRequest.fromBuffer(value),
        ($3.RefreshTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.LoginRequest, $3.RefreshTokenResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.LoginRequest.fromBuffer(value),
        ($3.RefreshTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.AccessTokenRequest, $3.AccessTokenResponse>(
        'AccessToken',
        accessToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.AccessTokenRequest.fromBuffer(value),
        ($3.AccessTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $4.User>(
        'GetCurrentUser',
        getCurrentUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($4.User value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.ResetPasswordRequest, $0.Empty>(
        'ResetPassword',
        resetPassword_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.ResetPasswordRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.GetMediaRequest, $5.GetMediaResponse>(
        'GetMedia',
        getMedia_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.GetMediaRequest.fromBuffer(value),
        ($5.GetMediaResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.Media, $0.Empty>(
        'DeleteMedia',
        deleteMedia_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.Media.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.GetUsersRequest, $4.GetUsersResponse>(
        'GetUsers',
        getUsers_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.GetUsersRequest.fromBuffer(value),
        ($4.GetUsersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.User, $4.User>(
        'UpdateUser',
        updateUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.User.fromBuffer(value),
        ($4.User value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.User, $0.Empty>(
        'DeleteUser',
        deleteUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.User.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Follow, $4.Follow>(
        'CreateFollow',
        createFollow_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Follow.fromBuffer(value),
        ($4.Follow value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Follow, $4.Follow>(
        'UpdateFollow',
        updateFollow_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Follow.fromBuffer(value),
        ($4.Follow value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Follow, $0.Empty>(
        'DeleteFollow',
        deleteFollow_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Follow.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.GetGroupsRequest, $6.GetGroupsResponse>(
        'GetGroups',
        getGroups_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.GetGroupsRequest.fromBuffer(value),
        ($6.GetGroupsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.Group, $6.Group>(
        'CreateGroup',
        createGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.Group.fromBuffer(value),
        ($6.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.Group, $6.Group>(
        'UpdateGroup',
        updateGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.Group.fromBuffer(value),
        ($6.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.Group, $0.Empty>(
        'DeleteGroup',
        deleteGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.Group.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$6.GetMembersRequest, $6.GetMembersResponse>(
        'GetMembers',
        getMembers_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $6.GetMembersRequest.fromBuffer(value),
        ($6.GetMembersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Membership, $4.Membership>(
        'CreateMembership',
        createMembership_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Membership.fromBuffer(value),
        ($4.Membership value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Membership, $4.Membership>(
        'UpdateMembership',
        updateMembership_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Membership.fromBuffer(value),
        ($4.Membership value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.Membership, $0.Empty>(
        'DeleteMembership',
        deleteMembership_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.Membership.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GetPostsRequest, $7.GetPostsResponse>(
        'GetPosts',
        getPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GetPostsRequest.fromBuffer(value),
        ($7.GetPostsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Post, $7.Post>(
        'CreatePost',
        createPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Post.fromBuffer(value),
        ($7.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Post, $7.Post>(
        'UpdatePost',
        updatePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Post.fromBuffer(value),
        ($7.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Post, $7.Post>(
        'DeletePost',
        deletePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Post.fromBuffer(value),
        ($7.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Post, $7.Post>(
        'StarPost',
        starPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Post.fromBuffer(value),
        ($7.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Post, $7.Post>(
        'UnstarPost',
        unstarPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Post.fromBuffer(value),
        ($7.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GetGroupPostsRequest, $7.GetGroupPostsResponse>(
        'GetGroupPosts',
        getGroupPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GetGroupPostsRequest.fromBuffer(value),
        ($7.GetGroupPostsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GroupPost, $7.GroupPost>(
        'CreateGroupPost',
        createGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GroupPost.fromBuffer(value),
        ($7.GroupPost value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GroupPost, $7.GroupPost>(
        'UpdateGroupPost',
        updateGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GroupPost.fromBuffer(value),
        ($7.GroupPost value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GroupPost, $0.Empty>(
        'DeleteGroupPost',
        deleteGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GroupPost.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.GetEventsRequest, $8.GetEventsResponse>(
        'GetEvents',
        getEvents_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GetEventsRequest.fromBuffer(value),
        ($8.GetEventsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Event, $8.Event>(
        'CreateEvent',
        createEvent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Event.fromBuffer(value),
        ($8.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Event, $8.Event>(
        'UpdateEvent',
        updateEvent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Event.fromBuffer(value),
        ($8.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Event, $8.Event>(
        'DeleteEvent',
        deleteEvent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Event.fromBuffer(value),
        ($8.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.GetEventAttendancesRequest, $8.EventAttendances>(
        'GetEventAttendances',
        getEventAttendances_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GetEventAttendancesRequest.fromBuffer(value),
        ($8.EventAttendances value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.EventAttendance, $8.EventAttendance>(
        'UpsertEventAttendance',
        upsertEventAttendance_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.EventAttendance.fromBuffer(value),
        ($8.EventAttendance value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.EventAttendance, $0.Empty>(
        'DeleteEventAttendance',
        deleteEventAttendance_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.EventAttendance.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.FederatedAccount, $1.FederatedAccount>(
        'FederateProfile',
        federateProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.FederatedAccount.fromBuffer(value),
        ($1.FederatedAccount value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.FederatedAccount, $0.Empty>(
        'DefederateProfile',
        defederateProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.FederatedAccount.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.ServerConfiguration, $2.ServerConfiguration>(
        'ConfigureServer',
        configureServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.ServerConfiguration.fromBuffer(value),
        ($2.ServerConfiguration value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'ResetData',
        resetData_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Post, $7.Post>(
        'StreamReplies',
        streamReplies_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $7.Post.fromBuffer(value),
        ($7.Post value) => value.writeToBuffer()));
  }

  $async.Future<$1.GetServiceVersionResponse> getServiceVersion_Pre($grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getServiceVersion($call, await $request);
  }

  $async.Future<$2.ServerConfiguration> getServerConfiguration_Pre($grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getServerConfiguration($call, await $request);
  }

  $async.Future<$3.RefreshTokenResponse> createAccount_Pre($grpc.ServiceCall $call, $async.Future<$3.CreateAccountRequest> $request) async {
    return createAccount($call, await $request);
  }

  $async.Future<$3.RefreshTokenResponse> login_Pre($grpc.ServiceCall $call, $async.Future<$3.LoginRequest> $request) async {
    return login($call, await $request);
  }

  $async.Future<$3.AccessTokenResponse> accessToken_Pre($grpc.ServiceCall $call, $async.Future<$3.AccessTokenRequest> $request) async {
    return accessToken($call, await $request);
  }

  $async.Future<$4.User> getCurrentUser_Pre($grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getCurrentUser($call, await $request);
  }

  $async.Future<$0.Empty> resetPassword_Pre($grpc.ServiceCall $call, $async.Future<$3.ResetPasswordRequest> $request) async {
    return resetPassword($call, await $request);
  }

  $async.Future<$5.GetMediaResponse> getMedia_Pre($grpc.ServiceCall $call, $async.Future<$5.GetMediaRequest> $request) async {
    return getMedia($call, await $request);
  }

  $async.Future<$0.Empty> deleteMedia_Pre($grpc.ServiceCall $call, $async.Future<$5.Media> $request) async {
    return deleteMedia($call, await $request);
  }

  $async.Future<$4.GetUsersResponse> getUsers_Pre($grpc.ServiceCall $call, $async.Future<$4.GetUsersRequest> $request) async {
    return getUsers($call, await $request);
  }

  $async.Future<$4.User> updateUser_Pre($grpc.ServiceCall $call, $async.Future<$4.User> $request) async {
    return updateUser($call, await $request);
  }

  $async.Future<$0.Empty> deleteUser_Pre($grpc.ServiceCall $call, $async.Future<$4.User> $request) async {
    return deleteUser($call, await $request);
  }

  $async.Future<$4.Follow> createFollow_Pre($grpc.ServiceCall $call, $async.Future<$4.Follow> $request) async {
    return createFollow($call, await $request);
  }

  $async.Future<$4.Follow> updateFollow_Pre($grpc.ServiceCall $call, $async.Future<$4.Follow> $request) async {
    return updateFollow($call, await $request);
  }

  $async.Future<$0.Empty> deleteFollow_Pre($grpc.ServiceCall $call, $async.Future<$4.Follow> $request) async {
    return deleteFollow($call, await $request);
  }

  $async.Future<$6.GetGroupsResponse> getGroups_Pre($grpc.ServiceCall $call, $async.Future<$6.GetGroupsRequest> $request) async {
    return getGroups($call, await $request);
  }

  $async.Future<$6.Group> createGroup_Pre($grpc.ServiceCall $call, $async.Future<$6.Group> $request) async {
    return createGroup($call, await $request);
  }

  $async.Future<$6.Group> updateGroup_Pre($grpc.ServiceCall $call, $async.Future<$6.Group> $request) async {
    return updateGroup($call, await $request);
  }

  $async.Future<$0.Empty> deleteGroup_Pre($grpc.ServiceCall $call, $async.Future<$6.Group> $request) async {
    return deleteGroup($call, await $request);
  }

  $async.Future<$6.GetMembersResponse> getMembers_Pre($grpc.ServiceCall $call, $async.Future<$6.GetMembersRequest> $request) async {
    return getMembers($call, await $request);
  }

  $async.Future<$4.Membership> createMembership_Pre($grpc.ServiceCall $call, $async.Future<$4.Membership> $request) async {
    return createMembership($call, await $request);
  }

  $async.Future<$4.Membership> updateMembership_Pre($grpc.ServiceCall $call, $async.Future<$4.Membership> $request) async {
    return updateMembership($call, await $request);
  }

  $async.Future<$0.Empty> deleteMembership_Pre($grpc.ServiceCall $call, $async.Future<$4.Membership> $request) async {
    return deleteMembership($call, await $request);
  }

  $async.Future<$7.GetPostsResponse> getPosts_Pre($grpc.ServiceCall $call, $async.Future<$7.GetPostsRequest> $request) async {
    return getPosts($call, await $request);
  }

  $async.Future<$7.Post> createPost_Pre($grpc.ServiceCall $call, $async.Future<$7.Post> $request) async {
    return createPost($call, await $request);
  }

  $async.Future<$7.Post> updatePost_Pre($grpc.ServiceCall $call, $async.Future<$7.Post> $request) async {
    return updatePost($call, await $request);
  }

  $async.Future<$7.Post> deletePost_Pre($grpc.ServiceCall $call, $async.Future<$7.Post> $request) async {
    return deletePost($call, await $request);
  }

  $async.Future<$7.Post> starPost_Pre($grpc.ServiceCall $call, $async.Future<$7.Post> $request) async {
    return starPost($call, await $request);
  }

  $async.Future<$7.Post> unstarPost_Pre($grpc.ServiceCall $call, $async.Future<$7.Post> $request) async {
    return unstarPost($call, await $request);
  }

  $async.Future<$7.GetGroupPostsResponse> getGroupPosts_Pre($grpc.ServiceCall $call, $async.Future<$7.GetGroupPostsRequest> $request) async {
    return getGroupPosts($call, await $request);
  }

  $async.Future<$7.GroupPost> createGroupPost_Pre($grpc.ServiceCall $call, $async.Future<$7.GroupPost> $request) async {
    return createGroupPost($call, await $request);
  }

  $async.Future<$7.GroupPost> updateGroupPost_Pre($grpc.ServiceCall $call, $async.Future<$7.GroupPost> $request) async {
    return updateGroupPost($call, await $request);
  }

  $async.Future<$0.Empty> deleteGroupPost_Pre($grpc.ServiceCall $call, $async.Future<$7.GroupPost> $request) async {
    return deleteGroupPost($call, await $request);
  }

  $async.Future<$8.GetEventsResponse> getEvents_Pre($grpc.ServiceCall $call, $async.Future<$8.GetEventsRequest> $request) async {
    return getEvents($call, await $request);
  }

  $async.Future<$8.Event> createEvent_Pre($grpc.ServiceCall $call, $async.Future<$8.Event> $request) async {
    return createEvent($call, await $request);
  }

  $async.Future<$8.Event> updateEvent_Pre($grpc.ServiceCall $call, $async.Future<$8.Event> $request) async {
    return updateEvent($call, await $request);
  }

  $async.Future<$8.Event> deleteEvent_Pre($grpc.ServiceCall $call, $async.Future<$8.Event> $request) async {
    return deleteEvent($call, await $request);
  }

  $async.Future<$8.EventAttendances> getEventAttendances_Pre($grpc.ServiceCall $call, $async.Future<$8.GetEventAttendancesRequest> $request) async {
    return getEventAttendances($call, await $request);
  }

  $async.Future<$8.EventAttendance> upsertEventAttendance_Pre($grpc.ServiceCall $call, $async.Future<$8.EventAttendance> $request) async {
    return upsertEventAttendance($call, await $request);
  }

  $async.Future<$0.Empty> deleteEventAttendance_Pre($grpc.ServiceCall $call, $async.Future<$8.EventAttendance> $request) async {
    return deleteEventAttendance($call, await $request);
  }

  $async.Future<$1.FederatedAccount> federateProfile_Pre($grpc.ServiceCall $call, $async.Future<$1.FederatedAccount> $request) async {
    return federateProfile($call, await $request);
  }

  $async.Future<$0.Empty> defederateProfile_Pre($grpc.ServiceCall $call, $async.Future<$1.FederatedAccount> $request) async {
    return defederateProfile($call, await $request);
  }

  $async.Future<$2.ServerConfiguration> configureServer_Pre($grpc.ServiceCall $call, $async.Future<$2.ServerConfiguration> $request) async {
    return configureServer($call, await $request);
  }

  $async.Future<$0.Empty> resetData_Pre($grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return resetData($call, await $request);
  }

  $async.Stream<$7.Post> streamReplies_Pre($grpc.ServiceCall $call, $async.Future<$7.Post> $request) async* {
    yield* streamReplies($call, await $request);
  }

  $async.Future<$1.GetServiceVersionResponse> getServiceVersion($grpc.ServiceCall call, $0.Empty request);
  $async.Future<$2.ServerConfiguration> getServerConfiguration($grpc.ServiceCall call, $0.Empty request);
  $async.Future<$3.RefreshTokenResponse> createAccount($grpc.ServiceCall call, $3.CreateAccountRequest request);
  $async.Future<$3.RefreshTokenResponse> login($grpc.ServiceCall call, $3.LoginRequest request);
  $async.Future<$3.AccessTokenResponse> accessToken($grpc.ServiceCall call, $3.AccessTokenRequest request);
  $async.Future<$4.User> getCurrentUser($grpc.ServiceCall call, $0.Empty request);
  $async.Future<$0.Empty> resetPassword($grpc.ServiceCall call, $3.ResetPasswordRequest request);
  $async.Future<$5.GetMediaResponse> getMedia($grpc.ServiceCall call, $5.GetMediaRequest request);
  $async.Future<$0.Empty> deleteMedia($grpc.ServiceCall call, $5.Media request);
  $async.Future<$4.GetUsersResponse> getUsers($grpc.ServiceCall call, $4.GetUsersRequest request);
  $async.Future<$4.User> updateUser($grpc.ServiceCall call, $4.User request);
  $async.Future<$0.Empty> deleteUser($grpc.ServiceCall call, $4.User request);
  $async.Future<$4.Follow> createFollow($grpc.ServiceCall call, $4.Follow request);
  $async.Future<$4.Follow> updateFollow($grpc.ServiceCall call, $4.Follow request);
  $async.Future<$0.Empty> deleteFollow($grpc.ServiceCall call, $4.Follow request);
  $async.Future<$6.GetGroupsResponse> getGroups($grpc.ServiceCall call, $6.GetGroupsRequest request);
  $async.Future<$6.Group> createGroup($grpc.ServiceCall call, $6.Group request);
  $async.Future<$6.Group> updateGroup($grpc.ServiceCall call, $6.Group request);
  $async.Future<$0.Empty> deleteGroup($grpc.ServiceCall call, $6.Group request);
  $async.Future<$6.GetMembersResponse> getMembers($grpc.ServiceCall call, $6.GetMembersRequest request);
  $async.Future<$4.Membership> createMembership($grpc.ServiceCall call, $4.Membership request);
  $async.Future<$4.Membership> updateMembership($grpc.ServiceCall call, $4.Membership request);
  $async.Future<$0.Empty> deleteMembership($grpc.ServiceCall call, $4.Membership request);
  $async.Future<$7.GetPostsResponse> getPosts($grpc.ServiceCall call, $7.GetPostsRequest request);
  $async.Future<$7.Post> createPost($grpc.ServiceCall call, $7.Post request);
  $async.Future<$7.Post> updatePost($grpc.ServiceCall call, $7.Post request);
  $async.Future<$7.Post> deletePost($grpc.ServiceCall call, $7.Post request);
  $async.Future<$7.Post> starPost($grpc.ServiceCall call, $7.Post request);
  $async.Future<$7.Post> unstarPost($grpc.ServiceCall call, $7.Post request);
  $async.Future<$7.GetGroupPostsResponse> getGroupPosts($grpc.ServiceCall call, $7.GetGroupPostsRequest request);
  $async.Future<$7.GroupPost> createGroupPost($grpc.ServiceCall call, $7.GroupPost request);
  $async.Future<$7.GroupPost> updateGroupPost($grpc.ServiceCall call, $7.GroupPost request);
  $async.Future<$0.Empty> deleteGroupPost($grpc.ServiceCall call, $7.GroupPost request);
  $async.Future<$8.GetEventsResponse> getEvents($grpc.ServiceCall call, $8.GetEventsRequest request);
  $async.Future<$8.Event> createEvent($grpc.ServiceCall call, $8.Event request);
  $async.Future<$8.Event> updateEvent($grpc.ServiceCall call, $8.Event request);
  $async.Future<$8.Event> deleteEvent($grpc.ServiceCall call, $8.Event request);
  $async.Future<$8.EventAttendances> getEventAttendances($grpc.ServiceCall call, $8.GetEventAttendancesRequest request);
  $async.Future<$8.EventAttendance> upsertEventAttendance($grpc.ServiceCall call, $8.EventAttendance request);
  $async.Future<$0.Empty> deleteEventAttendance($grpc.ServiceCall call, $8.EventAttendance request);
  $async.Future<$1.FederatedAccount> federateProfile($grpc.ServiceCall call, $1.FederatedAccount request);
  $async.Future<$0.Empty> defederateProfile($grpc.ServiceCall call, $1.FederatedAccount request);
  $async.Future<$2.ServerConfiguration> configureServer($grpc.ServiceCall call, $2.ServerConfiguration request);
  $async.Future<$0.Empty> resetData($grpc.ServiceCall call, $0.Empty request);
  $async.Stream<$7.Post> streamReplies($grpc.ServiceCall call, $7.Post request);
}
