module Components.Pages.UserProfilePage exposing
    ( Model
    , Msg
    , fromShared
    , init
    , nameHeader
    , subscriptions
    , titleFor
    , update
    , usernameHeading
    , view
    )

{-| The shared guts of a user profile page: fetching a `Proto.Jonline.User`
from a specific (possibly not-yet-connected) server, by id or by username, and
rendering it -- reused by both `Pages.User.UserId_` (`/user/:id[@host]`) and
`Pages.Username_` (`/:username[@host]`), which differ only in which `Lookup`
they parse out of their route and (for `Pages.Username_`) whether the username
is even routable at all (see `Components.Users.isReservedUsername`, checked by
the page itself before ever constructing this module's `Model`).

Mirrors `Pages.Post.PostId_`, generalized over the `Lookup` since (unlike
Posts, which are only ever looked up by id) a `User` can be fetched by either
id or username.

The actual "fetch a `User` once its server is connected, retry until it is"
state machine lives in `Components.Users.Resolver` (`model.resolver`), shared
with `Pages.Username_.Posts`, which needs the same username -> id resolution
but none of this module's profile-editing machinery.

-}

import Components.Authors as Authors
import Components.Markdown as Markdown
import Components.ServerDependentView as ServerDependentView
import Components.Users as Users
import Components.Users.FollowStatusAndButton as FollowStatusAndButton
import Components.Users.Resolver as Resolver
import Dict exposing (Dict)
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, a, button, div, h1, h2, input, option, p, select, span, text)
import Html.Attributes exposing (class, disabled, href, placeholder, selected, title, value)
import Html.Events exposing (onClick, onInput)
import Proto.Google.Protobuf
import Proto.Jonline exposing (FederatedAccount, User)
import Proto.Jonline.Permission exposing (Permission(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.BrowserTimeZone as BrowserTimeZone
import Shared.Conversions exposing (timestampToPosix)
import Shared.MarkdownPanel as MarkdownPanel
import Task
import UI
import UI.Classes exposing (classes, hostnameToCSSClass)


{-| The fetch state of one entry in a loaded `User.federatedProfiles`, keyed
by `federatedKey` -- mirrors `Shared.StarredPostsPanel.PostFetchStatus`, minus
that module's `ServerUnavailable`/poll-retry distinction, since an unreachable
federated server here just reads the same as any other failure (there's no
polling loop kicking these fetches off again).
-}
type FederatedProfileStatus
    = FederatedProfileLoading
    | FederatedProfileLoaded User
    | FederatedProfileFailed


{-| Shared by `RealNameEdit`/`PermissionsEdit` -- mirrors `Shared.MarkdownPanel`'s
own `SubmitStatus`, kept separate since these two edits are local to this page
rather than routed through that shared panel.
-}
type SubmitStatus
    = Idle
    | Submitting
    | SubmitFailed String


{-| Live only while the Real Name field (see `Model.realNameEdit`) is being
edited -- `input` is the in-progress value, independent of `status.user.realName`
until `RealNameSaveClicked` succeeds.
-}
type alias RealNameEdit =
    { input : String
    , status : SubmitStatus
    }


{-| Live only while the permissions list (see `Model.permissionsEdit`) is
being edited by an admin -- `pending` is the in-progress set (already
reflecting any `PermissionRemoveClicked`/`PermissionAddClicked` since editing
started), `addSelection` is whatever the "Add Permission" `<select>` currently
has chosen (always one of `Components.Users.allPermissions` not already in
`pending`, see `resolveAddSelection`).
-}
type alias PermissionsEdit =
    { pending : List Permission
    , addSelection : Maybe Permission
    , status : SubmitStatus
    }


{-| Live only while the federated profiles list (see `Model.federatedProfilesEdit`)
is being edited by the profile's own owner (see `isOwnProfile` -- unlike
`PermissionsEdit`, there's no `pending`/Save step: `FederateProfile`/
`DefederateProfile` (see `Components.Users.federateProfile`/`defederateProfile`)
each commit immediately, one account at a time, so `user.federatedProfiles`
itself stays the single source of truth throughout editing. `addSelection` is
whichever of the viewer's own other-server accounts (see `federableAccounts`)
the "Link Account" `<select>` currently has chosen.
-}
type alias FederatedProfilesEdit =
    { addSelection : Maybe AccountsPanel.Account
    , status : SubmitStatus
    }


type alias Model =
    { resolver : Resolver.Model
    , connectStatus : ServerDependentView.ConnectStatus
    , pageIsSecure : Bool
    , federatedProfiles : Dict String FederatedProfileStatus
    , realNameEdit : Maybe RealNameEdit
    , permissionsEdit : Maybe PermissionsEdit
    , federatedProfilesEdit : Maybe FederatedProfilesEdit
    , followStatusAndButton : FollowStatusAndButton.Model
    }


{-| `pageIsSecure` is `Shared.AccountsPanel.isSecure req` from the calling
page's own `Request` -- needed for `ConnectClicked` (see `AccountsPanel.connectToServer`),
but not otherwise derivable from `Shared.Model` alone.
-}
init : Shared.Model -> Bool -> String -> Resolver.Lookup -> ( Model, Effect Msg )
init shared pageIsSecure targetHost lookup =
    let
        ( resolverModel, resolverEffect ) =
            Resolver.init shared targetHost lookup
    in
    ( { resolver = resolverModel
      , connectStatus = ServerDependentView.NotConnected
      , pageIsSecure = pageIsSecure
      , federatedProfiles = Dict.empty
      , realNameEdit = Nothing
      , permissionsEdit = Nothing
      , federatedProfilesEdit = Nothing
      , followStatusAndButton = FollowStatusAndButton.init
      }
      -- Closes the Accounts Panel if it happened to be open -- landing on a
      -- profile page always shows the info an open panel would otherwise
      -- duplicate (see `Components.Pages.ServerInformationPage.init`, same
      -- reasoning).
    , Effect.batch
        [ Effect.map ResolverMsg resolverEffect
        , Effect.fromShared (Shared.AccountsPanelMsg AccountsPanel.CloseAccountsPanel)
        ]
    )


{-| Re-fetches the user unconditionally -- called once the shared Markdown
panel (see `Shared.MarkdownPanel`) reports a successful bio save, mirroring
`Pages.Post.PostId_.refetch`.
-}
refetch : Shared.Model -> Model -> ( Model, Effect Msg )
refetch shared model =
    Resolver.refetch shared model.resolver
        |> Tuple.mapFirst (\newResolver -> { model | resolver = newResolver })
        |> Tuple.mapSecond (Effect.map ResolverMsg)


{-| Optimistically applies a just-saved `User` (as returned by
`Users.updateUser`) straight to `model.resolver.status`, without a round-trip
refetch -- used by `GotRealNameSaveResult`/`GotPermissionsSaveResult`.
-}
withResolvedUser : User -> Resolver.Model -> Resolver.Model
withResolvedUser user resolver =
    { resolver | status = Resolver.Loaded user }



-- UPDATE


type Msg
    = ResolverMsg Resolver.Msg
    | ConnectClicked
    | GotConnectResult (Result Grpc.Error AccountsPanel.Server)
    | EnableClicked
    | SharedMsg Shared.Msg
    | GotFederatedServer FederatedAccount (Result Grpc.Error AccountsPanel.Server)
    | GotFederatedUser String (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetUsersResponse ))
    | RealNameEditClicked
    | RealNameInputChanged String
    | RealNameCancelClicked
    | RealNameSaveClicked
    | GotRealNameSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, User ))
    | BioEditClicked
    | PermissionsEditClicked
    | PermissionRemoveClicked Permission
    | PermissionAddSelectionChanged String
    | PermissionAddClicked
    | PermissionsCancelClicked
    | PermissionsSaveClicked
    | GotPermissionsSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, User ))
    | FederatedProfilesEditClicked
    | FederatedProfilesDoneClicked
    | FederatedProfileAddSelectionChanged String
    | FederatedProfileAddClicked
    | GotFederatedProfileAddResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, FederatedAccount ))
    | FederatedProfileRemoveClicked FederatedAccount
    | GotFederatedProfileRemoveResult FederatedAccount (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Google.Protobuf.Empty ))
    | FollowStatusAndButtonMsg FollowStatusAndButton.Msg


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
into `update`'s `SharedMsg` branch -- see `Pages.Post.PostId_.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


