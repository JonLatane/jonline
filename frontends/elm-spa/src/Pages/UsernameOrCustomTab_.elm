module Pages.UsernameOrCustomTab_ exposing (Model, Msg, fromShared, page)

{-| `/:usernameOrCustomTab[@host]` -- either a user profile looked up by (impermanent) username, on
`mainFrontendHost` or (with an `@host` suffix) some other federated server, *or*, first, a check
against `mainFrontendHost`'s own `ServerConfiguration.customTabs.tabs` (see `UI.CustomNav`) for a
tab whose own `path` matches this segment -- letting an admin mount `Events`/`Posts`/`People`/`About`/
a specific `Post` at a custom URL (e.g. a band's `/weddings` pointing at a Post about their wedding
offerings), per `CustomNavigationTabWithPath`'s own doc. That check runs first (`customTabFor`),
before the username fallback below, so a configured custom path always wins over a same-named user.

The top-level catch-all this implies means any username (or un-embeddable custom path) colliding
with this app's own routes (or the `/user`/`/post` prefixes) can never be reached this way -- see
`Components.Users.isReservedUsername`, checked here before `Components.UserProfilePage` (which does
the actual fetching/rendering, same as `Pages.User.UserId_`) is ever involved. Those usernames are
still reachable via `/user/:id[@host]`. Note `/events`/`/posts/`/`/people`/`/about` themselves are
never actually reachable *as* a custom path either way -- `Gen.Route.routes`' own `Parser.oneOf`
tries those literal static routes first, so this file's `init` never even runs for them.
-}

import Browser.Navigation
import Components.Pages.EventsPage as EventsPage
import Components.Pages.PostPage as PostPage
import Components.Pages.PostsPage as PostsPage
import Components.Pages.ServerInformationPage as ServerInformationPage
import Components.Pages.UserProfilePage as UserProfilePage
import Components.Pages.UsersPage as UsersPage
import Components.Users as Users
import Components.Users.Resolver as Resolver
import Effect exposing (Effect)
import Gen.Params.UsernameOrCustomTab_ exposing (Params)
import Gen.Route as Route exposing (Route)
import Html exposing (p, text)
import Html.Attributes exposing (class)
import Page
import Proto.Jonline.NavigationTab exposing (NavigationTab(..))
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
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


{-| `Reserved` short-circuits straight to a "not a user" message, without ever constructing a
`UserProfilePage.Model` (and thus without ever attempting a fetch) -- see the module doc.
`Embedded*` mount whichever `Components.Pages.*` a matched custom tab's `target` calls for, exactly
the same components `Pages.Events`/`Pages.Posts`/`Pages.People`/`Pages.About`/`Pages.Post.PostId_`
themselves wrap -- see `initEmbedded`, and that module's own doc for why a `Post` target is
genuinely indistinguishable from visiting `/post/:id` directly (down to the same `Components.Pages.PostPage`
being mounted either way). `Redirecting` covers `HOMETAB` alone (not normally reachable from the
admin editor -- see `UI.CustomNav.selectableTargetKinds`' own doc -- but not excluded at the type
level either): unlike the other five, `Pages.Home_`'s Events+Posts composite isn't factored into a
separately-reusable `Components.Pages.*` module (it's a deliberately-duplicated composite, per its
own doc), so redirecting to `/` gets a visitor to the right content without duplicating it wholesale
just for this. `Redirecting` renders nothing itself, since its own `Effect` fires a real navigation
in `init` that replaces this page before `view` would otherwise matter.
-}
type Model
    = Reserved String
    | Profile UserProfilePage.Model
    | EmbeddedEvents EventsPage.Model
    | EmbeddedPosts PostsPage.Model
    | EmbeddedPeople UsersPage.Model
    | EmbeddedAbout ServerInformationPage.Model
    | EmbeddedPost PostPage.Model
    | Redirecting


