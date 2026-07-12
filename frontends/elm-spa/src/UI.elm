module UI exposing (layout, page)

import Char
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Page
import Request
import Shared
import View exposing (View)


{-| Builds a page that has no state of its own beyond the shared auth/account
state, rendered inside the common `layout`. Every page that only needs the nav
and login form (i.e. doesn't need its own Model/Msg) should be built with this.
-}
page : Shared.Model -> Request.With params -> View Shared.Msg -> Page.With () Shared.Msg
page shared _ body =
    Page.advanced
        { init = ( (), Effect.none )
        , update = \msg () -> ( (), Effect.fromShared msg )
        , view = \() -> { title = body.title, body = layout shared body.body }
        , subscriptions = \() -> Sub.none
        }


layout : Shared.Model -> List (Html Shared.Msg) -> List (Html Shared.Msg)
layout shared children =
    [ Html.div [ Attr.class "container" ]
        [ Html.header [ Attr.class "navbar" ]
            [ Html.nav [ Attr.class "nav-links" ]
                [ viewLink "Home" "/"
                , viewLink "About" "/about"
                ]
            , accountsMenu shared
            ]
        , Html.main_ [] children
        ]
    ]


viewLink : String -> String -> Html msg
viewLink label url =
    Html.a [ Attr.href url ] [ Html.text label ]



-- ACCOUNTS MENU


accountsMenu : Shared.Model -> Html Shared.Msg
accountsMenu shared =
    Html.div [ Attr.class "accounts-menu" ]
        [ Html.button
            [ Attr.class "accounts-menu-toggle"
            , Events.onClick Shared.ToggleAccountsPanel
            ]
            [ Html.text (Shared.accountsMenuLabel shared) ]
        , if shared.showAccountsPanel then
            accountsPanel shared

          else
            Html.text ""
        ]


{-| Servers scroll horizontally in a short strip (there are usually few, and it
keeps them visually distinct from the taller, vertically-scrolling account
list below), which itself scrolls vertically since accounts are the thing
you'll accumulate the most of.
-}
accountsPanel : Shared.Model -> Html Shared.Msg
accountsPanel shared =
    Html.div [ Attr.class "accounts-panel" ]
        [ serversStrip shared.accounts shared.servers
        , addServerRow shared.addServerForm
        , Html.div [ Attr.class "panel-divider" ] []
        , accountsList shared.servers shared.accounts
        , Html.div [ Attr.class "panel-divider" ] []
        , formView shared.accountForm
        ]



-- SERVERS


serversStrip : List Shared.Account -> List Shared.Server -> Html Shared.Msg
serversStrip accounts servers =
    Html.div [ Attr.class "servers-strip" ]
        (List.map (serverChip accounts) servers)


{-| Top portion (logo/name/host) is tinted with the server's primary color;
the enable switch and delete button sit in a bottom portion tinted with its
secondary color -- both use that color's precomputed, readable text color.
-}
serverChip : List Shared.Account -> Shared.Server -> Html Shared.Msg
serverChip accounts server =
    let
        removable =
            not (Shared.serverHasAccounts accounts server.host)

        branding =
            Shared.brandingOf server
    in
    Html.div [ Attr.class "server-chip" ]
        [ Html.div
            [ Attr.class "server-chip-top"
            , Attr.style "background" branding.primary.hex
            , Attr.style "color" branding.primary.contrastText
            ]
            [ logoOrPlaceholder branding
            , Html.div [ Attr.class "server-chip-name" ] [ Html.text branding.name ]
            , Html.div [ Attr.class "server-chip-host" ] [ Html.text server.host ]
            ]
        , Html.div
            [ Attr.class "server-chip-bottom"
            , Attr.style "background" branding.secondary.hex
            , Attr.style "color" branding.secondary.contrastText
            ]
            [ switchInput server.enabled (Shared.ToggleServerEnabled server.host)
            , Html.button
                [ Attr.class "remove-btn"
                , Events.onClick (Shared.RemoveServerClicked server.host)
                , Attr.disabled (not removable)
                , Attr.title
                    (if removable then
                        "Remove server"

                     else
                        "Can't remove a server with accounts on it"
                    )
                ]
                [ Html.text "×" ]
            ]
        ]


logoOrPlaceholder : Shared.Branding -> Html msg
logoOrPlaceholder branding =
    case branding.logoUrl of
        Just url ->
            Html.img [ Attr.class "server-chip-logo", Attr.src url, Attr.alt branding.name ] []

        Nothing ->
            Html.div [ Attr.class "server-chip-logo placeholder" ] [ Html.text (initial branding.name) ]


{-| Adding a server first validates it (fetching its configuration) before it's
added to the list -- so a typo'd or unreachable host shows an error instead of
silently appearing as a dead chip.
-}
addServerRow : Shared.AddServerForm -> Html Shared.Msg
addServerRow form =
    let
        checking =
            form.status == Shared.Submitting
    in
    Html.div [ Attr.class "add-server" ]
        [ Html.div [ Attr.class "add-server-row" ]
            [ Html.input
                [ Attr.placeholder "Add a server host"
                , Attr.value form.host
                , Events.onInput Shared.ServerHostInputChanged
                , Attr.disabled checking
                ]
                []
            , Html.button
                [ Events.onClick Shared.AddServerClicked, Attr.disabled checking ]
                [ Html.text
                    (if checking then
                        "Checking…"

                     else
                        "Add Server"
                    )
                ]
            ]
        , case form.status of
            Shared.Errored err ->
                Html.div [ Attr.class "auth-error" ] [ Html.text err ]

            _ ->
                Html.text ""
        ]



-- ACCOUNTS


accountsList : List Shared.Server -> List Shared.Account -> Html Shared.Msg
accountsList servers accounts =
    if List.isEmpty accounts then
        Html.div [ Attr.class "accounts-empty" ] [ Html.text "No accounts yet." ]

    else
        Html.div [ Attr.class "accounts-list" ] (List.map (accountRow servers) accounts)


{-| The row's background is split into two bands (behind the username/host
text, tinted with the account's server's primary/secondary colors); the
switch, avatar and remove button float in a foreground layer on top of both
bands, each opaque, so they stay put and legible regardless of the bands'
colors underneath.
-}
accountRow : List Shared.Server -> Shared.Account -> Html Shared.Msg
accountRow servers account =
    let
        id =
            Shared.accountId account

        branding =
            Shared.brandingFor servers account.server
    in
    Html.div [ Attr.class "account-row" ]
        [ Html.div [ Attr.class "account-row-bg" ]
            [ Html.div [ Attr.class "account-row-bg-primary", Attr.style "background" branding.primary.hex ] []
            , Html.div [ Attr.class "account-row-bg-secondary", Attr.style "background" branding.secondary.hex ] []
            ]
        , Html.div [ Attr.class "account-row-fg" ]
            [ switchInput account.enabled (Shared.ToggleAccountEnabled id)
            , avatarOrPlaceholder account
            , Html.div [ Attr.class "account-row-label" ]
                [ Html.div
                    [ Attr.class "account-row-username"
                    , Attr.style "color" branding.primary.contrastText
                    ]
                    [ Html.text account.username ]
                , Html.div
                    [ Attr.class "account-row-server"
                    , Attr.style "color" branding.secondary.contrastText
                    ]
                    [ Html.text account.server ]
                ]
            , Html.button [ Attr.class "remove-btn", Events.onClick (Shared.RemoveAccountClicked id) ] [ Html.text "×" ]
            ]
        ]


