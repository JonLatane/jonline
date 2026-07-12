module Shared exposing
    ( Flags
    , Model
    , Msg(..)
    , ThemePreference(..)
    , effectiveDarkMode
    , init
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


type alias Flags =
    Decode.Value


{-| The user's chosen appearance. `Auto` follows `systemPrefersDark`; `Light`/
`Dark` force it regardless of the system.
-}
type ThemePreference
    = ThemeAuto
    | ThemeLight
    | ThemeDark


type alias Model =
    { accountsPanel : AccountsPanel.Model
    , adminPanel : AdminPanel.Model
    , themePreference : ThemePreference
    , systemPrefersDark : Bool
    }


type Msg
    = AccountsPanelMsg AccountsPanel.Msg
    | AdminPanelMsg AdminPanel.Msg
    | ThemePreferenceClicked
    | SystemPrefersDarkChanged Bool


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


{-| `flags` is `{ state, systemPrefersDark, themePreference }` -- see
`index.html`. `state` (the persisted accounts/servers blob) is handed to
`AccountsPanel.init` un-decoded; appearance has its own, separate persisted
key (`themePreference`) so changing it doesn't need to know anything about
`AccountsPanel`'s persisted shape, or vice versa.
-}
init : Request -> Flags -> ( Model, Cmd Msg )
init req flags =
    let
        accountsPanelFlags =
            Decode.decodeValue (Decode.field "state" Decode.value) flags
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
      , themePreference = themePreference
      , systemPrefersDark = systemPrefersDark
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
            in
            ( { model | accountsPanel = subModel }, Cmd.map AccountsPanelMsg subCmd )

        AdminPanelMsg subMsg ->
            ( { model | adminPanel = AdminPanel.update subMsg model.adminPanel }, Cmd.none )

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


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Ports.systemPrefersDarkChanged SystemPrefersDarkChanged
