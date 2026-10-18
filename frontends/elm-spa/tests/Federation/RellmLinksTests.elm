module Federation.RellmLinksTests exposing (suite)

{-| `Shared.Federation.RellmLinks`: which links count as "a post/event on a Rellm server" (the thing a post
quotes by putting it in its `link`), and which hosts the app is willing to probe to find out.
-}

import Expect
import Shared.Federation.RellmLinks as RellmLinks
import Test exposing (Test, describe, test)


target : String -> String -> Maybe RellmLinks.Target
target host id =
    Just { host = host, id = id }


{-| `/post/x` seen on rellm.org, i.e. `parse "rellm.org"`.
-}
onRellm : String -> Maybe RellmLinks.Target
onRellm =
    RellmLinks.parse "rellm.org"


suite : Test
suite =
    describe "Shared.Federation.RellmLinks"
        [ describe "relative links -- relative to the server the quoting post is on"
            [ test "/post/{id}" <|
                \_ -> onRellm "/post/4rAfoSKAuJo" |> Expect.equal (target "rellm.org" "4rAfoSKAuJo")
            , test "/event/{id}" <|
                \_ -> onRellm "/event/4rAfoSKAuJo" |> Expect.equal (target "rellm.org" "4rAfoSKAuJo")
            , test "the short form with `~`" <|
                \_ -> onRellm "/~4rAfoSKAuJo" |> Expect.equal (target "rellm.org" "4rAfoSKAuJo")
            , test "the short form with `:`" <|
                \_ -> onRellm "/:4rAfoSKAuJo" |> Expect.equal (target "rellm.org" "4rAfoSKAuJo")
            , test "the short form works with every character a username can't start with (that's a legal unescaped path character)" <|
                \_ ->
                    "-._~:!$&'()*+,;="
                        |> String.toList
                        |> List.map (\lead -> onRellm ("/" ++ String.fromChar lead ++ "abc123"))
                        |> Expect.equalLists (List.repeat 16 (target "rellm.org" "abc123"))
            , test "the short form with the characters that must be percent-encoded in a path (`?`, `[`, `]`, `%`, `@`)" <|
                \_ ->
                    [ "/%3Fabc", "/%5Babc", "/%5Dabc", "/%25abc", "/%40abc" ]
                        |> List.map onRellm
                        |> Expect.equalLists (List.repeat 5 (target "rellm.org" "abc"))
            , test "a path starting with a letter or digit is a username/custom tab, not a short link" <|
                \_ ->
                    [ "/jon", "/events", "/4rAfoSKAuJo", "/a~b" ]
                        |> List.map onRellm
                        |> Expect.equalLists [ Nothing, Nothing, Nothing, Nothing ]
            , test "`#` isn't a short-link lead (a fragment never reaches the server)" <|
                \_ -> onRellm "/#abc" |> Expect.equal Nothing
            , test "an `@host` suffix names the server the post is actually on" <|
                \_ ->
                    [ onRellm "/post/abc@jonline.io", onRellm "/event/abc@jonline.io", onRellm "/~abc@jonline.io" ]
                        |> Expect.equalLists (List.repeat 3 (target "jonline.io" "abc"))
            , test "the quoting post's server is lowercased and may carry a port" <|
                \_ -> RellmLinks.parse "localhost:8000" "/post/abc" |> Expect.equal (target "localhost:8000" "abc")
            , test "the form the server stores a relative link in (`CreatePost` prefixes `http://`): `http:///post/{id}`" <|
                \_ ->
                    [ onRellm "http:///post/abc", onRellm "http:///event/abc", onRellm "http:///~abc", onRellm "https:///post/abc?x=1", onRellm "http:///post/abc@jonline.io" ]
                        |> Expect.equalLists [ target "rellm.org" "abc", target "rellm.org" "abc", target "rellm.org" "abc", target "rellm.org" "abc", target "jonline.io" "abc" ]
            , test "surrounding whitespace is ignored" <|
                \_ -> onRellm "  /post/abc \n" |> Expect.equal (target "rellm.org" "abc")
            ]
        , describe "absolute links"
            [ test "https://host/post/{id}" <|
                \_ -> onRellm "https://jonline.io/post/abc" |> Expect.equal (target "jonline.io" "abc")
            , test "https://host/event/{id}" <|
                \_ -> onRellm "https://jonline.io/event/abc" |> Expect.equal (target "jonline.io" "abc")
            , test "https://host/~{id}, e.g. a short link on another server" <|
                \_ -> onRellm "https://jonline.io/~4rAfoSKAuJo" |> Expect.equal (target "jonline.io" "4rAfoSKAuJo")
            , test "http is fine" <|
                \_ -> onRellm "http://jonline.io/post/abc" |> Expect.equal (target "jonline.io" "abc")
            , test "a scheme-less link (`someserver.com/~something`)" <|
                \_ -> onRellm "someserver.com/~something" |> Expect.equal (target "someserver.com" "something")
            , test "the host is lowercased" <|
                \_ -> onRellm "https://JonLine.IO/post/abc" |> Expect.equal (target "jonline.io" "abc")
            , test "a non-default port is part of the host; the default one isn't" <|
                \_ ->
                    [ onRellm "http://localhost:8000/post/abc", onRellm "https://jonline.io:443/post/abc", onRellm "http://jonline.io:80/post/abc", onRellm "https://jonline.io:8443/post/abc" ]
                        |> Expect.equalLists [ target "localhost:8000" "abc", target "jonline.io" "abc", target "jonline.io" "abc", target "jonline.io:8443" "abc" ]
            , test "the Elm/Tamagui/Flutter frontend prefix is ignored" <|
                \_ ->
                    [ "https://rellm.org/elm/post/abc", "https://rellm.org/tamagui/event/abc", "https://rellm.org/flutter/~abc" ]
                        |> List.map onRellm
                        |> Expect.equalLists (List.repeat 3 (target "rellm.org" "abc"))
            , test "a query string, fragment and trailing slash are ignored" <|
                \_ ->
                    [ "https://rellm.org/post/abc?utm=x", "https://rellm.org/post/abc#top", "https://rellm.org/post/abc/", "https://rellm.org/~abc?a=b#c", "/post/abc?x=1" ]
                        |> List.map onRellm
                        |> Expect.equalLists (List.repeat 5 (target "rellm.org" "abc"))
            , test "an `@host` suffix wins over the host serving the link" <|
                \_ -> onRellm "https://rellm.org/post/abc@jonline.io" |> Expect.equal (target "jonline.io" "abc")
            , test "the example sites: a rellm.org post and a jonline.io post, quoted from each other" <|
                \_ ->
                    [ RellmLinks.parse "jonline.io" "https://rellm.org/post/4rAfoSKAuJo", RellmLinks.parse "rellm.org" "https://jonline.io/~4rAfoSKAuJo" ]
                        |> Expect.equalLists [ target "rellm.org" "4rAfoSKAuJo", target "jonline.io" "4rAfoSKAuJo" ]
            ]
        , describe "things that are not links to a Rellm post"
            [ test "empty and blank" <|
                \_ -> [ onRellm "", onRellm "   " ] |> Expect.equalLists [ Nothing, Nothing ]
            , test "a plain website, or a path that isn't a post/event one" <|
                \_ ->
                    [ "https://example.com", "https://example.com/", "https://example.com/blog/post/abc", "https://rellm.org/people", "https://rellm.org/post", "https://rellm.org/post/", "/post/abc/def", "/user/abc" ]
                        |> List.map onRellm
                        |> Expect.equalLists (List.repeat 8 Nothing)
            , test "ids that aren't Rellm ids" <|
                \_ ->
                    [ "/post/not-an-id", "/post/a b", "/post/at%3A%2F%2Fdid%3Aplc%3Aabc%2Fapp.bsky.feed.post%2Fxyz", "/post/did:plc:abc~xyz", "/~" ]
                        |> List.map onRellm
                        |> Expect.equalLists (List.repeat 5 Nothing)
            , test "a Bluesky or Mastodon post (their ids live on a pseudo-host, not a Rellm server)" <|
                \_ ->
                    [ "https://rellm.org/post/did:plc:abc~xyz@bluesky:", "/post/abc@bluesky:", "/post/110224857075517327@mastodon:mastodon.social", "https://bsky.app/profile/x.bsky.social/post/abc" ]
                        |> List.map onRellm
                        |> Expect.equalLists (List.repeat 4 Nothing)
            , test "a relative link on a Bluesky/Mastodon post has no Rellm server to be relative to" <|
                \_ ->
                    [ RellmLinks.parse "bluesky:alice.bsky.social" "/post/abc", RellmLinks.parse "mastodon:mastodon.social" "/~abc" ]
                        |> Expect.equalLists [ Nothing, Nothing ]
            , test "a protocol-relative link (`//evil.example/post/x`) is not treated as relative" <|
                \_ -> onRellm "//evil.example/post/abc" |> Expect.equal Nothing
            , test "other schemes" <|
                \_ ->
                    [ "ftp://example.com/post/abc", "mailto:a@b.c", "javascript:alert(1)" ]
                        |> List.map onRellm
                        |> Expect.equalLists (List.repeat 3 Nothing)
            , test "a bad `@host`" <|
                \_ ->
                    [ "/post/abc@", "/post/abc@a b", "/post/abc@x@y" ]
                        |> List.map onRellm
                        |> Expect.equalLists (List.repeat 3 Nothing)
            ]
        , describe "key"
            [ test "the same post named by any of the link shapes shares one key" <|
                \_ ->
                    [ "/post/abc", "/event/abc", "/~abc", "https://rellm.org/:abc" ]
                        |> List.filterMap onRellm
                        |> List.map RellmLinks.key
                        |> Expect.equalLists (List.repeat 4 "rellm.org|abc")
            , test "the same id on two servers doesn't" <|
                \_ ->
                    [ onRellm "/post/abc", onRellm "https://jonline.io/post/abc" ]
                        |> List.filterMap identity
                        |> List.map RellmLinks.key
                        |> Expect.equalLists [ "rellm.org|abc", "jonline.io|abc" ]
            ]
        , describe "canonicalLink"
            [ test "a post" <|
                \_ -> RellmLinks.canonicalLink { isEvent = False } { host = "rellm.org", id = "abc" } |> Expect.equal "https://rellm.org/post/abc"
            , test "an event" <|
                \_ -> RellmLinks.canonicalLink { isEvent = True } { host = "jonline.io", id = "abc" } |> Expect.equal "https://jonline.io/event/abc"
            , test "a local development server is http" <|
                \_ -> RellmLinks.canonicalLink { isEvent = False } { host = "localhost:8000", id = "abc" } |> Expect.equal "http://localhost:8000/post/abc"
            , test "it parses back to the same target" <|
                \_ ->
                    [ { host = "rellm.org", id = "abc" }, { host = "localhost:8000", id = "xyz" }, { host = "jonline.io:8443", id = "q" } ]
                        |> List.map
                            (\t ->
                                ( RellmLinks.parse "other.example" (RellmLinks.canonicalLink { isEvent = False } t)
                                , RellmLinks.parse "other.example" (RellmLinks.canonicalLink { isEvent = True } t)
                                )
                            )
                        |> Expect.equalLists
                            [ ( target "rellm.org" "abc", target "rellm.org" "abc" )
                            , ( target "localhost:8000" "xyz", target "localhost:8000" "xyz" )
                            , ( target "jonline.io:8443" "q", target "jonline.io:8443" "q" )
                            ]
            ]
        , describe "isProbeableHost -- a post's link can't make a viewer's browser probe their own network"
            [ test "public domain names are" <|
                \_ ->
                    [ "rellm.org", "jonline.io", "www.bullcity.social", "a-b.example.co.uk", "xn--bcher-kva.example" ]
                        |> List.map RellmLinks.isProbeableHost
                        |> Expect.equalLists (List.repeat 5 True)
            , test "IP addresses, localhost and bare names aren't" <|
                \_ ->
                    [ "127.0.0.1", "192.168.1.1", "10.0.0.5", "8.8.8.8", "localhost", "router", "[::1]" ]
                        |> List.map RellmLinks.isProbeableHost
                        |> Expect.equalLists (List.repeat 7 False)
            , test "LAN-style names aren't" <|
                \_ ->
                    [ "nas.local", "printer.lan", "wiki.internal", "x.localhost", "box.home", "files.corp", "a.intranet", "1.0.0.127.in-addr.arpa" ]
                        |> List.map RellmLinks.isProbeableHost
                        |> Expect.equalLists (List.repeat 8 False)
            , test "an explicit port isn't" <|
                \_ -> RellmLinks.isProbeableHost "rellm.org:8000" |> Expect.equal False
            , test "malformed names aren't" <|
                \_ ->
                    [ "", ".", "a..b", ".example.com", "example.com.", "ex ample.com", "a_b.example.com" ]
                        |> List.map RellmLinks.isProbeableHost
                        |> Expect.equalLists (List.repeat 7 False)
            ]
        ]