{-| Turns a `Maybe AccountsPanel.Msg` (as returned by `Components.Users`'
requests, if a token refresh happened) into an `Effect` to forward it,
`Effect.none` otherwise.
-}
accountsPanelEffect : Maybe AccountsPanel.Msg -> Effect Msg
accountsPanelEffect maybeAccountsPanelMsg =
    maybeAccountsPanelMsg
        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
        |> Maybe.withDefault Effect.none


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        ResolverMsg subMsg ->
            let
                ( newResolver, resolverEffect ) =
                    Resolver.update shared subMsg model.resolver

                newModel =
                    { model | resolver = newResolver }
            in
            case ( subMsg, newResolver.status ) of
                ( Resolver.GotUser (Ok _), Resolver.Loaded user ) ->
                    let
                        ( federatedModel, federatedEffect ) =
                            kickOffFederatedFetches shared user newModel
                    in
                    ( federatedModel, Effect.batch [ Effect.map ResolverMsg resolverEffect, federatedEffect ] )

                _ ->
                    ( newModel, Effect.map ResolverMsg resolverEffect )

        ConnectClicked ->
            ( { model | connectStatus = ServerDependentView.Connecting }
            , AccountsPanel.connectToServer model.pageIsSecure model.resolver.targetHost
                |> Task.attempt GotConnectResult
                |> Effect.fromCmd
            )

        GotConnectResult (Ok server) ->
            let
                ( newResolver, resolverEffect ) =
                    Resolver.fetchIfReady shared model.resolver
            in
            ( { model | connectStatus = ServerDependentView.NotConnected, resolver = newResolver }
            , Effect.batch
                [ Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.ServerConnected server))
                , Effect.map ResolverMsg resolverEffect
                ]
            )

        GotConnectResult (Err err) ->
            ( { model | connectStatus = ServerDependentView.ConnectFailed (AccountsPanel.grpcErrorToString err) }
            , Effect.none
            )

        EnableClicked ->
            ( model, Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.ToggleServerEnabled model.resolver.targetHost)) )

        SharedMsg subMsg ->
            let
                ( resolvedModel, resolverEffect ) =
                    Resolver.update shared (Resolver.fromShared subMsg) model.resolver
                        |> Tuple.mapFirst (\newResolver -> { model | resolver = newResolver })
                        |> Tuple.mapSecond (Effect.map ResolverMsg)

                ( fetchedModel, fetchEffect ) =
                    case subMsg of
                        Shared.MarkdownPanelMsg (MarkdownPanel.GotSaveResult (Ok _)) ->
                            refetch shared resolvedModel

                        _ ->
                            ( resolvedModel, Effect.none )
            in
            ( fetchedModel, Effect.batch [ resolverEffect, fetchEffect ] )

        RealNameEditClicked ->
            case model.resolver.status of
                Resolver.Loaded user ->
                    ( { model | realNameEdit = Just { input = user.realName, status = Idle } }, Effect.none )

                _ ->
                    ( model, Effect.none )

        RealNameInputChanged input ->
            ( { model | realNameEdit = model.realNameEdit |> Maybe.map (\edit -> { edit | input = input }) }
            , Effect.none
            )

        RealNameCancelClicked ->
            ( { model | realNameEdit = Nothing }, Effect.none )

        RealNameSaveClicked ->
            case ( model.resolver.status, model.realNameEdit, serverAndAccount shared model ) of
                ( Resolver.Loaded user, Just edit, Just ( server, account ) ) ->
                    ( { model | realNameEdit = Just { edit | status = Submitting } }
                    , Users.updateUser shared.accountsPanel ( Just account.userId, server.frontendHost ) user.id (\freshUser -> { freshUser | realName = edit.input })
                        |> Task.attempt GotRealNameSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotRealNameSaveResult (Ok ( maybeAccountsPanelMsg, updatedUser )) ->
            ( { model | resolver = withResolvedUser updatedUser model.resolver, realNameEdit = Nothing }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotRealNameSaveResult (Err err) ->
            ( { model
                | realNameEdit =
                    model.realNameEdit |> Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })
              }
            , Effect.none
            )

        BioEditClicked ->
            case model.resolver.status of
                Resolver.Loaded user ->
                    ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.UserBio user) model.resolver.targetHost)) )

                _ ->
                    ( model, Effect.none )

        PermissionsEditClicked ->
            case model.resolver.status of
                Resolver.Loaded user ->
                    ( { model | permissionsEdit = Just (newPermissionsEdit user.permissions) }, Effect.none )

                _ ->
                    ( model, Effect.none )

        PermissionRemoveClicked permission ->
            ( { model
                | permissionsEdit =
                    model.permissionsEdit
                        |> Maybe.map
                            (\edit ->
                                let
                                    pending =
                                        List.filter ((/=) permission) edit.pending
                                in
                                { edit | pending = pending, addSelection = resolveAddSelection edit.addSelection pending }
                            )
              }
            , Effect.none
            )

        PermissionAddSelectionChanged text ->
            ( { model
                | permissionsEdit =
                    model.permissionsEdit |> Maybe.map (\edit -> { edit | addSelection = Users.permissionFromText text })
              }
            , Effect.none
            )

        PermissionAddClicked ->
            ( { model
                | permissionsEdit =
                    model.permissionsEdit
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
              }
            , Effect.none
            )

        PermissionsCancelClicked ->
            ( { model | permissionsEdit = Nothing }, Effect.none )

        PermissionsSaveClicked ->
            case ( model.resolver.status, model.permissionsEdit, serverAndAccount shared model ) of
                ( Resolver.Loaded user, Just edit, Just ( server, account ) ) ->
                    ( { model | permissionsEdit = Just { edit | status = Submitting } }
                    , Users.updateUser shared.accountsPanel ( Just account.userId, server.frontendHost ) user.id (\freshUser -> { freshUser | permissions = edit.pending })
                        |> Task.attempt GotPermissionsSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotPermissionsSaveResult (Ok ( maybeAccountsPanelMsg, updatedUser )) ->
            ( { model | resolver = withResolvedUser updatedUser model.resolver, permissionsEdit = Nothing }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotPermissionsSaveResult (Err err) ->
            ( { model
                | permissionsEdit =
                    model.permissionsEdit |> Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })
              }
            , Effect.none
            )

        FederatedProfilesEditClicked ->
            ( { model
                | federatedProfilesEdit =
                    Just { addSelection = resolveFederatedAddSelection Nothing (federableAccountsFor shared model), status = Idle }
              }
            , Effect.none
            )

        FederatedProfilesDoneClicked ->
            ( { model | federatedProfilesEdit = Nothing }, Effect.none )

        FederatedProfileAddSelectionChanged key ->
            ( { model
                | federatedProfilesEdit =
                    model.federatedProfilesEdit
                        |> Maybe.map
                            (\edit ->
                                { edit
                                    | addSelection =
                                        federableAccountsFor shared model
                                            |> List.filter (\account -> accountKey account == key)
                                            |> List.head
                                }
                            )
              }
            , Effect.none
            )

        FederatedProfileAddClicked ->
            case ( model.federatedProfilesEdit, serverAndAccount shared model ) of
                ( Just edit, Just ( server, account ) ) ->
                    case edit.addSelection of
                        Just selected ->
                            ( { model | federatedProfilesEdit = Just { edit | status = Submitting } }
                            , Users.federateProfile shared.accountsPanel ( Just account.userId, server.frontendHost ) { host = selected.server, userId = selected.userId }
                                |> Task.attempt GotFederatedProfileAddResult
                                |> Effect.fromCmd
                            )

                        Nothing ->
                            ( model, Effect.none )

                _ ->
                    ( model, Effect.none )

        GotFederatedProfileAddResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            let
                clearedModel =
                    { model
                        | federatedProfilesEdit =
                            model.federatedProfilesEdit
                                |> Maybe.map (\edit -> { edit | status = Idle, addSelection = resolveFederatedAddSelection Nothing (federableAccountsFor shared model) })
                    }

                ( refetchedModel, refetchEffect ) =
                    refetch shared clearedModel
            in
            ( refetchedModel
            , Effect.batch
                [ accountsPanelEffect maybeAccountsPanelMsg
                , refetchEffect
                ]
            )

        GotFederatedProfileAddResult (Err err) ->
            ( { model
                | federatedProfilesEdit =
                    model.federatedProfilesEdit |> Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })
              }
            , Effect.none
            )

        FederatedProfileRemoveClicked account ->
            case ( model.federatedProfilesEdit, serverAndAccount shared model ) of
                ( Just edit, Just ( server, signedInAccount ) ) ->
                    ( { model | federatedProfilesEdit = Just { edit | status = Submitting } }
                    , Users.defederateProfile shared.accountsPanel ( Just signedInAccount.userId, server.frontendHost ) account
                        |> Task.attempt (GotFederatedProfileRemoveResult account)
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotFederatedProfileRemoveResult _ (Ok ( maybeAccountsPanelMsg, _ )) ->
            let
                clearedModel =
                    { model
                        | federatedProfilesEdit =
                            model.federatedProfilesEdit
                                |> Maybe.map (\edit -> { edit | status = Idle, addSelection = resolveFederatedAddSelection edit.addSelection (federableAccountsFor shared model) })
                    }

                ( refetchedModel, refetchEffect ) =
                    refetch shared clearedModel
            in
            ( refetchedModel
            , Effect.batch
                [ accountsPanelEffect maybeAccountsPanelMsg
                , refetchEffect
                ]
            )

        GotFederatedProfileRemoveResult _ (Err err) ->
            ( { model
                | federatedProfilesEdit =
                    model.federatedProfilesEdit |> Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })
              }
            , Effect.none
            )

        FollowStatusAndButtonMsg subMsg ->
            case ( model.resolver.status, serverAndAccount shared model ) of
                ( Resolver.Loaded user, Just ( server, account ) ) ->
                    let
                        ( newFollowStatusAndButton, followEffect ) =
                            FollowStatusAndButton.update shared server account user subMsg model.followStatusAndButton

                        newModel =
                            { model | followStatusAndButton = newFollowStatusAndButton }

                        mappedFollowEffect =
                            Effect.map FollowStatusAndButtonMsg followEffect
                    in
                    case subMsg of
                        FollowStatusAndButton.GotFollowResult (Ok _) ->
                            refetch shared newModel |> Tuple.mapSecond (\effect -> Effect.batch [ mappedFollowEffect, effect ])

                        FollowStatusAndButton.GotUnfollowResult (Ok _) ->
                            refetch shared newModel |> Tuple.mapSecond (\effect -> Effect.batch [ mappedFollowEffect, effect ])

                        FollowStatusAndButton.GotModerationResult (Ok _) ->
                            refetch shared newModel |> Tuple.mapSecond (\effect -> Effect.batch [ mappedFollowEffect, effect ])

                        _ ->
                            ( newModel, mappedFollowEffect )

                _ ->
                    ( model, Effect.none )

        GotFederatedServer account (Ok server) ->
            -- Registers the federated user's server into `shared.accountsPanel.servers`
            -- (same as `ConnectClicked`'s own `GotConnectResult` does for
            -- `targetHost`) -- needed so `UI.EmittedStylesheet` actually emits
            -- this host's `background-color-primary` rule for `federatedProfileLink`.
            ( model
            , Effect.batch
                [ Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.ServerConnected server))
                , fetchFederatedUserEffect shared server account
                ]
            )

        GotFederatedServer account (Err _) ->
            ( { model | federatedProfiles = Dict.insert (federatedKey account) FederatedProfileFailed model.federatedProfiles }
            , Effect.none
            )

        GotFederatedUser key (Ok ( maybeAccountsPanelMsg, response )) ->
            let
                accountEffect =
                    accountsPanelEffect maybeAccountsPanelMsg

                newStatus =
                    response.users
                        |> List.head
                        |> Maybe.map FederatedProfileLoaded
                        |> Maybe.withDefault FederatedProfileFailed
            in
            ( { model | federatedProfiles = Dict.insert key newStatus model.federatedProfiles }, accountEffect )

        GotFederatedUser key (Err _) ->
            ( { model | federatedProfiles = Dict.insert key FederatedProfileFailed model.federatedProfiles }
            , Effect.none
            )


