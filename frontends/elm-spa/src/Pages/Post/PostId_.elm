module Pages.Post.PostId_ exposing (Model, Msg, page)

import Components.Posts as Posts
import Components.ServerDependentView as ServerDependentView
import Effect exposing (Effect)
import Gen.Params.Post.PostId_ exposing (Params)
import Grpc
import Html exposing (Html, a, div, p, text)
import Html.Attributes exposing (class, href)
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
        { init = init shared req.params
        , update = update shared req
        , view = view shared req
        , subscriptions = subscriptions
        }



-- MODEL


type PostStatus
    = LoadingPost
    | PostLoaded Post
    | PostFailed


type alias Model =
    { targetHost : String
    , postId : String
    , postStatus : PostStatus
    , connectStatus : ServerDependentView.ConnectStatus
    , fetchStarted : Bool
    }


init : Shared.Model -> Params -> ( Model, Effect Msg )
init shared params =
    let
        ( postId, targetHost ) =
            parsePostRouteId shared.accountsPanel.mainFrontendHost params.postId
    in
    fetchIfReady shared
        { targetHost = targetHost
        , postId = postId
        , postStatus = LoadingPost
        , connectStatus = ServerDependentView.NotConnected
        , fetchStarted = False
        }


{-| `postId` is either a bare id (a post on the server this app's currently
browsing from) or `id@host` (a post on some other, federated server) -- see
the other side of this in `Components.Posts.postHref`.
-}
parsePostRouteId : String -> String -> ( String, String )
parsePostRouteId mainFrontendHost rawPostId =
    case String.split "@" rawPostId of
        [ id, host ] ->
            ( id, host )

        _ ->
            ( rawPostId, mainFrontendHost )


{-| Kicks off the actual `GetPosts` fetch the first time `targetHost` is a
known, connected server -- whether that was already true at `init`, or only
became true later because the user connected it (`ConnectClicked`) or it
auto-reconnected in the background. Reconnecting happens via `Shared`'s own
update, not this page's, so there's no direct hook for "a server just became
available" -- polling (see `subscriptions`/`Poll`) is how this page notices.
-}
fetchIfReady : Shared.Model -> Model -> ( Model, Effect Msg )
fetchIfReady shared model =
    if model.fetchStarted then
        ( model, Effect.none )

    else
        case AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost of
            Just server ->
                ( { model | fetchStarted = True }
                , Posts.fetchPost
                    server
                    (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost)
                    model.postId
                    |> Task.attempt GotPost
                    |> Effect.fromCmd
                )

            Nothing ->
                ( model, Effect.none )



-- UPDATE


type Msg
    = GotPost (Result Grpc.Error ( Maybe AccountsPanel.Account, Proto.Jonline.GetPostsResponse ))
    | ConnectClicked
    | GotConnectResult (Result Grpc.Error AccountsPanel.Server)
    | Poll
    | SharedMsg Shared.Msg


update : Shared.Model -> Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
update shared req msg model =
    case msg of
        GotPost (Ok ( maybeAccount, response )) ->
            let
                accountEffect =
                    maybeAccount
                        |> Maybe.map (AccountsPanel.AccountRefreshed >> Shared.AccountsPanelMsg >> Effect.fromShared)
                        |> Maybe.withDefault Effect.none
            in
            ( { model
                | postStatus =
                    response.posts
                        |> List.head
                        |> Maybe.map PostLoaded
                        |> Maybe.withDefault PostFailed
              }
            , accountEffect
            )

        GotPost (Err _) ->
            ( { model | postStatus = PostFailed }, Effect.none )

        ConnectClicked ->
            ( { model | connectStatus = ServerDependentView.Connecting }
            , AccountsPanel.connectToServer (AccountsPanel.isSecure req) model.targetHost
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
            ( model, Effect.fromShared subMsg )


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.fetchStarted then
        Sub.none

    else
        Time.every 1500 (\_ -> Poll)



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = titleFor model
    , body = UI.layout shared req.route SharedMsg [ bodyView shared req model ]
    }


titleFor : Model -> String
titleFor model =
    case model.postStatus of
        PostLoaded post ->
            Posts.postTitleText post

        _ ->
            "Post"


bodyView : Shared.Model -> Request.With Params -> Model -> Html Msg
bodyView shared req model =
    ServerDependentView.view
        { hostname = model.targetHost
        , servers = shared.accountsPanel.servers
        , accounts = shared.accountsPanel.accounts
        , connectStatus = model.connectStatus
        , onConnectClicked = ConnectClicked
        }
        (\_ _ ->
            case model.postStatus of
                LoadingPost ->
                    p [ class "post-loading" ] [ text "Loading…" ]

                PostFailed ->
                    p [ class "post-error" ] [ text "Couldn't load this post." ]

                PostLoaded post ->
                    div []
                        [ Posts.postDetail model.targetHost post
                        , commentsLinkView shared req post
                        ]
        )


{-| A link out to the same post's comments on the React (Tamagui) app, which
has actual comment-viewing/-posting UI this app doesn't yet -- only shown if
there are any comments to see. Same origin the Elm app itself is being viewed
from (just `/elm` swapped for `/tamagui`, and `#comments` appended to jump
straight there) -- except when that origin is the bare `elm-spa server` dev
server (port 1234), which has no Rust backend of its own to serve `/tamagui`
from at all, so that case links to the local backend's default port (8000)
instead.
-}
commentsLinkView : Shared.Model -> Request.With Params -> Post -> Html Msg
commentsLinkView shared req post =
    let
        commentCount =
            Posts.postCommentCount post
    in
    if commentCount <= 0 then
        text ""

    else
        p [ class "post-comments-link" ]
            [ a [ href (reactCommentsHref shared req) ]
                [ text
                    ("View "
                        ++ String.fromInt commentCount
                        ++ " comment"
                        ++ (if commentCount == 1 then
                                ""

                            else
                                "s"
                           )
                    )
                ]
            ]


reactCommentsHref : Shared.Model -> Request.With Params -> String
reactCommentsHref shared req =
    let
        isDevServer =
            req.url.port_ == Just 1234

        scheme =
            if AccountsPanel.isSecure req then
                "https://"

            else
                "http://"

        port_ =
            if isDevServer then
                Just 8000

            else
                req.url.port_

        portSuffix =
            port_
                |> Maybe.map (\p -> ":" ++ String.fromInt p)
                |> Maybe.withDefault ""
    in
    scheme
        ++ shared.accountsPanel.browsingHost
        ++ portSuffix
        ++ "/tamagui/post/"
        ++ req.params.postId
        ++ "#comments"
