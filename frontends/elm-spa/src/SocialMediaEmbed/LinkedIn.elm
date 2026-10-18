module SocialMediaEmbed.LinkedIn exposing (Embed, fromLink, srcOf, view)

{-| A LinkedIn post. `LinkedInEmbed` takes LinkedIn's own embed URL (from a post's "Embed this post" menu,
`linkedin.com/embed/feed/update/urn:li:share:…`) and iframes it as-is; that works here too, and so do the
ordinary links people actually copy -- `linkedin.com/feed/update/urn:li:activity:…` and
`linkedin.com/posts/someone_title-activity-123-xyz` -- which carry the same post id.
-}

import Html exposing (Html)
import SocialMediaEmbed.Common as Common exposing (Link)


type alias Embed =
    { urn : String
    , link : String
    }


fromLink : Link -> Maybe Embed
fromLink link =
    if Common.hostIs "linkedin.com" link then
        case link.segments of
            "embed" :: "feed" :: "update" :: urn :: _ ->
                validUrn urn |> Maybe.map (embedFor link)

            "feed" :: "update" :: urn :: _ ->
                validUrn urn |> Maybe.map (embedFor link)

            [ "posts", slug ] ->
                urnFromSlug slug |> Maybe.map (embedFor link)

            _ ->
                Nothing

    else
        Nothing


embedFor : Link -> String -> Embed
embedFor link urn =
    { urn = urn, link = link.raw }


{-| `urn:li:{share|ugcPost|activity}:{digits}`.
-}
validUrn : String -> Maybe String
validUrn urn =
    case String.split ":" urn of
        [ "urn", "li", kind, id ] ->
            if List.member kind [ "share", "ugcPost", "activity" ] && Common.isDigits id then
                Just urn

            else
                Nothing

        _ ->
            Nothing


{-| `someone_post-title-activity-7012345678901234567-AbCd` -- the post id follows `activity`/`share`/`ugcPost`.
-}
urnFromSlug : String -> Maybe String
urnFromSlug slug =
    let
        go : List String -> Maybe String
        go parts =
            case parts of
                kind :: id :: rest ->
                    if List.member kind [ "activity", "share", "ugcPost" ] && Common.isDigits id then
                        Just ("urn:li:" ++ kind ++ ":" ++ id)

                    else
                        go (id :: rest)

                _ ->
                    Nothing
    in
    go (String.split "-" slug)


srcOf : Embed -> String
srcOf embed =
    "https://www.linkedin.com/embed/feed/update/" ++ embed.urn


view : Embed -> Html msg
view embed =
    Common.frame
        { network = "linkedin"
        , src = srcOf embed
        , title = "LinkedIn post"
        , maxWidth = 550
        , height = 500
        , ratio = Nothing
        , linkUrl = embed.link
        , linkText = "View post on LinkedIn"
        , allow = "fullscreen; picture-in-picture"
        }
