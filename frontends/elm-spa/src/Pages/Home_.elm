module Pages.Home_ exposing (Model, Msg, page)

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


type alias Model =
    { postsByServer : Dict String ServerPosts
    }


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    fetchNewServers shared { postsByServer = Dict.empty }


{-| Servers connect asynchronously -- on app startup (reconnecting persisted
servers) or any time later (the user adding/enabling one) -- via `Shared`'s
own update, not this page's, so there's no direct hook for "a new server just
became available". Polling (see `subscriptions`/`Poll`) is how this page
notices and fetches its posts; already-fetched servers are cheap to skip
(`Dict.member`), so this is safe to call as often as it likes.
-}
fetchNewServers : Shared.Model -> Model -> ( Model, Effect Msg )
fetchNewServers shared model =
    let
        newServers =
            AccountsPanel.enabledServers shared.accountsPanel
                |> List.filter (\server -> not (Dict.member server.frontendHost model.postsByServer))

        fetchEffect server =
            Posts.fetchRecentPosts
                server
                (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost)
                |> Task.attempt (GotServerPosts server.frontendHost)
                |> Effect.fromCmd
    in
    ( { model
        | postsByServer =
            List.foldl (\server -> Dict.insert server.frontendHost Loading) model.postsByServer newServers
      }
    , Effect.batch (List.map fetchEffect newServers)
    )



-- UPDATE


type Msg
    = GotServerPosts String (Result Grpc.Error ( Maybe AccountsPanel.Account, Proto.Jonline.GetPostsResponse ))
    | Poll
    | SharedMsg Shared.Msg


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
            ( { model | postsByServer = Dict.insert frontendHost (Loaded response.posts) model.postsByServer }
            , accountEffect
            )

        GotServerPosts frontendHost (Err _) ->
            ( { model | postsByServer = Dict.insert frontendHost Failed model.postsByServer }, Effect.none )

        Poll ->
            fetchNewServers shared model

        SharedMsg subMsg ->
            ( model, Effect.fromShared subMsg )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 2000 (\_ -> Poll)



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
                    (\( host, status ) ->
                        case status of
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
            (List.map
                (\( host, post ) -> Posts.postCard shared.basePath shared.accountsPanel.mainFrontendHost host post)
                allPosts
            )
