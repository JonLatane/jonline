---
name: run-elm
description: Run, build, or regenerate protos for the local Elm SPA frontend (frontends/elm-spa). Use when the user wants to start the Elm dev server or check an Elm change standalone.
---

Jonline's Elm frontend lives in `frontends/elm-spa` and is driven through its own `Makefile`.

## Running the dev server

```
cd frontends/elm-spa && make run
```

- This runs `npx elm-spa server`.
- Serves on **port 1234** locally.
- The user often has this running themselves already — it's fine to kill and restart it.

## Other targets

- `make build` — `npx elm-spa build`, a production build.
- `make protos` — regenerates Elm proto bindings into `./src` from `../../protos/*.proto` via `protoc-gen-elm`. Run `make setup_proto_build` once beforehand if `protoc-gen-elm` isn't installed (`yarn global add protoc-gen-elm`).

## When to use this vs. the backend

Use this skill for fast standalone iteration on Elm code/UI. If you need to confirm a change works *as served by the Rust backend* (e.g. routing, embedded assets), use the `run-backend` skill's `rebuild_elm_and_run` target instead.
