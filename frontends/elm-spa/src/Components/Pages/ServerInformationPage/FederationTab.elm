module Components.Pages.ServerInformationPage.FederationTab exposing (Model, Msg, init, subscriptions, update, view)

{-| The Federation tab of `Components.Pages.ServerInformationPage` -- the server's federated-server
chip strip (add/remove/reorder-animated via `UI.Flip`, see `FederationEdit`'s own doc), the Facebook
App ID/Secret an admin connects so users can create Facebook Event Sync Destinations (see
`logic::facebook_sync` on the backend), and the Web Push VAPID public/private keys an admin sets so
`RegisterPushSubscription`'d browsers actually receive notifications (see `backend/src/web_push`).
All three are backed by fields on the same `ServerConfiguration`
(`federationInfo`/`federationInfo.facebookAuthConfig`/`webPushConfig`), saved through the same
`AccountsPanel.updateServerConfig` "fetch fresh copy, then write" dance every other editor on this
page uses.
-}

import Animation
import Browser.Dom as Dom
import Components.Pages.ServerInformationPage.Common as Common
import Dict exposing (Dict)
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, button, div, h3, input, p, span, text)
import Html.Attributes exposing (class, disabled, id, placeholder, title, value)
import Html.Events exposing (onClick, onInput, stopPropagationOn)
import Html.Keyed
import Json.Decode as Decode
import Proto.Jonline exposing (FederatedServer, ServerConfiguration)
import Shared
import Shared.AccountsPanel as AccountsPanel
import Task
import UI.Classes exposing (classes, hostnameToCSSClass)
import UI.Flip



-- MODEL


type alias Model =
    { federationEdit : Maybe FederationEdit
    , facebookAppIdEdit : Maybe TextFieldEdit
    , facebookAppSecretEdit : Maybe TextFieldEdit
    , webPushPublicKeyEdit : Maybe TextFieldEdit
    , webPushPrivateKeyEdit : Maybe TextFieldEdit
    }


type Msg
    = FederationEditClicked
    | FederationCancelClicked
    | FederationSaveClicked
    | GotFederationSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))
    | FederatedServerHostInputChanged String
    | FederatedServerAddClicked
    | GotFederatedServerAddResult String (Result Grpc.Error AccountsPanel.Server)
    | FederatedServerRemoveClicked String
    | FederatedServerRemoved String
    | FederatedServerConfiguredByDefaultToggled String
    | FederatedServerPinnedByDefaultToggled String
    | MoveFederatedServerLeftClicked String
    | MoveFederatedServerRightClicked String
    | GotPreMoveFederatedServerPositions String String Int (Result Dom.Error ( Dom.Element, Dom.Element ))
    | FederatedServerMoveSettled String
    | AnimateFederatedServerFlip Animation.Msg
    | AnimateFederatedServerMove Animation.Msg
    | FacebookAppIdEditClicked
    | FacebookAppIdChanged String
    | FacebookAppIdCancelClicked
    | FacebookAppIdSaveClicked
    | GotFacebookAppIdSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))
    | FacebookAppSecretEditClicked
    | FacebookAppSecretChanged String
    | FacebookAppSecretCancelClicked
    | FacebookAppSecretSaveClicked
    | GotFacebookAppSecretSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))
    | WebPushPublicKeyEditClicked
    | WebPushPublicKeyChanged String
    | WebPushPublicKeyCancelClicked
    | WebPushPublicKeySaveClicked
    | GotWebPushPublicKeySaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))
    | WebPushPrivateKeyEditClicked
    | WebPushPrivateKeyChanged String
    | WebPushPrivateKeyCancelClicked
    | WebPushPrivateKeySaveClicked
    | GotWebPushPrivateKeySaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))


{-| Live only while the Federation tab's `FederatedServer` list is being edited by an admin --
`pending` is the in-progress ordered list (its order is this editor's own, never rederived from a
fetch -- see `UI.Flip.remove`'s own doc on why a removing-but-not-yet-removed entry has to keep its
slot rather than being relocated), independent of the actual saved list until `FederationSaveClicked`
succeeds. `hostInput`/`addStatus` back the "type a host, validate it, add it" row
(`FederatedServerAddClicked`, validated via `AccountsPanel.connectToServer` the same way this page's
own probe validates an unknown server); a freshly-added entry always starts with both flags off (see
`GotFederatedServerAddResult`). `itemAnimations`/`moveAnimations` are this editor's own `UI.Flip`
state for the chip strip's add/remove fade and left/right reorder-slide -- mirrors
`Shared.AccountsPanel`'s `serverAnimations`/`serverMoveAnimations` for its Servers strip, just scoped
to this one in-progress edit instead of the app-wide server list.
-}
type alias FederationEdit =
    { pending : List FederatedServer
    , hostInput : String
    , addStatus : AccountsPanel.FormStatus
    , status : AccountsPanel.FormStatus
    , itemAnimations : Dict String (UI.Flip.State Msg)
    , moveAnimations : Dict String (UI.Flip.MoveState Msg)
    }


{-| Live only while one of this tab's simple "Edit" -> text field -> Save rows (Facebook App
ID/Secret, see `facebookAuthConfigSection`; Web Push public/private VAPID key, see
`webPushConfigSection`) is being edited by an admin -- `pending` is the in-progress `<input>` value.
The two write-only fields (`FacebookAuthConfig.appSecret`, `WebPushConfig.privateVapidKey`) always
start this at `""` (never pre-filled), since neither is ever actually sent back by the server (see
`ToProtoServerConfiguration` on the backend) -- saving with `pending == ""` is a deliberate no-op
there (leaves whatever's already stored alone), same as leaving a "change password" field blank. The
other two (`appId`, `publicVapidKey`) aren't secret, so their own edits start pre-filled with the
current value instead.
-}
type alias TextFieldEdit =
    { pending : String
    , status : AccountsPanel.FormStatus
    }


