module QuoteLinksTests exposing (suite)

{-| `Shared.QuoteLinks`' pure core: which server-selection branch a quoted link takes (`plan`), how a page's
requests turn into entries/fetches/preview loads (`request`), how waiting entries are re-planned when
`AccountsPanel` changes (`settle`), and what a fetch result does (`receive`). `Shared.QuoteLinks.update`/
`advance` are these plus the actual gRPC calls.
-}

import Dict
import Expect
import Proto.Rellm exposing (Event, Occasion, Post, defaultEvent, defaultOccasion)
import Proto.Rellm.PostContext exposing (PostContext(..))
import Set
import Shared.Federation.RellmLinks as RellmLinks
import Shared.QuoteLinks as QuoteLinks exposing (Entry(..), Plan(..), World)
import Support.PostFactory as PostFactory
import Support.RellmServerFactory as RellmServerFactory
import Test exposing (Test, describe, test)


emptyWorld : World
emptyWorld =
    { servers = [], previews = Dict.empty, nonRellmHosts = Set.empty }


{-| The user has rellm.org (enabled) and jonline.io (disabled); has previewed bullcity.social (a Rellm
server they haven't added); and a link to some-blog.example already failed its preview.
-}
world : World
world =
    { servers =
        [ RellmServerFactory.connected "rellm.org"
        , (\server -> { server | enabled = False }) (RellmServerFactory.connected "jonline.io")
        , RellmServerFactory.disconnected "offline.example"
        ]
    , previews =
        Dict.fromList
            [ ( "bullcity.social", RellmServerFactory.connected "bullcity.social" )
            , ( "some-blog.example", RellmServerFactory.disconnected "some-blog.example" )
            ]
    , nonRellmHosts = Set.singleton "some-blog.example"
    }


target : String -> String -> RellmLinks.Target
target host id =
    { host = host, id = id }


entryOf : String -> String -> QuoteLinks.Model -> Maybe Entry
entryOf host id model =
    QuoteLinks.entryFor model (target host id)


quotedPost : Post
quotedPost =
    PostFactory.post { id = "abc", createdAtMillis = 1000 }


suite : Test
suite =
    describe "Shared.QuoteLinks"
        [ describe "plan"
            [ test "a server the user added and enabled is fetched from" <|
                \_ -> QuoteLinks.plan world (target "rellm.org" "x") |> Expect.equal Fetch
            , test "a server the user added but disabled is waited on -- never contacted until they enable it" <|
                \_ -> QuoteLinks.plan world (target "jonline.io" "x") |> Expect.equal Wait
            , test "a server the user added that isn't connected (yet) is waited on" <|
                \_ -> QuoteLinks.plan world (target "offline.example" "x") |> Expect.equal Wait
            , test "a host whose preview connected is a Rellm server: fetched from anonymously" <|
                \_ -> QuoteLinks.plan world (target "bullcity.social" "x") |> Expect.equal Fetch
            , test "a host that already failed its preview is given up on" <|
                \_ -> QuoteLinks.plan world (target "some-blog.example" "x") |> Expect.equal GiveUp
            , test "an unknown public domain waits for its preview" <|
                \_ -> QuoteLinks.plan world (target "new-server.example" "x") |> Expect.equal Wait
            , test "an unknown host that isn't safe to probe is given up on, preview or not" <|
                \_ ->
                    [ "localhost:8000", "192.168.1.5", "router", "nas.local", "rellm.org:8000" ]
                        |> List.map (\host -> QuoteLinks.plan world (target host "x"))
                        |> Expect.equalLists (List.repeat 5 GiveUp)
            , test "but a safe-to-probe-or-not host the user did add is used regardless" <|
                \_ ->
                    QuoteLinks.plan { emptyWorld | servers = [ RellmServerFactory.connected "localhost:8000" ] } (target "localhost:8000" "x")
                        |> Expect.equal Fetch
            ]
        , describe "request"
            [ test "a post on an enabled server is fetched right away" <|
                \_ ->
                    let
                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target, previewHosts : List String }
                        result =
                            QuoteLinks.request world [ ( "rellm.org", "/post/abc" ) ] QuoteLinks.init
                    in
                    ( entryOf "rellm.org" "abc" result.model, result.fetch, result.previewHosts )
                        |> Expect.equal ( Just Loading, [ target "rellm.org" "abc" ], [] )
            , test "a relative link means the quoting post's server; an absolute one means its own" <|
                \_ ->
                    let
                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target, previewHosts : List String }
                        result =
                            QuoteLinks.request world [ ( "rellm.org", "/~abc" ), ( "rellm.org", "https://bullcity.social/post/def" ) ] QuoteLinks.init
                    in
                    result.fetch |> Expect.equal [ target "rellm.org" "abc", target "bullcity.social" "def" ]
            , test "a post on a server the user hasn't added waits, and asks for that server's preview -- once, however many posts" <|
                \_ ->
                    let
                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target, previewHosts : List String }
                        result =
                            QuoteLinks.request world
                                [ ( "rellm.org", "https://new-server.example/post/a" ), ( "rellm.org", "https://new-server.example/~b" ) ]
                                QuoteLinks.init
                    in
                    { a = entryOf "new-server.example" "a" result.model, b = entryOf "new-server.example" "b" result.model, fetch = result.fetch, previewHosts = result.previewHosts }
                        |> Expect.equal { a = Just (Awaiting (target "new-server.example" "a")), b = Just (Awaiting (target "new-server.example" "b")), fetch = [], previewHosts = [ "new-server.example" ] }
            , test "a post on a disabled server waits, without asking for a preview (it's one of the user's own servers)" <|
                \_ ->
                    let
                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target, previewHosts : List String }
                        result =
                            QuoteLinks.request world [ ( "rellm.org", "https://jonline.io/post/abc" ) ] QuoteLinks.init
                    in
                    ( entryOf "jonline.io" "abc" result.model, result.fetch, result.previewHosts )
                        |> Expect.equal ( Just (Awaiting (target "jonline.io" "abc")), [], [] )
            , test "a post on a host that isn't a Rellm server is marked unavailable, with nothing fetched or previewed" <|
                \_ ->
                    let
                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target, previewHosts : List String }
                        result =
                            QuoteLinks.request world [ ( "rellm.org", "https://some-blog.example/post/abc" ), ( "rellm.org", "http://192.168.1.5/post/abc" ) ] QuoteLinks.init
                    in
                    { blog = entryOf "some-blog.example" "abc" result.model, lan = entryOf "192.168.1.5" "abc" result.model, fetch = result.fetch, previewHosts = result.previewHosts }
                        |> Expect.equal { blog = Just Unavailable, lan = Just Unavailable, fetch = [], previewHosts = [] }
            , test "links that aren't Rellm post links, and federated posts' links, are ignored entirely" <|
                \_ ->
                    let
                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target, previewHosts : List String }
                        result =
                            QuoteLinks.request world
                                [ ( "rellm.org", "https://example.com/some/page" ), ( "bluesky:alice.bsky.social", "/post/abc" ), ( "rellm.org", "" ) ]
                                QuoteLinks.init
                    in
                    ( Dict.size result.model.entries, result.fetch, result.previewHosts )
                        |> Expect.equal ( 0, [], [] )
            , test "the same post named three ways is one entry, one fetch" <|
                \_ ->
                    let
                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target, previewHosts : List String }
                        result =
                            QuoteLinks.request world [ ( "rellm.org", "/post/abc" ), ( "rellm.org", "/event/abc" ), ( "rellm.org", "https://rellm.org/:abc" ) ] QuoteLinks.init
                    in
                    ( Dict.size result.model.entries, result.fetch )
                        |> Expect.equal ( 1, [ target "rellm.org" "abc" ] )
            , test "asking again never refetches, or re-asks for a preview" <|
                \_ ->
                    let
                        pairs : List ( String, String )
                        pairs =
                            [ ( "rellm.org", "/post/abc" ), ( "rellm.org", "https://new-server.example/post/a" ) ]

                        first : { model : QuoteLinks.Model, fetch : List RellmLinks.Target, previewHosts : List String }
                        first =
                            QuoteLinks.request world pairs QuoteLinks.init

                        second : { model : QuoteLinks.Model, fetch : List RellmLinks.Target, previewHosts : List String }
                        second =
                            QuoteLinks.request world pairs first.model
                    in
                    ( second.fetch, second.previewHosts, second.model == first.model )
                        |> Expect.equal ( [], [], True )
            ]
        , describe "unrequested -- what a page checks before waking Shared.update"
            [ test "only quote links it hasn't seen" <|
                \_ ->
                    let
                        seen : QuoteLinks.Model
                        seen =
                            (QuoteLinks.request world [ ( "rellm.org", "/post/abc" ) ] QuoteLinks.init).model
                    in
                    QuoteLinks.unrequested seen
                        [ ( "rellm.org", "/~abc" ), ( "rellm.org", "/post/def" ), ( "rellm.org", "https://example.com" ), ( "jonline.io", "/post/abc" ) ]
                        |> Expect.equal [ ( "rellm.org", "/post/def" ), ( "jonline.io", "/post/abc" ) ]
            ]
        , describe "settle -- re-planning waiting entries as accounts change"
            [ let
                waiting : QuoteLinks.Model
                waiting =
                    (QuoteLinks.request world
                        [ ( "rellm.org", "https://new-server.example/post/a" ), ( "rellm.org", "https://jonline.io/post/b" ), ( "rellm.org", "/post/c" ) ]
                        QuoteLinks.init
                    ).model
              in
              test "nothing changed: nothing happens" <|
                \_ ->
                    let
                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target }
                        result =
                            QuoteLinks.settle world waiting
                    in
                    ( result.fetch, result.model == waiting ) |> Expect.equal ( [], True )
            , test "a preview connection landing starts the fetch" <|
                \_ ->
                    let
                        waiting : QuoteLinks.Model
                        waiting =
                            (QuoteLinks.request world [ ( "rellm.org", "https://new-server.example/post/a" ) ] QuoteLinks.init).model

                        previewed : World
                        previewed =
                            { world | previews = Dict.insert "new-server.example" (RellmServerFactory.connected "new-server.example") world.previews }

                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target }
                        result =
                            QuoteLinks.settle previewed waiting
                    in
                    ( entryOf "new-server.example" "a" result.model, result.fetch )
                        |> Expect.equal ( Just Loading, [ target "new-server.example" "a" ] )
            , test "the host turning out not to be a Rellm server settles it as unavailable" <|
                \_ ->
                    let
                        waiting : QuoteLinks.Model
                        waiting =
                            (QuoteLinks.request world [ ( "rellm.org", "https://new-server.example/post/a" ) ] QuoteLinks.init).model

                        failed : World
                        failed =
                            { world | nonRellmHosts = Set.insert "new-server.example" world.nonRellmHosts }

                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target }
                        result =
                            QuoteLinks.settle failed waiting
                    in
                    ( entryOf "new-server.example" "a" result.model, result.fetch )
                        |> Expect.equal ( Just Unavailable, [] )
            , test "enabling a disabled server starts its fetch" <|
                \_ ->
                    let
                        waiting : QuoteLinks.Model
                        waiting =
                            (QuoteLinks.request world [ ( "rellm.org", "https://jonline.io/post/b" ) ] QuoteLinks.init).model

                        enabled : World
                        enabled =
                            { world | servers = List.map (\server -> { server | enabled = True }) world.servers }

                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target }
                        result =
                            QuoteLinks.settle enabled waiting
                    in
                    ( entryOf "jonline.io" "b" result.model, result.fetch )
                        |> Expect.equal ( Just Loading, [ target "jonline.io" "b" ] )
            , test "entries already loading, loaded or unavailable are left alone" <|
                \_ ->
                    let
                        model : QuoteLinks.Model
                        model =
                            { entries =
                                Dict.fromList
                                    [ ( "rellm.org|a", Loading ), ( "rellm.org|b", Loaded quotedPost ), ( "rellm.org|c", Unavailable ) ]
                            }

                        result : { model : QuoteLinks.Model, fetch : List RellmLinks.Target }
                        result =
                            QuoteLinks.settle world model
                    in
                    ( result.fetch, result.model == model ) |> Expect.equal ( [], True )
            ]
        , describe "receive"
            [ test "a fetched post is loaded" <|
                \_ ->
                    QuoteLinks.receive "rellm.org|abc" (Just quotedPost) QuoteLinks.init
                        |> entryOf "rellm.org" "abc"
                        |> Expect.equal (Just (Loaded quotedPost))
            , test "no post (not found, not visible, or the fetch failed) is unavailable" <|
                \_ ->
                    QuoteLinks.receive "rellm.org|abc" Nothing QuoteLinks.init
                        |> entryOf "rellm.org" "abc"
                        |> Expect.equal (Just Unavailable)
            , test "it replaces a loading entry" <|
                \_ ->
                    (QuoteLinks.request world [ ( "rellm.org", "/post/abc" ) ] QuoteLinks.init).model
                        |> QuoteLinks.receive "rellm.org|abc" (Just quotedPost)
                        |> entryOf "rellm.org" "abc"
                        |> Expect.equal (Just (Loaded quotedPost))
            ]
        , describe "events"
            [ test "only an event's or occasion's own post needs a GetEvents follow-up" <|
                \_ ->
                    [ POST, REPLY, EVENT, OCCASION ]
                        |> List.map (\context -> QuoteLinks.wantsEvent { quotedPost | context = context })
                        |> Expect.equalLists [ False, False, True, True ]
            , test "an event link shows the event's first occasion" <|
                \_ ->
                    QuoteLinks.eventOf { quotedPost | context = EVENT } (eventWith [ "o1", "o2" ])
                        |> Maybe.map (Tuple.second >> occasionId)
                        |> Expect.equal (Just "o1")
            , test "an occasion link shows that occasion, not the first" <|
                \_ ->
                    QuoteLinks.eventOf { quotedPost | id = "o2", context = OCCASION } (eventWith [ "o1", "o2" ])
                        |> Maybe.map (Tuple.second >> occasionId)
                        |> Expect.equal (Just "o2")
            , test "an occasion the event doesn't have, or an event with none, has nothing to show" <|
                \_ ->
                    [ QuoteLinks.eventOf { quotedPost | id = "zzz", context = OCCASION } (eventWith [ "o1" ])
                    , QuoteLinks.eventOf { quotedPost | context = EVENT } (eventWith [])
                    ]
                        |> Expect.equalLists [ Nothing, Nothing ]
            , test "receiveEvent loads an event card" <|
                \_ ->
                    QuoteLinks.receiveEvent "rellm.org|abc" { quotedPost | context = EVENT } (Just (eventWith [ "o1" ])) QuoteLinks.init
                        |> entryOf "rellm.org" "abc"
                        |> Maybe.map isEventEntry
                        |> Expect.equal (Just True)
            , test "if the event can't be fetched, the plain post stands in" <|
                \_ ->
                    QuoteLinks.receiveEvent "rellm.org|abc" { quotedPost | context = EVENT } Nothing QuoteLinks.init
                        |> entryOf "rellm.org" "abc"
                        |> Expect.equal (Just (Loaded { quotedPost | context = EVENT }))
            ]
        ]


eventWith : List String -> Event
eventWith occasionIds =
    { defaultEvent
        | occasions = List.map (\id -> { defaultOccasion | post = Just { quotedPost | id = id, context = OCCASION } }) occasionIds
    }


occasionId : Occasion -> String
occasionId occasion =
    occasion.post |> Maybe.map .id |> Maybe.withDefault ""


isEventEntry : Entry -> Bool
isEventEntry entry =
    case entry of
        LoadedEvent _ _ ->
            True

        _ ->
            False
