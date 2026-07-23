module Components.Pages.ServerInformationPage exposing (Model, Msg, fromShared, init, subscriptions, titleFor, update, view)

{-| The shared guts of a read-only Jonline server detail page -- reused by
`Pages.Server.ServerIdentifier_` (`/server/[http|https]:hostname`, an
arbitrary server) and `Pages.About` (always `mainFrontendHost`, shown above
the app's own "About Jonline" blurb). Mirrors `Components.Pages.UserProfilePage`,
generalized the same way over "which server" that module is over "which user."

If the server's already known (added to `Shared.AccountsPanel`, i.e. the user
has it in their Accounts & Servers), its live, cached `Server` is shown.
Otherwise this page probes it itself (`AccountsPanel.connectToServer`) purely
for display -- that probe is never written back to `Shared.AccountsPanel`
unless the user explicitly clicks "Add Server" (`AddServerClicked`), which
dispatches the same `AccountsPanel.ServerConnected` used by the Accounts
panel's own "Add Server" flow. (For `Pages.About`'s `mainFrontendHost`, this
branch is essentially unreachable -- that server is always already known --
but there's no reason to special-case it out.)

Almost everything shown lives in `Server.configuration` (a `ServerConfiguration`)
-- the sole exception is the About tab's admin list, which needs its own
`GetUsers` fetch (there's no dedicated "list admins" RPC yet, so this fetches
a page of users and filters for `ADMIN` client-side, same as the Tamagui
screen does).

Renaming (via `ConfigureServer`) is the only mutation this page supports, and
only for a signed-in account with `ADMIN` on this specific server -- routed
through `Shared.AccountsPanel.RenameServerClicked` (not called directly)
so the app's cached `Server` list stays in sync with the change, same as
`UI.elm`'s web-UI toggle.

-}

