module Shared exposing
    ( Account
    , AccountForm
    , AddServerForm
    , Branding
    , BrandingStatus(..)
    , Flags
    , FormStatus(..)
    , Model
    , Msg(..)
    , Server
    , Swatch
    , accountAvatarUrl
    , accountId
    , accountsMenuLabel
    , brandingFor
    , brandingOf
    , init
    , serverHasAccounts
    , subscriptions
    , update
    )

import Bitwise
import Grpc
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports
import Proto.Jonline exposing (ExpirableToken, RefreshTokenResponse, ServerConfiguration)
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
    , avatarMediaId : Maybe String
    }


{-| A server the app knows about (because an account was created/logged into there,
or it was explicitly added). `enabled` controls whether the server's (eventually
public) data is included when aggregating data across servers. `branding` is
fetched (and cached) separately, since it takes a network round-trip.
-}
type alias Server =
    { host : String
    , enabled : Bool
    , branding : BrandingStatus
    }


type BrandingStatus
    = BrandingUnknown
    | BrandingLoading
    | BrandingLoaded Branding
    | BrandingFailed


{-| A server's user-facing identity: its name, square logo (if any), and its
primary/secondary brand colors, each paired with a precomputed, readable
(black or white) text color to use on top of them.
-}
type alias Branding =
    { name : String
    , logoUrl : Maybe String
    , primary : Swatch
    , secondary : Swatch
    }


