module Components.Posts exposing
    ( allModerations
    , allVisibilities
    , allowedVisibilities
    , commentCountText
    , contentPreviewFadeThreshold
    , deletePost
    , fetchAncestors
    , fetchPost
    , fetchPosts
    , fetchReplies
    , isAuthor
    , mediaEditButton
    , moderationFromText
    , parsePostRouteId
    , postCard
    , postCommentCount
    , postContextLabel
    , postDetail
    , postHref
    , postLinkText
    , postTimestamp
    , postTitleText
    , postVisibilityText
    , repliesCountText
    , replyCard
    , starButton
    , stripLinkScheme
    , timestampsText
    , updatePost
    , visibilityFromText
    , visibilityText
    , whenText
    )

{-| Shared building blocks for displaying `Proto.Jonline.Post`s -- the compact
`postCard` used in the Home page's recent-posts feed, the fuller `postDetail`
used by the Post page, and the fetch/link helpers both (and any future
Post-related page) need: building a `GetPosts` request against a specific
`Shared.AccountsPanel.Server` (optionally authenticated, via
`Shared.MaybeAccountRequest`), and building/parsing the `/post/:postId`
route's `id` or `id@host` segment.
-}

import Components.Authors as Authors
import Components.Markdown as Markdown
import Components.MultiMediaRenderer as MultiMediaRenderer
import Components.Users as Users
import Gen.Route
import Grpc
import Html exposing (Html, a, button, div, h1, span, text)
import Html.Attributes exposing (attribute, class, href, rel, style, target, title)
import Html.Events
import Proto.Jonline exposing (GetPostsResponse, Post, defaultGetPostsRequest, defaultPost)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.Moderation exposing (Moderation(..))
import Proto.Jonline.Permission exposing (Permission(..))
import Proto.Jonline.PostContext exposing (PostContext(..))
import Proto.Jonline.PostListingType exposing (PostListingType(..))
import Proto.Jonline.Visibility exposing (Visibility(..))
import Shared.AccountsPanel as AccountsPanel exposing (performWithAccountServer, performWithOptionalAccountServer, withAccessToken)
import Shared.BrowserTimeZone as BrowserTimeZone exposing (BrowserTimeZone)
import Shared.Conversions exposing (int64ToInt, posixToTimestamp, timestampToPosix)
import Task exposing (Task)
import Time
import UI.Classes exposing (classes, hostnameToCSSClass)
import UI.HtmlEvents exposing (stopPropagationAndPreventDefaultOnClick)


{-| Fetches a single post (including reply/preview data) from
`maybeAccountServer`'s server, authenticated as its account if any, anonymous
otherwise. Returns a `Msg` to dispatch (via whatever out-msg/`Effect`
mechanism the caller already uses) if a token refresh happened, so the
caller never has to know an `Account`/`AccessTokenResponse` was even
involved -- see `Shared.AccountsPanel.performWithOptionalAccountServer`.
-}
fetchPost :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetPostsResponse )
fetchPost accountsPanelModel maybeAccountServer postId =
    performWithOptionalAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server maybeToken ->
            Grpc.new Jonline.getPosts { defaultGetPostsRequest | postId = Just postId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken maybeToken
                |> Grpc.toTask
        )


{-| Fetches posts from `maybeAccountServer`'s server, authenticated as its
account if any (so e.g. followed-user/group posts are included too) --
otherwise identical to `fetchPost`. `authorUserId`, if given, restricts the
results to that user's posts (see `GetPostsRequest`'s `{listing_type:
AuthorPosts, author_user_id:}` form), for `Components.Pages.PostsPage`'s use
on a user's own posts page.

`searchText`, if non-blank (leading/trailing whitespace is trimmed, and a
blank string is treated the same as empty), switches the request to
`TEXT_SEARCH` -- otherwise this is the same "most recent publicly-accessible
posts" request `fetchRecentPosts` used to be. `context` is sent either way
(`GetPosts`' `TEXT_SEARCH` and default `ALL_ACCESSIBLE_POSTS` branches both
read it -- see `backend/src/rpcs/posts/get_posts.rs`), so
`Components.Pages.PostsPage`'s POST/REPLY chooser works whether or not
there's search text entered.

`publishedOrCreatedBefore`, if given, is sent as `GetPostsRequest`'s own
field of the same name -- `Components.Pages.PostsPage`'s "Posts Before
<date>" tab's cutoff (see that module's `PostsBeforeDate` tab), restricting
results to posts published (or, absent that, created) before it. `Nothing`
for the default "Recent Posts" tab, same as every other unset-filter
convention here.

-}
fetchPosts :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> Maybe String
    -> String
    -> PostContext
    -> Maybe Time.Posix
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetPostsResponse )
fetchPosts accountsPanelModel maybeAccountServer authorUserId searchText context publishedOrCreatedBefore =
    let
        trimmedSearchText =
            String.trim searchText

        baseRequest =
            if String.isEmpty trimmedSearchText then
                { defaultGetPostsRequest | authorUserId = authorUserId, context = Just context }

            else
                { defaultGetPostsRequest
                    | authorUserId = authorUserId
                    , listingType = TEXTSEARCH
                    , searchText = Just trimmedSearchText
                    , context = Just context
                }

        request =
            { baseRequest
                | publishedOrCreatedBefore = Maybe.map posixToTimestamp publishedOrCreatedBefore
            }
    in
    performWithOptionalAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server maybeToken ->
            Grpc.new Jonline.getPosts request
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken maybeToken
                |> Grpc.toTask
        )