import Components.Markdown as Markdown
import Components.Users as Users
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, button, div, h2, h3, img, input, label, li, p, span, text, ul)
import Html.Attributes exposing (checked, class, disabled, src, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Proto.Jonline exposing (FederatedServer, GetServiceVersionResponse, GetUsersResponse, User, defaultGetUsersRequest, defaultServerInfo)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.Permission exposing (Permission(..))
import Proto.Jonline.WebUserInterface exposing (WebUserInterface(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import Task
import UI.Classes exposing (classes)
import UI.ServerTheme as ServerTheme



-- MODEL


type Tab
    = AboutTab
    | ThemeTab
    | SettingsTab
    | FederationTab
    | CdnTab


{-| This page's own probe of the server, kept entirely separate from
`Shared.AccountsPanel.Model.servers` -- see the module doc. Irrelevant
(`OwnServerNotNeeded`) whenever the server's already known.
-}
type OwnServerStatus
    = OwnServerNotNeeded
    | LoadingOwnServer
    | OwnServerLoaded AccountsPanel.Server
    | OwnServerFailed String


type AdminsStatus
    = AdminsNotLoaded
    | LoadingAdmins
    | AdminsLoaded (List User)
    | AdminsFailed


type VersionStatus
    = VersionNotLoaded
    | LoadingVersion
    | VersionLoaded String
    | VersionFailed


{-| Live only while the server's name is being edited by an admin -- `pending`
is the in-progress `<input>` value, independent of the actual name until
`RenameSaveClicked` succeeds. Mirrors `Pages.Post.PostId_`'s `VisibilityEdit`.
-}
type RenameStatus
    = NotRenaming
    | Renaming String AccountsPanel.FormStatus


type alias Model =
    { targetHost : String
    , isSecure : Bool
    , ownServerStatus : OwnServerStatus
    , activeTab : Tab
    , adminsStatus : AdminsStatus
    , versionStatus : VersionStatus
    , renameStatus : RenameStatus
    }


{-| `pageIsSecure` is `Shared.AccountsPanel.isSecure req` (`Pages.About`) or
parsed straight out of the route (`Pages.Server.ServerIdentifier_`'s
`[http|https]:hostname` segment) -- needed for the own-probe fallback (see
`AccountsPanel.connectToServer`), but not otherwise derivable from
`Shared.Model` alone.
-}
init : Shared.Model -> Bool -> String -> ( Model, Effect Msg )
init shared pageIsSecure targetHost =
    let
        model0 =

            { targetHost = targetHost
            , isSecure = pageIsSecure
            , ownServerStatus = LoadingOwnServer
            , activeTab = AboutTab
            , adminsStatus = AdminsNotLoaded
            , versionStatus = VersionNotLoaded
            , renameStatus = NotRenaming
            }
        ( fetchedModel, fetchEffect ) =
            case AccountsPanel.serverForHost shared.accountsPanel.servers targetHost of
                Just server ->
                    ( { model0 | ownServerStatus = OwnServerNotNeeded, adminsStatus = LoadingAdmins, versionStatus = LoadingVersion }
                    , Effect.batch [ fetchAdmins server, fetchVersion server ]
                    )

                Nothing ->
                    ( model0
                    , AccountsPanel.connectToServer pageIsSecure targetHost
                        |> Task.attempt GotOwnServerResult
                        |> Effect.fromCmd
                    )
    in
    ( fetchedModel
      -- Closes the Accounts Panel if it happened to be open -- landing on
      -- either of this component's pages (`Pages.About`/
      -- `Pages.Server.ServerIdentifier_`) always shows the info it'd
      -- otherwise duplicate, so leaving the panel open reads as redundant.
    , Effect.batch [ fetchEffect, closeAccountsPanelEffect ]
    )


{-| Closes the Accounts Panel, if it's open -- see `init`'s own doc.
-}
closeAccountsPanelEffect : Effect Msg
closeAccountsPanelEffect =
    Effect.fromShared (Shared.AccountsPanelMsg AccountsPanel.CloseAccountsPanel)


{-| The `Server` to actually show details for -- whichever the app already
knows about (from `Shared.AccountsPanel`, if this server's been added to
Accounts & Servers already), falling back to this page's own probe
(`ownServerStatus`) otherwise.
-}
effectiveServer : Shared.Model -> Model -> Maybe AccountsPanel.Server
effectiveServer shared model =
    case AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost of
        Just server ->
            Just server

        Nothing ->
            case model.ownServerStatus of
                OwnServerLoaded server ->
                    Just server

                _ ->
                    Nothing


isKnownServer : Shared.Model -> Model -> Bool
isKnownServer shared model =
    AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost /= Nothing


{-| `model.targetHost`/`isSecure` reassembled into the `[http|https]:hostname`
form `Pages.Server.ServerIdentifier_`'s route uses -- just for error messages
here (see `view`'s `OwnServerFailed` branch); this module has no route of its
own to round-trip through.
-}
identifierText : Model -> String
identifierText model =
    (if model.isSecure then
        "https:"

     else
        "http:"
    )
        ++ model.targetHost


fetchAdmins : AccountsPanel.Server -> Effect Msg
fetchAdmins server =
    Grpc.new Jonline.getUsers defaultGetUsersRequest
        |> Grpc.setHost (AccountsPanel.serverUrl server)
        |> Grpc.toTask
        |> Task.attempt GotAdmins
        |> Effect.fromCmd


fetchVersion : AccountsPanel.Server -> Effect Msg
fetchVersion server =
    Grpc.new Jonline.getServiceVersion {}
        |> Grpc.setHost (AccountsPanel.serverUrl server)
        |> Grpc.toTask
        |> Task.attempt GotVersion
        |> Effect.fromCmd


{-| The signed-in, enabled account (if any) on this specific server, but only
if it actually has `ADMIN` -- what gates the Rename button/RPC. Renaming (or
any other `ConfigureServer` mutation) is only possible for a server that's
already known (see the module doc), so this only ever matches once
`isKnownServer` is `True`.
-}
adminAccountFor : Shared.Model -> Model -> Maybe AccountsPanel.Account
adminAccountFor shared model =
    AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost
        |> Maybe.andThen
            (\account ->
                if AccountsPanel.isAdmin account then
                    Just account

                else
                    Nothing
            )



-- UPDATE


type Msg
    = TabSelected Tab
    | GotOwnServerResult (Result Grpc.Error AccountsPanel.Server)
    | AddServerClicked AccountsPanel.Server
    | GotAdmins (Result Grpc.Error GetUsersResponse)
    | GotVersion (Result Grpc.Error GetServiceVersionResponse)
    | RenameClicked String
    | RenameChanged String
    | RenameCancelClicked
    | RenameSaveClicked
    | SharedMsg Shared.Msg


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
into `update`'s `SharedMsg` branch -- see `Pages.Post.PostId_.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        TabSelected tab ->
            ( { model | activeTab = tab }, Effect.none )

        GotOwnServerResult (Ok server) ->
            ( { model | ownServerStatus = OwnServerLoaded server, adminsStatus = LoadingAdmins, versionStatus = LoadingVersion }
            , Effect.batch [ fetchAdmins server, fetchVersion server ]
            )

        GotOwnServerResult (Err err) ->
            ( { model | ownServerStatus = OwnServerFailed (AccountsPanel.grpcErrorToString err) }, Effect.none )

        AddServerClicked server ->
            ( model, Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.ServerConnected server)) )

        GotAdmins (Ok response) ->
            ( { model | adminsStatus = AdminsLoaded (List.filter (\user -> List.member ADMIN user.permissions) response.users) }
            , Effect.none
            )

        GotAdmins (Err _) ->
            ( { model | adminsStatus = AdminsFailed }, Effect.none )

        GotVersion (Ok response) ->
            ( { model | versionStatus = VersionLoaded response.version }, Effect.none )

        GotVersion (Err _) ->
            ( { model | versionStatus = VersionFailed }, Effect.none )

        RenameClicked currentName ->
            ( { model | renameStatus = Renaming currentName AccountsPanel.Idle }, Effect.none )

        RenameChanged newText ->
            ( { model
                | renameStatus =
                    case model.renameStatus of
                        Renaming _ status ->
                            Renaming newText status

                        NotRenaming ->
                            NotRenaming
              }
            , Effect.none
            )

        RenameCancelClicked ->
            ( { model | renameStatus = NotRenaming }, Effect.none )

        RenameSaveClicked ->
            case ( model.renameStatus, adminAccountFor shared model ) of
                ( Renaming pendingName _, Just account ) ->
                    ( { model | renameStatus = Renaming pendingName AccountsPanel.Submitting }
                    , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.RenameServerClicked (AccountsPanel.accountId account) pendingName))
                    )

                _ ->
                    ( model, Effect.none )

        SharedMsg subMsg ->
            let
                renameStatus =
                    case subMsg of
                        Shared.AccountsPanelMsg (AccountsPanel.GotRenameServerResult _ (Ok _)) ->
                            NotRenaming

                        Shared.AccountsPanelMsg (AccountsPanel.GotRenameServerResult _ (Err err)) ->
                            case model.renameStatus of
                                Renaming pending _ ->
                                    Renaming pending (AccountsPanel.Errored (AccountsPanel.grpcErrorToString err))

                                NotRenaming ->
                                    NotRenaming

                        _ ->
                            model.renameStatus
            in
            ( { model | renameStatus = renameStatus }, Effect.fromShared subMsg )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


