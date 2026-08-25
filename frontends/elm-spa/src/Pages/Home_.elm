module Pages.Home_ exposing (Model, Msg, fromShared, page)

{-| `/` -- upcoming events plus recent posts from every enabled server (the `Feed` variant), unless
`mainFrontendHost`'s own `ServerConfiguration.customTabs.home` overrides Home (`UI.CustomNav.homeTarget`,
restricted to `HOME_TAB`/`EVENTS_TAB`/`POSTS_TAB` or a bare `post_id` -- see that field's own proto
doc), in which case this instead renders: a top-level `Components.Pages.EventsPage` (`HomeEvents`,
target `EVENTS_TAB`) or `Components.Pages.PostsPage` (`HomePosts`, target `POSTS_TAB`) -- exactly
`Pages.Events`/`Pages.Posts` themselves render, not `Feed`'s own compact embedded copies (see those
two variants' own docs) -- or a specific Post (`HomePost`, target a `post_id`), exactly the way
`Pages.UsernameOrCustomTab_.EmbeddedPost` renders a regular custom tab's own `TargetPost` (same
`Components.Pages.PostPage`, same fetch, same edit/reply/delete/moderation UI).

`Feed` is a thin wrapper around `Components.Pages.EventsPage`/`Components.Pages.PostsPage`, which do
all the actual work -- mirrors `Pages.User.UserId_`/`Pages.UsernameOrCustomTab_.Posts`' own use of
`PostsPage` for the posts half, except this page adds its own "Recent Posts"/"Recent Replies"
heading (see `heading`, which tracks `PostsPage`'s own POST/REPLY context chooser), renders an
`EventsPage` above that (defaulted to `HorizontalList` mode -- via `EventsPage.init`'s own
`embeddedPage = True` argument, passed below -- rather than `EventsPage.init`'s ordinary
`VerticalList` default, so the home page's events read as a single row rather than competing with
the posts feed below for vertical space; `model.embeddedPage` also hides its List/Grid/Row mode
buttons entirely -- see `EventsPage.modeButtonsView`'s own doc for the full visibility rules,
including the "Show all event layouts" admin override), and passes `authorUserId = Nothing`/
`author = Nothing` to both (an unfiltered feed, rather than one user's own posts/events).

Both `PostsPage.init`/`EventsPage.init` are also passed `embeddedPage = True`
above, which keeps each from independently asserting its own
`Shared.Breadcrumbs` root on every `update` (see their own
`setBreadcrumbsRoot` docs) -- this page owns that instead, unlike the other
`PostsPage`/`EventsPage` callers, which each own their own page's root
directly. See `setBreadcrumbsHost` for why: two embedded copies each
asserting a root of their own turned out to fight a third, actually-different
root on `Components.Pages.UserProfilePage` (which embeds the same two
modules), a continuous flicker during animation. `HomeEvents`/`HomePosts`/`HomePost`
all instead leave breadcrumbs alone entirely: the former two pass
`embeddedPage = False` (own their own root the same as `Pages.Events`/`Pages.Posts`
do), and `PostPage.init`/`.update` (the latter) own their own breadcrumb root
already, the same as `Pages.Post.PostId_`/`Pages.UsernameOrCustomTab_.EmbeddedPost`
-- so `setBreadcrumbsHost` only ever fires for `Feed` (see `setBreadcrumbsEffect`).

There's only one visible search box in `Feed` (`EventsPage`'s -- `PostsPage.view`
is called with `showSearchRow = False`, hiding its own box and POST/REPLY
chooser entirely, since a second, independent search box for the same page
would be redundant/confusing). Typing in it still filters _both_ feeds: see
`updateInner`'s `PostsMsg`/`EventsMsg` branches, which relay a changed
`searchText` into the other page's model via
`PostsPage.searchTextChanged`/`EventsPage.searchTextChanged` -- each side
keeps its own independent debounce timer (see those modules' own
`SearchTextChanged`/`SearchDebounceElapsed`), so this doesn't add any new
debounce logic here, it just keeps both `model.posts.searchText`/
`model.events.searchText` in sync going forward. The `PostsMsg` half of that
relay is effectively unreachable with the box hidden, but is kept for
robustness/symmetry (e.g. a future `?search_text=` URL param divergence).

-}

