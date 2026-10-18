module QuotedPostProtoTests exposing (suite)

{-| `Post.quotedPost` (protos/posts.proto, field 27) survives the same binary encode/decode the gRPC-Web client
does for every Post -- including a quoted post that itself quotes another, which is how a post's page shows a
chain of them. (Only the Elm client ever sets it: see `Shared.Federation.Bluesky`/`Mastodon`, and
`Components.QuotedLink` for how a Rellm post's `link` becomes one.)
-}

import Expect
import Proto.Rellm exposing (Post, decodePost, defaultPost, encodePost, unwrapPost, wrapPost)
import Protobuf.Decode as Decode
import Protobuf.Encode as Encode
import Test exposing (Test, describe, test)


roundTrip : Post -> Maybe Post
roundTrip post =
    Decode.decode decodePost (Encode.encode (encodePost post))


suite : Test
suite =
    describe "Post.quotedPost"
        [ test "a quoted post round-trips" <|
            \_ ->
                { defaultPost | id = "2", quotedPost = Just (wrapPost { defaultPost | id = "1", content = Just "quoted" }) }
                    |> roundTrip
                    |> Maybe.andThen .quotedPost
                    |> Maybe.map (unwrapPost >> .content)
                    |> Expect.equal (Just (Just "quoted"))
        , test "a chain of quotes round-trips" <|
            \_ ->
                let
                    first : Post
                    first =
                        { defaultPost | id = "1", content = Just "first" }

                    second : Post
                    second =
                        { defaultPost | id = "2", content = Just "second", quotedPost = Just (wrapPost first) }
                in
                { defaultPost | id = "3", quotedPost = Just (wrapPost second) }
                    |> roundTrip
                    |> Maybe.andThen .quotedPost
                    |> Maybe.andThen (unwrapPost >> .quotedPost)
                    |> Maybe.map (unwrapPost >> .content)
                    |> Expect.equal (Just (Just "first"))
        , test "no quote stays Nothing" <|
            \_ ->
                { defaultPost | id = "1" }
                    |> roundTrip
                    |> Maybe.map (\post -> post.quotedPost == Nothing)
                    |> Expect.equal (Just True)
        ]
