module Shared exposing
    ( Account
    , AccountForm
    , Flags
    , FormStatus(..)
    , Model
    , Msg(..)
    , Server
    , accountId
    , accountsMenuLabel
    , init
    , serverHasAccounts
    , subscriptions
    , update
    )

import Grpc
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports
import Proto.Jonline exposing (ExpirableToken, RefreshTokenResponse)
import Proto.Jonline.Jonline as Jonline
import Request exposing (Request)


type alias Flags =
    Decode.Value


{-| A signed-into account on a server. `enabled` is a lightweight, non-destructive
"signed in/out" toggle: disabling an account keeps its tokens around so it can be
re-enabled without logging in again. Fully forgetting an account (`RemoveAccountClicked`)
is the "traditional" sign out.
-}
type alias Account =
    { server : String
    , userId : String
    , username : String
    , refreshToken : ExpirableToken
    , accessToken : ExpirableToken
    , enabled : Bool
    }


{-| A server the app knows about (because an account was created/logged into there).
`enabled` controls whether the server's (eventually public) data is included when
aggregating data across servers.
-}
type alias Server =
    { host : String
    , enabled : Bool
    }


type FormStatus
    = Idle
    | Submitting
    | Errored String


type alias AccountForm =
    { server : String
    , username : String
    , password : String
    , status : FormStatus
    }


type alias Model =
    { accounts : List Account
    , servers : List Server
    , accountForm : AccountForm
    , serverHostInput : String
    , showAccountsPanel : Bool
    }


type Msg
    = ServerChanged String
    | UsernameChanged String
    | PasswordChanged String
    | LoginClicked
    | CreateAccountClicked
    | GotAuthResult (Result Grpc.Error RefreshTokenResponse)
    | ToggleAccountEnabled String
    | RemoveAccountClicked String
    | ToggleServerEnabled String
    | ServerHostInputChanged String
    | AddServerClicked
    | RemoveServerClicked String
    | ToggleAccountsPanel


{-| A stable identifier for an account: a user's id is only unique per-server.
-}
accountId : Account -> String
accountId account =
    account.server ++ "|" ++ account.userId


{-| What the accounts-menu toggle button should say: "Log In" with nobody signed
in, just the username if there's exactly one signed-in account on the server
currently in the login form, that account's "username@server" if it's on some
other server, or an account count if several are signed in at once.
-}
accountsMenuLabel : Model -> String
accountsMenuLabel model =
    case List.filter .enabled model.accounts of
        [] ->
            "Log In"

        [ only ] ->
            if only.server == model.accountForm.server then
                only.username

            else
                only.username ++ "@" ++ only.server

        many ->
            String.fromInt (List.length many) ++ " Accounts"


init : Request -> Flags -> ( Model, Cmd Msg )
init _ flags =
    let
        persisted =
            Decode.decodeValue persistedStateDecoder flags
                |> Result.withDefault { accounts = [], servers = [] }
    in
    ( { accounts = persisted.accounts
      , servers = persisted.servers
      , accountForm = emptyForm
      , serverHostInput = ""
      , showAccountsPanel = False
      }
    , Cmd.none
    )


emptyForm : AccountForm
emptyForm =
    { server = "localhost:27707"
    , username = ""
    , password = ""
    , status = Idle
    }


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        ServerChanged server ->
            ( updateForm (\form -> { form | server = server }) model, Cmd.none )

        UsernameChanged username ->
            ( updateForm (\form -> { form | username = username }) model, Cmd.none )

        PasswordChanged password ->
            ( updateForm (\form -> { form | password = password }) model, Cmd.none )

        LoginClicked ->
            let
                form =
                    model.accountForm
            in
            ( updateForm (\f -> { f | status = Submitting }) model
            , Grpc.new Jonline.login
                { username = form.username
                , password = form.password
                , expiresAt = Nothing
                , deviceName = Nothing
                , userId = Nothing
                }
                |> Grpc.setHost (grpcHost form.server)
                |> Grpc.toCmd GotAuthResult
            )

        CreateAccountClicked ->
            let
                form =
                    model.accountForm
            in
            ( updateForm (\f -> { f | status = Submitting }) model
            , Grpc.new Jonline.createAccount
                { username = form.username
                , password = form.password
                , email = Nothing
                , phone = Nothing
                , expiresAt = Nothing
                , deviceName = Nothing
                }
                |> Grpc.setHost (grpcHost form.server)
                |> Grpc.toCmd GotAuthResult
            )

        GotAuthResult (Ok resp) ->
            case ( resp.user, resp.refreshToken, resp.accessToken ) of
                ( Just user, Just refreshToken, Just accessToken ) ->
                    let
                        host =
                            model.accountForm.server

                        account =
                            { server = host
                            , userId = user.id
                            , username = user.username
                            , refreshToken = refreshToken
                            , accessToken = accessToken
                            , enabled = True
                            }

                        newModel =
                            { model
                                | accounts = upsertAccount account model.accounts
                                , servers = upsertServer host model.servers
                                , accountForm =
                                    let
                                        form =
                                            model.accountForm
                                    in
                                    { form | password = "", status = Idle }
                            }
                    in
                    ( newModel, persist newModel )

                _ ->
                    ( updateForm (\f -> { f | status = Errored "Server response was missing user/token data." }) model
                    , Cmd.none
                    )

        GotAuthResult (Err err) ->
            ( updateForm (\f -> { f | status = Errored (grpcErrorToString err) }) model
            , Cmd.none
            )

        ToggleAccountEnabled id ->
            let
                newModel =
                    { model
                        | accounts =
                            List.map
                                (\account ->
                                    if accountId account == id then
                                        { account | enabled = not account.enabled }

                                    else
                                        account
                                )
                                model.accounts
                    }
            in
            ( newModel, persist newModel )

        RemoveAccountClicked id ->
            let
                newModel =
                    { model | accounts = List.filter (\account -> accountId account /= id) model.accounts }
            in
            ( newModel, persist newModel )

        ToggleServerEnabled host ->
            let
                newModel =
                    { model
                        | servers =
                            List.map
                                (\server ->
                                    if server.host == host then
                                        { server | enabled = not server.enabled }

                                    else
                                        server
                                )
                                model.servers
                    }
            in
            ( newModel, persist newModel )

        ServerHostInputChanged host ->
            ( { model | serverHostInput = host }, Cmd.none )

        AddServerClicked ->
            let
                host =
                    String.trim model.serverHostInput
            in
            if String.isEmpty host then
                ( model, Cmd.none )

            else
                let
                    newModel =
                        { model
                            | servers = upsertServer host model.servers
                            , serverHostInput = ""
                        }
                in
                ( newModel, persist newModel )

        RemoveServerClicked host ->
            if serverHasAccounts model.accounts host then
                ( model, Cmd.none )

            else
                let
                    newModel =
                        { model | servers = List.filter (\s -> s.host /= host) model.servers }
                in
                ( newModel, persist newModel )

        ToggleAccountsPanel ->
            ( { model | showAccountsPanel = not model.showAccountsPanel }, Cmd.none )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


