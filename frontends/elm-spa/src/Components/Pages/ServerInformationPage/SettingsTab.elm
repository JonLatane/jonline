module Components.Pages.ServerInformationPage.SettingsTab exposing (Model, Msg, applySharedMsg, init, subscriptions, update, view)

{-| The Settings tab of `Components.Pages.ServerInformationPage` -- the three server-wide grantable
permission sets (Anonymous/Default/Basic User Permissions, `permissionsSection`, one per
`ServerPermissionsSet`) and the five per-feature settings sections (People/Groups/Posts/Events/
Media, `featureSettingsSection`, one per `FeatureSettingsSet`). Both mirror
`Components.Pages.UserProfilePage`'s own Permissions editor, just reading/writing a
`ServerConfiguration` (via `AccountsPanel.updateServerConfig`, the shared "fetch fresh copy, then
write" RPC helper) instead of a `User`'s `permissions`.
-}

import Animation
import Browser.Dom as Dom
import Components.Pages.ServerInformationPage.Common as Common
import Components.Posts as Posts
import Components.Users as Users
import Dict exposing (Dict)
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, button, div, h3, input, option, p, select, span, text)
import Html.Attributes exposing (disabled, id, placeholder, selected, value)
import Html.Events exposing (onClick, onInput)
import Html.Keyed
import Proto.Jonline exposing (ServerConfiguration, defaultCustomNavigationTabSet, defaultEventSettings, defaultFeatureSettings, defaultMediaSettings, defaultPostSettings)
import Proto.Jonline.CalendarDisplayMode exposing (CalendarDisplayMode(..))
import Proto.Jonline.Moderation exposing (Moderation(..))
import Proto.Jonline.NavigationTab exposing (NavigationTab(..))
import Proto.Jonline.Permission exposing (Permission)
import Proto.Jonline.Visibility exposing (Visibility(..))
import Set exposing (Set)
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.MyMediaPanel as MyMediaPanel
import Task
import UI.Classes exposing (classes, hostnameToCSSClass)
import UI.CustomNav as CustomNav
import UI.Flip



-- MODEL


type alias Model =
    { anonymousPermissionsEdit : Maybe PermissionsEdit
    , defaultPermissionsEdit : Maybe PermissionsEdit
    , basicPermissionsEdit : Maybe PermissionsEdit
    , customTabsEdit : Maybe CustomTabsEdit
    , peopleSettingsEdit : Maybe FeatureSettingsEdit
    , groupSettingsEdit : Maybe FeatureSettingsEdit
    , postSettingsEdit : Maybe FeatureSettingsEdit
    , eventSettingsEdit : Maybe FeatureSettingsEdit
    , mediaSettingsEdit : Maybe FeatureSettingsEdit
    , collapsedFeatureSettings : Set String
    }


type Msg
    = PermissionsEditClicked ServerPermissionsSet
    | PermissionRemoveClicked ServerPermissionsSet Permission
    | PermissionAddSelectionChanged ServerPermissionsSet String
    | PermissionAddClicked ServerPermissionsSet
    | PermissionsCancelClicked ServerPermissionsSet
    | PermissionsSaveClicked ServerPermissionsSet
    | GotPermissionsSaveResult ServerPermissionsSet (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))
    | CustomTabsEditClicked
    | CustomTabsCancelClicked
    | CustomTabsSaveClicked
    | GotCustomTabsSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))
    | CustomTabAddClicked
    | CustomTabRemoveClicked String
    | CustomTabRemoved String
    | CustomTabTargetKindChanged String String
    | CustomTabPostIdChanged String String
    | CustomTabTitleChanged String String
    | CustomTabPathChanged String String
    | CustomTabEmojiChanged String String
    | CustomTabChooseImageClicked String
    | CustomTabRemoveImageClicked String
    | MoveCustomTabLeftClicked String
    | MoveCustomTabRightClicked String
    | GotPreMoveCustomTabPositions String String Int (Result Dom.Error ( Dom.Element, Dom.Element ))
    | CustomTabMoveSettled String
    | AnimateCustomTabFlip Animation.Msg
    | AnimateCustomTabMove Animation.Msg
    | FeatureSettingsSectionToggled FeatureSettingsSet
    | FeatureSettingsEditClicked FeatureSettingsSet
    | FeatureSettingsVisibleToggled FeatureSettingsSet
    | FeatureSettingsModerationChanged FeatureSettingsSet String
    | FeatureSettingsVisibilityChanged FeatureSettingsSet String
    | FeatureSettingsAliasSingularChanged FeatureSettingsSet String
    | FeatureSettingsAliasPluralChanged FeatureSettingsSet String
    | FeatureSettingsEnableRepliesToggled FeatureSettingsSet
    | FeatureSettingsCalendarLookbackDaysChanged FeatureSettingsSet String
    | FeatureSettingsCalendarDisplayModeChanged FeatureSettingsSet String
    | FeatureSettingsCancelClicked FeatureSettingsSet
    | FeatureSettingsSaveClicked FeatureSettingsSet
    | GotFeatureSettingsSaveResult FeatureSettingsSet (Result Grpc.Error ( Maybe AccountsPanel.Msg, ServerConfiguration ))


{-| Which of `ServerConfiguration`'s three grantable-permission-list fields a
`permissionsSection`/`PermissionsEdit` is for -- lets `view` reuse the exact same editing machinery
for all three (Anonymous/Default/Basic) rather than tripling it, the way
`Components.Pages.UserProfilePage` doesn't need to since it only ever edits one user's own
`permissions`.
-}
type ServerPermissionsSet
    = AnonymousPermissions
    | DefaultPermissions
    | BasicPermissions


{-| Live only while one of the three server-wide permission sets (see `ServerPermissionsSet`) is
being edited by an admin -- `pending` is the in-progress set, `addSelection` is whatever the "Add
Permission" `<select>` currently has chosen (always one of `Components.Users.configurableServerPermissions`
not already in `pending`, see `resolveAddSelection`).
-}
type alias PermissionsEdit =
    { pending : List Permission
    , addSelection : Maybe Permission
    , status : AccountsPanel.FormStatus
    }


