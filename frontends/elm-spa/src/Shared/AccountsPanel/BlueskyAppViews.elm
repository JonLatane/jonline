module Shared.AccountsPanel.BlueskyAppViews exposing
    ( BlueskyAppView
    , BlueskyState
    , decoder
    , disableAll
    , displayName
    , emptyState
    , enableOnly
    , encode
    , encodeState
    , normalize
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
import Shared.AccountsPanel.BlueskyAccounts as BlueskyAccounts exposing (BlueskyAccount)
import Shared.AccountsPanel.SortOrder exposing (sortOrderDecoder)
import Shared.Federation.Common exposing (publicBlueskyAppViewHost)


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
