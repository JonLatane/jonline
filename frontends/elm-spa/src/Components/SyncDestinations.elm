module Components.SyncDestinations exposing
    ( createSyncDestination
    , deleteSyncDestination
    , syncDestinationsView
    )

{-| RPC wrappers for `SyncDestination` (`protos/sync.proto`) -- mirrors
`Components.EventSyncSources` in shape (each takes the calling account/server as an
`AccountsPanel.MaybeAccountServer` and returns a `Task` resolving to `( Maybe AccountsPanel.Msg,
response )`), but only the three RPCs `Components.Pages.UserProfilePage`'s "Sync Destinations"
section actually needs: get/create/delete. There's no `updateSyncDestination` wrapper here --
reconnecting an existing destination isn't exposed in the UI yet, only link/unlink.

Also home to `syncDestinationsView`, the generic already-synced/available-to-sync-to row-rendering
logic shared by `Components.Events.eventSyncDestinationsView` (wrapping
`EventInstance.syncDestinations`) and `Components.Posts.postSyncDestinationsView` (wrapping
`Post.syncDestinations`) -- see that function's own doc for the union/rendering rules.
-}

import Grpc
import Html exposing (Html, a, button, div, span, text)
import Html.Attributes exposing (class, disabled, href, rel, target)
import Html.Events exposing (onClick)
import Proto.Jonline exposing (SyncDestination, SyncDestinationStatus)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.SyncDestination.Configuration as DestinationConfiguration
import Shared.AccountsPanel as AccountsPanel exposing (withAccessToken)
import Task exposing (Task)


{-| Always creates a destination owned by the calling account (mirrors
`createEventSyncSource`'s own doc -- the backend ignores/overrides any `owner` sent). Requires
`SYNC_EVENTS_TO_FACEBOOK` or `SYNC_POSTS_TO_FACEBOOK` (or Admin) server-side.
-}
createSyncDestination :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> SyncDestination
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, SyncDestination )
createSyncDestination accountsPanelModel maybeAccountServer destination =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.createSyncDestination destination
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


{-| `deleteSyncedPosts` is always sent `False` here -- there's no UI for the "also delete the
Facebook posts" option yet (see `DeleteSyncDestinationRequest.deleteSyncedPosts`), only a
plain unlink.
-}
deleteSyncDestination :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> SyncDestination
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, () )
deleteSyncDestination accountsPanelModel maybeAccountServer destination =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.deleteSyncDestination
                { destination = Just destination, deleteSyncedPosts = False }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
                |> Task.map (always ())
        )