{-| Just the subtitle -- the server's own name once known, else its
`targetHost` -- for the calling page's own `UI.pageTitle`.
-}
titleFor : Shared.Model -> Model -> String
titleFor shared model =
    case effectiveServer shared model of
        Just server ->
            server.branding.name

        Nothing ->
            model.targetHost


view : Shared.Model -> Model -> Html Msg
view shared model =
    case effectiveServer shared model of
        Just server ->
            div [ class "server-details" ]
                [ addServerButton shared model server
                , tabBar model
                , tabContent shared model server
                ]

        Nothing ->
            case model.ownServerStatus of
                LoadingOwnServer ->
                    p [ class "server-details-loading" ] [ text ("Connecting to " ++ model.targetHost ++ "…") ]

                OwnServerFailed err ->
                    div [ class "server-details-error" ]
                        [ p [] [ text ("Couldn't find a Jonline server at " ++ identifierText model ++ ".") ]
                        , p [] [ text err ]
                        ]

                _ ->
                    text ""


addServerButton : Shared.Model -> Model -> AccountsPanel.Server -> Html Msg
addServerButton shared model server =
    if isKnownServer shared model then
        text ""

    else
        div [ class "server-details-add" ]
            [ p [] [ text "This server hasn't been added to your Accounts & Servers yet -- these details are just a preview." ]
            , button [ class "server-details-add-button", onClick (AddServerClicked server) ] [ text ("Add " ++ model.targetHost) ]
            ]


