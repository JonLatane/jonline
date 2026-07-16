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
import Html.Events exposing (onClick)
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
    }


init : Model
init =
    { media = [], currentMediaReference = Nothing, maybePost = Nothing, targetHost = "" }


type Msg
    = Open Post String String
    | SetCurrent String
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
            }

        SetCurrent id ->
            case validCurrent model.media id of
                Just validId ->
                    { model | currentMediaReference = Just validId }

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

        navButton classNames msg label =
            button [ classes ("media-viewer-panel-nav" :: classNames), onClick msg ] [ text label ]
    in
    div [ classes [ "media-viewer-panel", "nav-panel", openClosedClass (isOpen model) ] ]
        [ div [ class "media-viewer-panel-header" ] indexLabel
        , div [ class "media-viewer-panel-content" ]
            [ case ( currentMedia, maybeServer ) of
                ( Just media, Just server ) ->
                    MediaRenderer.view MediaRenderer.Natural server maybeAccount SetCurrent media

                _ ->
                    text ""
            ]
        , div [ class "media-viewer-panel-toolbar" ]
            [ case adjacent -1 model of
                Just prevMedia ->
                    navButton [ "media-viewer-panel-prev" ] (SetCurrent prevMedia.id) "‹"

                Nothing ->
                    text ""
            , div [ class "media-viewer-panel-post-title" ]
                [ text (model.maybePost |> Maybe.map Posts.postTitleText |> Maybe.withDefault "") ]
            , case adjacent 1 model of
                Just nextMedia ->
                    navButton [ "media-viewer-panel-next" ] (SetCurrent nextMedia.id) "›"

                Nothing ->
                    text ""
            , button [ class "media-viewer-panel-close", onClick CloseClicked ] [ text "✕" ]
            ]
        ]
