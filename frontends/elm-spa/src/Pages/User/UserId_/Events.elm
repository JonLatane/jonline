module Pages.User.UserId_.Events exposing (Model, Msg, fromShared, page)

{-| `/user/:id[@host]/events` -- one user's own events, looked up by
(permanent) id. Resolves the `User` first via `Components.Users.Resolver`
(same as `Pages.Username_.Events`, just with `Resolver.ById` instead of
`Resolver.ByUsername`) so `Components.Pages.EventsPage` can filter the feed by
that id and show its "Events | &lt;name&gt;" heading -- mirrors
`Pages.User.UserId_.Posts`'s own use of `Components.Pages.PostsPage`.
-}

import Components.Pages.EventsPage as EventsPage
import Components.Users as Users
import Components.Users.Resolver as Resolver
import Effect exposing (Effect)
import Gen.Params.User.UserId_.Events exposing (Params)
import Html exposing (p, text)
import Html.Attributes exposing (class)
import Page
import Request
import Shared
import UI
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req
        , update = update shared req
        , view = view shared req
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Resolving Resolver.Model
    | Events EventsPage.Model


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        ( userId, targetHost ) =
            Users.parseUserRouteId shared.accountsPanel.mainFrontendHost req.params.userId
    in
    Resolver.init shared targetHost (Resolver.ById userId)
        |> Tuple.mapFirst Resolving
        |> Tuple.mapSecond (Effect.map ResolverMsg)



-- UPDATE


type Msg
    = ResolverMsg Resolver.Msg
    | EventsMsg EventsPage.Msg


{-| See `Components.Users.Resolver.fromShared`/`Components.Pages.EventsPage.fromShared`
-- lets `Main` notify this page of `Shared.Msg`s it didn't itself originate,
same as `Pages.User.UserId_.Posts.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared sharedMsg =
    ResolverMsg (Resolver.fromShared sharedMsg)


update : Shared.Model -> Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
update shared req msg model =
    case ( msg, model ) of
        ( ResolverMsg subMsg, Resolving resolverModel ) ->
            let
                ( newResolver, resolverEffect ) =
                    Resolver.update shared subMsg resolverModel
            in
            case newResolver.status of
                Resolver.Loaded user ->
                    let
                        ( eventsModel, eventsEffect ) =
                            EventsPage.init shared (Just ( newResolver.targetHost, user )) req.key req.url.path req.query
                    in
                    ( Events eventsModel, Effect.batch [ Effect.map ResolverMsg resolverEffect, Effect.map EventsMsg eventsEffect ] )

                _ ->
                    ( Resolving newResolver, Effect.map ResolverMsg resolverEffect )

        ( EventsMsg subMsg, Events eventsModel ) ->
            EventsPage.update shared subMsg eventsModel
                |> Tuple.mapFirst Events
                |> Tuple.mapSecond (Effect.map EventsMsg)

        ( ResolverMsg subMsg, Events eventsModel ) ->
            -- The resolver has already resolved (see above) -- any further
            -- `SharedMsg` it's forwarded (via `fromShared`) still needs to
            -- reach `EventsPage`, e.g. an `AccountsPanelMsg` it should
            -- re-fetch on, same as `Pages.User.UserId_.Posts` handles.
            case subMsg of
                Resolver.SharedMsg sharedMsg ->
                    EventsPage.update shared (EventsPage.fromShared sharedMsg) eventsModel
                        |> Tuple.mapFirst Events
                        |> Tuple.mapSecond (Effect.map EventsMsg)

                _ ->
                    ( model, Effect.none )

        _ ->
            ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Resolving resolverModel ->
            Sub.map ResolverMsg (Resolver.subscriptions resolverModel)

        Events eventsModel ->
            Sub.map EventsMsg (EventsPage.subscriptions eventsModel)



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared []
    , body =
        UI.layout shared
            req.route
            fromShared
            [ case model of
                Resolving _ ->
                    p [ class "posts-empty" ] [ text "Loading…" ]

                Events eventsModel ->
                    Html.map EventsMsg (EventsPage.view shared False eventsModel)
            ]
    }
