module Shared.Federation.FederatedLinks exposing
    ( Target(..)
    , key
    , parse
    )

{-| Recognizes a link to a Bluesky or Mastodon post -- what a Rellm post puts in its own `link` to embed it
(`Components.QuotedLink`, `Shared.QuoteLinks`), alongside `Shared.Federation.RellmLinks` for posts on Rellm
servers. Pure: it only decides what a link _claims_ to point at.

Accepted shapes, on any host (or relative, `/post/…`):

  - Rellm's own routes for a federated post (`Components.Posts.postHref`): `/post/{did}~{rkey}@bluesky:` and
    `/post/{statusId}@mastodon:{instanceHost}`, or the `/~…` short form of either. Which Rellm server serves
    the link doesn't matter -- the id says everything -- so this works for a link to any of them.
  - Bluesky itself: `https://bsky.app/profile/{did-or-handle}/post/{rkey}`, and `at://{did-or-handle}/app.bsky.feed.post/{rkey}`.
  - Mastodon itself, on whatever instance the link names: `/@{user}/{statusId}` (also `/@{user}@{origin}/{id}`)
    and `/users/{user}/statuses/{statusId}`. Whether that host really is a Mastodon server is found out by
    fetching (`Shared.QuoteLinks`).

Anything else is `Nothing`.

-}

import Components.Posts as Posts
import Url


type Target
    = -- `at://{did}/app.bsky.feed.post/{rkey}`
      BlueskyUri String
      -- A link that names its author by handle; the DID has to be looked up first.
    | BlueskyHandle { handle : String, rkey : String }
    | MastodonStatus { instanceHost : String, statusId : String }


{-| `Shared.QuoteLinks`' cache key -- never collides with a Rellm `host|id` key (those have no `bluesky:`/
`mastodon:` lead).
-}
key : Target -> String
key target =
    case target of
        BlueskyUri uri ->
            "bluesky:" ++ uri

        BlueskyHandle { handle, rkey } ->
            "bluesky-handle:" ++ handle ++ "/" ++ rkey

        MastodonStatus { instanceHost, statusId } ->
            "mastodon:" ++ instanceHost ++ "|" ++ statusId


parse : String -> Maybe Target
parse rawLink =
    let
        link : String
        link =
            String.trim rawLink
    in
    if String.startsWith "at://" link then
        parseAtUri (String.dropLeft 5 link |> pathOnly)

    else if String.startsWith "//" link then
        Nothing

    else if String.startsWith "/" link then
        parseUrl "" (pathOnly link)

    else if String.startsWith "http:///" link then
        parseUrl "" (pathOnly (String.dropLeft 7 link))

    else if String.startsWith "https:///" link then
        parseUrl "" (pathOnly (String.dropLeft 8 link))

    else if String.startsWith "http://" link || String.startsWith "https://" link then
        parseAbsolute link

    else if String.contains "." (firstSegment link) then
        parseAbsolute ("https://" ++ link)

    else
        Nothing


parseAbsolute : String -> Maybe Target
parseAbsolute link =
    Url.fromString link
        |> Maybe.andThen
            (\url ->
                if String.isEmpty url.host then
                    Nothing

                else
                    parseUrl
                        (String.toLower url.host
                            ++ (case url.port_ of
                                    Just port_ ->
                                        if port_ == 80 || port_ == 443 then
                                            ""

                                        else
                                            ":" ++ String.fromInt port_

                                    Nothing ->
                                        ""
                               )
                        )
                        url.path
            )


