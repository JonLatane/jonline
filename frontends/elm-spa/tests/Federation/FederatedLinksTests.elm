module Federation.FederatedLinksTests exposing (suite)

{-| `Shared.Federation.FederatedLinks.parse`: which links count as a link to a Bluesky/Mastodon post, in every
shape a Rellm post might carry one -- Rellm's own routes for federated posts (on any Rellm host, or relative),
Bluesky's and Mastodon's own URLs -- and which don't.
-}

import Expect
import Shared.Federation.FederatedLinks as FederatedLinks exposing (Target(..))
import Test exposing (Test, describe, test)


uri : String
uri =
    "at://did:plc:abc123/app.bsky.feed.post/3kxyz"


parses : String -> Maybe Target -> Test
parses link expected =
    test link <|
        \_ -> FederatedLinks.parse link |> Expect.equal expected


suite : Test
suite =
    describe "Shared.Federation.FederatedLinks"
        [ describe "Rellm's own routes for a federated post"
            [ parses "/post/did:plc:abc123~3kxyz@bluesky:" (Just (BlueskyUri uri))
            , parses "https://rellm.org/post/did:plc:abc123~3kxyz@bluesky:" (Just (BlueskyUri uri))
            , parses "rellm.org/post/did:plc:abc123~3kxyz@bluesky:" (Just (BlueskyUri uri))
            , parses "http:///post/did:plc:abc123~3kxyz@bluesky:" (Just (BlueskyUri uri))
            , parses "https://rellm.org/elm/post/did:plc:abc123~3kxyz@bluesky:?x=1#y" (Just (BlueskyUri uri))
            , parses "/~did:plc:abc123~3kxyz@bluesky:" (Just (BlueskyUri uri))
            , parses "/post/at%3A%2F%2Fdid%3Aplc%3Aabc123%2Fapp.bsky.feed.post%2F3kxyz@bluesky:" (Just (BlueskyUri uri))
            , parses "/post/109876@mastodon:mastodon.social" (Just (MastodonStatus { instanceHost = "mastodon.social", statusId = "109876" }))
            , parses "https://jonline.io/post/109876@mastodon:Fosstodon.org" (Just (MastodonStatus { instanceHost = "fosstodon.org", statusId = "109876" }))
            , parses "/~109876@mastodon:mastodon.social" (Just (MastodonStatus { instanceHost = "mastodon.social", statusId = "109876" }))
            ]
        , describe "Bluesky's own links"
            [ parses "https://bsky.app/profile/did:plc:abc123/post/3kxyz" (Just (BlueskyUri uri))
            , parses "https://bsky.app/profile/alice.bsky.social/post/3kxyz" (Just (BlueskyHandle { handle = "alice.bsky.social", rkey = "3kxyz" }))
            , parses "bsky.app/profile/Alice.Bsky.Social/post/3kxyz" (Just (BlueskyHandle { handle = "alice.bsky.social", rkey = "3kxyz" }))
            , parses "https://bsky.app/profile/alice.bsky.social/post/3kxyz?ref=x" (Just (BlueskyHandle { handle = "alice.bsky.social", rkey = "3kxyz" }))
            , parses uri (Just (BlueskyUri uri))
            , parses "at://alice.bsky.social/app.bsky.feed.post/3kxyz" (Just (BlueskyHandle { handle = "alice.bsky.social", rkey = "3kxyz" }))
            , parses "https://bsky.app/profile/alice.bsky.social" Nothing
            , parses "https://bsky.app/profile/alice.bsky.social/feed/3kxyz" Nothing
            , parses "https://example.com/profile/alice.bsky.social/post/3kxyz" Nothing
            , parses "at://did:plc:abc123/app.bsky.feed.like/3kxyz" Nothing
            ]
        , describe "Mastodon's own links, on whatever instance they name"
            [ parses "https://mastodon.social/@alice/109876" (Just (MastodonStatus { instanceHost = "mastodon.social", statusId = "109876" }))
            , parses "https://fosstodon.org/@alice@mastodon.social/109876" (Just (MastodonStatus { instanceHost = "fosstodon.org", statusId = "109876" }))
            , parses "https://mastodon.social/users/alice/statuses/109876" (Just (MastodonStatus { instanceHost = "mastodon.social", statusId = "109876" }))
            , parses "some.instance.example/@alice/109876" (Just (MastodonStatus { instanceHost = "some.instance.example", statusId = "109876" }))
            , parses "https://mastodon.social/@alice/109876/embed?x=1" Nothing
            , parses "https://mastodon.social/@alice" Nothing
            , parses "https://mastodon.social/@alice/not-a-number" Nothing
            , parses "/@alice/109876" Nothing
            ]
        , describe "not federated post links"
            [ test "an empty link" (\_ -> FederatedLinks.parse "" |> Expect.equal Nothing)
            , parses "https://example.com/article" Nothing
            , parses "/post/abc" Nothing
            , parses "https://rellm.org/post/abc" Nothing
            , parses "https://rellm.org/~abc" Nothing
            , parses "/post/abc@jonline.io" Nothing
            , parses "//evil.example/@alice/109876" Nothing
            ]
        , describe "key"
            [ test "distinct posts have distinct keys, and the same post the same one however it's spelled" <|
                \_ ->
                    [ FederatedLinks.parse "https://bsky.app/profile/did:plc:abc123/post/3kxyz"
                    , FederatedLinks.parse "/post/did:plc:abc123~3kxyz@bluesky:"
                    , FederatedLinks.parse "https://mastodon.social/@a/1"
                    , FederatedLinks.parse "https://mastodon.social/@a/2"
                    ]
                        |> List.map (Maybe.map FederatedLinks.key)
                        |> (\keys ->
                                ( List.head keys == List.head (List.drop 1 keys)
                                , List.drop 2 keys |> (\rest -> List.head rest == List.head (List.drop 1 rest))
                                )
                           )
                        |> Expect.equal ( True, False )
            ]
        ]
