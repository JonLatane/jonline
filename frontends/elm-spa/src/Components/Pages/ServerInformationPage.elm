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

Renaming, editing the description/privacy policy/media policy, picking the
Default Web UI, and editing the Anonymous/Default/Basic User Permissions
sets are the mutations this page supports (all via `ConfigureServer`), and
only for a signed-in account with `ADMIN` on this specific server. Renaming
is routed through `Shared.AccountsPanel.RenameServerClicked` (not called
directly) so the app's cached `Server` list stays in sync with the change.
The Web UI picker directly reuses `UI.webUiToggleRow` -- the same control
shown per-admin-account in the Accounts Panel's own `UI.adminAccountPanel`.
The three Markdown fields instead go through the shared `Shared.MarkdownPanel`
editor (`ServerDescription`/`ServerPrivacyPolicy`/`ServerMediaPolicy`, see
`policySectionView`) -- same edit-in-panel/Save flow as post content on
`Pages.Post.PostId_`. The permissions editors (`permissionsSection`, one per
`ServerPermissionsSet`) mirror `Components.Pages.UserProfilePage`'s own
Permissions editor, just reading/writing a `ServerConfiguration`'s
`anonymousUserPermissions`/`defaultUserPermissions`/`basicUserPermissions`
(via `AccountsPanel.updateServerConfig`) instead of a `User`'s `permissions`.
Every one of these mutations, on a successful save, dispatches
`AccountsPanel.GotServerConfigSaveResult` to patch the cached `Server` the
same way a rename does, so this page needs no refetch of its own to reflect
the change.

-}

