module Pages.Home_ exposing (Model, Msg, fromShared, page)

{-| `/` -- recent posts from every enabled server. Thin wrapper around
`Components.Pages.PostsPage`, which does all the actual work -- mirrors
`Pages.User.UserId_`/`Pages.Username_.Posts`' own use of that module, except
this page adds its own "Recent Posts" heading and passes `authorUserId =
Nothing` (an unfiltered feed, rather than one user's own posts).
-}

import Components.Pages.PostsPage as PostsPage
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
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
        , update = PostsPage.update shared
        , view = view shared req
        , subscriptions = PostsPage.subscriptions
        }



-- MODEL


type alias Model =
    PostsPage.Model


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    PostsPage.init shared Nothing



-- UPDATE


type alias Msg =
    PostsPage.Msg


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page --
see `Components.Pages.PostsPage.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    PostsPage.fromShared



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared []
    , body =
        UI.layout shared
            req.route
            fromShared
            [ h2 [] [ text "Recent Posts" ]
            , PostsPage.view shared model
            ]
    }
