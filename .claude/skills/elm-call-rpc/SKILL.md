---
name: elm-call-rpc
description: Call a Jonline gRPC RPC (from protos/*.proto) from Elm SPA code (frontends/elm-spa). Use when writing or wiring up a new fetch/mutation against the backend from a page or Shared panel.
---

## Basic shape

Each RPC (`protos/jonline.proto`'s `service Jonline`) has a generated `Grpc.Rpc req res` value in `Proto.Jonline.Jonline` (e.g. `Jonline.updatePost`, `Jonline.createPost`, `Jonline.getPosts`), from the `anmolitor/elm-grpc` package (`Grpc` module).

```elm
Grpc.new Jonline.updatePost requestValue
    |> Grpc.setHost (AccountsPanel.serverUrl server)
    |> Grpc.addHeader "authorization" token   -- only for authenticated calls
    |> Grpc.toTask                            -- : Task Grpc.Error res
```

Use `Grpc.toTask` when chaining (`Task.andThen`) or `Task.attempt`ing yourself; `Grpc.toCmd` if you just want a `Cmd msg` directly.

Many RPCs (`CreatePost`, `UpdatePost`, ...) take/return the whole resource message directly (`Post -> Post`), not a separate `FooRequest`/`FooResponse` pair — check the actual `rpc` line in the `.proto` file rather than assuming a request wrapper exists.

## Auth / token refresh: use `Shared.MaybeAccountRequest`

Don't call `Grpc.addHeader "authorization"` with a token you're holding onto — it may have expired. Instead:

- `MaybeAccountRequest.perform : connection -> Maybe Account -> (Maybe String -> Task Grpc.Error b) -> Task Grpc.Error ( Maybe Account, b )` — anonymous if given `Nothing`, otherwise refreshes the access token first if expired/expiring (via the `AccessToken` RPC), then calls your `req` with the current token. Returns the (possibly-refreshed) `Account` back so you can persist it.
- `MaybeAccountRequest.performWithAccount` — same, but takes/returns a concrete `Account` (not `Maybe`) — use once you've already confirmed a signed-in account exists (e.g. after your own permission check), so you're not re-handling `Nothing` at the call site.
- **Always propagate the refreshed account back**, e.g. `Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.AccountRefreshed account))` from a page, or as the `Maybe AccountsPanel.Msg` a `Shared`-level panel's `update` returns. Skipping this silently drops a rotated refresh token, breaking future requests once the old one expires. Grep any existing `fetchX`/`GotXResult` handler (`Components/Posts.elm`, `Shared/StarredPostsPanel.elm`, `Shared/MarkdownPanel.elm`) for the pattern.
- `connection` is `{ host : String, port_ : Int, tls : Bool }`, built from a `Server` as `{ host = server.backendHost, port_ = server.port_, tls = server.tls }` — **`backendHost`, not `frontendHost`** (the latter is the public-facing name; the gRPC API actually lives at `backendHost`, often a CDN).

## Read-modify-write safety

Some RPCs take and **unconditionally apply a whole record** server-side — e.g. `UpdatePost` (`backend/src/rpcs/posts/update_post.rs`) overwrites `visibility`/`media`/`embed_link`/`shareable`/etc. from whatever `Post` you send, not just the field you intended to change. If you're changing one field of something fetched a while ago (user was editing in a text box, a panel sat open, etc.), **re-fetch it fresh immediately before submitting** and overlay only your change onto that fresh copy — don't resubmit a possibly-stale in-hand snapshot. See `Shared/MarkdownPanel.elm`'s `saveTask` (`Task.andThen`s a fresh `GetPosts` into the eventual `UpdatePost`) for the pattern. Check the corresponding `backend/src/rpcs/**/*.rs` handler when in doubt about which fields get blindly overwritten vs. merged.

## Errors

`AccountsPanel.grpcErrorToString : Grpc.Error -> String` is the shared formatter (`Grpc.BadUrl`/`Timeout`/`NetworkError`/`BadStatus { errMessage }`/`BadBody`) used for displaying RPC failures — use it instead of writing a new `Grpc.Error -> String` case expression.
