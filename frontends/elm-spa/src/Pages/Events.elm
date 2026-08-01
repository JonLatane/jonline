module Pages.Events exposing (Model, Msg, fromShared, page)

{-| `/events` -- upcoming events from every enabled server. Thin wrapper
around `Components.Pages.EventsPage`, which does all the actual work --
mirrors `Pages.Home_`'s own use of `Components.Pages.PostsPage`, except this
page passes `author = Nothing` (an unfiltered feed, rather than one user's
own events) and needs no heading of its own -- `EventsPage.view`'s own
"Upcoming Events"/"Events After <date>" tabs (see `tabsView`) already
say what this listing is.
-}

import Components.Pages.EventsPage as EventsPage
import Effect exposing (Effect)
import Gen.Params.Events exposing (Params)
import Page
import Request
import Shared
import UI
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req
        , update = update shared
        , view = view shared req
        , subscriptions = EventsPage.subscriptions
        }



-- MODEL


type alias Model =
    EventsPage.Model


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    EventsPage.init shared Nothing req.key req.url.path req.query False



-- UPDATE


type alias Msg =
    EventsPage.Msg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    EventsPage.update shared msg model


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page --
see `Components.Pages.EventsPage.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    EventsPage.fromShared



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared []
    , body =
        UI.layout shared
            req.route
            fromShared
            [ EventsPage.view shared False True model ]
    }