{-| The connected `Server`/signed-in `Account` for `model.resolver.targetHost`, if
both exist -- what `RealNameSaveClicked`/`PermissionsSaveClicked` need to
actually submit their `Users.updateUser` task.
-}
serverAndAccount : Shared.Model -> Model -> Maybe ( AccountsPanel.Server, AccountsPanel.Account )
serverAndAccount shared model =
    Maybe.map2 Tuple.pair
        (AccountsPanel.serverForHost shared.accountsPanel.servers model.resolver.targetHost)
        (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.resolver.targetHost)


{-| Starts a `PermissionsEdit` off `currentPermissions` (the user's own, as
loaded) -- `addSelection` defaults to the first grantable permission not
already in that list, same as `resolveAddSelection` picks after every
add/remove.
-}
newPermissionsEdit : List Permission -> PermissionsEdit
newPermissionsEdit currentPermissions =
    { pending = currentPermissions
    , addSelection = resolveAddSelection Nothing currentPermissions
    , status = Idle
    }


{-| Keeps the "Add Permission" `<select>`'s selection valid as `pending`
changes: keeps `current` if it's still addable (not already in `pending`),
otherwise falls back to the first still-addable permission (`Nothing` if
every permission's already been added).
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
    Users.allPermissions |> List.filter (\permission -> not (List.member permission pending))


{-| Whether the currently signed-in account on `user`'s own server (`maybeAccount`)
_is_ `user` -- unlike `canEditProfile`, admins don't get a pass here, since
`FederateProfile`/`DefederateProfile` (see `Components.Users.federateProfile`/
`defederateProfile`) always act on whichever account's auth token made the
call, not any user id in the request (see
`backend/src/rpcs/federation/federate_profile.rs`) -- an admin editing this
list would only ever federate _their own_ profile, not `user`'s.
-}
isOwnProfile : Maybe AccountsPanel.Account -> User -> Bool
isOwnProfile maybeAccount user =
    case maybeAccount of
        Just account ->
            account.userId == user.id

        Nothing ->
            False


{-| The signed-in `AccountsPanel.Account`s (across every connected server,
see `Shared.AccountsPanel.Model.accounts`) that `user` could still federate
with: not `user`'s own account on `server` (that'd be federating with itself),
and not already listed in `user.federatedProfiles` -- mirrors the Tamagui
app's `federableAccounts` computation in
`frontends/tamagui/packages/app/features/user/federated_profiles.tsx`.
-}
federableAccounts : Shared.Model -> AccountsPanel.Server -> User -> List AccountsPanel.Account
federableAccounts shared server user =
    shared.accountsPanel.accounts
        |> List.filter
            (\account ->
                not (account.userId == user.id && account.server == server.frontendHost)
                    && not (List.any (\profile -> profile.host == account.server && profile.userId == account.userId) user.federatedProfiles)
            )


{-| `federableAccounts`, pulling `user`/`server` out of `model` itself --
what the update branches (which don't have a `User`/`Server` in hand directly)
need.
-}
federableAccountsFor : Shared.Model -> Model -> List AccountsPanel.Account
federableAccountsFor shared model =
    case ( model.resolver.status, serverAndAccount shared model ) of
        ( Resolver.Loaded user, Just ( server, _ ) ) ->
            federableAccounts shared server user

        _ ->
            []


{-| Keeps the "Link Account" `<select>`'s selection valid as the federated
profiles list changes: keeps `current` if it's still federable, otherwise
falls back to the first still-federable account (`Nothing` if there aren't
any) -- mirrors `resolveAddSelection`.
-}
resolveFederatedAddSelection : Maybe AccountsPanel.Account -> List AccountsPanel.Account -> Maybe AccountsPanel.Account
resolveFederatedAddSelection current available =
    case current of
        Just account ->
            if List.member account available then
                Just account

            else
                List.head available

        Nothing ->
            List.head available


{-| The `<select>` option value (and its reverse-lookup key, see
`FederatedProfileAddSelectionChanged`) for one federable `AccountsPanel.Account`
-- same `userId@host` shape as `federatedKey`, just over the other record type.
-}
accountKey : AccountsPanel.Account -> String
accountKey account =
    account.userId ++ "@" ++ account.server


{-| The "Link Account" `<select>`'s display label for one federable
`AccountsPanel.Account` -- unlike `accountKey`, leads with the human-readable
`username`, with the `userId` parenthesized for disambiguation (two accounts
on the same server could theoretically share nothing else at a glance).
-}
accountLabel : AccountsPanel.Account -> String
accountLabel account =
    account.username ++ "@" ++ account.server ++ " (" ++ account.userId ++ ")"


{-| Kicks off a fetch for every entry in `user.federatedProfiles` that isn't
already loading/loaded/failed -- grouping isn't needed the way
`Shared.StarredPostsPanel.kickOffFetches` groups by host, since a `User`
rarely lists more than a couple of federated accounts, and each is on its own
(likely not-yet-connected) server anyway.
-}
kickOffFederatedFetches : Shared.Model -> User -> Model -> ( Model, Effect Msg )
kickOffFederatedFetches shared user model =
    let
        pending =
            user.federatedProfiles
                |> List.filter (\account -> not (Dict.member (federatedKey account) model.federatedProfiles))

        ( newFederatedProfiles, effects ) =
            List.foldl (fetchFederated shared model.pageIsSecure) ( model.federatedProfiles, [] ) pending
    in
    ( { model | federatedProfiles = newFederatedProfiles }, Effect.batch effects )


{-| Either fetches `account`'s `User` directly (its server is already known --
see `AccountsPanel.serverForHost`) or first connects to that server anonymously
(mirrors `ConnectClicked`/`GotConnectResult` above), deferring the actual
`User` fetch to `GotFederatedServer`'s success branch.
-}
fetchFederated :
    Shared.Model
    -> Bool
    -> FederatedAccount
    -> ( Dict String FederatedProfileStatus, List (Effect Msg) )
    -> ( Dict String FederatedProfileStatus, List (Effect Msg) )
fetchFederated shared pageIsSecure account ( statuses, effects ) =
    let
        newStatuses =
            Dict.insert (federatedKey account) FederatedProfileLoading statuses
    in
    case AccountsPanel.serverForHost shared.accountsPanel.servers account.host of
        Just server ->
            ( newStatuses, effects ++ [ fetchFederatedUserEffect shared server account ] )

        Nothing ->
            ( newStatuses
            , effects
                ++ [ AccountsPanel.connectToServer pageIsSecure account.host
                        |> Task.attempt (GotFederatedServer account)
                        |> Effect.fromCmd
                   ]
            )


fetchFederatedUserEffect : Shared.Model -> AccountsPanel.Server -> FederatedAccount -> Effect Msg
fetchFederatedUserEffect shared _ account =
    Users.fetchUserById
        shared.accountsPanel
        ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts account.host |> Maybe.map .userId
        , account.host
        )
        account.userId
        |> Task.attempt (GotFederatedUser (federatedKey account))
        |> Effect.fromCmd


