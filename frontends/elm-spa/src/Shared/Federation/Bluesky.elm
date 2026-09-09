module Shared.Federation.Bluesky exposing
    ( FeedPost
    , decoder
    , fetchPost
    , fetchPosts
    , searchPosts
    , toPost
    )

{-| Translates Bluesky's (AT Protocol) API into Rellm's `Post` shape, entirely client-side -- see
`Shared.AccountsPanel.BlueskyAccount`'s own doc for the connection side this feeds off of. Unlike
Mastodon, there's no meaningful *unauthenticated* equivalent: a bare "public timeline" isn't a
concept AT Proto's federated network has (every PDS only ever serves its own users' own posts/feeds,
not a "local instance timeline" the way a Mastodon server does), so `fetchPosts` is a connected
account's own home timeline; `searchPosts`/`fetchPost` are both exceptions -- real endpoints that
read the wider public network rather than just the connected account's own timeline, still requiring
the same auth (there's no anonymous access to anything on Bluesky, unlike Mastodon). See
`Components.Pages.PostsPage.fetchFeedSource`'s `BlueskyFeed` case (`fetchPosts`/`searchPosts`) and
`Components.Pages.PostPage.init` (`fetchPost`, when a route's post id parses as
`Components.Posts.BlueskyPostId`) for how each gets wired into a real page.
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
import Url


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


{-| A `FeedPost`'s translation into a Rellm `Post` -- `id` is just the bare `feedPost.uri` (an
`at://` URI, already globally unique on its own -- it embeds the author's DID), *not* further
prefixed with `"bluesky:"` the way it briefly was, mirroring `Shared.Federation.Mastodon.toPost`'s
own bare `status.id` -- see that function's own doc on why (a federated post's `id` is never used
without its synthetic host alongside it, which already carries the `"bluesky:"` tag). `link` is a
real `https://bsky.app/...` URL (see `webUrl`) built from the `at://` URI, since that's meaningless
to a browser directly. `visibility` is always `GLOBALPUBLIC`: everything in a Bluesky timeline is
already public (AT Protocol has no private-post concept at all). `author.avatar` uses
`MediaReference.url`, same reasoning as Mastodon's own translation.
-}
toPost : FeedPost -> Post
toPost feedPost =
    { defaultPost
        | id = feedPost.uri
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


{-| `GET /xrpc/app.bsky.feed.searchPosts` -- Bluesky's real search endpoint, searching the whole
public network (not just the connected account's own timeline/follows) -- see
<https://docs.bsky.app/docs/api/app-bsky-feed-search-posts>. Requires auth despite that broad scope
(confirmed empirically: an unauthenticated request gets a clean `AuthMissing` JSON error, not a
network/CORS failure), so this is only ever called for an already-connected `BlueskyAccount` -- see
`Components.Pages.PostsPage.fetchFeedSource`'s `BlueskyFeed` case, which switches to this instead of
`fetchPosts` whenever `model.searchText` isn't blank, mirroring how a real `GetPosts` request switches
to `TEXTSEARCH`. Unlike `getTimeline`'s `feed` array (each entry wrapping a `post` alongside separate
`reply` context), each entry here is a bare `app.bsky.feed.defs#postView` directly, so `searchDecoder`
reads its fields one level shallower than `decoder` does, and detects a reply via the post's own
`record.reply` field being present (the same information `getTimeline`'s sibling `reply` field
carries, just nested differently here) rather than a sibling key.
-}
searchPosts : String -> String -> Task Http.Error (List Post)
searchPosts accessToken query =
    Http.task
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ accessToken) ]
        , url = "https://bsky.social/xrpc/app.bsky.feed.searchPosts?q=" ++ Url.percentEncode query ++ "&limit=20"
        , body = Http.emptyBody
        , resolver = jsonResolver (Decode.field "posts" (Decode.list searchDecoder)) (\metadata _ -> Http.BadStatus metadata.statusCode)
        , timeout = Just 10000
        }
        |> Task.map (List.map toPost)


searchDecoder : Decoder FeedPost
searchDecoder =
    Decode.map7 FeedPost
        (Decode.field "uri" Decode.string)
        (Decode.at [ "record", "text" ] Decode.string)
        (Decode.at [ "record", "createdAt" ] Iso8601.decoder)
        (Decode.maybe (Decode.at [ "record", "reply" ] Decode.value) |> Decode.map ((/=) Nothing))
        (Decode.at [ "author", "handle" ] Decode.string)
        (Decode.maybe (Decode.at [ "author", "displayName" ] Decode.string) |> Decode.map (Maybe.andThen nonEmpty))
        (Decode.maybe (Decode.at [ "author", "avatar" ] Decode.string))


{-| `GET /xrpc/app.bsky.feed.getPosts` for a single `uri` -- a real single-post lookup by AT URI,
authenticated the same way `searchPosts` is (any connected account's token works; this reads public
data regardless of whose token it is). A batch API in general (`uris` takes a comma-separated list),
but always called here with exactly one, so `Decode.field "posts"` is expected to come back with
either one element or none (deleted/never-existed) -- the latter fails the whole decode, surfacing as
an `Http.Error` the same as any other not-found. Response items are the same bare
`app.bsky.feed.defs#postView` shape `searchPosts` gets, so this reuses `searchDecoder` too.
-}
fetchPost : String -> String -> Task Http.Error Post
fetchPost accessToken uri =
    Http.task
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ accessToken) ]
        , url = "https://bsky.social/xrpc/app.bsky.feed.getPosts?uris=" ++ Url.percentEncode uri
        , body = Http.emptyBody
        , resolver =
            jsonResolver
                (Decode.field "posts" (Decode.list searchDecoder)
                    |> Decode.andThen
                        (\posts ->
                            case posts of
                                first :: _ ->
                                    Decode.succeed first

                                [] ->
                                    Decode.fail "post not found"
                        )
                )
                (\metadata _ -> Http.BadStatus metadata.statusCode)
        , timeout = Just 10000
        }
        |> Task.map toPost


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
