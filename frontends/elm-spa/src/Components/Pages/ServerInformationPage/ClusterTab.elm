module Components.Pages.ServerInformationPage.ClusterTab exposing (Model, Msg, init, update, view)

{-| The Cluster tab of `Components.Pages.ServerInformationPage` -- `ClusterResources` (see that
message's own doc in `server_configuration.proto`), editable by an admin holding
`EDITCLUSTERSETTINGS` as one unit (a single Edit/Save/Cancel, like every other section on this
page). Unlike every other tab, this one is never shown to a non-admin at all (see
`Components.Pages.ServerInformationPage`'s own tab list) -- `cluster_resources` is stripped
server-side from `GetServerConfiguration` for anyone but an admin, so there'd be nothing to show.

Within the tab, a *plain* admin (no `EDITCLUSTERSETTINGS`) still sees the current settings, just
without an Edit button -- mirroring `Common.adminAccountFor`'s "view vs. edit" split one permission
level further in, the same way `CdnTab`'s `cdnGrpc` field is always shown but never editable yet.
`clusterSharedSecret` is write-only (never sent back by the server, same as
`FacebookAuthConfig.appSecret`) -- its edit field always starts blank, and blank-on-save means
"leave the stored secret alone."
-}

import Components.Pages.ServerInformationPage.Common as Common
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, button, div, input, span, text)
import Html.Attributes exposing (class, disabled, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Proto.Rellm exposing (ClusterResources, ServerConfiguration, defaultClusterResources)
import Proto.Rellm.Permission exposing (Permission(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.AccountsPanel.RellmAccounts as RellmAccounts exposing (RellmAccount)
import Shared.AccountsPanel.RellmServers as RellmServers exposing (RellmServer)
import Task



-- MODEL


type alias Model =
    { configEdit : Maybe ClusterConfigEdit
    }


type Msg
    = ClusterEditClicked
    | ClusterEnabledToggled
    | ClusterNamespaceIdChanged String
    | ClusterConductorHostChanged String
    | ClusterSharedSecretChanged String
    | ClusterCancelClicked
    | ClusterSaveClicked
    | GotClusterSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))


{-| Live only while the cluster config is being edited -- `enabled` mirrors whether
`clusterResources` itself should be `Just`/`Nothing` on save (see `applyClusterConfig`);
`namespaceId`/`conductorHost`/`sharedSecret` are only meaningful (and only enabled in
`clusterEditView`) while `enabled` is `True`. `sharedSecret` always starts blank -- see this
module's own doc.
-}
type alias ClusterConfigEdit =
    { enabled : Bool
    , namespaceId : String
    , conductorHost : String
    , sharedSecret : String
    , status : AccountsPanel.FormStatus
    }


init : Model
init =
    { configEdit = Nothing }



-- UPDATE


update : Shared.Model -> String -> Maybe RellmServer -> Msg -> Model -> ( Model, Effect Msg )
update shared targetHost maybeServer msg model =
    case msg of
        ClusterEditClicked ->
            case maybeServer of
                Just server ->
                    let
                        clusterResources : Maybe ClusterResources
                        clusterResources =
                            (RellmServers.configurationOf server).clusterResources
                    in
                    ( { model
                        | configEdit =
                            Just
                                { enabled = clusterResources /= Nothing
                                , namespaceId = clusterResources |> Maybe.map .namespaceId |> Maybe.withDefault ""
                                , conductorHost = clusterResources |> Maybe.map .conductorHost |> Maybe.withDefault ""
                                , sharedSecret = ""
                                , status = AccountsPanel.Idle
                                }
                      }
                    , Effect.none
                    )

                Nothing ->
                    ( model, Effect.none )

        ClusterEnabledToggled ->
            ( { model | configEdit = model.configEdit |> Maybe.map (\edit -> { edit | enabled = not edit.enabled }) }, Effect.none )

        ClusterNamespaceIdChanged text ->
            ( { model | configEdit = model.configEdit |> Maybe.map (\edit -> { edit | namespaceId = text }) }, Effect.none )

        ClusterConductorHostChanged text ->
            ( { model | configEdit = model.configEdit |> Maybe.map (\edit -> { edit | conductorHost = text }) }, Effect.none )

        ClusterSharedSecretChanged text ->
            ( { model | configEdit = model.configEdit |> Maybe.map (\edit -> { edit | sharedSecret = text }) }, Effect.none )

        ClusterCancelClicked ->
            ( { model | configEdit = Nothing }, Effect.none )

        ClusterSaveClicked ->
            case ( model.configEdit, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( { model | configEdit = Just { edit | status = AccountsPanel.Submitting } }
                    , AccountsPanel.updateServerConfig shared.accounts ( Just account.userId, targetHost ) (applyClusterConfig edit)
                        |> Task.attempt GotClusterSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotClusterSaveResult (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( { model | configEdit = Nothing }
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotClusterSaveResult (Err err) ->
            ( { model | configEdit = model.configEdit |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )


{-| `ClusterSaveClicked`'s transform, passed to `AccountsPanel.updateServerConfig` the same way
every other editor's transform is -- when `enabled` is off, nulls `clusterResources` out entirely;
when on, overlays `namespaceId`/`conductorHost` onto whatever a freshly re-fetched config already
has for `clusterResources` (`defaultClusterResources` the first time it's ever set). `sharedSecret`
is sent blank unless this save is actually changing it (edit.sharedSecret non-empty) -- a blank
incoming value means "leave the stored secret alone" server-side, same as `applyFacebookAppSecret`.
`conductorState` is left untouched either way -- the server never lets `ConfigureServer` change it
regardless of what's sent (see `ClusterResources.conductorState`'s own doc).
-}
applyClusterConfig : ClusterConfigEdit -> ServerConfiguration -> ServerConfiguration
applyClusterConfig edit config =
    if edit.enabled then
        let
            existing : ClusterResources
            existing =
                Maybe.withDefault defaultClusterResources config.clusterResources
        in
        { config
            | clusterResources =
                Just
                    { existing
                        | namespaceId = edit.namespaceId
                        , conductorHost = edit.conductorHost
                        , clusterSharedSecret = edit.sharedSecret
                    }
        }

    else
        { config | clusterResources = Nothing }



-- VIEW


{-| Whether `account` can actually edit `clusterResources` via `ConfigureServer` -- `ADMIN` alone
(already required just to reach this tab -- see this module's own doc) isn't enough; the server
also requires `EDITCLUSTERSETTINGS` specifically (see that permission's own doc), deliberately not
grantable via `UpdateUser`, so this can't be self-served the way most permissions can.
-}
canEditCluster : RellmAccount -> Bool
canEditCluster account =
    List.member EDITCLUSTERSETTINGS account.permissions


view : RellmServer -> Maybe RellmAccount -> Model -> Html Msg
view server maybeAdminAccount model =
    let
        clusterResources : Maybe ClusterResources
        clusterResources =
            (RellmServers.configurationOf server).clusterResources
    in
    div [ class "server-details-tab-content server-details-cluster" ]
        (case model.configEdit of
            Just edit ->
                clusterEditView edit

            Nothing ->
                clusterDisplayView maybeAdminAccount clusterResources
        )


clusterDisplayView : Maybe RellmAccount -> Maybe ClusterResources -> List (Html Msg)
clusterDisplayView maybeAdminAccount clusterResources =
    [ Common.settingsRow "Cluster Resource Sharing" (Common.switchDisplay (clusterResources /= Nothing))
    , Common.settingsRow "Namespace ID" (span [ class "server-details-feature-settings-value" ] [ text (clusterResources |> Maybe.map .namespaceId |> Maybe.withDefault "—") ])
    , Common.settingsRow "Conductor Host" (span [ class "server-details-feature-settings-value" ] [ text (clusterResources |> Maybe.map .conductorHost |> Maybe.withDefault "—") ])
    , case maybeAdminAccount of
        Just account ->
            if canEditCluster account then
                button [ class "server-details-rename-button", onClick ClusterEditClicked ] [ text "Edit Cluster Settings" ]

            else
                text ""

        Nothing ->
            text ""
    ]


{-| `namespaceId`/`conductorHost`/`sharedSecret` are only `disabled False` (editable) while
`edit.enabled` is on -- turning the main toggle off is the "null the whole config out" action, so
there's nothing useful to type into them until it's back on.
-}
clusterEditView : ClusterConfigEdit -> List (Html Msg)
clusterEditView edit =
    [ Common.settingsRow "Cluster Resource Sharing" (Common.flagSwitch edit.enabled ClusterEnabledToggled)
    , Common.settingsRow "Namespace ID"
        (input
            [ class "server-details-rename-input"
            , placeholder "e.g. its Kubernetes namespace"
            , value edit.namespaceId
            , onInput ClusterNamespaceIdChanged
            , disabled (not edit.enabled || edit.status == AccountsPanel.Submitting)
            ]
            []
        )
    , Common.settingsRow "Conductor Host"
        (input
            [ class "server-details-rename-input"
            , placeholder "jonline.io"
            , value edit.conductorHost
            , onInput ClusterConductorHostChanged
            , disabled (not edit.enabled || edit.status == AccountsPanel.Submitting)
            ]
            []
        )
    , Common.settingsRow "Shared Secret"
        (input
            [ class "server-details-rename-input"
            , placeholder "leave blank to keep the current secret"
            , value edit.sharedSecret
            , onInput ClusterSharedSecretChanged
            , disabled (not edit.enabled || edit.status == AccountsPanel.Submitting)
            ]
            []
        )
    , div [ class "server-details-feature-settings-actions" ]
        [ Common.editSaveButton ClusterSaveClicked edit.status
        , Common.editCancelButton ClusterCancelClicked edit.status
        ]
    , Common.editErrorView edit.status
    ]
