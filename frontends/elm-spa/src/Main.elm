module Main exposing (main)

{-| Customized from `elm-spa`'s generated default (see `.elm-spa/defaults/Main.elm`,
which this was copied from and now overrides -- `.elm-spa/` itself is
gitignored/regenerated, so this is the only place changes here persist).

Four changes from the default:

1. This app can be served from `/` or from `/elm` (see
`backend/src/web/elm_web.rs`), so every `Url` gotten from the browser is
normalized (`Shared.normalizeUrl`) before it's handed to
`Gen.Route.fromUrl`/`Request.create`/`Pages.init`, stripping that mount's
`basePath` so routing always sees an app-relative path. `basePath` itself is
detected once, from the very first `Url` (immutable for the session, same as
`Shared.AccountsPanel`'s `browsingHost`), and threaded into `Shared.init` so
view code (`UI.navLink`) can prepend it back onto outgoing hrefs.

2. `Page pageMsg` applies any `Shared.Msg`s a page's `update` forwarded (via
`Effect.fromShared`) to `Shared.update` immediately, in this same call --
see `Effect.partitionShared`. The default routes them through `Effect.toCmd`
instead, which defers them to a `Task.perform` on a later `update`/`view`
cycle; that's invisible for most effects, but the Accounts Panel's login form
lives in `Shared.Model` (it's shown from every page's header, via
`UI.layout`), so every keystroke is a `Shared.Msg` forwarded this way. The
deferred version meant `view` ran once per keystroke with the stale
pre-keystroke model -- snapping a mid-edit cursor to the end of the old text
-- and then again with the correct model, snapping it again.

3. `Shared sharedMsg` (a top-level `Shared.Msg`, e.g. `GotReconnectResult`
firing from a `Cmd` kicked off in `Shared.init`) additionally forwards that
same message into the currently active page via `notifyPageOfSharedMsg`, for
pages that expose a `fromShared` hook (see `Pages.Home_`, `Pages.Post.PostId_`).
The default only ever routes messages page -> shared (via `Page pageMsg`,
change 2 above); without this, a page has no way to notice state that changes
outside of its own `update` -- e.g. a persisted server finishing its
reconnect at startup -- short of polling for it.

4. `ChangedUrl` fires `Shared.ShowScrollPreserver` (see `UI.scrollPreserver`)
when, and only when, the navigation was the browser's own back button rather
than an in-app link click, redirect, or typed/bookmarked url -- those always
land on a fresh page starting at scroll top, but stepping back restores the
browser's remembered scroll offset against a page whose content may still be
loading (and so shorter than it was when that offset was recorded), which
would otherwise visibly yank the scroll position while it fills back in. Elm
has no built-in way to ask "was this `ChangedUrl` a back-button nav", so
`Model.backStack` shadows the browser's own back-stack by hand: every
`ClickedLink (Browser.Internal url)` pushes the url being left onto it, and
`ChangedUrl` treats landing back on its top entry as a back-nav (popping it),
leaving any other url change untouched.
-}

import Browser
import Browser.Navigation as Nav exposing (Key)
import Effect exposing (Effect)
import Gen.Model
import Gen.Msg
import Gen.Pages as Pages
import Gen.Route as Route
import Pages.Home_
import Pages.Post.PostId_
import Pages.User.UserId_
import Pages.Username_
import Request
import Shared
import Url exposing (Url)
import View



main : Program Shared.Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        }



-- INIT


type alias Model =
    { url : Url
    , key : Key
    , shared : Shared.Model
    , page : Pages.Model

    -- Detected once from the raw URL `init` was given -- see the module doc.
    , basePath : String

    -- Urls navigated away from via an in-app link click, most-recently-left
    -- first -- see change 4 in the module doc.
    , backStack : List Url
    }


init : Shared.Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        basePath =
            Shared.basePathFromPath url.path

        normalizedUrl =
            Shared.normalizeUrl basePath url

        ( shared, sharedCmd ) =
            Shared.init basePath (Request.create () normalizedUrl key) flags

        ( page, effect ) =
            Pages.init (Route.fromUrl normalizedUrl) shared normalizedUrl key
    in
    ( Model normalizedUrl key shared page basePath []
    , Cmd.batch
        [ Cmd.map Shared sharedCmd
        , Effect.toCmd ( Shared, Page ) effect
        ]
    )



