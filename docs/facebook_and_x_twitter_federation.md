# Facebook and X (Twitter) Sync

Jonline's "Sync Destinations" feature lets a user connect one of their Facebook Pages as a
[`SyncDestination`](https://jonline.io/docs/protocol#jonline-SyncDestination), so calling [`SyncEventInstance`](https://jonline.io/docs/protocol#grpc-api-SyncEventInstance) or [`SyncPost`](https://jonline.io/docs/protocol#grpc-api-SyncPost) posts the [`EventInstance`](https://jonline.io/docs/protocol#jonline-EventInstance)/[`Post`](https://jonline.io/docs/protocol#jonline-Post) to
that Page. Implementation: [`backend/src/logic/facebook_sync.rs`](../backend/src/logic/facebook_sync.rs),
invoked from [`SyncEventInstance`](../backend/src/rpcs/events/sync_event_instance.rs) and
[`SyncPost`](../backend/src/rpcs/posts/sync_post.rs) alike (both dispatch through the same
`post_to_facebook_page`, sharing every Facebook-specific detail below regardless of content type).

This doc also covers X (Twitter) sync (see "X (Twitter)" below) since the two share a section for
now -- unlike Facebook, X sync isn't functional yet, so there isn't much to say about it on its
own. (Instagram, Mastodon, Bluesky, and Threads sync each have their own quirks worth documenting
separately if this file grows unwieldy -- for now, see each platform's own message doc comment in
[`protos/sync.proto`](../protos/sync.proto) and `protos/jonline.proto`'s `##### SyncDestination`
section for the rest.)

## It posts to the Page's feed, not a real Facebook Event

Posting an [`EventInstance`](https://jonline.io/docs/protocol#jonline-EventInstance) creates a Facebook **Page post** (`POST /{page-id}/feed`) formatted to
read like an event announcement, or attaches its media (see "What's in the post" below) -- it does
**not** create an actual Facebook **Event** object (the kind users can RSVP to natively on
Facebook), because the Graph API no longer allows that for ordinary third-party apps:

- `POST /{page-id}/events` (and update/delete) has been locked down since Graph API v3.3 (2018).
  Meta's own reference for the `event` node states creation isn't supported on that endpoint at
  all.
- Even *reading* Page/User events via the Graph API is restricted to approved **Facebook Marketing
  Partners** -- a vetted-agency program (minimum ad spend/message volume, ongoing compliance
  review) that isn't a realistic fit for a self-hosted Jonline server.
- Real integrations that appear to "create a Facebook Event" (e.g. Eventbrite) don't do it via a
  server-side API call either -- they deep-link the user's own browser into Facebook's native
  "Create Event" UI, pre-filled, and the human finishes it themselves.
- Meta does have an [Official Events API](https://developers.facebook.com/products/official-events-api/)
  product that *can* create real Events at scale, but it's gated behind a partner application
  (aimed at large ticketing/event platforms, not individual self-hosted servers) -- and as of this
  writing that page's own "Apply Now" link (`facebook.com/help/contact/FacebookEventsPartnerInquiryForm`)
  404s, with stale "pausing onboarding due to COVID-19" copy still up. Not a viable path.

So the Page-post approach here is the best available server-side option, not an oversight. (This
limitation is specific to *Events* -- a [`Post`](https://jonline.io/docs/protocol#jonline-Post) has no such native-object alternative to begin with,
so its Page post is simply the whole feature for Posts.)

## What's in the post

`logic::sync_message::build_event_instance_message`/`build_post_message` build one
platform-agnostic `SyncMessage` per sync (shared by every [`SyncDestination`](https://jonline.io/docs/protocol#jonline-SyncDestination) platform, not just
Facebook) from the content's own [`Post`](https://jonline.io/docs/protocol#jonline-Post) (`title`/`content`/`link`) and, for an [`EventInstance`](https://jonline.io/docs/protocol#jonline-EventInstance),
also its `starts_at`/`ends_at`/`location`:

1. Title -- for an EventInstance, `rpcs::events::sync_event_instance` combines the parent Event's
   own title with the instance's own (only if the instance actually overrides it) as
   `"{event_title}: {instance_title}"`, e.g. "Run Club" or "Run Club: Special Holiday Edition" (see
   `combine_title`/`combine_content` in that file)
2. *(EventInstance only)* Date/time range (single timestamp if `ends_at` isn't after `starts_at`,
   otherwise a friendly `start-end` range mirroring the Elm UI's own `Shared.Time.formatRange`;
   shown in the event location's local timezone if it could be resolved, else UTC -- see below)
3. *(EventInstance only)* Location (`EventInstance.location.uniformly_formatted_address`), if set,
   prefixed with 📍
4. Content/description -- for an EventInstance, the same combine-with-a-`---`-separator treatment
   as the title (`"{event_content}\n\n---\n\n{instance_content}"`)
5. The Jonline link (`event_url`/`post_url`), bare (EventInstance) or prefixed `View post:` (Post),
   if one could be built (see below)

`post_to_facebook_page` (in `facebook_sync.rs`) then decides how to send that `SyncMessage` to the
Page: text+link only if there's no attached media, one or more unpublished-photo uploads followed
by a `/feed` post referencing them (`attached_media[N]`) if there are images, or a dedicated
`/videos` post if there's a video (video wins if both are present -- the Graph API can't mix photo
attachments and a video in one Page post). The `link` param (which drives a text-only post's
link-preview card) prefers the Jonline URL; if that isn't available it falls back to the arbitrary
external `link` the author/organizer set on the [`Post`](https://jonline.io/docs/protocol#jonline-Post) itself (e.g. an article or ticketing site).

## Local-timezone times via free-text address geocoding

`EventInstance.location` only stores a free-text `uniformly_formatted_address` (no lat/lng --
see `protos/location.proto`), so showing times in the event's local timezone instead of UTC needs
resolving that address to a timezone first. `logic::geocoding` (`resolve_timezone`) does this in
two keyless, free steps, chained on every sync (never cached/persisted -- see "future work"
below):

1. **Address -> lat/lng**: OpenStreetMap's public Nominatim API (`nominatim.openstreetmap.org`) --
   the same service the Tamagui frontend's location picker already calls client-side
   (`packages/app/hooks/use_nominatim.ts`), just used server-side here too. Its response already
   includes `lat`/`lon`, which the Tamagui picker currently fetches and discards -- only
   `display_name` gets saved into the [`Location`](https://jonline.io/docs/protocol#jonline-Location).
2. **lat/lng -> IANA timezone**: the [`tzf-rs`](https://github.com/ringsaturn/tzf-rs) crate, an
   offline polygon-based dataset bundled into the binary -- no second network call, no rate limit,
   actively maintained.

Nominatim's [usage policy](https://operations.osmfoundation.org/policies/nominatim/) caps public
API use at roughly 1 request/second and requires a descriptive `User-Agent`, which is fine for
this on-demand, per-sync-click call but not for bulk/automated geocoding.

This is entirely best-effort: any failure (bad address, network error, unparseable response, no
geocoding match) makes `resolve_timezone` return `None`, and the post just falls back to UTC --
never a reason to fail the sync itself.

**Possible future work**: since Tamagui's Nominatim call already has `lat`/`lon` in hand at
location-pick time, persisting those on [`Location`](https://jonline.io/docs/protocol#jonline-Location) (proto + DB + both frontends) would let syncs
skip the live geocoding call entirely and use `tzf-rs` directly -- faster, no dependency on
Nominatim's uptime/policy, and it would also cover Elm-created locations if Elm ever gains its own
address picker (today Elm's location field is plain free text with no geocoding at all).

## The Jonline link needs CDN/frontend config

The `event_url`/`post_url` (`https://{frontend_host}/event/{instance_id}` or
`https://{frontend_host}/post/{post_id}`) is only built when this server has
`ServerConfiguration.external_cdn_config.frontend_host` configured. Unlike Rocket web routes
(`configured_frontend_domain` in `backend/src/web/external_cdn.rs`), the [`SyncEventInstance`](https://jonline.io/docs/protocol#grpc-api-SyncEventInstance)/
[`SyncPost`](https://jonline.io/docs/protocol#grpc-api-SyncPost) RPCs have no HTTP `Host` header to fall back on, so on servers without `frontend_host`
set, the post simply omits the Jonline link (falling back to the author's own `Post.link`, if any)
rather than guessing a domain. This is an accepted current limitation, not a bug -- set
`frontend_host` if you want synced posts to link back to their Jonline page.

## Connecting a Page (OAuth/token flow)

1. The client does Facebook Login and gets a short-lived **user** access token, passed to
   [`CreateSyncDestination`](https://jonline.io/docs/protocol#grpc-api-CreateSyncDestination) (or [`UpdateSyncDestination`](https://jonline.io/docs/protocol#grpc-api-UpdateSyncDestination) to reconnect).
2. The server loads its own Facebook App ID/Secret (admin-configured via [`ConfigureServer`](https://jonline.io/docs/protocol#grpc-api-ConfigureServer) ->
   `ServerConfiguration.federation_info.facebook_auth_config`) and exchanges the short-lived user
   token for a long-lived one (`connect_facebook_page` -> `exchange_long_lived_user_token`).
3. It then looks up the specific Page's own access token via `/me/accounts`
   (`find_page_access_token`), which only lists Pages the user administers.
4. The resulting long-lived **Page** access token is stored in
   `SyncDestination.configuration.facebook_page.access_token` and reused indefinitely -- Page
   tokens obtained this way don't expire on a timer, only if the user revokes access or changes
   their Facebook password.

Note this token only has permission to post to the Page's feed -- posting to a user's personal
timeline isn't possible via the Graph API at all (Facebook deprecated `publish_actions` in 2018).
(Instagram sync reuses this exact same connect flow and Page token -- see `protos/jonline.proto`'s
`##### SyncDestination` doc for how each platform's connect flow differs.)

## X (Twitter)

X sync exists as a [`SyncDestination`](https://jonline.io/docs/protocol#jonline-SyncDestination) platform in shape only -- the proto messages
([`XTwitterAccount`](https://jonline.io/docs/protocol#jonline-XTwitterAccount)), permissions (`SYNC_EVENTS_TO_X_TWITTER`/`SYNC_POSTS_TO_X_TWITTER`), and RPC
dispatch arms all exist, but there's no working connect or post flow behind them yet:

- [`CreateSyncDestination`](https://jonline.io/docs/protocol#grpc-api-CreateSyncDestination)/[`UpdateSyncDestination`](https://jonline.io/docs/protocol#grpc-api-UpdateSyncDestination) against an [`XTwitterAccount`](https://jonline.io/docs/protocol#jonline-XTwitterAccount) configuration, and
  [`SyncEventInstance`](https://jonline.io/docs/protocol#grpc-api-SyncEventInstance)/[`SyncPost`](https://jonline.io/docs/protocol#grpc-api-SyncPost) against an already-"connected" one, all unconditionally fail with
  `x_twitter_app_not_configured` -- regardless of what permissions the caller holds, including
  Admin. There's no code path that can ever succeed today.
- Why: unlike Facebook (whose app credentials also cover Instagram and Threads, since all three
  are Meta products), X requires its **own** registered X Developer App -- a separate client
  ID/secret, its own OAuth app review, and (as of the API's current pricing tiers) a paid plan for
  any meaningful write access. None of that exists for Jonline yet.
- `ServerConfiguration.federation_info.x_twitter_auth_config` (an `XTwitterAuthConfig { client_id,
  client_secret }`, mirroring `facebook_auth_config`'s shape) is reserved for when this changes,
  but is currently unused by any logic -- setting it does nothing yet.

**To actually implement this** (not yet started): register an X Developer App, wire
`x_twitter_auth_config` the same way `facebook_auth_config` is wired (admin-configured via
[`ConfigureServer`](https://jonline.io/docs/protocol#grpc-api-ConfigureServer)), and add a `logic::x_twitter_sync` module mirroring `threads_sync.rs`'s shape
most closely among the existing platforms -- X's OAuth 2.0 (with PKCE) is a `response_type=code`
authorize-then-exchange flow similar to Threads', and (depending on the API tier ultimately used)
posting is a single `POST /2/tweets` call, simpler than Facebook/Instagram's photo-upload or
container-based flows.

## Testing

`facebook_sync.rs`'s functions all take a `base_url` so specs
(`backend/src/tests/facebook_sync_tests.rs`) can run against a local mock
(`factories::serve_facebook_graph_api`) instead of the real Graph API. There is currently no real
Facebook App wired up for local dev, so the full connect/create flow against the real API can only
be exercised in production -- see the mock-based specs for what's covered locally.
