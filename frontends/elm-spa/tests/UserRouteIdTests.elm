module UserRouteIdTests exposing (suite)

import Components.Users as Users
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Users.parseUserRouteId"
        [ test "a bare username is on the main host" <|
            \_ ->
                Users.parseUserRouteId "rellm.org" "jon"
                    |> Expect.equal ( "jon", "rellm.org" )
        , test "username@host splits on the @" <|
            \_ ->
                Users.parseUserRouteId "rellm.org" "jon@other.org"
                    |> Expect.equal ( "jon", "other.org" )
        , test "a percent-encoded non-ASCII username is decoded" <|
            \_ ->
                Users.parseUserRouteId "rellm.org" "jos%C3%A9"
                    |> Expect.equal ( "josé", "rellm.org" )
        , test "a bare @bluesky host means @bluesky:" <|
            \_ ->
                Users.parseUserRouteId "rellm.org" "reggiegraham.bsky.social@bluesky"
                    |> Expect.equal ( "reggiegraham.bsky.social", "bluesky:" )
        , test "@bluesky: is still accepted" <|
            \_ ->
                Users.parseUserRouteId "rellm.org" "reggiegraham.bsky.social@bluesky:"
                    |> Expect.equal ( "reggiegraham.bsky.social", "bluesky:" )
        ]
