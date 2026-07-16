module Components.PostCard exposing
    ( authorLink
    , commentCountText
    , fetchPost
    , fetchRecentPosts
    , fetchReplies
    , isAuthor
    , parsePostRouteId
    , postAuthorHref
    , postAuthorName
    , postCard
    , postCommentCount
    , postContextLabel
    , postDetail
    , postHref
    , postTimestamp
    , postTitleText
    , postVisibilityText
    , repliesCountText
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
import Html.Attributes exposing (alt, attribute, class, href, src)
import Html.Events
import Json.Decode as Decode
import Proto.Jonline exposing (GetPostsResponse, Post, defaultGetPostsRequest)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.PostContext exposing (PostContext(..))
import Proto.Jonline.Visibility exposing (Visibility(..))
import Shared.AccountsPanel as AccountsPanel
import Shared.MaybeAccountRequest as MaybeAccountRequest
import Task exposing (Task)
import Time
import UI.Classes exposing (classes)


{-| Fetches a single post (including reply/preview data) from `server`,
authenticated as `maybeAccount` if given, anonymous otherwise -- see
`Shared.MaybeAccountRequest.perform`. Returns `maybeAccount` back (refreshed,
if it needed to be) alongside the response, so the caller can persist that
refresh -- see `Shared.AccountsPanel.AccountRefreshed`.
-}
fetchPost :
    AccountsPanel.Server
    -> Maybe AccountsPanel.Account
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Account, GetPostsResponse )
fetchPost server maybeAccount postId =
    MaybeAccountRequest.perform
        (connectionOf server)
        maybeAccount
        (\maybeToken ->
            Grpc.new Jonline.getPosts { defaultGetPostsRequest | postId = Just postId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAuth maybeToken
                |> Grpc.toTask
        )


{-| Fetches the most recent publicly-accessible posts from `server`,
authenticated as `maybeAccount` if given (so e.g. followed-user/group posts
are included too) -- otherwise identical to `fetchPost`.
-}
fetchRecentPosts :
    AccountsPanel.Server
    -> Maybe AccountsPanel.Account
    -> Task Grpc.Error ( Maybe AccountsPanel.Account, GetPostsResponse )
fetchRecentPosts server maybeAccount =
    MaybeAccountRequest.perform
        (connectionOf server)
        maybeAccount
        (\maybeToken ->
            Grpc.new Jonline.getPosts defaultGetPostsRequest
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAuth maybeToken
                |> Grpc.toTask
        )


{-| Fetches the replies to `postId` from `server`, `replyDepth` levels deep --
see `GetPostsRequest`'s doc comment: with `post_id` and `reply_depth` both set,
`GetPosts` returns the replies themselves, not `postId`'s own Post), authenticated
as `maybeAccount` if given, anonymous otherwise -- same auth/refresh handling as
`fetchPost`.
-}
fetchReplies :
    AccountsPanel.Server
    -> Maybe AccountsPanel.Account
    -> Int
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Account, GetPostsResponse )
fetchReplies server maybeAccount replyDepth postId =
    MaybeAccountRequest.perform
        (connectionOf server)
        maybeAccount
        (\maybeToken ->
            Grpc.new Jonline.getPosts { defaultGetPostsRequest | postId = Just postId, replyDepth = Just replyDepth }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAuth maybeToken
                |> Grpc.toTask
        )


