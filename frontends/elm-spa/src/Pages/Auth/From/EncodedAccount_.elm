module Pages.Auth.From.EncodedAccount_ exposing (Model, Msg, page)

{-| `/auth/from/:encodedAccount` -- the receiving side of the cross-server
SSO hand-off (see `Shared.FederatedAuth`): decrypts `:encodedAccount` with
this origin's own private key, then shows a confirmation ("add this
account?") before actually adding it to `Shared.AccountsPanel`'s accounts.
The sending side is `Pages.Auth.To.Key_`.
-}

import Browser.Navigation as Nav
import Dict
import Effect exposing (Effect)
import Gen.Params.Auth.From.EncodedAccount_ exposing (Params)
import Html exposing (Html, a, button, div, h2, p, span, text)
import Html.Attributes exposing (class, href, title)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Encode as Encode
import Page
import Ports
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel exposing (Account)
import Shared.FederatedAuth as FederatedAuth
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


type Status
    = Decrypting
    | DecryptFailed String
    | Decrypted Account
    | Accepted Account
    | Cancelled


type alias Model =
    { status : Status

    -- `?start_path=` (see `UI.signInFromButton`/`Pages.Auth.To.Key_`) -- the
    -- app-relative path the user was on, on this origin, before the SSO
    -- hand-off started. When present, a successfully decrypted account skips
    -- the confirmation step (see `GotDecryptResult`) and is added/redirected
    -- to automatically.
    , startPath : Maybe String
    }


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        startPath =
            Dict.get "start_path" req.query
    in
    case shared.federatedAuth.privateKey of
        Nothing ->
            ( { status = DecryptFailed "No pending sign-in was started from this browser.", startPath = startPath }, Effect.none )

        Just privateKey ->
            ( { status = Decrypting, startPath = startPath }
            , FederatedAuth.decrypt privateKey req.params.encodedAccount |> Effect.fromCmd
            )



-- UPDATE


type Msg
    = GotDecryptResult Encode.Value
    | ConfirmClicked
    | CancelClicked
    | SharedMsg Shared.Msg


update : Shared.Model -> Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
update shared req msg model =
    case msg of
        GotDecryptResult value ->
            case FederatedAuth.decryptResult value of
                Ok accountJson ->
                    case Decode.decodeString AccountsPanel.accountDecoder accountJson of
                        Ok account ->
                            case model.startPath of
                                Just startPath ->
                                    ( { model | status = Accepted account }
                                    , Effect.batch
                                        [ Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.FederatedAccountReceived account))
                                        , Effect.fromShared (Shared.FederatedAuthMsg FederatedAuth.Discarded)
                                        , Nav.replaceUrl req.key (shared.basePath ++ startPath) |> Effect.fromCmd
                                        ]
                                    )

                                Nothing ->
                                    ( { model | status = Decrypted account }, Effect.none )

                        Err _ ->
                            ( { model | status = DecryptFailed "The received account data was malformed." }, Effect.none )

                Err err ->
                    ( { model | status = DecryptFailed err }, Effect.none )

        ConfirmClicked ->
            case model.status of
                Decrypted account ->
                    ( { model | status = Accepted account }
                    , Effect.batch
                        [ Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.FederatedAccountReceived account))
                        , Effect.fromShared (Shared.FederatedAuthMsg FederatedAuth.Discarded)
                        ]
                    )

                _ ->
                    ( model, Effect.none )

        CancelClicked ->
            ( { model | status = Cancelled }
            , Effect.fromShared (Shared.FederatedAuthMsg FederatedAuth.Discarded)
            )

        SharedMsg subMsg ->
            ( model, Effect.fromShared subMsg )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.federatedAuthDecrypted GotDecryptResult



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared [ "Sign in" ]
    , body =
        UI.layout shared
            req.route
            SharedMsg
            [ statusView shared model ]
    }


statusView : Shared.Model -> Model -> Html Msg
statusView shared model =
    case model.status of
        Decrypting ->
            div [ class "auth-from-page" ] [ p [] [ text "Decrypting sign-in request…" ] ]

        DecryptFailed err ->
            div [ class "auth-from-page" ] [ p [] [ text err ] ]

        Cancelled ->
            div [ class "auth-from-page" ] [ p [] [ text "Sign-in cancelled." ] ]

        Decrypted account ->
            let
                avatarUrl =
                    AccountsPanel.accountAvatarUrl shared.accountsPanel.servers account

                branding =
                    AccountsPanel.brandingFor shared.accountsPanel.servers account.server

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
            div [ class "auth-from-page" ]
                [ div [ class "auth-from-header" ]
                    [ h2 [ class "auth-from-header-left" ]
                        [ span [ class "auth-from-greeting" ] [ text "Sign in as" ]
                        , UI.imageOrInitial [ "auth-from-avatar" ] account.username avatarUrl
                        , span [ class "auth-from-name" ] [ text nameAndHost ]
                        , span [ class "auth-from-greeting" ] [ text "?" ]
                        ]
                    , div [ class "auth-from-header-right" ]
                        [ button [ class "auth-from-cancel", onClick CancelClicked ] [ text "Cancel" ]
                        , button [ class "auth-from-confirm", onClick ConfirmClicked ] [ text "Add Account" ]
                        ]
                    ]
                , div [ class "profile-detail auth-from-profile" ]
                    [ div [ class "profile-header" ]
                        [ UI.imageOrInitial [ "profile-avatar" ] account.username avatarUrl
                        , div [ class "profile-header-names" ]
                            [ div [ class "profile-username" ]
                                [ text account.username
                                , if AccountsPanel.isAdmin account then
                                    span [ class "author-badge", title "Admin on this server" ] [ text "🛡️ Admin" ]

                                  else
                                    text ""
                                ]
                            , if String.isEmpty (String.trim account.realName) then
                                text ""

                              else
                                div [ class "profile-real-name-display" ]
                                    [ span [ class "profile-real-name" ] [ text account.realName ] ]
                            ]
                        ]
                    , div [ class "profile-meta" ] [ text (account.server ++ " · " ++ branding.name) ]
                    ]
                ]

        Accepted account ->
            div [ class "auth-from-page" ]
                [ p [] [ text ("Signed in as " ++ AccountsPanel.displayName account ++ " on " ++ account.server ++ ".") ]
                , a [ href (shared.basePath ++ "/") ] [ text "Continue" ]
                ]
