module Pages.User.UserId_ exposing (Model, Msg, fromShared, page)

{-| `/user/:id[@host]` -- a user profile looked up by (permanent) id, on
`mainFrontendHost` or, with an `@host` suffix, some other federated server.
Thin wrapper around `Components.UserProfilePage`, which does all the actual
work -- mirrors `Pages.Post.PostId_`. See `Pages.Username_` for the
`/:username[@host]` counterpart.
-}

import Components.UserProfilePage as UserProfilePage
import Components.Users as Users
import Effect exposing (Effect)
import Gen.Params.User.UserId_ exposing (Params)
import Page
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
import UI
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req
        , update = UserProfilePage.update shared
        , view = view shared req
        , subscriptions = UserProfilePage.subscriptions
        }



-- MODEL


type alias Model =
    UserProfilePage.Model


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        ( userId, targetHost ) =
            Users.parseUserRouteId shared.accountsPanel.mainFrontendHost req.params.userId
    in
    UserProfilePage.init shared (AccountsPanel.isSecure req) targetHost (UserProfilePage.ById userId)



-- UPDATE


type alias Msg =
    UserProfilePage.Msg


{-| See `Components.UserProfilePage.fromShared` -- lets `Main` notify this
page of `Shared.Msg`s it didn't itself originate (e.g. a server reconnecting
at startup), same as `Pages.Post.PostId_.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    UserProfilePage.fromShared



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared [ UserProfilePage.titleFor model ]
    , body = UI.layout shared req.route fromShared [ UserProfilePage.view shared model ]
    }
