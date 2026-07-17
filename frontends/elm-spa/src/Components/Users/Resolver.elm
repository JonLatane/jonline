module Components.Users.Resolver exposing
    ( Lookup(..)
    , Model
    , Msg(..)
    , Status(..)
    , fetchIfReady
    , fromShared
    , init
    , refetch
    , subscriptions
    , update
    )

{-| Fetches a `Proto.Jonline.User` from a specific (possibly not-yet-connected)
server, by id or by username -- the common guts `Components.Pages.UserProfilePage`
(which additionally lets the viewer edit the resolved profile once loaded) and
`Pages.Username_.Posts` (which just needs the resolved id, to filter
`Components.Pages.PostsPage`'s feed to one user's own posts) both need.

The fetch only ever runs once `targetHost` is a server the viewer is already
connected to (see `fetchTask`) -- this module has no connect-to-server UI of
its own (that's `Shared.Components.ServerDependentView`'s job, driven by
`UserProfilePage`'s own `connectStatus`); until then (or after a failure),
`Poll`/an `AccountsPanelMsg` passing through `SharedMsg` just keeps retrying,
same event-driven-plus-slow-poll approach as `Components.Pages.PostsPage`.
-}

import Effect exposing (Effect)
import Grpc
import Components.Users as Users
import Proto.Jonline
import Shared
import Shared.AccountsPanel as AccountsPanel
import Task
import Time


{-| Which `GetUsersRequest` field to search by -- an id or a username.
-}
type Lookup
    = ById String
    | ByUsername String


type Status
    = Loading
    | Loaded Proto.Jonline.User
    | Failed


type alias Model =
    { targetHost : String
    , lookup : Lookup
    , status : Status
    , fetchStarted : Bool
    }


init : Shared.Model -> String -> Lookup -> ( Model, Effect Msg )
init shared targetHost lookup =
    fetchIfReady shared { targetHost = targetHost, lookup = lookup, status = Loading, fetchStarted = False }


{-| The `GetUsers` fetch task for `model.lookup`/`model.targetHost`, if that
host is currently a known, connected server -- shared by `fetchIfReady` (only
kicked off once) and `refetch` (kicked off unconditionally, e.g. after a Real
Name/bio/permissions save succeeds).
-}
fetchTask : Shared.Model -> Model -> Maybe (Task.Task Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetUsersResponse ))
fetchTask shared model =
    AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost
        |> Maybe.map
            (\_ ->
                let
                    maybeAccountServer =
                        ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost |> Maybe.map .userId
                        , model.targetHost
                        )
                in
                case model.lookup of
                    ById userId ->
                        Users.fetchUserById shared.accountsPanel maybeAccountServer userId

                    ByUsername username ->
                        Users.fetchUserByUsername shared.accountsPanel maybeAccountServer username
            )


{-| Kicks off the actual `GetUsers` fetch the first time `targetHost` is a
known, connected server -- also called after `ConnectClicked` succeeds
(`UserProfilePage`'s `GotConnectResult`), since `fetchStarted` is still
`False` at that point (the fetch could never have started before the target
server was connected).
-}
fetchIfReady : Shared.Model -> Model -> ( Model, Effect Msg )
fetchIfReady shared model =
    if model.fetchStarted then
        ( model, Effect.none )

    else
        case fetchTask shared model of
            Just fetch ->
                ( { model | fetchStarted = True }
                , fetch |> Task.attempt GotUser |> Effect.fromCmd
                )

            Nothing ->
                ( model, Effect.none )


{-| Re-fetches the user unconditionally (unlike `fetchIfReady`, not gated on
`fetchStarted`, which is already `True` by the time this is ever called) --
e.g. called by `UserProfilePage` once its shared Markdown panel reports a
successful bio save.
-}
refetch : Shared.Model -> Model -> ( Model, Effect Msg )
refetch shared model =
    case fetchTask shared model of
        Just fetch ->
            ( model, fetch |> Task.attempt GotUser |> Effect.fromCmd )

        Nothing ->
            ( model, Effect.none )



-- UPDATE


type Msg
    = GotUser (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetUsersResponse ))
    | Poll
    | SharedMsg Shared.Msg


{-| Lets a caller forward a `Shared.Msg` that didn't originate from this
module (see e.g. `Main.notifyPageOfSharedMsg`) into `update`'s `SharedMsg`
branch.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        GotUser (Ok ( maybeAccountsPanelMsg, response )) ->
            let
                accountEffect =
                    maybeAccountsPanelMsg
                        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
                        |> Maybe.withDefault Effect.none

                newStatus =
                    response.users
                        |> List.head
                        |> Maybe.map Loaded
                        |> Maybe.withDefault Failed
            in
            ( { model | status = newStatus }, accountEffect )

        GotUser (Err _) ->
            ( { model | status = Failed }, Effect.none )

        Poll ->
            fetchIfReady shared model

        SharedMsg subMsg ->
            let
                ( fetchedModel, fetchEffect ) =
                    case subMsg of
                        Shared.AccountsPanelMsg _ ->
                            fetchIfReady shared model

                        _ ->
                            ( model, Effect.none )
            in
            ( fetchedModel, Effect.batch [ Effect.fromShared subMsg, fetchEffect ] )


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.fetchStarted then
        Sub.none

    else
        Time.every 30000 (\_ -> Poll)
