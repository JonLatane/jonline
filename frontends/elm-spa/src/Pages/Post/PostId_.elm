module Pages.Post.PostId_ exposing (Model, Msg, fromShared, page)

import Components.Markdown as Markdown
import Components.Posts as Posts
import Components.ServerDependentView as ServerDependentView
import Effect exposing (Effect)
import Gen.Params.Post.PostId_ exposing (Params)
import Grpc
import Html exposing (Html, a, button, div, p, span, text)
import Html.Attributes exposing (class, href, target)
import Html.Events exposing (onClick)
import Page
import Proto.Jonline exposing (Post)
import Proto.Jonline.Permission exposing (Permission(..))
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.MarkdownPanel as MarkdownPanel
import Shared.StarredPostsPanel as StarredPostsPanel
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


type RepliesStatus
    = RepliesNotLoaded
    | RepliesLoading
    | RepliesLoaded (List Post)
    | RepliesFailed


type alias Model =
    { targetHost : String
    , postId : String
    , postStatus : PostStatus
    , repliesStatus : RepliesStatus
    , connectStatus : ServerDependentView.ConnectStatus
    , fetchStarted : Bool
    }


init : Shared.Model -> Params -> ( Model, Effect Msg )
init shared params =
    let
        ( postId, targetHost ) =
            Posts.parsePostRouteId shared.accountsPanel.mainFrontendHost params.postId
    in
    fetchIfReady shared
        { targetHost = targetHost
        , postId = postId
        , postStatus = LoadingPost
        , repliesStatus = RepliesNotLoaded
        , connectStatus = ServerDependentView.NotConnected
        , fetchStarted = False
        }


{-| Kicks off the actual `GetPosts` fetch the first time `targetHost` is a
known, connected server -- whether that was already true at `init`, or only
became true later because the user connected it (`ConnectClicked`) or it
auto-reconnected in the background.

This is event-driven -- any `AccountsPanel` message passing through `update`'s
`SharedMsg` branch triggers a call, since that covers a server
connecting/being added, including reconnecting persisted servers on app
startup (`Main.notifyPageOfSharedMsg` forwards those top-level `Shared`
messages into whichever page is active). `subscriptions`' poll is just a
distrustful fallback in case some future state change doesn't route through
`SharedMsg`, so it can be slow.

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
                in
                ( { model | fetchStarted = True, repliesStatus = RepliesLoading }
                , Effect.batch
                    [ Posts.fetchPost server maybeAccount model.postId
                        |> Task.attempt GotPost
                        |> Effect.fromCmd
                    , Posts.fetchReplies server maybeAccount model.postId
                        |> Task.attempt GotReplies
                        |> Effect.fromCmd
                    ]
                )

            Nothing ->
                ( model, Effect.none )


{-| Re-fetches the post and its replies unconditionally (unlike `fetchIfReady`,
not gated on `fetchStarted`, which is already `True` by the time this is ever
called) -- for `update`'s `SharedMsg` branch to call once the Markdown panel
(see `Shared.MarkdownPanel`) reports a successful save: either this post's
content just changed (`MarkdownPanel.PostContent`) or a new reply to it was
just posted (`MarkdownPanel.NewReply`) -- either way, both are worth
refreshing, and refetching both unconditionally is simpler than threading
through which of the two it was.
-}
refetch : Shared.Model -> Model -> ( Model, Effect Msg )
refetch shared model =
    case AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost of
        Just server ->
            let
                maybeAccount =
                    AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost
            in
            ( model
            , Effect.batch
                [ Posts.fetchPost server maybeAccount model.postId
                    |> Task.attempt GotPost
                    |> Effect.fromCmd
                , Posts.fetchReplies server maybeAccount model.postId
                    |> Task.attempt GotReplies
                    |> Effect.fromCmd
                ]
            )

        Nothing ->
            ( model, Effect.none )



-- UPDATE


type Msg
    = GotPost (Result Grpc.Error ( Maybe AccountsPanel.Account, Proto.Jonline.GetPostsResponse ))
    | GotReplies (Result Grpc.Error ( Maybe AccountsPanel.Account, Proto.Jonline.GetPostsResponse ))
    | ConnectClicked
    | GotConnectResult (Result Grpc.Error AccountsPanel.Server)
    | EnableClicked
    | EditClicked Post
    | ReplyClicked Post
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

        GotReplies (Ok ( maybeAccount, response )) ->
            let
                accountEffect =
                    maybeAccount
                        |> Maybe.map (AccountsPanel.AccountRefreshed >> Shared.AccountsPanelMsg >> Effect.fromShared)
                        |> Maybe.withDefault Effect.none
            in
            ( { model | repliesStatus = RepliesLoaded response.posts }, accountEffect )

        GotReplies (Err _) ->
            ( { model | repliesStatus = RepliesFailed }, Effect.none )

        EditClicked post ->
            ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.PostContent post) model.targetHost)) )

        ReplyClicked post ->
            ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.NewReply post) model.targetHost)) )

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

        EnableClicked ->
            ( model, Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.ToggleServerEnabled model.targetHost)) )

        Poll ->
            fetchIfReady shared model

        SharedMsg subMsg ->
            let
                ( fetchedModel, fetchEffect ) =
                    case subMsg of
                        Shared.AccountsPanelMsg _ ->
                            fetchIfReady shared model

                        Shared.MarkdownPanelMsg (MarkdownPanel.GotSaveResult (Ok _)) ->
                            refetch shared model

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



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = titleFor shared model
    , body = UI.layout shared req.route SharedMsg [ bodyView shared req model ]
    }


