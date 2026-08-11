module Components.EventSyncDestinations exposing
    ( createEventSyncDestination
    , deleteEventSyncDestination
    )

{-| RPC wrappers for `EventSyncDestination` (`protos/events.proto`) -- mirrors
`Components.EventSyncSources` in shape (each takes the calling account/server as an
`AccountsPanel.MaybeAccountServer` and returns a `Task` resolving to `( Maybe AccountsPanel.Msg,
response )`), but only the three RPCs `Components.Pages.UserProfilePage`'s "Event Sync
Destinations" section actually needs: get/create/delete. There's no `updateEventSyncDestination`
wrapper here -- reconnecting an existing destination isn't exposed in the UI yet, only
link/unlink.
-}

import Grpc
import Proto.Jonline exposing (EventSyncDestination)
import Proto.Jonline.Jonline as Jonline
import Shared.AccountsPanel as AccountsPanel exposing (withAccessToken)
import Task exposing (Task)


{-| Always creates a destination owned by the calling account (mirrors
`createEventSyncSource`'s own doc -- the backend ignores/overrides any `owner` sent). Requires the
`SYNC_EVENTS_TO_FACEBOOK` permission (or Admin) server-side.
-}
createEventSyncDestination :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> EventSyncDestination
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, EventSyncDestination )
createEventSyncDestination accountsPanelModel maybeAccountServer destination =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.createEventSyncDestination destination
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


{-| `deleteSyncedPosts` is always sent `False` here -- there's no UI for the "also delete the
Facebook posts" option yet (see `DeleteEventSyncDestinationRequest.deleteSyncedPosts`), only a
plain unlink.
-}
deleteEventSyncDestination :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> EventSyncDestination
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, () )
deleteEventSyncDestination accountsPanelModel maybeAccountServer destination =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.deleteEventSyncDestination
                { destination = Just destination, deleteSyncedPosts = False }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
                |> Task.map (always ())
        )
