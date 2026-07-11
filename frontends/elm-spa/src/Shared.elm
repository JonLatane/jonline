module Shared exposing
    ( Account
    , Auth(..)
    , Flags
    , Model
    , Msg(..)
    , init
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


type alias Account =
    { server : String
    , userId : String
    , username : String
    , refreshToken : ExpirableToken
    , accessToken : ExpirableToken
    }


type Auth
    = SignedOut
    | SigningIn
    | SignedIn Account


type alias Model =
    { server : String
    , username : String
    , password : String
    , auth : Auth
    , authError : Maybe String
    }


type Msg
    = ServerChanged String
    | UsernameChanged String
    | PasswordChanged String
    | LoginClicked
    | CreateAccountClicked
    | LogOutClicked
    | GotAuthResult (Result Grpc.Error RefreshTokenResponse)


init : Request -> Flags -> ( Model, Cmd Msg )
init _ flags =
    let
        auth =
            Decode.decodeValue accountDecoder flags
                |> Result.map SignedIn
                |> Result.withDefault SignedOut
    in
    ( { server = "localhost:27707"
      , username = ""
      , password = ""
      , auth = auth
      , authError = Nothing
      }
    , Cmd.none
    )


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        ServerChanged server ->
            ( { model | server = server }, Cmd.none )

        UsernameChanged username ->
            ( { model | username = username }, Cmd.none )

        PasswordChanged password ->
            ( { model | password = password }, Cmd.none )

        LoginClicked ->
            ( { model | auth = SigningIn, authError = Nothing }
            , Grpc.new Jonline.login
                { username = model.username
                , password = model.password
                , expiresAt = Nothing
                , deviceName = Nothing
                , userId = Nothing
                }
                |> Grpc.setHost (grpcHost model.server)
                |> Grpc.toCmd GotAuthResult
            )

        CreateAccountClicked ->
            ( { model | auth = SigningIn, authError = Nothing }
            , Grpc.new Jonline.createAccount
                { username = model.username
                , password = model.password
                , email = Nothing
                , phone = Nothing
                , expiresAt = Nothing
                , deviceName = Nothing
                }
                |> Grpc.setHost (grpcHost model.server)
                |> Grpc.toCmd GotAuthResult
            )

        LogOutClicked ->
            ( { model | auth = SignedOut, password = "" }
            , Ports.clearAccount ()
            )

        GotAuthResult (Ok resp) ->
            case ( resp.user, resp.refreshToken, resp.accessToken ) of
                ( Just user, Just refreshToken, Just accessToken ) ->
                    let
                        account =
                            { server = model.server
                            , userId = user.id
                            , username = user.username
                            , refreshToken = refreshToken
                            , accessToken = accessToken
                            }
                    in
                    ( { model | auth = SignedIn account, password = "" }
                    , Ports.saveAccount (encodeAccount account)
                    )

                _ ->
                    ( { model | auth = SignedOut, authError = Just "Server response was missing user/token data." }
                    , Cmd.none
                    )

        GotAuthResult (Err err) ->
            ( { model | auth = SignedOut, authError = Just (grpcErrorToString err) }
            , Cmd.none
            )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


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


encodeAccount : Account -> Encode.Value
encodeAccount account =
    Encode.object
        [ ( "server", Encode.string account.server )
        , ( "userId", Encode.string account.userId )
        , ( "username", Encode.string account.username )
        , ( "refreshToken", Encode.string account.refreshToken.token )
        , ( "accessToken", Encode.string account.accessToken.token )
        ]


accountDecoder : Decoder Account
accountDecoder =
    Decode.map5 Account
        (Decode.field "server" Decode.string)
        (Decode.field "userId" Decode.string)
        (Decode.field "username" Decode.string)
        (Decode.field "refreshToken" tokenDecoder)
        (Decode.field "accessToken" tokenDecoder)


tokenDecoder : Decoder ExpirableToken
tokenDecoder =
    Decode.map (\token -> { token = token, expiresAt = Nothing }) Decode.string