import Components.Pages.EventsPage as EventsPage
import Components.Pages.PostPage as PostPage
import Components.Pages.PostsPage as PostsPage
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Html exposing (h3, text)
import Page
import Proto.Jonline.NavigationTab exposing (NavigationTab(..))
import Proto.Jonline.PostContext exposing (PostContext(..))
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.Breadcrumbs as Breadcrumbs
import UI
import UI.CustomNav as CustomNav
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req
        , update = update shared req
        , view = view shared req
        , subscriptions = subscriptions
        }


{-| `Feed` is the ordinary Events+Posts composite (see the module doc); `HomeEvents`/`HomePosts`/
`HomePost` are distinct variants (not, say, folded into `Feed` as a `Maybe`) for the same reason
`Pages.UsernameOrCustomTab_.EmbeddedProfile` is kept separate from its own `Profile` -- once
`updateInner`'s `SharedMsg` handling (below) has matched a `home` override and switched away from
`Feed`, it must stop re-deriving `homeTargetFor` on every subsequent `Shared.Msg`, or a still-live
`EventsPage`/`PostsPage`/`PostPage.Model` would be discarded and re-`init`ed (re-fetching) on every
single message.
-}
type Model
    = Feed FeedModel
    | HomeEvents EventsPage.Model
    | HomePosts PostsPage.Model
    | HomePost PostPage.Model


type alias FeedModel =
    { posts : PostsPage.Model
    , events : EventsPage.Model
    }


type Msg
    = PostsMsg PostsPage.Msg
    | EventsMsg EventsPage.Msg
    | HomeEventsMsg EventsPage.Msg
    | HomePostsMsg PostsPage.Msg
    | HomePostMsg PostPage.Msg
    | SharedMsg Shared.Msg


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    case initForTarget shared req (homeTargetFor shared) of
        Just result ->
            result

        Nothing ->
            initFeed shared req


initFeed : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
initFeed shared req =
    let
        ( postsModel, postsEffect ) =
            PostsPage.init shared Nothing req.key req.url.path req.query True

        ( eventsModel, eventsEffect ) =
            EventsPage.init shared Nothing req.key req.url.path req.query req.url.fragment True True Nothing
    in
    ( Feed { posts = postsModel, events = eventsModel }
    , Effect.batch [ Effect.map PostsMsg postsEffect, Effect.map EventsMsg eventsEffect, setBreadcrumbsHost shared, Effect.fromShared Shared.UncollapseHome ]
    )


{-| `target`'s own non-default init, if it has one -- `Nothing` for `TargetTab HOMETAB` (and any
other value `homeTargetFor` shouldn't ever actually produce, e.g. a stray `TargetProfile`), meaning
"fall back to `initFeed`." Factored out of `init` so `updateInner`'s `SharedMsg`/`Feed` branch (which
re-checks `homeTargetFor` on every incoming `Shared.Msg`, see `homeTargetFor`'s own doc) can reuse
the exact same three-way switch without duplicating it.
-}
initForTarget : Shared.Model -> Request.With Params -> CustomNav.CustomTabTarget -> Maybe ( Model, Effect Msg )
initForTarget shared req target =
    case target of
        CustomNav.TargetTab EVENTSTAB ->
            EventsPage.init shared Nothing req.key req.url.path req.query req.url.fragment False True Nothing
                |> Tuple.mapFirst HomeEvents
                |> Tuple.mapSecond (Effect.map HomeEventsMsg)
                |> Just

        CustomNav.TargetTab POSTSTAB ->
            PostsPage.init shared Nothing req.key req.url.path req.query False
                |> Tuple.mapFirst HomePosts
                |> Tuple.mapSecond (Effect.map HomePostsMsg)
                |> Just

        CustomNav.TargetPost postId ->
            PostPage.init shared (AccountsPanel.isSecure req) postId req.key
                |> Tuple.mapFirst HomePost
                |> Tuple.mapSecond (Effect.map HomePostMsg)
                |> Just

        _ ->
            Nothing


{-| `mainFrontendHost`'s own `customTabs.home` override, resolved via `UI.CustomNav.homeTarget` --
that function's own `Nothing`/unset-config fallback to `TargetTab HOMETAB` covers both "no override
configured" and "`mainFrontendHost`'s `ServerConfiguration` hasn't loaded yet" identically (see
`Pages.UsernameOrCustomTab_.customTabFor`'s identical reasoning for why that's the right fallback,
not an error), which is exactly why `init` alone isn't enough: `updateInner`'s `SharedMsg` handling
re-checks this on every incoming `Shared.Msg` while still in `Feed`, so a `home` override that
arrives moments after `init` (the common case for a first visit, before `mainFrontendHost`'s config
has finished connecting) still takes effect.
-}
homeTargetFor : Shared.Model -> CustomNav.CustomTabTarget
homeTargetFor shared =
    AccountsPanel.serverForHost shared.accounts.servers shared.accounts.mainFrontendHost
        |> Maybe.andThen (\server -> (AccountsPanel.configurationOf server).customTabs)
        |> CustomNav.homeTarget


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Feed feed ->
            Sub.batch
                [ Sub.map PostsMsg (PostsPage.subscriptions feed.posts)
                , Sub.map EventsMsg (EventsPage.subscriptions feed.events)
                ]

        HomeEvents subModel ->
            Sub.map HomeEventsMsg (EventsPage.subscriptions subModel)

        HomePosts subModel ->
            Sub.map HomePostsMsg (PostsPage.subscriptions subModel)

        HomePost subModel ->
            Sub.map HomePostMsg (PostPage.subscriptions subModel)


{-| `updateInner`, plus reissuing `setBreadcrumbsEffect` after every `update` --
mirrors `Components.Pages.UserProfilePage.update`'s identical wrapper.
-}
update : Shared.Model -> Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
update shared req msg model =
    let
        ( newModel, effect ) =
            updateInner shared req msg model
    in
    ( newModel, Effect.batch [ effect, setBreadcrumbsEffect shared newModel ] )


