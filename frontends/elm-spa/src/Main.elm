module Main exposing (main)

{-| Customized from `elm-spa`'s generated default (see `.elm-spa/defaults/Main.elm`,
which this was copied from and now overrides -- `.elm-spa/` itself is
gitignored/regenerated, so this is the only place changes here persist).

The only change from the default: this app can be served from `/` or from
`/elm` (see `backend/src/web/elm_web.rs`), so every `Url` gotten from the
browser is normalized (`Shared.normalizeUrl`) before it's handed to
`Gen.Route.fromUrl`/`Request.create`/`Pages.init`, stripping that mount's
`basePath` so routing always sees an app-relative path. `basePath` itself is
detected once, from the very first `Url` (immutable for the session, same as
`Shared.AccountsPanel`'s `browsingHost`), and threaded into `Shared.init` so
view code (`UI.navLink`) can prepend it back onto outgoing hrefs.
-}

import Browser
import Browser.Navigation as Nav exposing (Key)
import Effect
import Gen.Model
import Gen.Pages as Pages
import Gen.Route as Route
import Request
import Shared
import Url exposing (Url)
import View



main : Program Shared.Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        }



-- INIT


type alias Model =
    { url : Url
    , key : Key
    , shared : Shared.Model
    , page : Pages.Model

    -- Detected once from the raw URL `init` was given -- see the module doc.
    , basePath : String
    }


init : Shared.Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        basePath =
            Shared.basePathFromPath url.path

        normalizedUrl =
            Shared.normalizeUrl basePath url

        ( shared, sharedCmd ) =
            Shared.init basePath (Request.create () normalizedUrl key) flags

        ( page, effect ) =
            Pages.init (Route.fromUrl normalizedUrl) shared normalizedUrl key
    in
    ( Model normalizedUrl key shared page basePath
    , Cmd.batch
        [ Cmd.map Shared sharedCmd
        , Effect.toCmd ( Shared, Page ) effect
        ]
    )



-- UPDATE


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | Shared Shared.Msg
    | Page Pages.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink (Browser.Internal url) ->
            ( model
            , Nav.pushUrl model.key (Url.toString url)
            )

        ClickedLink (Browser.External url) ->
            ( model
            , Nav.load url
            )

        ChangedUrl rawUrl ->
            let
                url =
                    Shared.normalizeUrl model.basePath rawUrl
            in
            if url.path /= model.url.path then
                let
                    ( page, effect ) =
                        Pages.init (Route.fromUrl url) model.shared url model.key
                in
                ( { model | url = url, page = page }
                , Effect.toCmd ( Shared, Page ) effect
                )

            else
                ( { model | url = url }, Cmd.none )

        Shared sharedMsg ->
            let
                ( shared, sharedCmd ) =
                    Shared.update (Request.create () model.url model.key) sharedMsg model.shared

                ( page, effect ) =
                    Pages.init (Route.fromUrl model.url) shared model.url model.key
            in
            if page == Gen.Model.Redirecting_ then
                ( { model | shared = shared, page = page }
                , Cmd.batch
                    [ Cmd.map Shared sharedCmd
                    , Effect.toCmd ( Shared, Page ) effect
                    ]
                )

            else
                ( { model | shared = shared }
                , Cmd.map Shared sharedCmd
                )

        Page pageMsg ->
            let
                ( page, effect ) =
                    Pages.update pageMsg model.page model.shared model.url model.key
            in
            ( { model | page = page }
            , Effect.toCmd ( Shared, Page ) effect
            )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    Pages.view model.page model.shared model.url model.key
        |> View.map Page
        |> View.toBrowserDocument



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Pages.subscriptions model.page model.shared model.url model.key |> Sub.map Page
        , Shared.subscriptions (Request.create () model.url model.key) model.shared |> Sub.map Shared
        ]
