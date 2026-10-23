module PostOrEventPageTests exposing (suite)

{-| `Components.Pages.PostOrEventPage.federatedPostOf`: a short URL (`/~id`, `/:id`, ...) for a Bluesky or Mastodon post
is recognized as one -- and goes to its own page, like `/post/…@bluesky:` does -- instead of being treated as a Rellm id
to look up on a server called `bluesky:`, which never resolved.
-}

import Components.Pages.PostOrEventPage as PostOrEventPage
import Components.Posts as Posts exposing (FederatedPostId(..))
import Expect
import Test exposing (Test, describe, test)


blueskyUri : String
blueskyUri =
    "at://did:plc:wv5mhfadfpt6wmvoxedgqzyw/app.bsky.feed.post/3mte7ozu3qc2s"


recognized : String -> Maybe FederatedPostId -> Test
recognized segment expected =
    test segment <|
        \_ -> PostOrEventPage.federatedPostOf "rellm.org" segment |> Expect.equal expected


suite : Test
suite =
    describe "PostOrEventPage.federatedPostOf"
        [ describe "Bluesky"
            [ recognized "~did:plc:wv5mhfadfpt6wmvoxedgqzyw~3mte7ozu3qc2s@bluesky:" (Just (BlueskyPostId { uri = blueskyUri }))
            , recognized ":did:plc:wv5mhfadfpt6wmvoxedgqzyw~3mte7ozu3qc2s@bluesky:" (Just (BlueskyPostId { uri = blueskyUri }))
            , recognized "~did:plc:wv5mhfadfpt6wmvoxedgqzyw~3mte7ozu3qc2s@bluesky" (Just (BlueskyPostId { uri = blueskyUri }))
            ]
        , describe "Mastodon"
            [ recognized "~109876543210@mastodon:mastodon.social" (Just (MastodonPostId { instanceHost = "mastodon.social", statusId = "109876543210" }))
            , recognized ":117462924798124768@mastodon:mastodon.world" (Just (MastodonPostId { instanceHost = "mastodon.world", statusId = "117462924798124768" }))
            ]
        , describe "Rellm ids are not federated"
            [ recognized "~4rAfoSKAuJo" Nothing
            , recognized ":4rAfoSKAuJo" Nothing
            , recognized "~4rAfoSKAuJo@jonline.io" Nothing
            , recognized "~" Nothing
            ]
        , test "it agrees with what /post/:id's own route segment parses to" <|
            \_ ->
                let
                    routeSegment : String
                    routeSegment =
                        "did:plc:wv5mhfadfpt6wmvoxedgqzyw~3mte7ozu3qc2s@bluesky:"

                    ( id, host ) =
                        Posts.parsePostRouteId "rellm.org" routeSegment
                in
                PostOrEventPage.federatedPostOf "rellm.org" ("~" ++ routeSegment)
                    |> Expect.equal (Posts.parseFederatedPostId id host)
        ]