{-| Fetches the replies to `postId` from `maybeAccountServer`'s server,
`replyDepth` levels deep -- see `GetPostsRequest`'s doc comment: with
`post_id` and `reply_depth` both set, `GetPosts` returns the replies
themselves, not `postId`'s own Post), authenticated as its account if any,
anonymous otherwise -- same auth/refresh handling as `fetchPost`.
-}
fetchReplies :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> Int
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetPostsResponse )
fetchReplies accountsPanelModel maybeAccountServer replyDepth postId =
    performWithOptionalAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server maybeToken ->
            Grpc.new Jonline.getPosts { defaultGetPostsRequest | postId = Just postId, replyDepth = Just replyDepth }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken maybeToken
                |> Grpc.toTask
        )


{-| Whether `account` is `post`'s own author -- e.g. to show an Edit button
only to the post's author (see `Pages.Post.PostId_`). `False` if the post has
no `author` at all (shouldn't normally happen, but `Post.author` is optional).
-}
isAuthor : AccountsPanel.Account -> Post -> Bool
isAuthor account post =
    Maybe.map .userId post.author == Just account.userId


{-| Walks `post`'s own `replyToPostId` chain all the way up to (and including)
its root ancestor -- `Post` only carries its _children_ (`replies`), not its
parent, so there's no way to get this in one request. Returned root-first,
_not_ including `post` itself (the caller already has that) -- e.g. for a
reply-to-a-reply, `[root, parent]`. Empty if `post` has no `replyToPostId` at
all (it's already the root).

Used by `Pages.Post.PostId_` to populate `Shared.Breadcrumbs` for a Post
reached via a reply chain rather than directly. The whole walk (however many
hops it takes) happens inside a single `performWithOptionalAccountServer`
call -- see `fetchAncestorsHelp` -- so only one token-refresh check happens
for the whole chain, not one per hop.

-}
fetchAncestors :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> Post
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, List Post )
fetchAncestors accountsPanelModel maybeAccountServer post =
    performWithOptionalAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server maybeToken -> fetchAncestorsHelp server maybeToken post)


fetchAncestorsHelp : AccountsPanel.Server -> Maybe String -> Post -> Task Grpc.Error (List Post)
fetchAncestorsHelp server maybeToken post =
    case post.replyToPostId of
        Nothing ->
            Task.succeed []

        Just parentId ->
            Grpc.new Jonline.getPosts { defaultGetPostsRequest | postId = Just parentId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken maybeToken
                |> Grpc.toTask
                |> Task.andThen
                    (\response ->
                        case List.head response.posts of
                            Just parentPost ->
                                fetchAncestorsHelp server maybeToken parentPost
                                    |> Task.map (\ancestors -> ancestors ++ [ parentPost ])

                            Nothing ->
                                Task.succeed []
                    )


{-| Re-fetches `postId` fresh (via `GetPosts`) before submitting `UpdatePost`
with `updateFn` applied to that fresh copy -- so a stale in-hand `Post` (e.g.
one rendered a while ago) can't clobber any field that changed server-side
since, other than the one(s) `updateFn` itself means to change. Mirrors
`Components.Users.updateUser` exactly (same re-fetch-then-overlay dance,
`GetPosts`/`UpdatePost` in place of `GetUsers`/`UpdateUser`) -- used by
`Pages.Post.PostId_`'s visibility editor.
-}
updatePost :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> (Post -> Post)
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, Post )
updatePost accountsPanelModel maybeAccountServer postId updateFn =
    performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.getPosts { defaultGetPostsRequest | postId = Just postId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
                |> Task.andThen
                    (\response ->
                        case List.head response.posts of
                            Just freshPost ->
                                Grpc.new Jonline.updatePost (updateFn freshPost)
                                    |> Grpc.setHost (AccountsPanel.serverUrl server)
                                    |> withAccessToken (Just token)
                                    |> Grpc.toTask

                            Nothing ->
                                Task.fail Grpc.NetworkError
                    )
        )


{-| Deletes `postId` outright (`DeletePost`, owner-or-Admin gated
server-side, see `backend/src/rpcs/posts/delete_post.rs`) -- unlike
`updatePost`, there's nothing to overlay onto a fresh copy first, so this
just sends the id straight through. Used by `Pages.Post.PostId_`'s own
Delete button, via `Shared.ConfirmPostDelete`.
-}
deletePost :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, Post )
deletePost accountsPanelModel maybeAccountServer postId =
    performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.deletePost { defaultPost | id = postId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )



-- ROUTE / LINKS


