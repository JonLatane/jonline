module Pages.Username_.Followers exposing (Model, Msg, fromShared, page)

{-| `/:username[@host]/followers` -- the users following a user (looked up by
(impermanent) username). Mirrors `Pages.Username_.Posts` exactly
-- first resolving the username to an id via `Components.Users.Resolver`,
then handing the resolved `User` to `Components.Pages.UsersPage` (with
`UserListingType.FOLLOWERS`) instead of `Components.Pages.PostsPage`.

Same reserved-username short-circuit as `Pages.Username_`/`Pages.Username_.Posts`
-- see their module docs for why.

-}

import Components.Pages.UsersPage as UsersPage
import Components.Users as Users
import Components.Users.Resolver as Resolver
import Effect exposing (Effect)
import Gen.Params.Username_.Followers exposing (Params)
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
        , update = update shared req
        , view = view shared req
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Reserved String
    | Resolving Resolver.Model
    | Listing UsersPage.Model


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        ( username, targetHost ) =
            Users.parseUserRouteId shared.accountsPanel.mainFrontendHost req.params.username
    in
    if Users.isReservedUsername username then
        ( Reserved username, Effect.none )

    else
        Resolver.init shared targetHost (Resolver.ByUsername username)
            |> Tuple.mapFirst Resolving
            |> Tuple.mapSecond (Effect.map ResolverMsg)



-- UPDATE


type Msg
    = ResolverMsg Resolver.Msg
    | ListingMsg UsersPage.Msg


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page --
see `Components.Users.Resolver.fromShared`/`Components.Pages.UsersPage.fromShared`.
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
                        ( listingModel, listingEffect ) =
                            UsersPage.init shared (Just ( newResolver.targetHost, user, FOLLOWERS )) req.key req.url.path req.query
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
            -- re-fetch on.
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

        Reserved _ ->
            Sub.none



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared []
    , body =
        UI.layout shared
            req.route
            fromShared
            [ case model of
                Reserved username ->
                    p [ class "profile-error" ] [ text ("\"" ++ username ++ "\" isn't a user.") ]

                Resolving _ ->
                    p [ class "posts-empty" ] [ text "Loading…" ]

                Listing listingModel ->
                    Html.map ListingMsg (UsersPage.view shared listingModel)
            ]
    }
