module Pages.Home_ exposing (Model, Msg, fromShared, page)

{-| `/` -- upcoming events plus recent posts from every enabled server. Thin
wrapper around `Components.Pages.EventsPage`/`Components.Pages.PostsPage`,
which do all the actual work -- mirrors `Pages.User.UserId_`/
`Pages.Username_.Posts`' own use of `PostsPage` for the posts half, except
this page adds its own "Recent Posts"/"Recent Replies" heading (see
`heading`, which tracks `PostsPage`'s own POST/REPLY context chooser),
renders an `EventsPage` above that (defaulted to `HorizontalList` mode --
see `init`'s `defaultedEventsModel` -- rather than `EventsPage.init`'s own
`VerticalList` default, so the home page's events read as a single row
rather than competing with the posts feed below for vertical space, and
passed `homeEmbedded = True` in `view`, which hides its List/Grid/Row mode
buttons entirely -- see `EventsPage.modeButtonsView`'s own doc for the full
visibility rules, including the "Show all event layouts" admin override),
and passes `authorUserId = Nothing`/`author = Nothing` to both (an
unfiltered feed, rather than one user's own posts/events) -- plus, unlike
those other `PostsPage` callers, keeps `Shared.Breadcrumbs` pointed at
`mainFrontendHost` (see `setBreadcrumbsHost`), since this feed isn't scoped
to any one server for a breadcrumb trail to identify the way a Post's own
reply chain is.

There's only one visible search box here -- `EventsPage`'s (`PostsPage.view`
is called with `showSearchRow = False`, hiding its own box and POST/REPLY
chooser entirely, since a second, independent search box for the same page
would be redundant/confusing). Typing in it still filters *both* feeds: see
`update`'s `PostsMsg`/`EventsMsg` branches, which relay a changed
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
import Components.Pages.PostsPage as PostsPage
import Dict
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Html exposing (h2, text)
import Page
import Proto.Jonline.PostContext exposing (PostContext(..))
import Request
import Shared
import Shared.Breadcrumbs as Breadcrumbs
import UI
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req
        , update = update shared
        , view = view shared req
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { posts : PostsPage.Model
    , events : EventsPage.Model
    }


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        ( postsModel, postsEffect ) =
            PostsPage.init shared Nothing req.key req.url.path req.query

        ( eventsModel, eventsEffect ) =
            EventsPage.init shared Nothing req.key req.url.path req.query

        -- `EventsPage.init` itself defaults `mode` to `VerticalList` (see its
        -- own doc) absent a `?display=` query param -- overridden to
        -- `HorizontalList` here (and only here) so an explicit `?display=`
        -- (e.g. a shared/bookmarked link) still wins.
        defaultedEventsModel =
            if Dict.member "display" req.query then
                eventsModel

            else
                { eventsModel | mode = EventsPage.HorizontalList }
    in
    ( { posts = postsModel, events = defaultedEventsModel }
    , Effect.batch [ Effect.map PostsMsg postsEffect, Effect.map EventsMsg eventsEffect ]
    )



-- UPDATE


type Msg
    = PostsMsg PostsPage.Msg
    | EventsMsg EventsPage.Msg
    | SharedMsg Shared.Msg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        PostsMsg subMsg ->
            let
                ( newPosts, postsEffect ) =
                    PostsPage.update shared subMsg model.posts

                ( syncedEvents, syncEffect ) =
                    if newPosts.searchText /= model.events.searchText then
                        EventsPage.update shared (EventsPage.searchTextChanged newPosts.searchText) model.events

                    else
                        ( model.events, Effect.none )
            in
            ( { model | posts = newPosts, events = syncedEvents }
            , Effect.batch [ Effect.map PostsMsg postsEffect, Effect.map EventsMsg syncEffect ]
            )

        EventsMsg subMsg ->
            let
                ( newEvents, eventsEffect ) =
                    EventsPage.update shared subMsg model.events

                ( syncedPosts, syncEffect ) =
                    if newEvents.searchText /= model.posts.searchText then
                        PostsPage.update shared (PostsPage.searchTextChanged newEvents.searchText) model.posts

                    else
                        ( model.posts, Effect.none )
            in
            ( { model | events = newEvents, posts = syncedPosts }
            , Effect.batch [ Effect.map EventsMsg eventsEffect, Effect.map PostsMsg syncEffect ]
            )

        SharedMsg subMsg ->
            let
                ( newPosts, postsEffect ) =
                    PostsPage.update shared (PostsPage.fromShared subMsg) model.posts

                ( newEvents, eventsEffectRaw ) =
                    EventsPage.update shared (EventsPage.fromShared subMsg) model.events

                -- `PostsPage.update`/`EventsPage.update`'s own `SharedMsg`
                -- branches each unconditionally re-emit `Effect.fromShared
                -- subMsg` (see their own docs) -- that's what actually
                -- applies an incoming `Shared.Msg` (e.g. toggling the
                -- Accounts Panel or Starred Posts panel, both built with
                -- `Shared.Msg` in `UI.layout`'s header and only reaching
                -- either page via `fromShared`) back to `Shared.update`,
                -- correct when only one feed is handling it. Both would fire
                -- it here, for the exact same `subMsg` -- `Effect.partitionShared`
                -- (in `Main.elm`) would then apply it to `Shared.update`
                -- *twice* in the same pass. Harmless for an idempotent
                -- message, but for a toggle that flips it on then right back
                -- off again -- net zero, every time, which is exactly the
                -- "can't open the Accounts/Starred Posts panel" bug this
                -- fixes. `postsEffect` is kept as the one copy that actually
                -- re-broadcasts `subMsg`; `eventsEffectRaw`'s own copy is
                -- dropped via `Effect.partitionShared` (keeping its other
                -- effects, e.g. `fetchNewServers`'s own fetch, intact).
                ( _, eventsEffect ) =
                    Effect.partitionShared eventsEffectRaw
            in
            ( { model | posts = newPosts, events = newEvents }
            , Effect.batch [ Effect.map PostsMsg postsEffect, Effect.map EventsMsg eventsEffect ]
            )


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page --
see `Components.Pages.PostsPage.fromShared`/`Components.Pages.EventsPage.fromShared`,
both of which `SharedMsg` forwards to above.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map PostsMsg (PostsPage.subscriptions model.posts)
        , Sub.map EventsMsg (EventsPage.subscriptions model.events)
        ]



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared []
    , body =
        UI.layout shared
            req.route
            fromShared
            [ Html.map EventsMsg (EventsPage.view shared True model.events)
            , h2 [] [ text (heading model.posts.context) ]
            , Html.map PostsMsg (PostsPage.view shared False model.posts)
            ]
    }


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
