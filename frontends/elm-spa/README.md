# Jonline's Elm Frontend

A new Jonline web frontend built in Elm, living alongside the existing React/Tamagui
and Flutter clients. It's served at `/elm` by the Rust backend, and — once an admin
picks "Elm" as a server's web UI (see below) — can be served at `/` too.

The goal wasn't "port everything Tamagui does." It was to get a second, independent
implementation of Jonline's auth model — accounts, servers, tokens, permissions — onto
solid, boring, statically-typed ground, and see how far a much smaller surface area
could go before it needed to reach for the same complexity the React app has.

> 🌳  built with [elm-spa](https://elm-spa.dev)

## What's here

**Auth, from the ground up.** Login and Create Account forms, shared across every page
via elm-spa's `Shared` module, backed by gRPC-Web calls into the same Rust backend and
`.proto` definitions every other Jonline frontend uses (via
[`protoc-gen-elm`](https://www.npmjs.com/package/protoc-gen-elm) and
[`anmolitor/elm-grpc`](https://package.elm-lang.org/packages/anmolitor/elm-grpc/latest/)).

**Multi-account, multi-server, for real.** You can be signed into several accounts
across several servers at once, switch which one's "active," and the app tracks each
account's own tokens, permissions, and server independently. Adding a server runs it
through the same connectivity negotiation every Jonline client needs: discover the
real backend host behind a CDN (`GET /backend_host`), then try TLS/plaintext and
27707/443/80/8000 candidates in turn until one actually answers.

**An Accounts Panel that looks like the servers it's showing.** Each server's card,
badge, and buttons are tinted with that server's own primary/nav colors — computed
with the same shading/luma math as the Tamagui app's theme hooks, ported byte-for-byte
(including one deliberately "buggy" color formula, kept faithful to the original
rather than silently fixed). Since Elm's `Html.Attributes.style` can't set CSS custom
properties, the per-server color classes are emitted as a real `<style>` tag instead
(`UI.EmittedStylesheet`), regenerated on every render from current app state.

**Dark / Light / Auto theming**, following the OS preference live or overridden by
hand, persisted across reloads.

**Token expiry, tracked and acted on, not just stored.** Access and refresh tokens
carry their real expiration now (`Shared.MaybeAccountRequest`), and any authenticated
request checks the clock first: still valid, go ahead; expiring soon, hit the
`AccessToken` RPC for a new one *first*, then make the original call with whatever
token comes back. It's the same request-wrapping pattern regardless of which RPC is
being made, and it doesn't know or care about the concrete `Account` type — it works
on anything with the right two token fields, avoiding a module import cycle.

**Permissions that refresh themselves.** Every enabled account gets a `GetCurrentUser`
call the moment its server reconnects — which includes app startup and page reload,
not just fresh logins — so permission changes made elsewhere (or on another device)
show up without the user doing anything.

**A Server Admin Panel**, shown to anyone signed into an account with `ADMIN` on its
server. Today it holds:
- a "tap a server chip to make it the main server" toggle, and
- a **Web UI switcher**: one collapsible panel per admin-capable signed-in account
  (showing that account's username/avatar, since the change is authenticated
  *as that account*, not "whichever one's active"), letting them flip which frontend
  — Flutter, React, or Elm — the server hands out at `/`. Flutter's option is always
  shown, always disabled, for parity with the other two without suggesting it's a
  live choice. The same three-way switcher also shipped to the React app's
  `server_details_screen.tsx` in this pass, and along the way surfaced that both
  frontends' generated protobuf bindings for `WebUserInterface` predated the `ELM_SPA`
  enum value — regenerating them was step zero for either UI to be able to offer
  itself as an option.

**A full-width, sticky, on-brand nav.** The top nav spans the page (unlike the
narrower, centered body content below it), stays pinned via `position: sticky`
rather than `fixed` — it needs no compensating padding on the content below it, since
sticky content still reserves its own space in the page flow — and is tinted with the
current server's primary color, with the active page's link picking up the nav color
instead. All of it reuses the same per-server utility classes the Accounts Panel
already emits; no new color logic needed.

**A Home feed and Post page that read across every connected server at once.**
Home fetches each connected server's recent posts independently — authenticated
if you're signed into that server, anonymous otherwise — and merges them into
one recency-sorted feed, with each post's card tinted in *its own* server's
colors (not the browsing server's) so a mixed feed still reads as "which
server is this from" at a glance. The Post page (`/post/:id`, or
`/post/:id@host` for a post that's from some other, federated server) will
connect to that other server on the fly if it isn't already. Comments aren't
implemented here yet — a full post links out to "View N comments from the
React app" instead.

**Starring, without accounts.** `StarPost`/`UnstarPost` (see `jonline.proto`)
are anonymous, friendly counters — the backend keeps no per-user record of who
starred what. The Elm app fills that gap client-side: which posts you've
starred is tracked in `localStorage` (`Shared.StarredPostsPanel`), keyed by
`postId@frontendHost` so posts from different servers can't collide, and
survives reloads. A **Starred Posts panel**, opened from the nav alongside the
Accounts/Admin panels, lists every starred post — fetched (and periodically
re-polled) from whichever server it actually lives on, including servers
you're not currently signed into.

## Why Elm

Elm is a serious, production-grade choice here, battle-tested well beyond this
project. It's also, I'd argue, one of the most promising frontend languages
for AI-assisted development specifically — precisely *because* of how
strictly it enforces The Elm Architecture: a codebase where an LLM can't
quietly corrupt state with a stray mutation or a skipped null check is one it
can be turned loose on with real confidence in the result. A few things that
fell out of building a non-trivial multi-account/multi-server/permissions app
this way:

- No `null`/`undefined` crashes — expired tokens, missing servers, and absent
  permissions are all just values the compiler makes you handle.
- The Elm Architecture's strict `Model`/`Msg`/`update` split scales by composition:
  `Shared.elm` is a thin dispatcher over `Shared.AccountsPanel` and `Shared.AdminPanel`,
  each independently testable and each owning exactly the state and RPCs it needs.
- Nothing here reaches for a state management library, an effects framework, or a
  routing library beyond elm-spa itself — the type system and `Cmd`/`Task` plumbing
  carry the whole thing.

Make no mistake: Elm going from 0.19.1 six years ago to 0.19.2 today — with
zero security holes, zero app code breaking for six years,
a 2.4kb runtime, and industry-leading performance the
whole time (with 20%+ more performance coming in the next release) — is a
*feature*, not "stagnation" of any sort. While "has lots of updates" is certainly a
metric you could choose for success, at least for a tool, "doesn't need updates"
should make a different sort of sense.

The only "creative" thing Jonline's Elm FE does is Emitted Styles. This is simply a matter of emitting CSS classes, say, `.jonline-io.background-color-primary` for a div with `background-color` and `color` set to the `jonline.io` host's primary color and a contrasting text color for it. See below for details.

## Architecture, briefly

- `Shared.elm` — top-level state: composes `AccountsPanel` + `AdminPanel`, plus
  dark/light/auto theming.
- `Shared/AccountsPanel.elm` — servers, accounts, login/add-server forms, connectivity
  negotiation, persistence (`localStorage`, via ports).
- `Shared/AdminPanel.elm` — Server Admin Panel UI state (open/closed, expanded
  per-account panels, the main-server-switch flag).
- `Shared/MaybeAccountRequest.elm` — token-expiry-aware request wrapper, decoupled
  from the concrete `Account` type via an extensible record.
- `Shared/StarredPostsPanel.elm` — the client-only, `localStorage`-persisted
  starred-posts set, its `StarPost`/`UnstarPost` RPCs, and the nav's Starred
  Posts panel.
- `Components/Posts.elm` — shared Post rendering (`postCard`/`postDetail`) and
  fetch helpers, used by the Home feed, the Post page, and the Starred Posts
  panel alike.
- `Pages/Home_.elm` / `Pages/Post/PostId_.elm` — the recency-sorted,
  multi-server Home feed and the single-post Post page.
- `UI.elm` / `UI/EmittedStylesheet.elm` / `UI/ServerTheme.elm` — shared layout/nav/panel
  rendering, the emitted per-server CSS, and the color math behind it.
- `Proto/` — generated gRPC/protobuf bindings (`protoc --elm_out=./src -I../../protos
  ../../protos/*.proto`, via `make protos`) — never hand-edited.

## Emitted Styles

Since Elm's `Html.Attributes.style` can't set CSS custom properties, per-server
theming is done via a `<style>` tag computed fresh from `Shared.Model` on every
render (see
[`UI/EmittedStylesheet.elm`](https://github.com/JonLatane/jonline/blob/master/frontends/elm-spa/src/UI/EmittedStylesheet.elm))
rather than inline styles. For each known server it emits a handful of
"utility class" pairs — a class for that server's host plus a class for the
color you want — so any element can be given that server's colors just by
adding two classes (e.g. `class="jonline.io background-color-primary"`)
instead of threading a `ServerTheme` through as a view-function argument:

- `<host> background-color-primary` — `primaryColor` / `primaryTextColor`
- `<host> background-color-nav` — `navColor` / `navTextColor`
- `<host> background-color-primary-background` — `primaryBgColor` / `textColor`
- `<host> border-color-primary` — `primaryColor` (border-color only)
- `<host> border-color-primary-anchor` — `primaryAnchorColor` (border-color only)
- `<host> border-color-primary-anchor-50` — `primaryAnchorColor` at 50% opacity (border-color only)
- `<host> hover-border-color-primary-anchor` — `primaryAnchorColor` (border-color only), applied only on `:hover`

This is cheap to regenerate (it's just string-building); the actual expensive
color math is already cached in `Shared.Branding`/`UI.ServerTheme`.

Posts reuse these same classes, keyed to *the server the post itself is from*
rather than the server you're currently browsing — a post card in the Home
feed or Starred Posts panel is tinted with its own server's colors even when
that's not the "main" server, and its ★ star button fills with that server's
`primaryAnchorColor` (`.post-star.starred`) when starred, animated via a CSS
`transition` on toggle.

## Running locally

This project requires the latest LTS version of [Node.js](https://nodejs.org/).

```bash
npm install -g elm elm-spa
elm-spa server  # starts this app at http://localhost:1234
```

### other commands

```bash
elm-spa add    # add a new page to the application
elm-spa build  # production build
elm-spa watch  # runs build as you code (without the server)
make protos    # regenerate Proto/ from ../../protos/*.proto
```

## learn more

You can learn more at [elm-spa.dev](https://elm-spa.dev)
