module Pages.Home_ exposing (Model, Msg, page)

import Gen.Params.Home_ exposing (Params)
import Html exposing (text)
import Page
import Request
import Shared
import UI


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    UI.page shared
        req
        { title = "Homepage"
        , body = [ text "This is the Jonline home page. Intially I just wanna get auth right, and displaying a Post for demo purposes." ]
        }


type alias Model =
    ()


type alias Msg =
    Shared.Msg