{-| The `model.federatedProfiles` key for one `User.federatedProfiles` entry --
mirrors `Shared.StarredPostsPanel.starKey`.
-}
federatedKey : FederatedAccount -> String
federatedKey account =
    account.userId ++ "@" ++ account.host


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map ResolverMsg (Resolver.subscriptions model.resolver)



-- VIEW


{-| Renders a `Lookup` (plus the server it's being looked up on) the way it'd
appear in a route: `username@server.com` for `ByUsername`, or
`id:theUserId@server.com` for `ById`.
-}
lookupToString : String -> Resolver.Lookup -> String
lookupToString targetHost lookup =
    case lookup of
        Resolver.ByUsername username ->
            username ++ "@" ++ targetHost

        Resolver.ById userId ->
            "id:" ++ userId ++ "@" ++ targetHost


{-| Before the `User` has loaded, falls back to whatever the route itself
already told us: the username for `ByUsername` (`Pages.Username_`), or else
"User <id>" for `ById` (`Pages.User.UserId_`, which has no username to show
yet).
-}
titleFor : Model -> String
titleFor model =
    case model.resolver.status of
        Resolver.Loaded user ->
            Users.titleName user

        _ ->
            case model.resolver.lookup of
                Resolver.ByUsername username ->
                    username

                Resolver.ById userId ->
                    "User " ++ userId


view : Shared.Model -> Model -> Html Msg
view shared model =
    ServerDependentView.view
        { hostname = model.resolver.targetHost
        , servers = shared.accountsPanel.servers
        , accounts = shared.accountsPanel.accounts
        , connectStatus = model.connectStatus
        , onConnectClicked = ConnectClicked
        , onEnableClicked = EnableClicked
        }
        (\server maybeAccount ->
            case model.resolver.status of
                Resolver.Loading ->
                    p [ class "profile-loading" ] [ text "Loading…" ]

                Resolver.Failed ->
                    p [ class "profile-error" ] [ text ("Couldn't load the profile for " ++ lookupToString model.resolver.targetHost model.resolver.lookup ++ ". Maybe they don't exist, or maybe you need to be logged in?") ]

                Resolver.Loaded user ->
                    profileDetail shared model server maybeAccount user
        )


profileDetail : Shared.Model -> Model -> AccountsPanel.Server -> Maybe AccountsPanel.Account -> User -> Html Msg
profileDetail shared model server maybeAccount user =
    let
        canEdit =
            canEditProfile maybeAccount user

        isAdmin =
            isAdminAccount maybeAccount

        baseHref =
            Users.profileHref shared.basePath
                shared.accountsPanel.mainFrontendHost
                server.frontendHost
                { userId = user.id, username = user.username }

        postsHref =
            baseHref ++ "/posts"

        followersHref =
            baseHref ++ "/followers"

        followingHref =
            baseHref ++ "/following"
    in
    div [ classes [ "profile-detail", server.frontendHost, "border-color-primary-anchor-50" ] ]
        [ div [ class "profile-header-row" ]
            [ div [ class "profile-header" ]
                [ UI.imageOrInitial [ "profile-avatar" ] user.username (Users.avatarUrl server maybeAccount user)
                , div [ class "profile-header-names" ]
                    [ usernameHeading user
                    , realNameView canEdit model.realNameEdit user
                    ]
                , otherServerIndicator shared server
                ]
            , Html.map FollowStatusAndButtonMsg (FollowStatusAndButton.view model.followStatusAndButton maybeAccount user)
            ]
        , federatedProfilesSection shared model server (isOwnProfile maybeAccount user) user
        , div [ class "profile-meta" ]
            [ text
                (Users.visibilityText user.visibility
                    ++ " · "
                    ++ Users.moderationText user.moderation
                    ++ (user.createdAt
                            |> Maybe.map (\ts -> " · Joined " ++ BrowserTimeZone.formatDate shared.browserTimeZone.zone (timestampToPosix ts))
                            |> Maybe.withDefault ""
                       )
                )
            ]
        , profileCounts postsHref followersHref followingHref user
        , bioSection canEdit user
        , permissionsSection isAdmin model.permissionsEdit user
        ]


{-| Whether the currently signed-in account on `user`'s own server (`maybeAccount`,
`profileDetail`'s own -- the enabled account for the target host, not
necessarily `user` itself) may edit `user`'s Real Name/bio: `user` themself,
or an `ADMIN` -- matches `backend/src/rpcs/users/update_user.rs`'s own
`self_update || admin` check (see `Shared.MarkdownPanel.resolve`'s `UserBio`
case, which re-verifies this server-side gate right before a bio save).
-}
canEditProfile : Maybe AccountsPanel.Account -> User -> Bool
canEditProfile maybeAccount user =
    case maybeAccount of
        Just account ->
            account.userId == user.id || List.member ADMIN account.permissions

        Nothing ->
            False


