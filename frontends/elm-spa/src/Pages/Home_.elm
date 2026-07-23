module Pages.Home_ exposing (Model, Msg, fromShared, page)

{-| `/` -- recent posts from every enabled server. Thin wrapper around
`Components.Pages.PostsPage`, which does all the actual work -- mirrors
`Pages.User.UserId_`/`Pages.Username_.Posts`' own use of that module, except
this page adds its own "Recent Posts"/"Recent Replies" heading (see
`heading`, which tracks `PostsPage`'s own POST/REPLY context chooser) and
passes `authorUserId = Nothing` (an unfiltered feed, rather than one user's
own posts) -- plus, unlike those other `PostsPage` callers, keeps
`Shared.Breadcrumbs` pointed at `mainFrontendHost` (see `setBreadcrumbsHost`),
since this feed isn't scoped to any one server for a breadcrumb trail to
identify the way a Post's own reply chain is.
-}

import Components.Pages.PostsPage as PostsPage
import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Html exposing (h2, text)
import Page
import Proto.Jonline.PostContext exposing (PostContext(..))
import Request
import Shared
import Shared.Breadcrumbs as Breadcrumbs
import UI
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req
        , update = update shared
        , view = view shared req
        , subscriptions = PostsPage.subscriptions
        }



-- MODEL


type alias Model =
    PostsPage.Model


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        ( model, effect ) =
            PostsPage.init shared Nothing req.key req.url.path req.query
    in
    ( model, Effect.batch [ effect ] )



-- UPDATE


type alias Msg =
    PostsPage.Msg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    let
        ( newModel, effect ) =
            PostsPage.update shared msg model
    in
    ( newModel, Effect.batch [ effect ] )


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page --
see `Components.Pages.PostsPage.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    PostsPage.fromShared



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared []
    , body =
        UI.layout shared
            req.route
            fromShared
            [ h2 [] [ text (heading model.context) ]
            , PostsPage.view shared model
            ]
    }


{-| "Recent Posts"/"Recent Replies", matching `model.context` -- the same
POST/REPLY chooser `PostsPage.searchRowView` renders just below this heading.
-}
heading : PostContext -> String
heading context =
    case context of
        REPLY ->
            "Recent Replies"

        _ ->
            "Recent Posts"