import Components.Markdown as Markdown
import Components.Users as Users
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, button, div, h2, h3, img, input, label, li, option, p, select, span, text, ul)
import Html.Attributes exposing (checked, class, disabled, selected, src, style, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Proto.Jonline exposing (FederatedServer, GetServiceVersionResponse, GetUsersResponse, ServerConfiguration, User, defaultGetUsersRequest, defaultMediaReference, defaultServerColors, defaultServerInfo, defaultServerLogo)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.Permission exposing (Permission(..))
import Proto.Jonline.WebUserInterface exposing (WebUserInterface(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.Breadcrumbs as Breadcrumbs
import Shared.MarkdownPanel as MarkdownPanel
import Shared.MyMediaPanel as MyMediaPanel
import Task
import UI
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


{-| Which of `ServerConfiguration`'s three grantable-permission-list fields a
`permissionsSection`/`PermissionsEdit` is for -- lets `settingsTab` reuse the
exact same editing machinery for all three (Anonymous/Default/Basic) rather
than tripling it, the way `Components.Pages.UserProfilePage` doesn't need to
since it only ever edits one user's own `permissions`.
-}
type ServerPermissionsSet
    = AnonymousPermissions
    | DefaultPermissions
    | BasicPermissions


{-| Live only while one of the three server-wide permission sets (see
`ServerPermissionsSet`) is being edited by an admin -- otherwise mirrors
`Components.Pages.UserProfilePage`'s own `PermissionsEdit` exactly: `pending`
is the in-progress set, `addSelection` is whatever the "Add Permission"
`<select>` currently has chosen (always one of
`Components.Users.configurableServerPermissions` not already in `pending`,
see `resolveAddSelection`).
-}
type alias PermissionsEdit =
    { pending : List Permission
    , addSelection : Maybe Permission
    , status : AccountsPanel.FormStatus
    }


{-| What `LogoSaveClicked` should do to `serverInfo.logo.squareMediaId` --
mirrors `Components.Pages.UserProfilePage`'s `AvatarChoice`/`AvatarEdit`
exactly, just over the server's own square logo (a bare `Maybe String` media
id, unlike a `User`'s `avatar` `MediaReference`) instead of a `User`'s
avatar. `LogoUnchanged` is the default (entering edit mode without having
picked anything new yet), `LogoChosen mediaId` is set by
`Shared.MyMediaPanel`'s `SingleSelect` picker (see the `SharedMsg` handling of
`MyMediaPanel.MediaItemClicked`), and `LogoRemoved` (the "Remove" button)
clears it entirely.
-}
type LogoChoice
    = LogoUnchanged
    | LogoChosen String
    | LogoRemoved


{-| Live only while the server's square logo is being edited by an admin --
mirrors `PermissionsEdit`'s shape (a `pending`-style `choice` plus `status`).
-}
type alias LogoEdit =
    { choice : LogoChoice
    , status : AccountsPanel.FormStatus
    }


{-| Which of `ServerColors`' two user-facing color fields a `colorEditorRow`/
`ColorEdit` is for -- lets `settingsTab`/`themeTab`-style code reuse the same
editing machinery for both (Primary/Navigation) rather than duplicating it,
the same reason `ServerPermissionsSet` exists for the three permission lists.
-}
type ServerColorField
    = PrimaryColor
    | NavigationColor


{-| Live only while one of the two server colors (see `ServerColorField`) is
being edited by an admin -- `pending` is the in-progress `<input type="color">`
value (a `#rrggbb` hex string), independent of the actual saved color until
`ColorSaveClicked` succeeds.
-}
type alias ColorEdit =
    { pending : String
    , status : AccountsPanel.FormStatus
    }


type alias Model =
    { targetHost : String
    , isSecure : Bool
    , ownServerStatus : OwnServerStatus
    , activeTab : Tab
    , adminsStatus : AdminsStatus
    , versionStatus : VersionStatus
    , renameStatus : RenameStatus
    , anonymousPermissionsEdit : Maybe PermissionsEdit
    , defaultPermissionsEdit : Maybe PermissionsEdit
    , basicPermissionsEdit : Maybe PermissionsEdit
    , logoEdit : Maybe LogoEdit
    , primaryColorEdit : Maybe ColorEdit
    , navigationColorEdit : Maybe ColorEdit
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
            , anonymousPermissionsEdit = Nothing
            , defaultPermissionsEdit = Nothing
            , basicPermissionsEdit = Nothing
            , logoEdit = Nothing
            , primaryColorEdit = Nothing
            , navigationColorEdit = Nothing
            }

        ( fetchedModel, fetchEffect ) =
            case knownConnectedServer shared targetHost of
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
    , Effect.batch [ fetchEffect, setBreadcrumbsHost shared fetchedModel ]
    )


{-| `Shared.AccountsPanel`'s cached entry for `targetHost`, if it's both known
_and_ actually connected (see `AccountsPanel.knownConnectedServer`) -- a
known-but-disconnected entry is treated the same as not known at all, so this
page falls back to its own probe (just like a never-added host) rather than
trying to show configuration/admins/version for a server it can't currently
reach.
-}
knownConnectedServer : Shared.Model -> String -> Maybe AccountsPanel.Server
knownConnectedServer shared targetHost =
    AccountsPanel.knownConnectedServer shared.accountsPanel.servers targetHost


{-| The `Server` to actually show details for -- whichever the app already
knows about and is connected to (from `Shared.AccountsPanel`, if this
server's been added to Accounts & Servers already), falling back to this
page's own probe (`ownServerStatus`) otherwise.
-}
effectiveServer : Shared.Model -> Model -> Maybe AccountsPanel.Server
effectiveServer shared model =
    case knownConnectedServer shared model.targetHost of
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
    knownConnectedServer shared model.targetHost /= Nothing


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


{-| Keeps `Shared.Breadcrumbs` pointed at this page's own
`FromServerHost targetHost` -- mirrors `Components.Pages.UserProfilePage.setBreadcrumbsHost`
(reissued after every `update`, a no-op once already in sync via the same
equality check), so the trail identifies this server both on the very first
paint and across any later host change (e.g. `GotOwnServerResult` resolving
the own-probe).
-}
setBreadcrumbsHost : Shared.Model -> Model -> Effect Msg
setBreadcrumbsHost shared model =
    if shared.breadcrumbs.root == Just (Breadcrumbs.FromServerHost model.targetHost) then
        Effect.none

    else
        Effect.fromShared (Shared.BreadcrumbsMsg (Breadcrumbs.SetRoot (Breadcrumbs.FromServerHost model.targetHost) model.targetHost []))


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


{-| `model`'s in-progress `PermissionsEdit` for one `ServerPermissionsSet`,
alongside its setter `setPermissionsEditFor` just below -- lets `update`/
`view` treat all three sections generically instead of a `case` per Msg per
section.
-}
permissionsEditFor : ServerPermissionsSet -> Model -> Maybe PermissionsEdit
permissionsEditFor set model =
    case set of
        AnonymousPermissions ->
            model.anonymousPermissionsEdit

        DefaultPermissions ->
            model.defaultPermissionsEdit

        BasicPermissions ->
            model.basicPermissionsEdit


setPermissionsEditFor : ServerPermissionsSet -> Maybe PermissionsEdit -> Model -> Model
setPermissionsEditFor set edit model =
    case set of
        AnonymousPermissions ->
            { model | anonymousPermissionsEdit = edit }

        DefaultPermissions ->
            { model | defaultPermissionsEdit = edit }

        BasicPermissions ->
            { model | basicPermissionsEdit = edit }


{-| One `ServerPermissionsSet`'s current list out of a `ServerConfiguration`,
alongside its writer `applyPermissionsFor` just below.
-}
permissionsFor : ServerPermissionsSet -> ServerConfiguration -> List Permission
permissionsFor set config =
    case set of
        AnonymousPermissions ->
            config.anonymousUserPermissions

        DefaultPermissions ->
            config.defaultUserPermissions

        BasicPermissions ->
            config.basicUserPermissions


applyPermissionsFor : ServerPermissionsSet -> List Permission -> ServerConfiguration -> ServerConfiguration
applyPermissionsFor set permissions config =
    case set of
        AnonymousPermissions ->
            { config | anonymousUserPermissions = permissions }

        DefaultPermissions ->
            { config | defaultUserPermissions = permissions }

        BasicPermissions ->
            { config | basicUserPermissions = permissions }


{-| `LogoSaveClicked`'s transform, passed to `AccountsPanel.updateServerConfig`
the same way `applyPermissionsFor`'s result is -- overlays just the change
`edit.choice` describes onto a freshly re-fetched `ServerConfiguration`'s
`serverInfo.logo.squareMediaId`, leaving every other field (including the
other three `ServerLogo` variants, none of which this page edits) untouched.
Mirrors `Components.Pages.UserProfilePage.applyAvatarChoice`.
-}
applyLogoChoice : LogoChoice -> ServerConfiguration -> ServerConfiguration
applyLogoChoice choice config =
    let
        info =
            Maybe.withDefault defaultServerInfo config.serverInfo

        logo =
            Maybe.withDefault defaultServerLogo info.logo

        setSquareMediaId squareMediaId =
            { config | serverInfo = Just { info | logo = Just { logo | squareMediaId = squareMediaId } } }
    in
    case choice of
        LogoUnchanged ->
            config

        LogoChosen mediaId ->
            setSquareMediaId (Just mediaId)

        LogoRemoved ->
            setSquareMediaId Nothing


{-| One `ServerColorField`'s current ARGB value out of a `ServerConfiguration`,
alongside its writer `applyColorFor` just below -- both mirror `permissionsFor`/
`applyPermissionsFor`, just over `serverInfo.colors` instead of a top-level
permission list.
-}
colorArgbFor : ServerColorField -> ServerConfiguration -> Maybe Int
colorArgbFor field config =
    let
        colors =
            config.serverInfo |> Maybe.andThen .colors
    in
    case field of
        PrimaryColor ->
            colors |> Maybe.andThen .primary

        NavigationColor ->
            colors |> Maybe.andThen .navigation


applyColorFor : ServerColorField -> Int -> ServerConfiguration -> ServerConfiguration
applyColorFor field argb config =
    let
        info =
            Maybe.withDefault defaultServerInfo config.serverInfo

        colors =
            Maybe.withDefault defaultServerColors info.colors

        newColors =
            case field of
                PrimaryColor ->
                    { colors | primary = Just argb }

                NavigationColor ->
                    { colors | navigation = Just argb }
    in
    { config | serverInfo = Just { info | colors = Just newColors } }


{-| `model`'s in-progress `ColorEdit` for one `ServerColorField`, alongside its
setter `setColorEditFor` just below -- mirrors `permissionsEditFor`/
`setPermissionsEditFor`.
-}
colorEditFor : ServerColorField -> Model -> Maybe ColorEdit
colorEditFor field model =
    case field of
        PrimaryColor ->
            model.primaryColorEdit

        NavigationColor ->
            model.navigationColorEdit


setColorEditFor : ServerColorField -> Maybe ColorEdit -> Model -> Model
setColorEditFor field edit model =
    case field of
        PrimaryColor ->
            { model | primaryColorEdit = edit }

        NavigationColor ->
            { model | navigationColorEdit = edit }


{-| Starts a `PermissionsEdit` off `currentPermissions` (that set's own, as
currently configured) -- `addSelection` defaults to the first grantable
permission not already in that list, same as `resolveAddSelection` picks
after every add/remove. Mirrors `Components.Pages.UserProfilePage.newPermissionsEdit`.
-}
newPermissionsEdit : List Permission -> PermissionsEdit
newPermissionsEdit currentPermissions =
    { pending = currentPermissions
    , addSelection = resolveAddSelection Nothing currentPermissions
    , status = AccountsPanel.Idle
    }


{-| Keeps the "Add Permission" `<select>`'s selection valid as `pending`
changes: keeps `current` if it's still addable (not already in `pending`),
otherwise falls back to the first still-addable permission (`Nothing` if
every permission's already been added). Mirrors `UserProfilePage`'s own.
-}
resolveAddSelection : Maybe Permission -> List Permission -> Maybe Permission
resolveAddSelection current pending =
    let
        available =
            addablePermissions pending
    in
    case current of
        Just permission ->
            if List.member permission available then
                Just permission

            else
                List.head available

        Nothing ->
            List.head available


addablePermissions : List Permission -> List Permission
addablePermissions pending =
    Users.configurableServerPermissions |> List.filter (\permission -> not (List.member permission pending))


{-| Turns a `Maybe AccountsPanel.Msg` (as returned by `AccountsPanel.updateServerConfig`,
if a token refresh happened) into an `Effect` to forward it, `Effect.none`
otherwise. Mirrors `UserProfilePage.accountsPanelEffect`.
-}
accountsPanelEffect : Maybe AccountsPanel.Msg -> Effect Msg
accountsPanelEffect maybeAccountsPanelMsg =
    maybeAccountsPanelMsg
        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
        |> Maybe.withDefault Effect.none



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
    | EditDescriptionClicked AccountsPanel.Server
    | EditPrivacyPolicyClicked AccountsPanel.Server
    | EditMediaPolicyClicked AccountsPanel.Server
    | PermissionsEditClicked ServerPermissionsSet
    | PermissionRemoveClicked ServerPermissionsSet Permission
    | PermissionAddSelectionChanged ServerPermissionsSet String
    | PermissionAddClicked ServerPermissionsSet
    | PermissionsCancelClicked ServerPermissionsSet
    | PermissionsSaveClicked ServerPermissionsSet
    | GotPermissionsSaveResult ServerPermissionsSet (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))
    | LogoEditClicked
    | LogoRemoveClicked
    | LogoCancelClicked
    | LogoSaveClicked
    | GotLogoSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))
    | ColorEditClicked ServerColorField
    | ColorChanged ServerColorField String
    | ColorCancelClicked ServerColorField
    | ColorSaveClicked ServerColorField
    | GotColorSaveResult ServerColorField (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))
    | SharedMsg Shared.Msg


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
into `update`'s `SharedMsg` branch -- see `Pages.Post.PostId_.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    let
        ( newModel, effect ) =
            updateInner shared msg model
    in
    ( newModel, Effect.batch [ effect, setBreadcrumbsHost shared newModel ] )


