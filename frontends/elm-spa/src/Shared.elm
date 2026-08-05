module Shared exposing
    ( DeleteConfirmation(..)
    , Flags
    , Model
    , Msg(..)
    , NavAnimationState
    , ThemePreference(..)
    , basePathFromPath
    , effectiveDarkMode
    , init
    , navLinkHomeMaxWidth
    , normalizeUrl
    , subscriptions
    , themePreferenceLabel
    , update
    )

{-| The app-wide state: composes `Shared.AccountsPanel` (known servers,
signed-into accounts, login/add-server forms) and `Shared.AdminPanel` (the
Server Admin Panel, shown when any signed-in account has `ADMIN`), plus the
appearance (dark/light/auto) setting that doesn't belong to either.
-}

import Browser.Dom as Dom
import Browser.Events
import Browser.Navigation as Nav
import Components.EventSyncSources as EventSyncSources
import Components.Events as Events
import Components.Posts as Posts
import Grpc
import Json.Decode as Decode
import Json.Encode as Encode
import Ports
import Process
import Proto.Jonline exposing (Event, EventSyncSource, Media, Post)
import Request exposing (Request)
import Shared.AccountsPanel as AccountsPanel
import Shared.AdminPanel as AdminPanel
import Shared.Breadcrumbs as Breadcrumbs
import Shared.BrowserTimeZone exposing (BrowserTimeZone)
import Shared.CreateNewPanel as CreateNewPanel
import Shared.FederatedAuth as FederatedAuth
import Shared.MarkdownPanel as MarkdownPanel
import Shared.MediaViewerPanel as MediaViewerPanel
import Shared.MyMediaPanel as MyMediaPanel
import Shared.StarredPanel as StarredPanel
import Task
import Time
import TimeZone
import UI.Responsive as Responsive
import Url exposing (Url)


type alias Flags =
    Decode.Value


{-| The user's chosen appearance. `Auto` follows `systemPrefersDark`; `Light`/
`Dark` force it regardless of the system.
-}
type ThemePreference
    = ThemeAuto
    | ThemeLight
    | ThemeDark


