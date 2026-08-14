// This is a generated file - do not edit.
//
// Generated from jonline.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $0;

import 'authentication.pb.dart' as $3;
import 'events.pb.dart' as $9;
import 'federation.pb.dart' as $1;
import 'groups.pb.dart' as $7;
import 'media.pb.dart' as $5;
import 'messages.pb.dart' as $6;
import 'posts.pb.dart' as $8;
import 'server_configuration.pb.dart' as $2;
import 'users.pb.dart' as $4;

export 'jonline.pb.dart';

/// [Jonline](https://github.com/JonLatane/jonline) is a social media protocol with support for Users (and Follows), Media, Posts, Events, Groups, and Messages. It is designed to be federated,
/// but does not require federation to be a useful next-gen forum type solution.
/// It is designed to be used with a variety of frontends, including web, mobile, and desktop applications. It interoperates across numerous ports, protocols, and formats, including
/// gRPC, HTTP, HTTPS, and ICS/iCal, and is designed to link with SMTP via Stalwart (and other SMTP servers/providers), Facebook Page APIs for post ing Events, and more.
/// Essentially, your server is your own customizable, self-contained social network.
///
/// Jonline is designed to be easy to run and deploy yourself with a [2 minute setup with Homebrew](#2-minute-startup-with-homebrew) and [3 minute setup on Linux](#3-minute-startup-on-linux),
/// [images](https://hub.docker.com/r/jonlatane/jonline/tags) on [DockerHub](https://hub.docker.com/r/jonlatane/jonline_preview_generator/tags) and deployment to your K8s clusters available via
/// a simple but powerful `Makefile`-based design language.
///
/// #### Ports
/// Jonline servers interact across several ports:
/// * [gRPC (27707)](#grpc-api) - The main Jonline gRPC API. This is the primary port for all Jonline clients. It may or may not be TLS-enabled (443).
///      * Clients are expected to negotiate the gRPC host via the [`backend_host` HTTP endpoint (see below)](#http-based-client-host-negotiation-for-external-cdns) on port 80/443.
/// * [HTTP (80, 8000, 27705), HTTPS (443)](#http-endpoints) - The main Jonline HTTP API. This is used for some endpoints, including media upload/download, and for negotiating the gRPC host.
///      * Port 443 will serve up a secure HTTPS server. If it fails to startup, Jonline handles this gracefully and degrades to plain HTTP.
///      * Port 80 will serve up either an unsecured set of Jonline's HTTP endpoints, or a redirect to the HTTPS/443 server if that one launched successfully.
///      * Port 8000 *always* serves up an unsecured Jonline UI, in case something goes horribly wrong with 80 and 443. It can probably not be exposed in your load balancer/to the web.
///      * Port 27705 is an unsecured HTTP server meant for communication with other non-web facing services on your computer or in your cluster. It should not be exposed to the web.
///          * Currently this just has an `/email` endpoint. It is designed for [email support via an integration with Stalwart](https://github.com/JonLatane/jonline/tree/main/deploys/email).
///
/// #### API Design Notes
/// ##### Moderation and Visibility
/// Jonline APIs are designed to support `Moderation` and `Visibility` controls at the level of individual entities. However, to keep things
/// DRY, moderation and visibility controls are only implemented for `User`s, `Media`, `Group`s, and `Post`s.
///
/// `Event`s and future `Post`-like types simply use the same implementation as their contained `Post`s. The intent here is to maximize
/// both shared code and implementation robustness.
///
/// ##### Composition Over Inheritance
/// Jonline's APIs are designed using composition over inheritance. For instance, an `Event` contains
/// a `Post` rather than extending it. This pattern fits well all the way from the data model (very boring, safe, and normalized),
/// through Rust code implementing APIs, to both functional React code and more-OOP Flutter code equally well.
///
/// ##### Predictable Atomicity
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
/// #### Core Types
/// Jonline's data model centers around a handful of top-level types, most of which carry their own
/// [`Visibility`](#jonline-Visibility) and [`Moderation`](#jonline-Moderation) state and can be organized into
/// [`Group`](#jonline-Group)s.
///
/// ##### User
/// A [`User`](#jonline-User) is a Jonline account: username, real name, bio, avatar, contact methods, and
/// [`Permission`](#jonline-Permission)s, plus counts (followers, posts, events, etc.) and federation info (see
/// [Federated Profiles](#federated-profiles) above). A lighter-weight [`Author`](#jonline-Author) (just ID, username,
/// avatar, real name, permissions) is embedded on [`Post`](#jonline-Post)s, [`Message`](#jonline-Message)s, and similar
/// content types instead of a full `User`, to keep those payloads small.
///
/// - **Follows**: A [`Follow`](#jonline-Follow) is one `User` following another, optionally subject to the target's moderation
/// (i.e. approval). Mutual follows make two users "friends." Follows also drive the `FOLLOWING_POSTS`/`FOLLOWING_EVENTS`
/// listing types and `LIMITED`-visibility content.
///
/// - **Memberships**: A [`Membership`](#jonline-Membership) is a `User`'s membership (or pending join request/invitation)
/// in a `Group`, tracking the user's `Permission`s within the group plus separate group-side and user-side `Moderation`
/// (for join-approval flows). Returned as part of `User`/`Group` payloads, and via `Member` when listing a Group's members.
///
///
/// - **EventSyncSources**: A `User` can own many [`EventSyncSource`](#jonline-EventSyncSource)s - external calendars to
/// pull `Event`s in from, e.g. an iCal subscription. See the Event section below for how these attach to `Event`s.
///
/// - **EventSyncDestinations**: A `User` can also own many [`EventSyncDestination`](#jonline-EventSyncDestination)s -
/// external targets to push `EventInstance`s out to, e.g. a connected Facebook Page (configured via
/// [`FacebookPage`](#jonline-FacebookPage)). See the Event section below for how these attach to `EventInstance`s.
///
/// ##### Media
/// [`Media`](#jonline-Media) represents an uploaded (or server-generated) photo or video. Unlike other types, Media
/// content itself is *not* served over gRPC - it's uploaded/downloaded via plain HTTP (`POST`/`GET /media`) - while
/// its metadata (content type, name, visibility, moderation) is managed like any other Jonline type. Other messages
/// (like `User.avatar`, `Group.avatar`, and `Post.media`) reference Media via the lightweight `MediaReference` type.
///
/// ##### Post
/// [`Post`](#jonline-Post) is Jonline's fundamental content/building-block type: it's what actually carries a
/// title/link/content body, visibility, and moderation, and is reused (via `PostContext`) as the backing data for
/// replies, [`Event`](#jonline-Event)s, and `EventInstance`s alike. Posts can be replied to (threaded via
/// `reply_to_post_id`), cross-posted to `Group`s (`GroupPost`), and shared directly with users (`UserPost`).
///
/// - **GroupPosts**: A [`GroupPost`](#jonline-GroupPost) is the cross-posting of a `Post` into a `Group`, carrying the group-specific
/// moderation status and who shared it, separately from the Post's own (author-set) visibility/moderation.
///
/// - **UserPosts**: A [`UserPost`](#jonline-UserPost) is a "direct share" of a `Post` to a `User` (see also `DIRECT`
/// [`Visibility`](#jonline-Visibility)). Currently unused/unimplemented.
///
/// ##### Event
/// An [`Event`](#jonline-Event) is a wrapper for *at least two* `Post`s. It always has its own top-level `Post`
/// (`PostContext.EVENT`, holding the event's overall title/description) *and* it must have at least one
/// [`EventInstance`](#jonline-EventInstance) (see below), each of which in turn must have its own `Post`
/// (`PostContext.EVENT_INSTANCE`, carrying that instance's start/end time, `Location`, and optional per-instance
/// title/link/content override). So the smallest possible Event already backs 2 Posts, and events with recurring/multiple
/// instances back one Post per instance beyond that.
///
/// - **EventInstances**: An [`EventInstance`](#jonline-EventInstance) is the actual time-boxed occurrence of an `Event` -
/// it carries the `starts_at`/`ends_at` timestamps and optional `Location` that the parent `Event` itself does not have.
/// An `Event` with zero instances is meaningless (no time or place to attach to), so every `Event` must have at least one.
///
///     - **EventAttendances**: An [`EventAttendance`](#jonline-EventAttendance) (an "RSVP") tracks one attendee's status
///     (`INTERESTED`, `REQUESTED`, `GOING`, `NOT_GOING`) for a specific `EventInstance`. Attendees may be logged-in `User`s
///     or anonymous (tracked via `AnonymousAttendee` plus an `auth_token`), and are subject to their own `Moderation`,
///     independent of the Event's/Instance's own Post moderation.
///
///     - **EventSyncSource**: It's actually the parent `Event` (not the `EventInstance`) that can be synced *in* from a
///     user-owned [`EventSyncSource`](#jonline-EventSyncSource) (e.g. an iCal subscription). The relationship is
///     1:(0 or 1): a single source can back many synced `Event`s, but each `Event` has *at most one* source it came from
///     (`Event.event_sync_source` is a single optional field, not repeated).
///
///     - **EventSyncDestinations**: Conversely, it's each `EventInstance` (not the parent `Event`) that syncs *out* to
///     [`EventSyncDestination`](#jonline-EventSyncDestination)s (e.g. connected Facebook Pages). Unlike `EventSyncSource`,
///     this is the outlier's counterpart - a many-to-many relationship: each instance may push to several destinations
///     at once, tracked per-destination via the repeated `EventInstance.sync_destinations`
///     (each a [`EventInstanceSyncDestination`](#jonline-EventInstanceSyncDestination), carrying the destination's
///     resulting post ID/URL and last-synced time).
///
/// ##### Group
/// A [`Group`](#jonline-Group) organizes `User`s, `Post`s, and `Event`s together under shared visibility, moderation,
/// and permission defaults.
///
/// - **Memberships**: A [`Membership`](#jonline-Membership) is a `User`'s membership (or pending join request/invitation)
/// in a `Group`, tracking the user's `Permission`s within the group plus separate group-side and user-side `Moderation`
/// (for join-approval flows). Returned as part of `User`/`Group` payloads, and via `Member` when listing a Group's members.
///
/// - **GroupPosts**: A [`GroupPost`](#jonline-GroupPost) is the cross-posting of a `Post` into a `Group`, carrying the group-specific
/// moderation status and who shared it, separately from the Post's own (author-set) visibility/moderation.
///
/// ##### Message
/// [`Message`](#jonline-Message) is Jonline's "low trust" messaging/email system, meant to let strangers on a server
/// make first contact (e.g. via email, with no account required) before moving to a more trusted channel. Admins have
/// open access to all Messages on a server.
///
/// - **MessagingGroup**: A [`MessagingGroup`](#jonline-MessagingGroup) is the set of participants in a Message conversation. Every `Message`
/// belongs to one; if a client wasn't a visible recipient (e.g. they were BCC'ed), the `Message` they receive omits it.
///
/// #### Authentication
/// Jonline uses a standard OAuth2 flow (over gRPC) for authentication, with rotating `access_token`s and `refresh_token`s.
/// Authenticated calls require an `access_token` in request metadata to be included / directly as the value of the
/// `authorization` header (no `Bearer ` prefix).
///
/// First, use the [`CreateAccount`](#grpc-api-CreateAccount) or [`Login`](#grpc-api-Login) RPCs to fetch (and store) an initial
/// `refresh_token` and `access_token`. Clients should use the `access_token` until it expires,
/// then use the `refresh_token` to call the [`AccessToken`](#grpc-api-AccessToken) RPC for a new one. (The `AccessToken` RPC
/// may, at random, also return a new `refresh_token`. If so, it should immediately replace the old
/// one in client storage.)
///
/// #### Federation
/// Whereas other federated social networks (e.g. ActivityPub) have both client-server and server-server APIs,
/// Jonline only has client-server APIs. While server-to-server communication is possible, nothing but some
/// "nice to have" features require it, so it is not used.
///
/// ##### Federated Servers
/// Jonline servers can recommend other servers to clients with the `federation_info` field (a [`FederationInfo` message](http://localhost/docs/protocol#federationinfo)) in [`ServerConfiguration`](#jonline-ServerConfiguration).
/// Clients can use this information to discover other servers, or users can add new servers manually.
/// Note that, at least for web clients, this means everything is subject to CORS. In the future, Jonline will
/// allow CORS to be configured in a "strict" mode, so someone else's Jonline server cannot be used to access your server's data
/// unless you explicitly allow it.
///
/// ##### Federated Profiles
/// Jonline users can federate with users on any other Jonline server. This works by two-way verification:
/// For example, Jon has the user [`jonline.io/jon`](https://jonline.io/jon), [`oakcity.social/jon`](https://oakcity.social/jon),
/// and [`bullcity.social/jon`](https://bullcity.social/jon) associated with one another.
/// The UI will only show federated profiles if *both use profiles* have federated with one another.
///
/// This mechanism also allows users to link multiple profiles on the same server together. For instance, [`bullcity.social/jon`](https://bullcity.social/jon)
/// and [`bullcity.social/openmic`](https://bullcity.social/openmic) are linked together, but [`bullcity.social/openmic`](https://bullcity.social/openmic)
/// isn't linked to [`jonline.io/jon`](https://jonline.io/jon) or [`oakcity.social/jon`](https://oakcity.social/jon).
///
/// Federated profiles are managed via the `federated_profiles` field (a `repeated` [`FederatedAccount`](http://localhost/docs/protocol#jonline-FederatedAccount)) in the [`User`](#jonline-User) message.
///
/// #### HTTP Endpoints
///
/// ##### iCalendar/RFC5545 (`GET /calendar.ics`, `GET /calendar.ics?user_id={id}`)
/// Jonline events support iCalendar/RFC5545. Only public events are included in the calendar.
/// Users can "subscribe" to a Jonline server at, for instance, `https://jonline.io/calendar.ics`
/// to get a calendar of all public events on the server.
/// Users can also subscribe to a user's calendar at, for instance, `https://jonline.io/calendar.ics?user_id=CruFm`
/// to get a calendar of all public events for that user.
/// In the Tamagui/React frontend, links to the ICS endpoints are provided in the Upcoming Events section of the home page,
/// the Events page, and the user profile pages for all users with events in the last 3 months (or in the future).
///
/// ##### Robots & Sitemap (`GET /robots.txt` and `GET /sitemap.xml`)
/// Jonline servers are expected to serve a `robots.txt` file at `/robots.txt` and a `sitemap.xml` file at `/sitemap.xml`.
///
/// ##### Favicons (`GET /favicon.ico`, `GET /favicon.png`)
/// Favicons in a couple of formats.
///
/// ##### Media (`GET /media/{id}` and `POST /media`)
/// See the [Media](#jonline-Media) section for details on how to upload/download media files.
///
/// ##### HTTP-based client host negotiation (for external CDNs) (`GET /backend_host`)
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
/// ### gRPC API
@$pb.GrpcServiceName('jonline.Jonline')
class JonlineClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  JonlineClient(super.channel, {super.options, super.interceptors});

  /// Get the version (from Cargo) of the Jonline service. *Publicly accessible.*
  $grpc.ResponseFuture<$1.GetServiceVersionResponse> getServiceVersion(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getServiceVersion, request, options: options);
  }

  /// Gets the Jonline server's configuration. *Publicly accessible.*
  $grpc.ResponseFuture<$2.ServerConfiguration> getServerConfiguration(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getServerConfiguration, request,
        options: options);
  }

  /// Creates a user account and provides a `refresh_token` (along with an `access_token`). *Publicly accessible.*
  $grpc.ResponseFuture<$3.RefreshTokenResponse> createAccount(
    $3.CreateAccountRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createAccount, request, options: options);
  }

  /// Logs in a user and provides a `refresh_token` (along with an `access_token`). *Publicly accessible.*
  $grpc.ResponseFuture<$3.RefreshTokenResponse> login(
    $3.LoginRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$login, request, options: options);
  }

  /// Gets a new `access_token` (and possibly a new `refresh_token`, which should replace the old one in client storage), given a `refresh_token`. *Publicly accessible.*
  $grpc.ResponseFuture<$3.AccessTokenResponse> accessToken(
    $3.AccessTokenRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$accessToken, request, options: options);
  }

  /// Gets the current user. *Authenticated.*
  $grpc.ResponseFuture<$4.User> getCurrentUser(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getCurrentUser, request, options: options);
  }

  /// Resets the current user's - or, for admins, a given user's - password. *Authenticated.*
  $grpc.ResponseFuture<$0.Empty> resetPassword(
    $3.ResetPasswordRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$resetPassword, request, options: options);
  }

  /// Gets Media (Images, Videos, etc) uploaded/owned by the current user. *Authenticated.* To upload/download actual Media blob/binary data, use the [HTTP Media APIs](#media).
  $grpc.ResponseFuture<$5.GetMediaResponse> getMedia(
    $5.GetMediaRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getMedia, request, options: options);
  }

  /// Deletes a media item by ID. *Authenticated.* Note that media may still be accessible for 12 hours after deletes are requested, as separate jobs clean it up from S3/MinIO.
  /// Deleting other users' media requires `ADMIN` permissions.
  $grpc.ResponseFuture<$0.Empty> deleteMedia(
    $5.Media request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteMedia, request, options: options);
  }

  /// Gets Users. *Publicly accessible **or** Authenticated.*
  /// Unauthenticated calls only return Users of `GLOBAL_PUBLIC` visibility.
  $grpc.ResponseFuture<$4.GetUsersResponse> getUsers(
    $4.GetUsersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getUsers, request, options: options);
  }

  /// Update a user by ID. *Authenticated.*
  /// Updating other users requires `ADMIN` permissions.
  $grpc.ResponseFuture<$4.User> updateUser(
    $4.User request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateUser, request, options: options);
  }

  /// Deletes a user by ID. *Authenticated.*
  /// Deleting other users requires `ADMIN` permissions.
  $grpc.ResponseFuture<$0.Empty> deleteUser(
    $4.User request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteUser, request, options: options);
  }

  /// Sends a Message to one or more recipients (creating/reusing their MessagingGroup). *Publicly
  /// accessible **or** Authenticated.* Like `CreatePost`/`CreateEvent`, authentication (if any) is via
  /// a standard `access_token`; unauthenticated calls are simply sent with no `sender`.
  $grpc.ResponseFuture<$6.Message> sendMessage(
    $6.SendMessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendMessage, request, options: options);
  }

  /// Gets Messages. *Authenticated.*
  /// `PERSONAL_MESSAGES(_TEXT_SEARCH)` (and looking up a single Message/MessagingGroup) requires the
  /// `READ_PERSONAL_MESSAGES` permission and only returns Messages the current user sent or received.
  /// `ALL_SYSTEM_MESSAGES(_TEXT_SEARCH)` requires the `READ_ALL_SYSTEM_MESSAGES` permission and returns
  /// every Message on the server.
  $grpc.ResponseFuture<$6.GetMessagesResponse> getMessages(
    $6.GetMessagesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getMessages, request, options: options);
  }

  /// Follow (or request to follow) a user. *Authenticated.*
  $grpc.ResponseFuture<$4.Follow> createFollow(
    $4.Follow request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createFollow, request, options: options);
  }

  /// Used to approve follow requests. *Authenticated.*
  $grpc.ResponseFuture<$4.Follow> updateFollow(
    $4.Follow request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateFollow, request, options: options);
  }

  /// Unfollow (or unrequest) a user. *Authenticated.*
  $grpc.ResponseFuture<$0.Empty> deleteFollow(
    $4.Follow request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteFollow, request, options: options);
  }

  /// Gets Groups. *Publicly accessible **or** Authenticated.*
  /// Unauthenticated calls only return Groups of `GLOBAL_PUBLIC` visibility.
  $grpc.ResponseFuture<$7.GetGroupsResponse> getGroups(
    $7.GetGroupsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getGroups, request, options: options);
  }

  /// Creates a group with the current user as its admin. *Authenticated.*
  /// Requires the `CREATE_GROUPS` permission.
  $grpc.ResponseFuture<$7.Group> createGroup(
    $7.Group request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createGroup, request, options: options);
  }

  /// Update a Groups's information, default membership permissions or moderation. *Authenticated.*
  /// Requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user.
  $grpc.ResponseFuture<$7.Group> updateGroup(
    $7.Group request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateGroup, request, options: options);
  }

  /// Delete a Group. *Authenticated.*
  /// Requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user.
  $grpc.ResponseFuture<$0.Empty> deleteGroup(
    $7.Group request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteGroup, request, options: options);
  }

  /// Get Members (User+Membership) of a Group. *Publicly accessible **or** Authenticated.*
  $grpc.ResponseFuture<$7.GetMembersResponse> getMembers(
    $7.GetMembersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getMembers, request, options: options);
  }

  /// Requests to join a group (or joins it), or sends an invite to the user. *Authenticated.*
  /// Memberships and moderations are set to their defaults.
  $grpc.ResponseFuture<$4.Membership> createMembership(
    $4.Membership request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createMembership, request, options: options);
  }

  /// Update aspects of a user's membership. *Authenticated.*
  /// Updating permissions requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user.
  /// Updating moderation (approving/denying/banning) requires the same, or `MODERATE_USERS` permissions within the group.
  $grpc.ResponseFuture<$4.Membership> updateMembership(
    $4.Membership request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateMembership, request, options: options);
  }

  /// Leave a group (or cancel membership request). *Authenticated.*
  $grpc.ResponseFuture<$0.Empty> deleteMembership(
    $4.Membership request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteMembership, request, options: options);
  }

  /// Gets Posts. *Publicly accessible **or** Authenticated.*
  /// Unauthenticated calls only return Posts of `GLOBAL_PUBLIC` visibility.
  $grpc.ResponseFuture<$8.GetPostsResponse> getPosts(
    $8.GetPostsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getPosts, request, options: options);
  }

  /// Creates a Post. *Authenticated.*
  $grpc.ResponseFuture<$8.Post> createPost(
    $8.Post request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createPost, request, options: options);
  }

  /// Updates a Post. *Authenticated.*
  $grpc.ResponseFuture<$8.Post> updatePost(
    $8.Post request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updatePost, request, options: options);
  }

  /// (TODO) (Soft) deletes a Post. Returns the deleted version of the Post. *Authenticated.*
  $grpc.ResponseFuture<$8.Post> deletePost(
    $8.Post request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deletePost, request, options: options);
  }

  /// Star a Post. *Unauthenticated.*
  $grpc.ResponseFuture<$8.Post> starPost(
    $8.Post request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$starPost, request, options: options);
  }

  /// Unstar a Post. *Unauthenticated.*
  $grpc.ResponseFuture<$8.Post> unstarPost(
    $8.Post request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$unstarPost, request, options: options);
  }

  /// Get GroupPosts for a Post (and optional group). *Publicly accessible **or** Authenticated.*
  $grpc.ResponseFuture<$8.GetGroupPostsResponse> getGroupPosts(
    $8.GetGroupPostsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getGroupPosts, request, options: options);
  }

  /// Cross-post a Post to a Group. *Authenticated.*
  $grpc.ResponseFuture<$8.GroupPost> createGroupPost(
    $8.GroupPost request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createGroupPost, request, options: options);
  }

  /// Group Moderators: Approve/Reject a GroupPost. *Authenticated.*
  $grpc.ResponseFuture<$8.GroupPost> updateGroupPost(
    $8.GroupPost request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateGroupPost, request, options: options);
  }

  /// Delete a GroupPost. *Authenticated.*
  $grpc.ResponseFuture<$0.Empty> deleteGroupPost(
    $8.GroupPost request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteGroupPost, request, options: options);
  }

  /// Gets Events. *Publicly accessible **or** Authenticated.*
  /// Unauthenticated calls only return Events of `GLOBAL_PUBLIC` visibility.
  $grpc.ResponseFuture<$9.GetEventsResponse> getEvents(
    $9.GetEventsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getEvents, request, options: options);
  }

  /// Creates an Event. *Authenticated.*
  $grpc.ResponseFuture<$9.Event> createEvent(
    $9.Event request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createEvent, request, options: options);
  }

  /// Updates an Event. *Authenticated.*
  $grpc.ResponseFuture<$9.Event> updateEvent(
    $9.Event request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateEvent, request, options: options);
  }

  /// (TODO) (Soft) deletes a Event. Returns the deleted version of the Event. *Authenticated.*
  $grpc.ResponseFuture<$9.Event> deleteEvent(
    $9.Event request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteEvent, request, options: options);
  }

  /// Gets a user's EventSyncSources. *Authenticated* (self, or Admin for any user).
  $grpc.ResponseFuture<$9.GetEventSyncSourcesResponse> getEventSyncSources(
    $4.User request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getEventSyncSources, request, options: options);
  }

  /// Creates an EventSyncSource for the current user. *Authenticated*, requires `SYNCHRONIZE_EVENTS` (or Admin).
  $grpc.ResponseFuture<$4.EventSyncSource> createEventSyncSource(
    $4.EventSyncSource request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createEventSyncSource, request, options: options);
  }

  /// Updates an EventSyncSource. *Authenticated* (owner, or Admin for any user's), requires `SYNCHRONIZE_EVENTS` (or Admin).
  $grpc.ResponseFuture<$4.EventSyncSource> updateEventSyncSource(
    $4.EventSyncSource request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateEventSyncSource, request, options: options);
  }

  /// Deletes an EventSyncSource. *Authenticated* (owner, or Admin).
  $grpc.ResponseFuture<$0.Empty> deleteEventSyncSource(
    $9.DeleteEventSyncSourceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteEventSyncSource, request, options: options);
  }

  /// Gets a user's EventSyncDestinations. *Authenticated* (self, or Admin for any user).
  $grpc.ResponseFuture<$9.GetEventSyncDestinationsResponse>
      getEventSyncDestinations(
    $4.User request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getEventSyncDestinations, request,
        options: options);
  }

  /// Creates an EventSyncDestination for the current user. *Authenticated*, requires `SYNC_EVENTS_TO_FACEBOOK` (or Admin).
  $grpc.ResponseFuture<$4.EventSyncDestination> createEventSyncDestination(
    $4.EventSyncDestination request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createEventSyncDestination, request,
        options: options);
  }

  /// Updates an EventSyncDestination. *Authenticated* (owner, or Admin for any user's), requires `SYNC_EVENTS_TO_FACEBOOK` (or Admin).
  $grpc.ResponseFuture<$4.EventSyncDestination> updateEventSyncDestination(
    $4.EventSyncDestination request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateEventSyncDestination, request,
        options: options);
  }

  /// Deletes an EventSyncDestination. *Authenticated* (owner, or Admin).
  $grpc.ResponseFuture<$0.Empty> deleteEventSyncDestination(
    $9.DeleteEventSyncDestinationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteEventSyncDestination, request,
        options: options);
  }

  /// Syncs (cross-posts) an EventInstance to an EventSyncDestination. *Authenticated* (destination owner, or Admin), requires `SYNC_EVENTS_TO_FACEBOOK` (or Admin).
  $grpc.ResponseFuture<$9.EventInstance> syncEventInstance(
    $9.SyncEventInstanceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$syncEventInstance, request, options: options);
  }

  /// Gets EventAttendances for an EventInstance. *Publicly accessible **or** Authenticated.*
  $grpc.ResponseFuture<$9.EventAttendances> getEventAttendances(
    $9.GetEventAttendancesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getEventAttendances, request, options: options);
  }

  /// Upsert an EventAttendance. *Publicly accessible **or** Authenticated, with anonymous RSVP support.*
  /// See [EventAttendance](#jonline-EventAttendance) and [AnonymousAttendee](#jonline-AnonymousAttendee)
  /// for details. tl;dr: Anonymous RSVPs may updated/deleted with the `AnonymousAttendee.auth_token`
  /// returned by this RPC (the client should save this for the user, and ideally, offer a link
  /// with the token).
  $grpc.ResponseFuture<$9.EventAttendance> upsertEventAttendance(
    $9.EventAttendance request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$upsertEventAttendance, request, options: options);
  }

  /// Delete an EventAttendance.  *Publicly accessible **or** Authenticated, with anonymous RSVP support.*
  $grpc.ResponseFuture<$0.Empty> deleteEventAttendance(
    $9.EventAttendance request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteEventAttendance, request, options: options);
  }

  /// Federate the current user's profile with another user profile. *Authenticated*.
  $grpc.ResponseFuture<$1.FederatedAccount> federateProfile(
    $1.FederatedAccount request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$federateProfile, request, options: options);
  }

  /// *Authenticated*.
  $grpc.ResponseFuture<$0.Empty> defederateProfile(
    $1.FederatedAccount request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$defederateProfile, request, options: options);
  }

  /// Configure the server (i.e. the response to GetServerConfiguration). *Authenticated.*
  /// Requires `ADMIN` permissions.
  $grpc.ResponseFuture<$2.ServerConfiguration> configureServer(
    $2.ServerConfiguration request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$configureServer, request, options: options);
  }

  /// Delete ALL Media, Posts, Groups and Users except the user who performed the RPC. *Authenticated.*
  /// Requires `ADMIN` permissions.
  /// Note: Server Configuration is not deleted.
  $grpc.ResponseFuture<$0.Empty> resetData(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$resetData, request, options: options);
  }

  /// (TODO) Reply streaming interface. Currently just streams fake example data.
  $grpc.ResponseStream<$8.Post> streamReplies(
    $8.Post request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamReplies, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getServiceVersion =
      $grpc.ClientMethod<$0.Empty, $1.GetServiceVersionResponse>(
          '/jonline.Jonline/GetServiceVersion',
          ($0.Empty value) => value.writeToBuffer(),
          $1.GetServiceVersionResponse.fromBuffer);
  static final _$getServerConfiguration =
      $grpc.ClientMethod<$0.Empty, $2.ServerConfiguration>(
          '/jonline.Jonline/GetServerConfiguration',
          ($0.Empty value) => value.writeToBuffer(),
          $2.ServerConfiguration.fromBuffer);
  static final _$createAccount =
      $grpc.ClientMethod<$3.CreateAccountRequest, $3.RefreshTokenResponse>(
          '/jonline.Jonline/CreateAccount',
          ($3.CreateAccountRequest value) => value.writeToBuffer(),
          $3.RefreshTokenResponse.fromBuffer);
  static final _$login =
      $grpc.ClientMethod<$3.LoginRequest, $3.RefreshTokenResponse>(
          '/jonline.Jonline/Login',
          ($3.LoginRequest value) => value.writeToBuffer(),
          $3.RefreshTokenResponse.fromBuffer);
  static final _$accessToken =
      $grpc.ClientMethod<$3.AccessTokenRequest, $3.AccessTokenResponse>(
          '/jonline.Jonline/AccessToken',
          ($3.AccessTokenRequest value) => value.writeToBuffer(),
          $3.AccessTokenResponse.fromBuffer);
  static final _$getCurrentUser = $grpc.ClientMethod<$0.Empty, $4.User>(
      '/jonline.Jonline/GetCurrentUser',
      ($0.Empty value) => value.writeToBuffer(),
      $4.User.fromBuffer);
  static final _$resetPassword =
      $grpc.ClientMethod<$3.ResetPasswordRequest, $0.Empty>(
          '/jonline.Jonline/ResetPassword',
          ($3.ResetPasswordRequest value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$getMedia =
      $grpc.ClientMethod<$5.GetMediaRequest, $5.GetMediaResponse>(
          '/jonline.Jonline/GetMedia',
          ($5.GetMediaRequest value) => value.writeToBuffer(),
          $5.GetMediaResponse.fromBuffer);
  static final _$deleteMedia = $grpc.ClientMethod<$5.Media, $0.Empty>(
      '/jonline.Jonline/DeleteMedia',
      ($5.Media value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$getUsers =
      $grpc.ClientMethod<$4.GetUsersRequest, $4.GetUsersResponse>(
          '/jonline.Jonline/GetUsers',
          ($4.GetUsersRequest value) => value.writeToBuffer(),
          $4.GetUsersResponse.fromBuffer);
  static final _$updateUser = $grpc.ClientMethod<$4.User, $4.User>(
      '/jonline.Jonline/UpdateUser',
      ($4.User value) => value.writeToBuffer(),
      $4.User.fromBuffer);
  static final _$deleteUser = $grpc.ClientMethod<$4.User, $0.Empty>(
      '/jonline.Jonline/DeleteUser',
      ($4.User value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$sendMessage =
      $grpc.ClientMethod<$6.SendMessageRequest, $6.Message>(
          '/jonline.Jonline/SendMessage',
          ($6.SendMessageRequest value) => value.writeToBuffer(),
          $6.Message.fromBuffer);
  static final _$getMessages =
      $grpc.ClientMethod<$6.GetMessagesRequest, $6.GetMessagesResponse>(
          '/jonline.Jonline/GetMessages',
          ($6.GetMessagesRequest value) => value.writeToBuffer(),
          $6.GetMessagesResponse.fromBuffer);
  static final _$createFollow = $grpc.ClientMethod<$4.Follow, $4.Follow>(
      '/jonline.Jonline/CreateFollow',
      ($4.Follow value) => value.writeToBuffer(),
      $4.Follow.fromBuffer);
  static final _$updateFollow = $grpc.ClientMethod<$4.Follow, $4.Follow>(
      '/jonline.Jonline/UpdateFollow',
      ($4.Follow value) => value.writeToBuffer(),
      $4.Follow.fromBuffer);
  static final _$deleteFollow = $grpc.ClientMethod<$4.Follow, $0.Empty>(
      '/jonline.Jonline/DeleteFollow',
      ($4.Follow value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$getGroups =
      $grpc.ClientMethod<$7.GetGroupsRequest, $7.GetGroupsResponse>(
          '/jonline.Jonline/GetGroups',
          ($7.GetGroupsRequest value) => value.writeToBuffer(),
          $7.GetGroupsResponse.fromBuffer);
  static final _$createGroup = $grpc.ClientMethod<$7.Group, $7.Group>(
      '/jonline.Jonline/CreateGroup',
      ($7.Group value) => value.writeToBuffer(),
      $7.Group.fromBuffer);
  static final _$updateGroup = $grpc.ClientMethod<$7.Group, $7.Group>(
      '/jonline.Jonline/UpdateGroup',
      ($7.Group value) => value.writeToBuffer(),
      $7.Group.fromBuffer);
  static final _$deleteGroup = $grpc.ClientMethod<$7.Group, $0.Empty>(
      '/jonline.Jonline/DeleteGroup',
      ($7.Group value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$getMembers =
      $grpc.ClientMethod<$7.GetMembersRequest, $7.GetMembersResponse>(
          '/jonline.Jonline/GetMembers',
          ($7.GetMembersRequest value) => value.writeToBuffer(),
          $7.GetMembersResponse.fromBuffer);
  static final _$createMembership =
      $grpc.ClientMethod<$4.Membership, $4.Membership>(
          '/jonline.Jonline/CreateMembership',
          ($4.Membership value) => value.writeToBuffer(),
          $4.Membership.fromBuffer);
  static final _$updateMembership =
      $grpc.ClientMethod<$4.Membership, $4.Membership>(
          '/jonline.Jonline/UpdateMembership',
          ($4.Membership value) => value.writeToBuffer(),
          $4.Membership.fromBuffer);
  static final _$deleteMembership = $grpc.ClientMethod<$4.Membership, $0.Empty>(
      '/jonline.Jonline/DeleteMembership',
      ($4.Membership value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$getPosts =
      $grpc.ClientMethod<$8.GetPostsRequest, $8.GetPostsResponse>(
          '/jonline.Jonline/GetPosts',
          ($8.GetPostsRequest value) => value.writeToBuffer(),
          $8.GetPostsResponse.fromBuffer);
  static final _$createPost = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/CreatePost',
      ($8.Post value) => value.writeToBuffer(),
      $8.Post.fromBuffer);
  static final _$updatePost = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/UpdatePost',
      ($8.Post value) => value.writeToBuffer(),
      $8.Post.fromBuffer);
  static final _$deletePost = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/DeletePost',
      ($8.Post value) => value.writeToBuffer(),
      $8.Post.fromBuffer);
  static final _$starPost = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/StarPost',
      ($8.Post value) => value.writeToBuffer(),
      $8.Post.fromBuffer);
  static final _$unstarPost = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/UnstarPost',
      ($8.Post value) => value.writeToBuffer(),
      $8.Post.fromBuffer);
  static final _$getGroupPosts =
      $grpc.ClientMethod<$8.GetGroupPostsRequest, $8.GetGroupPostsResponse>(
          '/jonline.Jonline/GetGroupPosts',
          ($8.GetGroupPostsRequest value) => value.writeToBuffer(),
          $8.GetGroupPostsResponse.fromBuffer);
  static final _$createGroupPost =
      $grpc.ClientMethod<$8.GroupPost, $8.GroupPost>(
          '/jonline.Jonline/CreateGroupPost',
          ($8.GroupPost value) => value.writeToBuffer(),
          $8.GroupPost.fromBuffer);
  static final _$updateGroupPost =
      $grpc.ClientMethod<$8.GroupPost, $8.GroupPost>(
          '/jonline.Jonline/UpdateGroupPost',
          ($8.GroupPost value) => value.writeToBuffer(),
          $8.GroupPost.fromBuffer);
  static final _$deleteGroupPost = $grpc.ClientMethod<$8.GroupPost, $0.Empty>(
      '/jonline.Jonline/DeleteGroupPost',
      ($8.GroupPost value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$getEvents =
      $grpc.ClientMethod<$9.GetEventsRequest, $9.GetEventsResponse>(
          '/jonline.Jonline/GetEvents',
          ($9.GetEventsRequest value) => value.writeToBuffer(),
          $9.GetEventsResponse.fromBuffer);
  static final _$createEvent = $grpc.ClientMethod<$9.Event, $9.Event>(
      '/jonline.Jonline/CreateEvent',
      ($9.Event value) => value.writeToBuffer(),
      $9.Event.fromBuffer);
  static final _$updateEvent = $grpc.ClientMethod<$9.Event, $9.Event>(
      '/jonline.Jonline/UpdateEvent',
      ($9.Event value) => value.writeToBuffer(),
      $9.Event.fromBuffer);
  static final _$deleteEvent = $grpc.ClientMethod<$9.Event, $9.Event>(
      '/jonline.Jonline/DeleteEvent',
      ($9.Event value) => value.writeToBuffer(),
      $9.Event.fromBuffer);
  static final _$getEventSyncSources =
      $grpc.ClientMethod<$4.User, $9.GetEventSyncSourcesResponse>(
          '/jonline.Jonline/GetEventSyncSources',
          ($4.User value) => value.writeToBuffer(),
          $9.GetEventSyncSourcesResponse.fromBuffer);
  static final _$createEventSyncSource =
      $grpc.ClientMethod<$4.EventSyncSource, $4.EventSyncSource>(
          '/jonline.Jonline/CreateEventSyncSource',
          ($4.EventSyncSource value) => value.writeToBuffer(),
          $4.EventSyncSource.fromBuffer);
  static final _$updateEventSyncSource =
      $grpc.ClientMethod<$4.EventSyncSource, $4.EventSyncSource>(
          '/jonline.Jonline/UpdateEventSyncSource',
          ($4.EventSyncSource value) => value.writeToBuffer(),
          $4.EventSyncSource.fromBuffer);
  static final _$deleteEventSyncSource =
      $grpc.ClientMethod<$9.DeleteEventSyncSourceRequest, $0.Empty>(
          '/jonline.Jonline/DeleteEventSyncSource',
          ($9.DeleteEventSyncSourceRequest value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$getEventSyncDestinations =
      $grpc.ClientMethod<$4.User, $9.GetEventSyncDestinationsResponse>(
          '/jonline.Jonline/GetEventSyncDestinations',
          ($4.User value) => value.writeToBuffer(),
          $9.GetEventSyncDestinationsResponse.fromBuffer);
  static final _$createEventSyncDestination =
      $grpc.ClientMethod<$4.EventSyncDestination, $4.EventSyncDestination>(
          '/jonline.Jonline/CreateEventSyncDestination',
          ($4.EventSyncDestination value) => value.writeToBuffer(),
          $4.EventSyncDestination.fromBuffer);
  static final _$updateEventSyncDestination =
      $grpc.ClientMethod<$4.EventSyncDestination, $4.EventSyncDestination>(
          '/jonline.Jonline/UpdateEventSyncDestination',
          ($4.EventSyncDestination value) => value.writeToBuffer(),
          $4.EventSyncDestination.fromBuffer);
  static final _$deleteEventSyncDestination =
      $grpc.ClientMethod<$9.DeleteEventSyncDestinationRequest, $0.Empty>(
          '/jonline.Jonline/DeleteEventSyncDestination',
          ($9.DeleteEventSyncDestinationRequest value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$syncEventInstance =
      $grpc.ClientMethod<$9.SyncEventInstanceRequest, $9.EventInstance>(
          '/jonline.Jonline/SyncEventInstance',
          ($9.SyncEventInstanceRequest value) => value.writeToBuffer(),
          $9.EventInstance.fromBuffer);
  static final _$getEventAttendances =
      $grpc.ClientMethod<$9.GetEventAttendancesRequest, $9.EventAttendances>(
          '/jonline.Jonline/GetEventAttendances',
          ($9.GetEventAttendancesRequest value) => value.writeToBuffer(),
          $9.EventAttendances.fromBuffer);
  static final _$upsertEventAttendance =
      $grpc.ClientMethod<$9.EventAttendance, $9.EventAttendance>(
          '/jonline.Jonline/UpsertEventAttendance',
          ($9.EventAttendance value) => value.writeToBuffer(),
          $9.EventAttendance.fromBuffer);
  static final _$deleteEventAttendance =
      $grpc.ClientMethod<$9.EventAttendance, $0.Empty>(
          '/jonline.Jonline/DeleteEventAttendance',
          ($9.EventAttendance value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$federateProfile =
      $grpc.ClientMethod<$1.FederatedAccount, $1.FederatedAccount>(
          '/jonline.Jonline/FederateProfile',
          ($1.FederatedAccount value) => value.writeToBuffer(),
          $1.FederatedAccount.fromBuffer);
  static final _$defederateProfile =
      $grpc.ClientMethod<$1.FederatedAccount, $0.Empty>(
          '/jonline.Jonline/DefederateProfile',
          ($1.FederatedAccount value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$configureServer =
      $grpc.ClientMethod<$2.ServerConfiguration, $2.ServerConfiguration>(
          '/jonline.Jonline/ConfigureServer',
          ($2.ServerConfiguration value) => value.writeToBuffer(),
          $2.ServerConfiguration.fromBuffer);
  static final _$resetData = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/jonline.Jonline/ResetData',
      ($0.Empty value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$streamReplies = $grpc.ClientMethod<$8.Post, $8.Post>(
      '/jonline.Jonline/StreamReplies',
      ($8.Post value) => value.writeToBuffer(),
      $8.Post.fromBuffer);
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
    $addMethod(
        $grpc.ServiceMethod<$3.CreateAccountRequest, $3.RefreshTokenResponse>(
            'CreateAccount',
            createAccount_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $3.CreateAccountRequest.fromBuffer(value),
            ($3.RefreshTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$3.LoginRequest, $3.RefreshTokenResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $3.LoginRequest.fromBuffer(value),
        ($3.RefreshTokenResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$3.AccessTokenRequest, $3.AccessTokenResponse>(
            'AccessToken',
            accessToken_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $3.AccessTokenRequest.fromBuffer(value),
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
        ($core.List<$core.int> value) =>
            $3.ResetPasswordRequest.fromBuffer(value),
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
    $addMethod($grpc.ServiceMethod<$6.SendMessageRequest, $6.Message>(
        'SendMessage',
        sendMessage_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $6.SendMessageRequest.fromBuffer(value),
        ($6.Message value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$6.GetMessagesRequest, $6.GetMessagesResponse>(
            'GetMessages',
            getMessages_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $6.GetMessagesRequest.fromBuffer(value),
            ($6.GetMessagesResponse value) => value.writeToBuffer()));
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
    $addMethod($grpc.ServiceMethod<$7.GetGroupsRequest, $7.GetGroupsResponse>(
        'GetGroups',
        getGroups_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GetGroupsRequest.fromBuffer(value),
        ($7.GetGroupsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Group, $7.Group>(
        'CreateGroup',
        createGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Group.fromBuffer(value),
        ($7.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Group, $7.Group>(
        'UpdateGroup',
        updateGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Group.fromBuffer(value),
        ($7.Group value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.Group, $0.Empty>(
        'DeleteGroup',
        deleteGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.Group.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$7.GetMembersRequest, $7.GetMembersResponse>(
        'GetMembers',
        getMembers_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $7.GetMembersRequest.fromBuffer(value),
        ($7.GetMembersResponse value) => value.writeToBuffer()));
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
    $addMethod($grpc.ServiceMethod<$8.GetPostsRequest, $8.GetPostsResponse>(
        'GetPosts',
        getPosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GetPostsRequest.fromBuffer(value),
        ($8.GetPostsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'CreatePost',
        createPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'UpdatePost',
        updatePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'DeletePost',
        deletePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'StarPost',
        starPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'UnstarPost',
        unstarPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$8.GetGroupPostsRequest, $8.GetGroupPostsResponse>(
            'GetGroupPosts',
            getGroupPosts_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $8.GetGroupPostsRequest.fromBuffer(value),
            ($8.GetGroupPostsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.GroupPost, $8.GroupPost>(
        'CreateGroupPost',
        createGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GroupPost.fromBuffer(value),
        ($8.GroupPost value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.GroupPost, $8.GroupPost>(
        'UpdateGroupPost',
        updateGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GroupPost.fromBuffer(value),
        ($8.GroupPost value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.GroupPost, $0.Empty>(
        'DeleteGroupPost',
        deleteGroupPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $8.GroupPost.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.GetEventsRequest, $9.GetEventsResponse>(
        'GetEvents',
        getEvents_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.GetEventsRequest.fromBuffer(value),
        ($9.GetEventsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.Event, $9.Event>(
        'CreateEvent',
        createEvent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.Event.fromBuffer(value),
        ($9.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.Event, $9.Event>(
        'UpdateEvent',
        updateEvent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.Event.fromBuffer(value),
        ($9.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.Event, $9.Event>(
        'DeleteEvent',
        deleteEvent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.Event.fromBuffer(value),
        ($9.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.User, $9.GetEventSyncSourcesResponse>(
        'GetEventSyncSources',
        getEventSyncSources_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.User.fromBuffer(value),
        ($9.GetEventSyncSourcesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.EventSyncSource, $4.EventSyncSource>(
        'CreateEventSyncSource',
        createEventSyncSource_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.EventSyncSource.fromBuffer(value),
        ($4.EventSyncSource value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.EventSyncSource, $4.EventSyncSource>(
        'UpdateEventSyncSource',
        updateEventSyncSource_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.EventSyncSource.fromBuffer(value),
        ($4.EventSyncSource value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.DeleteEventSyncSourceRequest, $0.Empty>(
        'DeleteEventSyncSource',
        deleteEventSyncSource_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $9.DeleteEventSyncSourceRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$4.User, $9.GetEventSyncDestinationsResponse>(
            'GetEventSyncDestinations',
            getEventSyncDestinations_Pre,
            false,
            false,
            ($core.List<$core.int> value) => $4.User.fromBuffer(value),
            ($9.GetEventSyncDestinationsResponse value) =>
                value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$4.EventSyncDestination, $4.EventSyncDestination>(
            'CreateEventSyncDestination',
            createEventSyncDestination_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $4.EventSyncDestination.fromBuffer(value),
            ($4.EventSyncDestination value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$4.EventSyncDestination, $4.EventSyncDestination>(
            'UpdateEventSyncDestination',
            updateEventSyncDestination_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $4.EventSyncDestination.fromBuffer(value),
            ($4.EventSyncDestination value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$9.DeleteEventSyncDestinationRequest, $0.Empty>(
            'DeleteEventSyncDestination',
            deleteEventSyncDestination_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $9.DeleteEventSyncDestinationRequest.fromBuffer(value),
            ($0.Empty value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$9.SyncEventInstanceRequest, $9.EventInstance>(
            'SyncEventInstance',
            syncEventInstance_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $9.SyncEventInstanceRequest.fromBuffer(value),
            ($9.EventInstance value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$9.GetEventAttendancesRequest, $9.EventAttendances>(
            'GetEventAttendances',
            getEventAttendances_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $9.GetEventAttendancesRequest.fromBuffer(value),
            ($9.EventAttendances value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.EventAttendance, $9.EventAttendance>(
        'UpsertEventAttendance',
        upsertEventAttendance_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.EventAttendance.fromBuffer(value),
        ($9.EventAttendance value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$9.EventAttendance, $0.Empty>(
        'DeleteEventAttendance',
        deleteEventAttendance_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $9.EventAttendance.fromBuffer(value),
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
    $addMethod(
        $grpc.ServiceMethod<$2.ServerConfiguration, $2.ServerConfiguration>(
            'ConfigureServer',
            configureServer_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $2.ServerConfiguration.fromBuffer(value),
            ($2.ServerConfiguration value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'ResetData',
        resetData_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$8.Post, $8.Post>(
        'StreamReplies',
        streamReplies_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $8.Post.fromBuffer(value),
        ($8.Post value) => value.writeToBuffer()));
  }

  $async.Future<$1.GetServiceVersionResponse> getServiceVersion_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getServiceVersion($call, await $request);
  }

  $async.Future<$1.GetServiceVersionResponse> getServiceVersion(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$2.ServerConfiguration> getServerConfiguration_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getServerConfiguration($call, await $request);
  }

  $async.Future<$2.ServerConfiguration> getServerConfiguration(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$3.RefreshTokenResponse> createAccount_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$3.CreateAccountRequest> $request) async {
    return createAccount($call, await $request);
  }

  $async.Future<$3.RefreshTokenResponse> createAccount(
      $grpc.ServiceCall call, $3.CreateAccountRequest request);

  $async.Future<$3.RefreshTokenResponse> login_Pre(
      $grpc.ServiceCall $call, $async.Future<$3.LoginRequest> $request) async {
    return login($call, await $request);
  }

  $async.Future<$3.RefreshTokenResponse> login(
      $grpc.ServiceCall call, $3.LoginRequest request);

  $async.Future<$3.AccessTokenResponse> accessToken_Pre($grpc.ServiceCall $call,
      $async.Future<$3.AccessTokenRequest> $request) async {
    return accessToken($call, await $request);
  }

  $async.Future<$3.AccessTokenResponse> accessToken(
      $grpc.ServiceCall call, $3.AccessTokenRequest request);

  $async.Future<$4.User> getCurrentUser_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getCurrentUser($call, await $request);
  }

  $async.Future<$4.User> getCurrentUser(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.Empty> resetPassword_Pre($grpc.ServiceCall $call,
      $async.Future<$3.ResetPasswordRequest> $request) async {
    return resetPassword($call, await $request);
  }

  $async.Future<$0.Empty> resetPassword(
      $grpc.ServiceCall call, $3.ResetPasswordRequest request);

  $async.Future<$5.GetMediaResponse> getMedia_Pre($grpc.ServiceCall $call,
      $async.Future<$5.GetMediaRequest> $request) async {
    return getMedia($call, await $request);
  }

  $async.Future<$5.GetMediaResponse> getMedia(
      $grpc.ServiceCall call, $5.GetMediaRequest request);

  $async.Future<$0.Empty> deleteMedia_Pre(
      $grpc.ServiceCall $call, $async.Future<$5.Media> $request) async {
    return deleteMedia($call, await $request);
  }

  $async.Future<$0.Empty> deleteMedia($grpc.ServiceCall call, $5.Media request);

  $async.Future<$4.GetUsersResponse> getUsers_Pre($grpc.ServiceCall $call,
      $async.Future<$4.GetUsersRequest> $request) async {
    return getUsers($call, await $request);
  }

  $async.Future<$4.GetUsersResponse> getUsers(
      $grpc.ServiceCall call, $4.GetUsersRequest request);

  $async.Future<$4.User> updateUser_Pre(
      $grpc.ServiceCall $call, $async.Future<$4.User> $request) async {
    return updateUser($call, await $request);
  }

  $async.Future<$4.User> updateUser($grpc.ServiceCall call, $4.User request);

  $async.Future<$0.Empty> deleteUser_Pre(
      $grpc.ServiceCall $call, $async.Future<$4.User> $request) async {
    return deleteUser($call, await $request);
  }

  $async.Future<$0.Empty> deleteUser($grpc.ServiceCall call, $4.User request);

  $async.Future<$6.Message> sendMessage_Pre($grpc.ServiceCall $call,
      $async.Future<$6.SendMessageRequest> $request) async {
    return sendMessage($call, await $request);
  }

  $async.Future<$6.Message> sendMessage(
      $grpc.ServiceCall call, $6.SendMessageRequest request);

  $async.Future<$6.GetMessagesResponse> getMessages_Pre($grpc.ServiceCall $call,
      $async.Future<$6.GetMessagesRequest> $request) async {
    return getMessages($call, await $request);
  }

  $async.Future<$6.GetMessagesResponse> getMessages(
      $grpc.ServiceCall call, $6.GetMessagesRequest request);

  $async.Future<$4.Follow> createFollow_Pre(
      $grpc.ServiceCall $call, $async.Future<$4.Follow> $request) async {
    return createFollow($call, await $request);
  }

  $async.Future<$4.Follow> createFollow(
      $grpc.ServiceCall call, $4.Follow request);

  $async.Future<$4.Follow> updateFollow_Pre(
      $grpc.ServiceCall $call, $async.Future<$4.Follow> $request) async {
    return updateFollow($call, await $request);
  }

  $async.Future<$4.Follow> updateFollow(
      $grpc.ServiceCall call, $4.Follow request);

  $async.Future<$0.Empty> deleteFollow_Pre(
      $grpc.ServiceCall $call, $async.Future<$4.Follow> $request) async {
    return deleteFollow($call, await $request);
  }

  $async.Future<$0.Empty> deleteFollow(
      $grpc.ServiceCall call, $4.Follow request);

  $async.Future<$7.GetGroupsResponse> getGroups_Pre($grpc.ServiceCall $call,
      $async.Future<$7.GetGroupsRequest> $request) async {
    return getGroups($call, await $request);
  }

  $async.Future<$7.GetGroupsResponse> getGroups(
      $grpc.ServiceCall call, $7.GetGroupsRequest request);

  $async.Future<$7.Group> createGroup_Pre(
      $grpc.ServiceCall $call, $async.Future<$7.Group> $request) async {
    return createGroup($call, await $request);
  }

  $async.Future<$7.Group> createGroup($grpc.ServiceCall call, $7.Group request);

  $async.Future<$7.Group> updateGroup_Pre(
      $grpc.ServiceCall $call, $async.Future<$7.Group> $request) async {
    return updateGroup($call, await $request);
  }

  $async.Future<$7.Group> updateGroup($grpc.ServiceCall call, $7.Group request);

  $async.Future<$0.Empty> deleteGroup_Pre(
      $grpc.ServiceCall $call, $async.Future<$7.Group> $request) async {
    return deleteGroup($call, await $request);
  }

  $async.Future<$0.Empty> deleteGroup($grpc.ServiceCall call, $7.Group request);

  $async.Future<$7.GetMembersResponse> getMembers_Pre($grpc.ServiceCall $call,
      $async.Future<$7.GetMembersRequest> $request) async {
    return getMembers($call, await $request);
  }

  $async.Future<$7.GetMembersResponse> getMembers(
      $grpc.ServiceCall call, $7.GetMembersRequest request);

  $async.Future<$4.Membership> createMembership_Pre(
      $grpc.ServiceCall $call, $async.Future<$4.Membership> $request) async {
    return createMembership($call, await $request);
  }

  $async.Future<$4.Membership> createMembership(
      $grpc.ServiceCall call, $4.Membership request);

  $async.Future<$4.Membership> updateMembership_Pre(
      $grpc.ServiceCall $call, $async.Future<$4.Membership> $request) async {
    return updateMembership($call, await $request);
  }

  $async.Future<$4.Membership> updateMembership(
      $grpc.ServiceCall call, $4.Membership request);

  $async.Future<$0.Empty> deleteMembership_Pre(
      $grpc.ServiceCall $call, $async.Future<$4.Membership> $request) async {
    return deleteMembership($call, await $request);
  }

  $async.Future<$0.Empty> deleteMembership(
      $grpc.ServiceCall call, $4.Membership request);

  $async.Future<$8.GetPostsResponse> getPosts_Pre($grpc.ServiceCall $call,
      $async.Future<$8.GetPostsRequest> $request) async {
    return getPosts($call, await $request);
  }

  $async.Future<$8.GetPostsResponse> getPosts(
      $grpc.ServiceCall call, $8.GetPostsRequest request);

  $async.Future<$8.Post> createPost_Pre(
      $grpc.ServiceCall $call, $async.Future<$8.Post> $request) async {
    return createPost($call, await $request);
  }

  $async.Future<$8.Post> createPost($grpc.ServiceCall call, $8.Post request);

  $async.Future<$8.Post> updatePost_Pre(
      $grpc.ServiceCall $call, $async.Future<$8.Post> $request) async {
    return updatePost($call, await $request);
  }

  $async.Future<$8.Post> updatePost($grpc.ServiceCall call, $8.Post request);

  $async.Future<$8.Post> deletePost_Pre(
      $grpc.ServiceCall $call, $async.Future<$8.Post> $request) async {
    return deletePost($call, await $request);
  }

  $async.Future<$8.Post> deletePost($grpc.ServiceCall call, $8.Post request);

  $async.Future<$8.Post> starPost_Pre(
      $grpc.ServiceCall $call, $async.Future<$8.Post> $request) async {
    return starPost($call, await $request);
  }

  $async.Future<$8.Post> starPost($grpc.ServiceCall call, $8.Post request);

  $async.Future<$8.Post> unstarPost_Pre(
      $grpc.ServiceCall $call, $async.Future<$8.Post> $request) async {
    return unstarPost($call, await $request);
  }

  $async.Future<$8.Post> unstarPost($grpc.ServiceCall call, $8.Post request);

  $async.Future<$8.GetGroupPostsResponse> getGroupPosts_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$8.GetGroupPostsRequest> $request) async {
    return getGroupPosts($call, await $request);
  }

  $async.Future<$8.GetGroupPostsResponse> getGroupPosts(
      $grpc.ServiceCall call, $8.GetGroupPostsRequest request);

  $async.Future<$8.GroupPost> createGroupPost_Pre(
      $grpc.ServiceCall $call, $async.Future<$8.GroupPost> $request) async {
    return createGroupPost($call, await $request);
  }

  $async.Future<$8.GroupPost> createGroupPost(
      $grpc.ServiceCall call, $8.GroupPost request);

  $async.Future<$8.GroupPost> updateGroupPost_Pre(
      $grpc.ServiceCall $call, $async.Future<$8.GroupPost> $request) async {
    return updateGroupPost($call, await $request);
  }

  $async.Future<$8.GroupPost> updateGroupPost(
      $grpc.ServiceCall call, $8.GroupPost request);

  $async.Future<$0.Empty> deleteGroupPost_Pre(
      $grpc.ServiceCall $call, $async.Future<$8.GroupPost> $request) async {
    return deleteGroupPost($call, await $request);
  }

  $async.Future<$0.Empty> deleteGroupPost(
      $grpc.ServiceCall call, $8.GroupPost request);

  $async.Future<$9.GetEventsResponse> getEvents_Pre($grpc.ServiceCall $call,
      $async.Future<$9.GetEventsRequest> $request) async {
    return getEvents($call, await $request);
  }

  $async.Future<$9.GetEventsResponse> getEvents(
      $grpc.ServiceCall call, $9.GetEventsRequest request);

  $async.Future<$9.Event> createEvent_Pre(
      $grpc.ServiceCall $call, $async.Future<$9.Event> $request) async {
    return createEvent($call, await $request);
  }

  $async.Future<$9.Event> createEvent($grpc.ServiceCall call, $9.Event request);

  $async.Future<$9.Event> updateEvent_Pre(
      $grpc.ServiceCall $call, $async.Future<$9.Event> $request) async {
    return updateEvent($call, await $request);
  }

  $async.Future<$9.Event> updateEvent($grpc.ServiceCall call, $9.Event request);

  $async.Future<$9.Event> deleteEvent_Pre(
      $grpc.ServiceCall $call, $async.Future<$9.Event> $request) async {
    return deleteEvent($call, await $request);
  }

  $async.Future<$9.Event> deleteEvent($grpc.ServiceCall call, $9.Event request);

  $async.Future<$9.GetEventSyncSourcesResponse> getEventSyncSources_Pre(
      $grpc.ServiceCall $call, $async.Future<$4.User> $request) async {
    return getEventSyncSources($call, await $request);
  }

  $async.Future<$9.GetEventSyncSourcesResponse> getEventSyncSources(
      $grpc.ServiceCall call, $4.User request);

  $async.Future<$4.EventSyncSource> createEventSyncSource_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$4.EventSyncSource> $request) async {
    return createEventSyncSource($call, await $request);
  }

  $async.Future<$4.EventSyncSource> createEventSyncSource(
      $grpc.ServiceCall call, $4.EventSyncSource request);

  $async.Future<$4.EventSyncSource> updateEventSyncSource_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$4.EventSyncSource> $request) async {
    return updateEventSyncSource($call, await $request);
  }

  $async.Future<$4.EventSyncSource> updateEventSyncSource(
      $grpc.ServiceCall call, $4.EventSyncSource request);

  $async.Future<$0.Empty> deleteEventSyncSource_Pre($grpc.ServiceCall $call,
      $async.Future<$9.DeleteEventSyncSourceRequest> $request) async {
    return deleteEventSyncSource($call, await $request);
  }

  $async.Future<$0.Empty> deleteEventSyncSource(
      $grpc.ServiceCall call, $9.DeleteEventSyncSourceRequest request);

  $async.Future<$9.GetEventSyncDestinationsResponse>
      getEventSyncDestinations_Pre(
          $grpc.ServiceCall $call, $async.Future<$4.User> $request) async {
    return getEventSyncDestinations($call, await $request);
  }

  $async.Future<$9.GetEventSyncDestinationsResponse> getEventSyncDestinations(
      $grpc.ServiceCall call, $4.User request);

  $async.Future<$4.EventSyncDestination> createEventSyncDestination_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$4.EventSyncDestination> $request) async {
    return createEventSyncDestination($call, await $request);
  }

  $async.Future<$4.EventSyncDestination> createEventSyncDestination(
      $grpc.ServiceCall call, $4.EventSyncDestination request);

  $async.Future<$4.EventSyncDestination> updateEventSyncDestination_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$4.EventSyncDestination> $request) async {
    return updateEventSyncDestination($call, await $request);
  }

  $async.Future<$4.EventSyncDestination> updateEventSyncDestination(
      $grpc.ServiceCall call, $4.EventSyncDestination request);

  $async.Future<$0.Empty> deleteEventSyncDestination_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$9.DeleteEventSyncDestinationRequest> $request) async {
    return deleteEventSyncDestination($call, await $request);
  }

  $async.Future<$0.Empty> deleteEventSyncDestination(
      $grpc.ServiceCall call, $9.DeleteEventSyncDestinationRequest request);

  $async.Future<$9.EventInstance> syncEventInstance_Pre($grpc.ServiceCall $call,
      $async.Future<$9.SyncEventInstanceRequest> $request) async {
    return syncEventInstance($call, await $request);
  }

  $async.Future<$9.EventInstance> syncEventInstance(
      $grpc.ServiceCall call, $9.SyncEventInstanceRequest request);

  $async.Future<$9.EventAttendances> getEventAttendances_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$9.GetEventAttendancesRequest> $request) async {
    return getEventAttendances($call, await $request);
  }

  $async.Future<$9.EventAttendances> getEventAttendances(
      $grpc.ServiceCall call, $9.GetEventAttendancesRequest request);

  $async.Future<$9.EventAttendance> upsertEventAttendance_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$9.EventAttendance> $request) async {
    return upsertEventAttendance($call, await $request);
  }

  $async.Future<$9.EventAttendance> upsertEventAttendance(
      $grpc.ServiceCall call, $9.EventAttendance request);

  $async.Future<$0.Empty> deleteEventAttendance_Pre($grpc.ServiceCall $call,
      $async.Future<$9.EventAttendance> $request) async {
    return deleteEventAttendance($call, await $request);
  }

  $async.Future<$0.Empty> deleteEventAttendance(
      $grpc.ServiceCall call, $9.EventAttendance request);

  $async.Future<$1.FederatedAccount> federateProfile_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.FederatedAccount> $request) async {
    return federateProfile($call, await $request);
  }

  $async.Future<$1.FederatedAccount> federateProfile(
      $grpc.ServiceCall call, $1.FederatedAccount request);

  $async.Future<$0.Empty> defederateProfile_Pre($grpc.ServiceCall $call,
      $async.Future<$1.FederatedAccount> $request) async {
    return defederateProfile($call, await $request);
  }

  $async.Future<$0.Empty> defederateProfile(
      $grpc.ServiceCall call, $1.FederatedAccount request);

  $async.Future<$2.ServerConfiguration> configureServer_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$2.ServerConfiguration> $request) async {
    return configureServer($call, await $request);
  }

  $async.Future<$2.ServerConfiguration> configureServer(
      $grpc.ServiceCall call, $2.ServerConfiguration request);

  $async.Future<$0.Empty> resetData_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return resetData($call, await $request);
  }

  $async.Future<$0.Empty> resetData($grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$8.Post> streamReplies_Pre(
      $grpc.ServiceCall $call, $async.Future<$8.Post> $request) async* {
    yield* streamReplies($call, await $request);
  }

  $async.Stream<$8.Post> streamReplies($grpc.ServiceCall call, $8.Post request);
}
