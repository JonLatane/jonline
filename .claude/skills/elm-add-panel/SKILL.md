---
name: elm-add-panel
description: Add a new app-wide "Shared panel" (like Accounts/Starred Posts/Markdown) to the Elm SPA (frontends/elm-spa). Use when asked to add a new global overlay/panel driven from Shared.Model, not page-local state.
---

Jonline's Elm SPA has a handful of app-wide overlay panels (Accounts Panel, Starred Posts Panel, Admin Panel, Markdown Panel) that live in `Shared.Model` rather than any one page, so they're available everywhere and survive route changes. There's no central "list of panels" registry — each one is wired by hand into `Shared.elm` and `UI.elm` following the same shape. Add a new one the same way.

## 1. The panel module itself

New file: `frontends/elm-spa/src/Shared/<Name>Panel.elm`, exposing `Model`, `Msg(..)`, `init`, `update`, `view` (and whatever helpers callers need).

- **`update` signature** depends on whether the panel needs to resolve servers/accounts:
  - Needs `AccountsPanel.Model` (to look up a `Server`/`Account`, make an RPC call, etc.): `update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, Maybe AccountsPanel.Msg )`. The trailing `Maybe AccountsPanel.Msg` lets the panel ask `Shared.update` to forward something to `AccountsPanel` on its behalf (typically `AccountsPanel.AccountRefreshed` after a token refresh) — it can't dispatch that itself without importing `Shared`, which would cycle (`Shared` imports the panel, not the other way around). See `Shared/StarredPostsPanel.elm` and `Shared/MarkdownPanel.elm`.
  - No server/account dependency at all: plain `update : Msg -> Model -> Model` (no `Cmd`, no tuple) — see `Shared/AdminPanel.elm`, the minimal example.
- A panel module can freely import `Components.*`, `Shared.AccountsPanel`, `Shared.MaybeAccountRequest` (none of those import `Shared`) — but never `Shared`, `UI`, or `UI.EmittedStylesheet`, all of which depend on `Shared.Model`, which embeds your panel's `Model`.
- **"Always rendered"** — the view renders in both open and closed states (never conditionally absent), so opening/closing is a pure CSS opacity/transform transition rather than the element mounting/unmounting. Drive that with `UI.Classes.openClosedClass isOpen` added as a class alongside `"nav-panel"` — see any panel's `view`.

## 2. Wiring into `Shared.elm`

Mechanical, copy the shape of the existing `StarredPostsPanelMsg`/`MarkdownPanelMsg` branches:
- Add a field to `Shared.Model` (e.g. `yourPanel : YourPanel.Model`).
- Add a constructor to `Shared.Msg` (e.g. `YourPanelMsg YourPanel.Msg`).
- Initialize it in `Shared.init`.
- In `Shared.update`, add a branch that calls the panel's own `update`, applies any forwarded `AccountsPanel.Msg` via `AccountsPanel.update`, and `Cmd.batch`s both mapped commands together. If the panel has `subscriptions`, batch those into `Shared.subscriptions` too (gate on the panel being open if the subscription is expensive/animation-only).

## 3. Mounting the view in `UI.elm`

Two patterns depending on how the panel opens:
- **Toggled from a nav icon** (Starred Posts): add a toggle button + the panel's own render as siblings in `headerNav`, following `starredPostsToggle`/`starredPostsPanel`.
- **Opened contextually from a page** (Markdown Panel, opened via a page's own Edit/Reply button dispatching `Effect.fromShared (Shared.YourPanelMsg (YourPanel.Open ...))`): just mount it once, unconditionally, in `layout`'s children list: `Html.map toMsg (yourPanel shared)` where `yourPanel shared = Html.map Shared.YourPanelMsg (YourPanel.view shared.accountsPanel shared.yourPanel)`.
- Either way, add an entry to `sharedBackdrop`'s `panels` list so a background tap closes it. That list is ordered **nearest-first**: a tap only closes the first (topmost, by z-index) open panel in the list, not all of them — put a lower-z-index panel later in the list. Set `blurs = True` if the panel should block interaction with the rest of the page while open (most editing/login-style panels do); `False` if it's meant to coexist with using the rest of the app (Starred Posts).

## 4. CSS

- Reuse the shared `.nav-panel` base rule (`public/style/shared/accounts_panel.css`) for position/opacity/pointer-events transition plumbing, then override position/size/z-index in your own `public/style/shared/<name>_panel.css`. **Link the new file in `public/index.html`** — CSS files aren't auto-discovered.
- Existing z-indices: Accounts Panel `20`, Starred Posts Panel `25` (deliberately above Accounts). Pick your panel's z-index relative to those based on where it should sit if multiple are open at once.
- To tint an element with a specific server's brand color (e.g. a submit button matching the relevant Post/Group's server) without importing `UI`/`UI.EmittedStylesheet` (cycle risk), just add the classes `[ frontendHostString, "background-color-primary" ]` (or `-nav`, `-primary-5/10/25/50`, `-primary-background`, `border-color-primary...` — see `UI/EmittedStylesheet.elm`'s doc comment for the full list). `UI.EmittedStylesheet.view`, mounted once app-wide, already emits a CSS rule per known server keyed by that literal host string as a class — no plumbing needed beyond the class names themselves.