{-| `host` is `""` for a relative link. Raw (still percent-encoded) path segments, since the route form's own
parser (`Posts.parsePostRouteId`) does the decoding.
-}
parseUrl : String -> String -> Maybe Target
parseUrl host path =
    case segmentsOf path of
        [ "post", idAndHost ] ->
            parseRouteId idAndHost

        [ shortSegment ] ->
            -- `/~{did}~{rkey}@bluesky:` -- the leading reserved character is the alias marker.
            parseRouteId (String.dropLeft 1 shortSegment)

        [ "profile", actor, "post", rkey ] ->
            if host == "bsky.app" then
                bluesky actor rkey

            else
                Nothing

        [ at, statusId ] ->
            if String.startsWith "@" at && String.length at > 1 then
                mastodon host statusId

            else
                Nothing

        [ "users", _, "statuses", statusId ] ->
            mastodon host statusId

        _ ->
            Nothing


{-| `/post/{id}@bluesky:` / `{id}@mastodon:{host}`, the part of `Components.Posts.postHref` after `/post/`.
-}
parseRouteId : String -> Maybe Target
parseRouteId idAndHost =
    if String.contains "@bluesky:" idAndHost || String.endsWith "@bluesky" idAndHost || String.contains "@mastodon:" idAndHost then
        let
            ( id, host ) =
                Posts.parsePostRouteId "" idAndHost
        in
        case Posts.parseFederatedPostId id host of
            Just (Posts.BlueskyPostId { uri }) ->
                if String.startsWith "at://" uri then
                    parseAtUri (String.dropLeft 5 uri)

                else
                    Nothing

            Just (Posts.MastodonPostId { instanceHost, statusId }) ->
                if isHostname instanceHost then
                    mastodon (String.toLower instanceHost) statusId

                else
                    Nothing

            Nothing ->
                Nothing

    else
        Nothing


{-| `{did-or-handle}/app.bsky.feed.post/{rkey}`, after `at://`.
-}
parseAtUri : String -> Maybe Target
parseAtUri rest =
    case segmentsOf rest of
        [ actor, "app.bsky.feed.post", rkey ] ->
            bluesky actor rkey

        _ ->
            Nothing


bluesky : String -> String -> Maybe Target
bluesky actor rkey =
    if not (isRecordKey rkey) then
        Nothing

    else if String.startsWith "did:" actor && String.all (\c -> Char.isAlphaNum c || c == ':' || c == '.' || c == '-' || c == '_') actor then
        Just (BlueskyUri ("at://" ++ actor ++ "/app.bsky.feed.post/" ++ rkey))

    else if String.contains "." actor && isHostname actor then
        Just (BlueskyHandle { handle = String.toLower actor, rkey = rkey })

    else
        Nothing


{-| Mastodon status ids are numeric.
-}
mastodon : String -> String -> Maybe Target
mastodon host statusId =
    if not (String.isEmpty host) && isHostname host && not (String.isEmpty statusId) && String.all Char.isDigit statusId then
        Just (MastodonStatus { instanceHost = host, statusId = statusId })

    else
        Nothing


isRecordKey : String -> Bool
isRecordKey rkey =
    not (String.isEmpty rkey) && String.all (\c -> Char.isAlphaNum c || c == '.' || c == '-' || c == '_' || c == '~' || c == ':') rkey


isHostname : String -> Bool
isHostname host =
    not (String.isEmpty host) && String.all (\c -> Char.isAlphaNum c || c == '.' || c == '-' || c == ':') host


{-| `/`-separated, non-empty segments of `path` minus a leading `/elm`/`/tamagui`/`/flutter` frontend prefix.
-}
segmentsOf : String -> List String
segmentsOf path =
    case String.split "/" path |> List.filter (not << String.isEmpty) of
        first :: rest ->
            if List.member first [ "elm", "tamagui", "flutter" ] then
                rest

            else
                first :: rest

        [] ->
            []


pathOnly : String -> String
pathOnly link =
    String.left (pathEnd link) link


pathEnd : String -> Int
pathEnd s =
    let
        indexOrLength : String -> Int
        indexOrLength needle =
            String.indexes needle s |> List.head |> Maybe.withDefault (String.length s)
    in
    min (indexOrLength "?") (indexOrLength "#")


firstSegment : String -> String
firstSegment link =
    String.split "/" link |> List.head |> Maybe.withDefault link
