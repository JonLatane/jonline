module Components.Pages.PostsPage exposing
    ( Model
    , Msg
    , fromShared
    , init
    , subscriptions
    , update
    , view
    )

{-| The shared guts of a "recent posts" page: fetching recent posts from every
enabled server and rendering them with fade in/out animations -- reused by
`Pages.Home_` (which adds its own "Recent Posts" heading and passes
`author = Nothing`) and `Pages.Username_.Posts`/`Pages.User.UserId_.Posts`
(which pass the already-resolved profile `User`, restricting the feed to
that user's own posts and adding this module's own "Posts | &lt;name&gt;"
heading, via `Components.Pages.UserProfilePage.nameHeader`), mirroring how
`Components.Pages.UserProfilePage` is reused by `Pages.Username_` and
`Pages.User.UserId_` themselves.
-}

import Animation
import Components.Pages.UserProfilePage as UserProfilePage
import Components.Posts as Posts
import Components.Users exposing (usernameHref)
import Dict exposing (Dict)
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, a, div, h2, p, text)
import Html.Attributes exposing (class, href, style)
import Html.Keyed
import Proto.Jonline exposing (Post, User)
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.MediaViewerPanel as MediaViewerPanel
import Shared.StarredPostsPanel as StarredPostsPanel
import Task
import Time
import UI.Classes exposing (hostnameToCSSClass)
import UI.Flip



-- MODEL


type ServerPosts
    = Loading
    | Loaded (List Post)
    | Failed


{-| `accountId` is the enabled account (if any) the posts were/are being
fetched with, so a later account enable/disable on the same server can be
detected as "the acting credential changed" and trigger a re-fetch.
-}
type alias ServerFeed =
    { status : ServerPosts
    , accountId : Maybe String
    }


{-| A post's fade in/out state, keyed in `postAnimations` by `postAnimationKey`
so it survives independently of `postsByServer` -- see that dict's own doc
comment for why: a server being disabled (or re-fetched under a different
account) drops/replaces its posts in `postsByServer` immediately, but a
`removing` `flip` entry here keeps rendering its last-known `post`/`host`
until its fade-out finishes, instead of the post just vanishing. See
`UI.Flip` for what `flip` itself drives.
-}
type alias PostAnimation =
    { host : String
    , post : Post
    , flip : UI.Flip.State Msg
    }


type alias Model =
    { postsByServer : Dict String ServerFeed
    , postAnimations : Dict String PostAnimation
    , author : Maybe ( String, User )
    }


{-| `author`, if given, restricts the feed to that user's own posts (see
`Components.PostCard.fetchRecentPosts`) and adds a "Posts | &lt;name&gt;"
heading (see `view`) -- `Pages.Home_` passes `Nothing`,
`Pages.Username_.Posts`/`Pages.User.UserId_.Posts` pass their
already-resolved profile `User` paired with the host it was resolved from
(`Components.Users.Resolver`'s own `targetHost`, resolved before ever calling
this, so this module never needs to fetch the `User` itself -- it only needs
the host alongside it to look up that server's `AccountsPanel.Server`/signed-in
`Account` for `authorHeadingView`'s avatar).
-}
init : Shared.Model -> Maybe ( String, User ) -> ( Model, Effect Msg )
init shared author =
    fetchNewServers shared { postsByServer = Dict.empty, postAnimations = Dict.empty, author = author }


{-| Drops posts for servers that are no longer enabled (so disabling a server
hides its posts entirely), and re-fetches a server whose acting account (the
first enabled account signed into it, or anonymous) has changed since the
last fetch -- covering both disabling an account (falls back to anonymous)
and enabling a different one. Already-fetched-with-the-same-account servers
are cheap to skip, so this is safe to call as often as it likes.

This is event-driven -- any `AccountsPanel` message passing through `update`'s
`SharedMsg` branch triggers a call, since that covers server/account
add/remove/enable/toggle, including reconnecting persisted servers on app
startup (`Main.notifyPageOfSharedMsg` forwards those top-level `Shared`
messages into whichever page is active). `subscriptions`' poll is just a
distrustful fallback in case some future state change doesn't route through
`SharedMsg`, so it can be slow.

-}
fetchNewServers : Shared.Model -> Model -> ( Model, Effect Msg )
fetchNewServers shared model =
    let
        enabledServers =
            AccountsPanel.enabledServers shared.accountsPanel

        currentAccountId server =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost
                |> Maybe.map AccountsPanel.accountId

        serversToFetch =
            enabledServers
                |> List.filter
                    (\server ->
                        case Dict.get server.frontendHost model.postsByServer of
                            Nothing ->
                                True

                            Just feed ->
                                feed.accountId /= currentAccountId server
                    )

        fetchEffect server =
            Posts.fetchRecentPosts
                shared.accountsPanel
                ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost |> Maybe.map .userId
                , server.frontendHost
                )
                (model.author |> Maybe.map (Tuple.second >> .id))
                |> Task.attempt (GotServerPosts server.frontendHost)
                |> Effect.fromCmd

        prunedPostsByServer =
            Dict.filter (\host _ -> List.member host (List.map .frontendHost enabledServers)) model.postsByServer
    in
    ( { model
        | postsByServer =
            List.foldl
                (\server -> Dict.insert server.frontendHost { status = Loading, accountId = currentAccountId server })
                prunedPostsByServer
                serversToFetch
      }
    , Effect.batch (List.map fetchEffect serversToFetch)
    )
        |> Tuple.mapFirst syncAnimations



