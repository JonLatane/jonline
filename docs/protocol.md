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
    - [MediaMetadata](#jonline-MediaMetadata)
    - [MediaReference](#jonline-MediaReference)
  
- [messages.proto](#messages-proto)
    - [GetMessagesRequest](#jonline-GetMessagesRequest)
    - [GetMessagesResponse](#jonline-GetMessagesResponse)
    - [GetPushSubscriptionStatusRequest](#jonline-GetPushSubscriptionStatusRequest)
    - [GetPushSubscriptionStatusResponse](#jonline-GetPushSubscriptionStatusResponse)
    - [MarkMessagesReadRequest](#jonline-MarkMessagesReadRequest)
    - [MarkMessagesReadResponse](#jonline-MarkMessagesReadResponse)
    - [Message](#jonline-Message)
    - [MessageRead](#jonline-MessageRead)
    - [MessagingGroup](#jonline-MessagingGroup)
    - [PushSubscription](#jonline-PushSubscription)
    - [RegisterPushSubscriptionRequest](#jonline-RegisterPushSubscriptionRequest)
    - [SendMessageRequest](#jonline-SendMessageRequest)
    - [UnregisterPushSubscriptionRequest](#jonline-UnregisterPushSubscriptionRequest)
  
    - [MessageListingType](#jonline-MessageListingType)
  
- [groups.proto](#groups-proto)
    - [GetGroupsRequest](#jonline-GetGroupsRequest)
    - [GetGroupsResponse](#jonline-GetGroupsResponse)
    - [GetMembersRequest](#jonline-GetMembersRequest)
    - [GetMembersResponse](#jonline-GetMembersResponse)
    - [Group](#jonline-Group)
    - [Member](#jonline-Member)
  
    - [GroupListingType](#jonline-GroupListingType)
  
- [posts.proto](#posts-proto)
    - [DeletePostSyncDestinationRequest](#jonline-DeletePostSyncDestinationRequest)
    - [GetGroupPostsRequest](#jonline-GetGroupPostsRequest)
    - [GetGroupPostsResponse](#jonline-GetGroupPostsResponse)
    - [GetPostsRequest](#jonline-GetPostsRequest)
    - [GetPostsResponse](#jonline-GetPostsResponse)
    - [GroupPost](#jonline-GroupPost)
    - [Post](#jonline-Post)
    - [SyncPostRequest](#jonline-SyncPostRequest)
    - [UserPost](#jonline-UserPost)
  
    - [PostContext](#jonline-PostContext)
    - [PostListingType](#jonline-PostListingType)
    - [PostMediaLayout](#jonline-PostMediaLayout)
  
- [events.proto](#events-proto)
    - [AnonymousAttendee](#jonline-AnonymousAttendee)
    - [DeleteEventInstanceSyncDestinationRequest](#jonline-DeleteEventInstanceSyncDestinationRequest)
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
    - [SyncEventInstanceRequest](#jonline-SyncEventInstanceRequest)
    - [TimeFilter](#jonline-TimeFilter)
    - [UserAttendee](#jonline-UserAttendee)
  
    - [AttendanceStatus](#jonline-AttendanceStatus)
    - [EventListingType](#jonline-EventListingType)
  
- [server_configuration.proto](#server_configuration-proto)
    - [CustomHomePage](#jonline-CustomHomePage)
    - [CustomNavigationTab](#jonline-CustomNavigationTab)
    - [CustomNavigationTabSet](#jonline-CustomNavigationTabSet)
    - [EventSettings](#jonline-EventSettings)
    - [ExternalCDNConfig](#jonline-ExternalCDNConfig)
    - [FeatureSettings](#jonline-FeatureSettings)
    - [MediaSettings](#jonline-MediaSettings)
    - [PostSettings](#jonline-PostSettings)
    - [ServerColors](#jonline-ServerColors)
    - [ServerConfiguration](#jonline-ServerConfiguration)
    - [ServerInfo](#jonline-ServerInfo)
    - [ServerLogo](#jonline-ServerLogo)
    - [WebPushConfig](#jonline-WebPushConfig)
  
    - [AuthenticationFeature](#jonline-AuthenticationFeature)
    - [CalendarDisplayMode](#jonline-CalendarDisplayMode)
    - [NavigationTab](#jonline-NavigationTab)
    - [PrivateUserStrategy](#jonline-PrivateUserStrategy)
    - [WebUserInterface](#jonline-WebUserInterface)
  
- [federation.proto](#federation-proto)
    - [FacebookAuthConfig](#jonline-FacebookAuthConfig)
    - [FederatedAccount](#jonline-FederatedAccount)
    - [FederatedServer](#jonline-FederatedServer)
    - [FederationInfo](#jonline-FederationInfo)
    - [GetServiceVersionResponse](#jonline-GetServiceVersionResponse)
    - [XTwitterAuthConfig](#jonline-XTwitterAuthConfig)
  
- [sync.proto](#sync-proto)
    - [BlueskyAccount](#jonline-BlueskyAccount)
    - [DeleteSyncDestinationRequest](#jonline-DeleteSyncDestinationRequest)
    - [DeleteSyncSourceRequest](#jonline-DeleteSyncSourceRequest)
    - [FacebookPage](#jonline-FacebookPage)
    - [GetSyncDestinationsResponse](#jonline-GetSyncDestinationsResponse)
    - [GetSyncSourcesResponse](#jonline-GetSyncSourcesResponse)
    - [InstagramAccount](#jonline-InstagramAccount)
    - [MastodonAccount](#jonline-MastodonAccount)
    - [SyncDestination](#jonline-SyncDestination)
    - [SyncDestinationStatus](#jonline-SyncDestinationStatus)
    - [SyncSource](#jonline-SyncSource)
    - [ThreadsAccount](#jonline-ThreadsAccount)
    - [XTwitterAccount](#jonline-XTwitterAccount)
  
- [ai_model_providers.proto](#ai_model_providers-proto)
    - [AIModelProvider](#jonline-AIModelProvider)
    - [AIModelProviderGrant](#jonline-AIModelProviderGrant)
    - [AnthropicCredentials](#jonline-AnthropicCredentials)
    - [AvailableAIModel](#jonline-AvailableAIModel)
    - [DeleteAIModelProviderRequest](#jonline-DeleteAIModelProviderRequest)
    - [DigitalOceanCredentials](#jonline-DigitalOceanCredentials)
    - [GeminiCredentials](#jonline-GeminiCredentials)
    - [GenerateMediaRequest](#jonline-GenerateMediaRequest)
    - [GetAIModelProvidersResponse](#jonline-GetAIModelProvidersResponse)
    - [GrantAIModelProviderRequest](#jonline-GrantAIModelProviderRequest)
    - [OpenAICredentials](#jonline-OpenAICredentials)
    - [RevokeAIModelProviderRequest](#jonline-RevokeAIModelProviderRequest)
  
    - [AIModelCapability](#jonline-AIModelCapability)
  
- [Scalar Value Types](#scalar-value-types)



<a name="jonline-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## jonline.proto


 

 

 


<a name="jonline-Jonline"></a>

### Jonline
[Jonline](https://github.com/JonLatane/jonline) is a social media protocol with support for Users (and Follows), Media, Posts, Events, Groups, and Messages. It is designed to be federated, 
but does not require federation to be a useful next-gen forum type solution.
It is designed to be used with a variety of frontends, including web, mobile, and desktop applications. It interoperates across numerous ports, protocols, and formats, including
gRPC, HTTP, HTTPS, and ICS/iCal, and is designed to link with SMTP via Stalwart (and other SMTP servers/providers), Facebook Page APIs for post ing Events, and more.
Essentially, your server is your own customizable, self-contained social network.

Jonline is designed to be easy to run and deploy yourself with a [2 minute setup with Homebrew](#2-minute-startup-with-homebrew) and [3 minute setup on Linux](#3-minute-startup-on-linux),
[images](https://hub.docker.com/r/jonlatane/jonline/tags) on [DockerHub](https://hub.docker.com/r/jonlatane/jonline_preview_generator/tags) and deployment to your K8s clusters available via
a simple but powerful `Makefile`-based design language.

### Ports &amp; Protocols
Jonline servers interact across several ports:
* [gRPC (27707)](#grpc-api) - The main Jonline gRPC API. This is the primary port for all Jonline clients. It may or may not be TLS-enabled (443).
     * Clients are expected to negotiate the gRPC host via the [`backend_host` HTTP endpoint (see below)](#http-based-client-host-negotiation-for-external-cdns) on port 80/443.
* [HTTP (80, 8000, 27705), HTTPS (443)](#http-endpoints) - The main Jonline HTTP API. This is used for some endpoints, including media upload/download, and for negotiating the gRPC host.
     * Port 443 will serve up a secure HTTPS server. If it fails to startup, Jonline handles this gracefully and degrades to plain HTTP.
     * Port 80 will serve up either an unsecured set of Jonline&#39;s HTTP endpoints, or a redirect to the HTTPS/443 server if that one launched successfully.
     * Port 8000 *always* serves up an unsecured Jonline UI, in case something goes horribly wrong with 80 and 443. It can probably not be exposed in your load balancer/to the web.
     * Port 27705 is an unsecured HTTP server meant for communication with other non-web facing services on your computer or in your cluster. It should not be exposed to the web.
         * Currently this just has an `/email` endpoint. It is designed for [email/SMTP support via an integration with Stalwart](https://github.com/JonLatane/jonline/tree/main/deploys/email).

### API Design Notes
#### Moderation and Visibility
Jonline APIs are designed to support [`Moderation`](#jonline-Moderation) and [`Visibility`](#jonline-Visibility) controls at the level of individual entities. However, to keep things
DRY, moderation and visibility controls are only implemented for [`User`](#jonline-User)s, [`Media`](#jonline-Media), [`Group`](#jonline-Group)s, and [`Post`](#jonline-Post)s.

[`Event`](#jonline-Event)s and future [`Post`](#jonline-Post)-like types simply use the same implementation as their contained [`Post`](#jonline-Post)s. The intent here is to maximize
both shared code and implementation robustness.

#### Composition Over Inheritance
Jonline&#39;s APIs are designed using composition over inheritance. For instance, an [`Event`](#jonline-Event) contains
a [`Post`](#jonline-Post) rather than extending it. This pattern fits well all the way from the data model (very boring, safe, and normalized), 
through Rust code implementing APIs, to both functional React code and more-OOP Flutter code equally well.

#### Predictable Atomicity
The use of composition over inheritance also means that Jonline APIs can be *predictably* non-atomic based on their compositional structure.
For instance, [`UpdatePost`](#grpc-api-UpdatePost) is fully atomic.

[`UpdateEvent`](#grpc-api-UpdateEvent), however, is non-atomic. Given that an [`Event`](#jonline-Event) has a [`Post`](#jonline-Post) and many [`EventInstance`](#jonline-EventInstance)s,
[`UpdateEvent`](#grpc-api-UpdateEvent) is implemented as a composition of four other RPCs -- each independently callable and individually atomic --
run in a fixed order: [`UpdateEventDetails`](#grpc-api-UpdateEventDetails) (which itself first updates the [`Event`](#jonline-Event)&#39;s own [`Post`](#jonline-Post)
atomically, literally calling the [`UpdatePost`](#grpc-api-UpdatePost) RPC), then [`CreateNewEventInstances`](#grpc-api-CreateNewEventInstances),
[`UpdateEventInstances`](#grpc-api-UpdateEventInstances), and finally [`DeleteRemovedEventInstances`](#grpc-api-DeleteRemovedEventInstances).
Create must run before Delete so that a request which both drops an old [`EventInstance`](#jonline-EventInstance) and adds a new one never transiently
leaves the [`Event`](#jonline-Event) with zero instances.

Because moderation/visibility lives at the [`Post`](#jonline-Post) level, and [`UpdateEventDetails`](#grpc-api-UpdateEventDetails) runs first, this means that a developer error in the
later [`EventInstance`](#jonline-EventInstance)-processing steps cannot prevent visibility and moderation changes from being made in Events, even if there are errors elsewhere.
This should prove a robust pattern for any future entities intended to be shareable at a Group level with visibility and
moderation controls (for instance, `Sheet`, `SharedExpenseReport`, `SharedCalendar`, etc.). The entire architecture should promote this
approach to predictable atomicity.

### Core Types
Jonline&#39;s data model centers around a handful of top-level types, most of which carry their own
[`Visibility`](#jonline-Visibility) and [`Moderation`](#jonline-Moderation) state and can be organized into
[`Group`](#jonline-Group)s.

#### ServerConfiguration
Jonline incorporates server configuration, including fairly deep customization of the end-user UI/UX, as perhaps its *most* primitive type.
[`ServerConfiguration`](#jonline-ServerConfiguration) is unlike most of the highly-normalized, minimalist types in the Jonline protocol,
and is more like a document than a row in a database. (That said, every [`ServerConfiguration`](#jonline-ServerConfiguration) change *is* a row in a database, meaning
reverting broken configurations is easy.)

Any client using the Jonline protocol is basically expected to follow a flow of &#34;get service version, then [`ServerConfiguration`](#jonline-ServerConfiguration),
then worry about auth, then finally about retrieving anything else.&#34;

##### Server Info and Theme
[`ServerInfo`](#jonline-ServerInfo) (`server_info`) carries the server&#39;s public-facing identity: `name`,
`short_name`, `description`, `privacy_policy` and `media_policy` text shown during account creation and on the
`/about` page, a multi-size [`ServerLogo`](#jonline-ServerLogo) (separate light/dark, square/wide media IDs), a
[`ServerColors`](#jonline-ServerColors) scheme (primary/navigation accents plus author/admin/moderator name
colors), and `web_user_interface` choosing which UI a browser is served (React/Tamagui by default, or the Elm
SPA/Flutter Web alternatives).

##### Custom Tabs
[`CustomNavigationTabSet`](#jonline-CustomNavigationTabSet) (`custom_tabs`) lets a server admin override the Elm
UI&#39;s default navigation. `home` (a [`CustomHomePage`](#jonline-CustomHomePage)) replaces `/` itself -- a
predefined tab or a specific Post, optionally with Posts pinned above its content and/or an Events strip shown
above it; `tabs` (repeated [`CustomNavigationTab`](#jonline-CustomNavigationTab)) replaces the
`EVENTS_TAB`/`POSTS_TAB`/`PEOPLE_TAB`/`ABOUT_TAB` set entirely, each pinned to its own custom URL (`path`). Each
`CustomNavigationTab` targets either a predefined [`NavigationTab`](#jonline-NavigationTab), a Post ID, or
(path-only) a user profile, with its own emoji- or Media-backed icon and optional title override. `path` is
fully live -- the Elm SPA actually routes it (`Pages.UsernameOrCustomTab_`), not just previews it -- except for
the built-in `/events`, `/posts`, `/people`, and `/about` paths themselves, which stay reserved for their own
matching predefined tab and can&#39;t be remapped elsewhere.

##### Anonymous, Default, and Basic User Permission Sets
Three [`Permission`](#jonline-Permission) lists set the server&#39;s baseline access, each enforced independently of
any per-User/per-Group grants: `anonymous_user_permissions` (what a logged-out visitor may do -- only the
`VIEW_*` permissions are valid here), `default_user_permissions` (what every new account starts with), and
`basic_user_permissions` (the superset a user holding `GRANT_BASIC_PERMISSIONS` may hand out to others). Granting
`GLOBAL_PUBLIC` as a feature&#39;s `default_visibility` (see `people_settings`/`group_settings`/`post_settings`/
`event_settings` below) requires the matching `PUBLISH_*_GLOBALLY` permission to actually be present in
`default_user_permissions`.

##### Federation Settings
[`FederationInfo`](#jonline-FederationInfo) (`federation_info`) is where all federation and social-sync
credentials live.

###### Other Jonline servers
`servers` (repeated [`FederatedServer`](#jonline-FederatedServer)) recommends other Jonline hosts to clients,
each optionally `configured_by_default` (client should enable/configure it automatically) and/or
`pinned_by_default` (client should pin its Events/Posts alongside the &#34;main&#34; server&#39;s).

###### Facebook API Keys
`facebook_auth_config` (a [`FacebookAuthConfig`](#jonline-FacebookAuthConfig), `app_id`/`app_secret`) registers
this server&#39;s Facebook App, enabling users to connect Facebook Page and Instagram Business
[`SyncDestination`](#jonline-SyncDestination)s. `app_secret` is write-only/never serialized back to clients;
admins set/rotate it via [`ConfigureServer`](#grpc-api-ConfigureServer) (i.e. the same admin UI form that
manages the rest of [`ServerConfiguration`](#jonline-ServerConfiguration)) -- the secret is simply never echoed
back in subsequent [`GetServerConfiguration`](#grpc-api-GetServerConfiguration) responses.

###### X (Twitter) API Keys
`x_twitter_auth_config` (an [`XTwitterAuthConfig`](#jonline-XTwitterAuthConfig), `client_id`/`client_secret`)
registers this server&#39;s X Developer App, enabling users to connect X [`SyncDestination`](#jonline-SyncDestination)s
-- until set, X SyncDestinations fail with `x_twitter_app_not_configured`. `client_secret` is write-only/never
serialized back to clients, set/rotated the same way as the Facebook API keys above.

##### Web Push Configuration
[`WebPushConfig`](#jonline-WebPushConfig) (`web_push_config`) holds the server&#39;s VAPID keypair for Web Push
notifications: `public_vapid_key` is served to clients so they can subscribe, while `private_vapid_key` signs
outgoing pushes and is *never* serialized to clients -- like the federation secrets above, admins set/rotate it
via [`ConfigureServer`](#grpc-api-ConfigureServer), not by editing the database directly.

##### CDN Configuration
[`ExternalCDNConfig`](#jonline-ExternalCDNConfig) (`external_cdn_config`) enables running Jonline behind a CDN
(e.g. Cloudflare&#39;s &#34;CNAME HTTPS Proxy&#34;): when set, the unsecured HTTP server (port 80) stops redirecting to
HTTPS and instead serves the Tamagui Web client directly, with `frontend_host`/`backend_host` telling the web
client which domains to use instead of `window.location.hostname` (Tamagui web only, for now). `secure_media`
plus its `media_ipv4_allowlist`/`media_ipv6_allowlist` are a (TODO, not yet enforced) way to restrict media
downloads on the unsecured server to the CDN&#39;s own IP ranges; `cdn_grpc` is a further (TODO) mode that would move
the gRPC server itself onto port 443 to ride along Cloudflare&#39;s gRPC support.

#### User
A [`User`](#jonline-User) is a Jonline account: username, real name, bio, avatar, contact methods, and
[`Permission`](#jonline-Permission)s, plus counts (followers, posts, events, etc.) and federation info (see
[Federated Profiles](#federated-profiles) above). A lighter-weight [`Author`](#jonline-Author) (just ID, username,
avatar, real name, permissions) is embedded on [`Post`](#jonline-Post)s, [`Message`](#jonline-Message)s, and similar
content types instead of a full [`User`](#jonline-User), to keep those payloads small.

##### Follows
A [`Follow`](#jonline-Follow) is one [`User`](#jonline-User) following another, optionally subject to the target&#39;s moderation
(i.e. approval). Mutual follows make two users &#34;friends.&#34; Follows also drive the `FOLLOWING_POSTS`/`FOLLOWING_EVENTS`
listing types and `LIMITED`-visibility content.

##### Memberships
A [`Membership`](#jonline-Membership) is a [`User`](#jonline-User)&#39;s membership (or pending join request/invitation)
in a [`Group`](#jonline-Group), tracking the user&#39;s [`Permission`](#jonline-Permission)s within the group plus separate group-side and user-side [`Moderation`](#jonline-Moderation)
(for join-approval flows). Returned as part of [`User`](#jonline-User)/[`Group`](#jonline-Group) payloads, and via [`Member`](#jonline-Member) when listing a Group&#39;s members.

##### SyncSources
While Federation is a first-class feature of Jonline, a [`User`](#jonline-User) can also own many
[`SyncSource`](#jonline-SyncSource)s - server-owned external origins to sync with other fediverse and less-open
platforms, pulling [`Event`](#jonline-Event)s and [`Post`](#jonline-Post)s in via a `oneof configuration` naming
which source type it is -- currently only an iCal subscription URL (`configuration.ics_subscription_url`), though
the `oneof` leaves room for other source types. This is a 1:(0 or 1) relationship: it&#39;s the parent
[`Event`](#jonline-Event) (not the [`EventInstance`](#jonline-EventInstance)) that gets synced in and tagged with
its source (`Event.sync_source`), since a single source can back many synced [`Event`](#jonline-Event)s but each
[`Event`](#jonline-Event) has at most one source it came from -- see the Event section below for how these attach.
A background job re-pulls each source on its own `sync_interval_seconds` cadence, recomputing
`event_count`/`event_instance_count` on every sync.

Sources are managed via [`GetSyncSources`](#grpc-api-GetSyncSources), [`CreateSyncSource`](#grpc-api-CreateSyncSource)
(requires `SYNC_EVENTS_FROM_ICS`, or Admin), [`UpdateSyncSource`](#grpc-api-UpdateSyncSource), and
[`DeleteSyncSource`](#grpc-api-DeleteSyncSource).

See also: [`SyncDestination`](#jonline-SyncDestination)

###### iCal
`configuration.ics_subscription_url` is the only source type today: a plain iCal (`.ics`) subscription URL. The
background job fetches and parses it on each sync, creating/updating one [`Event`](#jonline-Event) per iCal `VEVENT`
(keyed by the iCal UID, stored as `EventInstance.sync_source_instance_id`) and recomputing `event_count`/
`event_instance_count`. An `Event`&#39;s `sync_missing_since` is set the first time one of its instances stops
appearing in the feed, letting the owner decide whether that means it should be deleted. No auth/credentials are
supported yet -- only public iCal URLs.

##### SyncDestinations
A [`User`](#jonline-User) can also own many [`SyncDestination`](#jonline-SyncDestination)s - user-owned external
targets to push [`EventInstance`](#jonline-EventInstance)s and [`Post`](#jonline-Post)s out to (see the Event and
Post sections below for how these attach), via a `oneof configuration` naming which platform it is. This is a
many-to-many relationship: it&#39;s each [`EventInstance`](#jonline-EventInstance) or [`Post`](#jonline-Post) (not,
say, the parent [`Event`](#jonline-Event)) that syncs out, and each may push to several destinations at once,
tracked per-destination via the repeated `EventInstance.sync_destinations`/`Post.sync_destinations` (each a
[`SyncDestinationStatus`](#jonline-SyncDestinationStatus), carrying the destination&#39;s resulting post ID/URL and
last-synced time). Destinations are pushed to on demand rather than synced in bulk on an interval, so
`synced_event_instance_count`/`synced_post_count` are computed with a `COUNT` at request time instead of being
recomputed-and-stored. All API keys for these external platforms are stored in
[`ServerConfiguration`](#jonline-ServerConfiguration)&#39;s `federation_info`.

Destinations are managed via [`GetSyncDestinations`](#grpc-api-GetSyncDestinations),
[`CreateSyncDestination`](#grpc-api-CreateSyncDestination), [`UpdateSyncDestination`](#grpc-api-UpdateSyncDestination),
and [`DeleteSyncDestination`](#grpc-api-DeleteSyncDestination) -- each gated on the `SYNC_EVENTS_TO_*`/
`SYNC_POSTS_TO_*` permission pair matching the destination&#39;s own platform (or Admin; see each platform&#39;s own
section below). Actually syncing (or un-syncing) a given [`EventInstance`](#jonline-EventInstance) or [`Post`](#jonline-Post) to a destination is a separate
step, via [`SyncEventInstance`](#grpc-api-SyncEventInstance)/
[`DeleteEventInstanceSyncDestination`](#grpc-api-DeleteEventInstanceSyncDestination) and
[`SyncPost`](#grpc-api-SyncPost)/[`DeletePostSyncDestination`](#grpc-api-DeletePostSyncDestination), gated the same
way (the `_EVENTS_`/`_POSTS_` half matching which RPC).

See also: [`SyncSource`](#jonline-SyncSource)

###### Facebook
`configuration.facebook_page` (a [`FacebookPage`](#jonline-FacebookPage)) is a connected Facebook Page.
Connecting one requires a short-lived user access token from client-side Facebook Login
(`FacebookPage.short_lived_user_access_token`), which the server exchanges for a long-lived Page access token; the
short-lived token is write-only and never populated back in responses. Gated on `SYNC_EVENTS_TO_FACEBOOK`/
`SYNC_POSTS_TO_FACEBOOK`.

###### Instagram
`configuration.instagram_account` (an [`InstagramAccount`](#jonline-InstagramAccount)) is a connected Instagram
Business/Creator account. Instagram posting is only possible for an account linked to a Facebook Page, so
connecting one reuses the exact same Facebook Login flow/app credentials as Facebook above -- the server exchanges
the token for the chosen Page&#39;s access token, then looks up that Page&#39;s linked Instagram Business account
(`instagram_business_account_id`). Unlike Facebook, Instagram&#39;s Graph API has no text-only post type; syncing a
[`Post`](#jonline-Post)/[`EventInstance`](#jonline-EventInstance) with no attached media fails with `instagram_requires_media`. Gated on
`SYNC_EVENTS_TO_INSTAGRAM`/`SYNC_POSTS_TO_INSTAGRAM`.

###### Mastodon
`configuration.mastodon_account` (a [`MastodonAccount`](#jonline-MastodonAccount)) is a connected Mastodon
account, on any instance the user names (`instance_host`) -- there&#39;s no single app to register the way
Facebook/Instagram have one, so connecting one is a user-pasted Personal Access Token
(`MastodonAccount.access_token`, generated on the user&#39;s own instance under Preferences &gt; Development) rather than
an OAuth popup. Gated on `SYNC_EVENTS_TO_MASTODON`/`SYNC_POSTS_TO_MASTODON`.

###### Bluesky
`configuration.bluesky_account` (a [`BlueskyAccount`](#jonline-BlueskyAccount)) is a connected Bluesky (AT
Protocol) account. Connecting one is a user-supplied &#34;App Password&#34; (`BlueskyAccount.app_password`, generated at
Settings &gt; App Passwords -- not the account&#39;s main password) rather than an OAuth popup. Gated on
`SYNC_EVENTS_TO_BLUESKY`/`SYNC_POSTS_TO_BLUESKY`.

###### X (Twitter)
`configuration.x_twitter_account` (an [`XTwitterAccount`](#jonline-XTwitterAccount)) is a connected X account. Requires this
server to have a registered X Developer App configured (`FederationInfo.x_twitter_auth_config`) -- until an admin
sets one, every RPC touching an [`XTwitterAccount`](#jonline-XTwitterAccount) destination fails with `x_twitter_app_not_configured`. Once
configured, connecting is an OAuth 2.0 Authorization Code &#43; PKCE flow at x.com (`response_type=code`, like
Threads, but with a `code_challenge`/`code_verifier` pair X requires and Threads doesn&#39;t) -- the server exchanges
the code for a short-lived access token (2 hour expiry) plus a refresh token, transparently refreshing before
each post. Only image media is uploaded today; video is not yet supported (see `XTwitterAccount`&#39;s own doc).
Gated on `SYNC_EVENTS_TO_X_TWITTER`/`SYNC_POSTS_TO_X_TWITTER`.

###### Threads
`configuration.threads_account` (a [`ThreadsAccount`](#jonline-ThreadsAccount)) is a connected Threads account.
Threads API is a product added to this server&#39;s *existing* Facebook App (see [`FacebookAuthConfig`](#jonline-FacebookAuthConfig)) rather than a
separately-registered app, but its OAuth flow is otherwise its own: authorization happens at threads.net (not
facebook.com) using `response_type=code` rather than Facebook&#39;s implicit `response_type=token`, with no &#34;choose a
Page&#34; step -- it directly authorizes the user&#39;s own Threads account. The server exchanges the code for a
short-lived token, then a long-lived one (~60 day expiry, refreshable via `grant_type=th_refresh_token` -- not yet
implemented, so a connected destination needs reconnecting after ~60 days). Unlike Instagram, Threads supports
text-only posts. Gated on `SYNC_EVENTS_TO_THREADS`/`SYNC_POSTS_TO_THREADS`.

##### AIModelProviders
A [`User`](#jonline-User) can also own many [`AIModelProvider`](#jonline-AIModelProvider)s -
connections to external AI model APIs (e.g. a Gemini or OpenAI API key) - and grant other users metered access to
them via [`AIModelProviderGrant`](#jonline-AIModelProviderGrant)s. See `ai_model_providers.proto` and the
AIModelProvider section below. Which models are actually available, and what each can do
([`AIModelCapability`](#jonline-AIModelCapability)), is a hand-maintained catalog (no provider exposes a stable
&#34;list models&#34; API to build this from at request time) - see
[`backend/src/logic/ai_model_catalog.rs`](https://github.com/JonLatane/jonline/blob/main/backend/src/logic/ai_model_catalog.rs)
on GitHub for the actual source of truth.

#### AIModelProvider
An [`AIModelProvider`](#jonline-AIModelProvider) is a user-owned connection to an external AI model API (e.g. a
Gemini API key), via a `oneof provider` naming which service it is -- structurally similar to
[`SyncDestination`](#jonline-SyncDestination)/[`SyncSource`](#jonline-SyncSource), but rather than pushing/pulling
content, it&#39;s metered *access* an owner can share out to other users of this server. As with
[`SyncDestination`](#jonline-SyncDestination)&#39;s platform credentials, the actual API key is write-only -- accepted
on [`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider)/[`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider)
but never populated back in a response.

Providers are managed via [`GetAIModelProviders`](#grpc-api-GetAIModelProviders),
[`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider) (requires `CREATE_AI_MODEL_PROVIDERS`, or Admin),
[`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider), and [`DeleteAIModelProvider`](#grpc-api-DeleteAIModelProvider)
-- each gated self-or-Admin, the same shape as [`SyncDestination`](#jonline-SyncDestination)&#39;s RPCs.

##### Gemini
`provider.gemini_credentials` (a [`GeminiCredentials`](#jonline-GeminiCredentials)) is a Google Gemini API
connection (`ai.google.dev/gemini-api`), used for image generation/editing (e.g. generating Event posters) via
its Interactions API.

##### OpenAI
`provider.openai_credentials` (an [`OpenAICredentials`](#jonline-OpenAICredentials)) is an OpenAI API connection
(`platform.openai.com/docs/guides/image-generation`), used for image generation/editing via its Images API (GPT
Image models).

##### Anthropic
`provider.anthropic_credentials` (an [`AnthropicCredentials`](#jonline-AnthropicCredentials)) is reserved for a
connected Anthropic API, but **not yet creatable** -- Anthropic doesn&#39;t offer an image generation API, so it&#39;s
defined only for forward compatibility.

##### DigitalOcean
`provider.digitalocean_credentials` (a [`DigitalOceanCredentials`](#jonline-DigitalOceanCredentials)) is a
DigitalOcean Gradient AI Platform / Serverless Inference connection (`docs.digitalocean.com/products/inference`),
used for image *generation only* (no editing -- DigitalOcean&#39;s Serverless Inference API has no
`/v1/images/edits`-equivalent endpoint) via its OpenAI-Images-API-shaped `/v1/images/generations` endpoint (GPT
Image and Stable Diffusion models, re-hosted under DigitalOcean&#39;s own billing).

##### AIModelProviderGrants
A provider&#39;s owner may share metered access to it with other users via
[`AIModelProviderGrant`](#jonline-AIModelProviderGrant)s, each carrying a `tokens_remaining` budget for that grantee.
Granted/reset via [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider) (upserted on the unique
`(ai_model_provider_id, grantee)` pair -- granting again *resets*, rather than adds to, `tokens_remaining`) and
removed via [`RevokeAIModelProvider`](#grpc-api-RevokeAIModelProvider). Unlike every other RPC pair in this section,
these two are **owner-only, with no Admin override** -- an Admin may manage the provider record itself, but only
its owner may hand out access to it.

#### Media
[`Media`](#jonline-Media) represents an uploaded (or server-generated) photo or video. Unlike other types, Media
content itself is *not* served over gRPC - it&#39;s uploaded/downloaded via plain HTTP (`POST`/`GET /media`) - while
its metadata (content type, name, visibility, moderation) is managed like any other Jonline type. Other messages
(like `User.avatar`, `Group.avatar`, and `Post.media`) reference Media via the lightweight [`MediaReference`](#jonline-MediaReference) type.

#### Post
[`Post`](#jonline-Post) is Jonline&#39;s fundamental content/building-block type: it&#39;s what actually carries a
title/link/content body, visibility, and moderation, and is reused (via [`PostContext`](#jonline-PostContext)) as the backing data for
replies, [`Event`](#jonline-Event)s, and [`EventInstance`](#jonline-EventInstance)s alike. Posts can be replied to (threaded via
`reply_to_post_id`), cross-posted to [`Group`](#jonline-Group)s ([`GroupPost`](#jonline-GroupPost)), and shared directly with users ([`UserPost`](#jonline-UserPost)).

##### GroupPosts
A [`GroupPost`](#jonline-GroupPost) is the cross-posting of a [`Post`](#jonline-Post) into a [`Group`](#jonline-Group), carrying the group-specific
moderation status and who shared it, separately from the Post&#39;s own (author-set) visibility/moderation.

##### UserPosts
A [`UserPost`](#jonline-UserPost) is a &#34;direct share&#34; of a [`Post`](#jonline-Post) to a [`User`](#jonline-User) (see also `DIRECT`
[`Visibility`](#jonline-Visibility)). Currently unused/unimplemented.

##### SyncDestinations
A [`Post`](#jonline-Post) may also be synced (cross-posted) out to a user-owned
[`SyncDestination`](#jonline-SyncDestination) (e.g. a connected Facebook Page), the same mechanism
[`EventInstance`](#jonline-EventInstance)s use (see below) - each Post may push to several destinations at once, tracked via the
repeated `Post.sync_destinations` (each a [`SyncDestinationStatus`](#jonline-SyncDestinationStatus)).

#### Event
An [`Event`](#jonline-Event) is a wrapper for *at least two* [`Post`](#jonline-Post)s. It always has its own top-level [`Post`](#jonline-Post)
(`PostContext.EVENT`, holding the event&#39;s overall title/description) *and* it must have at least one
[`EventInstance`](#jonline-EventInstance) (see below), each of which in turn must have its own [`Post`](#jonline-Post)
(`PostContext.EVENT_INSTANCE`, carrying that instance&#39;s start/end time, [`Location`](#jonline-Location), and optional per-instance
title/link/content override). So the smallest possible Event already backs 2 Posts, and events with recurring/multiple
instances back one Post per instance beyond that.

##### EventInstances
An [`EventInstance`](#jonline-EventInstance) is the actual time-boxed occurrence of an [`Event`](#jonline-Event) -
it carries the `starts_at`/`ends_at` timestamps and optional [`Location`](#jonline-Location) that the parent [`Event`](#jonline-Event) itself does not have.
An [`Event`](#jonline-Event) with zero instances is meaningless (no time or place to attach to), so every [`Event`](#jonline-Event) must have at least one.

    - **EventAttendances**: An [`EventAttendance`](#jonline-EventAttendance) (an &#34;RSVP&#34;) tracks one attendee&#39;s status
    (`INTERESTED`, `REQUESTED`, `GOING`, `NOT_GOING`) for a specific [`EventInstance`](#jonline-EventInstance). Attendees may be logged-in [`User`](#jonline-User)s
    or anonymous (tracked via [`AnonymousAttendee`](#jonline-AnonymousAttendee) plus an `auth_token`), and are subject to their own [`Moderation`](#jonline-Moderation),
    independent of the Event&#39;s/Instance&#39;s own Post moderation.

    - **SyncSource**: It&#39;s actually the parent [`Event`](#jonline-Event) (not the [`EventInstance`](#jonline-EventInstance)) that can be synced *in* from a
    user-owned [`SyncSource`](#jonline-SyncSource) (e.g. an iCal subscription). The relationship is
    1:(0 or 1): a single source can back many synced [`Event`](#jonline-Event)s, but each [`Event`](#jonline-Event) has *at most one* source it came from
    (`Event.sync_source` is a single optional field, not repeated).

    - **SyncDestinations**: Conversely, it&#39;s each [`EventInstance`](#jonline-EventInstance) (not the parent [`Event`](#jonline-Event)) that syncs *out* to
    [`SyncDestination`](#jonline-SyncDestination)s (e.g. connected Facebook Pages) - the same mechanism [`Post`](#jonline-Post)s use
    (see above). Unlike [`SyncSource`](#jonline-SyncSource), this is the outlier&#39;s counterpart - a many-to-many relationship: each
    instance may push to several destinations at once, tracked per-destination via the repeated
    `EventInstance.sync_destinations` (each a [`SyncDestinationStatus`](#jonline-SyncDestinationStatus)), carrying
    the destination&#39;s resulting post ID/URL and last-synced time.

#### Group
A [`Group`](#jonline-Group) organizes [`User`](#jonline-User)s, [`Post`](#jonline-Post)s, and [`Event`](#jonline-Event)s together under shared visibility, moderation,
and permission defaults.

##### Memberships
A [`Membership`](#jonline-Membership) is a [`User`](#jonline-User)&#39;s membership (or pending join request/invitation)
in a [`Group`](#jonline-Group), tracking the user&#39;s [`Permission`](#jonline-Permission)s within the group plus separate group-side and user-side [`Moderation`](#jonline-Moderation)
(for join-approval flows). Returned as part of [`User`](#jonline-User)/[`Group`](#jonline-Group) payloads, and via [`Member`](#jonline-Member) when listing a Group&#39;s members.

##### GroupPosts
A [`GroupPost`](#jonline-GroupPost) is the cross-posting of a [`Post`](#jonline-Post) into a [`Group`](#jonline-Group), carrying the group-specific
moderation status and who shared it, separately from the Post&#39;s own (author-set) visibility/moderation.

#### Message
[`Message`](#jonline-Message) is Jonline&#39;s &#34;low trust&#34; messaging/email system, meant to let strangers on a server
make first contact (e.g. via email, with no account required) before moving to a more trusted channel. Admins have
open access to all Messages on a server.

Email support in Messages comes from the [Stalwart integration](#post-email-stalwart-email-integration) and requires 
a Stalwart server to be running and configured to forward emails to the Jonline server. Jonline provides tooling
to do this automatically, but it is completely optional.

##### MessagingGroup
A [`MessagingGroup`](#jonline-MessagingGroup) is the set of participants in a Message conversation. Every [`Message`](#jonline-Message)
belongs to one; if a client wasn&#39;t a visible recipient (e.g. they were BCC&#39;ed), the [`Message`](#jonline-Message) they receive omits it.

### Authentication
Jonline uses a standard OAuth2 flow (over gRPC) for authentication, with rotating `access_token`s and `refresh_token`s (both [`ExpirableToken`s](#jonline-ExpirableToken)).
Authenticated calls require an `access_token` in request metadata to be included / directly as the value of the
`authorization` header (no `Bearer ` prefix).
The `ExpirableToken` type allows clients to know ahead of time when their `access_token` and `refresh_token` are about to expire.

First, before *any* authentication is done, you should [resolve your backend host](#http-based-client-host-negotiation-for-external-cdns-get-backend_host),
and check its [`GetServiceVersion`](#grpc-api-GetServiceVersion) and [`GetServerConfiguration`](#grpc-api-GetServerConfiguration) RPCs.
Check whether you have the `CREATE_ACCOUNT` and/or `LOGIN` [`AuthenticationFeature`](#jonline-AuthenticationFeature)s in your [`ServerConfiguration`](#jonline-ServerConfiguration).

Next, use the [`CreateAccount`](#grpc-api-CreateAccount) or [`Login`](#grpc-api-Login) RPCs to fetch (and store) an initial
`refresh_token` and `access_token`. Clients should use the `access_token` until it expires,
then use the `refresh_token` to call the [`AccessToken`](#grpc-api-AccessToken) RPC for a new one. (The [`AccessToken`](#grpc-api-AccessToken) RPC
may, at random, also return a new `refresh_token`. If so, it should immediately replace the old
one in client storage.)

#### Federated Authentication
tl;dr: Lets you sign in to the `jon@bullcity.social` user on `jonline.io`, without ever entering your `bullcity.social`
credentials on `jonline.io`.

Elm-only feature (`frontends/elm-spa`) letting a user sign in to one Jonline server using an account they already
have (or are willing to create) on a *different* Jonline server, without either backend ever seeing a plaintext
token that isn&#39;t its own. It&#39;s pure browser-to-browser: two Elm SPA page routes
([`/auth/to/...`](#authtopublic_keyrequesting_host-sending-side) and
[`/auth/from/...`](#authfromencrypted_account_auth_tokens-receiving-side)) exchange
an encrypted pair of tokens via a full-page redirect; no gRPC/HTTP endpoint on either backend is involved beyond
the [`Login`](#grpc-api-Login) RPC itself (plus [`GetCurrentUser`](#grpc-api-GetCurrentUser) on the receiving side,
to hydrate everything else -- see step 6).

1. Say a user is on `jonline.io`, adding a new account, and enters `bullcity.social` as the server. Since that
isn&#39;t the current host, the Accounts panel offers a &#34;Sign in via bullcity.social&#34; button instead of (or alongside)
a normal username/password form.
2. Clicking it does a full-page navigation to `bullcity.social`, carrying `jonline.io`&#39;s ECDH public key (freshly
generated in-browser and persisted for this purpose) and its own hostname in the URL: `/auth/to/{public_key}@jonline.io`.
3. `bullcity.social` shows its own sign-in form (or, if already signed in there, a badge to reuse that session),
plus a &#34;Sign back in here&#34; checkbox, checked by default.
4. The user authenticates via the [`Login`](#grpc-api-Login) RPC. This always issues a *fresh* `refresh_token`/
`access_token` pair, reserved purely for transfer back to `jonline.io` -- it&#39;s never used to sign the browser into
`bullcity.social` itself. If &#34;Sign back in here&#34; is checked, a **second**, independent [`Login`](#grpc-api-Login)
call also runs, so `bullcity.social` gets its own local session too, and the two servers never end up sharing a
token pair. (Hence &#34;1-2 refresh tokens.&#34;)
5. Only `bullcity.social`&#39;s hostname and that fresh `refresh_token`/`access_token` pair are JSON-encoded and
encrypted to `jonline.io`&#39;s public key from step 2 (ephemeral ECDH &#43; HKDF &#43; AES-GCM -- see below) -- nothing else
about the account travels in the payload. The browser is then redirected back to `jonline.io` at
`/auth/from/{ciphertext}`.
6. `jonline.io` decrypts the payload with the private key it generated in step 2, calls
[`GetCurrentUser`](#grpc-api-GetCurrentUser) against `bullcity.social` with the decrypted `access_token` to hydrate
the rest of the account (user ID, username, avatar, permissions, etc. straight from `bullcity.social` itself
rather than trusting a client-supplied copy of them), then adds it to its Accounts panel and navigates the user
onward -- no confirmation step. Either way, the one-time keypair generated in step 2 is discarded and a fresh one
generated in its place, so it can&#39;t be reused for a second transfer.

See the two [Web UI](#authtopublic_keyrequesting_host-and-authfromencrypted_account_auth_tokens-receiving-side)
page routes below for the exact URL/crypto shape.

### Federation
Whereas other federated social networks (e.g. ActivityPub) have both client-server and server-server APIs,
Jonline only has client-server APIs. While server-to-server communication is possible, nothing but some
&#34;nice to have&#34; features require it, so it is not used.

#### Federated Servers
Jonline servers can recommend other servers to clients with the `federation_info` field (a [`FederationInfo` message](#jonline-FederationInfo)) in [`ServerConfiguration`](#jonline-ServerConfiguration).
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

Federated profiles are managed via the `federated_profiles` field (a `repeated` [`FederatedAccount`](#jonline-FederatedAccount)) in the [`User`](#jonline-User) message.

#### Federated Browsing
Jonline&#39;s protocols and UI are designed to work together to present a seamless UX for content from many types of communities. Users can add/remove servers
in a way that gives them control, transparency and trust. Meanwhile, server owners get extreme customization and useful integrations with social media
platforms.

#### Federated Messaging
Jonline&#39;s Elm Messaging UI is generally a multi-server federated messenger. The main limitation is that it can only receive push notifications
from one server. (This could be changed with VAPID key sharing, but is part of the VAPID protocol.)

### HTTP Endpoints
#### Internal HTTP server (27705)
##### `POST /email`: Stalwart Email Integration
Delivery endpoint called by the [Stalwart](https://stalw.art) mail server (see
[`deploys/email`](https://github.com/JonLatane/jonline/tree/main/deploys/email)&#39;s
[README](https://github.com/JonLatane/jonline/blob/main/deploys/email/README.md) for setup/architecture) once it
accepts an inbound message addressed to one of this Jonline instance&#39;s onboarded domains, turning it into a
[`Message`](#jonline-Message). It is **internal-only**: mounted solely on the unsecured 27705 server (never on
80/8000/443), has no authentication of its own, and trusts its caller completely -- that trust boundary is
expected to be enforced at the network layer (e.g. a `NetworkPolicy` restricting port 27705 to Stalwart&#39;s pod).

* **Request**: the body is Stalwart&#39;s `data`-stage [MTA Hook](https://stalw.art/docs/mta/filter/mtahooks/) JSON
payload (up to 50 MiB), not a raw MIME stream -- only the fields below are read, the rest of Stalwart&#39;s payload
(`context`, `envelope.from`, `message.serverHeaders`, `message.size`, ...) is ignored:
```json
{
  &#34;envelope&#34;: { &#34;to&#34;: [{ &#34;address&#34;: &#34;someone@yourdomain.com&#34; }] },
  &#34;message&#34;: {
    &#34;headers&#34;: [[&#34;Subject&#34;, &#34;Hello&#34;], [&#34;From&#34;, &#34;sender@example.com&#34;], [&#34;To&#34;, &#34;someone@yourdomain.com&#34;]],
    &#34;contents&#34;: &#34;Hello, World!\r\n&#34;
  }
}
```
Recipients come from `envelope.to[].address` -- deliberately the SMTP envelope, not the message&#39;s `To`/`Cc`
headers, since that&#39;s the only place Bcc&#39;d recipients show up at all. The message itself is reconstructed by
concatenating `message.headers` (each an unfolded `[name, value]` pair) with `message.contents` across a blank
line, which `mail_parser` then parses as the RFC822 message -- Stalwart only splits at the top-level header/body
boundary, so this still captures multipart bodies and attachments intact within `contents`. A body that isn&#39;t
valid JSON in this shape, or that doesn&#39;t reconstruct into a parseable MIME message, returns `400 Bad Request`;
an oversized body returns `413 Payload Too Large`.
* **Recipient resolution**: each envelope address&#39;s local part (before the `@`) is looked up as a username on this
server; addresses that don&#39;t match any user are silently skipped, since Stalwart is expected to have already
confirmed deliverability before calling this endpoint. If none match, the whole message is dropped and the
endpoint returns `404 Not Found`.
* **Storage**: matched recipients become a [`Message`](#jonline-Message) addressed to a
[`MessagingGroup`](#jonline-MessagingGroup) keyed on the `To`/`Cc` recipients only -- Bcc&#39;d recipients are excluded
from the group (so they stay invisible to everyone else on the thread) and instead recorded individually as `Bcc`
rows on the [`Message`](#jonline-Message). The [`Message`](#jonline-Message) has no `from_user_id`, since inbound email never has a local sender; its
parsed `from`/`to`/`cc` headers are stored alongside it, and the raw `.eml` is uploaded to the same MinIO store
used for [`Media`](#jonline-Media). Duplicate deliveries of the same `Message-ID` (Stalwart retries on transient failure) reuse the
existing [`Message`](#jonline-Message) row rather than storing/uploading a duplicate.
* **Response**: `200 OK` with a body of `{&#34;action&#34;: &#34;accept&#34;}` on success -- Stalwart&#39;s MTA Hook protocol parses
the response *body*, not just the status code, so this has to be the exact shape it expects
(see &lt;https://stalw.art/docs/mta/filter/mtahooks/&gt;) or Stalwart treats the call as a hook failure regardless of
status; combined with the `MtaHook`&#39;s `tempFailOnError: true`, that surfaces to the sending client as a
`451` temp-fail rather than anything indicating the real cause.

#### External HTTP servers (80, 8000, 443)
Note that, if the TLS server on port 443 starts up successfully, the server on port 80
will simply redirect to HTTPS.

The server on port 8000 will always serve up unsecured HTTP. It is up to server admins to block this
port if they find that necessary.

##### `GET /backend_host`: HTTP-based client host negotiation (for external CDNs)
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

##### `GET /robots.txt`: Robots
Generated on the fly (not a static file) from the request&#39;s `Host` header, publicly cacheable for 1 hour. Always
allows all crawling (`User-agent: * / Allow: /`) and points crawlers at `https://{host}/sitemap.xml`.

##### `GET /sitemap.xml`: Sitemap
Generated on the fly (not a static file) from the request&#39;s `Host` header, publicly cacheable for 1 hour. Lists a
fixed set of top-level, server-wide pages -- `/`, `/posts`, `/events`, `/people`, `/about`, `/about_jonline`,
`/flutter`, `/tamagui`, `/elm` -- plus any `CustomNavigationTabSet.tabs` paths configured on the server (excluding
the reserved `posts`/`events`/`people`/`about` paths, which are always included above), each qualified with the
request&#39;s `Host`. It also enumerates individual pages: every [`Post`](#jonline-Post) from an unauthenticated [`GetPosts`](#grpc-api-GetPosts) (the same
&#34;first page&#34; an anonymous visitor sees) as `/post/{id}`, and every [`Event`](#jonline-Event) instance from an unauthenticated
[`GetEvents`](#grpc-api-GetEvents) starting `EventSettings.calendar_lookback_days` (or 14, if unset) ago as `/event/{instance_id}`.
It does not (yet) enumerate individual [`User`](#jonline-User) pages.

##### `GET /favicon.ico`: ICO Favicon
Serves the server&#39;s configured logo (`ServerConfiguration.server_info.logo.square_media_id`, a [`Media`](#jonline-Media)
reference) as an `.ico`, publicly cacheable for 12 hours (`must-revalidate`), converting on the fly if the
stored rendition is a `.png`. If no logo is configured, falls back to the bundled Tamagui frontend&#39;s default
favicon instead. Whichever converted rendition of the logo is served, it&#39;s picked in size preference order
Medium, then Small, then Large, then the original upload if none of those conversions exist (favicons are small,
so there&#39;s no reason to prefer a bigger one).

##### `GET /favicon.png`: PNG Favicon
As `GET /favicon.ico` above, but serves (and if necessary converts to) `.png` instead.

##### `POST /media`: Upload Media
See the [Media](#jonline-Media) section for the [`Media`](#jonline-Media) type itself; this is how its bytes actually get in
(an `OPTIONS /media` variant also exists, solely to satisfy CORS preflight requests). *Authenticated* (via
`Authorization` header or a `jonline_access_token` cookie). Requires `Content-Type` and `Filename` headers; the
body is streamed directly to the object store, capped at 250 MiB -- note that a larger upload is silently
truncated to that cap rather than rejected, since nothing checks for completeness the way `POST /email` does --
at a path namespaced by uploader and request host (`user/{user_id}@{host}-{username}/{uuid}-{filename}`). A
[`Media`](#jonline-Media) row is created immediately at `GLOBAL_PUBLIC` visibility (video content types also get
a default `video_preview_time_ms`) and its ID returned as plain text -- there&#39;s no separate &#34;confirm&#34; step, and
no image/video conversion happens synchronously on this request (see the background media-conversion job).

##### `GET /media/{id}?size={original|small|medium|large}`: Download Media
(An `OPTIONS /media/{id}` variant also exists, solely to satisfy CORS preflight requests.) Publicly downloadable
-- **moderation/visibility/permission checks on read are not yet enforced** (a `TODO` in `media_file`&#39;s
implementation), so a [`Media`](#jonline-Media) ID is currently a bearer capability. `size` (default `medium`) selects a converted
rendition, falling back to the original upload if that conversion doesn&#39;t exist. The first request for a given
rendition lazily downloads it from the object store into a local on-disk cache; subsequent requests are served
from that cache. Cacheable for 12 hours (`must-revalidate`).

##### `GET /calendar.ics`: Server Calendar
Jonline events support iCalendar/RFC5545; only public events are included. &#34;Subscribe&#34; to a Jonline server at,
for instance, `https://jonline.io/calendar.ics` to get a calendar of all public events on the server. In the
Tamagui/React frontend, links to these endpoints are provided in the Upcoming Events section of the home page,
the Events page, and the user profile pages for all users with events in the last 3 months (or in the future).

##### `GET /calendar.ics?user_id={id}`: User Calendar
&#34;Subscribe&#34; to a user&#39;s calendar at, for instance, `https://jonline.io/calendar.ics?user_id=CruFm` to get a
calendar of all public events for that user.

### Web UI paths
Jonline serves three web frontends from the same backend: Tamagui (React/Next.js), Elm, and Flutter.

Tamagui and Elm share one page structure (below) and are always *both* reachable, explicitly, at `/tamagui/*`
and `/elm/*` respectively; unprefixed requests (`/`, `/posts`, `/post/{postId}`, etc.) render whichever of the
two the server&#39;s `ServerConfiguration.server_info.web_user_interface` selects (`ELM_SPA` picks Elm; every other
setting, including no preference at all, picks Tamagui). Elm is a genuine single-page app -- every Elm-served
path, prefixed or not, resolves to the same `index.html`, with in-app (client-side) routing taking over from
there -- whereas Tamagui&#39;s Next.js build is statically exported one HTML file per route, so the server picks
between actual distinct files below, each enriched with server-rendered, per-route social-preview
(`&lt;title&gt;`/`og:*`) tags before being served.

**Flutter does not participate in any of this.** It has no page structure of its own to speak of: no per-route
pages, no server-rendered social-preview metadata, and no unprefixed presence at all -- a server configured to
prefer it doesn&#39;t route &#34;/&#34; through the Tamagui/Elm machinery below and then render Flutter, it instead serves
Flutter&#39;s own `index.html` directly, bypassing that machinery entirely. Flutter is otherwise reached only at the
literal `/flutter` and `/flutter/*` paths, which serve its compiled static assets; from there, all further
in-app navigation is handled entirely client-side by Flutter&#39;s own router and is invisible to the server.

The shared Tamagui/Elm page structure, grouped the way the [Elm app&#39;s `Pages`
directory](https://github.com/JonLatane/jonline/tree/main/frontends/elm-spa/src/Pages) is (`{name}` denotes a
dynamic path segment; `[@{host}]` marks where a [federated](#federated-profiles) `{username}@{host}`-style
suffix is accepted for that segment):

#### `/`: Home
The community&#39;s latest activity.

#### `/posts`: Posts
The Posts listing.

##### `/post/{postId}[@{host}]`: Post
An individual [`Post`](#jonline-Post) -- including [`Event`](#jonline-Event)/[`EventInstance`](#jonline-EventInstance) posts and replies, which are [`Post`](#jonline-Post)s
themselves (see [Post](#post) above).

#### `/events`: Events
The Events listing.

#### `/[-._~:/?[]@!$&amp;&#39;()*&#43;,;%=]{postId}`: Short Post/Event URLs
A [`Post`](#jonline-Post) or [`Event`](#jonline-Event)/[`EventInstance`](#jonline-EventInstance), reached at its own `post.id` prefixed
with any single character a username/custom tab path could never legally start with (see
[`validate_username`](https://github.com/JonLatane/jonline/blob/main/backend/src/rpcs/validations/validate_fields.rs)&#39;s
own reserved-lead-character check) -- e.g. `jonline.io/:4rAfoSKAuJo` or `ato.band/~4rAfoSKAuJo`.
This is purely a shorter, friendlier alias for `/post/{postId}[@{host}]` or
`/event/{postId}[@{host}]` (whichever the id turns out to belong to) -- it renders exactly that
same content in place, without redirecting the address bar away from the short URL. `#` is
deliberately excluded from the reserved set: URL fragments never reach the server, so they
can&#39;t be used for this.

##### `/event/{postId}[@{host}]`: Event
An individual [`Event`](#jonline-Event), looked up by its own `post.id` or any of its [`EventInstance`](#jonline-EventInstance)s&#39; `post.id`s.

##### `/event_ai`: AI Event Importer
Tamagui-only, for now -- an AI-assisted bulk [`Event`](#jonline-Event) importer. Elm doesn&#39;t have this page yet.

#### `/people`: People
The People listing.

##### `/people/follow_requests`: Follow Requests
The current user&#39;s pending [`Follow`](#jonline-Follow) requests.

##### `/user/{userId}`: Profile
A [`User`](#jonline-User) profile looked up by (stable) user ID.

#### `/{custom_tab_or_username}`: User pages by username, or a custom tab
The same [`User`](#jonline-User) profile (and its Posts/Friends/Followers/Following sub-pages) as `/user/{userId}` above, but
looked up by the current `username` instead -- lighter-weight to link to, but less stable than `/user/{userId}`
since a username can change. This single path segment is also the server&#39;s last-resort catch-all, resolved in
order: first any actual matching build asset or other explicit route above (e.g. `/posts`, `/user/{userId}`)
wins outright; then, if none matched, an admin-configured custom tab path (see
[`CustomNavigationTab`](#jonline-CustomNavigationTab).path) -- e.g. a band mounting their Events
listing at `/gigs` -- wins over a same-named user; only then, last, is it looked up as a plain username. A small
set of reserved names can never be reached this way, only via `/user/{userId}`.

##### `/{username}/posts`: Posts
##### `/{username}/friends`: Friends
##### `/{username}/followers`: Followers
##### `/{username}/following`: Following

#### `/g/{shortname}`: Groups
A [`Group`](#jonline-Group)&#39;s pages. Tamagui-only for now -- the Elm frontend doesn&#39;t have Group pages yet.

##### `/g/{shortname}`: Home
##### `/g/{shortname}/posts`: Posts
##### `/g/{shortname}/p/{postId}[@{host}]`: Post
An individual [`Post`](#jonline-Post) cross-posted into the group.

##### `/g/{shortname}/events`: Events
##### `/g/{shortname}/e/{eventInstanceId}[@{host}]`: Event
##### `/g/{shortname}/members`: Members
##### `/g/{shortname}/m/{username}`: Member
An individual [`Member`](#jonline-Member)&#39;s details.

#### `/server/{serverIdentifier}`: Server
Information about a (possibly federated) Jonline server.

#### `/about`, `/about_jonline`: About
This server&#39;s own About page, and a general &#34;what is Jonline&#34; page.

#### `/auth/to/{public_key}@{requesting_host}` and `/auth/from/{encrypted_account_auth_tokens}`: Federated Sign-In
**Elm-only** -- unlike everything else in this section, these two paths have no Tamagui equivalent. They&#39;re Elm
SPA pages (served like any other SPA route -- under the `/elm` base path when the Elm frontend isn&#39;t the one
mounted at `/`) rather than backend/gRPC handlers, driving the
[Federated Authentication](#federated-authentication) flow entirely in-browser via a pair of full-page redirects
carrying an encrypted payload.

##### `/auth/to/{public_key}@{requesting_host}`: sending side
`Pages.Auth.To.Key_`. Reached only via the cross-origin redirect from step 2 above (built by the *requesting*
origin&#39;s Accounts panel), never linked to directly.
* **Path params**: `{public_key}` is the requesting origin&#39;s ECDH (P-256) public key, raw-exported and
base64url-encoded; `{requesting_host}` is that origin&#39;s own hostname. The two are joined with a literal `@`
(chosen because `@` never appears in the base64url/dot-joined ciphertext the
[`/auth/from`](#authfromencrypted_account_auth_tokens-receiving-side) page below expects, so the split is
unambiguous).
* **Query params**: `start_path` -- the app-relative path the user was on when they clicked &#34;Sign in via ...&#34;, so
they can be dropped back there after the round trip. Percent-encoded; passed through unchanged to the eventual
[`/auth/from`](#authfromencrypted_account_auth_tokens-receiving-side) redirect.
* **Behavior**: shows a sign-in form for *this* server (or a &#34;currently signed in as ...&#34; badge, if already
authenticated here), plus a &#34;Sign back in here&#34;/&#34;Also sign in here&#34; checkbox (checked by default). Submitting
calls the [`Login`](#grpc-api-Login) RPC (always a fresh login, never reusing stored tokens) to mint the transfer
tokens; if the checkbox is checked, a second independent [`Login`](#grpc-api-Login) call also signs the browser
into this server locally. `{requesting_host}`&#39;s hostname plus that fresh `refresh_token`/`access_token` pair are
then AES-GCM-encrypted to `{public_key}` (fresh ephemeral ECDH keypair per encryption, shared secret via
ECDH &#43; HKDF-SHA256, output `ephemeral_public_key.iv.ciphertext`, each part base64url) and the browser is
redirected to `https://{requesting_host}/auth/from/{ciphertext}?start_path={start_path}`.

##### `/auth/from/{encrypted_account_auth_tokens}`: receiving side
`Pages.Auth.From.EncryptedAccountAuthTokens_`, closing the loop from
[`/auth/to`](#authtopublic_keyrequesting_host-sending-side) above. Reached only via that redirect.
* **Path params**: `{encrypted_account_auth_tokens}` is the `ephemeral_public_key.iv.ciphertext` blob produced by
[`/auth/to`](#authtopublic_keyrequesting_host-sending-side).
* **Query params**: `start_path`, passed through unchanged from
[`/auth/to`](#authtopublic_keyrequesting_host-sending-side); defaults to `/` if missing.
* **Behavior**: decrypts `{encrypted_account_auth_tokens}` using the private key this origin generated when it
built the [`/auth/to`](#authtopublic_keyrequesting_host-sending-side) link (same ECDH &#43; HKDF-SHA256 &#43; AES-GCM
derivation, in reverse), yielding `bullcity.social`&#39;s hostname and its `refresh_token`/`access_token`. Calls
[`GetCurrentUser`](#grpc-api-GetCurrentUser) against that server with the decrypted `access_token` to hydrate the
rest of the account, then adds it straight to the local Accounts panel and navigates to `start_path` -- no
confirmation step (decryption succeeding is itself the authenticity check: the ciphertext is AEAD-encrypted to
this origin&#39;s own one-time private key, so a forged or replayed payload just fails to decrypt rather than
producing a wrong-but-valid account). If either step fails (bad decrypt, or the `GetCurrentUser` call itself),
an error is shown instead. Either way, once the flow completes (added, or failed), the one-time private key is
discarded and a fresh keypair generated, so it&#39;s single-use per completed/failed transfer.

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
| SendMessage | [SendMessageRequest](#jonline-SendMessageRequest) | [Message](#jonline-Message) | Sends a Message to one or more recipients (creating/reusing their MessagingGroup). *Publicly accessible **or** Authenticated.* Like [`CreatePost`](#grpc-api-CreatePost)/[`CreateEvent`](#grpc-api-CreateEvent), authentication (if any) is via a standard `access_token`; unauthenticated calls are simply sent with no `sender`. |
| GetMessages | [GetMessagesRequest](#jonline-GetMessagesRequest) | [GetMessagesResponse](#jonline-GetMessagesResponse) | Gets Messages. *Authenticated.* `PERSONAL_MESSAGES(_TEXT_SEARCH)` (and looking up a single Message/MessagingGroup) requires the `READ_PERSONAL_MESSAGES` permission and only returns Messages the current user sent or received. `ALL_SYSTEM_MESSAGES(_TEXT_SEARCH)` requires the `READ_ALL_SYSTEM_MESSAGES` permission and returns every Message on the server. |
| MarkMessagesRead | [MarkMessagesReadRequest](#jonline-MarkMessagesReadRequest) | [MarkMessagesReadResponse](#jonline-MarkMessagesReadResponse) | Marks one or more Messages as read (or unread) by the current user, e.g. every message in a thread once it&#39;s been opened. *Authenticated.* Only needs the recipient/sender access [`GetMessages`](#grpc-api-GetMessages) already requires for each Message -- no separate permission. Atomic: if the caller lacks access to *any* of `message_ids`, none of them are marked (matching `MarkMessagesReadRequest.message_ids`&#39; own doc), so a client never has to reconcile a partially-applied batch. |
| RegisterPushSubscription | [RegisterPushSubscriptionRequest](#jonline-RegisterPushSubscriptionRequest) | [PushSubscription](#jonline-PushSubscription) | Registers (or re-registers) a browser&#39;s Web Push subscription for the current user, so new Messages sent/delivered to them (in-app or via email) push a notification to it even while the browser tab is closed. *Authenticated.* Re-registering an already-registered `endpoint` (e.g. because `PushManager.subscribe()` refreshed its keys) updates it in place rather than erroring. No-ops (server-side; not surfaced as an error to the caller) if the server has no [`WebPushConfig`](#jonline-WebPushConfig) configured -- there&#39;s nothing to push notifications *with*. |
| UnregisterPushSubscription | [UnregisterPushSubscriptionRequest](#jonline-UnregisterPushSubscriptionRequest) | [.google.protobuf.Empty](#google-protobuf-Empty) | Unregisters a browser&#39;s Web Push subscription, e.g. on logout or when `PushManager.subscribe()` reports the subscription as no longer valid. *Authenticated.* Not an error if `endpoint` isn&#39;t currently registered to the calling user. |
| GetPushSubscriptionStatus | [GetPushSubscriptionStatusRequest](#jonline-GetPushSubscriptionStatusRequest) | [GetPushSubscriptionStatusResponse](#jonline-GetPushSubscriptionStatusResponse) | Checks whether the calling user specifically (not just &#34;some account on this browser&#34;) has a [`PushSubscription`](#jonline-PushSubscription) registered for `endpoint`. *Authenticated.* Exists because a browser only ever exposes its own subscription&#39;s `endpoint`/keys, never *who* on the server side is registered against it -- multiple local accounts on the same server can share one browser subscription (see [`RegisterPushSubscription`](#grpc-api-RegisterPushSubscription)&#39;s own doc comment), so knowing the endpoint alone isn&#39;t enough to know which of them are actually notified by it. |
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
| SyncPost | [SyncPostRequest](#jonline-SyncPostRequest) | [Post](#jonline-Post) | Syncs (cross-posts) a Post to a SyncDestination. *Authenticated* (destination owner, or Admin), requires `SYNC_POSTS_TO_FACEBOOK` (or Admin). |
| DeletePostSyncDestination | [DeletePostSyncDestinationRequest](#jonline-DeletePostSyncDestinationRequest) | [.google.protobuf.Empty](#google-protobuf-Empty) | Removes a Post&#39;s sync (cross-post) to a SyncDestination, the reverse of [`SyncPost`](#grpc-api-SyncPost). *Authenticated* (destination owner, or Admin), requires `SYNC_POSTS_TO_FACEBOOK` (or Admin). |
| GetGroupPosts | [GetGroupPostsRequest](#jonline-GetGroupPostsRequest) | [GetGroupPostsResponse](#jonline-GetGroupPostsResponse) | Get GroupPosts for a Post (and optional group). *Publicly accessible **or** Authenticated.* |
| CreateGroupPost | [GroupPost](#jonline-GroupPost) | [GroupPost](#jonline-GroupPost) | Cross-post a Post to a Group. *Authenticated.* |
| UpdateGroupPost | [GroupPost](#jonline-GroupPost) | [GroupPost](#jonline-GroupPost) | Group Moderators: Approve/Reject a GroupPost. *Authenticated.* |
| DeleteGroupPost | [GroupPost](#jonline-GroupPost) | [.google.protobuf.Empty](#google-protobuf-Empty) | Delete a GroupPost. *Authenticated.* |
| GetEvents | [GetEventsRequest](#jonline-GetEventsRequest) | [GetEventsResponse](#jonline-GetEventsResponse) | Gets Events. *Publicly accessible **or** Authenticated.* Unauthenticated calls only return Events of `GLOBAL_PUBLIC` visibility. |
| CreateEvent | [Event](#jonline-Event) | [Event](#jonline-Event) | Creates an Event. *Authenticated.* |
| UpdateEvent | [Event](#jonline-Event) | [Event](#jonline-Event) | Updates an Event. Automatically creates/updates/deletes child EventInstances of the Event. *Authenticated.* Since Events are more complex structures, [`UpdateEventDetails`](#grpc-api-UpdateEventDetails), [`CreateNewEventInstances`](#grpc-api-CreateNewEventInstances), [`UpdateEventInstances`](#grpc-api-UpdateEventInstances), and [`DeleteRemovedEventInstances`](#grpc-api-DeleteRemovedEventInstances) are provided as separate RPCs to break down what happens during this request. |
| DeleteEvent | [Event](#jonline-Event) | [Event](#jonline-Event) | (Soft) deletes a Event. Returns the deleted version of the Event. *Authenticated.* |
| UpdateEventDetails | [Event](#jonline-Event) | [Event](#jonline-Event) | Updates only the [`Event`](#jonline-Event)&#39;s top-level details and those of its [`Post`](#jonline-Post) (not any [`EventInstance`](#jonline-EventInstance)s or their [`Post`](#jonline-Post)s). *Authenticated.* |
| CreateNewEventInstances | [Event](#jonline-Event) | [Event](#jonline-Event) | Creates EventInstances in an existing Event for every EventInstance in the request that isn&#39;t already on the event. *Authenticated.* Any other instances in the request are ignored. |
| UpdateEventInstances | [Event](#jonline-Event) | [Event](#jonline-Event) | Updates EventInstances in an existing Event for every EventInstance in the request that&#39;s already on the event. Any other instances in the request are ignored. *Authenticated.* |
| DeleteRemovedEventInstances | [Event](#jonline-Event) | [Event](#jonline-Event) | Deletes EventInstances in an existing Event that aren&#39;t present in the input Event. *Authenticated.* |
| GetSyncSources | [User](#jonline-User) | [GetSyncSourcesResponse](#jonline-GetSyncSourcesResponse) | Gets a user&#39;s SyncSources. *Authenticated* (self, or Admin for any user). |
| CreateSyncSource | [SyncSource](#jonline-SyncSource) | [SyncSource](#jonline-SyncSource) | Creates a SyncSource for the current user. *Authenticated*, requires `SYNC_EVENTS_FROM_ICS` (or Admin). |
| UpdateSyncSource | [SyncSource](#jonline-SyncSource) | [SyncSource](#jonline-SyncSource) | Updates a SyncSource. *Authenticated* (owner, or Admin for any user&#39;s), requires `SYNC_EVENTS_FROM_ICS` (or Admin). |
| DeleteSyncSource | [DeleteSyncSourceRequest](#jonline-DeleteSyncSourceRequest) | [.google.protobuf.Empty](#google-protobuf-Empty) | Deletes a SyncSource. *Authenticated* (owner, or Admin). |
| GetSyncDestinations | [User](#jonline-User) | [GetSyncDestinationsResponse](#jonline-GetSyncDestinationsResponse) | Gets a user&#39;s SyncDestinations. *Authenticated* (self, or Admin for any user). |
| CreateSyncDestination | [SyncDestination](#jonline-SyncDestination) | [SyncDestination](#jonline-SyncDestination) | Creates a SyncDestination for the current user. *Authenticated*, requires `SYNC_EVENTS_TO_FACEBOOK` or `SYNC_POSTS_TO_FACEBOOK` (or Admin). |
| UpdateSyncDestination | [SyncDestination](#jonline-SyncDestination) | [SyncDestination](#jonline-SyncDestination) | Updates a SyncDestination. *Authenticated* (owner, or Admin for any user&#39;s), requires `SYNC_EVENTS_TO_FACEBOOK` or `SYNC_POSTS_TO_FACEBOOK` (or Admin). |
| DeleteSyncDestination | [DeleteSyncDestinationRequest](#jonline-DeleteSyncDestinationRequest) | [.google.protobuf.Empty](#google-protobuf-Empty) | Deletes a SyncDestination. *Authenticated* (owner, or Admin). |
| SyncEventInstance | [SyncEventInstanceRequest](#jonline-SyncEventInstanceRequest) | [EventInstance](#jonline-EventInstance) | Syncs (cross-posts) an EventInstance to a SyncDestination. *Authenticated* (destination owner, or Admin), requires `SYNC_EVENTS_TO_FACEBOOK` (or Admin). |
| DeleteEventInstanceSyncDestination | [DeleteEventInstanceSyncDestinationRequest](#jonline-DeleteEventInstanceSyncDestinationRequest) | [.google.protobuf.Empty](#google-protobuf-Empty) | Removes an EventInstance&#39;s sync (cross-post) to a SyncDestination, the reverse of [`SyncEventInstance`](#grpc-api-SyncEventInstance). *Authenticated* (destination owner, or Admin), requires `SYNC_EVENTS_TO_FACEBOOK` (or Admin). |
| GetAIModelProviders | [User](#jonline-User) | [GetAIModelProvidersResponse](#jonline-GetAIModelProvidersResponse) | Gets a user&#39;s AIModelProviders. *Authenticated* (self, or Admin for any user). |
| CreateAIModelProvider | [AIModelProvider](#jonline-AIModelProvider) | [AIModelProvider](#jonline-AIModelProvider) | Creates an AIModelProvider for the current user. *Authenticated*, requires `CREATE_AI_MODEL_PROVIDERS` (or Admin). |
| UpdateAIModelProvider | [AIModelProvider](#jonline-AIModelProvider) | [AIModelProvider](#jonline-AIModelProvider) | Updates an AIModelProvider&#39;s name, provider, or credentials. *Authenticated* (owner, or Admin for any user&#39;s). |
| DeleteAIModelProvider | [DeleteAIModelProviderRequest](#jonline-DeleteAIModelProviderRequest) | [.google.protobuf.Empty](#google-protobuf-Empty) | Deletes an AIModelProvider (and its AIModelProviderGrants). *Authenticated* (owner, or Admin). |
| GrantAIModelProvider | [GrantAIModelProviderRequest](#jonline-GrantAIModelProviderRequest) | [AIModelProviderGrant](#jonline-AIModelProviderGrant) | Grants (or resets) another user&#39;s metered access to one of the current user&#39;s AIModelProviders. *Authenticated*, owner-only (no Admin override). |
| RevokeAIModelProvider | [RevokeAIModelProviderRequest](#jonline-RevokeAIModelProviderRequest) | [.google.protobuf.Empty](#google-protobuf-Empty) | Revokes another user&#39;s access to one of the current user&#39;s AIModelProviders. *Authenticated*, owner-only (no Admin override). |
| GenerateMedia | [GenerateMediaRequest](#jonline-GenerateMediaRequest) | [Media](#jonline-Media) | Generates (or edits, given reference `media_ids`) an image via one of the current user&#39;s AvailableAIModels, storing it as a new Media and, if `target` is set, attaching it to that Post/Event. *Authenticated* -- caller must own or have been granted access to the chosen AIModelProvider, and (if `target` is set) have edit access to that Post/Event. A grantee (never the provider&#39;s own owner) spends real AIModelProviderGrant.tokens_remaining on every call -- the provider&#39;s own reported token usage once generation succeeds, or (rejected before any request is even sent to the provider) a rough pre-flight estimate of the request&#39;s input cost alone, whichever catches an insufficient balance first. |
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
Request to create a new third-party refresh token. Unlike [`LoginRequest`](#jonline-LoginRequest) or [`CreateAccountRequest`](#jonline-CreateAccountRequest), the user must be logged in to create a third-party refresh token.

Generally, this is used to create a refresh token for another Jonline instance,
e.g., accessing `bullcity.social/jon`&#39;s data from `jonline.io`. On the web side, this is implemented as follows:

1. When the `bullcity.social` user wants to login on `jonline.io`, `bullcity.social` will redirect 
the user to `jonline.io/third_party_auth?to=bullcity.social`.
2. `jonline.io` will force the user to login if needed on this page.
3. `jonline.io` will prompt/warn the user, and then call this RPC to create a refresh &#43; access token for `bullcity.social`.
4. `jonline.io` will redirect the user back to `bullcity.social/third_party_auth?from=jonline.io&amp;token=&lt;Base64RefreshTokenResponse&gt;` with the refresh token POSTed in form data.
    * (`&lt;Base64RefreshTokenResponse&gt;` is a base64-encoded [`RefreshTokenResponse`](#jonline-RefreshTokenResponse) message.)
6. `bullcity.social` will ensure it can [`GetCurrentUser`](#grpc-api-GetCurrentUser) on `jonline.io` with its new auth token.
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

- A [`User`](#jonline-User) has a `moderation` that determines whether they can log in (and their visibility per their `visibility`).
  (This is poorly enforced currently! Fix it if you want!)
    - This is managed by `people_settings.default_moderation` in [`ServerConfiguration`](#jonline-ServerConfiguration).
      A default of `UNMODERATED` means that all users can log in. A default of `PENDING`
      means that all users must be approved by a moderator/admin before they can log in.
- A [`Follow`](#jonline-Follow) has a `target_user_moderation` that determines whether the [`User`](#jonline-User) is following the [`Group`](#jonline-Group).
   - It is managed by `default_follow_moderation` in the targeted [`User`](#jonline-User).
- A [`Group`](#jonline-Group) has a `moderation` that determines whether the [`Group`](#jonline-Group) is visible to users (per its `visibility`).
    - This is managed by `group_settings.default_moderation` in [`ServerConfiguration`](#jonline-ServerConfiguration).
- A [`Membership`](#jonline-Membership) has a `group_moderation` and `user_moderation` that determine whether
  the [`Group`](#jonline-Group) admins and/or the invited user has approved the [`Membership`](#jonline-Membership), respectively.
    - User invites to [`Group`](#jonline-Group)s (i.e. the `user_moderation`) always start as `PENDING`.
      The group side of this is managed by `default_membership_moderation` of the [`Group`](#jonline-Group) in question.
- A [`Post`](#jonline-Post) has a `moderation` that determines whether the [`Post`](#jonline-Post) is visible to users (per its `visibility`).
    - This is managed by `post_settings.default_moderation` in [`ServerConfiguration`](#jonline-ServerConfiguration).
- A [`GroupPost`](#jonline-GroupPost) has a `moderation` that determines whether the admins/mods of the [`Group`](#jonline-Group) has approved the [`Post`](#jonline-Post) (or [`Post`](#jonline-Post)-descended thing like [`Event`](#jonline-Event)s).
- [`Event`](#jonline-Event)s and further objects contain a [`Post`](#jonline-Post) and thus inherit its `moderation` and
  related [`GroupPost`](#jonline-GroupPost) behavior, for &#34;Group Events.&#34;

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
and each type of entity ([`User`](#jonline-User), [`Media`](#jonline-Media), [`Group`](#jonline-Group), then [`Post`](#jonline-Post)/[`Event`](#jonline-Event)/etc. with common logic)
has different rules for visibility.

From the top down, the rules break down as follows:

- Even a `PRIVATE` entity is always visible to the user who owns it.
    - For [`Group`](#jonline-Group)s, this means all full members of the [`Group`](#jonline-Group).
    - For [`User`](#jonline-User)s, this is confusing and there is a whole [`PrivateUserStrategy`](#jonline-PrivateUserStrategy) thing
      in [`ServerConfiguration`](#jonline-ServerConfiguration) for this.
- A `LIMITED` entity is visible to to the owner(s) and any explicitly associated
  [`User`](#jonline-User)s and [`Group`](#jonline-Group)s. Generally, this only applies to [`Post`](#jonline-Post)/[`Event`](#jonline-Event)/etc. entities.
  Associations exist via [`UserPost`](#jonline-UserPost)s and [`GroupPost`](#jonline-GroupPost)s.
    - This is currently only implemented for [`Group`](#jonline-Group)s and [`GroupPost`](#jonline-GroupPost)s. There are some
      choices to be made about how to implement this for [`User`](#jonline-User)s and [`UserPost`](#jonline-UserPost)s, and whether
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
(A [`Membership`](#jonline-Membership) is the link between a [`Group`](#jonline-Group) and a [`User`](#jonline-User).)

Subsets of these permissions are also applicable to anonymous users via [`anonymous_user_permissions` in `ServerConfiguration`](#jonline-ServerConfiguration),
and to Group non-members via [`non_member_permissions` in `Group`](#jonline-Group), as well as others documented there.

| Name | Number | Description |
| ---- | ------ | ----------- |
| PERMISSION_UNKNOWN | 0 | A permission that could not be read using the Jonline protocol. (Perhaps, a permission from a newer Jonline version.) |
| VIEW_USERS | 1 | Allow the user to view profiles with `SERVER_PUBLIC` Visibility. Allow anonymous users to view profiles with `GLOBAL_PUBLIC` Visibility (when configured as an anonymous user permission). |
| PUBLISH_USERS_LOCALLY | 2 | Allow the user to publish profiles with `SERVER_PUBLIC` Visibility. This generally only applies to the user&#39;s own profile, except for Admins. |
| PUBLISH_USERS_GLOBALLY | 3 | Allow the user to publish profiles with `GLOBAL_PUBLIC` Visibility. This generally only applies to the user&#39;s own profile, except for Admins. |
| MODERATE_USERS | 4 | Allow the user to grant `VIEW_POSTS`, `CREATE_POSTS`, `VIEW_EVENTS` and `CREATE_EVENTS` permissions to users. |
| FOLLOW_USERS | 5 | Allow the user to follow other users. |
| GRANT_BASIC_PERMISSIONS | 6 | Allow the user to grant Basic Permissions to other users. &#34;Basic Permissions&#34; are defined by your [`ServerConfiguration`](#jonline-ServerConfiguration)&#39;s `basic_user_permissions`. |
| VIEW_GROUPS | 10 | Allow the user to view groups with `SERVER_PUBLIC` visibility. Allow anonymous users to view groups with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission). |
| CREATE_GROUPS | 11 | Allow the user to create groups. |
| PUBLISH_GROUPS_LOCALLY | 12 | Allow the user to give groups `SERVER_PUBLIC` visibility. |
| PUBLISH_GROUPS_GLOBALLY | 13 | Allow the user to give groups `GLOBAL_PUBLIC` visibility. |
| MODERATE_GROUPS | 14 | The Moderate Groups permission makes a user effectively an admin of *any* group. |
| JOIN_GROUPS | 15 | Allow the user to (potentially request to) join groups of `SERVER_PUBLIC` or higher visibility. |
| INVITE_GROUP_MEMBERS | 16 | Allow the user to invite other users to groups. Only applicable as a Group permission (not at the User level). |
| VIEW_POSTS | 20 | As a user permission, allow the user to view posts with `SERVER_PUBLIC` or higher visibility. As a group permission, allow the user to view [`GroupPost`](#jonline-GroupPost)s whose [`Post`](#jonline-Post)s have `LIMITED` or higher visibility. Allow anonymous users to view posts with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission). |
| CREATE_POSTS | 21 | As a user permission, allow the user to create [`Post`](#jonline-Post)s of `PRIVATE` and `LIMITED` visibility. As a group permission, allow the user to create [`GroupPost`](#jonline-GroupPost)s for `POST` and `FEDERATED_POST` [`PostContext`](#jonline-PostContext)s.. |
| PUBLISH_POSTS_LOCALLY | 22 | Allow the user to publish posts with `SERVER_PUBLIC` visibility. |
| PUBLISH_POSTS_GLOBALLY | 23 | Allow the user to publish posts with `GLOBAL_PUBLIC` visibility. |
| MODERATE_POSTS | 24 | Allow the user to moderate posts. |
| REPLY_TO_POSTS | 25 | Allow the user to reply to posts. |
| EDIT_POST_TITLES_AND_LINKS | 26 | Allow the user to edit post titles and/or links. |
| VIEW_EVENTS | 30 | As a user permission, allow the user to view posts with `SERVER_PUBLIC` or higher visibility. As a group permission, allow the user to view [`GroupPost`](#jonline-GroupPost)s whose [`Event`](#jonline-Event) [`Post`](#jonline-Post)s have `LIMITED` or higher visibility. Allow anonymous users to view events with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission). |
| CREATE_EVENTS | 31 | As a user permission, allow the user to create [`Event`](#jonline-Event)s of `PRIVATE` and `LIMITED` visibility. As a group permission, allow the user to create [`GroupPost`](#jonline-GroupPost)s for `EVENT` and `FEDERATED_EVENT_INSTANCE` [`PostContext`](#jonline-PostContext)s.. |
| PUBLISH_EVENTS_LOCALLY | 32 | Allow the user to publish events with `SERVER_PUBLIC` visibility. |
| PUBLISH_EVENTS_GLOBALLY | 33 | Allow the user to publish events with `GLOBAL_PUBLIC` visibility. |
| MODERATE_EVENTS | 34 | Allow the user to moderate events. |
| RSVP_TO_EVENTS | 35 | Allow the user to RSVP to events that allow RSVPs. |
| VIEW_MEDIA | 40 | Allow the user to view media with `SERVER_PUBLIC` or higher visibility. *Not currently enforced.* Allow anonymous users to view media with `GLOBAL_PUBLIC` visibility (when configured as an anonymous user permission). *Not currently enforced.* |
| CREATE_MEDIA | 41 | Allow the user to create media of `PRIVATE` and `LIMITED` visibility. *Not currently enforced.* |
| PUBLISH_MEDIA_LOCALLY | 42 | Allow the user to publish media with `SERVER_PUBLIC` visibility. *Not currently enforced.* |
| PUBLISH_MEDIA_GLOBALLY | 43 | Allow the user to publish media with `GLOBAL_PUBLIC` visibility. *Not currently enforced.* |
| MODERATE_MEDIA | 44 | Allow the user to moderate events. |
| READ_PERSONAL_MESSAGES | 50 |  |
| READ_ALL_SYSTEM_MESSAGES | 51 |  |
| CREATE_AI_MODEL_PROVIDERS | 60 | Allow the user to create/update their own [`AIModelProvider`](#jonline-AIModelProvider)s (see `ai_model_providers.proto`) and grant/revoke other users&#39; access to them. |
| SYNC_EVENTS_FROM_ICS | 700 | Allow the user to create/update [`SyncSource`](#jonline-SyncSource)s (iCal subscriptions) that synchronize [`Event`](#jonline-Event)s in. |
| SYNC_EVENTS_TO_FACEBOOK | 1000 | Sync permissions -- each gates creating/updating [`SyncDestination`](#jonline-SyncDestination)s of that platform, and syncing that content type to them (see `sync.proto`). A generous reserved block (`1000`&#43;) since this is the most likely area to keep growing as new platforms are added.

Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post EventInstances to a connected Facebook Page, and to sync EventInstances to them. |
| SYNC_POSTS_TO_FACEBOOK | 1001 | Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post Posts to a connected Facebook Page, and to sync Posts to them. |
| SYNC_EVENTS_TO_INSTAGRAM | 1010 | Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post EventInstances to a connected Instagram Business/Creator account, and to sync EventInstances to them. |
| SYNC_POSTS_TO_INSTAGRAM | 1011 | Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post Posts to a connected Instagram Business/Creator account, and to sync Posts to them. |
| SYNC_EVENTS_TO_MASTODON | 1020 | Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post EventInstances to a connected Mastodon account, and to sync EventInstances to them. |
| SYNC_POSTS_TO_MASTODON | 1021 | Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post Posts to a connected Mastodon account, and to sync Posts to them. |
| SYNC_EVENTS_TO_BLUESKY | 1030 | Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post EventInstances to a connected Bluesky account, and to sync EventInstances to them. |
| SYNC_POSTS_TO_BLUESKY | 1031 | Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post Posts to a connected Bluesky account, and to sync Posts to them. |
| SYNC_EVENTS_TO_X_TWITTER | 1040 | Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post EventInstances to a connected X (Twitter) account, and to sync EventInstances to them. |
| SYNC_POSTS_TO_X_TWITTER | 1041 | Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post Posts to a connected X (Twitter) account, and to sync Posts to them. |
| SYNC_EVENTS_TO_THREADS | 1050 | Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post EventInstances to a connected Threads account, and to sync EventInstances to them. |
| SYNC_POSTS_TO_THREADS | 1051 | Allow the user to create/update [`SyncDestination`](#jonline-SyncDestination)s that cross-post Posts to a connected Threads account, and to sync Posts to them. |
| BUSINESS | 9998 | Indicates the user is a business. Used purely for display purposes. |
| RUN_BOTS | 9999 | Allow the user to run bots. There is no enforcement of this permission (yet), but it lets other users know that the user is allowed to run bots. |
| ADMIN | 10000 | Marks the user as an admin. In the context of user permissions, allows the user to configure the server, moderate/update visibility/permissions to any [`User`](#jonline-User), [`Group`](#jonline-Group), [`Post`](#jonline-Post) or [`Event`](#jonline-Event). In the context of group permissions, allows the user to configure the group, modify members and member permissions, and moderate [`GroupPost`](#jonline-GroupPost)s and `GroupEvent`s. |
| VIEW_PRIVATE_CONTACT_METHODS | 10001 | Allow the user to view the private contact methods of other users. Kept separate from `ADMIN` to allow for more fine-grained privacy control. |


 

 

 



<a name="users-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## users.proto



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

- `{listing_type: USERS_TEXT_SEARCH, search_text:}`
    - Full-text search across accessible users&#39; username, real name, and bio.
- `{listing_type: FOLLOWERS_TEXT_SEARCH, search_text:, user_id:}` (and the
  `FOLLOWING_TEXT_SEARCH`/`FRIENDS_TEXT_SEARCH`/`FOLLOW_REQUESTS_TEXT_SEARCH` equivalents)
    - Scopes that same full-text search to `user_id`&#39;s followers/following/friends/follow
      requests, same relationship rules as the non-search `listing_type`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| username | [string](#string) | optional | The username to search for. Substrings are supported. |
| user_id | [string](#string) | optional | The user ID to search for. |
| search_text | [string](#string) | optional | Full-text search query, matched against the user&#39;s username/real name/bio. Required (and only used) when `listing_type` is `USERS_TEXT_SEARCH` or one of the `*_TEXT_SEARCH` variants. |
| page | [int32](#int32) | optional | The page of results to return. Pages are 0-indexed. |
| listing_type | [UserListingType](#jonline-UserListingType) |  | The number of results to return per page. |






<a name="jonline-GetUsersResponse"></a>

### GetUsersResponse
Response to a [`GetUsersRequest`](#jonline-GetUsersRequest).


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
| friend_count | [int32](#int32) | optional | The number of users this user mutually follows (and is followed by). |
| group_count | [int32](#int32) | optional | The number of groups this user is a member of. |
| post_count | [int32](#int32) | optional | The number of posts this user has made. |
| response_count | [int32](#int32) | optional | The number of responses to [`Post`](#jonline-Post)s and [`Event`](#jonline-Event)s this user has made. |
| event_count | [int32](#int32) | optional | The number of events this user has created. |
| event_instance_count | [int32](#int32) | optional | The number of event instances this user has created (across all of their events). |
| current_user_follow | [Follow](#jonline-Follow) | optional | Presence indicates the current user is following or has a pending follow request for this user. |
| target_current_user_follow | [Follow](#jonline-Follow) | optional | Presence indicates this user is following or has a pending follow request for the current user. |
| current_group_membership | [Membership](#jonline-Membership) | optional | Returned by [`GetMembers`](#grpc-api-GetMembers) calls, for use when managing [`Group`](#jonline-Group) [`Membership`](#jonline-Membership)s. The [`Membership`](#jonline-Membership) should match the [`Group`](#jonline-Group) from the originating [`GetMembersRequest`](#jonline-GetMembersRequest), providing whether the user is a member of that [`Group`](#jonline-Group), has been invited, requested to join, etc.. |
| has_advanced_data | [bool](#bool) |  | Indicates that `federated_profiles` has been loaded. |
| federated_profiles | [FederatedAccount](#jonline-FederatedAccount) | repeated | Federated profiles for the user. *Not always loaded.* This is a list of profiles from other servers that the user has connected to their account. Managed by the user via `Federate` |
| sync_destinations | [SyncDestination](#jonline-SyncDestination) | repeated | The target user&#39;s own linked SyncDestinations (e.g. Facebook Pages). Populated by [`GetUsers`](#grpc-api-GetUsers)&#39; single-user lookups (by username or by user_id) when the viewer is the target user themselves (and holds `SYNC_EVENTS_TO_FACEBOOK` or `SYNC_POSTS_TO_FACEBOOK`) or an Admin, and by [`Login`](#grpc-api-Login)/[`CreateAccount`](#grpc-api-CreateAccount)/[`GetCurrentUser`](#grpc-api-GetCurrentUser) (always a self-view) -- always empty otherwise, including via every other [`GetUsers`](#grpc-api-GetUsers) listing type. |
| sync_sources | [SyncSource](#jonline-SyncSource) | repeated | The target user&#39;s own [`SyncSource`](#jonline-SyncSource)s. Unlike `sync_destinations`, also populated for the target user themselves *or an Admin* across every [`GetUsers`](#grpc-api-GetUsers) listing type (not just single-user lookups) -- e.g. an Admin&#39;s `EVERYONE` listing gets every returned user&#39;s sources filled in, batch-loaded in one query rather than per-user. Also populated by [`Login`](#grpc-api-Login)/[`CreateAccount`](#grpc-api-CreateAccount)/[`GetCurrentUser`](#grpc-api-GetCurrentUser) (always a self-view). Always empty for any other viewer. |
| available_ai_models | [AvailableAIModel](#jonline-AvailableAIModel) | repeated | Every [`AIModelProvider`](#jonline-AIModelProvider) model the target user may currently call -- their own providers&#39; models, plus any models granted to them on other users&#39; providers (see [`AvailableAIModel`](#jonline-AvailableAIModel)). Gated and populated the same way as `sync_sources` (target user themselves, or an Admin, across any [`GetUsers`](#grpc-api-GetUsers) listing type, plus [`Login`](#grpc-api-Login)/[`CreateAccount`](#grpc-api-CreateAccount)/[`GetCurrentUser`](#grpc-api-GetCurrentUser)). |
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
| USERS_TEXT_SEARCH | 5 | Returns users matching the full-text `search_text` query, scoped the same way `EVERYONE` is. Requires `search_text` parameter.

Named `USERS_TEXT_SEARCH` (not the bare `TEXT_SEARCH` used by [`PostListingType`](#jonline-PostListingType)) because proto3 enum values share a single namespace across the whole `jonline` package (C&#43;&#43; scoping rules) - [`PostListingType`](#jonline-PostListingType) already claimed `TEXT_SEARCH`. |
| FOLLOWERS_TEXT_SEARCH | 6 | Scopes `TEXT_SEARCH` to users following `user_id`. Requires `search_text` and `user_id`. |
| FOLLOWING_TEXT_SEARCH | 7 | Scopes `TEXT_SEARCH` to users `user_id` follows. Requires `search_text` and `user_id`. |
| FRIENDS_TEXT_SEARCH | 8 | Scopes `TEXT_SEARCH` to `user_id`&#39;s friends (mutual follows). Requires `search_text` and `user_id`. |
| FOLLOW_REQUESTS_TEXT_SEARCH | 9 | Scopes `TEXT_SEARCH` to the signed-in caller&#39;s pending follow requests. Requires `search_text`. |
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
| aspect_ratio | [float](#float) | optional | Width divided by height. Set by the `convert_media_sizes` background job once it&#39;s able to read the media&#39;s dimensions (via ImageMagick/ffprobe); unset until then. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  |  |
| metadata | [MediaMetadata](#jonline-MediaMetadata) |  |  |






<a name="jonline-MediaMetadata"></a>

### MediaMetadata
Free-form metadata about a [`Media`](#jonline-Media) item that isn&#39;t queried/filtered on, so doesn&#39;t need its
own columns.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| video_preview_time_ms | [uint32](#uint32) | optional | For video media, how far into the video (in milliseconds) its preview/poster frame should be taken from, via a `#t=&lt;seconds&gt;` Media Fragments URI on the `&lt;video&gt;` element&#39;s `src`. Unset means use the browser&#39;s default first-frame preview. |






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
| metadata | [MediaMetadata](#jonline-MediaMetadata) |  |  |
| aspect_ratio | [float](#float) | optional | Width divided by height. See `Media.aspect_ratio`. |





 

 

 

 



<a name="messages-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## messages.proto



<a name="jonline-GetMessagesRequest"></a>

### GetMessagesRequest
Request to get messages from the server. The request may be filtered by message ID, search text, or creation time.
All non-text-search requests return messages in reverse chronological order (newest first). 
Text search requests return messages in order of relevance to the search text.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| listing_type | [MessageListingType](#jonline-MessageListingType) |  | The type of message listing to return. Required. |
| message_id | [string](#string) | optional | Returns the single message with the given ID (assuming the user has access to it). |
| message_group_id | [string](#string) | optional | Returns messages that are part of the given messaging group (assuming the user has access to it). |
| search_text | [string](#string) | optional | Full-text search query, matched against the sender&#39;s username/real name and the message&#39;s subject and body. Required (and only used) when `listing_type` is `TEXT_SEARCH`. |
| sent_before | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Request to only return posts that were published or created before the given timestamp. |
| from_email | [string](#string) | optional | Returns messages (assuming the user has access to each) whose email &#34;from&#34; header exactly matches the given value - i.e. `Message.from` as returned by a previous response. Meant for expanding the &#34;sender&#34; grouping a client falls back to when `Message.messaging_group` isn&#39;t set (see that field&#39;s own doc comment): unlike `message_group_id`, there&#39;s no server-side group backing this, so it&#39;s just a straight filter, not an access-controlled entity lookup. Since `from` is unauthenticated/spoofable (see this file&#39;s own top-level doc comment), so is this filter - it matches whatever string the sender&#39;s email client sent, nothing more. |






<a name="jonline-GetMessagesResponse"></a>

### GetMessagesResponse
Response to a [`GetMessagesRequest`](#jonline-GetMessagesRequest), containing the requested messages.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| messages | [Message](#jonline-Message) | repeated | The messages that match the request. May be empty if no messages match. May be shortened to a server-defined limit, dependent on service version, configuration, load, etc. |






<a name="jonline-GetPushSubscriptionStatusRequest"></a>

### GetPushSubscriptionStatusRequest
Checks whether the current user has already registered a given Web Push subscription endpoint.
See [`GetPushSubscriptionStatus`](#grpc-api-GetPushSubscriptionStatus)&#39;s own RPC doc comment.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| endpoint | [string](#string) |  | The Web Push subscription endpoint URL to check, as given by `PushManager.subscribe()`. |






<a name="jonline-GetPushSubscriptionStatusResponse"></a>

### GetPushSubscriptionStatusResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| registered | [bool](#bool) |  | Whether the current user has a [`PushSubscription`](#jonline-PushSubscription) registered for this exact `endpoint`. |






<a name="jonline-MarkMessagesReadRequest"></a>

### MarkMessagesReadRequest
Marks (or unmarks) one or more Messages as read by the calling user, e.g. every message in a
thread once it&#39;s been opened. *Authenticated* -- read status is inherently personal, so there&#39;s
no anonymous variant the way [`SendMessage`](#grpc-api-SendMessage) has one.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| unread | [bool](#bool) |  | If `false` (the default), the request is to mark the messages as read. If `true`, marks them (back) as unread instead -- e.g. an explicit &#34;mark unread&#34; action on an already-read message. |
| message_ids | [string](#string) | repeated | The Messages to mark read/unread. The caller must have the same access to each of them [`GetMessages`](#grpc-api-GetMessages) would require (sender, a `messaging_group` member, a Bcc recipient, or an admin) -- see [`MarkMessagesRead`](#grpc-api-MarkMessagesRead)&#39;s own RPC doc comment. A message id the caller doesn&#39;t have access to fails the whole request (see that RPC&#39;s own doc on atomicity) rather than silently skipping it. |






<a name="jonline-MarkMessagesReadResponse"></a>

### MarkMessagesReadResponse
Response to a [`MarkMessagesReadRequest`](#jonline-MarkMessagesReadRequest) -- one [`MessageRead`](#jonline-MessageRead) per `message_ids` entry, in the
same order, each reflecting that message&#39;s own read/unread result (see `MarkMessagesReadRequest.unread`).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| message_reads | [MessageRead](#jonline-MessageRead) | repeated |  |






<a name="jonline-Message"></a>

### Message
A Jonline `Message` represents a single message/email sent to one or more recipients
(really, &#34;zero or more&#34;, as the design incorporates undeliverable messages).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | The ID of the message. |
| sender | [Author](#jonline-Author) | optional | The sender of the message. Note that this is *purported* (we don&#39;t protect against spoofing). |
| messaging_group | [MessagingGroup](#jonline-MessagingGroup) | optional | Note that, on the backend, every message actually has a messaging group. From the client&#39;s perspective, if messaging_group is not set, you were BCC&#39;ed on the message and don&#39;t have access to the messaging group. |
| body_text | [string](#string) |  | The body text of the message. For email messages, this is the email body. |
| subject | [string](#string) | optional | Subject of the message. For email messages, this is the email subject. |
| email_message_id | [string](#string) | optional | If this message derived from an email, the original email&#39;s message ID (RFC 5322). Used to prevent duplicate messages from being created when the same email is sent multiple times. |
| from | [string](#string) | optional | If this message derived from an email, the original email&#39;s &#34;from&#34; address. |
| to | [string](#string) | optional | If this message derived from an email, the original email&#39;s &#34;to&#34; address. |
| cc | [string](#string) | optional | If this message derived from an email, the original email&#39;s &#34;cc&#34; address. |
| bcc | [string](#string) | optional | If this message derived from an email, the original email&#39;s &#34;bcc&#34; address. |
| current_user_read | [MessageRead](#jonline-MessageRead) | optional | Whether/when *this response&#39;s viewer* has read the message -- unset means unread. Always reflects the currently-authenticated caller&#39;s own read status (via [`MarkMessagesRead`](#grpc-api-MarkMessagesRead)), even when browsing `ALL_SYSTEM_MESSAGES(_TEXT_SEARCH)` as an admin: it&#39;s a personal &#34;have I seen this&#34; marker, not tied to whichever user this response happens to be showing `messaging_group` for. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the message was created. |






<a name="jonline-MessageRead"></a>

### MessageRead
Records that a user has read a particular Message -- one row (conceptually; see the composite
`message_id`/`user_id` key on the backing table) per (Message, user) that&#39;s ever been marked
read. Only ever surfaced back to the user it belongs to, as `Message.current_user_read` -- there&#39;s
no RPC to see *other* users&#39; read status on a Message.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| message_id | [string](#string) |  |  |
| user_id | [string](#string) |  |  |
| read_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | When the message was marked read. Always set on a [`MessageRead`](#jonline-MessageRead) returned from [`MarkMessagesRead`](#grpc-api-MarkMessagesRead) -- including a `{ unread: true }` call, where it&#39;s simply the time of that unmark request, not a meaningful &#34;last read&#34; timestamp (there&#39;s no longer a row for it to come from at that point). |






<a name="jonline-MessagingGroup"></a>

### MessagingGroup
A group of users who are participating in a conversation.
Most servers will probably have a (dynamically created) &#34;empty group&#34; for an email like
`not_a_user@my_jonline_instance.com`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | The ID of the messaging group. |
| members | [Author](#jonline-Author) | repeated | The users who are members of the group. Note that this is a superset of the users who are |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the group was created. |






<a name="jonline-PushSubscription"></a>

### PushSubscription
A browser&#39;s Web Push subscription (see https://developer.mozilla.org/en-US/docs/Web/API/Push_API),
registered so the server can push new-Message notifications to it even while the browser tab is
closed. Only ever surfaced back to the user who registered it -- there&#39;s no RPC to list other
users&#39; subscriptions.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | The ID of the subscription. |
| endpoint | [string](#string) |  | The Web Push subscription endpoint URL, as given by `PushManager.subscribe()`. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the subscription was registered. |






<a name="jonline-RegisterPushSubscriptionRequest"></a>

### RegisterPushSubscriptionRequest
Registers (or re-registers) a browser&#39;s Web Push subscription for the current user, so new
Messages sent/delivered to them push a notification even while the browser tab is closed.
See [`RegisterPushSubscription`](#grpc-api-RegisterPushSubscription)&#39;s own RPC doc comment.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| endpoint | [string](#string) |  | The Web Push subscription endpoint URL, as given by `PushManager.subscribe()`. |
| p256dh_key | [string](#string) |  | The subscription&#39;s `p256dh` key (base64url), as given by `PushSubscription.getKey(&#39;p256dh&#39;)`. |
| auth_key | [string](#string) |  | The subscription&#39;s `auth` key (base64url), as given by `PushSubscription.getKey(&#39;auth&#39;)`. |






<a name="jonline-SendMessageRequest"></a>

### SendMessageRequest
Request to create a new message.
The server will create a new messaging group for the message, and send it to the given recipients.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| to_user_ids | [string](#string) | repeated |  |
| subject | [string](#string) | optional |  |
| body_text | [string](#string) | optional |  |






<a name="jonline-UnregisterPushSubscriptionRequest"></a>

### UnregisterPushSubscriptionRequest
Unregisters a browser&#39;s Web Push subscription for the current user, e.g. on logout or when
`PushManager.subscribe()` reports the subscription as no longer valid. See
[`UnregisterPushSubscription`](#grpc-api-UnregisterPushSubscription)&#39;s own RPC doc comment.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| endpoint | [string](#string) |  | The Web Push subscription endpoint URL to unregister, as previously passed to [`RegisterPushSubscription`](#grpc-api-RegisterPushSubscription). |





 


<a name="jonline-MessageListingType"></a>

### MessageListingType


| Name | Number | Description |
| ---- | ------ | ----------- |
| PERSONAL_MESSAGES | 0 | Gets messages sent to the current user, and messages (purportedly) sent by the user. |
| PERSONAL_MESSAGES_TEXT_SEARCH | 1 | Gets messages sent to the current user, and messages (purportedly) sent by the user, that match the given search text. Returns results in order of relevance to the search text. |
| ALL_SYSTEM_MESSAGES | 10 | Gets all messages on the server (to a limit), including those sent to other users. Requires admin privileges. |
| ALL_SYSTEM_MESSAGES_TEXT_SEARCH | 11 |  |


 

 

 



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
| shortname | [string](#string) |  | Immutable shortname of the group. Derived from changes to `name` when the [`Group`](#jonline-Group) is updated. |
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
Used when fetching group members using the [`GetMembers`](#grpc-api-GetMembers) RPC.


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



<a name="jonline-DeletePostSyncDestinationRequest"></a>

### DeletePostSyncDestinationRequest
Removes a single Post&#39;s sync (cross-post) to one SyncDestination -- the reverse of [`SyncPost`](#grpc-api-SyncPost).
Does not delete the post already made on the destination (e.g. the Facebook Page post), only the local sync record.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| post_id | [string](#string) |  | The Post to un-sync. |
| sync_destination_id | [string](#string) |  | The SyncDestination to un-sync it from. |






<a name="jonline-GetGroupPostsRequest"></a>

### GetGroupPostsRequest
Used for getting context about [`GroupPost`](#jonline-GroupPost)s of an existing [`Post`](#jonline-Post).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| post_id | [string](#string) |  | The ID of the post to get [`GroupPost`](#jonline-GroupPost)s for. |
| group_id | [string](#string) | optional | The ID of the group to get [`GroupPost`](#jonline-GroupPost)s for. |






<a name="jonline-GetGroupPostsResponse"></a>

### GetGroupPostsResponse
Used for getting context about [`GroupPost`](#jonline-GroupPost)s of an existing [`Post`](#jonline-Post).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| group_posts | [GroupPost](#jonline-GroupPost) | repeated | The [`GroupPost`](#jonline-GroupPost)s for the given [`Post`](#jonline-Post) or [`Group`](#jonline-Group). |






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
- `{listing_type: MyGroupsPosts|[`GroupPost`](#jonline-GroupPost)sPendingModeration, group_id:}`
    - Get posts/posts needing moderation for a group. Authorization may be required depending on group visibility.
- `{author_user_id:, group_id:}`
    - Get posts by a user for a group. (TODO)
- `{listing_type: AuthorPosts, author_user_id:}`
    - Get posts by a user. (TODO)
- `{listing_type: TextSearch, search_text:}`
    - Full-text search across accessible posts&#39; author username/real name, title, link, and content.
    - `{listing_type: TextSearch, search_text:, author_user_id:}` scopes the search to one author.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| post_id | [string](#string) | optional | Returns the single post with the given ID. |
| author_user_id | [string](#string) | optional | Limits results to those by the given author user ID. |
| group_id | [string](#string) | optional | Limits results to those in the given group ID. |
| reply_depth | [uint32](#uint32) | optional | Only supported for depth=2 for now. |
| context | [PostContext](#jonline-PostContext) | optional | Only POST and REPLY are supported for now. |
| post_ids | [string](#string) | optional | Returns expanded posts with the given IDs. |
| listing_type | [PostListingType](#jonline-PostListingType) |  | The listing type of the request. See [`PostListingType`](#jonline-PostListingType) for more info. |
| page | [uint32](#uint32) |  | The page of results to return. Defaults to 0. |
| search_text | [string](#string) | optional | Full-text search query, matched against the author&#39;s username/real name and the post&#39;s title/link/content. Required (and only used) when `listing_type` is `TEXT_SEARCH`. |
| published_or_created_before | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Request to only return posts that were published or created before the given timestamp. |






<a name="jonline-GetPostsResponse"></a>

### GetPostsResponse
Used for getting posts.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| posts | [Post](#jonline-Post) | repeated | The posts returned by the request. |






<a name="jonline-GroupPost"></a>

### GroupPost
A `GroupPost` is a cross-post of a [`Post`](#jonline-Post) to a [`Group`](#jonline-Group). It contains
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
as well as any associated [`GroupPost`](#jonline-GroupPost)s and [`UserPost`](#jonline-UserPost)s determine what users
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
| post_media_layout | [PostMediaLayout](#jonline-PostMediaLayout) |  | The desired end-user layout of Media attached to the post. |
| current_group_post | [GroupPost](#jonline-GroupPost) | optional | If the Post was retrieved from GetPosts with a group_id, the GroupPost metadata may be returned along with the Post. |
| replies | [Post](#jonline-Post) | repeated | Hierarchical replies to this post. There will never be more than `reply_count` replies. However, there may be fewer than `reply_count` replies if some replies are hidden by moderation or visibility. Replies are not generally loaded by default, but can be added to Posts in the frontend. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the post was created. |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the post was last updated. |
| published_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the post was published (its visibility first changed to `SERVER_PUBLIC` or `GLOBAL_PUBLIC`). |
| last_activity_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the post was last interacted with (replied to, etc.) |
| unauthenticated_star_count | [int64](#int64) |  | The number of unauthenticated stars on the post. |
| sync_destinations | [SyncDestinationStatus](#jonline-SyncDestinationStatus) | repeated | SyncDestinations this post has been synced (cross-posted) to, and their status. |






<a name="jonline-SyncPostRequest"></a>

### SyncPostRequest
Syncs (cross-posts) a single Post to one SyncDestination.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| post_id | [string](#string) |  | The Post to sync. |
| sync_destination_id | [string](#string) |  | The SyncDestination to sync it to. |






<a name="jonline-UserPost"></a>

### UserPost
A `UserPost` is a &#34;direct share&#34; of a [`Post`](#jonline-Post) to a [`User`](#jonline-User). Currently unused/unimplemented.
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
| POST | 0 | &#34;Standard&#34; or &#34;Top-Level&#34; Post. Can have media, a link, a title, and/or content. If provided, its `link` and `title` are permanent. |
| REPLY | 1 | Reply to a `POST`, `REPLY`, `EVENT`, or `EVENT_INSTANCE` Does not support a `link`. Requires a `reply_to_post_id`. |
| EVENT | 2 | Post behind an &#34;Event&#34; (which does not actually have a start/end time - it&#39;s a group of EventInstances, at least one, which each do). The Events table should have a row for this Post. Never created by the CreatePost RPC (this is an error); use CreateEvent. These Posts&#39; `link` and `title` fields are modifiable. |
| EVENT_INSTANCE | 3 | An &#34;Event Instance&#34; Post (which relates to an event with a start and end time). The EventInstances table should have a row for this Post. Never created by the CreatePost RPC (this is an error); use CreateEvent/UpdateEvent to manage EventInstances implicitly. These Posts&#39; `link` and `title` fields are modifiable. |
| FEDERATED_REPLY | 10 | A reply to a Post on another server. The post *must* have a link of the format `http[s]://&lt;server/post/&lt;post_id&gt;` in its `link` field. It will not have a `reply_to_post_id` value. |



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
| TEXT_SEARCH | 5 | Returns posts matching the full-text `search_text` query, scoped the same way ALL_ACCESSIBLE_POSTS is (plus author_user_id, if provided). Requires search_text parameter. |
| GROUP_POSTS | 10 | Returns posts from a specific group. Requires group_id parameter. |
| GROUP_POSTS_PENDING_MODERATION | 11 | Returns pending_moderation posts from a specific group. Requires group_id parameter and user must have group (or server) admin permissions. |



<a name="jonline-PostMediaLayout"></a>

### PostMediaLayout


| Name | Number | Description |
| ---- | ------ | ----------- |
| MEDIA_LAYOUT_STANDARD | 0 |  |
| MEDIA_LAYOUT_DYNAMIC_VERTICAL_SCROLL | 1 |  |


 

 

 



<a name="events-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## events.proto



<a name="jonline-AnonymousAttendee"></a>

### AnonymousAttendee
An anonymous internet user who has RSVP&#39;d to an [`EventInstance`](#jonline-EventInstance).

(TODO:) The visibility on `AnonymousAttendee` [`ContactMethod`](#jonline-ContactMethod)s should support the `LIMITED` visibility, which will
make them visible to the event creator.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| name | [string](#string) |  | A name for the anonymous user. For instance, &#34;Bob Gomez&#34; or &#34;The guy on your front porch.&#34; |
| contact_methods | [ContactMethod](#jonline-ContactMethod) | repeated | Contact methods for anonymous attendees. Currently not linked to Contact methods for users. |
| auth_token | [string](#string) | optional | Used to allow anonymous users to RSVP to an event. Generated by the server when an event attendance is upserted for the first time. Subsequent attendance upserts, with the same event_instance_id and anonymous_attendee.auth_token, will update existing anonymous attendance records. Invalid auth tokens used during upserts will always create a new [`EventAttendance`](#jonline-EventAttendance). |






<a name="jonline-DeleteEventInstanceSyncDestinationRequest"></a>

### DeleteEventInstanceSyncDestinationRequest
Removes a single EventInstance&#39;s sync (cross-post) to one SyncDestination -- the reverse of [`SyncEventInstance`](#grpc-api-SyncEventInstance).
Does not delete the post already made on the destination (e.g. the Facebook Page post), only the local sync record.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| event_instance_id | [string](#string) |  | The EventInstance to un-sync. |
| sync_destination_id | [string](#string) |  | The SyncDestination to un-sync it from. |






<a name="jonline-Event"></a>

### Event
An `Event` is a top-level type used to organize calendar events, RSVPs, and messaging/posting
about the `Event`. Actual time data lies in its `EventInstances`.

(Eventually, Jonline Events should also support ticketing.)


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| post | [Post](#jonline-Post) |  | The Post containing the underlying data for the event (title, content, moderation, visibility, etc.). Its [`PostContext`](#jonline-PostContext) should be `EVENT`. An `Event`&#39;s ID *is* its `post.id` -- there is no separate surrogate ID. |
| info | [EventInfo](#jonline-EventInfo) |  | Event configuration like whether to allow (anonymous) RSVPs, etc. |
| instances | [EventInstance](#jonline-EventInstance) | repeated | A list of instances for the Event. *Events will only include all instances if the request is for a single event.* |
| sync_source | [SyncSource](#jonline-SyncSource) | optional | If the event was synced from a source (meaning only its media should not be editable), this is the source it was synced from. |






<a name="jonline-EventAttendance"></a>

### EventAttendance
Could be called an &#34;RSVP.&#34; Describes the attendance of a user at an [`EventInstance`](#jonline-EventInstance). Such as:
* A user&#39;s RSVP to an [`EventInstance`](#jonline-EventInstance) (one of `INTERESTED`, `GOING`, `NOT_GOING`, or , `REQUESTED` (i.e. invited)).
* Invitation status of a user to an [`EventInstance`](#jonline-EventInstance).
* [`ContactMethod`](#jonline-ContactMethod)-driven management for anonymous RSVPs to an [`EventInstance`](#jonline-EventInstance).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | Unique server-generated ID for the attendance. |
| event_instance_id | [string](#string) |  | ID of the [`EventInstance`](#jonline-EventInstance) the attendance is for. |
| user_attendee | [UserAttendee](#jonline-UserAttendee) |  | If the attendance is non-anonymous, core data about the user. |
| anonymous_attendee | [AnonymousAttendee](#jonline-AnonymousAttendee) |  | If the attendance is anonymous, core data about the anonymous attendee. |
| number_of_guests | [uint32](#uint32) |  | Number of guests including the RSVPing user. (Minimum 1). |
| status | [AttendanceStatus](#jonline-AttendanceStatus) |  | The user&#39;s RSVP to an [`EventInstance`](#jonline-EventInstance) (one of `INTERESTED`, `REQUESTED` (i.e. invited), `GOING`, `NOT_GOING`) |
| inviting_user_id | [string](#string) | optional | User who invited the attendee. (Not yet used.) |
| private_note | [string](#string) |  | Public note for everyone who can see the event to see. |
| public_note | [string](#string) |  | Private note for the event owner. |
| moderation | [Moderation](#jonline-Moderation) |  | Moderation status for the attendance. Moderated by the [`Event`](#jonline-Event) owner (or [`EventInstance`](#jonline-EventInstance) owner if applicable). |
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
| hide_location_until_rsvp_approved | [bool](#bool) | optional | Hide the location until the user RSVPs (and it&#39;s accepted). From a system perspective, when this is set, Events will not include the [`Location`](#jonline-Location) until the user has RSVP&#39;d. Location will always be returned in EventAttendances if the request for the EventAttendances came from a (logged in or anonymous) user whose attendance is approved (or the event owner). |
| default_rsvp_moderation | [Moderation](#jonline-Moderation) | optional | Default moderation for RSVPs from logged-in users (either `PENDING` or `APPROVED`). Anonymous RSVPs are always moderated (default to `PENDING`). |






<a name="jonline-EventInstance"></a>

### EventInstance
The time-based component of an [`Event`](#jonline-Event). Has a `starts_at` and `ends_at` time,
a [`Location`](#jonline-Location), and an optional [`Post`](#jonline-Post) (and discussion thread) specific to this particular
`EventInstance` in addition to the parent [`Event`](#jonline-Event).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| event_id | [string](#string) |  | ID of the parent [`Event`](#jonline-Event) (i.e. the parent `Event.post.id`). |
| post | [Post](#jonline-Post) |  | Optional [`Post`](#jonline-Post) containing alternate title/link/description for this particular instance. Its [`PostContext`](#jonline-PostContext) should be `EVENT_INSTANCE`. An `EventInstance`&#39;s ID *is* its `post.id` -- there is no separate surrogate ID. |
| info | [EventInstanceInfo](#jonline-EventInstanceInfo) |  | Additional configuration for this instance of this [`EventInstance`](#jonline-EventInstance) beyond the [`EventInfo`](#jonline-EventInfo) in its parent [`Event`](#jonline-Event). |
| starts_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the event starts (UTC/Timestamp format). |
| ends_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the event ends (UTC/Timestamp format). |
| location | [Location](#jonline-Location) | optional | The location of the event. |
| sync_source_instance_id | [string](#string) | optional | The &#34;iCal ID&#34; (or external ID) of this instance, if its [`Event`](#jonline-Event) was synced from a [`SyncSource`](#jonline-SyncSource). |
| sync_missing_since | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time since this event &#34;disappeared&#34; from the sync source. It is up to the owner whether this means it should be deleted. |
| attendances | [EventAttendances](#jonline-EventAttendances) | optional | RSVP &#43; invite data for this instance. |
| current_user_attendance | [EventAttendance](#jonline-EventAttendance) | optional | If the request was made by a logged-in user, this is the current user&#39;s attendance for this instance. |
| sync_destinations | [SyncDestinationStatus](#jonline-SyncDestinationStatus) | repeated | SyncDestinations this instance has been synced (cross-posted) to, and their status. |






<a name="jonline-EventInstanceInfo"></a>

### EventInstanceInfo
To be used for ticketing, RSVPs, etc.
Stored as JSON in the database.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| rsvp_info | [EventInstanceRsvpInfo](#jonline-EventInstanceRsvpInfo) | optional | RSVP configuration and metadata for the event instance. |






<a name="jonline-EventInstanceRsvpInfo"></a>

### EventInstanceRsvpInfo
Consolidated type for RSVP info for an [`EventInstance`](#jonline-EventInstance).
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
Request to get Events in a formatted *per-EventInstance* structure. i.e. the response will carry duplicate [`Event`](#jonline-Event)s with the same ID
if that [`Event`](#jonline-Event) has multiple [`EventInstance`](#jonline-EventInstance)s in the time frame the client asked for.

These structured EventInstances are ordered by start time unless otherwise specified (specifically, `EventListingType.NEWLY_ADDED_EVENTS`).

Valid GetEventsRequest formats:
- `{[listing_type: PublicEvents]}`                 (TODO: get ServerPublic/GlobalPublic events you can see)
- `{listing_type:MyGroupsEvents|FollowingEvents}`  (TODO: get events for groups joined or user followed; auth required)
- `{post_id:}`                                     (get a single event, by its own Post ID or one of its EventInstances&#39; Post IDs)
- `{listing_type: GroupEvents| GroupEventsPendingModeration, group_id:}`
                                                   (TODO: get events/events needing moderation for a group)
- `{author_user_id:, group_id:}`                   (TODO: get events by a user for a group)
- `{listing_type: AuthorEvents, author_user_id:}`  (TODO: get events by a user)


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| author_user_id | [string](#string) | optional | Limits results to those by the given author user ID. |
| group_id | [string](#string) | optional | Limits results to those in the given group ID (via [`GroupPost`](#jonline-GroupPost) association&#39;s for the Event&#39;s internal [`Post`](#jonline-Post)). |
| time_filter | [TimeFilter](#jonline-TimeFilter) | optional | Filters returned [`EventInstance`](#jonline-EventInstance)s by time. |
| attendee_id | [string](#string) | optional | If set, only returns events that the given user is attending. If `attendance_statuses` is also set, returns events where that user&#39;s status is one of the given statuses. |
| attendance_statuses | [AttendanceStatus](#jonline-AttendanceStatus) | repeated | If set, only return events for which the current user&#39;s attendance status matches one of the given statuses. If `attendee_id` is also set, only returns events where the given user&#39;s status matches one of the given statuses. |
| post_id | [string](#string) | optional | Finds Events for the Post with the given ID. The Post should have a [`PostContext`](#jonline-PostContext) of `EVENT` or `EVENT_INSTANCE`. |
| listing_type | [EventListingType](#jonline-EventListingType) |  | The listing type, e.g. `ALL_ACCESSIBLE_EVENTS`, `FOLLOWING_EVENTS`, `MY_GROUPS_EVENTS`, `DIRECT_EVENTS`, `GROUP_EVENTS`, `GROUP_EVENTS_PENDING_MODERATION`. |
| search_text | [string](#string) | optional | Search text for full-text search. |
| event_instance_post_ids | [string](#string) | repeated | Loads multiple events by their event instances&#39; Post IDs -- returns one Event per matching EventInstance (see GetEventsResponse&#39;s own doc), not the requested EventInstance&#39;s whole parent Event&#39;s full instance list. |
| anonymous_attendee_auth_token | [string](#string) | optional | Auth token proving ownership of an anonymous RSVP, mirroring `GetEventAttendancesRequest.anonymous_attendee_auth_token`. Lets an anonymous attendee&#39;s own (possibly still-`PENDING`) [`EventAttendance`](#jonline-EventAttendance) and its `EventInstance.location` (when `EventInfo.hide_location_until_rsvp_approved` is set) surface via each returned `EventInstance.attendances`/`current_user_attendance`, same as a logged-in user&#39;s own RSVP does automatically. |






<a name="jonline-GetEventsResponse"></a>

### GetEventsResponse
A list of [`Event`](#jonline-Event)s with a maybe-incomplete (see [`GetEventsRequest`](#jonline-GetEventsRequest)) set of their [`EventInstance`](#jonline-EventInstance)s.

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






<a name="jonline-SyncEventInstanceRequest"></a>

### SyncEventInstanceRequest
Syncs (cross-posts) a single EventInstance to one SyncDestination.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| event_instance_id | [string](#string) |  | The EventInstance to sync. |
| sync_destination_id | [string](#string) |  | The SyncDestination to sync it to. |






<a name="jonline-TimeFilter"></a>

### TimeFilter
Time filter that works on the `starts_at` and `ends_at` fields of [`EventInstance`](#jonline-EventInstance).
API currently only supports `ends_after`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| starts_after | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Filter to events that start after the given time. |
| ends_after | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Filter to events that end after the given time. |
| starts_before | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Filter to events that start before the given time. |
| ends_before | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | Filter to events that end before the given time. |






<a name="jonline-UserAttendee"></a>

### UserAttendee
Wire-identical to [Author](#jonline-Author), but with a different name to avoid confusion.


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
| EVENT_TEXT_SEARCH | 5 | Returns posts matching the full-text `search_text` query, scoped the same way ALL_ACCESSIBLE_POSTS is (plus author_user_id, if provided). Requires search_text parameter. |
| GROUP_EVENTS | 10 | Returns events from a specific group. Requires group_id parameterRequires group_id parameter |
| GROUP_EVENTS_PENDING_MODERATION | 11 | Returns pending_moderation events from a specific group. Requires group_id parameter and user must have group (or server) admin permissions. |
| NEWLY_ADDED_EVENTS | 20 | Returns events from either `ALL_ACCESSIBLE_EVENTS` or a specific author (with optional author_user_id parameter). Returned EventInstances will be ordered by creation time rather than start time. |


 

 

 



<a name="server_configuration-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## server_configuration.proto



<a name="jonline-CustomHomePage"></a>

### CustomHomePage
Overrides the app&#39;s default `/` page (the combined Events&#43;Posts feed). Unlike a regular
`CustomNavigationTab`, this has no `path` (it&#39;s always `/`) and no `icon`/`title` (the server&#39;s
own name/logo are always shown for the Home tab in the nav, regardless of what it links to).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| tab | [NavigationTab](#jonline-NavigationTab) |  | What `/` renders. Only `HOME_TAB` (the default, combined Events&#43;Posts feed), `EVENTS_TAB`, or `POSTS_TAB` are valid here -- never `PEOPLE_TAB`/`ABOUT_TAB`. |
| post_id | [string](#string) |  | Renders a specific Post at `/` instead (e.g. for a custom business site&#39;s landing page). |
| pinned_post_ids | [string](#string) | repeated | Posts pinned to the top of the home page, above its normal content. Loaded the same way `StarredPanel` loads its own starred posts (i.e., conditionally fetching each pinned post&#39;s backing Event alongside it, for posts that are actually about an Event). |
| show_events_strip | [bool](#bool) |  | Shows the Events strip (the same horizontal upcoming-events row the default `HOME_TAB` always shows above its Posts feed) above `target`&#39;s own content. Only meaningful when `target` is `post_id` (pins an Events strip above that single Post); has no effect when `target` is unset/`HOME_TAB` (the strip is already shown) or `POSTS_TAB` (equivalent to just leaving `target` unset). |
| default_events_strip_to_row | [bool](#bool) |  | Whenever an Events strip is shown above other content -- `show_events_strip` is set, or `target` is unset/`HOME_TAB` (whose strip is always shown) -- whether it defaults to its row/list layout instead of a calendar. Unset defaults to the calendar layout. |
| default_events_strip_calendar_display_mode | [CalendarDisplayMode](#jonline-CalendarDisplayMode) |  | Whenever an Events strip is shown above other content (see `default_events_strip_to_row`&#39;s own doc) and defaults to the calendar layout (`default_events_strip_to_row` is unset), which granularity it opens to. Defaults to `CALENDAR_DISPLAY_WEEK`. |






<a name="jonline-CustomNavigationTab"></a>

### CustomNavigationTab
Either one of the app&#39;s predefined tabs, a Post, or a user profile -- reachable at `path`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| tab | [NavigationTab](#jonline-NavigationTab) |  | Links to one of the app&#39;s predefined tabs/pages. |
| post_id | [string](#string) |  | Links to a specific Post (e.g. for a custom business site&#39;s page). |
| is_profile | [bool](#bool) |  | Indicates the custom tab is for an actual user profile -- `path` is that user&#39;s username. Ultimately this isn&#39;t very &#34;custom&#34; in terms of the URL scheme, just it being a navigation tab. |
| emoji_icon | [string](#string) |  | Emoji shown as the tab&#39;s icon (e.g. &#34;🎪&#34;). |
| icon_media_id | [string](#string) |  | Media ID (see [`Media`](#jonline-Media) APIs) of an image shown as the tab&#39;s icon. |
| title | [string](#string) | optional | Title shown for the tab. Defaults to the predefined tab&#39;s/Post&#39;s title if unset. |
| path | [string](#string) |  | The path this tab is reachable at, e.g. `gigs` for a band&#39;s `/gigs` link to the Events page, or `weddings` for a Post about wedding offerings. Must be distinct across every entry in `CustomNavigationTabSet.tabs`. Note: `events`, `posts`, `people`, and `about` are reserved -- each may only be used to (redundantly) point back at its own matching predefined tab, never remapped to a different tab or a Post. `/` itself is never reachable this way -- it&#39;s overridden via `CustomNavigationTabSet.home` instead. |






<a name="jonline-CustomNavigationTabSet"></a>

### CustomNavigationTabSet
If set, overrides the default tab set for the Elm navigation on a Jonline instance.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| home | [CustomHomePage](#jonline-CustomHomePage) | optional | Overrides the default `/` page. If unset, the default combined Events&#43;Posts feed is used. |
| tabs | [CustomNavigationTab](#jonline-CustomNavigationTab) | repeated | Overrides the default tab set (`EVENTS_TAB`, `POSTS_TAB`, `PEOPLE_TAB`, `ABOUT_TAB`) entirely. Note: existing `/events`, `/posts`, `/people`, and `/about` paths are reserved for their matching predefined tab -- see [`CustomNavigationTab`](#jonline-CustomNavigationTab).path&#39;s own doc. `/` itself is overridden via `home` above instead. |






<a name="jonline-EventSettings"></a>

### EventSettings
Specific settings for Events.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| visible | [bool](#bool) |  | Hide the Events tab from the user with this flag. |
| default_moderation | [Moderation](#jonline-Moderation) |  | Only `UNMODERATED` and `PENDING` are valid. When `UNMODERATED`, user reports may transition status to `PENDING`. When `PENDING`, users&#39; SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not be visible until a moderator approves them. `LIMITED` visiblity posts are always visible to targeted users (who have not blocked the author) regardless of default_moderation. |
| default_visibility | [Visibility](#jonline-Visibility) |  | Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]` as appropriate. |
| alias_singular | [string](#string) | optional | Can be used to rename, e.g., &#34;Event&#34; to &#34;Gig&#34; or &#34;Performance&#34; |
| alias_plural | [string](#string) | optional | Can be used to rename, e.g. &#34;Events&#34; to &#34;Show,&#34; &#34;Game,&#34; &#34;Competition&#34; |
| enable_replies | [bool](#bool) | optional | Works the same as for Posts. |
| calendar_lookback_days | [uint32](#uint32) | optional | How far to look back for the &#34;Upcoming Events&#34; tab in the server&#39;s UI. Defaults to `14`. Servers with fewer events may want to set to a higher value. |
| default_calendar_display_mode | [CalendarDisplayMode](#jonline-CalendarDisplayMode) |  | What the Events Calendar&#39;s default UI mode will be. Defaults to `CALENDAR_DISPLAY_WEEK`. Servers with fewer events may want to set `CALENDAR_DISPLAY_MONTH`, or with more to `CALENDAR_DISPLAY_DAY`. |
| show_started_or_long_events_by_default | [bool](#bool) |  | Affects the Elm UI &#34;▽&#34; button on EventsPages (embedded or no). When this is false, that filter defaults to &#34;on.&#34; When true, that filter defaults to &#34;off.&#34;

For a band site (where you want to show your &#34;true calendar&#34;), this is best set to `true`. For a site where you have lots of event postings, it&#39;s best set to `false`. |






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
| alias_singular | [string](#string) | optional | Can be used to rename, e.g., &#34;Person&#34; to &#34;Contributor&#34; or &#34;Group&#34; to &#34;Community&#34; |
| alias_plural | [string](#string) | optional | Can be used to rename, e.g. &#34;Groups&#34; to &#34;Subtwaddits&#34; or &#34;People&#34; to &#34;Folks&#34; |






<a name="jonline-MediaSettings"></a>

### MediaSettings
Media is a special type and less customizable than &#34;Features.&#34;


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| visible | [bool](#bool) |  | Hide the Posts or Events tab from the user with this flag. |
| default_moderation | [Moderation](#jonline-Moderation) |  | Only `UNMODERATED` and `PENDING` are valid. When `UNMODERATED`, user reports may transition status to `PENDING`. When `PENDING`, users&#39; SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not be visible until a moderator approves them. `LIMITED` visiblity posts are always visible to targeted users (who have not blocked the author) regardless of default_moderation. |
| default_visibility | [Visibility](#jonline-Visibility) |  | Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]` as appropriate. |






<a name="jonline-PostSettings"></a>

### PostSettings
Specific settings for Posts.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| visible | [bool](#bool) |  | Hide the Posts tab from the user with this flag. |
| default_moderation | [Moderation](#jonline-Moderation) |  | Only `UNMODERATED` and `PENDING` are valid. When `UNMODERATED`, user reports may transition status to `PENDING`. When `PENDING`, users&#39; SERVER_PUBLIC or `GLOBAL_PUBLIC` posts will not be visible until a moderator approves them. `LIMITED` visiblity posts are always visible to targeted users (who have not blocked the author) regardless of default_moderation. |
| default_visibility | [Visibility](#jonline-Visibility) |  | Only `SERVER_PUBLIC` and `GLOBAL_PUBLIC` are valid. `GLOBAL_PUBLIC` is only valid if default_user_permissions contains `GLOBALLY_PUBLISH_[USERS|GROUPS|POSTS|EVENTS]` as appropriate. |
| alias_singular | [string](#string) | optional | Can be used to rename, e.g., &#34;Post&#34; &#34;Highlight&#34; or &#34;Squirt&#34; |
| alias_plural | [string](#string) | optional | Can be used to rename, e.g. &#34;Posts&#34; to &#34;Splurts&#34; or &#34;Memories&#34; |
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
| custom_tabs | [CustomNavigationTabSet](#jonline-CustomNavigationTabSet) | optional |  |
| people_settings | [FeatureSettings](#jonline-FeatureSettings) |  | Configuration for users on the server. If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_USERS_GLOBALLY`. |
| group_settings | [FeatureSettings](#jonline-FeatureSettings) |  | Configuration for groups on the server. If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_GROUPS_GLOBALLY`. |
| post_settings | [PostSettings](#jonline-PostSettings) |  | Configuration for posts on the server. If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_POSTS_GLOBALLY`. |
| event_settings | [EventSettings](#jonline-EventSettings) |  | Configuration for events on the server. If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_EVENTS_GLOBALLY`. |
| media_settings | [MediaSettings](#jonline-MediaSettings) |  | Configuration for media on the server. If default visibility is `GLOBAL_PUBLIC`, default_user_permissions *must* contain `PUBLISH_MEDIA_GLOBALLY`. |
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



<a name="jonline-CalendarDisplayMode"></a>

### CalendarDisplayMode
The Events Calendar&#39;s default UI granularity.

| Name | Number | Description |
| ---- | ------ | ----------- |
| CALENDAR_DISPLAY_WEEK | 0 | Shows a 7-day week at a time. Good default for most servers. |
| CALENDAR_DISPLAY_MONTH | 1 | Shows a full month at a time. Better for servers with fewer events. |
| CALENDAR_DISPLAY_DAY | 3 | Shows a single day at a time. Better for servers with many events. |



<a name="jonline-NavigationTab"></a>

### NavigationTab
The default navigation tabs in Jonline&#39;s Elm UI.

| Name | Number | Description |
| ---- | ------ | ----------- |
| HOME_TAB | 0 | The home/landing tab. |
| EVENTS_TAB | 10 | The Events tab. |
| POSTS_TAB | 11 | The Posts tab. |
| PEOPLE_TAB | 12 | The People tab. |
| ABOUT_TAB | 15 | The About tab. |



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
| ELM_SPA | 3 | Uses the Elm SPA client. Loaded from /elm. |


 

 

 



<a name="federation-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## federation.proto



<a name="jonline-FacebookAuthConfig"></a>

### FacebookAuthConfig
Facebook authentication configuration for the server.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| app_id | [string](#string) |  | The Facebook App ID for the server. |
| app_secret | [string](#string) |  | The Facebook App Secret for the server. *Never serialized to the client.* Admins: Edit this in the database&#39;s JSONB column directly. |






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
| facebook_auth_config | [FacebookAuthConfig](#jonline-FacebookAuthConfig) | optional | Facebook authentication configuration for the server. If set, allows users to create Facebook (and Instagram) SyncDestinations for their Posts and EventInstances. |
| x_twitter_auth_config | [XTwitterAuthConfig](#jonline-XTwitterAuthConfig) | optional | X (Twitter) authentication configuration for the server. If set, allows users to create X (Twitter) SyncDestinations for their Posts and EventInstances -- an admin registers one X Developer App here, and every user on the server connects their own X account through it via OAuth, the same relationship `facebook_auth_config` has to individual Facebook Pages. Until set, [`XTwitterAccount`](#jonline-XTwitterAccount) SyncDestinations always fail with `x_twitter_app_not_configured`. |






<a name="jonline-GetServiceVersionResponse"></a>

### GetServiceVersionResponse
Version information for the Jonline server.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| version | [string](#string) |  | The version of the Jonline server. May be suffixed with the GitHub SHA of the commit that generated the binary for the server. |






<a name="jonline-XTwitterAuthConfig"></a>

### XTwitterAuthConfig
X (Twitter) authentication configuration for the server. See `FederationInfo.x_twitter_auth_config`.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| client_id | [string](#string) |  | The X Developer App&#39;s Client ID for the server. |
| client_secret | [string](#string) |  | The X Developer App&#39;s Client Secret for the server. *Never serialized to the client.* Admins: Edit this in the database&#39;s JSONB column directly. |





 

 

 

 



<a name="sync-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## sync.proto



<a name="jonline-BlueskyAccount"></a>

### BlueskyAccount
A Bluesky (AT Protocol) account connected as a [`SyncDestination`](#jonline-SyncDestination) via an &#34;App Password&#34;
(generated at Settings &gt; App Passwords -- not the account&#39;s main password), rather than an
OAuth popup.

Media limitation: only attached *images* on a synced Post/EventInstance are posted (up to 4,
downloaded and re-uploaded as Bluesky blobs) -- video is silently dropped entirely. Bluesky
video embeds need a separate, more complex upload-and-processing flow not yet built.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| handle | [string](#string) |  | The account&#39;s handle, e.g. &#34;jon.bsky.social&#34;. |
| did | [string](#string) |  | The account&#39;s DID (decentralized identifier), populated by the server when the connection is made. |
| app_password | [string](#string) | optional | Only used (and required) on [`CreateSyncDestination`](#grpc-api-CreateSyncDestination)/[`UpdateSyncDestination`](#grpc-api-UpdateSyncDestination): the user&#39;s own App Password. Never populated in responses. Sessions are created fresh per post rather than stored/refreshed, since App Passwords don&#39;t expire. |






<a name="jonline-DeleteSyncDestinationRequest"></a>

### DeleteSyncDestinationRequest
Request to delete a SyncDestination.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| destination | [SyncDestination](#jonline-SyncDestination) |  | The destination to be deleted. |
| delete_synced_posts | [bool](#bool) |  | Whether to also delete posts already made on the destination (e.g. the Facebook Page posts). |






<a name="jonline-DeleteSyncSourceRequest"></a>

### DeleteSyncSourceRequest
Request to delete a SyncSource.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| source | [SyncSource](#jonline-SyncSource) |  | The source to be deleted. |
| delete_synced_events | [bool](#bool) |  | Whether to delete synced events. |






<a name="jonline-FacebookPage"></a>

### FacebookPage
A Facebook Page connected as a [`SyncDestination`](#jonline-SyncDestination) -- **never a personal profile**. Facebook
deprecated the `publish_actions` permission in 2018, which was the only way any third-party app
could ever post to a personal timeline; there&#39;s no Graph API call today, for any app, that can
post anything (feed post, photo, or otherwise) to a personal profile on a user&#39;s behalf. A Page
is the only kind of Facebook entity a self-hosted server like this can post to at all -- this
isn&#39;t a Jonline design choice to work around, it&#39;s a hard platform restriction. (Unrelated to
this: Facebook *Events* specifically are also unreachable, even for Pages -- see
`docs/facebook_and_x_twitter_federation.md`&#39;s &#34;It posts to the Page&#39;s feed, not a real Facebook
Event&#34; for that separate, independent 2018-era lockdown.)

Media limitation: a synced Post/EventInstance&#39;s attached video and images are mutually
exclusive on Facebook -- if both are present, the video is posted and any images are silently
dropped (Facebook Pages can&#39;t attach both to a single feed post).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| page_id | [string](#string) |  | The Facebook Page&#39;s ID. |
| page_name | [string](#string) |  | The Facebook Page&#39;s name, populated by the server when the connection is made. |
| short_lived_user_access_token | [string](#string) | optional | Only used (and required) on [`CreateSyncDestination`](#grpc-api-CreateSyncDestination): a short-lived user access token from client-side Facebook Login, exchanged server-side for a long-lived Page access token. Never populated in responses. |






<a name="jonline-GetSyncDestinationsResponse"></a>

### GetSyncDestinationsResponse
Response to a request for the current user&#39;s [`SyncDestination`](#jonline-SyncDestination)s.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| destinations | [SyncDestination](#jonline-SyncDestination) | repeated | The current user&#39;s SyncDestinations. |






<a name="jonline-GetSyncSourcesResponse"></a>

### GetSyncSourcesResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| sources | [SyncSource](#jonline-SyncSource) | repeated |  |






<a name="jonline-InstagramAccount"></a>

### InstagramAccount
An Instagram Business/Creator account connected as a [`SyncDestination`](#jonline-SyncDestination) -- **never a personal
Instagram account**. Unlike [`FacebookPage`](#jonline-FacebookPage)&#39;s restriction (a *deprecated* permission that used to let
apps post to a personal timeline), this one was never possible in the first place: Instagram&#39;s
Content Publishing API was built from the start only for professional (Business/Creator)
accounts, so a personal Instagram account simply has no API surface to post to at all,
regardless of what this server does. Posting to Instagram also requires the professional account
to be linked to a Facebook Page, so this reuses the same Facebook Login popup and app credentials
as [`FacebookPage`](#jonline-FacebookPage) -- the server exchanges the token for the Page&#39;s access token, then looks up
that Page&#39;s linked Instagram Business account.

Media limitation: only the *first* attached image/video on a synced Post/EventInstance is
posted -- no carousel/multi-image support yet. A post with no media at all is rejected
(`instagram_requires_media`) -- Instagram&#39;s Graph API has no text-only post type.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| instagram_business_account_id | [string](#string) |  | The Instagram Business/Creator account&#39;s ID, used for all Graph API posting calls. |
| username | [string](#string) |  | The Instagram account&#39;s @username, populated by the server when the connection is made. |
| page_id | [string](#string) |  | The linked Facebook Page&#39;s ID, kept for reference/reconnect. |
| short_lived_user_access_token | [string](#string) | optional | Only used (and required) on [`CreateSyncDestination`](#grpc-api-CreateSyncDestination): a short-lived user access token from client-side Facebook Login (same flow as [`FacebookPage`](#jonline-FacebookPage)), exchanged server-side for a long-lived Page access token, which is also used to post to the linked Instagram account. Never populated in responses. |






<a name="jonline-MastodonAccount"></a>

### MastodonAccount
A Mastodon account connected as a [`SyncDestination`](#jonline-SyncDestination) via a user-supplied Personal Access Token
(generated on the user&#39;s own instance, under Preferences &gt; Development), rather than an OAuth
popup -- Mastodon instances are user-chosen arbitrary domains, so there&#39;s no single app to
register ahead of time the way Facebook/Instagram have one.

Media: up to 4 attached images/videos on a synced Post/EventInstance are downloaded and
re-uploaded as real Mastodon media attachments (any mix of image/video types); a failed
individual upload is skipped rather than failing the whole post.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| instance_host | [string](#string) |  | The Mastodon instance&#39;s hostname, e.g. &#34;mastodon.social&#34;. |
| username | [string](#string) |  | The account&#39;s username on that instance, populated by the server when the connection is made. |
| access_token | [string](#string) | optional | Only used (and required) on [`CreateSyncDestination`](#grpc-api-CreateSyncDestination)/[`UpdateSyncDestination`](#grpc-api-UpdateSyncDestination): the user&#39;s own Personal Access Token for `instance_host`. Never populated in responses. |






<a name="jonline-SyncDestination"></a>

### SyncDestination
A user-owned destination to sync (cross-post) content out to. Mirrors [`SyncSource`](#jonline-SyncSource),
but for pushing content out rather than pulling content in. Originally Event-specific
(as `EventSyncDestination`), now shared by both [`EventInstance`](#jonline-EventInstance)s (see `events.proto`&#39;s
[`SyncEventInstanceRequest`](#jonline-SyncEventInstanceRequest)) and [`Post`](#jonline-Post)s (see `posts.proto`&#39;s [`SyncPostRequest`](#jonline-SyncPostRequest)).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | Unique ID for the destination. |
| owner | [Author](#jonline-Author) |  | The user information for the owner of this destination. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the SyncDestination was created. |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the SyncDestination was last updated. |
| synced_event_instance_count | [uint64](#uint64) | optional | The number of EventInstances synced to this destination so far. Computed with a `COUNT` at request time (unlike [`SyncSource`](#jonline-SyncSource)&#39;s `event_count`/`event_instance_count`, which are recomputed-and-stored on each sync) since destinations are pushed to on demand, not synced in bulk on an interval. |
| synced_post_count | [uint64](#uint64) | optional | The number of Posts synced to this destination so far. Computed the same way as `synced_event_instance_count`, just against Posts instead of EventInstances. |
| facebook_page | [FacebookPage](#jonline-FacebookPage) |  | A connected Facebook Page to post EventInstances/Posts to. |
| instagram_account | [InstagramAccount](#jonline-InstagramAccount) |  | A connected Instagram Business/Creator account to post EventInstances/Posts to. |
| mastodon_account | [MastodonAccount](#jonline-MastodonAccount) |  | A connected Mastodon account to post EventInstances/Posts to. |
| bluesky_account | [BlueskyAccount](#jonline-BlueskyAccount) |  | A connected Bluesky account to post EventInstances/Posts to. |
| x_twitter_account | [XTwitterAccount](#jonline-XTwitterAccount) |  | A connected X (Twitter) account to post EventInstances/Posts to. |
| threads_account | [ThreadsAccount](#jonline-ThreadsAccount) |  | A connected Threads account to post EventInstances/Posts to. |






<a name="jonline-SyncDestinationStatus"></a>

### SyncDestinationStatus
The status of a single piece of content&#39;s (an [`EventInstance`](#jonline-EventInstance) or [`Post`](#jonline-Post)) sync (cross-post) to
one [`SyncDestination`](#jonline-SyncDestination). Shared/generic so both `EventInstance.sync_destinations` and
`Post.sync_destinations` can reuse it.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| sync_destination_id | [string](#string) |  | The SyncDestination this status is for. |
| destination_instance_id | [string](#string) | optional | The ID of the resulting post on the destination (e.g. a Facebook Post ID). |
| destination_url | [string](#string) | optional | A link to the resulting post on the destination, if available. |
| synced_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time this content was last successfully synced to the destination. |






<a name="jonline-SyncSource"></a>

### SyncSource
A user-owned source to sync events from.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | Unique ID for the synchronization. |
| owner | [Author](#jonline-Author) |  | The user information for the owner of this sync source. |
| sync_interval_seconds | [uint64](#uint64) |  | How frequently the sync should happen in seconds. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the SyncSource was created. |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the SyncSource was last updated. |
| last_synced_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the SyncSource was last synced. |
| event_count | [uint64](#uint64) |  | The number of events total associated with this SyncSource. Recomputed on each sync. |
| event_instance_count | [uint64](#uint64) |  | The number of event instances total associated with this SyncSource. Recomputed on each sync. |
| post_count | [uint64](#uint64) |  | The number of posts total associated with this SyncSource. Not yet populated -- no source type syncs posts in yet. |
| ics_subscription_url | [string](#string) |  | The iCal subscription URL for the calendar sync. |






<a name="jonline-ThreadsAccount"></a>

### ThreadsAccount
A connected Threads account -- **a genuinely personal account works fine here**, unlike
[`FacebookPage`](#jonline-FacebookPage)/[`InstagramAccount`](#jonline-InstagramAccount): the Threads API (a separate product from Instagram&#39;s,
launched 2024) has no Page-linkage or Business/Creator-account requirement at all -- Threads
OAuth directly authorizes whatever single Threads account the user logs in with, personal or
not. It&#39;s still a product added to this server&#39;s existing Meta App (see [`FacebookAuthConfig`](#jonline-FacebookAuthConfig))
rather than a separately-registered app, so no separate auth config is needed. Unlike
[`FacebookPage`](#jonline-FacebookPage)/[`InstagramAccount`](#jonline-InstagramAccount), connecting one is a `response_type=code` OAuth flow at
threads.net (not facebook.com) with no &#34;choose a Page&#34; step -- the code is exchanged server-side
for a short-lived token, then a long-lived one (~60 day expiry, refreshable via
`grant_type=th_refresh_token` -- not yet implemented; a connected destination will need
reconnecting after ~60 days until a refresh job exists).

Media limitation: only the *first* attached image/video on a synced Post/EventInstance is
posted -- no carousel/multi-image support yet. Unlike [`InstagramAccount`](#jonline-InstagramAccount), a text-only post
(no media at all) is valid.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| threads_user_id | [string](#string) |  | The account&#39;s Threads user ID, used for all posting calls. |
| username | [string](#string) |  | The account&#39;s @username, populated by the server when the connection is made. |
| authorization_code | [string](#string) | optional | Only used (and required) on [`CreateSyncDestination`](#grpc-api-CreateSyncDestination): the OAuth authorization code from the Threads login popup. Never populated in responses. |






<a name="jonline-XTwitterAccount"></a>

### XTwitterAccount
An X (Twitter) account connected as a [`SyncDestination`](#jonline-SyncDestination), via an OAuth 2.0 Authorization Code &#43;
PKCE flow at x.com. Requires this server to have a registered X Developer App configured (see
`FederationInfo.x_twitter_auth_config`) -- every RPC touching an `XTwitterAccount` destination
fails with `x_twitter_app_not_configured` until an admin sets one, mirroring
[`FacebookAuthConfig`](#jonline-FacebookAuthConfig)/`facebook_app_not_configured`. Unlike Facebook/Instagram/Threads (which reuse one
Meta App), an admin registers this app once and every user on the server connects their own X
account through it -- no per-user API keys needed.

Media limitation: up to 4 attached *images* on a synced Post/EventInstance are downloaded and
re-uploaded via X&#39;s media upload endpoint. Video is not yet supported -- X&#39;s video upload
requires a chunked upload-and-processing flow (mirroring Bluesky&#39;s own documented video gap)
not yet built; a video attachment is silently skipped.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| username | [string](#string) |  | The account&#39;s @username, populated by the server when the connection is made. |
| x_user_id | [string](#string) |  | The account&#39;s numeric X user ID, populated by the server when the connection is made. |
| authorization_code | [string](#string) | optional | Only used (and required) on [`CreateSyncDestination`](#grpc-api-CreateSyncDestination): the OAuth authorization code from the X login popup. Never populated in responses. |
| code_verifier | [string](#string) | optional | Only used (and required, alongside `authorization_code`) on [`CreateSyncDestination`](#grpc-api-CreateSyncDestination): the PKCE code verifier the popup generated before sending its paired `code_challenge` to X&#39;s authorize endpoint. X mandates PKCE (unlike Threads/Facebook&#39;s plain code exchange), so the server needs this to complete the token exchange. Never populated in responses. |





 

 

 

 



<a name="ai_model_providers-proto"></a>
<p align="right"><a href="#top">Top</a></p>

## ai_model_providers.proto



<a name="jonline-AIModelProvider"></a>

### AIModelProvider
An AIModelProvider is a user-owned connection to an external AI model API (e.g. a Gemini API
key), which its owner can grant other users of this server metered, budgeted access to. Mirrors
[`SyncDestination`](#jonline-SyncDestination)/[`SyncSource`](#jonline-SyncSource) (also user-owned integrations
with an [`Author`](#jonline-Author) `owner` and a `oneof` naming which external system is configured), but where
those push/pull content, an AIModelProvider is metered *access* to a third-party LLM API -- shared out to
other users via [`AIModelProviderGrant`](#jonline-AIModelProviderGrant)s rather than posted-to/subscribed-from.

Providers are managed via [`GetAIModelProviders`](#grpc-api-GetAIModelProviders),
[`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider) (requires `CREATE_AI_MODEL_PROVIDERS`, or Admin),
[`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider) (owner, or Admin for any user&#39;s), and
[`DeleteAIModelProvider`](#grpc-api-DeleteAIModelProvider) (owner, or Admin) -- the same self-or-Admin shape as
[`SyncDestination`](#jonline-SyncDestination)&#39;s RPCs. Access to a provider is granted/revoked to other users via
[`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider)/[`RevokeAIModelProvider`](#grpc-api-RevokeAIModelProvider) which,
unlike every other RPC pair here, are **owner-only with no Admin override**: an Admin can manage the provider
record itself (rename it, rotate its key, delete it), but handing out access to *someone else&#39;s* API budget is a
call only its owner should be able to make.

[`GeminiCredentials`](#jonline-GeminiCredentials)/[`OpenAICredentials`](#jonline-OpenAICredentials)/
[`DigitalOceanCredentials`](#jonline-DigitalOceanCredentials) all have a working connection flow (Gemini&#39;s
Interactions API, OpenAI&#39;s Images API, DigitalOcean&#39;s Serverless Inference API -- the last of which is also
OpenAI-Images-API-shaped, just a different base URL/key and generation-only, no editing endpoint);
[`AnthropicCredentials`](#jonline-AnthropicCredentials) is defined for forward compatibility but is not yet
accepted by [`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider) (Anthropic doesn&#39;t offer image generation).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| id | [string](#string) |  | Unique ID for the AIModelProvider. |
| owner | [Author](#jonline-Author) |  | The user information for the owner of this AIModelProvider -- the only user (besides Admins) who may rename it or change its credentials/provider, and the *only* user (not even Admins) who may grant/revoke other users&#39; access to it. |
| name | [string](#string) |  | A display name for the provider, chosen by its owner (e.g. &#34;My Gemini Key&#34;, &#34;Team OpenAI Account&#34;). Purely cosmetic -- has no effect on behavior. |
| gemini_credentials | [GeminiCredentials](#jonline-GeminiCredentials) |  | A Google Gemini API connection (see `ai.google.dev/gemini-api`), used for image generation/editing (e.g. generating Event posters) via its Interactions API. |
| openai_credentials | [OpenAICredentials](#jonline-OpenAICredentials) |  | An OpenAI API connection (see `platform.openai.com/docs/guides/image-generation`), used for image generation/editing via its Images API (GPT Image models). |
| anthropic_credentials | [AnthropicCredentials](#jonline-AnthropicCredentials) |  | An Anthropic API connection. *Not yet creatable* -- Anthropic doesn&#39;t offer an image generation API. |
| digitalocean_credentials | [DigitalOceanCredentials](#jonline-DigitalOceanCredentials) |  | A DigitalOcean Gradient AI Platform / Serverless Inference connection (see `docs.digitalocean.com/products/inference`), used for image generation (no editing -- DigitalOcean&#39;s Serverless Inference API has no `/v1/images/edits`-equivalent endpoint) via its OpenAI-Images-API-shaped `/v1/images/generations` endpoint (GPT Image and Stable Diffusion models, re-hosted under DigitalOcean&#39;s own billing). |
| grants | [AIModelProviderGrant](#jonline-AIModelProviderGrant) | repeated | Other users this provider&#39;s owner has granted metered access to, via [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider). Only ever populated for the owner (or an Admin) -- see [`GetAIModelProviders`](#grpc-api-GetAIModelProviders). |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the provider was created. |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the provider was last updated (renamed, or had its provider/credentials changed). |






<a name="jonline-AIModelProviderGrant"></a>

### AIModelProviderGrant
A grant of metered access to someone else&#39;s [`AIModelProvider`](#jonline-AIModelProvider), created/reset via
[`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider) and removed via
[`RevokeAIModelProvider`](#grpc-api-RevokeAIModelProvider). Upserted on the unique
`(ai_model_provider_id, ai_model_grantee)` pair -- calling [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider)
again for a user who already has a grant *resets* `tokens_remaining` to the newly-requested amount, it does not
add to it.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| ai_model_provider_id | [string](#string) |  | The ID of the [`AIModelProvider`](#jonline-AIModelProvider) this grant is for. |
| ai_model_grantee | [Author](#jonline-Author) |  | The user this access was granted to. |
| model_names | [string](#string) | repeated | The model name (that will be used to call the provider) that the grantee is allowed to use by this grant. If blank, allows access to any models the provider supports. If non-blank, the grantee is only allowed to use the model(s) specified here. Allows granters to set per-model (or per-model-group) token budgets, e.g. &#34;gpt-4&#34; vs &#34;gpt-3.5-turbo&#34;. |
| tokens_remaining | [uint64](#uint64) |  | The number of tokens the grantee may still spend against this provider. Set (and reset) by the owner via [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider). Once this reaches 0, [`GenerateMedia`](#grpc-api-GenerateMedia) stops working for the grantee entirely, until the owner grants more via [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider) again. |
| overage | [uint64](#uint64) |  | How far a single [`GenerateMedia`](#grpc-api-GenerateMedia) call&#39;s actual token usage overshot `tokens_remaining` the moment it hit 0 -- effectively a &#34;negative `tokens_remaining`&#34; (which, being `uint64`, can&#39;t represent a negative value directly), recorded here instead as a positive debt for the owner&#39;s own visibility. E.g. a grantee with 30 tokens left whose next call actually costs 45 ends up with `tokens_remaining = 0` and `overage = 15`. Always 0 immediately after a fresh [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider) call (any prior debt is cleared, not carried forward) -- see that RPC&#39;s own doc. |
| created_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) |  | The time the grant was first created. |
| updated_at | [google.protobuf.Timestamp](#google-protobuf-Timestamp) | optional | The time the grant was last updated (i.e. last reset by another [`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider) call). |






<a name="jonline-AnthropicCredentials"></a>

### AnthropicCredentials
Credentials for an Anthropic API connection. *Not yet creatable* -- defined for forward compatibility only.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| anthropic_api_key | [string](#string) | optional | The Anthropic API key. Never populated in responses (see [`GeminiCredentials.gemini_api_key`](#jonline-GeminiCredentials)). |






<a name="jonline-AvailableAIModel"></a>

### AvailableAIModel
One specific model a user may call right now, and how -- via an [`AIModelProvider`](#jonline-AIModelProvider)
they own outright (`grant` unset), or via an [`AIModelProviderGrant`](#jonline-AIModelProviderGrant) someone else
granted them (`grant` set). Only ever defined relative to a user -- see
[`User.available_ai_models`](#jonline-User)/[`GetAIModelProvidersResponse.available_ai_models`](#jonline-GetAIModelProvidersResponse).
One `AvailableAIModel` exists per (provider, model) pair: an owner gets one row per model their
provider supports (see the server&#39;s own model catalog per provider type); a grantee gets one row
per model their grant actually covers -- expanded from `AIModelProviderGrant.model_names`, or
every model the provider supports if that list is empty.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| model_name | [string](#string) |  | The exact model name to use when calling the provider (e.g. `&#34;gemini-3.1-flash-image&#34;`). |
| capabilities | [AIModelCapability](#jonline-AIModelCapability) | repeated | What this model can actually do -- from the server&#39;s own hardcoded catalog for `provider.provider`&#39;s variant (see [`AIModelCapability`](#jonline-AIModelCapability)), not anything reported by the provider&#39;s API itself. Feature gating keys off this rather than `model_name` directly, so e.g. [`GenerateMedia`](#grpc-api-GenerateMedia) (which needs `AI_MODEL_CAPABILITY_IMAGE_EDITING` whenever `GenerateMediaRequest.media_ids` is non-empty, or just `AI_MODEL_CAPABILITY_IMAGE_GENERATION` when it&#39;s empty) doesn&#39;t need its own hardcoded list of model names. |
| grant | [AIModelProviderGrant](#jonline-AIModelProviderGrant) | optional | The grant that allows this access, when the current user isn&#39;t `provider.owner` themselves. Unset when the current user owns `provider` outright (full, ungated access -- no grant needed). |
| provider | [AIModelProvider](#jonline-AIModelProvider) |  | The provider this model belongs to. Its own `grants` list is only populated when the current user is `provider.owner` (or an Admin) -- see [`GetAIModelProviders`](#grpc-api-GetAIModelProviders)&#39;s own doc; a mere grantee never sees who else has been granted access to a provider they don&#39;t own. |






<a name="jonline-DeleteAIModelProviderRequest"></a>

### DeleteAIModelProviderRequest
Request to delete an AIModelProvider. Also deletes any of its [`AIModelProviderGrant`](#jonline-AIModelProviderGrant)s.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| provider | [AIModelProvider](#jonline-AIModelProvider) |  | The provider to be deleted. |






<a name="jonline-DigitalOceanCredentials"></a>

### DigitalOceanCredentials
Credentials for a DigitalOcean Gradient AI Platform / Serverless Inference connection, accepted by
[`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider)/[`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider).
Used for image *generation only* (no editing -- see `AIModelProvider.provider`&#39;s own doc on this variant) via
`https://inference.do-ai.run/v1/images/generations`, an OpenAI-Images-API-shaped endpoint re-hosting GPT Image
and Stable Diffusion models -- see [`GenerateMedia`](#grpc-api-GenerateMedia).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| digitalocean_api_key | [string](#string) | optional | The DigitalOcean Serverless Inference API token. Required (and only used) on [`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider)/[`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider) -- never populated in responses (see [`GeminiCredentials.gemini_api_key`](#jonline-GeminiCredentials)). |






<a name="jonline-GeminiCredentials"></a>

### GeminiCredentials
Credentials for a Google Gemini API connection (`ai.google.dev/gemini-api`) -- the only
[`AIModelProvider.provider`](#jonline-AIModelProvider) variant currently accepted by
[`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider)/[`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider).
Used for image generation/editing via Gemini&#39;s Interactions API (`ai.google.dev/gemini-api/docs/image-generation`),
e.g. to generate/edit Event posters from an Event&#39;s own content -- see [`GenerateMedia`](#grpc-api-GenerateMedia).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| gemini_api_key | [string](#string) | optional | The Gemini API key. Required (and only used) on [`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider)/[`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider) -- **never populated in responses**, the same write-only convention as e.g. [`MastodonAccount.access_token`](#jonline-MastodonAccount) in `sync.proto`. |






<a name="jonline-GenerateMediaRequest"></a>

### GenerateMediaRequest
Request to generate (or edit) an image via one of the current user&#39;s
[`AvailableAIModel`](#jonline-AvailableAIModel)s -- see [`GenerateMedia`](#grpc-api-GenerateMedia). The resulting
image is stored as a new [`Media`](#jonline-Media) (`generated = true`) owned by the current user, and -- if
`target` is set -- prepended as the *first* item in that Post&#39;s (or Event&#39;s own Post&#39;s) `media` list.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| model | [AvailableAIModel](#jonline-AvailableAIModel) |  | Which of the current user&#39;s `AvailableAIModel`s to generate with -- `model.model_name` selects the actual model, `model.provider.id` identifies whose `AIModelProvider` (the current user&#39;s own, or one they&#39;ve been granted access to) to call it through. Only `model_name`/`provider.id` are read server-side -- any other field sent here (e.g. a spoofed `grant`) is ignored in favor of the caller&#39;s real access, re-derived from `provider.id` and the current user. |
| user_prompt | [string](#string) |  | The user-editable prompt describing what to generate, e.g. &#34;Please generate a square headline poster for the following event.&#34; Combined server-side with `target`&#39;s own formatted content (title/description/date-time range/location -- the same formatting [`SyncDestination`](#jonline-SyncDestination)s use) before being sent to the model, so the user never has to paste that context in by hand. |
| media_ids | [string](#string) | repeated | Existing [`Media`](#jonline-Media) to pass to the model alongside `user_prompt`, for image editing/ reference-based generation (e.g. a target Post/Event&#39;s own current photos), in the order given here. Leave empty for plain text-to-image generation instead -- `model` must have the matching capability either way (`AI_MODEL_CAPABILITY_IMAGE_EDITING` here, `AI_MODEL_CAPABILITY_IMAGE_GENERATION` if empty -- see [`AIModelCapability`](#jonline-AIModelCapability)&#39;s own doc). Every id must be owned by the current user (or the current user must be an Admin). |
| post_id | [string](#string) |  | Attach to (and use the content of) this Post. Caller must be its author, or an Admin. |
| event_instance_id | [string](#string) |  | Attach to (and use the content of) this EventInstance&#39;s parent Event&#39;s own Post -- named by EventInstance, not Event, since that&#39;s what a viewer is actually looking at (and what gives the generated prompt its date/time/location context, the same way [`SyncEventInstance`](#grpc-api-SyncEventInstance) does). Caller must be the Event&#39;s own Post&#39;s author, or hold `MODERATE_POSTS`/`MODERATE_EVENTS`, or be an Admin. |






<a name="jonline-GetAIModelProvidersResponse"></a>

### GetAIModelProvidersResponse
Response to a request for a user&#39;s [`AIModelProvider`](#jonline-AIModelProvider)s.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| providers | [AIModelProvider](#jonline-AIModelProvider) | repeated | The requested user&#39;s own AIModelProviders (those they own) -- exactly the distinct `provider`s in `available_ai_models` whose `owner` is the requested user, each with its own `grants` populated (who else can use it). A convenience duplicate of data already in `available_ai_models`, so callers managing a user&#39;s own providers (rename/rekey/delete/grant/ revoke) don&#39;t have to de-duplicate that list themselves. |
| available_ai_models | [AvailableAIModel](#jonline-AvailableAIModel) | repeated | Every model the requested user may currently call -- their own providers&#39; models, plus any models granted to them on other users&#39; providers. See [`AvailableAIModel`](#jonline-AvailableAIModel)&#39;s own doc. |






<a name="jonline-GrantAIModelProviderRequest"></a>

### GrantAIModelProviderRequest
Request to grant (or reset) another user&#39;s metered access to one of the current user&#39;s
[`AIModelProvider`](#jonline-AIModelProvider)s. *Authenticated, owner-only -- no Admin override.*


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user_id | [string](#string) |  | The user to grant access to. |
| ai_model_provider_id | [string](#string) |  | The AIModelProvider to grant access to. Must be owned by the caller. |
| tokens | [uint64](#uint64) |  | The number of tokens the grantee may spend. Calling this RPC again for the same (`ai_model_provider_id`, `user_id`) pair *replaces*, rather than adds to, this value. |
| model_names | [string](#string) | repeated | The models the grantee is allowed to use, mirroring [`AIModelProviderGrant.model_names`](#jonline-AIModelProviderGrant) -- if empty, allows access to any model the provider supports. Also replaced (not merged) on a repeat call, same as `tokens`. |






<a name="jonline-OpenAICredentials"></a>

### OpenAICredentials
Credentials for an OpenAI API connection, accepted by
[`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider)/[`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider).
Used for image generation/editing via OpenAI&#39;s Images API (`platform.openai.com/docs/guides/image-generation`,
the GPT Image model family) -- same use case as [`GeminiCredentials`](#jonline-GeminiCredentials), see
[`GenerateMedia`](#grpc-api-GenerateMedia).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| openai_api_key | [string](#string) | optional | The OpenAI API key. Required (and only used) on [`CreateAIModelProvider`](#grpc-api-CreateAIModelProvider)/[`UpdateAIModelProvider`](#grpc-api-UpdateAIModelProvider) -- never populated in responses (see [`GeminiCredentials.gemini_api_key`](#jonline-GeminiCredentials)). |






<a name="jonline-RevokeAIModelProviderRequest"></a>

### RevokeAIModelProviderRequest
Request to revoke another user&#39;s access to one of the current user&#39;s
[`AIModelProvider`](#jonline-AIModelProvider)s, the reverse of
[`GrantAIModelProvider`](#grpc-api-GrantAIModelProvider). *Authenticated, owner-only -- no Admin override.*


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| user_id | [string](#string) |  | The user whose access should be revoked. |
| ai_model_provider_id | [string](#string) |  | The AIModelProvider to revoke access to. Must be owned by the caller. |





 


<a name="jonline-AIModelCapability"></a>

### AIModelCapability
What an [`AvailableAIModel`](#jonline-AvailableAIModel) can actually do -- drives feature gating
(e.g. [`GenerateMedia`](#grpc-api-GenerateMedia)&#39;s &#34;Generate Media…&#34; buttons/panel only offer
models carrying `AI_MODEL_CAPABILITY_IMAGE_EDITING`/`AI_MODEL_CAPABILITY_IMAGE_GENERATION`)
without the gated feature needing its own hardcoded list of model names to check against. A
model may carry more than one -- e.g. an image-editing model can also usually do plain
text-to-image generation.

| Name | Number | Description |
| ---- | ------ | ----------- |
| AI_MODEL_CAPABILITY_UNKNOWN | 0 | The model&#39;s capabilities are unknown (e.g. the server doesn&#39;t know what this provider supports). |
| AI_MODEL_CAPABILITY_TEXT_GENERATION | 1 | The model can generate new text from a prompt. |
| AI_MODEL_CAPABILITY_IMAGE_GENERATION | 2 | The model can generate a new image from a text prompt alone -- what [`GenerateMedia`](#grpc-api-GenerateMedia) requires when `GenerateMediaRequest.media_ids` is empty (no reference images to edit with). |
| AI_MODEL_CAPABILITY_IMAGE_EDITING | 3 | The model can edit an existing image, given a text prompt and one or more reference images -- what [`GenerateMedia`](#grpc-api-GenerateMedia) requires instead, whenever `GenerateMediaRequest.media_ids` is non-empty. Not every model with `AI_MODEL_CAPABILITY_IMAGE_GENERATION` also has this -- some (e.g. the cheaper/faster `gemini-3.1-flash-lite-image` tier) only support plain generation. |


 

 

 



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