{-| The href for `post`, as seen from `viewingServerHost` (typically
`shared.accountsPanel.mainFrontendHost`) -- a post on that same server links
as plain `/post/:id`; anything else includes its host, `/post/:id@host`, so
`Pages.Post.PostId_` knows which server to fetch it from. `basePath` is
`Shared.Model.basePath`, same as `UI.navLink`.
-}
postHref : String -> String -> String -> Post -> String
postHref basePath viewingServerHost postServerHost post =
    let
        postId =
            if postServerHost == viewingServerHost then
                post.id

            else
                post.id ++ "@" ++ postServerHost
    in
    basePath ++ Gen.Route.toHref (Gen.Route.Post__PostId_ { postId = postId })


{-| The inverse of `postHref`: `rawPostId` is either a bare id (a post on
`mainFrontendHost`) or `id@host` (a post on some other, federated server).
-}
parsePostRouteId : String -> String -> ( String, String )
parsePostRouteId mainFrontendHost rawPostId =
    case String.split "@" rawPostId of
        [ id, host ] ->
            ( id, host )

        _ ->
            ( rawPostId, mainFrontendHost )



-- DISPLAY


postTitleText : Post -> String
postTitleText post =
    case Maybe.map String.trim post.title of
        Just title ->
            if String.isEmpty title then
                fallbackTitle post

            else
                title

        Nothing ->
            fallbackTitle post


{-| The post's `link` field, trimmed -- `Nothing` if unset or blank, same
convention as `postTitleText`'s own trimming (just without a fallback, since
unlike a title, a post with no link simply shows no link row at all).
-}
postLinkText : Post -> Maybe String
postLinkText post =
    post.link
        |> Maybe.map String.trim
        |> Maybe.andThen
            (\link ->
                if String.isEmpty link then
                    Nothing

                else
                    Just link
            )


{-| `link` with a leading `http://`/`https://` dropped, for display only --
callers still `href` the untouched `postLinkText` value, this is just to
avoid stating the obvious (every post link is one or the other) and buy back
a few more characters before `.post-card-link`/`.post-detail-link`'s
`text-overflow: ellipsis` kicks in.
-}
stripLinkScheme : String -> String
stripLinkScheme link =
    if String.startsWith "https://" link then
        String.dropLeft 8 link

    else if String.startsWith "http://" link then
        String.dropLeft 7 link

    else
        link


fallbackTitle : Post -> String
fallbackTitle post =
    post.content
        |> Maybe.map (String.left 60)
        |> Maybe.withDefault "Post"


