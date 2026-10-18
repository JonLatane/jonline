module SocialMediaEmbed.Facebook exposing (Embed, fromLink, srcOf, view)

{-| A Facebook post, photo or video. `FacebookEmbed` loads Facebook's SDK and has it replace a `.fb-post` element
with the "post plugin" iframe; this embeds that plugin page directly (`plugins/post.php`, or `plugins/video.php`
for videos and reels). Only links that point at a piece of content are embedded -- a page or profile URL has
nothing for the plugin to show.
-}

import Html exposing (Html)
import SocialMediaEmbed.Common as Common exposing (Link)
import Url


type Kind
    = Post
    | Video


type alias Embed =
    { kind : Kind
    , href : String
    }


fromLink : Link -> Maybe Embed
fromLink link =
    if Common.hostIs "facebook.com" link || Common.hostIs "fb.com" link then
        kindOf link
            |> Maybe.map (\kind -> { kind = kind, href = canonicalHref link })

    else
        Nothing


kindOf : Link -> Maybe Kind
kindOf link =
    let
        has : String -> Bool
        has segment =
            List.member segment link.segments
    in
    if has "videos" || has "reel" || has "reels" then
        Just Video

    else if has "watch" then
        if Common.queryParam "v" link /= Nothing then
            Just Video

        else
            Nothing

    else if has "posts" || has "photos" || has "photo" || has "permalink" || has "activity" then
        Just Post

    else if has "share" then
        -- facebook.com/share/p/…, /share/v/…, /share/r/…
        case Common.allSegmentsAfter "share" link.segments of
            Just ("v" :: _ :: _) ->
                Just Video

            Just ("r" :: _ :: _) ->
                Just Video

            Just (_ :: _ :: _) ->
                Just Post

            _ ->
                Nothing

    else if List.member (List.head link.segments |> Maybe.withDefault "") [ "story.php", "photo.php", "permalink.php" ] then
        if Common.queryParam "story_fbid" link /= Nothing || Common.queryParam "fbid" link /= Nothing then
            Just Post

        else
            Nothing

    else
        Nothing


{-| The link as `https://www.facebook.com/…`: the same path (a trailing slash can matter: `/watch/?v=…`) and query
(a `story.php` link is nothing without it), on Facebook's canonical host, minus any `#fragment`.
-}
canonicalHref : Link -> String
canonicalHref link =
    let
        afterHost : String
        afterHost =
            link.raw
                |> String.split "://"
                |> List.drop 1
                |> String.join "://"
                |> String.split "/"
                |> List.drop 1
                |> String.join "/"
                |> String.split "#"
                |> List.head
                |> Maybe.withDefault ""
    in
    "https://www.facebook.com/" ++ afterHost


srcOf : Embed -> String
srcOf embed =
    "https://www.facebook.com/plugins/"
        ++ (case embed.kind of
                Post ->
                    "post.php"

                Video ->
                    "video.php"
           )
        ++ "?href="
        ++ Url.percentEncode embed.href
        ++ "&show_text=true&width=550"


view : Embed -> Html msg
view embed =
    Common.frame
        { network = "facebook"
        , src = srcOf embed
        , title = "Facebook post"
        , maxWidth = 550
        , height = 500
        , ratio = Nothing
        , linkUrl = embed.href
        , linkText = "View post on Facebook"
        , allow = "autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
        }
