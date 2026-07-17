module Pages.User.UserId_.Posts exposing (Model, Msg, fromShared, page)

{-| `/user/:id[@host]/posts` -- one user's own posts, looked up by (permanent)
id. Thin wrapper around `Components.Pages.PostsPage`, passing the id straight
through (already known from the route, unlike `Pages.Username_.Posts`) as
`authorUserId` -- mirrors `Pages.User.UserId_`'s own use of
`Components.Pages.UserProfilePage`.
-}

import Components.Pages.PostsPage as PostsPage
import Components.Users as Users
import Effect exposing (Effect)
import Gen.Params.User.UserId_.Posts exposing (Params)
import Page
import Request
import Shared
import UI
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req
        , update = PostsPage.update shared
        , view = view shared req
        , subscriptions = PostsPage.subscriptions
        }



-- MODEL


type alias Model =
    PostsPage.Model


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        ( userId, _ ) =
            Users.parseUserRouteId shared.accountsPanel.mainFrontendHost req.params.userId
    in
    PostsPage.init shared (Just userId)



-- UPDATE


type alias Msg =
    PostsPage.Msg


{-| See `Components.Pages.PostsPage.fromShared` -- lets `Main` notify this
page of `Shared.Msg`s it didn't itself originate, same as
`Pages.User.UserId_.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    PostsPage.fromShared



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared []
    , body = UI.layout shared req.route fromShared [ PostsPage.view shared model ]
    }
