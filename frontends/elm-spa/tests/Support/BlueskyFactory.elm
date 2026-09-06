module Support.BlueskyFactory exposing (Overrides, defaultOverrides, feedPost, feedViewPostJson)

{-| Test fixtures for `Shared.Federation.Bluesky` -- mirrors `Support.MastodonFactory` exactly:
`feedPost`/`feedViewPostJson` are two views of the same `Overrides` record, so a test can decode
`feedViewPostJson overrides` and compare it against `feedPost overrides` -- see
`Federation.BlueskyTests`' decoder suite.
-}

import Json.Encode as Encode
import Shared.Federation.Bluesky exposing (FeedPost)
import Time


{-| A `FeedPost`'s test-relevant fields, all overridable from `defaultOverrides`. `createdAtIso`/
`createdAtMillis` have to be kept in sync by hand -- see `Support.MastodonFactory.Overrides`' own
doc on the reference value both are built from (the same instant, 2023-04-05T12:00:00.000Z).
-}
type alias Overrides =
    { uri : String
    , text : String
    , createdAtIso : String
    , createdAtMillis : Int
    , isReply : Bool
    , handle : String
    , displayName : Maybe String
    , avatar : Maybe String
    }


defaultOverrides : Overrides
defaultOverrides =
    { uri = "at://did:plc:abc123/app.bsky.feed.post/xyz789"
    , text = "hello bluesky"
    , createdAtIso = "2023-04-05T12:00:00.000Z"
    , createdAtMillis = 1680696000000
    , isReply = False
    , handle = "alice.bsky.social"
    , displayName = Just "Alice"
    , avatar = Just "https://cdn.bsky.app/img/avatar/alice.jpg"
    }


feedPost : Overrides -> FeedPost
feedPost overrides =
    { uri = overrides.uri
    , text = overrides.text
    , createdAt = Time.millisToPosix overrides.createdAtMillis
    , isReply = overrides.isReply
    , authorHandle = overrides.handle
    , authorDisplayName = overrides.displayName
    , authorAvatarUrl = overrides.avatar
    }


{-| `reply`/`root`/`parent` refs are left as empty objects when `overrides.isReply` -- `decoder`
only ever checks whether the top-level `"reply"` key is present at all (see its own doc), never
what's inside it, so there's nothing worth fabricating there.
-}
feedViewPostJson : Overrides -> String
feedViewPostJson overrides =
    Encode.encode 0
        (Encode.object
            (( "post"
             , Encode.object
                [ ( "uri", Encode.string overrides.uri )
                , ( "cid", Encode.string "bafyreicid" )
                , ( "author", authorJson overrides )
                , ( "record"
                  , Encode.object
                        [ ( "$type", Encode.string "app.bsky.feed.post" )
                        , ( "text", Encode.string overrides.text )
                        , ( "createdAt", Encode.string overrides.createdAtIso )
                        ]
                  )
                , ( "indexedAt", Encode.string overrides.createdAtIso )
                ]
             )
                :: (if overrides.isReply then
                        [ ( "reply", Encode.object [ ( "root", Encode.object [] ), ( "parent", Encode.object [] ) ] ) ]

                    else
                        []
                   )
            )
        )


authorJson : Overrides -> Encode.Value
authorJson overrides =
    Encode.object
        ([ ( "did", Encode.string "did:plc:test" )
         , ( "handle", Encode.string overrides.handle )
         ]
            ++ (overrides.displayName |> Maybe.map (\d -> [ ( "displayName", Encode.string d ) ]) |> Maybe.withDefault [])
            ++ (overrides.avatar |> Maybe.map (\a -> [ ( "avatar", Encode.string a ) ]) |> Maybe.withDefault [])
        )