{-| `SharedMsg` (rather than always wrapping a forwarded `Shared.Msg` as, say, `ProfileMsg`) exists
because `fromShared` (below) has no way to know which `Embedded*`/`Profile` variant is actually
active when it's called -- `elm-spa`'s own `fromShared : Shared.Msg -> Msg` signature is model-blind
by design. Routing on the *current* `model` instead happens in `update`'s own `SharedMsg` branches,
each re-dispatching via that embedded module's own `fromShared`, mirroring `Pages.Home_.update`'s
identical reasoning for forwarding one incoming `Shared.Msg` to more than one possible destination.
-}
type Msg
    = ProfileMsg UserProfilePage.Msg
    | EventsMsg EventsPage.Msg
    | PostsMsg PostsPage.Msg
    | PeopleMsg UsersPage.Msg
    | AboutMsg ServerInformationPage.Msg
    | EmbeddedPostMsg PostPage.Msg
    | SharedMsg Shared.Msg


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    case customTabFor shared req.params.usernameOrCustomTab of
        Just tab ->
            initEmbedded shared req tab

        Nothing ->
            initProfile shared req


{-| `mainFrontendHost`'s own `CustomNavigationTabSet.tabs` entry (if any, and if that server's
`ServerConfiguration` is even known yet) whose `path` matches `path` exactly -- deliberately built
off `CustomNav.effectiveTabs (Just customTabs)`, not `AccountsPanel.configurationOf server |> .customTabs
|> CustomNav.effectiveTabs` directly, so an *unset* `customTabs` (the common case) never falls back to
`CustomNav.defaultTabs`' own paths here -- those are harmless if matched (see the module doc on why
they're unreachable anyway), but "no config" should mean "no custom routing," not "pretend the
defaults were explicitly configured."
-}
customTabFor : Shared.Model -> String -> Maybe CustomNav.CustomTab
customTabFor shared path =
    AccountsPanel.serverForHost shared.accounts.servers shared.accounts.mainFrontendHost
        |> Maybe.andThen (\server -> (AccountsPanel.configurationOf server).customTabs)
        |> Maybe.andThen (\customTabs -> CustomNav.effectiveTabs (Just customTabs) |> List.filter (\tab -> tab.path == path) |> List.head)


