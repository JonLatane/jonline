module Shared.Federation.RellmLinks exposing
    ( Target
    , canonicalLink
    , isProbeableHost
    , key
    , parse
    )

{-| Recognizes a link to a post on _some_ Rellm server -- what a Rellm post puts in its own `link` to quote
(embed) that post (see `Components.QuotedLink`, `Shared.QuoteLinks`, and the proto doc on `Post.quoted_post`).
Pure and total: nothing here talks to a network, it only decides what a link _claims_ to point at; whether
the host really is a Rellm server is `Shared.QuoteLinks`'s business (it probes, and caches the answer in
`Shared.AccountsPanel`).

Accepted shapes (`rellm.proto`'s routing docs list them), each either relative (`/post/abc` -- which the
server stores as `http:///post/abc`, see `parse`) or absolute (`https://rellm.org/post/abc`, or the
scheme-less `rellm.org/post/abc`):

  - `/post/{id}` and `/event/{id}` -- an Event's id is its own `Post`'s id, so both resolve the same way.
  - `/{c}{id}`, where `c` is any single character a username or custom tab could never start with (see
    `Components.Users.startsWithReservedShortUrlCharacter`) -- `/~abc`, `/:abc`, ... -- the short alias for
    either of those.
  - any of those with the usual `@{host}` suffix (`/post/abc@jonline.io`) naming the server the post is on
    when the page serving the link isn't it -- the same `id@host` convention as `Components.Posts.postHref`.

A frontend prefix (`/elm`, `/tamagui`, `/flutter`), a query string, a fragment and a trailing slash are all
ignored. Anything else -- a link to Bluesky/Mastodon (or `/post/{id}@bluesky:`), an id with characters no
Rellm id has, a path that isn't one of the above -- is `Nothing`.

-}

import Url


{-| `host` is the server's `frontendHost` -- lowercase, with a `:port` only when the link spelled out a
non-default one -- and `id` is the post's (or event's) own id.
-}
type alias Target =
    { host : String
    , id : String
    }


