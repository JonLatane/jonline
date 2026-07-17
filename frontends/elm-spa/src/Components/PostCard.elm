module Components.PostCard exposing
    ( allVisibilities
    , allowedVisibilities
    , authorLink
    , commentCountText
    , fetchAncestors
    , fetchPost
    , fetchRecentPosts
    , fetchReplies
    , isAuthor
    , parsePostRouteId
    , postAuthorAvatarUrl
    , postAuthorHref
    , postAuthorName
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
    , timestampsText
    , updatePost
    , visibilityFromText
    , visibilityText
    )

{-| Shared building blocks for displaying `Proto.Jonline.Post`s -- the compact
`postCard` used in the Home page's recent-posts feed, the fuller `postDetail`
used by the Post page, and the fetch/link helpers both (and any future
Post-related page) need: building a `GetPosts` request against a specific
`Shared.AccountsPanel.Server` (optionally authenticated, via
`Shared.MaybeAccountRequest`), and building/parsing the `/post/:postId`
route's `id` or `id@host` segment.
-}

import Components.Markdown as Markdown
import Components.MultiMediaRenderer as MultiMediaRenderer
import Components.Users as Users
import Gen.Route
import Grpc
import Html exposing (Html, a, button, div, h1, img, span, text)
import Html.Attributes exposing (alt, attribute, class, href, rel, src, target, title)
import Html.Events
import Json.Decode as Decode
import Proto.Jonline exposing (GetPostsResponse, Post, defaultGetPostsRequest)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.Permission exposing (Permission(..))
import Proto.Jonline.PostContext exposing (PostContext(..))
import Proto.Jonline.Visibility exposing (Visibility(..))
import Shared.AccountsPanel as AccountsPanel exposing (performWithAccountServer, performWithOptionalAccountServer, withAccessToken)
import Shared.BrowserTimeZone as BrowserTimeZone exposing (BrowserTimeZone)
import Shared.Conversions exposing (int64ToInt, timestampToPosix)
import Task exposing (Task)
import Time
import UI.Classes exposing (classes, hostnameToCSSClass)


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


{-| Fetches the most recent publicly-accessible posts from
`maybeAccountServer`'s server, authenticated as its account if any (so e.g.
followed-user/group posts are included too) -- otherwise identical to
`fetchPost`.
-}
fetchRecentPosts :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetPostsResponse )
fetchRecentPosts accountsPanelModel maybeAccountServer =
    performWithOptionalAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server maybeToken ->
            Grpc.new Jonline.getPosts defaultGetPostsRequest
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


postAuthorName : Post -> String
postAuthorName post =
    post.author
        |> Maybe.andThen .username
        |> Maybe.withDefault "unknown"