init : Model
init =
    { federationEdit = Nothing
    , facebookAppIdEdit = Nothing
    , facebookAppSecretEdit = Nothing
    , webPushPublicKeyEdit = Nothing
    , webPushPrivateKeyEdit = Nothing
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.federationEdit of
        Just edit ->
            Sub.batch
                [ UI.Flip.subscription AnimateFederatedServerFlip (Dict.values edit.itemAnimations)
                , UI.Flip.moveSubscription AnimateFederatedServerMove (Dict.values edit.moveAnimations)
                ]

        Nothing ->
            Sub.none



-- UPDATE


update : Shared.Model -> String -> Bool -> Maybe AccountsPanel.Server -> Msg -> Model -> ( Model, Effect Msg )
update shared targetHost isSecure maybeServer msg model =
    case msg of
        FederationEditClicked ->
            case maybeServer of
                Just server ->
                    let
                        savedServers : List FederatedServer
                        savedServers =
                            (AccountsPanel.configurationOf server).federationInfo |> Maybe.map .servers |> Maybe.withDefault []
                    in
                    ( { model
                        | federationEdit =
                            Just
                                { pending = savedServers
                                , hostInput = ""
                                , addStatus = AccountsPanel.Idle
                                , status = AccountsPanel.Idle
                                , itemAnimations = savedServers |> List.map (\federatedServer -> ( federatedServer.host, UI.Flip.restingState )) |> Dict.fromList
                                , moveAnimations = Dict.empty
                                }
                      }
                    , Effect.none
                    )

                Nothing ->
                    ( model, Effect.none )

        FederationCancelClicked ->
            ( { model | federationEdit = Nothing }, Effect.none )

        FederationSaveClicked ->
            case ( model.federationEdit, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( { model | federationEdit = Just { edit | status = AccountsPanel.Submitting } }
                    , AccountsPanel.updateServerConfig shared.accounts ( Just account.userId, targetHost ) (applyFederatedServers edit.pending)
                        |> Task.attempt GotFederationSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotFederationSaveResult (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( { model | federationEdit = Nothing }
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotFederationSaveResult (Err err) ->
            ( { model | federationEdit = model.federationEdit |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )

        FederatedServerHostInputChanged text ->
            ( { model | federationEdit = model.federationEdit |> Maybe.map (\edit -> { edit | hostInput = text }) }, Effect.none )

        FederatedServerAddClicked ->
            case model.federationEdit of
                Just edit ->
                    let
                        host : String
                        host =
                            String.trim edit.hostInput
                    in
                    if String.isEmpty host || List.any (\federatedServer -> federatedServer.host == host) edit.pending then
                        ( model, Effect.none )

                    else
                        ( { model | federationEdit = Just { edit | addStatus = AccountsPanel.Submitting } }
                        , AccountsPanel.connectToServer isSecure host
                            |> Task.attempt (GotFederatedServerAddResult host)
                            |> Effect.fromCmd
                        )

                Nothing ->
                    ( model, Effect.none )

        GotFederatedServerAddResult host (Ok _) ->
            ( { model
                | federationEdit =
                    model.federationEdit
                        |> Maybe.map
                            (\edit ->
                                { edit
                                    | pending = { host = host, configuredByDefault = Just False, pinnedByDefault = Just False } :: edit.pending
                                    , hostInput = ""
                                    , addStatus = AccountsPanel.Idle
                                    , itemAnimations = Dict.insert host UI.Flip.enter edit.itemAnimations
                                }
                            )
              }
            , Effect.none
            )

        GotFederatedServerAddResult _ (Err err) ->
            ( { model | federationEdit = model.federationEdit |> Maybe.map (\edit -> { edit | addStatus = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )

        FederatedServerRemoveClicked host ->
            ( { model
                | federationEdit =
                    model.federationEdit
                        |> Maybe.map
                            (\edit ->
                                let
                                    currentState : UI.Flip.State Msg
                                    currentState =
                                        Dict.get host edit.itemAnimations |> Maybe.withDefault UI.Flip.restingState
                                in
                                { edit | itemAnimations = Dict.insert host (UI.Flip.remove (FederatedServerRemoved host) currentState) edit.itemAnimations }
                            )
              }
            , Effect.none
            )

        FederatedServerRemoved host ->
            ( { model
                | federationEdit =
                    model.federationEdit
                        |> Maybe.map
                            (\edit ->
                                { edit
                                    | pending = List.filter (\federatedServer -> federatedServer.host /= host) edit.pending
                                    , itemAnimations = Dict.remove host edit.itemAnimations
                                }
                            )
              }
            , Effect.none
            )

        FederatedServerConfiguredByDefaultToggled host ->
            ( { model
                | federationEdit =
                    model.federationEdit
                        |> Maybe.map (mapPendingHost host (\federatedServer -> { federatedServer | configuredByDefault = Just (not (Maybe.withDefault False federatedServer.configuredByDefault)) }))
              }
            , Effect.none
            )

        FederatedServerPinnedByDefaultToggled host ->
            ( { model
                | federationEdit =
                    model.federationEdit
                        |> Maybe.map (mapPendingHost host (\federatedServer -> { federatedServer | pinnedByDefault = Just (not (Maybe.withDefault False federatedServer.pinnedByDefault)) }))
              }
            , Effect.none
            )

        MoveFederatedServerLeftClicked host ->
            ( model
            , model.federationEdit
                |> Maybe.map (\edit -> UI.Flip.beginReorder .host federatedServerChipDomId GotPreMoveFederatedServerPositions -1 host edit.pending)
                |> Maybe.withDefault Cmd.none
                |> Effect.fromCmd
            )

        MoveFederatedServerRightClicked host ->
            ( model
            , model.federationEdit
                |> Maybe.map (\edit -> UI.Flip.beginReorder .host federatedServerChipDomId GotPreMoveFederatedServerPositions 1 host edit.pending)
                |> Maybe.withDefault Cmd.none
                |> Effect.fromCmd
            )

        GotPreMoveFederatedServerPositions host _ offset (Err _) ->
            ( { model
                | federationEdit =
                    model.federationEdit |> Maybe.map (\edit -> { edit | pending = UI.Flip.moveListItemBy .host offset host edit.pending })
              }
            , Effect.none
            )

        GotPreMoveFederatedServerPositions host neighborHost offset (Ok ( chipEl, neighborEl )) ->
            ( { model
                | federationEdit =
                    model.federationEdit
                        |> Maybe.map
                            (\edit ->
                                { edit
                                    | pending = UI.Flip.moveListItemBy .host offset host edit.pending
                                    , moveAnimations = UI.Flip.applyReorder UI.Flip.Horizontal FederatedServerMoveSettled host neighborHost chipEl neighborEl edit.moveAnimations
                                }
                            )
              }
            , Effect.none
            )

        FederatedServerMoveSettled host ->
            ( { model
                | federationEdit =
                    model.federationEdit
                        |> Maybe.map (\edit -> { edit | moveAnimations = Dict.update host (Maybe.map (\state -> { state | moving = False })) edit.moveAnimations })
              }
            , Effect.none
            )

        AnimateFederatedServerFlip animMsg ->
            case model.federationEdit of
                Just edit ->
                    let
                        step : String -> UI.Flip.State Msg -> ( Dict String (UI.Flip.State Msg), List (Cmd Msg) ) -> ( Dict String (UI.Flip.State Msg), List (Cmd Msg) )
                        step key state ( states, stepCmds ) =
                            let
                                ( newState, cmd ) =
                                    UI.Flip.animate animMsg state
                            in
                            ( Dict.insert key newState states, cmd :: stepCmds )

                        ( newAnimations, cmds ) =
                            Dict.foldl step ( Dict.empty, [] ) edit.itemAnimations
                    in
                    ( { model | federationEdit = Just { edit | itemAnimations = newAnimations } }, Effect.fromCmd (Cmd.batch cmds) )

                Nothing ->
                    ( model, Effect.none )

        AnimateFederatedServerMove animMsg ->
            case model.federationEdit of
                Just edit ->
                    let
                        step : String -> UI.Flip.MoveState Msg -> ( Dict String (UI.Flip.MoveState Msg), List (Cmd Msg) ) -> ( Dict String (UI.Flip.MoveState Msg), List (Cmd Msg) )
                        step key state ( states, stepCmds ) =
                            let
                                ( newState, cmd ) =
                                    UI.Flip.moveAnimate animMsg state
                            in
                            ( Dict.insert key newState states, cmd :: stepCmds )

                        ( newAnimations, cmds ) =
                            Dict.foldl step ( Dict.empty, [] ) edit.moveAnimations
                    in
                    ( { model | federationEdit = Just { edit | moveAnimations = newAnimations } }, Effect.fromCmd (Cmd.batch cmds) )

                Nothing ->
                    ( model, Effect.none )

        FacebookAppIdEditClicked ->
            case maybeServer of
                Just server ->
                    let
                        currentAppId : String
                        currentAppId =
                            (AccountsPanel.configurationOf server).federationInfo
                                |> Maybe.andThen .facebookAuthConfig
                                |> Maybe.map .appId
                                |> Maybe.withDefault ""
                    in
                    ( { model | facebookAppIdEdit = Just { pending = currentAppId, status = AccountsPanel.Idle } }, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        FacebookAppIdChanged text ->
            ( { model | facebookAppIdEdit = model.facebookAppIdEdit |> Maybe.map (\edit -> { edit | pending = text }) }, Effect.none )

        FacebookAppIdCancelClicked ->
            ( { model | facebookAppIdEdit = Nothing }, Effect.none )

        FacebookAppIdSaveClicked ->
            case ( model.facebookAppIdEdit, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( { model | facebookAppIdEdit = Just { edit | status = AccountsPanel.Submitting } }
                    , AccountsPanel.updateServerConfig shared.accounts ( Just account.userId, targetHost ) (applyFacebookAppId edit.pending)
                        |> Task.attempt GotFacebookAppIdSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotFacebookAppIdSaveResult (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( { model | facebookAppIdEdit = Nothing }
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotFacebookAppIdSaveResult (Err err) ->
            ( { model | facebookAppIdEdit = model.facebookAppIdEdit |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )

        FacebookAppSecretEditClicked ->
            ( { model | facebookAppSecretEdit = Just { pending = "", status = AccountsPanel.Idle } }, Effect.none )

        FacebookAppSecretChanged text ->
            ( { model | facebookAppSecretEdit = model.facebookAppSecretEdit |> Maybe.map (\edit -> { edit | pending = text }) }, Effect.none )

        FacebookAppSecretCancelClicked ->
            ( { model | facebookAppSecretEdit = Nothing }, Effect.none )

        FacebookAppSecretSaveClicked ->
            case ( model.facebookAppSecretEdit, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( { model | facebookAppSecretEdit = Just { edit | status = AccountsPanel.Submitting } }
                    , AccountsPanel.updateServerConfig shared.accounts ( Just account.userId, targetHost ) (applyFacebookAppSecret edit.pending)
                        |> Task.attempt GotFacebookAppSecretSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotFacebookAppSecretSaveResult (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( { model | facebookAppSecretEdit = Nothing }
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotFacebookAppSecretSaveResult (Err err) ->
            ( { model | facebookAppSecretEdit = model.facebookAppSecretEdit |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )

        WebPushPublicKeyEditClicked ->
            case maybeServer of
                Just server ->
                    let
                        currentPublicKey : String
                        currentPublicKey =
                            (AccountsPanel.configurationOf server).webPushConfig
                                |> Maybe.map .publicVapidKey
                                |> Maybe.withDefault ""
                    in
                    ( { model | webPushPublicKeyEdit = Just { pending = currentPublicKey, status = AccountsPanel.Idle } }, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        WebPushPublicKeyChanged text ->
            ( { model | webPushPublicKeyEdit = model.webPushPublicKeyEdit |> Maybe.map (\edit -> { edit | pending = text }) }, Effect.none )

        WebPushPublicKeyCancelClicked ->
            ( { model | webPushPublicKeyEdit = Nothing }, Effect.none )

        WebPushPublicKeySaveClicked ->
            case ( model.webPushPublicKeyEdit, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( { model | webPushPublicKeyEdit = Just { edit | status = AccountsPanel.Submitting } }
                    , AccountsPanel.updateServerConfig shared.accounts ( Just account.userId, targetHost ) (applyWebPushPublicKey edit.pending)
                        |> Task.attempt GotWebPushPublicKeySaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotWebPushPublicKeySaveResult (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( { model | webPushPublicKeyEdit = Nothing }
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotWebPushPublicKeySaveResult (Err err) ->
            ( { model | webPushPublicKeyEdit = model.webPushPublicKeyEdit |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )

        WebPushPrivateKeyEditClicked ->
            ( { model | webPushPrivateKeyEdit = Just { pending = "", status = AccountsPanel.Idle } }, Effect.none )

        WebPushPrivateKeyChanged text ->
            ( { model | webPushPrivateKeyEdit = model.webPushPrivateKeyEdit |> Maybe.map (\edit -> { edit | pending = text }) }, Effect.none )

        WebPushPrivateKeyCancelClicked ->
            ( { model | webPushPrivateKeyEdit = Nothing }, Effect.none )

        WebPushPrivateKeySaveClicked ->
            case ( model.webPushPrivateKeyEdit, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( { model | webPushPrivateKeyEdit = Just { edit | status = AccountsPanel.Submitting } }
                    , AccountsPanel.updateServerConfig shared.accounts ( Just account.userId, targetHost ) (applyWebPushPrivateKey edit.pending)
                        |> Task.attempt GotWebPushPrivateKeySaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotWebPushPrivateKeySaveResult (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( { model | webPushPrivateKeyEdit = Nothing }
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotWebPushPrivateKeySaveResult (Err err) ->
            ( { model | webPushPrivateKeyEdit = model.webPushPrivateKeyEdit |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )


{-| `FederationSaveClicked`'s transform, passed to `AccountsPanel.updateServerConfig` the same way
every other editor's transform is -- overlays `servers` (the edit's `pending` list, in its edit's
own order) onto a freshly re-fetched `ServerConfiguration`'s `federationInfo`, leaving
`facebookAuthConfig` (and every other field) untouched.
-}
applyFederatedServers : List FederatedServer -> ServerConfiguration -> ServerConfiguration
applyFederatedServers servers config =
    { config
        | federationInfo =
            Just
                { servers = servers
                , facebookAuthConfig = config.federationInfo |> Maybe.andThen .facebookAuthConfig
                }
    }


{-| `FacebookAppIdSaveClicked`'s transform, passed to `AccountsPanel.updateServerConfig` the same
way `applyFederatedServers`'s result is -- overlays a new `appId` onto a freshly re-fetched
`ServerConfiguration`'s `federationInfo.facebookAuthConfig`, leaving `servers` untouched. `appSecret`
is always sent blank here: the backend's `ConfigureServer` treats a blank incoming `appSecret` as
"leave whatever's already stored alone" (it's write-only -- see `TextFieldEdit`'s own doc),
so this can never accidentally clobber it.
-}
applyFacebookAppId : String -> ServerConfiguration -> ServerConfiguration
applyFacebookAppId appId config =
    let
        federationInfo : Proto.Jonline.FederationInfo
        federationInfo =
            Maybe.withDefault { servers = [], facebookAuthConfig = Nothing } config.federationInfo
    in
    { config
        | federationInfo =
            Just { federationInfo | facebookAuthConfig = Just { appId = appId, appSecret = "" } }
    }


{-| `FacebookAppSecretSaveClicked`'s transform -- mirrors `applyFacebookAppId`, just overlaying a
new `appSecret` (this time actually non-blank, since this _is_ the save that's meant to change it)
instead. Keeps whatever `appId` the freshly re-fetched config already has.
-}
applyFacebookAppSecret : String -> ServerConfiguration -> ServerConfiguration
applyFacebookAppSecret appSecret config =
    let
        federationInfo : Proto.Jonline.FederationInfo
        federationInfo =
            Maybe.withDefault { servers = [], facebookAuthConfig = Nothing } config.federationInfo

        existingAppId : String
        existingAppId =
            federationInfo.facebookAuthConfig |> Maybe.map .appId |> Maybe.withDefault ""
    in
    { config
        | federationInfo =
            Just { federationInfo | facebookAuthConfig = Just { appId = existingAppId, appSecret = appSecret } }
    }


{-| `WebPushPublicKeySaveClicked`'s transform -- overlays a new `publicVapidKey` onto a freshly
re-fetched `ServerConfiguration`'s `webPushConfig`. `privateVapidKey` is always sent blank here:
same "blank means leave it alone" merge `applyFacebookAppId`'s own `appSecret` relies on, this time
in `ConfigureServer`'s `WebPushConfig`-specific merge block (see that RPC's own doc comment).
-}
applyWebPushPublicKey : String -> ServerConfiguration -> ServerConfiguration
applyWebPushPublicKey publicKey config =
    { config | webPushConfig = Just { publicVapidKey = publicKey, privateVapidKey = "" } }


{-| `WebPushPrivateKeySaveClicked`'s transform -- mirrors `applyWebPushPublicKey`, just overlaying a
new `privateVapidKey` (this time actually non-blank, since this _is_ the save that's meant to change
it) instead. Keeps whatever `publicVapidKey` the freshly re-fetched config already has.
-}
applyWebPushPrivateKey : String -> ServerConfiguration -> ServerConfiguration
applyWebPushPrivateKey privateKey config =
    let
        existingPublicKey : String
        existingPublicKey =
            config.webPushConfig |> Maybe.map .publicVapidKey |> Maybe.withDefault ""
    in
    { config | webPushConfig = Just { publicVapidKey = existingPublicKey, privateVapidKey = privateKey } }


{-| Updates the one entry of `edit.pending` matching `host`, if any --
`FederatedServerConfiguredByDefaultToggled`/`FederatedServerPinnedByDefaultToggled`'s shared
plumbing.
-}
mapPendingHost : String -> (FederatedServer -> FederatedServer) -> FederationEdit -> FederationEdit
mapPendingHost host fn edit =
    { edit
        | pending =
            edit.pending
                |> List.map
                    (\federatedServer ->
                        if federatedServer.host == host then
                            fn federatedServer

                        else
                            federatedServer
                    )
    }


{-| The DOM `id` a federated-server chip is rendered with while `federationEdit` is active -- the
`UI.Flip.Horizontal` counterpart of `AccountsPanel.serverChipDomId`, for
`MoveFederatedServerLeftClicked`/`MoveFederatedServerRightClicked` to measure. Deliberately its own
id scheme (not `AccountsPanel.serverChipDomId`) even though a federated host can coincide with an
already-added server's own `frontendHost` -- that server's own chip (in the Accounts Panel, via
`UI.serversStrip`) can be on-screen at the very same time this tab is, and DOM ids must be unique.
-}
federatedServerChipDomId : String -> String
federatedServerChipDomId host =
    "federated-server-chip-" ++ host


{-| The `AccountsPanel.Server` to show a federated host's name/logo off of -- the real,
already-known one if `host` happens to also be a known `Server` (e.g. also added to Accounts &
Servers), otherwise a synthetic unconnected record whose `AccountsPanel.brandingOf` falls back to
the bare host string (no logo, no separate name) -- same "synthesize an unconnected `Server`"
fallback `UI.recommendedServerChip` uses for a host it hasn't background-connected to yet.
-}
federatedServerFor : Shared.Model -> String -> AccountsPanel.Server
federatedServerFor shared host =
    AccountsPanel.serverForHost shared.accounts.servers host
        |> Maybe.withDefault { frontendHost = host, enabled = False, connected = Nothing }



-- VIEW


{-| Only an admin sees the Edit button (and, once clicked, the editor -- see
`federationEditorView`); anyone else just sees the read-only chip strip
(`federationDisplayView`), same split as every other editor on this page.
-}
view : Shared.Model -> AccountsPanel.Server -> Maybe AccountsPanel.Account -> Model -> Html Msg
view shared server maybeAdminAccount model =
    div [ class "server-details-tab-content server-details-federation" ]
        [ h3 [ class "section-title" ] [ text "Federated Servers" ]
        , case model.federationEdit of
            Just edit ->
                federationEditorView shared edit

            Nothing ->
                let
                    savedServers : List FederatedServer
                    savedServers =
                        (AccountsPanel.configurationOf server).federationInfo |> Maybe.map .servers |> Maybe.withDefault []
                in
                federationDisplayView shared savedServers
        , case ( model.federationEdit, maybeAdminAccount ) of
            ( Nothing, Just _ ) ->
                button [ class "server-details-rename-button", onClick FederationEditClicked ] [ text "Edit" ]

            _ ->
                text ""
        , facebookAuthConfigSection server model maybeAdminAccount
        , webPushConfigSection server model maybeAdminAccount
        ]


facebookAuthConfigSection : AccountsPanel.Server -> Model -> Maybe AccountsPanel.Account -> Html Msg
facebookAuthConfigSection server model maybeAdminAccount =
    let
        currentAppId : String
        currentAppId =
            (AccountsPanel.configurationOf server).federationInfo
                |> Maybe.andThen .facebookAuthConfig
                |> Maybe.map .appId
                |> Maybe.withDefault ""
    in
    div [ class "server-details-facebook-auth" ]
        (h3 [ class "section-title" ] [ text "Facebook Authentication Configuration" ]
            :: facebookAppIdRow currentAppId model.facebookAppIdEdit maybeAdminAccount
            :: (case maybeAdminAccount of
                    Just _ ->
                        [ facebookAppSecretRow model.facebookAppSecretEdit maybeAdminAccount ]

                    Nothing ->
                        []
               )
        )


facebookAppIdRow : String -> Maybe TextFieldEdit -> Maybe AccountsPanel.Account -> Html Msg
facebookAppIdRow currentAppId maybeEdit maybeAdminAccount =
    case maybeEdit of
        Just edit ->
            div [ class "server-details-color-row server-details-color-row-edit" ]
                [ span [ class "server-details-color-label" ] [ text "App ID" ]
                , input
                    [ class "server-details-rename-input"
                    , value edit.pending
                    , onInput FacebookAppIdChanged
                    , disabled (edit.status == AccountsPanel.Submitting)
                    ]
                    []
                , Common.editSaveButton FacebookAppIdSaveClicked edit.status
                , Common.editCancelButton FacebookAppIdCancelClicked edit.status
                , Common.editErrorView edit.status
                ]

        Nothing ->
            div [ class "server-details-color-row" ]
                [ span [ class "server-details-color-label" ] [ text "App ID" ]
                , span [ class "server-details-color-hex" ]
                    [ text
                        (if String.isEmpty currentAppId then
                            "Not set."

                         else
                            currentAppId
                        )
                    ]
                , case maybeAdminAccount of
                    Just _ ->
                        button [ class "server-details-rename-button", onClick FacebookAppIdEditClicked ] [ text "Edit" ]

                    Nothing ->
                        text ""
                ]


{-| Unlike `facebookAppIdRow`, there's no "current value" to show when not editing -- the server
never sends the real `appSecret` back (see `TextFieldEdit`'s doc), so the placeholder below
is shown regardless of whether a secret is actually configured. Clicking Edit always starts from a
blank `<input>`; saving it blank is a no-op on the backend, same as leaving a "change password"
field untouched.
-}
facebookAppSecretRow : Maybe TextFieldEdit -> Maybe AccountsPanel.Account -> Html Msg
facebookAppSecretRow maybeEdit maybeAdminAccount =
    case maybeEdit of
        Just edit ->
            div [ class "server-details-color-row server-details-color-row-edit" ]
                [ span [ class "server-details-color-label" ] [ text "App Secret" ]
                , input
                    [ Html.Attributes.type_ "password"
                    , class "server-details-rename-input"
                    , placeholder "New App Secret"
                    , value edit.pending
                    , onInput FacebookAppSecretChanged
                    , disabled (edit.status == AccountsPanel.Submitting)
                    ]
                    []
                , Common.editSaveButton FacebookAppSecretSaveClicked edit.status
                , Common.editCancelButton FacebookAppSecretCancelClicked edit.status
                , Common.editErrorView edit.status
                ]

        Nothing ->
            div [ class "server-details-color-row" ]
                [ span [ class "server-details-color-label" ] [ text "App Secret" ]
                , span [ class "server-details-color-hex" ] [ text "Never shown" ]
                , case maybeAdminAccount of
                    Just _ ->
                        button [ class "server-details-rename-button", onClick FacebookAppSecretEditClicked ] [ text "Edit" ]

                    Nothing ->
                        text ""
                ]


{-| Mirrors `facebookAuthConfigSection`: the VAPID public/private key pair an admin sets so Web
Push notifications (see `Shared.AccountsPanel`'s "Enable notifications", `backend/src/web_push`) can
actually be sent to this server's subscribers. Only ever shown to an admin -- there's nothing for a
non-admin to configure here, unlike the Facebook section (which shows the read-only App ID to
everyone).
-}
webPushConfigSection : AccountsPanel.Server -> Model -> Maybe AccountsPanel.Account -> Html Msg
webPushConfigSection server model maybeAdminAccount =
    case maybeAdminAccount of
        Nothing ->
            text ""

        Just _ ->
            let
                currentPublicKey : String
                currentPublicKey =
                    (AccountsPanel.configurationOf server).webPushConfig
                        |> Maybe.map .publicVapidKey
                        |> Maybe.withDefault ""
            in
            div [ class "server-details-facebook-auth" ]
                [ h3 [ class "section-title" ] [ text "Web Push Configuration" ]
                , webPushPublicKeyRow currentPublicKey model.webPushPublicKeyEdit maybeAdminAccount
                , webPushPrivateKeyRow model.webPushPrivateKeyEdit maybeAdminAccount
                ]


webPushPublicKeyRow : String -> Maybe TextFieldEdit -> Maybe AccountsPanel.Account -> Html Msg
webPushPublicKeyRow currentPublicKey maybeEdit maybeAdminAccount =
    case maybeEdit of
        Just edit ->
            div [ class "server-details-color-row server-details-color-row-edit" ]
                [ span [ class "server-details-color-label" ] [ text "Public VAPID Key" ]
                , input
                    [ class "server-details-rename-input"
                    , value edit.pending
                    , onInput WebPushPublicKeyChanged
                    , disabled (edit.status == AccountsPanel.Submitting)
                    ]
                    []
                , Common.editSaveButton WebPushPublicKeySaveClicked edit.status
                , Common.editCancelButton WebPushPublicKeyCancelClicked edit.status
                , Common.editErrorView edit.status
                ]

        Nothing ->
            div [ class "server-details-color-row" ]
                [ span [ class "server-details-color-label" ] [ text "Public VAPID Key" ]
                , span [ class "server-details-color-hex" ]
                    [ text
                        (if String.isEmpty currentPublicKey then
                            "Not set."

                         else
                            currentPublicKey
                        )
                    ]
                , case maybeAdminAccount of
                    Just _ ->
                        button [ class "server-details-rename-button", onClick WebPushPublicKeyEditClicked ] [ text "Edit" ]

                    Nothing ->
                        text ""
                ]


{-| Unlike `webPushPublicKeyRow`, there's no "current value" to show when not editing -- the server
never sends the real `privateVapidKey` back (see `TextFieldEdit`'s doc), so the placeholder below is
shown regardless of whether a key is actually configured. Clicking Edit always starts from a blank
`<input>`; saving it blank is a no-op on the backend, same as leaving a "change password" field
untouched.
-}
webPushPrivateKeyRow : Maybe TextFieldEdit -> Maybe AccountsPanel.Account -> Html Msg
webPushPrivateKeyRow maybeEdit maybeAdminAccount =
    case maybeEdit of
        Just edit ->
            div [ class "server-details-color-row server-details-color-row-edit" ]
                [ span [ class "server-details-color-label" ] [ text "Private VAPID Key" ]
                , input
                    [ Html.Attributes.type_ "password"
                    , class "server-details-rename-input"
                    , placeholder "New Private VAPID Key"
                    , value edit.pending
                    , onInput WebPushPrivateKeyChanged
                    , disabled (edit.status == AccountsPanel.Submitting)
                    ]
                    []
                , Common.editSaveButton WebPushPrivateKeySaveClicked edit.status
                , Common.editCancelButton WebPushPrivateKeyCancelClicked edit.status
                , Common.editErrorView edit.status
                ]

        Nothing ->
            div [ class "server-details-color-row" ]
                [ span [ class "server-details-color-label" ] [ text "Private VAPID Key" ]
                , span [ class "server-details-color-hex" ] [ text "Never shown" ]
                , case maybeAdminAccount of
                    Just _ ->
                        button [ class "server-details-rename-button", onClick WebPushPrivateKeyEditClicked ] [ text "Edit" ]

                    Nothing ->
                        text ""
                ]


federationDisplayView : Shared.Model -> List FederatedServer -> Html Msg
federationDisplayView shared servers =
    if List.isEmpty servers then
        p [] [ text "This server doesn't federate with any other servers." ]

    else
        div [ class "federated-servers-strip" ] (List.map (federatedServerDisplayChip shared) servers)


{-| One federated server, read-only -- host plus (only when set) its two default-federation flags,
renamed for this UI per the module's own convention (`configuredByDefault`/`pinnedByDefault` are how
`AccountsPanel.recommendedFederatedServers`' auto-connect/auto-pin behavior reads them, see that
function's own doc). Styled as one of `UI.serverChip`'s chips (`.server-chip`, `.servers-strip`'s
horizontal-scroll treatment, `.background-color-primary`/`-nav`) rather than introducing a whole new
chip look.
-}
federatedServerDisplayChip : Shared.Model -> FederatedServer -> Html Msg
federatedServerDisplayChip shared federatedServer =
    let
        configuredByDefault : Bool
        configuredByDefault =
            Maybe.withDefault False federatedServer.configuredByDefault

        pinnedByDefault : Bool
        pinnedByDefault =
            Maybe.withDefault False federatedServer.pinnedByDefault
    in
    div [ classes [ "server-chip", "federated-server-chip", hostnameToCSSClass federatedServer.host ] ]
        [ div [ classes [ "server-chip-top", "background-color-primary" ] ]
            [ AccountsPanel.serverNameAndLogo (federatedServerFor shared federatedServer.host) AccountsPanel.RegularServerLogo
            , div [ class "server-chip-host-row" ] [ div [ class "server-chip-host" ] [ text federatedServer.host ] ]
            ]
        , div [ classes [ "server-chip-bottom", "federated-server-flags", "background-color-nav" ] ]
            [ if configuredByDefault then
                span [ class "federated-server-flag-badge" ] [ text "Added by Default" ]

              else
                text ""
            , if pinnedByDefault then
                span [ class "federated-server-flag-badge" ] [ text "Enabled by Default" ]

              else
                text ""
            , if not configuredByDefault && not pinnedByDefault then
                span [ class "federated-server-flag-none" ] [ text "—" ]

              else
                text ""
            ]
        ]


{-| The chip strip (add/remove/reorder-animated via `UI.Flip`, see `FederationEdit`'s own doc), the
"type a host, validate it, add it" row, and the Save/Cancel actions -- everything shown once
`FederationEditClicked` has started an edit.
-}
federationEditorView : Shared.Model -> FederationEdit -> Html Msg
federationEditorView shared edit =
    div [ class "server-details-federation-edit" ]
        [ Html.Keyed.node "div"
            [ classes [ "federated-servers-strip", "flip-animated-row" ] ]
            (List.indexedMap
                (\index federatedServer -> ( federatedServer.host, federatedServerEditChipFlip shared edit (List.length edit.pending) index federatedServer ))
                edit.pending
            )
        , div [ class "server-details-federation-add" ]
            [ input
                [ class "server-details-federation-add-input"
                , value edit.hostInput
                , onInput FederatedServerHostInputChanged
                , placeholder "example.com"
                , disabled (edit.addStatus == AccountsPanel.Submitting)
                ]
                []
            , button
                [ class "server-details-rename-button"
                , onClick FederatedServerAddClicked
                , disabled (String.isEmpty (String.trim edit.hostInput) || edit.addStatus == AccountsPanel.Submitting)
                ]
                [ text
                    (if edit.addStatus == AccountsPanel.Submitting then
                        "Checking…"

                     else
                        "Add Server"
                    )
                ]
            , Common.editErrorView edit.addStatus
            ]
        , div [ class "server-details-permissions-actions" ]
            [ Common.editSaveButton FederationSaveClicked edit.status
            , Common.editCancelButton FederationCancelClicked edit.status
            ]
        , Common.editErrorView edit.status
        ]


{-| Wraps `federatedServerEditChip` in a fading/scaling/collapsing animated outer `div` (entering
when freshly added via `FederatedServerAddClicked`, removing when `FederatedServerRemoveClicked`) --
the edit-mode counterpart of `UI.serverChipFlip`, whose doc covers the two-layer reasoning
(fade/collapse here vs. the chip's own, independent reorder-slide) in full.
-}
federatedServerEditChipFlip : Shared.Model -> FederationEdit -> Int -> Int -> FederatedServer -> Html Msg
federatedServerEditChipFlip shared edit count index federatedServer =
    let
        flipState : UI.Flip.State Msg
        flipState =
            Dict.get federatedServer.host edit.itemAnimations |> Maybe.withDefault UI.Flip.restingState

        isMoving : Bool
        isMoving =
            Dict.get federatedServer.host edit.moveAnimations |> Maybe.map .moving |> Maybe.withDefault False

        pointerEventsAttr : List (Html.Attribute Msg)
        pointerEventsAttr =
            if flipState.removing then
                [ Html.Attributes.style "pointer-events" "none" ]

            else
                []
    in
    div (UI.Flip.itemAttributes UI.Flip.Horizontal flipState isMoving)
        [ div pointerEventsAttr [ federatedServerEditChip shared edit count index federatedServer ] ]


{-| One federated server's editor chip: left/right reorder arrows flanking the host (mirrors
`UI.serverChip`'s own, `stopPropagationOn` for the same reason -- see
`UI.Flip.reorderButtonPair`'s doc), the two default-federation flags as toggle switches (always
starting off for a freshly-added server, see `GotFederatedServerAddResult`), and a remove button.
-}
federatedServerEditChip : Shared.Model -> FederationEdit -> Int -> Int -> FederatedServer -> Html Msg
federatedServerEditChip shared edit count index federatedServer =
    let
        host : String
        host =
            federatedServer.host

        moveAttrs : List (Html.Attribute Msg)
        moveAttrs =
            edit.moveAnimations |> Dict.get host |> Maybe.map UI.Flip.moveAttributes |> Maybe.withDefault []

        stopClick : Msg -> Html.Attribute Msg
        stopClick msg =
            stopPropagationOn "click" (Decode.succeed ( msg, True ))

        showBackward : Bool
        showBackward =
            index > 0

        showForward : Bool
        showForward =
            index < count - 1

        reorderPair : { backward : Html Msg, forward : Html Msg }
        reorderPair =
            UI.Flip.reorderButtonPair UI.Flip.Horizontal
                { moveBackward = stopClick (MoveFederatedServerLeftClicked host)
                , moveForward = stopClick (MoveFederatedServerRightClicked host)
                , canMoveBackward = showBackward
                , canMoveForward = showForward
                }
    in
    div
        (id (federatedServerChipDomId host)
            :: classes [ "server-chip", "federated-server-chip", "federated-server-chip-edit", hostnameToCSSClass host ]
            :: moveAttrs
        )
        [ div [ classes [ "server-chip-top", "background-color-primary" ] ]
            [ div [ class "server-chip-logo-row" ]
                [ div [ Html.Attributes.classList [ ( "reorder-arrow", True ), ( "reorder-arrow-hidden", not showBackward ) ] ] [ reorderPair.backward ]
                , AccountsPanel.serverNameAndLogo (federatedServerFor shared host) AccountsPanel.RegularServerLogo
                , div [ Html.Attributes.classList [ ( "reorder-arrow", True ), ( "reorder-arrow-hidden", not showForward ) ] ] [ reorderPair.forward ]
                ]
            , div [ class "server-chip-host-row" ] [ div [ class "server-chip-host" ] [ text host ] ]
            ]
        , div [ classes [ "server-chip-bottom", "federated-server-flags-edit", "background-color-nav" ] ]
            [ federatedServerFlagToggle "Added by Default" (Maybe.withDefault False federatedServer.configuredByDefault) (FederatedServerConfiguredByDefaultToggled host)
            , federatedServerFlagToggle "Enabled by Default" (Maybe.withDefault False federatedServer.pinnedByDefault) (FederatedServerPinnedByDefaultToggled host)
            , div [ class "federated-server-chip-remove" ]
                [ button
                    [ class "remove-btn"
                    , onClick (FederatedServerRemoveClicked host)
                    , title ("Remove " ++ host)
                    ]
                    [ text "╳" ]
                ]
            ]
        ]


federatedServerFlagToggle : String -> Bool -> Msg -> Html Msg
federatedServerFlagToggle label_ isChecked toggleMsg =
    div [ class "federated-server-flag-toggle" ]
        [ span [ class "federated-server-flag-toggle-label" ] [ text label_ ]
        , Common.flagSwitch isChecked toggleMsg
        ]
