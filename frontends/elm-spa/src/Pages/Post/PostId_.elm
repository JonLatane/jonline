module Pages.Post.PostId_ exposing (Model, Msg, fromShared, page)

import Components.PostCard as Posts
import Components.PostReplies as PostReplies
import Components.ServerDependentView as ServerDependentView
import Effect exposing (Effect)
import Gen.Params.Post.PostId_ exposing (Params)
import Grpc
import Html exposing (Html, a, button, div, option, p, select, span, text)
import Html.Attributes exposing (class, disabled, href, selected, target, value)
import Html.Events exposing (onClick, onInput)
import Page
import Proto.Jonline exposing (Post)
import Proto.Jonline.Permission exposing (Permission(..))
import Proto.Jonline.PostContext exposing (PostContext(..))
import Proto.Jonline.Visibility exposing (Visibility)
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.Breadcrumbs as Breadcrumbs
import Shared.MarkdownPanel as MarkdownPanel
import Shared.MediaViewerPanel as MediaViewerPanel
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


{-| Mirrors `Components.UserProfilePage.SubmitStatus` -- kept separate since
this page's visibility edit is local to it rather than routed through
`Shared.MarkdownPanel`.
-}
type SubmitStatus
    = Idle
    | Submitting
    | SubmitFailed String


{-| Live only while the visibility picker (see `Model.visibilityEdit`) is
being edited by the post's own author -- `pending` is the in-progress
`<select>` value, independent of the loaded Post's own `visibility` until
`VisibilitySaveClicked` succeeds. Mirrors `Components.UserProfilePage`'s
`RealNameEdit`.
-}
type alias VisibilityEdit =
    { pending : Visibility
    , status : SubmitStatus
    }


type alias Model =
    { targetHost : String
    , postId : String
    , postStatus : PostStatus
    , repliesModel : Maybe PostReplies.Model
    , connectStatus : ServerDependentView.ConnectStatus
    , fetchStarted : Bool
    , visibilityEdit : Maybe VisibilityEdit
    }


init : Shared.Model -> Params -> ( Model, Effect Msg )
init shared params =
    let
        ( postId, targetHost ) =
            Posts.parsePostRouteId shared.accountsPanel.mainFrontendHost params.postId

        ( fetchedModel, fetchEffect ) =
            fetchIfReady shared
                { targetHost = targetHost
                , postId = postId
                , postStatus = LoadingPost
                , repliesModel = Nothing
                , connectStatus = ServerDependentView.NotConnected
                , fetchStarted = False
                , visibilityEdit = Nothing
                }
    in
    ( fetchedModel
      -- Clears any breadcrumb trail left over from whichever Post was
      -- viewed before this one -- `GotPost` below repopulates it once this
      -- Post's own data (and, if it's a reply, its ancestor chain) is back,
      -- so there's no stale trail shown in the meantime.
    , Effect.batch [ fetchEffect, Effect.fromShared (Shared.BreadcrumbsMsg Breadcrumbs.Clear) ]
    )


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
            Just _ ->
                ( { model | fetchStarted = True }
                , Posts.fetchPost shared.accountsPanel (maybeAccountServerFor shared model) model.postId
                    |> Task.attempt GotPost
                    |> Effect.fromCmd
                )

            Nothing ->
                ( model, Effect.none )


{-| `model.targetHost` paired with whatever account (if any) is currently
signed in on it -- what `Components.PostCard`/`Components.PostReplies`'
`Model`/`Msg`-free fetch helpers need instead of a live `Server`/`Account`.
-}
maybeAccountServerFor : Shared.Model -> Model -> AccountsPanel.MaybeAccountServer
maybeAccountServerFor shared model =
    ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost |> Maybe.map .userId
    , model.targetHost
    )


{-| Re-fetches the post unconditionally (unlike `fetchIfReady`, not gated on
`fetchStarted`, which is already `True` by the time this is ever called) --
for `update`'s `SharedMsg` branch to call once the Markdown panel (see
`Shared.MarkdownPanel`) reports a successful save: either this post's content
just changed (`MarkdownPanel.PostContent`) or a new reply to it was just
posted (`MarkdownPanel.NewReply`) -- either way, `GotPost`'s own handler
re-syncs `repliesModel` too (via `PostReplies.refresh`, since it's already
`Just` by the time any save could have happened), so there's nothing else to
trigger here.
-}
refetch : Shared.Model -> Model -> ( Model, Effect Msg )
refetch shared model =
    case AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost of
        Just _ ->
            ( model
            , Posts.fetchPost shared.accountsPanel (maybeAccountServerFor shared model) model.postId
                |> Task.attempt GotPost
                |> Effect.fromCmd
            )

        Nothing ->
            ( model, Effect.none )


