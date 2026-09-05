module JonlineTests exposing (suite)

{-| Tests for the main Jonline protocol's own multi-server post model -- specifically
`Components.Posts.postTimestamp`, the single function every server's (and, per
`Federation.MastodonTests`/`Federation.BlueskyTests`, every federated protocol's translated) posts
are sorted by wherever they're merged into one feed (see
`Components.Pages.PostsPage.postsListView`'s `sortedAnimations`). The cross-protocol test below is
the actual point of this whole feature: proving a real Jonline `Post` and a translated Mastodon/
Bluesky one sort correctly against each other, not just within their own protocol.
-}

import Components.Posts as Posts
import Expect
import Proto.Jonline exposing (Post)
import Shared.Conversions exposing (posixToTimestamp)
import Shared.Federation.Bluesky as Bluesky
import Shared.Federation.Mastodon as Mastodon
import Support.BlueskyFactory as BlueskyFactory
import Support.MastodonFactory as MastodonFactory
import Support.PostFactory as PostFactory
import Test exposing (Test, describe, test)
import Time


suite : Test
suite =
    describe "Components.Posts.postTimestamp"
        [ test "prefers publishedAt over createdAt when both are set" <|
            \_ ->
                let
                    post : Post
                    post =
                        PostFactory.post { id = "1", createdAtMillis = 1000 }

                    published : Post
                    published =
                        { post | publishedAt = Just (posixToTimestamp (Time.millisToPosix 2000)) }
                in
                Posts.postTimestamp published
                    |> Expect.equal (Time.millisToPosix 2000)
        , test "falls back to createdAt when publishedAt is unset" <|
            \_ ->
                PostFactory.post { id = "1", createdAtMillis = 5000 }
                    |> Posts.postTimestamp
                    |> Expect.equal (Time.millisToPosix 5000)
        , test "falls back to the epoch when neither is set" <|
            \_ ->
                let
                    blank : Post
                    blank =
                        PostFactory.post { id = "1", createdAtMillis = 5000 }
                            |> (\post -> { post | createdAt = Nothing, publishedAt = Nothing })
                in
                Posts.postTimestamp blank
                    |> Expect.equal (Time.millisToPosix 0)
        , describe "sorting across protocols (the actual point of this feature)"
            [ test "a Jonline post, a translated Mastodon post, and a translated Bluesky post all sort together by time" <|
                \_ ->
                    let
                        -- Oldest: just before the Mastodon fixture's own 2023-04-05T12:00:00.000Z
                        -- (see Support.MastodonFactory's doc on that instant's millisecond value).
                        jonlinePost : Post
                        jonlinePost =
                            PostFactory.post { id = "42", createdAtMillis = 1680695000000 }

                        mastodonPost : Post
                        mastodonPost =
                            Mastodon.toPost "mastodon.social" (MastodonFactory.status MastodonFactory.defaultOverrides)

                        -- Newest: two thousand seconds after the Mastodon fixture's own instant.
                        blueskyPost : Post
                        blueskyPost =
                            Bluesky.toPost (BlueskyFactory.feedPost { defaultBlueskyOverrides | createdAtMillis = 1680697000000 })

                        defaultBlueskyOverrides : BlueskyFactory.Overrides
                        defaultBlueskyOverrides =
                            BlueskyFactory.defaultOverrides

                        sortedIds : List String
                        sortedIds =
                            [ jonlinePost, mastodonPost, blueskyPost ]
                                |> List.sortBy (Posts.postTimestamp >> Time.posixToMillis)
                                |> List.map .id
                    in
                    sortedIds
                        |> Expect.equal
                            [ "42"
                            , "mastodon:mastodon.social:110224857075517327"
                            , "bluesky:at://did:plc:abc123/app.bsky.feed.post/xyz789"
                            ]
            ]
        ]
