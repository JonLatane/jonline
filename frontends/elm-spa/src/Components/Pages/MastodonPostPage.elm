module Components.Pages.MastodonPostPage exposing (Model, Msg, init, title, update, view)

{-| A single Mastodon post (status), read-only -- no reply/edit/delete/visibility/moderation/
sync-destination affordances (none of that makes sense for a post Rellm doesn't own), and no replies
tree (Rellm has no way to fetch a Mastodon post's own replies -- a "for now" gap). Just its author,
content, and a link back to the original.

Split out of `Components.Pages.PostPage` (which now only ever handles real Rellm posts) into its own
dedicated page so `Pages.Post.PostId_` can route to this directly once
`Components.Posts.parseFederatedPostId` recognizes the id as Mastodon's -- see that module's own doc,
and `Components.Pages.BlueskyPostPage` for the AT Protocol counterpart.

-}

import Components.Authors as Authors
import Components.Markdown as Markdown
import Components.Posts as Posts
import Effect exposing (Effect)
import Html exposing (Html, a, div, p, text)
import Html.Attributes exposing (class, href, rel, target)
import Http
import Proto.Rellm exposing (Post)
import Shared.Federation.Mastodon as Mastodon
import Task


type alias Model =
    { instanceHost : String
    , statusId : String
    , postStatus : PostStatus
    }


type PostStatus
    = LoadingPost
    | PostLoaded Post
    | PostFailed


type Msg
    = GotPost (Result Http.Error Post)


{-| `instanceHost`/`statusId` come straight from `Components.Posts.parseFederatedPostId`'s
`MastodonPostId` -- see that type's own doc on how they're picked back apart from the route.
-}
init : String -> String -> ( Model, Effect Msg )
init instanceHost statusId =
    ( { instanceHost = instanceHost, statusId = statusId, postStatus = LoadingPost }
    , Mastodon.fetchStatus instanceHost statusId
        |> Task.attempt GotPost
        |> Effect.fromCmd
    )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotPost (Ok post) ->
            ( { model | postStatus = PostLoaded post }, Effect.none )

        GotPost (Err _) ->
            ( { model | postStatus = PostFailed }, Effect.none )


view : Model -> Html Msg
view model =
    case model.postStatus of
        LoadingPost ->
            p [ class "post-loading" ] [ text "Loading…" ]

        PostFailed ->
            p [ class "post-error" ] [ text "Couldn't load this post. Maybe it was deleted, or maybe it's private." ]

        PostLoaded post ->
            federatedPostView model.instanceHost post


{-| No title, no URL row -- just the author (linking to their own `Components.Pages.MastodonUserProfilePage`,
via `Authors.link`, same as any other federated post card does), the content, and a "View original"
link back to the real post on Mastodon.
-}
federatedPostView : String -> Post -> Html Msg
federatedPostView instanceHost post =
    div [ class "post-detail" ]
        [ div [ class "federated-service-label" ] [ text "⇄ Mastodon" ]
        , Authors.link "" "" ("mastodon:" ++ instanceHost) Nothing Nothing post.author
        , Markdown.view [ class "post-detail-content" ] (Maybe.withDefault "" post.content)
        , case post.link of
            Just link ->
                a
                    [ class "post-link"
                    , href link
                    , target "_blank"
                    , rel "noopener noreferrer"
                    ]
                    [ text ("View original: " ++ Posts.stripLinkScheme link) ]

            Nothing ->
                text ""
        ]


{-| Just the subtitle -- the loaded post's own title, or "Post" before it's loaded -- for the
calling page's own `UI.pageTitle`. Mirrors `Components.Pages.PostPage.titleFor`.
-}
title : Model -> String
title model =
    case model.postStatus of
        PostLoaded post ->
            Posts.postTitleText post

        _ ->
            "Post"
