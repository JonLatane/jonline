module Shared.Federation.Mastodon exposing
    ( Status
    , decoder
    , fetchPosts
    , toPost
    )

{-| Translates Mastodon's REST API into Jonline's `Post` shape, entirely client-side -- see
`Ports.facebookLoginPopup`'s `"mastodon"` provider doc and `Shared.AccountsPanel.MastodonAccount`'s
own doc for the connection side this feeds off of. `fetchPosts` is called from
`Components.Pages.PostsPage.fetchFeedSource`'s `MastodonInstance` case -- see `FeedSource`'s own doc
for how a Mastodon instance's feed is fetched/stored/animated alongside a real Jonline server's.
-}

import Http
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Proto.Jonline exposing (Author, Post, defaultAuthor, defaultMediaReference, defaultPost)
import Proto.Jonline.PostContext exposing (PostContext(..))
import Proto.Jonline.Visibility exposing (Visibility(..))
import Shared.Conversions exposing (posixToTimestamp)
import Shared.Federation.Common exposing (jsonResolver, nonEmpty)
import Task exposing (Task)
import Time


{-| Just the fields of Mastodon's `Status` entity (one element of
`GET /api/v1/timelines/public`'s response array) that `toPost` actually needs -- see
<https://docs.joinmastodon.org/entities/Status/>.
-}
type alias Status =
    { id : String
    , url : Maybe String
    , content : String
    , createdAt : Time.Posix
    , inReplyToId : Maybe String
    , authorUsername : String
    , authorDisplayName : Maybe String
    , authorAvatarUrl : Maybe String
    }


decoder : Decoder Status
decoder =
    Decode.map8 Status
        (Decode.field "id" Decode.string)
        (Decode.maybe (Decode.field "url" Decode.string))
        (Decode.field "content" Decode.string)
        (Decode.field "created_at" Iso8601.decoder)
        (Decode.maybe (Decode.field "in_reply_to_id" Decode.string))
        (Decode.at [ "account", "username" ] Decode.string)
        (Decode.at [ "account", "display_name" ] Decode.string |> Decode.map nonEmpty)
        (Decode.at [ "account", "avatar" ] Decode.string |> Decode.map nonEmpty)


{-| A `Status`'s translation into a Jonline `Post` -- `id` is namespaced
(`"mastodon:" ++ instanceHost ++ ":" ++ status.id`) so it can never collide with a real Jonline
post's own id (a plain integer string) wherever the two get keyed together (e.g.
`Components.Pages.PostsPage.postAnimationKey`). `content` is left as Mastodon's own sanitized HTML
(Mastodon strips dangerous tags server-side before ever serving it back), not converted to/from
Markdown. `visibility` is always `GLOBALPUBLIC`: a `Status` fetched off a public timeline endpoint
is definitionally public. `author.avatar` uses `MediaReference.url` (see that field's own doc in
`protos/media.proto`) rather than `id`, since this avatar isn't and never will be Jonline-hosted
media.
-}
toPost : String -> Status -> Post
toPost instanceHost status =
    { defaultPost
        | id = "mastodon:" ++ instanceHost ++ ":" ++ status.id
        , author = Just (toAuthor instanceHost status)
        , content = Just status.content
        , link = status.url
        , context =
            if status.inReplyToId /= Nothing then
                REPLY

            else
                POST
        , visibility = GLOBALPUBLIC
        , createdAt = Just (posixToTimestamp status.createdAt)
        , lastActivityAt = Just (posixToTimestamp status.createdAt)
    }


{-| `GET /api/v1/timelines/public?local=true&limit=20` -- the local (this-instance-only) public
timeline, unauthenticated, already translated via `toPost`. `local=true` rather than the federated
(whole-known-network) timeline, since connecting one instance shouldn't implicitly pull in every
server it happens to federate with too -- mirrors Jonline's own `ALL_ACCESSIBLE_POSTS` being scoped
to *this* server's own posts, not every server it's federated with either.
-}
fetchPosts : String -> Task Http.Error (List Post)
fetchPosts instanceHost =
    Http.task
        { method = "GET"
        , headers = []
        , url = "https://" ++ instanceHost ++ "/api/v1/timelines/public?local=true&limit=20"
        , body = Http.emptyBody
        , resolver = jsonResolver (Decode.list decoder) (\metadata _ -> Http.BadStatus metadata.statusCode)
        , timeout = Just 10000
        }
        |> Task.map (List.map (toPost instanceHost))


toAuthor : String -> Status -> Author
toAuthor instanceHost status =
    { defaultAuthor
        | userId = "mastodon:" ++ instanceHost ++ ":" ++ status.authorUsername
        , username = Just (status.authorUsername ++ "@" ++ instanceHost)
        , realName = status.authorDisplayName
        , avatar = status.authorAvatarUrl |> Maybe.map (\url -> { defaultMediaReference | url = Just url })
    }
