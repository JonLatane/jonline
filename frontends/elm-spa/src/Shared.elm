module Shared exposing
    ( DeleteConfirmation(..)
    , Flags
    , Model
    , Msg(..)
    , ThemePreference(..)
    , basePathFromPath
    , effectiveDarkMode
    , init
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
import Json.Decode as Decode
import Json.Encode as Encode
import Ports
import Process
import Request exposing (Request)
import Shared.AccountsPanel as AccountsPanel
import Shared.AdminPanel as AdminPanel
import Shared.Breadcrumbs as Breadcrumbs
import Shared.BrowserTimeZone exposing (BrowserTimeZone)
import Shared.FederatedAuth as FederatedAuth
import Shared.MarkdownPanel as MarkdownPanel
import Shared.MediaViewerPanel as MediaViewerPanel
import Shared.MyMediaPanel as MyMediaPanel
import Shared.StarredPostsPanel as StarredPostsPanel
import Task
import Time
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
-}
type DeleteConfirmation
    = ConfirmServerDelete AccountsPanel.Server
    | ConfirmAccountDelete AccountsPanel.Account


type alias Model =
    { accountsPanel : AccountsPanel.Model
    , adminPanel : AdminPanel.Model
    , federatedAuth : FederatedAuth.Model
    , starredPostsPanel : StarredPostsPanel.Model
    , markdownPanel : MarkdownPanel.Model
    , mediaViewerPanel : MediaViewerPanel.Model
    , myMediaPanel : MyMediaPanel.Model
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

    -- Set while `UI.deleteConfirmationModal` is up, `Nothing` the rest of
    -- the time -- see `DeleteConfirmation`.
    , confirmingDeleteFor : Maybe DeleteConfirmation

    -- Drives `UI.scrollPreserver`: a tall spacer at the bottom of `main_`,
    -- shown for the first 2s after navigating *back* to a page (never a
    -- fresh link click) so its restored-but-possibly-still-loading content
    -- can't yank the scroll position around while it fills back in. See
    -- `Main.elm`'s `ChangedUrl`, which fires `ShowScrollPreserver` only for
    -- navigations it recognizes as the browser's back button.
    , scrollPreserverVisible : Bool

    -- The browser's current window size, kept live via `Browser.Events.onResize`
    -- (see `subscriptions`) after an initial `Browser.Dom.getViewport` read in
    -- `init`. Only consulted for `UI.Responsive.isNarrow` -- deciding whether
    -- the Accounts Panel and Starred Posts Panel should close one another when
    -- the other opens (see `update`'s `AccountsPanelMsg`/`StarredPostsPanelMsg`
    -- branches), since both are full-width slide-out panels on narrow screens
    -- and CSS alone can't reach into another panel's state.
    , windowSize : Responsive.WindowSize

    -- See `Shared.BrowserTimeZone`. Used everywhere a `Post`/`User` timestamp
    -- is displayed (see `Shared.BrowserTimeZone.formatDate`/`formatDateTime`)
    -- so those render in the viewer's own local time rather than the
    -- server's UTC.
    , browserTimeZone : BrowserTimeZone
    }


type Msg
    = AccountsPanelMsg AccountsPanel.Msg
    | AdminPanelMsg AdminPanel.Msg
    | FederatedAuthMsg FederatedAuth.Msg
    | StarredPostsPanelMsg StarredPostsPanel.Msg
    | MarkdownPanelMsg MarkdownPanel.Msg
    | MediaViewerPanelMsg MediaViewerPanel.Msg
    | MyMediaPanelMsg MyMediaPanel.Msg
    | MyMediaPanelOpenForAccount AccountsPanel.Account
    | CloseAllPanels
    | BreadcrumbsMsg Breadcrumbs.Msg
    | ThemePreferenceClicked
    | SystemPrefersDarkChanged Bool
    | RequestDelete DeleteConfirmation
    | CancelDelete
    | ConfirmDelete
    | ShowScrollPreserver
    | HideScrollPreserver
    | HomeLinkClicked Bool
    | ScrollToTop
    | NavigateExternal String
    | WindowResized Int Int
    | GotTimeZone Time.Zone
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


