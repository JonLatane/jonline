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
`Pages.UsernameOrCustomTab_` (`/:username[@host]`), which differ only in which `Lookup`
they parse out of their route and (for `Pages.UsernameOrCustomTab_`) whether the username
is even routable at all (see `Components.Users.isReservedUsername`, checked by
the page itself before ever constructing this module's `Model`).

Mirrors `Pages.Post.PostId_`, generalized over the `Lookup` since (unlike
Posts, which are only ever looked up by id) a `User` can be fetched by either
id or username.

The actual "fetch a `User` once its server is connected, retry until it is"
state machine lives in `Components.Users.Resolver` (`model.resolver`), shared
with `Pages.UsernameOrCustomTab_.Posts`, which needs the same username -> id resolution
but none of this module's profile-editing machinery.

-}

import Browser.Navigation
import Components.EventSyncSources as EventSyncSources
import Components.Markdown as Markdown
import Components.Pages.EventsPage as EventsPage
import Components.Pages.PostsPage as PostsPage
import Components.ServerDependentView as ServerDependentView
import Components.SyncDestinations as SyncDestinations
import Components.Users as Users
import Components.Users.FollowStatusAndButton as FollowStatusAndButton
import Components.Users.ProfileHeading as ProfileHeading
import Components.Users.Resolver as Resolver
import Dict exposing (Dict)
import Effect exposing (Effect)
import Gen.Route
import Grpc
import Html exposing (Html, a, button, div, h2, h3, input, label, option, p, select, span, text)
import Html.Attributes exposing (checked, class, classList, disabled, href, placeholder, selected, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode
import Ports
import Proto.Google.Protobuf
import Proto.Jonline exposing (EventSyncSource, FederatedAccount, SyncDestination, User, defaultEventSyncSource, defaultMediaReference, defaultSyncDestination)
import Proto.Jonline.EventSyncSource.Configuration as Configuration
import Proto.Jonline.SyncDestination.Configuration as DestinationConfiguration
import Proto.Jonline.Moderation exposing (Moderation(..))
import Proto.Jonline.Permission exposing (Permission(..))
import Proto.Jonline.PostContext exposing (PostContext(..))
import Proto.Jonline.Visibility exposing (Visibility)
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
import Url


type alias Model =
    { resolver : Resolver.Model
    , connectStatus : ServerDependentView.ConnectStatus
    , pageIsSecure : Bool
    , federatedProfiles : Dict String FederatedProfileStatus
    , realNameEdit : Maybe RealNameEdit
    , avatarEdit : Maybe AvatarEdit
    , visibilityEdit : Maybe VisibilityEdit
    , moderationEdit : Maybe ModerationEdit
    , followModerationStatus : SubmitStatus
    , permissionsEdit : Maybe PermissionsEdit
    , permissionsExpanded : Bool
    , federatedProfilesEdit : Maybe FederatedProfilesEdit
    , eventSyncSources : EventSyncSourcesState
    , eventSyncSourcesExpanded : Bool
    , syncDestinations : SyncDestinationsState
    , syncDestinationsExpanded : Bool
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
    | VisibilityEditClicked
    | VisibilityChanged String
    | VisibilityCancelClicked
    | VisibilitySaveClicked
    | GotVisibilitySaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, User ))
    | ModerationEditClicked
    | ModerationChanged String
    | ModerationCancelClicked
    | ModerationSaveClicked
    | GotModerationSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, User ))
    | FollowModerationToggled
    | GotFollowModerationSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, User ))
    | PermissionsExpandedToggled
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
    | GotFederatedProfileRemoveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Google.Protobuf.Empty ))
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
    | EventSyncSourcesExpandedToggled
    | SyncDestinationsExpandedToggled
    | FacebookLoginClicked
    | InstagramLoginClicked
    | GotFacebookLoginResult Decode.Value
    | GotFacebookPagesResult (Result Http.Error (List FacebookPageOption))
    | FacebookPageChosen FacebookPageOption
    | GotFacebookLinkResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, SyncDestination ))
    | MastodonConnectClicked
    | MastodonInstanceHostChanged String
    | MastodonAccessTokenChanged String
    | MastodonConnectCancelled
    | MastodonConnectSubmitted
    | GotMastodonLinkResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, SyncDestination ))
    | BlueskyConnectClicked
    | BlueskyHandleChanged String
    | BlueskyAppPasswordChanged String
    | BlueskyConnectCancelled
    | BlueskyConnectSubmitted
    | GotBlueskyLinkResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, SyncDestination ))
    | ThreadsLoginClicked
    | GotThreadsLoginResult Decode.Value
    | GotThreadsLinkResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, SyncDestination ))
    | SyncDestinationDeleteClicked SyncDestination
    | GotSyncDestinationDeleteResult String (Result Grpc.Error ( Maybe AccountsPanel.Msg, () ))
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


{-| Live only while the Visibility picker (see `Model.visibilityEdit`) is
being edited by the profile's own owner or an Admin (see `canEditProfile`,
the same gate `backend/src/rpcs/users/update_user.rs`'s `admin || self_update`
branch enforces server-side, which is also what actually applies
`visibility`) -- mirrors `Pages.Post.PostId_.VisibilityEdit`.
-}
type alias VisibilityEdit =
    { pending : Visibility
    , status : SubmitStatus
    }


{-| Live only while the Moderation picker (see `Model.moderationEdit`) is
being edited by an Admin or a `MODERATEUSERS` holder (see `canModerateUser`,
mirroring `update_user.rs`'s own `admin || moderator` branch, which is also
what actually applies `moderation`) -- mirrors `VisibilityEdit` exactly, just
for `Moderation` instead of `Visibility`.
-}
type alias ModerationEdit =
    { pending : Moderation
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


{-| One Facebook Page returned by the Graph API's `/me/accounts` after a successful Facebook
login (`fetchFacebookPages`) -- `id`/`name` only. The per-page access token that endpoint also
returns is never used: the backend re-derives its own long-lived Page token server-side from the
short-lived _user_ token this page already has, via `FacebookPage.shortLivedUserAccessToken` (see
`logic::facebook_sync::connect_facebook_page` on the backend).
-}
type alias FacebookPageOption =
    { id : String
    , name : String
    }


{-| Which platform a `FacebookLoginStatus` popup flow is connecting for -- Facebook and Instagram
share the exact same OAuth popup/"choose a Page" flow (Instagram Business posting piggybacks on a
linked Facebook Page's access token), so this is threaded through the shared states rather than
duplicating the whole state machine. Set once when the flow starts (`FacebookLoginClicked`/
`InstagramLoginClicked`) and read back in `FacebookPageChosen` to decide which `Configuration`
variant to build.
-}
type FacebookConnectPlatform
    = ConnectFacebook
    | ConnectInstagram


{-| The Facebook/Instagram "Sign in to Facebook Page" flow's own state machine (see
`FacebookLoginClicked`/`InstagramLoginClicked` and `syncDestinationsSection`). Each step
commits straight to the next -- there's no "form" to independently edit/cancel the way
`RealNameEdit`/`EventSyncAddForm` have:

  - `FacebookLoginNotStarted`: no platform button for this flow has been clicked, nothing in flight.
  - `FacebookLoginPopupOpen platform`: waiting on the `Ports.facebookLoginResult` port (the popup
    opened by `Ports.facebookLoginPopup` is open, or the user just closed it -- see
    `GotFacebookLoginResult`).
  - `FacebookLoginFetchingPages platform token`: got a short-lived user access token back, now
    calling the Graph API's `/me/accounts` (`fetchFacebookPages`) to list the Pages it can link.
  - `FacebookLoginChoosingPage platform token pages`: `/me/accounts` returned at least one Page --
    `pages` is shown as a plain clickable list (`FacebookPageChosen`) rather than picking one
    automatically, even when there's only one, so the user always sees what they're linking.
  - `FacebookLoginNoPagesFound`: `/me/accounts` returned zero Pages -- nothing to link, for either
    platform.
  - `FacebookLoginLinking platform page`: `CreateSyncDestination` is in flight for `page`.
  - `FacebookLoginFailed message`: the popup, the Graph API call, or the create RPC failed.

-}
type FacebookLoginStatus
    = FacebookLoginNotStarted
    | FacebookLoginPopupOpen FacebookConnectPlatform
    | FacebookLoginFetchingPages FacebookConnectPlatform String
    | FacebookLoginChoosingPage FacebookConnectPlatform String (List FacebookPageOption)
    | FacebookLoginNoPagesFound
    | FacebookLoginLinking FacebookConnectPlatform FacebookPageOption
    | FacebookLoginFailed String


{-| The Mastodon "Connect" flow's own state machine -- simpler than `FacebookLoginStatus` since
there's no popup/page-list step, just two pasted text fields (instance host + Personal Access
Token) and a submit. See `MastodonConnectClicked`/`mastodonConnectView`.
-}
type MastodonConnectStatus
    = MastodonConnectNotStarted
    | MastodonConnectEditing { instanceHost : String, accessToken : String }
    | MastodonConnectLinking { instanceHost : String, accessToken : String }
    | MastodonConnectFailed String


{-| The Bluesky "Connect" flow's own state machine -- identical shape to `MastodonConnectStatus`,
just a handle + "App Password" instead of an instance host + PAT. See
`BlueskyConnectClicked`/`blueskyConnectView`.
-}
type BlueskyConnectStatus
    = BlueskyConnectNotStarted
    | BlueskyConnectEditing { handle : String, appPassword : String }
    | BlueskyConnectLinking { handle : String, appPassword : String }
    | BlueskyConnectFailed String


