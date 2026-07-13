module Components.Posts exposing
    ( fetchPost
    , fetchRecentPosts
    , postAuthorName
    , postCard
    , postDetail
    , postHref
    , postTimestamp
    , postTitleText
    )

{-| Shared building blocks for displaying `Proto.Jonline.Post`s -- the compact
`postCard` used in the Home page's recent-posts feed, the fuller `postDetail`
used by the Post page, and the fetch/link helpers both (and any future
Post-related page) need: building a `GetPosts` request against a specific
`Shared.AccountsPanel.Server` (optionally authenticated, via
`Shared.MaybeAccountRequest`), and building/parsing the `/post/:postId`
route's `id` or `id@host` segment.
-}

import Gen.Route
import Grpc
import Html exposing (Html, a, div, h1, p, text)
import Html.Attributes exposing (class, href)
import Proto.Jonline exposing (GetPostsResponse, Post, defaultGetPostsRequest)
import Proto.Jonline.Jonline as Jonline
import Shared.AccountsPanel as AccountsPanel
import Shared.MaybeAccountRequest as MaybeAccountRequest
import Task exposing (Task)
import Time


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


{-| Compact rendering for a list of posts from multiple servers at once (see
the Home page's feed) -- shows which server a post is from, since that isn't
otherwise obvious once posts from several are mixed together by recency.
-}
postCard : String -> String -> String -> Post -> Html msg
postCard basePath viewingServerHost postServerHost post =
    a
        [ href (postHref basePath viewingServerHost postServerHost post)
        , class "post-card"
        ]
        [ div [ class "post-card-title" ] [ text (postTitleText post) ]
        , div [ class "post-card-meta" ] [ text (postAuthorName post ++ " · " ++ postServerHost) ]
        ]


{-| Full rendering for a single post (see the Post page) -- no server badge,
since that's already the page you're on.
-}
postDetail : Post -> Html msg
postDetail post =
    div [ class "post-detail" ]
        [ h1 [ class "post-detail-title" ] [ text (postTitleText post) ]
        , div [ class "post-detail-meta" ] [ text ("by " ++ postAuthorName post) ]
        , case post.content of
            Just content ->
                p [ class "post-detail-content" ] [ text content ]

            Nothing ->
                text ""
        ]