{-| Whether the currently signed-in account on this profile's server is an
`ADMIN` -- gates the permissions editor (`permissionsSection`), which only
`update_user.rs`'s own `admin` branch is ever allowed to change.
-}
isAdminAccount : Maybe AccountsPanel.Account -> Bool
isAdminAccount maybeAccount =
    case maybeAccount of
        Just account ->
            List.member ADMIN account.permissions

        Nothing ->
            False


{-| A user's username (plus Admin/Run Bots badges, if applicable -- see
`Components.Authors.badges`) exactly as it appears atop their profile page --
factored out of `profileDetail` since `nameHeader` (below) also needs it,
unadorned by any edit affordance, so this itself stays `Html msg`-polymorphic.
Also used directly by `Components.Pages.PostsPage` as a no-avatar fallback for
its "Posts | &lt;name&gt;" heading when the author's server isn't currently
known/enabled (so there's no `AccountsPanel.Server` to resolve an avatar
against).
-}
usernameHeading : User -> Html msg
usernameHeading user =
    h1 [ class "profile-username" ]
        (text user.username :: Authors.badges user)


{-| "@ &lt;server logo/name&gt;", shown to the right of the username/real
name/badges whenever this profile's own server (`server`, i.e. the target
host actually serving the profile) isn't `mainFrontendHost` -- lets a viewer
browsing a federated/other-server profile tell at a glance which server it
actually lives on. The "@" is its own muted, slightly-smaller-than-the-username
span; the logo/name reuses `AccountsPanel.serverNameAndLogo`'s `RegularServerLogo`
style, the same one `UI.homeLinkContent` uses for the Home button, just without
that button's nav-specific enlarging CSS.
-}
otherServerIndicator : Shared.Model -> AccountsPanel.Server -> Html msg
otherServerIndicator shared server =
    if server.frontendHost == shared.accountsPanel.mainFrontendHost then
        text ""

    else
        div [ class "profile-other-server" ]
            [ span [ class "profile-other-server-at" ] [ text "@" ]
            , AccountsPanel.serverNameAndLogo server AccountsPanel.RegularServerLogo
            ]


