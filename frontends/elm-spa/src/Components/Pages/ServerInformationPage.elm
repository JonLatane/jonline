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

This module is purely an orchestrator -- an admin's actual mutations (renaming,
editing the description/privacy policy/media policy, the Default Web UI, the
Anonymous/Default/Basic User Permissions sets, the five per-feature settings
sections, the server's logo/colors, Federation/Facebook Auth config, and the
CDN config) each live in one of five per-tab submodules
(`ServerInformationPage.AboutTab`/`ThemeTab`/`SettingsTab`/`FederationTab`/
`CdnTab`), composed here the same way `Shared.elm` composes
`Shared.AccountsPanel`/`Shared.MarkdownPanel`: this `Model` holds one field per
submodule's own `Model`, this `Msg` wraps each submodule's own `Msg` in a
constructor, and `updateInner` dispatches a wrapped `Msg` to its submodule via
`Effect.map`/`Tuple.mapFirst`, mirroring `Pages.Server.ServerIdentifier_`'s own
wrapping of this module. `Components.Pages.ServerInformationPage.Common` holds
the handful of `msg`-generic bits (Save/Cancel/error, toggle switches, the
"is this the signed-in account, and are they an admin on this server" check)
reused by 2+ of them.

`ownServerStatus`/`activeTab`/`adminsStatus`/`versionStatus` (and the RPCs that
fill in the latter two) stay here rather than in any one submodule -- they're
about loading the page's *subject* (which server, which tab, who its admins
are, what version it's running), not any one tab's editable content; `adminsStatus`/
`versionStatus` are fetched as soon as a server's known regardless of which tab
is active, even though only `AboutTab`'s `view` ever displays them.
-}

