module Shared.StarredPostsPanel exposing (Model, Msg(..), freshestPost, init, isStarred, rawKey, refreshHosts, starKey, subscriptions, toggleStarMsg, update, view)

{-| Tracks which Posts the user has starred, in this browser. `StarPost`/
`UnstarPost` (see `protos/jonline.proto`) are auth-less, "friendly" counters
with no per-user state on the server at all (see `Post.unauthenticated_star_count`)
-- the _only_ record of "did I star this" is this module's `starredPostIds`,
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

import Animation
import Browser.Dom as Dom
import Components.PostCard as Posts
import Components.ServerDependentView as ServerDependentView
import Dict exposing (Dict)
import Grpc
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Html.Keyed
import Json.Decode as Decode
import Json.Encode as Encode
import Ports
import Proto.Jonline exposing (GetPostsResponse, Post)
import Proto.Jonline.Jonline as Jonline
import Set exposing (Set)
import Shared.AccountsPanel as AccountsPanel
import Shared.MediaViewerPanel as MediaViewerPanel
import Task
import UI.Classes exposing (classes, openClosedClass)
import UI.Flip


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

    -- Same keys as `starredPostIds`, but ordered -- newest-star-first until
    -- the user drags that order around with `MoveStarUpClicked`/
    -- `MoveStarDownClicked` -- `starredPostIds` is a `Set` (unordered) so it
    -- can't drive display order itself. Kept in lockstep with
    -- `starredPostIds` by every mutation below.
    , starOrder : List String
    , showStarredPostsPanel : Bool
    , posts : Dict String PostFetchStatus

    -- In-flight/settling FLIP slide animations for starred posts just
    -- reordered via `MoveStarUpClicked`/`MoveStarDownClicked` (see
    -- `UI.Flip.MoveState`), keyed the same as `starOrder`/`posts`. An entry
    -- with no key here (the common case) just renders at rest.
    , moveAnimations : Dict String (UI.Flip.MoveState Msg)

    -- Each starred post's enter/leave `UI.Flip.State`, keyed the same as
    -- `starOrder`/`posts` -- `update`'s very last step (see
    -- `syncItemAnimations`) is always `UI.Flip.syncEnter identity
    -- model.starOrder`, which inserts a fresh `UI.Flip.enter` for any key
    -- that doesn't have an entry yet, so a newly-starred post animates in
    -- with no need to hunt down every "this added a star" code path by hand.
    -- A post mid fade-out after being unstarred (see `ToggleStar`) stays in
    -- `starredPostIds`/`starOrder` -- and its entry here keeps `removing =
    -- True` -- until its fade actually finishes (`FinishUnstar`), so it keeps
    -- rendering (fading/collapsing) in the panel instead of just vanishing.
    -- `init` seeds this with a plain `UI.Flip.restingState` (not `enter`) for
    -- every persisted star, so reloading the app doesn't replay their
    -- entrances.
    , starAnimations : Dict String (UI.Flip.State Msg)
    }


type Msg
    = ToggleStar AccountsPanel.Server Post
    | GotStarResult String Bool (Result Grpc.Error Post)
    | ToggleStarredPostsPanel
    | CloseStarredPostsPanel
    | EnableServerClicked String
    | GotStarredPost String (Result Grpc.Error ( Maybe AccountsPanel.Account, GetPostsResponse ))
    | PollStarredPosts
    | MoveStarUpClicked String
    | MoveStarDownClicked String
    | GotPreMoveStarPositions String String Int (Result Dom.Error ( Dom.Element, Dom.Element ))
    | AnimateMove Animation.Msg
    | MoveSettled String
    | FinishUnstar String
    | AnimateItemFlip Animation.Msg
    | MediaClicked String Post String