{-| The read-only "name area" atop a profile page -- `usernameHeading` plus
the Real Name, if set, with none of `realNameView`'s edit affordance (there's
no viewer/edit state to check outside of `Components.Pages.UserProfilePage`
itself). Used by `Components.Pages.PostsPage` for its "Posts | &lt;name&gt;"
heading on a user's own posts page (`Pages.Username_.Posts`/
`Pages.User.UserId_.Posts`).
-}
nameHeader : AccountsPanel.Server -> Maybe AccountsPanel.Account -> User -> Html msg
nameHeader server maybeAccount user =
    div [ class "profile-header" ]
        [ UI.imageOrInitial [ "profile-avatar" ] user.username (Users.avatarUrl server maybeAccount user)
        , div [ class "profile-header-names" ]
            [ usernameHeading user
            , if String.isEmpty (String.trim user.realName) then
                text ""

              else
                div [ class "profile-real-name-display" ]
                    [ span [ class "profile-real-name" ] [ text user.realName ] ]
            ]
        ]



-- div [ class "profile-header-names" ]
--     [ usernameHeading user
--     , if String.isEmpty (String.trim user.realName) then
--         text ""
--       else
--         div [ class "profile-real-name-display" ]
--             [ span [ class "profile-real-name" ] [ text user.realName ] ]
--     ]


{-| The Real Name line -- plain text (plus an Edit button, if `canEdit`) when
`model.realNameEdit == Nothing`, or an inline input/Save/Cancel form while
being edited. Shown (with just the Edit button, no text) even when `user`
has no Real Name yet, so `canEdit` viewers can add one.
-}
realNameView : Bool -> Maybe RealNameEdit -> User -> Html Msg
realNameView canEdit maybeEdit user =
    case maybeEdit of
        Just edit ->
            div [ class "profile-real-name-edit" ]
                [ input
                    [ class "profile-real-name-input"
                    , value edit.input
                    , onInput RealNameInputChanged
                    , placeholder "Real Name"
                    ]
                    []
                , editSaveButton RealNameSaveClicked edit.status
                , editCancelButton RealNameCancelClicked edit.status
                , editErrorView edit.status
                ]

        Nothing ->
            if String.isEmpty (String.trim user.realName) && not canEdit then
                text ""

            else
                div [ class "profile-real-name-display" ]
                    [ if String.isEmpty (String.trim user.realName) then
                        text ""

                      else
                        span [ class "profile-real-name" ] [ text user.realName ]
                    , if canEdit then
                        button [ class "profile-edit-button", onClick RealNameEditClicked ] [ text "Edit" ]

                      else
                        text ""
                    ]


