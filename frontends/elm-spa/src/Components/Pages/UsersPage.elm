module Components.Pages.UsersPage exposing
    ( Model
    , Msg
    , fromShared
    , init
    , subscriptions
    , update
    , view
    )

{-| The shared guts of a "list of users" page: fetching a `UserListingType`
listing of users and rendering them as `Components.Users.userCard`s -- reused
by `Pages.People` (which adds its own "People" heading and passes
`target = Nothing`, an unfiltered `EVERYONE` listing aggregated across every
enabled server, mirroring `Components.Pages.PostsPage`'s own aggregation for
`Pages.Home_`) and `Pages.Username_.{Following,Followers,Friends}`/
`Pages.User.UserId_.{Following,Followers,Friends}` (which pass the
already-resolved profile `User` paired with the host it was resolved from and
the relevant `UserListingType`, restricting the listing to that user's own
relationship, fetched from just that one host -- see `candidateServers` --
and adding a "Following | &lt;name&gt;"-style heading), mirroring
`Components.Pages.PostsPage`'s own `author` parameter and reuse by
`Pages.Username_.Posts`/`Pages.User.UserId_.Posts`.

Unlike `PostsPage`, this has no fade in/out animation machinery -- a list of
users has no equivalent of posts' star-driven reordering/removal to animate
around, so that complexity isn't needed here.

-}

import Components.Pages.UserProfilePage as UserProfilePage
import Components.Users as Users
import Dict exposing (Dict)
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, a, div, h2, p, text)
import Html.Attributes exposing (class, href)
import Proto.Jonline exposing (GetUsersResponse, User)
import Proto.Jonline.UserListingType exposing (UserListingType(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import Task
import Time
import UI.Classes exposing (hostnameToCSSClass)



-- MODEL


type ServerUsers
    = Loading
    | Loaded (List User)
    | Failed


{-| `accountId` is the enabled account (if any) the users were/are being
fetched with, so a later account enable/disable on the same server can be
detected as "the acting credential changed" and trigger a re-fetch -- same
convention as `Components.Pages.PostsPage.ServerFeed`.
-}
type alias ServerFeed =
    { status : ServerUsers
    , accountId : Maybe String
    }


type alias Model =
    { usersByServer : Dict String ServerFeed

    -- The user + host + listing type to restrict the listing to, if any --
    -- `Nothing` for `Pages.People`'s unfiltered `EVERYONE` listing.
    , target : Maybe ( String, User, UserListingType )
    }


init : Shared.Model -> Maybe ( String, User, UserListingType ) -> ( Model, Effect Msg )
init shared target =
    fetchNewServers shared { usersByServer = Dict.empty, target = target }


{-| Which servers this listing should ever fetch from: every enabled server,
aggregated together, when there's no `target` (`Pages.People`'s unfiltered
`EVERYONE` listing, mirroring `Components.Pages.PostsPage.fetchNewServers`'s
own aggregation for `Pages.Home_`) -- but just `target`'s own host, alone,
once there is one (`Pages.Username_.{Following,Followers,Friends}`/
`Pages.User.UserId_.{Following,Followers,Friends}`), since a user's
relationships only ever live on the one server that user themself is on;
querying every other enabled server too would be pointless (nothing there
could ever match that id) and misleadingly implies the listing is itself
federated when it isn't. Not gated on `.enabled` (unlike `enabledServers`) --
mirrors `Components.Users.Resolver.fetchTask`'s own plain `serverForHost`
check, since a profile page's own relationship listings should keep working
off of whichever server that profile was actually resolved from, regardless
of whether the viewer happens to have it "enabled" for aggregation elsewhere.
-}
candidateServers : Shared.Model -> Model -> List AccountsPanel.Server
candidateServers shared model =
    case model.target of
        Nothing ->
            AccountsPanel.enabledServers shared.accountsPanel

        Just ( host, _, _ ) ->
            AccountsPanel.serverForHost shared.accountsPanel.servers host
                |> Maybe.map List.singleton
                |> Maybe.withDefault []


{-| See `Components.Pages.PostsPage.fetchNewServers`'s doc comment -- same
drop-stale-servers/re-fetch-on-account-change/poll-fallback approach, just
against `GetUsers` instead of `GetPosts`, and scoped to `candidateServers`
rather than unconditionally every enabled server.
-}
fetchNewServers : Shared.Model -> Model -> ( Model, Effect Msg )
fetchNewServers shared model =
    let
        servers =
            candidateServers shared model

        currentAccountId server =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost
                |> Maybe.map AccountsPanel.accountId

        serversToFetch =
            servers
                |> List.filter
                    (\server ->
                        case Dict.get server.frontendHost model.usersByServer of
                            Nothing ->
                                True

                            Just feed ->
                                feed.accountId /= currentAccountId server
                    )

        fetchEffect server =
            Users.fetchUserListing
                shared.accountsPanel
                ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost |> Maybe.map .userId
                , server.frontendHost
                )
                (model.target |> Maybe.map (\( _, user, _ ) -> user.id))
                (model.target |> Maybe.map (\( _, _, listingType ) -> listingType) |> Maybe.withDefault EVERYONE)
                |> Task.attempt (GotServerUsers server.frontendHost)
                |> Effect.fromCmd

        prunedUsersByServer =
            Dict.filter (\host _ -> List.member host (List.map .frontendHost servers)) model.usersByServer
    in
    ( { model
        | usersByServer =
            List.foldl
                (\server -> Dict.insert server.frontendHost { status = Loading, accountId = currentAccountId server })
                prunedUsersByServer
                serversToFetch
      }
    , Effect.batch (List.map fetchEffect serversToFetch)
    )