{-| Live only while `ServerConfiguration.customTabs`' `tabs` list (see `UI.CustomNav.effectiveTabs`)
is being edited by an admin -- mirrors `FederationTab.FederationEdit` almost exactly (same
`pending`/FLIP-animation shape, over `CustomTabEntry` instead of `FederatedServer`), just with two
extras: `nextEntryId` (a monotonic counter minting each entry's own `entryId` -- unlike a
`FederatedServer`'s naturally-unique `host`, nothing about a tab is guaranteed unique up front, so
entries need a synthetic key for `UI.Flip`'s animation `Dict`s/DOM ids/list identity) and
`editingIconFor` (which entry's icon `Shared.MyMediaPanel` is currently picking for, if any -- see
`applySharedMsg`, mirroring `ThemeTab.LogoEdit`'s own `Shared.MyMediaPanel` integration).

The `home` slot is deliberately not part of this edit at all (see this module's own doc on the
"leave Home uneditable for now" scope decision) -- `pending` only ever holds `tabs`, not `home`.

-}
type alias CustomTabsEdit =
    { pending : List CustomTabEntry
    , nextEntryId : Int
    , editingIconFor : Maybe String
    , status : AccountsPanel.FormStatus
    , itemAnimations : Dict String (UI.Flip.State Msg)
    , moveAnimations : Dict String (UI.Flip.MoveState Msg)
    }


{-| One in-progress tab in a `CustomTabsEdit.pending` -- `target`/`icon`/`path` mirror
`UI.CustomNav.CustomTab`'s own fields exactly (this _is_ a `CustomTab`, plus `entryId`); `title` is
the raw `<input>` text (empty means "unset," same `optionalString` convention as
`FeatureSettingsEdit.aliasSingular`) rather than `CustomTab`'s own `Maybe String`. `path` is a plain
`<input>` too (see `customTabEditChip`'s own Path row) -- the backend's `validate_configuration`
rejects anything that isn't `[a-z_]+` on save, surfaced the same way any other server-side rejection
is (`Common.editErrorView`), rather than duplicating that regex client-side.
-}
type alias CustomTabEntry =
    { entryId : String
    , target : CustomNav.CustomTabTarget
    , icon : CustomNav.CustomTabIcon
    , title : String
    , path : String
    }


{-| Which of `ServerConfiguration`'s five per-feature settings a `featureSettingsSection`/
`FeatureSettingsEdit` is for -- lets `view` reuse the same editing machinery for
People/Groups/Posts/Events/Media, the same way `ServerPermissionsSet` does for the three
permission lists. `PostFeatureSettings`/`EventFeatureSettings` back `ServerConfiguration`'s
`PostSettings`/`EventSettings` fields (which also carry `enableReplies`, left untouched by this
editor -- see `applyFeatureSettingsFor`); the other three all back a plain `FeatureSettings`/
`MediaSettings`.
-}
type FeatureSettingsSet
    = PeopleFeatureSettings
    | GroupFeatureSettings
    | PostFeatureSettings
    | EventFeatureSettings
    | MediaFeatureSettings


{-| Live only while one of the five per-feature settings (see `FeatureSettingsSet`) is being
edited by an admin -- mirrors `PermissionsEdit`, just over `FeatureSettings`/`PostSettings`/
`EventSettings`/`MediaSettings`'s shared fields. Not every field applies to every
`FeatureSettingsSet` (`MediaSettings` has no alias, People/Groups have no `enableReplies`, only
Events have a calendar lookback/display mode -- see `featureSettingsFieldsFor`, which gates which
rows `featureSettingsDisplayView`/`featureSettingsEditView` show), so this carries all of them
regardless of `set` and `applyFeatureSettingsFor` only writes back the ones the real proto type
underneath actually has. `aliasSingular`/`aliasPlural`/`calendarLookbackDays` are the raw pending
`<input>` text (empty means "unset" -- see `optionalString`/`optionalNonNegativeInt`), not the
`Maybe String`/`Maybe Int` the proto itself uses.
-}
type alias FeatureSettingsEdit =
    { visible : Bool
    , moderation : Moderation
    , visibility : Visibility
    , aliasSingular : String
    , aliasPlural : String
    , enableReplies : Bool
    , calendarLookbackDays : String
    , calendarDisplayMode : CalendarDisplayMode
    , status : AccountsPanel.FormStatus
    }


init : Model
init =
    { anonymousPermissionsEdit = Nothing
    , defaultPermissionsEdit = Nothing
    , basicPermissionsEdit = Nothing
    , customTabsEdit = Nothing
    , peopleSettingsEdit = Nothing
    , groupSettingsEdit = Nothing
    , postSettingsEdit = Nothing
    , eventSettingsEdit = Nothing
    , mediaSettingsEdit = Nothing
    , collapsedFeatureSettings = Set.empty
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.customTabsEdit of
        Just edit ->
            Sub.batch
                [ UI.Flip.subscription AnimateCustomTabFlip (Dict.values edit.itemAnimations)
                , UI.Flip.moveSubscription AnimateCustomTabMove (Dict.values edit.moveAnimations)
                ]

        Nothing ->
            Sub.none



-- UPDATE


update : Shared.Model -> String -> Maybe AccountsPanel.Server -> Msg -> Model -> ( Model, Effect Msg )
update shared targetHost maybeServer msg model =
    case msg of
        PermissionsEditClicked set ->
            case maybeServer of
                Just server ->
                    let
                        currentPermissions : List Permission
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
                                pending : List Permission
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
                                        pending : List Permission
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
            case ( permissionsEditFor set model, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( setPermissionsEditFor set (Just { edit | status = AccountsPanel.Submitting }) model
                    , AccountsPanel.updateServerConfig shared.accounts ( Just account.userId, targetHost ) (applyPermissionsFor set edit.pending)
                        |> Task.attempt (GotPermissionsSaveResult set)
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotPermissionsSaveResult set (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( setPermissionsEditFor set Nothing model
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotPermissionsSaveResult set (Err err) ->
            ( setPermissionsEditFor set
                (permissionsEditFor set model |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }))
                model
            , Effect.none
            )

        CustomTabsEditClicked ->
            case maybeServer of
                Just server ->
                    let
                        entries : List CustomTabEntry
                        entries =
                            CustomNav.effectiveTabs (AccountsPanel.configurationOf server).customTabs |> List.indexedMap customTabEntryFrom
                    in
                    ( { model
                        | customTabsEdit =
                            Just
                                { pending = entries
                                , nextEntryId = List.length entries
                                , editingIconFor = Nothing
                                , status = AccountsPanel.Idle
                                , itemAnimations = entries |> List.map (\entry -> ( entry.entryId, UI.Flip.restingState )) |> Dict.fromList
                                , moveAnimations = Dict.empty
                                }
                      }
                    , Effect.none
                    )

                Nothing ->
                    ( model, Effect.none )

        CustomTabsCancelClicked ->
            ( { model | customTabsEdit = Nothing }, Effect.fromShared (Shared.MyMediaPanelMsg MyMediaPanel.CloseClicked) )

        CustomTabsSaveClicked ->
            case ( model.customTabsEdit, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( { model | customTabsEdit = Just { edit | status = AccountsPanel.Submitting } }
                    , AccountsPanel.updateServerConfig shared.accounts ( Just account.userId, targetHost ) (applyCustomTabs edit.pending)
                        |> Task.attempt GotCustomTabsSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotCustomTabsSaveResult (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( { model | customTabsEdit = Nothing }
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotCustomTabsSaveResult (Err err) ->
            ( { model | customTabsEdit = model.customTabsEdit |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }) }
            , Effect.none
            )

        CustomTabAddClicked ->
            case model.customTabsEdit of
                Just edit ->
                    let
                        entryId : String
                        entryId =
                            "tab-" ++ String.fromInt edit.nextEntryId

                        newEntry : CustomTabEntry
                        newEntry =
                            { entryId = entryId
                            , target = CustomNav.TargetTab EVENTSTAB
                            , icon = CustomNav.EmojiIcon "✨"
                            , title = ""
                            , path = CustomNav.defaultPathFor (CustomNav.TargetTab EVENTSTAB)
                            }
                    in
                    ( { model
                        | customTabsEdit =
                            Just
                                { edit
                                    | pending = edit.pending ++ [ newEntry ]
                                    , nextEntryId = edit.nextEntryId + 1
                                    , itemAnimations = Dict.insert entryId UI.Flip.enter edit.itemAnimations
                                }
                      }
                    , Effect.none
                    )

                Nothing ->
                    ( model, Effect.none )

        CustomTabRemoveClicked entryId ->
            ( { model
                | customTabsEdit =
                    model.customTabsEdit
                        |> Maybe.map
                            (\edit ->
                                let
                                    currentState : UI.Flip.State Msg
                                    currentState =
                                        Dict.get entryId edit.itemAnimations |> Maybe.withDefault UI.Flip.restingState
                                in
                                { edit | itemAnimations = Dict.insert entryId (UI.Flip.remove (CustomTabRemoved entryId) currentState) edit.itemAnimations }
                            )
              }
            , Effect.none
            )

        CustomTabRemoved entryId ->
            ( { model
                | customTabsEdit =
                    model.customTabsEdit
                        |> Maybe.map
                            (\edit ->
                                { edit
                                    | pending = List.filter (\entry -> entry.entryId /= entryId) edit.pending
                                    , itemAnimations = Dict.remove entryId edit.itemAnimations
                                    , editingIconFor =
                                        if edit.editingIconFor == Just entryId then
                                            Nothing

                                        else
                                            edit.editingIconFor
                                }
                            )
              }
            , Effect.none
            )

        CustomTabTargetKindChanged entryId text ->
            ( { model
                | customTabsEdit =
                    model.customTabsEdit
                        |> Maybe.map
                            (mapPendingEntry entryId
                                (\entry ->
                                    case CustomNav.targetKindFromText text of
                                        Just (CustomNav.KindTab navTab) ->
                                            { entry | target = CustomNav.TargetTab navTab }

                                        Just CustomNav.KindPost ->
                                            case entry.target of
                                                CustomNav.TargetPost _ ->
                                                    entry

                                                _ ->
                                                    { entry | target = CustomNav.TargetPost "" }

                                        Just CustomNav.KindProfile ->
                                            { entry | target = CustomNav.TargetProfile }

                                        Nothing ->
                                            entry
                                )
                            )
              }
            , Effect.none
            )

        CustomTabPostIdChanged entryId text ->
            ( { model | customTabsEdit = model.customTabsEdit |> Maybe.map (mapPendingEntry entryId (\entry -> { entry | target = CustomNav.TargetPost text })) }
            , Effect.none
            )

        CustomTabTitleChanged entryId text ->
            ( { model | customTabsEdit = model.customTabsEdit |> Maybe.map (mapPendingEntry entryId (\entry -> { entry | title = text })) }
            , Effect.none
            )

        CustomTabPathChanged entryId text ->
            ( { model | customTabsEdit = model.customTabsEdit |> Maybe.map (mapPendingEntry entryId (\entry -> { entry | path = text })) }
            , Effect.none
            )

        CustomTabEmojiChanged entryId text ->
            ( { model | customTabsEdit = model.customTabsEdit |> Maybe.map (mapPendingEntry entryId (\entry -> { entry | icon = CustomNav.EmojiIcon text })) }
            , Effect.none
            )

        CustomTabChooseImageClicked entryId ->
            ( { model | customTabsEdit = model.customTabsEdit |> Maybe.map (\edit -> { edit | editingIconFor = Just entryId }) }
            , Effect.fromShared (Shared.MyMediaPanelMsg (MyMediaPanel.Open (Just (MyMediaPanel.SingleSelect { imagesOnly = True, initialSelection = Nothing })) targetHost))
            )

        CustomTabRemoveImageClicked entryId ->
            ( { model | customTabsEdit = model.customTabsEdit |> Maybe.map (mapPendingEntry entryId (\entry -> { entry | icon = CustomNav.EmojiIcon "" })) }
            , Effect.none
            )

        MoveCustomTabLeftClicked entryId ->
            ( model
            , model.customTabsEdit
                |> Maybe.map (\edit -> UI.Flip.beginReorder .entryId customTabChipDomId GotPreMoveCustomTabPositions -1 entryId edit.pending)
                |> Maybe.withDefault Cmd.none
                |> Effect.fromCmd
            )

        MoveCustomTabRightClicked entryId ->
            ( model
            , model.customTabsEdit
                |> Maybe.map (\edit -> UI.Flip.beginReorder .entryId customTabChipDomId GotPreMoveCustomTabPositions 1 entryId edit.pending)
                |> Maybe.withDefault Cmd.none
                |> Effect.fromCmd
            )

        GotPreMoveCustomTabPositions entryId _ offset (Err _) ->
            ( { model
                | customTabsEdit =
                    model.customTabsEdit |> Maybe.map (\edit -> { edit | pending = UI.Flip.moveListItemBy .entryId offset entryId edit.pending })
              }
            , Effect.none
            )

        GotPreMoveCustomTabPositions entryId neighborEntryId offset (Ok ( chipEl, neighborEl )) ->
            ( { model
                | customTabsEdit =
                    model.customTabsEdit
                        |> Maybe.map
                            (\edit ->
                                { edit
                                    | pending = UI.Flip.moveListItemBy .entryId offset entryId edit.pending
                                    , moveAnimations = UI.Flip.applyReorder UI.Flip.Horizontal CustomTabMoveSettled entryId neighborEntryId chipEl neighborEl edit.moveAnimations
                                }
                            )
              }
            , Effect.none
            )

        CustomTabMoveSettled entryId ->
            ( { model
                | customTabsEdit =
                    model.customTabsEdit
                        |> Maybe.map (\edit -> { edit | moveAnimations = Dict.update entryId (Maybe.map (\state -> { state | moving = False })) edit.moveAnimations })
              }
            , Effect.none
            )

        AnimateCustomTabFlip animMsg ->
            case model.customTabsEdit of
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
                    ( { model | customTabsEdit = Just { edit | itemAnimations = newAnimations } }, Effect.fromCmd (Cmd.batch cmds) )

                Nothing ->
                    ( model, Effect.none )

        AnimateCustomTabMove animMsg ->
            case model.customTabsEdit of
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
                    ( { model | customTabsEdit = Just { edit | moveAnimations = newAnimations } }, Effect.fromCmd (Cmd.batch cmds) )

                Nothing ->
                    ( model, Effect.none )

        FeatureSettingsSectionToggled set ->
            ( { model | collapsedFeatureSettings = toggleSetMember (featureSettingsKey set) model.collapsedFeatureSettings }, Effect.none )

        FeatureSettingsEditClicked set ->
            case maybeServer of
                Just server ->
                    let
                        current : FeatureSettingsSummary
                        current =
                            currentFeatureSettingsFor set (AccountsPanel.configurationOf server)
                    in
                    ( setFeatureSettingsEditFor set
                        (Just
                            { visible = current.visible
                            , moderation = current.moderation
                            , visibility = current.visibility
                            , aliasSingular = Maybe.withDefault "" current.aliasSingular
                            , aliasPlural = Maybe.withDefault "" current.aliasPlural
                            , enableReplies = Maybe.withDefault False current.enableReplies
                            , calendarLookbackDays = current.calendarLookbackDays |> Maybe.map String.fromInt |> Maybe.withDefault ""
                            , calendarDisplayMode = Maybe.withDefault CALENDARDISPLAYWEEK current.calendarDisplayMode
                            , status = AccountsPanel.Idle
                            }
                        )
                        model
                    , Effect.none
                    )

                Nothing ->
                    ( model, Effect.none )

        FeatureSettingsVisibleToggled set ->
            ( setFeatureSettingsEditFor set
                (featureSettingsEditFor set model |> Maybe.map (\edit -> { edit | visible = not edit.visible }))
                model
            , Effect.none
            )

        FeatureSettingsModerationChanged set text ->
            ( setFeatureSettingsEditFor set
                (featureSettingsEditFor set model
                    |> Maybe.map (\edit -> { edit | moderation = Users.moderationFromText text |> Maybe.withDefault edit.moderation })
                )
                model
            , Effect.none
            )

        FeatureSettingsVisibilityChanged set text ->
            ( setFeatureSettingsEditFor set
                (featureSettingsEditFor set model
                    |> Maybe.map (\edit -> { edit | visibility = Posts.visibilityFromText text |> Maybe.withDefault edit.visibility })
                )
                model
            , Effect.none
            )

        FeatureSettingsAliasSingularChanged set text ->
            ( setFeatureSettingsEditFor set
                (featureSettingsEditFor set model |> Maybe.map (\edit -> { edit | aliasSingular = text }))
                model
            , Effect.none
            )

        FeatureSettingsAliasPluralChanged set text ->
            ( setFeatureSettingsEditFor set
                (featureSettingsEditFor set model |> Maybe.map (\edit -> { edit | aliasPlural = text }))
                model
            , Effect.none
            )

        FeatureSettingsEnableRepliesToggled set ->
            ( setFeatureSettingsEditFor set
                (featureSettingsEditFor set model |> Maybe.map (\edit -> { edit | enableReplies = not edit.enableReplies }))
                model
            , Effect.none
            )

        FeatureSettingsCalendarLookbackDaysChanged set text ->
            ( setFeatureSettingsEditFor set
                (featureSettingsEditFor set model |> Maybe.map (\edit -> { edit | calendarLookbackDays = text }))
                model
            , Effect.none
            )

        FeatureSettingsCalendarDisplayModeChanged set text ->
            ( setFeatureSettingsEditFor set
                (featureSettingsEditFor set model
                    |> Maybe.map (\edit -> { edit | calendarDisplayMode = calendarDisplayModeFromText text |> Maybe.withDefault edit.calendarDisplayMode })
                )
                model
            , Effect.none
            )

        FeatureSettingsCancelClicked set ->
            ( setFeatureSettingsEditFor set Nothing model, Effect.none )

        FeatureSettingsSaveClicked set ->
            case ( featureSettingsEditFor set model, Common.adminAccountFor shared targetHost ) of
                ( Just edit, Just account ) ->
                    ( setFeatureSettingsEditFor set (Just { edit | status = AccountsPanel.Submitting }) model
                    , AccountsPanel.updateServerConfig shared.accounts ( Just account.userId, targetHost ) (applyFeatureSettingsFor set edit)
                        |> Task.attempt (GotFeatureSettingsSaveResult set)
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotFeatureSettingsSaveResult set (Ok ( maybeAccountsPanelMsg, newConfig )) ->
            ( setFeatureSettingsEditFor set Nothing model
            , Effect.batch
                [ Common.accountsPanelEffect maybeAccountsPanelMsg
                , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.GotServerConfigSaveResult targetHost newConfig))
                ]
            )

        GotFeatureSettingsSaveResult set (Err err) ->
            ( setFeatureSettingsEditFor set
                (featureSettingsEditFor set model |> Maybe.map (\edit -> { edit | status = AccountsPanel.Errored (AccountsPanel.grpcErrorToString err) }))
                model
            , Effect.none
            )


{-| Reacts to a `Shared.Msg` forwarded through by the parent's own `SharedMsg` branch -- only the
shared `Shared.MyMediaPanel` chooser (opened by `CustomTabChooseImageClicked`) reporting a tap
matters here, gated on `customTabsEdit.editingIconFor` naming the entry that's actually mid-pick (so
an unrelated Browse-mode tap elsewhere can't be mistaken for an icon pick). Mirrors
`ThemeTab.applySharedMsg`'s own `MediaItemClicked` handling.
-}
applySharedMsg : Shared.Msg -> Model -> Model
applySharedMsg subMsg model =
    { model
        | customTabsEdit =
            case subMsg of
                Shared.MyMediaPanelMsg (MyMediaPanel.MediaItemClicked mediaId) ->
                    model.customTabsEdit
                        |> Maybe.map
                            (\edit ->
                                case edit.editingIconFor of
                                    Just entryId ->
                                        { edit | editingIconFor = Nothing }
                                            |> mapPendingEntry entryId (\entry -> { entry | icon = CustomNav.MediaIcon mediaId })

                                    Nothing ->
                                        edit
                            )

                _ ->
                    model.customTabsEdit
    }


{-| `model`'s in-progress `PermissionsEdit` for one `ServerPermissionsSet`, alongside its setter
`setPermissionsEditFor` just below -- lets `update`/`view` treat all three sections generically
instead of a `case` per Msg per section.
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


{-| One `ServerPermissionsSet`'s current list out of a `ServerConfiguration`, alongside its writer
`applyPermissionsFor` just below.
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


{-| Toggles a single `Set` member -- `FeatureSettingsSectionToggled`'s own plumbing, generic since
nothing else here needs a `Set` yet.
-}
toggleSetMember : comparable -> Set comparable -> Set comparable
toggleSetMember key set =
    if Set.member key set then
        Set.remove key set

    else
        Set.insert key set


{-| The URL-param-style key `collapsedFeatureSettings` stores per `FeatureSettingsSet` -- distinct
from `featureSettingsLabel`'s user-facing text so relabeling one never silently breaks the other.
-}
featureSettingsKey : FeatureSettingsSet -> String
featureSettingsKey set =
    case set of
        PeopleFeatureSettings ->
            "people"

        GroupFeatureSettings ->
            "group"

        PostFeatureSettings ->
            "post"

        EventFeatureSettings ->
            "event"

        MediaFeatureSettings ->
            "media"


featureSettingsLabel : FeatureSettingsSet -> String
featureSettingsLabel set =
    case set of
        PeopleFeatureSettings ->
            "People"

        GroupFeatureSettings ->
            "Groups"

        PostFeatureSettings ->
            "Posts"

        EventFeatureSettings ->
            "Events"

        MediaFeatureSettings ->
            "Media"


{-| `model`'s in-progress `FeatureSettingsEdit` for one `FeatureSettingsSet`, alongside its setter
`setFeatureSettingsEditFor` just below -- mirrors `permissionsEditFor`/`setPermissionsEditFor`.
-}
featureSettingsEditFor : FeatureSettingsSet -> Model -> Maybe FeatureSettingsEdit
featureSettingsEditFor set model =
    case set of
        PeopleFeatureSettings ->
            model.peopleSettingsEdit

        GroupFeatureSettings ->
            model.groupSettingsEdit

        PostFeatureSettings ->
            model.postSettingsEdit

        EventFeatureSettings ->
            model.eventSettingsEdit

        MediaFeatureSettings ->
            model.mediaSettingsEdit


setFeatureSettingsEditFor : FeatureSettingsSet -> Maybe FeatureSettingsEdit -> Model -> Model
setFeatureSettingsEditFor set edit model =
    case set of
        PeopleFeatureSettings ->
            { model | peopleSettingsEdit = edit }

        GroupFeatureSettings ->
            { model | groupSettingsEdit = edit }

        PostFeatureSettings ->
            { model | postSettingsEdit = edit }

        EventFeatureSettings ->
            { model | eventSettingsEdit = edit }

        MediaFeatureSettings ->
            { model | mediaSettingsEdit = edit }


{-| Only `UNMODERATED`/`PENDING` are valid `default_moderation` values (see
`protos/server_configuration.proto`'s own `FeatureSettings` doc) -- unlike
`Components.Users.allModerations`, which also offers `APPROVED`/`REJECTED` (valid on a Post/User's
own moderation, but not as a server-wide default).
-}
allowedDefaultModerations : List Moderation
allowedDefaultModerations =
    [ UNMODERATED, PENDING ]


{-| Only `SERVER_PUBLIC`/`GLOBAL_PUBLIC` are valid `default_visibility` values (same doc as
`allowedDefaultModerations`) -- unlike `Components.Posts.allVisibilities`, which also offers
`PRIVATE`/`LIMITED`.
-}
allowedDefaultVisibilities : List Visibility
allowedDefaultVisibilities =
    [ SERVERPUBLIC, GLOBALPUBLIC ]


allCalendarDisplayModes : List CalendarDisplayMode
allCalendarDisplayModes =
    [ CALENDARDISPLAYWEEK, CALENDARDISPLAYMONTH, CALENDARDISPLAYDAY ]


{-| Short UI labels for `CalendarDisplayMode` -- the enum's own protobuf names
(`CALENDAR_DISPLAY_WEEK`/etc.) are that verbose purely because protobuf enum values are
conventionally namespaced by their enum's name; the UI just needs "Week"/"Month"/"Day" (per this
page's own admin instructions).
-}
calendarDisplayModeText : CalendarDisplayMode -> String
calendarDisplayModeText mode =
    case mode of
        CALENDARDISPLAYWEEK ->
            "Week"

        CALENDARDISPLAYMONTH ->
            "Month"

        CALENDARDISPLAYDAY ->
            "Day"

        CalendarDisplayModeUnrecognized_ _ ->
            "Week"


calendarDisplayModeFromText : String -> Maybe CalendarDisplayMode
calendarDisplayModeFromText text =
    allCalendarDisplayModes |> List.filter (\mode -> calendarDisplayModeText mode == text) |> List.head


{-| Which of the "extra" fields (beyond `visible`/`defaultModeration`/`defaultVisibility`, which
every `FeatureSettingsSet` has) actually exist on the real proto type underneath `set` -- gates
which rows `featureSettingsDisplayView`/`featureSettingsEditView` show, and which fields
`applyFeatureSettingsFor` writes back. `MediaSettings` has none of them; `FeatureSettings`
(People/Groups) has only alias; `PostSettings` adds replies; `EventSettings` alone has all four.
-}
featureSettingsFieldsFor : FeatureSettingsSet -> { alias : Bool, replies : Bool, calendarLookback : Bool, calendarDisplayMode : Bool }
featureSettingsFieldsFor set =
    case set of
        PeopleFeatureSettings ->
            { alias = True, replies = False, calendarLookback = False, calendarDisplayMode = False }

        GroupFeatureSettings ->
            { alias = True, replies = False, calendarLookback = False, calendarDisplayMode = False }

        PostFeatureSettings ->
            { alias = True, replies = True, calendarLookback = False, calendarDisplayMode = False }

        EventFeatureSettings ->
            { alias = True, replies = True, calendarLookback = True, calendarDisplayMode = True }

        MediaFeatureSettings ->
            { alias = False, replies = False, calendarLookback = False, calendarDisplayMode = False }


{-| `currentFeatureSettingsFor`'s return shape -- every field every `FeatureSettingsSet` might show,
`Maybe`-wrapped for the four that not all of them have (see `featureSettingsFieldsFor`).
-}
type alias FeatureSettingsSummary =
    { visible : Bool
    , moderation : Moderation
    , visibility : Visibility
    , aliasSingular : Maybe String
    , aliasPlural : Maybe String
    , enableReplies : Maybe Bool
    , calendarLookbackDays : Maybe Int
    , calendarDisplayMode : Maybe CalendarDisplayMode
    }


{-| One `FeatureSettingsSet`'s current settings, defaulted (via `defaultFeatureSettings`/
`defaultPostSettings`/`defaultEventSettings`/`defaultMediaSettings`) the same way
`applyLogoChoice`/`applyColorFor` default their own optional message fields -- `ServerConfiguration`'s
`peopleSettings`/etc. are all `Maybe`-wrapped even though the proto itself doesn't mark them
`optional` (every message-typed field is implicitly optional in proto3). Each branch builds its own
`FeatureSettingsSummary` literal rather than sharing one polymorphic accessor across
`FeatureSettings`/`PostSettings`/`EventSettings`/`MediaSettings` -- those four types don't all have
the same fields (see `featureSettingsFieldsFor`), so there's no single row-polymorphic record they
all fit.
-}
currentFeatureSettingsFor : FeatureSettingsSet -> ServerConfiguration -> FeatureSettingsSummary
currentFeatureSettingsFor set config =
    case set of
        PeopleFeatureSettings ->
            let
                s : Proto.Jonline.FeatureSettings
                s =
                    Maybe.withDefault defaultFeatureSettings config.peopleSettings
            in
            { visible = s.visible, moderation = s.defaultModeration, visibility = s.defaultVisibility, aliasSingular = s.aliasSingular, aliasPlural = s.aliasPlural, enableReplies = Nothing, calendarLookbackDays = Nothing, calendarDisplayMode = Nothing }

        GroupFeatureSettings ->
            let
                s : Proto.Jonline.FeatureSettings
                s =
                    Maybe.withDefault defaultFeatureSettings config.groupSettings
            in
            { visible = s.visible, moderation = s.defaultModeration, visibility = s.defaultVisibility, aliasSingular = s.aliasSingular, aliasPlural = s.aliasPlural, enableReplies = Nothing, calendarLookbackDays = Nothing, calendarDisplayMode = Nothing }

        PostFeatureSettings ->
            let
                s : Proto.Jonline.PostSettings
                s =
                    Maybe.withDefault defaultPostSettings config.postSettings
            in
            { visible = s.visible, moderation = s.defaultModeration, visibility = s.defaultVisibility, aliasSingular = s.aliasSingular, aliasPlural = s.aliasPlural, enableReplies = s.enableReplies, calendarLookbackDays = Nothing, calendarDisplayMode = Nothing }

        EventFeatureSettings ->
            let
                s : Proto.Jonline.EventSettings
                s =
                    Maybe.withDefault defaultEventSettings config.eventSettings
            in
            { visible = s.visible, moderation = s.defaultModeration, visibility = s.defaultVisibility, aliasSingular = s.aliasSingular, aliasPlural = s.aliasPlural, enableReplies = s.enableReplies, calendarLookbackDays = s.calendarLookbackDays, calendarDisplayMode = Just s.defaultCalendarDisplayMode }

        MediaFeatureSettings ->
            let
                s : Proto.Jonline.MediaSettings
                s =
                    Maybe.withDefault defaultMediaSettings config.mediaSettings
            in
            { visible = s.visible, moderation = s.defaultModeration, visibility = s.defaultVisibility, aliasSingular = Nothing, aliasPlural = Nothing, enableReplies = Nothing, calendarLookbackDays = Nothing, calendarDisplayMode = Nothing }


{-| Overlays a `FeatureSettingsEdit`'s `visible`/`moderation`/`visibility` onto whichever of
`FeatureSettings`/`PostSettings`/`EventSettings`/`MediaSettings` `settings` already is, leaving
every other field untouched -- the trio every one of the four types shares. `applyFeatureSettingsFor`
layers each type's own extra fields (alias/replies/lookback/display mode) on top of this per branch,
since those aren't uniform across all four the way this trio is.
-}
updatedFeatureSettings : FeatureSettingsEdit -> { r | visible : Bool, defaultModeration : Moderation, defaultVisibility : Visibility } -> { r | visible : Bool, defaultModeration : Moderation, defaultVisibility : Visibility }
updatedFeatureSettings edit settings =
    { settings | visible = edit.visible, defaultModeration = edit.moderation, defaultVisibility = edit.visibility }


{-| Empty (after trimming) `<input>` text round-trips to `Nothing` -- how every optional-string
field on this page's editors (`aliasSingular`/`aliasPlural` here, `FacebookAuthFieldEdit`'s
`appId`/`appSecret` elsewhere) represents "unset."
-}
optionalString : String -> Maybe String
optionalString text =
    let
        trimmed : String
        trimmed =
            String.trim text
    in
    if String.isEmpty trimmed then
        Nothing

    else
        Just trimmed


{-| `calendarLookbackDays`'s pending `<input type="number">` text -> the proto's `optional uint32`.
Blank or unparseable text, or a negative number, both mean "unset" (falls back to the server's own
built-in default) -- there's no inline validation error for a bad value here, matching this page's
existing light-touch validation style (e.g. a blank Facebook App Secret is silently a no-op, not an
error).
-}
optionalNonNegativeInt : String -> Maybe Int
optionalNonNegativeInt text =
    String.toInt (String.trim text)
        |> Maybe.andThen
            (\n ->
                if n >= 0 then
                    Just n

                else
                    Nothing
            )


{-| `FeatureSettingsSaveClicked`'s transform, passed to `AccountsPanel.updateServerConfig` the same
way `applyPermissionsFor`'s result is -- overlays `edit`'s trio onto a freshly re-fetched
`ServerConfiguration`'s matching field (defaulted the same way `currentFeatureSettingsFor` is), then
layers on whichever of alias/replies/lookback/display mode that field's real type actually has (see
`featureSettingsFieldsFor`) -- `MediaSettings` gets none of them, `FeatureSettings` (People/Groups)
gets alias only, `PostSettings` adds replies, and `EventSettings` gets all four.
-}
applyFeatureSettingsFor : FeatureSettingsSet -> FeatureSettingsEdit -> ServerConfiguration -> ServerConfiguration
applyFeatureSettingsFor set edit config =
    case set of
        PeopleFeatureSettings ->
            let
                updated : Proto.Jonline.FeatureSettings
                updated =
                    updatedFeatureSettings edit (Maybe.withDefault defaultFeatureSettings config.peopleSettings)
            in
            { config | peopleSettings = Just { updated | aliasSingular = optionalString edit.aliasSingular, aliasPlural = optionalString edit.aliasPlural } }

        GroupFeatureSettings ->
            let
                updated : Proto.Jonline.FeatureSettings
                updated =
                    updatedFeatureSettings edit (Maybe.withDefault defaultFeatureSettings config.groupSettings)
            in
            { config | groupSettings = Just { updated | aliasSingular = optionalString edit.aliasSingular, aliasPlural = optionalString edit.aliasPlural } }

        PostFeatureSettings ->
            let
                updated : Proto.Jonline.PostSettings
                updated =
                    updatedFeatureSettings edit (Maybe.withDefault defaultPostSettings config.postSettings)
            in
            { config
                | postSettings =
                    Just
                        { updated
                            | aliasSingular = optionalString edit.aliasSingular
                            , aliasPlural = optionalString edit.aliasPlural
                            , enableReplies = Just edit.enableReplies
                        }
            }

        EventFeatureSettings ->
            let
                updated : Proto.Jonline.EventSettings
                updated =
                    updatedFeatureSettings edit (Maybe.withDefault defaultEventSettings config.eventSettings)
            in
            { config
                | eventSettings =
                    Just
                        { updated
                            | aliasSingular = optionalString edit.aliasSingular
                            , aliasPlural = optionalString edit.aliasPlural
                            , enableReplies = Just edit.enableReplies
                            , calendarLookbackDays = optionalNonNegativeInt edit.calendarLookbackDays
                            , defaultCalendarDisplayMode = edit.calendarDisplayMode
                        }
            }

        MediaFeatureSettings ->
            { config | mediaSettings = Just (updatedFeatureSettings edit (Maybe.withDefault defaultMediaSettings config.mediaSettings)) }


{-| Starts a `PermissionsEdit` off `currentPermissions` (that set's own, as currently configured) --
`addSelection` defaults to the first grantable permission not already in that list, same as
`resolveAddSelection` picks after every add/remove. Mirrors
`Components.Pages.UserProfilePage.newPermissionsEdit`.
-}
newPermissionsEdit : List Permission -> PermissionsEdit
newPermissionsEdit currentPermissions =
    { pending = currentPermissions
    , addSelection = resolveAddSelection Nothing currentPermissions
    , status = AccountsPanel.Idle
    }


{-| Keeps the "Add Permission" `<select>`'s selection valid as `pending` changes: keeps `current`
if it's still addable (not already in `pending`), otherwise falls back to the first still-addable
permission (`Nothing` if every permission's already been added). Mirrors `UserProfilePage`'s own.
-}
resolveAddSelection : Maybe Permission -> List Permission -> Maybe Permission
resolveAddSelection current pending =
    let
        available : List Permission
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


{-| `CustomTabsEditClicked`'s starting point -- one `CustomTabEntry` per `UI.CustomNav.effectiveTabs`
entry (so a freshly-opened editor starts from `defaultTabs` when `customTabs` itself is unset,
same "unset means the code-defined defaults" rule `CustomNav.effectiveTabs` already encodes),
`index` minting each entry's own stable `entryId` (see `CustomTabsEdit`'s own doc).
-}
customTabEntryFrom : Int -> CustomNav.CustomTab -> CustomTabEntry
customTabEntryFrom index tab =
    { entryId = "tab-" ++ String.fromInt index
    , target = tab.target
    , icon = tab.icon
    , title = Maybe.withDefault "" tab.title
    , path = tab.path
    }


{-| Updates the one entry of `edit.pending` matching `entryId`, if any -- every per-entry field
Msg's shared plumbing. Mirrors `FederationTab.mapPendingHost`.
-}
mapPendingEntry : String -> (CustomTabEntry -> CustomTabEntry) -> CustomTabsEdit -> CustomTabsEdit
mapPendingEntry entryId fn edit =
    { edit
        | pending =
            edit.pending
                |> List.map
                    (\entry ->
                        if entry.entryId == entryId then
                            fn entry

                        else
                            entry
                    )
    }


{-| `CustomTabsSaveClicked`'s transform, passed to `AccountsPanel.updateServerConfig` the same way
every other editor's transform is -- overlays `entries` (in the edit's own order) onto a freshly
re-fetched `ServerConfiguration`'s `customTabs.tabs`, leaving `customTabs.home` (never edited here --
see this module's own doc) untouched. Each entry's blank `title` round-trips to `Nothing` (same
`optionalString` convention as `applyFeatureSettingsFor`'s alias fields); `path` is sent as-is --
the backend's `validate_configuration` is the actual authority on whether it's a valid `[a-z_]+` slug
(see `CustomTabEntry`'s own doc), surfaced back through `GotCustomTabsSaveResult`'s `Err` branch same
as any other rejected save.
-}
applyCustomTabs : List CustomTabEntry -> ServerConfiguration -> ServerConfiguration
applyCustomTabs entries config =
    let
        existing : Proto.Jonline.CustomNavigationTabSet
        existing =
            Maybe.withDefault defaultCustomNavigationTabSet config.customTabs

        toTabWithPath : CustomTabEntry -> Proto.Jonline.CustomNavigationTabWithPath
        toTabWithPath entry =
            let
                tab : CustomNav.CustomTab
                tab =
                    { target = entry.target, icon = entry.icon, title = optionalString entry.title, path = entry.path }
            in
            { customTab = Just (CustomNav.toProtoTab tab), path = entry.path }
    in
    { config | customTabs = Just { existing | tabs = entries |> List.map toTabWithPath } }


{-| The DOM `id` a custom-tab chip is rendered with while `customTabsEdit` is active -- the
`UI.Flip.Horizontal` counterpart `MoveCustomTabLeftClicked`/`MoveCustomTabRightClicked` measure.
Mirrors `FederationTab.federatedServerChipDomId`.
-}
customTabChipDomId : String -> String
customTabChipDomId entryId =
    "custom-tab-chip-" ++ entryId



-- VIEW


view : AccountsPanel.Server -> Maybe AccountsPanel.Account -> Model -> Html Msg
view server maybeAdminAccount model =
    let
        config : ServerConfiguration
        config =
            AccountsPanel.configurationOf server
    in
    div [ Html.Attributes.class "server-details-tab-content server-details-settings" ]
        ([ permissionsSection AnonymousPermissions "Anonymous User Permissions" maybeAdminAccount model.anonymousPermissionsEdit config.anonymousUserPermissions
         , permissionsSection DefaultPermissions "Default User Permissions" maybeAdminAccount model.defaultPermissionsEdit config.defaultUserPermissions
         , permissionsSection BasicPermissions "Basic User Permissions" maybeAdminAccount model.basicPermissionsEdit config.basicUserPermissions
         , customTabsSection server maybeAdminAccount model.customTabsEdit
         ]
            ++ ([ PeopleFeatureSettings, GroupFeatureSettings, PostFeatureSettings, EventFeatureSettings, MediaFeatureSettings ]
                    |> List.map
                        (\set ->
                            featureSettingsSection set
                                maybeAdminAccount
                                (featureSettingsEditFor set model)
                                (Set.member (featureSettingsKey set) model.collapsedFeatureSettings)
                                (currentFeatureSettingsFor set config)
                        )
               )
        )


{-| One of the three server-wide permission sections (Anonymous/Default/Basic, distinguished by
`set`) -- plain badges (plus an Edit button, for an admin) when this section has no in-progress
`PermissionsEdit`, or the removable-badges + Add Permission + Save/Cancel editor while being
edited. Mirrors `Components.Pages.UserProfilePage.permissionsSection` exactly, just over a
`ServerConfiguration`'s permission list instead of a `User`'s.
-}
permissionsSection : ServerPermissionsSet -> String -> Maybe AccountsPanel.Account -> Maybe PermissionsEdit -> List Permission -> Html Msg
permissionsSection set label_ maybeAdminAccount maybeEdit permissions =
    case maybeEdit of
        Just edit ->
            div [ Html.Attributes.class "server-details-permissions server-details-permissions-edit" ]
                [ h3 [ classes [ "section-title" ] ] [ text label_ ]
                , div [ Html.Attributes.class "permission-badges" ] (edit.pending |> List.map (permissionEditBadge set))
                , div [ Html.Attributes.class "server-details-permissions-add" ]
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
                        [ Html.Attributes.class "server-details-rename-button"
                        , onClick (PermissionAddClicked set)
                        , disabled (edit.addSelection == Nothing || edit.status == AccountsPanel.Submitting)
                        ]
                        [ text "Add Permission" ]
                    ]
                , div [ Html.Attributes.class "server-details-permissions-actions" ]
                    [ Common.editSaveButton (PermissionsSaveClicked set) edit.status
                    , Common.editCancelButton (PermissionsCancelClicked set) edit.status
                    ]
                , Common.editErrorView edit.status
                ]

        Nothing ->
            div [ Html.Attributes.class "server-details-permissions" ]
                [ h3 [ classes [ "section-title" ] ] [ text label_ ]
                , if List.isEmpty permissions then
                    p [] [ text "None." ]

                  else
                    div [ Html.Attributes.class "permission-badges" ]
                        (permissions |> List.map (\permission -> span [ Html.Attributes.class "permission-badge" ] [ text (Users.permissionText permission) ]))
                , case maybeAdminAccount of
                    Just _ ->
                        button [ Html.Attributes.class "server-details-rename-button", onClick (PermissionsEditClicked set) ] [ text "Edit" ]

                    Nothing ->
                        text ""
                ]


permissionEditBadge : ServerPermissionsSet -> Permission -> Html Msg
permissionEditBadge set permission =
    span [ Html.Attributes.class "permission-badge editable" ]
        [ text (Users.permissionText permission)
        , button
            [ Html.Attributes.class "permission-remove"
            , onClick (PermissionRemoveClicked set permission)
            , Html.Attributes.title ("Remove " ++ Users.permissionText permission)
            ]
            [ text "×" ]
        ]


{-| The "Navigation Tabs" section -- a horizontal `Home` (uneditable, see this module's own doc)
chip followed by one chip per `UI.CustomNav.effectiveTabs` entry, previewing exactly the order/icons
`UI.headerNav` itself would show for this `server` if it were `Shared.AccountsPanel.Model.mainFrontendHost`
(see `UI.CustomNav`'s own module doc). Plain display chips (`customTabsDisplayView`) when nothing's
being edited, or the FLIP-reorderable editor (`customTabsEditorView`) once `CustomTabsEditClicked`
has started one -- same split as `permissionsSection`/`featureSettingsSection`.
-}
customTabsSection : AccountsPanel.Server -> Maybe AccountsPanel.Account -> Maybe CustomTabsEdit -> Html Msg
customTabsSection server maybeAdminAccount maybeEdit =
    div [ Html.Attributes.class "server-details-custom-tabs" ]
        [ h3 [ classes [ "section-title" ] ] [ text "Navigation Tabs" ]
        , case maybeEdit of
            Just edit ->
                customTabsEditorView server edit

            Nothing ->
                customTabsDisplayView server (CustomNav.effectiveTabs (AccountsPanel.configurationOf server).customTabs)
        , case ( maybeEdit, maybeAdminAccount ) of
            ( Nothing, Just _ ) ->
                button [ Html.Attributes.class "server-details-rename-button", onClick CustomTabsEditClicked ] [ text "Edit" ]

            _ ->
                text ""
        ]


customTabsDisplayView : AccountsPanel.Server -> List CustomNav.CustomTab -> Html Msg
customTabsDisplayView server tabs =
    div [ Html.Attributes.class "custom-tabs-strip" ] (homeTabChip server :: List.map (customTabChip server) tabs)


{-| The `Home` slot's own chip -- always the server's own logo/name (`AccountsPanel.serverNameAndLogo`,
same content `UI.homeLinkContent` shows in the real nav), regardless of `customTabs.home` (see this
module's own doc on why that override isn't wired up to any editor yet). Shown in both
`customTabsDisplayView` and `customTabsEditorView` so the preview always reads as "this is where Home
sits, then your tabs" -- but only the latter also wraps it in FLIP/reorder chrome, since it's never
itself reorderable.
-}
homeTabChip : AccountsPanel.Server -> Html msg
homeTabChip server =
    div [ classes [ "server-chip", "custom-tab-chip", "custom-tab-chip-home", hostnameToCSSClass server.frontendHost ] ]
        [ div [ classes [ "server-chip-top", "background-color-primary" ] ]
            [ AccountsPanel.serverNameAndLogo server AccountsPanel.RegularServerLogo ]
        , div [ classes [ "server-chip-bottom", "background-color-nav" ] ]
            [ span [ Html.Attributes.class "custom-tab-chip-label" ] [ text "Home" ] ]
        ]


customTabChip : AccountsPanel.Server -> CustomNav.CustomTab -> Html msg
customTabChip server tab =
    div [ classes [ "server-chip", "custom-tab-chip", hostnameToCSSClass server.frontendHost ] ]
        [ div [ classes [ "server-chip-top", "background-color-primary", "custom-tab-chip-icon-row" ] ]
            [ CustomNav.iconView server tab.icon ]
        , div [ classes [ "server-chip-bottom", "background-color-nav" ] ]
            [ span [ Html.Attributes.class "custom-tab-chip-label" ] [ text (CustomNav.resolvedTitle tab) ] ]
        ]


{-| The chip strip (add/remove/reorder-animated via `UI.Flip`, mirroring `FederationTab.federationEditorView`
almost exactly), the "Add Tab" button, and the Save/Cancel actions -- everything shown once
`CustomTabsEditClicked` has started an edit. `homeTabChip` is always the strip's first, non-FLIP,
non-reorderable entry (see its own doc).
-}
customTabsEditorView : AccountsPanel.Server -> CustomTabsEdit -> Html Msg
customTabsEditorView server edit =
    div [ Html.Attributes.class "server-details-custom-tabs-edit" ]
        [ Html.Keyed.node "div"
            [ classes [ "custom-tabs-strip", "flip-animated-row" ] ]
            (( "home", homeTabChip server )
                :: (edit.pending
                        |> List.indexedMap
                            (\index entry -> ( entry.entryId, customTabEditChipFlip server edit (List.length edit.pending) index entry ))
                   )
            )
        , div [ Html.Attributes.class "server-details-permissions-actions" ]
            [ button [ Html.Attributes.class "server-details-rename-button", onClick CustomTabAddClicked ] [ text "Add Tab" ] ]
        , div [ Html.Attributes.class "server-details-permissions-actions" ]
            [ Common.editSaveButton CustomTabsSaveClicked edit.status
            , Common.editCancelButton CustomTabsCancelClicked edit.status
            ]
        , Common.editErrorView edit.status
        ]


{-| Wraps `customTabEditChip` in a fading/scaling/collapsing animated outer `div` (entering when
freshly added via `CustomTabAddClicked`, removing when `CustomTabRemoveClicked`) -- mirrors
`FederationTab.federatedServerEditChipFlip` exactly, just over `CustomTabEntry` instead of
`FederatedServer`.
-}
customTabEditChipFlip : AccountsPanel.Server -> CustomTabsEdit -> Int -> Int -> CustomTabEntry -> Html Msg
customTabEditChipFlip server edit count index entry =
    let
        flipState : UI.Flip.State Msg
        flipState =
            Dict.get entry.entryId edit.itemAnimations |> Maybe.withDefault UI.Flip.restingState

        isMoving : Bool
        isMoving =
            Dict.get entry.entryId edit.moveAnimations |> Maybe.map .moving |> Maybe.withDefault False

        pointerEventsAttr : List (Html.Attribute Msg)
        pointerEventsAttr =
            if flipState.removing then
                [ Html.Attributes.style "pointer-events" "none" ]

            else
                []
    in
    div (UI.Flip.itemAttributes UI.Flip.Horizontal flipState isMoving)
        [ div pointerEventsAttr [ customTabEditChip server edit count index entry ] ]


{-| One custom tab's editor chip: left/right reorder arrows flanking the icon editor (mirrors
`FederationTab.federatedServerEditChip`'s own layout), then the "type of tab" `<select>` (plus a
Post-id `<input>` when that's the chosen kind), a Title `<input>`, and a remove button.
-}
customTabEditChip : AccountsPanel.Server -> CustomTabsEdit -> Int -> Int -> CustomTabEntry -> Html Msg
customTabEditChip server edit count index entry =
    let
        moveAttrs : List (Html.Attribute Msg)
        moveAttrs =
            edit.moveAnimations |> Dict.get entry.entryId |> Maybe.map UI.Flip.moveAttributes |> Maybe.withDefault []

        showBackward : Bool
        showBackward =
            index > 0

        showForward : Bool
        showForward =
            index < count - 1

        reorderPair : { backward : Html Msg, forward : Html Msg }
        reorderPair =
            UI.Flip.reorderButtonPair UI.Flip.Horizontal
                { moveBackward = onClick (MoveCustomTabLeftClicked entry.entryId)
                , moveForward = onClick (MoveCustomTabRightClicked entry.entryId)
                , canMoveBackward = showBackward
                , canMoveForward = showForward
                }
    in
    div
        (id (customTabChipDomId entry.entryId)
            :: classes [ "server-chip", "custom-tab-chip", "custom-tab-chip-edit", hostnameToCSSClass server.frontendHost ]
            :: moveAttrs
        )
        [ div [ classes [ "server-chip-top", "background-color-primary" ] ]
            [ div [ Html.Attributes.class "server-chip-logo-row" ]
                [ div [ Html.Attributes.classList [ ( "reorder-arrow", True ), ( "reorder-arrow-hidden", not showBackward ) ] ] [ reorderPair.backward ]
                , customTabIconEditor server entry
                , div [ Html.Attributes.classList [ ( "reorder-arrow", True ), ( "reorder-arrow-hidden", not showForward ) ] ] [ reorderPair.forward ]
                ]
            ]
        , div [ classes [ "server-chip-bottom", "background-color-nav", "custom-tab-chip-edit-fields" ] ]
            (List.concat
                [ [ customTabTargetSelect entry ]
                , case entry.target of
                    CustomNav.TargetPost postId ->
                        [ input
                            [ Html.Attributes.class "custom-tab-post-id-input"
                            , placeholder "Post ID"
                            , value postId
                            , onInput (CustomTabPostIdChanged entry.entryId)
                            ]
                            []
                        ]

                    CustomNav.TargetTab _ ->
                        []

                    CustomNav.TargetProfile ->
                        []
                , [ input
                        [ Html.Attributes.class "custom-tab-title-input"
                        , placeholder (CustomNav.resolvedTitle { target = entry.target, icon = entry.icon, title = Nothing, path = entry.path })
                        , value entry.title
                        , onInput (CustomTabTitleChanged entry.entryId)
                        ]
                        []
                  , input
                        [ Html.Attributes.class "custom-tab-path-input"
                        , placeholder
                            (case entry.target of
                                CustomNav.TargetProfile ->
                                    "username"

                                _ ->
                                    "path (a-z, _)"
                            )
                        , value entry.path
                        , onInput (CustomTabPathChanged entry.entryId)
                        ]
                        []
                  , button
                        [ Html.Attributes.class "remove-btn"
                        , onClick (CustomTabRemoveClicked entry.entryId)
                        , Html.Attributes.title "Remove tab"
                        ]
                        [ text "╳" ]
                  ]
                ]
            )
        ]


{-| An entry's icon editor: a live preview (`CustomNav.iconView`), an emoji `<input>` (only shown
while `entry.icon` is already an `EmojiIcon` -- typing into it always keeps it one, see
`CustomTabEmojiChanged`), and either a "Image…" button (opens `Shared.MyMediaPanel`, see
`CustomTabChooseImageClicked`/`applySharedMsg`) or, once a `MediaIcon`'s chosen, a "Use Emoji" button
reverting to a blank `EmojiIcon` instead.
-}
customTabIconEditor : AccountsPanel.Server -> CustomTabEntry -> Html Msg
customTabIconEditor server entry =
    div [ Html.Attributes.class "custom-tab-icon-editor" ]
        [ div [ Html.Attributes.class "custom-tab-icon-preview" ] [ CustomNav.iconView server entry.icon ]
        , case entry.icon of
            CustomNav.EmojiIcon emoji ->
                input
                    [ Html.Attributes.class "custom-tab-emoji-input"
                    , placeholder "✨"
                    , value emoji
                    , onInput (CustomTabEmojiChanged entry.entryId)
                    ]
                    []

            CustomNav.MediaIcon _ ->
                text ""
        , div [ Html.Attributes.class "custom-tab-icon-actions" ]
            [ button [ Html.Attributes.class "custom-tab-icon-choose", onClick (CustomTabChooseImageClicked entry.entryId) ] [ text "Image…" ]
            , case entry.icon of
                CustomNav.MediaIcon _ ->
                    button [ Html.Attributes.class "custom-tab-icon-choose", onClick (CustomTabRemoveImageClicked entry.entryId) ] [ text "Use Emoji" ]

                CustomNav.EmojiIcon _ ->
                    text ""
            ]
        ]


customTabTargetSelect : CustomTabEntry -> Html Msg
customTabTargetSelect entry =
    select [ onInput (CustomTabTargetKindChanged entry.entryId) ]
        (CustomNav.selectableTargetKinds
            |> List.map
                (\kind ->
                    option
                        [ value (CustomNav.targetKindText kind), selected (CustomNav.targetKind entry.target == kind) ]
                        [ text (CustomNav.targetKindText kind) ]
                )
        )


{-| One of the five per-feature settings sections (People/Groups/Posts/Events/Media, distinguished
by `set`) -- a collapsible panel (`expanded`, toggled by `FeatureSettingsSectionToggled`, defaulted
to expanded -- see `Model.collapsedFeatureSettings`), reusing the same `.section-title`/
`.expandable-section-title`/`.expandable-section-arrow` header look
`Components.Pages.UserProfilePage.expandableProfileSection` establishes for its own
Permissions/Event Sync sections. The body is `featureSettingsDisplayView` (plain text/a disabled
checkbox, plus an Edit button for an admin) when this section has no in-progress
`FeatureSettingsEdit`, or `featureSettingsEditView` (an enabled checkbox + Moderation/Visibility
`<select>`s + Save/Cancel) while being edited -- mirrors `permissionsSection`'s own edit/non-edit
split, just collapsible.
-}
featureSettingsSection : FeatureSettingsSet -> Maybe AccountsPanel.Account -> Maybe FeatureSettingsEdit -> Bool -> FeatureSettingsSummary -> Html Msg
featureSettingsSection set maybeAdminAccount maybeEdit collapsed current =
    let
        expanded : Bool
        expanded =
            not collapsed
    in
    div [ Html.Attributes.class "server-details-feature-settings" ]
        (h3
            [ classes [ "section-title", "expandable-section-title" ]
            , onClick (FeatureSettingsSectionToggled set)
            ]
            [ span [ Html.Attributes.class "expandable-section-arrow" ]
                [ text
                    (if expanded then
                        "▾"

                     else
                        "▸"
                    )
                ]
            , text (featureSettingsLabel set)
            ]
            :: (if expanded then
                    [ case maybeEdit of
                        Just edit ->
                            featureSettingsEditView set edit

                        Nothing ->
                            featureSettingsDisplayView set maybeAdminAccount current
                    ]

                else
                    []
               )
        )


{-| The non-editing body of a `featureSettingsSection` -- `visible`/`enableReplies` are always
disabled toggle switches (`Common.switchDisplay`, the same `.switch`/`.slider` control `CdnTab` uses
for its own read-only flags), everything else is plain monospace text, mirroring `Pages.Post.PostId_`'s
`moderationView`/`visibilityView` non-editing case. Which of alias/replies/lookback/display mode
actually show is gated by `featureSettingsFieldsFor set` -- e.g. Media shows none of them, only
Events shows a display mode. The Edit button is only shown to an admin (`maybeAdminAccount`), same
as `permissionsSection`.
-}
featureSettingsDisplayView : FeatureSettingsSet -> Maybe AccountsPanel.Account -> FeatureSettingsSummary -> Html Msg
featureSettingsDisplayView set maybeAdminAccount current =
    let
        fields : { alias : Bool, replies : Bool, calendarLookback : Bool, calendarDisplayMode : Bool }
        fields =
            featureSettingsFieldsFor set

        textValue : String -> Html Msg
        textValue text_ =
            span [ Html.Attributes.class "server-details-feature-settings-value" ] [ text text_ ]
    in
    div [ Html.Attributes.class "server-details-feature-settings-display" ]
        (List.concat
            [ [ -- Common.settingsRow "Visible" (Common.switchDisplay current.visible),
                Common.settingsRow "Moderation" (textValue (Users.moderationText current.moderation))
              , Common.settingsRow "Visibility" (textValue (Posts.visibilityText current.visibility))
              ]
            , if fields.alias then
                [ Common.settingsRow "Alias (Singular)" (textValue (Maybe.withDefault "—" current.aliasSingular))
                , Common.settingsRow "Alias (Plural)" (textValue (Maybe.withDefault "—" current.aliasPlural))
                ]

              else
                []
            , if fields.replies then
                [ Common.settingsRow "Enable Replies" (Common.switchDisplay (Maybe.withDefault False current.enableReplies)) ]

              else
                []
            , if fields.calendarLookback then
                [ Common.settingsRow "Calendar Lookback (Days)" (textValue (current.calendarLookbackDays |> Maybe.map String.fromInt |> Maybe.withDefault "—")) ]

              else
                []
            , if fields.calendarDisplayMode then
                [ Common.settingsRow "Default Calendar Display Mode" (textValue (current.calendarDisplayMode |> Maybe.map calendarDisplayModeText |> Maybe.withDefault "—")) ]

              else
                []
            , [ case maybeAdminAccount of
                    Just _ ->
                        button [ Html.Attributes.class "server-details-rename-button", onClick (FeatureSettingsEditClicked set) ] [ text "Edit" ]

                    Nothing ->
                        text ""
              ]
            ]
        )


{-| The editing body of a `featureSettingsSection` -- an enabled toggle switch (`Common.flagSwitch`,
same control the Federated Servers tab's own flags use) for `visible`/`enableReplies`, right-aligned
`<select>`s for `moderation`/`visibility`/`calendarDisplayMode`, and `<input>`s for the two alias
fields/`calendarLookbackDays`, mirroring `Pages.Post.PostId_`'s `moderationView`/`visibilityView`
editing case. `moderation`/`visibility` are narrowed to `allowedDefaultModerations`/
`allowedDefaultVisibilities` (the only values `ServerConfiguration`'s own doc allows for a
`default_moderation`/`default_visibility`); which of the rest actually show is gated by
`featureSettingsFieldsFor set`, same as `featureSettingsDisplayView`.
-}
featureSettingsEditView : FeatureSettingsSet -> FeatureSettingsEdit -> Html Msg
featureSettingsEditView set edit =
    let
        fields : { alias : Bool, replies : Bool, calendarLookback : Bool, calendarDisplayMode : Bool }
        fields =
            featureSettingsFieldsFor set

        textInput : (String -> Msg) -> String -> Html Msg
        textInput onChange currentValue =
            input
                [ Html.Attributes.class "server-details-rename-input"
                , value currentValue
                , onInput onChange
                , disabled (edit.status == AccountsPanel.Submitting)
                ]
                []
    in
    div [ Html.Attributes.class "server-details-feature-settings-edit" ]
        (List.concat
            [ [ --Common.settingsRow "Visible" (Common.flagSwitch edit.visible (FeatureSettingsVisibleToggled set)),
                Common.settingsRow "Moderation"
                    (select [ onInput (FeatureSettingsModerationChanged set) ]
                        (allowedDefaultModerations
                            |> List.map
                                (\moderation ->
                                    option
                                        [ value (Users.moderationText moderation), selected (edit.moderation == moderation) ]
                                        [ text (Users.moderationText moderation) ]
                                )
                        )
                    )
              , Common.settingsRow "Visibility"
                    (select [ onInput (FeatureSettingsVisibilityChanged set) ]
                        (allowedDefaultVisibilities
                            |> List.map
                                (\visibility ->
                                    option
                                        [ value (Posts.visibilityText visibility), selected (edit.visibility == visibility) ]
                                        [ text (Posts.visibilityText visibility) ]
                                )
                        )
                    )
              ]
            , if fields.alias then
                [ Common.settingsRow "Alias (Singular)" (textInput (FeatureSettingsAliasSingularChanged set) edit.aliasSingular)
                , Common.settingsRow "Alias (Plural)" (textInput (FeatureSettingsAliasPluralChanged set) edit.aliasPlural)
                ]

              else
                []
            , if fields.replies then
                [ Common.settingsRow "Enable Replies" (Common.flagSwitch edit.enableReplies (FeatureSettingsEnableRepliesToggled set)) ]

              else
                []
            , if fields.calendarLookback then
                [ Common.settingsRow "Calendar Lookback (Days)"
                    (input
                        [ Html.Attributes.class "server-details-rename-input"
                        , Html.Attributes.type_ "number"
                        , Html.Attributes.min "0"
                        , value edit.calendarLookbackDays
                        , onInput (FeatureSettingsCalendarLookbackDaysChanged set)
                        , disabled (edit.status == AccountsPanel.Submitting)
                        ]
                        []
                    )
                ]

              else
                []
            , if fields.calendarDisplayMode then
                [ Common.settingsRow "Default Calendar Display Mode"
                    (select [ onInput (FeatureSettingsCalendarDisplayModeChanged set) ]
                        (allCalendarDisplayModes
                            |> List.map
                                (\mode ->
                                    option
                                        [ value (calendarDisplayModeText mode), selected (edit.calendarDisplayMode == mode) ]
                                        [ text (calendarDisplayModeText mode) ]
                                )
                        )
                    )
                ]

              else
                []
            , [ div [ Html.Attributes.class "server-details-feature-settings-actions" ]
                    [ Common.editSaveButton (FeatureSettingsSaveClicked set) edit.status
                    , Common.editCancelButton (FeatureSettingsCancelClicked set) edit.status
                    ]
              , Common.editErrorView edit.status
              ]
            ]
        )
