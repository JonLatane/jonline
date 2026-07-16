module Pages.Auth.To.Key_ exposing (Model, Msg, page)

{-| `/auth/to/:key`, where `:key` is `PUBLIC_KEY_URLSTRING@requestingHost` --
the sending side of the cross-server SSO hand-off (see
`Shared.FederatedAuth`): shows whoever's currently signed in on this app's
own `mainFrontendHost`, asks for their password (a fresh Login RPC, not
reusing the already-stored tokens, since only a freshly issued token pair is
transferred), then encrypts the resulting `Account` to `requestingHost`'s
public key and redirects back to `https://requestingHost/elm/auth/from/...`.
The receiving side is `Pages.Auth.From.EncodedAccount_`.
-}

import Browser.Navigation as Nav
import Effect exposing (Effect)
import Gen.Params.Auth.To.Key_ exposing (Params)
import Grpc
import Html exposing (Html, button, div, h2, img, input, p, span, text)
import Html.Attributes exposing (class, disabled, placeholder, src, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Encode as Encode
import Page
import Ports
import Proto.Jonline exposing (RefreshTokenResponse)
import Proto.Jonline.Jonline as Jonline
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel exposing (Account, FormStatus(..))
import Shared.FederatedAuth as FederatedAuth
import Shared.MaybeAccountRequest as MaybeAccountRequest
import Task
import UI
import UI.Classes exposing (classes, hostnameToCSSClass)
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req.params
        , update = update shared
        , view = view shared req
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { requestingHost : String
    , publicKey : Maybe FederatedAuth.PublicKey
    , password : String
    , status : FormStatus
    }


{-| `rawKey` is `PUBLIC_KEY_URLSTRING@requestingHost` -- always both parts,
unlike `Components.PostCard.parsePostRouteId`'s `id[@host]`, since this route
has no "current server" to fall back to.
-}
init : Shared.Model -> Params -> ( Model, Effect Msg )
init _ params =
    let
        ( keyString, requestingHost ) =
            case String.split "@" params.key of
                [ key, host ] ->
                    ( Just key, host )

                _ ->
                    ( Nothing, "" )
    in
    ( { requestingHost = requestingHost
      , publicKey = keyString |> Maybe.andThen FederatedAuth.urlStringToPublicKey
      , password = ""
      , status = Idle
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = PasswordChanged String
    | SignInClicked
    | GotLoginResult (Result Grpc.Error ( Maybe Account, FederatedAuth.PublicKey ))
    | GotEncryptResult Encode.Value
    | SharedMsg Shared.Msg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        PasswordChanged password ->
            ( { model | password = password }, Effect.none )

        SignInClicked ->
            case
                ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts shared.accountsPanel.mainFrontendHost
                , AccountsPanel.serverForHost shared.accountsPanel.servers shared.accountsPanel.mainFrontendHost
                , model.publicKey
                )
            of
                ( Just signedInAccount, Just server, Just publicKey ) ->
                    ( { model | status = Submitting }
                    , Grpc.new Jonline.login
                        { username = signedInAccount.username
                        , password = model.password
                        , expiresAt = Nothing
                        , deviceName = Nothing
                        , userId = Nothing
                        }
                        |> Grpc.setHost (AccountsPanel.connectionUrl (AccountsPanel.connectionOf server))
                        |> Grpc.toTask
                        |> Task.map (\resp -> ( accountFromLogin shared.accountsPanel.mainFrontendHost resp, publicKey ))
                        |> Task.attempt GotLoginResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( { model | status = Errored ("You need to be signed in on " ++ shared.accountsPanel.mainFrontendHost ++ " to do that.") }
                    , Effect.none
                    )

        GotLoginResult (Ok ( Just account, publicKey )) ->
            ( model
            , FederatedAuth.encrypt publicKey (Encode.encode 0 (AccountsPanel.encodeAccount account))
                |> Effect.fromCmd
            )

        GotLoginResult (Ok ( Nothing, _ )) ->
            ( { model | status = Errored "Server response was missing user/token data." }, Effect.none )

        GotLoginResult (Err err) ->
            ( { model | status = Errored (AccountsPanel.grpcErrorToString err) }, Effect.none )

        GotEncryptResult value ->
            case FederatedAuth.encryptResult value of
                Ok ciphertext ->
                    ( model
                    , Nav.load ("https://" ++ model.requestingHost ++ "/elm/auth/from/" ++ ciphertext)
                        |> Effect.fromCmd
                    )

                Err err ->
                    ( { model | status = Errored err }, Effect.none )

        SharedMsg subMsg ->
            ( model, Effect.fromShared subMsg )


{-| Mirrors `Shared.AccountsPanel.updateHelp`'s `GotAuthResult` account
construction -- `Nothing` if the response is missing user/token data (an
`update` branch above turns that into the same `Errored` state `GotAuthResult`
would).
-}
accountFromLogin : String -> RefreshTokenResponse -> Maybe Account
accountFromLogin server resp =
    case ( resp.user, resp.refreshToken, resp.accessToken ) of
        ( Just user, Just refreshToken, Just accessToken ) ->
            Just
                { server = server
                , userId = user.id
                , username = user.username
                , refreshToken = MaybeAccountRequest.tokenFromExpirable refreshToken
                , accessToken = MaybeAccountRequest.tokenFromExpirable accessToken
                , enabled = True
                , avatarMediaId = Maybe.map .id user.avatar
                , permissions = user.permissions
                , realName = user.realName
                }

        _ ->
            Nothing


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.federatedAuthEncrypted GotEncryptResult



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared [ "Sign in" ]
    , body =
        UI.layout shared
            req.route
            SharedMsg
            [ signInView shared model ]
    }


signInView : Shared.Model -> Model -> Html Msg
signInView shared model =
    case ( model.publicKey, String.isEmpty model.requestingHost ) of
        ( Nothing, _ ) ->
            div [ class "auth-to-page" ] [ p [] [ text "This sign-in link is malformed." ] ]

        ( _, True ) ->
            div [ class "auth-to-page" ] [ p [] [ text "This sign-in link is malformed." ] ]

        ( Just _, False ) ->
            case AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts shared.accountsPanel.mainFrontendHost of
                Nothing ->
                    div [ class "auth-to-page" ]
                        [ p [] [ text (model.requestingHost ++ " is asking to sign in, but you're not signed in here.") ] ]

                Just account ->
                    let
                        submitting =
                            model.status == Submitting

                        avatarUrl =
                            AccountsPanel.accountAvatarUrl shared.accountsPanel.servers account

                        nameAndHost =
                            account.username
                                ++ (if String.isEmpty (String.trim account.realName) then
                                        ""

                                    else
                                        " | " ++ account.realName
                                   )
                                ++ " from "
                                ++ account.server
                    in
                    div [ class "auth-to-page" ]
                        [ h2 [] [ text (model.requestingHost ++ " is asking to sign in") ]
                        , div [ class "auth-to-account" ]
                            [ case AccountsPanel.accountAvatarUrl shared.accountsPanel.servers account of
                                Just url ->
                                    img [ class "auth-to-account-avatar", src url ] []

                                Nothing ->
                                    text ""

                            -- , text ("Sign in as " ++ AccountsPanel.displayName account ++ "?")
                            , span [ class "auth-from-greeting" ] [ text "Sign in as" ]
                            , UI.imageOrInitial [ "auth-from-avatar" ] account.username avatarUrl
                            , span [ class "auth-from-name" ] [ text nameAndHost ]
                            , span [ class "auth-from-greeting" ] [ text "?" ]
                            ]
                        , input
                            [ type_ "password"
                            , placeholder "Password"
                            , value model.password
                            , onInput PasswordChanged
                            , disabled submitting
                            ]
                            []
                        , button
                            [ onClick SignInClicked
                            , disabled (submitting || String.isEmpty model.password)
                            , classes [ hostnameToCSSClass model.requestingHost, "background-color-primary", "auth-to-signin-button" ]
                            ]
                            [ text ("Sign in on " ++ model.requestingHost) ]
                        , case model.status of
                            Errored err ->
                                div [ class "auth-error" ] [ text err ]

                            _ ->
                                text ""
                        ]
