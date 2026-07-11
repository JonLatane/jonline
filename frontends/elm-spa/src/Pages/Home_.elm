module Pages.Home_ exposing (Model, Msg, page)

import Gen.Params.Home_ exposing (Params)
import Html
import Page
import Request
import Shared
import UI


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    UI.page shared
        req
        { title = "Homepage"
        , body = [ Html.text "This is the Jonline home page. Probably still need to do more stuff here!" ]
        }


type alias Model =
    ()


type alias Msg =
    Shared.Msg
