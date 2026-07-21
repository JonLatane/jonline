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

Commands: `nav <url>`, `wait-for text=<text>` (or a CSS/Playwright selector), `click <selector>`, `fill <selector> <value>`, `press <key>`, `sleep <ms>`, `screenshot <path>`, `console-errors` (prints any `console.error`s seen so far). See the comment header in `driver.mjs` for the full list. Read the resulting PNG with the `Read` tool to actually look at it — a screenshot you didn't view proves nothing.

### Gotchas

- Navigating to a `/server/:id` (or similar server-probing) route logs `net::ERR_CONNECTION_REFUSED`/`ERR_SSL_PROTOCOL_ERROR` to the console while it tries candidate ports — that's `Shared.AccountsPanel`'s own connection negotiation working as designed, not a real error. Only worry about `console-errors` output that isn't explained by a page you know is probing a host.
- `npx playwright install chromium` can print a large "you're running this without installing your project's dependencies" warning banner and appear to do nothing — that's normal here (this driver's `package.json` lives in the skill dir, not the repo root); it still downloads the browser. If browsers were already cached from a previous run (`~/.cache/ms-playwright`), the command produces no output at all and returns immediately — that's success, not a hang.
- `node_modules`/`package-lock.json` under `.claude/skills/run-elm/` are for this driver only, gitignored via the skill's own `.gitignore` — don't confuse them with the Elm app's own dependencies (there are none; Elm has no `node_modules`).