updateInner : Shared.Model -> Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
updateInner shared req msg model =
    case ( msg, model ) of
        ( PostsMsg subMsg, Feed feed ) ->
            let
                ( newPosts, postsEffect ) =
                    PostsPage.update shared subMsg feed.posts

                ( syncedEvents, syncEffect ) =
                    if newPosts.searchText /= feed.events.searchText then
                        EventsPage.update shared (EventsPage.searchTextChanged newPosts.searchText) feed.events

                    else
                        ( feed.events, Effect.none )
            in
            ( Feed { feed | posts = newPosts, events = syncedEvents }
            , Effect.batch [ Effect.map PostsMsg postsEffect, Effect.map EventsMsg syncEffect ]
            )

        ( EventsMsg subMsg, Feed feed ) ->
            let
                ( newEvents, eventsEffect ) =
                    EventsPage.update shared subMsg feed.events

                ( syncedPosts, syncEffect ) =
                    if newEvents.searchText /= feed.posts.searchText then
                        PostsPage.update shared (PostsPage.searchTextChanged newEvents.searchText) feed.posts

                    else
                        ( feed.posts, Effect.none )
            in
            ( Feed { feed | events = newEvents, posts = syncedPosts }
            , Effect.batch [ Effect.map EventsMsg eventsEffect, Effect.map PostsMsg syncEffect ]
            )

        ( HomeEventsMsg subMsg, HomeEvents subModel ) ->
            EventsPage.update shared subMsg subModel
                |> Tuple.mapFirst HomeEvents
                |> Tuple.mapSecond (Effect.map HomeEventsMsg)

        ( HomePostsMsg subMsg, HomePosts subModel ) ->
            PostsPage.update shared subMsg subModel
                |> Tuple.mapFirst HomePosts
                |> Tuple.mapSecond (Effect.map HomePostsMsg)

        ( HomePostMsg subMsg, HomePost subModel ) ->
            PostPage.update shared subMsg subModel
                |> Tuple.mapFirst HomePost
                |> Tuple.mapSecond (Effect.map HomePostMsg)

        -- Re-checked (via `homeTargetFor`) on every incoming `Shared.Msg` while still in `Feed` --
        -- covers `init` having run before `mainFrontendHost`'s own `ServerConfiguration.customTabs`
        -- was known yet (see `homeTargetFor`'s own doc). Once matched, this switches straight to
        -- the matching fresh variant (abandoning whatever `Feed` fetches were in flight, same as
        -- `Pages.UsernameOrCustomTab_`'s identical `Profile` handling) rather than forwarding
        -- `subMsg` into it.
        ( SharedMsg subMsg, Feed feed ) ->
            case initForTarget shared req (homeTargetFor shared) of
                Just result ->
                    result

                Nothing ->
                    let
                        ( newPosts, postsEffect ) =
                            PostsPage.update shared (PostsPage.fromShared subMsg) feed.posts

                        ( newEvents, eventsEffectRaw ) =
                            EventsPage.update shared (EventsPage.fromShared subMsg) feed.events

                        -- `PostsPage.update`/`EventsPage.update`'s own `SharedMsg`
                        -- branches each unconditionally re-emit `Effect.fromShared
                        -- subMsg` (see their own docs) -- that's what actually
                        -- applies an incoming `Shared.Msg` (e.g. toggling the
                        -- Accounts Panel or Starred panel, both built with
                        -- `Shared.Msg` in `UI.layout`'s header and only reaching
                        -- either page via `fromShared`) back to `Shared.update`,
                        -- correct when only one feed is handling it. Both would fire
                        -- it here, for the exact same `subMsg` -- `Effect.partitionShared`
                        -- (in `Main.elm`) would then apply it to `Shared.update`
                        -- *twice* in the same pass. Harmless for an idempotent
                        -- message, but for a toggle that flips it on then right back
                        -- off again -- net zero, every time, which is exactly the
                        -- "can't open the Accounts/Starred panel" bug this
                        -- fixes. `postsEffect` is kept as the one copy that actually
                        -- re-broadcasts `subMsg`; `eventsEffectRaw`'s own copy is
                        -- dropped via `Effect.partitionShared` (keeping its other
                        -- effects, e.g. `fetchNewServers`'s own fetch, intact).
                        ( _, eventsEffect ) =
                            Effect.partitionShared eventsEffectRaw
                    in
                    ( Feed { feed | posts = newPosts, events = newEvents }
                    , Effect.batch [ Effect.map PostsMsg postsEffect, Effect.map EventsMsg eventsEffect ]
                    )

        ( SharedMsg subMsg, HomeEvents subModel ) ->
            EventsPage.update shared (EventsPage.fromShared subMsg) subModel
                |> Tuple.mapFirst HomeEvents
                |> Tuple.mapSecond (Effect.map HomeEventsMsg)

        ( SharedMsg subMsg, HomePosts subModel ) ->
            PostsPage.update shared (PostsPage.fromShared subMsg) subModel
                |> Tuple.mapFirst HomePosts
                |> Tuple.mapSecond (Effect.map HomePostsMsg)

        ( SharedMsg subMsg, HomePost subModel ) ->
            PostPage.update shared (PostPage.fromShared subMsg) subModel
                |> Tuple.mapFirst HomePost
                |> Tuple.mapSecond (Effect.map HomePostMsg)

        _ ->
            ( model, Effect.none )


{-| Keeps `Shared.Breadcrumbs` pointed at `mainFrontendHost`, but only for `Feed` -- this feed isn't
scoped to any one server for a breadcrumb trail to identify the way a Post's own reply chain is.
The one owner of `Shared.Breadcrumbs` for `Feed`: the embedded `PostsPage`/`EventsPage` copies above
both leave breadcrumbs alone entirely (`model.embeddedPage`, see their own `setBreadcrumbsRoot`
docs) rather than each independently asserting a root of its own -- `Components.Pages.UserProfilePage`
embeds the same two modules the same way, and used to let each of them (plus its own
`setBreadcrumbsHost`) independently assert a root on every `update`, including every animation tick;
whichever root won only lasted until the next tick reasserted the other, a continuous flicker
between them. `HomeEvents`/`HomePosts`/`HomePost` are all left alone entirely -- the former two own
their own breadcrumb root the same as `Pages.Events`/`Pages.Posts` (`embeddedPage = False`), and
`PostPage.init`/`.update` (the latter) already own theirs, the same as
`Pages.Post.PostId_`/`Pages.UsernameOrCustomTab_.EmbeddedPost`.
-}
setBreadcrumbsEffect : Shared.Model -> Model -> Effect Msg
setBreadcrumbsEffect shared model =
    case model of
        Feed _ ->
            setBreadcrumbsHost shared

        HomeEvents _ ->
            Effect.none

        HomePosts _ ->
            Effect.none

        HomePost _ ->
            Effect.none


setBreadcrumbsHost : Shared.Model -> Effect Msg
setBreadcrumbsHost shared =
    let
        host : String
        host =
            shared.accounts.mainFrontendHost
    in
    if shared.breadcrumbs.root == Just (Breadcrumbs.FromServerHost host) then
        Effect.none

    else
        Effect.fromShared (Shared.BreadcrumbsMsg (Breadcrumbs.SetRoot (Breadcrumbs.FromServerHost host) host []))


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared (titleFor model)
    , body =
        UI.layout shared
            req.route
            fromShared
            (case model of
                Feed feed ->
                    [ Html.map EventsMsg (EventsPage.view shared True feed.events)
                    , h3 [] [ text (heading feed.posts.context) ]
                    , Html.map PostsMsg (PostsPage.view shared False True feed.posts)
                    ]

                HomeEvents subModel ->
                    [ Html.map HomeEventsMsg (EventsPage.view shared True subModel) ]

                HomePosts subModel ->
                    [ Html.map HomePostsMsg (PostsPage.view shared True True subModel) ]

                HomePost subModel ->
                    [ Html.map HomePostMsg (PostPage.view shared subModel) ]
            )
    }


{-| `Feed` has no title of its own (matching this page's pre-existing behavior); `HomeEvents` mirrors
`Pages.Events`' own (none -- its own "Upcoming Events"/"Events After <date>" tabs already say what
the listing is); `HomePosts` mirrors `Pages.Posts`' own ("Posts"); `HomePost` uses the featured
Post's own title, same as `Pages.Post.PostId_`/`Pages.UsernameOrCustomTab_.titleFor`'s `EmbeddedPost`
case.
-}
titleFor : Model -> List String
titleFor model =
    case model of
        Feed _ ->
            []

        HomeEvents _ ->
            []

        HomePosts _ ->
            [ "Posts" ]

        HomePost subModel ->
            [ PostPage.titleFor subModel ]


{-| "Recent Posts"/"Recent Replies", matching `model.context` -- always "Recent Posts" in
practice here, since `PostsPage.view`'s `showSearchRow = False` above hides the only control
(`PostsPage.searchRowView`'s POST/REPLY chooser) that could ever change `model.posts.context`
away from its `POST` default.
-}
heading : PostContext -> String
heading context =
    case context of
        REPLY ->
            "Recent Replies"

        _ ->
            "Recent Posts"


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page --
see `Components.Pages.PostsPage.fromShared`/`Components.Pages.EventsPage.fromShared`,
both of which `SharedMsg` forwards to above.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg
