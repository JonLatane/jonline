module Components.MediaRenderer exposing (Sizing(..), view)

{-| Renders a single `Proto.Jonline.MediaReference` -- an image, a video, or
(for anything else, e.g. a PDF) a browser-native `<object>` embed with a
download-link fallback for content types the browser can't render inline.

Takes a `Sizing` telling it how to fit itself into its container (see
`.media-renderer-*` in `media.css`):

  - `Fill` stretches to `width`/`height: 100%` of the container, which is
    expected to already have the desired box dimensions (e.g. a fixed-size
    thumbnail in `Components.MultiMediaRenderer`'s scrolling strip).
  - `Natural` instead lets the media keep its own intrinsic aspect ratio,
    capped by `max-width`/`max-height` (used for a post's single "focus"
    media item, which shouldn't be squashed into a fixed box).

Mirrors the Tamagui app's `media_renderer.tsx`, minus its social embed
providers (Twitter/Instagram/etc. -- those key off `Post.link`, not
`MediaReference`, and are handled one level up by the Tamagui
`PostMediaRenderer`; not ported here) and its `ReactPlayer` dependency for
video -- a plain HTML5 `<video controls>` covers the same MIME types Jonline
actually serves media as.

-}

import Html exposing (Html, a, div, img, object, text, video)
import Html.Attributes exposing (alt, attribute, class, controls, href, src, target, type_)
import Proto.Jonline exposing (MediaReference)
import Shared.AccountsPanel as AccountsPanel


type Sizing
    = Fill
    | Natural


sizingClass : Sizing -> String
sizingClass sizing =
    case sizing of
        Fill ->
            "media-renderer-fill"

        Natural ->
            "media-renderer-natural"


view : Sizing -> AccountsPanel.Server -> Maybe AccountsPanel.Account -> MediaReference -> Html msg
view sizing server maybeAccount media =
    let
        mediaUrl =
            url server maybeAccount media

        sizeClass =
            sizingClass sizing
    in
    case String.split "/" media.contentType |> List.head |> Maybe.withDefault "" of
        "image" ->
            img [ class ("media-renderer-image " ++ sizeClass), src mediaUrl, alt (Maybe.withDefault "" media.name) ] []

        "video" ->
            video [ class ("media-renderer-video " ++ sizeClass), controls True, src mediaUrl ]
                [ text "Your browser doesn't support embedded video." ]

        _ ->
            object [ class ("media-renderer-object " ++ sizeClass), attribute "data" mediaUrl, type_ media.contentType ]
                [ div [ class "media-renderer-fallback" ]
                    [ text ("Can't preview " ++ media.contentType ++ " here. ")
                    , a [ href mediaUrl, target "_blank" ] [ text "Download it instead." ]
                    ]
                ]


{-| Authorized URL for `media`, mirroring `Components.Users.mediaReferenceUrl`
-- media may be visibility-restricted, so this may still 403 for a
`maybeAccount` (or anonymous request) that isn't allowed to see it.
-}
url : AccountsPanel.Server -> Maybe AccountsPanel.Account -> MediaReference -> String
url server maybeAccount media =
    let
        base =
            AccountsPanel.mediaUrl server media.id
    in
    case maybeAccount of
        Just account ->
            base ++ "?authorization=" ++ account.accessToken.token

        Nothing ->
            base
