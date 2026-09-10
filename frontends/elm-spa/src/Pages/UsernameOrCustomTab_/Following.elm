module Pages.UsernameOrCustomTab_.Following exposing (Model, Msg, fromShared, page)

{-| `/:username[@host]/following` -- the users a user (looked up by
(impermanent) username) is following. Mirrors `Pages.UsernameOrCustomTab_.Posts` exactly
-- first resolving the username to an id via `Components.Users.Resolver`,
then handing the resolved `User` to `Components.Pages.UsersPage` (with
`UserListingType.FOLLOWING`) instead of `Components.Pages.PostsPage`.

Same reserved-username short-circuit as `Pages.UsernameOrCustomTab_`/`Pages.UsernameOrCustomTab_.Posts`
-- see their module docs for why.

`host` starting with `"mastodon:"`/`"bluesky:"` (see `Components.Users.parseFederatedUserId`) skips
the `Resolver` path entirely -- see `Pages.UsernameOrCustomTab_.Followers`'s identical structure/doc,
one direction over, for why Mastodon still needs one local async resolve step
(`ResolvingMastodonAccount`) and Bluesky doesn't.

-}

import Components.Pages.UsersPage as UsersPage
import Components.Users as Users
import Components.Users.Resolver as Resolver
import Effect exposing (Effect)
import Gen.Params.UsernameOrCustomTab_.Following exposing (Params)
import Html exposing (p, text)
import Html.Attributes exposing (class)
import Http
import Page
import Proto.Rellm.UserListingType exposing (UserListingType(..))
import Request
import Shared
import Shared.Federation.Mastodon as Mastodon
import Task
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


type Model
    = Reserved String
    | Resolving Resolver.Model
    | ResolvingMastodonAccount { instanceHost : String, username : String }
    | Listing UsersPage.Model


type Msg
    = ResolverMsg Resolver.Msg
    | GotMastodonAccount String (Result Http.Error Mastodon.Account)
    | ListingMsg UsersPage.Msg


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        ( username, targetHost ) =
            Users.parseUserRouteId shared.accounts.mainFrontendHost req.params.usernameOrCustomTab
    in
    case Users.parseFederatedUserId username targetHost of
        Just (Users.MastodonUserId mastodonUser) ->
            ( ResolvingMastodonAccount mastodonUser
            , Mastodon.lookupAccount mastodonUser.instanceHost mastodonUser.username
                |> Task.attempt (GotMastodonAccount mastodonUser.instanceHost)
                |> Effect.fromCmd
            )

        Just (Users.BlueskyUserId { handle }) ->
            UsersPage.init shared
                Nothing
                (Just (UsersPage.BlueskyAccountTarget { handle = handle } UsersPage.FederatedFollowing))
                req.key
                req.url.path
                req.query
                |> Tuple.mapFirst Listing
                |> Tuple.mapSecond (Effect.map ListingMsg)

        Nothing ->
            if Users.isReservedUsername username then
                ( Reserved username, Effect.none )

            else
                Resolver.init shared targetHost (Resolver.ByUsername username)
                    |> Tuple.mapFirst Resolving
                    |> Tuple.mapSecond (Effect.map ResolverMsg)


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Resolving resolverModel ->
            Sub.map ResolverMsg (Resolver.subscriptions resolverModel)

        ResolvingMastodonAccount _ ->
            Sub.none

        Listing listingModel ->
            Sub.map ListingMsg (UsersPage.subscriptions listingModel)

        Reserved _ ->
            Sub.none


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
                            UsersPage.init shared (Just ( newResolver.targetHost, user, FOLLOWING )) Nothing req.key req.url.path req.query
                    in
                    ( Listing listingModel, Effect.batch [ Effect.map ResolverMsg resolverEffect, Effect.map ListingMsg listingEffect ] )

                _ ->
                    ( Resolving newResolver, Effect.map ResolverMsg resolverEffect )

        ( GotMastodonAccount instanceHost (Ok account), ResolvingMastodonAccount _ ) ->
            UsersPage.init shared
                Nothing
                (Just (UsersPage.MastodonAccountTarget { instanceHost = instanceHost, accountId = account.id, username = account.username } UsersPage.FederatedFollowing))
                req.key
                req.url.path
                req.query
                |> Tuple.mapFirst Listing
                |> Tuple.mapSecond (Effect.map ListingMsg)

        ( GotMastodonAccount _ (Err _), ResolvingMastodonAccount { username } ) ->
            ( Reserved username, Effect.none )

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

        -- `ResolvingMastodonAccount` has no `Resolver` of its own -- see
        -- `Pages.UsernameOrCustomTab_.Followers`'s identical catch-all doc.
        ( ResolverMsg (Resolver.SharedMsg sharedMsg), ResolvingMastodonAccount _ ) ->
            ( model, Effect.fromShared sharedMsg )

        _ ->
            ( model, Effect.none )


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

                ResolvingMastodonAccount _ ->
                    p [ class "posts-empty" ] [ text "Loading…" ]

                Listing listingModel ->
                    Html.map ListingMsg (UsersPage.view shared listingModel)
            ]
    }


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page --
see `Components.Users.Resolver.fromShared`/`Components.Pages.UsersPage.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared sharedMsg =
    ResolverMsg (Resolver.fromShared sharedMsg)
