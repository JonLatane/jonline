module Shared.AccountsPanel exposing
    ( Account
    , AccountForm
    , AddServerForm
    , Branding
    , FormStatus(..)
    , Model
    , Msg(..)
    , Server
    , accountAvatarUrl
    , accountId
    , accountsMenuLabel
    , brandingFor
    , hasAdminAccount
    , init
    , isAdmin
    , mainServerTheme
    , serverHasAccounts
    , serverThemeFor
    , serverThemeOf
    , update
    )

{-| Everything behind the Accounts Panel: known servers, signed-into accounts,
the login/add-server forms, and the connectivity logic (host negotiation,
CDN backend_host discovery) that gets you from a typed-in hostname to a
working connection.
-}

import Grpc
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports
import Proto.Jonline exposing (RefreshTokenResponse, ServerConfiguration, User)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.Permission exposing (Permission(..), fieldNumbersPermission)
import Proto.Jonline.WebUserInterface exposing (WebUserInterface)
import Request exposing (Request)
import Shared.MaybeAccountRequest as MaybeAccountRequest exposing (Token)
import Task exposing (Task)
import Time
import UI.ServerTheme
import Url


{-| A signed-into account on a server (identified by its `frontendHost`, e.g.
"jonline.io" -- see `Server`). `enabled` is a lightweight, non-destructive
"signed in/out" toggle: disabling an account keeps its tokens around so it can
be re-enabled without logging in again. Fully forgetting an account
(`RemoveAccountClicked`) is the "traditional" sign out.

`permissions` is refreshed via `GetCurrentUser` whenever the account's server
reconnects (app startup/reload, or the account being re-enabled) -- see
`refreshPermissions` -- so it's usually current, though it can still lag
between those refreshes if permissions change server-side.
-}
type alias Account =
    { server : String
    , userId : String
    , username : String
    , refreshToken : Token
    , accessToken : Token
    , enabled : Bool
    , avatarMediaId : Maybe String
    , permissions : List Permission
    }


{-| A server the app knows how to talk to. A `Server` only ever exists once
we've actually connected to it (see `negotiateServerConfig`), so `backendHost`/
`port_`/`tls` are always the combination that's known to work, and
`configuration` is always real data -- never a placeholder.

`frontendHost` is the server's public identity, e.g. "jonline.io" -- what a
user types in and what accounts are keyed by. `backendHost` is where its gRPC
API actually lives, e.g. "jonline.io.getj.online" behind a CDN -- discovered
via `GET {frontendHost}/backend_host` (see `discoverBackendHost`). They're
often the same host.

`enabled` controls whether the server's (eventually public) data is included
when aggregating data across servers.
-}
type alias Server =
    { frontendHost : String
    , backendHost : String
    , port_ : Int
    , tls : Bool
    , enabled : Bool
    , configuration : ServerConfiguration
    , branding : Branding
    }


{-| A server's user-facing identity: its name, square logo (if any), and its
primary/nav brand colors -- decomposed into `UI.ServerTheme.ColorMeta` (text
color, light/dark variants) once, when `configuration` first arrives (see
`brandingFromConfig`), and cached here rather than recomputed on every
render. Combine with the app's current dark/light mode via
`serverThemeOf`/`serverThemeFor` to get the full `UI.ServerTheme.ServerTheme`.
-}
type alias Branding =
    { name : String
    , logoUrl : Maybe String
    , primary : UI.ServerTheme.ColorMeta
    , nav : UI.ServerTheme.ColorMeta
    }


