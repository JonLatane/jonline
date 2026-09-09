module Shared.AccountsPanel.BlueskyAccounts exposing
    ( BlueskyAccount
    , BlueskyProfile
    , createSessionTask
    , decoder
    , encodeList
    , errorMessage
    , fetchProfileTask
    )

{-| Everything about a connected Bluesky account that doesn't need `Shared.AccountsPanel.Model`
itself to make sense: the persisted-list element type (`BlueskyAccount`), its encode/decode
(`Ports.persistBlueskyAccounts`'s wire format), and the plain HTTP tasks/decoders
`Shared.AccountsPanel.update` drives to build/refresh it (`com.atproto.server.createSession`,
`app.bsky.actor.getProfile`).

What's deliberately *not* here, and stays in `Shared.AccountsPanel` itself: the `Model` fields this
lives in, `BlueskyConnectForm` (the handle/App Password form itself -- tightly coupled to
`Shared.AccountsPanel`'s own per-keystroke `Msg`s and `FormStatus`), and the `Msg`s/`update` cases
that react to user actions and persist the result.

-}

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Shared.AccountsPanel.SortOrder exposing (sortOrderDecoder)
import Shared.Federation.Common exposing (jsonResolver, nonEmpty)
import Task exposing (Task)


{-| A Bluesky (AT Protocol) account connected via `UI.blueskyConnectSection`'s form -- unlike
Mastodon, there's no OAuth popup at all: `com.atproto.server.createSession` (see
`createSessionTask`) takes a handle and App Password directly, the same "plain form" shape
`Pages.Auth.To.Key_` already uses for Rellm's own Login RPC (and is itself the identity check --
the session response already carries `handle`, so there's no separate verify-credentials round trip
the way Mastodon's OAuth `code` needs). Known first-pass limitation: always calls `bsky.social`
directly rather than resolving `handle` to its actual PDS first (see `createSessionTask`'s own
doc), so a self-hosted-PDS account won't connect yet -- the overwhelming majority of Bluesky accounts
are hosted there by default, so this covers the common case. `enabled` mirrors `RellmServer.enabled` --
see `Shared.AccountsPanel.BrowsedMastodonInstance`'s own doc. `avatarUrl`/`displayName` both start
`Nothing` (the `createSession` response this is built from carries no profile info at all) and are
filled in shortly after, if they resolve, by a follow-up `fetchProfileTask` call -- see
`GotBlueskyProfileResult`.
-}
type alias BlueskyAccount =
    { handle : String
    , accessToken : String
    , enabled : Bool
    , avatarUrl : Maybe String
    , displayName : Maybe String
    , sortOrder : Int
    }


encodeList : List BlueskyAccount -> Encode.Value
encodeList accounts =
    Encode.list encodeAccount accounts


encodeAccount : BlueskyAccount -> Encode.Value
encodeAccount account =
    Encode.object
        [ ( "handle", Encode.string account.handle )
        , ( "accessToken", Encode.string account.accessToken )
        , ( "enabled", Encode.bool account.enabled )
        , ( "avatarUrl", account.avatarUrl |> Maybe.map Encode.string |> Maybe.withDefault Encode.null )
        , ( "displayName", account.displayName |> Maybe.map Encode.string |> Maybe.withDefault Encode.null )
        , ( "sortOrder", Encode.int account.sortOrder )
        ]


decoder : Decoder (List BlueskyAccount)
decoder =
    Decode.list accountDecoder


accountDecoder : Decoder BlueskyAccount
accountDecoder =
    Decode.map6 BlueskyAccount
        (Decode.field "handle" Decode.string)
        (Decode.field "accessToken" Decode.string)
        (Decode.field "enabled" Decode.bool)
        (Decode.maybe (Decode.field "avatarUrl" Decode.string))
        (Decode.maybe (Decode.field "displayName" Decode.string))
        sortOrderDecoder


{-| `com.atproto.server.createSession` -- Bluesky's own login RPC, taking a handle and App Password
directly (see `BlueskyAccount`'s own doc on why there's no OAuth popup here, and the known
`bsky.social`-only limitation). Decodes just `handle`/`accessJwt`, all a `BlueskyAccount` needs.
-}
createSessionTask : String -> String -> Task Http.Error BlueskyAccount
createSessionTask handle appPassword =
    Http.task
        { method = "POST"
        , headers = []
        , url = "https://bsky.social/xrpc/com.atproto.server.createSession"
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "identifier", Encode.string handle )
                    , ( "password", Encode.string appPassword )
                    ]
                )
        , resolver =
            jsonResolver sessionDecoder
                (\metadata body -> Http.BadBody (errorBody body |> Maybe.withDefault ("HTTP " ++ String.fromInt metadata.statusCode)))
        , timeout = Just 10000
        }


