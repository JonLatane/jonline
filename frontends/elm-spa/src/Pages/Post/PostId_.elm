module Pages.Post.PostId_ exposing (Model, Msg, fromShared, page)

{-| `/post/:id[@host]` -- a single Post, by id, on `mainFrontendHost` or (with an `@host` suffix)
some other federated server. Thin wrapper around `Components.Pages.PostPage`, which does all the
actual work -- mirrors `Pages.About`'s own direct-alias shape around
`Components.Pages.ServerInformationPage`. Also reused, unmodified, by
`Pages.UsernameOrCustomTab_` (once a custom tab's own `path` resolves to a `TargetPost`) so a vanity
URL like `/weddings` renders indistinguishably from this page itself -- see that module's
`initEmbedded`.
-}

import Components.Pages.PostPage as PostPage
import Effect exposing (Effect)
import Gen.Params.Post.PostId_ exposing (Params)
import Page
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
import UI
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req
        , update = update shared
        , view = view shared req
        , subscriptions = PostPage.subscriptions
        }


type alias Model =
    PostPage.Model


type alias Msg =
    PostPage.Msg


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    PostPage.init shared (AccountsPanel.isSecure req) req.params.postId req.key


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    PostPage.update shared msg model


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared [ PostPage.titleFor model ]
    , body =
        UI.layout shared
            req.route
            fromShared
            [ PostPage.view shared model ]
    }


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page -- see
`Components.Pages.PostPage.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    PostPage.fromShared