-- UPDATE


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | Shared Shared.Msg
    | Page Pages.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink (Browser.Internal url) ->
            ( { model | backStack = model.url :: model.backStack }
            , Nav.pushUrl model.key (Url.toString url)
            )

        ClickedLink (Browser.External url) ->
            ( model
            , Nav.load url
            )

        ChangedUrl rawUrl ->
            let
                url =
                    Shared.normalizeUrl model.basePath rawUrl
            in
            if url.path /= model.url.path then
                let
                    ( page, effect ) =
                        Pages.init (Route.fromUrl url) model.shared url model.key

                    isBackNav =
                        List.head model.backStack == Just url

                    backStack =
                        if isBackNav then
                            List.drop 1 model.backStack

                        else
                            model.backStack

                    ( shared, sharedCmd ) =
                        if isBackNav then
                            Shared.update (Request.create () url model.key) Shared.ShowScrollPreserver model.shared

                        else
                            ( model.shared, Cmd.none )
                in
                ( { model | url = url, page = page, shared = shared, backStack = backStack }
                , Cmd.batch
                    [ Effect.toCmd ( Shared, Page ) effect
                    , Cmd.map Shared sharedCmd
                    ]
                )

            else
                ( { model | url = url }, Cmd.none )

        Shared sharedMsg ->
            let
                ( shared, sharedCmd ) =
                    Shared.update (Request.create () model.url model.key) sharedMsg model.shared

                ( redirectPage, redirectEffect ) =
                    Pages.init (Route.fromUrl model.url) shared model.url model.key
            in
            if redirectPage == Gen.Model.Redirecting_ then
                ( { model | shared = shared, page = redirectPage }
                , Cmd.batch
                    [ Cmd.map Shared sharedCmd
                    , Effect.toCmd ( Shared, Page ) redirectEffect
                    ]
                )

            else
                let
                    ( page, notifyCmd ) =
                        notifyPageOfSharedMsg sharedMsg shared model.page model.url model.key
                in
                ( { model | shared = shared, page = page }
                , Cmd.batch [ Cmd.map Shared sharedCmd, notifyCmd ]
                )

        Page pageMsg ->
            let
                ( page, effect ) =
                    Pages.update pageMsg model.page model.shared model.url model.key

                ( sharedMsgs, remainingEffect ) =
                    Effect.partitionShared effect

                ( shared, sharedCmd ) =
                    List.foldl applySharedMsg ( model.shared, Cmd.none ) sharedMsgs

                applySharedMsg sharedMsg ( accShared, accCmd ) =
                    let
                        ( newShared, cmd ) =
                            Shared.update (Request.create () model.url model.key) sharedMsg accShared
                    in
                    ( newShared, Cmd.batch [ accCmd, Cmd.map Shared cmd ] )

                -- The page itself was just updated against `model.shared` -- the state as it
                -- stood *before* the `sharedMsgs` it forwarded were applied above, so any
                -- `fromShared` handler that reads shared state (e.g. `Pages.Home_`'s
                -- `fetchNewServers`, keying off `AccountsPanel.enabledServers`) sees last
                -- message's state, not this one's. Re-notify the page with the now-updated
                -- `shared`, exactly as `notifyPageOfSharedMsg` already does for Shared.Msgs
                -- that originate outside any page -- see its doc for why re-emitted
                -- Shared.Msgs from this second pass are safe to drop.
                ( notifiedPage, notifyCmd ) =
                    List.foldl
                        (\sharedMsg ( accPage, accCmd ) ->
                            let
                                ( newPage, cmd ) =
                                    notifyPageOfSharedMsg sharedMsg shared accPage model.url model.key
                            in
                            ( newPage, Cmd.batch [ accCmd, cmd ] )
                        )
                        ( page, Cmd.none )
                        sharedMsgs
            in
            ( { model | page = notifiedPage, shared = shared }
            , Cmd.batch [ sharedCmd, notifyCmd, Effect.toCmd ( Shared, Page ) remainingEffect ]
            )


{-| The `Gen.Msg.Msg` that delivers `sharedMsg` to `page` via its `fromShared`
hook, for whichever page is currently active. `Nothing` for pages with no
such hook (e.g. `About`, `NotFound`) -- see `Pages.Home_.fromShared`,
`Pages.Post.PostId_.fromShared`.
-}
sharedMsgForPage : Shared.Msg -> Gen.Model.Model -> Maybe Gen.Msg.Msg
sharedMsgForPage sharedMsg page =
    case page of
        Gen.Model.Home_ _ _ ->
            Just (Gen.Msg.Home_ (Pages.Home_.fromShared sharedMsg))

        Gen.Model.Post__PostId_ _ _ ->
            Just (Gen.Msg.Post__PostId_ (Pages.Post.PostId_.fromShared sharedMsg))

        Gen.Model.User__UserId_ _ _ ->
            Just (Gen.Msg.User__UserId_ (Pages.User.UserId_.fromShared sharedMsg))

        Gen.Model.Username_ _ _ ->
            Just (Gen.Msg.Username_ (Pages.Username_.fromShared sharedMsg))

        _ ->
            Nothing


{-| Forwards a `Shared.Msg` that originated outside any page's `update` --
e.g. `GotReconnectResult`, fired from a `Cmd` kicked off in `Shared.init` when
reconnecting persisted servers at startup -- into the currently active page,
so pages that react to it via their own `SharedMsg` case (see `Pages.Home_`,
`Pages.Post.PostId_`) notice immediately instead of relying on a poll to
eventually catch up.

Any `Shared.Msg`s the page's own `update` forwards back out in response (via
`Effect.fromShared`) are dropped rather than reapplied to `Shared.update` --
a page's `SharedMsg` handler only ever echoes back the very message it was
just given here, and `sharedMsg` has already been applied by the caller, so
reapplying it would double up a state change that's already been made.
-}
notifyPageOfSharedMsg : Shared.Msg -> Shared.Model -> Gen.Model.Model -> Url -> Key -> ( Gen.Model.Model, Cmd Msg )
notifyPageOfSharedMsg sharedMsg shared page url key =
    case sharedMsgForPage sharedMsg page of
        Nothing ->
            ( page, Cmd.none )

        Just msg ->
            let
                ( newPage, effect ) =
                    Pages.update msg page shared url key

                ( _, remainingEffect ) =
                    Effect.partitionShared effect
            in
            ( newPage, Effect.toCmd ( Shared, Page ) remainingEffect )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    Pages.view model.page model.shared model.url model.key
        |> View.map Page
        |> View.toBrowserDocument



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Pages.subscriptions model.page model.shared model.url model.key |> Sub.map Page
        , Shared.subscriptions (Request.create () model.url model.key) model.shared |> Sub.map Shared
        ]