{-| A server that has any associated accounts can't be removed (only disabled),
since removing it would orphan those accounts' stored credentials.
-}
serverHasAccounts : List Account -> String -> Bool
serverHasAccounts accounts host =
    List.any (\a -> a.server == host) accounts


updateForm : (AccountForm -> AccountForm) -> Model -> Model
updateForm fn model =
    { model | accountForm = fn model.accountForm }


upsertAccount : Account -> List Account -> List Account
upsertAccount account accounts =
    if List.any (\a -> accountId a == accountId account) accounts then
        List.map
            (\a ->
                if accountId a == accountId account then
                    account

                else
                    a
            )
            accounts

    else
        accounts ++ [ account ]


upsertServer : String -> List Server -> List Server
upsertServer host servers =
    if List.any (\s -> s.host == host) servers then
        servers

    else
        servers ++ [ { host = host, enabled = True } ]


grpcHost : String -> String
grpcHost server =
    if String.startsWith "http://" server || String.startsWith "https://" server then
        server

    else
        "http://" ++ server


grpcErrorToString : Grpc.Error -> String
grpcErrorToString err =
    case err of
        Grpc.BadUrl url ->
            "Invalid server address: " ++ url

        Grpc.Timeout ->
            "The request to the server timed out."

        Grpc.NetworkError ->
            "Couldn't reach the server. Check the address and your connection."

        Grpc.BadStatus { errMessage } ->
            if String.isEmpty errMessage then
                "The server rejected the request."

            else
                errMessage

        Grpc.BadBody _ ->
            "Received an unreadable response from the server."

        Grpc.UnknownGrpcStatus status ->
            "Unknown server error: " ++ status



-- PERSISTENCE
-- Tokens are stored without their (usually absent) expiration, since accounts
-- are non-expiring by default and expiry-aware refresh isn't implemented yet.


persist : Model -> Cmd Msg
persist model =
    Ports.persist (encodeState model)


encodeState : Model -> Encode.Value
encodeState model =
    Encode.object
        [ ( "accounts", Encode.list encodeAccount model.accounts )
        , ( "servers", Encode.list encodeServer model.servers )
        ]


encodeAccount : Account -> Encode.Value
encodeAccount account =
    Encode.object
        [ ( "server", Encode.string account.server )
        , ( "userId", Encode.string account.userId )
        , ( "username", Encode.string account.username )
        , ( "refreshToken", Encode.string account.refreshToken.token )
        , ( "accessToken", Encode.string account.accessToken.token )
        , ( "enabled", Encode.bool account.enabled )
        ]


encodeServer : Server -> Encode.Value
encodeServer server =
    Encode.object
        [ ( "host", Encode.string server.host )
        , ( "enabled", Encode.bool server.enabled )
        ]


type alias PersistedState =
    { accounts : List Account
    , servers : List Server
    }


persistedStateDecoder : Decoder PersistedState
persistedStateDecoder =
    Decode.map2 PersistedState
        (Decode.field "accounts" (Decode.list accountDecoder))
        (Decode.field "servers" (Decode.list serverDecoder))


accountDecoder : Decoder Account
accountDecoder =
    Decode.map6 Account
        (Decode.field "server" Decode.string)
        (Decode.field "userId" Decode.string)
        (Decode.field "username" Decode.string)
        (Decode.field "refreshToken" tokenDecoder)
        (Decode.field "accessToken" tokenDecoder)
        (Decode.field "enabled" Decode.bool)


serverDecoder : Decoder Server
serverDecoder =
    Decode.map2 Server
        (Decode.field "host" Decode.string)
        (Decode.field "enabled" Decode.bool)


tokenDecoder : Decoder ExpirableToken
tokenDecoder =
    Decode.map (\token -> { token = token, expiresAt = Nothing }) Decode.string
