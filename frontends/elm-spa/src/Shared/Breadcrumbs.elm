module Shared.Breadcrumbs exposing (BreadcrumbRoot(..), Model, Msg(..), bar, init, replyPanel, update)

{-| A trail of "how did I get here" chips shown at the bottom of the top nav
(see `UI.headerNav`), for a Post reached by following a chain of replies (and,
eventually, Event/Event Instance discussions) rather than directly: the root
thing's own title/name, then one avatar+username chip per reply on the way to
whichever Post is currently being viewed. Tapping any chip opens `replyPanel`,
a popup anchored just under the trail itself showing that chip's own Post --
so jumping back to an ancestor reply doesn't require actually navigating to
its own page. The open chip is tinted with `model.host`'s own
`background-color-primary` (see `UI.EmittedStylesheet`), so it's clear which
segment `replyPanel` is currently showing.

Wired into `Shared.Model`/`UI.elm` the same way `Shared.MarkdownPanel` is: one
shared instance, populated contextually by whichever page has a chain to show
(currently just `Pages.Post.PostId_`, via `SetRoot`) rather than each page
owning its own breadcrumb state.

Only `FromPost` is actually rendered for now -- `FromEvent` (an Event
Instance's discussion, reached the same way) is a real variant already so
callers/`Model` don't need to change shape again once it's wired up, but its
`rootSegment`/its own ancestor-fetching aren't implemented yet.

-}

import Components.Authors as Authors
import Components.Markdown as Markdown
import Components.MultiMediaRenderer as MultiMediaRenderer
import Components.Posts as Posts
import Html exposing (Html, a, button, div, h1, img, span, text)
import Html.Attributes exposing (alt, class, href, src)
import Html.Events exposing (onClick)
import Proto.Jonline exposing (Event, EventInstance, Post)
import Shared.AccountsPanel as AccountsPanel
import UI.Classes exposing (classes, openClosedClass)


type BreadcrumbRoot
    = FromPost Post
    | FromEvent Event EventInstance


type alias Model =
    { root : Maybe BreadcrumbRoot

    -- The `frontendHost` every Post in `root`/`replies` lives on -- they're
    -- always all on the same server (a reply chain never crosses servers),
    -- needed to resolve the `AccountsPanel.Server`/signed-in `Account` to
    -- render avatars/media/links with, same reasoning as
    -- `Shared.MarkdownPanel.Model`'s `targetHost`.
    , host : String

    -- The chain of replies from (but not including) `root` down to whichever
    -- Post is currently being viewed, root-first -- so the last entry is
    -- always the Post the page that called `SetRoot` is showing.
    , replies : List Post

    -- The id of whichever segment's `replyPanel` is currently open, if any --
    -- looked up against `root`/`replies` at render time (see `postFor`)
    -- rather than storing the `Post` itself a second time.
    , viewing : Maybe String
    }


init : Model
init =
    { root = Nothing
    , host = ""
    , replies = []
    , viewing = Nothing
    }


type Msg
    = SetRoot BreadcrumbRoot String (List Post)
    | Clear
    | SegmentClicked String
    | CloseViewer
    | NoOp


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetRoot root host replies ->
            { root = Just root, host = host, replies = replies, viewing = Nothing }

        Clear ->
            init

        SegmentClicked postId ->
            if model.viewing == Just postId then
                { model | viewing = Nothing }

            else
                { model | viewing = Just postId }

        CloseViewer ->
            { model | viewing = Nothing }

        NoOp ->
            model


{-| Every Post a segment currently renders for -- `root` (if it's a `FromPost`)
followed by `replies` -- used both to render the trail itself and to look up
`viewing`'s Post for `replyPanel`.
-}
segments : Model -> List Post
segments model =
    case model.root of
        Just (FromPost post) ->
            post :: model.replies

        _ ->
            model.replies


postFor : Model -> Maybe String -> Maybe Post
postFor model maybePostId =
    maybePostId
        |> Maybe.andThen (\postId -> segments model |> List.filter (\post -> post.id == postId) |> List.head)



-- VIEW


{-| The horizontally-scrollable trail itself -- empty (`text ""`) if no page
has set a `root` right now. Mounted at the bottom of `.navbar` (see
`UI.headerNav`), not as a floating panel like `replyPanel` below.
-}
bar : AccountsPanel.Model -> Model -> Html Msg
bar accountsPanelModel model =
    case model.root of
        Nothing ->
            text ""

        Just root ->
            div [ class "breadcrumbs-bar" ]
                (List.intersperse separator
                    (rootSegment model root :: List.map (replySegment accountsPanelModel model) model.replies)
                )


separator : Html Msg
separator =
    span [ class "breadcrumb-separator" ] [ text "›" ]


rootSegment : Model -> BreadcrumbRoot -> Html Msg
rootSegment model root =
    case root of
        FromPost post ->
            button
                [ classes (segmentClasses model "breadcrumb-root" post.id)
                , onClick (SegmentClicked post.id)
                ]
                [ span [ class "breadcrumb-root-title" ] [ text (Posts.postTitleText post) ] ]

        FromEvent _ _ ->
            div [ classes [ "breadcrumb-segment", "breadcrumb-root" ] ]
                [ text "TODO: User/Event Breadcrumb Rendering" ]


replySegment : AccountsPanel.Model -> Model -> Post -> Html Msg
replySegment accountsPanelModel model post =
    let
        maybeServer =
            AccountsPanel.serverForHost accountsPanelModel.servers model.host

        maybeAccount =
            AccountsPanel.enabledAccountForServer accountsPanelModel.accounts model.host

        name =
            Authors.name post.author
    in
    button
        [ classes (segmentClasses model "breadcrumb-reply" post.id)
        , onClick (SegmentClicked post.id)
        ]
        [ segmentAvatar name (Authors.avatarUrl maybeServer maybeAccount post.author)
        , span [ class "breadcrumb-reply-username" ] [ text name ]
        ]


{-| The classes for a segment button: always `"breadcrumb-segment"` plus its
own kind (`"breadcrumb-root"`/`"breadcrumb-reply"`); additionally
`[ model.host, "background-color-primary" ]` (see `UI.EmittedStylesheet`) when
this segment's Post is the one `replyPanel` currently has open, tinting it
with that server's own primary color to mark it as the open one.
-}
segmentClasses : Model -> String -> String -> List String
segmentClasses model kindClass postId =
    "breadcrumb-segment"
        :: kindClass
        :: (if model.viewing == Just postId then
                [ model.host, "background-color-primary" ]

            else
                []
           )


{-| Mirrors `Components.PostCard.authorAvatar`/`UI.imageOrInitial` -- not
reused directly (importing either would cycle: `Components.PostCard` doesn't
import `Shared.Breadcrumbs`, but `UI` does, and `UI` is what `imageOrInitial`
lives in).
-}
segmentAvatar : String -> Maybe String -> Html msg
segmentAvatar name maybeUrl =
    case maybeUrl of
        Just url ->
            img [ classes [ "breadcrumb-reply-avatar" ], src url, alt name ] []

        Nothing ->
            div [ classes [ "breadcrumb-reply-avatar", "placeholder" ] ] [ text (AccountsPanel.initialLetter name) ]


{-| A popup, anchored just under `bar`'s own trail (see nav.css's
`.breadcrumb-reply-panel`), showing whichever segment's Post was last tapped
(see `viewing`) -- a smaller, read-only relative of
`Components.Posts.replyCard` (title if it's the root -- see `isRoot`,
author, media, content via `Components.Markdown` same as everywhere else Post
content renders, permalink; no Reply/load-more/collapse actions, which don't
make sense for a single already-in-hand Post shown out of its thread, and no
close button of its own -- tapping the open segment again, another segment, or
the shared backdrop all already close it, see `UI.sharedBackdrop`). Always
rendered, even closed, same "opening/closing is a CSS transition" convention
as every other panel here -- see `UI.Classes.openClosedClass`. `basePath` is
`Shared.Model.basePath`, needed for the author/permalink links.
-}
replyPanel : String -> AccountsPanel.Model -> Model -> Html Msg
replyPanel basePath accountsPanelModel model =
    div [ classes [ "breadcrumb-reply-panel", "nav-panel", openClosedClass (model.viewing /= Nothing) ] ]
        (case postFor model model.viewing of
            Just post ->
                [ replyCardView basePath accountsPanelModel model post ]

            Nothing ->
                []
        )


{-| Whether `post` is `model`'s own root (as opposed to one of its `replies`)
-- the root is the only segment with a real title shown on its `replyCardView`;
a reply never has one worth showing on its own card, same as
`Components.PostReplies` never shows one for its own cards.
-}
isRoot : Model -> Post -> Bool
isRoot model post =
    case model.root of
        Just (FromPost rootPost) ->
            rootPost.id == post.id

        _ ->
            False


replyCardView : String -> AccountsPanel.Model -> Model -> Post -> Html Msg
replyCardView basePath accountsPanelModel model post =
    let
        maybeServer =
            AccountsPanel.serverForHost accountsPanelModel.servers model.host

        maybeAccount =
            AccountsPanel.enabledAccountForServer accountsPanelModel.accounts model.host
    in
    div [ class "breadcrumb-reply-card" ]
        [ if isRoot model post then
            h1 [ class "breadcrumb-reply-card-title" ] [ text (Posts.postTitleText post) ]

          else
            text ""
        , div [ class "breadcrumb-reply-card-meta" ]
            [ Authors.link basePath accountsPanelModel.mainFrontendHost model.host maybeServer maybeAccount post.author
            , a
                [ href (Posts.postHref basePath accountsPanelModel.mainFrontendHost model.host post)
                , class "breadcrumb-reply-card-permalink"
                ]
                [ text "🔗" ]
            ]
        , case maybeServer of
            Just server ->
                MultiMediaRenderer.previewExtraSmall server maybeAccount (\_ -> NoOp) post.media

            Nothing ->
                text ""
        , case post.content of
            Just content ->
                Markdown.view [ class "breadcrumb-reply-card-content" ] content

            Nothing ->
                text ""
        ]
