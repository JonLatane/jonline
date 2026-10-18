module SocialMediaEmbed.X exposing (Embed, fromLink, srcOf, view)

{-| A post on X (Twitter): `x.com/{user}/status/{id}` and the `twitter.com` equivalent (also `/i/web/status/{id}`
and trailing segments like `/photo/1`). `XEmbed` hands the id to `react-twitter-embed`, which loads X's
`widgets.js`; that builds the `platform.twitter.com/embed/Tweet.html` page this embeds directly.
-}

import Html exposing (Html)
import SocialMediaEmbed.Common as Common exposing (Link)


type alias Embed =
    { postId : String
    , link : String
    }


fromLink : Link -> Maybe Embed
fromLink link =
    if Common.hostIs "x.com" link || Common.hostIs "twitter.com" link then
        case idAfterStatus link.segments of
            Just postId ->
                Just { postId = postId, link = link.raw }

            Nothing ->
                Nothing

    else
        Nothing


idAfterStatus : List String -> Maybe String
idAfterStatus segments =
    case segments of
        marker :: id :: rest ->
            if (marker == "status" || marker == "statuses") && Common.isDigits id then
                Just id

            else
                idAfterStatus (id :: rest)

        _ ->
            Nothing


srcOf : Embed -> String
srcOf embed =
    "https://platform.twitter.com/embed/Tweet.html?dnt=true&frame=false&hideCard=false&hideThread=false&lang=en&theme=light&id="
        ++ embed.postId


view : Embed -> Html msg
view embed =
    Common.frame
        { network = "x"
        , src = srcOf embed
        , title = "Post on X"
        , maxWidth = 550
        , height = 350
        , ratio = Nothing
        , linkUrl = embed.link
        , linkText = "View post on X"
        , allow = "fullscreen"
        }
