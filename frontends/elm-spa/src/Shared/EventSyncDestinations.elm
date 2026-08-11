module Shared.EventSyncDestinations exposing
    ( Fetch(..)
    , Model
    , Msg(..)
    , destinationsFor
    , destinationsForCurrentUser
    , init
    , statusFor
    , update
    )

{-| A small app-wide cache of the current user's `EventSyncDestination`s
(linked Facebook Pages, see `events.proto`), keyed by hostname then userId --
sibling to `Shared.AccountsPanel` (same "own `Model`/`Msg`/`update`, take
`AccountsPanel.Model` in for auth, forward any `Maybe AccountsPanel.Msg` back
up" shape `Shared.StarredPanel` already uses) rather than a field on
`AccountsPanel.Account` -- this is about which `EventSyncDestination`s exist,
not about who's signed in.

Read from `Components.Events.eventCard`/`Pages.Event.EventId_`'s shared
`eventSyncDestinationsView` (both need "does the viewer have any linked Pages
to push this EventInstance to") and from `Components.Pages.UserProfilePage`'s
"Event Sync Destinations" section (which used to fetch/hold this locally,
see that module's own history) -- both read via `destinationsForCurrentUser`/
`statusFor`, never construct a fetch themselves beyond dispatching
`EnsureFetchedForCurrentUser`/`FetchRequested`.

The actual RPC wrapper (`Components.EventSyncDestinations.getEventSyncDestinations`)
already existed before this module did -- this only adds a cache and a
policy ("who's eligible, when to (re)fetch") on top of it.
-}

import Components.Authors as Authors
import Components.EventSyncDestinations as EventSyncDestinationsRpc
import Dict exposing (Dict)
import Grpc
import Proto.Jonline exposing (EventSyncDestination, GetEventSyncDestinationsResponse)
import Proto.Jonline.Permission exposing (Permission(..))
import Shared.AccountsPanel as AccountsPanel
import Task


{-| One `(hostname, userId)` slot's fetch state -- generalizes
`Components.Pages.UserProfilePage`'s old `EventSyncDestinationFetchStatus`/
`destinations` pair (a status plus a separately-tracked list) into one
value, now that it's cached per-user rather than singleton-per-page.
-}
type Fetch
    = NotFetched
    | Fetching
    | FetchFailed String
    | Fetched (List EventSyncDestination)


{-| Keyed by userId.
-}
type alias UserDestinations =
    Dict String Fetch


{-| Keyed by hostname.
-}
type alias Model =
    Dict String UserDestinations


init : Model
init =
    Dict.empty


type Msg
    = FetchRequested String String
      -- Fetches for the current-on-that-host account only if it's both
      -- eligible (`SYNC_EVENTS_TO_FACEBOOK` or `ADMIN`) and not already
      -- `Fetching`/`Fetched` -- see `Components.Pages.UserProfilePage`/
      -- `Pages.Event.EventId_`'s own docs for where/why each dispatches
      -- this at its own "about to show sync UI" moment.
    | EnsureFetchedForCurrentUser String
    | GotFetchResult String String (Result Grpc.Error ( Maybe AccountsPanel.Msg, GetEventSyncDestinationsResponse ))


statusFor : Model -> String -> String -> Fetch
statusFor model hostname userId =
    Dict.get hostname model
        |> Maybe.andThen (Dict.get userId)
        |> Maybe.withDefault NotFetched


destinationsFor : Model -> String -> String -> List EventSyncDestination
destinationsFor model hostname userId =
    case statusFor model hostname userId of
        Fetched destinations ->
            destinations

        _ ->
            []


destinationsForCurrentUser : AccountsPanel.Model -> Model -> String -> List EventSyncDestination
destinationsForCurrentUser accountsModel model hostname =
    case AccountsPanel.enabledAccountForServer accountsModel.accounts hostname of
        Just account ->
            destinationsFor model hostname account.userId

        Nothing ->
            []


setStatus : String -> String -> Fetch -> Model -> Model
setStatus hostname userId status model =
    let
        userDestinations =
            Dict.get hostname model |> Maybe.withDefault Dict.empty
    in
    Dict.insert hostname (Dict.insert userId status userDestinations) model


eligibleForSync : AccountsPanel.Account -> Bool
eligibleForSync account =
    Authors.hasPermission SYNCEVENTSTOFACEBOOK account || Authors.hasPermission ADMIN account


update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, Maybe AccountsPanel.Msg )
update accountsModel msg model =
    case msg of
        FetchRequested hostname userId ->
            case AccountsPanel.enabledAccountForServer accountsModel.accounts hostname of
                Just account ->
                    ( setStatus hostname userId Fetching model
                    , EventSyncDestinationsRpc.getEventSyncDestinations accountsModel ( Just account.userId, hostname ) userId
                        |> Task.attempt (GotFetchResult hostname userId)
                    , Nothing
                    )

                Nothing ->
                    ( model, Cmd.none, Nothing )

        EnsureFetchedForCurrentUser hostname ->
            case AccountsPanel.enabledAccountForServer accountsModel.accounts hostname of
                Just account ->
                    let
                        alreadyHandled =
                            case statusFor model hostname account.userId of
                                Fetching ->
                                    True

                                Fetched _ ->
                                    True

                                _ ->
                                    False
                    in
                    if eligibleForSync account && not alreadyHandled then
                        update accountsModel (FetchRequested hostname account.userId) model

                    else
                        ( model, Cmd.none, Nothing )

                Nothing ->
                    ( model, Cmd.none, Nothing )

        GotFetchResult hostname userId result ->
            case result of
                Ok ( maybeAccountsPanelMsg, response ) ->
                    ( setStatus hostname userId (Fetched response.destinations) model, Cmd.none, maybeAccountsPanelMsg )

                Err err ->
                    ( setStatus hostname userId (FetchFailed (AccountsPanel.grpcErrorToString err)) model, Cmd.none, Nothing )
