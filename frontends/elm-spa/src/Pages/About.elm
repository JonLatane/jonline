module Pages.About exposing (Model, Msg, fromShared, page)

{-| `/about` -- the main server's own info (`Components.Pages.ServerInformationPage`,
same as `Pages.Server.ServerIdentifier_` shows for an arbitrary server, just
always pointed at `mainFrontendHost`), followed by this app's own "About
Jonline" blurb. Thin wrapper, mirrors `Pages.User.UserId_`'s direct-alias
shape around `Components.Pages.UserProfilePage` -- there's no route segment
of its own to parse (and thus nothing that can be invalid), so unlike
`Pages.Server.ServerIdentifier_` there's no extra `Invalid`/`Info` split
needed here.
-}

import Components.Pages.ServerInformationPage as ServerInformationPage
import Effect exposing (Effect)
import Gen.Params.About exposing (Params)
import Html exposing (a, div, h2, p, text)
import Html.Attributes exposing (class, href)
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
        , update = ServerInformationPage.update shared
        , view = view shared req
        , subscriptions = ServerInformationPage.subscriptions
        }



-- MODEL


type alias Model =
    ServerInformationPage.Model


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    ServerInformationPage.init shared (AccountsPanel.isSecure req) shared.accountsPanel.mainFrontendHost



-- UPDATE


type alias Msg =
    ServerInformationPage.Msg


{-| See `Components.Pages.ServerInformationPage.fromShared` -- lets `Main`
notify this page of `Shared.Msg`s it didn't itself originate (e.g. the main
server reconnecting at startup), same as `Pages.Post.PostId_.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    ServerInformationPage.fromShared



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared [ "About" ]
    , body =
        UI.layout shared
            req.route
            fromShared
            [ ServerInformationPage.view shared model
            , aboutJonlineView
            ]
    }


aboutJonlineView : Html.Html Msg
aboutJonlineView =
    div [ class "about-jonline" ]
        [ h2 [] [ text "About Jonline" ]
        , p [] [ text "Jonline is a federated, decentralized social media platform created by Jon Latané." ]
        , p [] [ text "It's available under the AGPL, with a Rust BE and a new Elm FE, ", a [ href "https://github.com/JonLatane/jonline" ] [ text "available on GitHub" ], text ", and it should be easy to deploy yourself." ]
        , p [] [ text "It takes about ", a [ href "https://github.com/JonLatane/jonline#2-minute-startup-with-homebrew" ] [ text "2 minutes to set up Jonline on macOS with Homebrew" ], text " and ", a [ href "https://github.com/JonLatane/jonline#3-minute-startup-on-linux" ] [ text "3 minutes to set up Jonline on Linux" ], text "." ]
        , p [] [ text "Feel free to ", a [ href "mailto:jonlatane@gmail.com" ] [ text "email me" ], text " if you have any questions or want to contribute." ]
        ]
