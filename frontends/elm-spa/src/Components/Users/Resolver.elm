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

{-| Fetches a `Proto.Rellm.User` from a specific (possibly not-yet-connected)
server, by id or by username -- the common guts `Components.Pages.UserProfilePage`
(which additionally lets the viewer edit the resolved profile once loaded) and
`Pages.UsernameOrCustomTab_.Posts` (which just needs the resolved id, to filter
`Components.Pages.PostsPage`'s feed to one user's own posts) both need.

The fetch only ever runs once `targetHost` is a server the viewer is already
connected to (see `fetchTask`) -- this module has no connect-to-server UI of
its own (that's `Shared.Components.ServerDependentView`'s job, driven by
`UserProfilePage`'s own `connectStatus`); until then (or after a failure),
`Poll`/an `AccountsPanelMsg` passing through `SharedMsg` just keeps retrying,
same event-driven-plus-slow-poll approach as `Components.Pages.PostsPage`.

What `GetUsers` returns depends on who's asking: the self-or-Admin-only parts of a `User`
(sync sources/destinations, contact methods, subscriptions, ...) are only there when the account
acting on `targetHost` is that user or an Admin. So the fetch is re-run whenever that acting account
changes (logging in or out of the server, or enabling/disabling an account on it -- see
`actingAccountId`), rather than once for the life of the page; a response that comes back for an
account that's no longer the acting one is dropped. The same "refetch when the server's acting
account changes" rule `Components.Pages.PostsPage.fetchNewFeeds` applies to feeds.

-}

import Components.Users as Users
import Effect exposing (Effect)
import Grpc
import Proto.Rellm
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.AccountsPanel.RellmAccounts as RellmAccounts
import Shared.AccountsPanel.RellmServers as RellmServers
import Task
import Time


type alias Model =
    { targetHost : String
    , lookup : Lookup
    , status : Status
    , fetchStarted : Bool

    -- The account (`Nothing` = anonymous) the most recent fetch was made as -- see `actingAccountId`.
    , fetchedAs : Maybe String
    }


type Msg
    = GotUser (Maybe String) (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Rellm.GetUsersResponse ))
    | Poll
    | SharedMsg Shared.Msg


{-| Which `GetUsersRequest` field to search by -- an id or a username.
-}
type Lookup
    = ById String
    | ByUsername String


type Status
    = Loading
    | Loaded Proto.Rellm.User
    | Failed


init : Shared.Model -> String -> Lookup -> ( Model, Effect Msg )
init shared targetHost lookup =
    fetchIfReady shared { targetHost = targetHost, lookup = lookup, status = Loading, fetchStarted = False, fetchedAs = Nothing }


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.fetchStarted then
        Sub.none

    else
        Time.every 30000 (\_ -> Poll)


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        GotUser fetchedAs (Ok ( maybeAccountsPanelMsg, response )) ->
            let
                accountEffect : Effect Msg
                accountEffect =
                    maybeAccountsPanelMsg
                        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
                        |> Maybe.withDefault Effect.none

            in
            if fetchedAs == model.fetchedAs then
                ( { model
                    | status =
                        response.users
                            |> List.head
                            |> Maybe.map Loaded
                            |> Maybe.withDefault Failed
                  }
                , accountEffect
                )

            else
                -- Made as an account that's no longer the acting one: what it saw isn't what the
                -- current account would, so drop it (a refetch as the current account is already
                -- on its way). A refreshed token it carries is still worth keeping.
                ( model, accountEffect )

        GotUser fetchedAs (Err _) ->
            if fetchedAs == model.fetchedAs then
                ( { model | status = Failed }, Effect.none )

            else
                ( model, Effect.none )

        Poll ->
            fetchIfReady shared model

        SharedMsg subMsg ->
            let
                ( fetchedModel, fetchEffect ) =
                    case subMsg of
                        Shared.AccountsPanelMsg _ ->
                            if not model.fetchStarted then
                                fetchIfReady shared model

                            else if actingAccountId shared model /= model.fetchedAs then
                                -- Logged in/out of `targetHost`, or enabled/disabled an account on
                                -- it: the `User` held was fetched as someone else.
                                refetch shared model

                            else
                                ( model, Effect.none )

                        _ ->
                            ( model, Effect.none )
            in
            ( fetchedModel, Effect.batch [ Effect.fromShared subMsg, fetchEffect ] )


{-| The id of the account currently acting on `model.targetHost` (the enabled one -- the same one
`fetchTask` makes its request as), `Nothing` when none is, i.e. the viewer is anonymous there.
-}
actingAccountId : Shared.Model -> Model -> Maybe String
actingAccountId shared model =
    RellmAccounts.enabledRellmAccountForServer shared.accounts.accounts model.targetHost
        |> Maybe.map .userId


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
                let
                    viewer : Maybe String
                    viewer =
                        actingAccountId shared model
                in
                ( { model | fetchStarted = True, fetchedAs = viewer }
                , fetch |> Task.attempt (GotUser viewer) |> Effect.fromCmd
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
            let
                viewer : Maybe String
                viewer =
                    actingAccountId shared model
            in
            ( { model | fetchedAs = viewer }, fetch |> Task.attempt (GotUser viewer) |> Effect.fromCmd )

        Nothing ->
            ( model, Effect.none )


{-| The `GetUsers` fetch task for `model.lookup`/`model.targetHost`, if that
host is currently a known, connected server -- shared by `fetchIfReady` (only
kicked off once) and `refetch` (kicked off unconditionally, e.g. after a Real
Name/bio/permissions save succeeds).
-}
fetchTask : Shared.Model -> Model -> Maybe (Task.Task Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Rellm.GetUsersResponse ))
fetchTask shared model =
    RellmServers.knownConnectedRellmServer shared.accounts.servers model.targetHost
        |> Maybe.map
            (\_ ->
                let
                    maybeAccountServer : AccountsPanel.MaybeAccountServer
                    maybeAccountServer =
                        ( actingAccountId shared model, model.targetHost )
                in
                case model.lookup of
                    ById userId ->
                        Users.fetchUserById shared.accounts maybeAccountServer userId

                    ByUsername username ->
                        Users.fetchUserByUsername shared.accounts maybeAccountServer username
            )


{-| Lets a caller forward a `Shared.Msg` that didn't originate from this
module (see e.g. `Main.notifyPageOfSharedMsg`) into `update`'s `SharedMsg`
branch.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg
