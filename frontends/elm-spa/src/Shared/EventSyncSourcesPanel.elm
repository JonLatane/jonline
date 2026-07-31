module Shared.EventSyncSourcesPanel exposing (AddForm, Model, Msg(..), RowEdit, SubmitStatus(..), init, syncedCountsLabel, update, view)

{-| The "Event Sync Sources" section on `Components.Pages.UserProfilePage` --
basic CRUD over `EventSyncSource` (`protos/events.proto`) for the profile's
own user (or, for an Admin viewing someone else's profile, that user's
sources).

Lives in `Shared.Model` (like `Shared.MyMediaPanel`/`Shared.AccountsPanel`),
even though -- unlike those -- it's only ever displayed inline on one page,
rather than as its own global panel: `Shared.DeleteConfirmation`'s "are you
sure?" dialog always resolves through `Shared.update`'s `ConfirmDelete`,
which can only reach into `Shared.Model`'s own submodels (see
`ConfirmMediaDelete`'s handling of `MyMediaPanel.DeleteConfirmed`) -- a
Page-local model has no way to receive that confirmation back. Everything
else about the flow (fetch on open, edit/save/delete, forwarding a token
refresh, resolving which account to act as) mirrors `MyMediaPanel` at a
smaller scale.

-}

import Components.EventSyncSources as EventSyncSources
import Dict exposing (Dict)
import Grpc
import Html exposing (Html, button, div, h2, input, option, select, span, text)
import Html.Attributes exposing (class, disabled, placeholder, selected, type_, value)
import Html.Events exposing (onClick, onInput)
import Proto.Jonline exposing (EventSyncSource, GetEventSyncSourcesResponse, defaultEventSyncSource)
import Proto.Jonline.EventSyncSource.Configuration as Configuration
import Set exposing (Set)
import Shared.AccountsPanel as AccountsPanel
import Shared.BrowserTimeZone as BrowserTimeZone
import Shared.Conversions as Conversions
import Task
import UI.Classes exposing (classes, hostnameToCSSClass)


type SubmitStatus
    = Idle
    | Submitting
    | SubmitFailed String


{-| A row's in-progress edit -- created (from the source's own current
values, see `rowEditFor`) the moment the URL/interval input is first
touched, and dropped again once a save actually lands (see `update`'s
`GotRowSaveResult`). A row with no entry here just renders straight from its
`EventSyncSource` and shows "Refresh" rather than "Save" (see `isDirty`).
-}
type alias RowEdit =
    { pendingUrl : String
    , pendingIntervalSeconds : Int
    , status : SubmitStatus
    }


type alias AddForm =
    { url : String
    , intervalSeconds : Int
    , status : SubmitStatus
    }


defaultAddForm : AddForm
defaultAddForm =
    { url = "", intervalSeconds = 3600, status = Idle }


type FetchStatus
    = NotFetched
    | Fetching
    | FetchFailed String
    | Fetched


type alias Model =
    { -- The server hosting the profile currently loaded -- resolved fresh
      -- against `AccountsPanel.Model` whenever needed (see `resolve`), same
      -- "don't cache a live Account/Server" convention `MyMediaPanel.targetHost`
      -- uses. `""` means never fetched.
      targetHost : String

    -- The profile whose sources are currently loaded.
    , viewedUserId : String
    , status : FetchStatus
    , sources : List EventSyncSource
    , rowEdits : Dict String RowEdit
    , addForm : AddForm

    -- Source ids with a `DeleteEventSyncSource` request in flight -- same
    -- "a `Set`, not a single `Maybe`" reasoning as `MyMediaPanel.deletingIds`.
    , deletingIds : Set String
    }


init : Model
init =
    { targetHost = "", viewedUserId = "", status = NotFetched, sources = [], rowEdits = Dict.empty, addForm = defaultAddForm, deletingIds = Set.empty }


