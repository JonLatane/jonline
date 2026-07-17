module Pages.Username_.Posts exposing (Model, Msg, fromShared, page)

{-| `/:username[@host]/posts` -- one user's own posts, looked up by
(impermanent) username. `GetPostsRequest.authorUserId` needs the user's
actual id, which the route doesn't have directly (unlike
`Pages.User.UserId_.Posts`), so this page first resolves the username to an
id via `Components.Users.Resolver` (the same resolution machinery
`Components.Pages.UserProfilePage` uses internally, minus that module's
connect-to-server UI or profile-editing state, none of which this page needs)
before handing that id to `Components.Pages.PostsPage`.

Same reserved-username short-circuit as `Pages.Username_` -- see its module
doc for why.

-}

import Components.Pages.PostsPage as PostsPage
import Components.Users as Users
import Components.Users.Resolver as Resolver
import Effect exposing (Effect)
import Gen.Params.Username_.Posts exposing (Params)
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
        , update = update shared
        , view = view shared req
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Reserved String
    | Resolving Resolver.Model
    | Posts PostsPage.Model


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
    | PostsMsg PostsPage.Msg


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page --
see `Components.Users.Resolver.fromShared`/`Components.Pages.PostsPage.fromShared`.
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
                        ( postsModel, postsEffect ) =
                            PostsPage.init shared (Just user.id)
                    in
                    ( Posts postsModel, Effect.batch [ Effect.map ResolverMsg resolverEffect, Effect.map PostsMsg postsEffect ] )

                _ ->
                    ( Resolving newResolver, Effect.map ResolverMsg resolverEffect )

        ( PostsMsg subMsg, Posts postsModel ) ->
            PostsPage.update shared subMsg postsModel
                |> Tuple.mapFirst Posts
                |> Tuple.mapSecond (Effect.map PostsMsg)

        ( ResolverMsg subMsg, Posts postsModel ) ->
            -- The resolver has already resolved (see above) -- any further
            -- `SharedMsg` it's forwarded (via `fromShared`) still needs to
            -- reach `PostsPage`, e.g. an `AccountsPanelMsg` it should
            -- re-fetch on, same as `Pages.Home_` gets directly.
            case subMsg of
                Resolver.SharedMsg sharedMsg ->
                    PostsPage.update shared (PostsPage.fromShared sharedMsg) postsModel
                        |> Tuple.mapFirst Posts
                        |> Tuple.mapSecond (Effect.map PostsMsg)

                _ ->
                    ( model, Effect.none )

        _ ->
            ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Resolving resolverModel ->
            Sub.map ResolverMsg (Resolver.subscriptions resolverModel)

        Posts postsModel ->
            Sub.map PostsMsg (PostsPage.subscriptions postsModel)

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

                Posts postsModel ->
                    Html.map PostsMsg (PostsPage.view shared postsModel)
            ]
    }
