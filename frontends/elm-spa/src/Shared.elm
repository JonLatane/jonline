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

import Json.Decode as Decode
import Json.Encode as Encode
import Ports
import Request exposing (Request)
import Shared.AccountsPanel as AccountsPanel
import Shared.AdminPanel as AdminPanel
import Shared.StarredPostsPanel as StarredPostsPanel
import Time
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
    , starredPostsPanel : StarredPostsPanel.Model
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
    }


type Msg
    = AccountsPanelMsg AccountsPanel.Msg
    | AdminPanelMsg AdminPanel.Msg
    | StarredPostsPanelMsg StarredPostsPanel.Msg
    | ThemePreferenceClicked
    | SystemPrefersDarkChanged Bool
    | RequestDelete DeleteConfirmation
    | CancelDelete
    | ConfirmDelete


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


{-| `flags` is `{ state, systemPrefersDark, themePreference }` -- see
`index.html`. `state` (the persisted accounts/servers blob) is handed to
`AccountsPanel.init` un-decoded; appearance has its own, separate persisted
key (`themePreference`) so changing it doesn't need to know anything about
`AccountsPanel`'s persisted shape, or vice versa. `req.url` is assumed
already-normalized (see `normalizeUrl`) -- `basePath` is passed alongside it
only because view code (see `UI.navLink`) needs it back to build hrefs.
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

        systemPrefersDark =
            Decode.decodeValue (Decode.field "systemPrefersDark" Decode.bool) flags
                |> Result.withDefault False

        themePreference =
            Decode.decodeValue (Decode.field "themePreference" Decode.string) flags
                |> Result.map themePreferenceFromString
                |> Result.withDefault ThemeAuto

        ( accountsPanelModel, accountsPanelCmd ) =
            AccountsPanel.init req accountsPanelFlags
    in
    ( { accountsPanel = accountsPanelModel
      , adminPanel = AdminPanel.init
      , starredPostsPanel = StarredPostsPanel.init starredPostsFlags
      , themePreference = themePreference
      , systemPrefersDark = systemPrefersDark
      , basePath = basePath
      , confirmingDeleteFor = Nothing
      }
    , Cmd.batch
        [ Cmd.map AccountsPanelMsg accountsPanelCmd
        , Ports.setTheme (themePreferenceToString themePreference)
        ]
    )


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        AccountsPanelMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    AccountsPanel.update req subMsg model.accountsPanel

                changedHosts =
                    accountIdentityChangedHosts model.accountsPanel subModel

                ( refreshedStarredPostsPanel, refreshCmd ) =
                    StarredPostsPanel.refreshHosts subModel changedHosts model.starredPostsPanel
            in
            ( { model | accountsPanel = subModel, starredPostsPanel = refreshedStarredPostsPanel }
            , Cmd.batch
                [ Cmd.map AccountsPanelMsg subCmd
                , Cmd.map StarredPostsPanelMsg refreshCmd
                ]
            )

        AdminPanelMsg subMsg ->
            ( { model | adminPanel = AdminPanel.update subMsg model.adminPanel }, Cmd.none )

        StarredPostsPanelMsg subMsg ->
            let
                ( subModel, subCmd, maybeRefreshedAccount ) =
                    StarredPostsPanel.update model.accountsPanel subMsg model.starredPostsPanel

                ( accountsPanelModel, accountsPanelCmd ) =
                    case maybeRefreshedAccount of
                        Just account ->
                            AccountsPanel.update req (AccountsPanel.AccountRefreshed account) model.accountsPanel

                        Nothing ->
                            ( model.accountsPanel, Cmd.none )
            in
            ( { model | starredPostsPanel = subModel, accountsPanel = accountsPanelModel }
            , Cmd.batch
                [ Cmd.map StarredPostsPanelMsg subCmd
                , Cmd.map AccountsPanelMsg accountsPanelCmd
                ]
            )

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


{-| Hosts whose signed-in account (see `AccountsPanel.enabledAccountForServer`)
differs between `before` and `after` -- e.g. logging into/switching accounts on
a server, signing out, or disabling/re-enabling it (`ToggleServerEnabled`
disables its accounts too). Tells `Shared.StarredPostsPanel.refreshHosts` which
servers' cached starred `Post`s might now be wrong -- a starred post's
visibility can depend on which account fetched it -- and so need
clearing/refetching.
-}
accountIdentityChangedHosts : AccountsPanel.Model -> AccountsPanel.Model -> List String
accountIdentityChangedHosts before after =
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
            dedupe ((before.accounts |> List.map .server) ++ (after.accounts |> List.map .server))

        identity model_ host =
            AccountsPanel.enabledAccountForServer model_.accounts host
                |> Maybe.map AccountsPanel.accountId
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
        , Sub.map AccountsPanelMsg (AccountsPanel.subscriptions model.accountsPanel)
        , Sub.map StarredPostsPanelMsg (StarredPostsPanel.subscriptions model.starredPostsPanel)
        , if model.starredPostsPanel.showStarredPostsPanel then
            Time.every 1500 (\_ -> StarredPostsPanelMsg StarredPostsPanel.PollStarredPosts)

          else
            Sub.none
        ]
