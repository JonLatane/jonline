module Shared.Federation.Bluesky exposing
    ( FeedPost
    , decoder
    , fetchPosts
    , toPost
    )

{-| Translates Bluesky's (AT Protocol) API into Rellm's `Post` shape, entirely client-side -- see
`Shared.AccountsPanel.BlueskyAccount`'s own doc for the connection side this feeds off of. Unlike
Mastodon, there's no meaningful *unauthenticated* equivalent: a bare "public timeline" isn't a
concept AT Proto's federated network has (every PDS only ever serves its own users' own posts/feeds,
not a "local instance timeline" the way a Mastodon server does), so `fetchPosts` is a connected
account's own home timeline. See `Components.Pages.PostsPage.fetchFeedSource`'s `BlueskyFeed` case
(and `FeedSource`'s own doc) for how that gets wired into a real page.
-}

import Http
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Proto.Rellm exposing (Author, Post, defaultAuthor, defaultMediaReference, defaultPost)
import Proto.Rellm.PostContext exposing (PostContext(..))
import Proto.Rellm.Visibility exposing (Visibility(..))
import Shared.Conversions exposing (posixToTimestamp)
import Shared.Federation.Common exposing (jsonResolver, nonEmpty)
import Task exposing (Task)
import Time


{-| Just the fields of one `app.bsky.feed.defs#feedViewPost` (one element of
`GET /xrpc/app.bsky.feed.getTimeline`'s `feed` array) that `toPost` actually needs -- see
<https://docs.bsky.app/docs/api/app-bsky-feed-get-timeline>. `uri` is the post's `at://` URI
(`at://{did}/app.bsky.feed.post/{rkey}`), used both as this post's own identity and (via `webUrl`)
to build a real `https://bsky.app/...` link a browser can actually open.
-}
type alias FeedPost =
    { uri : String
    , text : String
    , createdAt : Time.Posix
    , isReply : Bool
    , authorHandle : String
    , authorDisplayName : Maybe String
    , authorAvatarUrl : Maybe String
    }


decoder : Decoder FeedPost
decoder =
    Decode.map7 FeedPost
        (Decode.at [ "post", "uri" ] Decode.string)
        (Decode.at [ "post", "record", "text" ] Decode.string)
        (Decode.at [ "post", "record", "createdAt" ] Iso8601.decoder)
        (Decode.maybe (Decode.field "reply" Decode.value) |> Decode.map ((/=) Nothing))
        (Decode.at [ "post", "author", "handle" ] Decode.string)
        (Decode.maybe (Decode.at [ "post", "author", "displayName" ] Decode.string) |> Decode.map (Maybe.andThen nonEmpty))
        (Decode.maybe (Decode.at [ "post", "author", "avatar" ] Decode.string))


{-| A `FeedPost`'s translation into a Rellm `Post` -- `id` is namespaced (`"bluesky:" ++
feedPost.uri`, already globally unique on its own -- an `at://` URI embeds the author's DID) so it
can never collide with a real Rellm post's own id, mirroring
`Shared.Federation.Mastodon.toPost`'s own `"mastodon:"` namespacing. `link` is a real
`https://bsky.app/...` URL (see `webUrl`) built from the `at://` URI, since that's meaningless to a
browser directly. `visibility` is always `GLOBALPUBLIC`: everything in a Bluesky timeline is
already public (AT Protocol has no private-post concept at all). `author.avatar` uses
`MediaReference.url`, same reasoning as Mastodon's own translation.
-}
toPost : FeedPost -> Post
toPost feedPost =
    { defaultPost
        | id = "bluesky:" ++ feedPost.uri
        , author = Just (toAuthor feedPost)
        , content = Just feedPost.text
        , link = Just (webUrl feedPost)
        , context =
            if feedPost.isReply then
                REPLY

            else
                POST
        , visibility = GLOBALPUBLIC
        , createdAt = Just (posixToTimestamp feedPost.createdAt)
        , lastActivityAt = Just (posixToTimestamp feedPost.createdAt)
    }


{-| `GET /xrpc/app.bsky.feed.getTimeline` against `bsky.social` (see `BlueskyAccount`'s own doc on
that fixed-PDS limitation), authenticated with `accessToken`, already translated via `toPost` -- the
connected account's own algorithmic home timeline (reverse-chronological-following, by default), the
AT Protocol equivalent of `ALL_ACCESSIBLE_POSTS`.
-}
fetchPosts : String -> Task Http.Error (List Post)
fetchPosts accessToken =
    Http.task
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ accessToken) ]
        , url = "https://bsky.social/xrpc/app.bsky.feed.getTimeline?limit=20"
        , body = Http.emptyBody
        , resolver = jsonResolver (Decode.field "feed" (Decode.list decoder)) (\metadata _ -> Http.BadStatus metadata.statusCode)
        , timeout = Just 10000
        }
        |> Task.map (List.map toPost)


{-| `at://{did}/app.bsky.feed.post/{rkey}` -> `https://bsky.app/profile/{handle}/post/{rkey}` --
the `rkey` (record key) is always the URI's last `/`-separated segment, regardless of the
collection/DID that precede it.
-}
webUrl : FeedPost -> String
webUrl feedPost =
    "https://bsky.app/profile/"
        ++ feedPost.authorHandle
        ++ "/post/"
        ++ (feedPost.uri |> String.split "/" |> List.reverse |> List.head |> Maybe.withDefault "")


toAuthor : FeedPost -> Author
toAuthor feedPost =
    { defaultAuthor
        | userId = "bluesky:" ++ feedPost.authorHandle
        , username = Just feedPost.authorHandle
        , realName = feedPost.authorDisplayName
        , avatar = feedPost.authorAvatarUrl |> Maybe.map (\url -> { defaultMediaReference | url = Just url })
    }