-- UPDATE


type Msg
    = GotServerUsers String (Result Grpc.Error ( Maybe AccountsPanel.Msg, GetUsersResponse ))
    | Poll
    | SharedMsg Shared.Msg


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
(see `Main.notifyPageOfSharedMsg`) into `update`'s `SharedMsg` branch, without
exposing the `SharedMsg` constructor itself -- mirrors
`Components.Pages.PostsPage.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        GotServerUsers frontendHost (Ok ( maybeAccountsPanelMsg, response )) ->
            let
                accountEffect =
                    maybeAccountsPanelMsg
                        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
                        |> Maybe.withDefault Effect.none
            in
            ( { model
                | usersByServer =
                    Dict.update frontendHost
                        (Maybe.map (\feed -> { feed | status = Loaded response.users }))
                        model.usersByServer
              }
            , accountEffect
            )

        GotServerUsers frontendHost (Err _) ->
            ( { model
                | usersByServer =
                    Dict.update frontendHost (Maybe.map (\feed -> { feed | status = Failed })) model.usersByServer
              }
            , Effect.none
            )

        Poll ->
            fetchNewServers shared model

        SharedMsg subMsg ->
            let
                ( fetchedModel, fetchEffect ) =
                    case subMsg of
                        Shared.AccountsPanelMsg _ ->
                            fetchNewServers shared model

                        _ ->
                            ( model, Effect.none )
            in
            ( fetchedModel, Effect.batch [ Effect.fromShared subMsg, fetchEffect ] )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 30000 (\_ -> Poll)



-- VIEW


view : Shared.Model -> Model -> Html Msg
view shared model =
    div []
        [ targetHeadingView shared model.target
        , usersListView shared model
        ]


{-| "Following"/"Followers"/"Friends" alone once there's a `target` to filter
by (even before that `User` -- already resolved by the caller, see `init` --
has actually rendered), upgraded to e.g. "Following | &lt;name&gt;" via
`Components.Pages.UserProfilePage.nameHeader` -- absent entirely for
`Pages.People`'s unfiltered listing (`target == Nothing`), which supplies its
own "People" heading instead. Mirrors
`Components.Pages.PostsPage.authorHeadingView` exactly.
-}
targetHeadingView : Shared.Model -> Maybe ( String, User, UserListingType ) -> Html Msg
targetHeadingView shared maybeTarget =
    case maybeTarget of
        Nothing ->
            text ""

        Just ( host, targetUser, listingType ) ->
            let
                profileUrl =
                    Users.usernameHref "" shared.accountsPanel.mainFrontendHost host targetUser.username
            in
            div [ class "posts-page-heading" ]
                [ h2 [] [ text (listingTypeHeading listingType) ]
                , a [ href profileUrl, class <| hostnameToCSSClass host ]
                    [ case AccountsPanel.serverForHost shared.accountsPanel.servers host of
                        Just server ->
                            UserProfilePage.nameHeader server (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host) targetUser

                        Nothing ->
                            UserProfilePage.usernameHeading targetUser
                    ]
                ]


listingTypeHeading : UserListingType -> String
listingTypeHeading listingType =
    case listingType of
        FOLLOWING ->
            "Following"

        FOLLOWERS ->
            "Followers"

        FRIENDS ->
            "Friends"

        _ ->
            "People"


usersListView : Shared.Model -> Model -> Html Msg
usersListView shared model =
    let
        loadedUsers =
            model.usersByServer
                |> Dict.toList
                |> List.concatMap
                    (\( host, feed ) ->
                        case feed.status of
                            Loaded users ->
                                List.map (\user -> ( host, user )) users

                            _ ->
                                []
                    )
                |> List.sortBy (\( _, user ) -> String.toLower user.username)
    in
    if Dict.isEmpty model.usersByServer then
        p [ class "posts-empty" ] [ text "Connect to a server to see people." ]

    else if List.isEmpty loadedUsers then
        p [ class "posts-empty" ] [ text "No people yet." ]

    else
        div [ class "users-list" ] (List.map (userCardView shared) loadedUsers)


userCardView : Shared.Model -> ( String, User ) -> Html Msg
userCardView shared ( host, user ) =
    case AccountsPanel.serverForHost shared.accountsPanel.servers host of
        Just server ->
            Users.userCard shared.basePath
                shared.accountsPanel.mainFrontendHost
                server
                (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host)
                user

        Nothing ->
            text ""