{-| A post's most relevant timestamp for "recency" sorting/display: when it
was published, falling back to when it was created (drafts, or servers that
don't distinguish the two).
-}
postTimestamp : Post -> Time.Posix
postTimestamp post =
    case ( post.publishedAt, post.createdAt ) of
        ( Just ts, _ ) ->
            timestampToPosix ts

        ( Nothing, Just ts ) ->
            timestampToPosix ts

        ( Nothing, Nothing ) ->
            Time.millisToPosix 0


{-| Display text for a post's visibility, e.g. for a "Public"/"Private"/etc.
badge on its preview.
-}
postVisibilityText : Post -> String
postVisibilityText post =
    visibilityText post.visibility


{-| Display text for a bare `Visibility` value -- same mapping
`postVisibilityText` uses for a `Post`'s own, but also needed on its own for
`Pages.Post.PostId_`'s visibility-editing `<select>`, whose options are
`allVisibilities` rather than any particular Post's current value.
-}
visibilityText : Visibility -> String
visibilityText visibility =
    case visibility of
        PRIVATE ->
            "Private"

        LIMITED ->
            "Limited"

        SERVERPUBLIC ->
            "Server Public"

        GLOBALPUBLIC ->
            "Global Public"

        DIRECT ->
            "Direct"

        VISIBILITYUNKNOWN ->
            "Unknown"

        VisibilityUnrecognized_ _ ->
            "Unknown"


{-| The visibility options offered by a visibility-editing `<select>` (see
`Pages.Post.PostId_`) -- excludes `DIRECT`, which the proto itself marks
`[TODO]`/unimplemented (see `protos/visibility_moderation.proto`), and
`VISIBILITYUNKNOWN`, which is never a valid value to _set_. Order matches
`visibilityText`/the proto's own declaration order.
-}
allVisibilities : List Visibility
allVisibilities =
    [ PRIVATE, LIMITED, SERVERPUBLIC, GLOBALPUBLIC ]


{-| The reverse of `visibilityText` -- looks up a `Visibility` by its display
label, the same round-trip `Components.Users.permissionFromText` does for
`Permission` -- needed because a plain HTML `<select>`'s value/`onInput` are
just strings. `Nothing` for any text that isn't one of `allVisibilities`'
labels (shouldn't happen, since the `<select>`'s own options are always built
from `allVisibilities` in the first place).
-}
visibilityFromText : String -> Maybe Visibility
visibilityFromText text =
    allVisibilities |> List.filter (\visibility -> visibilityText visibility == text) |> List.head


{-| The moderation-status options offered by a moderation-editing `<select>`
(see `Pages.Post.PostId_`/`Pages.Event.EventId_`'s own moderation selectors)
-- excludes `MODERATIONUNKNOWN`, never a valid value to _set_. Order matches
the proto's own declaration order.
-}
allModerations : List Moderation
allModerations =
    [ UNMODERATED, PENDING, APPROVED, REJECTED ]


{-| The reverse of `Components.Users.moderationText` -- same `<select>`-value
round-trip `visibilityFromText` does for `Visibility`.
-}
moderationFromText : String -> Maybe Moderation
moderationFromText text =
    allModerations |> List.filter (\moderation -> Users.moderationText moderation == text) |> List.head


{-| Which of `allVisibilities` `account` may pick for a Post/Event/etc. of
`context` -- mirrors `backend/src/rpcs/posts/update_post.rs`'s own permission
check: setting `SERVERPUBLIC`/`GLOBALPUBLIC` needs `PUBLISHPOSTSLOCALLY`/
`PUBLISHPOSTSGLOBALLY` for a plain `POST`/`REPLY`, or `PUBLISHEVENTSLOCALLY`/
`PUBLISHEVENTSGLOBALLY` for an `EVENT`/`EVENTINSTANCE` -- `ADMIN` always
passes either. `currentVisibility` is always included even if it wouldn't
otherwise be pickable, so an account whose permission was revoked after the
post was already elevated still sees its own current value in the list
(just can't newly pick it for some _other_ post) -- see
`Pages.Post.PostId_`'s visibility editor, which seeds its pending value from
the post's already-current one.
-}
allowedVisibilities : List Permission -> PostContext -> Visibility -> List Visibility
allowedVisibilities permissions context currentVisibility =
    let
        isEventContext =
            context == EVENT || context == EVENTINSTANCE

        has permission =
            List.member permission permissions || List.member ADMIN permissions

        canPublishLocally =
            has
                (if isEventContext then
                    PUBLISHEVENTSLOCALLY

                 else
                    PUBLISHPOSTSLOCALLY
                )

        canPublishGlobally =
            has
                (if isEventContext then
                    PUBLISHEVENTSGLOBALLY

                 else
                    PUBLISHPOSTSGLOBALLY
                )
    in
    allVisibilities
        |> List.filter
            (\visibility ->
                case visibility of
                    SERVERPUBLIC ->
                        canPublishLocally || visibility == currentVisibility

                    GLOBALPUBLIC ->
                        canPublishGlobally || visibility == currentVisibility

                    _ ->
                        True
            )


{-| A human-facing label for a Post's `context` when it's something other than
a plain `POST` (a `Reply`, `Event`, `Event Instance`, etc.) -- `Nothing` for a
plain `POST`, since that's the common case and doesn't need calling out
wherever a Post is shown alongside its context (see
`Shared.StarredPanel`'s panel view).
-}
postContextLabel : PostContext -> Maybe String
postContextLabel context =
    case context of
        POST ->
            Nothing

        REPLY ->
            Just "Reply"

        EVENT ->
            Just "Event"

        EVENTINSTANCE ->
            Nothing

        FEDERATEDREPLY ->
            Just "Federated Reply"

        PostContextUnrecognized_ _ ->
            Nothing


{-| A post's star count -- `unauthenticatedStarCount` is a protobuf `int64`,
which `protoc-gen-elm` represents as `Protobuf.Types.Int64.Int64` rather than
plain `Int` since it may exceed JS's safe integer range in general; star
counts never will, so this is a safe, simple conversion for display.
-}
postStarCount : Post -> Int
postStarCount post =
    int64ToInt post.unauthenticatedStarCount


{-| A post's comment count -- `responseCount` (replies _and_ replies to
replies, etc.), matching the Tamagui app's "N comments" label.
-}
postCommentCount : Post -> Int
postCommentCount post =
    post.responseCount


{-| The "★ N" star button of a post's meta line -- clickable (unless
`onStarClicked` is `Nothing`, e.g. its server isn't resolvable) to star/unstar
the post (see `Shared.StarredPanel`), filling with `postServerHost`'s
`primaryAnchorColor` (`.post-star.starred`, see `UI.EmittedStylesheet`) and
animating the fill via `transition` in `posts.css` when `starred` flips.
`stopPropagation`/`preventDefault` keep a click here from also following
`postCard`'s enclosing link.
-}
starButton : String -> Bool -> Maybe msg -> Post -> Html msg
starButton postServerHost starred onStarClicked post =
    span
        (classes
            (hostnameToCSSClass postServerHost
                :: "post-star"
                :: (if starred then
                        [ "starred" ]

                    else
                        []
                   )
            )
            :: (case onStarClicked of
                    Just msg ->
                        [ stopPropagationAndPreventDefaultOnClick msg ]

                    Nothing ->
                        []
               )
        )
        [ text ("★ " ++ String.fromInt (postStarCount post)) ]


{-| A post's reply-count display: just `responseCount` when `replyCount`
(direct replies only) and `responseCount` (all nested replies) agree -- the
common case, a post with no replies-to-replies -- otherwise
`"replyCount/responseCount"` (e.g. `"20/25"`) so a thread with actual
sub-discussion shows both numbers at a glance. Shared by `commentCountText`
(below, for `postCard`/`postDetail`) and `replyCard`, so a reply card's own
count matches a post card's exactly.
-}
repliesCountText : Post -> String
repliesCountText post =
    if post.replyCount == post.responseCount then
        String.fromInt post.responseCount

    else
        String.fromInt post.replyCount ++ "/" ++ String.fromInt post.responseCount


{-| "· 💬 12"-style suffix for a post's meta line, following `starButton`.
-}
commentCountText : Post -> String
commentCountText post =
    " · 💬 " ++ repliesCountText post


{-| A single `Post` timestamp, formatted the same way
`Components.Events.instanceWhenText` formats an `EventInstance` moment (e.g.
"August 1, 6PM", or "Today, August 1, 6PM" -- see `BrowserTimeZone.formatMoment`/
`dateLabel`) rather than a range, since a bare timestamp (created/updated/
published) is always a single point in time. `timestampsText`'s own sibling
-- used for its created/updated/published times, so a post's timestamps read
the same as an event's own "when" line.
-}
whenText : Time.Posix -> BrowserTimeZone -> Time.Posix -> String
whenText now browserTimeZone time =
    BrowserTimeZone.formatMoment now browserTimeZone time


{-| A post's created/updated/published times, as tersely as the data allows --
just one of the three normally (whichever's most relevant: `Published` if the
post has been published, else `Created`, else, in the one case a post could
have only this, `Updated`), with a trailing `*` plus a tooltip (native `title`)
covering the other one(s) whenever there's a genuinely _different_ edit
time to call out. Redundant fields (e.g. `publishedAt` equal to `createdAt`,
the common case for a post that was published immediately) are dropped
entirely rather than stated twice. All times shown in `browserTimeZone` via
`whenText` (e.g. "August 1, 6PM"), `now` supplying its own "current
year"/"current day" (see `BrowserTimeZone.dateLabel`).
-}
timestampsText : Time.Posix -> BrowserTimeZone -> Post -> Html msg
timestampsText now browserTimeZone post =
    let
        createdText =
            Maybe.map (timestampToPosix >> whenText now browserTimeZone) post.createdAt

        updatedText =
            Maybe.map (timestampToPosix >> whenText now browserTimeZone) post.updatedAt

        publishedText =
            Maybe.map (timestampToPosix >> whenText now browserTimeZone) post.publishedAt

        createdEqualsPublished =
            createdText /= Nothing && createdText == publishedText

        ( mainText, titleText ) =
            case ( createdText, updatedText, publishedText ) of
                ( Just created, Just updated, Just published ) ->
                    if createdEqualsPublished then
                        if updated == created then
                            ( "Created " ++ created, "" )

                        else
                            ( "Created " ++ created ++ "*", "Updated " ++ updated )

                    else if updated == published then
                        ( "Published " ++ published, "Created " ++ created )

                    else
                        ( "Published " ++ published ++ "*", "Updated " ++ updated ++ ", Created " ++ created )

                ( Just created, Just updated, Nothing ) ->
                    if updated == created then
                        ( "Created " ++ created, "" )

                    else
                        ( "Created " ++ created ++ "*", "Updated " ++ updated )

                ( Just created, Nothing, Just published ) ->
                    if createdEqualsPublished then
                        ( "Created " ++ created, "" )

                    else
                        ( "Published " ++ published, "Created " ++ created )

                ( Just created, Nothing, Nothing ) ->
                    ( "Created " ++ created, "" )

                ( Nothing, Just updated, Just published ) ->
                    if updated == published then
                        ( "Published " ++ published, "" )

                    else
                        ( "Published " ++ published ++ "*", "Updated " ++ updated )

                ( Nothing, Just updated, Nothing ) ->
                    ( "Updated " ++ updated, "" )

                ( Nothing, Nothing, Just published ) ->
                    ( "Published " ++ published, "" )

                ( Nothing, Nothing, Nothing ) ->
                    ( "", "" )
    in
    span
        [ class "post-timestamps"
        , title titleText
        ]
        [ text mainText ]


{-| An Edit button below `postDetail`'s Markdown content, shown only to
`post`'s own author (see `isAuthor`) -- `maybeAccount` is `postDetail`'s own
(the enabled account for the post's server, same one used for
`postAuthorAvatarUrl`), not necessarily `post.author` itself. Opens the shared
Markdown editor panel via `onEditClicked`, supplied by the caller
(`Pages.Post.PostId_`).
-}
editContentButton : Maybe AccountsPanel.Account -> msg -> Post -> Html msg
editContentButton maybeAccount onEditClicked post =
    case maybeAccount of
        Just account ->
            if isAuthor account post then
                button [ class "post-edit-button", Html.Events.onClick onEditClicked ] [ text "Edit Content" ]

            else
                text ""

        Nothing ->
            text ""


{-| `editButton`'s counterpart for `postDetail`'s media block -- shown below
`MultiMediaRenderer.view` (see `postDetail`) to `post`'s own author (same
`isAuthor` gate as `editButton`) _or_ an `ADMIN` account, mirroring
`backend/src/rpcs/posts/update_post.rs`'s own `admin || self_update` check
(that's what actually gates whether an `UpdatePost` carrying a changed
`media` list is accepted at all). Opens the shared `Shared.MyMediaPanel`
media chooser via `onMediaEditClicked` (`Pages.Post.PostId_`'s own
`MediaEditClicked`), unlike `editButton`'s Markdown panel.
-}
mediaEditButton : Maybe AccountsPanel.Account -> msg -> Post -> Html msg
mediaEditButton maybeAccount onMediaEditClicked post =
    case maybeAccount of
        Just account ->
            if isAuthor account post || List.member ADMIN account.permissions then
                button [ class "post-media-edit-button", Html.Events.onClick onMediaEditClicked ] [ text "Edit Media" ]

            else
                text ""

        Nothing ->
            text ""


{-| Compact rendering for a list of posts from multiple servers at once (see
the Home page's feed) -- shows which server a post is from, since that isn't
otherwise obvious once posts from several are mixed together by recency. Tinted
with `postServerHost`'s `primaryAnchorColor` border (see `UI.EmittedStylesheet`'s
`border-color-primary-anchor-50`/`hover-border-color-primary-anchor` utility
classes) -- faint normally, filling in on hover since the whole card is a link
-- so that's obvious at a glance too.

`current` marks this card as the one for the Post currently being viewed
(see `Shared.StarredPanel.view`, called from `UI.elm` with the current
route's post already resolved) -- filling the whole card with
`postServerHost`'s `primaryColor`/`primaryTextColor` (the `background-color-primary`
utility class) rather than just tinting its border, so it stands out from the
rest of the (unopened) Starred panel at a glance.

The card as a whole isn't a single enclosing `<a>` (despite looking/behaving
like one) -- `authorLink` needs to be a _real_, independently-clickable link of
its own, and nesting an `<a>` inside an `<a>` doesn't work in Elm: every
anchor's `href` navigation is wired up by `elm/browser` as its own native click
listener attached directly to that anchor's DOM node (see `_VirtualDom_divertHrefToApp`
in the compiled runtime), not by walking up to the nearest enclosing `<a>` --
so a click on a nested author link would fire _both_ listeners (author's, then
bubbling up to the card's), and since both call `preventDefault`/navigate, the
outer (later) one always wins and the author link would silently just open the
post instead. Instead this uses the "stretched link" pattern: the first child
below is an invisible `<a>` (`.post-card-link-overlay`) absolutely filling the
whole `.post-card`, sitting _behind_ the title/meta content (`position:
relative` on `.post-card-meta` -- title needs none, see its own lack of
interactive descendants -- stacks it above the overlay per normal CSS painting
order) with `.post-card-meta`'s own `pointer-events: none` (see `posts.css`)
making its plain text transparent to clicks, which fall through to the overlay
below -- while `authorLink`/`starButton`, both opted back in via
`pointer-events: auto`, catch clicks themselves before they ever reach it.

`.post-card-link` (the post's own `link` field, shown below the title via
`postLinkText` when set -- see `posts.css`) needs the same independent-click
treatment as `authorLink`/`starButton`, just via `position: relative` directly
on the anchor rather than the `pointer-events` dance: unlike the title (inert,
so it's fine to just fall through to the overlay behind it and open the post
either way), this one navigates somewhere else entirely, so it needs to win
the overlay's paint order itself.

`extraSmallMedia` shrinks the media preview's height further still (see
`MultiMediaRenderer.previewExtraSmall`) -- for `Shared.StarredPanel`'s
post rows, tighter on vertical space than the Home page's own feed of these
same cards.

-}
postCard : Time.Posix -> BrowserTimeZone -> String -> String -> String -> Maybe AccountsPanel.Server -> Maybe AccountsPanel.Account -> (String -> msg) -> Bool -> Bool -> Bool -> Maybe msg -> Post -> Html msg
postCard now browserTimeZone basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked extraSmallMedia current starred onStarClicked post =
    if post.context == REPLY then
        replyCard basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked 0 True False False Nothing Nothing Nothing post

    else
        postCardView now browserTimeZone basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked extraSmallMedia current starred onStarClicked post


