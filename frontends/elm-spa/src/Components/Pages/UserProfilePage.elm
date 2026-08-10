module Components.Pages.UserProfilePage exposing
    ( Model
    , Msg
    , fromShared
    , init
    , subscriptions
    , titleFor
    , update
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

import Browser.Navigation
import Components.EventSyncSources as EventSyncSources
import Components.Markdown as Markdown
import Components.Pages.EventsPage as EventsPage
import Components.Pages.PostsPage as PostsPage
import Components.ServerDependentView as ServerDependentView
import Components.Users as Users
import Components.Users.FollowStatusAndButton as FollowStatusAndButton
import Components.Users.ProfileHeading as ProfileHeading
import Components.Users.Resolver as Resolver
import Dict exposing (Dict)
import Effect exposing (Effect)
import Gen.Route
import Grpc
import Html exposing (Html, a, button, div, h2, h3, input, option, p, select, span, text)
import Html.Attributes exposing (class, disabled, href, placeholder, selected, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Proto.Google.Protobuf
import Proto.Jonline exposing (EventSyncSource, FederatedAccount, User, defaultEventSyncSource, defaultMediaReference)
import Proto.Jonline.EventSyncSource.Configuration as Configuration
import Proto.Jonline.Permission exposing (Permission(..))
import Proto.Jonline.PostContext exposing (PostContext(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.Breadcrumbs as Breadcrumbs
import Shared.Conversions as Conversions exposing (timestampToPosix)
import Shared.MarkdownPanel as MarkdownPanel
import Shared.MyMediaPanel as MyMediaPanel
import Shared.Time as SharedTime
import Task
import UI
import UI.Classes exposing (classes, hostnameToCSSClass)
import UI.HtmlEvents exposing (stopPropagationAndPreventDefaultOnClick)


type alias Model =
    { resolver : Resolver.Model
    , connectStatus : ServerDependentView.ConnectStatus
    , pageIsSecure : Bool
    , federatedProfiles : Dict String FederatedProfileStatus
    , realNameEdit : Maybe RealNameEdit
    , avatarEdit : Maybe AvatarEdit
    , permissionsEdit : Maybe PermissionsEdit
    , federatedProfilesEdit : Maybe FederatedProfilesEdit
    , eventSyncSources : EventSyncSourcesState
    , followStatusAndButton : FollowStatusAndButton.Model

    -- Embedded, row-laid-out `EventsPage`/search-box-less `PostsPage` copies of this
    -- user's own events/posts, mirroring `Pages.Home_.Model`'s own `posts`/`events`
    -- pair -- see `view`'s own doc. Both start `Nothing` (there's no resolved `User`
    -- to filter by yet) and are only ever initialized once, the first time `resolver`
    -- reports `Resolver.Loaded` (see `updateInner`'s `ResolverMsg` branch) -- a later
    -- refetch (e.g. after a follow/unfollow) re-`Loaded`s `resolver` again, but must
    -- *not* re-`init` either of these, which would wipe out their own in-progress
    -- search text/scroll position for no reason.
    , posts : Maybe PostsPage.Model
    , events : Maybe EventsPage.Model
    , navKey : Browser.Navigation.Key
    , path : String
    , query : Dict String String
    }


type Msg
    = ResolverMsg Resolver.Msg
    | PostsMsg PostsPage.Msg
    | EventsMsg EventsPage.Msg
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
    | AvatarEditClicked
    | AvatarRemoveClicked
    | AvatarCancelClicked
    | AvatarSaveClicked
    | GotAvatarSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, User ))
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
    | GotEventSyncSourcesFetchResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetEventSyncSourcesResponse ))
    | EventSyncSourceRowUrlChanged EventSyncSource String
    | EventSyncSourceRowIntervalChanged EventSyncSource Int
    | EventSyncSourceRowSaveClicked EventSyncSource
    | EventSyncSourceRowRefreshClicked EventSyncSource
    | GotEventSyncSourceRowSaveResult String (Result Grpc.Error ( Maybe AccountsPanel.Msg, EventSyncSource ))
    | EventSyncSourceAddUrlChanged String
    | EventSyncSourceAddIntervalChanged Int
    | EventSyncSourceAddClicked
    | GotEventSyncSourceAddResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, EventSyncSource ))
    | EventSyncSourceDeleteClicked EventSyncSource Bool
    | DeleteUserClicked