tabBar : Model -> Html Msg
tabBar model =
    div [ class "server-details-tab-bar" ]
        (List.map (tabButton model)
            [ ( AboutTab, "About" )
            , ( ThemeTab, "Theme" )
            , ( SettingsTab, "Settings" )
            , ( FederationTab, "Federation" )
            , ( CdnTab, "CDN" )
            ]
        )


tabButton : Model -> ( Tab, String ) -> Html Msg
tabButton model ( tab, label_ ) =
    button
        [ classes
            ("server-details-tab"
                :: (if model.activeTab == tab then
                        [ "selected" ]

                    else
                        []
                   )
            )
        , onClick (TabSelected tab)
        ]
        [ text label_ ]


tabContent : Shared.Model -> Model -> AccountsPanel.Server -> Html Msg
tabContent shared model server =
    case model.activeTab of
        AboutTab ->
            aboutTab shared model server

        ThemeTab ->
            themeTab server

        SettingsTab ->
            settingsTab server

        FederationTab ->
            federationTab server

        CdnTab ->
            cdnTab server



-- ABOUT TAB


aboutTab : Shared.Model -> Model -> AccountsPanel.Server -> Html Msg
aboutTab shared model server =
    let
        info =
            Maybe.withDefault defaultServerInfo server.configuration.serverInfo

        name =
            Maybe.withDefault server.frontendHost info.name

        maybeAdminAccount =
            adminAccountFor shared model
    in
    div [ class "server-details-tab-content server-details-about" ]
        [ h2 [ class "server-details-name" ] (nameView name model.renameStatus maybeAdminAccount)
        , versionView model.versionStatus
        , case info.description of
            Just description ->
                Markdown.view [ class "server-details-description" ] description

            Nothing ->
                text ""
        , case info.privacyPolicy of
            Just policy ->
                div [ class "server-details-policy" ]
                    [ h3 [] [ text "Privacy Policy" ]
                    , Markdown.view [] policy
                    ]

            Nothing ->
                text ""
        , case info.mediaPolicy of
            Just policy ->
                div [ class "server-details-policy" ]
                    [ h3 [] [ text "Media Policy" ]
                    , Markdown.view [] policy
                    ]

            Nothing ->
                text ""
        , adminsView shared server model.adminsStatus
        ]


nameView : String -> RenameStatus -> Maybe AccountsPanel.Account -> List (Html Msg)
nameView name renameStatus maybeAdminAccount =
    case ( renameStatus, maybeAdminAccount ) of
        ( Renaming pendingName status, Just _ ) ->
            [ input
                [ class "server-details-rename-input"
                , value pendingName
                , onInput RenameChanged
                , disabled (status == AccountsPanel.Submitting)
                ]
                []
            , button
                [ class "server-details-rename-save"
                , onClick RenameSaveClicked
                , disabled (status == AccountsPanel.Submitting)
                ]
                [ text
                    (if status == AccountsPanel.Submitting then
                        "Saving…"

                     else
                        "Save"
                    )
                ]
            , button
                [ class "server-details-rename-cancel"
                , onClick RenameCancelClicked
                , disabled (status == AccountsPanel.Submitting)
                ]
                [ text "Cancel" ]
            , case status of
                AccountsPanel.Errored err ->
                    span [ class "server-details-rename-error" ] [ text err ]

                _ ->
                    text ""
            ]

        _ ->
            [ text name
            , case maybeAdminAccount of
                Just _ ->
                    button [ class "server-details-rename-button", onClick (RenameClicked name) ] [ text "Rename" ]

                Nothing ->
                    text ""
            ]


