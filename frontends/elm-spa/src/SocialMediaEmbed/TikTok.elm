module SocialMediaEmbed.TikTok exposing (Embed, fromLink, srcOf, view)

{-| A TikTok video: `tiktok.com/@someone/video/{id}`. `TikTokEmbed` loads TikTok's `embed.js`, which swaps the
`blockquote` for TikTok's v2 player page -- `tiktok.com/embed/v2/{id}` -- which this embeds directly. (The
`vm.tiktok.com` short links carry no video id, so they can't be embedded without asking TikTok to resolve them.)
-}

import Html exposing (Html)
import SocialMediaEmbed.Common as Common exposing (Link)


type alias Embed =
    { videoId : String
    , link : String
    }


fromLink : Link -> Maybe Embed
fromLink link =
    if Common.hostIs "tiktok.com" link then
        case link.segments of
            [ user, "video", videoId ] ->
                if String.startsWith "@" user && Common.isDigits videoId then
                    Just { videoId = videoId, link = link.raw }

                else
                    Nothing

            [ "embed", "v2", videoId ] ->
                if Common.isDigits videoId then
                    Just { videoId = videoId, link = link.raw }

                else
                    Nothing

            _ ->
                Nothing

    else
        Nothing


srcOf : Embed -> String
srcOf embed =
    "https://www.tiktok.com/embed/v2/" ++ embed.videoId


view : Embed -> Html msg
view embed =
    Common.frame
        { network = "tiktok"
        , src = srcOf embed
        , title = "TikTok video"
        , maxWidth = 480
        , height = 739
        , ratio = Nothing
        , linkUrl = embed.link
        , linkText = "View post on TikTok"
        , allow = "autoplay; encrypted-media; fullscreen; picture-in-picture"
        }
