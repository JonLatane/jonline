module Pages.About exposing (Model, Msg, page)

import Gen.Params.About exposing (Params)
import Html
import Page
import Request
import Shared
import UI


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    UI.page shared
        req
        { title = "About"
        , body = [ Html.text "This is the Jonline home page. Probably still need to do more stuff here!" ]
        }


type alias Model =
    ()


type alias Msg =
    Shared.Msg
