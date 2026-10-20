module Shared.AccountsPanel.BlueskyAppViews exposing
    ( BlueskyAppView
    , BlueskyState
    , builtInLogoUrl
    , decoder
    , disableAll
    , displayName
    , emptyState
    , enableOnly
    , encode
    , encodeState
    , logoUrlFor
    , normalize
    , normalizeLogoUrl
    , stateDecoder
    )

{-| Everything about an anonymously-browsed Bluesky AppView that doesn't need
`Shared.AccountsPanel.Model` itself to make sense: the persisted-list element type (`BlueskyAppView`)
and its encode/decode, the Bluesky counterpart of `Shared.AccountsPanel.MastodonServers`'
`BrowsedMastodonInstance`.

AT Protocol splits "a server" into a PDS (hosts an account, handles its login) and an AppView (the read
side for the whole network) -- see `Shared.Federation.Common.BlueskyAuth`. An AppView such as Bluesky
PBC's `public.api.bsky.app` serves public data with no login at all, so adding one to the server strip
works like browsing a Mastodon instance's public timeline: no account involved. That makes it a
_server_ (`CombinedServerFeedItem`), whereas a connected `BlueskyAccount` (a PDS login, which also
brings personalization like a home timeline) stays an _account_. Every AppView and account reads the
same global network, so at most one Bluesky source is enabled at a time -- `enableOnly`/`disableAll`
here, plus `BlueskyAccounts.disableOtherBlueskyAccounts` for the account side.

-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Proto.Rellm exposing (BlueskyServer)
import Shared.AccountsPanel.BlueskyAccounts as BlueskyAccounts exposing (BlueskyAccount)
import Shared.AccountsPanel.SortOrder exposing (sortOrderDecoder)
import Shared.Federation.Common exposing (publicBlueskyAppViewHost)
import Url


{-| One AppView being browsed. `host` is its API hostname (`BlueskyServer.host`, e.g.
`public.api.bsky.app`). `enabled`/`sortOrder` mirror `BrowsedMastodonInstance`'s.
-}
type alias BlueskyAppView =
    { host : String
    , enabled : Bool
    , sortOrder : Int
    }


{-| What a chip shows for `host`: the public AppView is just "bsky.app" to users; any other AppView is
shown as its own hostname.
-}
displayName : String -> String
displayName host =
    if host == publicBlueskyAppViewHost then
        "bsky.app"

    else
        host


{-| The logo to show for the AppView at `host`: the `logoUrl` an admin set on its `BlueskyServer` (if
`configured` -- the main server's `FederationInfo.blueskyServers` -- has an entry for it with one),
else `builtInLogoUrl`. `Nothing` means "show the letter placeholder".
-}
logoUrlFor : List BlueskyServer -> String -> Maybe String
logoUrlFor configured host =
    configured
        |> List.filter (\bs -> bs.host == host)
        |> List.filterMap (\bs -> bs.logoUrl |> Maybe.andThen normalizeLogoUrl)
        |> List.head
        |> orElse (builtInLogoUrl host)


orElse : Maybe a -> Maybe a -> Maybe a
orElse fallback primary =
    case primary of
        Just _ ->
            primary

        Nothing ->
            fallback


{-| A logo URL as an admin may enter it: trimmed, and only `https://` ones count (anything else --
including a blank box -- is "no logo"), matching `BlueskyServer.logo_url`'s own doc. HTTPS-only because a
plain `http://` image on an HTTPS page is blocked as mixed content anyway, and it's only ever used as an
`<img src>`, so a stray scheme couldn't run anything.
-}
normalizeLogoUrl : String -> Maybe String
normalizeLogoUrl raw =
    let
        trimmed : String
        trimmed =
            String.trim raw
    in
    if String.startsWith "https://" trimmed then
        Just trimmed

    else
        Nothing


{-| The logo bundled with the app for Bluesky's own public AppView (the butterfly, as an inline SVG data
URI so there's no asset to serve): AT Protocol gives an AppView no way to describe itself (compare a Mastodon
instance's `thumbnail`), so anything else has none unless an admin sets `BlueskyServer.logo_url`.
-}
builtInLogoUrl : String -> Maybe String
builtInLogoUrl host =
    if host == publicBlueskyAppViewHost then
        Just butterflyLogoUrl

    else
        Nothing


butterflyLogoUrl : String
butterflyLogoUrl =
    "data:image/svg+xml," ++ Url.percentEncode butterflySvg


butterflySvg : String
butterflySvg =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\"><path fill=\"#1185FE\" d=\"M12 10.8c-1.087-2.114-4.046-6.053-6.798-7.995C2.566.944 1.561 1.266.902 1.565.139 1.908 0 3.08 0 3.768c0 .69.378 5.65.624 6.479.815 2.736 3.713 3.66 6.383 3.364.136-.02.275-.039.415-.056-.138.022-.276.04-.415.056-3.912.58-7.387 2.005-2.83 7.078 5.013 5.19 6.87-1.113 7.823-4.308.953 3.195 2.05 9.271 7.733 4.308 4.267-4.308 1.172-6.498-2.74-7.078a8.741 8.741 0 0 1-.415-.056c.14.017.279.036.415.056 2.67.297 5.568-.628 6.383-3.364.246-.828.624-5.79.624-6.478 0-.69-.139-1.861-.902-2.206-.659-.298-1.664-.62-4.3 1.24C16.046 4.748 13.087 8.687 12 10.8Z\"/></svg>"


encode : BlueskyAppView -> Encode.Value
encode appView =
    Encode.object
        [ ( "host", Encode.string appView.host )
        , ( "enabled", Encode.bool appView.enabled )
        , ( "sortOrder", Encode.int appView.sortOrder )
        ]


decoder : Decoder BlueskyAppView
decoder =
    Decode.map3 BlueskyAppView
        (Decode.field "host" Decode.string)
        (Decode.field "enabled" Decode.bool)
        sortOrderDecoder


{-| Disables every AppView -- called whenever a Bluesky account becomes enabled (a connected account's
view of the network is a superset of an anonymous one's).
-}
disableAll : List BlueskyAppView -> List BlueskyAppView
disableAll appViews =
    List.map (\a -> { a | enabled = False }) appViews


{-| Restores the "one Bluesky source at a time" invariant for state that didn't come from one of the
transitions that maintain it (persisted state, another tab's broadcast): any enabled account wins, so
every AppView is disabled; otherwise only the first enabled AppView stays on.
-}
normalize : List BlueskyAccount -> List BlueskyAppView -> List BlueskyAppView
normalize accounts appViews =
    if List.any .enabled accounts then
        disableAll appViews

    else
        case List.filter .enabled appViews of
            first :: _ :: _ ->
                enableOnly first.host appViews

            _ ->
                appViews


{-| Enables `host` and disables every other AppView -- only one Bluesky source is shown at a time.
-}
enableOnly : String -> List BlueskyAppView -> List BlueskyAppView
enableOnly host appViews =
    List.map (\a -> { a | enabled = a.host == host }) appViews


{-| `Ports.persistBlueskyAccounts`'s wire format -- the connected `BlueskyAccount`s and the
anonymously-browsed `BlueskyAppView`s bundled into one value (they're two `Model` fields rendered in
different places -- `UI.accountsList` and `UI.combinedServerFeedItemsStrip` -- but one "which Bluesky
source is on" decision, so persisted and broadcast to other tabs together). Written as
`{ accounts, appViews }`; `stateDecoder` also still reads what this port used to persist, a bare list of
accounts.

(A build from before AppViews existed can't read the object form -- it decodes it as no accounts -- so
rolling back to one drops the saved Bluesky accounts the next time it persists. Accounts can simply be
reconnected, but it's why this isn't a no-op to roll back.)
-}
type alias BlueskyState =
    { accounts : List BlueskyAccount
    , appViews : List BlueskyAppView
    }


emptyState : BlueskyState
emptyState =
    { accounts = [], appViews = [] }


stateDecoder : Decoder BlueskyState
stateDecoder =
    Decode.oneOf
        [ Decode.map2 BlueskyState
            (Decode.field "accounts" BlueskyAccounts.decoder)
            (Decode.field "appViews" (Decode.list decoder))
        , BlueskyAccounts.decoder |> Decode.map (\accounts -> { accounts = accounts, appViews = [] })
        ]


encodeState : BlueskyState -> Encode.Value
encodeState state =
    Encode.object
        [ ( "accounts", BlueskyAccounts.encodeList state.accounts )
        , ( "appViews", Encode.list encode state.appViews )
        ]
