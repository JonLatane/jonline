module Components.UserProfilePage exposing
    ( Lookup(..)
    , Model
    , Msg
    , fromShared
    , init
    , subscriptions
    , titleFor
    , update
    , view
    )

{-| The shared guts of a user profile page: fetching a `Proto.Jonline.User`
from a specific (possibly not-yet-connected) server, by id or by username, and
rendering it -- reused by both `Pages.User.UserId_` (`/user/:id[@host]`) and
`Pages.Username_` (`/:username[@host]`), which differ only in which `Lookup`
they parse out of their route and (for `Pages.Username_`) whether the username
is even routable at all (see `Components.Users.isReservedUsername`, checked by
the page itself before ever constructing this module's `Model`).

Mirrors `Pages.Post.PostId_`, generalized over the `Lookup` since (unlike
Posts, which are only ever looked up by id) a `User` can be fetched by either
id or username.
-}

import Components.Markdown as Markdown
import Components.Users as Users
import Components.ServerDependentView as ServerDependentView
import Dict exposing (Dict)
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, a, div, h1, h2, p, span, text)
import Html.Attributes exposing (class, href, title)
import Proto.Jonline exposing (FederatedAccount, User)
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.MaybeAccountRequest as MaybeAccountRequest
import Task
import Time
import UI
import UI.Classes exposing (classes)


{-| Which `GetUsersRequest` field to search by -- an id (`Pages.User.UserId_`)
or a username (`Pages.Username_`).
-}
type Lookup
    = ById String
    | ByUsername String


type Status
    = LoadingUser
    | UserLoaded User
    | UserFailed


{-| The fetch state of one entry in a loaded `User.federatedProfiles`, keyed
by `federatedKey` -- mirrors `Shared.StarredPostsPanel.PostFetchStatus`, minus
that module's `ServerUnavailable`/poll-retry distinction, since an unreachable
federated server here just reads the same as any other failure (there's no
polling loop kicking these fetches off again).
-}
type FederatedProfileStatus
    = FederatedProfileLoading
    | FederatedProfileLoaded User
    | FederatedProfileFailed


type alias Model =
    { targetHost : String
    , lookup : Lookup
    , status : Status
    , connectStatus : ServerDependentView.ConnectStatus
    , fetchStarted : Bool
    , pageIsSecure : Bool
    , federatedProfiles : Dict String FederatedProfileStatus
    }


{-| `pageIsSecure` is `Shared.AccountsPanel.isSecure req` from the calling
page's own `Request` -- needed for `ConnectClicked` (see `AccountsPanel.connectToServer`),
but not otherwise derivable from `Shared.Model` alone.
-}
init : Shared.Model -> Bool -> String -> Lookup -> ( Model, Effect Msg )
init shared pageIsSecure targetHost lookup =
    fetchIfReady shared
        { targetHost = targetHost
        , lookup = lookup
        , status = LoadingUser
        , connectStatus = ServerDependentView.NotConnected
        , fetchStarted = False
        , pageIsSecure = pageIsSecure
        , federatedProfiles = Dict.empty
        }


{-| Kicks off the actual `GetUsers` fetch the first time `targetHost` is a
known, connected server -- same event-driven approach as
`Pages.Post.PostId_.fetchIfReady` (see its docs for the full rationale).
-}
fetchIfReady : Shared.Model -> Model -> ( Model, Effect Msg )
fetchIfReady shared model =
    if model.fetchStarted then
        ( model, Effect.none )

    else
        case AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost of
            Just server ->
                let
                    maybeAccount =
                        AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost

                    fetch =
                        case model.lookup of
                            ById userId ->
                                Users.fetchUserById server maybeAccount userId

                            ByUsername username ->
                                Users.fetchUserByUsername server maybeAccount username
                in
                ( { model | fetchStarted = True }
                , fetch |> Task.attempt GotUser |> Effect.fromCmd
                )

            Nothing ->
                ( model, Effect.none )



-- UPDATE


