module Pages.User.UserId_.Following exposing (Model, Msg, fromShared, page)

{-| `/user/:id[@host]/following` -- the users a user (looked up by
(permanent) id) is following. Mirrors `Pages.User.UserId_.Posts` exactly --
resolves the `User` first via `Components.Users.Resolver` (`Resolver.ById`
instead of `Resolver.ByUsername`), then hands it to `Components.Pages.UsersPage`
(with `UserListingType.FOLLOWING`) instead of `Components.Pages.PostsPage`.
-}

import Components.Pages.UsersPage as UsersPage
import Components.Users as Users
import Components.Users.Resolver as Resolver
import Effect exposing (Effect)
import Gen.Params.User.UserId_.Following exposing (Params)
import Html exposing (p, text)
import Html.Attributes exposing (class)
import Page
import Proto.Jonline.UserListingType exposing (UserListingType(..))
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
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Resolving Resolver.Model
    | Listing UsersPage.Model


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
    | ListingMsg UsersPage.Msg


{-| See `Components.Users.Resolver.fromShared`/`Components.Pages.UsersPage.fromShared`
-- lets `Main` notify this page of `Shared.Msg`s it didn't itself originate,
same as `Pages.User.UserId_.Posts.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared sharedMsg =
    ResolverMsg (Resolver.fromShared sharedMsg)


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case ( msg, model ) of
        ( ResolverMsg subMsg, Resolving resolverModel ) ->
            let
                ( newResolver, resolverEffect ) =
                    Resolver.update shared subMsg resolverModel
            in
            case newResolver.status of
                Resolver.Loaded user ->
                    let
                        ( listingModel, listingEffect ) =
                            UsersPage.init shared (Just ( newResolver.targetHost, user, FOLLOWING ))
                    in
                    ( Listing listingModel, Effect.batch [ Effect.map ResolverMsg resolverEffect, Effect.map ListingMsg listingEffect ] )

                _ ->
                    ( Resolving newResolver, Effect.map ResolverMsg resolverEffect )

        ( ListingMsg subMsg, Listing listingModel ) ->
            UsersPage.update shared subMsg listingModel
                |> Tuple.mapFirst Listing
                |> Tuple.mapSecond (Effect.map ListingMsg)

        ( ResolverMsg subMsg, Listing listingModel ) ->
            -- The resolver has already resolved (see above) -- any further
            -- `SharedMsg` it's forwarded (via `fromShared`) still needs to
            -- reach `UsersPage`, e.g. an `AccountsPanelMsg` it should
            -- re-fetch on, same as `Pages.User.UserId_.Posts` gets directly.
            case subMsg of
                Resolver.SharedMsg sharedMsg ->
                    UsersPage.update shared (UsersPage.fromShared sharedMsg) listingModel
                        |> Tuple.mapFirst Listing
                        |> Tuple.mapSecond (Effect.map ListingMsg)

                _ ->
                    ( model, Effect.none )

        _ ->
            ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Resolving resolverModel ->
            Sub.map ResolverMsg (Resolver.subscriptions resolverModel)

        Listing listingModel ->
            Sub.map ListingMsg (UsersPage.subscriptions listingModel)



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

                Listing listingModel ->
                    Html.map ListingMsg (UsersPage.view shared listingModel)
            ]
    }
