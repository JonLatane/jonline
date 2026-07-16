module Shared.MediaViewerPanel exposing (Model, Msg(..), init, isOpen, update, view)

{-| A single, app-wide fullscreen image/video viewer -- an alternate,
"big"/fullscreen rendering of a `Post`'s `media` (compare
`Components.MultiMediaRenderer`'s compact card/detail previews), with a
"current" item the user can page through, like a carousel. One shared
instance, opened from wherever a `Post`'s media is tapped (`Pages.Home_`,
`Pages.Post.PostId_`, `Shared.StarredPostsPanel`) rather than each caller
owning its own viewer state, same reasoning as `Shared.MarkdownPanel`.

Doesn't need `AccountsPanel.Model` in `update` (no RPCs to make, nothing to
forward -- see `Shared.AdminPanel` for the same minimal shape); `view` still
takes it, to resolve `targetHost` into the `Server`/`Account` needed to build
each media item's URL, the same way `Components.MultiMediaRenderer`'s callers
do.

-}

import Components.MediaRenderer as MediaRenderer
import Components.PostCard as Posts
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick, stopPropagationOn)
import Html.Keyed
import Json.Decode as Decode
import Proto.Jonline exposing (MediaReference, Post)
import Shared.AccountsPanel as AccountsPanel
import UI.Classes exposing (classes, openClosedClass)


type alias Model =
    { media : List MediaReference
    , currentMediaReference : Maybe String

    -- The Post this media came from -- every caller opens this panel from a
    -- Post today (see `Open`), and its title is shown in the bottom toolbar
    -- (see `view`).
    , maybePost : Maybe Post

    -- Needed to resolve `view`'s `AccountsPanel.Model` down to the actual
    -- `Server`/`Account` the tapped Post's media belongs to -- same
    -- `targetHost` convention `Shared.MarkdownPanel` uses.
    , targetHost : String

    -- Which way the *last* `Next`/`Prev` paged, purely to pick a slide
    -- direction in `view` (see `directionClass`) -- has no bearing on
    -- `currentMediaReference` itself. Reset to `Entering` on every fresh
    -- `Open`, so the first image of a newly-opened post just fades in rather
    -- than sliding in from whatever direction the previous post's viewing
    -- happened to leave behind.
    , direction : Direction
    }


{-| See `Model.direction`'s doc.
-}
type Direction
    = Entering
    | Forward
    | Backward


init : Model
init =
    { media = [], currentMediaReference = Nothing, maybePost = Nothing, targetHost = "", direction = Entering }


type Msg
    = Open Post String String
    | SetCurrent String
    | Next
    | Prev
    | CloseClicked


{-| Whether the panel is currently open -- driving `openClosedClass` and
`UI.elm`'s `sharedBackdrop`, same as `MarkdownPanel`'s `target /= Nothing`.
-}
isOpen : Model -> Bool
isOpen model =
    model.currentMediaReference /= Nothing


{-| A `MediaReference.id` from `media`, if it's actually in `media` -- refuses
any id that isn't, so `currentMediaReference` can never point at an item the
panel wasn't given (a stale id left over from `SetCurrent`, or a caller
passing the wrong list/id pair to `Open`).
-}
validCurrent : List MediaReference -> String -> Maybe String
validCurrent media id =
    if List.any (\m -> m.id == id) media then
        Just id

    else
        Nothing


update : Msg -> Model -> Model
update msg model =
    case msg of
        Open post initialId host ->
            { media = post.media
            , currentMediaReference = validCurrent post.media initialId
            , maybePost = Just post
            , targetHost = host
            , direction = Entering
            }

        SetCurrent id ->
            case validCurrent model.media id of
                Just validId ->
                    { model | currentMediaReference = Just validId }

                Nothing ->
                    model

        Next ->
            case adjacent 1 model of
                Just nextMedia ->
                    { model | currentMediaReference = Just nextMedia.id, direction = Forward }

                Nothing ->
                    model

        Prev ->
            case adjacent -1 model of
                Just prevMedia ->
                    { model | currentMediaReference = Just prevMedia.id, direction = Backward }

                Nothing ->
                    model

        CloseClicked ->
            init


indexOf : String -> List MediaReference -> Maybe Int
indexOf id media =
    media
        |> List.indexedMap Tuple.pair
        |> List.filter (\( _, m ) -> m.id == id)
        |> List.head
        |> Maybe.map Tuple.first


getAt : Int -> List MediaReference -> Maybe MediaReference
getAt index media =
    media |> List.drop index |> List.head


