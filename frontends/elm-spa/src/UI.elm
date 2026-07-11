module UI exposing (layout, page)

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
        , addServerRow shared.serverHostInput
        , Html.div [ Attr.class "panel-divider" ] []
        , accountsList shared.accounts
        , Html.div [ Attr.class "panel-divider" ] []
        , formView shared.accountForm
        ]


serversStrip : List Shared.Account -> List Shared.Server -> Html Shared.Msg
serversStrip accounts servers =
    Html.div [ Attr.class "servers-strip" ]
        (List.map (serverChip accounts) servers)


serverChip : List Shared.Account -> Shared.Server -> Html Shared.Msg
serverChip accounts server =
    let
        removable =
            not (Shared.serverHasAccounts accounts server.host)
    in
    Html.div [ Attr.class "server-chip" ]
        [ switchInput server.enabled (Shared.ToggleServerEnabled server.host)
        , Html.div [ Attr.class "server-chip-host" ] [ Html.text server.host ]
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


addServerRow : String -> Html Shared.Msg
addServerRow hostInput =
    Html.div [ Attr.class "add-server" ]
        [ Html.input
            [ Attr.placeholder "Add a server host"
            , Attr.value hostInput
            , Events.onInput Shared.ServerHostInputChanged
            ]
            []
        , Html.button [ Events.onClick Shared.AddServerClicked ] [ Html.text "Add Server" ]
        ]


accountsList : List Shared.Account -> Html Shared.Msg
accountsList accounts =
    if List.isEmpty accounts then
        Html.div [ Attr.class "accounts-empty" ] [ Html.text "No accounts yet." ]

    else
        Html.div [ Attr.class "accounts-list" ] (List.map accountRow accounts)


accountRow : Shared.Account -> Html Shared.Msg
accountRow account =
    let
        id =
            Shared.accountId account
    in
    Html.div [ Attr.class "account-row" ]
        [ switchInput account.enabled (Shared.ToggleAccountEnabled id)
        , Html.div [ Attr.class "account-row-label" ]
            [ Html.div [ Attr.class "account-row-username" ] [ Html.text account.username ]
            , Html.div [ Attr.class "account-row-server" ] [ Html.text account.server ]
            ]
        , Html.button [ Attr.class "remove-btn", Events.onClick (Shared.RemoveAccountClicked id) ] [ Html.text "×" ]
        ]


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