avatarOrPlaceholder : Shared.Account -> Html msg
avatarOrPlaceholder account =
    case Shared.accountAvatarUrl account of
        Just url ->
            Html.img [ Attr.class "account-avatar", Attr.src url, Attr.alt account.username ] []

        Nothing ->
            Html.div [ Attr.class "account-avatar placeholder" ] [ Html.text (initial account.username) ]


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
    Html.label [ Attr.class "switch" ]
        [ Html.input
            [ Attr.type_ "checkbox"
            , Attr.checked isChecked
            , Events.onClick toggleMsg
            ]
            []
        , Html.span [ Attr.class "slider" ] []
        ]



-- LOGIN FORM


formView : Shared.AccountForm -> Html Shared.Msg
formView form =
    let
        submitting =
            form.status == Shared.Submitting
    in
    Html.div [ Attr.class "account-form" ]
        [ Html.input
            [ Attr.placeholder "Server"
            , Attr.value form.server
            , Events.onInput Shared.ServerChanged
            ]
            []
        , Html.input
            [ Attr.placeholder "Username"
            , Attr.value form.username
            , Events.onInput Shared.UsernameChanged
            ]
            []
        , Html.input
            [ Attr.type_ "password"
            , Attr.placeholder "Password"
            , Attr.value form.password
            , Events.onInput Shared.PasswordChanged
            ]
            []
        , Html.div [ Attr.class "account-form-buttons" ]
            [ Html.button
                [ Events.onClick Shared.LoginClicked, Attr.disabled submitting ]
                [ Html.text "Log In" ]
            , Html.button
                [ Events.onClick Shared.CreateAccountClicked, Attr.disabled submitting ]
                [ Html.text "Create Account" ]
            ]
        , case form.status of
            Shared.Errored err ->
                Html.div [ Attr.class "auth-error" ] [ Html.text err ]

            _ ->
                Html.text ""
        ]
