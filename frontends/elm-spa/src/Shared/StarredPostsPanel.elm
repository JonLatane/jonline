module Shared.StarredPostsPanel exposing (Model, Msg(..), freshestPost, init, isStarred, rawKey, starKey, toggleStarMsg, update, view)

{-| Tracks which Posts the user has starred, in this browser. `StarPost`/
`UnstarPost` (see `protos/jonline.proto`) are auth-less, "friendly" counters
with no per-user state on the server at all (see `Post.unauthenticated_star_count`)
-- the *only* record of "did I star this" is this module's `starredPostIds`,
persisted to localStorage (see `Ports.persistStarredPosts`) keyed by
`postId@frontendHost` (see `starKey`) so it survives reloads and tells posts
from different servers apart.

All `StarPost`/`UnstarPost` calls -- from `Pages.Home_`/`Pages.Post.PostId_`,
via `Shared.StarredPostsPanelMsg` -- route through here so the persisted set
and the RPC can't drift apart. The starred count itself isn't optimistically
adjusted client-side; instead, `GotStarResult`'s `Post` (the RPC's response,
which already carries the server's fresh `unauthenticated_star_count`) is
cached here, and `freshestPost` lets `Pages.Home_`/`Pages.Post.PostId_` read
it back out for immediate feedback. They can't just pattern-match
`GotStarResult` out of a `Shared.Msg` they see in their own `update` --
`Main.elm` fires the gRPC call's `Cmd` from `Shared.update` directly, so its
eventual reply lands back in `Main.elm`'s top-level `Shared` branch, never
passing back through a page's own `update` the way the initiating `ToggleStar`
click did.

This module also owns fetching+rendering the actual starred `Post`s for the
nav's Starred Posts panel (`view`) -- `posts` is a cache of that fetched data,
separate from `starredPostIds` itself so a re-star/unstar doesn't need a
round-trip to redisplay a post we already have in hand (see `ToggleStar`).
-}

import Components.Posts as Posts
import Dict exposing (Dict)
import Grpc
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports
import Proto.Jonline exposing (GetPostsResponse, Post)
import Proto.Jonline.Jonline as Jonline
import Set exposing (Set)
import Shared.AccountsPanel as AccountsPanel
import Task
import Time
import UI.Classes exposing (classes, openClosedClass)


