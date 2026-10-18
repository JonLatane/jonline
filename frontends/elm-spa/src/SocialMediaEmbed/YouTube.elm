module SocialMediaEmbed.YouTube exposing (Embed, fromLink, srcOf, view)

{-| A YouTube video: `youtube.com/watch?v=…`, `/shorts/…`, `/embed/…`, `/live/…`, and `youtu.be/…`, with an
optional start time (`start=` or `t=`, as `90`, `90s` or `1m30s`). `react-social-media-embed`'s `YouTubeEmbed`
renders `react-youtube`'s player, which is this same iframe.
-}

import Html exposing (Html)
import SocialMediaEmbed.Common as Common exposing (Link)


type alias Embed =
    { videoId : String
    , startSeconds : Int
    , link : String
    }


fromLink : Link -> Maybe Embed
fromLink link =
    if Common.hostIs "youtu.be" link then
        link.segments |> List.head |> Maybe.andThen (embedFor link)

    else if Common.hostIs "youtube.com" link || Common.hostIs "youtube-nocookie.com" link then
        case Common.queryParam "v" link of
            Just videoId ->
                embedFor link videoId

            Nothing ->
                case link.segments of
                    [ kind, videoId ] ->
                        if List.member kind [ "shorts", "embed", "live", "v" ] then
                            embedFor link videoId

                        else
                            Nothing

                    _ ->
                        Nothing

    else
        Nothing


embedFor : Link -> String -> Maybe Embed
embedFor link videoId =
    if String.length videoId == 11 && Common.isSlug videoId then
        Just
            { videoId = videoId
            , startSeconds =
                [ Common.queryParam "start" link, Common.queryParam "t" link ]
                    |> List.filterMap (Maybe.andThen parseSeconds)
                    |> List.head
                    |> Maybe.withDefault 0
            , link = link.raw
            }

    else
        Nothing


{-| `90`, `90s`, `1m30s`, `1h2m3s`.
-}
parseSeconds : String -> Maybe Int
parseSeconds raw =
    if Common.isDigits raw then
        String.toInt raw

    else
        let
            step : Char -> ( Int, Maybe Int ) -> ( Int, Maybe Int )
            step c ( total, pending ) =
                if Char.isDigit c then
                    ( total, Just (Maybe.withDefault 0 pending * 10 + (Char.toCode c - Char.toCode '0')) )

                else
                    case ( c, pending ) of
                        ( 'h', Just n ) ->
                            ( total + n * 3600, Nothing )

                        ( 'm', Just n ) ->
                            ( total + n * 60, Nothing )

                        ( 's', Just n ) ->
                            ( total + n, Nothing )

                        _ ->
                            ( -1000000, Nothing )

            ( seconds, leftover ) =
                String.foldl step ( 0, Nothing ) (String.toLower raw)
        in
        if seconds >= 0 && leftover == Nothing && not (String.isEmpty raw) then
            Just seconds

        else
            Nothing


srcOf : Embed -> String
srcOf embed =
    "https://www.youtube.com/embed/"
        ++ embed.videoId
        ++ (if embed.startSeconds > 0 then
                "?start=" ++ String.fromInt embed.startSeconds

            else
                ""
           )


view : Embed -> Html msg
view embed =
    Common.frame
        { network = "youtube"
        , src = srcOf embed
        , title = "YouTube video"
        , maxWidth = 640
        , height = 360
        , ratio = Just ( 16, 9 )
        , linkUrl = embed.link
        , linkText = "Watch on YouTube"
        , allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
        }
