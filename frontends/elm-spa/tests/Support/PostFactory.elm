module Support.PostFactory exposing (post)

{-| A minimal Rellm `Post` builder for tests that don't care about most fields -- unlike
`Support.MastodonFactory`/`Support.BlueskyFactory` (which fabricate a third-party API's JSON, since
that's genuinely complex enough to need a factory), `Proto.Rellm`'s own generated `defaultPost`
already is the factory for a real Rellm value -- this just wraps it with the two fields tests
actually vary: `id` and a timestamp.
-}

import Proto.Rellm exposing (Post, defaultPost)
import Shared.Conversions exposing (posixToTimestamp)
import Time


{-| `defaultPost` with `id`/`createdAt`/`lastActivityAt` set from the given millisecond instant --
enough for `Components.Posts.postTimestamp`-based sorting tests, which is what this exists for (see
`RellmTests`).
-}
post : { id : String, createdAtMillis : Int } -> Post
post { id, createdAtMillis } =
    { defaultPost
        | id = id
        , createdAt = Just (posixToTimestamp (Time.millisToPosix createdAtMillis))
        , lastActivityAt = Just (posixToTimestamp (Time.millisToPosix createdAtMillis))
    }