titleFor : Shared.Model -> Model -> String
titleFor shared model =
    let
        subtitle =
            case model.postStatus of
                PostLoaded post ->
                    Posts.postTitleText post

                _ ->
                    "Post " ++ model.postId
    in
    UI.pageTitle shared [ subtitle ]


bodyView : Shared.Model -> Request.With Params -> Model -> Html Msg
bodyView shared req model =
    ServerDependentView.view
        { hostname = model.targetHost
        , servers = shared.accountsPanel.servers
        , accounts = shared.accountsPanel.accounts
        , connectStatus = model.connectStatus
        , onConnectClicked = ConnectClicked
        , onEnableClicked = EnableClicked
        }
        (\_ _ ->
            case model.postStatus of
                LoadingPost ->
                    p [ class "post-loading" ] [ text "Loading…" ]

                PostFailed ->
                    p [ class "post-error" ] [ text ("Couldn't load Post " ++ model.postId ++ "@" ++ model.targetHost ++ ". Maybe it doesn't exist, or maybe you need to be logged in?") ]

                PostLoaded post ->
                    div []
                        [ postDetailView shared model post
                        , postActionsView shared model post
                        , repliesView model
                        , commentsLinkView shared req post
                        ]
        )


postDetailView : Shared.Model -> Model -> Post -> Html Msg
postDetailView shared model post =
    let
        displayPost =
            StarredPostsPanel.freshestPost model.targetHost post shared.starredPostsPanel

        starred =
            StarredPostsPanel.isStarred model.targetHost displayPost shared.starredPostsPanel

        onStarClicked =
            StarredPostsPanel.toggleStarMsg shared.accountsPanel model.targetHost displayPost
                |> Maybe.map (Shared.StarredPostsPanelMsg >> SharedMsg)

        maybeServer =
            AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost

        maybeAccount =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost
    in
    Posts.postDetail shared.basePath shared.accountsPanel.mainFrontendHost model.targetHost maybeServer maybeAccount starred onStarClicked displayPost


{-| An Edit button, shown only to `post`'s own author (see `Posts.isAuthor`),
and a Reply button, shown to any signed-in account with `REPLYTOPOSTS` -- both
open the shared Markdown editor panel (see `Shared.MarkdownPanel`), targeting
this Post either way (`EditClicked`/`ReplyClicked`).
-}
postActionsView : Shared.Model -> Model -> Post -> Html Msg
postActionsView shared model post =
    case AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost of
        Just account ->
            div [ class "post-actions" ]
                ((if Posts.isAuthor account post then
                    [ button [ class "post-edit-button", onClick (EditClicked post) ] [ text "Edit" ] ]

                  else
                    []
                 )
                    ++ (if List.member REPLYTOPOSTS account.permissions then
                            [ button [ class "post-reply-button", onClick (ReplyClicked post) ] [ text "Reply" ] ]

                        else
                            []
                       )
                )

        Nothing ->
            text ""


{-| A basic list of this post's direct replies (see `GotReplies`) -- updates
whenever a new reply is posted through the Reply button here (see `refetch`).
-}
repliesView : Model -> Html Msg
repliesView model =
    case model.repliesStatus of
        RepliesNotLoaded ->
            text ""

        RepliesLoading ->
            p [ class "replies-loading" ] [ text "Loading replies…" ]

        RepliesFailed ->
            text ""

        RepliesLoaded [] ->
            text ""

        RepliesLoaded replies ->
            div [ class "post-replies" ]
                (div [ class "post-replies-header" ] [ text "Replies" ]
                    :: List.map replyItemView replies
                )


replyItemView : Post -> Html Msg
replyItemView reply =
    div [ class "post-reply-item" ]
        [ span [ class "post-reply-author" ] [ text (Posts.postAuthorName reply) ]
        , case reply.content of
            Just content ->
                Markdown.view [ class "post-reply-content" ] content

            Nothing ->
                text ""
        ]


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
        p [ class "post-comments-link" ]
            [ a [ href (reactCommentsHref shared req), target "_self" ]
                [ text
                    "View from the React app"
                ]
            ]

    else
        p [ class "post-comments-link" ]
            [ a [ href (reactCommentsHref shared req), target "_self" ]
                [ text
                    ("View "
                        ++ String.fromInt commentCount
                        ++ " comment"
                        ++ (if commentCount == 1 then
                                ""

                            else
                                "s"
                           )
                        ++ " from the React app"
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



-- ++ "#discussion"