{-| `flags` is `{ state, systemPrefersDark, themePreference, timeZoneAbbreviation }`
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

        ( accountsPanelModel, accountsPanelCmd ) =
            AccountsPanel.init req accountsPanelFlags

        ( federatedAuthModel, federatedAuthCmd ) =
            FederatedAuth.init federatedAuthFlags

        model =
            { accountsPanel = accountsPanelModel
            , adminPanel = AdminPanel.init
            , federatedAuth = federatedAuthModel
            , starredPostsPanel = StarredPostsPanel.init starredPostsFlags
            , markdownPanel = MarkdownPanel.init
            , mediaViewerPanel = MediaViewerPanel.init
            , myMediaPanel = MyMediaPanel.init
            , breadcrumbs = Breadcrumbs.init
            , themePreference = themePreference
            , systemPrefersDark = systemPrefersDark
            , basePath = basePath
            , confirmingDeleteFor = Nothing
            , scrollPreserverVisible = False

            -- Corrected as soon as `getInitialWindowSizeCmd` resolves, below
            -- -- arbitrary until then, but never consulted before that (both
            -- panels start closed) so it doesn't matter what it is.
            , windowSize = { width = 0, height = 0 }

            -- `zone` is corrected as soon as `Time.here`, below, resolves.
            , browserTimeZone = { zone = Time.utc, abbreviation = timeZoneAbbreviation }
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
        , Task.perform GotTimeZone Time.here
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

                ( refreshedStarredPostsPanel, refreshCmd ) =
                    StarredPostsPanel.refreshHosts subModel changedHosts model.starredPostsPanel

                -- The Accounts Panel and Starred Posts Panel are both
                -- full-width slide-out panels on narrow screens (see
                -- `UI.Responsive`), so opening one closes the other there.
                shouldCloseStarredPostsPanel =
                    case subMsg of
                        AccountsPanel.ToggleAccountsPanel ->
                            subModel.showAccountsPanel && Responsive.isNarrow model.windowSize

                        _ ->
                            False

                ( closedStarredPostsPanel, closeCmd ) =
                    if shouldCloseStarredPostsPanel then
                        let
                            ( closedModel, cmd, _ ) =
                                StarredPostsPanel.update subModel StarredPostsPanel.CloseStarredPostsPanel refreshedStarredPostsPanel
                        in
                        ( closedModel, cmd )

                    else
                        ( refreshedStarredPostsPanel, Cmd.none )
            in
            ( { model | accountsPanel = subModel, starredPostsPanel = closedStarredPostsPanel }
            , Cmd.batch
                [ Cmd.map AccountsPanelMsg subCmd
                , Cmd.map StarredPostsPanelMsg refreshCmd
                , Cmd.map StarredPostsPanelMsg closeCmd
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

        StarredPostsPanelMsg subMsg ->
            let
                ( subModel, subCmd, ( maybeAccountsPanelMsg, maybeMediaViewerPanelMsg ) ) =
                    StarredPostsPanel.update model.accountsPanel subMsg model.starredPostsPanel

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
                        StarredPostsPanel.ToggleStarredPostsPanel ->
                            subModel.showStarredPostsPanel && Responsive.isNarrow model.windowSize

                        _ ->
                            False

                ( closedAccountsPanelModel, closeCmd ) =
                    if shouldCloseAccountsPanel then
                        AccountsPanel.update req AccountsPanel.CloseAccountsPanel accountsPanelModel

                    else
                        ( accountsPanelModel, Cmd.none )
            in
            ( { model | starredPostsPanel = subModel, accountsPanel = closedAccountsPanelModel, mediaViewerPanel = mediaViewerPanelModel }
            , Cmd.batch
                [ Cmd.map StarredPostsPanelMsg subCmd
                , Cmd.map AccountsPanelMsg accountsPanelCmd
                , Cmd.map AccountsPanelMsg closeCmd
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
            in
            ( { model | markdownPanel = subModel, accountsPanel = accountsPanelModel }
            , Cmd.batch
                [ Cmd.map MarkdownPanelMsg subCmd
                , Cmd.map AccountsPanelMsg accountsPanelCmd
                , scrollPreserverCmd
                ]
            )

        MyMediaPanelMsg subMsg ->
            let
                ( subModel, subCmd, maybeAccountsPanelMsg ) =
                    MyMediaPanel.update model.accountsPanel subMsg model.myMediaPanel

                ( accountsPanelModel, accountsPanelCmd ) =
                    case maybeAccountsPanelMsg of
                        Just accountsPanelMsg ->
                            AccountsPanel.update req accountsPanelMsg model.accountsPanel

                        Nothing ->
                            ( model.accountsPanel, Cmd.none )
            in
            ( { model | myMediaPanel = subModel, accountsPanel = accountsPanelModel }
            , Cmd.batch
                [ Cmd.map MyMediaPanelMsg subCmd
                , Cmd.map AccountsPanelMsg accountsPanelCmd
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
                    updateImpl req (MyMediaPanelMsg (MyMediaPanel.Open MyMediaPanel.Browse host)) enabledModel
            in
            ( openedModel, Cmd.batch [ enableCmd, openCmd ] )

        CloseAllPanels ->
            let
                ( closedAccountsModel, closeAccountsCmd ) =
                    updateImpl req (AccountsPanelMsg AccountsPanel.CloseAccountsPanel) model

                ( closedStarredModel, closeStarredCmd ) =
                    updateImpl req (StarredPostsPanelMsg StarredPostsPanel.CloseStarredPostsPanel) closedAccountsModel
            in
            ( closedStarredModel, Cmd.batch [ closeAccountsCmd, closeStarredCmd ] )

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
            let
                removeMsg =
                    model.confirmingDeleteFor
                        |> Maybe.map
                            (\confirmation ->
                                case confirmation of
                                    ConfirmAccountDelete account ->
                                        AccountsPanel.RemoveAccountClicked (AccountsPanel.accountId account)

                                    ConfirmServerDelete server ->
                                        AccountsPanel.RemoveServerClicked server.frontendHost
                            )
            in
            case removeMsg of
                Just subMsg ->
                    let
                        ( subModel, subCmd ) =
                            AccountsPanel.update req subMsg model.accountsPanel
                    in
                    ( { model | accountsPanel = subModel, confirmingDeleteFor = Nothing }
                    , Cmd.map AccountsPanelMsg subCmd
                    )

                Nothing ->
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
                    updateImpl req (StarredPostsPanelMsg StarredPostsPanel.CloseStarredPostsPanel) model

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

        NoOp ->
            ( model, Cmd.none )


{-| Hosts whose "usable right now" state differs between `before` and `after`
-- either their signed-in account (see `AccountsPanel.enabledAccountForServer`,
e.g. logging into/switching accounts on a server, signing out) or whether
their `Server` itself is enabled (`ToggleServerEnabled` -- which also disables
its accounts, but not for a server with none signed into it, so that flip
needs checking on its own). Tells `Shared.StarredPostsPanel.refreshHosts`
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


{-| Polls for still-missing starred posts (see `Shared.StarredPostsPanel.kickOffFetches`)
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
        , Sub.map StarredPostsPanelMsg (StarredPostsPanel.subscriptions model.starredPostsPanel)
        , Sub.map MediaViewerPanelMsg (MediaViewerPanel.subscriptions model.mediaViewerPanel)
        , if model.starredPostsPanel.showStarredPostsPanel then
            Time.every 1500 (\_ -> StarredPostsPanelMsg StarredPostsPanel.PollStarredPosts)

          else
            Sub.none
        ]
