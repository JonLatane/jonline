module SocialMediaEmbed.Instagram exposing (Embed, fromLink, srcOf, view)

{-| An Instagram post, reel or IGTV video: `instagram.com/p/…`, `/reel/…`, `/tv/…`, each also with a username
in front (`/someone/p/…`), as `InstagramEmbed` strips. Instagram's `embed.js` turns the post's `blockquote` into
the `…/embed/captioned/` page; this embeds that page directly.
-}

import Html exposing (Html)
import SocialMediaEmbed.Common as Common exposing (Link)


type Kind
    = Post
    | Reel
    | Tv


type alias Embed =
    { kind : Kind
    , shortcode : String
    , link : String
    }


fromLink : Link -> Maybe Embed
fromLink link =
    if Common.hostIs "instagram.com" link then
        case link.segments of
            [ kind, shortcode ] ->
                embedFor link kind shortcode

            [ _, kind, shortcode ] ->
                embedFor link kind shortcode

            _ ->
                Nothing

    else
        Nothing


embedFor : Link -> String -> String -> Maybe Embed
embedFor link kindSegment shortcode =
    if Common.isSlug shortcode then
        (case kindSegment of
            "p" ->
                Just Post

            "reel" ->
                Just Reel

            "reels" ->
                Just Reel

            "tv" ->
                Just Tv

            _ ->
                Nothing
        )
            |> Maybe.map (\kind -> { kind = kind, shortcode = shortcode, link = link.raw })

    else
        Nothing


srcOf : Embed -> String
srcOf embed =
    "https://www.instagram.com/"
        ++ (case embed.kind of
                Post ->
                    "p"

                Reel ->
                    "reel"

                Tv ->
                    "tv"
           )
        ++ "/"
        ++ embed.shortcode
        ++ "/embed/captioned/"


view : Embed -> Html msg
view embed =
    Common.frame
        { network = "instagram"
        , src = srcOf embed
        , title = "Instagram post"
        , maxWidth = 540
        , height = 600
        , ratio = Nothing
        , linkUrl = embed.link
        , linkText = "View post on Instagram"
        , allow = "encrypted-media; fullscreen; picture-in-picture"
        }