{-| Whether `account` is `post`'s own author -- e.g. to show an Edit button
only to the post's author (see `Pages.Post.PostId_`). `False` if the post has
no `author` at all (shouldn't normally happen, but `Post.author` is optional).
-}
isAuthor : AccountsPanel.Account -> Post -> Bool
isAuthor account post =
    Maybe.map .userId post.author == Just account.userId


connectionOf : AccountsPanel.Server -> { host : String, port_ : Int, tls : Bool }
connectionOf server =
    { host = server.backendHost, port_ = server.port_, tls = server.tls }


withAuth : Maybe String -> Grpc.RpcRequest req res -> Grpc.RpcRequest req res
withAuth maybeToken req =
    case maybeToken of
        Just token ->
            Grpc.addHeader "authorization" token req

        Nothing ->
            req



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
            MaybeAccountRequest.timestampToPosix ts

        ( Nothing, Just ts ) ->
            MaybeAccountRequest.timestampToPosix ts

        ( Nothing, Nothing ) ->
            Time.millisToPosix 0


{-| Display text for a post's visibility, e.g. for a "Public"/"Private"/etc.
badge on its preview.
-}
postVisibilityText : Post -> String
postVisibilityText post =
    case post.visibility of
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

        FEDERATEDPOST ->
            Just "Federated Post"

        FEDERATEDEVENTINSTANCE ->
            Just "Federated Event Instance"

        PostContextUnrecognized_ _ ->
            Nothing


{-| A post's star count -- `unauthenticatedStarCount` is a protobuf `int64`,
which `protoc-gen-elm` represents as `Protobuf.Types.Int64.Int64` rather than
plain `Int` since it may exceed JS's safe integer range in general; star
counts never will, so this is a safe, simple conversion for display.
-}
postStarCount : Post -> Int
postStarCount post =
    MaybeAccountRequest.int64ToInt post.unauthenticatedStarCount


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
            (postServerHost
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


{-| An Edit button for `postDetail`'s meta line, shown only to `post`'s own
author (see `isAuthor`) -- `maybeAccount` is `postDetail`'s own (the enabled
account for the post's server, same one used for `postAuthorAvatarUrl`), not
necessarily `post.author` itself. Opens the shared Markdown editor panel via
`onEditClicked`, supplied by the caller (`Pages.Post.PostId_`).
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

`extraSmallMedia` shrinks the media preview's height further still (see
`MultiMediaRenderer.previewExtraSmall`) -- for `Shared.StarredPostsPanel`'s
post rows, tighter on vertical space than the Home page's own feed of these
same cards.
-}
postCard : String -> String -> String -> Maybe AccountsPanel.Server -> Maybe AccountsPanel.Account -> (String -> msg) -> Bool -> Bool -> Bool -> Maybe msg -> Post -> Html msg
postCard basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked extraSmallMedia current starred onStarClicked post =
    div
        [ classes
            ([ "post-card"
             , postServerHost
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
                [ starButton postServerHost starred onStarClicked post
                , text (commentCountText post)
                ]
            ]
        ]


{-| Full rendering for a single post (see the Post page) -- no server badge,
since that's already the page you're on, but still tinted with `postServerHost`'s
`primaryAnchorColor` border like `postCard` is (just without the hover fill-in,
since this one isn't a link). `onEditClicked` drives `editButton`, shown in the
meta line's `post-meta-right` group only to the post's own author.
-}
postDetail : String -> String -> String -> Maybe AccountsPanel.Server -> Maybe AccountsPanel.Account -> (String -> msg) -> Bool -> Maybe msg -> msg -> Post -> Html msg
postDetail basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked starred onStarClicked onEditClicked post =
    div [ classes [ "post-detail", postServerHost, "border-color-primary-anchor-50" ] ]
        [ h1 [ class "post-detail-title" ] [ text (postTitleText post) ]
        , case maybeServer of
            Just server ->
                MultiMediaRenderer.view server maybeAccount onMediaClicked post.media

            Nothing ->
                text ""
        , div [ class "post-detail-meta" ]
            [ span [ class "post-meta-left" ]
                [ text "by "
                , authorLink basePath viewingServerHost postServerHost maybeServer maybeAccount post
                , text (" · " ++ postVisibilityText post)
                ]
            , span [ class "post-meta-right" ]
                [ editButton maybeAccount onEditClicked post
                , starButton postServerHost starred onStarClicked post
                , text (commentCountText post)
                ]
            ]
        , case post.content of
            Just content ->
                Markdown.view [ class "post-detail-content" ] content

            Nothing ->
                text ""
        ]
