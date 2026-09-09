module Components.Pages.BlueskyPostPage exposing (Model, Msg, init, title, update, view)

{-| A single Bluesky post, read-only -- no reply/edit/delete/visibility/moderation/sync-destination
affordances (none of that makes sense for a post Rellm doesn't own), and no replies tree (Rellm has
no way to fetch a Bluesky post's own replies -- a "for now" gap). Just its author, content, and a
link back to the original.

Split out of `Components.Pages.PostPage` (which now only ever handles real Rellm posts) into its own
dedicated page so `Pages.Post.PostId_` can route to this directly once
`Components.Posts.parseFederatedPostId` recognizes the id as Bluesky's -- see that module's own doc,
and `Components.Pages.MastodonPostPage` for the ActivityPub counterpart.

-}

import Components.Authors as Authors
import Components.Markdown as Markdown
import Components.Posts as Posts
import Effect exposing (Effect)
import Html exposing (Html, a, div, p, text)
import Html.Attributes exposing (class, href, rel, target)
import Http
import Proto.Rellm exposing (Post)
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.AccountsPanel.BlueskyAccounts as BlueskyAccounts exposing (BlueskyAccount)
import Shared.Federation.Bluesky as Bluesky
import Task


type alias Model =
    { uri : String
    , postStatus : PostStatus
    }


type PostStatus
    = LoadingPost
    | PostLoaded Post
    | PostFailed


type Msg
    = GotPost String (Result Http.Error ( Maybe BlueskyAccount, Post ))


{-| `uri` comes straight from `Components.Posts.parseFederatedPostId`'s `BlueskyPostId` -- see that
type's own doc. Fetched using whichever connected Bluesky account comes first -- reading a public
post doesn't need to be *that* account's own, any connected token works (see
`Shared.Federation.Bluesky.fetchPost`'s own doc) -- and fails outright (a bare `Http.BadStatus 401`,
landing on `PostFailed`, same as a real auth failure would) if none is connected at all, since AT
Protocol has no anonymous access to anything. Goes through `BlueskyAccounts.performWithBlueskyAccount`
same as `Components.Pages.PostsPage.fetchFeedSource`'s own `BlueskyFeed` case, so a since-expired
access token gets one refresh-and-retry rather than failing outright -- see `update`'s own handling
of the rotated/reauth-needed account this can come back with.
-}
init : Shared.Model -> String -> ( Model, Effect Msg )
init shared uri =
    let
        actingHandle : String
        actingHandle =
            List.head shared.accounts.blueskyAccounts |> Maybe.map .handle |> Maybe.withDefault ""

        fetchTask : Task.Task Http.Error ( Maybe BlueskyAccount, Post )
        fetchTask =
            case shared.accounts.blueskyAccounts of
                account :: _ ->
                    BlueskyAccounts.performWithBlueskyAccount account (\accessToken -> Bluesky.fetchPost accessToken uri)
                        |> Task.map
                            (\( refreshedAccount, post ) ->
                                ( if refreshedAccount.accessToken == account.accessToken then
                                    Nothing

                                  else
                                    Just refreshedAccount
                                , post
                                )
                            )

                [] ->
                    Task.fail (Http.BadStatus 401)
    in
    ( { uri = uri, postStatus = LoadingPost }
    , fetchTask |> Task.attempt (GotPost actingHandle) |> Effect.fromCmd
    )


{-| A successful fetch persists a rotated access/refresh token pair, if `performWithBlueskyAccount`
had to refresh one to get here (see that function's own doc on why the tokens it carries may have
silently rotated), via `Shared.AccountsPanel.BlueskyAccountRefreshed`; a final failure worth flagging
as `needsReauth` (see `BlueskyAccounts.isReauthError`) marks it the same way
`Components.Pages.PostsPage`'s own `fromBlueskyResult` does, so a revoked/expired account shows its
"Reconnect" affordance in the Accounts Panel rather than just failing silently every time this page
(or any other Bluesky-post link) is opened.
-}
update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotPost _ (Ok ( maybeRefreshedAccount, post )) ->
            ( { model | postStatus = PostLoaded post }
            , maybeRefreshedAccount
                |> Maybe.map (AccountsPanel.BlueskyAccountRefreshed >> Shared.AccountsPanelMsg >> Effect.fromShared)
                |> Maybe.withDefault Effect.none
            )

        GotPost handle (Err err) ->
            ( { model | postStatus = PostFailed }
            , if BlueskyAccounts.isReauthError err && handle /= "" then
                Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.MarkBlueskyAccountNeedsReauth handle))

              else
                Effect.none
            )


view : Model -> Html Msg
view model =
    case model.postStatus of
        LoadingPost ->
            p [ class "post-loading" ] [ text "Loading…" ]

        PostFailed ->
            p [ class "post-error" ] [ text "Couldn't load this post. Maybe it was deleted, or maybe it's private." ]

        PostLoaded post ->
            federatedPostView post


{-| No title, no URL row -- just the author (marked with a leading "⇄", same as
`Components.Posts.postCardView` marks a federated post's card), the content, and a "View original"
link back to the real post on Bluesky.
-}
federatedPostView : Post -> Html Msg
federatedPostView post =
    div [ class "post-detail" ]
        [ div [ class "post-author-link" ]
            [ text "⇄ "
            , Authors.avatar (Authors.name post.author) (post.author |> Maybe.andThen .avatar |> Maybe.andThen .url)
            , text (Authors.name post.author)
            ]
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
