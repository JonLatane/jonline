# Protocol Documentation
<a name="top"></a>

## Table of Contents

- [authentication.proto](#authentication-proto)
    - [AccessTokenRequest](#jonline-AccessTokenRequest)
    - [AccessTokenResponse](#jonline-AccessTokenResponse)
    - [CreateAccountRequest](#jonline-CreateAccountRequest)
    - [ExpirableToken](#jonline-ExpirableToken)
    - [LoginRequest](#jonline-LoginRequest)
    - [RefreshTokenResponse](#jonline-RefreshTokenResponse)
  
- [events.proto](#events-proto)
    - [Event](#jonline-Event)
    - [EventInfo](#jonline-EventInfo)
    - [EventInstance](#jonline-EventInstance)
    - [EventInstanceInfo](#jonline-EventInstanceInfo)
    - [GetEventsRequest](#jonline-GetEventsRequest)
    - [GetEventsResponse](#jonline-GetEventsResponse)
  
    - [EventListingType](#jonline-EventListingType)
  
- [federation.proto](#federation-proto)
    - [FederateRequest](#jonline-FederateRequest)
    - [FederateResponse](#jonline-FederateResponse)
    - [FederatedAccount](#jonline-FederatedAccount)
    - [GetFederatedAccountsRequest](#jonline-GetFederatedAccountsRequest)
    - [GetFederatedAccountsResponse](#jonline-GetFederatedAccountsResponse)
    - [GetServiceVersionResponse](#jonline-GetServiceVersionResponse)
  
    - [FederationCredentials](#jonline-FederationCredentials)
  
- [groups.proto](#groups-proto)
    - [GetGroupsRequest](#jonline-GetGroupsRequest)
    - [GetGroupsResponse](#jonline-GetGroupsResponse)
    - [GetMembersRequest](#jonline-GetMembersRequest)
    - [GetMembersResponse](#jonline-GetMembersResponse)
    - [Group](#jonline-Group)
    - [Member](#jonline-Member)
  
    - [GroupListingType](#jonline-GroupListingType)
  
- [jonline.proto](#jonline-proto)
    - [Jonline](#jonline-Jonline)
  
- [permissions.proto](#permissions-proto)
    - [Permission](#jonline-Permission)
  
- [posts.proto](#posts-proto)
    - [Author](#jonline-Author)
    - [CreatePostRequest](#jonline-CreatePostRequest)
    - [GetGroupPostsRequest](#jonline-GetGroupPostsRequest)
    - [GetGroupPostsResponse](#jonline-GetGroupPostsResponse)
    - [GetPostsRequest](#jonline-GetPostsRequest)
    - [GetPostsResponse](#jonline-GetPostsResponse)
    - [GroupPost](#jonline-GroupPost)
    - [Post](#jonline-Post)
    - [UserPost](#jonline-UserPost)
  
    - [PostListingType](#jonline-PostListingType)
  
- [server_configuration.proto](#server_configuration-proto)
    - [FeatureSettings](#jonline-FeatureSettings)
    - [ServerColors](#jonline-ServerColors)
    - [ServerConfiguration](#jonline-ServerConfiguration)
    - [ServerInfo](#jonline-ServerInfo)
  
    - [AuthenticationFeature](#jonline-AuthenticationFeature)
    - [PrivateUserStrategy](#jonline-PrivateUserStrategy)
    - [WebUserInterface](#jonline-WebUserInterface)
  
- [users.proto](#users-proto)
    - [ContactMethod](#jonline-ContactMethod)
    - [Follow](#jonline-Follow)
    - [GetUsersRequest](#jonline-GetUsersRequest)
    - [GetUsersResponse](#jonline-GetUsersResponse)
    - [Membership](#jonline-Membership)
    - [User](#jonline-User)
  
    - [UserListingType](#jonline-UserListingType)
  
- [visibility_moderation.proto](#visibility_moderation-proto)
    - [Moderation](#jonline-Moderation)
    - [Visibility](#jonline-Visibility)
  
- [Scalar Value Types](#scalar-value-types)



<a name="authentication-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## authentication.proto



<a name="jonline-AccessTokenRequest"></a>

### AccessTokenRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| refresh_token | [string](#string) |  |  |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Optional *requested* expiration time for the token. Server may ignore this. |






<a name="jonline-AccessTokenResponse"></a>

### AccessTokenResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| access_token | [string](#string) | optional |  |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |






<a name="jonline-CreateAccountRequest"></a>

### CreateAccountRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| username | [string](#string) |  |  |
| password | [string](#string) |  |  |
| email | [ContactMethod](#jonline-ContactMethod) | optional |  |
| phone | [ContactMethod](#jonline-ContactMethod) | optional |  |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Request an expiration time for the Auth Token returned. By default it will not expire. |
| device_name | [string](#string) | optional |  |






<a name="jonline-ExpirableToken"></a>

### ExpirableToken



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| token | [string](#string) |  |  |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Optional expiration time for the token. If not set, the token will not expire. |






<a name="jonline-LoginRequest"></a>

### LoginRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| username | [string](#string) |  |  |
| password | [string](#string) |  |  |
| expires_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Request an expiration time for the Auth Token returned. By default it will not expire. |
| device_name | [string](#string) | optional |  |






<a name="jonline-RefreshTokenResponse"></a>

### RefreshTokenResponse
Returned when creating an account or logging in.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| refresh_token | [ExpirableToken](#jonline-ExpirableToken) |  |  |
| access_token | [ExpirableToken](#jonline-ExpirableToken) |  |  |
| user | [User](#jonline-User) |  |  |





 

 

 

 



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
| listing_type | [EventListingType](#jonline-EventListingType) |  |  |






<a name="jonline-GetEventsResponse"></a>

### GetEventsResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| events | [Event](#jonline-Event) | repeated |  |





 


<a name="jonline-EventListingType"></a>

### EventListingType


| Name | Number | Description |
| ---- | ------ | ----------- |
| PUBLIC_EVENTS | 0 | Gets SERVER_PUBLIC and GLOBAL_PUBLIC events as is sensible. Also usable for getting replies anywhere. |
| FOLLOWING_EVENTS | 1 | Returns events from users the user is following. |
| MY_GROUPS_EVENTS | 2 | Returns events from any group the user is a member of. |
| DIRECT_EVENTS | 3 | Returns LIMITED events that are directly addressed to the user. |
| EVENTS_PENDING_MODERATION | 4 |  |
| GROUP_EVENTS | 10 | group_id parameter is required for these. |
| GROUP_EVENTS_PENDING_MODERATION | 11 |  |


 

 

 



<a name="federation-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## federation.proto



<a name="jonline-FederateRequest"></a>

### FederateRequest
Asks the Jonline instance the request is sent to federate your account with one at `server`.
By default, a simple FederationRequest of `{server:, username:}` will create an account with
the username on the server, generate a permanent auth token, and use it. If you want Jonline
to store the remote Jonline account password, use `stored_credentials`. If you want to get the
password and/or auth token for the remote account yourself, use `returned_credentials`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| server | [string](#string) |  | The remote server to federate accounts with. |
| preexisting_account | [bool](#bool) |  | Indicates whether the account already exists on the remote server. When false, the instance will attempt to create the account on the remote server. |
| username | [string](#string) |  | The username of the account on the remote server. |
| password | [string](#string) | optional | When preexisting_account = true, will attempt to federate using that password. When preexisting_account = false, will create a new account using that password. |
| refresh_token | [string](#string) | optional | When preexisting_account = true, will attempt to federate using that password. When preexisting_account = false, will create a new account using that password. |
| stored_credentials | [FederationCredentials](#jonline-FederationCredentials) |  | Request whether to store only the auth token, or the auth token and password. |
| returned_credentials | [FederationCredentials](#jonline-FederationCredentials) | optional | Request whether to return nothing, the auth token, or the auth token and password. |






<a name="jonline-FederateResponse"></a>

### FederateResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| refresh_token | [string](#string) | optional |  |
| password | [string](#string) | optional |  |






<a name="jonline-FederatedAccount"></a>

### FederatedAccount



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  |  |
| server | [string](#string) |  |  |
| username | [string](#string) |  |  |
| password | [string](#string) | optional |  |
| refresh_token | [string](#string) | optional |  |






<a name="jonline-GetFederatedAccountsRequest"></a>

### GetFederatedAccountsRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| returned_credentials | [FederationCredentials](#jonline-FederationCredentials) | optional |  |






<a name="jonline-GetFederatedAccountsResponse"></a>

### GetFederatedAccountsResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| federated_accounts | [FederatedAccount](#jonline-FederatedAccount) | repeated |  |






<a name="jonline-GetServiceVersionResponse"></a>

### GetServiceVersionResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| version | [string](#string) |  |  |





 


<a name="jonline-FederationCredentials"></a>

### FederationCredentials


| Name | Number | Description |
| ---- | ------ | ----------- |
| REFRESH_TOKEN_ONLY | 0 |  |
| REFRESH_TOKEN_AND_PASSWORD | 1 |  |


 

 

 



<a name="groups-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## groups.proto



<a name="jonline-GetGroupsRequest"></a>

### GetGroupsRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_id | [string](#string) | optional |  |
| group_name | [string](#string) | optional |  |
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
| description | [string](#string) |  |  |
| avatar | [bytes](#bytes) | optional |  |
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
| REQUESTED | 2 |  |
| INVITED | 3 |  |


 

 

 



<a name="jonline-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## jonline.proto


 

 

 


<a name="jonline-Jonline"></a>

### Jonline
Authenticated calls require a Refresh Token in request metadata, retrieved from
the AccessToken RPC. The CreateAccount or Login RPC should first be used to fetch
(and store) an Authentication Token to use when calling AccessToken.

| Method Name | Request Type | Response Type | Description |
| ----------- | ------------ | ------------- | ------------|
| GetServiceVersion | [.google.protobuf.Empty](#google-protobuf-Empty) | [GetServiceVersionResponse](#jonline-GetServiceVersionResponse) | Get the version (from Cargo) of the Jonline service. Publicly accessible. |
| GetServerConfiguration | [.google.protobuf.Empty](#google-protobuf-Empty) | [ServerConfiguration](#jonline-ServerConfiguration) | (TODO) Gets the Jonline server&#39;s configuration. Publicly accessible. |
| CreateAccount | [CreateAccountRequest](#jonline-CreateAccountRequest) | [RefreshTokenResponse](#jonline-RefreshTokenResponse) | Creates a user account and provides an auth token. Publicly accessible. |
| Login | [LoginRequest](#jonline-LoginRequest) | [RefreshTokenResponse](#jonline-RefreshTokenResponse) | Logs in a user and provides an Auth Token (along with a Refresh Token). |
| AccessToken | [AccessTokenRequest](#jonline-AccessTokenRequest) | [ExpirableToken](#jonline-ExpirableToken) | Gets a new Refresh Token (given an Auth Token). |
| GetCurrentUser | [.google.protobuf.Empty](#google-protobuf-Empty) | [User](#jonline-User) | Gets the current user. Authenticated. |
| GetUsers | [GetUsersRequest](#jonline-GetUsersRequest) | [GetUsersResponse](#jonline-GetUsersResponse) | Gets Users. Publicly accessible *or* authenticated. Unauthenticated calls only return Users of GLOBAL_PUBLIC visibility. |
| UpdateUser | [User](#jonline-User) | [User](#jonline-User) | Update a user by ID. Authenticated. Updating other users requires ADMIN permissions. |
| CreateFollow | [Follow](#jonline-Follow) | [Follow](#jonline-Follow) | Follow (or request to follow) a user. Authenticated. |
| UpdateFollow | [Follow](#jonline-Follow) | [Follow](#jonline-Follow) | Used to approve follow requests. Authenticated. |
| DeleteFollow | [Follow](#jonline-Follow) | [.google.protobuf.Empty](#google-protobuf-Empty) | Unfollow (or unrequest) a user. Authenticated. |
| GetGroups | [GetGroupsRequest](#jonline-GetGroupsRequest) | [GetGroupsResponse](#jonline-GetGroupsResponse) | Gets Groups. Publicly accessible *or* authenticated. Unauthenticated calls only return Groups of GLOBAL_PUBLIC visibility. |
| CreateGroup | [Group](#jonline-Group) | [Group](#jonline-Group) | Creates a group with the current user as its admin. Authenticated. Requires the CREATE_GROUPS permission. |
| UpdateGroup | [Group](#jonline-Group) | [Group](#jonline-Group) | Update a Groups&#39;s information, default membership permissions or moderation. Authenticated. Requires ADMIN permissions within the group, or ADMIN permissions for the user. |
| DeleteGroup | [Group](#jonline-Group) | [.google.protobuf.Empty](#google-protobuf-Empty) | Delete a Group. Authenticated. Requires ADMIN permissions within the group, or ADMIN permissions for the user. |
| CreateMembership | [Membership](#jonline-Membership) | [Membership](#jonline-Membership) | Requests to join a group (or joins it), or sends an invite to the user. Authenticated. Memberships and moderations are set to their defaults. |
| UpdateMembership | [Membership](#jonline-Membership) | [Membership](#jonline-Membership) | Update aspects of a user&#39;s membership. Authenticated. Updating permissions requires ADMIN permissions within the group, or ADMIN permissions for the user. Updating moderation (approving/denying/banning) requires the same, or MODERATE_USERS permissions within the group. |
| DeleteMembership | [Membership](#jonline-Membership) | [.google.protobuf.Empty](#google-protobuf-Empty) | Leave a group (or cancel membership request). Authenticated. |
| GetMembers | [GetMembersRequest](#jonline-GetMembersRequest) | [GetMembersResponse](#jonline-GetMembersResponse) | Get Members (User&#43;Membership) of a Group. Authenticated. |
| GetPosts | [GetPostsRequest](#jonline-GetPostsRequest) | [GetPostsResponse](#jonline-GetPostsResponse) | Gets Posts. Publicly accessible *or* authenticated. Unauthenticated calls only return Posts of GLOBAL_PUBLIC visibility. |
| CreatePost | [CreatePostRequest](#jonline-CreatePostRequest) | [Post](#jonline-Post) | Creates a Post. Authenticated. |
| UpdatePost | [Post](#jonline-Post) | [Post](#jonline-Post) | (TODO) Updates a Post. Authenticated. |
| DeletePost | [Post](#jonline-Post) | [Post](#jonline-Post) | (TODO) (Soft) deletes a Post. Returns the deleted version of the Post. Authenticated. |
| CreateGroupPost | [GroupPost](#jonline-GroupPost) | [GroupPost](#jonline-GroupPost) | Cross-post a Post to a Group. Authenticated. |
| UpdateGroupPost | [GroupPost](#jonline-GroupPost) | [GroupPost](#jonline-GroupPost) | Group Moderators: Approve/Reject a GroupPost. Authenticated. |
| DeleteGroupPost | [GroupPost](#jonline-GroupPost) | [.google.protobuf.Empty](#google-protobuf-Empty) | Delete a GroupPost. Authenticated. |
| GetGroupPosts | [GetGroupPostsRequest](#jonline-GetGroupPostsRequest) | [GetGroupPostsResponse](#jonline-GetGroupPostsResponse) | Get GroupPosts for a Post (and optional group). Publicly accessible *or* authenticated. |
| ConfigureServer | [ServerConfiguration](#jonline-ServerConfiguration) | [ServerConfiguration](#jonline-ServerConfiguration) | Configure the server (i.e. the response to GetServerConfiguration). Authenticated. Requires ADMIN permissions. |
| ResetData | [.google.protobuf.Empty](#google-protobuf-Empty) | [.google.protobuf.Empty](#google-protobuf-Empty) | DELETE ALL Posts, Groups and Users except the one who performed the RPC. Authenticated. Requires ADMIN permissions. Note: Server Configuration is not deleted. |

 



<a name="permissions-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## permissions.proto


 


<a name="jonline-Permission"></a>

### Permission


| Name | Number | Description |
| ---- | ------ | ----------- |
| PERMISSION_UNKNOWN | 0 |  |
| VIEW_USERS | 1 |  |
| PUBLISH_USERS_LOCALLY | 2 | This generally only applies to the user&#39;s own profile, except for Admins. |
| PUBLISH_USERS_GLOBALLY | 3 | This generally only applies to the user&#39;s own profile, except for Admins. |
| MODERATE_USERS | 4 | &#34;Moderate users&#34; refers to granting VIEW_POSTS, CREATE_POSTS, VIEW_EVENTS and CREATE_EVENTS permissions to users. |
| FOLLOW_USERS | 5 |  |
| GRANT_BASIC_PERMISSIONS | 6 | &#34;Basic Permissions&#34; are defined by your ServerConfiguration&#39;s basic_user_permissions. |
| VIEW_GROUPS | 10 |  |
| CREATE_GROUPS | 11 |  |
| PUBLISH_GROUPS_LOCALLY | 12 |  |
| PUBLISH_GROUPS_GLOBALLY | 13 |  |
| MODERATE_GROUPS | 14 | The Moderate Groups permission makes a user effectively an admin of *any* group. |
| JOIN_GROUPS | 15 |  |
| VIEW_POSTS | 20 |  |
| CREATE_POSTS | 21 |  |
| PUBLISH_POSTS_LOCALLY | 22 |  |
| PUBLISH_POSTS_GLOBALLY | 23 |  |
| MODERATE_POSTS | 24 |  |
| VIEW_EVENTS | 30 |  |
| CREATE_EVENTS | 31 |  |
| PUBLISH_EVENTS_LOCALLY | 32 |  |
| PUBLISH_EVENTS_GLOBALLY | 33 |  |
| MODERATE_EVENTS | 34 |  |
| RUN_BOTS | 9999 |  |
| ADMIN | 10000 |  |
| VIEW_PRIVATE_CONTACT_METHODS | 10001 |  |


 

 

 



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






<a name="jonline-CreatePostRequest"></a>

### CreatePostRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| title | [string](#string) | optional |  |
| link | [string](#string) | optional |  |
| content | [string](#string) | optional |  |
| reply_to_post_id | [string](#string) | optional |  |






<a name="jonline-GetGroupPostsRequest"></a>

### GetGroupPostsRequest
Used for getting context about GroupPosts of an existing Post.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| post_id | [string](#string) |  |  |
| group_id | [string](#string) | optional |  |






<a name="jonline-GetGroupPostsResponse"></a>

### GetGroupPostsResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_posts | [GroupPost](#jonline-GroupPost) | repeated |  |






<a name="jonline-GetPostsRequest"></a>

### GetPostsRequest
Valid GetPostsRequest formats:
- {[listing_type: PublicPosts]}                  (get ServerPublic/GlobalPublic posts you can see)
- {listing_type:MyGroupsPosts|FollowingPosts}    (auth required)
- {post_id:}                                     (get one post including preview data)
- {post_id:, reply_depth: 1}                     (get replies to a post - only support for replyDepth=1 for now tho)
- {listing_type: MyGroupsPosts|
     GroupPostsPendingModeration,
     group_id:}                                  (get posts/posts needing moderation for a group)
- {author_user_id:, group_id:}                   (get posts by a user for a group)
- {listing_type: AuthorPosts, author_user_id:}   (TODO: get posts by a user)


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| post_id | [string](#string) | optional | Returns the single post with the given ID. |
| author_user_id | [string](#string) | optional | Limits results to replies to the given post. optional string replies_to_post_id = 2; Limits results to those by the given author user ID. |
| group_id | [string](#string) | optional |  |
| reply_depth | [uint32](#uint32) | optional | TODO: Implement support for this |
| listing_type | [PostListingType](#jonline-PostListingType) |  |  |






<a name="jonline-GetPostsResponse"></a>

### GetPostsResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| posts | [Post](#jonline-Post) | repeated |  |






<a name="jonline-GroupPost"></a>

### GroupPost



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_id | [string](#string) |  |  |
| post_id | [string](#string) |  |  |
| user_id | [string](#string) |  |  |
| group_moderation | [Moderation](#jonline-Moderation) |  |  |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |






<a name="jonline-Post"></a>

### Post



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  |  |
| author | [Author](#jonline-Author) | optional |  |
| reply_to_post_id | [string](#string) | optional |  |
| title | [string](#string) | optional |  |
| link | [string](#string) | optional |  |
| content | [string](#string) | optional |  |
| response_count | [int32](#int32) |  |  |
| reply_count | [int32](#int32) |  |  |
| replies | [Post](#jonline-Post) | repeated |  |
| preview_image | [bytes](#bytes) | optional |  |
| visibility | [Visibility](#jonline-Visibility) |  |  |
| moderation | [Moderation](#jonline-Moderation) |  |  |
| group_count | [int32](#int32) |  |  |
| current_group_post | [GroupPost](#jonline-GroupPost) | optional | When the post is returned in the context of a group_id parameter, this can be returned. It lets the UI know whether the post can be cross-posted to a group, and of course, *about* the cross-post (time, moderation) if that&#39;s relevant. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional |  |






<a name="jonline-UserPost"></a>

### UserPost



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_id | [string](#string) |  |  |
| user_id | [string](#string) |  |  |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |





 


<a name="jonline-PostListingType"></a>

### PostListingType


| Name | Number | Description |
| ---- | ------ | ----------- |
| PUBLIC_POSTS | 0 | Gets SERVER_PUBLIC and GLOBAL_PUBLIC posts as is sensible. Also usable for getting replies anywhere. |
| FOLLOWING_POSTS | 1 | Returns posts from users the user is following. |
| MY_GROUPS_POSTS | 2 | Returns posts from any group the user is a member of. |
| DIRECT_POSTS | 3 | Returns LIMITED posts that are directly addressed to the user. |
| POSTS_PENDING_MODERATION | 4 |  |
| GROUP_POSTS | 10 | group_id parameter is required for these. |
| GROUP_POSTS_PENDING_MODERATION | 11 |  |


 

 

 



<a name="server_configuration-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## server_configuration.proto



<a name="jonline-FeatureSettings"></a>

### FeatureSettings



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| visible | [bool](#bool) |  | Hide the Posts or Events tab from the user with this flag. |
| default_moderation | [Moderation](#jonline-Moderation) |  | Only UNMODERATED and PENDING are valid. When UNMODERATED, user reports may transition status to PENDING. When PENDING, users&#39; SERVER_PUBLIC or GLOBAL_PUBLIC posts will not be visible until a moderator approves them. LIMITED visiblity posts are always visible to targeted users (who have not blocked the author) regardless of default_moderation. |
| default_visibility | [Visibility](#jonline-Visibility) |  | Only SERVER_PUBLIC and GLOBAL_PUBLIC are valid. GLOBAL_PUBLIC is only valid if default_user_permissions contains GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS] as appropriate. |
| custom_title | [string](#string) | optional |  |






<a name="jonline-ServerColors"></a>

### ServerColors
Color in ARGB hex format (i.e 0xAARRGGBB).
Clients may override/modify colors that cause poor UX.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| primary | [uint32](#uint32) | optional | App Bar/primary accent color. |
| navigation | [uint32](#uint32) | optional | Nav/secondary accent color. |
| author | [uint32](#uint32) | optional | Color used on author of a post in discussion threads for it. |
| admin | [uint32](#uint32) | optional | Color used on author for admin posts. |
| moderator | [uint32](#uint32) | optional | Color used on author for moderator posts. |






<a name="jonline-ServerConfiguration"></a>

### ServerConfiguration
Confuguration for a Jonline server instance.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| server_info | [ServerInfo](#jonline-ServerInfo) | optional | The name of the server. |
| anonymous_user_permissions | [Permission](#jonline-Permission) | repeated |  |
| default_user_permissions | [Permission](#jonline-Permission) | repeated | Default user permissions given to a user. Valid values are VIEW_POSTS, CREATE_POSTS, PUBLISH_POSTS_GLOBALLY, VIEW_EVENTS, CREATE_EVENTS, and PUBLISH_EVENTS_GLOBALLY. Users with MODERATE_USERS permission can grant these permissions to other users. Only users with ADMIN can grant MODERATE_USERS, MODERATE_POSTS, and MODERATE_EVENTS. |
| basic_user_permissions | [Permission](#jonline-Permission) | repeated |  |
| people_settings | [FeatureSettings](#jonline-FeatureSettings) |  | If default visibility is GLOBAL_PUBLIC, default_user_permissions *must* contain PUBLISH_USERS_GLOBALLY. |
| group_settings | [FeatureSettings](#jonline-FeatureSettings) |  | If default visibility is GLOBAL_PUBLIC, default_user_permissions *must* contain PUBLISH_GROUPS_GLOBALLY. |
| post_settings | [FeatureSettings](#jonline-FeatureSettings) |  | If default visibility is GLOBAL_PUBLIC, default_user_permissions *must* contain PUBLISH_POSTS_GLOBALLY. |
| event_settings | [FeatureSettings](#jonline-FeatureSettings) |  | If default visibility is GLOBAL_PUBLIC, default_user_permissions *must* contain PUBLISH_EVENTS_GLOBALLY. |
| private_user_strategy | [PrivateUserStrategy](#jonline-PrivateUserStrategy) |  | Strategy when a user sets their visibility to PRIVATE. Defaults to ACCOUNT_IS_FROZEN. |
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
| ACCOUNT_IS_FROZEN | 0 | PRIVATE Users can&#39;t see other Users (only PUBLIC_GLOBAL Visilibity Users/Posts/Events). Other users can&#39;t see them. |
| LIMITED_CREEPINESS | 1 | Users can see other users they follow, but only PUBLIC_GLOBAL Visilibity Posts/Events. Other users can&#39;t see them. |
| LET_ME_CREEP_ON_PPL | 2 | Users can see other users they follow, including their PUBLIC_SERVER Posts/Events, Other users can&#39;t see them. |



<a name="jonline-WebUserInterface"></a>

### WebUserInterface


| Name | Number | Description |
| ---- | ------ | ----------- |
| FLUTTER_WEB | 0 |  |
| HANDLEBARS_TEMPLATES | 1 |  |


 

 

 



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
| email | [ContactMethod](#jonline-ContactMethod) | optional |  |
| phone | [ContactMethod](#jonline-ContactMethod) | optional |  |
| permissions | [Permission](#jonline-Permission) | repeated |  |
| avatar | [bytes](#bytes) | optional |  |
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


 

 

 



<a name="visibility_moderation-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## visibility_moderation.proto


 


<a name="jonline-Moderation"></a>

### Moderation


| Name | Number | Description |
| ---- | ------ | ----------- |
| MODERATION_UNKNOWN | 0 |  |
| UNMODERATED | 1 |  |
| PENDING | 2 |  |
| APPROVED | 3 |  |
| REJECTED | 4 |  |



<a name="jonline-Visibility"></a>

### Visibility


| Name | Number | Description |
| ---- | ------ | ----------- |
| VISIBILITY_UNKNOWN | 0 |  |
| PRIVATE | 1 |  |
| LIMITED | 2 |  |
| SERVER_PUBLIC | 3 |  |
| GLOBAL_PUBLIC | 4 |  |


 

 

 



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