type Msg
    = GotUser (Result Grpc.Error ( Maybe AccountsPanel.Account, Proto.Jonline.GetUsersResponse ))
    | ConnectClicked
    | GotConnectResult (Result Grpc.Error AccountsPanel.Server)
    | Poll
    | SharedMsg Shared.Msg
    | GotFederatedServer FederatedAccount (Result Grpc.Error AccountsPanel.Server)
    | GotFederatedUser String (Result Grpc.Error ( Maybe AccountsPanel.Account, Proto.Jonline.GetUsersResponse ))


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
into `update`'s `SharedMsg` branch -- see `Pages.Post.PostId_.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        GotUser (Ok ( maybeAccount, response )) ->
            let
                accountEffect =
                    maybeAccount
                        |> Maybe.map (AccountsPanel.AccountRefreshed >> Shared.AccountsPanelMsg >> Effect.fromShared)
                        |> Maybe.withDefault Effect.none

                newStatus =
                    response.users
                        |> List.head
                        |> Maybe.map UserLoaded
                        |> Maybe.withDefault UserFailed
            in
            case newStatus of
                UserLoaded user ->
                    let
                        ( federatedModel, federatedEffect ) =
                            kickOffFederatedFetches shared user { model | status = newStatus }
                    in
                    ( federatedModel, Effect.batch [ accountEffect, federatedEffect ] )

                _ ->
                    ( { model | status = newStatus }, accountEffect )

        GotUser (Err _) ->
            ( { model | status = UserFailed }, Effect.none )

        ConnectClicked ->
            ( { model | connectStatus = ServerDependentView.Connecting }
            , AccountsPanel.connectToServer model.pageIsSecure model.targetHost
                |> Task.attempt GotConnectResult
                |> Effect.fromCmd
            )

        GotConnectResult (Ok server) ->
            let
                ( newModel, fetchEffect ) =
                    fetchIfReady shared { model | connectStatus = ServerDependentView.NotConnected }
            in
            ( newModel
            , Effect.batch
                [ Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.ServerConnected server))
                , fetchEffect
                ]
            )

        GotConnectResult (Err err) ->
            ( { model | connectStatus = ServerDependentView.ConnectFailed (AccountsPanel.grpcErrorToString err) }
            , Effect.none
            )

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

        GotFederatedServer account (Ok server) ->
            -- Registers the federated user's server into `shared.accountsPanel.servers`
            -- (same as `ConnectClicked`'s own `GotConnectResult` does for
            -- `targetHost`) -- needed so `UI.EmittedStylesheet` actually emits
            -- this host's `background-color-primary` rule for `federatedProfileLink`.
            ( model
            , Effect.batch
                [ Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.ServerConnected server))
                , fetchFederatedUserEffect shared server account
                ]
            )

        GotFederatedServer account (Err _) ->
            ( { model | federatedProfiles = Dict.insert (federatedKey account) FederatedProfileFailed model.federatedProfiles }
            , Effect.none
            )

        GotFederatedUser key (Ok ( maybeAccount, response )) ->
            let
                accountEffect =
                    maybeAccount
                        |> Maybe.map (AccountsPanel.AccountRefreshed >> Shared.AccountsPanelMsg >> Effect.fromShared)
                        |> Maybe.withDefault Effect.none

                newStatus =
                    response.users
                        |> List.head
                        |> Maybe.map FederatedProfileLoaded
                        |> Maybe.withDefault FederatedProfileFailed
            in
            ( { model | federatedProfiles = Dict.insert key newStatus model.federatedProfiles }, accountEffect )

        GotFederatedUser key (Err _) ->
            ( { model | federatedProfiles = Dict.insert key FederatedProfileFailed model.federatedProfiles }
            , Effect.none
            )


{-| Kicks off a fetch for every entry in `user.federatedProfiles` that isn't
already loading/loaded/failed -- grouping isn't needed the way
`Shared.StarredPostsPanel.kickOffFetches` groups by host, since a `User`
rarely lists more than a couple of federated accounts, and each is on its own
(likely not-yet-connected) server anyway.
-}
kickOffFederatedFetches : Shared.Model -> User -> Model -> ( Model, Effect Msg )
kickOffFederatedFetches shared user model =
    let
        pending =
            user.federatedProfiles
                |> List.filter (\account -> not (Dict.member (federatedKey account) model.federatedProfiles))

        ( newFederatedProfiles, effects ) =
            List.foldl (fetchFederated shared model.pageIsSecure) ( model.federatedProfiles, [] ) pending
    in
    ( { model | federatedProfiles = newFederatedProfiles }, Effect.batch effects )


