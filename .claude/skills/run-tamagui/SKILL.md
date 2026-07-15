---
name: run-tamagui
description: Run or rebuild the local Tamagui/Next.js frontend (frontends/tamagui). Use when the user wants to start the Tamagui dev server or rebuild it standalone.
---

Jonline's Tamagui frontend lives in `frontends/tamagui` (Tamagui + Next.js) and is driven through its own `Makefile`.

## Running the dev server

```
cd frontends/tamagui && make run_dev_server
```

- Runs `yarn web`, a Next.js dev server.
- Serves on **port 3000** locally.
- The user often has this running themselves already — it's fine to kill and restart it.

## Rebuilding

```
cd frontends/tamagui && make rebuild_fe
```

- Runs `yarn tsc && yarn build && yarn web:prod:build` (with `NODE_OPTIONS=--max-old-space-size=8192`).
- `make upgrade_tamagui` runs `yarn upgrade:tamagui` then `rebuild_fe`.
- Protos: `yarn protos` (invoked by the root `make protos` target — see the `rebuild-protos` skill).

## Prefer the backend-driven workflow for checking changes

Tamagui is noticeably slower and more painful to iterate with than Elm. **Unless the user specifically wants the standalone Next.js dev server**, prefer validating changes through the Rust backend instead, via the `run-backend` skill's:

```
cd backend && make rebuild_tamagui_and_run
```

This rebuilds the Tamagui FE and serves it from the Rust server (ports 80/8000), which is generally a more reliable way to check a change end-to-end.