{-| `flags` is the raw, persisted `List String` (see `Ports.persistStarredPosts`)
handed down from `Shared.init`, un-decoded -- same convention as
`AccountsPanel.init`'s `flags` argument.
-}
init : Decode.Value -> Model
init flags =
    let
        persistedOrder =
            Decode.decodeValue (Decode.list Decode.string) flags
                |> Result.withDefault []
    in
    { starredPostIds = Set.fromList persistedOrder
    , starOrder = persistedOrder
    , showStarredPostsPanel = False
    , posts = Dict.empty
    , moveAnimations = Dict.empty

    -- Seeded with a *resting* (not `enter`) state for every persisted star,
    -- so `syncItemAnimations` -- which would otherwise treat any key with no
    -- entry as "just appeared" -- doesn't replay every star's entrance on
    -- every reload.
    , starAnimations = persistedOrder |> List.map (\key -> ( key, UI.Flip.restingState )) |> Dict.fromList
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


{-| The DOM `id` a starred post's entry is rendered with (see
`starredPostEntry`) -- purely so `MoveStarUpClicked`/`MoveStarDownClicked` can
measure its position before/after a reorder (`Browser.Dom.getElement`) to
drive its `UI.Flip` slide.
-}
starEntryDomId : String -> String
starEntryDomId key =
    "starred-post-entry-" ++ key


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


persistCmd : List String -> Cmd Msg
persistCmd starOrder =
    Ports.persistStarredPosts (Encode.list Encode.string starOrder)


{-| `update` also needs `AccountsPanel.Model` (to resolve starred posts' hosts
to actual connected `Server`s/signed-in `Account`s -- see `kickOffFetches`)
and can itself surface an `AccountsPanel.Msg` it needs forwarded on its behalf
-- either a refreshed `Account` (from fetching a starred post whose access
token needed renewing first, see `Shared.MaybeAccountRequest`), persisted via
`AccountsPanel.AccountRefreshed`, or a disabled server's owner re-enabling it
(`EnableServerClicked`), forwarded as `AccountsPanel.ToggleServerEnabled` --
for `Shared.update` to actually dispatch. This module can't dispatch either
itself without importing `Shared` (a cycle, since `Shared` imports this
module).

Same reasoning covers the trailing `Maybe MediaViewerPanel.Msg` (paired with
the `Maybe AccountsPanel.Msg` above -- Elm tuples top out at three items, so
the two forwards share the last slot rather than this being a 4-tuple):
`MediaClicked` (a starred post's media tapped, see `starredPostView`) doesn't
change this module's own `Model` at all (see `updateHelp`'s no-op branch for
it) -- it just needs `Shared.update` to open `Shared.MediaViewerPanel` on its
behalf, same forwarding convention as the `AccountsPanel.Msg` case, just
computed directly from `msg` here rather than from `updateHelp`'s result,
since there's no `Model` state involved.
-}
update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, ( Maybe AccountsPanel.Msg, Maybe MediaViewerPanel.Msg ) )
update accountsPanelModel msg model =
    let
        ( newModel, cmd, maybeAccountsPanelMsg ) =
            updateHelp accountsPanelModel msg model

        maybeMediaViewerPanelMsg =
            case msg of
                MediaClicked host post mediaId ->
                    Just (MediaViewerPanel.Open post mediaId host)

                _ ->
                    Nothing
    in
    ( syncItemAnimations newModel, cmd, ( maybeAccountsPanelMsg, maybeMediaViewerPanelMsg ) )


{-| Inserts a fresh `UI.Flip.enter` into `starAnimations` for any starred
post that doesn't have an entry yet -- see that field's own doc, and
`UI.Flip.syncEnter`. Run unconditionally after every message (see `update`),
same reasoning as `AccountsPanel.syncItemAnimations`.
-}
syncItemAnimations : Model -> Model
syncItemAnimations model =
    { model | starAnimations = UI.Flip.syncEnter identity model.starOrder model.starAnimations }