{-| The author's profile link -- `Nothing` if the post has no `author` at all
(shouldn't normally happen, but `Post.author` is optional). The author is
always on `postServerHost` (the same server as the post itself; `Author` has
no host of its own to look elsewhere) -- see `Components.Users.profileHref`,
which already falls back to `/user/:id` if the username isn't routable.
-}
postAuthorHref : String -> String -> String -> Post -> Maybe String
postAuthorHref basePath viewingServerHost postServerHost post =
    post.author
        |> Maybe.map
            (\author ->
                Users.profileHref basePath
                    viewingServerHost
                    postServerHost
                    { userId = author.userId, username = Maybe.withDefault "" author.username }
            )


{-| The author's avatar URL -- `Nothing` if the post has no `author`, `server`
isn't resolved yet (e.g. still connecting), or the author just has no avatar
set. `server` (unlike `postAuthorHref`'s plain `postServerHost` string) needs
to be the actual resolved `Shared.AccountsPanel.Server` -- building a media URL
needs its connection details, not just its hostname (see
`Shared.AccountsPanel.mediaUrl`).
-}
postAuthorAvatarUrl : Maybe AccountsPanel.Server -> Maybe AccountsPanel.Account -> Post -> Maybe String
postAuthorAvatarUrl maybeServer maybeAccount post =
    Maybe.map2 (\server author -> Users.authorAvatarUrl server maybeAccount author) maybeServer post.author
        |> Maybe.andThen identity


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
`Shared.StarredPostsPanel`'s panel view).
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
            Just "Event Instance"

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
the post (see `Shared.StarredPostsPanel`), filling with `postServerHost`'s
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
                        [ Html.Events.custom "click"
                            (Decode.succeed { message = msg, stopPropagation = True, preventDefault = True })
                        ]

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
(below, for `postCard`/`postDetail`) and `Components.PostReplies.replyCard`,
so a reply card's own count matches a post card's exactly.
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


{-| A post's created/updated/published times, as tersely as the data allows --
just one of the three normally (whichever's most relevant: `Published` if the
post has been published, else `Created`, else, in the one case a post could
have only this, `Updated`), with a trailing `*` plus a tooltip (native `title`)
covering the other one(s) whenever there's a genuinely _different_ edit
time to call out. Redundant fields (e.g. `publishedAt` equal to `createdAt`,
the common case for a post that was published immediately) are dropped
entirely rather than stated twice. All times shown in `browserTimeZone`,
`YYYY-MM-DD HH:mm Z` (`BrowserTimeZone.formatDateTime`, `Z` its trailing
`abbreviation`).
-}
timestampsText : BrowserTimeZone -> Post -> Html msg
timestampsText browserTimeZone post =
    let
        createdText =
            Maybe.map (timestampToPosix >> BrowserTimeZone.formatDateTime browserTimeZone) post.createdAt

        updatedText =
            Maybe.map (timestampToPosix >> BrowserTimeZone.formatDateTime browserTimeZone) post.updatedAt

        publishedText =
            Maybe.map (timestampToPosix >> BrowserTimeZone.formatDateTime browserTimeZone) post.publishedAt

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
editButton : Maybe AccountsPanel.Account -> msg -> Post -> Html msg
editButton maybeAccount onEditClicked post =
    case maybeAccount of
        Just account ->
            if isAuthor account post then
                button [ class "post-edit-button", Html.Events.onClick onEditClicked ] [ text "Edit" ]

            else
                text ""

        Nothing ->
            text ""


{-| A small avatar/placeholder for a post's author, matching the size of the
Accounts Panel toggle's own avatars (`.post-author-avatar`, see `posts.css`).
Falls back to an initial-letter placeholder the same way `UI.imageOrInitial`
does elsewhere in the app; duplicated here rather than reusing that function
since `UI` itself imports `Components.Posts` (for `postCard`), so the reverse
import would be a cycle.
-}
authorAvatar : String -> Maybe String -> Html msg
authorAvatar name maybeUrl =
    case maybeUrl of
        Just url ->
            img [ class "post-author-avatar", src url, alt name ] []

        Nothing ->
            div [ classes [ "post-author-avatar", "placeholder" ] ] [ text (AccountsPanel.initialLetter name) ]


{-| A post's author avatar + name, linking to their profile (see
`postAuthorHref`) -- a `span` (not a link) if the post somehow has no `author`
at all, so the avatar still shows either way. Used by both `postDetail` (a
plain, unwrapped link -- fine as-is) and `postCard` (which needs the
"stretched link" dance in its own doc comment to keep this independently
clickable without nesting an `<a>` inside `postCard`'s own enclosing one).
-}
authorLink : String -> String -> String -> Maybe AccountsPanel.Server -> Maybe AccountsPanel.Account -> Post -> Html msg
authorLink basePath viewingServerHost postServerHost maybeServer maybeAccount post =
    let
        name =
            postAuthorName post

        content =
            [ authorAvatar name (postAuthorAvatarUrl maybeServer maybeAccount post), text name ]
    in
    case postAuthorHref basePath viewingServerHost postServerHost post of
        Just profileHref ->
            a [ href profileHref, class "post-author-link" ] content

        Nothing ->
            span [ class "post-author-link" ] content


{-| Compact rendering for a list of posts from multiple servers at once (see
the Home page's feed) -- shows which server a post is from, since that isn't
otherwise obvious once posts from several are mixed together by recency. Tinted
with `postServerHost`'s `primaryAnchorColor` border (see `UI.EmittedStylesheet`'s
`border-color-primary-anchor-50`/`hover-border-color-primary-anchor` utility
classes) -- faint normally, filling in on hover since the whole card is a link
-- so that's obvious at a glance too.

`current` marks this card as the one for the Post currently being viewed
(see `Shared.StarredPostsPanel.view`, called from `UI.elm` with the current
route's post already resolved) -- filling the whole card with
`postServerHost`'s `primaryColor`/`primaryTextColor` (the `background-color-primary`
utility class) rather than just tinting its border, so it stands out from the
rest of the (unopened) Starred Posts panel at a glance.

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
`MultiMediaRenderer.previewExtraSmall`) -- for `Shared.StarredPostsPanel`'s
post rows, tighter on vertical space than the Home page's own feed of these
same cards.

-}
postCard : BrowserTimeZone -> String -> String -> String -> Maybe AccountsPanel.Server -> Maybe AccountsPanel.Account -> (String -> msg) -> Bool -> Bool -> Bool -> Maybe msg -> Post -> Html msg
postCard browserTimeZone basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked extraSmallMedia current starred onStarClicked post =
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
        , div [ class "post-card-meta" ]
            [ span [ class "post-meta-left" ]
                [ authorLink basePath viewingServerHost postServerHost maybeServer maybeAccount post
                , text
                    (" · "
                        ++ postServerHost
                        ++ " · "
                        ++ postVisibilityText post
                    )
                ]
            , span [ class "post-meta-right" ]
                [ timestampsText browserTimeZone post
                , starButton postServerHost starred onStarClicked post
                , text (commentCountText post)
                ]
            ]
        ]