{-| Something the user has clicked "delete" on, awaiting confirmation --
`UI.deleteConfirmationModal` is one shared dialog for all of these, rather
than each having its own bespoke confirmation step (compare
`AccountsPanel.PendingCreateAccount`, which stays separate since Create
Account's confirmation isn't a plain "are you sure you want to delete this"
prompt). More constructors (e.g. for Posts) can be added here as that need
comes up.

`ConfirmServerDelete`/`ConfirmAccountDelete`/`ConfirmMediaDelete` delegate
their actual delete into a Shared-owned submodel's own `DeleteConfirmed`
(`AccountsPanel`/`MyMediaPanel`) once confirmed, since those submodels
(unlike a page's own `Model`) are reachable from here. `ConfirmMediaDelete`
could in principle follow the `ConfirmEventSyncSourceDelete`/`ConfirmPostDelete`/
`ConfirmEventDelete` shape below instead -- nothing about `MyMediaPanel`
_requires_ living in `Shared.Model`, it's just simpler to route through since
it's already there (it _is_ a real global panel, opened from several pages,
unlike the old `Shared.EventSyncSourcesPanel` used to be). `ConfirmServerDelete`/
`ConfirmAccountDelete` genuinely can't switch: removing a `Server`/`Account`
has to mutate `AccountsPanel.Model` itself, which only exists here.

-}
type DeleteConfirmation
    = ConfirmServerDelete AccountsPanel.Server
    | ConfirmAccountDelete AccountsPanel.Account
    | ConfirmMediaDelete Media
      -- The trailing `String` on each of these three is the acting
      -- `targetHost` (the source/Post/Event isn't itself paired with one) --
      -- resolved back to a signed-in `Account` (if any) in `ConfirmDelete`'s
      -- own handling. Unlike every `DeleteConfirmation` above, none of these
      -- three are owned by a Shared-owned panel to delegate a
      -- `DeleteConfirmed` into -- each is a plain list rendered by exactly
      -- one page (`Components.Pages.UserProfilePage`/`Pages.Post.PostId_`/
      -- `Pages.Event.EventId_`), so `ConfirmDelete` fires the delete RPC
      -- directly instead, and the result (`GotEventSyncSourceDeleteResult`/
      -- `GotPostDeleteResult`/`GotEventDeleteResult`) is forwarded on to
      -- whichever page is active the same as any other `Shared.Msg`, for
      -- that page's own `Model` to apply. This is the shape any *new*
      -- "list of deletable things shown on one page" should follow -- don't
      -- give the list itself a Shared-owned home just to reach this dialog.
    | ConfirmEventSyncSourceDelete EventSyncSource Bool String
    | ConfirmPostDelete Post String
    | ConfirmEventDelete Event String


{-| Everything driving the Home link's (`.nav-link-home`, `UI.navLink`)
scroll-triggered shrink animation, all bundled into one type since none of
it means anything on its own -- see each field's own comment, and
`navLinkHomeMaxWidth`, its one consumer.
-}
type alias NavAnimationState =
    { -- The live scroll metrics of `.nav-links-scroll` (see
      -- `UI.headerNav`), read off its `scroll` event
      -- (`UI.navLinksScrollDecoder`) -- currently only `scrollLeft` is
      -- consulted (below), but `scrollWidth`/`clientWidth` are kept too so
      -- they're there to reach for if the collapse condition needs to
      -- depend on them again later.
      scrollLeft : Float
    , scrollWidth : Float
    , clientWidth : Float

    -- The debounced on/off state `navLinkHomeMaxWidth` actually renders --
    -- `True` once `scrollLeft` goes positive, `False` once it's back to 0.
    -- Kept separate from the raw scroll position above because flipping
    -- `True` (big -> small) also sets `collapseLocked` for 1s (see that
    -- field), during which this doesn't itself flip again even if the raw
    -- scroll position would otherwise call for it -- rapid back-and-forth
    -- scrolling near the edge would otherwise flicker `.nav-link-home`'s
    -- width right as its own CSS transition is still running.
    , collapsed : Bool

    -- `True` for 1s after `collapsed` flips `False -> True`
    -- (`Process.sleep 1000` in `update`'s `NavLinksScrolled` branch,
    -- cleared by `NavLinkHomeCollapseLockExpired`) -- see `collapsed`.
    , collapseLocked : Bool
    }


{-| The Home link's (`.nav-link-home`, `UI.navLink`) `max-width`, applied
inline (rather than via a CSS class swap) so nav.css's own `transition` on
that property is what animates it; nav.css no longer sets `max-width`
itself, since this always overrides it. Just the two states, driven by
`NavAnimationState.collapsed` (already debounced by the time it gets here).
-}
navLinkHomeMaxWidth : NavAnimationState -> String
navLinkHomeMaxWidth state =
    if state.collapsed then
        "calc(min(max(64px, 25vw), 64px))"

    else
        "calc(min(max(150px, 25vw), 220px))"


type alias Model =
    { accountsPanel : AccountsPanel.Model
    , adminPanel : AdminPanel.Model
    , federatedAuth : FederatedAuth.Model
    , starredPanel : StarredPanel.Model
    , markdownPanel : MarkdownPanel.Model
    , mediaViewerPanel : MediaViewerPanel.Model
    , myMediaPanel : MyMediaPanel.Model
    , createNewPanel : CreateNewPanel.Model

    -- Effectively a "Panel" from the UI's point of view.
    -- Shows a delete confirmation modal while `UI.deleteConfirmationModal` is up,
    -- `Nothing` the rest of the time -- see `DeleteConfirmation`.
    , confirmingDeleteFor : Maybe DeleteConfirmation
    , breadcrumbs : Breadcrumbs.Model
    , themePreference : ThemePreference
    , systemPrefersDark : Bool

    -- The path prefix the app is being served under -- "" from `/`, "/elm"
    -- from `/elm` (see `backend/src/web/elm_web.rs`) -- immutable for the
    -- session, same as `AccountsPanel.Model`'s `browsingHost`. `Main.elm`
    -- strips this from every `Url` before routing (see `normalizeUrl`) so
    -- `Gen.Route.fromUrl` always sees app-relative paths regardless of which
    -- host route served it; view code (see `UI.navLink`) prepends it back
    -- onto any `Gen.Route.toHref` output so links/history stay under the
    -- right mount.
    , basePath : String

    -- Drives `UI.scrollPreserver`: a tall spacer at the bottom of `main_`,
    -- shown for the first 2s after navigating *back* to a page (never a
    -- fresh link click) so its restored-but-possibly-still-loading content
    -- can't yank the scroll position around while it fills back in. See
    -- `Main.elm`'s `ChangedUrl`, which fires `ShowScrollPreserver` only for
    -- navigations it recognizes as the browser's back button.
    , scrollPreserverVisible : Bool

    -- Drives the Home link's scroll-triggered shrink animation -- kept in
    -- sync via `.nav-links-scroll`'s `scroll` event
    -- (`UI.navLinksScrollDecoder` -> `NavLinksScrolled`). See
    -- `NavAnimationState`.
    , navAnimationState : NavAnimationState

    -- The browser's current window size, kept live via `Browser.Events.onResize`
    -- (see `subscriptions`) after an initial `Browser.Dom.getViewport` read in
    -- `init`. Only consulted for `UI.Responsive.isNarrow` -- deciding whether
    -- the Accounts Panel and Starred Panel should close one another when
    -- the other opens (see `update`'s `AccountsPanelMsg`/`StarredPanelMsg`
    -- branches), since both are full-width slide-out panels on narrow screens
    -- and CSS alone can't reach into another panel's state.
    , windowSize : Responsive.WindowSize

    -- See `Shared.BrowserTimeZone`. Used everywhere a `Post`/`User` timestamp
    -- is displayed (see `Shared.BrowserTimeZone.formatDate`/`formatDateTime`)
    -- so those render in the viewer's own local time rather than the
    -- server's UTC.
    , browserTimeZone : BrowserTimeZone

    -- Captured once via `Time.now` in `init` (mirrors `browserTimeZone.zone`'s
    -- own `getBrowserZone` capture exactly, including the `Time.millisToPosix 0`
    -- placeholder until it resolves) -- the single app-wide "now" every page
    -- that used to capture its own (`Pages.Event.EventId_`'s date-picker
    -- strip categorizing `EventInstance`s as upcoming/past, `Components.Events.eventCard`/
    -- `instanceWhenText`'s "is this date in the viewer's current year"
    -- check) reads instead, rather than each independently re-running
    -- `Task.perform ... Time.now`. Deliberately *not* kept live via a
    -- `Time.every` tick -- every current use only needs "roughly what day/year
    -- is it" for the length of a single page view, not a ticking clock, the
    -- same tolerance `Pages.Event.EventId_.Model.now`'s own doc already
    -- accepted before this moved here. `Components.Pages.EventsPage.Model.endsAfter`/
    -- `Components.Pages.PostsPage.Model.publishedBefore` are deliberately
    -- untouched by this -- those are live request cursors (polled and
    -- user-editable), not a display "what time is it", and already document
    -- why they're their own thing.
    , now : Time.Posix
    }


type Msg
    = AccountsPanelMsg AccountsPanel.Msg
    | AdminPanelMsg AdminPanel.Msg
    | FederatedAuthMsg FederatedAuth.Msg
    | StarredPanelMsg StarredPanel.Msg
    | MarkdownPanelMsg MarkdownPanel.Msg
    | MediaViewerPanelMsg MediaViewerPanel.Msg
    | MyMediaPanelMsg MyMediaPanel.Msg
    | MyMediaPanelOpenForAccount AccountsPanel.Account
    | CreateNewPanelMsg CreateNewPanel.Msg
    | CloseAllPanels
    | BreadcrumbsMsg Breadcrumbs.Msg
    | ThemePreferenceClicked
    | SystemPrefersDarkChanged Bool
    | RequestDelete DeleteConfirmation
    | CancelDelete
    | ConfirmDelete
      -- `ConfirmDelete`'s own handling of `ConfirmEventSyncSourceDelete`/
      -- `ConfirmPostDelete`/`ConfirmEventDelete` fires the
      -- `DeleteEventSyncSource`/`DeletePost`/`DeleteEvent` RPC directly
      -- (unlike every other `DeleteConfirmation`, none of these three is
      -- owned by any Shared-owned panel `Shared.update` could delegate to)
      -- -- these are their results. Forwarded, like every `Shared.Msg`, into
      -- whichever page is active (`Main.notifyPageOfSharedMsg`), so
      -- `Components.Pages.UserProfilePage`/`Pages.Post.PostId_`/
      -- `Pages.Event.EventId_`'s own `SharedMsg` handling can update their
      -- own list/navigate away on success.
    | GotEventSyncSourceDeleteResult String (Result Grpc.Error ( Maybe AccountsPanel.Msg, () ))
    | GotPostDeleteResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, Post ))
    | GotEventDeleteResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, Event ))
    | ShowScrollPreserver
    | HideScrollPreserver
    | HomeLinkClicked Bool
    | ScrollToTop
    | NavLinksScrolled { scrollLeft : Float, scrollWidth : Float, clientWidth : Float }
    | NavLinkHomeCollapseLockExpired
    | NavigateExternal String
    | WindowResized Int Int
    | GotTimeZone Time.Zone
    | GotNow Time.Posix
    | NoOp


