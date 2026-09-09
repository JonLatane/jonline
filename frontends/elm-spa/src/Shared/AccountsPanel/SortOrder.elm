module Shared.AccountsPanel.SortOrder exposing
    ( assignMissingSortOrders
    , nextMigratedSortOrderStart
    , sortOrderDecoder
    )

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


{-| One past the highest real (non-`missingSortOrderSentinel`) `sortOrder` across every list in a
migration's shared space, or `0` if none of them have one yet -- where `assignMissingSortOrders`
should start counting up from for that space's still-missing entries. Used by
`Shared.AccountsPanel.migrateServerFeedItemSortOrders`/`migrateAccountItemSortOrders` (kept there,
not here, since each mixes types from more than one provider submodule -- Rellm servers/accounts
alongside browsed Mastodon instances/connected Mastodon and Bluesky accounts -- so there's no single
provider module either could live in without a cyclic or one-sided dependency on the others).
-}
nextMigratedSortOrderStart : List (List Int) -> Int
nextMigratedSortOrderStart sortOrderLists =
    (List.concat sortOrderLists
        |> List.filter ((/=) missingSortOrderSentinel)
        |> List.maximum
        |> Maybe.withDefault -1
    )
        + 1


{-| Walks `items` in their own existing order, replacing every `missingSortOrderSentinel` entry with
the next sequential value counting up from `counter` -- so upgrading from a pre-`sortOrder` version
doesn't visibly reshuffle anything already on screen (each list keeps its own relative order; the
lists in a migration's shared space stack in roughly the same order they used to occupy separate
sections in). Returns the counter's value just past the last one it handed out (for a caller
migrating a second list in the same space right after) alongside the migrated list itself.
-}
assignMissingSortOrders : Int -> List { a | sortOrder : Int } -> ( Int, List { a | sortOrder : Int } )
assignMissingSortOrders counter items =
    List.foldl
        (\item ( next, acc ) ->
            if item.sortOrder == missingSortOrderSentinel then
                ( next + 1, { item | sortOrder = next } :: acc )

            else
                ( next, item :: acc )
        )
        ( counter, [] )
        items
        |> Tuple.mapSecond List.reverse
