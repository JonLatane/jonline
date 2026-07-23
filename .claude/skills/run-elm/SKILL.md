---
name: run-elm
description: Run, build, screenshot, or regenerate protos for the local Elm SPA frontend (frontends/elm-spa). Use when the user wants to start the Elm dev server, check an Elm change standalone, or drive/screenshot a page in a headless browser.
---

Jonline's Elm frontend lives in `frontends/elm-spa` and is driven through its own `Makefile`. Paths below are relative to the repo root unless noted.

## Running the dev server

```
cd frontends/elm-spa && make run
```

- This runs `npx elm-spa server`.
- Serves on **port 1234** locally.
- The user often has this running themselves already — it's fine to kill and restart it.

## Other targets

- `make build` — `npx elm-spa build`, a production build. Also the fastest way to get real compiler errors for a change — `Gen.*`/`Request`/`Route` (elm-spa's generated routing glue) only exist after this or `make run` has generated them at least once, so a bare `elm make` beforehand will show spurious "module not found" errors for those.
- `make protos` — regenerates Elm proto bindings into `./src` from `../../protos/*.proto` via `protoc-gen-elm`. Run `make setup_proto_build` once beforehand if `protoc-gen-elm` isn't installed (`yarn global add protoc-gen-elm`).

## When to use this vs. the backend

Use this skill for fast standalone iteration on Elm code/UI. If you need to confirm a change works *as served by the Rust backend* (e.g. routing, embedded assets), use the `run-backend` skill's `rebuild_elm_and_run` target instead.

## Screenshotting / driving a page (agent path)

`chromium-cli` isn't available in this container, so this skill carries its own tiny driver at `.claude/skills/run-elm/driver.mjs` (Playwright, chromium-cli-style line commands). It needs the dev server (above) already running on port 1234.

**One-time setup:**

```
cd .claude/skills/run-elm && npm install && npx playwright install chromium
```

**Usage:** pipe a line-per-command script to it (paths in `screenshot` are relative to your `cwd` when you invoke `node`, so `cd` back to the repo root first, or use absolute paths):

```
cd /path/to/jonline
node .claude/skills/run-elm/driver.mjs <<'EOF'
nav http://localhost:1234/server/http:localhost
wait-for text=About
screenshot /tmp/about.png
click button:has-text("Theme")
wait-for text=Primary Color
screenshot /tmp/theme.png
console-errors
EOF
```

Commands: `nav <url>`, `wait-for text=<text>` (or a CSS/Playwright selector), `click <selector>`, `click-at <selector> <x> <y>` (click at a specific offset inside `selector`, for hitting a large backdrop/overlay element at a point not covered by a smaller child on top of it), `fill <selector> <value>`, `type <anything> <value>` (types `value` via real keydown/keyup events at whatever element currently has DOM focus — the selector arg is ignored, no click-to-focus first; see the password-field gotcha below), `press <key>`, `sleep <ms>`, `screenshot <path>`, `console-errors` (prints any `console.error`s seen so far). See the comment header in `driver.mjs` for the full list. Read the resulting PNG with the `Read` tool to actually look at it — a screenshot you didn't view proves nothing.

### Gotchas

- Navigating to a `/server/:id` (or similar server-probing) route logs `net::ERR_CONNECTION_REFUSED`/`ERR_SSL_PROTOCOL_ERROR` to the console while it tries candidate ports — that's `Shared.AccountsPanel`'s own connection negotiation working as designed, not a real error. Only worry about `console-errors` output that isn't explained by a page you know is probing a host.
- `npx playwright install chromium` can print a large "you're running this without installing your project's dependencies" warning banner and appear to do nothing — that's normal here (this driver's `package.json` lives in the skill dir, not the repo root); it still downloads the browser. If browsers were already cached from a previous run (`~/.cache/ms-playwright`), the command produces no output at all and returns immediately — that's success, not a hang.
- `node_modules`/`package-lock.json` under `.claude/skills/run-elm/` are for this driver only, gitignored via the skill's own `.gitignore` — don't confuse them with the Elm app's own dependencies (there are none; Elm has no `node_modules`).
- **`fill` on the Accounts Panel's password field (`#account-form-password`) triggers a premature form submission with an empty/partial password**, popping the create-account confirmation modal early and (if you let it through) failing with a `password_too_short_min_8` error even though the field visually shows the right value. Root cause unconfirmed (suspected: this field is freshly mounted by `ChooseCreateAccountClicked`'s own `Dom.focus`, and `fill`'s synthetic value-set + input event races that). Use `type` instead — it sends real per-character key events to whatever's focused (no click first, since the app already focuses the field itself) and doesn't trigger the early submit. See the "log in as a test account" recipe below.

### Recipe: log in as a fresh test account

Needed any time a change touches something behind a signed-in account (e.g. an Accounts Panel chip action). Against the local dev backend (`localhost`, candidate port 27707 tried automatically — see `AccountsPanel.candidatePorts`), account creation has no email/approval step, so this is fully scriptable:

```
node .claude/skills/run-elm/driver.mjs <<'EOF'
nav http://localhost:1234
wait-for .accounts-menu-toggle
click .accounts-menu-toggle
wait-for #account-form-server
fill #account-form-username sometestuser
click button:has-text("Create Account")
wait-for #account-form-password
type x SomeP4ssword123
wait-for text=Media Policy
click button:has-text("Cancel")
sleep 300
click button[type="submit"]
wait-for text=Media Policy
sleep 500
click .create-account-modal button:has-text("Create Account")
sleep 2500
screenshot /tmp/logged_in.png
EOF
```

Why the extra Cancel/resubmit round-trip: the first `type` immediately after the password field appears pops the confirmation modal prematurely (see the gotcha above) — its `Cancel` button discards nothing (`CancelCreateAccountClicked` only clears the confirmation, not the form fields), so canceling and clicking the real submit button (`button[type="submit"]`) a second time confirms with the actual typed password intact. Skipping the cancel/resubmit and confirming straight through the premature modal is what produces the `password_too_short_min_8` failure.

The Server field defaults to a known/connected host already, so `#account-form-server` doesn't need to be touched unless testing against a different server. Username must be unique per test run — the backend has no reset between runs on a real dev instance, so reusing a name will hit a "username taken" error instead of creating a fresh account.
