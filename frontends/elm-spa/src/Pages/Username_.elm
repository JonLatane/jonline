module Pages.Username_ exposing (Model, Msg, fromShared, page)

{-| `/:username[@host]` -- a user profile looked up by (impermanent) username,
on `mainFrontendHost` or, with an `@host` suffix, some other federated
server. The top-level catch-all this implies means any username colliding
with this app's own routes (or the `/user`/`/post` prefixes) can never be
reached this way -- see `Components.Users.isReservedUsername`, checked here
before `Components.UserProfilePage` (which does the actual fetching/rendering,
same as `Pages.User.UserId_`) is ever involved. Those usernames are still
reachable via `/user/:id[@host]`.
-}

import Components.UserProfilePage as UserProfilePage
import Components.Users as Users
import Effect exposing (Effect)
import Gen.Params.Username_ exposing (Params)
import Html exposing (p, text)
import Html.Attributes exposing (class)
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
        , update = update shared
        , view = view shared req
        , subscriptions = subscriptions
        }



-- MODEL


{-| `Reserved` short-circuits straight to a "not a user" message, without ever
constructing a `UserProfilePage.Model` (and thus without ever attempting a
fetch) -- see the module doc.
-}
type Model
    = Reserved String
    | Profile UserProfilePage.Model


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        ( username, targetHost ) =
            Users.parseUserRouteId shared.accountsPanel.mainFrontendHost req.params.username
    in
    if Users.isReservedUsername username then
        ( Reserved username, Effect.none )

    else
        UserProfilePage.init shared (AccountsPanel.isSecure req) targetHost (UserProfilePage.ByUsername username)
            |> Tuple.mapFirst Profile
            |> Tuple.mapSecond (Effect.map ProfileMsg)



-- UPDATE


type Msg
    = ProfileMsg UserProfilePage.Msg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared (ProfileMsg subMsg) model =
    case model of
        Profile subModel ->
            UserProfilePage.update shared subMsg subModel
                |> Tuple.mapFirst Profile
                |> Tuple.mapSecond (Effect.map ProfileMsg)

        Reserved _ ->
            ( model, Effect.none )


{-| See `Components.UserProfilePage.fromShared` -- a no-op for a `Reserved`
page, which never fetches anything to begin with.
-}
fromShared : Shared.Msg -> Msg
fromShared sharedMsg =
    ProfileMsg (UserProfilePage.fromShared sharedMsg)


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Profile subModel ->
            Sub.map ProfileMsg (UserProfilePage.subscriptions subModel)

        Reserved _ ->
            Sub.none



-- VIEW


titleFor : Model -> String
titleFor model =
    case model of
        Profile subModel ->
            UserProfilePage.titleFor subModel

        Reserved _ ->
            "Not Found"


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared [ titleFor model ]
    , body =
        UI.layout shared
            req.route
            fromShared
            [ case model of
                Profile subModel ->
                    Html.map ProfileMsg (UserProfilePage.view shared subModel)

                Reserved username ->
                    p [ class "profile-error" ] [ text ("\"" ++ username ++ "\" isn't a user.") ]
            ]
    }
