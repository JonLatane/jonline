module Pages.Home_ exposing (Model, Msg, fromShared, page)

{-| `/` -- upcoming events plus recent posts from every enabled server. Thin
wrapper around `Components.Pages.EventsPage`/`Components.Pages.PostsPage`,
which do all the actual work -- mirrors `Pages.User.UserId_`/
`Pages.Username_.Posts`' own use of `PostsPage` for the posts half, except
this page adds its own "Recent Posts"/"Recent Replies" heading (see
`heading`, which tracks `PostsPage`'s own POST/REPLY context chooser),
renders an `EventsPage` above that (defaulted to `HorizontalList` mode --
via `EventsPage.init`'s own `embeddedPage = True` argument, passed below --
rather than `EventsPage.init`'s ordinary `VerticalList` default, so the
home page's events read as a single row rather than competing with the
posts feed below for vertical space; `model.embeddedPage` also hides its
List/Grid/Row mode buttons entirely -- see `EventsPage.modeButtonsView`'s own
doc for the full visibility rules, including the "Show all event layouts"
admin override), and passes `authorUserId = Nothing`/`author = Nothing` to
both (an unfiltered feed, rather than one user's own posts/events).

Both `PostsPage.init`/`EventsPage.init` are also passed `embeddedPage = True`
above, which keeps each from independently asserting its own
`Shared.Breadcrumbs` root on every `update` (see their own
`setBreadcrumbsRoot` docs) -- this page owns that instead, unlike the other
`PostsPage`/`EventsPage` callers, which each own their own page's root
directly. See `setBreadcrumbsHost` for why: two embedded copies each
asserting a root of their own turned out to fight a third, actually-different
root on `Components.Pages.UserProfilePage` (which embeds the same two
modules), a continuous flicker during animation.

There's only one visible search box here -- `EventsPage`'s (`PostsPage.view`
is called with `showSearchRow = False`, hiding its own box and POST/REPLY
chooser entirely, since a second, independent search box for the same page
would be redundant/confusing). Typing in it still filters _both_ feeds: see
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
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Html exposing (h3, text)
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
            PostsPage.init shared Nothing req.key req.url.path req.query True

        ( eventsModel, eventsEffect ) =
            EventsPage.init shared Nothing req.key req.url.path req.query True
    in
    ( { posts = postsModel, events = eventsModel }
    , Effect.batch [ Effect.map PostsMsg postsEffect, Effect.map EventsMsg eventsEffect, setBreadcrumbsHost shared ]
    )


{-| Keeps `Shared.Breadcrumbs` pointed at `mainFrontendHost` -- this feed
isn't scoped to any one server for a breadcrumb trail to identify the way a
Post's own reply chain is. The one owner of `Shared.Breadcrumbs` for this
page: the embedded `PostsPage`/`EventsPage` copies above both leave
breadcrumbs alone entirely (`model.embeddedPage`, see their own
`setBreadcrumbsRoot` docs) rather than each independently asserting a root of
its own -- `Components.Pages.UserProfilePage` embeds the same two modules the
same way, and used to let each of them (plus its own `setBreadcrumbsHost`)
independently assert a root on every `update`, including every animation
tick; whichever root won only lasted until the next tick reasserted the
other, a continuous flicker between them. Mirrors
`Components.Pages.UserProfilePage.setBreadcrumbsHost` exactly, reissued after
every `update`, a no-op once already in sync via the same equality check.
-}
setBreadcrumbsHost : Shared.Model -> Effect Msg
setBreadcrumbsHost shared =
    let
        host =
            shared.accounts.mainFrontendHost
    in
    if shared.breadcrumbs.root == Just (Breadcrumbs.FromServerHost host) then
        Effect.none

    else
        Effect.fromShared (Shared.BreadcrumbsMsg (Breadcrumbs.SetRoot (Breadcrumbs.FromServerHost host) host []))



-- UPDATE


type Msg
    = PostsMsg PostsPage.Msg
    | EventsMsg EventsPage.Msg
    | SharedMsg Shared.Msg


{-| `updateInner`, plus reissuing `setBreadcrumbsHost` after every `update` --
mirrors `Components.Pages.UserProfilePage.update`'s identical wrapper.
-}
update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    let
        ( newModel, effect ) =
            updateInner shared msg model
    in
    ( newModel, Effect.batch [ effect, setBreadcrumbsHost shared ] )


updateInner : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
updateInner shared msg model =
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
            , h3 [] [ text (heading model.posts.context) ]
            , Html.map PostsMsg (PostsPage.view shared False True model.posts)
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