type Msg
    = Fetch String String
    | GotFetchResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, GetEventSyncSourcesResponse ))
    | RowUrlChanged EventSyncSource String
    | RowIntervalChanged EventSyncSource Int
    | RowSaveClicked EventSyncSource
    | RowRefreshClicked EventSyncSource
    | GotRowSaveResult String (Result Grpc.Error ( Maybe AccountsPanel.Msg, EventSyncSource ))
    | AddUrlChanged String
    | AddIntervalChanged Int
    | AddClicked
    | GotAddResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, EventSyncSource ))
      -- Doesn't delete anything itself -- bubbles `( source, deleteSyncedEvents )`
      -- up through `update`'s own extra return value for `Shared.update` to
      -- turn into a `Shared.RequestDelete`, same as `MyMediaPanel.DeleteClicked`.
      -- `deleteSyncedEvents` is `True` for the row's "Delete along with N
      -- events" button, `False` for the plain "Delete" button that leaves the
      -- already-synced events/instances on the profile, no longer associated
      -- with a source.
    | DeleteClicked EventSyncSource Bool
      -- Fired back from `Shared.update`'s `ConfirmDelete` once the user's
      -- confirmed -- this is what actually calls `DeleteEventSyncSource`.
    | DeleteConfirmed EventSyncSource Bool
    | GotDeleteResult String (Result Grpc.Error ( Maybe AccountsPanel.Msg, () ))


{-| Same shape as `MyMediaPanel.update` -- needs `AccountsPanel.Model` to
resolve `targetHost` to a signed-in `Account` to authenticate as (not
necessarily `viewedUserId` themself; an Admin can manage another user's
sources -- see `resolve`), and can surface an `AccountsPanel.Msg` (a token
refresh) alongside a `DeleteClicked` request for `Shared.update` to
dispatch.
-}
update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, ( Maybe AccountsPanel.Msg, Maybe ( EventSyncSource, Bool ) ) )
update accountsPanelModel msg model =
    case msg of
        Fetch host userId ->
            case AccountsPanel.enabledAccountForServer accountsPanelModel.accounts host of
                Just account ->
                    ( { model | targetHost = host, viewedUserId = userId, status = Fetching, rowEdits = Dict.empty }
                    , EventSyncSources.getEventSyncSources accountsPanelModel ( Just account.userId, host ) userId
                        |> Task.attempt GotFetchResult
                    , ( Nothing, Nothing )
                    )

                Nothing ->
                    ( { model | targetHost = host, viewedUserId = userId, status = FetchFailed "You're not signed in on that server.", rowEdits = Dict.empty }
                    , Cmd.none
                    , ( Nothing, Nothing )
                    )

        GotFetchResult (Ok ( maybeAccountsPanelMsg, response )) ->
            ( { model | status = Fetched, sources = response.sources }, Cmd.none, ( maybeAccountsPanelMsg, Nothing ) )

        GotFetchResult (Err err) ->
            ( { model | status = FetchFailed (AccountsPanel.grpcErrorToString err) }, Cmd.none, ( Nothing, Nothing ) )

        RowUrlChanged source url ->
            let
                edit =
                    rowEditFor source model
            in
            ( { model | rowEdits = Dict.insert source.id { edit | pendingUrl = url } model.rowEdits }, Cmd.none, ( Nothing, Nothing ) )

        RowIntervalChanged source seconds ->
            let
                edit =
                    rowEditFor source model
            in
            ( { model | rowEdits = Dict.insert source.id { edit | pendingIntervalSeconds = seconds } model.rowEdits }, Cmd.none, ( Nothing, Nothing ) )

        RowSaveClicked source ->
            let
                edit =
                    rowEditFor source model

                updated =
                    { source
                        | configuration = Just (Configuration.IcsSubscriptionUrl edit.pendingUrl)
                        , syncIntervalSeconds = Conversions.int64FromInt edit.pendingIntervalSeconds
                    }
            in
            ( { model | rowEdits = Dict.insert source.id { edit | status = Submitting } model.rowEdits }
            , performForOwner accountsPanelModel model (\accountServer -> EventSyncSources.updateEventSyncSource accountsPanelModel accountServer updated)
                |> Task.attempt (GotRowSaveResult source.id)
            , ( Nothing, Nothing )
            )

        RowRefreshClicked source ->
            ( { model | rowEdits = Dict.insert source.id { pendingUrl = icsUrl source, pendingIntervalSeconds = Conversions.int64ToInt source.syncIntervalSeconds, status = Submitting } model.rowEdits }
            , performForOwner accountsPanelModel model (\accountServer -> EventSyncSources.updateEventSyncSource accountsPanelModel accountServer source)
                |> Task.attempt (GotRowSaveResult source.id)
            , ( Nothing, Nothing )
            )

        GotRowSaveResult id (Ok ( maybeAccountsPanelMsg, updated )) ->
            ( { model | sources = replaceSource updated model.sources, rowEdits = Dict.remove id model.rowEdits }
            , Cmd.none
            , ( maybeAccountsPanelMsg, Nothing )
            )

        GotRowSaveResult id (Err err) ->
            ( { model | rowEdits = Dict.update id (Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })) model.rowEdits }
            , Cmd.none
            , ( Nothing, Nothing )
            )

        AddUrlChanged url ->
            ( { model | addForm = setField (\f -> { f | url = url }) model.addForm }, Cmd.none, ( Nothing, Nothing ) )

        AddIntervalChanged seconds ->
            ( { model | addForm = setField (\f -> { f | intervalSeconds = seconds }) model.addForm }, Cmd.none, ( Nothing, Nothing ) )

        AddClicked ->
            let
                newSource =
                    { defaultEventSyncSource
                        | configuration = Just (Configuration.IcsSubscriptionUrl model.addForm.url)
                        , syncIntervalSeconds = Conversions.int64FromInt model.addForm.intervalSeconds
                    }
            in
            ( { model | addForm = setField (\f -> { f | status = Submitting }) model.addForm }
            , performForOwner accountsPanelModel model (\accountServer -> EventSyncSources.createEventSyncSource accountsPanelModel accountServer newSource)
                |> Task.attempt GotAddResult
            , ( Nothing, Nothing )
            )

        GotAddResult (Ok ( maybeAccountsPanelMsg, created )) ->
            ( { model | sources = model.sources ++ [ created ], addForm = defaultAddForm }, Cmd.none, ( maybeAccountsPanelMsg, Nothing ) )

        GotAddResult (Err err) ->
            ( { model | addForm = setField (\f -> { f | status = SubmitFailed (AccountsPanel.grpcErrorToString err) }) model.addForm }, Cmd.none, ( Nothing, Nothing ) )

        DeleteClicked source deleteSyncedEvents ->
            ( model, Cmd.none, ( Nothing, Just ( source, deleteSyncedEvents ) ) )

        DeleteConfirmed source deleteSyncedEvents ->
            ( { model | deletingIds = Set.insert source.id model.deletingIds }
            , performForOwner accountsPanelModel model (\accountServer -> EventSyncSources.deleteEventSyncSource accountsPanelModel accountServer source deleteSyncedEvents)
                |> Task.attempt (GotDeleteResult source.id)
            , ( Nothing, Nothing )
            )

        GotDeleteResult id (Ok ( maybeAccountsPanelMsg, _ )) ->
            ( { model | deletingIds = Set.remove id model.deletingIds, sources = List.filter (\s -> s.id /= id) model.sources }
            , Cmd.none
            , ( maybeAccountsPanelMsg, Nothing )
            )

        GotDeleteResult id (Err err) ->
            ( { model | deletingIds = Set.remove id model.deletingIds }
            , Cmd.none
            , ( Nothing, Nothing )
            )
                |> logDeleteError err


{-| `performForOwner`'s failure mode (not signed in on `model.targetHost`
anymore) has no dedicated `SubmitFailed` slot to land in from here, so it's
folded into a `Grpc.NetworkError` for the caller's own `Err` branch to
render via `AccountsPanel.grpcErrorToString`, same as any other failed RPC.
-}
performForOwner :
    AccountsPanel.Model
    -> Model
    -> (AccountsPanel.MaybeAccountServer -> Task.Task Grpc.Error a)
    -> Task.Task Grpc.Error a
performForOwner accountsPanelModel model req =
    case AccountsPanel.enabledAccountForServer accountsPanelModel.accounts model.targetHost of
        Just account ->
            req ( Just account.userId, model.targetHost )

        Nothing ->
            Task.fail Grpc.NetworkError


{-| No-op placeholder so `GotDeleteResult`'s `Err` branch above can still
name `err` for a future error slot without an unused-variable warning today
-- delete failures are rare enough (and the row's already gone from view)
that surfacing them isn't worth a dedicated status field yet.
-}
logDeleteError : Grpc.Error -> a -> a
logDeleteError _ result =
    result


setField : (a -> a) -> a -> a
setField fn value =
    fn value


replaceSource : EventSyncSource -> List EventSyncSource -> List EventSyncSource
replaceSource updated sources =
    sources
        |> List.map
            (\s ->
                if s.id == updated.id then
                    updated

                else
                    s
            )


{-| The in-progress edit for `source`'s row -- an existing one from
`model.rowEdits` if the user's touched it, otherwise a fresh, clean one
derived straight from `source`'s own current values (so a first keystroke in
either field has something correct to diff against/build on).
-}
rowEditFor : EventSyncSource -> Model -> RowEdit
rowEditFor source model =
    Dict.get source.id model.rowEdits
        |> Maybe.withDefault { pendingUrl = icsUrl source, pendingIntervalSeconds = Conversions.int64ToInt source.syncIntervalSeconds, status = Idle }


icsUrl : EventSyncSource -> String
icsUrl source =
    case source.configuration of
        Just (Configuration.IcsSubscriptionUrl url) ->
            url

        Nothing ->
            ""


isDirty : EventSyncSource -> RowEdit -> Bool
isDirty source edit =
    edit.pendingUrl /= icsUrl source || edit.pendingIntervalSeconds /= Conversions.int64ToInt source.syncIntervalSeconds


{-| Labels the row's "delete along with its events" button with exactly what
it'll take with it, so this doubles as the only warning the user gets before
those rows are gone for good. Also used (via `syncedCountsLabel`) in `UI`'s
confirmation dialog for the same source. The row's other, plain "Delete"
button (see `rowView`) leaves those events/instances alone -- see
`UI.deleteConfirmationModal`'s own message for that case.
-}
deleteButtonLabel : EventSyncSource -> String
deleteButtonLabel source =
    "Delete along with " ++ syncedCountsLabel source


{-| "N events" alone when every event has exactly one instance (the common
non-recurring case, where naming both is redundant) -- otherwise "N events
and M instances".
-}
syncedCountsLabel : EventSyncSource -> String
syncedCountsLabel source =
    let
        eventCount =
            Conversions.int64ToInt source.eventCount

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



-- VIEW


