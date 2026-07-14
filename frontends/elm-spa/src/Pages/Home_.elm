module Pages.Home_ exposing (Model, Msg, fromShared, page)

import Components.Posts as Posts
import Dict exposing (Dict)
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Grpc
import Html exposing (Html, div, h2, p, text)
import Html.Attributes exposing (class)
import Page
import Proto.Jonline exposing (Post)
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.StarredPostsPanel as StarredPostsPanel
import Task
import Time
import UI
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared
        , update = update shared
        , view = view shared req
        , subscriptions = subscriptions
        }



-- MODEL


type ServerPosts
    = Loading
    | Loaded (List Post)
    | Failed


{-| `accountId` is the enabled account (if any) the posts were/are being
fetched with, so a later account enable/disable on the same server can be
detected as "the acting credential changed" and trigger a re-fetch.
-}
type alias ServerFeed =
    { status : ServerPosts
    , accountId : Maybe String
    }


type alias Model =
    { postsByServer : Dict String ServerFeed
    }


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    fetchNewServers shared { postsByServer = Dict.empty }


{-| Drops posts for servers that are no longer enabled (so disabling a server
hides its posts entirely), and re-fetches a server whose acting account (the
first enabled account signed into it, or anonymous) has changed since the
last fetch -- covering both disabling an account (falls back to anonymous)
and enabling a different one. Already-fetched-with-the-same-account servers
are cheap to skip, so this is safe to call as often as it likes.

This is event-driven -- any `AccountsPanel` message passing through `update`'s
`SharedMsg` branch triggers a call, since that covers server/account
add/remove/enable/toggle, including reconnecting persisted servers on app
startup (`Main.notifyPageOfSharedMsg` forwards those top-level `Shared`
messages into whichever page is active). `subscriptions`' poll is just a
distrustful fallback in case some future state change doesn't route through
`SharedMsg`, so it can be slow.
-}
fetchNewServers : Shared.Model -> Model -> ( Model, Effect Msg )
fetchNewServers shared model =
    let
        enabledServers =
            AccountsPanel.enabledServers shared.accountsPanel

        currentAccountId server =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost
                |> Maybe.map AccountsPanel.accountId

        serversToFetch =
            enabledServers
                |> List.filter
                    (\server ->
                        case Dict.get server.frontendHost model.postsByServer of
                            Nothing ->
                                True

                            Just feed ->
                                feed.accountId /= currentAccountId server
                    )

        fetchEffect server =
            Posts.fetchRecentPosts
                server
                (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost)
                |> Task.attempt (GotServerPosts server.frontendHost)
                |> Effect.fromCmd

        prunedPostsByServer =
            Dict.filter (\host _ -> List.member host (List.map .frontendHost enabledServers)) model.postsByServer
    in
    ( { model
        | postsByServer =
            List.foldl
                (\server -> Dict.insert server.frontendHost { status = Loading, accountId = currentAccountId server })
                prunedPostsByServer
                serversToFetch
      }
    , Effect.batch (List.map fetchEffect serversToFetch)
    )



-- UPDATE


type Msg
    = GotServerPosts String (Result Grpc.Error ( Maybe AccountsPanel.Account, Proto.Jonline.GetPostsResponse ))
    | Poll
    | SharedMsg Shared.Msg


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
(see `Main.notifyPageOfSharedMsg`) into `update`'s `SharedMsg` branch, without
exposing the `SharedMsg` constructor itself (and thus every other constructor
of this otherwise-opaque `Msg`) outside this module.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        GotServerPosts frontendHost (Ok ( maybeAccount, response )) ->
            let
                accountEffect =
                    maybeAccount
                        |> Maybe.map (AccountsPanel.AccountRefreshed >> Shared.AccountsPanelMsg >> Effect.fromShared)
                        |> Maybe.withDefault Effect.none
            in
            ( { model
                | postsByServer =
                    Dict.update frontendHost
                        (Maybe.map (\feed -> { feed | status = Loaded response.posts }))
                        model.postsByServer
              }
            , accountEffect
            )

        GotServerPosts frontendHost (Err _) ->
            ( { model
                | postsByServer =
                    Dict.update frontendHost (Maybe.map (\feed -> { feed | status = Failed })) model.postsByServer
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


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = "Homepage"
    , body =
        UI.layout shared
            req.route
            SharedMsg
            [ h2 [] [ text "Recent Posts" ]
            , recentPostsView shared model
            ]
    }


recentPostsView : Shared.Model -> Model -> Html Msg
recentPostsView shared model =
    let
        allPosts =
            model.postsByServer
                |> Dict.toList
                |> List.concatMap
                    (\( host, feed ) ->
                        case feed.status of
                            Loaded posts ->
                                List.map (Tuple.pair host) posts

                            _ ->
                                []
                    )
                |> List.sortBy (\( _, post ) -> -(Time.posixToMillis (Posts.postTimestamp post)))
    in
    if Dict.isEmpty model.postsByServer then
        p [ class "posts-empty" ] [ text "Connect to a server to see recent posts." ]

    else if List.isEmpty allPosts then
        p [ class "posts-empty" ] [ text "No posts yet." ]

    else
        div [ class "posts-list" ]
            (List.map (postCardView shared) allPosts)


postCardView : Shared.Model -> ( String, Post ) -> Html Msg
postCardView shared ( host, post ) =
    let
        displayPost =
            StarredPostsPanel.freshestPost host post shared.starredPostsPanel

        starred =
            StarredPostsPanel.isStarred host displayPost shared.starredPostsPanel

        onStarClicked =
            AccountsPanel.serverForHost shared.accountsPanel.servers host
                |> Maybe.map
                    (\server ->
                        SharedMsg (Shared.StarredPostsPanelMsg (StarredPostsPanel.ToggleStar server displayPost))
                    )
    in
    Posts.postCard shared.basePath shared.accountsPanel.mainFrontendHost host False starred onStarClicked displayPost