{-| Below this many characters of raw Markdown, a content preview (this
module's own `postCardView`, and `Components.Events.eventCard`, which reuses
it) shows the whole (short) message without fading its bottom edge -- the
fade exists to signal "there's more below the cutoff", which would be
misleading to show over a preview that isn't actually being truncated.
-}
contentPreviewFadeThreshold : Int
contentPreviewFadeThreshold =
    220


{-| The plain (non-`REPLY`) rendering `postCard` falls back to -- see its own
doc comment above for why `REPLY` posts instead defer entirely to
`replyCard`.
-}
postCardView : Time.Posix -> BrowserTimeZone -> String -> String -> String -> Maybe AccountsPanel.Server -> Maybe AccountsPanel.Account -> (String -> msg) -> Bool -> Bool -> Bool -> Maybe msg -> Post -> Html msg
postCardView now browserTimeZone basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked extraSmallMedia current starred onStarClicked post =
    div
        [ classes
            ([ "post-card"
             , hostnameToCSSClass postServerHost
             , "border-color-primary-anchor-50"
             , "hover-border-color-primary-anchor"
             ]
                ++ (if current then
                        [ "post-card-current", "background-color-primary" ]

                    else
                        [ "background-color-primary-5" ]
                   )
            )
        ]
        [ a
            [ href (postHref basePath viewingServerHost postServerHost post)
            , class "post-card-link-overlay"
            , attribute "aria-label" (postTitleText post)
            ]
            []
        , div [ class "post-card-title" ] [ text (postTitleText post) ]
        , case postLinkText post of
            Just link ->
                a
                    [ href link
                    , target "_blank"
                    , rel "noopener noreferrer"
                    , classes [ hostnameToCSSClass postServerHost, "post-card-link" ]
                    ]
                    [ text (stripLinkScheme link) ]

            Nothing ->
                text ""
        , case maybeServer of
            Just server ->
                if extraSmallMedia then
                    MultiMediaRenderer.previewExtraSmall server maybeAccount onMediaClicked post.media

                else
                    MultiMediaRenderer.preview server maybeAccount onMediaClicked post.media

            Nothing ->
                text ""
        , case post.content of
            Just content ->
                Markdown.view
                    [ classes
                        (if String.length content > contentPreviewFadeThreshold then
                            [ "post-card-content-preview", "post-card-content-preview-fade" ]

                         else
                            [ "post-card-content-preview" ]
                        )
                    ]
                    content

            Nothing ->
                text ""
        , div [ class "post-card-meta" ]
            [ span [ class "post-meta-left" ]
                [ Authors.link basePath viewingServerHost postServerHost maybeServer maybeAccount post.author
                , text
                    (" · "
                        ++ postServerHost
                        ++ " · "
                        ++ postVisibilityText post
                    )
                ]
            , span [ class "post-meta-right" ]
                [ timestampsText now browserTimeZone post
                , starButton postServerHost starred onStarClicked post
                , text (commentCountText post)
                ]
            ]
        ]


