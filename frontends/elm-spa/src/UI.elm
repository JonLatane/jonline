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
    case shared.auth of
        Shared.SignedIn account ->
            Html.div [ Attr.class "auth" ]
                [ Html.text ("Signed in as " ++ account.username ++ " @ " ++ account.server)
                , Html.button [ Events.onClick Shared.LogOutClicked ] [ Html.text "Log Out" ]
                ]

        _ ->
            let
                signingIn =
                    shared.auth == Shared.SigningIn
            in
            Html.div [ Attr.class "auth" ]
                [ Html.input
                    [ Attr.placeholder "Server"
                    , Attr.value shared.server
                    , Events.onInput Shared.ServerChanged
                    ]
                    []
                , Html.input
                    [ Attr.placeholder "Username"
                    , Attr.value shared.username
                    , Events.onInput Shared.UsernameChanged
                    ]
                    []
                , Html.input
                    [ Attr.type_ "password"
                    , Attr.placeholder "Password"
                    , Attr.value shared.password
                    , Events.onInput Shared.PasswordChanged
                    ]
                    []
                , Html.button
                    [ Events.onClick Shared.LoginClicked, Attr.disabled signingIn ]
                    [ Html.text "Log In" ]
                , Html.button
                    [ Events.onClick Shared.CreateAccountClicked, Attr.disabled signingIn ]
                    [ Html.text "Create Account" ]
                , case shared.authError of
                    Just err ->
                        Html.div [ Attr.class "auth-error" ] [ Html.text err ]

                    Nothing ->
                        Html.text ""
                ]
