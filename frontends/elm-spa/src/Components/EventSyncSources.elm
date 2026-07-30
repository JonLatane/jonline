module Components.EventSyncSources exposing
    ( createEventSyncSource
    , deleteEventSyncSource
    , getEventSyncSources
    , intervalOptions
    , intervalText
    , updateEventSyncSource
    )

{-| RPC wrappers for `EventSyncSource` (`protos/events.proto`) -- mirrors
`Components.Users`' `updateUser`/`federateProfile`/etc in shape: each takes
the calling account/server as an `AccountsPanel.MaybeAccountServer` and
returns a `Task` resolving to `( Maybe AccountsPanel.Msg, response )`, so a
token refresh mid-request can still be forwarded on by the caller (see
`Shared.AccountsPanel.performWithAccountServer`).
-}

import Grpc
import Proto.Google.Protobuf
import Proto.Jonline exposing (DeleteEventSyncSourceRequest, EventSyncSource, GetEventSyncSourcesResponse, User, defaultUser)
import Proto.Jonline.Jonline as Jonline
import Shared.AccountsPanel as AccountsPanel exposing (withAccessToken)
import Task exposing (Task)


{-| `targetUserId = ""` asks the backend for the caller's own sources (see
`backend/src/rpcs/event_sync_sources/get_event_sync_sources.rs`); any other
id asks for that user's sources instead, which only succeeds for an Admin
caller.
-}
getEventSyncSources :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetEventSyncSourcesResponse )
getEventSyncSources accountsPanelModel maybeAccountServer targetUserId =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.getEventSyncSources { defaultUser | id = targetUserId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


{-| Always creates a source owned by the calling account -- the backend
ignores/overrides any `owner` sent (see `create_event_sync_source.rs`), so
there's no `targetUserId` parameter here unlike `getEventSyncSources`.
-}
createEventSyncSource :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> EventSyncSource
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, EventSyncSource )
createEventSyncSource accountsPanelModel maybeAccountServer source =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.createEventSyncSource source
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


updateEventSyncSource :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> EventSyncSource
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, EventSyncSource )
updateEventSyncSource accountsPanelModel maybeAccountServer source =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.updateEventSyncSource source
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


deleteEventSyncSource :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> EventSyncSource
    -> Bool
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, () )
deleteEventSyncSource accountsPanelModel maybeAccountServer source deleteSyncedEvents =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.deleteEventSyncSource
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
    [ ( 300, "5 minutes" )
    , ( 900, "15 minutes" )
    , ( 1800, "30 minutes" )
    , ( 3600, "1 hour" )
    , ( 14400, "4 hours" )
    , ( 28800, "8 hours" )
    , ( 86400, "1 day" )
    ]


{-| Label for a `sync_interval_seconds` value -- falls back to a plain
"`N` seconds" for anything outside `intervalOptions` (e.g. a value set by
some other client), rather than showing nothing.
-}
intervalText : Int -> String
intervalText seconds =
    intervalOptions
        |> List.filter (\( s, _ ) -> s == seconds)
        |> List.head
        |> Maybe.map Tuple.second
        |> Maybe.withDefault (String.fromInt seconds ++ " seconds")