{-| The item before/after the current one in `media`, wrapping around --
`Nothing` if `media` has one item or fewer (nothing to page to).
-}
adjacent : Int -> Model -> Maybe MediaReference
adjacent offset model =
    let
        count =
            List.length model.media
    in
    if count < 2 then
        Nothing

    else
        model.currentMediaReference
            |> Maybe.andThen (\id -> indexOf id model.media)
            |> Maybe.andThen (\index -> getAt (modBy count (index + offset)) model.media)


view : AccountsPanel.Model -> Model -> Html Msg
view accountsPanelModel model =
    let
        currentMedia =
            model.currentMediaReference
                |> Maybe.andThen (\id -> List.filter (\m -> m.id == id) model.media |> List.head)

        maybeServer =
            AccountsPanel.serverForHost accountsPanelModel.servers model.targetHost

        maybeAccount =
            AccountsPanel.enabledAccountForServer accountsPanelModel.accounts model.targetHost

        indexLabel =
            case ( model.currentMediaReference |> Maybe.andThen (\id -> indexOf id model.media), List.length model.media ) of
                ( Just index, count ) ->
                    if count > 1 then
                        [ span [ class "media-viewer-panel-index" ] [ text (String.fromInt (index + 1) ++ " / " ++ String.fromInt count) ] ]

                    else
                        []

                _ ->
                    []

        -- This panel's own root below carries the background-tap-to-close
        -- `onClick` (it's its own backdrop -- see media_viewer_panel.css's
        -- doc comment), so every *real* control needs to stop a click from
        -- bubbling back up to it -- otherwise paging/closing via a button, or
        -- just tapping the media itself, would also immediately re-close the
        -- whole panel. `stopClick` is `onClick` plus that guard.
        stopClick msg =
            stopPropagationOn "click" (Decode.succeed ( msg, True ))

        navButton classNames msg label =
            button [ classes ("media-viewer-panel-nav" :: classNames), stopClick msg ] [ text label ]
    in
    div
        [ classes [ "media-viewer-panel", "nav-panel", openClosedClass (isOpen model) ]
        , onClick CloseClicked
        ]
        [ div [ class "media-viewer-panel-header" ] indexLabel
        , div [ class "media-viewer-panel-content" ]
            [ case ( currentMedia, maybeServer ) of
                ( Just media, Just server ) ->
                    -- Keyed on `media.id` so paging to a different item swaps
                    -- in a brand-new DOM node rather than patching the old
                    -- `<img>`/`<video>`'s attributes in place -- that fresh
                    -- insertion is what lets `directionClass`'s CSS animation
                    -- (media_viewer_panel.css) actually play on every page,
                    -- the same trick `Shared.StarredPostsPanel`'s
                    -- `Html.Keyed` list uses for its own enter animation.
                    Html.Keyed.node "div"
                        [ class "media-viewer-panel-media-stage" ]
                        [ ( media.id
                          , div
                                [ classes [ "media-viewer-panel-media", directionClass model.direction ]
                                , stopClick (SetCurrent media.id)
                                ]
                                [ MediaRenderer.view MediaRenderer.Natural server maybeAccount SetCurrent media ]
                          )
                        ]

                _ ->
                    text ""
            ]
        , div [ class "media-viewer-panel-toolbar" ]
            [ case adjacent -1 model of
                Just _ ->
                    navButton [ "media-viewer-panel-prev" ] Prev "‹"

                Nothing ->
                    text ""
            , div [ class "media-viewer-panel-post-title", stopClick CloseClicked ]
                [ text (model.maybePost |> Maybe.map Posts.postTitleText |> Maybe.withDefault "") ]
            , case adjacent 1 model of
                Just _ ->
                    navButton [ "media-viewer-panel-next" ] Next "›"

                Nothing ->
                    text ""
            , button [ class "media-viewer-panel-close", stopClick CloseClicked ] [ text "✕" ]
            ]
        ]


{-| CSS animation to play for the media stage's freshly-keyed node (see
`view`) -- a directional slide for `Next`/`Prev`, a plain fade for a fresh
`Open`. Matched to `.media-viewer-panel-media-*` in media_viewer_panel.css.
-}
directionClass : Direction -> String
directionClass direction =
    case direction of
        Entering ->
            "media-viewer-panel-media-entering"

        Forward ->
            "media-viewer-panel-media-forward"

        Backward ->
            "media-viewer-panel-media-backward"