-- ANIMATION


{-| Identifies a post independently of which server/account fetched it, for
`postAnimations` -- `postHref`'s `id@host` convention is reused here purely as
a unique dict key, not as a route.
-}
postAnimationKey : String -> Post -> String
postAnimationKey host post =
    host ++ "@" ++ post.id


{-| A freshly-seen post: starts invisible/slightly shrunk and immediately
animates in to its natural opacity/scale.
-}
newPostAnimation : String -> Post -> PostAnimation
newPostAnimation host post =
    { host = host, post = post, flip = UI.Flip.enter }


{-| A post that was mid fade-out (its server got disabled, then re-enabled --
or its feed got re-fetched -- before the fade-out finished) reappearing:
interrupts whatever fade-out step was queued (including its trailing
`RemovePost` send, so that message never fires for this key) and animates
back in.
-}
reappearingPostAnimation : String -> Post -> PostAnimation -> PostAnimation
reappearingPostAnimation host post anim =
    { anim | host = host, post = post, flip = UI.Flip.reappear anim.flip }


{-| A post no longer present in `postsByServer` (its server was disabled, or
its feed is being re-fetched under a different account): animates out, then
sends `RemovePost` to actually drop it from `postAnimations` once the fade
finishes.
-}
removingPostAnimation : String -> PostAnimation -> PostAnimation
removingPostAnimation key anim =
    { anim | flip = UI.Flip.remove (RemovePost key) anim.flip }


{-| Reconciles `postAnimations` with the posts currently `Loaded` in
`postsByServer`: starts a fade-in for newly-seen posts, a fade-out for posts
that dropped out (rather than deleting them outright), and un-interrupts a
still-fading-out post that reappeared. Safe/cheap to call after every
`postsByServer` change, so `update` just calls it unconditionally wherever
that dict might have changed.
-}
syncAnimations : Model -> Model
syncAnimations model =
    let
        currentPosts : Dict String ( String, Post )
        currentPosts =
            model.postsByServer
                |> Dict.toList
                |> List.concatMap
                    (\( host, feed ) ->
                        case feed.status of
                            Loaded posts ->
                                List.map (\post -> ( postAnimationKey host post, ( host, post ) )) posts

                            _ ->
                                []
                    )
                |> Dict.fromList

        addOrRefresh key ( host, post ) animations =
            case Dict.get key animations of
                Nothing ->
                    Dict.insert key (newPostAnimation host post) animations

                Just anim ->
                    if anim.flip.removing then
                        Dict.insert key (reappearingPostAnimation host post anim) animations

                    else
                        Dict.insert key { anim | host = host, post = post } animations

        withCurrent =
            Dict.foldl addOrRefresh model.postAnimations currentPosts

        startRemovingIfGone key anim animations =
            if anim.flip.removing || Dict.member key currentPosts then
                animations

            else
                Dict.insert key (removingPostAnimation key anim) animations
    in
    { model | postAnimations = Dict.foldl startRemovingIfGone withCurrent withCurrent }



-- UPDATE


type Msg
    = GotServerPosts String (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetPostsResponse ))
    | Poll
    | Animate Animation.Msg
    | RemovePost String
    | SharedMsg Shared.Msg


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
(see `Main.notifyPageOfSharedMsg`) into `update`'s `SharedMsg` branch, without
exposing the `SharedMsg` constructor itself (and thus every other constructor
of this otherwise-opaque `Msg`) outside this module.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        GotServerPosts frontendHost (Ok ( maybeAccountsPanelMsg, response )) ->
            let
                accountEffect =
                    maybeAccountsPanelMsg
                        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
                        |> Maybe.withDefault Effect.none
            in
            ( { model
                | postsByServer =
                    Dict.update frontendHost
                        (Maybe.map (\feed -> { feed | status = Loaded response.posts }))
                        model.postsByServer
              }
                |> syncAnimations
            , accountEffect
            )

        GotServerPosts frontendHost (Err _) ->
            ( { model
                | postsByServer =
                    Dict.update frontendHost (Maybe.map (\feed -> { feed | status = Failed })) model.postsByServer
              }
                |> syncAnimations
            , Effect.none
            )

        Poll ->
            fetchNewServers shared model

        Animate animMsg ->
            let
                step key anim ( animations, accCmds ) =
                    let
                        ( newFlip, cmd ) =
                            UI.Flip.animate animMsg anim.flip
                    in
                    ( Dict.insert key { anim | flip = newFlip } animations, cmd :: accCmds )

                ( newAnimations, cmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.postAnimations
            in
            ( { model | postAnimations = newAnimations }, Effect.batch (List.map Effect.fromCmd cmds) )

        RemovePost key ->
            ( { model | postAnimations = Dict.remove key model.postAnimations }, Effect.none )

        SharedMsg subMsg ->
            let
                ( fetchedModel, fetchEffect ) =
                    case subMsg of
                        Shared.AccountsPanelMsg _ ->
                            fetchNewServers shared model

                        _ ->
                            ( model, Effect.none )
            in
            ( fetchedModel, Effect.batch [ Effect.fromShared subMsg, fetchEffect ] )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every 30000 (\_ -> Poll)
        , UI.Flip.subscription Animate (List.map .flip (Dict.values model.postAnimations))
        ]



