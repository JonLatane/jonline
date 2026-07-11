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
            [ viewLink "Home" "/"
            , viewLink "About" "/about"
            ]
        , authView shared
        , Html.main_ [] children
        ]
    ]


viewLink : String -> String -> Html msg
viewLink label url =
    Html.a [ Attr.href url ] [ Html.text label ]


authView : Shared.Model -> Html Shared.Msg
authView shared =
    Html.div [ Attr.class "auth" ]
        [ accountsView shared.accounts
        , serversView shared.servers
        , formView shared.accountForm
        ]


accountsView : List Shared.Account -> Html Shared.Msg
accountsView accounts =
    if List.isEmpty accounts then
        Html.text ""

    else
        Html.ul [ Attr.class "accounts" ] (List.map accountItem accounts)


accountItem : Shared.Account -> Html Shared.Msg
accountItem account =
    let
        id =
            Shared.accountId account
    in
    Html.li []
        [ Html.label []
            [ Html.input
                [ Attr.type_ "checkbox"
                , Attr.checked account.enabled
                , Events.onClick (Shared.ToggleAccountEnabled id)
                ]
                []
            , Html.text (" " ++ account.username ++ " @ " ++ account.server)
            ]
        , Html.button [ Events.onClick (Shared.RemoveAccountClicked id) ] [ Html.text "Remove" ]
        ]


serversView : List Shared.Server -> Html Shared.Msg
serversView servers =
    if List.isEmpty servers then
        Html.text ""

    else
        Html.ul [ Attr.class "servers" ] (List.map serverItem servers)


serverItem : Shared.Server -> Html Shared.Msg
serverItem server =
    Html.li []
        [ Html.label []
            [ Html.input
                [ Attr.type_ "checkbox"
                , Attr.checked server.enabled
                , Events.onClick (Shared.ToggleServerEnabled server.host)
                ]
                []
            , Html.text (" " ++ server.host)
            ]
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
        , Html.button
            [ Events.onClick Shared.LoginClicked, Attr.disabled submitting ]
            [ Html.text "Log In" ]
        , Html.button
            [ Events.onClick Shared.CreateAccountClicked, Attr.disabled submitting ]
            [ Html.text "Create Account" ]
        , case form.status of
            Shared.Errored err ->
                Html.div [ Attr.class "auth-error" ] [ Html.text err ]

            _ ->
                Html.text ""
        ]