{-| The fetch state of one entry in a loaded `User.federatedProfiles`, keyed
by `federatedKey` -- mirrors `Shared.StarredPanel.PostFetchStatus`, minus
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


{-| What `AvatarSaveClicked` should do to `user.avatar` (see `applyAvatarChoice`) --
`AvatarUnchanged` leaves it alone (the default, entering edit mode), `AvatarChosen
mediaId` overwrites it with that media (set by picking a tile in the shared
`Shared.MyMediaPanel`, opened in `SingleSelect` mode -- see `AvatarEditClicked`
and the `SharedMsg` handling of `MyMediaPanel.MediaItemClicked`), and `AvatarRemoved`
(the "✕" button, see `avatarView`) clears it entirely.
-}
type AvatarChoice
    = AvatarUnchanged
    | AvatarChosen String
    | AvatarRemoved


{-| Live only while the avatar (see `Model.avatarEdit`) is being edited --
mirrors `RealNameEdit`, except there's no in-progress text input, just
`choice` (see `AvatarChoice`), driven by taps on the avatar itself/its "✕"
button/the `Shared.MyMediaPanel` chooser this opens rather than typing.
-}
type alias AvatarEdit =
    { choice : AvatarChoice
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


{-| The fetch state of `Model.eventSyncSources.sources` -- mirrors
`FederatedProfileStatus`'s shape, just for the one list rather than one entry
per federated profile.
-}
type EventSyncFetchStatus
    = EventSyncSourcesNotFetched
    | EventSyncSourcesFetching
    | EventSyncSourcesFetchFailed String
    | EventSyncSourcesFetched


{-| A row's in-progress edit -- created (from the source's own current
values, see `eventSyncRowEditFor`) the moment the URL/interval input is first
touched, and dropped again once a save actually lands (see
`GotEventSyncSourceRowSaveResult`). A row with no entry here just renders
straight from its `EventSyncSource` and shows "Refresh" rather than "Save"
(see `eventSyncSourceIsDirty`).
-}
type alias EventSyncRowEdit =
    { pendingUrl : String
    , pendingIntervalSeconds : Int
    , status : SubmitStatus
    }


type alias EventSyncAddForm =
    { url : String
    , intervalSeconds : Int
    , status : SubmitStatus
    }


defaultEventSyncAddForm : EventSyncAddForm
defaultEventSyncAddForm =
    { url = "", intervalSeconds = 3600, status = Idle }


{-| The "Event Sync Sources" section's own state -- basic CRUD over
`EventSyncSource` (`protos/events.proto`) for this profile's own user (or,
for an Admin viewing someone else's profile, that user's sources). Bundled
into its own record (rather than flattened into `Model` alongside
`realNameEdit`/`permissionsEdit`/etc) since, unlike those, it needs several
fields at once (`status`/`sources`/`rowEdits`/`addForm`) that all change
together.

Used to live in `Shared.Model` (`Shared.EventSyncSourcesPanel`, since
removed) despite being shown only here, on this one page -- solely because
the delete confirmation dialog (`Shared.DeleteConfirmation`) is a global
overlay that can only resolve back into a Shared-owned submodel. Deletes now
follow the same shape `ConfirmPostDelete`/`ConfirmEventDelete` already used:
`Shared.update`'s `ConfirmDelete` fires the `DeleteEventSyncSource` RPC
directly (see `Shared.ConfirmEventSyncSourceDelete`), and its result
(`Shared.GotEventSyncSourceDeleteResult`) is forwarded back here like any
other `Shared.Msg` (see `updateInner`'s `SharedMsg` branch) -- so this state
has no reason to live anywhere but here. Unlike that old module, there's no
`targetHost`/`viewedUserId` staleness guard: this `Model` (unlike a
Shared-owned singleton) never outlives one profile.

-}
type alias EventSyncSourcesState =
    { status : EventSyncFetchStatus
    , sources : List EventSyncSource
    , rowEdits : Dict String EventSyncRowEdit
    , addForm : EventSyncAddForm
    }


initEventSyncSources : EventSyncSourcesState
initEventSyncSources =
    { status = EventSyncSourcesNotFetched, sources = [], rowEdits = Dict.empty, addForm = defaultEventSyncAddForm }


{-| `pageIsSecure` is `Shared.AccountsPanel.isSecure req` from the calling
page's own `Request` -- needed for `ConnectClicked` (see `AccountsPanel.connectToServer`),
but not otherwise derivable from `Shared.Model` alone. `navKey`/`path`/`query` are
the calling page's own `Request.With Params`' `key`/`url.path`/`query` -- kept around
(rather than threaded through some other way) so the embedded `PostsPage`/`EventsPage`
copies (see `Model.posts`/`Model.events`) can be `init`ed later, once `resolver` actually
resolves a `User` to filter them by -- mirrors `PostsPage.init`/`EventsPage.init`'s own
`navKey`/`path`/`query` params exactly.
-}
init : Shared.Model -> Bool -> String -> Resolver.Lookup -> Browser.Navigation.Key -> String -> Dict String String -> ( Model, Effect Msg )
init shared pageIsSecure targetHost lookup navKey path query =
    let
        ( resolverModel, resolverEffect ) =
            Resolver.init shared targetHost lookup

        model =
            { resolver = resolverModel
            , connectStatus = ServerDependentView.NotConnected
            , pageIsSecure = pageIsSecure
            , federatedProfiles = Dict.empty
            , realNameEdit = Nothing
            , avatarEdit = Nothing
            , permissionsEdit = Nothing
            , federatedProfilesEdit = Nothing
            , eventSyncSources = initEventSyncSources
            , followStatusAndButton = FollowStatusAndButton.init
            , posts = Nothing
            , events = Nothing
            , navKey = navKey
            , path = path
            , query = query
            }
    in
    ( model
      -- Closes the Accounts Panel if it happened to be open -- landing on a
      -- profile page always shows the info an open panel would otherwise
      -- duplicate (see `Components.Pages.ServerInformationPage.init`, same
      -- reasoning).
    , Effect.batch
        [ Effect.map ResolverMsg resolverEffect
        , Effect.fromShared Shared.CloseAllPanels
        , setBreadcrumbsHost shared model
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map ResolverMsg (Resolver.subscriptions model.resolver)
        , model.posts |> Maybe.map (PostsPage.subscriptions >> Sub.map PostsMsg) |> Maybe.withDefault Sub.none
        , model.events |> Maybe.map (EventsPage.subscriptions >> Sub.map EventsMsg) |> Maybe.withDefault Sub.none
        ]



-- UPDATE


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


{-| `update`, plus keeping `Shared.Breadcrumbs` pointed at this profile's own
`FromServerHost targetHost` -- mirrors `Pages.Home_.setBreadcrumbsHost`
(reissued after every `update`, a no-op once already in sync via the same
equality check), except keyed to `model.resolver.targetHost` rather than
`mainFrontendHost`, since a profile page (unlike the home feed) always
belongs to one specific server. `targetHost` is already known from the route
by `init` (see `Pages.User.UserId_.init`/`Pages.Username_.init`), so this
covers both the very first paint and any later host change (e.g.
`ConnectClicked` connecting a not-yet-connected `targetHost`).

This is the _only_ thing here allowed to touch `Shared.Breadcrumbs` --
`model.posts`/`model.events` are embedded `PostsPage`/`EventsPage` copies
(both `init`ed with `embeddedPage = True`), which leaves their own
`setBreadcrumbsRoot` a permanent no-op (see those docs).
Before that, both copies independently asserted their own root (`FromUser
user`) on every `update`, including every animation tick from
`model.events.eventAnimations` -- fighting this function's own
`FromServerHost` assertion right back on the very next tick, a continuous
flicker between the two roots.

-}
update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    let
        ( newModel, effect ) =
            updateInner shared msg model
    in
    ( newModel, Effect.batch [ effect, setBreadcrumbsHost shared newModel ] )


setBreadcrumbsHost : Shared.Model -> Model -> Effect Msg
setBreadcrumbsHost shared model =
    let
        host =
            model.resolver.targetHost
    in
    if shared.breadcrumbs.root == Just (Breadcrumbs.FromServerHost host) then
        Effect.none

    else
        Effect.fromShared (Shared.BreadcrumbsMsg (Breadcrumbs.SetRoot (Breadcrumbs.FromServerHost host) host []))


updateInner : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
updateInner shared msg model =
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

                        -- Only fetched for the caller's own profile or an
                        -- Admin viewing someone else's (matches
                        -- `get_event_sync_sources.rs`'s own gate) -- no point
                        -- firing a request every other visitor's just going
                        -- to get a `PermissionDenied` back from.
                        maybeAccount =
                            AccountsPanel.enabledAccountForServer shared.accounts.accounts newResolver.targetHost

                        ( eventSyncFetchedModel, eventSyncFetchEffect ) =
                            if canEditProfile maybeAccount user then
                                fetchEventSyncSources shared newResolver.targetHost user.id federatedModel

                            else
                                ( federatedModel, Effect.none )

                        -- Only ever `init`ed once -- see `Model.posts`/`Model.events`'
                        -- own doc for why a later refetch (which re-fires this same
                        -- `Loaded` case) must leave an already-`Just` copy alone.
                        ( postsInitedModel, postsInitEffect ) =
                            case eventSyncFetchedModel.posts of
                                Just _ ->
                                    ( eventSyncFetchedModel, Effect.none )

                                Nothing ->
                                    let
                                        ( postsModel, postsEffect ) =
                                            PostsPage.init shared (Just ( newResolver.targetHost, user )) eventSyncFetchedModel.navKey eventSyncFetchedModel.path eventSyncFetchedModel.query True
                                    in
                                    ( { eventSyncFetchedModel | posts = Just postsModel }, Effect.map PostsMsg postsEffect )

                        ( eventsInitedModel, eventsInitEffect ) =
                            case postsInitedModel.events of
                                Just _ ->
                                    ( postsInitedModel, Effect.none )

                                Nothing ->
                                    let
                                        ( eventsModel, eventsEffect ) =
                                            EventsPage.init shared (Just ( newResolver.targetHost, user )) postsInitedModel.navKey postsInitedModel.path postsInitedModel.query True
                                    in
                                    ( { postsInitedModel | events = Just eventsModel }, Effect.map EventsMsg eventsEffect )
                    in
                    ( eventsInitedModel
                    , Effect.batch
                        [ Effect.map ResolverMsg resolverEffect
                        , federatedEffect
                        , eventSyncFetchEffect
                        , postsInitEffect
                        , eventsInitEffect
                        ]
                    )

                _ ->
                    ( newModel, Effect.map ResolverMsg resolverEffect )

        PostsMsg subMsg ->
            case model.posts of
                Just postsModel ->
                    let
                        ( newPosts, postsEffect ) =
                            PostsPage.update shared subMsg postsModel

                        -- Keeps `EventsPage`'s own search box (the only one actually
                        -- shown, see `view`'s `showSearchRow = False`) in sync with
                        -- this hidden copy's `searchText` -- mirrors
                        -- `Pages.Home_.update`'s identical `PostsMsg`/`EventsMsg`
                        -- cross-sync exactly, just over `Maybe`-wrapped models.
                        ( syncedEvents, syncEffect ) =
                            case model.events of
                                Just eventsModel ->
                                    if newPosts.searchText /= eventsModel.searchText then
                                        EventsPage.update shared (EventsPage.searchTextChanged newPosts.searchText) eventsModel
                                            |> Tuple.mapFirst Just

                                    else
                                        ( model.events, Effect.none )

                                Nothing ->
                                    ( model.events, Effect.none )
                    in
                    ( { model | posts = Just newPosts, events = syncedEvents }
                    , Effect.batch [ Effect.map PostsMsg postsEffect, Effect.map EventsMsg syncEffect ]
                    )

                Nothing ->
                    ( model, Effect.none )

        EventsMsg subMsg ->
            case model.events of
                Just eventsModel ->
                    let
                        ( newEvents, eventsEffect ) =
                            EventsPage.update shared subMsg eventsModel

                        ( syncedPosts, syncEffect ) =
                            case model.posts of
                                Just postsModel ->
                                    if newEvents.searchText /= postsModel.searchText then
                                        PostsPage.update shared (PostsPage.searchTextChanged newEvents.searchText) postsModel
                                            |> Tuple.mapFirst Just

                                    else
                                        ( model.posts, Effect.none )

                                Nothing ->
                                    ( model.posts, Effect.none )
                    in
                    ( { model | events = Just newEvents, posts = syncedPosts }
                    , Effect.batch [ Effect.map EventsMsg eventsEffect, Effect.map PostsMsg syncEffect ]
                    )

                Nothing ->
                    ( model, Effect.none )

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

                        -- The shared `Shared.MyMediaPanel` chooser (opened by
                        -- `AvatarEditClicked`) reports a tap this way -- see
                        -- `Shared.MyMediaPanel`'s own module doc on why this
                        -- forwarded `Shared.Msg`, not some closure/callback,
                        -- is what delivers the pick back here. Gated on
                        -- `avatarEdit` already being `Just` so an unrelated
                        -- Browse-mode tap (e.g. from the Accounts Panel)
                        -- elsewhere can't be mistaken for an avatar pick.
                        Shared.MyMediaPanelMsg (MyMediaPanel.MediaItemClicked mediaId) ->
                            ( { resolvedModel
                                | avatarEdit =
                                    resolvedModel.avatarEdit |> Maybe.map (\edit -> { edit | choice = AvatarChosen mediaId })
                              }
                            , Effect.none
                            )

                        -- A successful delete of an Event Sync Source (fired
                        -- directly from `Shared.update`'s `ConfirmDelete`,
                        -- see `Shared.ConfirmEventSyncSourceDelete`'s own
                        -- doc) can remove Events/EventInstances behind the
                        -- already-`init`ed `EventsPage` copy's back --
                        -- refresh it so the change shows up without a manual
                        -- page reload, and drop the source from this page's
                        -- own list. (A successful row Save/Refresh triggers
                        -- the same refresh directly from
                        -- `GotEventSyncSourceRowSaveResult` below, since that
                        -- request -- unlike a delete -- is fired from this
                        -- page's own `Msg`, not routed through `Shared`.)
                        Shared.GotEventSyncSourceDeleteResult id (Ok _) ->
                            let
                                es =
                                    resolvedModel.eventSyncSources

                                deletedModel =
                                    { resolvedModel | eventSyncSources = { es | sources = List.filter (\s -> s.id /= id) es.sources } }
                            in
                            refetchEvents shared deletedModel

                        -- This page's own `DeleteUserClicked` (via
                        -- `Shared.RequestDelete`/`Shared.ConfirmDelete`)
                        -- resolving successfully -- the profile being
                        -- viewed no longer exists, so navigate away, same
                        -- as `Pages.Post.PostId_`'s own
                        -- `Shared.GotPostDeleteResult` handling. Signing
                        -- out locally, if it was the viewer's own account
                        -- being deleted, happens in `Shared.update`'s own
                        -- handling of this same result, not here --
                        -- `Main.notifyPageOfSharedMsg` (which is what
                        -- delivers a top-level-originated `Shared.Msg` like
                        -- this one to a page) silently drops any *new*
                        -- `Shared.Msg` a page's own `SharedMsg` branch
                        -- forwards back in response, on the assumption
                        -- that only an echo of the incoming message itself
                        -- is ever forwarded that way -- see its own doc.
                        Shared.GotUserDeleteResult _ _ (Ok _) ->
                            ( resolvedModel
                            , Browser.Navigation.pushUrl resolvedModel.navKey (Gen.Route.toHref Gen.Route.Home_) |> Effect.fromCmd
                            )

                        _ ->
                            ( resolvedModel, Effect.none )

                -- Forwarded on into the embedded `PostsPage`/`EventsPage` copies (if
                -- already `init`ed) the same way `Pages.Home_.update`'s own `SharedMsg`
                -- branch does -- e.g. an `AccountsPanelMsg` re-fetches both against the
                -- newly (dis)connected/(dis)abled server. `Effect.partitionShared`
                -- drops each one's own echoed re-broadcast of `subMsg` (see
                -- `PostsPage.update`/`EventsPage.update`'s own `SharedMsg` branch,
                -- which unconditionally re-emits it) -- `resolverEffect` above is
                -- already the one canonical copy of that echo; keeping either of
                -- these too would apply the same `Shared.Msg` several times over in
                -- one pass, harmless for most but a net-zero no-op for a toggle (see
                -- `Pages.Home_`'s own doc comment for the full "can't open the
                -- Accounts Panel" story this mirrors).
                ( postsSyncedModel, postsSyncEffect ) =
                    case fetchedModel.posts of
                        Just postsModel ->
                            let
                                ( newPosts, postsEffectRaw ) =
                                    PostsPage.update shared (PostsPage.fromShared subMsg) postsModel

                                ( _, postsEffect ) =
                                    Effect.partitionShared postsEffectRaw
                            in
                            ( { fetchedModel | posts = Just newPosts }, Effect.map PostsMsg postsEffect )

                        Nothing ->
                            ( fetchedModel, Effect.none )

                ( eventsSyncedModel, eventsSyncEffect ) =
                    case postsSyncedModel.events of
                        Just eventsModel ->
                            let
                                ( newEvents, eventsEffectRaw ) =
                                    EventsPage.update shared (EventsPage.fromShared subMsg) eventsModel

                                ( _, eventsEffect ) =
                                    Effect.partitionShared eventsEffectRaw
                            in
                            ( { postsSyncedModel | events = Just newEvents }, Effect.map EventsMsg eventsEffect )

                        Nothing ->
                            ( postsSyncedModel, Effect.none )
            in
            ( eventsSyncedModel, Effect.batch [ resolverEffect, fetchEffect, postsSyncEffect, eventsSyncEffect ] )

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
                    , Users.updateUser shared.accounts ( Just account.userId, server.frontendHost ) user.id (\freshUser -> { freshUser | realName = edit.input })
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

        AvatarEditClicked ->
            case model.resolver.status of
                Resolver.Loaded user ->
                    ( { model
                        | avatarEdit =
                            -- Preserves an already-in-progress `choice`/`status`
                            -- rather than resetting it -- this same message
                            -- doubles as "re-open the picker" (see `avatarView`'s
                            -- tap-the-avatar-while-editing handler), which
                            -- shouldn't discard whatever's already been picked.
                            case model.avatarEdit of
                                Just edit ->
                                    Just edit

                                Nothing ->
                                    Just { choice = AvatarUnchanged, status = Idle }
                      }
                    , Effect.fromShared
                        (Shared.MyMediaPanelMsg
                            (MyMediaPanel.Open
                                (Just (MyMediaPanel.SingleSelect { imagesOnly = True, initialSelection = user.avatar }))
                                model.resolver.targetHost
                            )
                        )
                    )

                _ ->
                    ( model, Effect.none )

        AvatarRemoveClicked ->
            ( { model | avatarEdit = model.avatarEdit |> Maybe.map (\edit -> { edit | choice = AvatarRemoved }) }
            , Effect.none
            )

        AvatarCancelClicked ->
            ( { model | avatarEdit = Nothing }
            , Effect.fromShared (Shared.MyMediaPanelMsg MyMediaPanel.CloseClicked)
            )

        AvatarSaveClicked ->
            case ( model.resolver.status, model.avatarEdit, serverAndAccount shared model ) of
                ( Resolver.Loaded user, Just edit, Just ( server, account ) ) ->
                    ( { model | avatarEdit = Just { edit | status = Submitting } }
                    , Users.updateUser shared.accounts ( Just account.userId, server.frontendHost ) user.id (applyAvatarChoice edit.choice)
                        |> Task.attempt GotAvatarSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotAvatarSaveResult (Ok ( maybeAccountsPanelMsg, updatedUser )) ->
            ( { model | resolver = withResolvedUser updatedUser model.resolver, avatarEdit = Nothing }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotAvatarSaveResult (Err err) ->
            ( { model
                | avatarEdit =
                    model.avatarEdit |> Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })
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
                    , Users.updateUser shared.accounts ( Just account.userId, server.frontendHost ) user.id (\freshUser -> { freshUser | permissions = edit.pending })
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
                            , Users.federateProfile shared.accounts ( Just account.userId, server.frontendHost ) { host = selected.server, userId = selected.userId }
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
                    , Users.defederateProfile shared.accounts ( Just signedInAccount.userId, server.frontendHost ) account
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

        GotEventSyncSourcesFetchResult (Ok ( maybeAccountsPanelMsg, response )) ->
            let
                es =
                    model.eventSyncSources
            in
            ( { model | eventSyncSources = { es | status = EventSyncSourcesFetched, sources = response.sources } }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotEventSyncSourcesFetchResult (Err err) ->
            let
                es =
                    model.eventSyncSources
            in
            ( { model | eventSyncSources = { es | status = EventSyncSourcesFetchFailed (AccountsPanel.grpcErrorToString err) } }
            , Effect.none
            )

        EventSyncSourceRowUrlChanged source url ->
            let
                es =
                    model.eventSyncSources

                edit =
                    eventSyncRowEditFor source es
            in
            ( { model | eventSyncSources = { es | rowEdits = Dict.insert source.id { edit | pendingUrl = url } es.rowEdits } }, Effect.none )

        EventSyncSourceRowIntervalChanged source seconds ->
            let
                es =
                    model.eventSyncSources

                edit =
                    eventSyncRowEditFor source es
            in
            ( { model | eventSyncSources = { es | rowEdits = Dict.insert source.id { edit | pendingIntervalSeconds = seconds } es.rowEdits } }, Effect.none )

        EventSyncSourceRowSaveClicked source ->
            let
                es =
                    model.eventSyncSources

                edit =
                    eventSyncRowEditFor source es

                updated =
                    { source
                        | configuration = Just (Configuration.IcsSubscriptionUrl edit.pendingUrl)
                        , syncIntervalSeconds = Conversions.int64FromInt edit.pendingIntervalSeconds
                    }
            in
            ( { model | eventSyncSources = { es | rowEdits = Dict.insert source.id { edit | status = Submitting } es.rowEdits } }
            , performForOwner shared model (\accountServer -> EventSyncSources.updateEventSyncSource shared.accounts accountServer updated)
                |> Task.attempt (GotEventSyncSourceRowSaveResult source.id)
                |> Effect.fromCmd
            )

        EventSyncSourceRowRefreshClicked source ->
            let
                es =
                    model.eventSyncSources
            in
            ( { model
                | eventSyncSources =
                    { es
                        | rowEdits =
                            Dict.insert source.id
                                { pendingUrl = eventSyncIcsUrl source, pendingIntervalSeconds = Conversions.int64ToInt source.syncIntervalSeconds, status = Submitting }
                                es.rowEdits
                    }
              }
            , performForOwner shared model (\accountServer -> EventSyncSources.updateEventSyncSource shared.accounts accountServer source)
                |> Task.attempt (GotEventSyncSourceRowSaveResult source.id)
                |> Effect.fromCmd
            )

        GotEventSyncSourceRowSaveResult id (Ok ( maybeAccountsPanelMsg, updated )) ->
            let
                es =
                    model.eventSyncSources

                savedModel =
                    { model | eventSyncSources = { es | sources = replaceEventSyncSource updated es.sources, rowEdits = Dict.remove id es.rowEdits } }

                ( refetchedModel, refetchEffect ) =
                    refetchEvents shared savedModel
            in
            ( refetchedModel, Effect.batch [ accountsPanelEffect maybeAccountsPanelMsg, refetchEffect ] )

        GotEventSyncSourceRowSaveResult id (Err err) ->
            let
                es =
                    model.eventSyncSources
            in
            ( { model | eventSyncSources = { es | rowEdits = Dict.update id (Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })) es.rowEdits } }
            , Effect.none
            )

        EventSyncSourceAddUrlChanged url ->
            ( { model | eventSyncSources = mapEventSyncAddForm (\f -> { f | url = url }) model.eventSyncSources }, Effect.none )

        EventSyncSourceAddIntervalChanged seconds ->
            ( { model | eventSyncSources = mapEventSyncAddForm (\f -> { f | intervalSeconds = seconds }) model.eventSyncSources }, Effect.none )

        EventSyncSourceAddClicked ->
            let
                es =
                    model.eventSyncSources

                newSource =
                    { defaultEventSyncSource
                        | configuration = Just (Configuration.IcsSubscriptionUrl es.addForm.url)
                        , syncIntervalSeconds = Conversions.int64FromInt es.addForm.intervalSeconds
                    }
            in
            ( { model | eventSyncSources = mapEventSyncAddForm (\f -> { f | status = Submitting }) es }
            , performForOwner shared model (\accountServer -> EventSyncSources.createEventSyncSource shared.accounts accountServer newSource)
                |> Task.attempt GotEventSyncSourceAddResult
                |> Effect.fromCmd
            )

        GotEventSyncSourceAddResult (Ok ( maybeAccountsPanelMsg, created )) ->
            let
                es =
                    model.eventSyncSources
            in
            ( { model | eventSyncSources = { es | sources = es.sources ++ [ created ], addForm = defaultEventSyncAddForm } }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotEventSyncSourceAddResult (Err err) ->
            ( { model | eventSyncSources = mapEventSyncAddForm (\f -> { f | status = SubmitFailed (AccountsPanel.grpcErrorToString err) }) model.eventSyncSources }, Effect.none )

        -- Doesn't delete anything itself -- just opens the shared "are you
        -- sure?" dialog (`Shared.RequestDelete`), same as
        -- `AvatarEditClicked`/etc do for their own confirmations. The actual
        -- `DeleteEventSyncSource` call happens in `Shared.update`'s
        -- `ConfirmDelete` (see `Shared.ConfirmEventSyncSourceDelete`'s own
        -- doc for why this is fired from there rather than from a page-owned
        -- `Task`), whose result comes back here as
        -- `Shared.GotEventSyncSourceDeleteResult` (see `SharedMsg` above).
        EventSyncSourceDeleteClicked source deleteSyncedEvents ->
            ( model
            , Effect.fromShared (Shared.RequestDelete (Shared.ConfirmEventSyncSourceDelete source deleteSyncedEvents model.resolver.targetHost))
            )

        -- Same shape as `EventSyncSourceDeleteClicked`: just opens the
        -- shared "are you sure?" dialog -- the actual `DeleteUser` call
        -- happens in `Shared.update`'s `ConfirmDelete` (see
        -- `Shared.ConfirmUserDelete`'s own doc), whose result comes back
        -- here as `Shared.GotUserDeleteResult` (see `SharedMsg` above).
        DeleteUserClicked ->
            case model.resolver.status of
                Resolver.Loaded user ->
                    ( model
                    , Effect.fromShared (Shared.RequestDelete (Shared.ConfirmUserDelete user model.resolver.targetHost))
                    )

                _ ->
                    ( model, Effect.none )

        GotFederatedServer account (Ok server) ->
            -- Registers the federated user's server into `shared.accounts.servers`
            -- (same as `ConnectClicked`'s own `GotConnectResult` does for
            -- `targetHost`) -- needed so `UI.EmittedStylesheet` actually emits
            -- this host's `background-color-primary` rule for `federatedProfileLink`.
            ( model
            , Effect.batch
                [ Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.ServerConnected server))
                , fetchFederatedUserEffect shared account
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
        (AccountsPanel.serverForHost shared.accounts.servers model.resolver.targetHost)
        (AccountsPanel.enabledAccountForServer shared.accounts.accounts model.resolver.targetHost)


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
    shared.accounts.accounts
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
`Shared.StarredPanel.kickOffFetches` groups by host, since a `User`
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
    case AccountsPanel.serverForHost shared.accounts.servers account.host of
        Just _ ->
            ( newStatuses, effects ++ [ fetchFederatedUserEffect shared account ] )

        Nothing ->
            ( newStatuses
            , effects
                ++ [ AccountsPanel.connectToServer pageIsSecure account.host
                        |> Task.attempt (GotFederatedServer account)
                        |> Effect.fromCmd
                   ]
            )


fetchFederatedUserEffect : Shared.Model -> FederatedAccount -> Effect Msg
fetchFederatedUserEffect shared account =
    Users.fetchUserById
        shared.accounts
        ( AccountsPanel.enabledAccountForServer shared.accounts.accounts account.host |> Maybe.map .userId
        , account.host
        )
        account.userId
        |> Task.attempt (GotFederatedUser (federatedKey account))
        |> Effect.fromCmd


{-| The `model.federatedProfiles` key for one `User.federatedProfiles` entry --
mirrors `Shared.StarredPanel.starKey`.
-}
federatedKey : FederatedAccount -> String
federatedKey account =
    account.userId ++ "@" ++ account.host


{-| Re-fetches the user unconditionally -- called once the shared Markdown
panel (see `Shared.MarkdownPanel`) reports a successful bio save, mirroring
`Pages.Post.PostId_.refetch`.
-}
refetch : Shared.Model -> Model -> ( Model, Effect Msg )
refetch shared model =
    Resolver.refetch shared model.resolver
        |> Tuple.mapFirst (\newResolver -> { model | resolver = newResolver })
        |> Tuple.mapSecond (Effect.map ResolverMsg)


{-| Re-`init`s the embedded `EventsPage` copy against `model.resolver`'s
already-loaded user -- called after a successful Event Sync Source
sync/update/delete (see `GotEventSyncSourceRowSaveResult` and `SharedMsg`'s
`Shared.GotEventSyncSourceDeleteResult` case), since a source's sync can
create, update, or remove Events/EventInstances that the already-`init`ed
`EventsPage.Model` has no way to know about on its own. Mirrors the
resolver-loaded `init` branch's own `EventsPage.init` call. A no-op if the
profile's own user hasn't loaded yet.
-}
refetchEvents : Shared.Model -> Model -> ( Model, Effect Msg )
refetchEvents shared model =
    case model.resolver.status of
        Resolver.Loaded user ->
            let
                ( eventsModel, eventsEffect ) =
                    EventsPage.init shared (Just ( model.resolver.targetHost, user )) model.navKey model.path model.query True
            in
            ( { model | events = Just eventsModel }, Effect.map EventsMsg eventsEffect )

        _ ->
            ( model, Effect.none )


{-| Kicks off `GetEventSyncSources` for `targetUserId` (this profile's own
`user.id`, or -- for an Admin viewing someone else's profile -- theirs) the
moment its `User` resolves and the viewer's allowed to manage it (see
`canEditProfile`, `updateInner`'s `ResolverMsg` branch) -- mirrors the old
`Shared.EventSyncSourcesPanel.Fetch`'s handling, minus its staleness
re-check on the result (see `EventSyncSourcesState`'s own doc for why that's
no longer needed here).
-}
fetchEventSyncSources : Shared.Model -> String -> String -> Model -> ( Model, Effect Msg )
fetchEventSyncSources shared host targetUserId model =
    let
        es =
            model.eventSyncSources
    in
    case AccountsPanel.enabledAccountForServer shared.accounts.accounts host of
        Just account ->
            ( { model | eventSyncSources = { es | status = EventSyncSourcesFetching, sources = [], rowEdits = Dict.empty } }
            , EventSyncSources.getEventSyncSources shared.accounts ( Just account.userId, host ) targetUserId
                |> Task.attempt GotEventSyncSourcesFetchResult
                |> Effect.fromCmd
            )

        Nothing ->
            ( { model | eventSyncSources = { es | status = EventSyncSourcesFetchFailed "You're not signed in on that server.", sources = [], rowEdits = Dict.empty } }
            , Effect.none
            )


{-| The `EventSyncSourceRowSaveClicked`/`EventSyncSourceRowRefreshClicked`/
`EventSyncSourceAddClicked` requests' shared "who's acting" resolution --
mirrors the old `Shared.EventSyncSourcesPanel.performForOwner` exactly, just
reading `model.resolver.targetHost` (this page's own target server) instead
of a bare `targetHost` field. Its failure mode (not signed in on that server
anymore) has no dedicated `SubmitFailed` slot to land in from here, so it's
folded into a `Grpc.NetworkError` for the caller's own `Err` branch to
render via `AccountsPanel.grpcErrorToString`, same as any other failed RPC.
-}
performForOwner :
    Shared.Model
    -> Model
    -> (AccountsPanel.MaybeAccountServer -> Task.Task Grpc.Error a)
    -> Task.Task Grpc.Error a
performForOwner shared model req =
    case AccountsPanel.enabledAccountForServer shared.accounts.accounts model.resolver.targetHost of
        Just account ->
            req ( Just account.userId, model.resolver.targetHost )

        Nothing ->
            Task.fail Grpc.NetworkError


{-| Optimistically applies a just-saved `User` (as returned by
`Users.updateUser`) straight to `model.resolver.status`, without a round-trip
refetch -- used by `GotRealNameSaveResult`/`GotPermissionsSaveResult`.
-}
withResolvedUser : User -> Resolver.Model -> Resolver.Model
withResolvedUser user resolver =
    { resolver | status = Resolver.Loaded user }


{-| `AvatarSaveClicked`'s transform, passed to `Users.updateUser` the same way
`RealNameSaveClicked`'s inline lambda is -- applied to a freshly re-fetched
`User`, not `model.resolver`'s own possibly-stale one (see `Users.updateUser`'s
own doc). `AvatarChosen mediaId` only ever needs to set `avatar.id` --
`backend/src/rpcs/users/update_user.rs`'s `update_user` reads nothing else off
it -- so the rest of `MediaReference` is left at `defaultMediaReference`'s
placeholders.
-}
applyAvatarChoice : AvatarChoice -> User -> User
applyAvatarChoice choice freshUser =
    case choice of
        AvatarUnchanged ->
            freshUser

        AvatarChosen mediaId ->
            { freshUser | avatar = Just { defaultMediaReference | id = mediaId } }

        AvatarRemoved ->
            { freshUser | avatar = Nothing }



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
        , servers = shared.accounts.servers
        , accounts = shared.accounts.accounts
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
                shared.accounts.mainFrontendHost
                server.frontendHost
                { userId = user.id, username = user.username }

        postsHref =
            baseHref ++ "/posts"

        repliesHref =
            baseHref ++ "/posts?context=reply"

        followersHref =
            baseHref ++ "/followers"

        followingHref =
            baseHref ++ "/following"

        friendsHref =
            baseHref ++ "/friends"

        eventsHref =
            baseHref ++ "/events"
    in
    div [ classes [ "profile-detail", hostnameToCSSClass server.frontendHost, "border-color-primary-anchor-50" ] ]
        [ div [ class "profile-header-row" ]
            [ div [ class "profile-header" ]
                [ avatarView canEdit server maybeAccount model.avatarEdit user
                , div [ class "profile-header-names" ]
                    [ ProfileHeading.usernameHeading user
                    , realNameView canEdit model.realNameEdit user
                    ]

                -- , otherServerIndicator shared server
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
                            |> Maybe.map (\ts -> " · Joined " ++ SharedTime.formatDate shared.time.browserTimeZone.zone (timestampToPosix ts))
                            |> Maybe.withDefault ""
                       )
                )
            ]
        , profileCounts postsHref repliesHref followersHref followingHref friendsHref eventsHref user
        , bioSection canEdit user
        , eventSyncSourcesSection shared model canEdit (isOwnProfile maybeAccount user)
        , case model.events of
            Just eventsModel ->
                Html.map EventsMsg (EventsPage.view shared False eventsModel)

            Nothing ->
                text ""
        , h3 [] [ text (postsHeading model.posts) ]
        , case model.posts of
            Just postsModel ->
                Html.map PostsMsg (PostsPage.view shared False False postsModel)

            Nothing ->
                text ""
        , permissionsSection isAdmin model.permissionsEdit user
        , deleteUserSection canEdit
        ]


{-| "Recent Posts"/"Recent Replies", matching `model.posts`' own `PostContext` --
mirrors `Pages.Home_.heading` exactly, just over a `Maybe PostsPage.Model` (not yet
`init`ed for the brief moment before `resolver` first resolves, see `Model.posts`'
own doc) -- defaults to "Recent Posts" both then and for the ordinary `POST` case,
same as `Pages.Home_.heading` does.
-}
postsHeading : Maybe PostsPage.Model -> String
postsHeading maybePosts =
    case maybePosts |> Maybe.map .context of
        Just REPLY ->
            "Recent Replies"

        _ ->
            "Recent Posts"


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


{-| The avatar, plus (only for `canEdit`) its editing affordance below it: an
"Edit" button when `model.avatarEdit == Nothing`, or -- while editing -- a "✕"
button over the avatar's top-right corner (`AvatarRemoveClicked`, clears the
avatar entirely) and a Save/Cancel row underneath it (mirrors `editSaveButton`/
`editCancelButton`'s use elsewhere on this page). The avatar image itself
previews `edit.choice` (see `avatarPreviewUrl`) rather than `user.avatar`
once editing's started, and -- while editing -- is itself clickable
(`AvatarEditClicked` again, which re-opens `Shared.MyMediaPanel` without
resetting `choice`/`status`, see its own doc) so the user can pick again
without hunting for a smaller "change" link. A non-`canEdit` viewer just gets
the plain avatar, same as before this existed.
-}
avatarView : Bool -> AccountsPanel.Server -> Maybe AccountsPanel.Account -> Maybe AvatarEdit -> User -> Html Msg
avatarView canEdit server maybeAccount maybeEdit user =
    if not canEdit then
        UI.imageOrInitial [ "profile-avatar" ] user.username (Users.avatarUrl server maybeAccount user)

    else
        div [ class "profile-avatar-wrapper" ]
            [ div
                (case maybeEdit of
                    Just _ ->
                        [ classes [ "profile-avatar-frame", "editable" ], onClick AvatarEditClicked, title "Change avatar" ]

                    Nothing ->
                        [ classes [ "profile-avatar-frame" ] ]
                )
                [ UI.imageOrInitial [ "profile-avatar" ] user.username (avatarPreviewUrl server maybeAccount maybeEdit user)
                , case maybeEdit of
                    Just edit ->
                        button
                            [ class "profile-avatar-remove"
                            , stopPropagationAndPreventDefaultOnClick AvatarRemoveClicked
                            , disabled (edit.status == Submitting)
                            , title "Remove avatar"
                            ]
                            [ text "✕" ]

                    Nothing ->
                        text ""
                ]
            , case maybeEdit of
                Just edit ->
                    div [ class "profile-avatar-edit-actions" ]
                        [ editSaveButton AvatarSaveClicked edit.status
                        , editCancelButton AvatarCancelClicked edit.status
                        , editErrorView edit.status
                        ]

                Nothing ->
                    button [ class "profile-edit-button", onClick AvatarEditClicked ] [ text "Edit" ]
            ]


{-| The avatar URL `avatarView` should actually preview: `user.avatar` itself
(same as `Users.avatarUrl`) once no edit's in progress or nothing's changed
yet (`AvatarUnchanged`), the just-picked media once one has (`AvatarChosen`,
built via `Users.mediaReferenceUrl` off a throwaway `MediaReference` wrapping
just that id -- nothing else about it is known/needed for a preview `<img>`),
or `Nothing` (falling back to `UI.imageOrInitial`'s initial-letter
placeholder) once the "✕" button's been hit (`AvatarRemoved`).
-}
avatarPreviewUrl : AccountsPanel.Server -> Maybe AccountsPanel.Account -> Maybe AvatarEdit -> User -> Maybe String
avatarPreviewUrl server maybeAccount maybeEdit user =
    case maybeEdit |> Maybe.map .choice of
        Nothing ->
            Users.avatarUrl server maybeAccount user

        Just AvatarUnchanged ->
            Users.avatarUrl server maybeAccount user

        Just (AvatarChosen mediaId) ->
            Users.mediaReferenceUrl server maybeAccount (Just { defaultMediaReference | id = mediaId })

        Just AvatarRemoved ->
            Nothing


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
            [ if String.isEmpty (String.trim user.bio) then
                text ""

              else
                Markdown.view [ class "profile-bio" ] user.bio
            , if canEdit then
                button [ class "profile-edit-button", onClick BioEditClicked ] [ text "Edit" ]

              else
                text ""
            ]


editSaveButton : Msg -> SubmitStatus -> Html Msg
editSaveButton onSave status =
    button
        [ classes [ "profile-edit-save", "background-color-primary" ]
        , onClick onSave
        , disabled (status == Submitting)
        ]
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


{-| `postsHref`/`followersHref`/`followingHref`/`friendsHref` (see `profileDetail`) link the
"Posts"/"Followers"/"Following"/"Friends" counts to `Pages.Username_.Posts`/
`Pages.Username_.Followers`/`Pages.Username_.Following`/`Pages.Username_.Friends`
(or their `Pages.User.UserId_.*` equivalents) -- the other counts have no page of their
own (yet) to link to.
-}
profileCounts : String -> String -> String -> String -> String -> String -> User -> Html Msg
profileCounts postsHref repliesHref followersHref followingHref friendsHref eventsHref user =
    let
        counts =
            [ ( "Followers", user.followerCount, Just followersHref )
            , ( "Following", user.followingCount, Just followingHref )
            , ( "Friends", user.friendCount, Just friendsHref )

            -- , ( "Groups", user.groupCount, Nothing )
            , ( "Posts", user.postCount, Just postsHref )
            , ( "Replies", user.responseCount, Just repliesHref )
            , ( "Events", user.eventInstanceCount, Just eventsHref )
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
                [ h2 [ class "section-title" ] [ text "Permissions" ]
                , div [ class "permission-badges" ] (edit.pending |> List.map permissionEditBadge)
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
                    [ h2 [ class "section-title" ] [ text "Permissions" ]
                    , div [ class "permission-badges" ]
                        (user.permissions
                            |> List.map (\permission -> span [ class "permission-badge" ] [ text (Users.permissionText permission) ])
                        )
                    , if isAdmin then
                        button [ class "profile-edit-button", onClick PermissionsEditClicked ] [ text "Edit" ]

                      else
                        text ""
                    ]


{-| The "Delete User" button -- shown only to `canEdit` viewers (the
profile's own owner, or an Admin), matching
`backend/src/rpcs/users/delete_user.rs`'s own self-or-Admin gate. Fires
`DeleteUserClicked`, which just opens the shared "are you sure?" dialog
(`Shared.RequestDelete`/`Shared.ConfirmUserDelete`) -- see its own doc for
where the actual `DeleteUser` RPC happens.
-}
deleteUserSection : Bool -> Html Msg
deleteUserSection canEdit =
    if not canEdit then
        text ""

    else
        div [ class "profile-delete-section" ]
            [ button [ class "profile-delete-button", onClick DeleteUserClicked ] [ text "Delete User" ] ]


permissionEditBadge : Permission -> Html Msg
permissionEditBadge permission =
    span [ class "permission-badge editable" ]
        [ text (Users.permissionText permission)
        , button
            [ class "permission-remove"
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
            (h2 [ class "section-title" ] [ text "Federated Profiles" ]
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
            AccountsPanel.serverForHost shared.accounts.servers account.host

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
                shared.accounts.mainFrontendHost
                account.host
                account.userId
            )
        ]
        (case ( maybeFederatedServer, Dict.get (federatedKey account) model.federatedProfiles ) of
            ( Just federatedServer, Just (FederatedProfileLoaded federatedUser) ) ->
                [ UI.imageOrInitial [ "profile-federated-avatar" ]
                    federatedUser.username
                    (Users.avatarUrl federatedServer
                        (AccountsPanel.enabledAccountForServer shared.accounts.accounts account.host)
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



-- EVENT SYNC SOURCES


{-| The in-progress edit for `source`'s row -- an existing one from
`es.rowEdits` if the user's touched it, otherwise a fresh, clean one derived
straight from `source`'s own current values (so a first keystroke in either
field has something correct to diff against/build on).
-}
eventSyncRowEditFor : EventSyncSource -> EventSyncSourcesState -> EventSyncRowEdit
eventSyncRowEditFor source es =
    Dict.get source.id es.rowEdits
        |> Maybe.withDefault { pendingUrl = eventSyncIcsUrl source, pendingIntervalSeconds = Conversions.int64ToInt source.syncIntervalSeconds, status = Idle }


eventSyncIcsUrl : EventSyncSource -> String
eventSyncIcsUrl source =
    case source.configuration of
        Just (Configuration.IcsSubscriptionUrl url) ->
            url

        Nothing ->
            ""


eventSyncSourceIsDirty : EventSyncSource -> EventSyncRowEdit -> Bool
eventSyncSourceIsDirty source edit =
    edit.pendingUrl /= eventSyncIcsUrl source || edit.pendingIntervalSeconds /= Conversions.int64ToInt source.syncIntervalSeconds


replaceEventSyncSource : EventSyncSource -> List EventSyncSource -> List EventSyncSource
replaceEventSyncSource updated sources =
    sources
        |> List.map
            (\s ->
                if s.id == updated.id then
                    updated

                else
                    s
            )


mapEventSyncAddForm : (EventSyncAddForm -> EventSyncAddForm) -> EventSyncSourcesState -> EventSyncSourcesState
mapEventSyncAddForm fn es =
    { es | addForm = fn es.addForm }


{-| Labels a row's "delete along with its events" button with exactly what
it'll take with it, so this doubles as the only warning the user gets before
those rows are gone for good. Also used (via `EventSyncSources.syncedCountsLabel`)
in `UI`'s confirmation dialog for the same source. A row's other, plain
"Delete" button leaves those events/instances alone -- see
`UI.deleteConfirmationModal`'s own message for that case.
-}
eventSyncSourceDeleteButtonLabel : EventSyncSource -> String
eventSyncSourceDeleteButtonLabel source =
    "Delete along with " ++ EventSyncSources.syncedCountsLabel source


{-| `canManage` is self-or-Admin (owner may always manage their own; an
Admin may manage anyone's) -- gates the whole section's edit/delete
affordances (a caller with neither shouldn't even see this section, but this
doesn't assume that's already been checked). `canAdd` is self-only (an Admin
still can't create a source _for_ someone else, see
`create_event_sync_source.rs`) -- gates just the add row.
-}
eventSyncSourcesSection : Shared.Model -> Model -> Bool -> Bool -> Html Msg
eventSyncSourcesSection shared model canManage canAdd =
    if not canManage then
        text ""

    else
        div [ class "event-sync-sources-section" ]
            ([ h2 [ class "section-title" ] [ text "Event Sync Sources" ]
             , div [ class "event-sync-sources-list" ] (eventSyncSourcesContentView model.resolver.targetHost shared.time.browserTimeZone model.eventSyncSources)
             ]
                ++ (if canAdd then
                        [ eventSyncSourceAddRowView model.resolver.targetHost model.eventSyncSources.addForm ]

                    else
                        []
                   )
            )


eventSyncSourcesContentView : String -> SharedTime.BrowserTimeZone -> EventSyncSourcesState -> List (Html Msg)
eventSyncSourcesContentView targetHost browserTimeZone es =
    if not (List.isEmpty es.sources) then
        List.map (eventSyncSourceRowView targetHost browserTimeZone es) es.sources

    else
        case es.status of
            EventSyncSourcesNotFetched ->
                []

            EventSyncSourcesFetching ->
                [ div [ class "event-sync-sources-message" ] [ text "Loading…" ] ]

            EventSyncSourcesFetchFailed err ->
                [ div [ class "event-sync-sources-message" ] [ text err ] ]

            EventSyncSourcesFetched ->
                [ div [ class "event-sync-sources-message" ] [ text "No event sync sources yet." ] ]


eventSyncSourceRowView : String -> SharedTime.BrowserTimeZone -> EventSyncSourcesState -> EventSyncSource -> Html Msg
eventSyncSourceRowView targetHost browserTimeZone es source =
    let
        edit =
            eventSyncRowEditFor source es

        dirty =
            eventSyncSourceIsDirty source edit

        submitting =
            edit.status == Submitting

        lastSyncedText =
            case source.lastSyncedAt of
                Just ts ->
                    SharedTime.formatDateTime browserTimeZone (Conversions.timestampToPosix ts)

                Nothing ->
                    "Never"
    in
    div [ classes [ "event-sync-source-row", hostnameToCSSClass targetHost, "list-item-bordered-color-primary" ] ]
        [ input
            [ class "event-sync-source-url"
            , type_ "text"
            , value edit.pendingUrl
            , placeholder "iCal subscription URL"
            , disabled submitting
            , onInput (EventSyncSourceRowUrlChanged source)
            ]
            []
        , eventSyncIntervalSelect (EventSyncSourceRowIntervalChanged source) edit.pendingIntervalSeconds submitting
        , div [ class "event-sync-source-actions" ]
            [ span [ class "event-sync-source-last-synced" ] [ text ("Last synced: " ++ lastSyncedText) ]
            , if dirty then
                button
                    [ classes [ "event-sync-source-save", "background-color-nav" ], onClick (EventSyncSourceRowSaveClicked source), disabled submitting ]
                    [ text
                        (if submitting then
                            "Saving…"

                         else
                            "Save"
                        )
                    ]

              else
                button
                    [ classes [ "event-sync-source-refresh", "background-color-nav" ], onClick (EventSyncSourceRowRefreshClicked source), disabled submitting ]
                    [ text
                        (if submitting then
                            "Refreshing…"

                         else
                            "Refresh"
                        )
                    ]
            , button
                [ class "event-sync-source-delete-plain", onClick (EventSyncSourceDeleteClicked source False) ]
                [ text "Delete" ]
            , button
                [ class "event-sync-source-delete", onClick (EventSyncSourceDeleteClicked source True) ]
                [ text (eventSyncSourceDeleteButtonLabel source) ]
            ]
        , case edit.status of
            SubmitFailed err ->
                div [ class "event-sync-source-error" ] [ text err ]

            _ ->
                text ""
        ]


eventSyncSourceAddRowView : String -> EventSyncAddForm -> Html Msg
eventSyncSourceAddRowView targetHost addForm =
    div [ classes [ "event-sync-source-row", "event-sync-source-add-row", hostnameToCSSClass targetHost, "list-item-bordered-color-primary" ] ]
        [ input
            [ class "event-sync-source-url"
            , type_ "text"
            , value addForm.url
            , placeholder "iCal subscription URL"
            , disabled (addForm.status == Submitting)
            , onInput EventSyncSourceAddUrlChanged
            ]
            []
        , eventSyncIntervalSelect EventSyncSourceAddIntervalChanged addForm.intervalSeconds (addForm.status == Submitting)
        , button
            [ class "event-sync-source-add"
            , onClick EventSyncSourceAddClicked
            , disabled (addForm.status == Submitting || String.isEmpty (String.trim addForm.url))
            ]
            [ text
                (if addForm.status == Submitting then
                    "Adding…"

                 else
                    "+ Add"
                )
            ]
        , case addForm.status of
            SubmitFailed err ->
                div [ class "event-sync-source-error" ] [ text err ]

            _ ->
                text ""
        ]


eventSyncIntervalSelect : (Int -> Msg) -> Int -> Bool -> Html Msg
eventSyncIntervalSelect onChange selectedSeconds disabledAttr =
    select
        [ class "event-sync-source-interval"
        , disabled disabledAttr
        , onInput (\s -> onChange (String.toInt s |> Maybe.withDefault selectedSeconds))
        ]
        (EventSyncSources.intervalOptions
            |> List.map
                (\( seconds, label ) ->
                    option [ value (String.fromInt seconds), selected (seconds == selectedSeconds) ] [ text label ]
                )
        )
