module Components.Pages.ServerInformationPage.IntegrationsTab exposing (Model, Msg, init, update, view)

{-| The Integrations tab of `Components.Pages.ServerInformationPage` -- Twilio (`TwilioConfig`) and
Bird (`BirdConfig`, see that message's own doc in `server_configuration.proto` -- a cheaper Twilio
alternative for SMS verification), each editable by an admin as its own unit (a single
Edit/Save/Cancel per provider, mirroring `CdnTab` -- the simplest existing tab, no async "activate on
select" dance like `ClusterTab` needs), plus a "Preferred Verification Providers" selector choosing
which provider is tried first when both are enabled (`preferredVerificationApis`).

Unlike `CdnTab`'s "External CDN HTTP Support" toggle (which nulls `externalCdnConfig` out entirely
when off), each provider's "Enabled" toggle here only ever flips its own `*Enabled` field -- the
rest of the config (account identifiers, and whatever's currently stored for the write-only secret)
is left alone on disable, so re-enabling later doesn't lose the credentials that were already
entered. `twilioApiKey`/`birdAccessKey` are write-only secrets -- `GetServerConfiguration` always
blanks them (mirroring `WebPushConfig.privateVapidKey`), so `*EditClicked` naturally seeds the
secret field blank with no special-casing, and each input's placeholder makes clear that leaving it
blank on Save keeps whatever's already stored.

The non-secret fields (`twilioAccountSid`/`twilioFromNumber`/`birdFrom`/`birdRegion`) aren't secret
among admins (just not shown to non-admins, since `twilioConfig`/`bird_config` are themselves
admin-only-serialized -- see `ServerInformationPage`'s tab bar gating), so they're shown in plain
text even in the read-only display view, same as CDN's `frontendHost`/`backendHost`.

The Preferred Providers selector mirrors `SettingsTab`'s Permissions editor (removable badges + an
Add `<select>` + Save/Cancel) -- with only two possible values, "reordering" just means
remove-then-re-add at the end, same as that editor offers no drag-and-drop either.
-}

import Components.Pages.ServerInformationPage.Common as Common
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, button, div, h3, input, option, select, span, text)
import Html.Attributes exposing (class, disabled, placeholder, selected, type_, value)
import Html.Events exposing (onClick, onInput)
import Proto.Rellm exposing (BirdConfig, ServerConfiguration, TwilioConfig, defaultBirdConfig, defaultTwilioConfig)
import Proto.Rellm.VerificationAPI exposing (VerificationAPI(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.AccountsPanel.RellmAccounts exposing (RellmAccount)
import Shared.AccountsPanel.RellmServers as RellmServers exposing (RellmServer)
import Task



-- MODEL


type alias Model =
    { configEdit : Maybe TwilioConfigEdit
    , birdConfigEdit : Maybe BirdConfigEdit
    , preferredProvidersEdit : Maybe PreferredProvidersEdit
    }


type Msg
    = TwilioEditClicked
    | TwilioEnabledToggled
    | TwilioAccountSidChanged String
    | TwilioAuthTokenChanged String
    | TwilioFromNumberChanged String
    | TwilioCancelClicked
    | TwilioSaveClicked
    | GotTwilioSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))
    | BirdEditClicked
    | BirdEnabledToggled
    | BirdAccessKeyChanged String
    | BirdFromChanged String
    | BirdRegionChanged String
    | BirdCancelClicked
    | BirdSaveClicked
    | GotBirdSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))
    | PreferredProvidersEditClicked
    | PreferredProviderRemoveClicked VerificationAPI
    | PreferredProviderAddSelectionChanged String
    | PreferredProviderAddClicked
    | PreferredProvidersCancelClicked
    | PreferredProvidersSaveClicked
    | GotPreferredProvidersSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))