{-| A single reply's card -- author, content, a Reply button, and (bottom
right of the actions row) a merged load-more/collapse-expand button carrying
`post`'s own reply/response counts (see `replyStatusButton`). `depth` (1 for a
direct reply, 2 for a reply to a reply, etc.) drives its left-indentation, so
`Components.PostReplies.view`'s flattened list still reads as a nested thread.

`onReplyClicked`/`onLoadRepliesClicked`/`onToggleCollapsedClicked` are each
`Maybe msg` rather than plain `msg` so a caller with no real handler for one
(`postCard`'s own `REPLY`-context fallback above, which has no reply-thread
state to drive these at all) can pass `Nothing` and get that action's
button omitted entirely, rather than needing to fabricate a message value
that can never actually fire.

-}
replyCard :
    String
    -> String
    -> String
    -> Maybe AccountsPanel.Server
    -> Maybe AccountsPanel.Account
    -> (String -> msg)
    -> Int
    -> Bool
    -> Bool
    -> Bool
    -> Maybe msg
    -> Maybe msg
    -> Maybe msg
    -> Post
    -> Html msg
replyCard basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked depth loaded loading collapsed onReplyClicked onLoadRepliesClicked onToggleCollapsedClicked post =
    div
        [ class "post-reply-item"
        , style "margin-left" (String.fromInt (min depth 8 * 20) ++ "px")
        ]
        [ div [ class "post-reply-meta" ]
            [ span [ class "post-meta-left" ]
                (Authors.link basePath viewingServerHost postServerHost maybeServer maybeAccount post.author
                    :: (if post.visibility == GLOBALPUBLIC then
                            []

                        else
                            [ text (" · " ++ postVisibilityText post) ]
                       )
                )
            , span [ class "post-meta-right" ]
                [ a
                    [ href (postHref basePath viewingServerHost postServerHost post)
                    , class "post-reply-permalink"
                    , attribute "aria-label" "Permalink"
                    ]
                    [ text "🔗" ]
                ]
            ]
        , case maybeServer of
            Just server ->
                MultiMediaRenderer.previewExtraSmall server maybeAccount onMediaClicked post.media

            Nothing ->
                text ""
        , case post.content of
            Just content ->
                Markdown.view [ class "post-reply-content" ] content

            Nothing ->
                text ""
        , div [ class "post-reply-actions" ]
            [ case ( maybeAccount, onReplyClicked ) of
                ( Just account, Just msg ) ->
                    if List.member REPLYTOPOSTS account.permissions then
                        button [ class "post-reply-button", Html.Events.onClick msg ] [ text "Reply" ]

                    else
                        text ""

                _ ->
                    text ""
            , replyStatusButton loaded loading collapsed onLoadRepliesClicked onToggleCollapsedClicked post
            ]
        ]


