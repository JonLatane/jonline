module Pages.Username_.Posts exposing (Model, Msg, fromShared, page)

{-| `/:username[@host]/posts` -- one user's own posts, looked up by
(impermanent) username. `GetPostsRequest.authorUserId` needs the user's
actual id, which the route doesn't have directly (unlike
`Pages.User.UserId_.Posts`), so this page first resolves the username to an
id (a small `GetUsers` fetch, mirroring `Components.Pages.UserProfilePage`'s
own `fetchIfReady`/`fetchTask`, but without that module's connect-to-server
UI or profile-editing state, none of which this page needs) before handing
that id to `Components.Pages.PostsPage`.

Same reserved-username short-circuit as `Pages.Username_` -- see its module
doc for why.

-}

import Components.Pages.PostsPage as PostsPage
import Components.Users as Users
import Effect exposing (Effect)
import Gen.Params.Username_.Posts exposing (Params)
import Grpc
import Html exposing (p, text)
import Html.Attributes exposing (class)
import Page
import Proto.Jonline
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
import Task
import Time
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


{-| `fetchStarted` is only ever `True` while the `GetUsers` fetch it guards is
in flight -- a failure (or the target server not being connected yet) resets
it to `False`, so `subscriptions`' poll (and any `AccountsPanelMsg`, via
`update`'s `SharedMsg` branch) retries, mirroring
`Components.Pages.UserProfilePage.fetchIfReady`.
-}
type alias ResolveState =
    { username : String
    , targetHost : String
    , fetchStarted : Bool
    }


type Model
    = Reserved String
    | Resolving ResolveState
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
        fetchIfReady shared { username = username, targetHost = targetHost, fetchStarted = False }


{-| The `GetUsers` fetch task for `state.username`/`state.targetHost`, if that
host is currently a known, connected server -- mirrors
`Components.Pages.UserProfilePage.fetchTask`.
-}
fetchTask : Shared.Model -> ResolveState -> Maybe (Task.Task Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetUsersResponse ))
fetchTask shared state =
    AccountsPanel.serverForHost shared.accountsPanel.servers state.targetHost
        |> Maybe.map
            (\_ ->
                Users.fetchUserByUsername
                    shared.accountsPanel
                    ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts state.targetHost |> Maybe.map .userId
                    , state.targetHost
                    )
                    state.username
            )


{-| Kicks off the username-resolving fetch the first time `state.targetHost`
is a known, connected server -- mirrors
`Components.Pages.UserProfilePage.fetchIfReady`.
-}
fetchIfReady : Shared.Model -> ResolveState -> ( Model, Effect Msg )
fetchIfReady shared state =
    if state.fetchStarted then
        ( Resolving state, Effect.none )

    else
        case fetchTask shared state of
            Just fetch ->
                ( Resolving { state | fetchStarted = True }, fetch |> Task.attempt GotUser |> Effect.fromCmd )

            Nothing ->
                ( Resolving state, Effect.none )



-- UPDATE


type Msg
    = GotUser (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetUsersResponse ))
    | Poll
    | PostsMsg PostsPage.Msg
    | SharedMsg Shared.Msg


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
into `update`'s `SharedMsg` branch -- see `Pages.Username_.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


accountsPanelEffect : Maybe AccountsPanel.Msg -> Effect Msg
accountsPanelEffect maybeAccountsPanelMsg =
    maybeAccountsPanelMsg
        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
        |> Maybe.withDefault Effect.none


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case ( msg, model ) of
        ( GotUser (Ok ( maybeAccountsPanelMsg, response )), Resolving state ) ->
            case List.head response.users of
                Just user ->
                    let
                        ( postsModel, postsEffect ) =
                            PostsPage.init shared (Just user.id)
                    in
                    ( Posts postsModel, Effect.batch [ accountsPanelEffect maybeAccountsPanelMsg, Effect.map PostsMsg postsEffect ] )

                Nothing ->
                    ( Resolving { state | fetchStarted = False }, accountsPanelEffect maybeAccountsPanelMsg )

        ( GotUser (Err _), Resolving state ) ->
            ( Resolving { state | fetchStarted = False }, Effect.none )

        ( Poll, Resolving state ) ->
            fetchIfReady shared state

        ( PostsMsg subMsg, Posts postsModel ) ->
            PostsPage.update shared subMsg postsModel
                |> Tuple.mapFirst Posts
                |> Tuple.mapSecond (Effect.map PostsMsg)

        ( SharedMsg subMsg, Resolving state ) ->
            let
                ( fetchedModel, fetchEffect ) =
                    case subMsg of
                        Shared.AccountsPanelMsg _ ->
                            fetchIfReady shared state

                        _ ->
                            ( Resolving state, Effect.none )
            in
            ( fetchedModel, Effect.batch [ Effect.fromShared subMsg, fetchEffect ] )

        ( SharedMsg subMsg, Posts postsModel ) ->
            PostsPage.update shared (PostsPage.fromShared subMsg) postsModel
                |> Tuple.mapFirst Posts
                |> Tuple.mapSecond (Effect.map PostsMsg)

        _ ->
            ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Resolving state ->
            if state.fetchStarted then
                Sub.none

            else
                Time.every 30000 (\_ -> Poll)

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
