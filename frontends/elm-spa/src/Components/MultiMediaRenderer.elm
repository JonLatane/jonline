module Components.MultiMediaRenderer exposing (preview, previewExtraSmall, view)

{-| Renders a `Post`'s `media`. A single item (the common case) is the
"focus" of the post, so it's rendered big -- at its own inherent aspect
ratio (portrait, landscape, square, whatever), capped by reasonable bounds
rather than squashed into a fixed box (`.multi-media-single`/
`.multi-media-single-item` in `media.css`, `Components.MediaRenderer`'s
`Natural` sizing). Multiple items instead get a horizontally-scrolling strip
(`.multi-media-strip`/`.multi-media-item`, the same horizontal-scroll pattern
as the Accounts Panel's `.servers-strip`) of thumbnails, each still at its
own aspect ratio, just capped to a small square (`Components.MediaRenderer`'s
`Compact` sizing) rather than stretched/cropped to a fixed size. Mirrors the
Tamagui app's `post_media_renderer.tsx`, minus its embed-link
(Twitter/Instagram/etc., which key off `Post.link` rather than `Post.media`)
handling.
-}

import Components.MediaRenderer as MediaRenderer
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Proto.Jonline exposing (MediaReference)
import Shared.AccountsPanel as AccountsPanel
import UI.Classes exposing (classes)


view : AccountsPanel.Server -> Maybe AccountsPanel.Account -> List MediaReference -> Html msg
view server maybeAccount media =
    render Nothing server maybeAccount media


{-| Same single-item-vs-scrolling-strip layout as `view`, just tighter
margins to fit in the middle of `Components.PostCard.postCard`'s compact
rendering (see `.multi-media-preview` in `media.css`, layered onto
`.multi-media-single`/`.multi-media-strip`'s own classes) -- and, for the
single-item case, `Compact` rather than `Natural` sizing (same as every
strip thumbnail already gets), since a post's full-size "focus" media would
dominate the card.

Left `pointer-events: auto` (see `.multi-media-preview`'s own doc comment) so
a video preview's native `controls` are directly clickable/playable rather
than falling through to `postCard`'s `.post-card-link-overlay` like
`.post-card-meta`'s plain text does.

-}
preview : AccountsPanel.Server -> Maybe AccountsPanel.Account -> List MediaReference -> Html msg
preview server maybeAccount media =
    render (Just MediaRenderer.Small) server maybeAccount media


{-| Same as `preview`, just with `MediaRenderer.ExtraSmall` sizing (half the
height of `preview`'s usual `Small`) -- for contexts even tighter on vertical
space than an ordinary post card, e.g. `Shared.StarredPostsPanel`'s post rows.
-}
previewExtraSmall : AccountsPanel.Server -> Maybe AccountsPanel.Account -> List MediaReference -> Html msg
previewExtraSmall server maybeAccount media =
    render (Just MediaRenderer.ExtraSmall) server maybeAccount media


{-| `Nothing` renders full-size (`view`); `Just sizing` renders as a preview
(`.multi-media-preview` layout) at `sizing`, used for both the single-item
case and every thumbnail in the scrolling strip.
-}
render : Maybe MediaRenderer.Sizing -> AccountsPanel.Server -> Maybe AccountsPanel.Account -> List MediaReference -> Html msg
render previewSizing server maybeAccount media =
    let
        previewClasses =
            case previewSizing of
                Just _ ->
                    [ "multi-media-preview" ]

                Nothing ->
                    []

        singleSizing =
            Maybe.withDefault MediaRenderer.Natural previewSizing

        stripSizing =
            Maybe.withDefault MediaRenderer.Small previewSizing
    in
    case media of
        [] ->
            text ""

        [ single ] ->
            div [ classes ("multi-media-single" :: previewClasses) ]
                [ div [ class "multi-media-single-item" ]
                    [ MediaRenderer.view singleSizing server maybeAccount single ]
                ]

        _ ->
            div [ classes ("multi-media-strip" :: previewClasses) ]
                (media
                    |> List.map
                        (\mediaRef ->
                            div [ class "multi-media-item" ]
                                [ MediaRenderer.view stripSizing server maybeAccount mediaRef ]
                        )
                )