{-| The fetch state of one starred post, keyed by its `starKey` -- see
`kickOffFetches`. `ServerUnavailable` (its server isn't currently connected)
is kept distinct from `Failed` (the fetch itself came back an error, e.g. the
post is private and we're not signed in) so polling only keeps retrying the
former -- a server reconnecting is worth another try; a request that already
failed against a reachable server generally won't succeed just by asking
again.
-}
type PostFetchStatus
    = FetchingPost
    | PostFetchLoaded String Post
    | PostFetchFailed
    | ServerUnavailable


type alias Model =
    { starredPostIds : Set String
    , showStarredPostsPanel : Bool
    , posts : Dict String PostFetchStatus
    }


type Msg
    = ToggleStar AccountsPanel.Server Post
    | GotStarResult String Bool (Result Grpc.Error Post)
    | ToggleStarredPostsPanel
    | GotStarredPost String (Result Grpc.Error ( Maybe AccountsPanel.Account, GetPostsResponse ))
    | PollStarredPosts


{-| `flags` is the raw, persisted `List String` (see `Ports.persistStarredPosts`)
handed down from `Shared.init`, un-decoded -- same convention as
`AccountsPanel.init`'s `flags` argument.
-}
init : Decode.Value -> Model
init flags =
    { starredPostIds =
        Decode.decodeValue (Decode.list Decode.string) flags
            |> Result.map Set.fromList
            |> Result.withDefault Set.empty
    , showStarredPostsPanel = False
    , posts = Dict.empty
    }


{-| The persisted key for a Post on `frontendHost`. Always includes the host
explicitly -- unlike `Components.Posts.postHref`'s "bare id implies
mainFrontendHost" convention -- since `mainFrontendHost` can change later
(`AccountsPanel.ResetMainFrontendHost`) and a starred post needs to keep
pointing at the server it actually came from regardless.
-}
starKey : String -> Post -> String
starKey frontendHost post =
    post.id ++ "@" ++ frontendHost


isStarred : String -> Post -> Model -> Bool
isStarred frontendHost post model =
    Set.member (starKey frontendHost post) model.starredPostIds


{-| The freshest known version of `post` -- if it's ever been starred/unstarred
this session (see `ToggleStar`), `model.posts` holds either the optimistic
snapshot from that click or (once the RPC replies) the server's actual updated
`Post`, complete with its current star count. Falls back to `post` itself
(whatever the caller fetched it as) if it's never been touched.
-}
freshestPost : String -> Post -> Model -> Post
freshestPost frontendHost post model =
    case Dict.get (starKey frontendHost post) model.posts of
        Just (PostFetchLoaded _ freshPost) ->
            freshPost

        _ ->
            post


persistCmd : Set String -> Cmd Msg
persistCmd starredPostIds =
    Ports.persistStarredPosts (Encode.list Encode.string (Set.toList starredPostIds))


{-| `update` also needs `AccountsPanel.Model` (to resolve starred posts' hosts
to actual connected `Server`s/signed-in `Account`s -- see `kickOffFetches`)
and can itself surface a refreshed `Account` (from fetching a starred post
whose access token needed renewing first, see `Shared.MaybeAccountRequest`)
for `Shared.update` to persist via `AccountsPanel.AccountRefreshed` -- this
module can't dispatch that itself without importing `Shared` (a cycle, since
`Shared` imports this module).
-}
update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, Maybe AccountsPanel.Account )
update accountsPanelModel msg model =
    case msg of
        ToggleStar server post ->
            let
                key =
                    starKey server.frontendHost post

                starring =
                    not (Set.member key model.starredPostIds)

                newStarredPostIds =
                    if starring then
                        Set.insert key model.starredPostIds

                    else
                        Set.remove key model.starredPostIds

                rpc =
                    if starring then
                        Jonline.starPost

                    else
                        Jonline.unstarPost
            in
            ( { model
                | starredPostIds = newStarredPostIds

                -- We already have this Post in hand -- cache it so the panel can show
                -- it immediately without a redundant fetch.
                , posts = Dict.insert key (PostFetchLoaded server.frontendHost post) model.posts
              }
            , Cmd.batch
                [ persistCmd newStarredPostIds
                , Grpc.new rpc post
                    |> Grpc.setHost (AccountsPanel.serverUrl server)
                    |> Grpc.toTask
                    |> Task.attempt (GotStarResult key starring)
                ]
            , Nothing
            )

        GotStarResult key _ (Ok updatedPost) ->
            let
                newPosts =
                    case parseStarKey key of
                        Just ( _, host ) ->
                            Dict.insert key (PostFetchLoaded host updatedPost) model.posts

                        Nothing ->
                            model.posts
            in
            ( { model | posts = newPosts }, Cmd.none, Nothing )

        GotStarResult key starring (Err _) ->
            let
                revertedStarredPostIds =
                    if starring then
                        Set.remove key model.starredPostIds

                    else
                        Set.insert key model.starredPostIds
            in
            ( { model | starredPostIds = revertedStarredPostIds }, persistCmd revertedStarredPostIds, Nothing )

        ToggleStarredPostsPanel ->
            let
                toggledModel =
                    { model | showStarredPostsPanel = not model.showStarredPostsPanel }
            in
            if toggledModel.showStarredPostsPanel then
                let
                    ( fetchedModel, cmd ) =
                        kickOffFetches accountsPanelModel toggledModel
                in
                ( fetchedModel, cmd, Nothing )

            else
                ( toggledModel, Cmd.none, Nothing )

        PollStarredPosts ->
            let
                ( fetchedModel, cmd ) =
                    kickOffFetches accountsPanelModel model
            in
            ( fetchedModel, cmd, Nothing )

        GotStarredPost key (Ok ( maybeAccount, response )) ->
            let
                newStatus =
                    case ( parseStarKey key, List.head response.posts ) of
                        ( Just ( _, host ), Just post ) ->
                            PostFetchLoaded host post

                        _ ->
                            PostFetchFailed
            in
            ( { model | posts = Dict.insert key newStatus model.posts }, Cmd.none, maybeAccount )

        GotStarredPost key (Err _) ->
            ( { model | posts = Dict.insert key PostFetchFailed model.posts }, Cmd.none, Nothing )


{-| Fetches every starred post that isn't already loaded, in flight, or
permanently failed (see `PostFetchStatus`) -- grouped by host first, so each
server's connected `Server`/signed-in `Account` (from `AccountsPanel.Model`,
see `Shared.AccountsPanel.enabledAccountForServer`) is only looked up once per
server rather than once per post, and posts on a server we're not signed into
are still fetched anonymously (same as `Pages.Home_`/`Pages.Post.PostId_`),
just without any `LIMITED`/`PRIVATE` visibility they'd need an account for.
-}
kickOffFetches : AccountsPanel.Model -> Model -> ( Model, Cmd Msg )
kickOffFetches accountsPanelModel model =
    let
        pending =
            model.starredPostIds
                |> Set.toList
                |> List.filterMap parseStarKey
                |> List.filter (\( postId, host ) -> needsFetch model.posts (rawKey postId host))

        ( newPosts, cmds ) =
            pending
                |> groupByHost
                |> List.foldl (fetchGroup accountsPanelModel) ( model.posts, [] )
    in
    ( { model | posts = newPosts }, Cmd.batch cmds )


fetchGroup :
    AccountsPanel.Model
    -> ( String, List String )
    -> ( Dict String PostFetchStatus, List (Cmd Msg) )
    -> ( Dict String PostFetchStatus, List (Cmd Msg) )
