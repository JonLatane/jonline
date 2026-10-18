module CreateNewPanelQuoteTests exposing (suite)

{-| How `Shared.CreateNewPanel` treats a quote: opening it from a post's quote button, what the form shows,
and -- the part that matters -- what a save sends. A quote is a `POST` whose `link` is the quoted post's
link; an event never quotes, even when the panel was switched to Event mode with a quote still in it.
-}

import Expect
import Proto.Rellm exposing (Post)
import Proto.Rellm.PostContext exposing (PostContext(..))
import Shared.CreateNewPanel as CreateNewPanel
import Support.PostFactory as PostFactory
import Test exposing (Test, describe, test)


post : PostContext -> Post
post context =
    PostFactory.post { id = "abc", createdAtMillis = 0 } |> (\p -> { p | context = context })


init : CreateNewPanel.Model
init =
    CreateNewPanel.init


quoting : CreateNewPanel.Model
quoting =
    CreateNewPanel.openQuoting "rellm.org" (post POST) init


eventMode : CreateNewPanel.Model -> CreateNewPanel.Model
eventMode model =
    { model | mode = CreateNewPanel.EventMode }


suite : Test
suite =
    describe "Shared.CreateNewPanel quoting"
        [ describe "openQuoting"
            [ test "opens the panel in Post mode, quoting the post by its absolute link" <|
                \_ ->
                    ( quoting.open, quoting.mode == CreateNewPanel.PostMode, quoting.quotedLink )
                        |> Expect.equal ( True, True, Just "https://rellm.org/post/abc" )
            , test "quoting an event links to its /event page" <|
                \_ ->
                    CreateNewPanel.openQuoting "jonline.io" (post EVENT) init
                        |> .quotedLink
                        |> Expect.equal (Just "https://jonline.io/event/abc")
            , test "from Event mode, switches to Post mode" <|
                \_ ->
                    CreateNewPanel.openQuoting "rellm.org" (post POST) (eventMode init)
                        |> .mode
                        |> Expect.equal CreateNewPanel.PostMode
            , test "keeps the rest of an in-progress draft" <|
                \_ ->
                    CreateNewPanel.openQuoting "rellm.org" (post POST) { init | title = "My thoughts", content = "…" }
                        |> (\model -> ( model.title, model.content ))
                        |> Expect.equal ( "My thoughts", "…" )
            ]
        , describe "shownQuote -- what the form displays"
            [ test "the quote, in Post mode" <|
                \_ -> CreateNewPanel.shownQuote quoting |> Expect.equal (Just "https://rellm.org/post/abc")
            , test "nothing in Event mode, though it's still held" <|
                \_ ->
                    ( CreateNewPanel.shownQuote (eventMode quoting), (eventMode quoting).quotedLink )
                        |> Expect.equal ( Nothing, Just "https://rellm.org/post/abc" )
            , test "and back again when switching back to Post mode" <|
                \_ ->
                    eventMode quoting
                        |> (\model -> { model | mode = CreateNewPanel.PostMode })
                        |> CreateNewPanel.shownQuote
                        |> Expect.equal (Just "https://rellm.org/post/abc")
            , test "nothing at all when nothing is quoted" <|
                \_ -> CreateNewPanel.shownQuote init |> Expect.equal Nothing
            ]
        , describe "linkToSave -- what a save sends as the post's link"
            [ test "a Post-mode quote is the link" <|
                \_ -> CreateNewPanel.linkToSave CreateNewPanel.PostMode quoting |> Expect.equal (Just "https://rellm.org/post/abc")
            , test "it replaces a link the user had typed -- a post has just the one" <|
                \_ ->
                    CreateNewPanel.linkToSave CreateNewPanel.PostMode { quoting | link = "https://example.com" }
                        |> Expect.equal (Just "https://rellm.org/post/abc")
            , test "an event never sends the quote, even with one held -- only what was typed" <|
                \_ ->
                    [ CreateNewPanel.linkToSave CreateNewPanel.EventMode quoting
                    , CreateNewPanel.linkToSave CreateNewPanel.EventMode { quoting | link = "  https://example.com/tickets \n" }
                    ]
                        |> Expect.equalLists [ Nothing, Just "https://example.com/tickets" ]
            , test "with no quote, the typed link, trimmed, or none if blank" <|
                \_ ->
                    [ CreateNewPanel.linkToSave CreateNewPanel.PostMode { quoting | quotedLink = Nothing, link = " https://example.com " }
                    , CreateNewPanel.linkToSave CreateNewPanel.PostMode { quoting | quotedLink = Nothing, link = "   " }
                    ]
                        |> Expect.equalLists [ Just "https://example.com", Nothing ]
            , test "removing the quote brings the typed link back" <|
                \_ ->
                    CreateNewPanel.linkToSave CreateNewPanel.PostMode { quoting | link = "https://example.com", quotedLink = Nothing }
                        |> Expect.equal (Just "https://example.com")
            ]
        ]