{-| Live only while the Twilio config is being edited by an admin. `authToken` always starts blank
(see module doc) -- leaving it blank on Save means "keep whatever's already stored" (the backend
splices the existing value back in when the incoming `twilio_api_key` is empty, mirroring
`WebPushConfig.privateVapidKey`'s own merge rule).
-}
type alias TwilioConfigEdit =
    { enabled : Bool
    , accountSid : String
    , authToken : String
    , fromNumber : String
    , status : AccountsPanel.FormStatus
    }


{-| Same as `TwilioConfigEdit`, but for Bird -- `accessKey` always starts blank the same way
`authToken` does.
-}
type alias BirdConfigEdit =
    { enabled : Bool
    , accessKey : String
    , from : String
    , region : String
    , status : AccountsPanel.FormStatus
    }


{-| Live only while `preferredVerificationApis` is being edited by an admin -- mirrors
`SettingsTab.PermissionsEdit` exactly, just over `VerificationAPI` instead of `Permission`.
`pending`'s order IS the preference order (see module doc).
-}
type alias PreferredProvidersEdit =
    { pending : List VerificationAPI
    , addSelection : Maybe VerificationAPI
    , status : AccountsPanel.FormStatus
    }


init : Model
init =
    { configEdit = Nothing
    , birdConfigEdit = Nothing
    , preferredProvidersEdit = Nothing
    }



-- UPDATE


update : Shared.Model -> String -> Maybe RellmServer -> Msg -> Model -> ( Model, Effect Msg )
update shared targetHost maybeServer msg model =
    case msg of
        TwilioEditClicked ->
            case maybeServer of
                Just server ->
                    let
                        twilioConfig : Maybe TwilioConfig
                        twilioConfig =
                            (RellmServers.configurationOf server).twilioConfig
                    in
                    ( { model
                        | configEdit =
                            Just
                                { enabled = twilioConfig |> Maybe.map .twilioEnabled |> Maybe.withDefault False
                                , accountSid = twilioConfig |> Maybe.map .twilioAccountSid |> Maybe.withDefault ""
                                , authToken = ""
                                , fromNumber = twilioConfig |> Maybe.map .twilioFromNumber |> Maybe.withDefault ""
                                , status = AccountsPanel.Idle
                                }
                      }
                    , Effect.none
                    )

                Nothing ->
                    ( model, Effect.none )

        TwilioEnabledToggled ->
            ( { model | configEdit = model.configEdit |> Maybe.map (\edit -> { edit | enabled = not edit.enabled }) }, Effect.none )

        TwilioAccountSidChanged text ->
            ( { model | configEdit = model.configEdit |> Maybe.map (\edit -> { edit | accountSid = text }) }, Effect.none )

        TwilioAuthTokenChanged text ->
            ( { model | configEdit = model.configEdit |> Maybe.map (\edit -> { edit | authToken = text }) }, Effect.none )

        TwilioFromNumberChanged text ->
            ( { model | configEdit = model.configEdit |> Maybe.map (\edit -> { edit | fromNumber = text }) }, Effect.none )

        TwilioCancelClicked ->
            ( { model | configEdit = Nothing }, Effect.none )

        TwilioSaveClicked ->
            case ( model.configEdit, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( { model | configEdit = Just { edit | status = AccountsPanel.Submitting } }
                    , AccountsPanel.updateServerConfig shared.accounts ( Just account.userId, targetHost ) (applyTwilioConfig edit)
                        |> Task.attempt GotTwilioSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotTwilioSaveResult (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( { model | configEdit = Nothing }
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotTwilioSaveResult (Err err) ->
            ( { model | configEdit = model.configEdit |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )

        BirdEditClicked ->
            case maybeServer of
                Just server ->
                    let
                        birdConfig : Maybe BirdConfig
                        birdConfig =
                            (RellmServers.configurationOf server).birdConfig
                    in
                    ( { model
                        | birdConfigEdit =
                            Just
                                { enabled = birdConfig |> Maybe.map .birdEnabled |> Maybe.withDefault False
                                , accessKey = ""
                                , from = birdConfig |> Maybe.map .birdFrom |> Maybe.withDefault ""
                                , region = birdConfig |> Maybe.map .birdRegion |> Maybe.withDefault ""
                                , status = AccountsPanel.Idle
                                }
                      }
                    , Effect.none
                    )

                Nothing ->
                    ( model, Effect.none )

        BirdEnabledToggled ->
            ( { model | birdConfigEdit = model.birdConfigEdit |> Maybe.map (\edit -> { edit | enabled = not edit.enabled }) }, Effect.none )

        BirdAccessKeyChanged text ->
            ( { model | birdConfigEdit = model.birdConfigEdit |> Maybe.map (\edit -> { edit | accessKey = text }) }, Effect.none )

        BirdFromChanged text ->
            ( { model | birdConfigEdit = model.birdConfigEdit |> Maybe.map (\edit -> { edit | from = text }) }, Effect.none )

        BirdRegionChanged text ->
            ( { model | birdConfigEdit = model.birdConfigEdit |> Maybe.map (\edit -> { edit | region = text }) }, Effect.none )

        BirdCancelClicked ->
            ( { model | birdConfigEdit = Nothing }, Effect.none )

        BirdSaveClicked ->
            case ( model.birdConfigEdit, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( { model | birdConfigEdit = Just { edit | status = AccountsPanel.Submitting } }
                    , AccountsPanel.updateServerConfig shared.accounts ( Just account.userId, targetHost ) (applyBirdConfig edit)
                        |> Task.attempt GotBirdSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotBirdSaveResult (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( { model | birdConfigEdit = Nothing }
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotBirdSaveResult (Err err) ->
            ( { model | birdConfigEdit = model.birdConfigEdit |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )

        PreferredProvidersEditClicked ->
            case maybeServer of
                Just server ->
                    let
                        current : List VerificationAPI
                        current =
                            (RellmServers.configurationOf server).preferredVerificationApis
                    in
                    ( { model | preferredProvidersEdit = Just { pending = current, addSelection = resolveAddSelection Nothing current, status = AccountsPanel.Idle } }
                    , Effect.none
                    )

                Nothing ->
                    ( model, Effect.none )

        PreferredProviderRemoveClicked provider ->
            ( { model
                | preferredProvidersEdit =
                    model.preferredProvidersEdit
                        |> Maybe.map
                            (\edit ->
                                let
                                    pending : List VerificationAPI
                                    pending =
                                        List.filter ((/=) provider) edit.pending
                                in
                                { edit | pending = pending, addSelection = resolveAddSelection edit.addSelection pending }
                            )
              }
            , Effect.none
            )

        PreferredProviderAddSelectionChanged text ->
            ( { model | preferredProvidersEdit = model.preferredProvidersEdit |> Maybe.map (\edit -> { edit | addSelection = verificationApiFromText text }) }
            , Effect.none
            )

        PreferredProviderAddClicked ->
            ( { model
                | preferredProvidersEdit =
                    model.preferredProvidersEdit
                        |> Maybe.map
                            (\edit ->
                                case edit.addSelection of
                                    Just provider ->
                                        let
                                            pending : List VerificationAPI
                                            pending =
                                                edit.pending ++ [ provider ]
                                        in
                                        { edit | pending = pending, addSelection = resolveAddSelection Nothing pending }

                                    Nothing ->
                                        edit
                            )
              }
            , Effect.none
            )

        PreferredProvidersCancelClicked ->
            ( { model | preferredProvidersEdit = Nothing }, Effect.none )

        PreferredProvidersSaveClicked ->
            case ( model.preferredProvidersEdit, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( { model | preferredProvidersEdit = Just { edit | status = AccountsPanel.Submitting } }
                    , AccountsPanel.updateServerConfig shared.accounts
                        ( Just account.userId, targetHost )
                        (\config -> { config | preferredVerificationApis = edit.pending })
                        |> Task.attempt GotPreferredProvidersSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotPreferredProvidersSaveResult (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( { model | preferredProvidersEdit = Nothing }
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotPreferredProvidersSaveResult (Err err) ->
            ( { model | preferredProvidersEdit = model.preferredProvidersEdit |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )


{-| `TwilioSaveClicked`'s transform, passed to `AccountsPanel.updateServerConfig` the same way every
other editor's transform is. Unlike `CdnTab.applyCdnConfig` (which nulls `externalCdnConfig` out
entirely when its toggle is off), this never nulls `twilioConfig` out -- `twilioEnabled` is itself
the field that means "off," so disabling just flips that bool while `accountSid`/`fromNumber` (and
whatever's stored for `authToken`, left untouched when `edit.authToken` is blank) stay put, letting
an admin flip Twilio off and back on without re-entering credentials.
-}
applyTwilioConfig : TwilioConfigEdit -> ServerConfiguration -> ServerConfiguration
applyTwilioConfig edit config =
    let
        existing : TwilioConfig
        existing =
            Maybe.withDefault defaultTwilioConfig config.twilioConfig
    in
    { config
        | twilioConfig =
            Just
                { existing
                    | twilioEnabled = edit.enabled
                    , twilioAccountSid = edit.accountSid
                    , twilioApiKey = edit.authToken
                    , twilioFromNumber = edit.fromNumber
                }
    }


{-| Same as `applyTwilioConfig`, but for Bird.
-}
applyBirdConfig : BirdConfigEdit -> ServerConfiguration -> ServerConfiguration
applyBirdConfig edit config =
    let
        existing : BirdConfig
        existing =
            Maybe.withDefault defaultBirdConfig config.birdConfig
    in
    { config
        | birdConfig =
            Just
                { existing
                    | birdEnabled = edit.enabled
                    , birdAccessKey = edit.accessKey
                    , birdFrom = edit.from
                    , birdRegion = edit.region
                }
    }


{-| Every `VerificationAPI` value, in a fixed display order -- used both for the Add dropdown's
full option list and (indirectly, via `addablePreferredProviders`) for what's left to add.
-}
allVerificationApis : List VerificationAPI
allVerificationApis =
    [ VERIFICATIONAPITWILIO, VERIFICATIONAPIBIRD ]


addablePreferredProviders : List VerificationAPI -> List VerificationAPI
addablePreferredProviders pending =
    List.filter (\api -> not (List.member api pending)) allVerificationApis


{-| The first still-addable provider, preferring to keep `current` selected if it's still
addable -- mirrors `SettingsTab.resolveAddSelection` exactly.
-}
resolveAddSelection : Maybe VerificationAPI -> List VerificationAPI -> Maybe VerificationAPI
resolveAddSelection current pending =
    let
        addable : List VerificationAPI
        addable =
            addablePreferredProviders pending
    in
    case current of
        Just api ->
            if List.member api addable then
                Just api

            else
                List.head addable

        Nothing ->
            List.head addable


verificationApiText : VerificationAPI -> String
verificationApiText api =
    case api of
        VERIFICATIONAPITWILIO ->
            "Twilio"

        VERIFICATIONAPIBIRD ->
            "Bird"

        VerificationAPIUnrecognized_ _ ->
            "Unknown"


verificationApiFromText : String -> Maybe VerificationAPI
verificationApiFromText text_ =
    allVerificationApis |> List.filter (\api -> verificationApiText api == text_) |> List.head



-- VIEW


view : RellmServer -> Maybe RellmAccount -> Model -> Html Msg
view server maybeAdminAccount model =
    let
        config : ServerConfiguration
        config =
            RellmServers.configurationOf server
    in
    div [ class "server-details-tab-content server-details-integrations" ]
        [ div []
            (case model.configEdit of
                Just edit ->
                    twilioEditView edit

                Nothing ->
                    twilioDisplayView maybeAdminAccount config.twilioConfig
            )
        , div []
            (case model.birdConfigEdit of
                Just edit ->
                    birdEditView edit

                Nothing ->
                    birdDisplayView maybeAdminAccount config.birdConfig
            )
        , preferredProvidersSection maybeAdminAccount model.preferredProvidersEdit config.preferredVerificationApis
        ]


twilioDisplayView : Maybe RellmAccount -> Maybe TwilioConfig -> List (Html Msg)
twilioDisplayView maybeAdminAccount twilioConfig =
    [ h3 [ class "section-title" ] [ text "Twilio" ]
    , Common.settingsRow "Twilio Enabled" (Common.switchDisplay (twilioConfig |> Maybe.map .twilioEnabled |> Maybe.withDefault False))
    , Common.settingsRow "Account SID" (span [ class "server-details-feature-settings-value" ] [ text (twilioConfig |> Maybe.map .twilioAccountSid |> Maybe.withDefault "—") ])
    , Common.settingsRow "From Number" (span [ class "server-details-feature-settings-value" ] [ text (twilioConfig |> Maybe.map .twilioFromNumber |> Maybe.withDefault "—") ])
    , case maybeAdminAccount of
        Just _ ->
            button [ class "server-details-rename-button", onClick TwilioEditClicked ] [ text "Edit Twilio Settings" ]

        Nothing ->
            text ""
    ]


twilioEditView : TwilioConfigEdit -> List (Html Msg)
twilioEditView edit =
    [ h3 [ class "section-title" ] [ text "Twilio" ]
    , Common.settingsRow "Twilio Enabled" (Common.flagSwitch edit.enabled TwilioEnabledToggled)
    , Common.settingsRow "Account SID"
        (input
            [ class "server-details-rename-input"
            , placeholder "ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            , value edit.accountSid
            , onInput TwilioAccountSidChanged
            , disabled (edit.status == AccountsPanel.Submitting)
            ]
            []
        )
    , Common.settingsRow "Auth Token"
        (input
            [ type_ "password"
            , class "server-details-rename-input"
            , placeholder "Enter to change"
            , value edit.authToken
            , onInput TwilioAuthTokenChanged
            , disabled (edit.status == AccountsPanel.Submitting)
            ]
            []
        )
    , Common.settingsRow "From Number"
        (input
            [ class "server-details-rename-input"
            , placeholder "+15555550100"
            , value edit.fromNumber
            , onInput TwilioFromNumberChanged
            , disabled (edit.status == AccountsPanel.Submitting)
            ]
            []
        )
    , div [ class "server-details-feature-settings-actions" ]
        [ Common.editSaveButton TwilioSaveClicked edit.status
        , Common.editCancelButton TwilioCancelClicked edit.status
        ]
    , Common.editErrorView edit.status
    ]


birdDisplayView : Maybe RellmAccount -> Maybe BirdConfig -> List (Html Msg)
birdDisplayView maybeAdminAccount birdConfig =
    [ h3 [ class "section-title" ] [ text "Bird" ]
    , Common.settingsRow "Bird Enabled" (Common.switchDisplay (birdConfig |> Maybe.map .birdEnabled |> Maybe.withDefault False))
    , Common.settingsRow "From" (span [ class "server-details-feature-settings-value" ] [ text (birdConfig |> Maybe.map .birdFrom |> Maybe.withDefault "—") ])
    , Common.settingsRow "Region" (span [ class "server-details-feature-settings-value" ] [ text (birdConfig |> Maybe.map .birdRegion |> Maybe.andThen emptyToNothing |> Maybe.withDefault "us1 (default)") ])
    , case maybeAdminAccount of
        Just _ ->
            button [ class "server-details-rename-button", onClick BirdEditClicked ] [ text "Edit Bird Settings" ]

        Nothing ->
            text ""
    ]


birdEditView : BirdConfigEdit -> List (Html Msg)
birdEditView edit =
    [ h3 [ class "section-title" ] [ text "Bird" ]
    , Common.settingsRow "Bird Enabled" (Common.flagSwitch edit.enabled BirdEnabledToggled)
    , Common.settingsRow "Access Key"
        (input
            [ type_ "password"
            , class "server-details-rename-input"
            , placeholder "Enter to change"
            , value edit.accessKey
            , onInput BirdAccessKeyChanged
            , disabled (edit.status == AccountsPanel.Submitting)
            ]
            []
        )
    , Common.settingsRow "From"
        (input
            [ class "server-details-rename-input"
            , placeholder "Bird (or an owned number/short code)"
            , value edit.from
            , onInput BirdFromChanged
            , disabled (edit.status == AccountsPanel.Submitting)
            ]
            []
        )
    , Common.settingsRow "Region"
        (input
            [ class "server-details-rename-input"
            , placeholder "us1"
            , value edit.region
            , onInput BirdRegionChanged
            , disabled (edit.status == AccountsPanel.Submitting)
            ]
            []
        )
    , div [ class "server-details-feature-settings-actions" ]
        [ Common.editSaveButton BirdSaveClicked edit.status
        , Common.editCancelButton BirdCancelClicked edit.status
        ]
    , Common.editErrorView edit.status
    ]


emptyToNothing : String -> Maybe String
emptyToNothing str =
    if String.isEmpty str then
        Nothing

    else
        Just str


{-| The "Preferred Verification Providers" selector -- plain badges (plus an Edit button, for an
admin) when not being edited, or the removable-badges + Add Provider + Save/Cancel editor while
being edited. Mirrors `SettingsTab.permissionsSection` exactly (see module doc).
-}
preferredProvidersSection : Maybe RellmAccount -> Maybe PreferredProvidersEdit -> List VerificationAPI -> Html Msg
preferredProvidersSection maybeAdminAccount maybeEdit preferred =
    case maybeEdit of
        Just edit ->
            div [ class "server-details-permissions server-details-permissions-edit" ]
                [ h3 [ class "section-title" ] [ text "Preferred Verification Providers" ]
                , div [ class "permission-badges" ] (edit.pending |> List.map preferredProviderEditBadge)
                , div [ class "server-details-permissions-add" ]
                    [ select [ onInput PreferredProviderAddSelectionChanged ]
                        (addablePreferredProviders edit.pending
                            |> List.map
                                (\api ->
                                    option
                                        [ value (verificationApiText api)
                                        , selected (edit.addSelection == Just api)
                                        ]
                                        [ text (verificationApiText api) ]
                                )
                        )
                    , button
                        [ class "server-details-rename-button"
                        , onClick PreferredProviderAddClicked
                        , disabled (edit.addSelection == Nothing || edit.status == AccountsPanel.Submitting)
                        ]
                        [ text "Add Provider" ]
                    ]
                , div [ class "server-details-permissions-actions" ]
                    [ Common.editSaveButton PreferredProvidersSaveClicked edit.status
                    , Common.editCancelButton PreferredProvidersCancelClicked edit.status
                    ]
                , Common.editErrorView edit.status
                ]

        Nothing ->
            div [ class "server-details-permissions" ]
                [ h3 [ class "section-title" ] [ text "Preferred Verification Providers" ]
                , if List.isEmpty preferred then
                    Html.p [] [ text "None set -- falls back to whichever provider is enabled (Twilio first, then Bird)." ]

                  else
                    div [ class "permission-badges" ]
                        (preferred |> List.map (\api -> span [ class "permission-badge" ] [ text (verificationApiText api) ]))
                , case maybeAdminAccount of
                    Just _ ->
                        button [ class "server-details-rename-button", onClick PreferredProvidersEditClicked ] [ text "Edit Preferred Providers" ]

                    Nothing ->
                        text ""
                ]


preferredProviderEditBadge : VerificationAPI -> Html Msg
preferredProviderEditBadge api =
    span [ class "permission-badge editable" ]
        [ text (verificationApiText api)
        , button
            [ class "permission-remove"
            , onClick (PreferredProviderRemoveClicked api)
            , Html.Attributes.title ("Remove " ++ verificationApiText api)
            ]
            [ text "×" ]
        ]
