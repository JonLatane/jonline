module Components.PostMediaRenderer exposing (view)

{-| Renders a `Post`'s `media` as a horizontally-scrolling strip of
`Components.MediaRenderer`s (`.post-media-strip`/`.post-media-item` in
`style.css`, the same horizontal-scroll pattern as the Accounts Panel's
`.servers-strip`). Mirrors the Tamagui app's `post_media_renderer.tsx`, minus
its embed-link (Twitter/Instagram/etc., which key off `Post.link` rather than
`Post.media`) and "single full-width preview vs. scrollable strip" branching
-- every Post with any media just gets the same simple strip here; a lone
item still sits in a strip, just one that (usually) won't overflow enough to
actually need to scroll.
-}

import Components.MediaRenderer as MediaRenderer
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Proto.Jonline exposing (MediaReference)
import Shared.AccountsPanel as AccountsPanel


view : AccountsPanel.Server -> Maybe AccountsPanel.Account -> List MediaReference -> Html msg
view server maybeAccount media =
    if List.isEmpty media then
        text ""

    else
        div [ class "post-media-strip" ]
            (media
                |> List.map
                    (\mediaRef ->
                        div [ class "post-media-item" ] [ MediaRenderer.view server maybeAccount mediaRef ]
                    )
            )