{-| Either fetches `account`'s `User` directly (its server is already known --
see `AccountsPanel.serverForHost`) or first connects to that server anonymously
(mirrors `ConnectClicked`/`GotConnectResult` above), deferring the actual
`User` fetch to `GotFederatedServer`'s success branch.
-}
fetchFederated :
    Shared.Model
    -> Bool
    -> FederatedAccount
    -> ( Dict String FederatedProfileStatus, List (Effect Msg) )
    -> ( Dict String FederatedProfileStatus, List (Effect Msg) )
fetchFederated shared pageIsSecure account ( statuses, effects ) =
    let
        newStatuses =
            Dict.insert (federatedKey account) FederatedProfileLoading statuses
    in
    case AccountsPanel.serverForHost shared.accountsPanel.servers account.host of
        Just server ->
            ( newStatuses, effects ++ [ fetchFederatedUserEffect shared server account ] )

        Nothing ->
            ( newStatuses
            , effects
                ++ [ AccountsPanel.connectToServer pageIsSecure account.host
                        |> Task.attempt (GotFederatedServer account)
                        |> Effect.fromCmd
                   ]
            )


fetchFederatedUserEffect : Shared.Model -> AccountsPanel.Server -> FederatedAccount -> Effect Msg
fetchFederatedUserEffect shared server account =
    Users.fetchUserById server (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts account.host) account.userId
        |> Task.attempt (GotFederatedUser (federatedKey account))
        |> Effect.fromCmd


{-| The `model.federatedProfiles` key for one `User.federatedProfiles` entry --
mirrors `Shared.StarredPostsPanel.starKey`.
-}
federatedKey : FederatedAccount -> String
federatedKey account =
    account.userId ++ "@" ++ account.host


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.fetchStarted then
        Sub.none

    else
        Time.every 30000 (\_ -> Poll)



-- VIEW


titleFor : Model -> String
titleFor model =
    case model.status of
        UserLoaded user ->
            Users.displayName user

        _ ->
            "Profile"


view : Shared.Model -> Model -> Html Msg
view shared model =
    ServerDependentView.view
        { hostname = model.targetHost
        , servers = shared.accountsPanel.servers
        , accounts = shared.accountsPanel.accounts
        , connectStatus = model.connectStatus
        , onConnectClicked = ConnectClicked
        }
        (\server maybeAccount ->
            case model.status of
                LoadingUser ->
                    p [ class "profile-loading" ] [ text "Loading…" ]

                UserFailed ->
                    p [ class "profile-error" ] [ text "Couldn't load this profile." ]

                UserLoaded user ->
                    profileDetail shared model server maybeAccount user
        )


profileDetail : Shared.Model -> Model -> AccountsPanel.Server -> Maybe AccountsPanel.Account -> User -> Html Msg
profileDetail shared model server maybeAccount user =
    div [ classes [ "profile-detail", server.frontendHost, "border-color-primary-anchor-50" ] ]
        [ div [ class "profile-header" ]
            [ UI.imageOrInitial [ "profile-avatar" ] user.username (Users.avatarUrl server maybeAccount user)
            , div [ class "profile-header-names" ]
                [ h1 [ class "profile-username" ]
                    [ text user.username
                    , if Users.isAdminUser user then
                        span [ class "profile-admin-badge", title "Admin" ] [ text "🛡️ Admin" ]

                      else
                        text ""
                    ]
                , if String.isEmpty (String.trim user.realName) then
                    text ""

                  else
                    div [ class "profile-real-name" ] [ text user.realName ]
                ]
            ]
        , federatedProfilesSection shared model server user
        , div [ class "profile-meta" ]
            [ text
                (Users.visibilityText user.visibility
                    ++ " · "
                    ++ Users.moderationText user.moderation
                    ++ (user.createdAt
                            |> Maybe.map (\ts -> " · Joined " ++ Users.formatDate (MaybeAccountRequest.timestampToPosix ts))
                            |> Maybe.withDefault ""
                       )
                )
            ]
        , profileCounts user
        , if String.isEmpty (String.trim user.bio) then
            text ""

          else
            Markdown.view [ class "profile-bio" ] user.bio
        , permissionsSection user
        ]