sessionDecoder : Decode.Decoder BlueskyAccount
sessionDecoder =
    Decode.map6 BlueskyAccount
        (Decode.field "handle" Decode.string)
        (Decode.field "accessJwt" Decode.string)
        (Decode.succeed True)
        (Decode.succeed Nothing)
        (Decode.succeed Nothing)
        -- Overwritten by `Shared.AccountsPanel.GotBlueskyConnectResult` with
        -- `nextFrontAccountSortOrder model` before this ever reaches `model.blueskyAccounts` --
        -- see that handler.
        (Decode.succeed 0)


{-| `com.atproto.server.createSession`'s error responses are `{ error : String, message : String }`
(e.g. `{"error":"AuthenticationRequired","message":"Invalid identifier or password"}`) -- extracts
`message` when present, so `BlueskyConnectForm.status`'s `Errored` shows something more useful than
a bare status code.
-}
errorBody : String -> Maybe String
errorBody body =
    Decode.decodeString (Decode.field "message" Decode.string) body |> Result.toMaybe


{-| `fetchProfileTask`'s result -- `avatarUrl`/`displayName` both `Nothing` if unset, the same
as `Shared.AccountsPanel.MastodonAccountAndServers.MastodonInstanceInfo`'s own convention.
-}
type alias BlueskyProfile =
    { avatarUrl : Maybe String
    , displayName : Maybe String
    }


{-| `app.bsky.actor.getProfile` for `handle`, authenticated with the just-connected account's own
`accessToken` -- fetched once right after `createSessionTask` succeeds (see
`GotBlueskyConnectResult`/`GotBlueskyProfileResult`), since the session response itself carries no
profile info.
-}
fetchProfileTask : String -> String -> Task Http.Error BlueskyProfile
fetchProfileTask handle accessToken =
    Http.task
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ accessToken) ]
        , url = "https://bsky.social/xrpc/app.bsky.actor.getProfile?actor=" ++ handle
        , body = Http.emptyBody
        , resolver =
            jsonResolver profileDecoder
                (\metadata _ -> Http.BadStatus metadata.statusCode)
        , timeout = Just 10000
        }


profileDecoder : Decode.Decoder BlueskyProfile
profileDecoder =
    Decode.map2 BlueskyProfile
        (Decode.maybe (Decode.field "avatar" Decode.string))
        (Decode.maybe (Decode.field "displayName" Decode.string) |> Decode.map (Maybe.andThen nonEmpty))


{-| `GotBlueskyConnectResult`'s error-to-display-string projection -- `Http.BadBody` here always
carries `createSessionTask`'s own already-human-readable message (either the server's own
`message`, or a bare status code fallback -- see `errorBody`), so it's shown as-is; every
other `Http.Error` variant gets a generic message, same as this codebase's `grpcErrorToString`
doesn't try to describe network/timeout errors in detail either.
-}
errorMessage : Http.Error -> String
errorMessage err =
    case err of
        Http.BadBody message ->
            message

        Http.BadUrl _ ->
            "Couldn't connect to Bluesky."

        Http.Timeout ->
            "Bluesky didn't respond in time."

        Http.NetworkError ->
            "Couldn't reach Bluesky."

        Http.BadStatus code ->
            "Bluesky returned an error (" ++ String.fromInt code ++ ")."
