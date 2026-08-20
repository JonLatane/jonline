port module Ports exposing
    ( accountsAndServersUpdated
    , calendarEventClicked
    , checkPushSubscription
    , clearFederatedAuthKeyPair
    , copyToClipboard
    , elementsMeasured
    , facebookLoginPopup
    , facebookLoginResult
    , federatedAuthDecrypt
    , federatedAuthDecrypted
    , federatedAuthEncrypt
    , federatedAuthEncrypted
    , federatedAuthGenerateKeyPair
    , federatedAuthKeyPairGenerated
    , measureElements
    , persistAccountsAndServers
    , persistFederatedAuthKeyPair
    , persistStarredPosts
    , persistThemePreference
    , persistUserPreferences
    , pushSubscribed
    , pushSubscriptionChecked
    , renderCalendar
    , scrollElementLeft
    , setNavBarColor
    , setTheme
    , starredPostsUpdated
    , subscribeToPush
    , systemPrefersDarkChanged
    , unsubscribeFromPush
    )

import Json.Encode as Encode


{-| Persists the full account/server list (with their enabled flags) to
localStorage, and broadcasts it (see `public/index.html`'s `BroadcastChannel`)
to any other tab open on the same origin, which applies it via
`accountsAndServersUpdated` -- see `Shared.AccountsPanel.subscriptions`.
-}
port persistAccountsAndServers : Encode.Value -> Cmd msg


{-| Fires in _other_ tabs (never the tab that called `persistAccountsAndServers`
itself) whenever one tab's accounts/servers change, carrying the same value
`persistAccountsAndServers` was given -- decode with
`Shared.AccountsPanel.persistedStateDecoder`. Lets multiple tabs on the same
origin stay in sync (e.g. signing in on one tab shows the new account on all
the others) without each tab polling localStorage.
-}
port accountsAndServersUpdated : (Encode.Value -> msg) -> Sub msg


{-| Persists the set of starred Posts (as a list of `postId@frontendHost`
strings, see `Shared.StarredPanel.starKey`) to its own localStorage key
-- kept independent of `persist` for the same reason `persistThemePreference`
is: `Shared.StarredPanel` doesn't need to know `Shared.AccountsPanel`'s
persisted shape, or vice versa. Also broadcasts it (see `public/index.html`'s
`BroadcastChannel`) to any other tab open on the same origin, which applies it
via `starredPostsUpdated` -- see `Shared.StarredPanel.subscriptions`,
mirroring `persistAccountsAndServers`/`accountsAndServersUpdated`.
-}
port persistStarredPosts : Encode.Value -> Cmd msg


{-| Fires in _other_ tabs (never the tab that called `persistStarredPosts`
itself) whenever one tab's starred posts change, carrying the same value
`persistStarredPosts` was given -- decode with `Decode.list Decode.string`,
same as `Shared.StarredPanel.init`'s flags.
-}
port starredPostsUpdated : (Encode.Value -> msg) -> Sub msg


{-| Persists `Shared.UserPreferences.Model` (currently just `{ prefersCalendar
: Bool }`) to its own localStorage key -- kept independent of `persist`/
`persistStarredPosts` for the same reason those are: `Shared.UserPreferences`
doesn't need to know any other module's persisted shape, or vice versa.
Unlike `persistStarredPosts`/`persistAccountsAndServers`, this doesn't
broadcast to other tabs via a `BroadcastChannel` -- these preferences are read
back out at `Shared.init` (a fresh page load) rather than needing to update
an already-open tab live, so there's no counterpart `Sub` for this one.
-}
port persistUserPreferences : Encode.Value -> Cmd msg


{-| Persists the appearance ("auto"/"light"/"dark") preference to its own
localStorage key -- kept independent of `persist` so `Shared` and
`Shared.AccountsPanel` don't need to know about each other's persisted shape.
-}
port persistThemePreference : String -> Cmd msg


{-| Applies the effective dark/light mode to the page: "dark" or "light" sets
`<html data-theme>` (overriding the system preference); "auto" clears it
(falling back to the `prefers-color-scheme` media query).
-}
port setTheme : String -> Cmd msg


{-| Scrolls the element with the given `id` (a `{ id : String, left : Float }`
JSON payload, see `public/index.html`) so its `scrollLeft` becomes `left` --
animated if it (or an ancestor) has CSS `scroll-behavior: smooth`. Exists
because `Browser.Dom.setViewportOf` always performs its own `scrollLeft`
assignment from inside a `requestAnimationFrame` callback (see `elm/browser`'s
kernel code) -- which, at least in the environments this was tested in,
silently fails to take effect at all on an element with `scroll-behavior:
smooth` set, even though the `Task` itself reports success. A plain
port-triggered assignment runs as a normal JS callback, not wrapped in
`requestAnimationFrame`, and doesn't have this problem. See
`Pages.Event.EventId_.scrollToInstance`, the only current caller.
-}
port scrollElementLeft : Encode.Value -> Cmd msg


{-| Measures every DOM element named in the given JSON array of
`{ key : String, id : String }` objects (`id` is the actual DOM id to look
up; `key` is the caller's own correlation id, echoed back verbatim in the
result -- see `elementsMeasured`) via a single plain JS callback -- exists
for exactly the reason `scrollElementLeft` does (see its own doc comment):
`Browser.Dom.getElement` (elm/browser's kernel code, see `_Browser_withNode`)
wraps _every single call_ in its own `requestAnimationFrame`, and Elm's
`Task`s compose strictly sequentially (no real concurrency), so measuring N
elements via `Task.sequence` over N separate `Dom.getElement` calls costs N
whole animation frames, one after another. For
`Components.Pages.EventsPage`'s FLIP layout-switch measurement (up to
`maxDisplayedEvents` elements, twice per switch), that added up to a highly
visible multi-hundred-millisecond gap between the layout actually switching
and the slide-back animation starting -- confirmed by instrumenting a real
transition (a `requestAnimationFrame` sampler logging the container's class
and the moving element's `transform` every frame) and finding a ~150-250ms
window on each side where the new layout had already rendered at its plain,
un-inverted resting position before the invert transform was applied. A
single port round-trip measures every requested id in one JS turn, with no
`requestAnimationFrame` involved at all, so it costs the same one turn
regardless of how many ids are given.
-}
port measureElements : Encode.Value -> Cmd msg


{-| `[ { key : String, x : Float, y : Float, width : Float, height : Float }, ... ]`
-- the result of `measureElements`, one entry per `key` whose `id` was
actually found in the DOM (a missing one is just omitted, not an error).
`key` is exactly whatever the caller sent as that item's own `key` (its own
correlation id -- e.g. `Components.Pages.EventsPage`'s animation key, not the
DOM id derived from it), never the DOM `id` itself -- this is what lets the
Elm side avoid ever needing to reverse-derive its own key back out of a DOM
id string. `x`/`y` are page (not viewport) coordinates, matching
`Browser.Dom.Element.element`'s own convention. See
`Components.Pages.EventsPage.rectsDecoder`.
-}
port elementsMeasured : (Encode.Value -> msg) -> Sub msg


{-| Renders (or, for a container `id` it's already rendered into, refreshes)
a [FullCalendar](https://fullcalendar.io/) view showing `events` --
`{ id : String, initialView : String, events : List { id, title, start, end, classNames } }`,
where `id` is the DOM id of the container `div` to render into and each
event's own `start`/`end` are ISO 8601 UTC strings (`start` omitted for an
event with no `startsAt`, `end` likewise) -- see `Components.Pages.EventsPage`'s
`Calendar` display mode, the only current caller. `initialView` is a
FullCalendar view name (`"dayGridMonth"`/`"timeGridWeek"`/`"timeGridDay"` --
see `Components.Pages.EventsPage.fullCalendarInitialView`) only actually read
the first time a given container mounts; `public/index.html`'s
reused-container branch (refreshing `events` on an already-mounted calendar)
never re-reads it. `classNames` (a `List String`) is passed straight through
to FullCalendar's own `EventInput.classNames` --
`Components.Pages.EventsPage.calendarEventEncoder` sets it to that event's
host's `hostnameToCSSClass`/`"background-color-primary"`, so it's colored by
the same per-server `UI.EmittedStylesheet` rule every other per-server-colored
element in the app already uses, rather than this port needing raw color hex
strings of its own. No result comes back over a `Sub`; this is
fire-and-forget, same as `setNavBarColor`/`copyToClipboard`.
-}
port renderCalendar : Encode.Value -> Cmd msg


{-| Fires the `id` (an `eventAnimationKey`) of whichever `Calendar`-mode event
was clicked -- `public/index.html`'s `renderCalendar` subscriber wires this to
FullCalendar's own `eventClick` callback. See
`Components.Pages.EventsPage.CalendarEventClicked`, the only current
subscriber, which opens/scrolls its own preview strip to that event's card.
-}
port calendarEventClicked : (String -> msg) -> Sub msg


{-| Sets every `<meta name="theme-color">` tag's `content` to `mainFrontendHost`'s
current `primaryColor` (a `#rrggbb` string -- see `UI.ServerTheme.ColorMeta`),
so the browser/OS chrome (e.g. a mobile browser's tab bar) tints to match the
server being browsed. Called from `Shared.navBarColorCmd` whenever that color
actually changes -- `mainFrontendHost` switching, or its `Server`'s branding
being (re)populated.
-}
port setNavBarColor : String -> Cmd msg


{-| Writes `text` to the system clipboard via `navigator.clipboard.writeText`
-- see `Components.Pages.EventsPage`'s "Export" popover, the only current
caller.
-}
port copyToClipboard : String -> Cmd msg


{-| Fires when the OS-level dark/light preference changes while the app is
open (relevant only in "auto" mode).
-}
port systemPrefersDarkChanged : (Bool -> msg) -> Sub msg


{-| Opens a Facebook OAuth login popup for `Components.EventSyncDestinations` (via
`Components.Pages.UserProfilePage`'s "Sign in to Facebook Page" button), for the given Facebook
App ID. Deliberately hand-rolled (a plain `window.open` at Facebook's own OAuth dialog URL, with
our own tiny static `facebook-callback.html` as the `redirect_uri`) rather than loading Facebook's
JS SDK -- see `public/index.html`'s subscription for why: the popup has to open synchronously
inside the click that requested it to reliably avoid being blocked (especially on mobile Safari),
and loading a third-party SDK first would introduce an async gap that breaks that. The result
arrives via `facebookLoginResult`.
-}
port facebookLoginPopup : String -> Cmd msg


{-| `{ ok : Bool, value : String }` -- on success, `value` is a short-lived Facebook user access
token (to send straight through as `FacebookPage.shortLivedUserAccessToken` on
`CreateEventSyncDestination`; the backend exchanges it server-side and never stores/returns it as
given). On failure, `value` is either `"cancelled"` (the user closed the popup without finishing)
or a human-readable error message -- callers should treat `"cancelled"` as "silently go back to
not-logged-in," not as an error to display.
-}
port facebookLoginResult : (Encode.Value -> msg) -> Sub msg



-- FEDERATED AUTH (see `Shared.FederatedAuth`) -- SSO-style cross-server
-- account hand-off, encrypted with a per-browser ECDH keypair via the
-- browser's WebCrypto `SubtleCrypto` API (no crypto primitives in Elm
-- itself). See `public/index.html` for the JS side of all of these.


{-| Generates a fresh ECDH (P-256) keypair; the result arrives via
`federatedAuthKeyPairGenerated`. The argument is unused (ports need a
JSON-encodable payload) -- always call with `Encode.null`.
-}
port federatedAuthGenerateKeyPair : Encode.Value -> Cmd msg


{-| `{ publicKey : String, privateKey : String }`, both base64url-encoded --
see `Shared.FederatedAuth.keyPairDecoder`.
-}
port federatedAuthKeyPairGenerated : (Encode.Value -> msg) -> Sub msg


{-| Persists the current keypair (see `federatedAuthKeyPairGenerated`) to its
own localStorage key, mirroring `persistStarredPosts`/`persistThemePreference`.
-}
port persistFederatedAuthKeyPair : Encode.Value -> Cmd msg


{-| Drops the persisted keypair from localStorage -- called once a received
account has been accepted or declined (see `Shared.FederatedAuth.Discarded`),
so a used private key doesn't linger. The argument is unused, same as
`federatedAuthGenerateKeyPair`.
-}
port clearFederatedAuthKeyPair : Encode.Value -> Cmd msg


{-| Encrypts `{ publicKey : String, plaintext : String }` (the recipient's
public key and the plaintext to encrypt to it) via ECIES-style hybrid
encryption (ephemeral ECDH + HKDF-SHA256 + AES-256-GCM); the result arrives
via `federatedAuthEncrypted`.
-}
port federatedAuthEncrypt : Encode.Value -> Cmd msg


{-| `{ ok : Bool, value : String }` -- `value` is the encrypted, url-safe
ciphertext string on success, or an error message on failure.
-}
port federatedAuthEncrypted : (Encode.Value -> msg) -> Sub msg


{-| Decrypts `{ privateKey : String, encoded : String }` (this origin's own
private key and a ciphertext string produced by `federatedAuthEncrypt`
elsewhere); the result arrives via `federatedAuthDecrypted`.
-}
port federatedAuthDecrypt : Encode.Value -> Cmd msg


{-| `{ ok : Bool, value : String }` -- `value` is the decrypted plaintext on
success, or an error message on failure (wrong key, tampered ciphertext,
etc).
-}
port federatedAuthDecrypted : (Encode.Value -> msg) -> Sub msg



-- WEB PUSH (see `Shared.AccountsPanel`'s "Enable notifications") -- browser
-- Service Worker push subscription registration. See `public/index.html` for
-- the JS side and `public/service-worker.js` for the `push`/`notificationclick`
-- handlers themselves.


{-| Requests a browser Web Push subscription for `{ accountId : String, publicKey : String }`
(`publicKey` is that account's server's VAPID public key, base64url) --
registers the service worker (if not already), prompts for Notification
permission if needed, then calls `PushManager.subscribe()`. The result
(success or failure, either way carrying the same `accountId` back) arrives
via `pushSubscribed`.
-}
port subscribeToPush : Encode.Value -> Cmd msg


{-| `{ accountId : String, ok : Bool, endpoint : String, p256dhKey : String, authKey : String }`
on success, or `{ accountId : String, ok : Bool, error : String }` (`ok = False`) on failure --
e.g. permission denied, or the browser doesn't support Push. `accountId` is always the same value
`subscribeToPush` was called with, so the Elm side can tell which account's request this answers.
-}
port pushSubscribed : (Encode.Value -> msg) -> Sub msg


{-| Unsubscribes the browser's Web Push subscription for `{ accountId : String, endpoint : String }`,
if the browser's current subscription still matches `endpoint` -- fire-and-forget, no response port;
the Elm side already optimistically drops its own record of the subscription (and calls
`UnregisterPushSubscription` server-side) the moment this is sent.
-}
port unsubscribeFromPush : Encode.Value -> Cmd msg


{-| Asks the browser for whatever Web Push subscription (if any) currently exists for this
origin's service worker -- there's at most one, browser-wide, no matter how many Jonline accounts
are signed in (`PushSubscriptionCheckReceived`'s own doc comment covers how that's reconciled back
to a specific account). Called once at `Shared.AccountsPanel.init`, since `pushSubscriptions` is
otherwise session-only state -- without this, a page refresh would show every account's
notification toggle as off even though the browser (and server) still have an active subscription.
The argument is unused (ports need a JSON-encodable payload) -- always call with `Encode.null`.
-}
port checkPushSubscription : Encode.Value -> Cmd msg


{-| `{ endpoint : String, publicKey : String } | null` -- the browser's current Web Push
subscription's endpoint and the VAPID public key (base64url) it was created with, or `null` if
there's no active subscription at all. `publicKey` is what lets `PushSubscriptionCheckReceived`
figure out *which* account this belongs to: matched against each signed-in account's own server's
`AccountsPanel.serverWebPushPublicKey`, since the Push API itself has no concept of "which
account" -- only one subscription can ever exist per origin.
-}
port pushSubscriptionChecked : (Encode.Value -> msg) -> Sub msg