{-| `Nothing` renders one line per `syncDestinations` entry with a
`destinationUrl` set, linking out to wherever the content item was synced to (e.g. the resulting
Facebook post) -- read-only, no push controls -- used by every caller except
`Components.Pages.UserProfilePage`'s embedded feeds.

`Just availableDestinations` renders a unified row list instead: one row per destination id in
`syncDestinations` (already synced, shows its URL if any) unioned with any of
`availableDestinations` not yet in that list (not yet synced, no URL), each with a "Push"/"Push
again" button -- `isPushing`/`pushError` (keyed by destination id) drive its disabled/error state,
`onPush` fires the push. Already-synced rows also get a Delete button (`onDelete`, given the
destination id and its display name for the confirmation dialog -- see
`Shared.ConfirmEventInstanceSyncDestinationDelete`/`Shared.ConfirmPostSyncDestinationDelete`),
which removes just the local sync record, putting the row back into its unsynced "Push" state.
This `Maybe` is the *only* gate on whether push/delete controls show at all -- deciding when to
pass `Just` (only `UserProfilePage`'s own embedded feeds, for now) is entirely the caller's call;
this module has no opinion on `AccountsPanel`/permissions.

Shared by `Components.Events.eventSyncDestinationsView` (passing `instance.syncDestinations`) and
`Components.Posts.postSyncDestinationsView` (passing `post.syncDestinations`) -- both thin
wrappers over this. Kept on the `.event-*`-prefixed CSS classes `events.css` already defines for
this row layout (`.event-card-sync-destinations`/`.event-card-sync-destination-*`,
`.event-synced-to*`) rather than introducing a `.post-*` equivalent -- they're purely visual and
carry no `.event-card`-specific selector, so they render identically for a Post card/detail view.
-}
syncDestinationsView :
    List SyncDestinationStatus
    -> Maybe (List SyncDestination)
    -> (String -> Bool)
    -> (String -> Maybe String)
    -> (String -> msg)
    -> (String -> String -> msg)
    -> Html msg
syncDestinationsView syncDestinations availableSyncDestinations isPushing pushError onPush onDelete =
    case availableSyncDestinations of
        Nothing ->
            let
                urls : List String
                urls =
                    syncDestinations |> List.filterMap .destinationUrl
            in
            if List.isEmpty urls then
                text ""

            else
                div [ class "event-synced-to" ]
                    (urls
                        |> List.map
                            (\url ->
                                div [ class "event-synced-to-line" ]
                                    [ text "synced to "
                                    , a [ href url, target "_blank", rel "noopener noreferrer", class "event-synced-to-link" ] [ text url ]
                                    ]
                            )
                    )

        Just availableDestinations ->
            let
                destinationName : String -> Maybe String
                destinationName id =
                    availableDestinations
                        |> List.filter (\d -> d.id == id)
                        |> List.head
                        |> Maybe.andThen .configuration
                        |> Maybe.map (\(DestinationConfiguration.FacebookPage page) -> page.pageName)

                syncedRows : List { id : String, url : Maybe String, synced : Bool }
                syncedRows =
                    syncDestinations
                        |> List.map (\sd -> { id = sd.syncDestinationId, url = sd.destinationUrl, synced = True })

                syncedIds : List String
                syncedIds =
                    syncedRows |> List.map .id

                notYetSyncedRows : List { id : String, url : Maybe String, synced : Bool }
                notYetSyncedRows =
                    availableDestinations
                        |> List.filter (\d -> not (List.member d.id syncedIds))
                        |> List.map (\d -> { id = d.id, url = Nothing, synced = False })

                rows : List { id : String, url : Maybe String, synced : Bool }
                rows =
                    syncedRows ++ notYetSyncedRows
            in
            if List.isEmpty rows then
                text ""

            else
                div [ class "event-card-sync-destinations" ]
                    (rows |> List.map (syncDestinationRowView destinationName isPushing pushError onPush onDelete))


syncDestinationRowView :
    (String -> Maybe String)
    -> (String -> Bool)
    -> (String -> Maybe String)
    -> (String -> msg)
    -> (String -> String -> msg)
    -> { id : String, url : Maybe String, synced : Bool }
    -> Html msg
syncDestinationRowView destinationName isPushing pushError onPush onDelete row =
    let
        pushing : Bool
        pushing =
            isPushing row.id

        label : String
        label =
            if pushing then
                "Pushing…"

            else if row.url == Nothing then
                "Push"

            else
                "Push again"

        name : String
        name =
            destinationName row.id |> Maybe.withDefault "Facebook Page"
    in
    div [ class "event-card-sync-destination-row" ]
        [ span [ class "event-card-sync-destination-name" ]
            [ text name ]
        , case row.url of
            Just url ->
                a
                    [ href url
                    , target "_blank"
                    , rel "noopener noreferrer"
                    , class "event-card-sync-destination-link"
                    ]
                    [ text url ]

            Nothing ->
                text ""
        , button
            [ class "event-card-sync-destination-push"
            , onClick (onPush row.id)
            , disabled pushing
            ]
            [ text label ]
        , if row.synced then
            button
                [ class "event-card-sync-destination-delete"
                , onClick (onDelete row.id name)
                , disabled pushing
                ]
                [ text "Delete" ]

          else
            text ""
        , case pushError row.id of
            Just err ->
                div [ class "event-card-sync-destination-push-error" ] [ text err ]

            Nothing ->
                text ""
        ]
