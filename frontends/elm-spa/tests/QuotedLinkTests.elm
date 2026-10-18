module QuotedLinkTests exposing (suite)

{-| `Components.QuotedLink`: which posts quote anything (`targetOf`), and what the embed shows for each kind of
server the link can point at -- one of the user's own (enabled, disabled), one they haven't added that turns
out to be a Rellm server, one that doesn't, or one we know nothing about yet.
-}

import Components.MediaRenderer as MediaRenderer
import Components.QuotedLink as QuotedLink
import Dict
import Expect
import Html exposing (div)
import Html.Attributes
import Proto.Rellm exposing (Post, defaultAuthor, wrapPost)
import Proto.Rellm.PostContext exposing (PostContext(..))
import Set
import Shared.Federation.RellmLinks as RellmLinks
import Shared.QuoteLinks as QuoteLinks
import Support.PostFactory as PostFactory
import Support.RellmServerFactory as RellmServerFactory
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Time


type Msg
    = AddServer String
    | EnableServer String
    | PlayMedia


{-| The server a button's message is about -- `Nothing` for `PlayMedia`.
-}
serverOf : Msg -> Maybe String
serverOf msg =
    case msg of
        AddServer host ->
            Just host

        EnableServer host ->
            Just host

        PlayMedia ->
            Nothing


quoting : String -> Post
quoting link =
    let
        post : Post
        post =
            PostFactory.post { id = "quoter", createdAtMillis = 1000 }
    in
    { post | context = POST, link = Just link, content = Just "my take" }


quoted : Post
quoted =
    let
        post : Post
        post =
            PostFactory.post { id = "abc", createdAtMillis = 1000 }
    in
    { post
        | context = POST
        , title = Just "The Original"
        , content = Just "the quoted content"
        , author = Just { defaultAuthor | userId = "u1", username = Just "alice" }
    }