{-| Whether the app should currently render in dark mode, resolving `Auto`
against the last-known system preference.
-}
effectiveDarkMode : Model -> Bool
effectiveDarkMode model =
    case model.themePreference of
        ThemeAuto ->
            model.systemPrefersDark

        ThemeLight ->
            False

        ThemeDark ->
            True


themePreferenceLabel : ThemePreference -> String
themePreferenceLabel pref =
    case pref of
        ThemeAuto ->
            "Auto"

        ThemeLight ->
            "Light"

        ThemeDark ->
            "Dark"


themePreferenceToString : ThemePreference -> String
themePreferenceToString pref =
    case pref of
        ThemeAuto ->
            "auto"

        ThemeLight ->
            "light"

        ThemeDark ->
            "dark"


themePreferenceFromString : String -> ThemePreference
themePreferenceFromString s =
    case s of
        "light" ->
            ThemeLight

        "dark" ->
            ThemeDark

        _ ->
            ThemeAuto


nextThemePreference : ThemePreference -> ThemePreference
nextThemePreference pref =
    case pref of
        ThemeAuto ->
            ThemeLight

        ThemeLight ->
            ThemeDark

        ThemeDark ->
            ThemeAuto


{-| The `/elm`-or-`/`-style mount prefix for a raw (un-normalized) URL path --
see `Model`'s `basePath` field. Only ever `""` or `"/elm"` today (the only two
hosts `backend/src/web/elm_web.rs`/`main_index.rs` serve this app from), found
by checking whether `path` is exactly `/elm` or starts with `/elm/` -- "elm" is
a reserved username (see `validate_username`), so this can never collide with
a real in-app route or federated-user path.
-}
basePathFromPath : String -> String
basePathFromPath path =
    if path == "/elm" || String.startsWith "/elm/" path then
        "/elm"

    else
        ""


{-| Strips `basePath` off `url.path`, so `Gen.Route.fromUrl` can parse it as
if the app were served from `/` -- see `Main.elm`, which calls this on every
`Url` before it touches routing.
-}
normalizeUrl : String -> Url -> Url
normalizeUrl basePath url =
    if basePath == "" then
        url

    else if url.path == basePath then
        { url | path = "/" }

    else if String.startsWith (basePath ++ "/") url.path then
        { url | path = String.dropLeft (String.length basePath) url.path }

    else
        url


{-| `flags` is `{ state, systemPrefersDark, themePreference, timeZoneAbbreviation, uses24HourTime }`
-- see `index.html`. `state` (the persisted accounts/servers blob) is handed
to `AccountsPanel.init` un-decoded; appearance has its own, separate
persisted key (`themePreference`) so changing it doesn't need to know
anything about `AccountsPanel`'s persisted shape, or vice versa. `req.url` is
assumed already-normalized (see `normalizeUrl`) -- `basePath` is passed
alongside it only because view code (see `UI.navLink`) needs it back to
build hrefs.
-}
init : String -> Request -> Flags -> ( Model, Cmd Msg )
init basePath req flags =
    let
        accountsPanelFlags =
            Decode.decodeValue (Decode.field "state" Decode.value) flags
                |> Result.withDefault Encode.null

        starredPostsFlags =
            Decode.decodeValue (Decode.field "starredPosts" Decode.value) flags
                |> Result.withDefault Encode.null

        federatedAuthFlags =
            Decode.decodeValue (Decode.field "federatedAuthKeyPair" Decode.value) flags
                |> Result.withDefault Encode.null

        systemPrefersDark =
            Decode.decodeValue (Decode.field "systemPrefersDark" Decode.bool) flags
                |> Result.withDefault False

        themePreference =
            Decode.decodeValue (Decode.field "themePreference" Decode.string) flags
                |> Result.map themePreferenceFromString
                |> Result.withDefault ThemeAuto

        timeZoneAbbreviation =
            Decode.decodeValue (Decode.field "timeZoneAbbreviation" Decode.string) flags
                |> Result.withDefault ""

        uses24HourTime =
            Decode.decodeValue (Decode.field "uses24HourTime" Decode.bool) flags
                |> Result.withDefault False

        ( accountsPanelModel, accountsPanelCmd ) =
            AccountsPanel.init req accountsPanelFlags

        ( federatedAuthModel, federatedAuthCmd ) =
            FederatedAuth.init federatedAuthFlags

        model =
            { accountsPanel = accountsPanelModel
            , adminPanel = AdminPanel.init
            , federatedAuth = federatedAuthModel
            , starredPanel = StarredPanel.init starredPostsFlags
            , markdownPanel = MarkdownPanel.init
            , mediaViewerPanel = MediaViewerPanel.init
            , myMediaPanel = MyMediaPanel.init
            , createNewPanel = CreateNewPanel.init
            , breadcrumbs = Breadcrumbs.init
            , themePreference = themePreference
            , systemPrefersDark = systemPrefersDark
            , basePath = basePath
            , confirmingDeleteFor = Nothing
            , scrollPreserverVisible = False
            , navAnimationState =
                { scrollLeft = 0
                , scrollWidth = 0
                , clientWidth = 0
                , collapsed = False
                , collapseLocked = False
                }

            -- Corrected as soon as `getInitialWindowSizeCmd` resolves, below
            -- -- arbitrary until then, but never consulted before that (both
            -- panels start closed) so it doesn't matter what it is.
            , windowSize = { width = 0, height = 0 }

            -- `zone` is corrected as soon as `Time.here`, below, resolves.
            , browserTimeZone = { zone = Time.utc, abbreviation = timeZoneAbbreviation, uses24Hour = uses24HourTime }

            -- Corrected as soon as `Task.perform GotNow Time.now`, below,
            -- resolves -- see `Model.now`'s own doc.
            , now = Time.millisToPosix 0
            }
    in
    ( model
    , Cmd.batch
        [ Cmd.map AccountsPanelMsg accountsPanelCmd
        , Cmd.map FederatedAuthMsg federatedAuthCmd
        , Ports.setTheme (themePreferenceToString themePreference)

        -- `mainFrontendHost`'s branding isn't fetched yet at this point, so
        -- this is only ever the neutral placeholder (see
        -- `UI.ServerTheme.neutralColorMeta`) -- matches `updateImpl`'s later
        -- calls once real branding loads via `navBarColorCmd`, rather than
        -- leaving the static light/dark `<meta>` values from `index.html` in
        -- place until then.
        , Ports.setNavBarColor (AccountsPanel.mainServerTheme (effectiveDarkMode model) model.accountsPanel).primaryColor
        , getInitialWindowSizeCmd
        , Task.attempt (\result -> GotTimeZone (Result.withDefault Time.utc result)) getBrowserZone
        , Task.perform GotNow Time.now
        ]
    )