fetchGroup accountsPanelModel ( host, postIds ) ( posts, cmds ) =
    case AccountsPanel.serverForHost accountsPanelModel.servers host of
        Nothing ->
            ( List.foldl (\postId -> Dict.insert (rawKey postId host) ServerUnavailable) posts postIds
            , cmds
            )

        Just server ->
            let
                maybeAccount =
                    AccountsPanel.enabledAccountForServer accountsPanelModel.accounts host

                fetchCmds =
                    List.map
                        (\postId ->
                            Posts.fetchPost server maybeAccount postId
                                |> Task.attempt (GotStarredPost (rawKey postId host))
                        )
                        postIds
            in
            ( List.foldl (\postId -> Dict.insert (rawKey postId host) FetchingPost) posts postIds
            , cmds ++ fetchCmds
            )


groupByHost : List ( String, String ) -> List ( String, List String )
groupByHost pairs =
    pairs
        |> List.foldl
            (\( postId, host ) -> Dict.update host (\existing -> Just (postId :: Maybe.withDefault [] existing)))
            Dict.empty
        |> Dict.toList


needsFetch : Dict String PostFetchStatus -> String -> Bool
needsFetch posts key =
    case Dict.get key posts of
        Just (PostFetchLoaded _ _) ->
            False

        Just FetchingPost ->
            False

        Just PostFetchFailed ->
            False

        Just ServerUnavailable ->
            True

        Nothing ->
            True


{-| The inverse of `starKey ++ "@" ++ host` -- a starred post's id and the
host it was starred from.
-}
parseStarKey : String -> Maybe ( String, String )
parseStarKey key =
    case String.split "@" key of
        [ postId, host ] ->
            Just ( postId, host )

        _ ->
            Nothing


rawKey : String -> String -> String
rawKey postId host =
    postId ++ "@" ++ host


{-| `ToggleStar`, if `host` currently resolves to a connected `Server` --
`Nothing` if it doesn't (nothing to star it against). Shared by every page
that renders a `postCard`/`postDetail` (`Pages.Home_`, `Pages.Post.PostId_`,
and this module's own `starredPostView`) so each doesn't re-derive the same
"look up the server, then wrap `ToggleStar`" logic.
-}
toggleStarMsg : AccountsPanel.Model -> String -> Post -> Maybe Msg
toggleStarMsg accountsPanelModel host post =
    AccountsPanel.serverForHost accountsPanelModel.servers host
        |> Maybe.map (\server -> ToggleStar server post)



-- VIEW


{-| The Starred Posts panel's content -- always rendered (even "closed"), same
as `UI.elm`'s Accounts/Admin panels, so opening/closing can be a plain CSS
transition. Returns `Html Msg` (this module's own `Msg`, mapped into
`Shared.Msg` by `UI.elm`'s `starredPostsMenu`) rather than `Html Shared.Msg`
directly -- unlike those other panels' view code, which lives in `UI.elm`
itself and so can reach `Shared.Msg` freely, this one can't (`Shared` imports
`Shared.StarredPostsPanel`, so the reverse import would be a cycle).
-}
view : String -> AccountsPanel.Model -> Maybe String -> Model -> Html Msg
view basePath accountsPanelModel currentPostKey model =
    let
        stateClass =
            openClosedClass model.showStarredPostsPanel

        orderedKeys =
            model.starredPostIds
                |> Set.toList
                |> List.sortBy (\key -> -(loadedTimestampMillis model.posts key))
    in
    div [ classes [ "accounts-panel", "starred-posts-panel", stateClass ] ]
        (div [ class "starred-posts-header" ] [ text "Starred Posts" ]
            :: (if Set.isEmpty model.starredPostIds then
                    [ div [ class "starred-posts-empty" ] [ text "No starred posts yet." ] ]

                else
                    List.map (starredPostView basePath accountsPanelModel currentPostKey model) orderedKeys
               )
        )


{-| Loaded posts sort most-recent-first, same as the Home page's feed; posts
that aren't loaded yet (or never will be) have no timestamp to sort by, so
they're pinned behind every loaded one instead of jumping around as they load.
-}
loadedTimestampMillis : Dict String PostFetchStatus -> String -> Int
loadedTimestampMillis posts key =
    case Dict.get key posts of
        Just (PostFetchLoaded _ post) ->
            Time.posixToMillis (Posts.postTimestamp post)

        _ ->
            0


starredPostView : String -> AccountsPanel.Model -> Maybe String -> Model -> String -> Html Msg
starredPostView basePath accountsPanelModel currentPostKey model key =
    case Dict.get key model.posts of
        Just (PostFetchLoaded host post) ->
            let
                starred =
                    isStarred host post model

                current =
                    currentPostKey == Just key

                onStarClicked =
                    toggleStarMsg accountsPanelModel host post
            in
            div [ class "starred-post-entry" ]
                [ case Posts.postContextLabel post.context of
                    Just contextLabel ->
                        div [ class "starred-post-context" ] [ text contextLabel ]

                    Nothing ->
                        text ""
                , Posts.postCard basePath accountsPanelModel.mainFrontendHost host current starred onStarClicked post
                ]

        Just FetchingPost ->
            div [ class "starred-post-entry post-loading" ] [ text "Loading…" ]

        Just PostFetchFailed ->
            div [ class "starred-post-entry post-error" ] [ text "Couldn't load this post." ]

        Just ServerUnavailable ->
            div [ class "starred-post-entry post-error" ] [ text "That post's server isn't reachable right now." ]

        Nothing ->
            text ""
