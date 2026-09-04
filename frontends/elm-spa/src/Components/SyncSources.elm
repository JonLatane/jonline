module Components.SyncSources exposing
    ( createSyncSource
    , deleteSyncSource
    , getSyncSources
    , intervalOptions
    , syncedCountsLabel
    , updateSyncSource
    )

{-| RPC wrappers for `SyncSource` (`protos/sync.proto`) -- mirrors
`Components.Users`' `updateUser`/`federateProfile`/etc in shape: each takes
the calling account/server as an `AccountsPanel.MaybeAccountServer` and
returns a `Task` resolving to `( Maybe AccountsPanel.Msg, response )`, so a
token refresh mid-request can still be forwarded on by the caller (see
`Shared.AccountsPanel.performWithAccountServer`).

`UserProfilePage` no longer fetches `SyncSource`s on its own initial load (it reads
`User.sync_sources`, already carried by the resolved `User`), and every mutation now triggers
a full `refetch` of that `User`. `getSyncSources` is still used, though -- by that section's
manual "Refresh" button (`SyncSourcesRefreshClicked`), which overlays just the fresh `sources`
onto the resolved `User` without a whole-profile refetch -- see `Components.AIModelProviders`' own
matching doc comment on `getAIModelProviders`.
-}

import Grpc
import Proto.Jonline exposing (GetSyncSourcesResponse, SyncSource, defaultUser)
import Proto.Jonline.Jonline as Jonline
import Shared.AccountsPanel as AccountsPanel exposing (withAccessToken)
import Shared.Conversions as Conversions
import Task exposing (Task)


{-| "N events" alone when every event has exactly one instance (the common
non-recurring case, where naming both is redundant) -- otherwise "N events
and M instances". Used by both `Components.Pages.UserProfilePage` (each row's
"delete along with its events" button) and `UI`'s shared delete-confirmation
dialog for the same source, so it lives here rather than on either caller.
-}
syncedCountsLabel : SyncSource -> String
syncedCountsLabel source =
    let
        eventCount : Int
        eventCount =
            Conversions.int64ToInt source.eventCount

        instanceCount : Int
        instanceCount =
            Conversions.int64ToInt source.eventInstanceCount
    in
    if eventCount == instanceCount then
        pluralCount eventCount "event"

    else
        pluralCount eventCount "event"
            ++ " and "
            ++ pluralCount instanceCount "instance"


pluralCount : Int -> String -> String
pluralCount count noun =
    String.fromInt count
        ++ " "
        ++ noun
        ++ (if count == 1 then
                ""

            else
                "s"
           )


{-| `targetUserId = ""` asks the backend for the caller's own sources (see
`backend/src/rpcs/sync_sources/get_sync_sources.rs`); any other
id asks for that user's sources instead, which only succeeds for an Admin
caller.
-}
getSyncSources :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetSyncSourcesResponse )
getSyncSources accountsPanelModel maybeAccountServer targetUserId =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.getSyncSources { defaultUser | id = targetUserId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


{-| Always creates a source owned by the calling account -- the backend
ignores/overrides any `owner` sent (see `create_sync_source.rs`), so
there's no `targetUserId` parameter here unlike `getSyncSources`.
-}
createSyncSource :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> SyncSource
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, SyncSource )
createSyncSource accountsPanelModel maybeAccountServer source =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.createSyncSource source
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


updateSyncSource :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> SyncSource
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, SyncSource )
updateSyncSource accountsPanelModel maybeAccountServer source =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.updateSyncSource source
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


deleteSyncSource :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> SyncSource
    -> Bool
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, () )
deleteSyncSource accountsPanelModel maybeAccountServer source deleteSyncedEvents =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.deleteSyncSource
                { source = Just source, deleteSyncedEvents = deleteSyncedEvents }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
                |> Task.map (always ())
        )


{-| The fixed set of sync intervals offered in the UI (seconds, label) --
matches what was asked for: 5/15/30 minutes, 1/4/8 hours, 1 day.
-}
intervalOptions : List ( Int, String )
intervalOptions =
    [ ( 60, "1 minute" )
    , ( 300, "5 minutes" )
    , ( 900, "15 minutes" )
    , ( 1800, "30 minutes" )
    , ( 3600, "1 hour" )
    , ( 14400, "4 hours" )
    , ( 28800, "8 hours" )
    , ( 86400, "1 day" )
    ]