{-| The merged "load more"/"collapse"/"expand" button in a reply card's
bottom-right corner (`.post-reply-status-button`, pinned right via
`margin-left: auto` same as `.post-meta-right`), carrying `post`'s own
reply/response counts (`repliesCountText`, matching `commentCountText`'s own
formatting) in each of its three states:

  - still more to fetch (`post.replies`'s length doesn't yet match
    `post.replyCount`, and this node hasn't been explicitly `ReplyLoaded`):
    "Load 💬 X/Y More" (or a "Loading replies…" placeholder while `loading`),
    firing `onLoadRepliesClicked` (if supplied)
  - fully loaded and has any replies: an Expand/Collapse toggle (driven by
    `collapsed`) firing `onToggleCollapsedClicked` (if supplied)
  - fully loaded with no replies at all, or no handler supplied for the
    state it's in: nothing

-}
replyStatusButton : Bool -> Bool -> Bool -> Maybe msg -> Maybe msg -> Post -> Html msg
replyStatusButton loaded loading collapsed onLoadRepliesClicked onToggleCollapsedClicked post =
    let
        fullyLoaded =
            loaded || List.length post.replies == post.replyCount

        countText =
            "💬 " ++ repliesCountText post
    in
    if fullyLoaded then
        if List.isEmpty post.replies then
            text ""

        else
            case onToggleCollapsedClicked of
                Just msg ->
                    button
                        [ class "post-reply-status-button", Html.Events.onClick msg ]
                        [ text
                            -- ▲/▼ ◀/▶
                            ((if collapsed then
                                "▶ "

                              else
                                "▼ "
                             )
                                ++ countText
                            )
                        ]

                Nothing ->
                    text ""

    else if loading then
        span [ class "post-reply-loading" ] [ text "Loading replies…" ]

    else
        case onLoadRepliesClicked of
            Just msg ->
                button
                    [ class "post-reply-status-button", Html.Events.onClick msg ]
                    [ text ("Load " ++ countText ++ " More") ]

            Nothing ->
                text ""


{-| Full rendering for a single post (see the Post page) -- still tinted with
`postServerHost`'s `primaryAnchorColor` border like `postCard` is (just
without the hover fill-in, since this one isn't a link). `onEditClicked`
drives `editButton`, shown in the meta line's `post-meta-right` group only to
the post's own author.

Only a plain `POST` gets a title at all -- a `REPLY`/`EVENT`/etc. has no real
title of its own (`postTitleText`'s fallback to a truncated `content` exists
for contexts, like `postCard`'s feed entries, where _something_ short is
needed regardless; here, with the full `content` rendered right below anyway,
that fallback would just be a redundant near-duplicate of it). It gets
`postContextLabel`'s small context chip in its place instead (mirroring
`Shared.StarredPanel`'s own `starred-post-context`) -- since a Post
reached this way is, on `Pages.Post.PostId_`, already headed by
`Shared.Breadcrumbs`' own trail showing exactly _which_ reply this is, this
chip only needs to mark plainly _that_ it's one, not repeat any of that
context.

`visibilityView` is the whole visibility segment of the meta line -- plain
text (the common case) or an in-progress `<select>` editor, entirely up to
the caller (`Pages.Post.PostId_`, which owns the editing state/permission
gating for it, the same way it owns `onEditClicked`) -- this just slots
whatever `Html` it's given in after the author link, in place of what used to
be a bare `postVisibilityText post` text node. `moderationView` is the same
idea, slotted right after it, for the (Admin-/`MODERATEPOSTS`-only)
moderation-status segment.

-}
postDetail : Time.Posix -> BrowserTimeZone -> String -> String -> String -> Maybe AccountsPanel.Server -> Maybe AccountsPanel.Account -> (String -> msg) -> msg -> Bool -> Maybe msg -> msg -> Html msg -> Html msg -> Post -> Html msg
postDetail now browserTimeZone basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked onMediaEditClicked starred onStarClicked onEditClicked visibilityView moderationView post =
    div [ classes [ "post-detail", hostnameToCSSClass postServerHost, "border-color-primary-anchor-50" ] ]
        [ div [ class "post-detail-title-row" ]
            [ if post.context == POST then
                h1 [ class "post-detail-title" ] [ text (postTitleText post) ]

              else
                case postContextLabel post.context of
                    Just contextLabel ->
                        div [ class "post-detail-context" ] [ text contextLabel ]

                    Nothing ->
                        text ""
            ]
        , case postLinkText post of
            Just link ->
                a
                    [ href link
                    , target "_blank"
                    , rel "noopener noreferrer"
                    , classes [ hostnameToCSSClass postServerHost, "post-detail-link" ]
                    ]
                    [ text (stripLinkScheme link) ]

            Nothing ->
                text ""
        , case maybeServer of
            Just server ->
                div []
                    [ MultiMediaRenderer.view server maybeAccount onMediaClicked post.media
                    , div [ class "post-detail-media-edit-row" ] [ mediaEditButton maybeAccount onMediaEditClicked post ]
                    ]

            Nothing ->
                text ""
        , div [ class "post-detail-meta" ]
            [ span [ class "post-meta-left" ]
                [ text "by "
                , Authors.link basePath viewingServerHost postServerHost maybeServer maybeAccount post.author
                , text " · "
                , visibilityView
                , moderationView
                ]
            , span [ class "post-meta-right" ]
                [ timestampsText now browserTimeZone post
                , starButton postServerHost starred onStarClicked post
                , text (commentCountText post)
                ]
            ]
        , case post.content of
            Just content ->
                Markdown.view [ class "post-detail-content" ] content

            Nothing ->
                text ""
        , div [ class "post-detail-edit-row" ] [ editContentButton maybeAccount onEditClicked post ]
        ]