updateHelp : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, Maybe AccountsPanel.Msg )
updateHelp accountsPanelModel msg model =
    case msg of
        ToggleStar server post ->
            let
                key =
                    starKey server.frontendHost post

                starring =
                    not (Set.member key model.starredPostIds)

                rpc =
                    if starring then
                        Jonline.starPost

                    else
                        Jonline.unstarPost

                rpcCmd =
                    Grpc.new rpc post
                        |> Grpc.setHost (AccountsPanel.serverUrl server)
                        |> Grpc.toTask
                        |> Task.attempt (GotStarResult key starring)

                -- We already have this Post in hand -- cache it so the panel can show
                -- it immediately without a redundant fetch.
                newPosts =
                    Dict.insert key (PostFetchLoaded server.frontendHost post) model.posts
            in
            if starring then
                let
                    newStarredPostIds =
                        Set.insert key model.starredPostIds

                    newStarOrder =
                        key :: model.starOrder
                in
                ( { model | starredPostIds = newStarredPostIds, starOrder = newStarOrder, posts = newPosts }
                , Cmd.batch [ persistCmd newStarOrder, rpcCmd ]
                , Nothing
                )

            else
                -- Doesn't actually unstar (remove from `starredPostIds`/`starOrder`)
                -- yet -- starts its fade-out in the panel (see `starAnimations`),
                -- which sends `FinishUnstar` once that finishes to do the real
                -- removal. The RPC itself still fires immediately either way.
                let
                    currentState =
                        Dict.get key model.starAnimations |> Maybe.withDefault UI.Flip.restingState
                in
                ( { model
                    | posts = newPosts
                    , starAnimations = Dict.insert key (UI.Flip.remove (FinishUnstar key) currentState) model.starAnimations
                  }
                , rpcCmd
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
            if starring then
                -- Starring failed -- we DID optimistically add it, so revert that.
                let
                    revertedStarredPostIds =
                        Set.remove key model.starredPostIds

                    revertedStarOrder =
                        List.filter ((/=) key) model.starOrder
                in
                ( { model | starredPostIds = revertedStarredPostIds, starOrder = revertedStarOrder }
                , persistCmd revertedStarOrder
                , Nothing
                )

            else
                -- Unstarring failed -- we deferred actually removing it (see
                -- `ToggleStar`), so it's still in `starredPostIds`/`starOrder`
                -- either way; just undo whatever we started.
                case Dict.get key model.starAnimations of
                    Just _ ->
                        -- Still fading out -- cancel that, fading back in instead
                        -- (`UI.Flip.reappear`), same as a post that was mid
                        -- fade-out reappearing elsewhere (see `Pages.Home_`).
                        ( { model | starAnimations = Dict.update key (Maybe.map UI.Flip.reappear) model.starAnimations }
                        , Cmd.none
                        , Nothing
                        )

                    Nothing ->
                        -- The fade (and the real removal, `FinishUnstar`) already
                        -- finished before this reply arrived -- re-add it, same as
                        -- if freshly starred again.
                        let
                            revertedStarredPostIds =
                                Set.insert key model.starredPostIds

                            revertedStarOrder =
                                key :: model.starOrder
                        in
                        ( { model | starredPostIds = revertedStarredPostIds, starOrder = revertedStarOrder }
                        , persistCmd revertedStarOrder
                        , Nothing
                        )

        FinishUnstar key ->
            let
                newStarredPostIds =
                    Set.remove key model.starredPostIds

                newStarOrder =
                    List.filter ((/=) key) model.starOrder
            in
            ( { model | starredPostIds = newStarredPostIds, starOrder = newStarOrder, starAnimations = Dict.remove key model.starAnimations }
            , persistCmd newStarOrder
            , Nothing
            )

        AnimateItemFlip animMsg ->
            let
                step key state ( states, accCmds ) =
                    let
                        ( newState, cmd ) =
                            UI.Flip.animate animMsg state
                    in
                    ( Dict.insert key newState states, cmd :: accCmds )

                ( newStarAnimations, cmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.starAnimations
            in
            ( { model | starAnimations = newStarAnimations }, Cmd.batch cmds, Nothing )

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

        -- Unlike `ToggleStarredPostsPanel`, always closes rather than
        -- flipping -- dispatched by the Home link (`UI.navLink`) on every
        -- click, so navigating Home also dismisses this panel if it happened
        -- to be open, same as `AccountsPanel.CloseAccountsPanel`'s `i`-button.
        CloseStarredPostsPanel ->
            ( { model | showStarredPostsPanel = False }, Cmd.none, Nothing )

        EnableServerClicked host ->
            -- Just forwards to `AccountsPanel.ToggleServerEnabled` -- once
            -- `Shared.update` dispatches it and the server's `enabled` flips
            -- back on, `refreshHosts` re-fetches this post the same as any
            -- other reconnect (see `Shared.starredPostsRefreshHosts`).
            ( model, Cmd.none, Just (AccountsPanel.ToggleServerEnabled host) )

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
            ( { model | posts = Dict.insert key newStatus model.posts }, Cmd.none, Maybe.map AccountsPanel.AccountRefreshed maybeAccount )

        GotStarredPost key (Err _) ->
            ( { model | posts = Dict.insert key PostFetchFailed model.posts }, Cmd.none, Nothing )

        MoveStarUpClicked key ->
            ( model, UI.Flip.beginReorder identity starEntryDomId GotPreMoveStarPositions -1 key model.starOrder, Nothing )

        MoveStarDownClicked key ->
            ( model, UI.Flip.beginReorder identity starEntryDomId GotPreMoveStarPositions 1 key model.starOrder, Nothing )

        GotPreMoveStarPositions key _ offset (Err _) ->
            -- Couldn't measure -- e.g. an entry not actually mounted -- fall
            -- back to reordering without a slide animation, same end state
            -- either way.
            let
                newOrder =
                    UI.Flip.moveListItemBy identity offset key model.starOrder
            in
            ( { model | starOrder = newOrder }, persistCmd newOrder, Nothing )

        GotPreMoveStarPositions key neighborKey offset (Ok ( entryEl, neighborEl )) ->
            -- Both `key` and `neighborKey` are adjacent, so their post-swap
            -- positions are derivable from this one (pre-swap) measurement --
            -- see `UI.Flip.applyReorder`/`swapDeltas`. Computing it this way
            -- (rather than reordering first, then measuring again after the
            -- next render) means the pinned "Invert" transform is set in the
            -- very same update as the reorder, so there's no frame where the
            -- reordered list renders at rest before the animation kicks in.
            let
                newOrder =
                    UI.Flip.moveListItemBy identity offset key model.starOrder

                newModel =
                    { model | starOrder = newOrder }
            in
            ( { newModel
                | moveAnimations =
                    UI.Flip.applyReorder UI.Flip.Vertical MoveSettled key neighborKey entryEl neighborEl newModel.moveAnimations
              }
            , persistCmd newOrder
            , Nothing
            )

        AnimateMove animMsg ->
            let
                step key state ( states, cmds ) =
                    let
                        ( newState, cmd ) =
                            UI.Flip.moveAnimate animMsg state
                    in
                    ( Dict.insert key newState states, cmd :: cmds )

                ( newMoveAnimations, moveCmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.moveAnimations
            in
            ( { model | moveAnimations = newMoveAnimations }
            , Cmd.batch moveCmds
            , Nothing
            )

        MoveSettled key ->
            ( { model | moveAnimations = Dict.update key (Maybe.map (\state -> { state | moving = False })) model.moveAnimations }
            , Cmd.none
            , Nothing
            )

        MediaClicked _ _ _ ->
            -- Handled by `update`, above -- see its own doc comment. Doesn't
            -- touch this module's `Model`, so nothing to do here.
            ( model, Cmd.none, Nothing )


{-| Just the starred posts' reorder-slide animations (see `moveAnimations`)
-- only while the panel's actually open, same reasoning as `Shared.subscriptions`'
own poll for this module.
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ if model.showStarredPostsPanel then
            UI.Flip.moveSubscription AnimateMove (Dict.values model.moveAnimations)

          else
            Sub.none

        -- Unlike the reorder-only `AnimateMove` above, this can't be gated on
        -- the panel being open -- `ToggleStar` (and so a pending `FinishUnstar`)
        -- can be triggered from anywhere a post card renders (Home, Post
        -- detail, ...), not just from here, so this needs to keep ticking
        -- regardless in order to ever actually fire.
        , UI.Flip.subscription AnimateItemFlip (Dict.values model.starAnimations)
        ]


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


{-| Clears any cached fetched Posts (see `posts`) on `hosts` and kicks off
fresh fetches for whichever of those are still starred -- for `Shared.update`
to call when the signed-in account for a server changes (comparing
`AccountsPanel.enabledAccountForServer` before/after an `AccountsPanelMsg`),
since a starred post's visibility -- and its cached `freshestPost` snapshot --
can depend on which account fetched it. A no-op if `hosts` is empty, the
common case for most `AccountsPanel.Msg`s.
-}
refreshHosts : AccountsPanel.Model -> List String -> Model -> ( Model, Cmd Msg )
refreshHosts accountsPanelModel hosts model =
    if List.isEmpty hosts then
        ( model, Cmd.none )

    else
        let
            hostSet =
                Set.fromList hosts

            clearedPosts =
                Dict.filter
                    (\key _ ->
                        case parseStarKey key of
                            Just ( _, host ) ->
                                not (Set.member host hostSet)

                            Nothing ->
                                True
                    )
                    model.posts
        in
        kickOffFetches accountsPanelModel { model | posts = clearedPosts }


{-| `ServerDependentView.availableServer` -- not the raw
`AccountsPanel.serverForHost` -- so a starred post whose server is known but
disabled (see `Shared.AccountsPanel`'s `Server.enabled`) is treated the same
as one whose server was never connected at all: marked `ServerUnavailable`
below rather than fetched, matching the panel's own `starredPostView`, which
shows the same "server isn't reachable" message either way.
-}
fetchGroup :
    AccountsPanel.Model
    -> ( String, List String )
    -> ( Dict String PostFetchStatus, List (Cmd Msg) )
    -> ( Dict String PostFetchStatus, List (Cmd Msg) )
fetchGroup accountsPanelModel ( host, postIds ) ( posts, cmds ) =
    case ServerDependentView.availableServer accountsPanelModel.servers host of
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

        count =
            List.length model.starOrder
    in
    div [ classes [ "starred-posts-panel", "nav-panel", stateClass ] ]
        (div [ class "starred-posts-header" ] [ text "Starred Posts" ]
            :: (if Set.isEmpty model.starredPostIds then
                    [ div [ class "starred-posts-empty" ] [ text "No starred posts yet." ] ]

                else
                    -- `starOrder` starts newest-star-first (see `Model`), but the user
                    -- can then drag it around from there via `MoveStarUpClicked`/
                    -- `MoveStarDownClicked`.
                    [ Html.Keyed.node "div"
                        [ classes [ "starred-posts-list", "flip-animated-column" ] ]
                        (List.indexedMap
                            (\index key -> ( key, starredPostRowFlip basePath accountsPanelModel currentPostKey model count index key ))
                            model.starOrder
                        )
                    ]
               )
        )


{-| Wraps `starredPostRow` in a fading/scaling/collapsing animated outer
`div` (entering when freshly starred, removing when unstarred -- see
`starAnimations`/`UI.Flip`), same two-layer reasoning as `UI.accountRowFlip`
(fade/collapse here vs. `starredPostRow`'s own, independent reorder-slide).
-}
starredPostRowFlip : String -> AccountsPanel.Model -> Maybe String -> Model -> Int -> Int -> String -> Html Msg
starredPostRowFlip basePath accountsPanelModel currentPostKey model count index key =
    let
        flipState =
            Dict.get key model.starAnimations |> Maybe.withDefault UI.Flip.restingState

        isMoving =
            Dict.get key model.moveAnimations |> Maybe.map .moving |> Maybe.withDefault False

        pointerEventsAttr =
            if flipState.removing then
                [ Html.Attributes.style "pointer-events" "none" ]

            else
                []
    in
    div (UI.Flip.itemAttributes UI.Flip.Vertical flipState isMoving)
        [ div pointerEventsAttr [ starredPostRow basePath accountsPanelModel currentPostKey model count index key ] ]


{-| Wraps `starredPostView`'s content with `UI.Flip`'s slide-on-reorder
transform and the up/down reorder buttons -- mirrors `UI.accountRow`'s
equivalent for Accounts.
-}
starredPostRow : String -> AccountsPanel.Model -> Maybe String -> Model -> Int -> Int -> String -> Html Msg
starredPostRow basePath accountsPanelModel currentPostKey model count index key =
    let
        moveAttrs =
            model.moveAnimations
                |> Dict.get key
                |> Maybe.map UI.Flip.moveAttributes
                |> Maybe.withDefault []
    in
    div
        (id (starEntryDomId key)
            :: class "starred-post-row"
            :: moveAttrs
        )
        [ UI.Flip.reorderButtons
            { moveUp = MoveStarUpClicked key
            , moveDown = MoveStarDownClicked key
            , canMoveUp = index > 0
            , canMoveDown = index < count - 1
            }
        , starredPostView basePath accountsPanelModel currentPostKey model key
        ]


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

                maybeServer =
                    AccountsPanel.serverForHost accountsPanelModel.servers host

                maybeAccount =
                    AccountsPanel.enabledAccountForServer accountsPanelModel.accounts host

                onMediaClicked mediaId =
                    MediaClicked host post mediaId
            in
            div [ class "starred-post-entry" ]
                [ case Posts.postContextLabel post.context of
                    Just contextLabel ->
                        div [ class "starred-post-context" ] [ text contextLabel ]

                    Nothing ->
                        text ""
                , Posts.postCard basePath accountsPanelModel.mainFrontendHost host maybeServer maybeAccount onMediaClicked True current starred onStarClicked post
                ]

        Just FetchingPost ->
            div [ class "starred-post-entry post-loading" ] [ text "Loading…" ]

        Just PostFetchFailed ->
            div [ class "starred-post-entry post-error" ] [ text ("Couldn't load Post " ++ key ++ ". Maybe it doesn't exist, or maybe you need to be logged in?") ]

        Just ServerUnavailable ->
            let
                -- `ServerUnavailable` covers both "server not connected at
                -- all" and "server connected but disabled" (see `fetchGroup`'s
                -- use of `ServerDependentView.availableServer`) -- only the
                -- latter has anything to offer a button for, so re-derive the
                -- actual `Server` (if disabled) from `key`'s host.
                maybeDisabledServer =
                    parseStarKey key
                        |> Maybe.andThen (\( _, host ) -> AccountsPanel.serverForHost accountsPanelModel.servers host)
                        |> Maybe.andThen
                            (\server ->
                                if server.enabled then
                                    Nothing

                                else
                                    Just server
                            )
            in
            div [ class "starred-post-entry post-error" ]
                (text "That post's server isn't reachable right now."
                    :: (case maybeDisabledServer of
                            Just server ->
                                [ button [ onClick (EnableServerClicked server.frontendHost) ] [ text ("Enable " ++ server.frontendHost) ] ]

                            Nothing ->
                                []
                       )
                )

        Nothing ->
            text ""