profileCounts : User -> Html Msg
profileCounts user =
    let
        counts =
            [ ( "Followers", user.followerCount )
            , ( "Following", user.followingCount )
            , ( "Groups", user.groupCount )
            , ( "Posts", user.postCount )
            , ( "Responses", user.responseCount )
            , ( "Events", user.eventCount )
            ]
                |> List.filterMap (\( label, maybeCount) -> maybeCount |> Maybe.map (\c -> ( label, c )))
    in
    if List.isEmpty counts then
        text ""

    else
        div [ class "profile-counts" ]
            (counts
                |> List.map
                    (\( label, count ) ->
                        div [ class "profile-count" ]
                            [ div [ class "profile-count-value" ] [ text (String.fromInt count) ]
                            , div [ class "profile-count-label" ] [ text label ]
                            ]
                    )
            )


permissionsSection : User -> Html Msg
permissionsSection user =
    if List.isEmpty user.permissions then
        text ""

    else
        div [ class "profile-permissions" ]
            (h2 [ class "profile-section-title" ] [ text "Permissions" ]
                :: (user.permissions
                        |> List.map (\permission -> span [ class "profile-permission-badge" ] [ text (Users.permissionText permission) ])
                   )
            )


federatedProfilesSection : Shared.Model -> Model -> AccountsPanel.Server -> User -> Html Msg
federatedProfilesSection shared model server user =
    if List.isEmpty user.federatedProfiles then
        text ""

    else
        div [ class "profile-federated" ]
            (h2 [ class "profile-section-title" ] [ text "Federated Profiles" ]
                :: (user.federatedProfiles
                        |> List.map (federatedProfileLink shared model server user)
                   )
            )


{-| One federated profile's link/button -- always links out via
`Users.userIdHref` (the "still just a link" baseline behavior), but once its
`User` has actually loaded (see `kickOffFederatedFetches`), it's upgraded to
show that user's avatar, their username on that server, a `crossCheckBadge`,
and -- via `federatedServer`'s CSS class, see `UI.EmittedStylesheet` -- that
server's own colors.
-}
federatedProfileLink : Shared.Model -> Model -> AccountsPanel.Server -> User -> FederatedAccount -> Html Msg
federatedProfileLink shared model server user account =
    let
        maybeFederatedServer =
            AccountsPanel.serverForHost shared.accountsPanel.servers account.host

        colorClasses =
            case maybeFederatedServer of
                Just federatedServer ->
                    [ federatedServer.frontendHost, "background-color-primary" ]

                Nothing ->
                    []
    in
    a
        [ classes ("profile-federated-link" :: colorClasses)
        , href
            (Users.userIdHref shared.basePath
                shared.accountsPanel.mainFrontendHost
                account.host
                account.userId
            )
        ]
        (case ( maybeFederatedServer, Dict.get (federatedKey account) model.federatedProfiles ) of
            ( Just federatedServer, Just (FederatedProfileLoaded federatedUser) ) ->
                [ UI.imageOrInitial [ "profile-federated-avatar" ]
                    federatedUser.username
                    (Users.avatarUrl federatedServer
                        (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts account.host)
                        federatedUser
                    )
                , span [ class "profile-federated-username" ] [ text (federatedUser.username ++ "@" ++ account.host) ]
                , crossCheckBadge server user federatedUser
                ]

            _ ->
                [ text (account.userId ++ "@" ++ account.host) ]
        )


{-| ✅ if `federatedUser` (fetched from its own server) also lists `user`
back -- one of its own `federatedProfiles` names `server.frontendHost`/
`user.id` -- confirming the two profiles actually link to *each other*, not
just this one linking out. ⚠️ otherwise (e.g. still pending on the other
side, or never confirmed).
-}
crossCheckBadge : AccountsPanel.Server -> User -> User -> Html Msg
crossCheckBadge server user federatedUser =
    let
        reciprocated =
            List.any (\account -> account.host == server.frontendHost && account.userId == user.id)
                federatedUser.federatedProfiles
    in
    if reciprocated then
        span [ class "profile-federated-badge", title "Both profiles link to each other" ] [ text "✅" ]

    else
        span [ class "profile-federated-badge", title "This profile doesn't link back" ] [ text "⚠️" ]