{-| The connected `Server`/signed-in `Account` for `model.targetHost`, if
both exist -- what `VisibilitySaveClicked` needs to actually submit its
`Posts.updatePost` task. Mirrors `Components.UserProfilePage.serverAndAccount`.
-}
serverAndAccount : Shared.Model -> Model -> Maybe ( AccountsPanel.Server, AccountsPanel.Account )
serverAndAccount shared model =
    Maybe.map2 Tuple.pair
        (AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost)
        (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost)



-- UPDATE


type Msg
    = GotPost (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetPostsResponse ))
    | GotBreadcrumbAncestors Post (Result Grpc.Error ( Maybe AccountsPanel.Msg, List Post ))
    | PostRepliesMsg PostReplies.Msg
    | ConnectClicked
    | GotConnectResult (Result Grpc.Error AccountsPanel.Server)
    | EnableClicked
    | EditClicked Post
    | ReplyClicked Post
    | MediaClicked Post String
    | VisibilityEditClicked Post
    | VisibilityChanged String
    | VisibilityCancelClicked
    | VisibilitySaveClicked Post
    | GotVisibilitySaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, Post ))
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


{-| Turns a `Maybe AccountsPanel.Msg` (as returned by `Components.PostCard`/
`Components.PostReplies`' requests, if a token refresh happened) into an
`Effect` to forward it, `Effect.none` otherwise.
-}
accountsPanelEffect : Maybe AccountsPanel.Msg -> Effect Msg
accountsPanelEffect maybeAccountsPanelMsg =
    maybeAccountsPanelMsg
        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
        |> Maybe.withDefault Effect.none


update : Shared.Model -> Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
update shared req msg model =
    case msg of
        GotPost (Ok ( maybeAccountsPanelMsg, response )) ->
            let
                accountEffect =
                    accountsPanelEffect maybeAccountsPanelMsg

                maybeUserId =
                    AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost |> Maybe.map .userId

                ( repliesModel, repliesEffect ) =
                    case ( List.head response.posts, model.repliesModel ) of
                        ( Just post, Nothing ) ->
                            PostReplies.init shared.accountsPanel maybeUserId model.targetHost post
                                |> Tuple.mapFirst Just
                                |> Tuple.mapSecond (Effect.map PostRepliesMsg)

                        ( Just post, Just existing ) ->
                            PostReplies.refresh shared.accountsPanel maybeUserId post existing
                                |> Tuple.mapFirst Just
                                |> Tuple.mapSecond (Effect.map PostRepliesMsg)

                        ( Nothing, existing ) ->
                            ( existing, Effect.none )

                -- Only a Post reached via a reply chain (`REPLY` context) has
                -- any breadcrumb trail to show -- see `GotBreadcrumbAncestors`
                -- for where `Shared.Breadcrumbs` actually gets set once this
                -- resolves. A plain top-level Post just clears whatever trail
                -- an earlier reply page here might have left behind.
                breadcrumbsEffect =
                    case List.head response.posts of
                        Just post ->
                            if post.context == REPLY then
                                Posts.fetchAncestors shared.accountsPanel (maybeAccountServerFor shared model) post
                                    |> Task.attempt (GotBreadcrumbAncestors post)
                                    |> Effect.fromCmd

                            else
                                Effect.fromShared (Shared.BreadcrumbsMsg Breadcrumbs.Clear)

                        Nothing ->
                            Effect.none
            in
            ( { model
                | postStatus =
                    response.posts
                        |> List.head
                        |> Maybe.map PostLoaded
                        |> Maybe.withDefault PostFailed
                , repliesModel = repliesModel
              }
            , Effect.batch [ accountEffect, repliesEffect, breadcrumbsEffect ]
            )

        GotPost (Err _) ->
            ( { model | postStatus = PostFailed }, Effect.none )

        GotBreadcrumbAncestors post (Ok ( maybeAccountsPanelMsg, ancestors )) ->
            let
                accountEffect =
                    accountsPanelEffect maybeAccountsPanelMsg

                -- `ancestors` is root-first and excludes `post` itself (see
                -- `Posts.fetchAncestors`) -- its first entry is the root
                -- (this Post's own reply chain can't be empty, since this is
                -- only ever kicked off for a `REPLY`-context Post), and
                -- everything after it, plus `post` itself, is the rest of the
                -- chain shown as reply segments.
                root =
                    List.head ancestors |> Maybe.withDefault post

                replies =
                    List.drop 1 ancestors ++ [ post ]
            in
            ( model
            , Effect.batch
                [ accountEffect
                , Effect.fromShared
                    (Shared.BreadcrumbsMsg (Breadcrumbs.SetRoot (Breadcrumbs.FromPost root) model.targetHost replies))
                ]
            )

        GotBreadcrumbAncestors _ (Err _) ->
            ( model, Effect.none )

        PostRepliesMsg subMsg ->
            case model.repliesModel of
                Just repliesModel ->
                    let
                        maybeUserId =
                            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost |> Maybe.map .userId

                        ( newRepliesModel, effect ) =
                            PostReplies.update shared.accountsPanel maybeUserId subMsg repliesModel
                    in
                    ( { model | repliesModel = Just newRepliesModel }, Effect.map PostRepliesMsg effect )

                Nothing ->
                    ( model, Effect.none )

        EditClicked post ->
            ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.PostContent post) model.targetHost)) )

        ReplyClicked post ->
            ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.NewReply post) model.targetHost)) )

        MediaClicked post mediaId ->
            ( model, Effect.fromShared (Shared.MediaViewerPanelMsg (MediaViewerPanel.Open post mediaId model.targetHost)) )

        VisibilityEditClicked post ->
            ( { model | visibilityEdit = Just { pending = post.visibility, status = Idle } }, Effect.none )

        VisibilityChanged text ->
            ( { model
                | visibilityEdit =
                    model.visibilityEdit
                        |> Maybe.map
                            (\edit -> { edit | pending = Posts.visibilityFromText text |> Maybe.withDefault edit.pending })
              }
            , Effect.none
            )

        VisibilityCancelClicked ->
            ( { model | visibilityEdit = Nothing }, Effect.none )

        VisibilitySaveClicked post ->
            case ( model.visibilityEdit, serverAndAccount shared model ) of
                ( Just edit, Just ( server, account ) ) ->
                    ( { model | visibilityEdit = Just { edit | status = Submitting } }
                    , Posts.updatePost shared.accountsPanel ( Just account.userId, server.frontendHost ) post.id (\freshPost -> { freshPost | visibility = edit.pending })
                        |> Task.attempt GotVisibilitySaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotVisibilitySaveResult (Ok ( maybeAccountsPanelMsg, updatedPost )) ->
            ( { model | postStatus = PostLoaded updatedPost, visibilityEdit = Nothing }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotVisibilitySaveResult (Err err) ->
            ( { model
                | visibilityEdit =
                    model.visibilityEdit |> Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })
              }
            , Effect.none
            )

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
    Sub.batch
        [ if model.fetchStarted then
            Sub.none

          else
            Time.every 30000 (\_ -> Poll)
        , model.repliesModel
            |> Maybe.map (PostReplies.subscriptions >> Sub.map PostRepliesMsg)
            |> Maybe.withDefault Sub.none
        ]



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
                        , repliesView shared model
                        , reactLinkView shared req
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

        onMediaClicked mediaId =
            MediaClicked displayPost mediaId
    in
    Posts.postDetail shared.basePath
        shared.accountsPanel.mainFrontendHost
        model.targetHost
        maybeServer
        maybeAccount
        onMediaClicked
        starred
        onStarClicked
        (EditClicked post)
        (visibilityView maybeAccount model.visibilityEdit displayPost)
        displayPost