versionView : VersionStatus -> Html Msg
versionView status =
    case status of
        VersionNotLoaded ->
            text ""

        LoadingVersion ->
            text ""

        VersionLoaded version ->
            p [ class "server-details-version" ] [ text ("Jonline " ++ version) ]

        VersionFailed ->
            text ""


adminsView : Shared.Model -> AccountsPanel.Server -> AdminsStatus -> Html Msg
adminsView shared server status =
    div [ class "server-details-admins" ]
        [ h3 [] [ text "Admins" ]
        , case status of
            AdminsNotLoaded ->
                text ""

            LoadingAdmins ->
                p [] [ text "Loading admins…" ]

            AdminsFailed ->
                p [] [ text "Couldn't load admins." ]

            AdminsLoaded [] ->
                p [] [ text "No admins found." ]

            AdminsLoaded admins ->
                div [ class "users-list" ] (List.map (adminCardView shared server) admins)
        ]


{-| One admin's `Users.userCard` -- links to that admin's profile (same card
used by `Components.Pages.UsersPage`'s People/Following/Followers/Friends
listings), with no follow-status/button slot (`text ""`) since this page is
otherwise entirely read-only (see the module doc) and doesn't track any
per-card `FollowStatusAndButton.Model` state to back one.
-}
adminCardView : Shared.Model -> AccountsPanel.Server -> User -> Html Msg
adminCardView shared server user =
    Users.userCard shared.basePath
        shared.accountsPanel.mainFrontendHost
        server
        (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost)
        (text "")
        user



-- THEME TAB


themeTab : AccountsPanel.Server -> Html Msg
themeTab server =
    let
        info =
            Maybe.withDefault defaultServerInfo server.configuration.serverInfo

        primary =
            info.colors |> Maybe.andThen .primary |> Maybe.map ServerTheme.colorMetaFromArgb |> Maybe.withDefault ServerTheme.neutralColorMeta

        nav =
            info.colors |> Maybe.andThen .navigation |> Maybe.map ServerTheme.colorMetaFromArgb |> Maybe.withDefault ServerTheme.neutralColorMeta

        squareMediaId =
            info.logo |> Maybe.andThen .squareMediaId
    in
    div [ class "server-details-tab-content server-details-theme" ]
        [ colorSwatchRow "Primary Color" primary
        , colorSwatchRow "Navigation Color" nav
        , div [ class "server-details-logo" ]
            [ h3 [] [ text "Server Image" ]
            , case squareMediaId of
                Just mediaId ->
                    img [ class "server-details-logo-image", src (AccountsPanel.mediaUrl server mediaId) ] []

                Nothing ->
                    p [] [ text "No server image set." ]
            ]
        ]


colorSwatchRow : String -> ServerTheme.ColorMeta -> Html Msg
colorSwatchRow label_ colorMeta =
    div [ class "server-details-color-row" ]
        [ span [ class "server-details-color-swatch", style "background-color" colorMeta.color ] []
        , span [ class "server-details-color-label" ] [ text label_ ]
        , span [ class "server-details-color-hex" ] [ text colorMeta.color ]
        ]



-- SETTINGS TAB


settingsTab : AccountsPanel.Server -> Html Msg
settingsTab server =
    let
        config =
            server.configuration

        webUi =
            config.serverInfo |> Maybe.andThen .webUserInterface |> Maybe.withDefault FLUTTERWEB
    in
    div [ class "server-details-tab-content server-details-settings" ]
        [ div [ class "server-details-setting" ]
            [ h3 [] [ text "Default Web UI" ]
            , p [] [ text (webUserInterfaceText webUi) ]
            ]
        , permissionsSection "Anonymous User Permissions" config.anonymousUserPermissions
        , permissionsSection "Default User Permissions" config.defaultUserPermissions
        , permissionsSection "Basic User Permissions" config.basicUserPermissions
        ]


