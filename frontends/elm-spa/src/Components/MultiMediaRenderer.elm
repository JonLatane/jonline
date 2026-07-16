module Components.MultiMediaRenderer exposing (preview, view)

{-| Renders a `Post`'s `media`. A single item (the common case) is the
"focus" of the post, so it's rendered big -- at its own inherent aspect
ratio (portrait, landscape, square, whatever), capped by reasonable bounds
rather than squashed into a fixed box (`.multi-media-single`/
`.multi-media-single-item` in `media.css`, `Components.MediaRenderer`'s
`Natural` sizing). Multiple items instead get a horizontally-scrolling strip
of fixed-size thumbnails (`.multi-media-strip`/`.multi-media-item`, the same
horizontal-scroll pattern as the Accounts Panel's `.servers-strip`,
`Components.MediaRenderer`'s `Fill` sizing). Mirrors the Tamagui app's
`post_media_renderer.tsx`, minus its embed-link (Twitter/Instagram/etc.,
which key off `Post.link` rather than `Post.media`) handling.
-}

import Components.MediaRenderer as MediaRenderer
import Html exposing (Html, div, text)
import Proto.Jonline exposing (MediaReference)
import Shared.AccountsPanel as AccountsPanel
import UI.Classes exposing (classes)


view : AccountsPanel.Server -> Maybe AccountsPanel.Account -> List MediaReference -> Html msg
view server maybeAccount media =
    render False server maybeAccount media


{-| Same single-item-vs-scrolling-strip layout as `view`, just shorter (see
`.multi-media-preview` in `media.css`, layered onto `.multi-media-single`/
`.multi-media-strip`'s own classes) -- used in the middle of
`Components.PostCard.postCard`'s compact rendering, where a post's full-size
"focus" media would dominate the card. The single-item case also switches
from `view`'s `MediaRenderer.Natural` (own aspect ratio, capped by
`max-height`) to `MediaRenderer.Fill` (stretched to the fixed preview height,
same as every strip thumbnail already gets) -- `.multi-media-preview`'s fixed
height wouldn't otherwise cap a `Natural`-sized item at all.

Left `pointer-events: auto` (see `.multi-media-preview`'s own doc comment) so
a video preview's native `controls` are directly clickable/playable rather
than falling through to `postCard`'s `.post-card-link-overlay` like
`.post-card-meta`'s plain text does.
-}
preview : AccountsPanel.Server -> Maybe AccountsPanel.Account -> List MediaReference -> Html msg
preview server maybeAccount media =
    render True server maybeAccount media


render : Bool -> AccountsPanel.Server -> Maybe AccountsPanel.Account -> List MediaReference -> Html msg
render isPreview server maybeAccount media =
    let
        previewClasses =
            if isPreview then
                [ "multi-media-preview" ]

            else
                []
    in
    case media of
        [] ->
            text ""

        [ single ] ->
            div [ classes ("multi-media-single" :: previewClasses) ]
                [ div [ classes ("multi-media-single-item" :: previewClasses) ]
                    [ MediaRenderer.view
                        (if isPreview then
                            MediaRenderer.Fill

                         else
                            MediaRenderer.Natural
                        )
                        server
                        maybeAccount
                        single
                    ]
                ]

        _ ->
            div [ classes ("multi-media-strip" :: previewClasses) ]
                (media
                    |> List.map
                        (\mediaRef ->
                            div [ classes ("multi-media-item" :: previewClasses) ]
                                [ MediaRenderer.view MediaRenderer.Fill server maybeAccount mediaRef ]
                        )
                )