{-| Full rendering for a single post (see the Post page) -- no server badge,
since that's already the page you're on, but still tinted with `postServerHost`'s
`primaryAnchorColor` border like `postCard` is (just without the hover fill-in,
since this one isn't a link). `onEditClicked` drives `editButton`, shown in the
meta line's `post-meta-right` group only to the post's own author.

Only a plain `POST` gets a title at all -- a `REPLY`/`EVENT`/etc. has no real
title of its own (`postTitleText`'s fallback to a truncated `content` exists
for contexts, like `postCard`'s feed entries, where _something_ short is
needed regardless; here, with the full `content` rendered right below anyway,
that fallback would just be a redundant near-duplicate of it). It gets
`postContextLabel`'s small context chip in its place instead (mirroring
`Shared.StarredPostsPanel`'s own `starred-post-context`) -- since a Post
reached this way is, on `Pages.Post.PostId_`, already headed by
`Shared.Breadcrumbs`' own trail showing exactly _which_ reply this is, this
chip only needs to mark plainly _that_ it's one, not repeat any of that
context.

`visibilityView` is the whole visibility segment of the meta line -- plain
text (the common case) or an in-progress `<select>` editor, entirely up to
the caller (`Pages.Post.PostId_`, which owns the editing state/permission
gating for it, the same way it owns `onEditClicked`) -- this just slots
whatever `Html` it's given in after the author link, in place of what used to
be a bare `postVisibilityText post` text node.

-}
postDetail : BrowserTimeZone -> String -> String -> String -> Maybe AccountsPanel.Server -> Maybe AccountsPanel.Account -> (String -> msg) -> Bool -> Maybe msg -> msg -> Html msg -> Post -> Html msg
postDetail browserTimeZone basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked starred onStarClicked onEditClicked visibilityView post =
    div [ classes [ "post-detail", postServerHost, "border-color-primary-anchor-50" ] ]
        [ if post.context == POST then
            h1 [ class "post-detail-title" ] [ text (postTitleText post) ]

          else
            case postContextLabel post.context of
                Just contextLabel ->
                    div [ class "post-detail-context" ] [ text contextLabel ]

                Nothing ->
                    text ""
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
                MultiMediaRenderer.view server maybeAccount onMediaClicked post.media

            Nothing ->
                text ""
        , div [ class "post-detail-meta" ]
            [ span [ class "post-meta-left" ]
                [ text "by "
                , authorLink basePath viewingServerHost postServerHost maybeServer maybeAccount post
                , text " · "
                , visibilityView
                ]
            , span [ class "post-meta-right" ]
                [ timestampsText browserTimeZone post
                , starButton postServerHost starred onStarClicked post
                , text (commentCountText post)
                ]
            ]
        , case post.content of
            Just content ->
                Markdown.view [ class "post-detail-content" ] content

            Nothing ->
                text ""
        , div [ class "post-detail-edit-row" ] [ editButton maybeAccount onEditClicked post ]
        ]