{-| The bio, rendered as Markdown, with an Edit button (opening the shared
`Shared.MarkdownPanel` panel via `BioEditClicked`, targeting `MarkdownPanel.UserBio`)
if `canEdit` -- shown (with just the Edit button) even with no bio yet, so
`canEdit` viewers can add one.
-}
bioSection : Bool -> User -> Html Msg
bioSection canEdit user =
    if String.isEmpty (String.trim user.bio) && not canEdit then
        text ""

    else
        div [ class "profile-bio-section" ]
            [ if canEdit then
                button [ class "profile-edit-button", onClick BioEditClicked ] [ text "Edit" ]

              else
                text ""
            , if String.isEmpty (String.trim user.bio) then
                text ""

              else
                Markdown.view [ class "profile-bio" ] user.bio
            ]


editSaveButton : Msg -> SubmitStatus -> Html Msg
editSaveButton onSave status =
    button
        [ class "profile-edit-save", onClick onSave, disabled (status == Submitting) ]
        [ text
            (if status == Submitting then
                "Saving…"

             else
                "Save"
            )
        ]


editCancelButton : Msg -> SubmitStatus -> Html Msg
editCancelButton onCancel status =
    button [ class "profile-edit-cancel", onClick onCancel, disabled (status == Submitting) ] [ text "Cancel" ]


editErrorView : SubmitStatus -> Html msg
editErrorView status =
    case status of
        SubmitFailed err ->
            div [ class "profile-edit-error" ] [ text err ]

        _ ->
            text ""


{-| `postsHref`/`followersHref`/`followingHref` (see `profileDetail`) link the
"Posts"/"Followers"/"Following" counts to `Pages.Username_.Posts`/
`Pages.Username_.Followers`/`Pages.Username_.Following` (or their
`Pages.User.UserId_.*` equivalents) -- the other counts have no page of their
own (yet) to link to.
-}
profileCounts : String -> String -> String -> User -> Html Msg
profileCounts postsHref followersHref followingHref user =
    let
        counts =
            [ ( "Followers", user.followerCount, Just followersHref )
            , ( "Following", user.followingCount, Just followingHref )
            , ( "Groups", user.groupCount, Nothing )
            , ( "Posts", user.postCount, Just postsHref )
            , ( "Responses", user.responseCount, Nothing )
            , ( "Events", user.eventCount, Nothing )
            ]
                |> List.filterMap (\( label, maybeCount, maybeHref ) -> maybeCount |> Maybe.map (\c -> ( label, c, maybeHref )))
    in
    if List.isEmpty counts then
        text ""

    else
        div [ class "profile-counts" ] (counts |> List.map profileCountView)


profileCountView : ( String, Int, Maybe String ) -> Html Msg
profileCountView ( label, count, maybeHref ) =
    let
        content =
            [ div [ class "profile-count-value" ] [ text (String.fromInt count) ]
            , div [ class "profile-count-label" ] [ text label ]
            ]
    in
    case maybeHref of
        Just linkHref ->
            a [ class "profile-count", href linkHref ] content

        Nothing ->
            div [ class "profile-count" ] content


{-| The Permissions list -- plain badges (plus an Edit button, if `isAdmin`)
when `permissionsEdit == Nothing`, or the removable-badges + Add Permission +
Save/Cancel editor while being edited by an admin. Shown (with just the Edit
button) even with no permissions yet, so an admin can grant the first one.
-}
permissionsSection : Bool -> Maybe PermissionsEdit -> User -> Html Msg
permissionsSection isAdmin maybeEdit user =
    case maybeEdit of
        Just edit ->
            div [ class "profile-permissions-edit" ]
                [ h2 [ class "profile-section-title" ] [ text "Permissions" ]
                , div [ class "profile-permissions" ] (edit.pending |> List.map permissionEditBadge)
                , div [ class "profile-permissions-add" ]
                    [ select [ onInput PermissionAddSelectionChanged ]
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
                        [ class "profile-permission-add-button"
                        , onClick PermissionAddClicked
                        , disabled (edit.addSelection == Nothing)
                        ]
                        [ text "Add Permission" ]
                    ]
                , div [ class "profile-permissions-actions" ]
                    [ editSaveButton PermissionsSaveClicked edit.status
                    , editCancelButton PermissionsCancelClicked edit.status
                    ]
                , editErrorView edit.status
                ]

        Nothing ->
            if List.isEmpty user.permissions && not isAdmin then
                text ""

            else
                div [ class "profile-permissions-view" ]
                    [ h2 [ class "profile-section-title" ] [ text "Permissions" ]
                    , div [ class "profile-permissions" ]
                        (user.permissions
                            |> List.map (\permission -> span [ class "profile-permission-badge" ] [ text (Users.permissionText permission) ])
                        )
                    , if isAdmin then
                        button [ class "profile-edit-button", onClick PermissionsEditClicked ] [ text "Edit" ]

                      else
                        text ""
                    ]


permissionEditBadge : Permission -> Html Msg
permissionEditBadge permission =
    span [ class "profile-permission-badge editable" ]
        [ text (Users.permissionText permission)
        , button
            [ class "profile-permission-remove"
            , onClick (PermissionRemoveClicked permission)
            , title ("Remove " ++ Users.permissionText permission)
            ]
            [ text "×" ]
        ]


{-| The Federated Profiles list -- read-only links (each upgraded with a
`crossCheckBadge` once loaded, see `federatedProfileLink`) when
`federatedProfilesEdit == Nothing`, plus (only for `canEdit`, i.e.
`isOwnProfile`) an Edit button; while being edited, each entry additionally
gets a remove (×) button, and a "Link Account" `<select>`+button lets the
owner federate any of their other signed-in accounts (see
`federableAccounts`) that isn't listed yet. Shown (with just the Edit button)
even with no federated profiles yet, so the owner can add the first one.
-}
federatedProfilesSection : Shared.Model -> Model -> AccountsPanel.Server -> Bool -> User -> Html Msg
federatedProfilesSection shared model server canEdit user =
    if List.isEmpty user.federatedProfiles && not canEdit then
        text ""

    else
        div [ class "profile-federated" ]
            (h2 [ class "profile-section-title" ] [ text "Federated Profiles" ]
                :: (user.federatedProfiles
                        |> List.map (federatedProfileEntry shared model server user model.federatedProfilesEdit)
                   )
                ++ federatedProfilesEditControls shared model server canEdit user
            )


