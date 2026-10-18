module SocialMediaEmbed.Pinterest exposing (Embed, fromLink, srcOf, view)

{-| A Pinterest pin: `pinterest.com/pin/{id}` (any Pinterest country domain, and any suffix such as
`/sent/?invite_code=…`). `PinterestEmbed` iframes `assets.pinterest.com/ext/embed.html?id={id}`, as this does.
-}

import Html exposing (Html)
import SocialMediaEmbed.Common as Common exposing (Link)


type alias Embed =
    { pinId : String
    , link : String
    }


fromLink : Link -> Maybe Embed
fromLink link =
    if isPinterestHost link.host then
        case Common.allSegmentsAfter "pin" link.segments of
            Just (pinId :: _) ->
                if Common.isSlug pinId then
                    Just { pinId = pinId, link = link.raw }

                else
                    Nothing

            _ ->
                Nothing

    else
        Nothing


{-| `pinterest.com`, `uk.pinterest.com`, `pinterest.co.uk`, `pinterest.de`, ... -- "pinterest" as the registrable name,
before a country-code or `co`/`com` + country-code suffix. Never `pinterest.someone-else.example`.
-}
isPinterestHost : String -> Bool
isPinterestHost host =
    case host |> String.split "." |> List.reverse of
        _ :: "pinterest" :: _ ->
            True

        _ :: second :: "pinterest" :: _ ->
            -- pinterest.co.uk, pinterest.com.au
            second == "co" || second == "com"

        _ ->
            False


srcOf : Embed -> String
srcOf embed =
    "https://assets.pinterest.com/ext/embed.html?id=" ++ embed.pinId


view : Embed -> Html msg
view embed =
    Common.frame
        { network = "pinterest"
        , src = srcOf embed
        , title = "Pinterest pin"
        , maxWidth = 550
        , height = 500
        , ratio = Nothing
        , linkUrl = embed.link
        , linkText = "View post on Pinterest"
        , allow = "fullscreen"
        }