{-| The user has rellm.org (enabled) and jonline.io (disabled), and previewed bullcity.social (a Rellm server
they haven't added); a link to some-blog.example already failed its preview.
-}
accounts : QuotedLink.AccountsInfo
accounts =
    { servers =
        [ RellmServerFactory.connected "rellm.org"
        , (\server -> { server | enabled = False }) (RellmServerFactory.connected "jonline.io")
        ]
    , accounts = []
    , previews =
        Dict.fromList
            [ ( "bullcity.social", RellmServerFactory.connected "bullcity.social" )
            , ( "some-blog.example", RellmServerFactory.disconnected "some-blog.example" )
            ]
    , nonRellmHosts = Set.singleton "some-blog.example"
    , mainFrontendHost = "rellm.org"
    }


config : QuoteLinks.Model -> QuotedLink.Config Msg
config quotes =
    { time = { browserTimeZone = { zone = Time.utc, name = "UTC", abbreviation = "UTC", uses24Hour = True }, now = Time.millisToPosix 0 }
    , basePath = ""
    , accounts = accounts
    , quotes = quotes
    , mediaPlayState = MediaRenderer.init
    , onMediaPlayClicked = \_ -> PlayMedia
    , onAddServerClicked = AddServer
    , onEnableServerClicked = EnableServer
    }


loaded : String -> String -> QuoteLinks.Model
loaded host id =
    { entries = Dict.singleton (RellmLinks.key { host = host, id = id }) (QuoteLinks.Loaded quoted) }


with : String -> String -> QuoteLinks.Entry -> QuoteLinks.Model
with host id entry =
    { entries = Dict.singleton (RellmLinks.key { host = host, id = id }) entry }


{-| Rendered inside a `div`, since `Test.Html.Query` needs an element root and `view` is allowed to be empty.
-}
rendered : QuoteLinks.Model -> String -> Post -> Query.Single Msg
rendered quotes postServerHost post =
    Query.fromHtml (div [] [ QuotedLink.view (config quotes) postServerHost post ])


{-| `Components.Markdown.view` renders content through a `<rellm-markdown content="...">` element.
-}
quotedContent : Selector.Selector
quotedContent =
    Selector.attribute (Html.Attributes.attribute "content" "the quoted content")


{-| None of `selectors` appears anywhere in the rendered output -- one count per selector, since
`Query.hasNot` with several only fails when they _all_ match.
-}
lacks : List Selector.Selector -> Query.Single Msg -> Expect.Expectation
lacks selectors query =
    selectors
        |> List.map (\selector -> \q -> q |> Query.findAll [ selector ] |> Query.count (Expect.equal 0))
        |> (\checks -> Expect.all checks query)


card : Selector.Selector
card =
    Selector.class "post-card-quote"


addButton : Selector.Selector
addButton =
    Selector.all [ Selector.tag "button", Selector.class "server-action-button" ]


suite : Test
suite =
    describe "Components.QuotedLink"
        [ describe "targetOf"
            [ test "a POST on a Rellm server whose link is a Rellm post link" <|
                \_ -> QuotedLink.targetOf "rellm.org" (quoting "/post/abc") |> Expect.equal (Just { host = "rellm.org", id = "abc" })
            , test "an absolute link to another server" <|
                \_ -> QuotedLink.targetOf "rellm.org" (quoting "https://jonline.io/~abc") |> Expect.equal (Just { host = "jonline.io", id = "abc" })
            , test "no link, or a link that isn't to a Rellm post" <|
                \_ ->
                    let
                        noLink : Post
                        noLink =
                            quoting "x" |> (\post -> { post | link = Nothing })
                    in
                    [ QuotedLink.targetOf "rellm.org" noLink, QuotedLink.targetOf "rellm.org" (quoting "https://example.com/article") ]
                        |> Expect.equalLists [ Nothing, Nothing ]
            , test "only a top-level POST quotes: a reply, event or occasion with such a link just has a link" <|
                \_ ->
                    [ REPLY, EVENT, OCCASION ]
                        |> List.map (\context -> QuotedLink.targetOf "rellm.org" (quoting "/post/abc" |> (\post -> { post | context = context })))
                        |> Expect.equalLists [ Nothing, Nothing, Nothing ]
            , test "a federated post's `link` is its original URL, not a quote -- its quote arrives resolved in `quotedPost`" <|
                \_ ->
                    [ QuotedLink.targetOf "bluesky:alice.bsky.social" (quoting "https://rellm.org/post/abc")
                    , QuotedLink.targetOf "mastodon:mastodon.social" (quoting "https://rellm.org/post/abc")
                    , QuotedLink.targetOf "rellm.org" (quoting "/post/abc" |> (\post -> { post | quotedPost = Just (wrapPost quoted) }))
                    ]
                        |> Expect.equalLists [ Nothing, Nothing, Nothing ]
            ]
        , describe "a quote from one of the user's own enabled servers"
            [ test "shows the quoted post as a card" <|
                \_ ->
                    rendered (loaded "rellm.org" "abc") "rellm.org" (quoting "/post/abc")
                        |> Query.has [ card, quotedContent ]
            , test "the card links to the quoted post's own page" <|
                \_ ->
                    rendered (loaded "rellm.org" "abc") "rellm.org" (quoting "/post/abc")
                        |> Query.find [ Selector.class "post-card-link-overlay" ]
                        |> Query.has [ Selector.attribute (Html.Attributes.href "/post/abc") ]
            , test "an absolute link works the same, and an unrelated server's post links with its host" <|
                \_ ->
                    rendered (loaded "rellm.org" "abc") "other.example" (quoting "https://rellm.org/post/abc")
                        |> Query.has [ card ]
            , test "while it loads, a loading line" <|
                \_ ->
                    rendered (with "rellm.org" "abc" QuoteLinks.Loading) "rellm.org" (quoting "/post/abc")
                        |> Query.has [ Selector.class "quoted-post-loading" ]
            , test "and while it waits for its server" <|
                \_ ->
                    rendered (with "rellm.org" "abc" (QuoteLinks.Awaiting { host = "rellm.org", id = "abc" })) "rellm.org" (quoting "/post/abc")
                        |> Query.has [ Selector.class "quoted-post-loading" ]
            , test "a post that can't be seen shows nothing at all" <|
                \_ ->
                    rendered (with "rellm.org" "abc" QuoteLinks.Unavailable) "rellm.org" (quoting "/post/abc")
                        |> lacks [ card, Selector.class "quoted-post-loading", addButton ]
            , test "a post that isn't a quote shows nothing" <|
                \_ ->
                    rendered (loaded "rellm.org" "abc") "rellm.org" (quoting "https://example.com/article")
                        |> lacks [ card ]
            ]
        , describe "a quote from a server the user disabled"
            [ test "is Enable prompt, not the post -- a switched-off server isn't read from" <|
                \_ ->
                    rendered (loaded "jonline.io" "abc") "rellm.org" (quoting "https://jonline.io/post/abc")
                        |> Expect.all
                            [ Query.has [ Selector.class "server-dependent-prompt", Selector.text "jonline.io is disabled" ]
                            , lacks [ card ]
                            ]
            , test "its button enables that server" <|
                \_ ->
                    rendered QuoteLinks.init "rellm.org" (quoting "https://jonline.io/post/abc")
                        |> Query.find [ Selector.class "server-action-button" ]
                        |> Event.simulate Event.click
                        |> Event.toResult
                        |> Result.map (\msg -> ( msg, serverOf msg ))
                        |> Expect.equal (Ok ( EnableServer "jonline.io", Just "jonline.io" ))
            ]
        , describe "a quote from a Rellm server the user hasn't added"
            [ test "shows the post and an Add button for the server" <|
                \_ ->
                    rendered (loaded "bullcity.social" "abc") "rellm.org" (quoting "https://bullcity.social/~abc")
                        |> Expect.all
                            [ Query.has [ card, quotedContent ]
                            , Query.has [ addButton ]
                            ]
            , test "the button adds that server" <|
                \_ ->
                    rendered (loaded "bullcity.social" "abc") "rellm.org" (quoting "https://bullcity.social/~abc")
                        |> Query.find [ addButton ]
                        |> Event.simulate Event.click
                        |> Event.toResult
                        |> Result.map (\msg -> ( msg, serverOf msg ))
                        |> Expect.equal (Ok ( AddServer "bullcity.social", Just "bullcity.social" ))
            , test "if the post itself can't be seen, still offers the button -- it's a Rellm server" <|
                \_ ->
                    rendered (with "bullcity.social" "abc" QuoteLinks.Unavailable) "rellm.org" (quoting "https://bullcity.social/~abc")
                        |> Expect.all
                            [ lacks [ card ]
                            , Query.has [ addButton ]
                            ]
            ]
        , describe "a quote from a host that isn't (known to be) a Rellm server"
            [ test "a host that failed its preview shows nothing, not even if something is cached for it" <|
                \_ ->
                    rendered (loaded "some-blog.example" "abc") "rellm.org" (quoting "https://some-blog.example/post/abc")
                        |> lacks [ card, addButton ]
            , test "a host we haven't heard back from yet shows nothing -- an ordinary-looking link doesn't flash a loader" <|
                \_ ->
                    rendered (with "new-server.example" "abc" (QuoteLinks.Awaiting { host = "new-server.example", id = "abc" })) "rellm.org" (quoting "https://new-server.example/post/abc")
                        |> lacks [ card, addButton, Selector.class "quoted-post-loading" ]
            ]
        ]