{-| Where a `Server` lives: enough to build a URL, before we know anything
else about it.
-}
type alias Connection =
    { frontendHost : String
    , backendHost : String
    , port_ : Int
    , tls : Bool
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

    -- The host this app is actually being viewed from (immutable for the
    -- session -- it's a plain SPA reload to change it).
    , browsingHost : String

    -- The server that host resolves to, once known: usually `browsingHost`
    -- itself, but corrected to a CDN's public `frontendHost` if `browsingHost`
    -- turns out to be a backend host presenting a different public identity
    -- (see `resolvedFrontendHost`). A mismatch between the two is shown as a
    -- warning. This is also (ordinarily) the one server entry the user isn't
    -- allowed to remove from the Accounts Panel -- see `MainServerSelected`
    -- for how an admin can change it.
    , mainFrontendHost : String
    }


type Msg
    = ServerChanged String
    | UsernameChanged String
    | PasswordChanged String
    | LoginClicked
    | CreateAccountClicked
    | GotAuthResult (Result Grpc.Error ( Connection, ServerConfiguration, RefreshTokenResponse ))
    | GotReconnectResult Bool (Result Grpc.Error ( Connection, ServerConfiguration ))
    | GotMainServerResult (Result Grpc.Error ( Connection, ServerConfiguration ))
    | ToggleAccountEnabled String
    | RemoveAccountClicked String
    | ToggleServerEnabled String
    | ServerHostInputChanged String
    | AddServerClicked
    | GotNewServerResult (Result Grpc.Error ( Connection, ServerConfiguration ))
    | RemoveServerClicked String
    | ToggleAccountsPanel
    | GotPermissionsRefresh String (Result Grpc.Error ( Account, User ))
    | MainServerSelected String
    | SetWebUserInterfaceClicked String WebUserInterface
    | GotSetWebUserInterfaceResult String (Result Grpc.Error ( Account, ServerConfiguration ))


{-| A stable identifier for an account: a user's id is only unique per-server.
-}
accountId : Account -> String
accountId account =
    account.server ++ "|" ++ account.userId


{-| Whether an account has the `ADMIN` permission.
-}
isAdmin : Account -> Bool
isAdmin account =
    List.member ADMIN account.permissions


{-| Whether any *signed-in* (enabled) account has `ADMIN` on its server --
gates showing the Server Admin Panel button at all.
-}
hasAdminAccount : Model -> Bool
hasAdminAccount model =
    List.any (\a -> a.enabled && isAdmin a) model.accounts


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
accountAvatarUrl : List Server -> Account -> Maybe String
accountAvatarUrl servers account =
    account.avatarMediaId
        |> Maybe.andThen
            (\id ->
                servers
                    |> List.filter (\s -> s.frontendHost == account.server)
                    |> List.head
                    |> Maybe.map
                        (\s ->
                            mediaBaseUrl (connectionOf s)
                                ++ "/media/"
                                ++ id
                                ++ "?authorization="
                                ++ account.accessToken.token
                        )
            )


{-| A server's branding, looked up by its `frontendHost` (for e.g. an
account's `server` field, cross-referenced against the server list), falling
back to the bare hostname and neutral colors if that server isn't known.
-}
brandingFor : List Server -> String -> Branding
brandingFor servers frontendHost =
    servers
        |> List.filter (\s -> s.frontendHost == frontendHost)
        |> List.head
        |> Maybe.map .branding
        |> Maybe.withDefault (defaultBranding frontendHost)


defaultBranding : String -> Branding
defaultBranding frontendHost =
    { name = frontendHost
    , logoUrl = Nothing
    , primary = UI.ServerTheme.neutralColorMeta
    , nav = UI.ServerTheme.neutralColorMeta
    }


{-| The full color theme for a server, combining its cached `branding` with
the app's current dark/light mode (`Shared.effectiveDarkMode`). Cheap -- fine
to call on every render.
-}
serverThemeOf : Bool -> Server -> UI.ServerTheme.ServerTheme
serverThemeOf darkMode server =
    UI.ServerTheme.fromColorMetas darkMode server.branding.primary server.branding.nav


{-| Like `serverThemeOf`, but looks a server up by `frontendHost` (for e.g. an
account's `server` field).
-}
serverThemeFor : Bool -> Model -> String -> UI.ServerTheme.ServerTheme
serverThemeFor darkMode model frontendHost =
    let
        branding =
            brandingFor model.servers frontendHost
    in
    UI.ServerTheme.fromColorMetas darkMode branding.primary branding.nav


{-| The theme for chrome that isn't scoped to any one server/account row (nav
links, form buttons, etc.) -- currently always `mainFrontendHost`'s theme.
-}
mainServerTheme : Bool -> Model -> UI.ServerTheme.ServerTheme
mainServerTheme darkMode model =
    serverThemeFor darkMode model model.mainFrontendHost


init : Request -> Flags -> ( Model, Cmd Msg )
init req flags =
    let
        persisted =
            Decode.decodeValue persistedStateDecoder flags
                |> Result.withDefault emptyPersistedState

        pageIsSecure =
            isSecure req

        browsingHost =
            req.url.host

        -- The app is very often served up by a Jonline server itself, so whichever
        -- host it's being viewed from is worth auto-connecting to, same as any other
        -- server. If it's already a known server, this is a no-op -- the persisted
        -- entry (and its enabled flag) wins, and we already know it's not a
        -- backend-only host (see `GotMainServerResult`), so no correction is needed.
        browsingHostAlreadyKnown =
            List.any (\s -> s.frontendHost == browsingHost) persisted.servers

        mainServerCmd =
            if browsingHostAlreadyKnown then
                Cmd.none

            else
                negotiateServerConfig pageIsSecure browsingHost
                    |> Task.attempt GotMainServerResult

        reconnectCmds =
            List.map
                (\ps ->
                    negotiateServerConfig pageIsSecure ps.frontendHost
                        |> Task.attempt (GotReconnectResult ps.enabled)
                )
                persisted.servers
    in
    ( { accounts = persisted.accounts
      , servers = []
      , accountForm = emptyForm
      , addServerForm = emptyAddServerForm
      , showAccountsPanel = False
      , browsingHost = browsingHost
      , mainFrontendHost = browsingHost
      }
    , Cmd.batch (mainServerCmd :: reconnectCmds)
    )


{-| Whether the page itself was loaded over TLS -- if so, we only ever try
TLS candidates for a new host, since a secure page can't make plaintext
requests (mixed content). Only an insecure (e.g. local dev) page falls back
to trying plaintext ports too.
-}
isSecure : Request -> Bool
isSecure req =
    req.url.protocol == Url.Https


emptyForm : AccountForm
emptyForm =
    { server = "localhost"
    , username = ""
    , password = ""
    , status = Idle
    }


emptyAddServerForm : AddServerForm
emptyAddServerForm =
    { host = "", status = Idle }


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
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
            , resolveHost (isSecure req) model.servers form.server
                |> Task.andThen
                    (\( connection, config ) ->
                        Grpc.new Jonline.login
                            { username = form.username
                            , password = form.password
                            , expiresAt = Nothing
                            , deviceName = Nothing
                            , userId = Nothing
                            }
                            |> Grpc.setHost (connectionUrl connection)
                            |> Grpc.toTask
                            |> Task.map (\resp -> ( connection, config, resp ))
                    )
                |> Task.attempt GotAuthResult
            )

        CreateAccountClicked ->
            let
                form =
                    model.accountForm
            in
            ( updateForm (\f -> { f | status = Submitting }) model
            , resolveHost (isSecure req) model.servers form.server
                |> Task.andThen
                    (\( connection, config ) ->
                        Grpc.new Jonline.createAccount
                            { username = form.username
                            , password = form.password
                            , email = Nothing
                            , phone = Nothing
                            , expiresAt = Nothing
                            , deviceName = Nothing
                            }
                            |> Grpc.setHost (connectionUrl connection)
                            |> Grpc.toTask
                            |> Task.map (\resp -> ( connection, config, resp ))
                    )
                |> Task.attempt GotAuthResult
            )

        GotAuthResult (Ok ( connection, config, resp )) ->
            case ( resp.user, resp.refreshToken, resp.accessToken ) of
                ( Just user, Just refreshToken, Just accessToken ) ->
                    let
                        account =
                            { server = connection.frontendHost
                            , userId = user.id
                            , username = user.username
                            , refreshToken = MaybeAccountRequest.tokenFromExpirable refreshToken
                            , accessToken = MaybeAccountRequest.tokenFromExpirable accessToken
                            , enabled = True
                            , avatarMediaId = Maybe.map .id user.avatar
                            , permissions = user.permissions
                            }

                        alreadyKnown =
                            List.any (\s -> s.frontendHost == connection.frontendHost) model.servers

                        newModel =
                            { model
                                | accounts = upsertAccount account model.accounts
                                , servers =
                                    if alreadyKnown then
                                        model.servers

                                    else
                                        model.servers ++ [ serverFrom connection True config ]
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

        GotReconnectResult enabled result ->
            case result of
                Ok ( connection, config ) ->
                    let
                        server =
                            serverFrom connection enabled config

                        newModel =
                            { model | servers = model.servers ++ [ server ] }
                    in
                    -- Persisting here is a no-op for a server that was already known, but is
                    -- how a freshly auto-detected "current host" server (see `init`) gets saved.
                    -- Also refresh permissions for any of its enabled accounts now that we can
                    -- actually reach it -- this is what makes permissions current on app
                    -- startup/reload, not just after a fresh login.
                    ( newModel
                    , Cmd.batch [ persist newModel, refreshPermissionsForServer server newModel.accounts ]
                    )

                Err _ ->
                    -- Couldn't reconnect (server's down, moved, etc.); leave it out of the
                    -- list rather than showing a permanently-broken entry. Its host/enabled
                    -- flag is still safe in localStorage in case it comes back.
                    ( model, Cmd.none )

        GotMainServerResult result ->
            case result of
                Ok ( connection, config ) ->
                    let
                        -- If the host we're browsing from turns out to be a backend-only
                        -- host presenting a different public identity (e.g. we ended up on
                        -- jonline.io.getj.online, a CDN's backend, when jonline.io is the
                        -- real front door), treat *that* as the main server instead --
                        -- exactly as if the user had typed it in directly.
                        resolvedFrontend =
                            resolvedFrontendHost model.browsingHost config

                        correctedConnection =
                            { connection | frontendHost = resolvedFrontend }

                        alreadyKnown =
                            List.any (\s -> s.frontendHost == resolvedFrontend) model.servers

                        server =
                            serverFrom correctedConnection True config

                        newModel =
                            { model
                                | mainFrontendHost = resolvedFrontend
                                , servers =
                                    if alreadyKnown then
                                        model.servers

                                    else
                                        model.servers ++ [ server ]
                            }
                    in
                    ( newModel
                    , Cmd.batch [ persist newModel, refreshPermissionsForServer server newModel.accounts ]
                    )

                Err _ ->
                    ( model, Cmd.none )

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

                justEnabledAccount =
                    newModel.accounts
                        |> List.filter (\a -> accountId a == id && a.enabled)
                        |> List.head

                refreshCmd =
                    justEnabledAccount
                        |> Maybe.andThen
                            (\account ->
                                model.servers
                                    |> List.filter (\s -> s.frontendHost == account.server)
                                    |> List.head
                                    |> Maybe.map (\server -> refreshPermissions server account)
                            )
                        |> Maybe.withDefault Cmd.none
            in
            ( newModel, Cmd.batch [ persist newModel, refreshCmd ] )

        RemoveAccountClicked id ->
            let
                newModel =
                    { model | accounts = List.filter (\account -> accountId account /= id) model.accounts }
            in
            ( newModel, persist newModel )

        ToggleServerEnabled frontendHost ->
            let
                newModel =
                    { model
                        | servers =
                            List.map
                                (\server ->
                                    if server.frontendHost == frontendHost then
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

            else if List.any (\s -> s.frontendHost == host) model.servers then
                ( updateAddServerForm (\f -> { f | status = Errored "That server is already in your list." }) model
                , Cmd.none
                )

            else
                ( updateAddServerForm (\f -> { f | status = Submitting }) model
                , negotiateServerConfig (isSecure req) host
                    |> Task.attempt GotNewServerResult
                )

        GotNewServerResult result ->
            case result of
                Ok ( connection, config ) ->
                    let
                        newModel =
                            { model
                                | servers = model.servers ++ [ serverFrom connection True config ]
                                , addServerForm = emptyAddServerForm
                            }
                    in
                    ( newModel, persist newModel )

                Err err ->
                    ( updateAddServerForm (\f -> { f | status = Errored (grpcErrorToString err) }) model
                    , Cmd.none
                    )

        RemoveServerClicked frontendHost ->
            if serverHasAccounts model.accounts frontendHost || frontendHost == model.mainFrontendHost then
                ( model, Cmd.none )

            else
                let
                    newModel =
                        { model | servers = List.filter (\s -> s.frontendHost /= frontendHost) model.servers }
                in
                ( newModel, persist newModel )

        ToggleAccountsPanel ->
            ( { model | showAccountsPanel = not model.showAccountsPanel }, Cmd.none )

        GotPermissionsRefresh _ result ->
            case result of
                Ok ( refreshedAccount, user ) ->
                    let
                        mergedAccount =
                            { refreshedAccount
                                | username = user.username
                                , permissions = user.permissions
                                , avatarMediaId = Maybe.map .id user.avatar
                            }

                        newModel =
                            { model | accounts = upsertAccount mergedAccount model.accounts }
                    in
                    ( newModel, persist newModel )

                Err _ ->
                    -- Server unreachable, refresh token rejected, etc. -- leave the account as
                    -- it was; it'll be retried on the next reconnect/enable.
                    ( model, Cmd.none )

        MainServerSelected frontendHost ->
            if List.any (\s -> s.frontendHost == frontendHost) model.servers then
                let
                    newModel =
                        { model | mainFrontendHost = frontendHost }
                in
                ( newModel, persist newModel )

            else
                ( model, Cmd.none )

        SetWebUserInterfaceClicked id ui ->
            let
                maybeAccount =
                    model.accounts |> List.filter (\a -> accountId a == id) |> List.head

                maybeServer =
                    maybeAccount
                        |> Maybe.andThen (\a -> model.servers |> List.filter (\s -> s.frontendHost == a.server) |> List.head)
            in
            case ( maybeAccount, maybeServer ) of
                ( Just account, Just server ) ->
                    ( model, setWebUserInterface server account ui )

                _ ->
                    ( model, Cmd.none )

        GotSetWebUserInterfaceResult _ result ->
            case result of
                Ok ( refreshedAccount, newConfig ) ->
                    let
                        newModel =
                            { model
                                | accounts = upsertAccount refreshedAccount model.accounts
                                , servers =
                                    List.map
                                        (\s ->
                                            if s.frontendHost == refreshedAccount.server then
                                                { s | configuration = newConfig, branding = brandingFromConfig (connectionOf s) newConfig }

                                            else
                                                s
                                        )
                                        model.servers
                            }
                    in
                    ( newModel, persist newModel )

                Err _ ->
                    -- Server unreachable, refresh token rejected, etc. -- the toggle just
                    -- doesn't visibly change; the admin can retry.
                    ( model, Cmd.none )


{-| A server that has any associated accounts can't be removed (only disabled),
since removing it would orphan those accounts' stored credentials.
-}
serverHasAccounts : List Account -> String -> Bool
serverHasAccounts accounts frontendHost =
    List.any (\a -> a.server == frontendHost) accounts


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


serverFrom : Connection -> Bool -> ServerConfiguration -> Server
serverFrom connection enabled config =
    { frontendHost = connection.frontendHost
    , backendHost = connection.backendHost
    , port_ = connection.port_
    , tls = connection.tls
    , enabled = enabled
    , configuration = config
    , branding = brandingFromConfig connection config
    }


connectionOf : Server -> Connection
connectionOf server =
    { frontendHost = server.frontendHost, backendHost = server.backendHost, port_ = server.port_, tls = server.tls }


{-| Refreshes an account's `permissions` (and `username`, in case it changed
server-side) via `GetCurrentUser`, refreshing its access token first if
needed -- see `Shared.MaybeAccountRequest`. Fired whenever `account`'s server
reconnects (app startup/reload) or the account is (re-)enabled, so permissions
granted/revoked elsewhere stay current without the user doing anything.
-}
refreshPermissions : Server -> Account -> Cmd Msg
refreshPermissions server account =
    MaybeAccountRequest.perform
        { host = server.backendHost, port_ = server.port_, tls = server.tls }
        account
        (\accessToken ->
            Grpc.new Jonline.getCurrentUser {}
                |> Grpc.setHost (connectionUrl (connectionOf server))
                |> Grpc.addHeader "authorization" accessToken
                |> Grpc.toTask
        )
        |> Task.attempt (GotPermissionsRefresh (accountId account))


{-| `refreshPermissions` for every enabled account on the given server. -}
refreshPermissionsForServer : Server -> List Account -> Cmd Msg
refreshPermissionsForServer server accounts =
    accounts
        |> List.filter (\a -> a.enabled && a.server == server.frontendHost)
        |> List.map (refreshPermissions server)
        |> Cmd.batch


{-| Sets which frontend (`/`, `/flutter`, or `/elm`) `server` serves at its
root, via `ConfigureServer`, authenticated as `account` (refreshing its access
token first if needed -- see `Shared.MaybeAccountRequest`). Only ever invoked
for accounts with `ADMIN` on `server` (see `UI.elm`'s admin account panel);
the server itself also validates that permission.

`ConfigureServer` replaces the whole configuration rather than merging one
field, so this starts from the server's actual last-known `configuration`
(not any locally-edited-but-unsaved form state elsewhere) and only changes
`webUserInterface` within it.
-}
setWebUserInterface : Server -> Account -> WebUserInterface -> Cmd Msg
setWebUserInterface server account ui =
    let
        config =
            server.configuration

        info =
            Maybe.withDefault Proto.Jonline.defaultServerInfo config.serverInfo

        newConfig =
            { config | serverInfo = Just { info | webUserInterface = Just ui } }
    in
    MaybeAccountRequest.perform
        { host = server.backendHost, port_ = server.port_, tls = server.tls }
        account
        (\accessToken ->
            Grpc.new Jonline.configureServer newConfig
                |> Grpc.setHost (connectionUrl (connectionOf server))
                |> Grpc.addHeader "authorization" accessToken
                |> Grpc.toTask
        )
        |> Task.attempt (GotSetWebUserInterfaceResult (accountId account))


{-| A server's configuration can declare (via `externalCdnConfig`) that it's
really meant to be reached at a different public `frontendHost` than the one
we just connected to -- e.g. we're on jonline.io.getj.online, a CDN's backend
host, when it's actually configured to look like jonline.io. Falls back to
the host we connected to if there's no such declaration.
-}
resolvedFrontendHost : String -> ServerConfiguration -> String
resolvedFrontendHost connectedHost config =
    config.externalCdnConfig
        |> Maybe.map .frontendHost
        |> Maybe.andThen ifNonEmpty
        |> Maybe.withDefault connectedHost



-- CONNECTING


{-| Candidate (port, tls) combinations to try, in order, against a server's
backend host, once we know it: TLS on the standard gRPC port, then TLS on the
standard HTTPS port; and, only when this page itself isn't loaded over TLS (a
secure page can't make plaintext requests), fall back to plaintext on the
gRPC port, then 80, then 8000, for local/dev servers.
-}
candidatePorts : Bool -> List ( Int, Bool )
candidatePorts pageIsSecure =
    let
        secure =
            [ ( 27707, True ), ( 443, True ) ]

        insecure =
            [ ( 27707, False ), ( 80, False ), ( 8000, False ) ]
    in
    if pageIsSecure then
        secure

    else
        secure ++ insecure


{-| Reuses an already-connected server's known-good connection and cached
configuration if we have one; otherwise negotiates a fresh connection.
-}
resolveHost : Bool -> List Server -> String -> Task Grpc.Error ( Connection, ServerConfiguration )
resolveHost pageIsSecure servers frontendHost =
    case List.filter (\s -> s.frontendHost == frontendHost) servers |> List.head of
        Just server ->
            Task.succeed ( connectionOf server, server.configuration )

        Nothing ->
            negotiateServerConfig pageIsSecure frontendHost


{-| Connects to a server given only its public (`frontendHost`) identity:
first discovers its real backend host (in case it's served from behind a CDN,
see `discoverBackendHost`), then tries each candidate port/TLS combination
against that backend host in turn, stopping at the first one that
successfully returns server configuration -- which doubles as the
connectivity check ("can we talk to a server here at all?") and a useful
result (its configuration) at the same time.
-}
negotiateServerConfig : Bool -> String -> Task Grpc.Error ( Connection, ServerConfiguration )
negotiateServerConfig pageIsSecure frontendHost =
    discoverBackendHost pageIsSecure frontendHost
        |> Task.andThen
            (\backendHost ->
                let
                    tryCandidates candidates =
                        case candidates of
                            [] ->
                                Task.fail Grpc.NetworkError

                            ( port_, tls ) :: rest ->
                                let
                                    connection =
                                        { frontendHost = frontendHost, backendHost = backendHost, port_ = port_, tls = tls }
                                in
                                Grpc.new Jonline.getServerConfiguration {}
                                    |> Grpc.setHost (connectionUrl connection)
                                    |> Grpc.toTask
                                    |> Task.map (Tuple.pair connection)
                                    |> Task.onError (\_ -> tryCandidates rest)
                in
                tryCandidates (candidatePorts pageIsSecure)
            )


{-| A server's public "frontend" host may just be serving a web app that
points browsers at a different "backend" host for the actual gRPC API (e.g.
to sit behind a CDN that can't proxy gRPC-web) -- discoverable via a plain
`GET {frontendHost}/backend_host`, tried over HTTPS/443 then (only when this
page itself isn't secure) HTTP/80. Falls back to `frontendHost` itself
(meaning "no redirection") if that fails or comes back empty; never fails.
-}
discoverBackendHost : Bool -> String -> Task x String
discoverBackendHost pageIsSecure frontendHost =
    let
        tryTls tlsFlags =
            case tlsFlags of
                [] ->
                    Task.succeed frontendHost

                tls :: rest ->
                    Http.task
                        { method = "GET"
                        , headers = []
                        , url = (if tls then "https://" else "http://") ++ frontendHost ++ "/backend_host"
                        , body = Http.emptyBody
                        , resolver =
                            Http.stringResolver
                                (\response ->
                                    case response of
                                        Http.GoodStatus_ _ body ->
                                            Ok body

                                        _ ->
                                            Err ()
                                )
                        , timeout = Just 5000
                        }
                        |> Task.map
                            (\body ->
                                case String.trim body of
                                    "" ->
                                        frontendHost

                                    backendHost ->
                                        backendHost
                            )
                        |> Task.onError (\_ -> tryTls rest)
    in
    tryTls
        (if pageIsSecure then
            [ True ]

         else
            [ True, False ]
        )
        |> Task.onError (\_ -> Task.succeed frontendHost)


connectionUrl : Connection -> String
connectionUrl connection =
    (if connection.tls then
        "https://"

     else
        "http://"
    )
        ++ connection.backendHost
        ++ ":"
        ++ String.fromInt connection.port_


{-| Media (avatars, server logos) is served over plain HTTP(S) on the standard
web port -- not the gRPC(-web) port a `Connection` was negotiated against for
actual API calls -- so this omits the port entirely (the browser defaults to
80/443 per scheme).
-}
mediaBaseUrl : Connection -> String
mediaBaseUrl connection =
    (if connection.tls then
        "https://"

     else
        "http://"
    )
        ++ connection.backendHost


brandingFromConfig : Connection -> ServerConfiguration -> Branding
brandingFromConfig connection config =
    let
        info =
            Maybe.withDefault Proto.Jonline.defaultServerInfo config.serverInfo

        name =
            info.name
                |> Maybe.andThen ifNonEmpty
                |> Maybe.withDefault connection.frontendHost

        logoUrl =
            info.logo
                |> Maybe.andThen .squareMediaId
                |> Maybe.map (\id -> mediaBaseUrl connection ++ "/media/" ++ id)

        primaryArgb =
            info.colors |> Maybe.andThen .primary |> Maybe.withDefault 0x424242

        navArgb =
            info.colors |> Maybe.andThen .navigation |> Maybe.withDefault 0xFFFFFF
    in
    { name = name
    , logoUrl = logoUrl
    , primary = UI.ServerTheme.colorMetaFromArgb primaryArgb
    , nav = UI.ServerTheme.colorMetaFromArgb navArgb
    }


ifNonEmpty : String -> Maybe String
ifNonEmpty s =
    if String.isEmpty s then
        Nothing

    else
        Just s


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
-- Tokens are stored with their expiration (if any), so an access token that's
-- expired (or about to) while the app was closed is refreshed on next use
-- rather than trusted as-is -- see `Shared.MaybeAccountRequest`.
-- Servers are persisted as just their frontendHost + enabled flag: backendHost/
-- port/tls/configuration are all rediscovered by reconnecting each session
-- rather than trusted from a (possibly stale) previous one.


type alias Flags =
    Decode.Value


persist : Model -> Cmd Msg
persist model =
    Ports.persist (encodeState model)


encodeState : Model -> Encode.Value
encodeState model =
    Encode.object
        [ ( "accounts", Encode.list encodeAccount model.accounts )
        , ( "servers", Encode.list encodePersistedServer model.servers )
        ]


encodeAccount : Account -> Encode.Value
encodeAccount account =
    Encode.object
        [ ( "server", Encode.string account.server )
        , ( "userId", Encode.string account.userId )
        , ( "username", Encode.string account.username )
        , ( "refreshToken", encodeToken account.refreshToken )
        , ( "accessToken", encodeToken account.accessToken )
        , ( "enabled", Encode.bool account.enabled )
        , ( "avatarMediaId", account.avatarMediaId |> Maybe.map Encode.string |> Maybe.withDefault Encode.null )
        , ( "permissions", Encode.list (fieldNumbersPermission >> Encode.int) account.permissions )
        ]


encodeToken : Token -> Encode.Value
encodeToken token =
    Encode.object
        [ ( "token", Encode.string token.token )
        , ( "expiresAt", token.expiresAt |> Maybe.map (Time.posixToMillis >> Encode.int) |> Maybe.withDefault Encode.null )
        ]


encodePersistedServer : Server -> Encode.Value
encodePersistedServer server =
    Encode.object
        [ ( "frontendHost", Encode.string server.frontendHost )
        , ( "enabled", Encode.bool server.enabled )
        ]


type alias PersistedServer =
    { frontendHost : String
    , enabled : Bool
    }


type alias PersistedState =
    { accounts : List Account
    , servers : List PersistedServer
    }


emptyPersistedState : PersistedState
emptyPersistedState =
    { accounts = [], servers = [] }


persistedStateDecoder : Decoder PersistedState
persistedStateDecoder =
    Decode.map2 PersistedState
        (Decode.field "accounts" (Decode.list accountDecoder))
        (Decode.field "servers" (Decode.list persistedServerDecoder))


accountDecoder : Decoder Account
accountDecoder =
    Decode.map8 Account
        (Decode.field "server" Decode.string)
        (Decode.field "userId" Decode.string)
        (Decode.field "username" Decode.string)
        (Decode.field "refreshToken" tokenDecoder)
        (Decode.field "accessToken" tokenDecoder)
        (Decode.field "enabled" Decode.bool)
        (optionalString "avatarMediaId")
        permissionsDecoder


{-| Defaults to no permissions if the key is missing entirely (older
persisted state), without failing the rest of the decode.
-}
permissionsDecoder : Decoder (List Permission)
permissionsDecoder =
    Decode.oneOf
        [ Decode.field "permissions" (Decode.list (Decode.map permissionFromInt Decode.int))
        , Decode.succeed []
        ]


permissionFromInt : Int -> Permission
permissionFromInt n =
    case n of
        0 ->
            PERMISSIONUNKNOWN

        1 ->
            VIEWUSERS

        2 ->
            PUBLISHUSERSLOCALLY

        3 ->
            PUBLISHUSERSGLOBALLY

        4 ->
            MODERATEUSERS

        5 ->
            FOLLOWUSERS

        6 ->
            GRANTBASICPERMISSIONS

        10 ->
            VIEWGROUPS

        11 ->
            CREATEGROUPS

        12 ->
            PUBLISHGROUPSLOCALLY

        13 ->
            PUBLISHGROUPSGLOBALLY

        14 ->
            MODERATEGROUPS

        15 ->
            JOINGROUPS

        16 ->
            INVITEGROUPMEMBERS

        20 ->
            VIEWPOSTS

        21 ->
            CREATEPOSTS

        22 ->
            PUBLISHPOSTSLOCALLY

        23 ->
            PUBLISHPOSTSGLOBALLY

        24 ->
            MODERATEPOSTS

        25 ->
            REPLYTOPOSTS

        30 ->
            VIEWEVENTS

        31 ->
            CREATEEVENTS

        32 ->
            PUBLISHEVENTSLOCALLY

        33 ->
            PUBLISHEVENTSGLOBALLY

        34 ->
            MODERATEEVENTS

        35 ->
            RSVPTOEVENTS

        40 ->
            VIEWMEDIA

        41 ->
            CREATEMEDIA

        42 ->
            PUBLISHMEDIALOCALLY

        43 ->
            PUBLISHMEDIAGLOBALLY

        44 ->
            MODERATEMEDIA

        9998 ->
            BUSINESS

        9999 ->
            RUNBOTS

        10000 ->
            ADMIN

        10001 ->
            VIEWPRIVATECONTACTMETHODS

        other ->
            PermissionUnrecognized_ other


persistedServerDecoder : Decoder PersistedServer
persistedServerDecoder =
    Decode.map2 PersistedServer
        (Decode.field "frontendHost" Decode.string)
        (Decode.field "enabled" Decode.bool)


{-| Accepts both the current `{token, expiresAt}` shape and the older
bare-string shape (from before tokens tracked expiration), so existing
persisted accounts aren't invalidated by this change.
-}
tokenDecoder : Decoder Token
tokenDecoder =
    Decode.oneOf
        [ Decode.map2 Token
            (Decode.field "token" Decode.string)
            (Decode.maybe (Decode.field "expiresAt" (Decode.nullable Decode.int))
                |> Decode.map (Maybe.andThen identity >> Maybe.map Time.millisToPosix)
            )
        , Decode.map (\token -> { token = token, expiresAt = Nothing }) Decode.string
        ]


optionalString : String -> Decoder (Maybe String)
optionalString field =
    Decode.maybe (Decode.field field (Decode.nullable Decode.string))
        |> Decode.map (Maybe.andThen identity)
