# Facebook Event Sync

Jonline's "Event Sync Destinations" feature lets a user connect one of their Facebook Pages to
an `EventInstance`, so calling `SyncEventInstance` posts the event to that Page. Implementation:
[`backend/src/logic/facebook_sync.rs`](../backend/src/logic/facebook_sync.rs), invoked from
[`SyncEventInstance`](../backend/src/rpcs/event_sync_destinations/sync_event_instance.rs).

## It posts to the Page's feed, not a real Facebook Event

`SyncEventInstance` creates a Facebook **Page post** (`POST /{page-id}/feed`) formatted to read
like an event announcement. It does **not** create an actual Facebook **Event** object (the kind
users can RSVP to natively on Facebook), because the Graph API no longer allows that for ordinary
third-party apps:

- `POST /{page-id}/events` (and update/delete) has been locked down since Graph API v3.3 (2018).
  Meta's own reference for the `event` node states creation isn't supported on that endpoint at
  all.
- Even *reading* Page/User events via the Graph API is restricted to approved **Facebook Marketing
  Partners** -- a vetted-agency program (minimum ad spend/message volume, ongoing compliance
  review) that isn't a realistic fit for a self-hosted Jonline server.
- Real integrations that appear to "create a Facebook Event" (e.g. Eventbrite) don't do it via a
  server-side API call either -- they deep-link the user's own browser into Facebook's native
  "Create Event" UI, pre-filled, and the human finishes it themselves.

So the Page-post approach here is the best available server-side option, not an oversight.

## What's in the post

`format_message` (in `facebook_sync.rs`) builds the post body from the event's own `Post`
(`title`/`content`/`link`) and its `EventInstance` (`starts_at`/`ends_at`/`location`):

1. Title
2. Date/time range (single timestamp if `ends_at` isn't after `starts_at`, otherwise a `start –
   end` range; times shown in UTC)
3. Location (`EventInstance.location.uniformly_formatted_address`), if set
4. Content/description
5. `Details & RSVP: {event_url}`, if a Jonline event link could be built (see below)

The Graph API `link` param (which drives the post's link-preview card) prefers the Jonline event
URL; if that isn't available it falls back to the arbitrary external `link` the organizer set on
the `Post` itself (e.g. a ticketing site).

## The Jonline event link needs CDN/frontend config

The `event_url` (`https://{frontend_host}/event/{instance_id}`) is only built when this server has
`ServerConfiguration.external_cdn_config.frontend_host` configured. Unlike Rocket web routes
(`configured_frontend_domain` in `backend/src/web/external_cdn.rs`), the `SyncEventInstance` RPC
has no HTTP `Host` header to fall back on, so on servers without `frontend_host` set, the post
simply omits the Jonline link (falling back to the organizer's `Post.link`, if any) rather than
guessing a domain. This is an accepted current limitation, not a bug -- set `frontend_host` if you
want synced posts to link back to the event.

## Connecting a Page (OAuth/token flow)

1. The client does Facebook Login and gets a short-lived **user** access token, passed to
   `CreateEventSyncDestination`.
2. The server loads its own Facebook App ID/Secret (admin-configured via `ConfigureServer` ->
   `ServerConfiguration.federation_info.facebook_auth_config`) and exchanges the short-lived user
   token for a long-lived one (`connect_facebook_page` -> `exchange_long_lived_user_token`).
3. It then looks up the specific Page's own access token via `/me/accounts`
   (`find_page_access_token`), which only lists Pages the user administers.
4. The resulting long-lived **Page** access token is stored in
   `EventSyncDestination.configuration.facebook_page.access_token` and reused indefinitely -- Page
   tokens obtained this way don't expire on a timer, only if the user revokes access or changes
   their Facebook password.

Note this token only has permission to post to the Page's feed -- posting to a user's personal
timeline isn't possible via the Graph API at all (Facebook deprecated `publish_actions` in 2018).

## Testing

`facebook_sync.rs`'s functions all take a `base_url` so specs
(`backend/src/tests/facebook_sync_tests.rs`) can run against a local mock
(`factories::serve_facebook_graph_api`) instead of the real Graph API. There is currently no real
Facebook App wired up for local dev, so the full connect/create flow against the real API can only
be exercised in production -- see the mock-based specs for what's covered locally.
