module Components.MultiMediaRenderer exposing (view)

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
import Html.Attributes exposing (class)
import Proto.Jonline exposing (MediaReference)
import Shared.AccountsPanel as AccountsPanel


view : AccountsPanel.Server -> Maybe AccountsPanel.Account -> List MediaReference -> Html msg
view server maybeAccount media =
    case media of
        [] ->
            text ""

        [ single ] ->
            div [ class "multi-media-single" ]
                [ div [ class "multi-media-single-item" ]
                    [ MediaRenderer.view MediaRenderer.Natural server maybeAccount single ]
                ]

        _ ->
            div [ class "multi-media-strip" ]
                (media
                    |> List.map
                        (\mediaRef ->
                            div [ class "multi-media-item" ]
                                [ MediaRenderer.view MediaRenderer.Fill server maybeAccount mediaRef ]
                        )
                )
