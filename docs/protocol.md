# Protocol Documentation
<a name="top"></a>

## Table of Contents

- [jonline.proto](#jonline-proto)
    - [Jonline](#jonline-Jonline)
  
- [authentication.proto](#authentication-proto)
    - [AccessTokenRequest](#jonline-AccessTokenRequest)
    - [AccessTokenResponse](#jonline-AccessTokenResponse)
    - [CreateAccountRequest](#jonline-CreateAccountRequest)
    - [ExpirableToken](#jonline-ExpirableToken)
    - [LoginRequest](#jonline-LoginRequest)
    - [RefreshTokenResponse](#jonline-RefreshTokenResponse)
  
- [visibility_moderation.proto](#visibility_moderation-proto)
    - [Moderation](#jonline-Moderation)
    - [Visibility](#jonline-Visibility)
  
- [permissions.proto](#permissions-proto)
    - [Permission](#jonline-Permission)
  
- [users.proto](#users-proto)
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
  
- [groups.proto](#groups-proto)
    - [GetGroupsRequest](#jonline-GetGroupsRequest)
    - [GetGroupsResponse](#jonline-GetGroupsResponse)
    - [GetMembersRequest](#jonline-GetMembersRequest)
    - [GetMembersResponse](#jonline-GetMembersResponse)
    - [Group](#jonline-Group)
    - [Member](#jonline-Member)
  
    - [GroupListingType](#jonline-GroupListingType)
  
- [posts.proto](#posts-proto)
    - [Author](#jonline-Author)
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
    - [Event](#jonline-Event)
    - [EventAttendance](#jonline-EventAttendance)
    - [EventInfo](#jonline-EventInfo)
    - [EventInstance](#jonline-EventInstance)
    - [EventInstanceInfo](#jonline-EventInstanceInfo)
    - [GetEventsRequest](#jonline-GetEventsRequest)
    - [GetEventsResponse](#jonline-GetEventsResponse)
    - [TimeFilter](#jonline-TimeFilter)
  
    - [AttendanceStatus](#jonline-AttendanceStatus)
    - [EventListingType](#jonline-EventListingType)
  
- [server_configuration.proto](#server_configuration-proto)
    - [ExternalCDNConfig](#jonline-ExternalCDNConfig)
    - [FeatureSettings](#jonline-FeatureSettings)
    - [PostSettings](#jonline-PostSettings)
    - [ServerColors](#jonline-ServerColors)
    - [ServerConfiguration](#jonline-ServerConfiguration)
    - [ServerInfo](#jonline-ServerInfo)
  
    - [AuthenticationFeature](#jonline-AuthenticationFeature)
    - [PrivateUserStrategy](#jonline-PrivateUserStrategy)
    - [WebUserInterface](#jonline-WebUserInterface)
  
- [Scalar Value Types](#scalar-value-types)



<a name="jonline-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## jonline.proto


 

 

 


<a name="jonline-Jonline"></a>

### Jonline
The internet-facing Jonline service implementing the Jonline protocol,
generally exposed on port 27707 (see &#34;HTTP-based client host negotiation&#34; below for clarifications).

Authenticated calls require an `access_token` in request metadata to be included
directly as the value of the `authorization` header (with no `Bearer ` prefix).
First, use the `CreateAccount` or `Login` RPCs to fetch (and store) an initial
`refresh_token` and `access_token`. Use the `access_token` until it expires,
then use the `refresh_token` to call the `AccessToken` RPC for a new one.

##### HTTP-based client host negotiation (for external CDNs)
When negotiating the gRPC connection to a host, say, `jonline.io`, before attempting
to connect to `jonline.io` via gRPC on 27707, the client
is expected to first attempt to fetch `jonline.io/backend_host` over HTTP (port 80) or HTTPS (port 443)
(depending upon whether the gRPC server is expected to have TLS). This is to allow
support for external CDNs as frontends. See https://jonline.io/about for more
information about external CDN setup.

Both Jonline&#39;s [React/Tamagui](https://github.com/JonLatane/jonline/blob/main/frontends/tamagui/packages/app/store/clients.ts) 
and [Flutter](https://github.com/JonLatane/jonline/blob/main/frontends/flutter/lib/models/jonline_clients.dart) 
clients already do this.

| Method Name | Request Type | Response Type | Description |
| ----------- | ------------ | ------------- | ------------|
| GetServiceVersion | [.google.protobuf.Empty](#google-protobuf-Empty) | [GetServiceVersionResponse](#jonline-GetServiceVersionResponse) | Get the version (from Cargo) of the Jonline service. *Publicly accessible.* |
| GetServerConfiguration | [.google.protobuf.Empty](#google-protobuf-Empty) | [ServerConfiguration](#jonline-ServerConfiguration) | Gets the Jonline server&#39;s configuration. *Publicly accessible.* |
| CreateAccount | [CreateAccountRequest](#jonline-CreateAccountRequest) | [RefreshTokenResponse](#jonline-RefreshTokenResponse) | Creates a user account and provides a `refresh_token` (along with an `access_token`). *Publicly accessible.* |
| Login | [LoginRequest](#jonline-LoginRequest) | [RefreshTokenResponse](#jonline-RefreshTokenResponse) | Logs in a user and provides a `refresh_token` (along with an `access_token`). *Publicly accessible.* |
| AccessToken | [AccessTokenRequest](#jonline-AccessTokenRequest) | [AccessTokenResponse](#jonline-AccessTokenResponse) | Gets a new `access_token` (and possibly a new `refresh_token`, which should replace the old one in client storage), given a `refresh_token`. *Publicly accessible.* |
| GetCurrentUser | [.google.protobuf.Empty](#google-protobuf-Empty) | [User](#jonline-User) | Gets the current user. *Authenticated.* |
| GetUsers | [GetUsersRequest](#jonline-GetUsersRequest) | [GetUsersResponse](#jonline-GetUsersResponse) | Gets Users. *Publicly accessible **or** Authenticated.* Unauthenticated calls only return Users of `GLOBAL_PUBLIC` visibility. |
| UpdateUser | [User](#jonline-User) | [User](#jonline-User) | Update a user by ID. *Authenticated.* Updating other users requires `ADMIN` permissions. |
| DeleteUser | [User](#jonline-User) | [.google.protobuf.Empty](#google-protobuf-Empty) | Deletes a user by ID. *Authenticated.* Deleting other users requires `ADMIN` permissions. |
| CreateFollow | [Follow](#jonline-Follow) | [Follow](#jonline-Follow) | Follow (or request to follow) a user. *Authenticated.* |
| UpdateFollow | [Follow](#jonline-Follow) | [Follow](#jonline-Follow) | Used to approve follow requests. *Authenticated.* |
| DeleteFollow | [Follow](#jonline-Follow) | [.google.protobuf.Empty](#google-protobuf-Empty) | Unfollow (or unrequest) a user. *Authenticated.* |
| GetMedia | [GetMediaRequest](#jonline-GetMediaRequest) | [GetMediaResponse](#jonline-GetMediaResponse) | Gets Media (Images, Videos, etc) uploaded/owned by the current user. *Authenticated.* |
| DeleteMedia | [Media](#jonline-Media) | [.google.protobuf.Empty](#google-protobuf-Empty) | Deletes a media item by ID. *Authenticated.* Note that media may still be accessible for 12 hours after deletes are requested, as separate jobs clean it up from S3/MinIO. Deleting other users&#39; media requires `ADMIN` permissions. |
| GetGroups | [GetGroupsRequest](#jonline-GetGroupsRequest) | [GetGroupsResponse](#jonline-GetGroupsResponse) | Gets Groups. *Publicly accessible **or** Authenticated.* Unauthenticated calls only return Groups of `GLOBAL_PUBLIC` visibility. |
| CreateGroup | [Group](#jonline-Group) | [Group](#jonline-Group) | Creates a group with the current user as its admin. *Authenticated.* Requires the `CREATE_GROUPS` permission. |
| UpdateGroup | [Group](#jonline-Group) | [Group](#jonline-Group) | Update a Groups&#39;s information, default membership permissions or moderation. *Authenticated.* Requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user. |
| DeleteGroup | [Group](#jonline-Group) | [.google.protobuf.Empty](#google-protobuf-Empty) | Delete a Group. *Authenticated.* Requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user. |
| CreateMembership | [Membership](#jonline-Membership) | [Membership](#jonline-Membership) | Requests to join a group (or joins it), or sends an invite to the user. *Authenticated.* Memberships and moderations are set to their defaults. |
| UpdateMembership | [Membership](#jonline-Membership) | [Membership](#jonline-Membership) | Update aspects of a user&#39;s membership. *Authenticated.* Updating permissions requires `ADMIN` permissions within the group, or `ADMIN` permissions for the user. Updating moderation (approving/denying/banning) requires the same, or `MODERATE_USERS` permissions within the group. |
| DeleteMembership | [Membership](#jonline-Membership) | [.google.protobuf.Empty](#google-protobuf-Empty) | Leave a group (or cancel membership request). *Authenticated.* |
| GetMembers | [GetMembersRequest](#jonline-GetMembersRequest) | [GetMembersResponse](#jonline-GetMembersResponse) | Get Members (User&#43;Membership) of a Group. *Authenticated.* |
| GetPosts | [GetPostsRequest](#jonline-GetPostsRequest) | [GetPostsResponse](#jonline-GetPostsResponse) | Gets Posts. *Publicly accessible **or** Authenticated.* Unauthenticated calls only return Posts of `GLOBAL_PUBLIC` visibility. |
| CreatePost | [Post](#jonline-Post) | [Post](#jonline-Post) | Creates a Post. *Authenticated.* |
| UpdatePost | [Post](#jonline-Post) | [Post](#jonline-Post) | Updates a Post. *Authenticated.* |
| DeletePost | [Post](#jonline-Post) | [Post](#jonline-Post) | (TODO) (Soft) deletes a Post. Returns the deleted version of the Post. *Authenticated.* |
| CreateGroupPost | [GroupPost](#jonline-GroupPost) | [GroupPost](#jonline-GroupPost) | Cross-post a Post to a Group. *Authenticated.* |
| UpdateGroupPost | [GroupPost](#jonline-GroupPost) | [GroupPost](#jonline-GroupPost) | Group Moderators: Approve/Reject a GroupPost. *Authenticated.* |
| DeleteGroupPost | [GroupPost](#jonline-GroupPost) | [.google.protobuf.Empty](#google-protobuf-Empty) | Delete a GroupPost. *Authenticated.* |
| GetGroupPosts | [GetGroupPostsRequest](#jonline-GetGroupPostsRequest) | [GetGroupPostsResponse](#jonline-GetGroupPostsResponse) | Get GroupPosts for a Post (and optional group). *Publicly accessible **or** Authenticated.* |
| StreamReplies | [Post](#jonline-Post) | [Post](#jonline-Post) stream | (TODO) Reply streaming interface |
| CreateEvent | [Event](#jonline-Event) | [Event](#jonline-Event) | Creates an Event. *Authenticated.* |
| GetEvents | [GetEventsRequest](#jonline-GetEventsRequest) | [GetEventsResponse](#jonline-GetEventsResponse) | Gets Events. *Publicly accessible **or** Authenticated.* Unauthenticated calls only return Events of `GLOBAL_PUBLIC` visibility. |
| ConfigureServer | [ServerConfiguration](#jonline-ServerConfiguration) | [ServerConfiguration](#jonline-ServerConfiguration) | Configure the server (i.e. the response to GetServerConfiguration). *Authenticated.* Requires `ADMIN` permissions. |
| ResetData | [.google.protobuf.Empty](#google-protobuf-Empty) | [.google.protobuf.Empty](#google-protobuf-Empty) | Delete ALL Media, Posts, Groups and Users except the user who performed the RPC. *Authenticated.* Requires `ADMIN` permissions. Note: Server Configuration is not deleted. |

 



<a name="authentication-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## authentication.proto



<a name="jonline-AccessTokenRequest"></a>

### AccessTokenRequest
Request for a new access token using a refresh token.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| refresh_token | [string](#string) |  |  |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Optional *requested* expiration time for the token. Server may ignore this. |






<a name="jonline-AccessTokenResponse"></a>

### AccessTokenResponse
Returned when requesting access tokens.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| refresh_token | [ExpirableToken](#jonline-ExpirableToken) | optional | If a refresh token is returned, it should be stored. Old refresh tokens may expire *before* their indicated expiration. See: https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation |
| access_token | [ExpirableToken](#jonline-ExpirableToken) |  |  |






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
| device_name | [string](#string) | optional |  |






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
| device_name | [string](#string) | optional | (Not yet implemented.) |
| user_id | [string](#string) | optional | (TODO) If provided, username is ignored and login is initiated via user_id instead. |






<a name="jonline-RefreshTokenResponse"></a>

### RefreshTokenResponse
Returned when creating an account or logging in.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| refresh_token | [ExpirableToken](#jonline-ExpirableToken) |  | The persisted token the device should store and associate with the account. Used to request new access tokens. |
| access_token | [ExpirableToken](#jonline-ExpirableToken) |  | An initial access token provided for convenience. |
| user | [User](#jonline-User) |  | The user associated with the account that was created/logged into. |





 

 

 

 



<a name="visibility_moderation-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## visibility_moderation.proto


 


<a name="jonline-Moderation"></a>

### Moderation


| Name | Number | Description |
| ---- | ------ | ----------- |
| MODERATION_UNKNOWN | 0 |  |
| UNMODERATED | 1 | Subject has not been moderated and is visible to all users. |
| PENDING | 2 | Subject is awaiting moderation and not visible to any users. |
| APPROVED | 3 | Subject has been approved by moderators and is visible to all users. |
| REJECTED | 4 | Subject has been rejected by moderators and is not visible to any users. |



<a name="jonline-Visibility"></a>

### Visibility


| Name | Number | Description |
| ---- | ------ | ----------- |
| VISIBILITY_UNKNOWN | 0 |  |
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


| Name | Number | Description |
| ---- | ------ | ----------- |
| PERMISSION_UNKNOWN | 0 |  |
| VIEW_USERS | 1 |  |
| PUBLISH_USERS_LOCALLY | 2 | Allow the user to publish profiles with `SERVER_PUBLIC` Visbility. This generally only applies to the user&#39;s own profile, except for Admins. |
| PUBLISH_USERS_GLOBALLY | 3 | Allow the user to publish profiles with `GLOBAL_PUBLIC` Visbility. This generally only applies to the user&#39;s own profile, except for Admins. |
| MODERATE_USERS | 4 | Allow the user to grant `VIEW_POSTS`, `CREATE_POSTS`, `VIEW_EVENTS` and `CREATE_EVENTS` permissions to users. |
| FOLLOW_USERS | 5 | Allow the user to follow other users. |
| GRANT_BASIC_PERMISSIONS | 6 | Allow the user to grant Basic Permissions to other users. &#34;Basic Permissions&#34; are defined by your `ServerConfiguration`&#39;s `basic_user_permissions`. |
| VIEW_GROUPS | 10 | Allow the user to view groups with `SERVER_PUBLIC` visibility. |
| CREATE_GROUPS | 11 | Allow the user to create groups. |
| PUBLISH_GROUPS_LOCALLY | 12 | Allow the user to give groups `SERVER_PUBLIC` visibility. |
| PUBLISH_GROUPS_GLOBALLY | 13 | Allow the user to give groups `GLOBAL_PUBLIC` visibility. |
| MODERATE_GROUPS | 14 | The Moderate Groups permission makes a user effectively an admin of *any* group. |
| JOIN_GROUPS | 15 | Allow the user to (potentially request to) join groups of `SERVER_PUBLIC` or higher visibility. |
| VIEW_POSTS | 20 | In the context of user permissions, allow the user to view posts with `SERVER_PUBLIC` or higher visibility. In the context of group permissions, allow the user to view `GroupPost`s whose `Post`s have `LIMITED` or higher visibility. |
| CREATE_POSTS | 21 | In the context of user permissions, allow the user to view posts with `SERVER_PUBLIC` or higher visibility. In the context of group permissions, allow the user to create `GroupPost`s whose `Post`s have `LIMITED` or higher visibility. |
| PUBLISH_POSTS_LOCALLY | 22 |  |
| PUBLISH_POSTS_GLOBALLY | 23 |  |
| MODERATE_POSTS | 24 |  |
| REPLY_TO_POSTS | 25 |  |
| VIEW_EVENTS | 30 |  |
| CREATE_EVENTS | 31 |  |
| PUBLISH_EVENTS_LOCALLY | 32 |  |
| PUBLISH_EVENTS_GLOBALLY | 33 |  |
| MODERATE_EVENTS | 34 | Allow the user to moderate events. |
| VIEW_MEDIA | 40 |  |
| CREATE_MEDIA | 41 |  |
| PUBLISH_MEDIA_LOCALLY | 42 |  |
| PUBLISH_MEDIA_GLOBALLY | 43 |  |
| MODERATE_MEDIA | 44 | Allow the user to moderate events. |
| RUN_BOTS | 9999 | Allow the user to run bots. There is no enforcement of this permission (yet), but it lets other users know that the user is allowed to run bots. |
| ADMIN | 10000 | Marks the user as an admin. In the context of user permissions, allows the user to configure the server, moderate/update visibility/permissions to any `User`, `Group`, `Post` or `Event`. In the context of group permissions, allows the user to configure the group, modify members and member permissions, and moderate `GroupPost`s and `GroupEvent`s. |
| VIEW_PRIVATE_CONTACT_METHODS | 10001 | Allow the user to view the private contact methods of other users. Kept separate from `ADMIN` to allow for more fine-grained privacy control. |


 

 

 



<a name="users-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## users.proto



<a name="jonline-ContactMethod"></a>

### ContactMethod



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| value | [string](#string) | optional |  |
| visibility | [Visibility](#jonline-Visibility) |  |  |






<a name="jonline-Follow"></a>

### Follow



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user_id | [string](#string) |  |  |
| target_user_id | [string](#string) |  |  |
| target_user_moderation | [Moderation](#jonline-Moderation) |  |  |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |






<a name="jonline-GetUsersRequest"></a>

### GetUsersRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| username | [string](#string) | optional |  |
| user_id | [string](#string) | optional |  |
| page | [int32](#int32) | optional | optional string group_id = 3; optional string email = 2; optional string phone = 3; |
| listing_type | [UserListingType](#jonline-UserListingType) |  |  |






<a name="jonline-GetUsersResponse"></a>

### GetUsersResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| users | [User](#jonline-User) | repeated |  |
| has_next_page | [bool](#bool) |  |  |






<a name="jonline-Membership"></a>

### Membership
Model for a user&#39;s membership in a group. Memberships are generically
included as part of User models when relevant in Jonline, but UIs should use the group_id
to reconcile memberships with groups.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user_id | [string](#string) |  |  |
| group_id | [string](#string) |  |  |
| permissions | [Permission](#jonline-Permission) | repeated | Valid Membership Permissions are: * VIEW_POSTS, CREATE_POSTS, MODERATE_POSTS * VIEW_EVENTS, CREATE_EVENTS, MODERATE_EVENTS * ADMIN and MODERATE_USERS |
| group_moderation | [Moderation](#jonline-Moderation) |  | Tracks whether group moderators need to approve the membership. |
| user_moderation | [Moderation](#jonline-Moderation) |  | Tracks whether the user needs to approve the membership. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |






<a name="jonline-User"></a>

### User



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  |  |
| username | [string](#string) |  |  |
| real_name | [string](#string) |  |  |
| email | [ContactMethod](#jonline-ContactMethod) | optional |  |
| phone | [ContactMethod](#jonline-ContactMethod) | optional |  |
| permissions | [Permission](#jonline-Permission) | repeated |  |
| avatar_media_id | [string](#string) | optional | Media ID for the user&#39;s avatar. Note that its visibility is managed by the User and thus it may not be accessible to the current user. |
| bio | [string](#string) |  |  |
| visibility | [Visibility](#jonline-Visibility) |  | User visibility is a bit different from Post visibility. LIMITED means the user can only be seen by users they follow (as opposed to Posts&#39; individualized visibilities). PRIVATE visibility means no one can see the user. See server_configuration.proto for details about PRIVATE users&#39; ability to creep. |
| moderation | [Moderation](#jonline-Moderation) |  |  |
| default_follow_moderation | [Moderation](#jonline-Moderation) |  | Only PENDING or UNMODERATED are valid. |
| follower_count | [int32](#int32) | optional |  |
| following_count | [int32](#int32) | optional |  |
| group_count | [int32](#int32) | optional |  |
| post_count | [int32](#int32) | optional |  |
| response_count | [int32](#int32) | optional |  |
| current_user_follow | [Follow](#jonline-Follow) | optional | Presence indicates the current user is following or has a pending follow request for this user. |
| target_current_user_follow | [Follow](#jonline-Follow) | optional | Presence indicates this user is following or has a pending follow request for the current user. |
| current_group_membership | [Membership](#jonline-Membership) | optional |  |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |





 


<a name="jonline-UserListingType"></a>

### UserListingType


| Name | Number | Description |
| ---- | ------ | ----------- |
| EVERYONE | 0 |  |
| FOLLOWING | 1 |  |
| FRIENDS | 2 |  |
| FOLLOWERS | 3 |  |
| FOLLOW_REQUESTS | 4 |  |


 

 

 



<a name="media-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## media.proto



<a name="jonline-GetMediaRequest"></a>

### GetMediaRequest
Valid GetMediaRequest formats:
- `{user_id: &#34;123&#34;}` - Gets the media of the given user that the current user can see. IE:
    - *all* of the current user&#39;s own media
    - `GLOBAL_PUBLIC` media for the user if the current user is not logged in.
    - `SERVER_PUBLIC` media for the user if the current user is logged in.
    - `LIMITED` media for the user if the current user is following the user.
- `{media_id: &#34;123&#34;}` - Gets the media with the given ID, if visible to the current user.


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
Media data is deliberately *not returnable from the gRPC API*. Instead, the client
should fetch media from `http[s]://my.jonline.instance/media/{id}`.

Media items may be created with a HTTP POST to `http[s]://my.jonline.instance/media`
along with an &#34;Authorization&#34; header (your access token) and a &#34;Content-Type&#34; header.
On success, the endpoint will return the media ID in plaintext.

`POST /media` supports the following headers:
- `Content-Type` - The MIME content type of the media item.
- `Filename` - An optional title for the media item.
- `Authorization` - Jonline Access Token for the user. Required, but may be supplied in `Cookies`.
- `Cookies` - Standard web cookies. The `jonline_access_token` cookie may be used for authentication.

`GET /media` supports the following:
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





 

 

 

 



<a name="groups-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## groups.proto



<a name="jonline-GetGroupsRequest"></a>

### GetGroupsRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_id | [string](#string) | optional |  |
| group_name | [string](#string) | optional |  |
| group_shortname | [string](#string) | optional | Group shortname search is case-insensitive. |
| listing_type | [GroupListingType](#jonline-GroupListingType) |  |  |
| page | [int32](#int32) | optional |  |






<a name="jonline-GetGroupsResponse"></a>

### GetGroupsResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| groups | [Group](#jonline-Group) | repeated |  |
| has_next_page | [bool](#bool) |  |  |






<a name="jonline-GetMembersRequest"></a>

### GetMembersRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_id | [string](#string) |  |  |
| username | [string](#string) | optional |  |
| group_moderation | [Moderation](#jonline-Moderation) | optional |  |
| page | [int32](#int32) | optional |  |






<a name="jonline-GetMembersResponse"></a>

### GetMembersResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| members | [Member](#jonline-Member) | repeated |  |
| has_next_page | [bool](#bool) |  |  |






<a name="jonline-Group"></a>

### Group



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  |  |
| name | [string](#string) |  |  |
| shortname | [string](#string) |  |  |
| description | [string](#string) |  |  |
| avatar_media_id | [string](#string) | optional |  |
| default_membership_permissions | [Permission](#jonline-Permission) | repeated |  |
| default_membership_moderation | [Moderation](#jonline-Moderation) |  | Valid values are PENDING (requires a moderator to let you join) and UNMODERATED. |
| default_post_moderation | [Moderation](#jonline-Moderation) |  |  |
| default_event_moderation | [Moderation](#jonline-Moderation) |  |  |
| visibility | [Visibility](#jonline-Visibility) |  | LIMITED visibility groups are only visible to members. PRIVATE groups are only visibile to users with the ADMIN group permission. |
| member_count | [uint32](#uint32) |  |  |
| post_count | [uint32](#uint32) |  |  |
| current_user_membership | [Membership](#jonline-Membership) | optional |  |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |






<a name="jonline-Member"></a>

### Member
Used by group MODERATE_USERS mods to manage group requests from the People tab.
See also: UserListingType.MEMBERSHIP_REQUESTS.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user | [User](#jonline-User) |  |  |
| membership | [Membership](#jonline-Membership) |  |  |





 


<a name="jonline-GroupListingType"></a>

### GroupListingType


| Name | Number | Description |
| ---- | ------ | ----------- |
| ALL_GROUPS | 0 |  |
| MY_GROUPS | 1 |  |
| REQUESTED_GROUPS | 2 |  |
| INVITED_GROUPS | 3 |  |


 

 

 



<a name="posts-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## posts.proto



<a name="jonline-Author"></a>

### Author
Post-centric version of User. UI can cross-reference user details
from its own cache (for things like admin/bot icons).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user_id | [string](#string) |  |  |
| username | [string](#string) | optional |  |






<a name="jonline-GetGroupPostsRequest"></a>

### GetGroupPostsRequest
Used for getting context about GroupPosts of an existing Post.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| post_id | [string](#string) |  |  |
| group_id | [string](#string) | optional |  |






<a name="jonline-GetGroupPostsResponse"></a>

### GetGroupPostsResponse
Used for getting context about GroupPosts of an existing Post.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_posts | [GroupPost](#jonline-GroupPost) | repeated |  |






<a name="jonline-GetPostsRequest"></a>

### GetPostsRequest
Valid GetPostsRequest formats:

- `{[listing_type: PublicPosts]}`
    - Get ServerPublic/GlobalPublic posts you can see based on your authorization (or lack thereof).
- `{listing_type:MyGroupsPosts|FollowingPosts}`
    - Get posts from groups you&#39;re a member of or from users you&#39;re following. Authorization required.
- `{post_id:}`
    - Get one post ,including preview data/
- `{post_id:, reply_depth: 1}`
    - Get replies to a post - only support for replyDepth=1 is done for now though.
- `{listing_type: MyGroupsPosts|GroupPostsPendingModeration, group_id:}`
    - Get posts/posts needing moderation for a group. Authorization may be required depending on group visibility.
- `{author_user_id:, group_id:}`
    - Get posts by a user for a group. (TODO)
- `{listing_type: AuthorPosts, author_user_id:}`
    - Get posts by a user. (TODO)


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| post_id | [string](#string) | optional | Returns the single post with the given ID. |
| author_user_id | [string](#string) | optional | Limits results to replies to the given post. optional string replies_to_post_id = 2; Limits results to those by the given author user ID. |
| group_id | [string](#string) | optional |  |
| reply_depth | [uint32](#uint32) | optional | TODO: Implement support for this |
| listing_type | [PostListingType](#jonline-PostListingType) |  |  |
| page | [uint32](#uint32) |  |  |






<a name="jonline-GetPostsResponse"></a>

### GetPostsResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| posts | [Post](#jonline-Post) | repeated |  |






<a name="jonline-GroupPost"></a>

### GroupPost
A `GroupPost` is a cross-post of a `Post` to a `Group`. It contains
information about the moderation of the post in the group, as well as
the time it was cross-posted and the user who did the cross-posting.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_id | [string](#string) |  |  |
| post_id | [string](#string) |  |  |
| user_id | [string](#string) |  |  |
| group_moderation | [Moderation](#jonline-Moderation) |  |  |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |






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
| media | [string](#string) | repeated | List of Media IDs associated with this post. Order is preserved. |
| media_generated | [bool](#bool) |  | Flag indicating whether Media has been generated for this Post. Currently previews are generated for any Link post. |
| embed_link | [bool](#bool) |  | Flag indicating |
| shareable | [bool](#bool) |  | Flag indicating a `LIMITED` or `SERVER_PUBLIC` post can be shared with groups and individuals, and a `DIRECT` post can be shared with individuals. |
| context | [PostContext](#jonline-PostContext) |  | Context of the Post (`POST`, `REPLY`, `EVENT`, or `EVENT_INSTANCE`.) |
| visibility | [Visibility](#jonline-Visibility) |  | The visibility of the Post. |
| moderation | [Moderation](#jonline-Moderation) |  | The moderation of the Post. |
| current_group_post | [GroupPost](#jonline-GroupPost) | optional | If the Post was retrieved from GetPosts with a group_id, the GroupPost metadata may be returned along with the Post. |
| replies | [Post](#jonline-Post) | repeated | Hierarchical replies to this post.

There will never be more than `reply_count` replies. However, there may be fewer than `reply_count` replies if some replies are hidden by moderation or visibility. Replies are not generally loaded by default, but can be added to Posts in the frontend. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |
| published_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |
| last_activity_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |






<a name="jonline-UserPost"></a>

### UserPost
A `UserPost` is a &#34;direct share&#34; of a `Post` to a `User`. Currently unused.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_id | [string](#string) |  |  |
| user_id | [string](#string) |  |  |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |





 


<a name="jonline-PostContext"></a>

### PostContext


| Name | Number | Description |
| ---- | ------ | ----------- |
| POST | 0 |  |
| REPLY | 1 |  |
| EVENT | 2 |  |
| EVENT_INSTANCE | 3 |  |



<a name="jonline-PostListingType"></a>

### PostListingType
A high-level enumeration of general ways of requesting posts.

| Name | Number | Description |
| ---- | ------ | ----------- |
| PUBLIC_POSTS | 0 | Gets SERVER_PUBLIC and GLOBAL_PUBLIC posts as is sensible. Also usable for getting replies anywhere. |
| FOLLOWING_POSTS | 1 | Returns posts from users the user is following. |
| MY_GROUPS_POSTS | 2 | Returns posts from any group the user is a member of. |
| DIRECT_POSTS | 3 | Returns `DIRECT` posts that are directly addressed to the user. |
| POSTS_PENDING_MODERATION | 4 |  |
| GROUP_POSTS | 10 | group_id parameter is required for these. |
| GROUP_POSTS_PENDING_MODERATION | 11 |  |


 

 

 



<a name="events-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## events.proto



<a name="jonline-Event"></a>

### Event



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  |  |
| post | [Post](#jonline-Post) |  |  |
| info | [EventInfo](#jonline-EventInfo) |  |  |
| instances | [EventInstance](#jonline-EventInstance) | repeated |  |






<a name="jonline-EventAttendance"></a>

### EventAttendance



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| event_instance_id | [string](#string) |  |  |
| user_id | [string](#string) |  |  |
| status | [AttendanceStatus](#jonline-AttendanceStatus) |  |  |
| inviting_user_id | [string](#string) | optional |  |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |






<a name="jonline-EventInfo"></a>

### EventInfo
To be used for ticketing, RSVPs, etc.






<a name="jonline-EventInstance"></a>

### EventInstance



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  |  |
| event_id | [string](#string) |  |  |
| post | [Post](#jonline-Post) | optional |  |
| info | [EventInstanceInfo](#jonline-EventInstanceInfo) |  |  |
| starts_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |
| ends_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |






<a name="jonline-EventInstanceInfo"></a>

### EventInstanceInfo
To be used for ticketing, RSVPs, etc.






<a name="jonline-GetEventsRequest"></a>

### GetEventsRequest
Valid GetEventsRequest formats:
- {[listing_type: PublicEvents]}                  (TODO: get ServerPublic/GlobalPublic events you can see)
- {listing_type:MyGroupsEvents|FollowingEvents}   (TODO: get events for groups joined or user followed; auth required)
- {event_id:}                                     (TODO: get single event including preview data)
- {listing_type: GroupEvents|
     GroupEventsPendingModeration,
     group_id:}                                  (TODO: get events/events needing moderation for a group)
- {author_user_id:, group_id:}                   (TODO: get events by a user for a group)
- {listing_type: AuthorEvents, author_user_id:}  (TODO: get events by a user)


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| event_id | [string](#string) | optional | Returns the single event with the given ID. |
| author_user_id | [string](#string) | optional | Limits results to replies to the given event. optional string replies_to_event_id = 2; Limits results to those by the given author user ID. |
| group_id | [string](#string) | optional |  |
| event_instance_id | [string](#string) | optional |  |
| time_filter | [TimeFilter](#jonline-TimeFilter) | optional |  |
| listing_type | [EventListingType](#jonline-EventListingType) |  |  |






<a name="jonline-GetEventsResponse"></a>

### GetEventsResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| events | [Event](#jonline-Event) | repeated |  |






<a name="jonline-TimeFilter"></a>

### TimeFilter
Time filter that simply works on the starts_at and ends_at fields.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| starts_after | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |
| ends_after | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |
| starts_before | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |
| ends_before | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |





 


<a name="jonline-AttendanceStatus"></a>

### AttendanceStatus


| Name | Number | Description |
| ---- | ------ | ----------- |
| INTERESTED | 0 |  |
| GOING | 1 |  |
| NOT_GOING | 2 |  |
| REQUESTED | 3 |  |
| WENT | 10 |  |
| DID_NOT_GO | 11 |  |



<a name="jonline-EventListingType"></a>

### EventListingType


| Name | Number | Description |
| ---- | ------ | ----------- |
| PUBLIC_EVENTS | 0 | Gets SERVER_PUBLIC and GLOBAL_PUBLIC events as is sensible. Also usable for getting replies anywhere. |
| FOLLOWING_EVENTS | 1 | Returns events from users the user is following. |
| MY_GROUPS_EVENTS | 2 | Returns events from any group the user is a member of. |
| DIRECT_EVENTS | 3 | Returns `DIRECT` events that are directly addressed to the user. |
| EVENTS_PENDING_MODERATION | 4 |  |
| GROUP_EVENTS | 10 | group_id parameter is required for these. |
| GROUP_EVENTS_PENDING_MODERATION | 11 |  |


 

 

 



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






<a name="jonline-FeatureSettings"></a>

### FeatureSettings



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| visible | [bool](#bool) |  | Hide the Posts or Events tab from the user with this flag. |
| default_moderation | [Moderation](#jonline-Moderation) |  | Only `UNMODERATED` and `PENDING` are valid. When `UNMODERATED`, user reports may transition status to `PENDING`. When `PENDING`, users&#39; SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not be visible until a moderator approves them. `LIMITED` visiblity posts are always visible to targeted users (who have not blocked the author) regardless of default_moderation. |
| default_visibility | [Visibility](#jonline-Visibility) |  | Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]` as appropriate. |
| custom_title | [string](#string) | optional |  |






<a name="jonline-PostSettings"></a>

### PostSettings



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| visible | [bool](#bool) |  | Hide the Posts or Events tab from the user with this flag. |
| default_moderation | [Moderation](#jonline-Moderation) |  | Only `UNMODERATED` and `PENDING` are valid. When `UNMODERATED`, user reports may transition status to `PENDING`. When `PENDING`, users&#39; SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not be visible until a moderator approves them. `LIMITED` visiblity posts are always visible to targeted users (who have not blocked the author) regardless of default_moderation. |
| default_visibility | [Visibility](#jonline-Visibility) |  | Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]` as appropriate. |
| custom_title | [string](#string) | optional |  |
| enable_replies | [bool](#bool) |  | Controls whether replies are shown in the UI. Note that users&#39; ability to reply is controlled by the `REPLY_TO_POSTS` permission. |






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
| anonymous_user_permissions | [Permission](#jonline-Permission) | repeated | Permissions for a user who isn&#39;t logged in to the server. Allows admins to disable certain features for anonymous users. Valid values are `VIEW_USERS`, `VIEW_GROUPS`, `VIEW_POSTS`, and `VIEW_EVENTS`. |
| default_user_permissions | [Permission](#jonline-Permission) | repeated | Default user permissions given to a new user. Users with `MODERATE_USERS` permission can also grant/revoke these permissions for others. Valid values are `VIEW_USERS`, `PUBLISH_USERS_LOCALLY`, `PUBLISH_USERS_GLOBALLY`, `VIEW_GROUPS`, `CREATE_GROUPS`, `PUBLISH_GROUPS_LOCALLY`, `PUBLISH_GROUPS_GLOBALLY`, `JOIN_GROUPS`, `VIEW_POSTS`, `CREATE_POSTS`, `PUBLISH_POSTS_LOCALLY`, `PUBLISH_POSTS_GLOBALLY`, `VIEW_EVENTS`, `CREATE_EVENTS`, `PUBLISH_EVENTS_LOCALLY`, and `PUBLISH_EVENTS_GLOBALLY`. |
| basic_user_permissions | [Permission](#jonline-Permission) | repeated | Permissions grantable by a user with the `GRANT_BASIC_PERMISSIONS` permission. Valid values are `VIEW_USERS`, `PUBLISH_USERS_LOCALLY`, `PUBLISH_USERS_GLOBALLY`, `VIEW_GROUPS`, `CREATE_GROUPS`, `PUBLISH_GROUPS_LOCALLY`, `PUBLISH_GROUPS_GLOBALLY`, `JOIN_GROUPS`, `VIEW_POSTS`, `CREATE_POSTS`, `PUBLISH_POSTS_LOCALLY`, `PUBLISH_POSTS_GLOBALLY`, `VIEW_EVENTS`, `CREATE_EVENTS`, `PUBLISH_EVENTS_LOCALLY`, and `PUBLISH_EVENTS_GLOBALLY`. |
| people_settings | [FeatureSettings](#jonline-FeatureSettings) |  | If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_USERS_GLOBALLY`. |
| group_settings | [FeatureSettings](#jonline-FeatureSettings) |  | If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_GROUPS_GLOBALLY`. |
| post_settings | [PostSettings](#jonline-PostSettings) |  | If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_POSTS_GLOBALLY`. |
| event_settings | [FeatureSettings](#jonline-FeatureSettings) |  | If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_EVENTS_GLOBALLY`. |
| media_settings | [FeatureSettings](#jonline-FeatureSettings) |  | If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_EVENTS_GLOBALLY`. |
| external_cdn_config | [ExternalCDNConfig](#jonline-ExternalCDNConfig) | optional |  |
| private_user_strategy | [PrivateUserStrategy](#jonline-PrivateUserStrategy) |  | Strategy when a user sets their visibility to `PRIVATE`. Defaults to `ACCOUNT_IS_FROZEN`. |
| authentication_features | [AuthenticationFeature](#jonline-AuthenticationFeature) | repeated | Allows admins to enable/disable creating accounts and logging in. Eventually, external auth too hopefully! |






<a name="jonline-ServerInfo"></a>

### ServerInfo



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| name | [string](#string) | optional |  |
| short_name | [string](#string) | optional |  |
| description | [string](#string) | optional |  |
| privacy_policy_link | [string](#string) | optional |  |
| about_link | [string](#string) | optional |  |
| web_user_interface | [WebUserInterface](#jonline-WebUserInterface) | optional |  |
| colors | [ServerColors](#jonline-ServerColors) | optional |  |
| logo | [bytes](#bytes) | optional |  |





 


<a name="jonline-AuthenticationFeature"></a>

### AuthenticationFeature


| Name | Number | Description |
| ---- | ------ | ----------- |
| AUTHENTICATION_FEATURE_UNKNOWN | 0 |  |
| CREATE_ACCOUNT | 1 | Users can sign up for an account. |
| LOGIN | 2 | Users can sign in with an existing account. |



<a name="jonline-PrivateUserStrategy"></a>

### PrivateUserStrategy


| Name | Number | Description |
| ---- | ------ | ----------- |
| ACCOUNT_IS_FROZEN | 0 | `PRIVATE` Users can&#39;t see other Users (only `PUBLIC_GLOBAL` Visilibity Users/Posts/Events). Other users can&#39;t see them. |
| LIMITED_CREEPINESS | 1 | Users can see other users they follow, but only `PUBLIC_GLOBAL` Visilibity Posts/Events. Other users can&#39;t see them. |
| LET_ME_CREEP_ON_PPL | 2 | Users can see other users they follow, including their `PUBLIC_SERVER` Posts/Events. Other users can&#39;t see them. |



<a name="jonline-WebUserInterface"></a>

### WebUserInterface
Offers a choice of web UIs. All

| Name | Number | Description |
| ---- | ------ | ----------- |
| FLUTTER_WEB | 0 | Uses Flutter Web. Loaded from /app. |
| HANDLEBARS_TEMPLATES | 1 | Uses Handlebars templates. Deprecated; will revert to Tamagui UI if chosen. |
| REACT_TAMAGUI | 2 | React UI using Tamagui (a React Native UI library). |


 

 

 



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

