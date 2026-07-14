module Components.Posts exposing
    ( fetchPost
    , fetchRecentPosts
    , parsePostRouteId
    , postAuthorName
    , postCard
    , postCommentCount
    , postContextLabel
    , postDetail
    , postHref
    , postTimestamp
    , postTitleText
    , postVisibilityText
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
import Gen.Route
import Grpc
import Html exposing (Html, a, div, h1, span, text)
import Html.Attributes exposing (class, href)
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


{-| A post's comment count -- `responseCount` (replies *and* replies to
replies, etc.), matching the Tamagui app's "N comments" label.
-}
postCommentCount : Post -> Int
postCommentCount post =
    post.responseCount


{-| The "★ N" star button of a post's meta line -- clickable (unless
`onStarClicked` is `Nothing`, e.g. its server isn't resolvable) to star/unstar
the post (see `Shared.StarredPostsPanel`), filling with `postServerHost`'s
`primaryAnchorColor` (`.post-star.starred`, see `UI.EmittedStylesheet`) and
animating the fill via `transition` in `style.css` when `starred` flips.
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


{-| "· 💬 12"-style suffix for a post's meta line, following `starButton`.
-}
commentCountText : Post -> String
commentCountText post =
    " · 💬 " ++ String.fromInt (postCommentCount post)


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
-}
postCard : String -> String -> String -> Bool -> Bool -> Maybe msg -> Post -> Html msg
postCard basePath viewingServerHost postServerHost current starred onStarClicked post =
    a
        [ href (postHref basePath viewingServerHost postServerHost post)
        , classes
            ([ "post-card"
             , postServerHost
             , "border-color-primary-anchor-50"
             , "hover-border-color-primary-anchor"
             ]
                ++ (if current then
                        [ "post-card-current", "background-color-primary" ]

                    else
                        []
                   )
            )
        ]
        [ div [ class "post-card-title" ] [ text (postTitleText post) ]
        , div [ class "post-card-meta" ]
            [ text
                (postAuthorName post
                    ++ " · "
                    ++ postServerHost
                    ++ " · "
                    ++ postVisibilityText post
                    ++ " · "
                )
            , starButton postServerHost starred onStarClicked post
            , text (commentCountText post)
            ]
        ]


{-| Full rendering for a single post (see the Post page) -- no server badge,
since that's already the page you're on, but still tinted with `postServerHost`'s
`primaryAnchorColor` border like `postCard` is (just without the hover fill-in,
since this one isn't a link).
-}
postDetail : String -> Bool -> Maybe msg -> Post -> Html msg
postDetail postServerHost starred onStarClicked post =
    div [ classes [ "post-detail", postServerHost, "border-color-primary-anchor-50" ] ]
        [ h1 [ class "post-detail-title" ] [ text (postTitleText post) ]
        , div [ class "post-detail-meta" ]
            [ text
                ("by "
                    ++ postAuthorName post
                    ++ " · "
                    ++ postVisibilityText post
                    ++ " · "
                )
            , starButton postServerHost starred onStarClicked post
            , text (commentCountText post)
            ]
        , case post.content of
            Just content ->
                Markdown.view [ class "post-detail-content" ] content

            Nothing ->
                text ""
        ]