{-| Mounts whichever page a matched custom tab's `target` calls for. `EVENTSTAB`/`POSTSTAB`/`PEOPLETAB`/
`ABOUTTAB` embed inline (each call mirrors `Pages.Events`/`Pages.Posts`/`Pages.People`/`Pages.About`'s
own `init` exactly, just wrapped in this module's `Embedded*` instead of their own bare `Model`), so
the custom path itself stays in the address bar with that page's content rendered at it -- the actual
point of a vanity URL. `TargetPost` mounts `Components.Pages.PostPage` exactly the same way
`Pages.Post.PostId_` itself does, so e.g. a band's `/weddings` renders indistinguishably from
`/post/:id` for the Post it's configured to point at -- same fetch, same edit/reply/delete/moderation
UI, same everything, just a friendlier url. `HOMETAB` instead redirects to `/` (see `Model`'s own
doc on why that one's not embedded the same way). A malformed/future `NavigationTabUnrecognized_`
target falls back to the ordinary username lookup, same as if this path hadn't matched a tab at all.
-}
initEmbedded : Shared.Model -> Request.With Params -> CustomNav.CustomTab -> ( Model, Effect Msg )
initEmbedded shared req tab =
    case tab.target of
        CustomNav.TargetTab EVENTSTAB ->
            EventsPage.init shared Nothing req.key req.url.path req.query False True Nothing
                |> Tuple.mapFirst EmbeddedEvents
                |> Tuple.mapSecond (Effect.map EventsMsg)

        CustomNav.TargetTab POSTSTAB ->
            PostsPage.init shared Nothing req.key req.url.path req.query False
                |> Tuple.mapFirst EmbeddedPosts
                |> Tuple.mapSecond (Effect.map PostsMsg)

        CustomNav.TargetTab PEOPLETAB ->
            UsersPage.init shared Nothing req.key req.url.path req.query
                |> Tuple.mapFirst EmbeddedPeople
                |> Tuple.mapSecond (Effect.map PeopleMsg)

        CustomNav.TargetTab ABOUTTAB ->
            ServerInformationPage.init shared (AccountsPanel.isSecure req) shared.accounts.mainFrontendHost req.key req.url.path req.query
                |> Tuple.mapFirst EmbeddedAbout
                |> Tuple.mapSecond (Effect.map AboutMsg)

        CustomNav.TargetTab HOMETAB ->
            ( Redirecting, redirectTo req.key Route.Home_ )

        CustomNav.TargetTab (NavigationTabUnrecognized_ _) ->
            initProfile shared req

        CustomNav.TargetPost postId ->
            PostPage.init shared (AccountsPanel.isSecure req) postId req.key
                |> Tuple.mapFirst EmbeddedPost
                |> Tuple.mapSecond (Effect.map EmbeddedPostMsg)


{-| `replaceUrl`, not `pushUrl` -- a vanity path like `/gigs` should read as if `/events` were the
url all along, so the back button (from wherever the redirect lands) skips over it rather than
bouncing back into another redirect.
-}
redirectTo : Browser.Navigation.Key -> Route -> Effect Msg
redirectTo key route =
    Browser.Navigation.replaceUrl key (Route.toHref route) |> Effect.fromCmd


initProfile : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
initProfile shared req =
    let
        ( username, targetHost ) =
            Users.parseUserRouteId shared.accounts.mainFrontendHost req.params.usernameOrCustomTab
    in
    if Users.isReservedUsername username then
        ( Reserved username
        , Effect.none
        )

    else
        UserProfilePage.init shared (AccountsPanel.isSecure req) targetHost (Resolver.ByUsername username) req.key req.url.path req.query
            |> Tuple.mapFirst Profile
            |> Tuple.mapSecond (Effect.map ProfileMsg)


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Profile subModel ->
            Sub.map ProfileMsg (UserProfilePage.subscriptions subModel)

        EmbeddedEvents subModel ->
            Sub.map EventsMsg (EventsPage.subscriptions subModel)

        EmbeddedPosts subModel ->
            Sub.map PostsMsg (PostsPage.subscriptions subModel)

        EmbeddedPeople subModel ->
            Sub.map PeopleMsg (UsersPage.subscriptions subModel)

        EmbeddedAbout subModel ->
            Sub.map AboutMsg (ServerInformationPage.subscriptions subModel)

        EmbeddedPost subModel ->
            Sub.map EmbeddedPostMsg (PostPage.subscriptions subModel)

        Reserved _ ->
            Sub.none

        Redirecting ->
            Sub.none


update : Shared.Model -> Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
update shared req msg model =
    case ( msg, model ) of
        ( ProfileMsg subMsg, Profile subModel ) ->
            UserProfilePage.update shared subMsg subModel
                |> Tuple.mapFirst Profile
                |> Tuple.mapSecond (Effect.map ProfileMsg)

        ( EventsMsg subMsg, EmbeddedEvents subModel ) ->
            EventsPage.update shared subMsg subModel
                |> Tuple.mapFirst EmbeddedEvents
                |> Tuple.mapSecond (Effect.map EventsMsg)

        ( PostsMsg subMsg, EmbeddedPosts subModel ) ->
            PostsPage.update shared subMsg subModel
                |> Tuple.mapFirst EmbeddedPosts
                |> Tuple.mapSecond (Effect.map PostsMsg)

        ( PeopleMsg subMsg, EmbeddedPeople subModel ) ->
            UsersPage.update shared subMsg subModel
                |> Tuple.mapFirst EmbeddedPeople
                |> Tuple.mapSecond (Effect.map PeopleMsg)

        ( AboutMsg subMsg, EmbeddedAbout subModel ) ->
            ServerInformationPage.update shared subMsg subModel
                |> Tuple.mapFirst EmbeddedAbout
                |> Tuple.mapSecond (Effect.map AboutMsg)

        ( EmbeddedPostMsg subMsg, EmbeddedPost subModel ) ->
            PostPage.update shared subMsg subModel
                |> Tuple.mapFirst EmbeddedPost
                |> Tuple.mapSecond (Effect.map EmbeddedPostMsg)

        -- `Reserved`/`Profile` are re-examined (via `customTabFor`) on every incoming
        -- `Shared.Msg` first -- covers `init` having run before `mainFrontendHost`'s own
        -- `ServerConfiguration.customTabs` was known yet (the common case on a fresh
        -- load/reload of a custom-tab path: that server hasn't finished connecting when this
        -- page's `init` first runs, so `customTabFor` sees no config and falls through to
        -- `initProfile`, same as an actual unknown user would). Once a match is found this way,
        -- it wins outright -- whatever `Profile` fetch was in flight is simply abandoned.
        ( SharedMsg _, Reserved username ) ->
            case customTabFor shared req.params.usernameOrCustomTab of
                Just tab ->
                    initEmbedded shared req tab

                Nothing ->
                    ( Reserved username, Effect.none )

        -- See `Msg`'s own doc -- routes one incoming `Shared.Msg` to whichever
        -- embedded module is actually live right now, re-entering through that
        -- module's own `fromShared` (same as if `Main` had called it directly).
        ( SharedMsg subMsg, Profile subModel ) ->
            case customTabFor shared req.params.usernameOrCustomTab of
                Just tab ->
                    initEmbedded shared req tab

                Nothing ->
                    UserProfilePage.update shared (UserProfilePage.fromShared subMsg) subModel
                        |> Tuple.mapFirst Profile
                        |> Tuple.mapSecond (Effect.map ProfileMsg)

        ( SharedMsg subMsg, EmbeddedEvents subModel ) ->
            EventsPage.update shared (EventsPage.fromShared subMsg) subModel
                |> Tuple.mapFirst EmbeddedEvents
                |> Tuple.mapSecond (Effect.map EventsMsg)

        ( SharedMsg subMsg, EmbeddedPosts subModel ) ->
            PostsPage.update shared (PostsPage.fromShared subMsg) subModel
                |> Tuple.mapFirst EmbeddedPosts
                |> Tuple.mapSecond (Effect.map PostsMsg)

        ( SharedMsg subMsg, EmbeddedPeople subModel ) ->
            UsersPage.update shared (UsersPage.fromShared subMsg) subModel
                |> Tuple.mapFirst EmbeddedPeople
                |> Tuple.mapSecond (Effect.map PeopleMsg)

        ( SharedMsg subMsg, EmbeddedAbout subModel ) ->
            ServerInformationPage.update shared (ServerInformationPage.fromShared subMsg) subModel
                |> Tuple.mapFirst EmbeddedAbout
                |> Tuple.mapSecond (Effect.map AboutMsg)

        ( SharedMsg subMsg, EmbeddedPost subModel ) ->
            PostPage.update shared (PostPage.fromShared subMsg) subModel
                |> Tuple.mapFirst EmbeddedPost
                |> Tuple.mapSecond (Effect.map EmbeddedPostMsg)

        _ ->
            ( model, Effect.none )


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared (titleFor model)
    , body =
        UI.layout shared
            req.route
            fromShared
            [ case model of
                Profile subModel ->
                    Html.map ProfileMsg (UserProfilePage.view shared subModel)

                EmbeddedEvents subModel ->
                    Html.map EventsMsg (EventsPage.view shared True subModel)

                EmbeddedPosts subModel ->
                    Html.map PostsMsg (PostsPage.view shared True True subModel)

                EmbeddedPeople subModel ->
                    Html.map PeopleMsg (UsersPage.view shared subModel)

                EmbeddedAbout subModel ->
                    Html.map AboutMsg (ServerInformationPage.view shared subModel)

                EmbeddedPost subModel ->
                    Html.map EmbeddedPostMsg (PostPage.view shared subModel)

                Reserved username ->
                    p [ class "profile-error" ] [ text ("\"" ++ username ++ "\" isn't a user.") ]

                Redirecting ->
                    text ""
            ]
    }


titleFor : Model -> List String
titleFor model =
    case model of
        Profile subModel ->
            [ UserProfilePage.titleFor subModel ]

        EmbeddedEvents _ ->
            []

        EmbeddedPosts _ ->
            [ "Posts" ]

        EmbeddedPeople _ ->
            [ "People" ]

        EmbeddedAbout _ ->
            [ "About" ]

        EmbeddedPost subModel ->
            [ PostPage.titleFor subModel ]

        Reserved _ ->
            [ "Not Found" ]

        Redirecting ->
            []


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page -- see `Msg`'s own doc
on why this always wraps as `SharedMsg` rather than picking one embedded module's wrapper up front.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg
