module Components.MediaRenderer exposing (MediaSize(..), SizeConstraint(..), view)

{-| Renders a single `Proto.Jonline.MediaReference` -- an image, a video, or
(for anything else, e.g. a PDF) a browser-native `<object>` embed with a
download-link fallback for content types the browser can't render inline.

Takes a `Sizing` telling it how big to allow itself to get (see
`.media-renderer-*` in `media.css`) -- either way the media keeps its own
intrinsic aspect ratio (portrait, landscape, square, whatever); nothing here
ever stretches or crops it into a fixed box:

  - `Natural` caps it by the container's own width and a generous viewport-relative
    height (used for a post's single "focus" media item).
  - `Compact` instead caps both width and height to the same small square,
    so it ends up as narrow or as short as its own ratio calls for (used for
    every thumbnail in `Components.MultiMediaRenderer`'s scrolling strip and
    its `preview`).
  - `ExtraSmall` is the same width cap as `Compact`, just half its height --
    for contexts even tighter on vertical space than an ordinary preview
    (used by `Shared.StarredPanel`'s post rows, see
    `Components.MultiMediaRenderer.previewExtraSmall`).

Mirrors the Tamagui app's `media_renderer.tsx`, minus its social embed
providers (Twitter/Instagram/etc. -- those key off `Post.link`, not
`MediaReference`, and are handled one level up by the Tamagui
`PostMediaRenderer`; not ported here) and its `ReactPlayer` dependency for
video -- a plain HTML5 `<video controls>` covers the same MIME types Jonline
actually serves media as.

`onImageClicked` fires (with `media.id`) only for images -- videos keep their
existing native-`controls` click behavior untouched (see `Shared.MediaViewerPanel`,
the only caller today: tapping an image opens it fullscreen there; tapping a
video just plays/pauses/scrubs it in place, same as before that panel
existed).

-}

import Html exposing (Html, a, div, img, object, text, video)
import Html.Attributes exposing (alt, attribute, class, controls, href, src, target, type_)
import Html.Events exposing (onClick)
import Proto.Jonline exposing (MediaReference)
import Shared.AccountsPanel as AccountsPanel


type MediaSize
    = Natural
    | Small
    | ExtraSmall


{-| Which of an image/video's two dimensions (see `.media-renderer-to-*` in
`media.css`) gets scaled to its `Sizing`'s bound, with the other left free to
whatever its own aspect ratio calls for -- `ToWidthAndHeight` (the default
everywhere except `Components.MultiMediaRenderer`'s scrolling strip) instead
bounds both, same as before this type existed.
-}
type SizeConstraint
    = ToHeight
    | ToWidthAndHeight


view : MediaSize -> SizeConstraint -> AccountsPanel.Server -> Maybe AccountsPanel.Account -> (String -> msg) -> MediaReference -> Html msg
view mediaSize sizeConstraint server maybeAccount onImageClicked media =
    let
        mediaUrl =
            url mediaSize server maybeAccount media

        sizeClass =
            mediaSizeClass mediaSize ++ " " ++ sizeConstraintClass sizeConstraint
    in
    case String.split "/" media.contentType |> List.head |> Maybe.withDefault "" of
        "image" ->
            img
                [ class ("media-renderer-image " ++ sizeClass)
                , src mediaUrl
                , alt (Maybe.withDefault "" media.name)
                , onClick (onImageClicked media.id)
                , attribute "loading" "lazy"
                ]
                []

        "video" ->
            video
                [ class ("media-renderer-video " ++ sizeClass)
                , controls True
                , attribute "preload" "metadata"
                , src (mediaUrl ++ previewTimeFragment media)
                ]
                [ text "Your browser doesn't support embedded video." ]

        _ ->
            object [ class ("media-renderer-object " ++ sizeClass), attribute "data" mediaUrl, type_ media.contentType ]
                [ div [ class "media-renderer-fallback" ]
                    [ text ("Can't preview " ++ media.contentType ++ " here. ")
                    , a [ href mediaUrl, target "_blank" ] [ text "Download it instead." ]
                    ]
                ]


mediaSizeClass : MediaSize -> String
mediaSizeClass mediaSize =
    case mediaSize of
        Natural ->
            "media-renderer-natural"

        Small ->
            "media-renderer-small"

        ExtraSmall ->
            "media-renderer-extra-small"


sizeConstraintClass : SizeConstraint -> String
sizeConstraintClass sizeConstraint =
    case sizeConstraint of
        ToHeight ->
            "media-renderer-to-height"

        ToWidthAndHeight ->
            "media-renderer-to-width-and-height"


{-| A Media Fragments URI (`#t=<seconds>`) selecting the timestamp a `<video>` should show as its
preview/poster frame, per `media.metadata.videoPreviewTimeMs` -- empty (no fragment) if unset,
which leaves the browser's default first-frame preview in place. `npt-sec` (the fragment's time
format) is specified in whole-or-decimal seconds, so milliseconds are rendered as a fraction of a
second (1456ms -> "#t=1.456") rather than truncated to whole seconds.
-}
previewTimeFragment : MediaReference -> String
previewTimeFragment media =
    media.metadata
        |> Maybe.andThen .videoPreviewTimeMs
        |> Maybe.map (\ms -> "#t=" ++ String.fromFloat (toFloat ms / 1000))
        |> Maybe.withDefault ""


{-| Authorized URL for `media`, mirroring `Components.Users.mediaReferenceUrl`
-- media may be visibility-restricted, so this may still 403 for a
`maybeAccount` (or anonymous request) that isn't allowed to see it. `Natural`
sizing requests the server's larger rendition (`?size=large`) since it's used
for a post's single "focus" media item, rather than the server's default
size.
-}
url : MediaSize -> AccountsPanel.Server -> Maybe AccountsPanel.Account -> MediaReference -> String
url mediaSize server maybeAccount media =
    let
        base =
            AccountsPanel.mediaUrl server media.id |> Maybe.withDefault ""

        sizeParam =
            case mediaSize of
                Natural ->
                    [ "size=large" ]

                Small ->
                    []

                ExtraSmall ->
                    []

        authParam =
            case maybeAccount of
                Just account ->
                    [ "authorization=" ++ account.accessToken.token ]

                Nothing ->
                    []
    in
    case sizeParam ++ authParam of
        [] ->
            base

        params ->
            base ++ "?" ++ String.join "&" params