{-| `Shared.QuoteLinks`'s cache key. An id is unique across a server's posts and events alike (an event's id
_is_ its post's), so `host` + `id` identify a target no matter which of the link shapes named it.
-}
key : Target -> String
key target =
    target.host ++ "|" ++ target.id


{-| `parse postServerHost link`: what `link`, found on a post served by `postServerHost` (a relative link
means that server), points at. `Nothing` if it isn't a Rellm post/event link at all, or `postServerHost` is a
Mastodon/Bluesky pseudo-host and the link is relative (so there's no Rellm server it could mean).
-}
parse : String -> String -> Maybe Target
parse postServerHost rawLink =
    let
        link : String
        link =
            String.trim rawLink
    in
    if String.isEmpty link then
        Nothing

    else if String.startsWith "//" link then
        Nothing

    else if String.startsWith "/" link then
        parsePath postServerHost (pathOf link)

    else if String.startsWith "http:///" link then
        -- What the server stores for a relative link: `CreatePost` prefixes anything not starting with
        -- `http` with `http://`, so `/post/abc` comes back as `http:///post/abc`. Still a relative link.
        parsePath postServerHost (pathOf (String.dropLeft 7 link))

    else if String.startsWith "https:///" link then
        parsePath postServerHost (pathOf (String.dropLeft 8 link))

    else if String.startsWith "http://" link || String.startsWith "https://" link then
        parseAbsolute link

    else if String.contains "." (String.left (hostEnd link) link) then
        -- `someserver.com/~abc`, no scheme.
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
                    parsePath
                        (String.toLower url.host
                            ++ (case ( url.port_, url.protocol ) of
                                    ( Just 443, Url.Https ) ->
                                        ""

                                    ( Just 80, Url.Http ) ->
                                        ""

                                    ( Just port_, _ ) ->
                                        ":" ++ String.fromInt port_

                                    ( Nothing, _ ) ->
                                        ""
                               )
                        )
                        url.path
            )


{-| `defaultHost` is who an `id` with no `@host` suffix belongs to (a federated `postServerHost` is rejected
by `resolveHost`, in `targetFrom`).
-}
parsePath : String -> String -> Maybe Target
parsePath defaultHost path =
    case pathSegments path of
        [ "post", idAndHost ] ->
            targetFrom defaultHost idAndHost

        [ "event", idAndHost ] ->
            targetFrom defaultHost idAndHost

        [ shortSegment ] ->
            -- `/~abc`: the leading reserved character is the alias marker, not part of the id.
            case String.uncons shortSegment of
                Just ( lead, rest ) ->
                    if isReservedLeadCharacter lead then
                        targetFrom defaultHost rest

                    else
                        Nothing

                Nothing ->
                    Nothing

        _ ->
            Nothing


{-| The `/`-separated, percent-decoded segments of `path`, minus an empty trailing one and a leading
`/elm`/`/tamagui`/`/flutter` frontend prefix.
-}
pathSegments : String -> List String
pathSegments path =
    let
        decoded : List String
        decoded =
            path
                |> String.split "/"
                |> List.filter (not << String.isEmpty)
                |> List.map (\segment -> Url.percentDecode segment |> Maybe.withDefault segment)
    in
    case decoded of
        first :: rest ->
            if List.member first [ "elm", "tamagui", "flutter" ] then
                rest

            else
                decoded

        [] ->
            []


{-| `{id}` or `{id}@{host}` -- see the module doc.
-}
targetFrom : String -> String -> Maybe Target
targetFrom defaultHost idAndHost =
    case String.split "@" idAndHost of
        [ id ] ->
            if isRellmId id then
                resolveHost defaultHost |> Maybe.map (\host -> { host = host, id = id })

            else
                Nothing

        [ id, host ] ->
            if isRellmId id then
                resolveHost host |> Maybe.map (\resolved -> { host = resolved, id = id })

            else
                Nothing

        _ ->
            Nothing


{-| Lowercases `host`, rejecting the `mastodon:`/`bluesky:` pseudo-hosts (federated posts aren't Rellm
posts, whatever server's frontend happens to route them) and anything that can't be a hostname at all.
-}
resolveHost : String -> Maybe String
resolveHost host =
    let
        lowered : String
        lowered =
            String.toLower host
    in
    if String.isEmpty lowered || String.startsWith "mastodon:" lowered || String.startsWith "bluesky:" lowered then
        Nothing

    else if String.all (\c -> Char.isAlphaNum c || c == '.' || c == '-' || c == ':') lowered then
        Just lowered

    else
        Nothing


{-| Rellm ids are base58 -- alphanumeric. Narrower than a Bluesky `did~rkey` or an AT URI on purpose, so
those never read as Rellm ids.
-}
isRellmId : String -> Bool
isRellmId id =
    not (String.isEmpty id) && String.all Char.isAlphaNum id


{-| `-._~:/?[]@!$&'()*+,;%=` -- the characters `validate_username` refuses a username/custom tab to start
with, mirrored by `Components.Users.startsWithReservedShortUrlCharacter`.
-}
isReservedLeadCharacter : Char -> Bool
isReservedLeadCharacter c =
    String.contains (String.fromChar c) "-._~:/?[]@!$&'()*+,;%="


{-| `link` up to (not including) its first `?` or `#`.
-}
pathOf : String -> String
pathOf link =
    String.left (hostEnd link) link


{-| Index of the first `?` or `#` in `s` (or its length) -- where a path ends. Also used (on a scheme-less
`host/path`) to bound the part checked for a `.`.
-}
hostEnd : String -> Int
hostEnd s =
    let
        indexOrLength : String -> Int
        indexOrLength needle =
            String.indexes needle s |> List.head |> Maybe.withDefault (String.length s)
    in
    min (indexOrLength "?") (indexOrLength "#")


{-| The absolute link a post quoting `target` should carry in its `link` -- `https://{host}/post/{id}`
(`/event/{id}` for an event), `http` for a local development host. Absolute rather than relative so it
means the same thing to every consumer of `Post.link` (RSS/Atom feeds, other clients, ...), not just to a
page served by the quoted post's own server.
-}
canonicalLink : { isEvent : Bool } -> Target -> String
canonicalLink { isEvent } target =
    (if isLocalHost target.host then
        "http://"

     else
        "https://"
    )
        ++ target.host
        ++ (if isEvent then
                "/event/"

            else
                "/post/"
           )
        ++ target.id


isLocalHost : String -> Bool
isLocalHost host =
    let
        hostname : String
        hostname =
            String.split ":" host |> List.head |> Maybe.withDefault host
    in
    hostname == "localhost" || hostname == "127.0.0.1" || String.endsWith ".local" hostname


{-| Whether it's reasonable for the app to _probe_ `host` (several candidate connections, see
`RellmServers.negotiateRellmServerConfig`) just because a post's `link` mentions it, when it isn't a server
the user added: only a plain public domain name, no explicit port. Never an IP address, `localhost`, a
`.local`/`.internal`-style LAN name or an IPv6 literal -- a link in somebody else's post shouldn't be able to
make a viewer's browser poke around their own network. (A server the user already knows about, or whose
preview is already loaded, is used regardless of this.)
-}
isProbeableHost : String -> Bool
isProbeableHost host =
    let
        labels : List String
        labels =
            String.split "." host

        isNumeric : String -> Bool
        isNumeric label =
            not (String.isEmpty label) && String.all Char.isDigit label
    in
    String.contains "." host
        && not (String.contains ":" host)
        && not (List.all isNumeric labels)
        && not (List.any (\suffix -> String.endsWith suffix host) [ ".local", ".localhost", ".internal", ".lan", ".home", ".corp", ".intranet", ".arpa" ])
        && List.all (\label -> not (String.isEmpty label) && String.all (\c -> Char.isAlphaNum c || c == '-') label) labels