webUserInterfaceText : WebUserInterface -> String
webUserInterfaceText ui =
    case ui of
        FLUTTERWEB ->
            "Flutter (legacy)"

        HANDLEBARSTEMPLATES ->
            "Handlebars Templates (deprecated)"

        REACTTAMAGUI ->
            "React (Tamagui)"

        ELMSPA ->
            "Elm"

        WebUserInterfaceUnrecognized_ _ ->
            "Unknown"


permissionsSection : String -> List Permission -> Html Msg
permissionsSection label_ permissions =
    div [ class "server-details-permissions" ]
        [ h3 [ class "section-title" ] [ text label_ ]
        , if List.isEmpty permissions then
            p [] [ text "None." ]

          else
            div [ class "permission-badges" ]
                (permissions |> List.map (\permission -> span [ class "permission-badge" ] [ text (Users.permissionText permission) ]))
        ]



-- FEDERATION TAB


federationTab : AccountsPanel.Server -> Html Msg
federationTab server =
    let
        federatedServers =
            server.configuration.federationInfo |> Maybe.map .servers |> Maybe.withDefault []
    in
    div [ class "server-details-tab-content server-details-federation" ]
        [ h3 [] [ text "Federated Servers" ]
        , if List.isEmpty federatedServers then
            p [] [ text "This server doesn't federate with any other servers." ]

          else
            ul [ class "server-details-federated-servers" ]
                (List.map federatedServerRow federatedServers)
        ]


federatedServerRow : FederatedServer -> Html Msg
federatedServerRow federatedServer =
    li [ class "server-details-federated-server" ]
        [ span [ class "server-details-federated-server-host" ] [ text federatedServer.host ]
        , if Maybe.withDefault False federatedServer.configuredByDefault then
            span [ class "server-details-federated-server-badge" ] [ text "configured by default" ]

          else
            text ""
        , if Maybe.withDefault False federatedServer.pinnedByDefault then
            span [ class "server-details-federated-server-badge" ] [ text "pinned by default" ]

          else
            text ""
        ]



-- CDN TAB


cdnTab : AccountsPanel.Server -> Html Msg
cdnTab server =
    let
        cdnConfig =
            server.configuration.externalCdnConfig
    in
    div [ class "server-details-tab-content server-details-cdn" ]
        [ div [ class "server-details-cdn-row" ]
            [ switchDisplay (cdnConfig /= Nothing)
            , span [] [ text "External CDN HTTP Support" ]
            ]
        , div [ class "server-details-cdn-field" ]
            [ span [ class "server-details-cdn-field-label" ] [ text "Frontend Host" ]
            , span [] [ text (cdnConfig |> Maybe.map .frontendHost |> Maybe.withDefault "\u{2014}") ]
            ]
        , div [ class "server-details-cdn-field" ]
            [ span [ class "server-details-cdn-field-label" ] [ text "Backend Host" ]
            , span [] [ text (cdnConfig |> Maybe.map .backendHost |> Maybe.withDefault "\u{2014}") ]
            ]
        , div [ class "server-details-cdn-row" ]
            [ switchDisplay (cdnConfig |> Maybe.map .cdnGrpc |> Maybe.withDefault False)
            , span [] [ text "External CDN gRPC Support" ]
            ]
        ]


{-| An always-disabled toggle switch -- this page is read-only apart from
renaming (see the module doc), so CDN settings are shown but never editable
here. Styled identically to `UI.elm`'s own `switchInput` (same `.switch`/
`.disabled`/`.slider` classes, see `switch.css`), just without needing a live
`Shared.Msg` to fire (it never will).
-}
switchDisplay : Bool -> Html Msg
switchDisplay isChecked =
    label [ classes [ "switch", "disabled" ] ]
        [ input [ type_ "checkbox", checked isChecked, disabled True ] []
        , span [ class "slider" ] []
        ]
