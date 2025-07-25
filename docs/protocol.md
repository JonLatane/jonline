# Protocol Documentation
<a name="top"></a>

## Table of Contents

- [jonline.proto](#jonline-proto)
    - [Jonline](#jonline-Jonline)
  
- [authentication.proto](#authentication-proto)
    - [AccessTokenRequest](#jonline-AccessTokenRequest)
    - [AccessTokenResponse](#jonline-AccessTokenResponse)
    - [CreateAccountRequest](#jonline-CreateAccountRequest)
    - [CreateThirdPartyRefreshTokenRequest](#jonline-CreateThirdPartyRefreshTokenRequest)
    - [ExpirableToken](#jonline-ExpirableToken)
    - [LoginRequest](#jonline-LoginRequest)
    - [RefreshTokenMetadata](#jonline-RefreshTokenMetadata)
    - [RefreshTokenResponse](#jonline-RefreshTokenResponse)
    - [ResetPasswordRequest](#jonline-ResetPasswordRequest)
    - [UserRefreshTokensResponse](#jonline-UserRefreshTokensResponse)
  
- [visibility_moderation.proto](#visibility_moderation-proto)
    - [Moderation](#jonline-Moderation)
    - [Visibility](#jonline-Visibility)
  
- [permissions.proto](#permissions-proto)
    - [Permission](#jonline-Permission)
  
- [users.proto](#users-proto)
    - [Author](#jonline-Author)
    - [ContactMethod](#jonline-ContactMethod)
    - [Follow](#jonline-Follow)
    - [GetUsersRequest](#jonline-GetUsersRequest)
    - [GetUsersResponse](#jonline-GetUsersResponse)
    - [Membership](#jonline-Membership)
    - [User](#jonline-User)
  
    - [UserListingType](#jonline-UserListingType)
  
- [media.proto](#media-proto)
    - [GetMediaRequest](#jonline-GetMediaRequest)
    - [GetMediaResponse](#jonline-GetMediaResponse)
    - [Media](#jonline-Media)
    - [MediaReference](#jonline-MediaReference)
  
- [groups.proto](#groups-proto)
    - [GetGroupsRequest](#jonline-GetGroupsRequest)
    - [GetGroupsResponse](#jonline-GetGroupsResponse)
    - [GetMembersRequest](#jonline-GetMembersRequest)
    - [GetMembersResponse](#jonline-GetMembersResponse)
    - [Group](#jonline-Group)
    - [Member](#jonline-Member)
  
    - [GroupListingType](#jonline-GroupListingType)
  
- [posts.proto](#posts-proto)
    - [GetGroupPostsRequest](#jonline-GetGroupPostsRequest)
    - [GetGroupPostsResponse](#jonline-GetGroupPostsResponse)
    - [GetPostsRequest](#jonline-GetPostsRequest)
    - [GetPostsResponse](#jonline-GetPostsResponse)
    - [GroupPost](#jonline-GroupPost)
    - [Post](#jonline-Post)
    - [UserPost](#jonline-UserPost)
  
    - [PostContext](#jonline-PostContext)
    - [PostListingType](#jonline-PostListingType)
  
- [events.proto](#events-proto)
    - [AnonymousAttendee](#jonline-AnonymousAttendee)
    - [Event](#jonline-Event)
    - [EventAttendance](#jonline-EventAttendance)
    - [EventAttendances](#jonline-EventAttendances)
    - [EventInfo](#jonline-EventInfo)
    - [EventInstance](#jonline-EventInstance)
    - [EventInstanceInfo](#jonline-EventInstanceInfo)
    - [EventInstanceRsvpInfo](#jonline-EventInstanceRsvpInfo)
    - [GetEventAttendancesRequest](#jonline-GetEventAttendancesRequest)
    - [GetEventsRequest](#jonline-GetEventsRequest)
    - [GetEventsResponse](#jonline-GetEventsResponse)
    - [TimeFilter](#jonline-TimeFilter)
    - [UserAttendee](#jonline-UserAttendee)
  
    - [AttendanceStatus](#jonline-AttendanceStatus)
    - [EventListingType](#jonline-EventListingType)
  
- [server_configuration.proto](#server_configuration-proto)
    - [ExternalCDNConfig](#jonline-ExternalCDNConfig)
    - [FeatureSettings](#jonline-FeatureSettings)
    - [PostSettings](#jonline-PostSettings)
    - [ServerColors](#jonline-ServerColors)
    - [ServerConfiguration](#jonline-ServerConfiguration)
    - [ServerInfo](#jonline-ServerInfo)
    - [ServerLogo](#jonline-ServerLogo)
    - [WebPushConfig](#jonline-WebPushConfig)
  
    - [AuthenticationFeature](#jonline-AuthenticationFeature)
    - [PrivateUserStrategy](#jonline-PrivateUserStrategy)
    - [WebUserInterface](#jonline-WebUserInterface)
  
- [federation.proto](#federation-proto)
    - [FederatedAccount](#jonline-FederatedAccount)
    - [FederatedServer](#jonline-FederatedServer)
    - [FederationInfo](#jonline-FederationInfo)
    - [GetServiceVersionResponse](#jonline-GetServiceVersionResponse)
  
- [Scalar Value Types](#scalar-value-types)



<a name="jonline-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## jonline.proto


 

 

 


<a name="jonline-Jonline"></a>

### Jonline
A Jonline server is generally expected to run a gRPC server on port 27707 and/or 443, and an HTTP server on port 80 and/or 443.
The bulk of these docs involve the [gRPC API](#grpc-api) (the &#34;protocol&#34;), while the HTTP server is expected to serve up web apps (React and, previously, Flutter),
[media files](#jonline-Media), and a [`backend_host` resource for client/host negotiation](#http-based-client-host-negotiation-for-external-cdns).
Jonline serves up a few other [HTTP endpoints](#http-endpoints), providing a `/sitemap.xml`, `/robots.txt`, iCal/RFC5545 subscription endpoints, and more,
but these are essentially accessories to the core APIs.

#### Authentication
Jonline uses a standard OAuth2 flow (over gRPC) for authentication, with rotating `access_token`s and `refresh_token`s.
Authenticated calls require an `access_token` in request metadata to be included / directly as the value of the
`authorization` header (no `Bearer ` prefix).

First, use the `CreateAccount` or `Login` RPCs to fetch (and store) an initial
`refresh_token` and `access_token`. Clients should use the `access_token` until it expires,
then use the `refresh_token` to call the `AccessToken` RPC for a new one. (The `AccessToken` RPC
may, at random, also return a new `refresh_token`. If so, it should immediately replace the old
one in client storage.)

#### Dumfederation
Whereas other federated social networks (e.g. ActivityPub) have both client-server and server-server APIs,
Jonline only has client-server APIs. While server-to-server communication is possible, nothing but some
&#34;nice to have&#34; features require it, so it is not used.

##### Federated Servers
Jonline servers can recommend other servers to clients with the `federation_info` field (a [`FederationInfo` message](http://localhost/docs/protocol#federationinfo)) in [`ServerConfiguration`](#jonline-ServerConfiguration).
Clients can use this information to discover other servers, or users can add new servers manually.
Note that, at least for web clients, this means everything is subject to CORS. In the future, Jonline will
allow CORS to be configured in a &#34;strict&#34; mode, so someone else&#39;s Jonline server cannot be used to access your server&#39;s data
unless you explicitly allow it.

#### Federated Profiles
Jonline users can federate with users on any other Jonline server. This works by two-way verification:
For example, Jon has the user [`jonline.io/jon`](https://jonline.io/jon), [`oakcity.social/jon`](https://oakcity.social/jon),
and [`bullcity.social/jon`](https://bullcity.social/jon) associated with one another. 
The UI will only show federated profiles if *both use profiles* have federated with one another.

This mechanism also allows users to link multiple profiles on the same server together. For instance, [`bullcity.social/jon`](https://bullcity.social/jon)
and [`bullcity.social/openmic`](https://bullcity.social/openmic) are linked together, but [`bullcity.social/openmic`](https://bullcity.social/openmic)
isn&#39;t linked to [`jonline.io/jon`](https://jonline.io/jon) or [`oakcity.social/jon`](https://oakcity.social/jon).

Federated profiles are managed via the `federated_profiles` field (a `repeated` [`FederatedAccount`](http://localhost/docs/protocol#jonline-FederatedAccount)) in the [`User`](#jonline-User) message.

#### HTTP Endpoints

##### iCalendar/RFC5545 (`GET /calendar.ics`, `GET /calendar.ics?user_id={id}`)
Jonline events support iCalendar/RFC5545. Only public events are included in the calendar.
Users can &#34;subscribe&#34; to a Jonline server at, for instance, `https://jonline.io/calendar.ics` 
to get a calendar of all public events on the server.
Users can also subscribe to a user&#39;s calendar at, for instance, `https://jonline.io/calendar.ics?user_id=CruFm`
to get a calendar of all public events for that user.
In the Tamagui/React frontend, links to the ICS endpoints are provided in the Upcoming Events section of the home page,
the Events page, and the user profile pages for all users with events in the last 3 months (or in the future).

##### Robots &amp; Sitemap (`GET /robots.txt` and `GET /sitemap.xml`)
Jonline servers are expected to serve a `robots.txt` file at `/robots.txt` and a `sitemap.xml` file at `/sitemap.xml`.

##### Media (`GET /media/{id}` and `POST /media`)
See the [Media](#jonline-Media) section for details on how to upload/download media files.

##### HTTP-based client host negotiation (for external CDNs) (`GET /backend_host`)
When first negotiating the gRPC connection to a host, say, `jonline.io`, before attempting
to connect to `jonline.io` via gRPC on 27707/443, the client
is expected to first attempt to `GET jonline.io/backend_host` over HTTP (port 80) or HTTPS (port 443)
(depending upon whether the gRPC server is expected to have TLS). If the `backend_host` string resource
is a valid domain, say, `jonline.io.itsj.online`, the client is expected to connect
to `jonline.io.itsj.online` on port 27707/443 instead. To users, the server should still *generally* appear to 
be `jonline.io`. The client can trust `jonline.io/backend_host` to always point to the correct backend host for
`jonline.io`.

This negotiation enables support for external CDNs as frontends. See https://jonline.io/about?section=cdn for
more information about external CDN setup. Developers may wish to review the [React/Tamagui](https://github.com/JonLatane/jonline/blob/main/frontends/tamagui/packages/app/store/clients.ts#L116) 
and [Flutter](https://github.com/JonLatane/jonline/blob/main/frontends/flutter/lib/models/jonline_clients.dart#L26) 
client implementations of this negotiation.

In the works to be released soon, Jonline will also support a &#34;fully behind CDN&#34; mode, where gRPC is served over port 443 and HTTP over port
80, with no HTTPS web page/media serving (other than the HTTPS that naturally underpins gRPC-Web). This is designed to use Cloudflare&#39;s gRPC
proxy support. With this, both web and gRPC resources can live behind a CDN.

#### API Design Notes
##### Moderation and Visibility
Jonline APIs are designed to support `Moderation` and `Visibility` controls at the level of individual entities. However, to keep things
DRY, moderation and visibility controls are only implemented for `User`s, `Media`, `Group`s, and `Post`s.

`Event`s and future `Post`-like types simply use the same implementation as their contained `Post`s. The intent here is to maximize
both shared code and implementation robustness.

##### Composition Over Inheritance
Jonline&#39;s APIs are designed using composition over inheritance. For instance, an `Event` contains
a `Post` rather than extending it. This pattern fits well all the way from the data model (very boring, safe, and normalized), 
through Rust code implementing APIs, to both functional React code and more-OOP Flutter code equally well.

##### Predictable Atomicity
The use of composition over inheritance also means that Jonline APIs can be *predictably* non-atomic based on their compositional structure.
For instance, `UpdatePost` is fully atomic.

`UpdateEvent`, however, is non-atomic. Given that an `Event` has a `Post` and many `EventInstance`s, 
`UpdateEvent` will first update the `Post` atomically (literally calling the `UpdatePost` RPC),
then the `Event` atomically, and then finally process updates to its `EventInstance`s in a final atomic operation. 

Because moderation/visibility lives at the `Post` level, this means that a developer error in `UpdateEvents` cannot prevent 
visibility and moderation changes from being made in Events, even if there are errors elsewhere.
This should prove a robust pattern for any future entities intended to be shareable at a Group level with visibility and
moderation controls (for instance, `Sheet`, `SharedExpenseReport`, `SharedCalendar`, etc.). The entire architecture should promote this
approach to predictable atomicity.

### gRPC API

| Method Name | Request Type | Response Type | Description |
| ----------- | ------------ | ------------- | ------------|
| GetServiceVersion | [.google.protobuf.Empty](#google-protobuf-Empty) | [GetServiceVersionResponse](#jonline-GetServiceVersionResponse) | Get the version (from Cargo) of the Jonline service. *Publicly accessible.* |
| GetServerConfiguration | [.google.protobuf.Empty](#google-protobuf-Empty) | [ServerConfiguration](#jonline-ServerConfiguration) | Gets the Jonline server&#39;s configuration. *Publicly accessible.* |
| CreateAccount | [CreateAccountRequest](#jonline-CreateAccountRequest) | [RefreshTokenResponse](#jonline-RefreshTokenResponse) | Creates a user account and provides a `refresh_token` (along with an `access_token`). *Publicly accessible.* |
| Login | [LoginRequest](#jonline-LoginRequest) | [RefreshTokenResponse](#jonline-RefreshTokenResponse) | Logs in a user and provides a `refresh_token` (along with an `access_token`). *Publicly accessible.* |
| AccessToken | [AccessTokenRequest](#jonline-AccessTokenRequest) | [AccessTokenResponse](#jonline-AccessTokenResponse) | Gets a new `access_token` (and possibly a new `refresh_token`, which should replace the old one in client storage), given a `refresh_token`. *Publicly accessible.* |
| GetCurrentUser | [.google.protobuf.Empty](#google-protobuf-Empty) | [User](#jonline-User) | Gets the current user. *Authenticated.* |
| ResetPassword | [ResetPasswordRequest](#jonline-ResetPasswordRequest) | [.google.protobuf.Empty](#google-protobuf-Empty) | Resets the current user&#39;s - or, for admins, a given user&#39;s - password. *Authenticated.* |
| GetMedia | [GetMediaRequest](#jonline-GetMediaRequest) | [GetMediaResponse](#jonline-GetMediaResponse) | Gets Media (Images, Videos, etc) uploaded/owned by the current user. *Authenticated.* To upload/download actual Media blob/binary data, use the [HTTP Media APIs](#media). |
| DeleteMedia | [Media](#jonline-Media) | [.google.protobuf.Empty](#google-protobuf-Empty) | Deletes a media item by ID. *Authenticated.* Note that media may still be accessible for 12 hours after deletes are requested, as separate jobs clean it up from S3/MinIO. Deleting other users&#39; media requires `ADMIN` permissions. |
| GetUsers | [GetUsersRequest](#jonline-GetUsersRequest) | [GetUsersResponse](#jonline-GetUsersResponse) | Gets Users. *Publicly accessible **or** Authenticated.* Unauthenticated calls only return Users of `GLOBAL_PUBLIC` visibility. |
| UpdateUser | [User](#jonline-User) | [User](#jonline-User) | Update a user by ID. *Authenticated.* Updating other users requires `ADMIN` permissions. |
| DeleteUser | [User](#jonline-User) | [.google.protobuf.Empty](#google-protobuf-Empty) | Deletes a user by ID. *Authenticated.* Deleting other users requires `ADMIN` permissions. |
| CreateFollow | [Follow](#jonline-Follow) | [Follow](#jonline-Follow) | Follow (or request to follow) a user. *Authenticated.* |
| UpdateFollow | [Follow](#jonline-Follow) | [Follow](#jonline-Follow) | Used to approve follow requests. *Authenticated.* |
| DeleteFollow | [Follow](#jonline-Follow) | [.google.protobuf.Empty](#google-protobuf-Empty) | Unfollow (or unrequest) a user. *Authenticated.* |
| GetGroups | [GetGroupsRequest](#jonline-GetGroupsRequest) | [GetGroupsResponse](#jonline-GetGroupsResponse) | Gets Groups. *Publicly accessible **or** Authenticated.* Unauthenticated calls only return Groups of `GLOBAL_PUBLIC` visibility. |
| CreateGroup | [Group](#jonline-Group) | [Group](#jonline-Group) | Creates a group with the current user as its admin. *Authenticated.* Requires the `CREATE_GROUPS` permission. |
| UpdateGroup | [Group](#jonline-Group) | [Group](#jonline-Group) | Update a Groups&#39;s information, default membership permissions or moderation. *Authenticated.* Requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user. |
| DeleteGroup | [Group](#jonline-Group) | [.google.protobuf.Empty](#google-protobuf-Empty) | Delete a Group. *Authenticated.* Requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user. |
| GetMembers | [GetMembersRequest](#jonline-GetMembersRequest) | [GetMembersResponse](#jonline-GetMembersResponse) | Get Members (User&#43;Membership) of a Group. *Publicly accessible **or** Authenticated.* |
| CreateMembership | [Membership](#jonline-Membership) | [Membership](#jonline-Membership) | Requests to join a group (or joins it), or sends an invite to the user. *Authenticated.* Memberships and moderations are set to their defaults. |
| UpdateMembership | [Membership](#jonline-Membership) | [Membership](#jonline-Membership) | Update aspects of a user&#39;s membership. *Authenticated.* Updating permissions requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user. Updating moderation (approving/denying/banning) requires the same, or `MODERATE_USERS` permissions within the group. |
| DeleteMembership | [Membership](#jonline-Membership) | [.google.protobuf.Empty](#google-protobuf-Empty) | Leave a group (or cancel membership request). *Authenticated.* |
| GetPosts | [GetPostsRequest](#jonline-GetPostsRequest) | [GetPostsResponse](#jonline-GetPostsResponse) | Gets Posts. *Publicly accessible **or** Authenticated.* Unauthenticated calls only return Posts of `GLOBAL_PUBLIC` visibility. |
| CreatePost | [Post](#jonline-Post) | [Post](#jonline-Post) | Creates a Post. *Authenticated.* |
| UpdatePost | [Post](#jonline-Post) | [Post](#jonline-Post) | Updates a Post. *Authenticated.* |
| DeletePost | [Post](#jonline-Post) | [Post](#jonline-Post) | (TODO) (Soft) deletes a Post. Returns the deleted version of the Post. *Authenticated.* |
| StarPost | [Post](#jonline-Post) | [Post](#jonline-Post) | Star a Post. *Unauthenticated.* |
| UnstarPost | [Post](#jonline-Post) | [Post](#jonline-Post) | Unstar a Post. *Unauthenticated.* |
| GetGroupPosts | [GetGroupPostsRequest](#jonline-GetGroupPostsRequest) | [GetGroupPostsResponse](#jonline-GetGroupPostsResponse) | Get GroupPosts for a Post (and optional group). *Publicly accessible **or** Authenticated.* |
| CreateGroupPost | [GroupPost](#jonline-GroupPost) | [GroupPost](#jonline-GroupPost) | Cross-post a Post to a Group. *Authenticated.* |
| UpdateGroupPost | [GroupPost](#jonline-GroupPost) | [GroupPost](#jonline-GroupPost) | Group Moderators: Approve/Reject a GroupPost. *Authenticated.* |
| DeleteGroupPost | [GroupPost](#jonline-GroupPost) | [.google.protobuf.Empty](#google-protobuf-Empty) | Delete a GroupPost. *Authenticated.* |
| GetEvents | [GetEventsRequest](#jonline-GetEventsRequest) | [GetEventsResponse](#jonline-GetEventsResponse) | Gets Events. *Publicly accessible **or** Authenticated.* Unauthenticated calls only return Events of `GLOBAL_PUBLIC` visibility. |
| CreateEvent | [Event](#jonline-Event) | [Event](#jonline-Event) | Creates an Event. *Authenticated.* |
| UpdateEvent | [Event](#jonline-Event) | [Event](#jonline-Event) | Updates an Event. *Authenticated.* |
| DeleteEvent | [Event](#jonline-Event) | [Event](#jonline-Event) | (TODO) (Soft) deletes a Event. Returns the deleted version of the Event. *Authenticated.* |
| GetEventAttendances | [GetEventAttendancesRequest](#jonline-GetEventAttendancesRequest) | [EventAttendances](#jonline-EventAttendances) | Gets EventAttendances for an EventInstance. *Publicly accessible **or** Authenticated.* |
| UpsertEventAttendance | [EventAttendance](#jonline-EventAttendance) | [EventAttendance](#jonline-EventAttendance) | Upsert an EventAttendance. *Publicly accessible **or** Authenticated, with anonymous RSVP support.* See [EventAttendance](#jonline-EventAttendance) and [AnonymousAttendee](#jonline-AnonymousAttendee) for details. tl;dr: Anonymous RSVPs may updated/deleted with the `AnonymousAttendee.auth_token` returned by this RPC (the client should save this for the user, and ideally, offer a link with the token). |
| DeleteEventAttendance | [EventAttendance](#jonline-EventAttendance) | [.google.protobuf.Empty](#google-protobuf-Empty) | Delete an EventAttendance. *Publicly accessible **or** Authenticated, with anonymous RSVP support.* |
| FederateProfile | [FederatedAccount](#jonline-FederatedAccount) | [FederatedAccount](#jonline-FederatedAccount) | Federate the current user&#39;s profile with another user profile. *Authenticated*. |
| DefederateProfile | [FederatedAccount](#jonline-FederatedAccount) | [.google.protobuf.Empty](#google-protobuf-Empty) | Authenticated*. |
| ConfigureServer | [ServerConfiguration](#jonline-ServerConfiguration) | [ServerConfiguration](#jonline-ServerConfiguration) | Configure the server (i.e. the response to GetServerConfiguration). *Authenticated.* Requires `ADMIN` permissions. |
| ResetData | [.google.protobuf.Empty](#google-protobuf-Empty) | [.google.protobuf.Empty](#google-protobuf-Empty) | Delete ALL Media, Posts, Groups and Users except the user who performed the RPC. *Authenticated.* Requires `ADMIN` permissions. Note: Server Configuration is not deleted. |
| StreamReplies | [Post](#jonline-Post) | [Post](#jonline-Post) stream | (TODO) Reply streaming interface. Currently just streams fake example data. |

 



<a name="authentication-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## authentication.proto



<a name="jonline-AccessTokenRequest"></a>

### AccessTokenRequest
Request for a new access token using a refresh token.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| refresh_token | [string](#string) |  | The refresh token to use to request a new access token. |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Optional *requested* expiration time for the token. Server may ignore this. |






<a name="jonline-AccessTokenResponse"></a>

### AccessTokenResponse
Returned when requesting access tokens.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| refresh_token | [ExpirableToken](#jonline-ExpirableToken) | optional | If a refresh token is returned, it should be stored. Old refresh tokens may expire *before* their indicated expiration. See: https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation |
| access_token | [ExpirableToken](#jonline-ExpirableToken) |  | The new access token. |






<a name="jonline-CreateAccountRequest"></a>

### CreateAccountRequest
Request to create a new account.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| username | [string](#string) |  | Username for the account to be created. Must not exist. |
| password | [string](#string) |  | Password for the account to be created. Must be at least 8 characters. |
| email | [ContactMethod](#jonline-ContactMethod) | optional | Email to be used as a contact method. |
| phone | [ContactMethod](#jonline-ContactMethod) | optional | Phone number to be used as a contact method. |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Request an expiration time for the Auth Token returned. By default it will not expire. |
| device_name | [string](#string) | optional | (Not yet implemented.) The name of the device being used to create the account. |






<a name="jonline-CreateThirdPartyRefreshTokenRequest"></a>

### CreateThirdPartyRefreshTokenRequest
Request to create a new third-party refresh token. Unlike `LoginRequest` or `CreateAccountRequest`, the user must be logged in to create a third-party refresh token.

Generally, this is used to create a refresh token for another Jonline instance,
e.g., accessing `bullcity.social/jon`&#39;s data from `jonline.io`. On the web side, this is implemented as follows:

1. When the `bullcity.social` user wants to login on `jonline.io`, `bullcity.social` will redirect 
the user to `jonline.io/third_party_auth?to=bullcity.social`.
2. `jonline.io` will force the user to login if needed on this page.
3. `jonline.io` will prompt/warn the user, and then call this RPC to create a refresh &#43; access token for `bullcity.social`.
4. `jonline.io` will redirect the user back to `bullcity.social/third_party_auth?from=jonline.io&amp;token=&lt;Base64RefreshTokenResponse&gt;` with the refresh token POSTed in form data.
    * (`&lt;Base64RefreshTokenResponse&gt;` is a base64-encoded `RefreshTokenResponse` message.)
6. `bullcity.social` will ensure it can `GetCurrentUser` on `jonline.io` with its new auth token.
5. `bullcity.social` will replace the current location with `bullcity.social/third_party_auth?from=jonline.io`.
7. `bullcity.social` will use the access token to make requests to `jonline.io` (the same as with `bullcity.social`).

Note that refresh tokens


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The third-party refresh token&#39;s expiration time. |
| user_id | [string](#string) |  | The third-party refresh token&#39;s user ID. |
| device_name | [string](#string) |  | The third-party refresh token&#39;s device name. |






<a name="jonline-ExpirableToken"></a>

### ExpirableToken
Generic type for refresh and access tokens.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| token | [string](#string) |  | The secure token value. |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Optional expiration time for the token. If not set, the token will not expire. |






<a name="jonline-LoginRequest"></a>

### LoginRequest
Request to login to an existing account.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| username | [string](#string) |  | Username for the account to be logged into. Must exist. |
| password | [string](#string) |  | Password for the account to be logged into. |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Request an expiration time for the Auth Token returned. By default it will not expire. |
| device_name | [string](#string) | optional | (Not yet implemented.) The name of the device being used to login. |
| user_id | [string](#string) | optional | (TODO) If provided, username is ignored and login is initiated via user_id instead. |






<a name="jonline-RefreshTokenMetadata"></a>

### RefreshTokenMetadata
Metadata on a refresh token for the current user, used when managing refresh tokens as a user.
Does not include the token itself.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [uint64](#uint64) |  | The DB ID of the refresh token. Used when deleting the token or updating the device_name. |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Expiration date of the refresh token. |
| device_name | [string](#string) | optional | The device name the refresh token is on. User-updateable. |
| is_this_device | [bool](#bool) |  | Whether the refresh token is associated with the current device (based on what user is making the request). |
| third_party | [bool](#bool) |  |  |






<a name="jonline-RefreshTokenResponse"></a>

### RefreshTokenResponse
Returned when creating an account, logging in, or creating a third-party refresh token.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| refresh_token | [ExpirableToken](#jonline-ExpirableToken) |  | The persisted token the device should store and associate with the account. Used to request new access tokens. |
| access_token | [ExpirableToken](#jonline-ExpirableToken) |  | An initial access token provided for convenience. |
| user | [User](#jonline-User) |  | The user associated with the account that was created/logged into. |






<a name="jonline-ResetPasswordRequest"></a>

### ResetPasswordRequest
Request to reset a password.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user_id | [string](#string) | optional | If not set, use the current user of the request. |
| password | [string](#string) |  | The new password to set. |






<a name="jonline-UserRefreshTokensResponse"></a>

### UserRefreshTokensResponse
Response for `GetUserRefreshTokens` RPC. Returns all refresh tokens associated with the current user.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| refresh_tokens | [RefreshTokenMetadata](#jonline-RefreshTokenMetadata) | repeated | The refresh tokens associated with the current user. |





 

 

 

 



<a name="visibility_moderation-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## visibility_moderation.proto


 


<a name="jonline-Moderation"></a>

### Moderation
Nearly everything in Jonline has one or more `Moderation`s on it.

From a high level:

- A `User` has a `moderation` that determines whether they can log in (and their visibility per their `visibility`).
  (This is poorly enforced currently! Fix it if you want!)
    - This is managed by `people_settings.default_moderation` in `ServerConfiguration`.
      A default of `UNMODERATED` means that all users can log in. A default of `PENDING`
      means that all users must be approved by a moderator/admin before they can log in.
- A `Follow` has a `target_user_moderation` that determines whether the `User` is following the `Group`.
   - It is managed by `default_follow_moderation` in the targeted `User`.
- A `Group` has a `moderation` that determines whether the `Group` is visible to users (per its `visibility`).
    - This is managed by `group_settings.default_moderation` in `ServerConfiguration`.
- A `Membership` has a `group_moderation` and `user_moderation` that determine whether
  the `Group` admins and/or the invited user has approved the `Membership`, respectively.
    - User invites to `Group`s (i.e. the `user_moderation`) always start as `PENDING`.
      The group side of this is managed by `default_membership_moderation` of the `Group` in question.
- A `Post` has a `moderation` that determines whether the `Post` is visible to users (per its `visibility`).
    - This is managed by `post_settings.default_moderation` in `ServerConfiguration`.
- A `GroupPost` has a `moderation` that determines whether the admins/mods of the `Group` has approved the `Post` (or `Post`-descended thing like `Event`s).
- `Event`s and further objects contain a `Post` and thus inherit its `moderation` and
  related `GroupPost` behavior, for &#34;Group Events.&#34;

| Name | Number | Description |
| ---- | ------ | ----------- |
| MODERATION_UNKNOWN | 0 | A moderation that is not known to the protocol. (Likely, the client and server use different versions of the Jonline protocol.) |
| UNMODERATED | 1 | Subject has not been moderated and is visible to all users. |
| PENDING | 2 | Subject is awaiting moderation and not visible to any users. |
| APPROVED | 3 | Subject has been approved by moderators and is visible to all users. |
| REJECTED | 4 | Subject has been rejected by moderators and is not visible to any users. |



<a name="jonline-Visibility"></a>

### Visibility
Visibility in Jonline is a complex topic. There are several different types of visibility, 
and each type of entity (`User`, `Media`, `Group`, then `Post`/`Event`/etc. with common logic)
has different rules for visibility.

From the top down, the rules break down as follows:

- Even a `PRIVATE` entity is always visible to the user who owns it.
    - For `Group`s, this means all full members of the `Group`.
    - For `User`s, this is confusing and there is a whole `PrivateUserStrategy` thing
      in `ServerConfiguration` for this.
- A `LIMITED` entity is visible to to the owner(s) and any explicitly associated
  `User`s and `Group`s. Generally, this only applies to `Post`/`Event`/etc. entities.
  Associations exist via `UserPost`s and `GroupPost`s.
    - This is currently only implemented for `Group`s and `GroupPost`s. There are some
      choices to be made about how to implement this for `User`s and `UserPost`s, and whether
      `DIRECT` should be a separate visibility type.
- A `SERVER_PUBLIC` entity is visible to all authenticated users.
- A `GLOBAL_PUBLIC` entity is visible to the open internet.

| Name | Number | Description |
| ---- | ------ | ----------- |
| VISIBILITY_UNKNOWN | 0 | A visibility that is not known to the protocol. (Likely, the client and server use different versions of the Jonline protocol.) |
| PRIVATE | 1 | Subject is only visible to the user who owns it. |
| LIMITED | 2 | Subject is only visible to explictly associated Groups and Users. See: [`GroupPost`](#jonline-GroupPost) and [`UserPost`](#jonline-UserPost). |
| SERVER_PUBLIC | 3 | Subject is visible to all authenticated users. |
| GLOBAL_PUBLIC | 4 | Subject is visible to all users on the internet. |
| DIRECT | 5 | [TODO] Subject is visible to explicitly-associated Users. Only applicable to Posts and Events. For Users, this is the same as LIMITED. See: [`UserPost`](#jonline-UserPost). |


 

 

 



<a name="permissions-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## permissions.proto


 


<a name="jonline-Permission"></a>

### Permission
Jonline Permissions are a set of permissions that can be granted directly to [`User`](#jonline-User)s and [`Membership`](#jonline-Membership)s.
(A `Membership` is the link between a [`Group`](#jonline-Group) and a `User`.)

Subsets of these permissions are also applicable to anonymous users via [`anonymous_user_permissions` in `ServerConfiguration`](#jonline-ServerConfiguration),
and to Group non-members via [`non_member_permissions` in `Group`](#jonline-Group), as well as others documented there.

| Name | Number | Description |
| ---- | ------ | ----------- |
| PERMISSION_UNKNOWN | 0 | A permission that could not be read using the Jonline protocol. (Perhaps, a permission from a newer Jonline version.) |
| VIEW_USERS | 1 | Allow the user to view profiles with `SERVER_PUBLIC` Visbility. Allow anonymous users to view profiles with `GLOBAL_PUBLIC` Visbility (when configured as an anonymous user permission). |
| PUBLISH_USERS_LOCALLY | 2 | Allow the user to publish profiles with `SERVER_PUBLIC` Visbility. This generally only applies to the user&#39;s own profile, except for Admins. |
| PUBLISH_USERS_GLOBALLY | 3 | Allow the user to publish profiles with `GLOBAL_PUBLIC` Visbility. This generally only applies to the user&#39;s own profile, except for Admins. |
| MODERATE_USERS | 4 | Allow the user to grant `VIEW_POSTS`, `CREATE_POSTS`, `VIEW_EVENTS` and `CREATE_EVENTS` permissions to users. |
| FOLLOW_USERS | 5 | Allow the user to follow other users. |
| GRANT_BASIC_PERMISSIONS | 6 | Allow the user to grant Basic Permissions to other users. &#34;Basic Permissions&#34; are defined by your `ServerConfiguration`&#39;s `basic_user_permissions`. |
| VIEW_GROUPS | 10 | Allow the user to view groups with `SERVER_PUBLIC` visibility. Allow anonymous users to view groups with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission). |
| CREATE_GROUPS | 11 | Allow the user to create groups. |
| PUBLISH_GROUPS_LOCALLY | 12 | Allow the user to give groups `SERVER_PUBLIC` visibility. |
| PUBLISH_GROUPS_GLOBALLY | 13 | Allow the user to give groups `GLOBAL_PUBLIC` visibility. |
| MODERATE_GROUPS | 14 | The Moderate Groups permission makes a user effectively an admin of *any* group. |
| JOIN_GROUPS | 15 | Allow the user to (potentially request to) join groups of `SERVER_PUBLIC` or higher visibility. |
| INVITE_GROUP_MEMBERS | 16 | Allow the user to invite other users to groups. Only applicable as a Group permission (not at the User level). |
| VIEW_POSTS | 20 | As a user permission, allow the user to view posts with `SERVER_PUBLIC` or higher visibility. As a group permission, allow the user to view `GroupPost`s whose `Post`s have `LIMITED` or higher visibility. Allow anonymous users to view posts with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission). |
| CREATE_POSTS | 21 | As a user permission, allow the user to create `Post`s of `PRIVATE` and `LIMITED` visibility. As a group permission, allow the user to create `GroupPost`s for `POST` and `FEDERATED_POST` `PostContext`s.. |
| PUBLISH_POSTS_LOCALLY | 22 | Allow the user to publish posts with `SERVER_PUBLIC` visibility. |
| PUBLISH_POSTS_GLOBALLY | 23 | Allow the user to publish posts with `GLOBAL_PUBLIC` visibility. |
| MODERATE_POSTS | 24 | Allow the user to moderate posts. |
| REPLY_TO_POSTS | 25 | Allow the user to reply to posts. |
| VIEW_EVENTS | 30 | As a user permission, allow the user to view posts with `SERVER_PUBLIC` or higher visibility. As a group permission, allow the user to view `GroupPost`s whose `Event` `Post`s have `LIMITED` or higher visibility. Allow anonymous users to view events with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission). |
| CREATE_EVENTS | 31 | As a user permission, allow the user to create `Event`s of `PRIVATE` and `LIMITED` visibility. As a group permission, allow the user to create `GroupPost`s for `EVENT` and `FEDERATED_EVENT_INSTANCE` `PostContext`s.. |
| PUBLISH_EVENTS_LOCALLY | 32 | Allow the user to publish events with `SERVER_PUBLIC` visibility. |
| PUBLISH_EVENTS_GLOBALLY | 33 | Allow the user to publish events with `GLOBAL_PUBLIC` visibility. |
| MODERATE_EVENTS | 34 | Allow the user to moderate events. |
| RSVP_TO_EVENTS | 35 | Allow the user to RSVP to events that allow RSVPs. |
| VIEW_MEDIA | 40 | Allow the user to view media with `SERVER_PUBLIC` or higher visibility. *Not currently enforced.* Allow anonymous users to view media with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission). *Not currently enforced.* |
| CREATE_MEDIA | 41 | Allow the user to create media of `PRIVATE` and `LIMITED` visibility. *Not currently enforced.* |
| PUBLISH_MEDIA_LOCALLY | 42 | Allow the user to publish media with `SERVER_PUBLIC` visibility. *Not currently enforced.* |
| PUBLISH_MEDIA_GLOBALLY | 43 | Allow the user to publish media with `GLOBAL_PUBLIC` visibility. *Not currently enforced.* |
| MODERATE_MEDIA | 44 | Allow the user to moderate events. |
| BUSINESS | 9998 | Indicates the user is a business. Used purely for display purposes. |
| RUN_BOTS | 9999 | Allow the user to run bots. There is no enforcement of this permission (yet), but it lets other users know that the user is allowed to run bots. |
| ADMIN | 10000 | Marks the user as an admin. In the context of user permissions, allows the user to configure the server, moderate/update visibility/permissions to any `User`, `Group`, `Post` or `Event`. In the context of group permissions, allows the user to configure the group, modify members and member permissions, and moderate `GroupPost`s and `GroupEvent`s. |
| VIEW_PRIVATE_CONTACT_METHODS | 10001 | Allow the user to view the private contact methods of other users. Kept separate from `ADMIN` to allow for more fine-grained privacy control. |


 

 

 



<a name="users-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## users.proto



<a name="jonline-Author"></a>

### Author
Post/authorship-centric version of User. UI can cross-reference user details
from its own cache (for things like admin/bot icons).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user_id | [string](#string) |  | Permanent string ID for the user. Will never contain a `@` symbol. |
| username | [string](#string) | optional | Impermanent string username for the user. Will never contain a `@` symbol. |
| avatar | [MediaReference](#jonline-MediaReference) | optional | The user&#39;s avatar. |
| real_name | [string](#string) | optional |  |
| permissions | [Permission](#jonline-Permission) | repeated |  |






<a name="jonline-ContactMethod"></a>

### ContactMethod
A contact method for a user. Models designed to support verification,
but verification RPCs are not yet implemented.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| value | [string](#string) | optional | Either a `mailto:` or `tel:` URL. |
| visibility | [Visibility](#jonline-Visibility) |  | The visibility of the contact method. |
| supported_by_server | [bool](#bool) |  | Server-side flag indicating whether the server can verify (and otherwise interact via) the contact method. |
| verified | [bool](#bool) |  | Indicates the user has completed verification of the contact method. Verification requires `supported_by_server` to be `true`. |






<a name="jonline-Follow"></a>

### Follow
Model for a user&#39;s follow of another user.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user_id | [string](#string) |  | The follower in the relationship. |
| target_user_id | [string](#string) |  | The user being followed. |
| target_user_moderation | [Moderation](#jonline-Moderation) |  | Tracks whether the target user needs to approve the follow. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the follow was created. |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the follow was last updated. |






<a name="jonline-GetUsersRequest"></a>

### GetUsersRequest
Request to get one or more users by a variety of parameters.
Supported parameters depend on `listing_type`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| username | [string](#string) | optional | The username to search for. Substrings are supported. |
| user_id | [string](#string) | optional | The user ID to search for. |
| page | [int32](#int32) | optional | The page of results to return. Pages are 0-indexed. |
| listing_type | [UserListingType](#jonline-UserListingType) |  | The number of results to return per page. |






<a name="jonline-GetUsersResponse"></a>

### GetUsersResponse
Response to a `GetUsersRequest`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| users | [User](#jonline-User) | repeated | The users matching the request. |
| has_next_page | [bool](#bool) |  | Whether there are more pages of results. |






<a name="jonline-Membership"></a>

### Membership
Model for a user&#39;s membership in a group. Memberships are generically
included as part of User models when relevant in Jonline, but UIs should use the group_id
to reconcile memberships with groups.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user_id | [string](#string) |  | The member (or requested/invited member). |
| group_id | [string](#string) |  | The group the membership pertains to. |
| permissions | [Permission](#jonline-Permission) | repeated | Valid Membership Permissions are: `VIEW_POSTS`, `CREATE_POSTS`, `MODERATE_POSTS`, `VIEW_EVENTS`, CREATE_EVENTS, `MODERATE_EVENTS`, `ADMIN`, `RUN_BOTS`, and `MODERATE_USERS` |
| group_moderation | [Moderation](#jonline-Moderation) |  | Tracks whether group moderators need to approve the membership. |
| user_moderation | [Moderation](#jonline-Moderation) |  | Tracks whether the user needs to approve the membership. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the membership was created. |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the membership was last updated. |






<a name="jonline-User"></a>

### User
Model for a Jonline user. This user may have [`Media`](#jonline-Media), [`Group`](#jonline-Group) [`Membership`](#jonline-Membership)s,
[`Post`](#jonline-Post)s, [`Event`](#jonline-Event)s, and other objects associated with them.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | Permanent string ID for the user. Will never contain a `@` symbol. |
| username | [string](#string) |  | Impermanent string username for the user. Will never contain a `@` symbol. |
| real_name | [string](#string) |  | The user&#39;s real name. |
| email | [ContactMethod](#jonline-ContactMethod) | optional | The user&#39;s email address. |
| phone | [ContactMethod](#jonline-ContactMethod) | optional | The user&#39;s phone number. |
| permissions | [Permission](#jonline-Permission) | repeated | The user&#39;s permissions. See [`Permission`](#jonline-Permission) for details. |
| avatar | [MediaReference](#jonline-MediaReference) | optional | The user&#39;s avatar. Note that its visibility is managed by the User and thus it may not be accessible to the current user. |
| bio | [string](#string) |  | The user&#39;s bio. |
| visibility | [Visibility](#jonline-Visibility) |  | User visibility is a bit different from Post visibility. LIMITED means the user can only be seen by users they follow (as opposed to Posts&#39; individualized visibilities). PRIVATE visibility means no one can see the user. See server_configuration.proto for details about PRIVATE users&#39; ability to creep. |
| moderation | [Moderation](#jonline-Moderation) |  | The user&#39;s moderation status. See [`Moderation`](#jonline-Moderation) for details. |
| default_follow_moderation | [Moderation](#jonline-Moderation) |  | Only PENDING or UNMODERATED are valid. |
| follower_count | [int32](#int32) | optional | The number of users following this user. |
| following_count | [int32](#int32) | optional | The number of users this user is following. |
| group_count | [int32](#int32) | optional | The number of groups this user is a member of. |
| post_count | [int32](#int32) | optional | The number of posts this user has made. |
| response_count | [int32](#int32) | optional | The number of responses to `Post`s and `Event`s this user has made. |
| event_count | [int32](#int32) | optional | The number of events this user has created. |
| current_user_follow | [Follow](#jonline-Follow) | optional | Presence indicates the current user is following or has a pending follow request for this user. |
| target_current_user_follow | [Follow](#jonline-Follow) | optional | Presence indicates this user is following or has a pending follow request for the current user. |
| current_group_membership | [Membership](#jonline-Membership) | optional | Returned by `GetMembers` calls, for use when managing [`Group`](#jonline-Group) [`Membership`](#jonline-Membership)s. The `Membership` should match the `Group` from the originating [`GetMembersRequest`](#jonline-GetMembersRequest), providing whether the user is a member of that `Group`, has been invited, requested to join, etc.. |
| has_advanced_data | [bool](#bool) |  | Indicates that `federated_profiles` has been loaded. |
| federated_profiles | [FederatedAccount](#jonline-FederatedAccount) | repeated | Federated profiles for the user. *Not always loaded.* This is a list of profiles from other servers that the user has connected to their account. Managed by the user via `Federate` |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the user was created. |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the user was last updated. |





 


<a name="jonline-UserListingType"></a>

### UserListingType
Ways of listing users.

| Name | Number | Description |
| ---- | ------ | ----------- |
| EVERYONE | 0 | Get all users. |
| FOLLOWING | 1 | Get users the current user is following. |
| FRIENDS | 2 | Get users who follow and are followed by the current user. |
| FOLLOWERS | 3 | Get users who follow the current user. |
| FOLLOW_REQUESTS | 4 | Get users who have requested to follow the current user. |
| ADMINS | 10 | [TODO] Gets admins for a server. |


 

 

 



<a name="media-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## media.proto



<a name="jonline-GetMediaRequest"></a>

### GetMediaRequest
Valid GetMediaRequest formats:
- `{user_id: abc123}` - Gets the media of the given user that the current user can see. IE:
    - *all* of the current user&#39;s own media
    - `GLOBAL_PUBLIC` media for the user if the current user is not logged in.
    - `SERVER_PUBLIC` media for the user if the current user is logged in.
    - `LIMITED` media for the user if the current user is following the user.
- `{media_id: abc123}` - Gets the media with the given ID, if visible to the current user.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| media_id | [string](#string) | optional | Returns the single media item with the given ID. |
| user_id | [string](#string) | optional | Returns all media items for the given user. |
| page | [uint32](#uint32) |  |  |






<a name="jonline-GetMediaResponse"></a>

### GetMediaResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| media | [Media](#jonline-Media) | repeated |  |
| has_next_page | [bool](#bool) |  |  |






<a name="jonline-Media"></a>

### Media
A Jonline `Media` message represents a single media item, such as a photo or video.
Media data is deliberately *not accessible from the gRPC API*. Instead, the client
should fetch media from `http[s]://my.jonline.instance/media/{id}`.

Media items may be created with a HTTP POST to `http[s]://my.jonline.instance/media`
along with an &#34;Authorization&#34; header (your access token) and a &#34;Content-Type&#34; header.
On success, the endpoint will return the media ID in plaintext.

`POST /media` supports the following headers:
- `Content-Type` - The MIME content type of the media item.
- `Filename` - An optional title for the media item.
- `Authorization` - Jonline Access Token for the user. Required, but may be supplied in `Cookies`.
- `Cookies` - Standard web cookies. The `jonline_access_token` cookie may be used for authentication.

`GET /media/{id}` supports the following:
- **Headers**:
    - `Authorization` - Jonline Access Token for the user. May also be supplied in `Cookies` or via query parameter.
    - `Cookies` - Standard web cookies. The `jonline_access_token` cookie may be used for authentication.
- **Query Parameters**:
    - `authorization` - Jonline Access Token for the user. May also be supplied in the `Cookies` or `Authorization` headers.
- Fetching media without authentication requires that it has `GLOBAL_PUBLIC` visibility.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | The ID of the media item. |
| user_id | [string](#string) | optional | The ID of the user who created the media item. |
| content_type | [string](#string) |  | The MIME content type of the media item. |
| name | [string](#string) | optional | An optional title for the media item. |
| description | [string](#string) | optional | An optional description for the media item. |
| visibility | [Visibility](#jonline-Visibility) |  | Visibility of the media item. |
| moderation | [Moderation](#jonline-Moderation) |  | Moderation of the media item. |
| generated | [bool](#bool) |  | Indicates the media was generated by the server rather than uploaded manually by a user. |
| processed | [bool](#bool) |  | Media is generally stored as-is on upload. When background jobs process and compress the media, this flag is set to true. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |






<a name="jonline-MediaReference"></a>

### MediaReference
A reference to a media item, designed to be included in other messages as a reference.
Contains the bare minimum data needed to fetch media via the HTTP API and render it,
and the media item&#39;s name (for alt text usage).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| content_type | [string](#string) |  | The MIME content type of the media item. |
| id | [string](#string) |  | The ID of the media item. |
| name | [string](#string) | optional | An optional title for the media item. |
| generated | [bool](#bool) |  | Indicates the media was generated by the server rather than uploaded manually by a user. |





 

 

 

 



<a name="groups-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## groups.proto



<a name="jonline-GetGroupsRequest"></a>

### GetGroupsRequest
Request to get a group or groups by name or ID.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_id | [string](#string) | optional | The ID of the group to get. |
| group_name | [string](#string) | optional | The name of the group to get. |
| group_shortname | [string](#string) | optional | The shortname of the group to get. Group shortname search is case-insensitive. |
| listing_type | [GroupListingType](#jonline-GroupListingType) |  | The group listing type. |
| page | [int32](#int32) | optional | The page of results to get. |






<a name="jonline-GetGroupsResponse"></a>

### GetGroupsResponse
Response to a GetGroupsRequest.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| groups | [Group](#jonline-Group) | repeated | The groups that matched the request. |
| has_next_page | [bool](#bool) |  | Whether there are more groups to get. |






<a name="jonline-GetMembersRequest"></a>

### GetMembersRequest
Request to get members of a group.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_id | [string](#string) |  | The ID of the group to get members of. |
| username | [string](#string) | optional | The username of the members to search for. |
| group_moderation | [Moderation](#jonline-Moderation) | optional | The membership status to filter members by. If not specified, all members are returned. |
| page | [int32](#int32) | optional | The page of results to get. |






<a name="jonline-GetMembersResponse"></a>

### GetMembersResponse
Response to a GetMembersRequest.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| members | [Member](#jonline-Member) | repeated | The members that matched the request. |
| has_next_page | [bool](#bool) |  | Whether there are more members to get. |






<a name="jonline-Group"></a>

### Group
`Group`s are a way to organize users and posts (and thus events). They can be used for many purposes,


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | The group&#39;s unique ID. |
| name | [string](#string) |  | Mutable name of the group. Must be unique, such that the derived `shortname` is also unique. |
| shortname | [string](#string) |  | Immutable shortname of the group. Derived from changes to `name` when the `Group` is updated. |
| description | [string](#string) |  | A description of the group. |
| avatar | [MediaReference](#jonline-MediaReference) | optional | An avatar for the group. |
| default_membership_permissions | [Permission](#jonline-Permission) | repeated | The default permissions for new members of the group. |
| default_membership_moderation | [Moderation](#jonline-Moderation) |  | The default moderation for new members of the group. Valid values are PENDING (requires a moderator to let you join) and UNMODERATED. |
| default_post_moderation | [Moderation](#jonline-Moderation) |  | The default moderation for new posts in the group. |
| default_event_moderation | [Moderation](#jonline-Moderation) |  | The default moderation for new events in the group. |
| visibility | [Visibility](#jonline-Visibility) |  | LIMITED visibility groups are only visible to members. PRIVATE groups are only visibile to users with the ADMIN group permission. |
| member_count | [uint32](#uint32) |  | The number of members in the group. |
| post_count | [uint32](#uint32) |  | The number of posts in the group. |
| event_count | [uint32](#uint32) |  | The number of events in the group. |
| non_member_permissions | [Permission](#jonline-Permission) | repeated | The permissions given to non-members of the group. |
| current_user_membership | [Membership](#jonline-Membership) | optional | The membership for the current user, if any. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the group was created. |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the group was last updated. |






<a name="jonline-Member"></a>

### Member
Used when fetching group members using the `GetMembers` RPC.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user | [User](#jonline-User) |  | The user. |
| membership | [Membership](#jonline-Membership) |  | The user&#39;s membership (or join request, or invitation, or both) in the group. |





 


<a name="jonline-GroupListingType"></a>

### GroupListingType
The type of group listing to get.

| Name | Number | Description |
| ---- | ------ | ----------- |
| ALL_GROUPS | 0 | Get all groups (visible to the current user). |
| MY_GROUPS | 1 | Get groups the current user is a member of. |
| REQUESTED_GROUPS | 2 | Get groups the current user has requested to join. |
| INVITED_GROUPS | 3 | Get groups the current user has been invited to. |


 

 

 



<a name="posts-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## posts.proto



<a name="jonline-GetGroupPostsRequest"></a>

### GetGroupPostsRequest
Used for getting context about `GroupPost`s of an existing `Post`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| post_id | [string](#string) |  | The ID of the post to get `GroupPost`s for. |
| group_id | [string](#string) | optional | The ID of the group to get `GroupPost`s for. |






<a name="jonline-GetGroupPostsResponse"></a>

### GetGroupPostsResponse
Used for getting context about `GroupPost`s of an existing `Post`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_posts | [GroupPost](#jonline-GroupPost) | repeated | The `GroupPost`s for the given `Post` or `Group`. |






<a name="jonline-GetPostsRequest"></a>

### GetPostsRequest
Valid GetPostsRequest formats:

- `{[listing_type: AllAccessiblePosts]}`
    - Get ServerPublic/GlobalPublic posts you can see based on your authorization (or lack thereof).
- `{listing_type:MyGroupsPosts|FollowingPosts}`
    - Get posts from groups you&#39;re a member of or from users you&#39;re following. Authorization required.
- `{post_id:}`
    - Get one post ,including preview data/
- `{post_id:, reply_depth: 1}`
    - Get replies to a post - only support for replyDepth=1 is done for now though.
- `{listing_type: MyGroupsPosts|`GroupPost`sPendingModeration, group_id:}`
    - Get posts/posts needing moderation for a group. Authorization may be required depending on group visibility.
- `{author_user_id:, group_id:}`
    - Get posts by a user for a group. (TODO)
- `{listing_type: AuthorPosts, author_user_id:}`
    - Get posts by a user. (TODO)


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| post_id | [string](#string) | optional | Returns the single post with the given ID. |
| author_user_id | [string](#string) | optional | Limits results to those by the given author user ID. |
| group_id | [string](#string) | optional | Limits results to those in the given group ID. |
| reply_depth | [uint32](#uint32) | optional | Only supported for depth=2 for now. |
| context | [PostContext](#jonline-PostContext) | optional | Only POST and REPLY are supported for now. |
| post_ids | [string](#string) | optional | Returns expanded posts with the given IDs. |
| listing_type | [PostListingType](#jonline-PostListingType) |  | The listing type of the request. See `PostListingType` for more info. |
| page | [uint32](#uint32) |  | The page of results to return. Defaults to 0. |






<a name="jonline-GetPostsResponse"></a>

### GetPostsResponse
Used for getting posts.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| posts | [Post](#jonline-Post) | repeated | The posts returned by the request. |






<a name="jonline-GroupPost"></a>

### GroupPost
A `GroupPost` is a cross-post of a `Post` to a `Group`. It contains
information about the moderation of the post in the group, as well as
the time it was cross-posted and the user who did the cross-posting.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_id | [string](#string) |  | The ID of the group this post is in. |
| post_id | [string](#string) |  | The ID of the post. |
| user_id | [string](#string) |  | **Deprecated.** Deprecated.** Prefer to use `shared_by`. The ID of the user who cross-posted the post. |
| group_moderation | [Moderation](#jonline-Moderation) |  | The moderation of the post in the group. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the post was cross-posted. |
| shared_by | [Author](#jonline-Author) |  | Author info for the user who cross-posted the post. |






<a name="jonline-Post"></a>

### Post
A `Post` is a message that can be posted to the server. Its `visibility`
as well as any associated `GroupPost`s and `UserPost`s determine what users
see it and where.

`Post`s are also a fundamental unit of the system. They provide a building block
of Visibility and Moderation management that is used throughout Posts, Replies, Events,
and Event Instances.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | Unique ID of the post. |
| author | [Author](#jonline-Author) | optional | The author of the post. This is a smaller version of User. |
| reply_to_post_id | [string](#string) | optional | If this is a reply, this is the ID of the post it&#39;s replying to. |
| title | [string](#string) | optional | The title of the post. This is invalid for replies. |
| link | [string](#string) | optional | The link of the post. This is invalid for replies. |
| content | [string](#string) | optional | The content of the post. This is required for replies. |
| response_count | [int32](#int32) |  | The number of responses (replies *and* replies to replies, etc.) to this post. |
| reply_count | [int32](#int32) |  | The number of *direct* replies to this post. |
| group_count | [int32](#int32) |  | The number of groups this post is in. |
| media | [MediaReference](#jonline-MediaReference) | repeated | List of Media IDs associated with this post. Order is preserved. |
| media_generated | [bool](#bool) |  | Flag indicating whether Media has been generated for this Post. Currently previews are generated for any Link post. |
| embed_link | [bool](#bool) |  | Flag indicating |
| shareable | [bool](#bool) |  | Flag indicating a `LIMITED` or `SERVER_PUBLIC` post can be shared with groups and individuals, and a `DIRECT` post can be shared with individuals. |
| context | [PostContext](#jonline-PostContext) |  | Context of the Post (`POST`, `REPLY`, `EVENT`, or `EVENT_INSTANCE`.) |
| visibility | [Visibility](#jonline-Visibility) |  | The visibility of the Post. |
| moderation | [Moderation](#jonline-Moderation) |  | The moderation of the Post. |
| current_group_post | [GroupPost](#jonline-GroupPost) | optional | If the Post was retrieved from GetPosts with a group_id, the GroupPost metadata may be returned along with the Post. |
| replies | [Post](#jonline-Post) | repeated | Hierarchical replies to this post. There will never be more than `reply_count` replies. However, there may be fewer than `reply_count` replies if some replies are hidden by moderation or visibility. Replies are not generally loaded by default, but can be added to Posts in the frontend. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the post was created. |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the post was last updated. |
| published_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the post was published (its visibility first changed to `SERVER_PUBLIC` or `GLOBAL_PUBLIC`). |
| last_activity_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the post was last interacted with (replied to, etc.) |
| unauthenticated_star_count | [int64](#int64) |  | The number of unauthenticated stars on the post. |






<a name="jonline-UserPost"></a>

### UserPost
A `UserPost` is a &#34;direct share&#34; of a `Post` to a `User`. Currently unused/unimplemented.
See also: [`DIRECT` `Visibility`](#jonline-Visibility).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user_id | [string](#string) |  | The ID of the user the post is shared with. |
| post_id | [string](#string) |  | The ID of the post shared. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the post was shared. |





 


<a name="jonline-PostContext"></a>

### PostContext
Differentiates the context of a Post, as in Jonline&#39;s data models, Post is the &#34;core&#34; type where Jonline consolidates moderation and visibility data and logic.

| Name | Number | Description |
| ---- | ------ | ----------- |
| POST | 0 | &#34;Standard&#34; Post. |
| REPLY | 1 | Reply to a `POST`, `REPLY`, `EVENT`, `EVENT_INSTANCE`, `FEDERATED_POST`, or `FEDERATED_EVENT_INSTANCE`. Does not suport a `link`. |
| EVENT | 2 | An &#34;Event&#34; Post. The Events table should have a row for this Post. These Posts&#39; `link` and `title` fields are modifiable. |
| EVENT_INSTANCE | 3 | An &#34;Event Instance&#34; Post. The EventInstances table should have a row for this Post. These Posts&#39; `link` and `title` fields are modifiable. |
| FEDERATED_POST | 10 | A &#34;Federated&#34; Post. This is a Post that was created on another server. Its `link` field *must* be a link to the original Post, i.e. `htttps://jonline.io/post/abcd1234`. This is enforced by the `CreatePost` PRC. |
| FEDERATED_EVENT_INSTANCE | 13 | A &#34;Federated&#34; EventInstance. This is an EventInstance that was created on another server. Its `link` field *must* be a link to the original EventInstance, i.e. `https://jonline.io/event/abcd1234`. |



<a name="jonline-PostListingType"></a>

### PostListingType
A high-level enumeration of general ways of requesting posts.

| Name | Number | Description |
| ---- | ------ | ----------- |
| ALL_ACCESSIBLE_POSTS | 0 | Gets SERVER_PUBLIC and GLOBAL_PUBLIC posts as is sensible. Also usable for getting replies anywhere. |
| FOLLOWING_POSTS | 1 | Returns posts from users the user is following. |
| MY_GROUPS_POSTS | 2 | Returns posts from any group the user is a member of. |
| DIRECT_POSTS | 3 | Returns `DIRECT` posts that are directly addressed to the user. |
| POSTS_PENDING_MODERATION | 4 | Returns posts pending moderation by the server-level mods/admins. |
| GROUP_POSTS | 10 | Returns posts from a specific group. Requires group_id parameter. |
| GROUP_POSTS_PENDING_MODERATION | 11 | Returns pending_moderation posts from a specific group. Requires group_id parameter and user must have group (or server) admin permissions. |


 

 

 



<a name="events-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## events.proto



<a name="jonline-AnonymousAttendee"></a>

### AnonymousAttendee
An anonymous internet user who has RSVP&#39;d to an `EventInstance`.

(TODO:) The visibility on `AnonymousAttendee` `ContactMethod`s should support the `LIMITED` visibility, which will
make them visible to the event creator.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| name | [string](#string) |  | A name for the anonymous user. For instance, &#34;Bob Gomez&#34; or &#34;The guy on your front porch.&#34; |
| contact_methods | [ContactMethod](#jonline-ContactMethod) | repeated | Contact methods for anonymous attendees. Currently not linked to Contact methods for users. |
| auth_token | [string](#string) | optional | Used to allow anonymous users to RSVP to an event. Generated by the server when an event attendance is upserted for the first time. Subsequent attendance upserts, with the same event_instance_id and anonymous_attendee.auth_token, will update existing anonymous attendance records. Invalid auth tokens used during upserts will always create a new `EventAttendance`. |






<a name="jonline-Event"></a>

### Event
An `Event` is a top-level type used to organize calendar events, RSVPs, and messaging/posting
about the `Event`. Actual time data lies in its `EventInstances`.

(Eventually, Jonline Events should also support ticketing.)


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | Unique ID for the event generated by the Jonline BE. |
| post | [Post](#jonline-Post) |  | The Post containing the underlying data for the event (names). Its `PostContext` should be `EVENT`. |
| info | [EventInfo](#jonline-EventInfo) |  | Event configuration like whether to allow (anonymous) RSVPs, etc. |
| instances | [EventInstance](#jonline-EventInstance) | repeated | A list of instances for the Event. *Events will only include all instances if the request is for a single event.* |






<a name="jonline-EventAttendance"></a>

### EventAttendance
Could be called an &#34;RSVP.&#34; Describes the attendance of a user at an `EventInstance`. Such as:
* A user&#39;s RSVP to an `EventInstance` (one of `INTERESTED`, `GOING`, `NOT_GOING`, or , `REQUESTED` (i.e. invited)).
* Invitation status of a user to an `EventInstance`.
* `ContactMethod`-driven management for anonymous RSVPs to an `EventInstance`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | Unique server-generated ID for the attendance. |
| event_instance_id | [string](#string) |  | ID of the `EventInstance` the attendance is for. |
| user_attendee | [UserAttendee](#jonline-UserAttendee) |  | If the attendance is non-anonymous, core data about the user. |
| anonymous_attendee | [AnonymousAttendee](#jonline-AnonymousAttendee) |  | If the attendance is anonymous, core data about the anonymous attendee. |
| number_of_guests | [uint32](#uint32) |  | Number of guests including the RSVPing user. (Minimum 1). |
| status | [AttendanceStatus](#jonline-AttendanceStatus) |  | The user&#39;s RSVP to an `EventInstance` (one of `INTERESTED`, `REQUESTED` (i.e. invited), `GOING`, `NOT_GOING`) |
| inviting_user_id | [string](#string) | optional | User who invited the attendee. (Not yet used.) |
| private_note | [string](#string) |  | Public note for everyone who can see the event to see. |
| public_note | [string](#string) |  | Private note for the event owner. |
| moderation | [Moderation](#jonline-Moderation) |  | Moderation status for the attendance. Moderated by the `Event` owner (or `EventInstance` owner if applicable). |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the attendance was created. |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the attendance was last updated. |






<a name="jonline-EventAttendances"></a>

### EventAttendances
Response to get RSVP data for an event.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| attendances | [EventAttendance](#jonline-EventAttendance) | repeated | The attendance data for the event, in no particular order. |
| hidden_location | [Location](#jonline-Location) | optional | When `hide_location_until_rsvp_approved` is set, the location of the event. |






<a name="jonline-EventInfo"></a>

### EventInfo
To be used for ticketing, RSVPs, etc.
Stored as JSON in the database.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| allows_rsvps | [bool](#bool) | optional | Whether to allow RSVPs for the event. |
| allows_anonymous_rsvps | [bool](#bool) | optional | Whether to allow anonymous RSVPs for the event. |
| max_attendees | [uint32](#uint32) | optional | Limit the max number of attendees. No effect unless `allows_rsvps` is true. Not yet supported. |
| hide_location_until_rsvp_approved | [bool](#bool) | optional | Hide the location until the user RSVPs (and it&#39;s accepted). From a system perspective, when this is set, Events will not include the `Location` until the user has RSVP&#39;d. Location will always be returned in EventAttendances if the request for the EventAttendances came from a (logged in or anonymous) user whose attendance is approved (or the event owner). |
| default_rsvp_moderation | [Moderation](#jonline-Moderation) | optional | Default moderation for RSVPs from logged-in users (either `PENDING` or `APPROVED`). Anonymous RSVPs are always moderated (default to `PENDING`). |






<a name="jonline-EventInstance"></a>

### EventInstance
The time-based component of an `Event`. Has a `starts_at` and `ends_at` time,
a `Location`, and an optional `Post` (and discussion thread) specific to this particular
`EventInstance` in addition to the parent `Event`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | Unique ID for the event instance generated by the Jonline BE. |
| event_id | [string](#string) |  | ID of the parent `Event`. |
| post | [Post](#jonline-Post) |  | Optional `Post` containing alternate name/link/description for this particular instance. Its `PostContext` should be `EVENT_INSTANCE`. |
| info | [EventInstanceInfo](#jonline-EventInstanceInfo) |  | Additional configuration for this instance of this `EventInstance` beyond the `EventInfo` in its parent `Event`. |
| starts_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the event starts (UTC/Timestamp format). |
| ends_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the event ends (UTC/Timestamp format). |
| location | [Location](#jonline-Location) | optional | The location of the event. |






<a name="jonline-EventInstanceInfo"></a>

### EventInstanceInfo
To be used for ticketing, RSVPs, etc.
Stored as JSON in the database.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| rsvp_info | [EventInstanceRsvpInfo](#jonline-EventInstanceRsvpInfo) | optional | RSVP configuration and metadata for the event instance. |






<a name="jonline-EventInstanceRsvpInfo"></a>

### EventInstanceRsvpInfo
Consolidated type for RSVP info for an `EventInstance`.
Curently, the `optional` counts below are *never* returned by the API.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| allows_rsvps | [bool](#bool) | optional | Overrides `EventInfo.allows_rsvps`, if set, for this instance. |
| allows_anonymous_rsvps | [bool](#bool) | optional | Overrides `EventInfo.allows_anonymous_rsvps`, if set, for this instance. |
| max_attendees | [uint32](#uint32) | optional | Overrides `EventInfo.max_attendees`, if set, for this instance. Not yet supported. |
| going_rsvps | [uint32](#uint32) | optional | The number of users who have RSVP&#39;d to the event. |
| going_attendees | [uint32](#uint32) | optional | The number of attendees who have RSVP&#39;d to the event. (RSVPs may have multiple attendees, i.e. guests.) |
| interested_rsvps | [uint32](#uint32) | optional | The number of users who have signaled interest in the event. |
| interested_attendees | [uint32](#uint32) | optional | The number of attendees who have signaled interest in the event. (RSVPs may have multiple attendees, i.e. guests.) |
| invited_rsvps | [uint32](#uint32) | optional | The number of users who have been invited to the event. |
| invited_attendees | [uint32](#uint32) | optional | The number of attendees who have been invited to the event. (RSVPs may have multiple attendees, i.e. guests.) |






<a name="jonline-GetEventAttendancesRequest"></a>

### GetEventAttendancesRequest
Request to get RSVP data for an event.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| event_instance_id | [string](#string) |  | The ID of the event to get RSVP data for. |
| anonymous_attendee_auth_token | [string](#string) | optional | If set, and if the token has an RSVP for this even, request that RSVP data in addition to the rest of the RSVP data. (The event creator can always see and moderate anonymous RSVPs.) |






<a name="jonline-GetEventsRequest"></a>

### GetEventsRequest
Request to get Events in a formatted *per-EventInstance* structure. i.e. the response will carry duplicate `Event`s with the same ID
if that `Event` has multiple `EventInstance`s in the time frame the client asked for.

These structured EventInstances are ordered by start time unless otherwise specified (specifically, `EventListingType.NEWLY_ADDED_EVENTS`).

Valid GetEventsRequest formats:
- `{[listing_type: PublicEvents]}`                 (TODO: get ServerPublic/GlobalPublic events you can see)
- `{listing_type:MyGroupsEvents|FollowingEvents}`  (TODO: get events for groups joined or user followed; auth required)
- `{event_id:}`                                    (TODO: get single event including preview data)
- `{listing_type: GroupEvents| GroupEventsPendingModeration, group_id:}`
                                                   (TODO: get events/events needing moderation for a group)
- `{author_user_id:, group_id:}`                   (TODO: get events by a user for a group)
- `{listing_type: AuthorEvents, author_user_id:}`  (TODO: get events by a user)


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| event_id | [string](#string) | optional | Returns the single event with the given ID. |
| author_user_id | [string](#string) | optional | Limits results to those by the given author user ID. |
| group_id | [string](#string) | optional | Limits results to those in the given group ID (via `GroupPost` association&#39;s for the Event&#39;s internal `Post`). |
| event_instance_id | [string](#string) | optional | Limits results to those with the given event instance ID. |
| time_filter | [TimeFilter](#jonline-TimeFilter) | optional | Filters returned `EventInstance`s by time. |
| attendee_id | [string](#string) | optional | If set, only returns events that the given user is attending. If `attendance_statuses` is also set, returns events where that user&#39;s status is one of the given statuses. |
| attendance_statuses | [AttendanceStatus](#jonline-AttendanceStatus) | repeated | If set, only return events for which the current user&#39;s attendance status matches one of the given statuses. If `attendee_id` is also set, only returns events where the given user&#39;s status matches one of the given statuses. |
| post_id | [string](#string) | optional | Finds Events for the Post with the given ID. The Post should have a `PostContext` of `EVENT` or `EVENT_INSTANCE`. |
| listing_type | [EventListingType](#jonline-EventListingType) |  | The listing type, e.g. `ALL_ACCESSIBLE_EVENTS`, `FOLLOWING_EVENTS`, `MY_GROUPS_EVENTS`, `DIRECT_EVENTS`, `GROUP_EVENTS`, `GROUP_EVENTS_PENDING_MODERATION`. |






<a name="jonline-GetEventsResponse"></a>

### GetEventsResponse
A list of `Event`s with a maybe-incomplete (see [`GetEventsRequest`](#geteventsrequest)) set of their `EventInstance`s.

Note that `GetEventsResponse` may often include duplicate Events with the same ID.
I.E. something like: `{events: [{id: a, instances: [{id: x}]}, {id: a, instances: [{id: y}]}, ]}` is a valid response.
This semantically means: &#34;Event A has both instances X and Y in the time frame the client asked for.&#34;
The client should be able to handle this.

In the React/Tamagui client, this is handled by the Redux store, which
effectively &#34;compacts&#34; all response into its own internal Events store, in a form something like:
`{events: {a: {id: a, instances: [{id: x}, {id: y}]}, ...}, instanceEventIds: {x:a, y:a}}`.
(In reality it uses `EntityAdapter` which is a bit more complicated, but the idea is the same.)


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| events | [Event](#jonline-Event) | repeated |  |






<a name="jonline-TimeFilter"></a>

### TimeFilter
Time filter that works on the `starts_at` and `ends_at` fields of `EventInstance`.
API currently only supports `ends_after`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| starts_after | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Filter to events that start after the given time. |
| ends_after | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Filter to events that end after the given time. |
| starts_before | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Filter to events that start before the given time. |
| ends_before | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Filter to events that end before the given time. |






<a name="jonline-UserAttendee"></a>

### UserAttendee
Wire-identical to [Author](#author), but with a different name to avoid confusion.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user_id | [string](#string) |  | The user ID of the attendee. |
| username | [string](#string) | optional | The username of the attendee. |
| avatar | [MediaReference](#jonline-MediaReference) | optional | The attendee&#39;s user avatar. |
| real_name | [string](#string) | optional |  |
| permissions | [Permission](#jonline-Permission) | repeated |  |





 


<a name="jonline-AttendanceStatus"></a>

### AttendanceStatus
EventInstance attendance statuses. State transitions may generally happen
in any direction, but:
* `REQUESTED` can only be selected if another user invited the user whose attendance is being described.
* `GOING` and `NOT_GOING` cannot be selected if the EventInstance has ended (end time is in the past).
* `WENT` and `DID_NOT_GO` cannot be selected if the EventInstance has not started (start time is in the future).
`INTERESTED` and `REQUESTED` can apply regardless of whether an event has started or ended.

| Name | Number | Description |
| ---- | ------ | ----------- |
| INTERESTED | 0 | The user is (or was) interested in attending. This is the default status. |
| REQUESTED | 1 | Another user has invited the user to the event. |
| GOING | 2 | The user plans to go to the event, or went to the event. |
| NOT_GOING | 3 | The user does not plan to go to the event, or did not go to the event. |



<a name="jonline-EventListingType"></a>

### EventListingType
The listing type, e.g. `ALL_ACCESSIBLE_EVENTS`, `FOLLOWING_EVENTS`, `MY_GROUPS_EVENTS`, `DIRECT_EVENTS`, `GROUP_EVENTS`, `GROUP_EVENTS_PENDING_MODERATION`.

Events returned are ordered by start time unless otherwise specified (specifically, `NEWLY_ADDED_EVENTS`).

| Name | Number | Description |
| ---- | ------ | ----------- |
| ALL_ACCESSIBLE_EVENTS | 0 | Gets `SERVER_PUBLIC` and `GLOBAL_PUBLIC` events depending on whether the user is logged in, `LIMITED` events from authors the user is following, and `PRIVATE` events owned by, or directly addressed to, the current user. |
| FOLLOWING_EVENTS | 1 | Returns events from users the user is following. |
| MY_GROUPS_EVENTS | 2 | Returns events from any group the user is a member of. |
| DIRECT_EVENTS | 3 | Returns `DIRECT` events that are directly addressed to the user. |
| EVENTS_PENDING_MODERATION | 4 | Returns events pending moderation by the server-level mods/admins. |
| GROUP_EVENTS | 10 | Returns events from a specific group. Requires group_id parameterRequires group_id parameter |
| GROUP_EVENTS_PENDING_MODERATION | 11 | Returns pending_moderation events from a specific group. Requires group_id parameter and user must have group (or server) admin permissions. |
| NEWLY_ADDED_EVENTS | 20 | Returns events from either `ALL_ACCESSIBLE_EVENTS` or a specific author (with optional author_user_id parameter). Returned EventInstances will be ordered by creation time rather than start time. |


 

 

 



<a name="server_configuration-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## server_configuration.proto



<a name="jonline-ExternalCDNConfig"></a>

### ExternalCDNConfig
Useful for setting your Jonline instance up to run underneath a CDN.
By default, the web client uses `window.location.hostname` to determine the backend server.
If set, the web client will use this value instead. NOTE: Only applies to Tamagui web client for now.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| frontend_host | [string](#string) |  | The domain where the frontend is hosted. For example, jonline.io. Typically your CDN (like Cloudflare) should own the DNS for this domain. |
| backend_host | [string](#string) |  | The domain where the backend is hosted. For example, jonline.io.itsj.online. Typically your Kubernetes provider should own DNS for this domain. |
| secure_media | [bool](#bool) |  | (TODO) When set, the HTTP `GET /media/&lt;id&gt;?&lt;authorization&gt;` endpoint will be disabled by default on the HTTP (non-secure) server that sends data to the CDN. Only requests from IPs in `media_ipv4_allowlist` and `media_ipv6_allowlist` will be allowed. |
| media_ipv4_allowlist | [string](#string) | optional | Whitespace- and/or comma- separated list of IPv4 addresses/ranges to whom media data may be served. Only applicable if `secure_media` is `true`. For reference, Cloudflare&#39;s are at https://www.cloudflare.com/ips-v4. |
| media_ipv6_allowlist | [string](#string) | optional | Whitespace- and/or comma- separated list of IPv6 addresses/ranges to whom media data may be served. Only applicable if `secure_media` is `true`. For reference, Cloudflare&#39;s are at https://www.cloudflare.com/ips-v6. |
| cdn_grpc | [bool](#bool) |  | (TODO) When implemented, this actually changes the whole Jonline protocol (in terms of ports). When enabled, Jonline should *not* server a secure site on HTTPS, and instead serve the Tonic gRPC server there (on port 443). Jonine clients will need to be updated to always seek out a secure client on port 443 when this feature is enabled. This would let Jonline leverage Cloudflare&#39;s DDOS protection and performance on gRPC as well as HTTP. (This is a Cloudflare-specific feature requirement.) |






<a name="jonline-FeatureSettings"></a>

### FeatureSettings
Settings for a feature (e.g. People, Groups, Posts, Events, Media).
Encompasses both the feature&#39;s visibility and moderation settings.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| visible | [bool](#bool) |  | Hide the Posts or Events tab from the user with this flag. |
| default_moderation | [Moderation](#jonline-Moderation) |  | Only `UNMODERATED` and `PENDING` are valid. When `UNMODERATED`, user reports may transition status to `PENDING`. When `PENDING`, users&#39; SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not be visible until a moderator approves them. `LIMITED` visiblity posts are always visible to targeted users (who have not blocked the author) regardless of default_moderation. |
| default_visibility | [Visibility](#jonline-Visibility) |  | Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]` as appropriate. |
| custom_title | [string](#string) | optional | (TODO) Custom title, like &#34;Section&#34;s instead of &#34;Group&#34;s. This is more an idea; internationalization is obviously problematic here. |






<a name="jonline-PostSettings"></a>

### PostSettings
Specific settings for Posts and Events.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| visible | [bool](#bool) |  | Hide the Posts or Events tab from the user with this flag. |
| default_moderation | [Moderation](#jonline-Moderation) |  | Only `UNMODERATED` and `PENDING` are valid. When `UNMODERATED`, user reports may transition status to `PENDING`. When `PENDING`, users&#39; SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not be visible until a moderator approves them. `LIMITED` visiblity posts are always visible to targeted users (who have not blocked the author) regardless of default_moderation. |
| default_visibility | [Visibility](#jonline-Visibility) |  | Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]` as appropriate. |
| custom_title | [string](#string) | optional | (TODO) Custom title, like &#34;Section&#34;s instead of &#34;Group&#34;s. This is more an idea; internationalization is obviously problematic here. |
| enable_replies | [bool](#bool) | optional | Controls whether replies are shown in the UI. Note that users&#39; ability to reply is controlled by the `REPLY_TO_POSTS` permission. |






<a name="jonline-ServerColors"></a>

### ServerColors
Color in ARGB hex format (i.e `0xAARRGGBB`).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| primary | [uint32](#uint32) | optional | App Bar/primary accent color. |
| navigation | [uint32](#uint32) | optional | Nav/secondary accent color. |
| author | [uint32](#uint32) | optional | Color used on author of a post in discussion threads for it. |
| admin | [uint32](#uint32) | optional | Color used on author for admin posts. |
| moderator | [uint32](#uint32) | optional | Color used on author for moderator posts. |






<a name="jonline-ServerConfiguration"></a>

### ServerConfiguration
Configuration for a Jonline server instance.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| server_info | [ServerInfo](#jonline-ServerInfo) | optional | The name, description, logo, color scheme, etc. of the server. |
| federation_info | [FederationInfo](#jonline-FederationInfo) | optional | The federation configuration for the server. |
| anonymous_user_permissions | [Permission](#jonline-Permission) | repeated | Permissions for a user who isn&#39;t logged in to the server. Allows admins to disable certain features for anonymous users. Valid values are `VIEW_USERS`, `VIEW_GROUPS`, `VIEW_POSTS`, and `VIEW_EVENTS`. |
| default_user_permissions | [Permission](#jonline-Permission) | repeated | Default user permissions given to a new user. Users with `MODERATE_USERS` permission can also grant/revoke these permissions for others. Valid values are `VIEW_USERS`, `PUBLISH_USERS_LOCALLY`, `PUBLISH_USERS_GLOBALLY`, `VIEW_GROUPS`, `CREATE_GROUPS`, `PUBLISH_GROUPS_LOCALLY`, `PUBLISH_GROUPS_GLOBALLY`, `JOIN_GROUPS`, `VIEW_POSTS`, `CREATE_POSTS`, `PUBLISH_POSTS_LOCALLY`, `PUBLISH_POSTS_GLOBALLY`, `VIEW_EVENTS`, `CREATE_EVENTS`, `PUBLISH_EVENTS_LOCALLY`, and `PUBLISH_EVENTS_GLOBALLY`. |
| basic_user_permissions | [Permission](#jonline-Permission) | repeated | Permissions grantable by a user with the `GRANT_BASIC_PERMISSIONS` permission. Valid values are `VIEW_USERS`, `PUBLISH_USERS_LOCALLY`, `PUBLISH_USERS_GLOBALLY`, `VIEW_GROUPS`, `CREATE_GROUPS`, `PUBLISH_GROUPS_LOCALLY`, `PUBLISH_GROUPS_GLOBALLY`, `JOIN_GROUPS`, `VIEW_POSTS`, `CREATE_POSTS`, `PUBLISH_POSTS_LOCALLY`, `PUBLISH_POSTS_GLOBALLY`, `VIEW_EVENTS`, `CREATE_EVENTS`, `PUBLISH_EVENTS_LOCALLY`, and `PUBLISH_EVENTS_GLOBALLY`. |
| people_settings | [FeatureSettings](#jonline-FeatureSettings) |  | Configuration for users on the server. If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_USERS_GLOBALLY`. |
| group_settings | [FeatureSettings](#jonline-FeatureSettings) |  | Configuration for groups on the server. If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_GROUPS_GLOBALLY`. |
| post_settings | [PostSettings](#jonline-PostSettings) |  | Configuration for posts on the server. If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_POSTS_GLOBALLY`. |
| event_settings | [PostSettings](#jonline-PostSettings) |  | Configuration for events on the server. If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_EVENTS_GLOBALLY`. |
| media_settings | [FeatureSettings](#jonline-FeatureSettings) |  | Configuration for media on the server. If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_MEDIA_GLOBALLY`. |
| external_cdn_config | [ExternalCDNConfig](#jonline-ExternalCDNConfig) | optional | If set, enables External CDN support for the server. This means that the non-secure HTTP server (on port 80) will *not* redirect to the secure server, and instead serve up Tamagui Web/Flutter clients directly. This allows you to point Cloudflare&#39;s &#34;CNAME HTTPS Proxy&#34; feature at your Jonline server to serve up HTML/CS/JS and Media files with caching from Cloudflare&#39;s CDN. See ExternalCDNConfig for more details on securing this setup. |
| private_user_strategy | [PrivateUserStrategy](#jonline-PrivateUserStrategy) |  | Strategy when a user sets their visibility to `PRIVATE`. Defaults to `ACCOUNT_IS_FROZEN`. |
| authentication_features | [AuthenticationFeature](#jonline-AuthenticationFeature) | repeated | (TODO) Allows admins to enable/disable creating accounts and logging in. Eventually, external auth too hopefully! |
| web_push_config | [WebPushConfig](#jonline-WebPushConfig) | optional | Web Push (VAPID) configuration for the server. |






<a name="jonline-ServerInfo"></a>

### ServerInfo
User-facing information about the server displayed on the &#34;about&#34; page.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| name | [string](#string) | optional | Name of the server. |
| short_name | [string](#string) | optional | Short name of the server. Used in URLs, etc. (Currently unused.) |
| description | [string](#string) | optional | Description of the server. |
| privacy_policy | [string](#string) | optional | The server&#39;s privacy policy. Will be displayed during account creation and on the `/about` page. |
| logo | [ServerLogo](#jonline-ServerLogo) | optional | Multi-size logo data for the server. |
| web_user_interface | [WebUserInterface](#jonline-WebUserInterface) | optional | The web UI to use (React/Tamagui (default) vs. Flutter Web) |
| colors | [ServerColors](#jonline-ServerColors) | optional | The color scheme for the server. |
| media_policy | [string](#string) | optional | The media policy for the server. Will be displayed during account creation and on the `/about` page. |
| recommended_server_hosts | [string](#string) | repeated | **Deprecated.** This will be replaced with FederationInfo soon. |






<a name="jonline-ServerLogo"></a>

### ServerLogo
Logo data for the server. Built atop Jonline [`Media` APIs](#jonline-Media).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| squareMediaId | [string](#string) | optional | The media ID for the square logo. |
| squareMediaIdDark | [string](#string) | optional | The media ID for the square logo in dark mode. |
| wideMediaId | [string](#string) | optional | The media ID for the wide logo. |
| wideMediaIdDark | [string](#string) | optional | The media ID for the wide logo in dark mode. |






<a name="jonline-WebPushConfig"></a>

### WebPushConfig
Web Push (VAPID) configuration for the server.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| public_vapid_key | [string](#string) |  | Public VAPID key for the server. |
| private_vapid_key | [string](#string) |  | Private VAPID key for the server. *Never serialized to the client.* Admins: Edit this in the database&#39;s JSONB column directly. |





 


<a name="jonline-AuthenticationFeature"></a>

### AuthenticationFeature
Authentication features that can be enabled/disabled by the server admin.

| Name | Number | Description |
| ---- | ------ | ----------- |
| AUTHENTICATION_FEATURE_UNKNOWN | 0 | An authentication feature that is not known to the server. (Likely, the client and server use different versions of the Jonline protocol.) |
| CREATE_ACCOUNT | 1 | Users can sign up for an account. |
| LOGIN | 2 | Users can sign in with an existing account. |



<a name="jonline-PrivateUserStrategy"></a>

### PrivateUserStrategy
Strategy when a user sets their visibility to `PRIVATE`.

| Name | Number | Description |
| ---- | ------ | ----------- |
| ACCOUNT_IS_FROZEN | 0 | `PRIVATE` Users can&#39;t see other Users (only `PUBLIC_GLOBAL` Visilibity Users/Posts/Events). Other users can&#39;t see them. |
| LIMITED_CREEPINESS | 1 | Users can see other users they follow, but only `PUBLIC_GLOBAL` Visilibity Posts/Events. Other users can&#39;t see them. |
| LET_ME_CREEP_ON_PPL | 2 | Users can see other users they follow, including their `PUBLIC_SERVER` Posts/Events. Other users can&#39;t see them. |



<a name="jonline-WebUserInterface"></a>

### WebUserInterface
Offers a choice of web UIs. Generally though, React/Tamagui is
a century ahead of Flutter Web, so it&#39;s the default.

| Name | Number | Description |
| ---- | ------ | ----------- |
| FLUTTER_WEB | 0 | Uses Flutter Web. Loaded from /app. |
| HANDLEBARS_TEMPLATES | 1 | Uses Handlebars templates. Deprecated; will revert to Tamagui UI if chosen. |
| REACT_TAMAGUI | 2 | React UI using Tamagui (a React Native UI library). |


 

 

 



<a name="federation-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## federation.proto



<a name="jonline-FederatedAccount"></a>

### FederatedAccount
Some user on a Jonline server.
Most commonly a different server than the one serving up FederatedAccount data,
but users may also federate multiple accounts on the same server.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| host | [string](#string) |  | The DNS hostname of the server that this user is on. |
| user_id | [string](#string) |  | The user ID of the user on the server. |






<a name="jonline-FederatedServer"></a>

### FederatedServer
A server that this server will federate with.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| host | [string](#string) |  | The DNS hostname of the server to federate with. |
| configured_by_default | [bool](#bool) | optional | Indicates to UI clients that they should enable/configure the indicated server by default. |
| pinned_by_default | [bool](#bool) | optional | Indicates to UI clients that they should pin the indicated server by default (showing its Events and Posts alongside the &#34;main&#34; server). |






<a name="jonline-FederationInfo"></a>

### FederationInfo
The federation configuration for a Jonline server.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| servers | [FederatedServer](#jonline-FederatedServer) | repeated | A list of servers that this server will federate with. |






<a name="jonline-GetServiceVersionResponse"></a>

### GetServiceVersionResponse
Version information for the Jonline server.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| version | [string](#string) |  | The version of the Jonline server. May be suffixed with the GitHub SHA of the commit that generated the binary for the server. |





 

 

 

 



## Scalar Value Types

| .proto Type | Notes | C++ | Java | Python | Go | C# | PHP | Ruby |
| ----------- | ----- | --- | ---- | ------ | -- | -- | --- | ---- |
| <a name="double" /> double |  | double | double | float | float64 | double | float | Float |
| <a name="float" /> float |  | float | float | float | float32 | float | float | Float |
| <a name="int32" /> int32 | Uses variable-length encoding. Inefficient for encoding negative numbers – if your field is likely to have negative values, use sint32 instead. | int32 | int | int | int32 | int | integer | Bignum or Fixnum (as required) |
| <a name="int64" /> int64 | Uses variable-length encoding. Inefficient for encoding negative numbers – if your field is likely to have negative values, use sint64 instead. | int64 | long | int/long | int64 | long | integer/string | Bignum |
| <a name="uint32" /> uint32 | Uses variable-length encoding. | uint32 | int | int/long | uint32 | uint | integer | Bignum or Fixnum (as required) |
| <a name="uint64" /> uint64 | Uses variable-length encoding. | uint64 | long | int/long | uint64 | ulong | integer/string | Bignum or Fixnum (as required) |
| <a name="sint32" /> sint32 | Uses variable-length encoding. Signed int value. These more efficiently encode negative numbers than regular int32s. | int32 | int | int | int32 | int | integer | Bignum or Fixnum (as required) |
| <a name="sint64" /> sint64 | Uses variable-length encoding. Signed int value. These more efficiently encode negative numbers than regular int64s. | int64 | long | int/long | int64 | long | integer/string | Bignum |
| <a name="fixed32" /> fixed32 | Always four bytes. More efficient than uint32 if values are often greater than 2^28. | uint32 | int | int | uint32 | uint | integer | Bignum or Fixnum (as required) |
| <a name="fixed64" /> fixed64 | Always eight bytes. More efficient than uint64 if values are often greater than 2^56. | uint64 | long | int/long | uint64 | ulong | integer/string | Bignum |
| <a name="sfixed32" /> sfixed32 | Always four bytes. | int32 | int | int | int32 | int | integer | Bignum or Fixnum (as required) |
| <a name="sfixed64" /> sfixed64 | Always eight bytes. | int64 | long | int/long | int64 | long | integer/string | Bignum |
| <a name="bool" /> bool |  | bool | boolean | boolean | bool | bool | boolean | TrueClass/FalseClass |
| <a name="string" /> string | A string must always contain UTF-8 encoded or 7-bit ASCII text. | string | String | str/unicode | string | string | string | String (UTF-8) |
| <a name="bytes" /> bytes | May contain any arbitrary sequence of bytes. | string | ByteString | str | []byte | ByteString | string | String (ASCII-8BIT) |