{-| A background color plus the text color that reads best on top of it.
-}
type alias Swatch =
    { hex : String
    , contrastText : String
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


{-| The "Add Server" control's own form state -- separate from `AccountForm`
since adding a server (an unauthenticated `GetServerConfiguration` probe) and
logging in are independent flows that can be in-flight/erroring independently.
-}
type alias AddServerForm =
    { host : String
    , status : FormStatus
    }


type alias Model =
    { accounts : List Account
    , servers : List Server
    , accountForm : AccountForm
    , addServerForm : AddServerForm
    , showAccountsPanel : Bool
    }


type Msg
    = ServerChanged String
    | UsernameChanged String
    | PasswordChanged String
    | LoginClicked
    | CreateAccountClicked
    | GotAuthResult (Result Grpc.Error RefreshTokenResponse)
    | GotServerConfiguration String (Result Grpc.Error ServerConfiguration)
    | ToggleAccountEnabled String
    | RemoveAccountClicked String
    | ToggleServerEnabled String
    | ServerHostInputChanged String
    | AddServerClicked
    | GotNewServerResult String (Result Grpc.Error ServerConfiguration)
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


{-| The URL for an account's avatar, authorized with its own access token
(avatars can be visibility-restricted, but an account can always see its own).
-}
accountAvatarUrl : Account -> Maybe String
accountAvatarUrl account =
    account.avatarMediaId
        |> Maybe.map (\id -> grpcHost account.server ++ "/media/" ++ id ++ "?authorization=" ++ account.accessToken.token)


{-| A server's branding, falling back to its bare hostname and neutral colors
until (or unless) it's loaded.
-}
brandingOf : Server -> Branding
brandingOf server =
    case server.branding of
        BrandingLoaded branding ->
            branding

        _ ->
            defaultBranding server.host


{-| Like `brandingOf`, but looks a server up by host (for e.g. an account's
`server` field, cross-referenced against the server list).
-}
brandingFor : List Server -> String -> Branding
brandingFor servers host =
    servers
        |> List.filter (\s -> s.host == host)
        |> List.head
        |> Maybe.map brandingOf
        |> Maybe.withDefault (defaultBranding host)


defaultBranding : String -> Branding
defaultBranding host =
    { name = host, logoUrl = Nothing, primary = fallbackSwatch, secondary = fallbackSwatch }


fallbackSwatch : Swatch
fallbackSwatch =
    { hex = "var(--chip-bg)", contrastText = "var(--fg)" }


init : Request -> Flags -> ( Model, Cmd Msg )
init _ flags =
    let
        persisted =
            Decode.decodeValue persistedStateDecoder flags
                |> Result.withDefault { accounts = [], servers = [] }

        servers =
            List.map (\s -> { s | branding = BrandingLoading }) persisted.servers
    in
    ( { accounts = persisted.accounts
      , servers = servers
      , accountForm = emptyForm
      , addServerForm = emptyAddServerForm
      , showAccountsPanel = False
      }
    , Cmd.batch (List.map (\s -> fetchServerConfig s.host) servers)
    )


emptyForm : AccountForm
emptyForm =
    { server = "localhost:27707"
    , username = ""
    , password = ""
    , status = Idle
    }


emptyAddServerForm : AddServerForm
emptyAddServerForm =
    { host = "", status = Idle }


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
                            , avatarMediaId = Maybe.map .id user.avatar
                            }

                        ( updatedServers, isNewServer ) =
                            upsertServer host model.servers

                        newModel =
                            { model
                                | accounts = upsertAccount account model.accounts
                                , servers = updatedServers
                                , accountForm =
                                    let
                                        form =
                                            model.accountForm
                                    in
                                    { form | password = "", status = Idle }
                            }
                    in
                    ( newModel
                    , Cmd.batch
                        [ persist newModel
                        , if isNewServer then
                            fetchServerConfig host

                          else
                            Cmd.none
                        ]
                    )

                _ ->
                    ( updateForm (\f -> { f | status = Errored "Server response was missing user/token data." }) model
                    , Cmd.none
                    )

        GotAuthResult (Err err) ->
            ( updateForm (\f -> { f | status = Errored (grpcErrorToString err) }) model
            , Cmd.none
            )

        GotServerConfiguration host result ->
            let
                branding =
                    case result of
                        Ok config ->
                            BrandingLoaded (brandingFromConfig host config)

                        Err _ ->
                            BrandingFailed

                newModel =
                    { model
                        | servers =
                            List.map
                                (\s ->
                                    if s.host == host then
                                        { s | branding = branding }

                                    else
                                        s
                                )
                                model.servers
                    }
            in
            ( newModel, Cmd.none )

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
            ( { model | addServerForm = { host = host, status = Idle } }, Cmd.none )

        AddServerClicked ->
            let
                host =
                    String.trim model.addServerForm.host
            in
            if String.isEmpty host then
                ( model, Cmd.none )

            else if List.any (\s -> s.host == host) model.servers then
                ( updateAddServerForm (\f -> { f | status = Errored "That server is already in your list." }) model
                , Cmd.none
                )

            else
                ( updateAddServerForm (\f -> { f | status = Submitting }) model
                , Grpc.new Jonline.getServerConfiguration {}
                    |> Grpc.setHost (grpcHost host)
                    |> Grpc.toCmd (GotNewServerResult host)
                )

        GotNewServerResult host result ->
            case result of
                Ok config ->
                    let
                        newModel =
                            { model
                                | servers = model.servers ++ [ { host = host, enabled = True, branding = BrandingLoaded (brandingFromConfig host config) } ]
                                , addServerForm = emptyAddServerForm
                            }
                    in
                    ( newModel, persist newModel )

                Err err ->
                    ( updateAddServerForm (\f -> { f | status = Errored (grpcErrorToString err) }) model
                    , Cmd.none
                    )

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


updateAddServerForm : (AddServerForm -> AddServerForm) -> Model -> Model
updateAddServerForm fn model =
    { model | addServerForm = fn model.addServerForm }


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


{-| Adds a server if it's not already known, reporting whether it did so (so
callers can decide whether to kick off a branding fetch for it).
-}
upsertServer : String -> List Server -> ( List Server, Bool )
upsertServer host servers =
    if List.any (\s -> s.host == host) servers then
        ( servers, False )

    else
        ( servers ++ [ { host = host, enabled = True, branding = BrandingLoading } ], True )


