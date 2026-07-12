module UI exposing (layout, page)

import Char
import Effect exposing (Effect)
import Gen.Route as Route exposing (Route(..))
import Html exposing (Attribute, Html, a, button, div, header, img, input, label, main_, nav, span, text)
import Html.Attributes exposing (alt, checked, class, disabled, href, placeholder, src, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Page
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.AdminPanel as AdminPanel
import UI.EmittedStylesheet
import View exposing (View)


{-| Builds a page that has no state of its own beyond the shared auth/account
state, rendered inside the common `layout`. Every page that only needs the nav
and login form (i.e. doesn't need its own Model/Msg) should be built with this.
-}
page : Shared.Model -> Request.With params -> View Shared.Msg -> Page.With () Shared.Msg
page shared req body =
    Page.advanced
        { init = ( (), Effect.none )
        , update = \msg () -> ( (), Effect.fromShared msg )
        , view = \() -> { title = body.title, body = layout shared req.route body.body }
        , subscriptions = \() -> Sub.none
        }


{-| The nav (`header`) is a full-width, sticky band tinted with
`mainFrontendHost`'s `primaryColor` (see `UI.EmittedStylesheet`'s
`background-color-primary` utility class) -- its own `.navbar-inner` wrapper
keeps its content lined up with the (narrower) page content below. `main` gets
its own `.container` so it's centered independently of the nav.
-}
layout : Shared.Model -> Route -> List (Html Shared.Msg) -> List (Html Shared.Msg)
layout shared currentRoute children =
    [ UI.EmittedStylesheet.view shared
    , accountsBackdrop shared
    , header [ classes [ "navbar", shared.accountsPanel.mainFrontendHost, "background-color-primary" ] ]
        [ div [ class "navbar-inner" ]
            [ nav [ class "nav-links" ]
                [ navLink shared currentRoute "Home" Route.Home_
                , navLink shared currentRoute "About" Route.About
                ]
            , div [ class "nav-right" ]
                [ themeToggle shared
                , accountsMenu shared
                , if AccountsPanel.hasAdminAccount shared.accountsPanel then
                    adminMenu shared

                  else
                    text ""
                ]
            ]
        ]
    , div [ class "container" ] [ main_ [] children ]
    ]


{-| Covers everything except the top nav (which sits in its own, higher
stacking context -- see `.navbar` in style.css) with a transitioned blur while
the Accounts Panel is open; clicking it closes the panel. Always rendered,
like `accountsPanel`, so the blur fades rather than snapping in/out, and only
receives clicks (`pointer-events`) while open.
-}
accountsBackdrop : Shared.Model -> Html Shared.Msg
accountsBackdrop shared =
    let
        stateClass =
            if shared.accountsPanel.showAccountsPanel then
                "is-open"

            else
                "is-closed"
    in
    div
        [ classes [ "accounts-backdrop", stateClass ]
        , onClick (Shared.AccountsPanelMsg AccountsPanel.ToggleAccountsPanel)
        ]
        []


{-| Combines several class names into one `class` attribute -- `Html`
attributes of the same kind don't merge, so `[ class "a", class "b" ]` would
just apply "b".
-}
classes : List String -> Attribute msg
classes names =
    class (String.join " " names)


{-| A nav link styled as a button: the current page's link additionally gets
`mainFrontendHost`'s `background-color-nav` utility class, tinting it with
`navColor`/`navTextColor` so it stands out against the `primaryColor`-tinted
navbar around it; other links just inherit that surrounding primary color/text
color by not overriding them.
-}
navLink : Shared.Model -> Route -> String -> Route -> Html msg
navLink shared currentRoute linkLabel linkRoute =
    let
        isCurrent =
            linkRoute == currentRoute
    in
    a
        [ href (Route.toHref linkRoute)
        , classes
            (if isCurrent then
                [ "nav-link", shared.accountsPanel.mainFrontendHost, "background-color-nav" ]

             else
                [ "nav-link" ]
            )
        ]
        [ text linkLabel ]


{-| Cycles Auto -> Light -> Dark -> Auto. "Auto" follows the OS preference
(and reacts live if it changes); "Light"/"Dark" force it.
-}
themeToggle : Shared.Model -> Html Shared.Msg
themeToggle shared =
    let
        icon =
            case shared.themePreference of
                Shared.ThemeAuto ->
                    "🌓"

                Shared.ThemeLight ->
                    "☀️"

                Shared.ThemeDark ->
                    "🌙"
    in
    button
        [ class "theme-toggle"
        , onClick Shared.ThemePreferenceClicked
        , title ("Appearance: " ++ Shared.themePreferenceLabel shared.themePreference ++ " (click to change)")
        ]
        [ text icon ]



-- ACCOUNTS MENU


accountsMenu : Shared.Model -> Html Shared.Msg
accountsMenu shared =
    div [ class "accounts-menu" ]
        [ div [ class "accounts-menu-row" ]
            [ button
                [ class "accounts-menu-toggle"
                , onClick (Shared.AccountsPanelMsg AccountsPanel.ToggleAccountsPanel)
                ]
                [ text (AccountsPanel.accountsMenuLabel shared.accountsPanel) ]
            , hostMismatchWarning shared
            ]
        , accountsPanel shared
        ]


{-| `browsingHost` and `mainFrontendHost` differ when the host we're actually
being viewed from turns out to be a backend-only host with a different public
identity (see `Shared.AccountsPanel`'s `resolvedFrontendHost`) -- worth
flagging, since the user probably has the "wrong" (if working) URL open.
-}
hostMismatchWarning : Shared.Model -> Html msg
hostMismatchWarning shared =
    let
        accountsPanelModel =
            shared.accountsPanel
    in
    if accountsPanelModel.browsingHost /= accountsPanelModel.mainFrontendHost then
        span
            [ class "host-mismatch-warning"
            , title
                ("You're browsing from "
                    ++ accountsPanelModel.browsingHost
                    ++ ", but it's configured to look like "
                    ++ accountsPanelModel.mainFrontendHost
                    ++ ". You should probably just browse from "
                    ++ accountsPanelModel.mainFrontendHost
                    ++ "."
                )
            ]
            [ text "⚠️" ]

    else
        text ""


{-| Servers scroll horizontally in a short strip (there are usually few, and it
keeps them visually distinct from the taller, vertically-scrolling account
list below), which itself scrolls vertically since accounts are the thing
you'll accumulate the most of.

Always rendered (even "closed"), so opening/closing can be a plain CSS
transition (fade + slide) rather than the panel just appearing/disappearing
outright -- see `.accounts-panel`/`.accounts-panel.is-closed` in style.css.
-}
accountsPanel : Shared.Model -> Html Shared.Msg
accountsPanel shared =
    let
        accountsPanelModel =
            shared.accountsPanel

        stateClass =
            if accountsPanelModel.showAccountsPanel then
                "is-open"

            else
                "is-closed"
    in
    div [ classes [ "accounts-panel", stateClass ] ]
        [ serversStrip shared
        , addServerRow accountsPanelModel.mainFrontendHost accountsPanelModel.addServerForm
        , div [ class "panel-divider" ] []
        , accountsList shared
        , div [ class "panel-divider" ] []
        , formView accountsPanelModel.mainFrontendHost accountsPanelModel.accountForm
        ]



-- SERVERS


serversStrip : Shared.Model -> Html Shared.Msg
serversStrip shared =
    div [ class "servers-strip" ]
        (List.map (serverChip shared) shared.accountsPanel.servers)


{-| Top portion (logo/name/host) gets that server's `background-color-primary`
utility classes (see `UI.EmittedStylesheet`); the enable switch and delete
button sit in a bottom portion using `background-color-nav` instead.

When the Server Admin Panel's "switch main server" toggle is on (see
`Shared.AdminPanel`), the top portion also becomes clickable, setting that
server as `mainFrontendHost` instead of doing nothing.
-}
serverChip : Shared.Model -> AccountsPanel.Server -> Html Shared.Msg
serverChip shared server =
    let
        accountsPanelModel =
            shared.accountsPanel

        isMainServer =
            server.frontendHost == accountsPanelModel.mainFrontendHost

        hasAccounts =
            AccountsPanel.serverHasAccounts accountsPanelModel.accounts server.frontendHost

        removable =
            not hasAccounts && not isMainServer

        branding =
            server.branding

        canSelectMain =
            shared.adminPanel.allowMainServerSwitch

        topClasses =
            [ "server-chip-top", server.frontendHost, "background-color-primary" ]
                ++ (if canSelectMain then
                        [ "selectable" ]

                    else
                        []
                   )

        topAttrs =
            classes topClasses
                :: (if canSelectMain then
                        [ onClick (Shared.AccountsPanelMsg (AccountsPanel.MainServerSelected server.frontendHost))
                        , title "Set as main server"
                        ]

                    else
                        []
                   )
    in
    div [ class "server-chip" ]
        [ div topAttrs
            [ logoOrPlaceholder branding
            , div [ class "server-chip-name" ] [ text branding.name ]
            , div [ class "server-chip-host" ] [ text server.frontendHost ]
            , if isMainServer then
                div [ class "server-chip-main-badge" ] [ text "★ Main" ]

              else
                text ""
            ]
        , div [ classes [ "server-chip-bottom", server.frontendHost, "background-color-nav" ] ]
            [ switchInput server.enabled (Shared.AccountsPanelMsg (AccountsPanel.ToggleServerEnabled server.frontendHost))
            , button
                [ class "remove-btn"
                , onClick (Shared.AccountsPanelMsg (AccountsPanel.RemoveServerClicked server.frontendHost))
                , disabled (not removable)
                , title
                    (if isMainServer then
                        "Can't remove the server you're currently browsing from"

                     else if hasAccounts then
                        "Can't remove a server with accounts on it"

                     else
                        "Remove server"
                    )
                ]
                [ text "×" ]
            ]
        ]


logoOrPlaceholder : AccountsPanel.Branding -> Html msg
logoOrPlaceholder branding =
    case branding.logoUrl of
        Just url ->
            img [ class "server-chip-logo", src url, alt branding.name ] []

        Nothing ->
            div [ class "server-chip-logo placeholder" ] [ text (initial branding.name) ]


{-| Adding a server first validates it (fetching its configuration) before it's
added to the list -- so a typo'd or unreachable host shows an error instead of
silently appearing as a dead chip.
-}
addServerRow : String -> AccountsPanel.AddServerForm -> Html Shared.Msg
addServerRow mainFrontendHost form =
    let
        checking =
            form.status == AccountsPanel.Submitting
    in
    div [ class "add-server" ]
        [ div [ class "add-server-row" ]
            [ input
                [ placeholder "Add a server host"
                , value form.host
                , onInput (AccountsPanel.ServerHostInputChanged >> Shared.AccountsPanelMsg)
                , disabled checking
                ]
                []
            , button
                [ onClick (Shared.AccountsPanelMsg AccountsPanel.AddServerClicked)
                , disabled checking
                , classes [ mainFrontendHost, "background-color-nav" ]
                ]
                [ text
                    (if checking then
                        "Checking…"

                     else
                        "Add Server"
                    )
                ]
            ]
        , case form.status of
            AccountsPanel.Errored err ->
                div [ class "auth-error" ] [ text err ]

            _ ->
                text ""
        ]



-- ACCOUNTS


accountsList : Shared.Model -> Html Shared.Msg
accountsList shared =
    if List.isEmpty shared.accountsPanel.accounts then
        div [ class "accounts-empty" ] [ text "No accounts yet." ]

    else
        div [ class "accounts-list" ] (List.map (accountRow shared) shared.accountsPanel.accounts)


{-| The whole row is tinted with the account's server's `background-color-primary`
(background = `primaryColor`, text = `primaryTextColor`, inherited by the
username); the "host | server name" badge underneath it uses
`background-color-nav` instead, layered on top as a normal (not
absolutely-positioned) element now that the row isn't split into bands.
-}
accountRow : Shared.Model -> AccountsPanel.Account -> Html Shared.Msg
accountRow shared account =
    let
        id =
            AccountsPanel.accountId account

        branding =
            AccountsPanel.brandingFor shared.accountsPanel.servers account.server
    in
    div [ classes [ "account-row", account.server, "background-color-primary" ] ]
        [ switchInput account.enabled (Shared.AccountsPanelMsg (AccountsPanel.ToggleAccountEnabled id))
        , avatarOrPlaceholder shared.accountsPanel.servers account
        , div [ class "account-row-label" ]
            [ div [ class "account-row-username" ]
                [ text account.username
                , if AccountsPanel.isAdmin account then
                    span [ class "account-admin-badge", title "Admin on this server" ] [ text "🛡️" ]

                  else
                    text ""
                ]
            , div [ classes [ "account-row-server-badge", account.server, "background-color-nav" ] ]
                [ text (account.server ++ " | " ++ branding.name) ]
            ]
        , button
            [ class "remove-btn"
            , onClick (Shared.AccountsPanelMsg (AccountsPanel.RemoveAccountClicked id))
            ]
            [ text "×" ]
        ]


avatarOrPlaceholder : List AccountsPanel.Server -> AccountsPanel.Account -> Html msg
avatarOrPlaceholder servers account =
    case AccountsPanel.accountAvatarUrl servers account of
        Just url ->
            img [ class "account-avatar", src url, alt account.username ] []

        Nothing ->
            div [ class "account-avatar placeholder" ] [ text (initial account.username) ]


{-| First letter of a name, upper-cased, for use as an avatar/logo placeholder.
-}
initial : String -> String
initial name =
    name
        |> String.trim
        |> String.uncons
        |> Maybe.map (Tuple.first >> Char.toUpper >> String.fromChar)
        |> Maybe.withDefault "?"


{-| A checkbox styled as a toggle switch.
-}
switchInput : Bool -> Shared.Msg -> Html Shared.Msg
switchInput isChecked toggleMsg =
    label [ class "switch" ]
        [ input
            [ type_ "checkbox"
            , checked isChecked
            , onClick toggleMsg
            ]
            []
        , span [ class "slider" ] []
        ]



-- LOGIN FORM


formView : String -> AccountsPanel.AccountForm -> Html Shared.Msg
formView mainFrontendHost form =
    let
        submitting =
            form.status == AccountsPanel.Submitting
    in
    div [ class "account-form" ]
        [ input
            [ placeholder "Server"
            , value form.server
            , onInput (AccountsPanel.ServerChanged >> Shared.AccountsPanelMsg)
            ]
            []
        , input
            [ placeholder "Username"
            , value form.username
            , onInput (AccountsPanel.UsernameChanged >> Shared.AccountsPanelMsg)
            ]
            []
        , input
            [ type_ "password"
            , placeholder "Password"
            , value form.password
            , onInput (AccountsPanel.PasswordChanged >> Shared.AccountsPanelMsg)
            ]
            []
        , div [ class "account-form-buttons" ]
            [ button
                [ onClick (Shared.AccountsPanelMsg AccountsPanel.LoginClicked)
                , disabled submitting
                , classes [ mainFrontendHost, "background-color-primary" ]
                ]
                [ text "Log In" ]
            , button
                [ onClick (Shared.AccountsPanelMsg AccountsPanel.CreateAccountClicked)
                , disabled submitting
                , classes [ mainFrontendHost, "background-color-primary" ]
                ]
                [ text "Create Account" ]
            ]
        , case form.status of
            AccountsPanel.Errored err ->
                div [ class "auth-error" ] [ text err ]

            _ ->
                text ""
        ]



-- ADMIN MENU


{-| Only shown at all when `AccountsPanel.hasAdminAccount` -- see `layout`.
For now just holds the "switch main server" toggle (see `serverChip`); future
admin features land here too.
-}
adminMenu : Shared.Model -> Html Shared.Msg
adminMenu shared =
    div [ class "admin-menu" ]
        [ button
            [ class "accounts-menu-toggle"
            , onClick (Shared.AdminPanelMsg AdminPanel.ToggleAdminPanel)
            , title "Server Admin Panel"
            ]
            [ text "🛡️" ]
        , adminPanel shared
        ]


adminPanel : Shared.Model -> Html Shared.Msg
adminPanel shared =
    let
        stateClass =
            if shared.adminPanel.showAdminPanel then
                "is-open"

            else
                "is-closed"
    in
    div [ classes [ "accounts-panel", "admin-panel", stateClass ] ]
        [ label [ class "admin-switch-row" ]
            [ switchInput shared.adminPanel.allowMainServerSwitch (Shared.AdminPanelMsg AdminPanel.ToggleAllowMainServerSwitch)
            , span [] [ text "Switch main server by tapping servers" ]
            ]
        ]