{-| The Threads "Connect" flow's own state machine -- popup-based like `FacebookLoginStatus` (it
rides the same `Ports.facebookLoginPopup`/`facebookLoginResult` plumbing, see
`Ports.facebookLoginPopup`'s own doc), but doesn't fit that type: Threads OAuth authorizes the
user's single Threads account directly, with no "choose a Page" step, so there's no equivalent of
`FacebookLoginFetchingPages`/`FacebookLoginChoosingPage`/`FacebookLoginNoPagesFound` -- a popup
result goes straight from "got a code" to "create the destination." Doesn't fit
`MastodonConnectStatus`/`BlueskyConnectStatus`'s paste-a-credential form shape either, since
there's no form, just a popup. See `ThreadsLoginClicked`/`threadsConnectView`.

  - `ThreadsConnectNotStarted`: no button clicked, nothing in flight.
  - `ThreadsConnectPopupOpen`: waiting on `Ports.facebookLoginResult` (see `GotThreadsLoginResult`).
  - `ThreadsConnectLinking`: got an authorization code back, `CreateSyncDestination` in flight.
  - `ThreadsConnectFailed message`: the popup or the create RPC failed.

-}
type ThreadsConnectStatus
    = ThreadsConnectNotStarted
    | ThreadsConnectPopupOpen
    | ThreadsConnectLinking
    | ThreadsConnectFailed String


{-| The "Sync Destinations" section's own state -- mirrors `EventSyncSourcesState`'s doc
(bundled into one record for the same reason), but far simpler: no per-row edits (a destination's
only mutable-from-here field, in effect, is "does it exist"), so this is just the four connect
flows' own state machines (`login` for Facebook/Instagram's shared popup flow, `mastodon`/
`bluesky` for their own inline paste-a-credential forms, `threads` for Threads' own simpler popup
flow -- see `ThreadsConnectStatus`), plus a per-destination-id `SubmitStatus` for
`SyncDestinationDeleteClicked` (`Dict` rather than a single field since, in principle,
more than one delete could be in flight -- e.g. an Admin clicking two rows quickly). At most one of
`login`/`mastodon`/`bluesky`/`threads` is ever not-`NotStarted` at a time -- see
`platformConnectView`, which renders whichever one is in progress (or a platform-picker row of
buttons if none are). The destinations themselves are no longer fetched/held here at all --
`Components.Users.Resolver` already resolves this profile's own `User` (via `GetUsers`), which
(self-or-Admin gated server-side, see `protos/users.proto`'s own doc on `User.sync_destinations`)
already carries them, so `syncDestinationsSection` just reads `user.syncDestinations` directly.

Unlike `EventSyncSourcesState`, deletes are NOT routed through `Shared.DeleteConfirmation`: unlinking
a connected account is a low-stakes, easily-reversible action (nothing else gets deleted --
`deleteSyncedPosts` is always sent `False`, see `Components.SyncDestinations`), so there's no
need for the global "are you sure?" overlay here.

-}
type alias SyncDestinationsState =
    { login : FacebookLoginStatus
    , mastodon : MastodonConnectStatus
    , bluesky : BlueskyConnectStatus
    , threads : ThreadsConnectStatus
    , deleteStatuses : Dict String SubmitStatus
    }


