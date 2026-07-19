module Pages.People exposing (Model, Msg, fromShared, page)

{-| `/people` -- every user visible on each enabled server
(`UserListingType.EVERYONE`). Thin wrapper around `Components.Pages.UsersPage`,
which does all the actual work -- mirrors `Pages.Home_`'s own use of
`Components.Pages.PostsPage`, except this passes `target = Nothing` to browse
every user rather than filtering by one user's own relationships.
-}

import Components.Pages.UsersPage as UsersPage
import Effect exposing (Effect)
import Gen.Params.People exposing (Params)
import Html exposing (h2, text)
import Page
import Request
import Shared
import UI
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared
        , update = UsersPage.update shared
        , view = view shared req
        , subscriptions = UsersPage.subscriptions
        }



-- MODEL


type alias Model =
    UsersPage.Model


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    UsersPage.init shared Nothing



-- UPDATE


type alias Msg =
    UsersPage.Msg


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page --
see `Components.Pages.UsersPage.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    UsersPage.fromShared



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared [ "People" ]
    , body =
        UI.layout shared
            req.route
            fromShared
            [ h2 [] [ text "People" ]
            , UsersPage.view shared model
            ]
    }
