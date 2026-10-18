module SocialMediaEmbed.Common exposing
    ( Frame
    , Link
    , allSegmentsAfter
    , frame
    , hostIs
    , isDigits
    , isSlug
    , parseLink
    , queryParam
    )

{-| What every network's embed in `SocialMediaEmbed` shares: a forgiving parse of a pasted link, and the
common shape every embed has.

That shape follows `react-social-media-embed` (<https://github.com/justinmahar/react-social-media-embed>):
a bordered, rounded, `overflow: hidden` box (`.rsme-embed`) holding the embedded post, with a placeholder under it
-- a "View post on …" link and a spinner -- that shows until the post has loaded (and stays, as a plain link, if
it never does: the site is blocked, the post is gone, ...). Where the React library injects each network's own
script and lets it build the embed, these build the very iframe those scripts end up creating -- so there is no
third-party script on the page, only the network's own embed page inside a sandboxed `<iframe>`.

Heights are fixed here, as a starting point; `index.html`'s `message` listener resizes an iframe to what the embed
reports (Instagram and X do), standing in for the React library's own resize handling.

-}

import Html exposing (Html, a, div, iframe, span, text)
import Html.Attributes exposing (attribute, class, href, rel, src, style, target, title)
import Url


{-| A link, picked apart. `host` is lowercased with any leading `www.` removed; `segments` are the path's
non-empty segments (percent-decoded); `raw` is the link as an absolute `http(s)` URL.
-}
type alias Link =
    { raw : String
    , host : String
    , segments : List String
    , query : List ( String, String )
    }


{-| Accepts what people paste: a full URL, or one with no scheme (`youtu.be/abc`). `Nothing` for anything that
isn't a web address.
-}
parseLink : String -> Maybe Link
parseLink rawLink =
    let
        trimmed : String
        trimmed =
            String.trim rawLink
    in
    if String.isEmpty trimmed || String.contains " " trimmed || String.startsWith "/" trimmed then
        Nothing

    else
        let
            withScheme : String
            withScheme =
                if String.startsWith "http://" trimmed || String.startsWith "https://" trimmed then
                    trimmed

                else
                    "https://" ++ trimmed
        in
        Url.fromString withScheme
            |> Maybe.andThen
                (\url ->
                    let
                        host : String
                        host =
                            url.host |> String.toLower |> dropWww
                    in
                    if String.contains "." host then
                        Just
                            { raw = withScheme
                            , host = host
                            , segments =
                                url.path
                                    |> String.split "/"
                                    |> List.filter (not << String.isEmpty)
                                    |> List.map (\segment -> Url.percentDecode segment |> Maybe.withDefault segment)
                            , query = url.query |> Maybe.map parseQuery |> Maybe.withDefault []
                            }

                    else
                        Nothing
                )


dropWww : String -> String
dropWww host =
    if String.startsWith "www." host then
        String.dropLeft 4 host

    else
        host


parseQuery : String -> List ( String, String )
parseQuery query =
    query
        |> String.split "&"
        |> List.filterMap
            (\pair ->
                case String.split "=" pair of
                    key :: valueParts ->
                        if String.isEmpty key then
                            Nothing

                        else
                            let
                                value : String
                                value =
                                    String.join "=" valueParts |> String.replace "+" " "
                            in
                            Just ( key, Url.percentDecode value |> Maybe.withDefault value )

                    [] ->
                        Nothing
            )


{-| Whether the link is on `domain` or a subdomain of it (`m.youtube.com` is on `youtube.com`; `notyoutube.com`
isn't).
-}
hostIs : String -> Link -> Bool
hostIs domain link =
    link.host == domain || String.endsWith ("." ++ domain) link.host


queryParam : String -> Link -> Maybe String
queryParam key link =
    link.query
        |> List.filter (\( k, _ ) -> k == key)
        |> List.head
        |> Maybe.map Tuple.second


{-| The segments after the first occurrence of `marker`, if there is one.
-}
allSegmentsAfter : String -> List String -> Maybe (List String)
allSegmentsAfter marker segments =
    case segments of
        [] ->
            Nothing

        first :: rest ->
            if first == marker then
                Just rest

            else
                allSegmentsAfter marker rest


isDigits : String -> Bool
isDigits s =
    not (String.isEmpty s) && String.all Char.isDigit s


{-| A post/video id's characters: letters, digits, `_` and `-`.
-}
isSlug : String -> Bool
isSlug s =
    not (String.isEmpty s) && String.all (\c -> Char.isAlphaNum c || c == '_' || c == '-') s



-- VIEW


{-| One embed: `network` names the CSS class (`rsme-youtube-embed`), `maxWidth` caps its width the way the
library's per-network `maxPlaceholderWidth` does, `ratio` (width, height) makes the box that shape (a video) while
`Nothing` gives the iframe a fixed `height` (a post), and `linkUrl`/`linkText` are the placeholder's link.
-}
type alias Frame =
    { network : String
    , src : String
    , title : String
    , maxWidth : Int
    , height : Int
    , ratio : Maybe ( Int, Int )
    , linkUrl : String
    , linkText : String
    , allow : String
    }


frame : Frame -> Html msg
frame config =
    div
        ([ class ("rsme-embed rsme-" ++ config.network ++ "-embed")
         , style "max-width" (String.fromInt config.maxWidth ++ "px")
         ]
            ++ (case config.ratio of
                    Just ( w, h ) ->
                        [ style "aspect-ratio" (String.fromInt w ++ " / " ++ String.fromInt h) ]

                    Nothing ->
                        -- The box is as tall as its iframe, which `index.html` resizes to what the embed reports.
                        []
               )
        )
        [ a
            [ class "rsme-placeholder"
            , href config.linkUrl
            , target "_blank"
            , rel "noopener noreferrer"
            ]
            [ span [ class "rsme-placeholder-text" ] [ text config.linkText ]
            , span [ class "rsme-spinner" ] []
            ]
        , iframe
            ([ class "rsme-frame"
             , src config.src
             , title config.title
             , attribute "loading" "lazy"
             , attribute "frameborder" "0"
             , attribute "referrerpolicy" "strict-origin-when-cross-origin"
             , attribute "sandbox" "allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox allow-presentation allow-forms"
             , attribute "allow" config.allow
             , attribute "allowfullscreen" ""
             ]
                ++ (case config.ratio of
                        Just _ ->
                            []

                        Nothing ->
                            [ style "height" (String.fromInt config.height ++ "px") ]
                   )
            )
            []
        ]