updateInner : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
updateInner shared msg model =
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

        EditDescriptionClicked server ->
            ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.ServerDescription server) model.targetHost)) )

        EditPrivacyPolicyClicked server ->
            ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.ServerPrivacyPolicy server) model.targetHost)) )

        EditMediaPolicyClicked server ->
            ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.ServerMediaPolicy server) model.targetHost)) )

        PermissionsEditClicked set ->
            case effectiveServer shared model of
                Just server ->
                    let
                        currentPermissions =
                            permissionsFor set (AccountsPanel.configurationOf server)
                    in
                    ( setPermissionsEditFor set (Just (newPermissionsEdit currentPermissions)) model, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        PermissionRemoveClicked set permission ->
            ( setPermissionsEditFor set
                (permissionsEditFor set model
                    |> Maybe.map
                        (\edit ->
                            let
                                pending =
                                    List.filter ((/=) permission) edit.pending
                            in
                            { edit | pending = pending, addSelection = resolveAddSelection edit.addSelection pending }
                        )
                )
                model
            , Effect.none
            )

        PermissionAddSelectionChanged set text ->
            ( setPermissionsEditFor set
                (permissionsEditFor set model |> Maybe.map (\edit -> { edit | addSelection = Users.permissionFromText text }))
                model
            , Effect.none
            )

        PermissionAddClicked set ->
            ( setPermissionsEditFor set
                (permissionsEditFor set model
                    |> Maybe.map
                        (\edit ->
                            case edit.addSelection of
                                Just permission ->
                                    let
                                        pending =
                                            edit.pending ++ [ permission ]
                                    in
                                    { edit | pending = pending, addSelection = resolveAddSelection Nothing pending }

                                Nothing ->
                                    edit
                        )
                )
                model
            , Effect.none
            )

        PermissionsCancelClicked set ->
            ( setPermissionsEditFor set Nothing model, Effect.none )

        PermissionsSaveClicked set ->
            case ( permissionsEditFor set model, adminAccountFor shared model ) of
                ( Just edit, Just account ) ->
                    ( setPermissionsEditFor set (Just { edit | status = AccountsPanel.Submitting }) model
                    , AccountsPanel.updateServerConfig shared.accountsPanel ( Just account.userId, model.targetHost ) (applyPermissionsFor set edit.pending)
                        |> Task.attempt (GotPermissionsSaveResult set)
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotPermissionsSaveResult set (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( setPermissionsEditFor set Nothing model
            , Effect.batch
                [ accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult model.targetHost newConfig))
                ]
            )

        GotPermissionsSaveResult set (Err err) ->
            ( setPermissionsEditFor set
                (permissionsEditFor set model |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }))
                model
            , Effect.none
            )

        LogoEditClicked ->
            case effectiveServer shared model of
                Just server ->
                    let
                        squareMediaId =
                            (AccountsPanel.configurationOf server).serverInfo |> Maybe.andThen .logo |> Maybe.andThen .squareMediaId
                    in
                    ( { model
                        | logoEdit =
                            -- Preserves an already-in-progress `choice`/`status`
                            -- rather than resetting it -- this same message
                            -- doubles as "re-open the picker" (see
                            -- `logoEditorView`'s "Choose Image" button, shown
                            -- even while already editing), which shouldn't
                            -- discard whatever's already been picked. Mirrors
                            -- `UserProfilePage.AvatarEditClicked`.
                            case model.logoEdit of
                                Just edit ->
                                    Just edit

                                Nothing ->
                                    Just { choice = LogoUnchanged, status = AccountsPanel.Idle }
                      }
                    , Effect.fromShared
                        (Shared.MyMediaPanelMsg
                            (MyMediaPanel.Open
                                (Just (MyMediaPanel.SingleSelect { imagesOnly = True, initialSelection = squareMediaId |> Maybe.map (\id -> { defaultMediaReference | id = id }) }))
                                model.targetHost
                            )
                        )
                    )

                Nothing ->
                    ( model, Effect.none )

        LogoRemoveClicked ->
            ( { model | logoEdit = model.logoEdit |> Maybe.map (\edit -> { edit | choice = LogoRemoved }) }, Effect.none )

        LogoCancelClicked ->
            ( { model | logoEdit = Nothing }, Effect.fromShared (Shared.MyMediaPanelMsg MyMediaPanel.CloseClicked) )

        LogoSaveClicked ->
            case ( model.logoEdit, adminAccountFor shared model ) of
                ( Just edit, Just account ) ->
                    ( { model | logoEdit = Just { edit | status = AccountsPanel.Submitting } }
                    , AccountsPanel.updateServerConfig shared.accountsPanel ( Just account.userId, model.targetHost ) (applyLogoChoice edit.choice)
                        |> Task.attempt GotLogoSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotLogoSaveResult (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( { model | logoEdit = Nothing }
            , Effect.batch
                [ accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult model.targetHost newConfig))
                ]
            )

        GotLogoSaveResult (Err err) ->
            ( { model | logoEdit = model.logoEdit |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )

        ColorEditClicked field ->
            case effectiveServer shared model of
                Just server ->
                    let
                        pending =
                            colorArgbFor field (AccountsPanel.configurationOf server)
                                |> Maybe.map ServerTheme.colorMetaFromArgb
                                |> Maybe.withDefault ServerTheme.neutralColorMeta
                                |> .color
                    in
                    ( setColorEditFor field (Just { pending = pending, status = AccountsPanel.Idle }) model, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        ColorChanged field hex ->
            ( setColorEditFor field (colorEditFor field model |> Maybe.map (\edit -> { edit | pending = hex })) model, Effect.none )

        ColorCancelClicked field ->
            ( setColorEditFor field Nothing model, Effect.none )

        ColorSaveClicked field ->
            case ( colorEditFor field model, adminAccountFor shared model ) of
                ( Just edit, Just account ) ->
                    ( setColorEditFor field (Just { edit | status = AccountsPanel.Submitting }) model
                    , AccountsPanel.updateServerConfig shared.accountsPanel ( Just account.userId, model.targetHost ) (applyColorFor field (ServerTheme.argbFromHex edit.pending))
                        |> Task.attempt (GotColorSaveResult field)
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotColorSaveResult field (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( setColorEditFor field Nothing model
            , Effect.batch
                [ accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult model.targetHost newConfig))
                ]
            )

        GotColorSaveResult field (Err err) ->
            ( setColorEditFor field
                (colorEditFor field model |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }))
                model
            , Effect.none
            )

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

                logoEdit =
                    -- The shared `Shared.MyMediaPanel` chooser (opened by
                    -- `LogoEditClicked`) reports a tap this way -- see
                    -- `Shared.MyMediaPanel`'s own module doc on why this
                    -- forwarded `Shared.Msg`, not some closure/callback, is
                    -- what delivers the pick back here. Gated on `logoEdit`
                    -- already being `Just` so an unrelated Browse-mode tap
                    -- (e.g. from the Accounts Panel) elsewhere can't be
                    -- mistaken for a logo pick. Mirrors
                    -- `UserProfilePage`'s own `MediaItemClicked` handling.
                    case subMsg of
                        Shared.MyMediaPanelMsg (MyMediaPanel.MediaItemClicked mediaId) ->
                            model.logoEdit |> Maybe.map (\edit -> { edit | choice = LogoChosen mediaId })

                        _ ->
                            model.logoEdit
            in
            ( { model | renameStatus = renameStatus, logoEdit = logoEdit }, Effect.fromShared subMsg )


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
            (AccountsPanel.brandingOf server).name

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
            themeTab shared model server

        SettingsTab ->
            settingsTab shared model server

        FederationTab ->
            federationTab server

        CdnTab ->
            cdnTab server



