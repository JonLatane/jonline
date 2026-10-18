module EventRoutingTests exposing (suite)

{-| How a post id becomes an event page: `Components.Events.occasionFor` (a `/event/:id` route id may be an
occasion's own post id, or the event's -- which is what `/post/:id` of an event carries) and `eventHref`,
what `Pages.Post.PostId_` redirects an `EVENT`/`OCCASION` post to.
-}

import Components.Events as Events
import Expect
import Proto.Rellm exposing (Event, Occasion, defaultEvent, defaultOccasion)
import Proto.Rellm.PostContext exposing (PostContext(..))
import Support.PostFactory as PostFactory
import Test exposing (Test, describe, test)


occasion : String -> Occasion
occasion id =
    { defaultOccasion | post = Just (PostFactory.post { id = id, createdAtMillis = 0 } |> (\post -> { post | context = OCCASION })) }


event : Event
event =
    { defaultEvent
        | post = Just (PostFactory.post { id = "ev", createdAtMillis = 0 } |> (\post -> { post | context = EVENT }))
        , occasions = [ occasion "o1", occasion "o2" ]
    }


idOf : Maybe Occasion -> Maybe String
idOf =
    Maybe.andThen .post >> Maybe.map .id


suite : Test
suite =
    describe "event routing"
        [ describe "occasionFor"
            [ test "an occasion's own post id finds that occasion" <|
                \_ -> Events.occasionFor "o2" event |> idOf |> Expect.equal (Just "o2")
            , test "the event's own post id finds its first occasion" <|
                \_ -> Events.occasionFor "ev" event |> idOf |> Expect.equal (Just "o1")
            , test "any other id finds nothing" <|
                \_ -> Events.occasionFor "nope" event |> idOf |> Expect.equal Nothing
            , test "an event with no occasions has nothing to show, even by its own id" <|
                \_ -> Events.occasionFor "ev" { event | occasions = [] } |> idOf |> Expect.equal Nothing
            ]
        , describe "eventHref"
            [ test "on the viewing server, just the id" <|
                \_ -> Events.eventHref "" "rellm.org" "rellm.org" "ev" |> Expect.equal "/event/ev"
            , test "on another server, id@host" <|
                \_ -> Events.eventHref "" "rellm.org" "jonline.io" "ev" |> Expect.equal "/event/ev@jonline.io"
            , test "under a base path" <|
                \_ -> Events.eventHref "/elm" "rellm.org" "rellm.org" "ev" |> Expect.equal "/elm/event/ev"
            ]
        ]