{-| The window size isn't known until the DOM actually exists to measure --
`Browser.Events.onResize` (see `subscriptions`) only fires on subsequent
changes, so this is what gets `Model.windowSize` its real initial value.
-}
getInitialWindowSizeCmd : Cmd Msg
getInitialWindowSizeCmd =
    Task.perform
        (\viewport -> WindowResized (round viewport.viewport.width) (round viewport.viewport.height))
        Dom.getViewport


{-| The browser's local `Time.Zone`, DST-aware -- unlike plain `Time.here`
(which just snapshots `new Date().getTimezoneOffset()` for the _current_
instant into a fixed-offset `Time.customZone` with no era table, so every
other instant it's ever asked to convert -- e.g. an `EventInstance` months
away, on the other side of a DST transition -- gets rendered with today's
offset instead of its own). This instead reads the browser's actual IANA
zone name (e.g. "America/New\_York", via `elm/time`'s `Time.getZoneName`)
and looks up its real transition history/future in
`justinmimbs/timezone-data`, so `Components.Events.instanceWhenText`/
`siblingInstanceWhenText` show a recurring weekly event's fixed local time
(e.g. "6-7PM") as the same "6-7PM" on both sides of a DST change, rather
than drifting an hour. Falls back to plain `Time.here` if the zone name
can't be read or isn't in `timezone-data` (e.g. an unusual environment
`Intl` doesn't cover) -- never fails outright.
-}
getBrowserZone : Task.Task x Time.Zone
getBrowserZone =
    TimeZone.getZone
        |> Task.map Tuple.second
        |> Task.onError (\_ -> Time.here)


{-| Wraps `updateImpl` to also call out to `Ports.setNavBarColor` whenever
`mainFrontendHost`'s theme actually changes as a result of the message --
either `mainFrontendHost` itself changing (e.g. `AccountsPanel.SetMainFrontendHost`)
or its `Server`'s cached branding being (re)populated (e.g. after a
`ServerConfiguration` fetch). Comparing `primaryColor` before/after here,
rather than threading a "did the theme change" flag out of every branch that
touches `accountsPanel`, means every current and future such path gets this
for free.
-}
update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    let
        ( newModel, cmd ) =
            updateImpl req msg model
    in
    ( newModel, Cmd.batch [ cmd, navBarColorCmd model newModel ] )


{-| The `primaryColor` `Ports.setNavBarColor` should push to the page's
`<meta name="theme-color">` tags -- see `mainServerTheme`'s note on why
`primaryColor` itself (unlike `primaryBgColor`/`primaryAnchorColor`) doesn't
vary with dark/light mode, so this never fires from a `ThemePreferenceClicked`/
`SystemPrefersDarkChanged` alone.
-}
navBarColorCmd : Model -> Model -> Cmd Msg
navBarColorCmd before after =
    let
        colorOf model_ =
            (AccountsPanel.mainServerTheme (effectiveDarkMode model_) model_.accountsPanel).primaryColor
    in
    if colorOf before /= colorOf after then
        Ports.setNavBarColor (colorOf after)

    else
        Cmd.none


updateImpl : Request -> Msg -> Model -> ( Model, Cmd Msg )
updateImpl req msg model =
    case msg of
        AccountsPanelMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    AccountsPanel.update req subMsg model.accountsPanel

                changedHosts =
                    starredPostsRefreshHosts model.accountsPanel subModel

                ( refreshedStarredPanel, refreshCmd ) =
                    StarredPanel.refreshHosts subModel changedHosts model.starredPanel

                -- The Accounts Panel and Starred Panel are both
                -- full-width slide-out panels on narrow screens (see
                -- `UI.Responsive`), so opening one closes the other there.
                shouldCloseStarredPanel =
                    case subMsg of
                        AccountsPanel.ToggleAccountsPanel ->
                            subModel.showAccountsPanel && Responsive.isNarrow model.windowSize

                        _ ->
                            False

                ( closedStarredPanel, closeCmd ) =
                    if shouldCloseStarredPanel then
                        let
                            ( closedModel, cmd, _ ) =
                                StarredPanel.update subModel StarredPanel.CloseStarredPanel refreshedStarredPanel
                        in
                        ( closedModel, cmd )

                    else
                        ( refreshedStarredPanel, Cmd.none )

                -- Unlike `shouldCloseStarredPanel` above, unconditional --
                -- not just narrow screens -- since the New Post/Event panel
                -- opens at this same vertical position (see
                -- create_new_panel.css's own `top` comment) rather than as
                -- one of `.navbar`'s own dropdowns, so the two would
                -- visually collide at any width. Mirrors `CreateNewPanelMsg`'s
                -- own `shouldCloseAccountsPanel`, in the other direction.
                shouldCloseCreateNewPanel =
                    case subMsg of
                        AccountsPanel.ToggleAccountsPanel ->
                            subModel.showAccountsPanel

                        _ ->
                            False

                ( closedCreateNewPanel, closeCreateNewCmd ) =
                    if shouldCloseCreateNewPanel then
                        let
                            ( m, cmd, _ ) =
                                CreateNewPanel.update model.browserTimeZone.zone subModel CreateNewPanel.CloseClicked model.createNewPanel
                        in
                        ( m, cmd )

                    else
                        ( model.createNewPanel, Cmd.none )
            in
            ( { model | accountsPanel = subModel, starredPanel = closedStarredPanel, createNewPanel = closedCreateNewPanel }
            , Cmd.batch
                [ Cmd.map AccountsPanelMsg subCmd
                , Cmd.map StarredPanelMsg refreshCmd
                , Cmd.map StarredPanelMsg closeCmd
                , Cmd.map CreateNewPanelMsg closeCreateNewCmd
                ]
            )

        AdminPanelMsg subMsg ->
            ( { model | adminPanel = AdminPanel.update subMsg model.adminPanel }, Cmd.none )

        FederatedAuthMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    FederatedAuth.update subMsg model.federatedAuth
            in
            ( { model | federatedAuth = subModel }, Cmd.map FederatedAuthMsg subCmd )

        StarredPanelMsg subMsg ->
            let
                ( subModel, subCmd, ( maybeAccountsPanelMsg, maybeMediaViewerPanelMsg ) ) =
                    StarredPanel.update model.accountsPanel subMsg model.starredPanel

                ( accountsPanelModel, accountsPanelCmd ) =
                    case maybeAccountsPanelMsg of
                        Just accountsPanelMsg ->
                            AccountsPanel.update req accountsPanelMsg model.accountsPanel

                        Nothing ->
                            ( model.accountsPanel, Cmd.none )

                mediaViewerPanelModel =
                    case maybeMediaViewerPanelMsg of
                        Just mediaViewerPanelMsg ->
                            MediaViewerPanel.update mediaViewerPanelMsg model.mediaViewerPanel

                        Nothing ->
                            model.mediaViewerPanel

                -- Mirrors `AccountsPanelMsg`'s own close-the-other-panel
                -- branch, above -- see `UI.Responsive`.
                shouldCloseAccountsPanel =
                    case subMsg of
                        StarredPanel.ToggleStarredPanel ->
                            subModel.showStarredPanel && Responsive.isNarrow model.windowSize

                        _ ->
                            False

                ( closedAccountsPanelModel, closeCmd ) =
                    if shouldCloseAccountsPanel then
                        AccountsPanel.update req AccountsPanel.CloseAccountsPanel accountsPanelModel

                    else
                        ( accountsPanelModel, Cmd.none )

                -- Unlike `shouldCloseAccountsPanel` above, unconditional --
                -- not just narrow screens -- since the New Post panel opens
                -- at this same vertical position (see
                -- create_new_panel.css's own `top` comment) rather than as
                -- one of `.navbar`'s own dropdowns, so the two would visually
                -- collide at any width.
                shouldCloseCreateNewPanel =
                    case subMsg of
                        StarredPanel.ToggleStarredPanel ->
                            subModel.showStarredPanel

                        _ ->
                            False

                ( closedCreateNewPanelModel, closeCreateNewCmd ) =
                    if shouldCloseCreateNewPanel then
                        let
                            ( m, cmd, _ ) =
                                CreateNewPanel.update model.browserTimeZone.zone closedAccountsPanelModel CreateNewPanel.CloseClicked model.createNewPanel
                        in
                        ( m, cmd )

                    else
                        ( model.createNewPanel, Cmd.none )
            in
            ( { model
                | starredPanel = subModel
                , accountsPanel = closedAccountsPanelModel
                , mediaViewerPanel = mediaViewerPanelModel
                , createNewPanel = closedCreateNewPanelModel
              }
            , Cmd.batch
                [ Cmd.map StarredPanelMsg subCmd
                , Cmd.map AccountsPanelMsg accountsPanelCmd
                , Cmd.map AccountsPanelMsg closeCmd
                , Cmd.map CreateNewPanelMsg closeCreateNewCmd
                ]
            )

        MediaViewerPanelMsg subMsg ->
            ( { model | mediaViewerPanel = MediaViewerPanel.update subMsg model.mediaViewerPanel }, Cmd.none )

        BreadcrumbsMsg subMsg ->
            let
                breadcrumbsModel =
                    { model | breadcrumbs = Breadcrumbs.update subMsg model.breadcrumbs }
            in
            case subMsg of
                Breadcrumbs.SetRoot _ _ _ ->
                    updateImpl req CloseAllPanels breadcrumbsModel

                _ ->
                    ( breadcrumbsModel, Cmd.none )

        MarkdownPanelMsg subMsg ->
            let
                -- `Shared.CreateNewPanel`'s own draft content, if this exact
                -- `SaveClicked` is the one closing out its
                -- `MarkdownPanel.NewPostContent` edit -- read off
                -- `model.markdownPanel.content` *before* `MarkdownPanel.update`
                -- (below) resets it back to `init`, since `MarkdownPanel`
                -- itself has no Post to save this to (see `TargetType`'s own
                -- doc on `NewPostContent`) and so never hands it back on its
                -- own `Msg`.
                savedNewPostContent =
                    case ( subMsg, model.markdownPanel.target ) of
                        ( MarkdownPanel.SaveClicked, Just (MarkdownPanel.NewPostContent _) ) ->
                            Just model.markdownPanel.content

                        _ ->
                            Nothing

                ( subModel, subCmd, ( maybeAccountsPanelMsg, showScrollPreserver ) ) =
                    MarkdownPanel.update model.accountsPanel subMsg model.markdownPanel

                ( accountsPanelModel, accountsPanelCmd ) =
                    case maybeAccountsPanelMsg of
                        Just accountsPanelMsg ->
                            AccountsPanel.update req accountsPanelMsg model.accountsPanel

                        Nothing ->
                            ( model.accountsPanel, Cmd.none )

                scrollPreserverCmd =
                    if showScrollPreserver then
                        Task.perform (\() -> ShowScrollPreserver) (Task.succeed ())

                    else
                        Cmd.none

                ( createNewPanelModel, createNewPanelCmd ) =
                    case savedNewPostContent of
                        Just content ->
                            let
                                ( m, cmd, _ ) =
                                    CreateNewPanel.update model.browserTimeZone.zone model.accountsPanel (CreateNewPanel.ContentSaved content) model.createNewPanel
                            in
                            ( m, cmd )

                        Nothing ->
                            ( model.createNewPanel, Cmd.none )
            in
            ( { model | markdownPanel = subModel, accountsPanel = accountsPanelModel, createNewPanel = createNewPanelModel }
            , Cmd.batch
                [ Cmd.map MarkdownPanelMsg subCmd
                , Cmd.map AccountsPanelMsg accountsPanelCmd
                , scrollPreserverCmd
                , Cmd.map CreateNewPanelMsg createNewPanelCmd
                ]
            )

        MyMediaPanelMsg subMsg ->
            let
                -- `Shared.CreateNewPanel`'s own picked media, if this exact
                -- `SaveMediaClicked` is the one closing out the `MultiSelect`
                -- it opened (`EditMediaClicked`) -- gated on it currently
                -- being open, same "am I mid-edit" reasoning
                -- `Pages.Post.PostId_.mediaEditActive` uses for its own,
                -- page-level `MultiSelect` consumer (see `MyMediaPanel`'s own
                -- module doc).
                savedMedia =
                    case subMsg of
                        MyMediaPanel.SaveMediaClicked media ->
                            if CreateNewPanel.isOpen model.createNewPanel then
                                Just media

                            else
                                Nothing

                        _ ->
                            Nothing

                ( subModel, subCmd, ( maybeAccountsPanelMsg, maybeDeleteRequest ) ) =
                    MyMediaPanel.update model.accountsPanel subMsg model.myMediaPanel

                ( accountsPanelModel, accountsPanelCmd ) =
                    case maybeAccountsPanelMsg of
                        Just accountsPanelMsg ->
                            AccountsPanel.update req accountsPanelMsg model.accountsPanel

                        Nothing ->
                            ( model.accountsPanel, Cmd.none )

                -- `MyMediaPanel.DeleteClicked`'s own request (see its doc) to
                -- open the shared "are you sure?" dialog -- same
                -- `RequestDelete` a plain `Shared.Msg` click (`serverChip`/
                -- `accountRow`) would fire directly, just routed through this
                -- panel's own `Msg` space instead since its `view` is fully
                -- `Html.map`-wrapped (see `UI.myMediaPanel`).
                confirmingDeleteFor =
                    case maybeDeleteRequest of
                        Just media ->
                            Just (ConfirmMediaDelete media)

                        Nothing ->
                            model.confirmingDeleteFor

                ( createNewPanelModel, createNewPanelCmd ) =
                    case savedMedia of
                        Just media ->
                            let
                                ( m, cmd, _ ) =
                                    CreateNewPanel.update model.browserTimeZone.zone model.accountsPanel (CreateNewPanel.MediaSaved media) model.createNewPanel
                            in
                            ( m, cmd )

                        Nothing ->
                            ( model.createNewPanel, Cmd.none )
            in
            ( { model | myMediaPanel = subModel, accountsPanel = accountsPanelModel, confirmingDeleteFor = confirmingDeleteFor, createNewPanel = createNewPanelModel }
            , Cmd.batch
                [ Cmd.map MyMediaPanelMsg subCmd
                , Cmd.map AccountsPanelMsg accountsPanelCmd
                , Cmd.map CreateNewPanelMsg createNewPanelCmd
                ]
            )

        CreateNewPanelMsg subMsg ->
            let
                ( subModel, subCmd, ( maybeAccountsPanelMsg, maybeMarkdownPanelMsg, maybeMyMediaPanelMsg ) ) =
                    CreateNewPanel.update model.browserTimeZone.zone model.accountsPanel subMsg model.createNewPanel

                ( accountsPanelModel, accountsPanelCmd ) =
                    case maybeAccountsPanelMsg of
                        Just accountsPanelMsg ->
                            AccountsPanel.update req accountsPanelMsg model.accountsPanel

                        Nothing ->
                            ( model.accountsPanel, Cmd.none )

                -- `CreateNewPanel.EditContentClicked`/`EditMediaClicked`'s own
                -- request (see its module doc) to actually open
                -- `MarkdownPanel`/`MyMediaPanel` on its behalf -- it can't
                -- dispatch either directly without importing `Shared`, which
                -- would cycle.
                ( markdownPanelModel, markdownPanelCmd ) =
                    case maybeMarkdownPanelMsg of
                        Just markdownPanelMsg ->
                            let
                                ( m, cmd, _ ) =
                                    MarkdownPanel.update accountsPanelModel markdownPanelMsg model.markdownPanel
                            in
                            ( m, cmd )

                        Nothing ->
                            ( model.markdownPanel, Cmd.none )

                ( myMediaPanelModel, myMediaPanelCmd ) =
                    case maybeMyMediaPanelMsg of
                        Just myMediaPanelMsg ->
                            let
                                ( m, cmd, _ ) =
                                    MyMediaPanel.update accountsPanelModel myMediaPanelMsg model.myMediaPanel
                            in
                            ( m, cmd )

                        Nothing ->
                            ( model.myMediaPanel, Cmd.none )

                -- Mirrors `StarredPanelMsg`'s own
                -- `shouldCloseCreateNewPanel`, in the other direction --
                -- unconditional (not narrow-screen-gated), same reasoning.
                shouldCloseStarredPanel =
                    case subMsg of
                        CreateNewPanel.ToggleOpen ->
                            subModel.open

                        _ ->
                            False

                ( closedStarredPanelModel, closeStarredPostsCmd ) =
                    if shouldCloseStarredPanel then
                        let
                            ( m, cmd, _ ) =
                                StarredPanel.update accountsPanelModel StarredPanel.CloseStarredPanel model.starredPanel
                        in
                        ( m, cmd )

                    else
                        ( model.starredPanel, Cmd.none )

                -- Mirrors `AccountsPanelMsg`'s own `shouldCloseCreateNewPanel`,
                -- in the other direction -- see its own doc.
                shouldCloseAccountsPanel =
                    case subMsg of
                        CreateNewPanel.ToggleOpen ->
                            subModel.open

                        _ ->
                            False

                ( closedAccountsPanelModel, closeAccountsCmd ) =
                    if shouldCloseAccountsPanel then
                        AccountsPanel.update req AccountsPanel.CloseAccountsPanel accountsPanelModel

                    else
                        ( accountsPanelModel, Cmd.none )
            in
            ( { model
                | createNewPanel = subModel
                , accountsPanel = closedAccountsPanelModel
                , markdownPanel = markdownPanelModel
                , myMediaPanel = myMediaPanelModel
                , starredPanel = closedStarredPanelModel
              }
            , Cmd.batch
                [ Cmd.map CreateNewPanelMsg subCmd
                , Cmd.map AccountsPanelMsg accountsPanelCmd
                , Cmd.map AccountsPanelMsg closeAccountsCmd
                , Cmd.map MarkdownPanelMsg markdownPanelCmd
                , Cmd.map MyMediaPanelMsg myMediaPanelCmd
                , Cmd.map StarredPanelMsg closeStarredPostsCmd
                ]
            )

        MyMediaPanelOpenForAccount account ->
            -- The media button on an Account chip (`UI.accountRow`) opens this
            -- panel for that account's server -- mirrors `HomeLinkClicked`'s own
            -- multi-panel composition via `updateImpl`. The chip is clickable for
            -- disabled (signed-out-of-aggregation) accounts too, so bring the
            -- account along into `enabled` here, the same as clicking its switch
            -- (`AccountsPanel.ToggleAccountEnabled`), rather than silently
            -- browsing an account the Accounts Panel still shows as off.
            let
                host =
                    account.server

                ( enabledModel, enableCmd ) =
                    if account.enabled then
                        ( model, Cmd.none )

                    else
                        updateImpl req (AccountsPanelMsg (AccountsPanel.ToggleAccountEnabled (AccountsPanel.accountId account))) model

                ( openedModel, openCmd ) =
                    updateImpl req (MyMediaPanelMsg (MyMediaPanel.Open Nothing host)) enabledModel
            in
            ( openedModel, Cmd.batch [ enableCmd, openCmd ] )

        CloseAllPanels ->
            let
                ( closedAccountsModel, closeAccountsCmd ) =
                    updateImpl req (AccountsPanelMsg AccountsPanel.CloseAccountsPanel) model

                ( closedStarredModel, closeStarredCmd ) =
                    updateImpl req (StarredPanelMsg StarredPanel.CloseStarredPanel) closedAccountsModel

                ( closedCreateNewModel, closeCreateNewCmd ) =
                    updateImpl req (CreateNewPanelMsg CreateNewPanel.CloseClicked) closedStarredModel
            in
            ( closedCreateNewModel, Cmd.batch [ closeAccountsCmd, closeStarredCmd, closeCreateNewCmd ] )

        ThemePreferenceClicked ->
            let
                newPreference =
                    nextThemePreference model.themePreference
            in
            ( { model | themePreference = newPreference }
            , Cmd.batch
                [ Ports.setTheme (themePreferenceToString newPreference)
                , Ports.persistThemePreference (themePreferenceToString newPreference)
                ]
            )

        SystemPrefersDarkChanged prefersDark ->
            ( { model | systemPrefersDark = prefersDark }, Cmd.none )

        RequestDelete confirmation ->
            ( { model | confirmingDeleteFor = Just confirmation }, Cmd.none )

        CancelDelete ->
            ( { model | confirmingDeleteFor = Nothing }, Cmd.none )

        ConfirmDelete ->
            case model.confirmingDeleteFor of
                -- These two route straight into `AccountsPanel.update`
                -- rather than resolving through `Task.attempt` + a
                -- `GotXDeleteResult` here, unlike every branch below. That's
                -- fine *only* because `AccountsPanel.Model` already lives on
                -- `Shared.Model` for unrelated reasons (it's real global
                -- state -- known servers, signed-in accounts -- read from
                -- all over the app); it's not a reason to give some other
                -- page-local delete a Shared-owned home just to reach this
                -- `case`. See `DeleteConfirmation`'s own doc.
                Just (ConfirmAccountDelete account) ->
                    let
                        ( subModel, subCmd ) =
                            AccountsPanel.update req (AccountsPanel.RemoveAccountClicked (AccountsPanel.accountId account)) model.accountsPanel
                    in
                    ( { model | accountsPanel = subModel, confirmingDeleteFor = Nothing }
                    , Cmd.map AccountsPanelMsg subCmd
                    )

                Just (ConfirmServerDelete server) ->
                    let
                        ( subModel, subCmd ) =
                            AccountsPanel.update req (AccountsPanel.RemoveServerClicked server.frontendHost) model.accountsPanel
                    in
                    ( { model | accountsPanel = subModel, confirmingDeleteFor = Nothing }
                    , Cmd.map AccountsPanelMsg subCmd
                    )

                -- Unlike the two branches above (which just flip local
                -- state), this actually calls `DeleteMedia` -- see
                -- `MyMediaPanel.deleteTask`. Its own `maybeAccountsPanelMsg`
                -- is forwarded the same way `MyMediaPanelMsg` above does;
                -- `DeleteConfirmed` never produces a delete request of its
                -- own (that's only `DeleteClicked`), so its second value is
                -- ignored here.
                Just (ConfirmMediaDelete media) ->
                    let
                        ( subModel, subCmd, ( maybeAccountsPanelMsg, _ ) ) =
                            MyMediaPanel.update model.accountsPanel (MyMediaPanel.DeleteConfirmed media) model.myMediaPanel

                        ( accountsPanelModel, accountsPanelCmd ) =
                            case maybeAccountsPanelMsg of
                                Just accountsPanelMsg ->
                                    AccountsPanel.update req accountsPanelMsg model.accountsPanel

                                Nothing ->
                                    ( model.accountsPanel, Cmd.none )
                    in
                    ( { model | myMediaPanel = subModel, accountsPanel = accountsPanelModel, confirmingDeleteFor = Nothing }
                    , Cmd.batch
                        [ Cmd.map MyMediaPanelMsg subCmd
                        , Cmd.map AccountsPanelMsg accountsPanelCmd
                        ]
                    )

                -- Unlike every branch above, none of these three is owned by
                -- any Shared-owned panel to delegate a `DeleteConfirmed`
                -- into -- each fires its delete RPC directly instead,
                -- resolving the acting account from the carried `targetHost`.
                -- Each result (`GotEventSyncSourceDeleteResult`/
                -- `GotPostDeleteResult`/`GotEventDeleteResult`) is picked up
                -- by whichever page is active, same as any other
                -- `Shared.Msg` -- see `DeleteConfirmation`'s own doc for why
                -- this is the shape new page-owned deletable lists should
                -- follow.
                Just (ConfirmEventSyncSourceDelete source deleteSyncedEvents host) ->
                    ( { model | confirmingDeleteFor = Nothing }
                    , EventSyncSources.deleteEventSyncSource
                        model.accountsPanel
                        ( AccountsPanel.enabledAccountForServer model.accountsPanel.accounts host |> Maybe.map .userId, host )
                        source
                        deleteSyncedEvents
                        |> Task.attempt (GotEventSyncSourceDeleteResult source.id)
                    )

                Just (ConfirmPostDelete post host) ->
                    ( { model | confirmingDeleteFor = Nothing }
                    , Posts.deletePost
                        model.accountsPanel
                        ( AccountsPanel.enabledAccountForServer model.accountsPanel.accounts host |> Maybe.map .userId, host )
                        post.id
                        |> Task.attempt GotPostDeleteResult
                    )

                Just (ConfirmEventDelete event host) ->
                    ( { model | confirmingDeleteFor = Nothing }
                    , Events.deleteEvent
                        model.accountsPanel
                        ( AccountsPanel.enabledAccountForServer model.accountsPanel.accounts host |> Maybe.map .userId, host )
                        event.id
                        |> Task.attempt GotEventDeleteResult
                    )

                Nothing ->
                    ( model, Cmd.none )

        GotEventSyncSourceDeleteResult _ (Ok ( maybeAccountsPanelMsg, _ )) ->
            let
                ( accountsPanelModel, accountsPanelCmd ) =
                    case maybeAccountsPanelMsg of
                        Just accountsPanelMsg ->
                            AccountsPanel.update req accountsPanelMsg model.accountsPanel

                        Nothing ->
                            ( model.accountsPanel, Cmd.none )
            in
            ( { model | accountsPanel = accountsPanelModel }, Cmd.map AccountsPanelMsg accountsPanelCmd )

        GotEventSyncSourceDeleteResult _ (Err _) ->
            ( model, Cmd.none )

        GotPostDeleteResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            let
                ( accountsPanelModel, accountsPanelCmd ) =
                    case maybeAccountsPanelMsg of
                        Just accountsPanelMsg ->
                            AccountsPanel.update req accountsPanelMsg model.accountsPanel

                        Nothing ->
                            ( model.accountsPanel, Cmd.none )
            in
            ( { model | accountsPanel = accountsPanelModel }, Cmd.map AccountsPanelMsg accountsPanelCmd )

        GotPostDeleteResult (Err _) ->
            ( model, Cmd.none )

        GotEventDeleteResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            let
                ( accountsPanelModel, accountsPanelCmd ) =
                    case maybeAccountsPanelMsg of
                        Just accountsPanelMsg ->
                            AccountsPanel.update req accountsPanelMsg model.accountsPanel

                        Nothing ->
                            ( model.accountsPanel, Cmd.none )
            in
            ( { model | accountsPanel = accountsPanelModel }, Cmd.map AccountsPanelMsg accountsPanelCmd )

        GotEventDeleteResult (Err _) ->
            ( model, Cmd.none )

        ShowScrollPreserver ->
            ( { model | scrollPreserverVisible = True }
            , Process.sleep 3000 |> Task.perform (\() -> HideScrollPreserver)
            )

        HideScrollPreserver ->
            ( { model | scrollPreserverVisible = False }, Cmd.none )

        HomeLinkClicked alreadyHome ->
            let
                ( closedModel, closeCmd ) =
                    updateImpl req (StarredPanelMsg StarredPanel.CloseStarredPanel) model

                -- Re-clicking Home while already on it doesn't rerun
                -- `Pages.Home_.init` (same route), so `Main.elm`'s `ChangedUrl`
                -- never fires either -- this is the only reliable "just tapped
                -- Home" hook (see `UI.navLink`), hence scrolling to top here.
                ( scrolledModel, scrollCmd ) =
                    if alreadyHome then
                        updateImpl req ScrollToTop closedModel

                    else
                        ( closedModel, Cmd.none )
            in
            ( scrolledModel, Cmd.batch [ closeCmd, scrollCmd ] )

        ScrollToTop ->
            ( model, Task.perform (\_ -> NoOp) (Dom.setViewport 0 0) )

        NavLinksScrolled position ->
            let
                state =
                    model.navAnimationState

                positionedState =
                    { state
                        | scrollLeft = position.scrollLeft
                        , scrollWidth = position.scrollWidth
                        , clientWidth = position.clientWidth
                    }

                desiredCollapsed =
                    position.scrollLeft > 0
            in
            if state.collapseLocked || desiredCollapsed == state.collapsed then
                ( { model | navAnimationState = positionedState }, Cmd.none )

            else if desiredCollapsed then
                ( { model | navAnimationState = { positionedState | collapsed = True, collapseLocked = True } }
                , Process.sleep 1000 |> Task.perform (\() -> NavLinkHomeCollapseLockExpired)
                )

            else
                ( { model | navAnimationState = { positionedState | collapsed = False } }, Cmd.none )

        NavLinkHomeCollapseLockExpired ->
            let
                state =
                    model.navAnimationState
            in
            ( { model
                | navAnimationState =
                    { state
                        | collapseLocked = False
                        , collapsed = state.scrollLeft > 0
                    }
              }
            , Cmd.none
            )

        NavigateExternal url ->
            ( model, Nav.load url )

        WindowResized width height ->
            ( { model | windowSize = { width = width, height = height } }, Cmd.none )

        GotTimeZone zone ->
            let
                browserTimeZone =
                    model.browserTimeZone
            in
            ( { model | browserTimeZone = { browserTimeZone | zone = zone } }, Cmd.none )

        GotNow now ->
            ( { model | now = now }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


{-| Hosts whose "usable right now" state differs between `before` and `after`
-- either their signed-in account (see `AccountsPanel.enabledAccountForServer`,
e.g. logging into/switching accounts on a server, signing out) or whether
their `Server` itself is enabled (`ToggleServerEnabled` -- which also disables
its accounts, but not for a server with none signed into it, so that flip
needs checking on its own). Tells `Shared.StarredPanel.refreshHosts`
which servers' cached starred `Post`s might now be wrong -- a starred post's
visibility can depend on which account fetched it, and an unavailable
server's shouldn't be fetched/shown at all (see
`Components.ServerDependentView.availableServer`) -- and so need
clearing/refetching.
-}
starredPostsRefreshHosts : AccountsPanel.Model -> AccountsPanel.Model -> List String
starredPostsRefreshHosts before after =
    let
        dedupe list =
            List.foldl
                (\host acc ->
                    if List.member host acc then
                        acc

                    else
                        host :: acc
                )
                []
                list

        hosts =
            dedupe
                ((before.accounts |> List.map .server)
                    ++ (after.accounts |> List.map .server)
                    ++ (before.servers |> List.map .frontendHost)
                    ++ (after.servers |> List.map .frontendHost)
                )

        identity model_ host =
            ( AccountsPanel.enabledAccountForServer model_.accounts host
                |> Maybe.map AccountsPanel.accountId
            , AccountsPanel.serverForHost model_.servers host
                |> Maybe.map .enabled
            )
    in
    hosts |> List.filter (\host -> identity before host /= identity after host)


{-| Polls for still-missing starred posts (see `Shared.StarredPanel.kickOffFetches`)
only while the panel's actually open -- there's nothing to show for it
otherwise, so no reason to keep hitting servers in the background.
-}
subscriptions : Request -> Model -> Sub Msg
subscriptions _ model =
    Sub.batch
        [ Ports.systemPrefersDarkChanged SystemPrefersDarkChanged
        , Browser.Events.onResize WindowResized
        , Sub.map AccountsPanelMsg (AccountsPanel.subscriptions model.accountsPanel)
        , Sub.map FederatedAuthMsg FederatedAuth.subscriptions
        , Sub.map StarredPanelMsg (StarredPanel.subscriptions model.starredPanel)
        , Sub.map MediaViewerPanelMsg (MediaViewerPanel.subscriptions model.mediaViewerPanel)
        , Sub.map MyMediaPanelMsg (MyMediaPanel.subscriptions model.myMediaPanel)
        , if model.starredPanel.showStarredPanel then
            Time.every 1500 (\_ -> StarredPanelMsg StarredPanel.PollStarredPosts)

          else
            Sub.none
        ]
