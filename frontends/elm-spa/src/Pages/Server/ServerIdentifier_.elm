module Pages.Server.ServerIdentifier_ exposing (Model, Msg, fromShared, page)

{-| `/server/:serverIdentifier` -- a read-only detail page for a Jonline
server, identified by a `[http|https]:hostname` route segment (e.g.
"http:localhost", "https:jonline.io" -- no slashes, since this is a single
route param; mirrors the Tamagui app's `server_details_screen.tsx`, which
parses its own `id` route param the same way). Thin wrapper around
`Components.Pages.ServerInformationPage`, which does all the actual work --
mirrors `Pages.Username_`'s own `Reserved`/`Profile` split around
`Components.Pages.UserProfilePage`, for the same reason: parsing the route
segment can fail (an ill-formed identifier) in a way that has nothing to do
with that shared module, so it's handled here instead, before that module's
`Model` is ever constructed.
-}

import Components.Pages.ServerInformationPage as ServerInformationPage
import Effect exposing (Effect)
import Gen.Params.Server.ServerIdentifier_ exposing (Params)
import Html exposing (div, p, text)
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
        { init = init shared req.params
        , update = update shared
        , view = view shared req
        , subscriptions = subscriptions
        }



-- MODEL


{-| `Invalid` short-circuits straight to an error message, without ever
constructing a `ServerInformationPage.Model` (and thus without ever
attempting a connection) -- see the module doc.
-}
type Model
    = Invalid String
    | Info ServerInformationPage.Model


{-| Parses a `/server/:serverIdentifier` route segment like "http:localhost"
or "https:jonline.io" -- `Nothing` if it isn't exactly `[http|https]:host`
(no slashes, no port -- `AccountsPanel.connectToServer` discovers the actual
port/backend host itself).
-}
parseServerIdentifier : String -> Maybe { isSecure : Bool, host : String }
parseServerIdentifier identifier =
    case String.split ":" identifier of
        [ "http", host ] ->
            Just { isSecure = False, host = host }

        [ "https", host ] ->
            Just { isSecure = True, host = host }

        _ ->
            Nothing


init : Shared.Model -> Params -> ( Model, Effect Msg )
init shared params =
    case parseServerIdentifier params.serverIdentifier of
        Nothing ->
            ( Invalid params.serverIdentifier
            , Effect.fromShared (Shared.AccountsPanelMsg AccountsPanel.CloseAccountsPanel)
            )

        Just parsed ->
            ServerInformationPage.init shared parsed.isSecure parsed.host
                |> Tuple.mapFirst Info
                |> Tuple.mapSecond (Effect.map InfoMsg)



-- UPDATE


type Msg
    = InfoMsg ServerInformationPage.Msg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared (InfoMsg subMsg) model =
    case model of
        Info subModel ->
            ServerInformationPage.update shared subMsg subModel
                |> Tuple.mapFirst Info
                |> Tuple.mapSecond (Effect.map InfoMsg)

        Invalid _ ->
            ( model, Effect.none )


{-| See `Components.Pages.ServerInformationPage.fromShared` -- a no-op for an
`Invalid` page, which never fetches anything to begin with.
-}
fromShared : Shared.Msg -> Msg
fromShared sharedMsg =
    InfoMsg (ServerInformationPage.fromShared sharedMsg)


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Info subModel ->
            Sub.map InfoMsg (ServerInformationPage.subscriptions subModel)

        Invalid _ ->
            Sub.none



-- VIEW


titleFor : Shared.Model -> Model -> String
titleFor shared model =
    case model of
        Info subModel ->
            ServerInformationPage.titleFor shared subModel

        Invalid identifier ->
            identifier


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared [ titleFor shared model ]
    , body =
        UI.layout shared
            req.route
            fromShared
            [ case model of
                Info subModel ->
                    Html.map InfoMsg (ServerInformationPage.view shared subModel)

                Invalid identifier ->
                    div [ class "server-details-error" ]
                        [ p [] [ text ("\"" ++ identifier ++ "\" isn't a valid server identifier.") ]
                        , p [] [ text "Server identifiers look like http:hostname or https:hostname, e.g. https:jonline.io." ]
                        ]
            ]
    }