{-| One federated profile entry: its `federatedProfileLink`, plus (only while
`maybeEdit` is `Just`, i.e. the owner is actively editing) a remove (×)
button that fires `FederatedProfileRemoveClicked` -- mirrors
`permissionEditBadge`, except the remove button sits alongside the link
rather than inside a single badge, since the link itself needs to stay
clickable.
-}
federatedProfileEntry : Shared.Model -> Model -> AccountsPanel.Server -> User -> Maybe FederatedProfilesEdit -> FederatedAccount -> Html Msg
federatedProfileEntry shared model server user maybeEdit account =
    div [ class "profile-federated-entry" ]
        (federatedProfileLink shared model server user account
            :: (case maybeEdit of
                    Just edit ->
                        [ button
                            [ class "profile-federated-remove"
                            , onClick (FederatedProfileRemoveClicked account)
                            , title ("Unlink " ++ account.userId ++ "@" ++ account.host)
                            , disabled (edit.status == Submitting)
                            ]
                            [ text "×" ]
                        ]

                    Nothing ->
                        []
               )
        )


{-| The Edit button (`federatedProfilesEdit == Nothing`) or the "Link
Account" `<select>`+button/Done/error (while editing) -- `[]` entirely
when `not canEdit`, same "no controls for a viewer who can't act" shape as
`permissionsSection`'s admin gate.
-}
federatedProfilesEditControls : Shared.Model -> Model -> AccountsPanel.Server -> Bool -> User -> List (Html Msg)
federatedProfilesEditControls shared model server canEdit user =
    if not canEdit then
        []

    else
        case model.federatedProfilesEdit of
            Just edit ->
                let
                    available =
                        federableAccounts shared server user
                in
                [ div [ class "profile-federated-add" ]
                    (if List.isEmpty available then
                        [ span [ class "profile-federated-add-empty" ] [ text "No other linkable accounts available." ] ]

                     else
                        [ select [ onInput FederatedProfileAddSelectionChanged ]
                            (available
                                |> List.map
                                    (\account ->
                                        option
                                            [ value (accountKey account)
                                            , selected (edit.addSelection == Just account)
                                            ]
                                            [ text (accountLabel account) ]
                                    )
                            )
                        , button
                            [ class "profile-permission-add-button"
                            , onClick FederatedProfileAddClicked
                            , disabled (edit.addSelection == Nothing || edit.status == Submitting)
                            ]
                            [ text "Link Account" ]
                        ]
                    )
                , div [ class "profile-permissions-actions" ]
                    [ button [ class "profile-edit-cancel", onClick FederatedProfilesDoneClicked ] [ text "Done" ]
                    ]
                , editErrorView edit.status
                ]

            Nothing ->
                [ button [ class "profile-edit-button", onClick FederatedProfilesEditClicked ] [ text "Edit" ] ]


{-| One federated profile's link/button -- always links out via
`Users.userIdHref` (the "still just a link" baseline behavior), but once its
`User` has actually loaded (see `kickOffFederatedFetches`), it's upgraded to
show that user's avatar, their username on that server, their real name (if
set), a `crossCheckBadge`, and -- via `federatedServer`'s CSS class, see
`UI.EmittedStylesheet` -- that server's own colors.
-}
federatedProfileLink : Shared.Model -> Model -> AccountsPanel.Server -> User -> FederatedAccount -> Html Msg
federatedProfileLink shared model server user account =
    let
        maybeFederatedServer =
            AccountsPanel.serverForHost shared.accountsPanel.servers account.host

        colorClasses =
            case maybeFederatedServer of
                Just federatedServer ->
                    [ hostnameToCSSClass federatedServer.frontendHost, "background-color-primary" ]

                Nothing ->
                    []
    in
    a
        [ classes ("profile-federated-link" :: colorClasses)
        , href
            (Users.userIdHref shared.basePath
                shared.accountsPanel.mainFrontendHost
                account.host
                account.userId
            )
        ]
        (case ( maybeFederatedServer, Dict.get (federatedKey account) model.federatedProfiles ) of
            ( Just federatedServer, Just (FederatedProfileLoaded federatedUser) ) ->
                [ UI.imageOrInitial [ "profile-federated-avatar" ]
                    federatedUser.username
                    (Users.avatarUrl federatedServer
                        (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts account.host)
                        federatedUser
                    )
                , div [ class "profile-federated-names" ]
                    [ span [ class "profile-federated-username" ] [ text (federatedUser.username ++ "@" ++ account.host) ]
                    , if String.isEmpty (String.trim federatedUser.realName) then
                        text ""

                      else
                        span [ class "profile-federated-realname" ] [ text federatedUser.realName ]
                    ]
                , crossCheckBadge server user federatedUser
                ]

            _ ->
                [ text (account.userId ++ "@" ++ account.host) ]
        )


{-| ✅ if `federatedUser` (fetched from its own server) also lists `user`
back -- one of its own `federatedProfiles` names `server.frontendHost`/
`user.id` -- confirming the two profiles actually link to _each other_, not
just this one linking out. ⚠️ otherwise (e.g. still pending on the other
side, or never confirmed).
-}
crossCheckBadge : AccountsPanel.Server -> User -> User -> Html Msg
crossCheckBadge server user federatedUser =
    let
        reciprocated =
            List.any (\account -> account.host == server.frontendHost && account.userId == user.id)
                federatedUser.federatedProfiles
    in
    if reciprocated then
        span [ class "profile-federated-badge", title "Both profiles link to each other" ] [ text "✅" ]

    else
        span [ class "profile-federated-badge", title "This profile doesn't link back" ] [ text "⚠️" ]
