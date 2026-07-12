module Pages.About exposing (Model, Msg, page)

import Gen.Params.About exposing (Params)
import Html exposing (a, p, text)
import Html.Attributes exposing (href)
import Page
import Request
import Shared
import UI


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    UI.page shared
        req
        { title = "About"
        , body =
            [ p [] [ text "Jonline is a federated, decentralized social media platform created by Jon Latané." ]
            , p [] [ text "It's available under the AGPL, with a Rust BE and a new Elm FE,", a [ href "https://github.com/JonLatane/jonline" ] [ text "available on GitHub" ], text ", and it should be easy to deploy yourself." ]
            , p [] [ text "Feel free to", a [ href "mailto:jonlatane@gmail.com" ] [ text "email me" ], text " if you have any questions or want to contribute." ]
            ]
        }


type alias Model =
    ()


type alias Msg =
    Shared.Msg
