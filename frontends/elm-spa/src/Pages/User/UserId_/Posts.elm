module Pages.User.UserId_.Posts exposing (Model, Msg, fromShared, page)

{-| `/user/:id[@host]/posts` -- one user's own posts, looked up by (permanent)
id. Resolves the `User` first via `Components.Users.Resolver` (same as
`Pages.Username_.Posts`, just with `Resolver.ById` instead of
`Resolver.ByUsername`) so `Components.Pages.PostsPage` can both filter the
feed by that id and show its "Posts | &lt;name&gt;" heading -- mirrors
`Pages.User.UserId_`'s own use of `Components.Pages.UserProfilePage`.
-}

import Components.Pages.PostsPage as PostsPage
import Components.Users as Users
import Components.Users.Resolver as Resolver
import Effect exposing (Effect)
import Gen.Params.User.UserId_.Posts exposing (Params)
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
    = Resolving Resolver.Model
    | Posts PostsPage.Model


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
    | PostsMsg PostsPage.Msg


{-| See `Components.Users.Resolver.fromShared`/`Components.Pages.PostsPage.fromShared`
-- lets `Main` notify this page of `Shared.Msg`s it didn't itself originate,
same as `Pages.User.UserId_.fromShared`.
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
                            PostsPage.init shared (Just ( newResolver.targetHost, user ))
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

                Posts postsModel ->
                    Html.map PostsMsg (PostsPage.view shared postsModel)
            ]
    }