fetchServerConfig : String -> Cmd Msg
fetchServerConfig host =
    Grpc.new Jonline.getServerConfiguration {}
        |> Grpc.setHost (grpcHost host)
        |> Grpc.toCmd (GotServerConfiguration host)


brandingFromConfig : String -> ServerConfiguration -> Branding
brandingFromConfig host config =
    let
        info =
            Maybe.withDefault Proto.Jonline.defaultServerInfo config.serverInfo

        name =
            info.name
                |> Maybe.andThen (\n -> ifNonEmpty n)
                |> Maybe.withDefault host

        logoUrl =
            info.logo
                |> Maybe.andThen .squareMediaId
                |> Maybe.map (\id -> grpcHost host ++ "/media/" ++ id)
    in
    { name = name
    , logoUrl = logoUrl
    , primary = info.colors |> Maybe.andThen .primary |> Maybe.map swatchFromArgb |> Maybe.withDefault fallbackSwatch
    , secondary = info.colors |> Maybe.andThen .navigation |> Maybe.map swatchFromArgb |> Maybe.withDefault fallbackSwatch
    }


ifNonEmpty : String -> Maybe String
ifNonEmpty s =
    if String.isEmpty s then
        Nothing

    else
        Just s


swatchFromArgb : Int -> Swatch
swatchFromArgb argb =
    let
        rgb =
            { r = Bitwise.and 0xFF (Bitwise.shiftRightBy 16 argb)
            , g = Bitwise.and 0xFF (Bitwise.shiftRightBy 8 argb)
            , b = Bitwise.and 0xFF argb
            }
    in
    { hex = toHexColor rgb, contrastText = contrastingTextColor rgb }


toHexColor : { r : Int, g : Int, b : Int } -> String
toHexColor { r, g, b } =
    "#" ++ toHexByte r ++ toHexByte g ++ toHexByte b


toHexByte : Int -> String
toHexByte n =
    let
        hexDigit d =
            String.slice d (d + 1) "0123456789abcdef"
    in
    hexDigit (n // 16) ++ hexDigit (modBy 16 n)


{-| Whether black or white text reads better on top of a color, via the WCAG
relative-luminance formula (a couple of `^2.4`s per channel). Computed once
here, when a server's colors first arrive over the network, and cached in the
model from then on rather than recomputed on every render.
-}
contrastingTextColor : { r : Int, g : Int, b : Int } -> String
contrastingTextColor { r, g, b } =
    let
        linear c =
            let
                s =
                    toFloat c / 255
            in
            if s <= 0.03928 then
                s / 12.92

            else
                ((s + 0.055) / 1.055) ^ 2.4

        luminance =
            0.2126 * linear r + 0.7152 * linear g + 0.0722 * linear b
    in
    if luminance > 0.179 then
        "#000000"

    else
        "#ffffff"


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
-- Branding is never persisted -- it's re-fetched each session.


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
        , ( "avatarMediaId", account.avatarMediaId |> Maybe.map Encode.string |> Maybe.withDefault Encode.null )
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
    Decode.map7 Account
        (Decode.field "server" Decode.string)
        (Decode.field "userId" Decode.string)
        (Decode.field "username" Decode.string)
        (Decode.field "refreshToken" tokenDecoder)
        (Decode.field "accessToken" tokenDecoder)
        (Decode.field "enabled" Decode.bool)
        (optionalString "avatarMediaId")


serverDecoder : Decoder Server
serverDecoder =
    Decode.map2 (\host enabled -> { host = host, enabled = enabled, branding = BrandingUnknown })
        (Decode.field "host" Decode.string)
        (Decode.field "enabled" Decode.bool)


tokenDecoder : Decoder ExpirableToken
tokenDecoder =
    Decode.map (\token -> { token = token, expiresAt = Nothing }) Decode.string


optionalString : String -> Decoder (Maybe String)
optionalString field =
    Decode.maybe (Decode.field field (Decode.nullable Decode.string))
        |> Decode.map (Maybe.andThen identity)
