module Shared.AccountsPanel.SortOrder exposing (missingSortOrderSentinel, sortOrderDecoder)

{-| The shared `sortOrder : Int` decode fallback every reorderable, persisted list in
`Shared.AccountsPanel` (Rellm servers/accounts, browsed Mastodon instances, connected Mastodon/
Bluesky accounts) uses -- pulled into its own leaf module (rather than living in
`Shared.AccountsPanel` itself) purely so `Shared.AccountsPanel.MastodonAccountAndServers`/
`Shared.AccountsPanel.BlueskyAccounts` can both import it too, without a cyclic import back to
`Shared.AccountsPanel`.
-}

import Json.Decode as Decode exposing (Decoder)


{-| Sentinel `sortOrder` for an entry persisted before that field existed -- `sortOrderDecoder`
falls back to this (mirroring `Shared.AccountsPanel.realNameDecoder`/`needsPasswordDecoder`/
`permissionsDecoder`'s own "default when the key is missing entirely" pattern) rather than failing
the rest of the decode. `Shared.AccountsPanel.migrateServerFeedItemSortOrders`/
`migrateAccountItemSortOrders` (run once, in `init`) replace every sentinel-valued entry with a real
one -- see their own docs. Deliberately far outside the range any real `sortOrder` could reach (the
`nextFront*SortOrder`/`nextBack*SortOrder` helpers only ever step by 1 from whatever's already
there), so it can never collide with one.
-}
missingSortOrderSentinel : Int
missingSortOrderSentinel =
    -2000000000


{-| Defaults to `missingSortOrderSentinel` if the key is missing entirely (state persisted before
`sortOrder` existed), without failing the rest of the decode -- see that value's own doc.
-}
sortOrderDecoder : Decoder Int
sortOrderDecoder =
    Decode.oneOf
        [ Decode.field "sortOrder" Decode.int
        , Decode.succeed missingSortOrderSentinel
        ]