initSyncDestinations : SyncDestinationsState
initSyncDestinations =
    { login = FacebookLoginNotStarted
    , mastodon = MastodonConnectNotStarted
    , bluesky = BlueskyConnectNotStarted
    , threads = ThreadsConnectNotStarted
    , deleteStatuses = Dict.empty
    }


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

        model : Model
        model =
            { resolver = resolverModel
            , connectStatus = ServerDependentView.NotConnected
            , pageIsSecure = pageIsSecure
            , federatedProfiles = Dict.empty
            , realNameEdit = Nothing
            , avatarEdit = Nothing
            , visibilityEdit = Nothing
            , moderationEdit = Nothing
            , followModerationStatus = Idle
            , permissionsEdit = Nothing
            , permissionsExpanded = False
            , federatedProfilesEdit = Nothing
            , eventSyncSources = initEventSyncSources
            , eventSyncSourcesExpanded = False
            , syncDestinations = initSyncDestinations
            , syncDestinationsExpanded = False
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
        , Ports.facebookLoginResult GotFacebookLoginResult
        , Ports.facebookLoginResult GotThreadsLoginResult
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
by `init` (see `Pages.User.UserId_.init`/`Pages.UsernameOrCustomTab_.init`), so this
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
        host : String
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

                newModel : Model
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
                        maybeAccount : Maybe AccountsPanel.Account
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
                                            PostsPage.init shared (Just ( newResolver.targetHost, user )) eventSyncFetchedModel.navKey eventSyncFetchedModel.path eventSyncFetchedModel.query True (Just user.syncDestinations)
                                    in
                                    ( { eventSyncFetchedModel
                                        | posts =
                                            Just { postsModel | showSyncDestinations = model.syncDestinationsExpanded }
                                      }
                                    , Effect.map PostsMsg postsEffect
                                    )

                        ( eventsInitedModel, eventsInitEffect ) =
                            case postsInitedModel.events of
                                Just _ ->
                                    ( postsInitedModel, Effect.none )

                                Nothing ->
                                    let
                                        ( eventsModel, eventsEffect ) =
                                            EventsPage.init shared (Just ( newResolver.targetHost, user )) postsInitedModel.navKey postsInitedModel.path postsInitedModel.query Nothing True False (Just user.syncDestinations)
                                    in
                                    ( { postsInitedModel
                                        | events =
                                            Just
                                                { eventsModel
                                                    | showSyncSources = model.eventSyncSourcesExpanded
                                                    , showSyncDestinations = model.syncDestinationsExpanded
                                                }
                                      }
                                    , Effect.map EventsMsg eventsEffect
                                    )

                        -- A *refetch* (not just the first load) needs this too --
                        -- the `Just _ -> (postsInitedModel, Effect.none)` guard
                        -- above deliberately leaves an already-`init`ed
                        -- `EventsPage.Model` alone, so its own `availableSyncDestinations`
                        -- (seeded once, at `init` time) would otherwise go stale
                        -- after e.g. linking/unlinking a Facebook Page (see
                        -- `refetch`'s own call sites below). Harmless/redundant on
                        -- the very first load, where `init` above already got the
                        -- right value directly.
                        eventsResyncedModel : Model
                        eventsResyncedModel =
                            { eventsInitedModel
                                | events =
                                    eventsInitedModel.events
                                        |> Maybe.map (\em -> { em | availableSyncDestinations = Just user.syncDestinations })
                            }

                        -- Same reasoning as `eventsResyncedModel` above, just for the
                        -- embedded `PostsPage.Model`'s own `availableSyncDestinations`.
                        postsResyncedModel : Model
                        postsResyncedModel =
                            { eventsResyncedModel
                                | posts =
                                    eventsResyncedModel.posts
                                        |> Maybe.map (\pm -> { pm | availableSyncDestinations = Just user.syncDestinations })
                            }
                    in
                    ( postsResyncedModel
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
                                es : EventSyncSourcesState
                                es =
                                    resolvedModel.eventSyncSources

                                deletedModel : Model
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

        VisibilityEditClicked ->
            case model.resolver.status of
                Resolver.Loaded user ->
                    ( { model | visibilityEdit = Just { pending = user.visibility, status = Idle } }, Effect.none )

                _ ->
                    ( model, Effect.none )

        VisibilityChanged text ->
            ( { model
                | visibilityEdit =
                    model.visibilityEdit
                        |> Maybe.map (\edit -> { edit | pending = Users.visibilityFromText text |> Maybe.withDefault edit.pending })
              }
            , Effect.none
            )

        VisibilityCancelClicked ->
            ( { model | visibilityEdit = Nothing }, Effect.none )

        VisibilitySaveClicked ->
            case ( model.resolver.status, model.visibilityEdit, serverAndAccount shared model ) of
                ( Resolver.Loaded user, Just edit, Just ( server, account ) ) ->
                    ( { model | visibilityEdit = Just { edit | status = Submitting } }
                    , Users.updateUser shared.accounts ( Just account.userId, server.frontendHost ) user.id (\freshUser -> { freshUser | visibility = edit.pending })
                        |> Task.attempt GotVisibilitySaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotVisibilitySaveResult (Ok ( maybeAccountsPanelMsg, updatedUser )) ->
            ( { model | resolver = withResolvedUser updatedUser model.resolver, visibilityEdit = Nothing }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotVisibilitySaveResult (Err err) ->
            ( { model
                | visibilityEdit =
                    model.visibilityEdit |> Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })
              }
            , Effect.none
            )

        ModerationEditClicked ->
            case model.resolver.status of
                Resolver.Loaded user ->
                    ( { model | moderationEdit = Just { pending = user.moderation, status = Idle } }, Effect.none )

                _ ->
                    ( model, Effect.none )

        ModerationChanged text ->
            ( { model
                | moderationEdit =
                    model.moderationEdit
                        |> Maybe.map (\edit -> { edit | pending = Users.moderationFromText text |> Maybe.withDefault edit.pending })
              }
            , Effect.none
            )

        ModerationCancelClicked ->
            ( { model | moderationEdit = Nothing }, Effect.none )

        ModerationSaveClicked ->
            case ( model.resolver.status, model.moderationEdit, serverAndAccount shared model ) of
                ( Resolver.Loaded user, Just edit, Just ( server, account ) ) ->
                    ( { model | moderationEdit = Just { edit | status = Submitting } }
                    , Users.updateUser shared.accounts ( Just account.userId, server.frontendHost ) user.id (\freshUser -> { freshUser | moderation = edit.pending })
                        |> Task.attempt GotModerationSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotModerationSaveResult (Ok ( maybeAccountsPanelMsg, updatedUser )) ->
            ( { model | resolver = withResolvedUser updatedUser model.resolver, moderationEdit = Nothing }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotModerationSaveResult (Err err) ->
            ( { model
                | moderationEdit =
                    model.moderationEdit |> Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })
              }
            , Effect.none
            )

        FollowModerationToggled ->
            case ( model.resolver.status, serverAndAccount shared model ) of
                ( Resolver.Loaded user, Just ( server, account ) ) ->
                    let
                        newModeration : Moderation
                        newModeration =
                            if user.defaultFollowModeration == PENDING then
                                UNMODERATED

                            else
                                PENDING
                    in
                    ( { model | followModerationStatus = Submitting }
                    , Users.updateUser shared.accounts ( Just account.userId, server.frontendHost ) user.id (\freshUser -> { freshUser | defaultFollowModeration = newModeration })
                        |> Task.attempt GotFollowModerationSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotFollowModerationSaveResult (Ok ( maybeAccountsPanelMsg, updatedUser )) ->
            ( { model | resolver = withResolvedUser updatedUser model.resolver, followModerationStatus = Idle }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotFollowModerationSaveResult (Err err) ->
            ( { model | followModerationStatus = SubmitFailed (AccountsPanel.grpcErrorToString err) }, Effect.none )

        PermissionsExpandedToggled ->
            ( { model | permissionsExpanded = not model.permissionsExpanded }, Effect.none )

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
                                    pending : List Permission
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
                                            pending : List Permission
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
                clearedModel : Model
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
                        |> Task.attempt GotFederatedProfileRemoveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotFederatedProfileRemoveResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            let
                clearedModel : Model
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

        GotFederatedProfileRemoveResult (Err err) ->
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

                        newModel : Model
                        newModel =
                            { model | followStatusAndButton = newFollowStatusAndButton }

                        mappedFollowEffect : Effect Msg
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
                es : EventSyncSourcesState
                es =
                    model.eventSyncSources
            in
            ( { model | eventSyncSources = { es | status = EventSyncSourcesFetched, sources = response.sources } }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotEventSyncSourcesFetchResult (Err err) ->
            let
                es : EventSyncSourcesState
                es =
                    model.eventSyncSources
            in
            ( { model | eventSyncSources = { es | status = EventSyncSourcesFetchFailed (AccountsPanel.grpcErrorToString err) } }
            , Effect.none
            )

        EventSyncSourceRowUrlChanged source url ->
            let
                es : EventSyncSourcesState
                es =
                    model.eventSyncSources

                edit : EventSyncRowEdit
                edit =
                    eventSyncRowEditFor source es
            in
            ( { model | eventSyncSources = { es | rowEdits = Dict.insert source.id { edit | pendingUrl = url } es.rowEdits } }, Effect.none )

        EventSyncSourceRowIntervalChanged source seconds ->
            let
                es : EventSyncSourcesState
                es =
                    model.eventSyncSources

                edit : EventSyncRowEdit
                edit =
                    eventSyncRowEditFor source es
            in
            ( { model | eventSyncSources = { es | rowEdits = Dict.insert source.id { edit | pendingIntervalSeconds = seconds } es.rowEdits } }, Effect.none )

        EventSyncSourceRowSaveClicked source ->
            let
                es : EventSyncSourcesState
                es =
                    model.eventSyncSources

                edit : EventSyncRowEdit
                edit =
                    eventSyncRowEditFor source es

                updated : EventSyncSource
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
                es : EventSyncSourcesState
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
                es : EventSyncSourcesState
                es =
                    model.eventSyncSources

                savedModel : Model
                savedModel =
                    { model | eventSyncSources = { es | sources = replaceEventSyncSource updated es.sources, rowEdits = Dict.remove id es.rowEdits } }

                ( refetchedModel, refetchEffect ) =
                    refetchEvents shared savedModel
            in
            ( refetchedModel, Effect.batch [ accountsPanelEffect maybeAccountsPanelMsg, refetchEffect ] )

        GotEventSyncSourceRowSaveResult id (Err err) ->
            let
                es : EventSyncSourcesState
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
                es : EventSyncSourcesState
                es =
                    model.eventSyncSources

                newSource : EventSyncSource
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
                es : EventSyncSourcesState
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

        EventSyncSourcesExpandedToggled ->
            let
                expanded : Bool
                expanded =
                    not model.eventSyncSourcesExpanded
            in
            case model.events of
                Just eventsModel ->
                    let
                        ( newEventsModel, eventsEffect ) =
                            EventsPage.update shared (EventsPage.showSyncSourcesChanged expanded) eventsModel
                    in
                    ( { model | eventSyncSourcesExpanded = expanded, events = Just newEventsModel }
                    , Effect.map EventsMsg eventsEffect
                    )

                Nothing ->
                    ( { model | eventSyncSourcesExpanded = expanded }, Effect.none )

        SyncDestinationsExpandedToggled ->
            let
                expanded : Bool
                expanded =
                    not model.syncDestinationsExpanded

                ( eventsUpdatedModel, eventsEffect ) =
                    case model.events of
                        Just eventsModel ->
                            let
                                ( newEventsModel, effect ) =
                                    EventsPage.update shared (EventsPage.showSyncDestinationsChanged expanded) eventsModel
                            in
                            ( { model | syncDestinationsExpanded = expanded, events = Just newEventsModel }, effect )

                        Nothing ->
                            ( { model | syncDestinationsExpanded = expanded }, Effect.none )

                -- Same toggle also drives the embedded `PostsPage.Model`'s own
                -- `showSyncDestinations` -- mirrors the `model.events` handling just
                -- above exactly, since "Sync Destinations" now covers both Events and
                -- Posts (see `syncDestinationsSection`'s own doc).
                ( postsUpdatedModel, postsEffect ) =
                    case eventsUpdatedModel.posts of
                        Just postsModel ->
                            let
                                ( newPostsModel, effect ) =
                                    PostsPage.update shared (PostsPage.showSyncDestinationsChanged expanded) postsModel
                            in
                            ( { eventsUpdatedModel | posts = Just newPostsModel }, effect )

                        Nothing ->
                            ( eventsUpdatedModel, Effect.none )
            in
            ( postsUpdatedModel
            , Effect.batch [ Effect.map EventsMsg eventsEffect, Effect.map PostsMsg postsEffect ]
            )

        -- Opens the popup (see `Ports.facebookLoginPopup`'s own doc for why this happens
        -- synchronously here rather than after some other async step) -- the result arrives via
        -- `GotFacebookLoginResult`. Instagram reuses this exact same popup/"choose a Page" flow
        -- (see `FacebookConnectPlatform`'s own doc), just tagging which platform it's connecting
        -- for so `FacebookPageChosen` knows which `Configuration` variant to build.
        FacebookLoginClicked ->
            startFacebookLogin shared model ConnectFacebook

        InstagramLoginClicked ->
            startFacebookLogin shared model ConnectInstagram

        -- Guarded on `login` actually being `FacebookLoginPopupOpen` -- `Ports.facebookLoginResult`
        -- is one shared port subscribed to by both this Msg and `GotThreadsLoginResult` (see
        -- `Ports.facebookLoginPopup`'s own doc), so a result meant for the Threads flow arrives
        -- here too and must be ignored rather than misrouted into this state machine.
        GotFacebookLoginResult value ->
            case model.syncDestinations.login of
                FacebookLoginPopupOpen platform ->
                    case facebookLoginResultDecoder value of
                        Ok accessToken ->
                            ( setSyncDestinationsLogin (FacebookLoginFetchingPages platform accessToken) model
                            , fetchFacebookPages accessToken |> Effect.fromCmd
                            )

                        -- The user just closed the popup -- quietly go back to not-logged-in rather
                        -- than showing an "error" for a deliberate cancel (see
                        -- `Ports.facebookLoginResult`'s own doc).
                        Err "cancelled" ->
                            ( setSyncDestinationsLogin FacebookLoginNotStarted model, Effect.none )

                        Err message ->
                            ( setSyncDestinationsLogin (FacebookLoginFailed message) model, Effect.none )

                _ ->
                    ( model, Effect.none )

        GotFacebookPagesResult (Ok pages) ->
            case model.syncDestinations.login of
                FacebookLoginFetchingPages platform accessToken ->
                    ( setSyncDestinationsLogin
                        (if List.isEmpty pages then
                            FacebookLoginNoPagesFound

                         else
                            FacebookLoginChoosingPage platform accessToken pages
                        )
                        model
                    , Effect.none
                    )

                _ ->
                    ( model, Effect.none )

        GotFacebookPagesResult (Err _) ->
            ( setSyncDestinationsLogin (FacebookLoginFailed "Couldn't load your Facebook Pages.") model, Effect.none )

        FacebookPageChosen page ->
            case model.syncDestinations.login of
                FacebookLoginChoosingPage platform accessToken _ ->
                    let
                        newDestination : SyncDestination
                        newDestination =
                            { defaultSyncDestination
                                | configuration =
                                    Just
                                        (case platform of
                                            ConnectFacebook ->
                                                DestinationConfiguration.FacebookPage
                                                    { pageId = page.id
                                                    , pageName = page.name
                                                    , shortLivedUserAccessToken = Just accessToken
                                                    }

                                            -- The empty-string fields are fine -- the server
                                            -- populates them (looking up the Page's linked
                                            -- Instagram Business account); this local value is
                                            -- only used to build the outgoing request, not
                                            -- rendered directly.
                                            ConnectInstagram ->
                                                DestinationConfiguration.InstagramAccount
                                                    { instagramBusinessAccountId = ""
                                                    , username = ""
                                                    , pageId = page.id
                                                    , shortLivedUserAccessToken = Just accessToken
                                                    }
                                        )
                            }
                    in
                    ( setSyncDestinationsLogin (FacebookLoginLinking platform page) model
                    , performForOwner shared model (\accountServer -> SyncDestinations.createSyncDestination shared.accounts accountServer newDestination)
                        |> Task.attempt GotFacebookLinkResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotFacebookLinkResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            let
                ed : SyncDestinationsState
                ed =
                    model.syncDestinations

                loginResetModel : Model
                loginResetModel =
                    { model | syncDestinations = { ed | login = FacebookLoginNotStarted } }

                ( refetchedModel, refetchEffect ) =
                    refetch shared loginResetModel
            in
            ( refetchedModel, Effect.batch [ refetchEffect, accountsPanelEffect maybeAccountsPanelMsg ] )

        GotFacebookLinkResult (Err err) ->
            ( setSyncDestinationsLogin (FacebookLoginFailed (facebookLinkErrorMessage err)) model, Effect.none )

        MastodonConnectClicked ->
            ( setSyncDestinationsMastodon (MastodonConnectEditing { instanceHost = "", accessToken = "" }) model, Effect.none )

        MastodonInstanceHostChanged instanceHost ->
            ( updateMastodonEditing (\form -> { form | instanceHost = instanceHost }) model, Effect.none )

        MastodonAccessTokenChanged accessToken ->
            ( updateMastodonEditing (\form -> { form | accessToken = accessToken }) model, Effect.none )

        MastodonConnectCancelled ->
            ( setSyncDestinationsMastodon MastodonConnectNotStarted model, Effect.none )

        MastodonConnectSubmitted ->
            case model.syncDestinations.mastodon of
                MastodonConnectEditing form ->
                    let
                        newDestination : SyncDestination
                        newDestination =
                            { defaultSyncDestination
                                | configuration =
                                    Just
                                        (DestinationConfiguration.MastodonAccount
                                            { instanceHost = form.instanceHost
                                            , username = ""
                                            , accessToken = Just form.accessToken
                                            }
                                        )
                            }
                    in
                    ( setSyncDestinationsMastodon (MastodonConnectLinking form) model
                    , performForOwner shared model (\accountServer -> SyncDestinations.createSyncDestination shared.accounts accountServer newDestination)
                        |> Task.attempt GotMastodonLinkResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotMastodonLinkResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            let
                ed : SyncDestinationsState
                ed =
                    model.syncDestinations

                mastodonResetModel : Model
                mastodonResetModel =
                    { model | syncDestinations = { ed | mastodon = MastodonConnectNotStarted } }

                ( refetchedModel, refetchEffect ) =
                    refetch shared mastodonResetModel
            in
            ( refetchedModel, Effect.batch [ refetchEffect, accountsPanelEffect maybeAccountsPanelMsg ] )

        GotMastodonLinkResult (Err err) ->
            ( setSyncDestinationsMastodon (MastodonConnectFailed (AccountsPanel.grpcErrorToString err)) model, Effect.none )

        BlueskyConnectClicked ->
            ( setSyncDestinationsBluesky (BlueskyConnectEditing { handle = "", appPassword = "" }) model, Effect.none )

        BlueskyHandleChanged handle ->
            ( updateBlueskyEditing (\form -> { form | handle = handle }) model, Effect.none )

        BlueskyAppPasswordChanged appPassword ->
            ( updateBlueskyEditing (\form -> { form | appPassword = appPassword }) model, Effect.none )

        BlueskyConnectCancelled ->
            ( setSyncDestinationsBluesky BlueskyConnectNotStarted model, Effect.none )

        BlueskyConnectSubmitted ->
            case model.syncDestinations.bluesky of
                BlueskyConnectEditing form ->
                    let
                        newDestination : SyncDestination
                        newDestination =
                            { defaultSyncDestination
                                | configuration =
                                    Just
                                        (DestinationConfiguration.BlueskyAccount
                                            { handle = form.handle
                                            , did = ""
                                            , appPassword = Just form.appPassword
                                            }
                                        )
                            }
                    in
                    ( setSyncDestinationsBluesky (BlueskyConnectLinking form) model
                    , performForOwner shared model (\accountServer -> SyncDestinations.createSyncDestination shared.accounts accountServer newDestination)
                        |> Task.attempt GotBlueskyLinkResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotBlueskyLinkResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            let
                ed : SyncDestinationsState
                ed =
                    model.syncDestinations

                blueskyResetModel : Model
                blueskyResetModel =
                    { model | syncDestinations = { ed | bluesky = BlueskyConnectNotStarted } }

                ( refetchedModel, refetchEffect ) =
                    refetch shared blueskyResetModel
            in
            ( refetchedModel, Effect.batch [ refetchEffect, accountsPanelEffect maybeAccountsPanelMsg ] )

        GotBlueskyLinkResult (Err err) ->
            ( setSyncDestinationsBluesky (BlueskyConnectFailed (AccountsPanel.grpcErrorToString err)) model, Effect.none )

        -- Opens the Threads popup (see `Ports.facebookLoginPopup`'s own doc) -- Threads rides the
        -- same Meta App as Facebook/Instagram, so this reuses `facebookAppId` the same way
        -- `startFacebookLogin` does, just pointed at the `"threads"` provider and this flow's own
        -- simpler state machine (no page-picker, see `ThreadsConnectStatus`).
        ThreadsLoginClicked ->
            case facebookAppId shared model.resolver.targetHost of
                Just appId ->
                    ( setSyncDestinationsThreads ThreadsConnectPopupOpen model
                    , Ports.facebookLoginPopup { provider = "threads", appId = appId } |> Effect.fromCmd
                    )

                Nothing ->
                    ( model, Effect.none )

        -- Guarded on `threads` actually being `ThreadsConnectPopupOpen` -- see
        -- `GotFacebookLoginResult`'s own doc on why this shared port needs a guard on both sides.
        -- Unlike Facebook/Instagram, a successful result goes straight to building the create
        -- request -- there's no page-picker step to land on first.
        GotThreadsLoginResult value ->
            case model.syncDestinations.threads of
                ThreadsConnectPopupOpen ->
                    case facebookLoginResultDecoder value of
                        Ok code ->
                            let
                                newDestination : SyncDestination
                                newDestination =
                                    { defaultSyncDestination
                                        | configuration =
                                            Just
                                                -- The empty-string fields are fine -- the server
                                                -- populates them; this local value is only used to
                                                -- build the outgoing request, not rendered directly
                                                -- (mirrors how Instagram's create request is built).
                                                (DestinationConfiguration.ThreadsAccount
                                                    { threadsUserId = ""
                                                    , username = ""
                                                    , authorizationCode = Just code
                                                    }
                                                )
                                    }
                            in
                            ( setSyncDestinationsThreads ThreadsConnectLinking model
                            , performForOwner shared model (\accountServer -> SyncDestinations.createSyncDestination shared.accounts accountServer newDestination)
                                |> Task.attempt GotThreadsLinkResult
                                |> Effect.fromCmd
                            )

                        -- The user just closed the popup -- quietly go back to not-connected
                        -- rather than showing an "error" for a deliberate cancel (see
                        -- `Ports.facebookLoginResult`'s own doc).
                        Err "cancelled" ->
                            ( setSyncDestinationsThreads ThreadsConnectNotStarted model, Effect.none )

                        Err message ->
                            ( setSyncDestinationsThreads (ThreadsConnectFailed message) model, Effect.none )

                _ ->
                    ( model, Effect.none )

        GotThreadsLinkResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            let
                ed : SyncDestinationsState
                ed =
                    model.syncDestinations

                threadsResetModel : Model
                threadsResetModel =
                    { model | syncDestinations = { ed | threads = ThreadsConnectNotStarted } }

                ( refetchedModel, refetchEffect ) =
                    refetch shared threadsResetModel
            in
            ( refetchedModel, Effect.batch [ refetchEffect, accountsPanelEffect maybeAccountsPanelMsg ] )

        GotThreadsLinkResult (Err err) ->
            ( setSyncDestinationsThreads (ThreadsConnectFailed (AccountsPanel.grpcErrorToString err)) model, Effect.none )

        -- Unlike `EventSyncSourceDeleteClicked`, this deletes immediately rather than opening
        -- the shared confirmation dialog -- see `SyncDestinationsState`'s own doc for why.
        SyncDestinationDeleteClicked destination ->
            let
                ed : SyncDestinationsState
                ed =
                    model.syncDestinations
            in
            ( { model | syncDestinations = { ed | deleteStatuses = Dict.insert destination.id Submitting ed.deleteStatuses } }
            , performForOwner shared model (\accountServer -> SyncDestinations.deleteSyncDestination shared.accounts accountServer destination)
                |> Task.attempt (GotSyncDestinationDeleteResult destination.id)
                |> Effect.fromCmd
            )

        GotSyncDestinationDeleteResult id (Ok ( maybeAccountsPanelMsg, () )) ->
            let
                ed : SyncDestinationsState
                ed =
                    model.syncDestinations

                clearedModel : Model
                clearedModel =
                    { model | syncDestinations = { ed | deleteStatuses = Dict.remove id ed.deleteStatuses } }

                ( refetchedModel, refetchEffect ) =
                    refetch shared clearedModel
            in
            ( refetchedModel, Effect.batch [ refetchEffect, accountsPanelEffect maybeAccountsPanelMsg ] )

        GotSyncDestinationDeleteResult id (Err err) ->
            let
                ed : SyncDestinationsState
                ed =
                    model.syncDestinations
            in
            ( { model | syncDestinations = { ed | deleteStatuses = Dict.insert id (SubmitFailed (AccountsPanel.grpcErrorToString err)) ed.deleteStatuses } }
            , Effect.none
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
                accountEffect : Effect Msg
                accountEffect =
                    accountsPanelEffect maybeAccountsPanelMsg

                newStatus : FederatedProfileStatus
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
        pending : List FederatedAccount
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
        newStatuses : Dict String FederatedProfileStatus
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
                    EventsPage.init shared (Just ( model.resolver.targetHost, user )) model.navKey model.path model.query Nothing True False (Just user.syncDestinations)
            in
            ( { model
                | events =
                    Just
                        { eventsModel
                            | showSyncSources = model.eventSyncSourcesExpanded
                            , showSyncDestinations = model.syncDestinationsExpanded
                        }
              }
            , Effect.map EventsMsg eventsEffect
            )

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
        es : EventSyncSourcesState
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


setSyncDestinationsLogin : FacebookLoginStatus -> Model -> Model
setSyncDestinationsLogin login model =
    let
        ed : SyncDestinationsState
        ed =
            model.syncDestinations
    in
    { model | syncDestinations = { ed | login = login } }


setSyncDestinationsMastodon : MastodonConnectStatus -> Model -> Model
setSyncDestinationsMastodon mastodon model =
    let
        ed : SyncDestinationsState
        ed =
            model.syncDestinations
    in
    { model | syncDestinations = { ed | mastodon = mastodon } }


{-| Applies `f` to the in-progress Mastodon connect form's fields (a no-op if `mastodon` isn't
currently `MastodonConnectEditing`, e.g. a stray keystroke event after submit) -- used by
`MastodonInstanceHostChanged`/`MastodonAccessTokenChanged`.
-}
updateMastodonEditing : ({ instanceHost : String, accessToken : String } -> { instanceHost : String, accessToken : String }) -> Model -> Model
updateMastodonEditing f model =
    case model.syncDestinations.mastodon of
        MastodonConnectEditing form ->
            setSyncDestinationsMastodon (MastodonConnectEditing (f form)) model

        _ ->
            model


setSyncDestinationsBluesky : BlueskyConnectStatus -> Model -> Model
setSyncDestinationsBluesky bluesky model =
    let
        ed : SyncDestinationsState
        ed =
            model.syncDestinations
    in
    { model | syncDestinations = { ed | bluesky = bluesky } }


{-| Applies `f` to the in-progress Bluesky connect form's fields -- mirrors
`updateMastodonEditing` exactly, see its own doc.
-}
updateBlueskyEditing : ({ handle : String, appPassword : String } -> { handle : String, appPassword : String }) -> Model -> Model
updateBlueskyEditing f model =
    case model.syncDestinations.bluesky of
        BlueskyConnectEditing form ->
            setSyncDestinationsBluesky (BlueskyConnectEditing (f form)) model

        _ ->
            model


setSyncDestinationsThreads : ThreadsConnectStatus -> Model -> Model
setSyncDestinationsThreads threads model =
    let
        ed : SyncDestinationsState
        ed =
            model.syncDestinations
    in
    { model | syncDestinations = { ed | threads = threads } }


{-| Opens the Facebook/Instagram popup for `platform` (see `FacebookLoginClicked`'s own doc for
why this happens synchronously rather than after some other async step) -- shared by
`FacebookLoginClicked`/`InstagramLoginClicked`, which differ only in which platform they pass.
-}
startFacebookLogin : Shared.Model -> Model -> FacebookConnectPlatform -> ( Model, Effect Msg )
startFacebookLogin shared model platform =
    case facebookAppId shared model.resolver.targetHost of
        Just appId ->
            ( setSyncDestinationsLogin (FacebookLoginPopupOpen platform) model
            , Ports.facebookLoginPopup { provider = "facebook", appId = appId } |> Effect.fromCmd
            )

        Nothing ->
            ( model, Effect.none )


{-| `GotFacebookLinkResult (Err err)`'s message, with one friendlier substitution: the server's
raw `instagram_no_linked_business_account` `FailedPrecondition` message (see
`logic::facebook_sync::get_linked_instagram_business_account` on the backend) becomes an
actionable sentence instead of a bare error code -- every other failure (including any other
Instagram/Facebook error) falls through to the same `AccountsPanel.grpcErrorToString` rendering
every other RPC failure in this file uses.
-}
facebookLinkErrorMessage : Grpc.Error -> String
facebookLinkErrorMessage err =
    let
        raw : String
        raw =
            AccountsPanel.grpcErrorToString err
    in
    if String.contains "instagram_no_linked_business_account" raw then
        "That Facebook Page doesn't have a linked Instagram Business account."

    else
        raw


{-| Whether the "Sync Destinations" section should be shown at all -- the viewer holding *any* of
the 10 `SYNC_EVENTS_TO_*`/`SYNC_POSTS_TO_*` permission pairs (or `ADMIN`) is enough to show the
section (each platform's own button within it applies its own, more specific gate -- see
`hasSyncToFacebookPermission` and friends, plus `facebookAppConfigured` for Facebook/Instagram
specifically).
-}
canUseSyncDestinations : Maybe AccountsPanel.Account -> Bool
canUseSyncDestinations maybeAccount =
    hasSyncToFacebookPermission maybeAccount
        || hasSyncToInstagramPermission maybeAccount
        || hasSyncToMastodonPermission maybeAccount
        || hasSyncToBlueskyPermission maybeAccount
        || hasSyncToXTwitterPermission maybeAccount
        || hasSyncToThreadsPermission maybeAccount


{-| Whether `maybeAccount` holds either half of one platform's `SYNC_EVENTS_TO_*`/
`SYNC_POSTS_TO_*` permission pair (or `ADMIN`) -- a generic `SyncDestination` can serve either
content type, so either permission alone is enough to use that platform. Shared by
`hasSyncToFacebookPermission`/`hasSyncToInstagramPermission`/`hasSyncToMastodonPermission`/
`hasSyncToBlueskyPermission`/`hasSyncToXTwitterPermission`/`hasSyncToThreadsPermission` below, one
per platform.
-}
hasSyncPermissionPair : Permission -> Permission -> Maybe AccountsPanel.Account -> Bool
hasSyncPermissionPair eventsPermission postsPermission maybeAccount =
    maybeAccount
        |> Maybe.map
            (\account ->
                List.member eventsPermission account.permissions
                    || List.member postsPermission account.permissions
                    || List.member ADMIN account.permissions
            )
        |> Maybe.withDefault False


hasSyncToFacebookPermission : Maybe AccountsPanel.Account -> Bool
hasSyncToFacebookPermission =
    hasSyncPermissionPair SYNCEVENTSTOFACEBOOK SYNCPOSTSTOFACEBOOK


hasSyncToInstagramPermission : Maybe AccountsPanel.Account -> Bool
hasSyncToInstagramPermission =
    hasSyncPermissionPair SYNCEVENTSTOINSTAGRAM SYNCPOSTSTOINSTAGRAM


hasSyncToMastodonPermission : Maybe AccountsPanel.Account -> Bool
hasSyncToMastodonPermission =
    hasSyncPermissionPair SYNCEVENTSTOMASTODON SYNCPOSTSTOMASTODON


hasSyncToBlueskyPermission : Maybe AccountsPanel.Account -> Bool
hasSyncToBlueskyPermission =
    hasSyncPermissionPair SYNCEVENTSTOBLUESKY SYNCPOSTSTOBLUESKY


hasSyncToXTwitterPermission : Maybe AccountsPanel.Account -> Bool
hasSyncToXTwitterPermission =
    hasSyncPermissionPair SYNCEVENTSTOXTWITTER SYNCPOSTSTOXTWITTER


hasSyncToThreadsPermission : Maybe AccountsPanel.Account -> Bool
hasSyncToThreadsPermission =
    hasSyncPermissionPair SYNCEVENTSTOTHREADS SYNCPOSTSTOTHREADS


{-| Whether `host` has a Facebook App configured -- gates the Facebook *and* Instagram buttons
specifically (both ride on the same Facebook App/popup, see `FacebookConnectPlatform`'s own doc),
not Mastodon/Bluesky, which need no server-side app config at all to be usable.
-}
facebookAppConfigured : Shared.Model -> String -> Bool
facebookAppConfigured shared host =
    facebookAppId shared host /= Nothing


{-| `host`'s configured Facebook App ID (`Just id`, non-empty), or `Nothing` if that server
hasn't set one up (`ConfigureServer`'s `federationInfo.facebookAuthConfig`, see
`Components.Pages.ServerInformationPage`'s Federation tab, where an admin sets this).
-}
facebookAppId : Shared.Model -> String -> Maybe String
facebookAppId shared host =
    AccountsPanel.serverForHost shared.accounts.servers host
        |> Maybe.map AccountsPanel.configurationOf
        |> Maybe.andThen .federationInfo
        |> Maybe.andThen .facebookAuthConfig
        |> Maybe.map .appId
        |> Maybe.andThen
            (\id ->
                if String.isEmpty id then
                    Nothing

                else
                    Just id
            )


{-| Decodes a `facebookLoginResult` payload (`{ ok : Bool, value : String }`, see that port's own
doc) the same way `Shared.FederatedAuth.resultDecoder` does for its own `{ok, value}` ports --
`Ok accessToken` on success, `Err "cancelled"` or `Err message` otherwise.
-}
facebookLoginResultDecoder : Decode.Value -> Result String String
facebookLoginResultDecoder value =
    case
        Decode.decodeValue
            (Decode.map2 Tuple.pair (Decode.field "ok" Decode.bool) (Decode.field "value" Decode.string))
            value
    of
        Ok ( True, token ) ->
            Ok token

        Ok ( False, err ) ->
            Err err

        Err err ->
            Err (Decode.errorToString err)


{-| Lists the Facebook Pages the just-logged-in account manages, straight from the Graph API
(`GET /me/accounts`) -- a plain client-side HTTP call, not routed through the Jonline backend at
all, since it's Facebook's own API being asked "which Pages can this token manage," not anything
Jonline-specific. Only `id`/`name` are read out of each entry (see `FacebookPageOption`'s own doc
for why the per-page access token Facebook also returns here isn't used).
-}
fetchFacebookPages : String -> Cmd Msg
fetchFacebookPages accessToken =
    Http.get
        { url = "https://graph.facebook.com/v19.0/me/accounts?fields=id,name&access_token=" ++ Url.percentEncode accessToken
        , expect = Http.expectJson GotFacebookPagesResult facebookPagesDecoder
        }


facebookPagesDecoder : Decode.Decoder (List FacebookPageOption)
facebookPagesDecoder =
    Decode.field "data"
        (Decode.list
            (Decode.map2 FacebookPageOption
                (Decode.field "id" Decode.string)
                (Decode.field "name" Decode.string)
            )
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
already told us: the username for `ByUsername` (`Pages.UsernameOrCustomTab_`), or else
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
        canEdit : Bool
        canEdit =
            canEditProfile maybeAccount user

        isAdmin : Bool
        isAdmin =
            isAdminAccount maybeAccount

        baseHref : String
        baseHref =
            Users.profileHref shared.basePath
                shared.accounts.mainFrontendHost
                server.frontendHost
                { userId = user.id, username = user.username }

        postsHref : String
        postsHref =
            baseHref ++ "/posts"

        repliesHref : String
        repliesHref =
            baseHref ++ "/posts?context=reply"

        followersHref : String
        followersHref =
            baseHref ++ "/followers"

        followingHref : String
        followingHref =
            baseHref ++ "/following"

        friendsHref : String
        friendsHref =
            baseHref ++ "/friends"

        eventsHref : String
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
            ([ visibilityView canEdit maybeAccount model.visibilityEdit user
             , moderationView (canModerateUser maybeAccount) model.moderationEdit user
             ]
                ++ (user.createdAt
                        |> Maybe.map (\ts -> text (" · Joined " ++ SharedTime.formatDate shared.time.browserTimeZone.zone (timestampToPosix ts)))
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []
                   )
            )
        , followModerationToggleView canEdit model.followModerationStatus user
        , profileCounts postsHref repliesHref followersHref followingHref friendsHref eventsHref user
        , bioSection canEdit user
        , case model.events of
            Just eventsModel ->
                Html.map EventsMsg (EventsPage.view shared False eventsModel)

            Nothing ->
                text ""
        , eventSyncSourcesSection shared model canEdit (isOwnProfile maybeAccount user)
        , syncDestinationsSection shared model maybeAccount user
        , h3 [] [ text (postsHeading model.posts) ]
        , case model.posts of
            Just postsModel ->
                Html.map PostsMsg (PostsPage.view shared False False postsModel)

            Nothing ->
                text ""
        , permissionsSection isAdmin model.permissionsExpanded model.permissionsEdit user
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


{-| Whether the currently signed-in account on this profile's server may
moderate `user` -- an `ADMIN`, or a `MODERATEUSERS` holder, matching
`backend/src/rpcs/users/update_user.rs`'s own `admin || moderator` check
(the branch that actually applies `moderation`), gating `moderationView`'s
"Moderate" button. Unlike `canEditProfile`, `user` themself doesn't get a
pass here unless they also hold one of these permissions.
-}
canModerateUser : Maybe AccountsPanel.Account -> Bool
canModerateUser maybeAccount =
    case maybeAccount of
        Just account ->
            List.member ADMIN account.permissions || List.member MODERATEUSERS account.permissions

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


{-| The Visibility segment of `profileDetail`'s meta line -- plain text
(`Users.visibilityText`) plus an Edit button when `model.visibilityEdit ==
Nothing`, shown only to `canEdit` viewers (mirrors `Pages.Post.PostId_.
visibilityView`'s own `isAuthor`-gated Edit button, just gated on
`canEditProfile` here instead); an inline `<select>` + Save/Cancel once
editing, with its options narrowed to whatever `maybeAccount` is actually
allowed to pick (`Users.allowedVisibilities`, mirroring
`backend/src/rpcs/users/update_user.rs`'s own `PUBLISHUSERSGLOBALLY` check).
-}
visibilityView : Bool -> Maybe AccountsPanel.Account -> Maybe VisibilityEdit -> User -> Html Msg
visibilityView canEdit maybeAccount maybeEdit user =
    case maybeEdit of
        Just edit ->
            let
                options : List Visibility
                options =
                    maybeAccount
                        |> Maybe.map (\account -> Users.allowedVisibilities account.permissions user.visibility)
                        |> Maybe.withDefault [ edit.pending ]
            in
            span [ class "profile-visibility-edit" ]
                [ select [ onInput VisibilityChanged ]
                    (options
                        |> List.map
                            (\visibility ->
                                option
                                    [ value (Users.visibilityText visibility)
                                    , selected (edit.pending == visibility)
                                    ]
                                    [ text (Users.visibilityText visibility) ]
                            )
                    )
                , editSaveButton VisibilitySaveClicked edit.status
                , editCancelButton VisibilityCancelClicked edit.status
                , editErrorView edit.status
                ]

        Nothing ->
            span [ class "profile-visibility-display" ]
                [ text (Users.visibilityText user.visibility)
                , if canEdit then
                    button [ class "profile-edit-button", onClick VisibilityEditClicked ] [ text "Edit" ]

                  else
                    text ""
                ]


{-| The Moderation segment of `profileDetail`'s meta line -- mirrors
`visibilityView` exactly, just for `Moderation` instead of `Visibility`,
shown to an Admin/`MODERATEUSERS` holder instead of `canEditProfile` (see
`canModerateUser`), and its own "Edit" button reads "Moderate" instead,
mirroring `Pages.Post.PostId_.moderationView`'s own convention.
-}
moderationView : Bool -> Maybe ModerationEdit -> User -> Html Msg
moderationView canModerate maybeEdit user =
    case maybeEdit of
        Just edit ->
            span [ class "profile-moderation-edit" ]
                [ text " · "
                , select [ onInput ModerationChanged ]
                    (Users.allModerations
                        |> List.map
                            (\moderation ->
                                option
                                    [ value (Users.moderationText moderation)
                                    , selected (edit.pending == moderation)
                                    ]
                                    [ text (Users.moderationText moderation) ]
                            )
                    )
                , editSaveButton ModerationSaveClicked edit.status
                , editCancelButton ModerationCancelClicked edit.status
                , editErrorView edit.status
                ]

        Nothing ->
            span [ class "profile-moderation-display" ]
                [ text (" · " ++ Users.moderationText user.moderation)
                , if canModerate then
                    button [ class "profile-edit-button", onClick ModerationEditClicked ] [ text "Moderate" ]

                  else
                    text ""
                ]


{-| The "Requires permission to follow" toggle -- a bare on/off switch
(`profileSwitch`) rather than a Save/Cancel edit like `visibilityView`/
`moderationView`, since it's just one boolean: "on" sets
`user.defaultFollowModeration` to `PENDING` (a follow request needs
approval), "off" sets it to `UNMODERATED` (anyone can follow outright).
Treats any moderation value other than `PENDING` (e.g. a legacy `APPROVED`/
`REJECTED`) as "off", matching `Components.Users.moderationPasses`' own
`UNMODERATED`-or-`APPROVED` "in effect" reasoning -- there's no third state
to round-trip here. Always shown (unlike `visibilityView`/`moderationView`'s
Edit/Moderate buttons, which disappear entirely for a viewer who can't use
them), just disabled for a `not canEdit` viewer -- mirrors
`Components.Pages.ServerInformationPage.switchDisplay`'s "show the state,
disable the control" treatment for a setting this viewer can see but not
change.
-}
followModerationToggleView : Bool -> SubmitStatus -> User -> Html Msg
followModerationToggleView canEdit status user =
    div [ class "profile-follow-moderation-toggle" ]
        [ span [ class "profile-follow-moderation-label" ] [ text "Requires permission to follow" ]
        , profileSwitch (user.defaultFollowModeration == PENDING) (not canEdit || status == Submitting) FollowModerationToggled
        , editErrorView status
        ]


{-| A checkbox styled as a toggle switch -- same `.switch`/`.slider` classes
as `UI.switchInput`, not reused directly since that function's `toggleMsg` is
hard-coded to `Shared.Msg` (mirrors `Components.Pages.ServerInformationPage.
flagSwitch`, which duplicates it for the same reason).
-}
profileSwitch : Bool -> Bool -> Msg -> Html Msg
profileSwitch isChecked isDisabled toggleMsg =
    label [ classList [ ( "switch", True ), ( "disabled", isDisabled ) ] ]
        [ input [ type_ "checkbox", checked isChecked, disabled isDisabled, onClick toggleMsg ] []
        , span [ class "slider" ] []
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
"Posts"/"Followers"/"Following"/"Friends" counts to `Pages.UsernameOrCustomTab_.Posts`/
`Pages.UsernameOrCustomTab_.Followers`/`Pages.UsernameOrCustomTab_.Following`/`Pages.UsernameOrCustomTab_.Friends`
(or their `Pages.User.UserId_.*` equivalents) -- the other counts have no page of their
own (yet) to link to.
-}
profileCounts : String -> String -> String -> String -> String -> String -> User -> Html Msg
profileCounts postsHref repliesHref followersHref followingHref friendsHref eventsHref user =
    let
        counts : List ( String, Int, Maybe String )
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
        content : List (Html Msg)
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


{-| A `.section-title` header that also toggles a collapsed/expanded body
below it -- shared by `permissionsSection`/`eventSyncSourcesSection`, both of
which start collapsed (see `Model.permissionsExpanded`/`eventSyncSourcesExpanded`,
both `False` in `init`) so neither dumps a wall of mostly-admin-only content
onto every profile visit by default.
-}
expandableProfileSection : String -> String -> Bool -> Msg -> List (Html Msg) -> Html Msg
expandableProfileSection sectionClass title expanded toggleMsg content =
    div [ class sectionClass ]
        (h2
            [ classes [ "section-title", "expandable-section-title" ]
            , onClick toggleMsg
            ]
            [ span [ class "expandable-section-arrow" ]
                [ text
                    (if expanded then
                        "▾"

                     else
                        "▸"
                    )
                ]
            , text title
            ]
            :: (if expanded then
                    content

                else
                    []
               )
        )


{-| The Permissions list -- plain badges (plus an Edit button, if `isAdmin`)
when `permissionsEdit == Nothing`, or the removable-badges + Add Permission +
Save/Cancel editor while being edited by an admin. Shown (with just the Edit
button) even with no permissions yet, so an admin can grant the first one.
Collapsed by default (`expanded`, `Model.permissionsExpanded`) behind
`expandableProfileSection`'s own header -- an admin must expand it before the
Edit button (and thus `PermissionsEditClicked`) is even reachable.
-}
permissionsSection : Bool -> Bool -> Maybe PermissionsEdit -> User -> Html Msg
permissionsSection isAdmin expanded maybeEdit user =
    if List.isEmpty user.permissions && not isAdmin then
        text ""

    else
        expandableProfileSection "profile-permissions-section"
            "Permissions"
            expanded
            PermissionsExpandedToggled
            [ case maybeEdit of
                Just edit ->
                    div [ class "profile-permissions-edit" ]
                        [ div [ class "permission-badges" ] (edit.pending |> List.map permissionEditBadge)
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
                    div [ class "profile-permissions-view" ]
                        [ div [ class "permission-badges" ]
                            (user.permissions
                                |> List.map (\permission -> span [ class "permission-badge" ] [ text (Users.permissionText permission) ])
                            )
                        , if isAdmin then
                            button [ class "profile-edit-button", onClick PermissionsEditClicked ] [ text "Edit" ]

                          else
                            text ""
                        ]
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
                    available : List AccountsPanel.Account
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
        maybeFederatedServer : Maybe AccountsPanel.Server
        maybeFederatedServer =
            AccountsPanel.serverForHost shared.accounts.servers account.host

        colorClasses : List String
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
        reciprocated : Bool
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
`create_event_sync_source.rs`) -- gates just the add row. Collapsed by
default (`model.eventSyncSourcesExpanded`) behind `expandableProfileSection`'s
own header.
-}
eventSyncSourcesSection : Shared.Model -> Model -> Bool -> Bool -> Html Msg
eventSyncSourcesSection shared model canManage canAdd =
    if not canManage then
        text ""

    else
        expandableProfileSection "event-sync-sources-section"
            "Event Sync Sources"
            model.eventSyncSourcesExpanded
            EventSyncSourcesExpandedToggled
            (div [ class "event-sync-sources-list" ] (eventSyncSourcesContentView model.resolver.targetHost shared.time.browserTimeZone model.eventSyncSources)
                :: (if canAdd then
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
        edit : EventSyncRowEdit
        edit =
            eventSyncRowEditFor source es

        dirty : Bool
        dirty =
            eventSyncSourceIsDirty source edit

        submitting : Bool
        submitting =
            edit.status == Submitting

        lastSyncedText : String
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
    div [ classes [ "event-sync-source-row", "event-sync-source-add-row", hostnameToCSSClass targetHost ] ]
        [ input
            [ class "event-sync-source-url"
            , type_ "text"
            , value addForm.url
            , placeholder "New iCal subscription URL"
            , disabled (addForm.status == Submitting)
            , onInput EventSyncSourceAddUrlChanged
            ]
            []
        , eventSyncIntervalSelect EventSyncSourceAddIntervalChanged addForm.intervalSeconds (addForm.status == Submitting)
        , button
            [ classes [ "event-sync-source-add", "background-color-primary" ]
            , onClick EventSyncSourceAddClicked
            , disabled (addForm.status == Submitting || String.isEmpty (String.trim addForm.url))
            ]
            [ text
                (if addForm.status == Submitting then
                    "Adding…"

                 else
                    "+ Create New Source"
                )
            ]
        , case addForm.status of
            SubmitFailed err ->
                div [ class "event-sync-source-error" ] [ text err ]

            _ ->
                text ""
        ]


{-| Unlike `eventSyncSourcesSection`, this is shown (or not) as a single all-or-nothing check --
own profile, holding any of the 10 `SYNC_EVENTS_TO_*`/`SYNC_POSTS_TO_*` permission pairs (or
`ADMIN`) (see `canUseSyncDestinations`) -- rather than a separate `canManage`/`canAdd` split
(individual platform buttons within the section apply their own, more specific gate -- see
`platformPickerView`). There's no "view-only for an Admin visiting someone else's profile" case the
way sources have: a linked destination is always the _caller's own_
(`create_sync_destination.rs` always creates for `current_user`), so there's nothing for
anyone else to usefully see here.
-}
syncDestinationsSection : Shared.Model -> Model -> Maybe AccountsPanel.Account -> User -> Html Msg
syncDestinationsSection shared model maybeAccount user =
    if not (isOwnProfile maybeAccount user && canUseSyncDestinations maybeAccount) then
        text ""

    else
        expandableProfileSection "sync-destinations-section"
            "Sync Destinations"
            model.syncDestinationsExpanded
            SyncDestinationsExpandedToggled
            [ div [ class "sync-destinations-list" ] (syncDestinationsContentView model.syncDestinations user.syncDestinations)
            , platformConnectView shared model.resolver.targetHost maybeAccount model.syncDestinations
            ]


{-| Reads `destinations` straight off the profile's already-resolved `User`
(`user.syncDestinations`, self-or-Admin gated server-side -- see
`protos/users.proto`'s own doc on that field) rather than a separately
fetched/tracked status -- no "Loading…" state needed, same as nothing
elsewhere shows a "loading permissions" spinner for other `User` fields.
-}
syncDestinationsContentView : SyncDestinationsState -> List SyncDestination -> List (Html Msg)
syncDestinationsContentView ed destinations =
    if List.isEmpty destinations then
        [ div [ class "sync-destinations-message" ] [ text "No sync destinations linked yet." ] ]

    else
        List.map (syncDestinationRowView ed) destinations


syncDestinationRowView : SyncDestinationsState -> SyncDestination -> Html Msg
syncDestinationRowView ed destination =
    let
        platformLabel : String
        platformLabel =
            case destination.configuration of
                Just (DestinationConfiguration.FacebookPage _) ->
                    "Facebook Page"

                Just (DestinationConfiguration.InstagramAccount _) ->
                    "Instagram"

                Just (DestinationConfiguration.MastodonAccount _) ->
                    "Mastodon"

                Just (DestinationConfiguration.BlueskyAccount _) ->
                    "Bluesky"

                Just (DestinationConfiguration.XTwitterAccount _) ->
                    "X (Twitter)"

                Just (DestinationConfiguration.ThreadsAccount _) ->
                    "Threads"

                Nothing ->
                    "Sync Destination"

        destinationName : String
        destinationName =
            case destination.configuration of
                Just (DestinationConfiguration.FacebookPage page) ->
                    page.pageName

                Just (DestinationConfiguration.InstagramAccount account) ->
                    "@" ++ account.username

                Just (DestinationConfiguration.MastodonAccount account) ->
                    account.username ++ "@" ++ account.instanceHost

                Just (DestinationConfiguration.BlueskyAccount account) ->
                    account.handle

                Just (DestinationConfiguration.XTwitterAccount account) ->
                    "@" ++ account.username

                Just (DestinationConfiguration.ThreadsAccount account) ->
                    "@" ++ account.username

                Nothing ->
                    platformLabel

        count : Int
        count =
            destination.syncedEventInstanceCount |> Maybe.map Conversions.int64ToInt |> Maybe.withDefault 0

        deleting : Bool
        deleting =
            Dict.get destination.id ed.deleteStatuses == Just Submitting
    in
    div [ class "sync-destination-row list-item-bordered-color-primary" ]
        [ span [ class "sync-destination-name" ] [ text destinationName ]
        , span [ class "sync-destination-count" ] [ text (pluralCount count "event" ++ " synced") ]
        , button
            [ class "sync-destination-delete", onClick (SyncDestinationDeleteClicked destination), disabled deleting ]
            [ text
                (if deleting then
                    "Unlinking…"

                 else
                    "Unlink " ++ platformLabel
                )
            ]
        , case Dict.get destination.id ed.deleteStatuses of
            Just (SubmitFailed err) ->
                div [ class "sync-destination-error" ] [ text err ]

            _ ->
                text ""
        ]


pluralCount : Int -> String -> String
pluralCount count noun =
    String.fromInt count
        ++ " "
        ++ noun
        ++ (if count == 1 then
                ""

            else
                "s"
           )


{-| Renders whichever of the three connect flows (`login`/`mastodon`/`bluesky`) is currently in
progress, or -- if none are -- `platformPickerView`'s row of platform buttons. At most one flow is
ever in progress at a time (starting one doesn't clear the others' state, but the UI only ever
lets one be started, since the picker itself is hidden once any is in progress) -- see
`SyncDestinationsState`'s own doc.
-}
platformConnectView : Shared.Model -> String -> Maybe AccountsPanel.Account -> SyncDestinationsState -> Html Msg
platformConnectView shared host maybeAccount ed =
    if ed.login /= FacebookLoginNotStarted then
        facebookLoginView ed.login

    else if ed.mastodon /= MastodonConnectNotStarted then
        mastodonConnectView ed.mastodon

    else if ed.bluesky /= BlueskyConnectNotStarted then
        blueskyConnectView ed.bluesky

    else if ed.threads /= ThreadsConnectNotStarted then
        threadsConnectView ed.threads

    else
        platformPickerView shared host maybeAccount


{-| The platform picker row -- one button per platform the viewer can use (each gated on that
platform's own `SYNC_EVENTS_TO_*`/`SYNC_POSTS_TO_*` permission pair, mirroring
`hasSyncToFacebookPermission` and friends; Facebook/Instagram/Threads additionally require the
server having a Facebook App configured, see `facebookAppConfigured` -- Threads rides on that same
Meta App), plus a permanently-disabled X button -- there's no working `XTwitterAccount` create flow
at all client-side, since the server always rejects it (see `protos/sync.proto`'s own doc on
`XTwitterAccount`), so this doesn't build a form that can only ever fail.
-}
platformPickerView : Shared.Model -> String -> Maybe AccountsPanel.Account -> Html Msg
platformPickerView shared host maybeAccount =
    let
        facebookAppReady : Bool
        facebookAppReady =
            facebookAppConfigured shared host
    in
    div [ class "sync-destination-platform-picker" ]
        [ platformButton (hasSyncToFacebookPermission maybeAccount && facebookAppReady) FacebookLoginClicked "Sign in to Facebook Page"
        , platformButton (hasSyncToInstagramPermission maybeAccount && facebookAppReady) InstagramLoginClicked "Sign in to Instagram"
        , platformButton (hasSyncToMastodonPermission maybeAccount) MastodonConnectClicked "Connect Mastodon"
        , platformButton (hasSyncToBlueskyPermission maybeAccount) BlueskyConnectClicked "Connect Bluesky"
        , platformButton (hasSyncToThreadsPermission maybeAccount && facebookAppReady) ThreadsLoginClicked "Connect Threads"
        , if hasSyncToXTwitterPermission maybeAccount then
            button
                [ classes [ "sync-destination-login" ]
                , disabled True
                , title "X (Twitter) support is coming soon."
                ]
                [ text "X (Twitter) — Coming soon" ]

          else
            text ""
        ]


platformButton : Bool -> Msg -> String -> Html Msg
platformButton visible msg buttonText =
    if visible then
        button
            [ classes [ "sync-destination-login", "background-color-primary" ], onClick msg ]
            [ text buttonText ]

    else
        text ""


{-| Every step of `FacebookLoginStatus` (see its own doc) -- covers both the Facebook and
Instagram flows, since they share this one popup/page-list state machine.
-}
facebookLoginView : FacebookLoginStatus -> Html Msg
facebookLoginView login =
    case login of
        FacebookLoginNotStarted ->
            text ""

        FacebookLoginPopupOpen platform ->
            div [ class "sync-destinations-message" ] [ text ("Waiting for " ++ connectPlatformLabel platform ++ "…") ]

        FacebookLoginFetchingPages _ _ ->
            div [ class "sync-destinations-message" ] [ text "Loading your Facebook Pages…" ]

        FacebookLoginChoosingPage _ _ pages ->
            div [ class "sync-destination-page-picker" ]
                (div [ class "sync-destinations-message" ] [ text "Choose a Page to link:" ]
                    :: List.map
                        (\page ->
                            button
                                [ class "sync-destination-page-option", onClick (FacebookPageChosen page) ]
                                [ text page.name ]
                        )
                        pages
                )

        FacebookLoginNoPagesFound ->
            div [ class "sync-destinations-message" ] [ text "That Facebook account doesn't manage any Pages." ]

        FacebookLoginLinking platform page ->
            div [ class "sync-destinations-message" ] [ text ("Linking " ++ page.name ++ " for " ++ connectPlatformLabel platform ++ "…") ]

        FacebookLoginFailed err ->
            div [ class "sync-destination-error" ] [ text err ]


connectPlatformLabel : FacebookConnectPlatform -> String
connectPlatformLabel platform =
    case platform of
        ConnectFacebook ->
            "Facebook"

        ConnectInstagram ->
            "Instagram"


{-| The Mastodon "Connect" form -- instance host + Personal Access Token, see
`MastodonConnectStatus`'s own doc.
-}
mastodonConnectView : MastodonConnectStatus -> Html Msg
mastodonConnectView status =
    case status of
        MastodonConnectNotStarted ->
            text ""

        MastodonConnectEditing form ->
            div [ class "sync-destination-connect-form" ]
                [ div [ class "sync-destinations-message" ] [ text "Connect a Mastodon account:" ]
                , input
                    [ class "sync-destination-connect-input"
                    , placeholder "Instance host, e.g. mastodon.social"
                    , value form.instanceHost
                    , onInput MastodonInstanceHostChanged
                    ]
                    []
                , input
                    [ class "sync-destination-connect-input"
                    , type_ "password"
                    , placeholder "Personal Access Token"
                    , value form.accessToken
                    , onInput MastodonAccessTokenChanged
                    ]
                    []
                , button
                    [ classes [ "sync-destination-login", "background-color-primary" ]
                    , onClick MastodonConnectSubmitted
                    , disabled (String.isEmpty form.instanceHost || String.isEmpty form.accessToken)
                    ]
                    [ text "Connect" ]
                , button [ class "sync-destination-connect-cancel", onClick MastodonConnectCancelled ] [ text "Cancel" ]
                ]

        MastodonConnectLinking form ->
            div [ class "sync-destinations-message" ] [ text ("Linking " ++ form.instanceHost ++ "…") ]

        MastodonConnectFailed err ->
            div []
                [ div [ class "sync-destination-error" ] [ text err ]
                , button [ class "sync-destination-connect-cancel", onClick MastodonConnectClicked ] [ text "Try Again" ]
                ]


{-| The Bluesky "Connect" form -- handle + "App Password", see `BlueskyConnectStatus`'s own doc.
-}
blueskyConnectView : BlueskyConnectStatus -> Html Msg
blueskyConnectView status =
    case status of
        BlueskyConnectNotStarted ->
            text ""

        BlueskyConnectEditing form ->
            div [ class "sync-destination-connect-form" ]
                [ div [ class "sync-destinations-message" ] [ text "Connect a Bluesky account:" ]
                , input
                    [ class "sync-destination-connect-input"
                    , placeholder "Handle, e.g. jon.bsky.social"
                    , value form.handle
                    , onInput BlueskyHandleChanged
                    ]
                    []
                , input
                    [ class "sync-destination-connect-input"
                    , type_ "password"
                    , placeholder "App Password"
                    , value form.appPassword
                    , onInput BlueskyAppPasswordChanged
                    ]
                    []
                , button
                    [ classes [ "sync-destination-login", "background-color-primary" ]
                    , onClick BlueskyConnectSubmitted
                    , disabled (String.isEmpty form.handle || String.isEmpty form.appPassword)
                    ]
                    [ text "Connect" ]
                , button [ class "sync-destination-connect-cancel", onClick BlueskyConnectCancelled ] [ text "Cancel" ]
                ]

        BlueskyConnectLinking form ->
            div [ class "sync-destinations-message" ] [ text ("Linking " ++ form.handle ++ "…") ]

        BlueskyConnectFailed err ->
            div []
                [ div [ class "sync-destination-error" ] [ text err ]
                , button [ class "sync-destination-connect-cancel", onClick BlueskyConnectClicked ] [ text "Try Again" ]
                ]


{-| Every step of `ThreadsConnectStatus` (see its own doc) -- much shorter than
`facebookLoginView` since there's no page-picker step.
-}
threadsConnectView : ThreadsConnectStatus -> Html Msg
threadsConnectView status =
    case status of
        ThreadsConnectNotStarted ->
            text ""

        ThreadsConnectPopupOpen ->
            div [ class "sync-destinations-message" ] [ text "Waiting for Threads…" ]

        ThreadsConnectLinking ->
            div [ class "sync-destinations-message" ] [ text "Linking Threads…" ]

        ThreadsConnectFailed err ->
            div []
                [ div [ class "sync-destination-error" ] [ text err ]
                , button [ class "sync-destination-connect-cancel", onClick ThreadsLoginClicked ] [ text "Try Again" ]
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