-- VIEW


view : Shared.Model -> Model -> Html Msg
view shared model =
    div []
        [ authorHeadingView shared model.author
        , postsListView shared model
        ]


{-| "Posts" alone once there's an `author` to filter by (even before that
`User` -- already resolved by the caller, see `init` -- has actually
rendered), upgraded to "Posts | &lt;name&gt;" via
`Components.Pages.UserProfilePage.nameHeader` (with that author's avatar, via
its resolved-host `AccountsPanel.Server`/signed-in `Account`, if that host is
still a known server -- falling back to `UserProfilePage.usernameHeading`,
avatar-less, if not) -- absent entirely for `Pages.Home_`'s unfiltered feed
(`author == Nothing`), which supplies its own "Recent Posts" heading instead.
-}
authorHeadingView : Shared.Model -> Maybe ( String, User ) -> Html Msg
authorHeadingView shared maybeAuthor =
    case maybeAuthor of
        Nothing ->
            text ""

        Just ( host, author ) ->
            let
                profileUrl =
                    usernameHref "" shared.accountsPanel.mainFrontendHost host author.username
            in
            div [ class "posts-page-heading" ]
                [ h2 [] [ text "Posts" ]
                , a [ href profileUrl, class <| hostnameToCSSClass host ]
                    [ case AccountsPanel.serverForHost shared.accountsPanel.servers host of
                        Just server ->
                            UserProfilePage.nameHeader server (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host) author

                        Nothing ->
                            UserProfilePage.usernameHeading author
                    ]
                ]


postsListView : Shared.Model -> Model -> Html Msg
postsListView shared model =
    let
        sortedAnimations =
            model.postAnimations
                |> Dict.toList
                |> List.sortBy (\( _, anim ) -> -(Time.posixToMillis (Posts.postTimestamp anim.post)))
    in
    if Dict.isEmpty model.postsByServer then
        p [ class "posts-empty" ] [ text "Connect to a server to see recent posts." ]

    else if List.isEmpty sortedAnimations then
        p [ class "posts-empty" ] [ text "No posts yet." ]

    else
        Html.Keyed.node "div"
            [ class "posts-list flip-animated-column" ]
            (List.map (postAnimationView shared) sortedAnimations)


{-| Wraps `Posts.postCard` in a fading/scaling/collapsing animated `<div>`
(see `syncAnimations`) -- the `.flip-collapsed` class (present while
`entering` or `removing`) is what makes `flip.css`'s `.flip-animated-item`
rules grow/shrink this wrapper's own height, which is what makes the _other_
posts slide smoothly into the space this one leaves/needs, on top of its own
fade -- see that rule's doc comment for how. The inner `div` is purely a clip
layer (`.flip-animated-item > *` in `flip.css`, invisible/borderless) so the
inter-post spacing it holds as `padding-bottom` can shrink away smoothly
along with everything else, rather than showing up inside `.post-card`'s own
border; it also carries `pointer-events: none` while `removing` so a
fading-out card (e.g. from a just-disabled server) can't be clicked/starred
while it's on its way out.
-}
postAnimationView : Shared.Model -> ( String, PostAnimation ) -> ( String, Html Msg )
postAnimationView shared ( key, anim ) =
    let
        pointerEventsAttr =
            if anim.flip.removing then
                [ style "pointer-events" "none" ]

            else
                []
    in
    ( key
    , div (UI.Flip.itemAttributes UI.Flip.Vertical anim.flip False)
        [ div pointerEventsAttr [ postCardView shared ( anim.host, anim.post ) ] ]
    )


postCardView : Shared.Model -> ( String, Post ) -> Html Msg
postCardView shared ( host, post ) =
    let
        displayPost =
            StarredPostsPanel.freshestPost host post shared.starredPostsPanel

        starred =
            StarredPostsPanel.isStarred host displayPost shared.starredPostsPanel

        onStarClicked =
            StarredPostsPanel.toggleStarMsg shared.accountsPanel host displayPost
                |> Maybe.map (Shared.StarredPostsPanelMsg >> SharedMsg)

        maybeServer =
            AccountsPanel.serverForHost shared.accountsPanel.servers host

        maybeAccount =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host

        onMediaClicked mediaId =
            SharedMsg (Shared.MediaViewerPanelMsg (MediaViewerPanel.Open displayPost mediaId host))
    in
    Posts.postCard shared.browserTimeZone shared.basePath shared.accountsPanel.mainFrontendHost host maybeServer maybeAccount onMediaClicked False False starred onStarClicked displayPost
