module Pages.Auth.To.Key_ exposing (Model, Msg, page)

{-| `/auth/to/:key`, where `:key` is `PUBLIC_KEY_URLSTRING@requestingHost` --
the sending side of the cross-server SSO hand-off (see
`Shared.FederatedAuth`): shows whoever's currently signed in on this app's own
`browsingHost` (`Shared.AccountsPanel.Model.browsingHost`), or -- if nobody
is -- lets them type in (or pick, via `usernameField`'s quick-fill buttons)
the username to sign in as. Either way, asks for their password (a fresh
Login RPC, not reusing any already-stored tokens, since only a freshly issued
token pair is transferred), then encrypts the resulting `Account` to
`requestingHost`'s public key and redirects back to
`https://requestingHost/elm/auth/from/...`. The receiving side is
`Pages.Auth.From.EncodedAccount_`.

Optionally (`alsoSignInHere`), that same username/password is also used for a
*second*, independent Login RPC (see `GotLoginResult`/`GotLocalSignInResult`)
whose fresh token pair is fed into this browser's own `Shared.AccountsPanel`
instead of being sent anywhere -- so the transfer to `requestingHost` and
this browser's own sign-in on `browsingHost` never share a token pair.

-}

import Browser.Navigation as Nav
import Dict
import Effect exposing (Effect)
import Gen.Params.Auth.To.Key_ exposing (Params)
import Grpc
import Html exposing (Html, button, div, h2, input, label, p, span, text)
import Html.Attributes exposing (checked, class, disabled, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Encode as Encode
import Page
import Ports
import Proto.Jonline exposing (ExpirableToken, RefreshTokenResponse)
import Proto.Jonline.Jonline as Jonline
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel exposing (Account, FormStatus(..), Token)
import Shared.Conversions exposing (timestampToPosix)
import Shared.FederatedAuth as FederatedAuth
import Task exposing (Task)
import UI
import UI.Classes exposing (classes, hostnameToCSSClass)
import Url
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


type alias Model =
    { requestingHost : String
    , publicKey : Maybe FederatedAuth.PublicKey

    -- Only used/shown when nobody's currently signed in to `browsingHost` --
    -- see `usernameField`. Otherwise the signed-in account's own username is
    -- used instead (see `effectiveUsername`).
    , username : String
    , password : String

    -- Whether to also feed this page's own fresh Login RPC into this
    -- browser's `Shared.AccountsPanel`, signing (or re-signing) in locally on
    -- `browsingHost` -- see `GotLoginResult`/`GotLocalSignInResult`.
    , alsoSignInHere : Bool

    -- The transfer `Account` (bound for `requestingHost`) and its public key,
    -- held here between `GotLoginResult` and `GotLocalSignInResult` while
    -- `alsoSignInHere`'s second Login RPC is still in flight. `Nothing` the
    -- rest of the time -- including once that second RPC settles, at which
    -- point it's consumed to actually kick off the encrypt/redirect.
    , pendingTransferAccount : Maybe ( Account, FederatedAuth.PublicKey )
    , status : FormStatus

    -- The path (app-relative, no `basePath`) the user was on when they
    -- clicked "Sign in from <server>" (see `UI.signInFromButton`) -- passed
    -- through unchanged into the redirect back to `requestingHost` (see
    -- `GotEncryptResult`) so `Pages.Auth.From.EncodedAccount_` can send them
    -- back where they started instead of just the home page.
    , startPath : Maybe String
    }


{-| `rawKey` is `PUBLIC_KEY_URLSTRING@requestingHost` -- always both parts,
unlike `Components.PostCard.parsePostRouteId`'s `id[@host]`, since this route
has no "current server" to fall back to.
-}
init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        ( keyString, requestingHost ) =
            case String.split "@" req.params.key of
                [ key, host ] ->
                    ( Just key, host )

                _ ->
                    ( Nothing, "" )

        browsingHost =
            shared.accountsPanel.browsingHost

        -- Pre-filled only when there's exactly one candidate to guess --
        -- see `usernameField`'s quick-fill buttons for the ambiguous case.
        defaultUsername =
            case AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts browsingHost of
                Just _ ->
                    ""

                Nothing ->
                    case List.filter (\a -> a.server == browsingHost) shared.accountsPanel.accounts of
                        [ onlyAccount ] ->
                            onlyAccount.username

                        _ ->
                            ""
    in
    ( { requestingHost = requestingHost
      , publicKey = keyString |> Maybe.andThen FederatedAuth.urlStringToPublicKey
      , username = defaultUsername
      , password = ""
      , alsoSignInHere = False
      , pendingTransferAccount = Nothing
      , status = Idle
      , startPath = Dict.get "start_path" req.query
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = UsernameChanged String
    | PasswordChanged String
    | UsernameButtonClicked String
    | AlsoSignInHereToggled
    | SignInClicked
    | GotLoginResult (Result Grpc.Error ( Maybe Account, FederatedAuth.PublicKey ))
    | GotLocalSignInResult (Result Grpc.Error (Maybe Account))
    | GotEncryptResult Encode.Value
    | SharedMsg Shared.Msg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        UsernameChanged username ->
            ( { model | username = username }, Effect.none )

        PasswordChanged password ->
            ( { model | password = password }, Effect.none )

        UsernameButtonClicked username ->
            ( { model | username = username }, Effect.none )

        AlsoSignInHereToggled ->
            ( { model | alsoSignInHere = not model.alsoSignInHere }, Effect.none )

        SignInClicked ->
            let
                browsingHost =
                    shared.accountsPanel.browsingHost
            in
            case ( AccountsPanel.serverForHost shared.accountsPanel.servers browsingHost, model.publicKey ) of
                ( Just server, Just publicKey ) ->
                    ( { model | status = Submitting }
                    , loginTask server (effectiveUsername shared model) model.password
                        |> Task.map (\resp -> ( accountFromLogin browsingHost resp, publicKey ))
                        |> Task.attempt GotLoginResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( { model | status = Errored ("You need to be signed in on " ++ browsingHost ++ " to do that.") }
                    , Effect.none
                    )

        GotLoginResult (Ok ( Just account, publicKey )) ->
            if model.alsoSignInHere then
                let
                    browsingHost =
                        shared.accountsPanel.browsingHost
                in
                case AccountsPanel.serverForHost shared.accountsPanel.servers browsingHost of
                    Just server ->
                        ( { model | pendingTransferAccount = Just ( account, publicKey ) }
                        , loginTask server (effectiveUsername shared model) model.password
                            |> Task.map (accountFromLogin browsingHost)
                            |> Task.attempt GotLocalSignInResult
                            |> Effect.fromCmd
                        )

                    Nothing ->
                        ( model, encryptAndSendEffect publicKey account )

            else
                ( model, encryptAndSendEffect publicKey account )

        GotLoginResult (Ok ( Nothing, _ )) ->
            ( { model | status = Errored "Server response was missing user/token data." }, Effect.none )

        GotLoginResult (Err err) ->
            ( { model | status = Errored (AccountsPanel.grpcErrorToString err) }, Effect.none )

        GotLocalSignInResult (Ok (Just localAccount)) ->
            case model.pendingTransferAccount of
                Just ( account, publicKey ) ->
                    -- Writes `localAccount`'s tokens into `Shared.AccountsPanel` (and
                    -- has it kick off `persist`, via `FederatedAccountReceived`) before
                    -- the batched `encryptAndSendEffect` below ever navigates away --
                    -- `Main.elm`'s `Effect.partitionShared` applies a page's forwarded
                    -- `Shared.Msg`s synchronously, in this very update cycle.
                    ( { model | pendingTransferAccount = Nothing }
                    , Effect.batch
                        [ Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.FederatedAccountReceived localAccount))
                        , encryptAndSendEffect publicKey account
                        ]
                    )

                Nothing ->
                    ( model, Effect.none )

        GotLocalSignInResult (Ok Nothing) ->
            ( { model | status = Errored "Server response was missing user/token data.", pendingTransferAccount = Nothing }
            , Effect.none
            )

        GotLocalSignInResult (Err err) ->
            ( { model | status = Errored (AccountsPanel.grpcErrorToString err), pendingTransferAccount = Nothing }
            , Effect.none
            )

        GotEncryptResult value ->
            case FederatedAuth.encryptResult value of
                Ok ciphertext ->
                    ( model
                    , Nav.load
                        ("https://"
                            ++ model.requestingHost
                            ++ "/elm/auth/from/"
                            ++ ciphertext
                            ++ (case model.startPath of
                                    Just startPath ->
                                        "?start_path=" ++ Url.percentEncode startPath

                                    Nothing ->
                                        ""
                               )
                        )
                        |> Effect.fromCmd
                    )

                Err err ->
                    ( { model | status = Errored err }, Effect.none )

        SharedMsg subMsg ->
            ( model, Effect.fromShared subMsg )


{-| The username this page's Login RPC(s) actually authenticate as: the
signed-in account's own, if `browsingHost` has one, otherwise whatever's
typed into `usernameField`. Shared between `signInView` (for the submit
button's disabled state) and `update` (for the RPC(s) themselves) so the two
never disagree.
-}
effectiveUsername : Shared.Model -> Model -> String
effectiveUsername shared model =
    case AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts shared.accountsPanel.browsingHost of
        Just account ->
            account.username

        Nothing ->
            model.username


loginTask : AccountsPanel.Server -> String -> String -> Task Grpc.Error RefreshTokenResponse
loginTask server username password =
    Grpc.new Jonline.login
        { username = username
        , password = password
        , expiresAt = Nothing
        , deviceName = Nothing
        , userId = Nothing
        }
        |> Grpc.setHost (AccountsPanel.connectionUrl (AccountsPanel.connectionOf server))
        |> Grpc.toTask


encryptAndSendEffect : FederatedAuth.PublicKey -> Account -> Effect Msg
encryptAndSendEffect publicKey account =
    FederatedAuth.encrypt publicKey (Encode.encode 0 (AccountsPanel.encodeAccount account))
        |> Effect.fromCmd


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
                , refreshToken = tokenFromExpirable refreshToken
                , accessToken = tokenFromExpirable accessToken
                , enabled = True
                , avatarMediaId = Maybe.map .id user.avatar
                , permissions = user.permissions
                , realName = user.realName
                , needsPassword = False
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
            let
                browsingHost =
                    shared.accountsPanel.browsingHost

                signedInAccount =
                    AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts browsingHost

                accountsOnHost =
                    List.filter (\a -> a.server == browsingHost) shared.accountsPanel.accounts

                username =
                    effectiveUsername shared model

                accountForUsername =
                    accountsOnHost |> List.filter (\a -> a.username == username) |> List.head

                submitting =
                    model.status == Submitting
            in
            div [ class "auth-to-page" ]
                [ h2 [] [ text (model.requestingHost ++ " is asking to sign in") ]
                , case signedInAccount of
                    Just account ->
                        currentAccountBadge shared account

                    Nothing ->
                        usernameField shared model accountsOnHost submitting
                , input
                    [ type_ "password"
                    , placeholder "Password"
                    , value model.password
                    , onInput PasswordChanged
                    , disabled submitting
                    ]
                    []
                , alsoSignInCheckbox model.alsoSignInHere accountForUsername submitting
                , button
                    [ onClick SignInClicked
                    , disabled (submitting || String.isEmpty model.password || String.isEmpty username)
                    , classes [ hostnameToCSSClass model.requestingHost, "background-color-primary", "auth-to-signin-button" ]
                    ]
                    [ text ("Sign in on " ++ model.requestingHost) ]
                , case model.status of
                    Errored err ->
                        div [ class "auth-error" ] [ text err ]

                    _ ->
                        text ""
                ]


currentAccountBadge : Shared.Model -> Account -> Html Msg
currentAccountBadge shared account =
    let
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
    div [ class "auth-to-account" ]
        [ span [ class "auth-from-greeting" ] [ text "Sign in as" ]
        , UI.imageOrInitial [ "auth-from-avatar" ] account.username avatarUrl
        , span [ class "auth-from-name" ] [ text nameAndHost ]
        , span [ class "auth-from-greeting" ] [ text "?" ]
        ]


{-| Shown in place of `currentAccountBadge` when nobody's currently signed in
to `browsingHost` -- a plain username input, plus one quick-fill button per
account already known for that host (signed out, or needing a password), so
picking a previously-used username doesn't require retyping it. The
single-candidate auto-fill happens once, in `init`.
-}
usernameField : Shared.Model -> Model -> List Account -> Bool -> Html Msg
usernameField shared model accountsOnHost submitting =
    div [ class "auth-to-username-section" ]
        (input
            [ type_ "text"
            , placeholder ("Username on " ++ shared.accountsPanel.browsingHost)
            , value model.username
            , onInput UsernameChanged
            , disabled submitting
            ]
            []
            :: (if List.isEmpty accountsOnHost then
                    []

                else
                    [ div [ class "auth-to-username-buttons" ]
                        (List.map (usernameButton shared submitting) accountsOnHost)
                    ]
               )
        )


usernameButton : Shared.Model -> Bool -> Account -> Html Msg
usernameButton shared submitting account =
    button
        [ type_ "button"
        , class "auth-to-username-button"
        , onClick (UsernameButtonClicked account.username)
        , disabled submitting
        ]
        [ UI.imageOrInitial [ "auth-to-username-button-avatar" ] account.username (AccountsPanel.accountAvatarUrl shared.accountsPanel.servers account)
        , span [] [ text account.username ]
        ]


{-| Below the password field -- lets a fresh Login also be written into
`Shared.AccountsPanel` for `browsingHost` (see `GotLoginResult`), rather than
only ever being used for the `requestingHost` transfer. Its label reflects
whether `accountForUsername` (the current username's existing Account here,
if any) already exists, since checking it either creates a brand new
sign-in or just refreshes/re-enables that existing one.
-}
alsoSignInCheckbox : Bool -> Maybe Account -> Bool -> Html Msg
alsoSignInCheckbox isChecked accountForUsername submitting =
    label [ class "auth-to-also-sign-in" ]
        [ input
            [ type_ "checkbox"
            , checked isChecked
            , onClick AlsoSignInHereToggled
            , disabled submitting
            ]
            []
        , text
            (case accountForUsername of
                Nothing ->
                    "Also sign in here"

                Just _ ->
                    "Sign back in here"
            )
        ]


tokenFromExpirable : ExpirableToken -> Token
tokenFromExpirable expirable =
    { token = expirable.token
    , expiresAt = Maybe.map timestampToPosix expirable.expiresAt
    }