import Browser.Navigation
import Components.Pages.ServerInformationPage.AboutTab as AboutTab
import Components.Pages.ServerInformationPage.CdnTab as CdnTab
import Components.Pages.ServerInformationPage.Common as Common
import Components.Pages.ServerInformationPage.FederationTab as FederationTab
import Components.Pages.ServerInformationPage.SettingsTab as SettingsTab
import Components.Pages.ServerInformationPage.ThemeTab as ThemeTab
import Dict exposing (Dict)
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, button, div, p, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Proto.Jonline exposing (GetServiceVersionResponse, GetUsersResponse, defaultGetUsersRequest)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.Permission exposing (Permission(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.Breadcrumbs as Breadcrumbs
import Task
import UI.Classes exposing (classes)
import Url.Builder



-- MODEL


type alias Model =
    { targetHost : String
    , isSecure : Bool
    , navKey : Browser.Navigation.Key
    , path : String
    , ownServerStatus : OwnServerStatus
    , activeTab : Tab
    , adminsStatus : AboutTab.AdminsStatus
    , versionStatus : AboutTab.VersionStatus
    , aboutTab : AboutTab.Model
    , themeTab : ThemeTab.Model
    , settingsTab : SettingsTab.Model
    , federationTab : FederationTab.Model
    , cdnTab : CdnTab.Model
    }


type Msg
    = TabSelected Tab
    | GotOwnServerResult (Result Grpc.Error AccountsPanel.Server)
    | AddServerClicked AccountsPanel.Server
    | GotAdmins (Result Grpc.Error GetUsersResponse)
    | GotVersion (Result Grpc.Error GetServiceVersionResponse)
    | AboutTabMsg AboutTab.Msg
    | ThemeTabMsg ThemeTab.Msg
    | SettingsTabMsg SettingsTab.Msg
    | FederationTabMsg FederationTab.Msg
    | CdnTabMsg CdnTab.Msg
    | SharedMsg Shared.Msg


{-| Named `TabAbout`/etc. (not bare `AboutTab`/etc.) purely to avoid colliding with this module's
own `AboutTab`/`ThemeTab`/`SettingsTab`/`FederationTab`/`CdnTab` submodule aliases -- those are used
qualified (`AboutTab.Model`, `AboutTab.view`, ...) everywhere else in this file.
-}
type Tab
    = TabAbout
    | TabTheme
    | TabSettings
    | TabFederation
    | TabCdn


{-| `Tab`'s URL-facing form for the `tab` query param (see `pushTabUrl`) -- lowercase, mirroring
`Components.Pages.PostsPage.postContextParam`. `TabAbout` is the default and is never written out
(see `pushTabUrl`), but is included here for `tabFromParam`'s sake.
-}
tabParam : Tab -> String
tabParam tab =
    case tab of
        TabAbout ->
            "about"

        TabTheme ->
            "theme"

        TabSettings ->
            "settings"

        TabFederation ->
            "federation"

        TabCdn ->
            "cdn"


{-| Case-insensitive inverse of `tabParam`, mirroring
`Components.Pages.PostsPage.postContextFromParam`. Any unrecognized value (e.g. a hand-edited link)
round-trips back to `Nothing`, falling back to `TabAbout` in `init`.
-}
tabFromParam : String -> Maybe Tab
tabFromParam param =
    case String.toLower param of
        "about" ->
            Just TabAbout

        "theme" ->
            Just TabTheme

        "settings" ->
            Just TabSettings

        "federation" ->
            Just TabFederation

        "cdn" ->
            Just TabCdn

        _ ->
            Nothing


{-| This page's own probe of the server, kept entirely separate from
`Shared.AccountsPanel.Model.servers` -- see the module doc. Irrelevant (`OwnServerNotNeeded`)
whenever the server's already known.
-}
type OwnServerStatus
    = OwnServerNotNeeded
    | LoadingOwnServer
    | OwnServerLoaded AccountsPanel.Server
    | OwnServerFailed String


{-| `pageIsSecure` is `Shared.AccountsPanel.isSecure req` (`Pages.About`) or parsed straight out of
the route (`Pages.Server.ServerIdentifier_`'s `[http|https]:hostname` segment) -- needed for the
own-probe fallback (see `AccountsPanel.connectToServer`), but not otherwise derivable from
`Shared.Model` alone. `navKey`/`path`, from the calling page's own `Request`, are what let
`TabSelected` persist the active tab as a `tab` URL query param (see `pushTabUrl`), mirroring
`Components.Pages.PostsPage.init`'s own `navKey`/`path` (there, for `search_text`/`context`) --
exactly, since every caller's `Request.key`/`Request.url.path` fit this regardless of which
page-specific `Gen.Params.*` type they're parameterized over. `query`, that same `Request`'s
already-parsed `.query`, seeds `activeTab` back out of the URL on load, so a shared/reloaded link
reopens on the same tab.
-}
init : Shared.Model -> Bool -> String -> Browser.Navigation.Key -> String -> Dict String String -> ( Model, Effect Msg )
init shared pageIsSecure targetHost navKey path query =
    let
        model0 =
            { targetHost = targetHost
            , isSecure = pageIsSecure
            , navKey = navKey
            , path = path
            , ownServerStatus = LoadingOwnServer
            , activeTab = Dict.get "tab" query |> Maybe.andThen tabFromParam |> Maybe.withDefault TabAbout
            , adminsStatus = AboutTab.AdminsNotLoaded
            , versionStatus = AboutTab.VersionNotLoaded
            , aboutTab = AboutTab.init
            , themeTab = ThemeTab.init
            , settingsTab = SettingsTab.init
            , federationTab = FederationTab.init
            , cdnTab = CdnTab.init
            }

        ( fetchedModel, fetchEffect ) =
            case knownConnectedServer shared targetHost of
                Just server ->
                    ( { model0 | ownServerStatus = OwnServerNotNeeded, adminsStatus = AboutTab.LoadingAdmins, versionStatus = AboutTab.LoadingVersion }
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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map FederationTabMsg (FederationTab.subscriptions model.federationTab)



-- UPDATE


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page into `update`'s
`SharedMsg` branch -- see `Pages.Post.PostId_.fromShared`.
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
            let
                newModel =
                    { model | activeTab = tab }
            in
            ( newModel, pushTabUrl newModel )

        GotOwnServerResult (Ok server) ->
            ( { model | ownServerStatus = OwnServerLoaded server, adminsStatus = AboutTab.LoadingAdmins, versionStatus = AboutTab.LoadingVersion }
            , Effect.batch [ fetchAdmins server, fetchVersion server ]
            )

        GotOwnServerResult (Err err) ->
            ( { model | ownServerStatus = OwnServerFailed (AccountsPanel.grpcErrorToString err) }, Effect.none )

        AddServerClicked server ->
            ( model, Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.ServerConnected server)) )

        GotAdmins (Ok response) ->
            ( { model | adminsStatus = AboutTab.AdminsLoaded (List.filter (\user -> List.member ADMIN user.permissions) response.users) }
            , Effect.none
            )

        GotAdmins (Err _) ->
            ( { model | adminsStatus = AboutTab.AdminsFailed }, Effect.none )

        GotVersion (Ok response) ->
            ( { model | versionStatus = AboutTab.VersionLoaded response.version }, Effect.none )

        GotVersion (Err _) ->
            ( { model | versionStatus = AboutTab.VersionFailed }, Effect.none )

        AboutTabMsg subMsg ->
            AboutTab.update shared model.targetHost subMsg model.aboutTab
                |> Tuple.mapFirst (\subModel -> { model | aboutTab = subModel })
                |> Tuple.mapSecond (Effect.map AboutTabMsg)

        ThemeTabMsg subMsg ->
            ThemeTab.update shared model.targetHost (effectiveServer shared model) subMsg model.themeTab
                |> Tuple.mapFirst (\subModel -> { model | themeTab = subModel })
                |> Tuple.mapSecond (Effect.map ThemeTabMsg)

        SettingsTabMsg subMsg ->
            SettingsTab.update shared model.targetHost (effectiveServer shared model) subMsg model.settingsTab
                |> Tuple.mapFirst (\subModel -> { model | settingsTab = subModel })
                |> Tuple.mapSecond (Effect.map SettingsTabMsg)

        FederationTabMsg subMsg ->
            FederationTab.update shared model.targetHost model.isSecure (effectiveServer shared model) subMsg model.federationTab
                |> Tuple.mapFirst (\subModel -> { model | federationTab = subModel })
                |> Tuple.mapSecond (Effect.map FederationTabMsg)

        CdnTabMsg subMsg ->
            CdnTab.update shared model.targetHost (effectiveServer shared model) subMsg model.cdnTab
                |> Tuple.mapFirst (\subModel -> { model | cdnTab = subModel })
                |> Tuple.mapSecond (Effect.map CdnTabMsg)

        SharedMsg subMsg ->
            ( { model
                | aboutTab = AboutTab.applySharedMsg subMsg model.aboutTab
                , themeTab = ThemeTab.applySharedMsg subMsg model.themeTab
              }
            , Effect.fromShared subMsg
            )


{-| `Shared.AccountsPanel`'s cached entry for `targetHost`, if it's both known _and_ actually
connected (see `AccountsPanel.knownConnectedServer`) -- a known-but-disconnected entry is treated
the same as not known at all, so this page falls back to its own probe (just like a never-added
host) rather than trying to show configuration/admins/version for a server it can't currently reach.
-}
knownConnectedServer : Shared.Model -> String -> Maybe AccountsPanel.Server
knownConnectedServer shared targetHost =
    AccountsPanel.knownConnectedServer shared.accounts.servers targetHost


{-| The `Server` to actually show details for -- whichever the app already knows about and is
connected to (from `Shared.AccountsPanel`, if this server's been added to Accounts & Servers
already), falling back to this page's own probe (`ownServerStatus`) otherwise.
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


{-| `model.targetHost`/`isSecure` reassembled into the `[http|https]:hostname` form
`Pages.Server.ServerIdentifier_`'s route uses -- just for error messages here (see `view`'s
`OwnServerFailed` branch); this module has no route of its own to round-trip through.
-}
identifierText : Model -> String
identifierText model =
    (if model.isSecure then
        "https:"

     else
        "http:"
    )
        ++ model.targetHost


{-| Keeps `Shared.Breadcrumbs` pointed at this page's own `FromServerHost targetHost` -- mirrors
`Components.Pages.UserProfilePage.setBreadcrumbsHost` (reissued after every `update`, a no-op once
already in sync via the same equality check), so the trail identifies this server both on the very
first paint and across any later host change (e.g. `GotOwnServerResult` resolving the own-probe).
-}
setBreadcrumbsHost : Shared.Model -> Model -> Effect Msg
setBreadcrumbsHost shared model =
    if shared.breadcrumbs.root == Just (Breadcrumbs.FromServerHost model.targetHost) then
        Effect.none

    else
        Effect.fromShared (Shared.BreadcrumbsMsg (Breadcrumbs.SetRoot (Breadcrumbs.FromServerHost model.targetHost) model.targetHost []))


{-| Persists `model.activeTab` to the URL as a `tab` query param, via `replaceUrl` (not `pushUrl` --
switching tabs shouldn't spam browser history with one entry per click). Omitted entirely at the
default (`TabAbout`), so the common case keeps a clean URL. Mirrors
`Components.Pages.PostsPage.pushSearchUrl` exactly, just over a single `Tab` param instead of
`search_text`/`context`.
-}
pushTabUrl : Model -> Effect Msg
pushTabUrl model =
    let
        tabParams =
            if model.activeTab == TabAbout then
                []

            else
                [ Url.Builder.string "tab" (tabParam model.activeTab) ]
    in
    Browser.Navigation.replaceUrl model.navKey (model.path ++ Url.Builder.toQuery tabParams)
        |> Effect.fromCmd


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



-- VIEW


{-| Just the subtitle -- the server's own name once known, else its `targetHost` -- for the calling
page's own `UI.pageTitle`.
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
            [ ( TabAbout, "About" )
            , ( TabTheme, "Theme" )
            , ( TabSettings, "Settings" )
            , ( TabFederation, "Federation" )
            , ( TabCdn, "CDN" )
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
    let
        maybeAdminAccount =
            Common.adminAccountFor shared model.targetHost
    in
    case model.activeTab of
        TabAbout ->
            Html.map AboutTabMsg (AboutTab.view shared server maybeAdminAccount model.adminsStatus model.versionStatus model.aboutTab)

        TabTheme ->
            Html.map ThemeTabMsg (ThemeTab.view server maybeAdminAccount model.themeTab)

        TabSettings ->
            Html.map SettingsTabMsg (SettingsTab.view server maybeAdminAccount model.settingsTab)

        TabFederation ->
            Html.map FederationTabMsg (FederationTab.view shared server maybeAdminAccount model.federationTab)

        TabCdn ->
            Html.map CdnTabMsg (CdnTab.view server maybeAdminAccount model.cdnTab)