{-| `canManage` is self-or-Admin (owner may always manage their own; an
Admin may manage anyone's) -- gates the whole section's edit/delete
affordances (a caller with neither shouldn't even see this section, but
`view` doesn't assume that's already been checked). `canAdd` is
self-only (an Admin still can't create a source _for_ someone else, see
`create_event_sync_source.rs`) -- gates just the add row.
-}
view : BrowserTimeZone.BrowserTimeZone -> { canManage : Bool, canAdd : Bool } -> Model -> Html Msg
view browserTimeZone { canManage, canAdd } model =
    if not canManage then
        text ""

    else
        div [ class "event-sync-sources-section" ]
            ([ h2 [ class "section-title" ] [ text "Event Sync Sources" ]
             , div [ class "event-sync-sources-list" ] (contentView browserTimeZone model)
             ]
                ++ (if canAdd then
                        [ addRowView model.targetHost model.addForm ]

                    else
                        []
                   )
            )


contentView : BrowserTimeZone.BrowserTimeZone -> Model -> List (Html Msg)
contentView browserTimeZone model =
    if not (List.isEmpty model.sources) then
        List.map (rowView browserTimeZone model) model.sources

    else
        case model.status of
            NotFetched ->
                []

            Fetching ->
                [ div [ class "event-sync-sources-message" ] [ text "Loading…" ] ]

            FetchFailed err ->
                [ div [ class "event-sync-sources-message" ] [ text err ] ]

            Fetched ->
                [ div [ class "event-sync-sources-message" ] [ text "No event sync sources yet." ] ]


rowView : BrowserTimeZone.BrowserTimeZone -> Model -> EventSyncSource -> Html Msg
rowView browserTimeZone model source =
    let
        edit =
            rowEditFor source model

        dirty =
            isDirty source edit

        submitting =
            edit.status == Submitting

        deleting =
            Set.member source.id model.deletingIds

        lastSyncedText =
            case source.lastSyncedAt of
                Just ts ->
                    BrowserTimeZone.formatDateTime browserTimeZone (Conversions.timestampToPosix ts)

                Nothing ->
                    "Never"
    in
    div [ classes [ "event-sync-source-row", hostnameToCSSClass model.targetHost, "border-left-thick-color-primary" ] ]
        [ input
            [ class "event-sync-source-url"
            , type_ "text"
            , value edit.pendingUrl
            , placeholder "iCal subscription URL"
            , disabled (submitting || deleting)
            , onInput (RowUrlChanged source)
            ]
            []
        , intervalSelect (RowIntervalChanged source) edit.pendingIntervalSeconds (submitting || deleting)
        , div [ class "event-sync-source-actions" ]
            [ span [ class "event-sync-source-last-synced" ] [ text ("Last synced: " ++ lastSyncedText) ]
            , if dirty then
                button
                    [ classes [ "event-sync-source-save", "background-color-nav" ], onClick (RowSaveClicked source), disabled submitting ]
                    [ text
                        (if submitting then
                            "Saving…"

                         else
                            "Save"
                        )
                    ]

              else
                button
                    [ classes [ "event-sync-source-refresh", "background-color-primary" ], onClick (RowRefreshClicked source), disabled submitting ]
                    [ text
                        (if submitting then
                            "Refreshing…"

                         else
                            "Refresh"
                        )
                    ]
            , button
                [ class "event-sync-source-delete-plain", onClick (DeleteClicked source False), disabled deleting ]
                [ text
                    (if deleting then
                        "Deleting…"

                     else
                        "Delete"
                    )
                ]
            , button
                [ class "event-sync-source-delete", onClick (DeleteClicked source True), disabled deleting ]
                [ text
                    (if deleting then
                        "Deleting…"

                     else
                        deleteButtonLabel source
                    )
                ]
            ]
        , case edit.status of
            SubmitFailed err ->
                div [ class "event-sync-source-error" ] [ text err ]

            _ ->
                text ""
        ]


addRowView : String -> AddForm -> Html Msg
addRowView targetHost addForm =
    div [ classes [ "event-sync-source-row", "event-sync-source-add-row", hostnameToCSSClass targetHost, "border-left-thick-color-primary" ] ]
        [ input
            [ class "event-sync-source-url"
            , type_ "text"
            , value addForm.url
            , placeholder "iCal subscription URL"
            , disabled (addForm.status == Submitting)
            , onInput AddUrlChanged
            ]
            []
        , intervalSelect AddIntervalChanged addForm.intervalSeconds (addForm.status == Submitting)
        , button
            [ class "event-sync-source-add"
            , onClick AddClicked
            , disabled (addForm.status == Submitting || String.isEmpty (String.trim addForm.url))
            ]
            [ text
                (if addForm.status == Submitting then
                    "Adding…"

                 else
                    "+ Add"
                )
            ]
        , case addForm.status of
            SubmitFailed err ->
                div [ class "event-sync-source-error" ] [ text err ]

            _ ->
                text ""
        ]


intervalSelect : (Int -> Msg) -> Int -> Bool -> Html Msg
intervalSelect onChange selectedSeconds disabledAttr =
    select
        [ class "event-sync-source-interval"
        , disabled disabledAttr
        , onInput (\s -> onChange (String.toInt s |> Maybe.withDefault selectedSeconds))
        ]
        (EventSyncSources.intervalOptions
            |> List.map
                (\( seconds, label ) ->
                    option [ value (String.fromInt seconds), selected (seconds == selectedSeconds) ] [ text label ]
                )
        )