-- ABOUT TAB


aboutTab : Shared.Model -> Model -> AccountsPanel.Server -> Html Msg
aboutTab shared model server =
    let
        info =
            AccountsPanel.serverInfoOf server

        name =
            Maybe.withDefault server.frontendHost info.name

        maybeAdminAccount =
            adminAccountFor shared model
    in
    div [ class "server-details-tab-content server-details-about" ]
        [ h2 [ class "server-details-name" ] (nameView name model.renameStatus maybeAdminAccount)
        , versionView model.versionStatus
        , policySectionView "server-details-description" Nothing (EditDescriptionClicked server) maybeAdminAccount info.description
        , policySectionView "server-details-policy" (Just "Privacy Policy") (EditPrivacyPolicyClicked server) maybeAdminAccount info.privacyPolicy
        , policySectionView "server-details-policy" (Just "Media Policy") (EditMediaPolicyClicked server) maybeAdminAccount info.mediaPolicy
        , adminsView shared server model.adminsStatus
        ]


{-| One about-tab Markdown field backed by `Shared.MarkdownPanel` --
`description` (`heading = Nothing`) or `privacyPolicy`/`mediaPolicy` (each
headed). Renders nothing for a non-admin viewer when the field's unset, same
as before this page supported editing it; an admin sees an "Edit" button
either way -- even when unset, so they can set it for the first time, not
just change existing text -- mirroring `nameView`'s Rename button.
-}
policySectionView : String -> Maybe String -> Msg -> Maybe AccountsPanel.Account -> Maybe String -> Html Msg
policySectionView sectionClass heading editClicked maybeAdminAccount content =
    case ( content, maybeAdminAccount ) of
        ( Nothing, Nothing ) ->
            text ""

        _ ->
            div [ class sectionClass ]
                [ case heading of
                    Just headingText ->
                        h3 [] [ text headingText ]

                    Nothing ->
                        text ""
                , case content of
                    Just markdown ->
                        Markdown.view [] markdown

                    Nothing ->
                        p [ class "server-details-policy-unset" ] [ text "Not set." ]
                , case maybeAdminAccount of
                    Just _ ->
                        button [ class "server-details-rename-button", onClick editClicked ] [ text "Edit" ]

                    Nothing ->
                        text ""
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
                [ classes [ "server-details-rename-save", "background-color-primary" ]
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


{-| Only `PrimaryColor`/`NavigationColor` are editable here (an admin's
`colorEditorRow`, backed by an `<input type="color">`, see its own doc);
`author`/`admin`/`moderator` (the other three `ServerColors` fields) aren't
shown at all -- this page has no UI for them yet, same as before this tab
supported any editing. The square logo (`logoEditorView`) is the tab's other
editable field. A non-admin viewer sees both exactly as before -- plain
swatches/hex and a plain image, no edit affordances.
-}
themeTab : Shared.Model -> Model -> AccountsPanel.Server -> Html Msg
themeTab shared model server =
    let
        info =
            AccountsPanel.serverInfoOf server

        maybeAdminAccount =
            adminAccountFor shared model
    in
    div [ class "server-details-tab-content server-details-theme" ]
        [ colorEditorRow PrimaryColor "Primary Color" maybeAdminAccount model.primaryColorEdit (info.colors |> Maybe.andThen .primary)
        , colorEditorRow NavigationColor "Navigation Color" maybeAdminAccount model.navigationColorEdit (info.colors |> Maybe.andThen .navigation)
        , logoEditorView maybeAdminAccount model.logoEdit server (info.logo |> Maybe.andThen .squareMediaId)
        ]


{-| One `ServerColorField`'s row: the plain swatch/hex (plus an Edit button,
for an admin) when it has no in-progress `ColorEdit`, or an `<input
type="color">` (native, no picker library -- see `UI.ServerTheme.argbFromHex`'s
own doc) bound to `edit.pending` plus Save/Cancel while being edited. Mirrors
`permissionsSection`'s edit/non-edit split.
-}
colorEditorRow : ServerColorField -> String -> Maybe AccountsPanel.Account -> Maybe ColorEdit -> Maybe Int -> Html Msg
colorEditorRow field label_ maybeAdminAccount maybeEdit argb =
    case maybeEdit of
        Just edit ->
            div [ class "server-details-color-row server-details-color-row-edit" ]
                [ input [ type_ "color", value edit.pending, onInput (ColorChanged field) ] []
                , span [ class "server-details-color-label" ] [ text label_ ]
                , span [ class "server-details-color-hex" ] [ text edit.pending ]
                , editSaveButton (ColorSaveClicked field) edit.status
                , editCancelButton (ColorCancelClicked field) edit.status
                , editErrorView edit.status
                ]

        Nothing ->
            let
                colorMeta =
                    argb |> Maybe.map ServerTheme.colorMetaFromArgb |> Maybe.withDefault ServerTheme.neutralColorMeta
            in
            div [ class "server-details-color-row" ]
                [ span [ class "server-details-color-swatch", style "background-color" colorMeta.color ] []
                , span [ class "server-details-color-label" ] [ text label_ ]
                , span [ class "server-details-color-hex" ] [ text colorMeta.color ]
                , case maybeAdminAccount of
                    Just _ ->
                        button [ class "server-details-rename-button", onClick (ColorEditClicked field) ] [ text "Edit" ]

                    Nothing ->
                        text ""
                ]


{-| The square logo, plus (only for an admin, and only once `logoEdit` is
started) a `MyMediaPanel`-backed picker: "Choose Image" (re)opens
`Shared.MyMediaPanel` in `SingleSelect` mode (see `LogoEditClicked`), "Remove"
clears the pick entirely, and Save/Cancel commit or discard it. The image
itself previews `edit.choice` (see `logoPreviewUrl`) rather than
`currentSquareMediaId` once editing's started, mirroring
`Components.Pages.UserProfilePage.avatarPreviewUrl`'s own "preview the pending
choice, not the saved value" behavior.
-}
logoEditorView : Maybe AccountsPanel.Account -> Maybe LogoEdit -> AccountsPanel.Server -> Maybe String -> Html Msg
logoEditorView maybeAdminAccount maybeEdit server currentSquareMediaId =
    div [ class "server-details-logo" ]
        [ h3 [] [ text "Server Image" ]
        , case maybeEdit of
            Just edit ->
                div [ class "server-details-logo-edit" ]
                    [ case logoPreviewUrl server edit.choice currentSquareMediaId of
                        Just url ->
                            img [ class "server-details-logo-image", src url ] []

                        Nothing ->
                            p [ class "server-details-policy-unset" ] [ text "No server image set." ]
                    , div [ class "server-details-logo-edit-actions" ]
                        [ button
                            [ class "server-details-rename-button", onClick LogoEditClicked, disabled (edit.status == AccountsPanel.Submitting) ]
                            [ text "Choose Image" ]
                        , button
                            [ class "server-details-rename-cancel", onClick LogoRemoveClicked, disabled (edit.status == AccountsPanel.Submitting) ]
                            [ text "Remove" ]
                        ]
                    , div [ class "server-details-logo-edit-actions" ]
                        [ editSaveButton LogoSaveClicked edit.status
                        , editCancelButton LogoCancelClicked edit.status
                        ]
                    , editErrorView edit.status
                    ]

            Nothing ->
                div []
                    [ case currentSquareMediaId |> Maybe.andThen (AccountsPanel.mediaUrl server) of
                        Just url ->
                            img [ class "server-details-logo-image", src url ] []

                        Nothing ->
                            p [] [ text "No server image set." ]
                    , case maybeAdminAccount of
                        Just _ ->
                            button [ class "server-details-rename-button", onClick LogoEditClicked ] [ text "Edit" ]

                        Nothing ->
                            text ""
                    ]
        ]


{-| The logo URL `logoEditorView` should actually preview -- mirrors
`Components.Pages.UserProfilePage.avatarPreviewUrl` exactly, just over
`LogoChoice` instead of `AvatarChoice` (and with no initial-letter placeholder
fallback to drop to, since a server has no analogous "username" -- `Nothing`
just shows the "No server image set." text, same as the non-editing case).
-}
logoPreviewUrl : AccountsPanel.Server -> LogoChoice -> Maybe String -> Maybe String
logoPreviewUrl server choice currentSquareMediaId =
    case choice of
        LogoUnchanged ->
            currentSquareMediaId |> Maybe.andThen (AccountsPanel.mediaUrl server)

        LogoChosen mediaId ->
            AccountsPanel.mediaUrl server mediaId

        LogoRemoved ->
            Nothing



-- SETTINGS TAB


{-| The Default Web UI picker reuses `UI.webUiToggleRow` -- the same
Flutter/React/Elm toggle shown per-admin-account in the Accounts Panel's own
`UI.adminAccountPanel` -- rather than duplicating it, so an admin sees (and
can change) the exact same control here as in that panel. Only shown to a
signed-in admin (`adminAccountFor`); anyone else just sees the current
choice as plain text, same as before this was editable.
-}
settingsTab : Shared.Model -> Model -> AccountsPanel.Server -> Html Msg
settingsTab shared model server =
    let
        config =
            AccountsPanel.configurationOf server

        webUi =
            config.serverInfo |> Maybe.andThen .webUserInterface |> Maybe.withDefault FLUTTERWEB

        maybeAdminAccount =
            adminAccountFor shared model
    in
    div [ class "server-details-tab-content server-details-settings" ]
        [ div [ class "server-details-setting" ]
            [ h3 [] [ text "Default Web UI" ]
            , case maybeAdminAccount of
                Just account ->
                    Html.map SharedMsg (UI.webUiToggleRow (AccountsPanel.accountId account) server.frontendHost webUi)

                Nothing ->
                    p [] [ text (webUserInterfaceText webUi) ]
            ]
        , permissionsSection AnonymousPermissions "Anonymous User Permissions" maybeAdminAccount model.anonymousPermissionsEdit config.anonymousUserPermissions
        , permissionsSection DefaultPermissions "Default User Permissions" maybeAdminAccount model.defaultPermissionsEdit config.defaultUserPermissions
        , permissionsSection BasicPermissions "Basic User Permissions" maybeAdminAccount model.basicPermissionsEdit config.basicUserPermissions
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


{-| One of the three server-wide permission sections (Anonymous/Default/Basic,
distinguished by `set`) -- plain badges (plus an Edit button, for an admin)
when this section has no in-progress `PermissionsEdit`, or the
removable-badges + Add Permission + Save/Cancel editor while being edited.
Mirrors `Components.Pages.UserProfilePage.permissionsSection` exactly, just
over a `ServerConfiguration`'s permission list instead of a `User`'s.
-}
permissionsSection : ServerPermissionsSet -> String -> Maybe AccountsPanel.Account -> Maybe PermissionsEdit -> List Permission -> Html Msg
permissionsSection set label_ maybeAdminAccount maybeEdit permissions =
    case maybeEdit of
        Just edit ->
            div [ class "server-details-permissions server-details-permissions-edit" ]
                [ h3 [ class "section-title" ] [ text label_ ]
                , div [ class "permission-badges" ] (edit.pending |> List.map (permissionEditBadge set))
                , div [ class "server-details-permissions-add" ]
                    [ select [ onInput (PermissionAddSelectionChanged set) ]
                        (addablePermissions edit.pending
                            |> List.map
                                (\permission ->
                                    option
                                        [ value (Users.permissionText permission)
                                        , selected (edit.addSelection == Just permission)
                                        ]
                                        [ text (Users.permissionText permission) ]
                                )
                        )
                    , button
                        [ class "server-details-rename-button"
                        , onClick (PermissionAddClicked set)
                        , disabled (edit.addSelection == Nothing || edit.status == AccountsPanel.Submitting)
                        ]
                        [ text "Add Permission" ]
                    ]
                , div [ class "server-details-permissions-actions" ]
                    [ editSaveButton (PermissionsSaveClicked set) edit.status
                    , editCancelButton (PermissionsCancelClicked set) edit.status
                    ]
                , editErrorView edit.status
                ]

        Nothing ->
            div [ class "server-details-permissions" ]
                [ h3 [ class "section-title" ] [ text label_ ]
                , if List.isEmpty permissions then
                    p [] [ text "None." ]

                  else
                    div [ class "permission-badges" ]
                        (permissions |> List.map (\permission -> span [ class "permission-badge" ] [ text (Users.permissionText permission) ]))
                , case maybeAdminAccount of
                    Just _ ->
                        button [ class "server-details-rename-button", onClick (PermissionsEditClicked set) ] [ text "Edit" ]

                    Nothing ->
                        text ""
                ]


permissionEditBadge : ServerPermissionsSet -> Permission -> Html Msg
permissionEditBadge set permission =
    span [ class "permission-badge editable" ]
        [ text (Users.permissionText permission)
        , button
            [ class "permission-remove"
            , onClick (PermissionRemoveClicked set permission)
            , title ("Remove " ++ Users.permissionText permission)
            ]
            [ text "×" ]
        ]


editSaveButton : Msg -> AccountsPanel.FormStatus -> Html Msg
editSaveButton onSave status =
    button
        [ classes [ "server-details-rename-save", "background-color-primary" ]
        , onClick onSave
        , disabled (status == AccountsPanel.Submitting)
        ]
        [ text
            (if status == AccountsPanel.Submitting then
                "Saving…"

             else
                "Save"
            )
        ]


editCancelButton : Msg -> AccountsPanel.FormStatus -> Html Msg
editCancelButton onCancel status =
    button [ class "server-details-rename-cancel", onClick onCancel, disabled (status == AccountsPanel.Submitting) ] [ text "Cancel" ]


editErrorView : AccountsPanel.FormStatus -> Html msg
editErrorView status =
    case status of
        AccountsPanel.Errored err ->
            span [ class "server-details-rename-error" ] [ text err ]

        _ ->
            text ""



-- FEDERATION TAB


federationTab : AccountsPanel.Server -> Html Msg
federationTab server =
    let
        federatedServers =
            (AccountsPanel.configurationOf server).federationInfo |> Maybe.map .servers |> Maybe.withDefault []
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
            (AccountsPanel.configurationOf server).externalCdnConfig
    in
    div [ class "server-details-tab-content server-details-cdn" ]
        [ div [ class "server-details-cdn-row" ]
            [ switchDisplay (cdnConfig /= Nothing)
            , span [] [ text "External CDN HTTP Support" ]
            ]
        , div [ class "server-details-cdn-field" ]
            [ span [ class "server-details-cdn-field-label" ] [ text "Frontend Host" ]
            , span [] [ text (cdnConfig |> Maybe.map .frontendHost |> Maybe.withDefault "—") ]
            ]
        , div [ class "server-details-cdn-field" ]
            [ span [ class "server-details-cdn-field-label" ] [ text "Backend Host" ]
            , span [] [ text (cdnConfig |> Maybe.map .backendHost |> Maybe.withDefault "—") ]
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
