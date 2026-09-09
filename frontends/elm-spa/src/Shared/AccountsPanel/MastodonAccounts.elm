module Shared.AccountsPanel.MastodonAccounts exposing
    ( MastodonAccount
    , encodeMastodonAccount
    , mastodonAccountDecoder
    , mastodonLoginResultDecoder
    , verifyMastodonCredentialsTask
    )

{-| Everything about a connected Mastodon account that doesn't need `Shared.AccountsPanel.Model`
itself to make sense: the persisted-list element type (`MastodonAccount`), its encode/decode, and the
plain HTTP tasks/decoders `Shared.AccountsPanel.update` drives to build it (`MastodonConnectClicked`'s
OAuth popup result, `verify_credentials`). See `Shared.AccountsPanel.MastodonServers` for the sibling
module covering *browsed* (not connected) Mastodon instances -- the two used to be one module
(`MastodonAccountAndServers`) since they're persisted together (see
`Ports.persistMastodonAccountsAndServers`), but that bundling is `Shared.AccountsPanel`'s own
coordinating concern (mirrors `PersistedState` bundling `RellmAccount`s and `RellmServer`s), not
something either type needs to know about itself.

What's deliberately *not* here, and stays in `Shared.AccountsPanel` itself: the `Model` field this
lives in (`mastodonAccounts`), and every `Msg`/`update` case that reacts to user actions and persists
the result.

-}

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Shared.AccountsPanel.SortOrder exposing (sortOrderDecoder)
import Shared.Federation.Common exposing (jsonResolver)
import Task exposing (Task)


{-| A Mastodon account connected via `UI.mastodonConnectButton`'s "Connect" button (see
`Shared.AccountsPanel.MastodonConnectClicked`/`GotMastodonLoginResult`) -- `accessToken` came out of
an OAuth popup Elm never directly handled (see `Ports.facebookLoginPopup`'s `"mastodon"` provider:
app registration (the admin-registered `MastodonServer.appId`, looked up via
`Shared.AccountsPanel.mastodonServerFor`, or -- if that instance has none -- a throwaway one
dynamically self-registered on the spot), PKCE, and the code/token exchange all happen in
`public/index.html`'s JS, entirely between the browser and `instanceHost` itself, `app_secret` never
included either way), and `username` is fetched once, right after, via
`GET /api/v1/accounts/verify_credentials` (see `verifyMastodonCredentialsTask`) -- just enough to
display the connection, not a full `RellmAccount`, since a Mastodon account isn't a Rellm one.
-}
type alias MastodonAccount =
    { instanceHost : String
    , accessToken : String
    , username : String
    , sortOrder : Int
    }


encodeMastodonAccount : MastodonAccount -> Encode.Value
encodeMastodonAccount account =
    Encode.object
        [ ( "instanceHost", Encode.string account.instanceHost )
        , ( "accessToken", Encode.string account.accessToken )
        , ( "username", Encode.string account.username )
        , ( "sortOrder", Encode.int account.sortOrder )
        ]


mastodonAccountDecoder : Decoder MastodonAccount
mastodonAccountDecoder =
    Decode.map4 MastodonAccount
        (Decode.field "instanceHost" Decode.string)
        (Decode.field "accessToken" Decode.string)
        (Decode.field "username" Decode.string)
        sortOrderDecoder


{-| Decodes a `facebookLoginResult` payload (`{ ok : Bool, value : String }`, see that port's own
doc) for the `"mastodon"` provider specifically -- `Ok accessToken` on success, `Err message`
otherwise (including the "cancelled" case, same as every other provider's use of this port).
Mirrors `Components.Pages.UserProfilePage.facebookLoginResultDecoder` exactly; kept as its own copy
here rather than exposed cross-module, since the two are otherwise unrelated (one page's Facebook/
Threads/X connect flows, this module's Mastodon one).
-}
mastodonLoginResultDecoder : Decode.Value -> Result String String
mastodonLoginResultDecoder value =
    case
        Decode.decodeValue
            (Decode.map2 Tuple.pair (Decode.field "ok" Decode.bool) (Decode.field "value" Decode.string))
            value
    of
        Ok ( True, token ) ->
            Ok token

        Ok ( False, err ) ->
            Err err

        Err err ->
            Err (Decode.errorToString err)


{-| `GET /api/v1/accounts/verify_credentials` against `instanceHost`, authenticated with the
freshly-minted `accessToken` -- the one Mastodon call `GotMastodonLoginResult` needs before it can
actually add a `MastodonAccount`, since the OAuth result alone is just a bare token with no
identity attached yet. Decodes just `username`, all a `MastodonAccount` needs to display the
connection.
-}
verifyMastodonCredentialsTask : String -> String -> Task Http.Error String
verifyMastodonCredentialsTask instanceHost accessToken =
    Http.task
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ accessToken) ]
        , url = "https://" ++ instanceHost ++ "/api/v1/accounts/verify_credentials"
        , body = Http.emptyBody
        , resolver = jsonResolver (Decode.field "username" Decode.string) (\metadata _ -> Http.BadStatus metadata.statusCode)
        , timeout = Just 10000
        }