{-| The visibility segment of `postDetail`'s meta line (see `postDetail`'s own
`visibilityView` parameter) -- plain text (`Posts.postVisibilityText`) plus an
Edit button when `model.visibilityEdit == Nothing`, shown only to `post`'s own
author (mirrors `Posts.editButton`'s own `isAuthor` gate, matching
`backend/src/rpcs/posts/update_post.rs`'s `self_update` check); an inline
`<select>` + Save/Cancel once editing, with its options narrowed to whatever
`maybeAccount` is actually allowed to pick (`Posts.allowedVisibilities`,
mirroring that same file's `PUBLISHPOSTS*`/`PUBLISHEVENTS*` permission check).
-}
visibilityView : Maybe AccountsPanel.Account -> Maybe VisibilityEdit -> Post -> Html Msg
visibilityView maybeAccount maybeEdit post =
    case ( maybeEdit, maybeAccount ) of
        ( Just edit, Just account ) ->
            let
                options =
                    Posts.allowedVisibilities account.permissions post.context post.visibility
            in
            span [ class "post-visibility-edit" ]
                [ select [ onInput VisibilityChanged ]
                    (options
                        |> List.map
                            (\visibility ->
                                option
                                    [ value (Posts.visibilityText visibility)
                                    , selected (edit.pending == visibility)
                                    ]
                                    [ text (Posts.visibilityText visibility) ]
                            )
                    )
                , button
                    [ class "post-visibility-save"
                    , onClick (VisibilitySaveClicked post)
                    , disabled (edit.status == Submitting)
                    ]
                    [ text
                        (if edit.status == Submitting then
                            "Saving…"

                         else
                            "Save"
                        )
                    ]
                , button
                    [ class "post-visibility-cancel"
                    , onClick VisibilityCancelClicked
                    , disabled (edit.status == Submitting)
                    ]
                    [ text "Cancel" ]
                , case edit.status of
                    SubmitFailed err ->
                        span [ class "post-visibility-error" ] [ text err ]

                    _ ->
                        text ""
                ]

        _ ->
            span [ class "post-visibility-display" ]
                [ text (Posts.postVisibilityText post)
                , case maybeAccount of
                    Just account ->
                        if Posts.isAuthor account post then
                            button [ class "post-visibility-edit-button", onClick (VisibilityEditClicked post) ] [ text "Edit" ]

                        else
                            text ""

                    Nothing ->
                        text ""
                ]


{-| A Reply button, shown to any signed-in account with `REPLYTOPOSTS` --
opens the shared Markdown editor panel (see `Shared.MarkdownPanel`), targeting
this Post (`ReplyClicked`). The Edit button lives in `Posts.postDetail` itself
now (see `postDetailView`), below its Markdown content.
-}
postActionsView : Shared.Model -> Model -> Post -> Html Msg
postActionsView shared model post =
    case AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost of
        Just account ->
            if List.member REPLYTOPOSTS account.permissions then
                div [ class "post-actions" ]
                    [ button [ class "post-reply-button", onClick (ReplyClicked post) ] [ text "Reply" ] ]

            else
                text ""

        Nothing ->
            text ""


{-| This post's whole threaded-replies tree (see `Components.PostReplies`) --
updates whenever a new reply is posted through the Reply button here (see
`refetch`) or a reply's own subtree is expanded.
-}
repliesView : Shared.Model -> Model -> Html Msg
repliesView shared model =
    case model.repliesModel of
        Just repliesModel ->
            PostReplies.view
                { basePath = shared.basePath
                , viewingServerHost = shared.accountsPanel.mainFrontendHost
                , postServerHost = model.targetHost
                , maybeServer = AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost
                , maybeAccount = AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost
                , onMediaClicked = MediaClicked
                , onReplyClicked = ReplyClicked
                , toMsg = PostRepliesMsg
                }
                repliesModel

        Nothing ->
            text ""


{-| A link out to the same post's comments on the React (Tamagui) app, which
has actual comment-viewing/-posting UI this app doesn't yet -- only shown if
there are any comments to see. Same origin the Elm app itself is being viewed
from (just `/elm` swapped for `/tamagui`, and `#comments` appended to jump
straight there) -- except when that origin is the bare `elm-spa server` dev
server (port 1234), which has no Rust backend of its own to serve `/tamagui`
from at all, so that case links to the local backend's default port (8000)
instead.
-}
reactLinkView : Shared.Model -> Request.With Params -> Html Msg
reactLinkView shared req =
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

        reactCommentsHref =
            scheme
                ++ shared.accountsPanel.browsingHost
                ++ portSuffix
                ++ "/tamagui/post/"
                ++ req.params.postId
    in
    p [ class "post-comments-link" ]
        [ a [ href reactCommentsHref, target "_self" ]
            [ text
                "View from the React app"
            ]
        ]
