module Shared.AccountsPanel exposing
    ( AcceptedCreateAccount
    , Account
    , AccountForm
    , AddServerForm
    , Branding
    , Connection
    , FormStatus(..)
    , MaybeAccountServer
    , Model
    , Msg(..)
    , NewAccountType(..)
    , PendingCreateAccount
    , Server
    , ServerLogoSize(..)
    , Tab(..)
    , Token
    , accountAvatarUrl
    , accountDecoder
    , accountId
    , accountRowDomId
    , brandingFor
    , brandingOf
    , configurationOf
    , connectToServer
    , connectionOf
    , connectionUrl
    , createAccountModalBodyId
    , displayName
    , enabledAccountForServer
    , enabledAccounts
    , enabledServers
    , encodeAccount
    , grpcErrorToString
    , hasAdminAccount
    , init
    , initialLetter
    , isAdmin
    , isKnownServer
    , isMainServer
    , isSecure
    , knownConnectedServer
    , mainServerTheme
    , mediaBaseUrl
    , mediaUrl
    , performWithAccountServer
    , performWithOptionalAccountServer
    , recommendedFederatedServers
    , serverChipDomId
    , serverForHost
    , serverHasAccounts
    , serverInfoOf
    , serverNameAndLogo
    , serverThemeOf
    , serverUrl
    , serverWebPushPublicKey
    , shouldShowAddAccountForm
    , subscriptions
    , unreachableAccountHosts
    , update
    , updateServerConfig
    , withAccessToken
    )

{-| Everything behind the Accounts Panel: known servers, signed-into accounts,
the login/add-server forms, and the connectivity logic (host negotiation,
CDN backend\_host discovery) that gets you from a typed-in hostname to a
working connection.
-}

import Animation
import Browser.Dom as Dom
import Dict exposing (Dict)
import Grpc
import Html exposing (Html, div, img, text)
import Html.Attributes exposing (alt, class, src)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports
import Proto.Jonline exposing (AccessTokenResponse, ExpirableToken, FederatedServer, GetPushSubscriptionStatusResponse, PushSubscription, RefreshTokenResponse, ServerConfiguration, ServerInfo, User, defaultServerInfo)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.Permission exposing (Permission(..), fieldNumbersPermission)
import Proto.Jonline.WebUserInterface exposing (WebUserInterface)
import Request exposing (Request)
import Set
import Shared.AccountsPanel.AdminTab as AdminTab
import Shared.AccountsPanel.DebugTab as DebugTab
import Shared.Conversions exposing (timestampToPosix)
import Task exposing (Task)
import Time
import UI.Classes exposing (hostnameToCSSClass)
import UI.Flip
import UI.ServerTheme
import Url


type alias Model =
    { accounts : List Account
    , servers : List Server
    , accountForm : AccountForm
    , addServerForm : AddServerForm
    , showAccountsPanel : Bool

    -- Whether the "X Recommended Servers..." button (see `UI.recommendedServersStrip`)
    -- has been expanded into its horizontally-scrollable strip of chips.
    -- Purely session-transient UI state, not persisted -- reset to `False`
    -- whenever the Accounts Panel closes (`CloseAccountsPanel`/
    -- `ToggleAccountsPanel`), so it always starts collapsed again next time
    -- the panel opens, same as `addAccountFormExpanded` starting points but
    -- unconditionally rather than only-if-idle.
    , recommendedServersExpanded : Bool

    -- Once-fetched `ServerConfiguration`s (as `Server`s, so the same
    -- `serverNameAndLogo`/branding machinery renders them) for hosts
    -- currently recommended via `recommendedFederatedServers` -- keyed by
    -- `frontendHost`, populated lazily by `ToggleRecommendedServersExpanded`
    -- (a fresh disconnected placeholder inserted immediately, replaced once
    -- `GotRecommendedServerConfig` resolves) rather than eagerly for every
    -- federated server up front. Cleared for a host once it stops being
    -- recommended by getting added (`GotRecommendedServerAddResult`) or by
    -- being removed again (`FinishRemoveServer`, which also immediately
    -- refetches if the strip is still open) -- otherwise the host would
    -- reappear in the strip still pointing at stale/placeholder branding.
    -- Simply closing the panel leaves it in place -- harmless, and means
    -- reopening the strip doesn't re-fetch hosts it already has cached.
    , recommendedServerConnections : Dict String Server

    -- Whether the "Add Account/Server" form (Server/Username/Password/etc.)
    -- is expanded, once there's at least one account already -- see
    -- `shouldShowAddAccountForm`. Irrelevant (the form always shows) when
    -- `accounts` is empty.
    , addAccountFormExpanded : Bool

    -- Once the Username field names a known server, whether (and which of)
    -- "Log In"/"Create Account" has been picked -- see `ChooseLoginClicked`/
    -- `ChooseCreateAccountClicked`. `Nothing` while still at the
    -- Username-only step, before either's been picked: the Password field
    -- (see `UI.addAccountForm`) only renders once this is `Just _`, so its
    -- `autocomplete`/`name` can be set to "new-password" or "current-password"
    -- up front, rather than the field existing from the start with an
    -- autocomplete hint that's only a guess. For Log In, set the moment
    -- "Log In" is clicked; for Create Account, only once the policy
    -- confirmation modal's been accepted (`ConfirmCreateAccountClicked`) --
    -- see `acceptedCreateAccount`. Once set, the same button (now alongside a
    -- "<- Back" button, `NewAccountBackClicked`) actually submits via
    -- `LoginClicked`/`CreateAccountClicked`. Reset to `Nothing` by
    -- `NewAccountBackClicked`, a successful `GotAuthResult`, or the Server
    -- field changing (`setServerField`).
    , newAccountType : Maybe NewAccountType

    -- Set once `ChooseCreateAccountClicked` (the Username-step "Create
    -- Account" button) has resolved the target server's configuration, until
    -- the user accepts or cancels -- see `UI.createAccountConfirmationModal`.
    -- `Nothing` the rest of the time. Accepting moves the target
    -- server/username into `acceptedCreateAccount` and reveals the Password
    -- field; nothing here carries a password -- it doesn't exist yet.
    , createAccountConfirmation : Maybe PendingCreateAccount

    -- Set once the policy confirmation modal's been accepted
    -- (`ConfirmCreateAccountClicked`, "Accept and Continue") -- from then on,
    -- until the real `CreateAccount` RPC fires (`CreateAccountClicked`, now
    -- the Password field's own submit) or the flow's abandoned, this is what
    -- that RPC reads its server/username from (see `AcceptedCreateAccount`).
    -- `Nothing` the rest of the time.
    , acceptedCreateAccount : Maybe AcceptedCreateAccount

    -- The host this app is actually being viewed from (immutable for the
    -- session -- it's a plain SPA reload to change it).
    , browsingHost : String

    -- The server that host resolves to, once known: usually `browsingHost`
    -- itself, but corrected to a CDN's public `frontendHost` if `browsingHost`
    -- turns out to be a backend host presenting a different public identity
    -- (see `resolvedFrontendHost`). A mismatch between the two is shown as a
    -- warning (`UI.hostMismatchWarning`), which the user can click to force it
    -- back to `browsingHost` (`ResetMainFrontendHost`) -- same as the brief
    -- window before the main server's first connect resolves, this leaves
    -- `mainFrontendHost` pointing at a host with no `servers` entry until a
    -- reconnect adds one, which `UI.mainServer` already tolerates. This is
    -- also (ordinarily) the one server entry the user isn't allowed to remove
    -- from the Accounts Panel -- see `MainServerSelected` for how an admin
    -- can change it.
    , mainFrontendHost : String

    -- In-flight/settling FLIP slide animations for accounts just reordered
    -- via `MoveAccountUpClicked`/`MoveAccountDownClicked` (see
    -- `UI.Flip.MoveState`), keyed by `accountId`. An account with no entry
    -- here (the common case) just renders at rest.
    , moveAnimations : Dict String (UI.Flip.MoveState Msg)

    -- Same as `moveAnimations`, but for servers reordered via
    -- `MoveServerLeftClicked`/`MoveServerRightClicked`, keyed by
    -- `frontendHost`. Kept separate from `moveAnimations` (rather than one
    -- dict shared by both lists) since they're two independent keyed lists --
    -- an account id and a server host happening to collide as plain strings
    -- would otherwise cross-wire their animations.
    , serverMoveAnimations : Dict String (UI.Flip.MoveState Msg)

    -- Each account's enter/leave `UI.Flip.State`, keyed by `accountId` --
    -- `update`'s very last step (see `syncItemAnimations`) is always
    -- `UI.Flip.syncEnter accountId model.accounts`, which inserts a fresh
    -- `UI.Flip.enter` for any account that doesn't have an entry yet, so a
    -- newly-added account animates in with no need to hunt down every single
    -- "this added an account" code path by hand. An account mid fade-out
    -- after `RemoveAccountClicked` (confirmed via `UI.deleteConfirmationModal`)
    -- stays in `accounts` -- and its entry here keeps `removing = True` --
    -- until its fade actually finishes (`FinishRemoveAccount`), so it keeps
    -- rendering (fading/collapsing) instead of just vanishing. `init` seeds
    -- this with a plain `UI.Flip.restingState` (not `enter`) for every
    -- persisted account, so reloading the app doesn't replay their entrances.
    , accountAnimations : Dict String (UI.Flip.State Msg)

    -- Same as `accountAnimations`, but for servers (keyed by `frontendHost`)
    -- via `MoveServerLeftClicked`/`RemoveServerClicked`/`syncEnter .frontendHost
    -- model.servers` -- see `accountAnimations`'s own doc for why these stay
    -- separate dicts.
    , serverAnimations : Dict String (UI.Flip.State Msg)

    -- Whether `init`'s startup sweep -- reconnecting to every persisted server
    -- and checking/refreshing every one of its accounts' access tokens (see
    -- `refreshPermissionsForServer`) -- has fully settled. `persist` no-ops
    -- until this flips `True`, so a page load doesn't write (and broadcast to
    -- every other open tab -- see `Ports.persistAccountsAndServers`) a rapid
    -- burst of intermediate "0 servers, 1 server, 2 servers..." states as each
    -- reconnect/refresh trickles in -- see `pendingServerChecks` and
    -- `finishStartupUnit`.
    , accessTokenRefreshChecked : Bool

    -- How many of `init`'s startup reconnect attempts (one per persisted/
    -- missing server, plus the browsing host's own if it's not already known)
    -- haven't yet fully settled -- decremented by `finishStartupUnit` as each
    -- one finishes (immediately, on a failed reconnect; once every one of its
    -- accounts' access tokens has been checked, on a successful one -- see
    -- `GotServerPermissionsRefresh`). `accessTokenRefreshChecked` flips `True`
    -- (see `finishStartupUnit`) once this reaches zero. Meaningless (never
    -- read) once `accessTokenRefreshChecked` is `True`.
    , pendingServerChecks : Int

    -- Which of the Accounts Panel's tabs is showing (see `Tab`), plus the
    -- Debug/Admin tabs' own state -- see `Shared.AccountsPanel.DebugTab`/
    -- `Shared.AccountsPanel.AdminTab`. There's no `accountsAndServersTab` field
    -- alongside these two, since that tab's content is everything else in this
    -- `Model` -- the Accounts & Servers tab *is* the Accounts Panel, as far as
    -- this module's concerned.
    , activeTab : Tab
    , debugTab : DebugTab.Model
    , adminTab : AdminTab.Model

    -- Every account (keyed by `accountId`) with an active Web Push subscription registered by
    -- this browser -- the value is the subscription's `endpoint`, so `DisableNotificationsClicked`
    -- can pass it back to both `Ports.unsubscribeFromPush` and `UnregisterPushSubscription`. The
    -- Push API allows only *one* active subscription per browser origin, tied to one VAPID key --
    -- but `UI.notificationsButton` is only ever shown for an account on `browsingHost`, so every
    -- account that can appear here shares that same one server, and so that same one key/endpoint:
    -- several entries can (and normally will, once more than one local account on `browsingHost`
    -- has notifications on) legitimately share the exact same `endpoint` value at once, all riding
    -- the browser's one real subscription together. `DisableNotificationsClicked` only actually
    -- tears that subscription down (`Ports.unsubscribeFromPush`) once no other entry here still
    -- points at the same `endpoint` -- see its own `lastAccountOnThisEndpoint`. Not persisted
    -- across page loads -- `Ports.checkPushSubscription` (fired at `init`) tells us the browser's
    -- current `endpoint`, but not *which* local accounts on that server are actually registered
    -- for it (a browser subscription carries no notion of "account") -- so
    -- `resolvePendingPushSubscriptionCheck` verifies each candidate individually via
    -- `GetPushSubscriptionStatus` (see `GotPushSubscriptionStatusResult`) before adding it here,
    -- rather than assuming every local account on that server is registered.
    , pushSubscriptions : Dict String String

    -- Last known reason "Enable notifications" (or the register/unregister RPC that follows it)
    -- failed for a given `accountId`, if any -- e.g. "Notification permission wasn't granted.",
    -- or a `grpcErrorToString`. Surfaced by `UI.notificationsButton` so a failure (silently
    -- swallowed prior to this field's existence -- see its own git history) is actually visible
    -- instead of the button just doing nothing. Cleared whenever that account's button is clicked
    -- again, so a retry starts from a clean slate.
    , notificationErrors : Dict String String

    -- The `accountId` `EnableNotificationsClicked`/`DisableNotificationsClicked` most recently
    -- fired for -- `PushSubscriptionPortReceived` already carries its own `accountId` back, but
    -- `GotRegisterPushSubscriptionResult`/`GotUnregisterPushSubscriptionResult`'s `Err` case is
    -- just a bare `Grpc.Error` with no account info of its own, so this is what lets those two
    -- still know which `notificationErrors` entry to fill in.
    , pendingNotificationAccountId : Maybe String

    -- `Ports.checkPushSubscription`'s result, still waiting to be matched against an account (see
    -- `resolvePendingPushSubscriptionCheck`) -- fired once at `init`, but `model.servers` doesn't
    -- have any `Server.connected`/`webPushConfig` populated yet at that point (reconnects are all
    -- still in flight), so the very first match attempt almost always fails. Kept around (instead
    -- of discarded on that first failed attempt) and retried on every subsequent update until it
    -- either resolves or the app decides there's truly no matching account, so a page refresh
    -- correctly restores the notification toggle's "on" state once the relevant server actually
    -- finishes reconnecting, rather than only working by lucky timing.
    , pendingPushSubscriptionCheck : Maybe PushSubscriptionCheck
    }


type Msg
    = TabSelected Tab
    | DebugTabMsg DebugTab.Msg
    | AdminTabMsg AdminTab.Msg
    | ServerChanged String
    | UsernameChanged String
    | PasswordChanged String
    | PasswordVisibilityToggled
    | LoginClicked
    | CreateAccountClicked
    | ChooseLoginClicked
    | ChooseCreateAccountClicked
    | NewAccountBackClicked
    | GotCreateAccountServerInfo (Result Grpc.Error ( Connection, ServerConfiguration ))
    | GotCreateAccountModalViewport (Result Dom.Error Dom.Viewport)
    | AccessTokenResponseReceived Account AccessTokenResponse
    | CreateAccountModalScrolled Bool
    | ConfirmCreateAccountClicked
    | GotCreateAccountAcceptedTime Time.Posix
    | CancelCreateAccountClicked
    | GotAuthResult (Result Grpc.Error ( Connection, ServerConfiguration, RefreshTokenResponse ))
    | FederatedAccountReceived Account
    | GotReconnectResult String Bool Bool (Result Grpc.Error ( Connection, ServerConfiguration ))
    | GotMainServerResult (Result Grpc.Error ( Connection, ServerConfiguration ))
    | AccountsAndServersBroadcastReceived Decode.Value
    | ToggleAccountEnabled String
    | RemoveAccountClicked String
    | ToggleServerEnabled String
    | ReconnectServerClicked String
    | AddServerClicked
    | GotNewServerResult (Result Grpc.Error ( Connection, ServerConfiguration ))
    | ToggleRecommendedServersExpanded
    | GotRecommendedServerConfig String (Result Grpc.Error ( Connection, ServerConfiguration ))
    | RecommendedServerClicked String
    | GotRecommendedServerAddResult String (Result Grpc.Error ( Connection, ServerConfiguration ))
    | RemoveServerClicked String
    | ToggleAccountsPanel
    | CloseAccountsPanel
    | ShowAddAccountFormClicked
    | ReauthenticateButtonClicked Account
    | GotPermissionsRefresh String (Result Grpc.Error ( Account, User ))
    | GotServerPermissionsRefresh (List ( String, Result Grpc.Error ( Account, User ) ))
    | MainServerSelected String
    | ResetMainFrontendHost
    | ServerChipClicked String
    | SetWebUserInterfaceClicked String WebUserInterface
    | GotSetWebUserInterfaceResult (Result Grpc.Error ( Account, ServerConfiguration ))
    | RenameServerClicked String String
    | GotRenameServerResult (Result Grpc.Error ( Account, ServerConfiguration ))
    | ChangeServerShortNameClicked String String
    | GotChangeServerShortNameResult (Result Grpc.Error ( Account, ServerConfiguration ))
    | GotServerConfigSaveResult String ServerConfiguration
    | FocusInput String
    | ClearFieldClicked String Msg
    | ServerConnected Server
    | MoveAccountUpClicked String
    | MoveAccountDownClicked String
    | GotPreMovePositions String (List String) (List String) Int (Result Dom.Error ( ( Dom.Element, Dom.Element ), ( Dom.Element, Dom.Element ) ))
    | MoveServerLeftClicked String
    | MoveServerRightClicked String
    | GotPreMoveServerPositions String String Int (Result Dom.Error ( Dom.Element, Dom.Element ))
    | AnimateMove Animation.Msg
    | MoveSettled String
    | ServerMoveSettled String
    | FinishRemoveAccount String
    | FinishRemoveServer String
    | AnimateItemFlip Animation.Msg
    | EnableNotificationsClicked Account
    | DisableNotificationsClicked Account
    | PushSubscriptionPortReceived Decode.Value
    | GotRegisterPushSubscriptionResult (Result Grpc.Error ( Account, PushSubscription ))
    | GotUnregisterPushSubscriptionResult (Result Grpc.Error Account)
    | PushSubscriptionCheckReceived Decode.Value
    | GotPushSubscriptionStatusResult String (Result Grpc.Error ( Account, GetPushSubscriptionStatusResponse ))
    | NoOp


{-| A signed-into account on a server (identified by its `frontendHost`, e.g.
"jonline.io" -- see `Server`). `enabled` is a lightweight, non-destructive
"signed in/out" toggle: disabling an account keeps its tokens around so it can
be re-enabled without logging in again. Fully forgetting an account
(`RemoveAccountClicked`) is the "traditional" sign out.

`permissions` is refreshed via `GetCurrentUser` whenever the account's server
reconnects (app startup/reload, or the account being re-enabled) -- see
`refreshPermissions` -- so it's usually current, though it can still lag
between those refreshes if permissions change server-side. That same refresh
is what discovers a `refreshToken` no longer works (revoked, expired past its
own grace period) -- see `GotPermissionsRefresh` -- setting `needsPassword`
so the account shows as needing to be signed back into with a password rather
than silently failing every request.

-}
type alias Account =
    { server : String
    , userId : String
    , username : String
    , refreshToken : Token
    , accessToken : Token
    , enabled : Bool
    , avatarMediaId : Maybe String
    , permissions : List Permission
    , realName : String
    , needsPassword : Bool
    }


{-| A server the app knows about -- either from a persisted server list entry
or an account signed into it. `frontendHost` is the server's public identity,
e.g. "jonline.io" -- what a user types in and what accounts are keyed by.

`enabled` controls whether the server's (eventually public) data is included
when aggregating data across servers. It's tracked here (rather than only on
`connected`) because it's meaningful -- and persisted (see
`encodePersistedServer`) -- even while disconnected.

`connected` is everything that's only known once we've actually negotiated
with the server (see `negotiateServerConfig`): `Nothing` for a server that's
currently unreachable (down, moved, or just not tried yet this session) --
see `disconnectedServer`/`ReconnectServerClicked`. A server keeps its place in
`Model.servers` (and so its position in the persisted list/UI) whether or not
it's currently connected -- only `FinishRemoveServer` (an explicit user
delete) removes an entry outright.

-}
type alias Server =
    { frontendHost : String
    , enabled : Bool
    , connected : Maybe ConnectedServer
    }


{-| Everything about a `Server` that's only known once we've actually
connected to it: `backendHost`/`port_`/`tls` are the combination that's known
to work (`backendHost` is where its gRPC API actually lives, e.g.
"jonline.io.getj.online" behind a CDN -- discovered via
`GET {frontendHost}/backend_host`, see `discoverBackendHost` -- often the same
as `frontendHost`), and `configuration`/`branding` are real data, never a
placeholder.
-}
type alias ConnectedServer =
    { backendHost : String
    , port_ : Int
    , tls : Bool
    , configuration : ServerConfiguration
    , branding : Branding
    }


{-| A server's user-facing identity: its name, square logo (if any), and its
primary/nav brand colors -- decomposed into `UI.ServerTheme.ColorMeta` (text
color, light/dark variants) once, when `configuration` first arrives (see
`brandingFromConfig`), and cached here rather than recomputed on every
render. Combine with the app's current dark/light mode via
`serverThemeOf`/`serverThemeFor` to get the full `UI.ServerTheme.ServerTheme`.
-}
type alias Branding =
    { name : String
    , logoUrl : Maybe String
    , primary : UI.ServerTheme.ColorMeta
    , nav : UI.ServerTheme.ColorMeta
    }


{-| Where a `Server` lives: enough to build a URL, before we know anything
else about it.
-}
type alias Connection =
    { frontendHost : String
    , backendHost : String
    , port_ : Int
    , tls : Bool
    }


type FormStatus
    = Idle
    | Submitting
    | Errored String


{-| Which of the two flows `Model.newAccountType` is mid-way through --
picked by `ChooseLoginClicked`/`ChooseCreateAccountClicked` -- so the Password
field (see `UI.addAccountForm`) knows whether to ask the browser for a
"new-password" (with generation offered) or a "current-password" (with saved
passwords offered) autofill.
-}
type NewAccountType
    = CreateNewAccount
    | LoginToAccount


{-| Which of the Accounts Panel's tabs (see `UI.elm`'s `accountsPanel`/
`accountsPanelTabBar`) is showing -- `TabAccountsAndServers` is the default (and only
one always shown; the other two only appear once `UI.elm`'s `debugCount`/
`hasAdminAccount` say there's something to show). Named inverted from
`Shared.AccountsPanel.DebugTab`/`Shared.AccountsPanel.AdminTab` (`TabDebug`/
`TabAdmin`, not `DebugTab`/`AdminTab`), mirroring
`Components.Pages.ServerInformationPage`'s own `Tab`/`TabAbout`/`TabTheme`/etc.
-}
type Tab
    = TabAccountsAndServers
    | TabDebug
    | TabAdmin


type alias AccountForm =
    { server : String
    , username : String
    , password : String
    , status : FormStatus

    -- Whether the password field (see `UI.addAccountForm`) is currently
    -- rendered as plain text rather than masked -- toggled by its "show
    -- password" button (`PasswordVisibilityToggled`).
    , showPasswordAsText : Bool
    }


{-| The policy confirmation modal's own pending state, captured when
`ChooseCreateAccountClicked` first resolves the server (see
`GotCreateAccountServerInfo`) rather than re-read from `accountForm` later --
so the modal (and the `AcceptedCreateAccount` it produces) always names the
username that was on screen at the moment "Create Account" was clicked, even
if the form's fields somehow changed while the confirmation step
(`UI.createAccountConfirmationModal`) was up. There's no password here yet --
this step happens _before_ the Password field even renders (see
`Model.newAccountType`).
-}
type alias PendingCreateAccount =
    { server : Server
    , username : String

    -- Whether the user has scrolled the confirmation modal's policy text
    -- (see `UI.createAccountConfirmationModal`) to its bottom -- or it never
    -- needed scrolling in the first place, per `GotCreateAccountModalViewport`
    -- -- gating the modal's own "Accept and Continue" button so it can't be
    -- clicked past unread policy text.
    , reachedBottom : Bool
    }


{-| What's kept around once the user's actually accepted the policies
(`ConfirmCreateAccountClicked`, "Accept and Continue") -- from then on, until
the real `CreateAccount` RPC fires (`CreateAccountClicked`, now the Password
field's own submit) or the flow's abandoned (`NewAccountBackClicked`,
`setServerField`, a successful `GotAuthResult`), `server`/`username` are read
from here rather than `accountForm`, same reasoning as `PendingCreateAccount`.

`acceptedAt` is the click time of "Accept and Continue" itself, captured via
`Time.now` (see `GotCreateAccountAcceptedTime`) -- not yet sent with the
`CreateAccount` RPC (the API has no field for it), but kept on hand ready for
when it does.

-}
type alias AcceptedCreateAccount =
    { server : Server
    , username : String
    , acceptedAt : Maybe Time.Posix
    }


{-| The "Add Server" control's own status -- separate from `AccountForm`'s
since adding a server (an unauthenticated `GetServerConfiguration` probe) and
logging in are independent flows that can be in-flight/erroring independently.
The host being added is `AccountForm.server` itself -- the Server field is
shared between the two flows (see `AddServerClicked`).
-}
type alias AddServerForm =
    { status : FormStatus
    }


{-| Like `ExpirableToken`, but with a plain `Time.Posix` expiration instead of
a protobuf `Timestamp` (whose seconds are an `Int64`) -- directly comparable
to `Time.now`, and easy to persist as milliseconds.
-}
type alias Token =
    { token : String
    , expiresAt : Maybe Time.Posix
    }


type alias Flags =
    Decode.Value


type alias PersistedServer =
    { frontendHost : String
    , enabled : Bool
    }


type alias PersistedState =
    { accounts : List Account
    , servers : List PersistedServer
    }


{-| Identifies "act as this account (if any) on this server" by identity --
`( maybe userId, hostname )` -- rather than a live `Account`/`Server`
snapshot: `( Nothing, host )` means anonymous on `host`; `( Just userId,
host )` means that specific (must be enabled) account. Resolved fresh
against the current `Model` inside `performWithAccountServer`/
`performWithOptionalAccountServer`, so callers elsewhere in the app (see
`Components.PostCard`, `Components.Users`, `Shared.MarkdownPanel`) can store
just this pair -- e.g. across a page's own `Model` -- rather than a copy of
`Account`/`Server` that can go stale, and never need to know how tokens get
refreshed/persisted (`AccessTokenResponseReceived`) at all.
-}
type alias MaybeAccountServer =
    ( Maybe String, String )


{-| A stable identifier for an account: a user's id is only unique per-server.
-}
accountId : Account -> String
accountId account =
    account.server ++ "|" ++ account.userId


{-| The DOM `id` an account's row is rendered with (see `UI.accountRow`) --
purely so `MoveAccountUpClicked`/`MoveAccountDownClicked` can measure its
position before/after a reorder (`Browser.Dom.getElement`) to drive its
`UI.Flip` slide.
-}
accountRowDomId : String -> String
accountRowDomId id =
    "account-row-" ++ id


{-| The DOM `id` a server chip is rendered with -- the `UI.Flip.Horizontal`
counterpart of `accountRowDomId`, for `MoveServerLeftClicked`/
`MoveServerRightClicked`.
-}
serverChipDomId : String -> String
serverChipDomId frontendHost =
    "server-chip-" ++ hostnameToCSSClass frontendHost


accountAt : Int -> List Account -> Maybe Account
accountAt idx accounts =
    List.drop idx accounts |> List.head


accountIndex : String -> List Account -> Maybe Int
accountIndex id accounts =
    accounts
        |> List.indexedMap Tuple.pair
        |> List.filter (\( _, a ) -> accountId a == id)
        |> List.head
        |> Maybe.map Tuple.first


slice : Int -> Int -> List a -> List a
slice lo hi items =
    items |> List.drop lo |> List.take (hi - lo + 1)


{-| What `id` moving by `offset` (always +-1, from a move button) actually
swaps: normally just `id`'s own Account trading places with its single
`offset` neighbor -- but if that neighbor is on a _different_ server, `id`
sits at the edge of its own same-server group nearest that neighbor (top
edge moving up, bottom edge moving down), so every other Account on `id`'s
server on the _other_ side (below it moving up, above it moving down) comes
along too. That group is found by scanning _only_ away from the neighbor,
back across `id`'s own side -- same-server Accounts are already kept
contiguous elsewhere (see `sortMainServerAccountsFirst`/
`insertAfterSameServer`).

The neighbor's own same-server group has to come along too, though: it's
just as contiguous as `id`'s, so swapping `id`'s group past only the single
adjacent neighbor Account would split the neighbor's group in two (its far
side ending up on the wrong side of the moved group). So the neighbor side
is expanded the same way -- scanning _forward_, away from `id`, from
`neighborIdx`.

Returns the moved Accounts' index range `( lo, hi )` and the neighbor
group's own index range, or `Nothing` if `id` isn't found or there's no
neighbor in that direction.

-}
accountSwapRange : Int -> String -> List Account -> Maybe ( ( Int, Int ), ( Int, Int ) )
accountSwapRange offset id accounts =
    accountIndex id accounts
        |> Maybe.andThen
            (\i ->
                let
                    neighborIdx : Int
                    neighborIdx =
                        i + offset
                in
                case ( accountAt i accounts, accountAt neighborIdx accounts ) of
                    ( Just clicked, Just neighbor ) ->
                        if clicked.server == neighbor.server then
                            Just ( ( i, i ), ( neighborIdx, neighborIdx ) )

                        else
                            let
                                walk : Int -> String -> Int -> Int
                                walk step server idx =
                                    if (accountAt (idx + step) accounts |> Maybe.map .server) == Just server then
                                        walk step server (idx + step)

                                    else
                                        idx

                                movedEdge : Int
                                movedEdge =
                                    walk -offset clicked.server i

                                neighborEdge : Int
                                neighborEdge =
                                    walk offset neighbor.server neighborIdx
                            in
                            Just
                                ( ( min i movedEdge, max i movedEdge )
                                , ( min neighborIdx neighborEdge, max neighborIdx neighborEdge )
                                )

                    _ ->
                        Nothing
            )


{-| `accounts`' own order is exactly what `UI.accountsList` renders, so
reordering is just reordering this list (see `accountSwapRange`).
-}
moveAccountBy : Int -> String -> List Account -> List Account
moveAccountBy offset id accounts =
    case accountSwapRange offset id accounts of
        Nothing ->
            accounts

        Just ( ( lo, hi ), ( nlo, nhi ) ) ->
            if nhi < lo then
                List.take nlo accounts
                    ++ slice lo hi accounts
                    ++ slice nlo nhi accounts
                    ++ List.drop (hi + 1) accounts

            else
                List.take lo accounts
                    ++ slice nlo nhi accounts
                    ++ slice lo hi accounts
                    ++ List.drop (nhi + 1) accounts


{-| Kicks off a reorder move (see `accountSwapRange`): measures the pre-swap
position of the moved Account(s)' first/last row and the neighbor group's
first/last row it's swapping past (the "First" of FLIP), via
`GotPreMovePositions` -- so the resulting message has something to compare
the post-swap position against. A no-op (no neighbor in that direction) just
does nothing.
-}
beginAccountMove : Int -> String -> List Account -> Cmd Msg
beginAccountMove offset id accounts =
    case accountSwapRange offset id accounts of
        Nothing ->
            Cmd.none

        Just ( ( lo, hi ), ( nlo, nhi ) ) ->
            let
                movedIds : List String
                movedIds =
                    slice lo hi accounts |> List.map accountId

                neighborIds : List String
                neighborIds =
                    slice nlo nhi accounts |> List.map accountId

                movedFirstId : String
                movedFirstId =
                    List.head movedIds |> Maybe.withDefault id

                movedLastId : String
                movedLastId =
                    List.reverse movedIds |> List.head |> Maybe.withDefault id

                neighborFirstId : String
                neighborFirstId =
                    List.head neighborIds |> Maybe.withDefault id

                neighborLastId : String
                neighborLastId =
                    List.reverse neighborIds |> List.head |> Maybe.withDefault id
            in
            Task.attempt (GotPreMovePositions id movedIds neighborIds offset)
                (Task.map2 Tuple.pair
                    (Task.map2 Tuple.pair (Dom.getElement (accountRowDomId movedFirstId)) (Dom.getElement (accountRowDomId movedLastId)))
                    (Task.map2 Tuple.pair (Dom.getElement (accountRowDomId neighborFirstId)) (Dom.getElement (accountRowDomId neighborLastId)))
                )


{-| `servers`' own order is exactly what `UI.serversStrip` renders.
-}
moveServerBy : Int -> String -> List Server -> List Server
moveServerBy =
    UI.Flip.moveListItemBy .frontendHost


{-| Pins the `mainFrontendHost` server (if known yet) at the front of
`servers`, preserving the relative order of everything else -- run
unconditionally after every `update` (see its doc) so this holds both right
after app startup resolves `mainFrontendHost` from `browsingHost`
(`GotMainServerResult`) and whenever it's changed afterward
(`MainServerSelected`/`ResetMainFrontendHost`), without needing to fix up
`servers` by hand at each of those call sites. `UI.serverChip` relies on this
to special-case index `0` as the one, unmovable main server.
-}
sortMainServerFirst : Model -> Model
sortMainServerFirst model =
    let
        ( mainServers, otherServers ) =
            List.partition (\s -> s.frontendHost == model.mainFrontendHost) model.servers
    in
    { model | servers = mainServers ++ otherServers }


{-| Same idea as `sortMainServerFirst`, for `accounts` -- pins every account
on the `mainFrontendHost` server at the front, preserving the relative order
of everything else. Run at the same two points (see `sortMainServerFirst`'s
doc), this keeps the main server's account(s) contiguous at the front, which
is what lets `UI.accountRow` hide (rather than merely disable) an arrow that
would otherwise cross the main/non-main boundary -- moving a main-server
account below the group, or a non-main one above it -- instead of just
tracking each account's own up/down bounds.
-}
sortMainServerAccountsFirst : Model -> Model
sortMainServerAccountsFirst model =
    let
        ( mainAccounts, otherAccounts ) =
            List.partition (\a -> a.server == model.mainFrontendHost) model.accounts
    in
    { model | accounts = mainAccounts ++ otherAccounts }


{-| Whether an account has the `ADMIN` permission.
-}
isAdmin : Account -> Bool
isAdmin account =
    List.member ADMIN account.permissions


{-| Whether any _signed-in_ (enabled) account has `ADMIN` on its server --
gates showing the Server Admin Panel button at all.
-}
hasAdminAccount : Model -> Bool
hasAdminAccount model =
    List.any (\a -> a.enabled && isAdmin a) model.accounts


{-| Signed-in accounts -- what the accounts-menu toggle button renders as a
row of avatars instead of the "Login" label (see `UI.elm`'s
`accountsMenuButtonContent`).
-}
enabledAccounts : Model -> List Account
enabledAccounts model =
    List.filter .enabled model.accounts


{-| A username display enriched with the account's Real Name, if it has one --
e.g. "Jon Latane (jon)" rather than just "jon". Falls back to the bare
username when `realName` is empty (unset).
-}
displayName : Account -> String
displayName account =
    if String.isEmpty (String.trim account.realName) then
        account.username

    else
        account.realName ++ " (" ++ account.username ++ ")"


{-| The URL for an account's avatar, authorized with its own access token
(avatars can be visibility-restricted, but an account can always see its own).
-}
accountAvatarUrl : List Server -> Account -> Maybe String
accountAvatarUrl servers account =
    account.avatarMediaId
        |> Maybe.andThen
            (\id ->
                serverForHost servers account.server
                    |> Maybe.andThen (\s -> mediaUrl s id)
                    |> Maybe.map (\url -> url ++ "?authorization=" ++ account.accessToken.token)
            )


{-| The (unauthorized) base URL for a piece of media by `id` on `server` --
e.g. avatars belonging to some other user (see `Components.Users.avatarUrl`),
which the caller may still need to append its own `?authorization=` to if
that media turns out to be visibility-restricted. `Nothing` if `server` is
currently disconnected -- there's no host to fetch it from.
-}
mediaUrl : Server -> String -> Maybe String
mediaUrl server id =
    connectionOf server
        |> Maybe.map (\connection -> mediaBaseUrl connection ++ "/media/" ++ id)


{-| A server's branding, looked up by its `frontendHost` (for e.g. an
account's `server` field, cross-referenced against the server list), falling
back to the bare hostname and neutral colors if that server isn't known, or
is known but currently disconnected (see `Server.connected`).
-}
brandingFor : List Server -> String -> Branding
brandingFor servers frontendHost =
    serverForHost servers frontendHost
        |> Maybe.map brandingOf
        |> Maybe.withDefault (defaultBranding frontendHost)


defaultBranding : String -> Branding
defaultBranding frontendHost =
    { name = frontendHost
    , logoUrl = Nothing
    , primary = UI.ServerTheme.neutralColorMeta
    , nav = UI.ServerTheme.neutralColorMeta
    }


{-| A `Server`'s branding, falling back to the bare hostname and neutral
colors while it's disconnected (see `Server.connected`) -- `brandingFor`'s
same fallback, for callers that already have the `Server` in hand rather
than just its `frontendHost`.
-}
brandingOf : Server -> Branding
brandingOf server =
    server.connected
        |> Maybe.map .branding
        |> Maybe.withDefault (defaultBranding server.frontendHost)


{-| The full color theme for a server, combining its cached `branding` with
the app's current dark/light mode (`Shared.effectiveDarkMode`). Cheap -- fine
to call on every render.
-}
serverThemeOf : Bool -> Server -> UI.ServerTheme.ServerTheme
serverThemeOf darkMode server =
    let
        branding : Branding
        branding =
            brandingOf server
    in
    UI.ServerTheme.fromColorMetas darkMode branding.primary branding.nav


{-| Like `serverThemeOf`, but looks a server up by `frontendHost` (for e.g. an
account's `server` field).
-}
serverThemeFor : Bool -> Model -> String -> UI.ServerTheme.ServerTheme
serverThemeFor darkMode model frontendHost =
    let
        branding : Branding
        branding =
            brandingFor model.servers frontendHost
    in
    UI.ServerTheme.fromColorMetas darkMode branding.primary branding.nav


{-| The theme for chrome that isn't scoped to any one server/account row (nav
links, form buttons, etc.) -- currently always `mainFrontendHost`'s theme.
-}
mainServerTheme : Bool -> Model -> UI.ServerTheme.ServerTheme
mainServerTheme darkMode model =
    serverThemeFor darkMode model model.mainFrontendHost



-- SERVER NAME + LOGO
-- Port of the React app's `server_name_and_logo.tsx`: server names often
-- encode a short "badge" name before a `|` or the name's first emoji, with a
-- fuller name after it (e.g. "jonline.io | Jon's Cool Server 🎉"). This pulls
-- that apart and picks a logo (the server's square image, its emoji, or an
-- initial-letter placeholder, in that preference order) and font sizes so the
-- short badge name doesn't look tiny next to a long full one.


{-| `CompactServerLogo` is a single-line horizontal glyph+name, for tight
spaces like the nav bar; `RegularServerLogo` stacks a larger glyph above a
(possibly two-line) name, for the Accounts Panel's server chips.
`HorizontalServerLogo` is `RegularServerLogo`'s same larger glyph/(possibly
two-line) name, just laid out in a row (glyph left of the name) with the name
left-aligned instead of stacked/centered -- for contexts with more width to
spare than the nav bar but where a centered stack still reads oddly, e.g.
`Shared.Breadcrumbs`' server overview panel.
-}
type ServerLogoSize
    = RegularServerLogo
    | HorizontalServerLogo


serverNameAndLogo : Server -> ServerLogoSize -> Html msg
serverNameAndLogo server size =
    let
        branding : Branding
        branding =
            brandingOf server

        ( namePrefix, emoji, nameSuffix ) =
            splitOnFirstEmoji True branding.name

        largeName : Bool
        largeName =
            String.length namePrefix < 10 && (nameSuffix == Nothing || nameSuffix == Just "")

        logo : Html msg
        logo =
            case branding.logoUrl of
                Just url ->
                    img [ class "server-logo-image", src url, alt branding.name ] []

                Nothing ->
                    let
                        hasEmoji : Bool
                        hasEmoji =
                            case emoji of
                                Just e ->
                                    e /= "" && e /= "|"

                                Nothing ->
                                    False
                    in
                    if hasEmoji then
                        div [ class "server-logo-emoji" ] [ text (Maybe.withDefault "" emoji) ]

                    else
                        div [ class "server-logo-placeholder" ] [ text (initialLetter branding.name) ]

        -- The emoji never gets folded into the primary line, even when it's
        -- not already standing in as the logo above (i.e. there's a real
        -- image logo) -- appending it as text throws off the browser's width
        -- measurement for the nav's ellipsis-truncated name (emoji glyphs
        -- need font-fallback shaping that the intrinsic-sizing pass
        -- under-measures vs. their actual painted width), causing the name
        -- to truncate early even with plenty of room on screen.
        primaryLine : String
        primaryLine =
            namePrefix

        -- `RegularServerLogo` and `HorizontalServerLogo` share the same
        -- larger glyph size and "large" primary-line/secondary-line logic --
        -- they differ only in layout (stacked+centered vs. row+left-aligned,
        -- both via `sizeClass` below), not sizing.
        isBig : Bool
        isBig =
            True

        primaryClasses : List String
        primaryClasses =
            "server-name-primary"
                :: (if isBig && largeName then
                        [ "large" ]

                    else
                        []
                   )

        secondaryLine : Html msg
        secondaryLine =
            case nameSuffix of
                Just suffix ->
                    if isBig && not largeName && suffix /= "" then
                        div [ class "server-name-secondary" ] [ text suffix ]

                    else
                        text ""

                Nothing ->
                    text ""

        sizeClass : String
        sizeClass =
            case size of
                RegularServerLogo ->
                    "regular"

                HorizontalServerLogo ->
                    "horizontal"
    in
    div [ class ("server-name-and-logo " ++ sizeClass) ]
        [ logo
        , div [ class "server-name-breakdown" ]
            [ div [ class (String.join " " primaryClasses) ] [ text primaryLine ]
            , secondaryLine
            ]
        ]


{-| First letter of a name, upper-cased, for use as an avatar/logo placeholder
-- see `UI.imageOrInitial`.
-}
initialLetter : String -> String
initialLetter fullName =
    fullName
        |> String.trim
        |> String.uncons
        |> Maybe.map (Tuple.first >> Char.toUpper >> String.fromChar)
        |> Maybe.withDefault "?"


{-| Approximates the React app's `splitOnFirstEmoji` (which gets grapheme-
cluster splitting for free from `Intl.Segmenter`): finds the first
pictographic character (or, if `supportPipe`, a literal `|`) and splits the
string around it, trimming both sides. A found emoji is extended to swallow
any immediately-following variation-selector/ZWJ/skin-tone/pictographic/
regional-indicator characters, so most multi-codepoint emoji (flags, ZWJ
sequences, skin tones) stay together as one unit -- not a real grapheme
segmenter, but close enough for the short server names this is applied to.
-}
splitOnFirstEmoji : Bool -> String -> ( String, Maybe String, Maybe String )
splitOnFirstEmoji supportPipe fullText =
    let
        chars : List Char
        chars =
            String.toList fullText

        isSplitChar : Char -> Bool
        isSplitChar c =
            isPictographic c || (supportPipe && c == '|')
    in
    case findIndex isSplitChar chars of
        Nothing ->
            ( fullText, Nothing, Nothing )

        Just idx ->
            let
                before : String
                before =
                    List.take idx chars |> String.fromList |> String.trim

                atSplit : List Char
                atSplit =
                    List.drop idx chars
            in
            case atSplit of
                '|' :: rest ->
                    ( before, Just "|", ifNonEmpty (String.trim (String.fromList rest)) )

                _ ->
                    let
                        ( emojiChars, rest ) =
                            takeEmojiRun atSplit
                    in
                    ( before, Just (String.fromList emojiChars), ifNonEmpty (String.trim (String.fromList rest)) )


findIndex : (a -> Bool) -> List a -> Maybe Int
findIndex pred list =
    list
        |> List.indexedMap Tuple.pair
        |> List.filter (Tuple.second >> pred)
        |> List.head
        |> Maybe.map Tuple.first


takeEmojiRun : List Char -> ( List Char, List Char )
takeEmojiRun chars =
    case chars of
        first :: rest ->
            let
                ( continuation, remaining ) =
                    spanEmojiContinuation rest
            in
            ( first :: continuation, remaining )

        [] ->
            ( [], [] )


spanEmojiContinuation : List Char -> ( List Char, List Char )
spanEmojiContinuation chars =
    case chars of
        c :: rest ->
            if isEmojiContinuation c then
                let
                    ( more, remaining ) =
                        spanEmojiContinuation rest
                in
                ( c :: more, remaining )

            else
                ( [], chars )

        [] ->
            ( [], [] )


isEmojiContinuation : Char -> Bool
isEmojiContinuation c =
    isPictographic c || isVariationSelector c || isZeroWidthJoiner c || isSkinToneModifier c


isVariationSelector : Char -> Bool
isVariationSelector c =
    Char.toCode c == 0xFE0F


isZeroWidthJoiner : Char -> Bool
isZeroWidthJoiner c =
    Char.toCode c == 0x200D


isSkinToneModifier : Char -> Bool
isSkinToneModifier c =
    let
        code : Int
        code =
            Char.toCode c
    in
    code >= 0x0001F3FB && code <= 0x0001F3FF


isRegionalIndicator : Char -> Bool
isRegionalIndicator c =
    let
        code : Int
        code =
            Char.toCode c
    in
    code >= 0x0001F1E6 && code <= 0x0001F1FF


{-| Approximates Unicode's `Extended_Pictographic` property (which the React
app's regex engine gets for free) via known emoji code-point blocks -- covers
the vast majority of emoji actually used in server names.
-}
isPictographic : Char -> Bool
isPictographic c =
    let
        code : Int
        code =
            Char.toCode c
    in
    (code >= 0x0001F300 && code <= 0x0001FAFF)
        || (code >= 0x2600 && code <= 0x27BF)
        || (code >= 0x2300 && code <= 0x23FF)
        || (code >= 0x2B00 && code <= 0x2BFF)
        || isRegionalIndicator c


init : Request -> Flags -> ( Model, Cmd Msg )
init req flags =
    let
        persisted : PersistedState
        persisted =
            Decode.decodeValue persistedStateDecoder flags
                |> Result.withDefault emptyPersistedState

        pageIsSecure : Bool
        pageIsSecure =
            isSecure req

        browsingHost : String
        browsingHost =
            req.url.host

        -- The app is very often served up by a Jonline server itself, so whichever
        -- host it's being viewed from is worth auto-connecting to, same as any other
        -- server. If it's already a known server, this is a no-op -- the persisted
        -- entry (and its enabled flag) wins, and we already know it's not a
        -- backend-only host (see `GotMainServerResult`), so no correction is needed.
        browsingHostAlreadyKnown : Bool
        browsingHostAlreadyKnown =
            List.any (\s -> s.frontendHost == browsingHost) persisted.servers

        mainServerCmd : Cmd Msg
        mainServerCmd =
            if browsingHostAlreadyKnown then
                Cmd.none

            else
                negotiateServerConfig pageIsSecure browsingHost
                    |> Task.attempt GotMainServerResult

        reconnectCmds : List (Cmd Msg)
        reconnectCmds =
            List.map
                (\ps ->
                    negotiateServerConfig pageIsSecure ps.frontendHost
                        |> Task.attempt (GotReconnectResult ps.frontendHost ps.enabled False)
                )
                persisted.servers

        -- Accounts whose server host has no persisted Server entry at all (stale/
        -- corrupted localStorage, a server dropped by an old bug, etc.) would
        -- otherwise never get a reconnect attempt and stay permanently
        -- "unreachable" (see `unreachableAccountHosts`) even though we still have
        -- credentials for them. Treat each such host like any other reconnect,
        -- enabling it if any of its accounts are themselves enabled -- mirrors
        -- `ToggleAccountEnabled` bringing a disabled server along with an account
        -- being re-enabled.
        missingServerHosts : List String
        missingServerHosts =
            persisted.accounts
                |> List.map .server
                |> List.filter (\host -> not (List.any (\s -> s.frontendHost == host) persisted.servers))
                |> Set.fromList
                |> Set.toList

        missingServerCmds : List (Cmd Msg)
        missingServerCmds =
            List.map
                (\host ->
                    negotiateServerConfig pageIsSecure host
                        |> Task.attempt (GotReconnectResult host (List.any (\a -> a.server == host && a.enabled) persisted.accounts) False)
                )
                missingServerHosts

        -- One "unit" per reconnect attempt just dispatched above -- see
        -- `pendingServerChecks`/`finishStartupUnit`.
        initialPendingServerChecks : Int
        initialPendingServerChecks =
            (if browsingHostAlreadyKnown then
                0

             else
                1
            )
                + List.length persisted.servers
                + List.length missingServerHosts
    in
    ( { accounts = persisted.accounts

      -- Seeded disconnected (see `Server.connected`/`disconnectedServer`), in
      -- persisted order, rather than starting empty -- so a server stays in
      -- its place (and keeps showing, as disconnected, rather than just
      -- vanishing) if `reconnectCmds`/`missingServerCmds` below never bring
      -- it back this session. Each entry gets replaced in place (see
      -- `upsertServer`) once/if its own reconnect actually succeeds
      -- (`GotReconnectResult`).
      , servers =
            (persisted.servers |> List.map disconnectedServer)
                ++ (missingServerHosts
                        |> List.map
                            (\host ->
                                disconnectedServer
                                    { frontendHost = host
                                    , enabled = List.any (\a -> a.server == host && a.enabled) persisted.accounts
                                    }
                            )
                   )
      , accountForm = { emptyForm | server = browsingHost }
      , addServerForm = emptyAddServerForm
      , showAccountsPanel = False
      , recommendedServersExpanded = False
      , recommendedServerConnections = Dict.empty
      , addAccountFormExpanded = False
      , newAccountType = Nothing
      , createAccountConfirmation = Nothing
      , acceptedCreateAccount = Nothing
      , browsingHost = browsingHost
      , mainFrontendHost = browsingHost
      , moveAnimations = Dict.empty
      , serverMoveAnimations = Dict.empty

      -- Seeded with a *resting* (not `enter`) state for everything already
      -- persisted, so `syncItemAnimations` -- which would otherwise treat any
      -- id with no entry as "just appeared" -- doesn't replay every account's/
      -- server's entrance on every reload. Only genuinely new ones (signed in,
      -- or added, after this) start from `Dict.empty`-implied absence and so
      -- actually animate in.
      , accountAnimations = persisted.accounts |> List.map (\account -> ( accountId account, UI.Flip.restingState )) |> Dict.fromList
      , serverAnimations = persisted.servers |> List.map (\server -> ( server.frontendHost, UI.Flip.restingState )) |> Dict.fromList
      , accessTokenRefreshChecked = initialPendingServerChecks <= 0
      , pendingServerChecks = initialPendingServerChecks
      , activeTab = TabAccountsAndServers
      , debugTab = DebugTab.init
      , adminTab = AdminTab.init
      , pushSubscriptions = Dict.empty
      , notificationErrors = Dict.empty
      , pendingNotificationAccountId = Nothing
      , pendingPushSubscriptionCheck = Nothing
      }
    , Cmd.batch (Ports.checkPushSubscription Encode.null :: mainServerCmd :: reconnectCmds ++ missingServerCmds)
    )


{-| Just the accounts' reorder-slide animations (see `moveAnimations`) --
`Shared.subscriptions` batches this in with everything else.
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ UI.Flip.moveSubscription AnimateMove
            (Dict.values model.moveAnimations ++ Dict.values model.serverMoveAnimations)
        , UI.Flip.subscription AnimateItemFlip
            (Dict.values model.accountAnimations ++ Dict.values model.serverAnimations)
        , Ports.accountsAndServersUpdated AccountsAndServersBroadcastReceived
        , Ports.pushSubscribed PushSubscriptionPortReceived
        , Ports.pushSubscriptionChecked PushSubscriptionCheckReceived
        ]


{-| `sendUpdate`'s actual per-`Msg` logic, plus `syncItemAnimations`,
`sortMainServerFirst`, and `sortMainServerAccountsFirst` run unconditionally
afterward -- so every code path that can add an account/server, or change
`mainFrontendHost`, gets its enter animation/correct ordering for free,
without auditing each one by hand. Cheap enough (`accounts`/`servers` are
small) to run after every single message.
-}
update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    let
        ( updatedModel, cmd ) =
            sendUpdate req msg model
                |> Tuple.mapFirst syncItemAnimations
                |> Tuple.mapFirst sortMainServerFirst
                |> Tuple.mapFirst sortMainServerAccountsFirst

        ( resolvedModel, resolveCmd ) =
            resolvePendingPushSubscriptionCheck updatedModel
    in
    ( resolvedModel, Cmd.batch [ cmd, resolveCmd ] )


{-| Retries matching `pendingPushSubscriptionCheck` (see its own doc comment) against
`model.accounts`/`model.servers` on every update, not just when it first arrives -- the servers a
`PushSubscriptionCheck`'s `publicKey` needs to match against are usually still reconnecting (no
`Server.connected` yet) at the moment `checkPushSubscription`'s result actually comes back, so the
very first attempt almost always finds nothing. A no-op once there's nothing pending, or once a
match has already been dispatched -- cheap enough to run unconditionally alongside
`syncItemAnimations`/etc.

Doesn't just trust every matching account straight into `pushSubscriptions` -- the browser's
subscription only proves _some_ account on this server is registered for it, not which ones (see
`GetPushSubscriptionStatus`'s own RPC doc comment) -- so instead this fires one verification call
per matching account and lets `GotPushSubscriptionStatusResult` fill in `pushSubscriptions` only
for the ones the server actually confirms.

-}
resolvePendingPushSubscriptionCheck : Model -> ( Model, Cmd Msg )
resolvePendingPushSubscriptionCheck model =
    case model.pendingPushSubscriptionCheck of
        Nothing ->
            ( model, Cmd.none )

        Just check ->
            let
                matchingAccounts : List Account
                matchingAccounts =
                    model.accounts
                        |> List.filter (\account -> serverWebPushPublicKey model.servers account.server == Just check.publicKey)
            in
            if List.isEmpty matchingAccounts then
                ( model, Cmd.none )

            else
                ( { model | pendingPushSubscriptionCheck = Nothing }
                , matchingAccounts
                    |> List.filterMap
                        (\account ->
                            serverForHost model.servers account.server
                                |> Maybe.andThen connectionOf
                                |> Maybe.map
                                    (\connection ->
                                        performWithAccount
                                            connection
                                            account
                                            (\accessToken ->
                                                Grpc.new Jonline.getPushSubscriptionStatus { endpoint = check.endpoint }
                                                    |> Grpc.setHost (connectionUrl connection)
                                                    |> withAccessToken (Just accessToken)
                                                    |> Grpc.toTask
                                            )
                                            |> Task.attempt (GotPushSubscriptionStatusResult check.endpoint)
                                    )
                        )
                    |> Cmd.batch
                )


{-| Inserts a fresh `UI.Flip.enter` into `accountAnimations`/`serverAnimations`
for any account/server that doesn't have an entry yet -- see those fields'
own docs, and `UI.Flip.syncEnter`.
-}
syncItemAnimations : Model -> Model
syncItemAnimations model =
    { model
        | accountAnimations = UI.Flip.syncEnter accountId model.accounts model.accountAnimations
        , serverAnimations = UI.Flip.syncEnter .frontendHost model.servers model.serverAnimations
    }


sendUpdate : Request -> Msg -> Model -> ( Model, Cmd Msg )
sendUpdate req msg model =
    case msg of
        TabSelected tab ->
            ( { model | activeTab = tab }, Cmd.none )

        DebugTabMsg subMsg ->
            ( { model | debugTab = DebugTab.update subMsg model.debugTab }, Cmd.none )

        AdminTabMsg subMsg ->
            ( { model | adminTab = AdminTab.update subMsg model.adminTab }, Cmd.none )

        ServerChanged server ->
            ( setServerField server model, Cmd.none )

        UsernameChanged username ->
            ( updateForm (\form -> { form | username = username }) model, Cmd.none )

        PasswordChanged password ->
            ( updateForm
                (\form ->
                    { form
                        | password = password
                        , showPasswordAsText = form.showPasswordAsText && not (String.isEmpty password)
                    }
                )
                model
            , Cmd.none
            )

        PasswordVisibilityToggled ->
            ( updateForm (\form -> { form | showPasswordAsText = not form.showPasswordAsText }) model, Cmd.none )

        ChooseLoginClicked ->
            ( { model | newAccountType = Just LoginToAccount }
            , Task.attempt (\_ -> NoOp) (Dom.focus "account-form-password")
            )

        ChooseCreateAccountClicked ->
            let
                form : AccountForm
                form =
                    model.accountForm
            in
            ( model
                |> updateForm (\f -> { f | status = Submitting })
                |> updateAddServerForm (\f -> { f | status = clearErrored f.status })
            , resolveHost (isSecure req) model.servers (String.trim form.server)
                |> Task.attempt GotCreateAccountServerInfo
            )

        NewAccountBackClicked ->
            ( { model | newAccountType = Nothing, acceptedCreateAccount = Nothing }
                |> updateForm (\f -> { f | password = "", showPasswordAsText = False })
            , Cmd.none
            )

        LoginClicked ->
            let
                form : AccountForm
                form =
                    model.accountForm

                server : String
                server =
                    String.trim form.server
            in
            ( model
                |> updateForm (\f -> { f | status = Submitting })
                |> updateAddServerForm (\f -> { f | status = clearErrored f.status })
            , resolveHost (isSecure req) model.servers server
                |> Task.andThen
                    (\( connection, config ) ->
                        Grpc.new Jonline.login
                            { username = form.username
                            , password = form.password
                            , expiresAt = Nothing
                            , deviceName = Nothing
                            , userId = Nothing
                            }
                            |> Grpc.setHost (connectionUrl connection)
                            |> Grpc.toTask
                            |> Task.map (\resp -> ( connection, config, resp ))
                    )
                |> Task.attempt GotAuthResult
            )

        CreateAccountClicked ->
            case model.acceptedCreateAccount of
                Nothing ->
                    -- The submit button only renders once `newAccountType`
                    -- is `Just CreateNewAccount`, which only happens once
                    -- `acceptedCreateAccount` is set (`ConfirmCreateAccountClicked`)
                    -- -- unreachable in practice.
                    ( model, Cmd.none )

                Just accepted ->
                    case ( connectionOf accepted.server, accepted.server.connected ) of
                        ( Just connection, Just { configuration } ) ->
                            let
                                form : AccountForm
                                form =
                                    model.accountForm
                            in
                            ( model
                                |> updateForm (\f -> { f | status = Submitting })
                            , Grpc.new Jonline.createAccount
                                { username = accepted.username
                                , password = form.password
                                , email = Nothing
                                , phone = Nothing
                                , expiresAt = Nothing
                                , deviceName = Nothing
                                }
                                |> Grpc.setHost (connectionUrl connection)
                                |> Grpc.toTask
                                |> Task.map (\resp -> ( connection, configuration, resp ))
                                |> Task.attempt GotAuthResult
                            )

                        -- `accepted.server` was built by `serverFrom` (see
                        -- `GotCreateAccountServerInfo`), which is always connected --
                        -- unreachable in practice.
                        _ ->
                            ( model, Cmd.none )

        GotCreateAccountServerInfo (Ok ( connection, config )) ->
            let
                form : AccountForm
                form =
                    model.accountForm

                newModel : Model
                newModel =
                    { model
                        | createAccountConfirmation =
                            Just
                                { server = serverFrom connection True config
                                , username = form.username
                                , reachedBottom = False
                                }
                    }
            in
            ( updateForm (\f -> { f | status = Idle }) newModel
            , Task.attempt GotCreateAccountModalViewport (Dom.getViewportOf createAccountModalBodyId)
            )

        GotCreateAccountServerInfo (Err err) ->
            ( updateForm (\f -> { f | status = Errored (grpcErrorToString err) }) model
            , Cmd.none
            )

        GotCreateAccountModalViewport result ->
            case result of
                Ok viewport ->
                    -- The policy text didn't even need scrolling to begin
                    -- with (it all already fits) -- nothing more to wait on.
                    if viewport.scene.height <= viewport.viewport.height + 1 then
                        ( markCreateAccountBottomReached model, Cmd.none )

                    else
                        ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        CreateAccountModalScrolled atBottom ->
            ( if atBottom then
                markCreateAccountBottomReached model

              else
                model
            , Cmd.none
            )

        CancelCreateAccountClicked ->
            ( { model | createAccountConfirmation = Nothing }, Cmd.none )

        ConfirmCreateAccountClicked ->
            case model.createAccountConfirmation of
                Nothing ->
                    ( model, Cmd.none )

                Just pending ->
                    ( { model
                        | createAccountConfirmation = Nothing
                        , acceptedCreateAccount =
                            Just
                                { server = pending.server
                                , username = pending.username
                                , acceptedAt = Nothing
                                }
                        , newAccountType = Just CreateNewAccount
                      }
                    , Cmd.batch
                        [ Task.perform GotCreateAccountAcceptedTime Time.now
                        , Task.attempt (\_ -> NoOp) (Dom.focus "account-form-password")
                        ]
                    )

        GotCreateAccountAcceptedTime time ->
            ( { model
                | acceptedCreateAccount =
                    Maybe.map (\accepted -> { accepted | acceptedAt = Just time }) model.acceptedCreateAccount
              }
            , Cmd.none
            )

        GotAuthResult (Ok ( connection, config, resp )) ->
            case ( resp.user, resp.refreshToken, resp.accessToken ) of
                ( Just user, Just refreshToken, Just accessToken ) ->
                    let
                        account : Account
                        account =
                            { server = connection.frontendHost
                            , userId = user.id
                            , username = user.username
                            , refreshToken = tokenFromExpirable refreshToken
                            , accessToken = tokenFromExpirable accessToken
                            , enabled = True
                            , avatarMediaId = Maybe.map .id user.avatar
                            , permissions = user.permissions
                            , realName = user.realName
                            , needsPassword = False
                            }

                        newModel : Model
                        newModel =
                            { model
                                | accounts =
                                    upsertAccount account model.accounts
                                        |> disableOtherAccountsOnServer (accountId account) account.server
                                , servers =
                                    upsertServer (serverFrom connection True config) model.servers
                                        |> enableServerFor connection.frontendHost
                                , accountForm =
                                    let
                                        form : AccountForm
                                        form =
                                            model.accountForm
                                    in
                                    { form | password = "", showPasswordAsText = False, status = Idle }
                                , newAccountType = Nothing
                                , acceptedCreateAccount = Nothing
                            }
                    in
                    ( newModel, persist newModel )

                _ ->
                    ( updateForm (\f -> { f | status = Errored "Server response was missing user/token data." }) model
                    , Cmd.none
                    )

        GotAuthResult (Err err) ->
            ( updateForm (\f -> { f | status = Errored (grpcErrorToString err) }) model
            , Cmd.none
            )

        FederatedAccountReceived account ->
            -- Same upsert as `GotAuthResult`, but the account arrived already
            -- signed-in (via `Pages.Auth.From.EncodedAccount_`'s SSO hand-off)
            -- rather than through this form's own `LoginClicked` -- always
            -- enabled once accepted, regardless of what `enabled` it carried
            -- across the wire.
            let
                enabledAccount : Account
                enabledAccount =
                    { account | enabled = True }

                newModel : Model
                newModel =
                    { model
                        | accounts =
                            upsertAccount enabledAccount model.accounts
                                |> disableOtherAccountsOnServer (accountId enabledAccount) enabledAccount.server
                        , servers = enableServerFor enabledAccount.server model.servers
                    }

                -- The account's server may not be known (or may be known but
                -- disconnected) on this origin yet -- same situation `init`'s
                -- `missingServerHosts` handles for accounts surviving from stale/
                -- corrupted localStorage.
                reconnectCmd : Cmd Msg
                reconnectCmd =
                    if List.any (\s -> s.frontendHost == enabledAccount.server && s.connected /= Nothing) model.servers then
                        Cmd.none

                    else
                        negotiateServerConfig (isSecure req) enabledAccount.server
                            |> Task.attempt (GotReconnectResult enabledAccount.server True False)
            in
            ( newModel, Cmd.batch [ persist newModel, reconnectCmd ] )

        AccessTokenResponseReceived account accessTokenResponse ->
            let
                newModel : Model
                newModel =
                    { model
                        | accounts =
                            List.map
                                (\a ->
                                    if a.userId == account.userId && a.server == account.server then
                                        case ( accessTokenResponse.accessToken, accessTokenResponse.refreshToken ) of
                                            ( Just accessToken, Just refreshToken ) ->
                                                { a
                                                    | accessToken = tokenFromExpirable accessToken
                                                    , refreshToken = tokenFromExpirable refreshToken
                                                }

                                            ( Just accessToken, Nothing ) ->
                                                { a | accessToken = tokenFromExpirable accessToken }

                                            ( Nothing, Just refreshToken ) ->
                                                { a | refreshToken = tokenFromExpirable refreshToken }

                                            ( Nothing, Nothing ) ->
                                                a

                                    else
                                        a
                                )
                                model.accounts
                    }
            in
            ( newModel, persist newModel )

        GotReconnectResult frontendHost enabled appendToEnd result ->
            let
                insert : Server -> List Server -> List Server
                insert =
                    if appendToEnd then
                        upsertServerAppend

                    else
                        upsertServer
            in
            case result of
                Ok ( connection, config ) ->
                    let
                        server : Server
                        server =
                            serverFrom connection enabled config

                        newModel : Model
                        newModel =
                            { model | servers = insert server model.servers }
                    in
                    -- Replaces (rather than just skipping) any existing entry for this host,
                    -- keeping its place in the list (see `upsertServer`) -- this fires on
                    -- every reconnect (app startup/reload, `init`'s `reconnectCmds`), so an
                    -- unconditional append here would otherwise duplicate the server on each
                    -- successful reconnect. Also refresh permissions for any of its accounts
                    -- now that we can actually reach it -- this is what makes permissions
                    -- (and access tokens -- see `needsPassword`) current on app startup/
                    -- reload, not just after a fresh login. `refreshPermissionsForServer`
                    -- itself persists (this server's own addition included) once that
                    -- settles -- see its own doc.
                    ( newModel
                    , refreshPermissionsForServer server newModel.accounts
                    )

                Err _ ->
                    -- Couldn't reconnect (server's down, moved, etc.). Rather than dropping it
                    -- (which would silently erase it from what's persisted, see
                    -- `encodePersistedServer`, the very next time `persist` fires), mark/keep
                    -- it disconnected in place -- `disconnectedServer` if this host has no
                    -- entry yet at all (e.g. a federated server whose very first negotiation
                    -- failed), otherwise leave any existing entry (already disconnected, or
                    -- about to be replaced by a still-in-flight reconnect for the same host)
                    -- untouched. Still settles this server's startup-sweep unit, if one's
                    -- pending -- see `settleStartupUnit`.
                    let
                        newModel : Model
                        newModel =
                            if List.any (\s -> s.frontendHost == frontendHost) model.servers then
                                model

                            else
                                { model | servers = insert (disconnectedServer { frontendHost = frontendHost, enabled = enabled }) model.servers }
                    in
                    settleStartupUnit newModel

        GotMainServerResult result ->
            case result of
                Ok ( connection, config ) ->
                    let
                        -- If the host we're browsing from turns out to be a backend-only
                        -- host presenting a different public identity (e.g. we ended up on
                        -- jonline.io.getj.online, a CDN's backend, when jonline.io is the
                        -- real front door), treat *that* as the main server instead --
                        -- exactly as if the user had typed it in directly.
                        resolvedFrontend : String
                        resolvedFrontend =
                            resolvedFrontendHost model.browsingHost config

                        correctedConnection : Connection
                        correctedConnection =
                            { connection | frontendHost = resolvedFrontend }

                        server : Server
                        server =
                            serverFrom correctedConnection True config

                        newModel : Model
                        newModel =
                            { model
                                | mainFrontendHost = resolvedFrontend
                                , servers = upsertServer server model.servers
                            }

                        -- The base host may recommend other servers to federate with (see
                        -- `federation.proto`'s `FederatedServer`). At this first-setup moment
                        -- (this whole branch only runs the first time we've ever seen this
                        -- browsing host -- see `init`'s `browsingHostAlreadyKnown`), connect to
                        -- each one that's `configuredByDefault`, appending it to the *end* of
                        -- the server list once negotiated (see `upsertServerAppend`) -- unlike
                        -- a server added later (which lands right after the current server, see
                        -- `upsertServer`), these are recommendations the user didn't ask for, so
                        -- they shouldn't jump ahead of any server already in the list.
                        -- `pinnedByDefault` ones are enabled immediately, the rest added
                        -- disabled for the user to opt into.
                        federatedServerCmds : List (Cmd Msg)
                        federatedServerCmds =
                            config.federationInfo
                                |> Maybe.map .servers
                                |> Maybe.withDefault []
                                |> List.filter
                                    (\fs ->
                                        fs.host /= resolvedFrontend && Maybe.withDefault False fs.configuredByDefault
                                    )
                                |> List.map
                                    (\fs ->
                                        negotiateServerConfig (isSecure req) fs.host
                                            |> Task.attempt (GotReconnectResult fs.host (Maybe.withDefault False fs.pinnedByDefault) True)
                                    )
                    in
                    -- `refreshPermissionsForServer` persists (this server's own addition/
                    -- `mainFrontendHost` change included) once it settles -- see its own doc.
                    ( newModel
                    , Cmd.batch (refreshPermissionsForServer server newModel.accounts :: federatedServerCmds)
                    )

                Err _ ->
                    -- Still settles this server's startup-sweep unit, if one's pending -- see
                    -- `settleStartupUnit`.
                    settleStartupUnit model

        AccountsAndServersBroadcastReceived value ->
            case Decode.decodeValue persistedStateDecoder value of
                Err _ ->
                    ( model, Cmd.none )

                Ok persisted ->
                    let
                        -- Every host the broadcast still lists, keeping this tab's existing
                        -- entry (connected or disconnected -- see `Server.connected`) in place
                        -- if it has one, adopting the broadcasting tab's `enabled` flag;
                        -- otherwise seeding a fresh disconnected placeholder (e.g. a server
                        -- added in another tab this one hasn't reconnected to yet -- mirrors
                        -- `init`'s own seeding). Drops any host this tab knows about that the
                        -- broadcast no longer lists (removed there via `RemoveServerClicked`).
                        keptServers : List Server
                        keptServers =
                            persisted.servers
                                |> List.map
                                    (\ps ->
                                        model.servers
                                            |> List.filter (\s -> s.frontendHost == ps.frontendHost)
                                            |> List.head
                                            |> Maybe.map (\s -> { s | enabled = ps.enabled })
                                            |> Maybe.withDefault (disconnectedServer ps)
                                    )

                        -- Hosts already connected -- no need to attempt another reconnect for
                        -- those; anything else (never known, or known but still disconnected)
                        -- gets one, mirroring `init`'s `reconnectCmds`.
                        connectedHosts : List String
                        connectedHosts =
                            keptServers |> List.filter (\s -> s.connected /= Nothing) |> List.map .frontendHost

                        newServerCmds : List (Cmd Msg)
                        newServerCmds =
                            persisted.servers
                                |> List.filter (\ps -> not (List.member ps.frontendHost connectedHosts))
                                |> List.map
                                    (\ps ->
                                        negotiateServerConfig (isSecure req) ps.frontendHost
                                            |> Task.attempt (GotReconnectResult ps.frontendHost ps.enabled False)
                                    )

                        -- Same as `init`'s `missingServerHosts`/`missingServerCmds`: accounts
                        -- whose server host isn't in `persisted.servers` at all (stale/
                        -- corrupted state in the broadcasting tab) still deserve a reconnect
                        -- attempt here.
                        missingServerHosts : List String
                        missingServerHosts =
                            persisted.accounts
                                |> List.map .server
                                |> List.filter (\host -> not (List.any (\ps -> ps.frontendHost == host) persisted.servers))
                                |> Set.fromList
                                |> Set.toList

                        missingServerCmds : List (Cmd Msg)
                        missingServerCmds =
                            List.map
                                (\host ->
                                    negotiateServerConfig (isSecure req) host
                                        |> Task.attempt (GotReconnectResult host (List.any (\a -> a.server == host && a.enabled) persisted.accounts) False)
                                )
                                missingServerHosts

                        newModel : Model
                        newModel =
                            { model
                                | accounts = persisted.accounts
                                , servers = keptServers
                            }
                    in
                    ( newModel, Cmd.batch (newServerCmds ++ missingServerCmds) )

        ToggleAccountEnabled id ->
            let
                toggledAccounts : List Account
                toggledAccounts =
                    List.map
                        (\account ->
                            if accountId account == id then
                                { account | enabled = not account.enabled }

                            else
                                account
                        )
                        model.accounts

                justEnabledAccount : Maybe Account
                justEnabledAccount =
                    toggledAccounts
                        |> List.filter (\a -> accountId a == id && a.enabled)
                        |> List.head

                -- Only one account per server may be enabled (signed in) at a time --
                -- enabling this one disables any other account already enabled on the
                -- same server.
                exclusiveAccounts : List Account
                exclusiveAccounts =
                    case justEnabledAccount of
                        Just account ->
                            disableOtherAccountsOnServer id account.server toggledAccounts

                        Nothing ->
                            toggledAccounts

                newServers : List Server
                newServers =
                    case justEnabledAccount of
                        Just account ->
                            enableServerFor account.server model.servers

                        Nothing ->
                            model.servers

                newModel : Model
                newModel =
                    { model | accounts = exclusiveAccounts, servers = newServers }

                refreshCmd : Cmd Msg
                refreshCmd =
                    justEnabledAccount
                        |> Maybe.andThen
                            (\account ->
                                serverForHost newModel.servers account.server
                                    |> Maybe.map (\server -> refreshPermissions server account)
                            )
                        |> Maybe.withDefault Cmd.none
            in
            ( newModel, Cmd.batch [ persist newModel, refreshCmd ] )

        RemoveAccountClicked id ->
            -- Doesn't actually remove the account yet -- starts its fade-out
            -- (see `accountAnimations`), which sends `FinishRemoveAccount` once
            -- that finishes to do the real removal.
            let
                currentState : UI.Flip.State Msg
                currentState =
                    Dict.get id model.accountAnimations |> Maybe.withDefault UI.Flip.restingState
            in
            ( { model | accountAnimations = Dict.insert id (UI.Flip.remove (FinishRemoveAccount id) currentState) model.accountAnimations }
            , Cmd.none
            )

        FinishRemoveAccount id ->
            let
                newModel : Model
                newModel =
                    { model
                        | accounts = List.filter (\account -> accountId account /= id) model.accounts
                        , accountAnimations = Dict.remove id model.accountAnimations
                    }
            in
            ( newModel, persist newModel )

        MoveAccountUpClicked id ->
            ( model, beginAccountMove -1 id model.accounts )

        MoveAccountDownClicked id ->
            ( model, beginAccountMove 1 id model.accounts )

        GotPreMovePositions id _ _ offset (Err _) ->
            -- Couldn't measure -- e.g. a row not actually mounted -- fall back to
            -- swapping without a slide animation, same end state either way.
            let
                newModel : Model
                newModel =
                    { model | accounts = moveAccountBy offset id model.accounts }
            in
            ( newModel, persist newModel )

        GotPreMovePositions id movedIds neighborIds offset (Ok ( ( movedFirstEl, movedLastEl ), ( neighborFirstEl, neighborLastEl ) )) ->
            -- `movedIds`' post-swap position is derivable from this one
            -- (pre-swap) measurement of its first/last row and the
            -- neighbor group's first/last row it's swapping past (see
            -- `accountSwapRange`). Computing it this way (rather than
            -- swapping first, then measuring again after the next render)
            -- means the pinned "Invert" transform is set in the very same
            -- update as the swap, so there's no frame where the swapped
            -- list renders at rest before the animation kicks in.
            let
                newModel : Model
                newModel =
                    { model | accounts = moveAccountBy offset id model.accounts }

                -- Both groups span from their first row's top to their last
                -- row's bottom -- a single synthetic rect standing in for
                -- each whole group, so `UI.Flip.swapDeltas` (built for a
                -- plain two-item swap) can compute one shared slide delta
                -- for each side.
                span : Dom.Element -> Dom.Element -> Dom.Element
                span firstEl lastEl =
                    { firstEl
                        | element =
                            { x = firstEl.element.x
                            , y = firstEl.element.y
                            , width = firstEl.element.width
                            , height = lastEl.element.y + lastEl.element.height - firstEl.element.y
                            }
                    }

                ( movedDelta, neighborDelta ) =
                    UI.Flip.swapDeltas UI.Flip.Vertical (span movedFirstEl movedLastEl) (span neighborFirstEl neighborLastEl)

                startOrRestart : ( Float, Float ) -> String -> Dict String (UI.Flip.MoveState Msg) -> Dict String (UI.Flip.MoveState Msg)
                startOrRestart delta key anims =
                    Dict.insert key (UI.Flip.startMove (MoveSettled key) delta (Dict.get key anims |> Maybe.withDefault UI.Flip.atRest)) anims

                newMoveAnimations : Dict String (UI.Flip.MoveState Msg)
                newMoveAnimations =
                    newModel.moveAnimations
                        |> (\anims -> List.foldl (startOrRestart movedDelta) anims movedIds)
                        |> (\anims -> List.foldl (startOrRestart neighborDelta) anims neighborIds)
            in
            ( { newModel | moveAnimations = newMoveAnimations }, persist newModel )

        MoveServerLeftClicked id ->
            ( model, UI.Flip.beginReorder .frontendHost serverChipDomId GotPreMoveServerPositions -1 id model.servers )

        MoveServerRightClicked id ->
            ( model, UI.Flip.beginReorder .frontendHost serverChipDomId GotPreMoveServerPositions 1 id model.servers )

        GotPreMoveServerPositions id _ offset (Err _) ->
            let
                newModel : Model
                newModel =
                    { model | servers = moveServerBy offset id model.servers }
            in
            ( newModel, persist newModel )

        GotPreMoveServerPositions id neighborId offset (Ok ( chipEl, neighborEl )) ->
            let
                newModel : Model
                newModel =
                    { model | servers = moveServerBy offset id model.servers }
            in
            ( { newModel
                | serverMoveAnimations =
                    UI.Flip.applyReorder UI.Flip.Horizontal ServerMoveSettled id neighborId chipEl neighborEl newModel.serverMoveAnimations
              }
            , persist newModel
            )

        AnimateMove animMsg ->
            let
                step : String -> UI.Flip.MoveState Msg -> ( Dict String (UI.Flip.MoveState Msg), List (Cmd Msg) ) -> ( Dict String (UI.Flip.MoveState Msg), List (Cmd Msg) )
                step key state ( states, cmds ) =
                    let
                        ( newState, cmd ) =
                            UI.Flip.moveAnimate animMsg state
                    in
                    ( Dict.insert key newState states, cmd :: cmds )

                ( newMoveAnimations, moveCmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.moveAnimations

                ( newServerMoveAnimations, serverMoveCmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.serverMoveAnimations
            in
            ( { model | moveAnimations = newMoveAnimations, serverMoveAnimations = newServerMoveAnimations }
            , Cmd.batch (moveCmds ++ serverMoveCmds)
            )

        MoveSettled id ->
            ( { model | moveAnimations = Dict.update id (Maybe.map (\state -> { state | moving = False })) model.moveAnimations }
            , Cmd.none
            )

        ServerMoveSettled id ->
            ( { model | serverMoveAnimations = Dict.update id (Maybe.map (\state -> { state | moving = False })) model.serverMoveAnimations }
            , Cmd.none
            )

        AnimateItemFlip animMsg ->
            let
                step : String -> UI.Flip.State Msg -> ( Dict String (UI.Flip.State Msg), List (Cmd Msg) ) -> ( Dict String (UI.Flip.State Msg), List (Cmd Msg) )
                step key state ( states, cmds ) =
                    let
                        ( newState, cmd ) =
                            UI.Flip.animate animMsg state
                    in
                    ( Dict.insert key newState states, cmd :: cmds )

                ( newAccountAnimations, accountCmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.accountAnimations

                ( newServerAnimations, serverCmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.serverAnimations
            in
            ( { model | accountAnimations = newAccountAnimations, serverAnimations = newServerAnimations }
            , Cmd.batch (accountCmds ++ serverCmds)
            )

        ToggleServerEnabled frontendHost ->
            let
                wasEnabled : Bool
                wasEnabled =
                    serverForHost model.servers frontendHost
                        |> Maybe.map .enabled
                        |> Maybe.withDefault False

                newModel : Model
                newModel =
                    { model
                        | servers =
                            List.map
                                (\server ->
                                    if server.frontendHost == frontendHost then
                                        { server | enabled = not server.enabled }

                                    else
                                        server
                                )
                                model.servers

                        -- Disabling a server takes its accounts along with it -- an account
                        -- signed into a server that's no longer included in aggregated data
                        -- shouldn't itself keep counting as "signed in" (e.g. for
                        -- `enabledAccounts`, or the Home feed). Re-enabling the server
                        -- doesn't reverse this automatically -- that's a deliberate,
                        -- separate choice per account, same as signing in fresh.
                        , accounts =
                            if wasEnabled then
                                List.map
                                    (\account ->
                                        if account.server == frontendHost then
                                            { account | enabled = False }

                                        else
                                            account
                                    )
                                    model.accounts

                            else
                                model.accounts
                    }
            in
            ( newModel, persist newModel )

        ReconnectServerClicked frontendHost ->
            -- Manual retry for a disconnected server (see `Server.connected`) --
            -- functionally identical to `init`'s own `reconnectCmds`, just fired
            -- on demand rather than at startup. Keeps whatever `enabled` this
            -- host currently has; `GotReconnectResult` replaces the placeholder
            -- in place (preserving its position) on success, or leaves it
            -- disconnected on failure.
            let
                enabled : Bool
                enabled =
                    serverForHost model.servers frontendHost
                        |> Maybe.map .enabled
                        |> Maybe.withDefault False
            in
            ( model
            , negotiateServerConfig (isSecure req) frontendHost
                |> Task.attempt (GotReconnectResult frontendHost enabled False)
            )

        AddServerClicked ->
            let
                host : String
                host =
                    String.trim model.accountForm.server
            in
            if String.isEmpty host then
                ( model, Cmd.none )

            else if List.any (\s -> s.frontendHost == host && s.connected /= Nothing) model.servers then
                ( model
                    |> updateAddServerForm (\f -> { f | status = Errored "That server is already in your list." })
                    |> updateForm (\f -> { f | status = clearErrored f.status })
                , Cmd.none
                )

            else
                -- Also reached for a host that's already in the list but currently
                -- disconnected (see `Server.connected`) -- functions as that
                -- placeholder's "Reconnect" (see `ReconnectServerClicked`), just via
                -- the Add Server form instead of a dedicated button.
                ( model
                    |> updateAddServerForm (\f -> { f | status = Submitting })
                    |> updateForm (\f -> { f | status = clearErrored f.status })
                , negotiateServerConfig (isSecure req) host
                    |> Task.attempt GotNewServerResult
                )

        GotNewServerResult result ->
            case result of
                Ok ( connection, config ) ->
                    let
                        newModel : Model
                        newModel =
                            { model
                                | servers = upsertServer (serverFrom connection True config) model.servers
                                , addServerForm = emptyAddServerForm
                            }
                    in
                    -- The server just typed into the (shared) Server field is now valid, so
                    -- Username/Password become enabled -- move focus there, same as if the
                    -- user had hit Enter on an already-known server (see `formView`).
                    ( newModel
                    , Cmd.batch [ persist newModel, Task.attempt (\_ -> NoOp) (Dom.focus "account-form-username") ]
                    )

                Err err ->
                    ( updateAddServerForm (\f -> { f | status = Errored (grpcErrorToString err) }) model
                    , Cmd.none
                    )

        ToggleRecommendedServersExpanded ->
            let
                newlyExpanded : Bool
                newlyExpanded =
                    not model.recommendedServersExpanded

                -- Only fetch hosts we haven't already cached (see
                -- `recommendedServerConnections`'s own doc) -- reopening the
                -- strip after having already expanded it once this session
                -- shouldn't re-fetch everything from scratch.
                hostsToFetch : List String
                hostsToFetch =
                    if newlyExpanded then
                        recommendedFederatedServers model
                            |> List.map .host
                            |> List.filter (\host -> not (Dict.member host model.recommendedServerConnections))

                    else
                        []

                newModel : Model
                newModel =
                    { model
                        | recommendedServersExpanded = newlyExpanded

                        -- Seeded disconnected immediately (same idea as `init`'s own
                        -- `disconnectedServer` seeding), so each chip has something to
                        -- render -- a "loading" look, via the same
                        -- `server-chip-disconnected` styling -- the instant the strip
                        -- expands, rather than staying blank until its fetch resolves.
                        , recommendedServerConnections =
                            List.foldl
                                (\host -> Dict.insert host (disconnectedServer { frontendHost = host, enabled = False }))
                                model.recommendedServerConnections
                                hostsToFetch
                    }
            in
            ( newModel
            , hostsToFetch
                |> List.map
                    (\host ->
                        negotiateServerConfig (isSecure req) host
                            |> Task.attempt (GotRecommendedServerConfig host)
                    )
                |> Cmd.batch
            )

        GotRecommendedServerConfig host result ->
            case result of
                Ok ( connection, config ) ->
                    ( { model | recommendedServerConnections = Dict.insert host (serverFrom connection False config) model.recommendedServerConnections }
                    , Cmd.none
                    )

                Err _ ->
                    -- Leaves the disconnected placeholder `ToggleRecommendedServersExpanded`
                    -- already inserted in place -- same "still shows, just dimmed" treatment
                    -- as any other unreachable server chip.
                    ( model, Cmd.none )

        RecommendedServerClicked host ->
            -- Reuses the connection already cached in `recommendedServerConnections`
            -- (see `resolveHost`) if its fetch already resolved, rather than
            -- renegotiating one from scratch.
            ( model
            , resolveHost (isSecure req) (Dict.values model.recommendedServerConnections) host
                |> Task.attempt (GotRecommendedServerAddResult host)
            )

        GotRecommendedServerAddResult host result ->
            case result of
                Ok ( connection, config ) ->
                    let
                        -- An explicit tap on a recommended-server chip is exactly the
                        -- same kind of deliberate "add this server" action as
                        -- `GotNewServerResult`'s manual Add Server flow -- enabled
                        -- immediately, same as that.
                        newModel : Model
                        newModel =
                            { model
                                | servers = upsertServer (serverFrom connection True config) model.servers
                                , recommendedServerConnections = Dict.remove host model.recommendedServerConnections
                            }
                    in
                    ( newModel, persist newModel )

                Err _ ->
                    ( model, Cmd.none )

        RemoveServerClicked frontendHost ->
            -- Same "fade first, actually remove once that finishes" deferral as
            -- `RemoveAccountClicked` -- see `serverAnimations`.
            if serverHasAccounts model.accounts frontendHost || frontendHost == model.mainFrontendHost then
                ( model, Cmd.none )

            else
                let
                    currentState : UI.Flip.State Msg
                    currentState =
                        Dict.get frontendHost model.serverAnimations |> Maybe.withDefault UI.Flip.restingState
                in
                ( { model | serverAnimations = Dict.insert frontendHost (UI.Flip.remove (FinishRemoveServer frontendHost) currentState) model.serverAnimations }
                , Cmd.none
                )

        FinishRemoveServer frontendHost ->
            let
                removedModel : Model
                removedModel =
                    { model
                        | servers = List.filter (\s -> s.frontendHost /= frontendHost) model.servers
                        , serverAnimations = Dict.remove frontendHost model.serverAnimations

                        -- Drop any stale branding cached from before this host was
                        -- added (see `recommendedServerConnections`'s doc) -- otherwise
                        -- it reappears in the recommended strip still pointing at the
                        -- placeholder left behind by `GotRecommendedServerAddResult`'s
                        -- `Dict.remove`, and never gets refetched.
                        , recommendedServerConnections = Dict.remove frontendHost model.recommendedServerConnections
                    }

                -- If the strip is open right now, the chip for this host is already
                -- back on screen (it just became "recommended" again) -- refetch its
                -- branding immediately instead of waiting on a collapse/re-expand,
                -- mirroring `ToggleRecommendedServersExpanded`'s own fetch.
                needsRefetch : Bool
                needsRefetch =
                    removedModel.recommendedServersExpanded
                        && List.any (\fs -> fs.host == frontendHost) (recommendedFederatedServers removedModel)

                newModel : Model
                newModel =
                    if needsRefetch then
                        { removedModel
                            | recommendedServerConnections =
                                Dict.insert frontendHost
                                    (disconnectedServer { frontendHost = frontendHost, enabled = False })
                                    removedModel.recommendedServerConnections
                        }

                    else
                        removedModel
            in
            ( newModel
            , Cmd.batch
                [ persist newModel
                , if needsRefetch then
                    negotiateServerConfig (isSecure req) frontendHost
                        |> Task.attempt (GotRecommendedServerConfig frontendHost)

                  else
                    Cmd.none
                ]
            )

        ToggleAccountsPanel ->
            let
                newlyShown : Bool
                newlyShown =
                    not model.showAccountsPanel

                newModel : Model
                newModel =
                    { model | showAccountsPanel = newlyShown }
            in
            ( if newlyShown then
                repopulateBlankServerField newModel

              else
                collapseAddAccountFormIfIdle { newModel | recommendedServersExpanded = False }
            , Cmd.none
            )

        CloseAccountsPanel ->
            ( collapseAddAccountFormIfIdle
                { model | showAccountsPanel = False, createAccountConfirmation = Nothing, acceptedCreateAccount = Nothing, recommendedServersExpanded = False }
            , Cmd.none
            )

        ShowAddAccountFormClicked ->
            ( { model | addAccountFormExpanded = True }, Cmd.none )

        ReauthenticateButtonClicked account ->
            -- Reopens the (possibly-collapsed) Account form pre-filled with this
            -- account's server/username, focused straight on Password -- the
            -- quickest path back to a working access token once its refresh
            -- token's been rejected (see `GotPermissionsRefresh`).
            ( { model
                | addAccountFormExpanded = True
                , newAccountType = Just LoginToAccount
                , accountForm =
                    { server = account.server
                    , username = account.username
                    , password = ""
                    , status = Idle
                    , showPasswordAsText = False
                    }
              }
            , Task.attempt (\_ -> NoOp) (Dom.focus "account-form-password")
            )

        GotPermissionsRefresh accId result ->
            let
                newModel : Model
                newModel =
                    { model | accounts = applyPermissionsRefreshResult accId result model.accounts }
            in
            ( newModel, persist newModel )

        GotServerPermissionsRefresh results ->
            let
                newModel : Model
                newModel =
                    { model
                        | accounts =
                            List.foldl
                                (\( accId, result ) accounts -> applyPermissionsRefreshResult accId result accounts)
                                model.accounts
                                results
                    }
            in
            -- One `persist` for the whole server (every one of its accounts'
            -- results folded in above) rather than one per account -- see
            -- `refreshPermissionsForServer`'s own doc -- and, while `init`'s
            -- startup sweep is still in progress, deferred further still, into
            -- the single sweep-wide `persist` -- see `settleStartupUnit`/
            -- `Model.accessTokenRefreshChecked`.
            settleStartupUnit newModel

        MainServerSelected frontendHost ->
            if List.any (\s -> s.frontendHost == frontendHost) model.servers then
                let
                    newModel : Model
                    newModel =
                        { model | mainFrontendHost = frontendHost }
                            |> setServerField frontendHost
                in
                ( newModel, persist newModel )

            else
                ( model, Cmd.none )

        ResetMainFrontendHost ->
            let
                newModel : Model
                newModel =
                    { model | mainFrontendHost = model.browsingHost }
            in
            ( newModel, persist newModel )

        ServerChipClicked frontendHost ->
            ( setServerField frontendHost model, Cmd.none )

        SetWebUserInterfaceClicked id ui ->
            let
                maybeAccount : Maybe Account
                maybeAccount =
                    model.accounts |> List.filter (\a -> accountId a == id) |> List.head

                maybeServer : Maybe Server
                maybeServer =
                    maybeAccount
                        |> Maybe.andThen (\a -> serverForHost model.servers a.server)
            in
            case ( maybeAccount, maybeServer ) of
                ( Just account, Just server ) ->
                    ( model, setWebUserInterface server account ui )

                _ ->
                    ( model, Cmd.none )

        GotSetWebUserInterfaceResult result ->
            case result of
                Ok ( refreshedAccount, newConfig ) ->
                    let
                        newModel : Model
                        newModel =
                            { model
                                | accounts = upsertAccount refreshedAccount model.accounts
                                , servers =
                                    List.map
                                        (\s ->
                                            if s.frontendHost == refreshedAccount.server then
                                                updateServerConfiguration newConfig s

                                            else
                                                s
                                        )
                                        model.servers
                            }
                    in
                    ( newModel, persist newModel )

                Err _ ->
                    -- Server unreachable, refresh token rejected, etc. -- the toggle just
                    -- doesn't visibly change; the admin can retry.
                    ( model, Cmd.none )

        RenameServerClicked id newName ->
            let
                maybeAccount : Maybe Account
                maybeAccount =
                    model.accounts |> List.filter (\a -> accountId a == id) |> List.head

                maybeServer : Maybe Server
                maybeServer =
                    maybeAccount
                        |> Maybe.andThen (\a -> serverForHost model.servers a.server)
            in
            case ( maybeAccount, maybeServer ) of
                ( Just account, Just server ) ->
                    ( model, renameServer server account newName )

                _ ->
                    ( model, Cmd.none )

        GotRenameServerResult result ->
            case result of
                Ok ( refreshedAccount, newConfig ) ->
                    let
                        newModel : Model
                        newModel =
                            { model
                                | accounts = upsertAccount refreshedAccount model.accounts
                                , servers =
                                    List.map
                                        (\s ->
                                            if s.frontendHost == refreshedAccount.server then
                                                updateServerConfiguration newConfig s

                                            else
                                                s
                                        )
                                        model.servers
                            }
                    in
                    ( newModel, persist newModel )

                Err _ ->
                    -- Server unreachable, refresh token rejected, etc. -- surfaced to
                    -- the caller (see `Pages.Server.ServerIdentifier_`) via this same
                    -- `Result` passing through `Main.notifyPageOfSharedMsg`.
                    ( model, Cmd.none )

        ChangeServerShortNameClicked id newShortName ->
            let
                maybeAccount : Maybe Account
                maybeAccount =
                    model.accounts |> List.filter (\a -> accountId a == id) |> List.head

                maybeServer : Maybe Server
                maybeServer =
                    maybeAccount
                        |> Maybe.andThen (\a -> serverForHost model.servers a.server)
            in
            case ( maybeAccount, maybeServer ) of
                ( Just account, Just server ) ->
                    ( model, changeServerShortName server account newShortName )

                _ ->
                    ( model, Cmd.none )

        GotChangeServerShortNameResult result ->
            case result of
                Ok ( refreshedAccount, newConfig ) ->
                    let
                        newModel : Model
                        newModel =
                            { model
                                | accounts = upsertAccount refreshedAccount model.accounts
                                , servers =
                                    List.map
                                        (\s ->
                                            if s.frontendHost == refreshedAccount.server then
                                                updateServerConfiguration newConfig s

                                            else
                                                s
                                        )
                                        model.servers
                            }
                    in
                    ( newModel, persist newModel )

                Err _ ->
                    -- Server unreachable, refresh token rejected, etc. -- surfaced to
                    -- the caller (see `AboutTab`) via this same `Result` passing
                    -- through `Main.notifyPageOfSharedMsg`, same as `GotRenameServerResult`.
                    ( model, Cmd.none )

        GotServerConfigSaveResult host newConfig ->
            let
                newModel : Model
                newModel =
                    { model
                        | servers =
                            List.map
                                (\s ->
                                    if s.frontendHost == host then
                                        updateServerConfiguration newConfig s

                                    else
                                        s
                                )
                                model.servers
                    }
            in
            ( newModel, persist newModel )

        FocusInput domId ->
            ( model, Task.attempt (\_ -> NoOp) (Dom.focus domId) )

        -- A field's "clear" button (see `UI.elm`'s `fieldClearButton`):
        -- applies the actual clear (`ServerChanged ""`/`UsernameChanged
        -- ""`/`PasswordChanged ""`) and refocuses the now-empty field, so
        -- clearing it doesn't also lose your place in the form.
        ClearFieldClicked domId clearMsg ->
            let
                ( clearedModel, clearCmd ) =
                    sendUpdate req clearMsg model
            in
            ( clearedModel, Cmd.batch [ clearCmd, Task.attempt (\_ -> NoOp) (Dom.focus domId) ] )

        ServerConnected server ->
            if List.any (\s -> s.frontendHost == server.frontendHost && s.connected /= Nothing) model.servers then
                ( model, Cmd.none )

            else
                let
                    newModel : Model
                    newModel =
                        { model | servers = upsertServer server model.servers }
                in
                ( newModel, persist newModel )

        EnableNotificationsClicked account ->
            case serverWebPushPublicKey model.servers account.server of
                Nothing ->
                    -- No `WebPushConfig` on this account's server (see `UI.accountRow`, which
                    -- only shows the button at all when this is `Just _`) -- unreachable in
                    -- practice.
                    ( model, Cmd.none )

                Just publicKey ->
                    ( { model
                        | notificationErrors = Dict.remove (accountId account) model.notificationErrors
                        , pendingNotificationAccountId = Just (accountId account)
                      }
                    , Ports.subscribeToPush
                        (Encode.object
                            [ ( "accountId", Encode.string (accountId account) )
                            , ( "publicKey", Encode.string publicKey )
                            ]
                        )
                    )

        DisableNotificationsClicked account ->
            let
                id : String
                id =
                    accountId account
            in
            case ( Dict.get id model.pushSubscriptions, serverForHost model.servers account.server |> Maybe.andThen connectionOf ) of
                ( Just endpoint, Just connection ) ->
                    let
                        -- Multiple accounts on the same server share one real browser
                        -- subscription/`endpoint` (see `pushSubscriptions`'s own doc comment) --
                        -- only actually tear it down at the browser level if this was the *last*
                        -- account still relying on it, otherwise every other account sharing it
                        -- would silently stop receiving notifications too. Either way, this
                        -- account's own server-side registration is dropped.
                        lastAccountOnThisEndpoint : Bool
                        lastAccountOnThisEndpoint =
                            model.pushSubscriptions
                                |> Dict.toList
                                |> List.any (\( otherId, otherEndpoint ) -> otherId /= id && otherEndpoint == endpoint)
                                |> not
                    in
                    ( { model
                        | pushSubscriptions = Dict.remove id model.pushSubscriptions
                        , notificationErrors = Dict.remove id model.notificationErrors
                        , pendingNotificationAccountId = Just id
                      }
                    , Cmd.batch
                        [ if lastAccountOnThisEndpoint then
                            Ports.unsubscribeFromPush
                                (Encode.object
                                    [ ( "accountId", Encode.string id )
                                    , ( "endpoint", Encode.string endpoint )
                                    ]
                                )

                          else
                            Cmd.none
                        , performWithAccount
                            connection
                            account
                            (\accessToken ->
                                Grpc.new Jonline.unregisterPushSubscription { endpoint = endpoint }
                                    |> Grpc.setHost (connectionUrl connection)
                                    |> withAccessToken (Just accessToken)
                                    |> Grpc.toTask
                            )
                            |> Task.map Tuple.first
                            |> Task.attempt GotUnregisterPushSubscriptionResult
                        ]
                    )

                _ ->
                    -- Not currently tracked as subscribed (or the server's since gone
                    -- disconnected) -- nothing to unregister.
                    ( { model | pushSubscriptions = Dict.remove id model.pushSubscriptions }, Cmd.none )

        PushSubscriptionPortReceived value ->
            case Decode.decodeValue pushSubscriptionPortDecoder value of
                Ok ( id, Ok keys ) ->
                    case
                        model.accounts
                            |> List.filter (\a -> accountId a == id)
                            |> List.head
                            |> Maybe.andThen (\account -> serverForHost model.servers account.server |> Maybe.andThen connectionOf |> Maybe.map (Tuple.pair account))
                    of
                        Just ( account, connection ) ->
                            ( model
                            , performWithAccount
                                connection
                                account
                                (\accessToken ->
                                    Grpc.new Jonline.registerPushSubscription
                                        { endpoint = keys.endpoint, p256dhKey = keys.p256dhKey, authKey = keys.authKey }
                                        |> Grpc.setHost (connectionUrl connection)
                                        |> withAccessToken (Just accessToken)
                                        |> Grpc.toTask
                                )
                                |> Task.attempt GotRegisterPushSubscriptionResult
                            )

                        Nothing ->
                            ( model, Cmd.none )

                -- Permission denied, unsupported browser, subscribe failed, etc. -- surfaced via
                -- `notificationErrors` (see `UI.notificationsButton`) instead of silently no-oping,
                -- so a real failure (e.g. the browser blocking notifications for this site, or iOS
                -- Safari requiring the site be added to the Home Screen first) is actually visible.
                Ok ( id, Err reason ) ->
                    ( { model | notificationErrors = Dict.insert id reason model.notificationErrors }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        GotRegisterPushSubscriptionResult result ->
            case result of
                Ok ( refreshedAccount, pushSubscription ) ->
                    let
                        newModel : Model
                        newModel =
                            { model
                                | accounts = upsertAccount refreshedAccount model.accounts

                                -- `Dict.insert`, not `Dict.singleton` -- `Ports.subscribeToPush`'s
                                -- JS side reuses the existing browser subscription when its key
                                -- already matches the one being requested (see its own doc
                                -- comment), which is exactly what happens when a *second* local
                                -- account on the same server enables notifications -- both truly
                                -- do end up sharing one active subscription, so both stay recorded
                                -- here instead of this one evicting the other.
                                , pushSubscriptions = Dict.insert (accountId refreshedAccount) pushSubscription.endpoint model.pushSubscriptions
                                , notificationErrors = Dict.remove (accountId refreshedAccount) model.notificationErrors
                            }
                    in
                    ( newModel, persist newModel )

                Err error ->
                    case model.pendingNotificationAccountId of
                        Just id ->
                            ( { model | notificationErrors = Dict.insert id (grpcErrorToString error) model.notificationErrors }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

        GotUnregisterPushSubscriptionResult result ->
            case result of
                Ok refreshedAccount ->
                    let
                        newModel : Model
                        newModel =
                            { model | accounts = upsertAccount refreshedAccount model.accounts }
                    in
                    ( newModel, persist newModel )

                Err _ ->
                    ( model, Cmd.none )

        PushSubscriptionCheckReceived value ->
            ( { model | pendingPushSubscriptionCheck = Decode.decodeValue pushSubscriptionCheckDecoder value |> Result.withDefault Nothing }
            , Cmd.none
            )

        GotPushSubscriptionStatusResult endpoint result ->
            case result of
                Ok ( refreshedAccount, response ) ->
                    let
                        newModel : Model
                        newModel =
                            { model
                                | accounts = upsertAccount refreshedAccount model.accounts
                                , pushSubscriptions =
                                    if response.registered then
                                        Dict.insert (accountId refreshedAccount) endpoint model.pushSubscriptions

                                    else
                                        model.pushSubscriptions
                            }
                    in
                    ( newModel, Cmd.none )

                Err _ ->
                    -- Best-effort hydration -- if the check itself fails (network blip, an
                    -- unrefreshable expired token, etc.), just leave that account showing as
                    -- disabled; nothing here was user-initiated, so there's no `notificationErrors`
                    -- entry to fill in the way a real click's failure gets one.
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


{-| Whether the page itself was loaded over TLS -- if so, we only ever try
TLS candidates for a new host, since a secure page can't make plaintext
requests (mixed content). Only an insecure (e.g. local dev) page falls back
to trying plaintext ports too.

Generic over `params` (rather than just this module's own `Request`) so any
page can pass its own `Request.With Params` straight in -- see
`connectToServer`.

-}
isSecure : Request.With params -> Bool
isSecure req =
    req.url.protocol == Url.Https


emptyForm : AccountForm
emptyForm =
    { server = "localhost"
    , username = ""
    , password = ""
    , status = Idle
    , showPasswordAsText = False
    }


emptyAddServerForm : AddServerForm
emptyAddServerForm =
    { status = Idle }


{-| A server that has any associated accounts can't be removed (only disabled),
since removing it would orphan those accounts' stored credentials.
-}
serverHasAccounts : List Account -> String -> Bool
serverHasAccounts accounts frontendHost =
    List.any (\a -> a.server == frontendHost) accounts


{-| Hosts of accounts we're keeping around but that are currently disconnected
(see `Server.connected`) -- e.g. the server's down, moved, or otherwise
unreachable right now (see `GotReconnectResult`'s `Err` branch, which marks a
failed-to-reconnect server disconnected in place rather than dropping its
accounts). Also includes any host with no `Server` entry at all, though that
should only ever be transient (see `init`'s `missingServerHosts`, which seeds
one for every account's host). Deduplicated, for a "Couldn't reach: host1,
host2" warning below the Servers strip.
-}
unreachableAccountHosts : Model -> List String
unreachableAccountHosts model =
    model.accounts
        |> List.map .server
        |> List.filter
            (\host ->
                model.servers
                    |> List.filter (\s -> s.frontendHost == host)
                    |> List.head
                    |> Maybe.map (\s -> s.connected == Nothing)
                    |> Maybe.withDefault True
            )
        |> Set.fromList
        |> Set.toList


{-| Whether `frontendHost` (trimmed) is a server we're actually connected to --
used by the Account form to decide whether Username/Password/Login/Create
Account should be enabled, or whether "Add Server" should be offered instead
(see `AddServerClicked`, which adds whatever's currently typed into the
(shared) `AccountForm.server` field).
-}
isKnownServer : Model -> String -> Bool
isKnownServer model frontendHost =
    List.any (\s -> s.frontendHost == String.trim frontendHost) model.servers


{-| The `mainFrontendHost` server's own `federation_info.servers` (see
`federation.proto`'s `FederatedServer`) that aren't already in `model.servers`
-- in practice, the ones that weren't `configured_by_default` (see
`GotMainServerResult`), so never got auto-added in the first place. Drives
`UI.recommendedServersStrip`'s "X Recommended Servers..." button; empty (so
that button never shows) once there's no main server yet, the main server has
no federation info, or every federated server it names is already known.
-}
recommendedFederatedServers : Model -> List FederatedServer
recommendedFederatedServers model =
    serverForHost model.servers model.mainFrontendHost
        |> Maybe.map configurationOf
        |> Maybe.andThen .federationInfo
        |> Maybe.map .servers
        |> Maybe.withDefault []
        |> List.filter (\fs -> not (isKnownServer model fs.host))


{-| Whether `frontendHost` (trimmed) is this app's own "home" server --
`browsingHost` (the host actually being viewed from) or `mainFrontendHost`
(what that resolves to, once negotiated -- see `mainFrontendHost`'s own doc).
Username/password auth (Login/Create Account) is only ever offered for one of
these -- everywhere else, `signInFromButton`'s cross-server SSO hand-off is
the only way in, unless an admin has flipped
`DebugTab.allowUsernamePasswordForOtherHosts` (`model.debugTab`).
-}
isMainServer : Model -> String -> Bool
isMainServer model frontendHost =
    let
        trimmed : String
        trimmed =
            String.trim frontendHost
    in
    trimmed == model.browsingHost || trimmed == model.mainFrontendHost


{-| Whether the Add Account/Server form (Server/Username/Password/etc.)
should be shown outright, rather than collapsed behind an "Add Account/Server"
button -- always true while there are no accounts yet (there'd be nothing for
the button to hide behind), otherwise only once the user's expanded it (see
`ShowAddAccountFormClicked`).
-}
shouldShowAddAccountForm : Model -> Bool
shouldShowAddAccountForm model =
    List.isEmpty model.accounts || model.addAccountFormExpanded


{-| Whether the user has unsaved progress in the Add Account/Server form that
would be surprising to lose by auto-collapsing it back behind the button --
either they've typed something into Username/Password, or the typed-in Server
names a host we're not connected to yet (so "Add Server" is the button
actually showing, rather than Login/Create Account). Shared by
`ToggleAccountsPanel` and `CloseAccountsPanel`, the panel's two ways of
closing -- see `collapseAddAccountFormIfIdle`.
-}
hasInProgressAddAccountInput : Model -> Bool
hasInProgressAddAccountInput model =
    let
        form : AccountForm
        form =
            model.accountForm
    in
    (String.trim form.username /= "")
        || (String.trim form.password /= "")
        || (model.newAccountType /= Nothing)
        || not (isKnownServer model form.server)


{-| Collapses the Add Account/Server form back behind its button when the
Accounts Panel closes, unless `hasInProgressAddAccountInput` says there's
progress worth keeping visible.
-}
collapseAddAccountFormIfIdle : Model -> Model
collapseAddAccountFormIfIdle model =
    if hasInProgressAddAccountInput model then
        model

    else
        { model | addAccountFormExpanded = False }


{-| Looks up a known server by its `frontendHost` -- e.g. for a route param
naming a specific server (see `Components.ServerDependentView`), or an
account's `server` field.
-}
serverForHost : List Server -> String -> Maybe Server
serverForHost servers frontendHost =
    servers |> List.filter (\s -> s.frontendHost == frontendHost) |> List.head


{-| The VAPID public key `frontendHost`'s server would want a `RegisterPushSubscription` call
signed with -- `Nothing` if the server isn't connected, or is connected but has no `WebPushConfig`
(the admin hasn't set one up), either of which means there's nothing to actually push
notifications with. `UI.accountRow` only shows its "Enable notifications" button when this is
`Just _`.
-}
serverWebPushPublicKey : List Server -> String -> Maybe String
serverWebPushPublicKey servers frontendHost =
    serverForHost servers frontendHost
        |> Maybe.andThen .connected
        |> Maybe.andThen (\connected -> connected.configuration.webPushConfig)
        |> Maybe.map .publicVapidKey


{-| `serverForHost`, but only if that entry is both known _and_ actually
connected -- a known-but-disconnected entry (see `Server.connected`) is
treated the same as not known at all. `init` seeds every persisted server
disconnected before its own reconnect attempt resolves (see `init`'s own
doc), so a route-driven fetch gated on plain `serverForHost` alone can fire
against that placeholder the instant the app boots, before there's an actual
connection to fetch from -- failing immediately, and (since these fetches are
typically only attempted once) staying failed even after the real reconnect
lands moments later. Callers that need to fetch from a specific route-named
host (`Pages.Event.EventId_`, `Pages.Post.PostId_`,
`Components.Users.Resolver`) should gate on this instead of `serverForHost`
directly.
-}
knownConnectedServer : List Server -> String -> Maybe Server
knownConnectedServer servers frontendHost =
    serverForHost servers frontendHost
        |> Maybe.andThen
            (\server ->
                if server.connected /= Nothing then
                    Just server

                else
                    Nothing
            )


{-| The signed-in account to use for `frontendHost`, if there is one --
picking the first enabled account on that server. Used wherever content needs
to be fetched "as whichever account, if any, is currently signed into this
server" (see `Components.Posts`), rather than any one specific account.
-}
enabledAccountForServer : List Account -> String -> Maybe Account
enabledAccountForServer accounts frontendHost =
    accounts
        |> List.filter (\a -> a.server == frontendHost && a.enabled)
        |> List.head


{-| Servers whose data should be included when aggregating across all of
them -- e.g. the Home page's recent-posts feed. Excludes disabled servers, as
well as ones that are currently disconnected (see `Server.connected`) --
there's nothing to aggregate from a server that can't be reached right now.
-}
enabledServers : Model -> List Server
enabledServers model =
    List.filter (\s -> s.enabled && s.connected /= Nothing) model.servers


{-| A server's full base URL, for making requests against it directly (e.g.
`Components.Posts`' `GetPosts` calls) without needing to build a `Connection`.
-}
serverUrl : Server -> String
serverUrl server =
    -- Every caller reaches `server` via `resolveAccountServer`/`enabledServers`,
    -- both of which only ever hand back a connected `Server` -- see
    -- `Server.connected`. The empty-string fallback is unreachable in
    -- practice; `serverUrl` stays total rather than pushing a `Maybe` onto
    -- the many call sites that already know they're on solid ground.
    connectionOf server
        |> Maybe.map connectionUrl
        |> Maybe.withDefault ""


{-| Connects to a server given only its hostname, same as adding one via the
Account form's "Add Server" button (see `AddServerClicked`) -- but as a plain
`Task`, for callers outside the Accounts Panel that need to connect to a
specific server themselves (see `Components.ServerDependentView`) and decide
what to do with the result (typically dispatching `ServerConnected` once it
resolves, then proceeding with whatever they actually wanted the server for).
-}
connectToServer : Bool -> String -> Task Grpc.Error Server
connectToServer pageIsSecure frontendHost =
    negotiateServerConfig pageIsSecure frontendHost
        |> Task.map (\( connection, config ) -> serverFrom connection True config)


updateAddServerForm : (AddServerForm -> AddServerForm) -> Model -> Model
updateAddServerForm fn model =
    { model | addServerForm = fn model.addServerForm }


updateForm : (AccountForm -> AccountForm) -> Model -> Model
updateForm fn model =
    { model | accountForm = fn model.accountForm }


{-| The `id` of the Create Account confirmation modal's scrolling policy-text
body -- shared between `Dom.getViewportOf` (see `GotCreateAccountServerInfo`)
and the `id` attribute `UI.createAccountConfirmationModal` puts on that same
element, so the two can't drift out of sync.
-}
createAccountModalBodyId : String
createAccountModalBodyId =
    "create-account-modal-body"


{-| Marks the pending Create Account confirmation (if any -- a no-op once the
user's already confirmed/canceled it away) as having had its policy text
fully read, per `GotCreateAccountModalViewport`/`CreateAccountModalScrolled`.
-}
markCreateAccountBottomReached : Model -> Model
markCreateAccountBottomReached model =
    { model
        | createAccountConfirmation =
            Maybe.map (\pending -> { pending | reachedBottom = True }) model.createAccountConfirmation
    }


{-| Resets an `Errored` status back to `Idle`, leaving `Submitting`/`Idle`
alone -- used to drop a stale error from the _other_ form (login vs. add-server)
sharing the Server field, without clobbering a submission that's actually
in flight (see `ServerChanged`, `LoginClicked`, `CreateAccountClicked`,
`AddServerClicked`).
-}
clearErrored : FormStatus -> FormStatus
clearErrored status =
    case status of
        Errored _ ->
            Idle

        other ->
            other


{-| Sets the (shared) Server field and clears any stale error left over from
either form -- both `AccountForm.status` and `AddServerForm.status` render
into the same message below the field (see `UI.elm`'s `formView`), so an old
error (a failed login, "That server is already in your list.", etc.) needs
clearing whenever the field changes for _any_ reason: typing
(`ServerChanged`), tapping a known server's chip (`ServerChipClicked`), or
picking a new main server (`MainServerSelected`). Also resets
`newAccountType`/`createAccountConfirmation`/`acceptedCreateAccount` back to
the Username-only step -- a Login/Create Account choice (or policy
confirmation) made for whatever server was previously named no longer
applies.
-}
setServerField : String -> Model -> Model
setServerField server model =
    { model | newAccountType = Nothing, createAccountConfirmation = Nothing, acceptedCreateAccount = Nothing }
        |> updateForm (\form -> { form | server = server, status = clearErrored form.status })
        |> updateAddServerForm (\f -> { f | status = clearErrored f.status })


{-| Repopulates the Server field with `mainFrontendHost` if it's blank -- e.g.
left cleared via the field's own "clear" button before the panel was last
closed. Called whenever the Accounts Panel reopens (`ToggleAccountsPanel`), so
a blanked-out Server field doesn't persist across a close/reopen cycle.
-}
repopulateBlankServerField : Model -> Model
repopulateBlankServerField model =
    if String.trim model.accountForm.server == "" then
        setServerField model.mainFrontendHost model

    else
        model


{-| Disables every other account on `server` besides `keepEnabledId` -- only one
account per server may be signed in (enabled) at a time, since aggregated
feeds/permissions assume a single identity per server. Called whenever an
account becomes enabled, whether by toggling it on or by a fresh sign-in.
-}
disableOtherAccountsOnServer : String -> String -> List Account -> List Account
disableOtherAccountsOnServer keepEnabledId server accounts =
    List.map
        (\a ->
            if a.server == server && accountId a /= keepEnabledId then
                { a | enabled = False }

            else
                a
        )
        accounts


{-| Signing in/re-enabling an account whose server is still marked disabled
would leave it silently excluded from aggregated data anyway -- bring the
server along, mirroring what `ToggleServerEnabled` does for its accounts when
the server itself is disabled. Used by every path that force-enables an
account (`GotAuthResult`, `FederatedAccountReceived`, `ToggleAccountEnabled`).
-}
enableServerFor : String -> List Server -> List Server
enableServerFor frontendHost servers =
    List.map
        (\server ->
            if server.frontendHost == frontendHost then
                { server | enabled = True }

            else
                server
        )
        servers


upsertAccount : Account -> List Account -> List Account
upsertAccount account accounts =
    if List.any (\a -> accountId a == accountId account) accounts then
        List.map
            (\a ->
                if accountId a == accountId account then
                    account

                else
                    a
            )
            accounts

    else
        -- TODO: temporarily prepending (bypassing insertAfterSameServer) so a
        -- newly-added account is visible without scrolling, to see its FLIP
        -- entrance animation -- revisit ordering later.
        account :: accounts


serverFrom : Connection -> Bool -> ServerConfiguration -> Server
serverFrom connection enabled config =
    { frontendHost = connection.frontendHost
    , enabled = enabled
    , connected =
        Just
            { backendHost = connection.backendHost
            , port_ = connection.port_
            , tls = connection.tls
            , configuration = config
            , branding = brandingFromConfig connection config
            }
    }


{-| A server known only from a persisted server-list entry (or an account
signed into it), not yet (re)connected this session -- see `Server.connected`.
Keeps `frontendHost`/`enabled` (the only two fields that get persisted) so it
still has its place in `Model.servers`, and so its `PersistedServer` entry
survives a failed/never-attempted reconnect (see `GotReconnectResult`'s `Err`
branch) exactly as it would if nothing had gone wrong.
-}
disconnectedServer : PersistedServer -> Server
disconnectedServer persisted =
    { frontendHost = persisted.frontendHost
    , enabled = persisted.enabled
    , connected = Nothing
    }


{-| Adds/updates `server` in `servers` by `frontendHost`, keeping its existing
position (and existing `enabled` flag, if any -- see below) rather than
moving it to the front/back -- the reordering (`MoveServerLeftClicked`/
`RightClicked`) or disconnection (`GotReconnectResult`'s `Err` branch)
already applied to that slot shouldn't be undone just because a fresh
connection/login/rename came in for it. Prepends if there's no existing entry
for this host at all (a genuinely new server) -- see `upsertServerAppend` for
the append-at-end variant used for servers discovered via federation at
first-setup time.

Deliberately keeps the _existing_ entry's `enabled` over `server`'s own --
`enabled` is a persisted user preference, independent of whether we're
currently connected, so a fresh reconnect (whose caller may only know the
`enabled` its host had at the _start_ of `init`'s startup sweep, see
`reconnectCmds`) should never clobber a more recent in-session toggle
(`ToggleServerEnabled`/`ToggleAccountEnabled`) applied to the same host's
placeholder while that reconnect was still in flight.

-}
upsertServer : Server -> List Server -> List Server
upsertServer =
    upsertServerWith (::)


{-| Same as `upsertServer`, but for a genuinely new host appends it to the
_end_ of `servers` instead of prepending it. Used only for servers
discovered via `GotMainServerResult`'s `federatedServerCmds` at first-setup
time, so the base host's own federation recommendations land after any
servers the user already knew about, rather than jumping ahead of them.
-}
upsertServerAppend : Server -> List Server -> List Server
upsertServerAppend =
    upsertServerWith (\server servers -> servers ++ [ server ])


upsertServerWith : (Server -> List Server -> List Server) -> Server -> List Server -> List Server
upsertServerWith insertNew server servers =
    case List.filter (\s -> s.frontendHost == server.frontendHost) servers |> List.head of
        Just existing ->
            List.map
                (\s ->
                    if s.frontendHost == server.frontendHost then
                        { server | enabled = existing.enabled }

                    else
                        s
                )
                servers

        Nothing ->
            insertNew server servers


{-| Patches a server's cached `configuration` (and re-derives `branding` from
it) in place after a config-changing RPC succeeds (rename, web-UI toggle,
settings save) -- shared by `GotSetWebUserInterfaceResult`/
`GotRenameServerResult`/`GotServerConfigSaveResult`. A no-op if `server` is
currently disconnected (see `Server.connected`) -- unreachable in practice,
since all three only fire after an RPC that itself required a live
connection.
-}
updateServerConfiguration : ServerConfiguration -> Server -> Server
updateServerConfiguration newConfig server =
    case connectionOf server of
        Nothing ->
            server

        Just connection ->
            { server
                | connected =
                    Maybe.map
                        (\c -> { c | configuration = newConfig, branding = brandingFromConfig connection newConfig })
                        server.connected
            }


connectionOf : Server -> Maybe Connection
connectionOf server =
    server.connected
        |> Maybe.map
            (\c -> { frontendHost = server.frontendHost, backendHost = c.backendHost, port_ = c.port_, tls = c.tls })


{-| The bare `Task` behind `refreshPermissions`/`refreshPermissionsForServer` --
refreshes an account's `permissions` (and `username`, in case it changed
server-side) via `GetCurrentUser`, refreshing its access token first if
needed -- see `performWithAccount`.
-}
refreshPermissionsTask : Server -> Account -> Task Grpc.Error ( Account, User )
refreshPermissionsTask server account =
    case connectionOf server of
        -- `server` is disconnected (see `Server.connected`) -- nothing to refresh
        -- against right now; callers (e.g. `ToggleAccountEnabled` re-enabling an
        -- account on a server that's since gone unreachable) just leave the
        -- account's existing permissions/token alone.
        Nothing ->
            Task.fail Grpc.NetworkError

        Just connection ->
            performWithAccount
                connection
                account
                (\accessToken ->
                    Grpc.new Jonline.getCurrentUser {}
                        |> Grpc.setHost (connectionUrl connection)
                        |> withAccessToken (Just accessToken)
                        |> Grpc.toTask
                )


{-| Folds one account's `GetCurrentUser`/access-token-refresh result (see
`refreshPermissionsTask`) into `accounts` -- shared by `GotPermissionsRefresh`
(a single account, e.g. `ToggleAccountEnabled`) and `GotServerPermissionsRefresh`
(a whole server's worth at once, see `refreshPermissionsForServer`) so both
apply the exact same rules:

  - On success, merges the refreshed `username`/`permissions`/`avatarMediaId`/
    `realName` and clears `needsPassword`.
  - On an `Unauthenticated` failure, the refresh token itself was rejected
    (revoked, expired past its own grace period) -- unlike a network blip,
    retrying later won't fix this; the account needs a fresh password (see
    `UI.accountRow`'s "password required" badge, and `PasswordNeededClicked`).
    Also disabled -- it's not actually signed in anymore (every request would
    fail the same way), so it shouldn't keep counting as such for aggregated
    feeds/permissions until the user signs back in.
  - Any other failure (network blip, server unreachable, etc.) leaves the
    account as it was; it'll be retried on the next reconnect/enable.

-}
applyPermissionsRefreshResult : String -> Result Grpc.Error ( Account, User ) -> List Account -> List Account
applyPermissionsRefreshResult accId result accounts =
    case result of
        Ok ( refreshedAccount, user ) ->
            upsertAccount
                { refreshedAccount
                    | username = user.username
                    , permissions = user.permissions
                    , avatarMediaId = Maybe.map .id user.avatar
                    , realName = user.realName
                    , needsPassword = False
                }
                accounts

        Err (Grpc.BadStatus { status }) ->
            if status == Grpc.Unauthenticated then
                List.map
                    (\a ->
                        if accountId a == accId then
                            { a | needsPassword = True, enabled = False }

                        else
                            a
                    )
                    accounts

            else
                accounts

        Err _ ->
            accounts


{-| Refreshes a single account's permissions -- fired when it's individually
(re-)enabled (`ToggleAccountEnabled`), so permissions granted/revoked
elsewhere stay current without the user doing anything. See
`refreshPermissionsForServer` for the whole-server, startup-time equivalent.
-}
refreshPermissions : Server -> Account -> Cmd Msg
refreshPermissions server account =
    refreshPermissionsTask server account
        |> Task.attempt (GotPermissionsRefresh (accountId account))


{-| `refreshPermissionsTask` for every account on the given server that isn't
already known to need a password -- not just enabled (signed-in) ones, so a
disabled account's access token is refreshed (and `needsPassword` discovered)
right along with everyone else's, rather than only once the user re-enables
it.

Skips accounts already flagged `needsPassword` -- their refresh token is
already known to be dead, and retrying it on every single reconnect (app
startup/reload, this same function's own other callers) would just fail the
exact same way every time while persisting/broadcasting a no-op change --
effectively a boot loop on every future load. The only way out of
`needsPassword` is a fresh login (`PasswordNeededClicked` -> `GotAuthResult`),
which doesn't go through here at all.

Runs every account's refresh as one batch, settling into a single
`GotServerPermissionsRefresh` once _all_ of them finish, rather than each
independently dispatching (and persisting the result of) its own
`GotPermissionsRefresh` -- so a server with several accounts produces one
`persist` (and cross-tab broadcast -- see `Ports.persistAccountsAndServers`)
instead of one per account. Two tabs both reconnecting to the same servers at
startup would otherwise each re-broadcast every single account's result as it
trickles in, each broadcast in turn nudging the _other_ tab's own
`AccountsAndServersBroadcastReceived` -- see `Model.accessTokenRefreshChecked`,
which defers this even further, into one `persist` for the whole startup
sweep.

-}
refreshPermissionsForServer : Server -> List Account -> Cmd Msg
refreshPermissionsForServer server accounts =
    accounts
        |> List.filter (\a -> a.server == server.frontendHost && not a.needsPassword)
        |> List.map
            (\account ->
                refreshPermissionsTask server account
                    |> Task.map Ok
                    |> Task.onError (Err >> Task.succeed)
                    |> Task.map (Tuple.pair (accountId account))
            )
        |> Task.sequence
        |> Task.perform GotServerPermissionsRefresh


{-| Sets which frontend (`/`, `/flutter`, or `/elm`) `server` serves at its
root, via `ConfigureServer`, authenticated as `account` (refreshing its access
token first if needed -- see `Shared.MaybeAccountRequest`). Only ever invoked
for accounts with `ADMIN` on `server` (see `UI.elm`'s admin account panel);
the server itself also validates that permission.

`ConfigureServer` replaces the whole configuration rather than merging one
field, so this starts from the server's actual last-known `configuration`
(not any locally-edited-but-unsaved form state elsewhere) and only changes
`webUserInterface` within it.

-}
setWebUserInterface : Server -> Account -> WebUserInterface -> Cmd Msg
setWebUserInterface server account ui =
    case ( connectionOf server, server.connected ) of
        ( Just connection, Just { configuration } ) ->
            let
                info : ServerInfo
                info =
                    Maybe.withDefault Proto.Jonline.defaultServerInfo configuration.serverInfo

                newConfig : ServerConfiguration
                newConfig =
                    { configuration | serverInfo = Just { info | webUserInterface = Just ui } }
            in
            performWithAccount
                connection
                account
                (\accessToken ->
                    Grpc.new Jonline.configureServer newConfig
                        |> Grpc.setHost (connectionUrl connection)
                        |> withAccessToken (Just accessToken)
                        |> Grpc.toTask
                )
                |> Task.attempt GotSetWebUserInterfaceResult

        -- `server` is disconnected (see `Server.connected`) -- callers only ever
        -- reach this for a server the account panel shows as connected, so
        -- this is unreachable in practice.
        _ ->
            Cmd.none


{-| Sets `server`'s display name via `ConfigureServer`, authenticated as
`account` -- same convention as `setWebUserInterface` just above (only ever
invoked for accounts with `ADMIN` on `server`, see
`Pages.Server.ServerIdentifier_`'s rename button; the server itself also
validates that permission). Unlike `setWebUserInterface`, this re-fetches the
server's configuration fresh (`GetServerConfiguration`) right before writing
it back, rather than starting from `server.configuration` (this page's own
possibly-stale cache) -- same reasoning as `Components.Posts.updatePost`'s
own fetch-then-update -- so a config change made elsewhere (another tab, the
Tamagui app, another admin) in between isn't clobbered by this one only
changing `serverInfo.name`.
-}
renameServer : Server -> Account -> String -> Cmd Msg
renameServer server account newName =
    case connectionOf server of
        -- `server` is disconnected (see `Server.connected`) -- callers only ever
        -- reach this for a server the account panel shows as connected, so
        -- this is unreachable in practice.
        Nothing ->
            Cmd.none

        Just connection ->
            performWithAccount
                connection
                account
                (\accessToken ->
                    Grpc.new Jonline.getServerConfiguration {}
                        |> Grpc.setHost (connectionUrl connection)
                        |> withAccessToken (Just accessToken)
                        |> Grpc.toTask
                        |> Task.andThen
                            (\freshConfig ->
                                let
                                    info : ServerInfo
                                    info =
                                        Maybe.withDefault Proto.Jonline.defaultServerInfo freshConfig.serverInfo

                                    newConfig : ServerConfiguration
                                    newConfig =
                                        { freshConfig | serverInfo = Just { info | name = Just newName } }
                                in
                                Grpc.new Jonline.configureServer newConfig
                                    |> Grpc.setHost (connectionUrl connection)
                                    |> withAccessToken (Just accessToken)
                                    |> Grpc.toTask
                            )
                )
                |> Task.attempt GotRenameServerResult


{-| Sets `server`'s short name (`ServerInfo.short_name`) via `ConfigureServer`, authenticated as
`account` -- same fetch-then-overlay-then-write shape as `renameServer` just above (only `name`
vs. `shortName` differs), for the same reason: don't clobber a config change made elsewhere in
between. A blank `newShortName` clears the field back to unset rather than saving an empty string,
so `Components.Pages.ServerInformationPage.AboutTab`'s display falls back to "Not set." instead of
showing nothing.
-}
changeServerShortName : Server -> Account -> String -> Cmd Msg
changeServerShortName server account newShortName =
    case connectionOf server of
        -- `server` is disconnected (see `Server.connected`) -- callers only ever
        -- reach this for a server the account panel shows as connected, so
        -- this is unreachable in practice.
        Nothing ->
            Cmd.none

        Just connection ->
            performWithAccount
                connection
                account
                (\accessToken ->
                    Grpc.new Jonline.getServerConfiguration {}
                        |> Grpc.setHost (connectionUrl connection)
                        |> withAccessToken (Just accessToken)
                        |> Grpc.toTask
                        |> Task.andThen
                            (\freshConfig ->
                                let
                                    info : ServerInfo
                                    info =
                                        Maybe.withDefault Proto.Jonline.defaultServerInfo freshConfig.serverInfo

                                    trimmedShortName : Maybe String
                                    trimmedShortName =
                                        case String.trim newShortName of
                                            "" ->
                                                Nothing

                                            trimmed ->
                                                Just trimmed

                                    newConfig : ServerConfiguration
                                    newConfig =
                                        { freshConfig | serverInfo = Just { info | shortName = trimmedShortName } }
                                in
                                Grpc.new Jonline.configureServer newConfig
                                    |> Grpc.setHost (connectionUrl connection)
                                    |> withAccessToken (Just accessToken)
                                    |> Grpc.toTask
                            )
                )
                |> Task.attempt GotChangeServerShortNameResult


{-| Re-fetches `maybeAccountServer`'s server configuration fresh
(`GetServerConfiguration`) and writes back whatever `updateFn` makes of it
(via `ConfigureServer`) -- the same "reload, then write" dance
`Components.Users.updateUser`/`Shared.MarkdownPanel.saveServerInfoField` use
for a `User`/`ServerInfo` field, generalized here to the whole
`ServerConfiguration` since callers like
`Components.Pages.ServerInformationPage`'s permissions editors change a
top-level field (`anonymousUserPermissions`/`defaultUserPermissions`/
`basicUserPermissions`), not one nested in `serverInfo`. Returns a `Msg` to
dispatch if a token refresh happened, alongside the newly written
`ServerConfiguration` -- callers should patch it into `model.servers`
themselves via `GotServerConfigSaveResult`, same as a rename or `serverInfo`
field save.
-}
updateServerConfig :
    Model
    -> MaybeAccountServer
    -> (ServerConfiguration -> ServerConfiguration)
    -> Task Grpc.Error ( Maybe Msg, ServerConfiguration )
updateServerConfig accountsPanelModel maybeAccountServer updateFn =
    performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.getServerConfiguration {}
                |> Grpc.setHost (serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
                |> Task.andThen
                    (\freshConfig ->
                        Grpc.new Jonline.configureServer (updateFn freshConfig)
                            |> Grpc.setHost (serverUrl server)
                            |> withAccessToken (Just token)
                            |> Grpc.toTask
                    )
        )


{-| A server's configuration can declare (via `externalCdnConfig`) that it's
really meant to be reached at a different public `frontendHost` than the one
we just connected to -- e.g. we're on jonline.io.getj.online, a CDN's backend
host, when it's actually configured to look like jonline.io. Falls back to
the host we connected to if there's no such declaration.
-}
resolvedFrontendHost : String -> ServerConfiguration -> String
resolvedFrontendHost connectedHost config =
    config.externalCdnConfig
        |> Maybe.map .frontendHost
        |> Maybe.andThen ifNonEmpty
        |> Maybe.withDefault connectedHost



-- CONNECTING


{-| Candidate (port, tls) combinations to try, in order, against a server's
backend host, once we know it: TLS on the standard gRPC port, then TLS on the
standard HTTPS port; and, only when this page itself isn't loaded over TLS (a
secure page can't make plaintext requests), fall back to plaintext on the
gRPC port, then 80, then 8000, for local/dev servers.
-}
candidatePorts : Bool -> List ( Int, Bool )
candidatePorts pageIsSecure =
    let
        secure : List ( Int, Bool )
        secure =
            [ ( 27707, True ), ( 443, True ) ]
    in
    if pageIsSecure then
        secure

    else
        let
            insecure : List ( Int, Bool )
            insecure =
                [ ( 27707, False ), ( 80, False ), ( 8000, False ) ]
        in
        secure ++ insecure


{-| Reuses an already-connected server's known-good connection and cached
configuration if we have one; otherwise negotiates a fresh connection.
-}
resolveHost : Bool -> List Server -> String -> Task Grpc.Error ( Connection, ServerConfiguration )
resolveHost pageIsSecure servers frontendHost =
    case serverForHost servers frontendHost |> Maybe.andThen .connected of
        Just connected ->
            Task.succeed ( { frontendHost = frontendHost, backendHost = connected.backendHost, port_ = connected.port_, tls = connected.tls }, connected.configuration )

        -- Not known, or known but currently disconnected (see `Server.connected`)
        -- -- either way, there's no cached connection to reuse.
        Nothing ->
            negotiateServerConfig pageIsSecure frontendHost


{-| Connects to a server given only its public (`frontendHost`) identity:
first discovers its real backend host (in case it's served from behind a CDN,
see `discoverBackendHost`), then tries each candidate port/TLS combination
against that backend host in turn, stopping at the first one that
successfully returns server configuration -- which doubles as the
connectivity check ("can we talk to a server here at all?") and a useful
result (its configuration) at the same time.

Each candidate gets `Grpc.setTimeout` (matching `discoverBackendHost`'s own
5000ms) -- a wrong `(port_, tls)` combination doesn't always fail fast (a
`GoodStatus_`-or-`ERR_CONNECTION_REFUSED` port refusal is quick, but e.g. TLS
against a plaintext-only port can leave the browser's own connect/handshake
timeout to eventually give up, which is far longer, tens of seconds).
Without an explicit timeout here, `candidatePorts`' later entries only get
tried once every earlier wrong one has separately run out that clock --
multiplied by however many are wrong, this made connecting to a server whose
correct candidate isn't first in the list (any federated server not
listening on 27707, e.g. `bullcity.social`) visibly slow to the point of
looking hung, on every page that needs to resolve it (any
`Components.ServerDependentView` caller, plus every persisted server `init`
reconnects to at startup) -- not particular to any one page.

-}
negotiateServerConfig : Bool -> String -> Task Grpc.Error ( Connection, ServerConfiguration )
negotiateServerConfig pageIsSecure frontendHost =
    discoverBackendHost pageIsSecure frontendHost
        |> Task.andThen
            (\backendHost ->
                let
                    tryCandidates : List ( Int, Bool ) -> Task Grpc.Error ( Connection, ServerConfiguration )
                    tryCandidates candidates =
                        case candidates of
                            [] ->
                                Task.fail Grpc.NetworkError

                            ( port_, tls ) :: rest ->
                                let
                                    connection : Connection
                                    connection =
                                        { frontendHost = frontendHost, backendHost = backendHost, port_ = port_, tls = tls }
                                in
                                Grpc.new Jonline.getServerConfiguration {}
                                    |> Grpc.setHost (connectionUrl connection)
                                    |> Grpc.setTimeout 5000
                                    |> Grpc.toTask
                                    |> Task.map (Tuple.pair connection)
                                    |> Task.onError (\_ -> tryCandidates rest)
                in
                tryCandidates (candidatePorts pageIsSecure)
            )


{-| A server's public "frontend" host may just be serving a web app that
points browsers at a different "backend" host for the actual gRPC API (e.g.
to sit behind a CDN that can't proxy gRPC-web) -- discoverable via a plain
`GET {frontendHost}/backend_host`, tried over HTTPS/443 then (only when this
page itself isn't secure) HTTP/80. Falls back to `frontendHost` itself
(meaning "no redirection") if that fails or comes back empty; never fails.
-}
discoverBackendHost : Bool -> String -> Task x String
discoverBackendHost pageIsSecure frontendHost =
    let
        tryTls : List Bool -> Task x String
        tryTls tlsFlags =
            case tlsFlags of
                [] ->
                    Task.succeed frontendHost

                tls :: rest ->
                    Http.task
                        { method = "GET"
                        , headers = []
                        , url =
                            (if tls then
                                "https://"

                             else
                                "http://"
                            )
                                ++ frontendHost
                                ++ "/backend_host"
                        , body = Http.emptyBody
                        , resolver =
                            Http.stringResolver
                                (\response ->
                                    case response of
                                        Http.GoodStatus_ _ body ->
                                            Ok body

                                        _ ->
                                            Err ()
                                )
                        , timeout = Just 5000
                        }
                        |> Task.map
                            (\body ->
                                case String.trim body of
                                    "" ->
                                        frontendHost

                                    backendHost ->
                                        backendHost
                            )
                        |> Task.onError (\_ -> tryTls rest)
    in
    tryTls
        (if pageIsSecure then
            [ True ]

         else
            [ True, False ]
        )
        |> Task.onError (\_ -> Task.succeed frontendHost)


connectionUrl : Connection -> String
connectionUrl connection =
    (if connection.tls then
        "https://"

     else
        "http://"
    )
        ++ connection.backendHost
        ++ ":"
        ++ String.fromInt connection.port_


{-| Media (avatars, server logos) is served over plain HTTP(S) on the standard
web port -- not the gRPC(-web) port a `Connection` was negotiated against for
actual API calls -- so this omits the port entirely (the browser defaults to
80/443 per scheme). Uses `frontendHost` (the server's branded domain, e.g.
`ato.band` standing in for the literal `ato.band.getj.online` host actual API
calls connect to -- see `resolvedFrontendHost`), not `backendHost`, since a
server declaring an `ExternalCdnConfig` is fully reverse-proxying that
branded domain through to the backend, `/media` included -- unlike
`connectionUrl`, which stays on `backendHost` for gRPC(-web) calls
specifically, since that's the host `candidatePorts` actually negotiated a
working connection against.
-}
mediaBaseUrl : Connection -> String
mediaBaseUrl connection =
    (if connection.tls then
        "https://"

     else
        "http://"
    )
        ++ connection.frontendHost


{-| A server's raw `ServerInfo` (name, description, privacy/media policy
text, etc.), defaulted the same way `brandingFromConfig` does -- for callers
that need fields `Branding` doesn't carry, e.g. `UI.createAccountConfirmationModal`
showing the description/privacy policy/media policy during account creation.
-}
serverInfoOf : Server -> ServerInfo
serverInfoOf server =
    server.connected
        |> Maybe.andThen (\connected -> connected.configuration.serverInfo)
        |> Maybe.withDefault defaultServerInfo


{-| A server's raw `ServerConfiguration`, falling back to
`Proto.Jonline.defaultServerConfiguration` while disconnected (see
`Server.connected`) -- for callers (e.g. `Components.Pages.ServerInformationPage`)
that need more of it than `serverInfoOf`'s `ServerInfo` carries.
-}
configurationOf : Server -> ServerConfiguration
configurationOf server =
    server.connected
        |> Maybe.map .configuration
        |> Maybe.withDefault Proto.Jonline.defaultServerConfiguration


brandingFromConfig : Connection -> ServerConfiguration -> Branding
brandingFromConfig connection config =
    let
        info : ServerInfo
        info =
            Maybe.withDefault Proto.Jonline.defaultServerInfo config.serverInfo

        name : String
        name =
            info.name
                |> Maybe.andThen ifNonEmpty
                |> Maybe.withDefault connection.frontendHost

        logoUrl : Maybe String
        logoUrl =
            info.logo
                |> Maybe.andThen .squareMediaId
                |> Maybe.map (\id -> mediaBaseUrl connection ++ "/media/" ++ id)

        primaryArgb : Int
        primaryArgb =
            info.colors |> Maybe.andThen .primary |> Maybe.withDefault 0x00424242

        navArgb : Int
        navArgb =
            info.colors |> Maybe.andThen .navigation |> Maybe.withDefault 0x00FFFFFF
    in
    { name = name
    , logoUrl = logoUrl
    , primary = UI.ServerTheme.colorMetaFromArgb primaryArgb
    , nav = UI.ServerTheme.colorMetaFromArgb navArgb
    }


ifNonEmpty : String -> Maybe String
ifNonEmpty s =
    if String.isEmpty s then
        Nothing

    else
        Just s


grpcErrorToString : Grpc.Error -> String
grpcErrorToString err =
    case err of
        Grpc.BadUrl url ->
            "Invalid server address: " ++ url

        Grpc.Timeout ->
            "The request to the server timed out."

        Grpc.NetworkError ->
            "Couldn't reach the server. Check the address and your connection."

        Grpc.BadStatus { errMessage } ->
            if String.isEmpty errMessage then
                "The server rejected the request."

            else
                errMessage

        Grpc.BadBody _ ->
            "Received an unreadable response from the server."

        Grpc.UnknownGrpcStatus status ->
            "Unknown server error: " ++ status



-- PERSISTENCE
-- Tokens are stored with their expiration (if any), so an access token that's
-- expired (or about to) while the app was closed is refreshed on next use
-- rather than trusted as-is -- see `Shared.MaybeAccountRequest`.
-- Servers are persisted as just their frontendHost + enabled flag: backendHost/
-- port/tls/configuration are all rediscovered by reconnecting each session
-- rather than trusted from a (possibly stale) previous one.


{-| No-ops until `init`'s startup sweep has fully settled (see
`accessTokenRefreshChecked`/`finishStartupUnit`) -- otherwise every
individual reconnect/account-refresh that happens to land before then would
each write (and broadcast to every other open tab) their own sliver of
still-converging state, rather than the one coherent snapshot this waits for.
Anything that changes in the meantime (a user actually doing something in the
brief window before the sweep settles, vs. the sweep's own churn) still shows
up on screen immediately either way -- `model` itself is never gated, only
writing it out -- and gets swept up into that same first `persist` once
`finishStartupUnit` fires it.
-}
persist : Model -> Cmd Msg
persist model =
    if model.accessTokenRefreshChecked then
        Ports.persistAccountsAndServers (encodeState model)

    else
        Cmd.none


{-| Marks one "unit" of `init`'s startup sweep as finished -- one server
either failing to reconnect at all, or fully reconnecting and having every
one of its accounts' access tokens checked/refreshed (see
`refreshPermissionsForServer`/`GotServerPermissionsRefresh`). Once every unit
from `pendingServerChecks` has finished, flips `accessTokenRefreshChecked`.
Doesn't persist itself -- see `settleStartupUnit`, every call site's actual
entry point, which pairs this with the one `persist` call that actually needs
to happen. No-ops (returns `model` unchanged) once already checked.
-}
finishStartupUnit : Model -> Model
finishStartupUnit model =
    if model.accessTokenRefreshChecked then
        model

    else
        let
            stillPending : Int
            stillPending =
                model.pendingServerChecks - 1
        in
        { model | pendingServerChecks = stillPending, accessTokenRefreshChecked = stillPending <= 0 }


{-| `finishStartupUnit`, then `persist`s -- but only when that'll actually
write anything: either this unit is the one that just finished the _whole_
sweep (flipping `accessTokenRefreshChecked` from `False` to `True`), so
`persist` now finally goes through, capturing every server/account change
accumulated during the sweep in one write (see `persist`'s own doc); or the
sweep was already long done (ordinary steady-state operation -- e.g. a server
added well after startup, via `AccountsAndServersBroadcastReceived` or the Add
Server form), where `persist` behaves exactly as it always has, once per
call. Only skips persisting in between those two: this unit finished, but
others are still pending, so `persist` would just no-op anyway (see
`persist`) -- no need to call it.
-}
settleStartupUnit : Model -> ( Model, Cmd Msg )
settleStartupUnit model =
    let
        newModel : Model
        newModel =
            finishStartupUnit model
    in
    if newModel.accessTokenRefreshChecked then
        ( newModel, persist newModel )

    else
        ( newModel, Cmd.none )


encodeState : Model -> Encode.Value
encodeState model =
    Encode.object
        [ ( "accounts", Encode.list encodeAccount model.accounts )
        , ( "servers", Encode.list encodePersistedServer model.servers )
        ]


encodeAccount : Account -> Encode.Value
encodeAccount account =
    Encode.object
        [ ( "server", Encode.string account.server )
        , ( "userId", Encode.string account.userId )
        , ( "username", Encode.string account.username )
        , ( "refreshToken", encodeToken account.refreshToken )
        , ( "accessToken", encodeToken account.accessToken )
        , ( "enabled", Encode.bool account.enabled )
        , ( "avatarMediaId", account.avatarMediaId |> Maybe.map Encode.string |> Maybe.withDefault Encode.null )
        , ( "permissions", Encode.list (fieldNumbersPermission >> Encode.int) account.permissions )
        , ( "realName", Encode.string account.realName )
        , ( "needsPassword", Encode.bool account.needsPassword )
        ]


encodeToken : Token -> Encode.Value
encodeToken token =
    Encode.object
        [ ( "token", Encode.string token.token )
        , ( "expiresAt", token.expiresAt |> Maybe.map (Time.posixToMillis >> Encode.int) |> Maybe.withDefault Encode.null )
        ]


encodePersistedServer : Server -> Encode.Value
encodePersistedServer server =
    Encode.object
        [ ( "frontendHost", Encode.string server.frontendHost )
        , ( "enabled", Encode.bool server.enabled )
        ]


emptyPersistedState : PersistedState
emptyPersistedState =
    { accounts = [], servers = [] }


{-| The `PushManager.subscribe()` result Ports.pushSubscribed's JS side hands back on success --
see `RegisterPushSubscriptionRequest`, which this maps directly onto.
-}
type alias PushSubscriptionKeys =
    { endpoint : String
    , p256dhKey : String
    , authKey : String
    }


{-| Decodes `Ports.pushSubscribed`'s payload: `{ accountId, ok, endpoint, p256dhKey, authKey }` on
success, or `{ accountId, ok, error }` (`ok = False`) on failure -- see that port's own doc
comment. `accountId` comes back either way, so `PushSubscriptionPortReceived` can always tell which
account's `subscribeToPush` call this answers.
-}
pushSubscriptionPortDecoder : Decoder ( String, Result String PushSubscriptionKeys )
pushSubscriptionPortDecoder =
    Decode.field "accountId" Decode.string
        |> Decode.andThen
            (\id ->
                Decode.field "ok" Decode.bool
                    |> Decode.andThen
                        (\ok ->
                            if ok then
                                Decode.map3 PushSubscriptionKeys
                                    (Decode.field "endpoint" Decode.string)
                                    (Decode.field "p256dhKey" Decode.string)
                                    (Decode.field "authKey" Decode.string)
                                    |> Decode.map (\keys -> ( id, Ok keys ))

                            else
                                Decode.field "error" Decode.string
                                    |> Decode.map (\error -> ( id, Err error ))
                        )
            )


{-| `Ports.pushSubscriptionChecked`'s payload when the browser has an active Web Push subscription
-- see that port's own doc comment for why `publicKey` (not an `accountId`, which the Push API has
no concept of) is what identifies which account it belongs to.
-}
type alias PushSubscriptionCheck =
    { endpoint : String
    , publicKey : String
    }


{-| Decodes `Ports.pushSubscriptionChecked`'s payload: `null`, or `{ endpoint, publicKey }`.
-}
pushSubscriptionCheckDecoder : Decoder (Maybe PushSubscriptionCheck)
pushSubscriptionCheckDecoder =
    Decode.nullable
        (Decode.map2 PushSubscriptionCheck
            (Decode.field "endpoint" Decode.string)
            (Decode.field "publicKey" Decode.string)
        )


persistedStateDecoder : Decoder PersistedState
persistedStateDecoder =
    Decode.map2 PersistedState
        (Decode.field "accounts" (Decode.list accountDecoder))
        (Decode.field "servers" (Decode.list persistedServerDecoder))


{-| `elm/json` only provides `map8`, but `Account` now has 10 fields -- so this
decodes the first 8 into a partially-applied `Account` constructor, then
applies `realName` and `needsPassword` on top of that.
-}
accountDecoder : Decoder Account
accountDecoder =
    Decode.map3 (\partial realName needsPassword -> partial realName needsPassword)
        (Decode.map8 Account
            (Decode.field "server" Decode.string)
            (Decode.field "userId" Decode.string)
            (Decode.field "username" Decode.string)
            (Decode.field "refreshToken" tokenDecoder)
            (Decode.field "accessToken" tokenDecoder)
            (Decode.field "enabled" Decode.bool)
            (optionalString "avatarMediaId")
            permissionsDecoder
        )
        realNameDecoder
        needsPasswordDecoder


{-| Defaults to "" if the key is missing entirely (older persisted state),
without failing the rest of the decode.
-}
realNameDecoder : Decoder String
realNameDecoder =
    Decode.oneOf
        [ Decode.field "realName" Decode.string
        , Decode.succeed ""
        ]


{-| Defaults to `False` if the key is missing entirely (older persisted
state, or a freshly-logged-in account -- see `GotAuthResult`), without
failing the rest of the decode.
-}
needsPasswordDecoder : Decoder Bool
needsPasswordDecoder =
    Decode.oneOf
        [ Decode.field "needsPassword" Decode.bool
        , Decode.succeed False
        ]


{-| Defaults to no permissions if the key is missing entirely (older
persisted state), without failing the rest of the decode.
-}
permissionsDecoder : Decoder (List Permission)
permissionsDecoder =
    Decode.oneOf
        [ Decode.field "permissions" (Decode.list (Decode.map permissionFromInt Decode.int))
        , Decode.succeed []
        ]


permissionFromInt : Int -> Permission
permissionFromInt n =
    case n of
        0 ->
            PERMISSIONUNKNOWN

        1 ->
            VIEWUSERS

        2 ->
            PUBLISHUSERSLOCALLY

        3 ->
            PUBLISHUSERSGLOBALLY

        4 ->
            MODERATEUSERS

        5 ->
            FOLLOWUSERS

        6 ->
            GRANTBASICPERMISSIONS

        10 ->
            VIEWGROUPS

        11 ->
            CREATEGROUPS

        12 ->
            PUBLISHGROUPSLOCALLY

        13 ->
            PUBLISHGROUPSGLOBALLY

        14 ->
            MODERATEGROUPS

        15 ->
            JOINGROUPS

        16 ->
            INVITEGROUPMEMBERS

        20 ->
            VIEWPOSTS

        21 ->
            CREATEPOSTS

        22 ->
            PUBLISHPOSTSLOCALLY

        23 ->
            PUBLISHPOSTSGLOBALLY

        24 ->
            MODERATEPOSTS

        25 ->
            REPLYTOPOSTS

        30 ->
            VIEWEVENTS

        31 ->
            CREATEEVENTS

        32 ->
            PUBLISHEVENTSLOCALLY

        33 ->
            PUBLISHEVENTSGLOBALLY

        34 ->
            MODERATEEVENTS

        35 ->
            RSVPTOEVENTS

        36 ->
            SYNCHRONIZEEVENTS

        37 ->
            SYNCEVENTSTOFACEBOOK

        40 ->
            VIEWMEDIA

        41 ->
            CREATEMEDIA

        42 ->
            PUBLISHMEDIALOCALLY

        43 ->
            PUBLISHMEDIAGLOBALLY

        44 ->
            MODERATEMEDIA

        50 ->
            READPERSONALMESSAGES

        51 ->
            READALLSYSTEMMESSAGES

        9998 ->
            BUSINESS

        9999 ->
            RUNBOTS

        10000 ->
            ADMIN

        10001 ->
            VIEWPRIVATECONTACTMETHODS

        other ->
            PermissionUnrecognized_ other


persistedServerDecoder : Decoder PersistedServer
persistedServerDecoder =
    Decode.map2 PersistedServer
        (Decode.field "frontendHost" Decode.string)
        (Decode.field "enabled" Decode.bool)


{-| Accepts both the current `{token, expiresAt}` shape and the older
bare-string shape (from before tokens tracked expiration), so existing
persisted accounts aren't invalidated by this change.
-}
tokenDecoder : Decoder Token
tokenDecoder =
    Decode.oneOf
        [ Decode.map2 Token
            (Decode.field "token" Decode.string)
            (Decode.maybe (Decode.field "expiresAt" (Decode.nullable Decode.int))
                |> Decode.map (Maybe.andThen identity >> Maybe.map Time.millisToPosix)
            )
        , Decode.map (\token -> { token = token, expiresAt = Nothing }) Decode.string
        ]


optionalString : String -> Decoder (Maybe String)
optionalString field =
    Decode.maybe (Decode.field field (Decode.nullable Decode.string))
        |> Decode.map (Maybe.andThen identity)


tokenFromExpirable : ExpirableToken -> Token
tokenFromExpirable expirable =
    { token = expirable.token
    , expiresAt = Maybe.map timestampToPosix expirable.expiresAt
    }


{-| Whether a token is expired, or expiring within the next minute (enough
margin that it shouldn't expire mid-request). A token with no expiration
(`expiresAt == Nothing`, the default unless a server was asked for one)
never expires.
-}
isExpired : Time.Posix -> Token -> Bool
isExpired now token =
    case token.expiresAt of
        Nothing ->
            False

        Just expiresAt ->
            Time.posixToMillis now + 60000 >= Time.posixToMillis expiresAt


{-| Ensures `account`'s access token is valid as of now (refreshing it first
if needed), then performs `req` with it. `req` is given just the access token
string, ready to pass to `withAccessToken`. Returns the account
as it ended up (with refreshed tokens if a refresh happened, unchanged
otherwise) alongside `req`'s result, so the caller can persist any refreshed
tokens. Private -- `refreshPermissions`/`setWebUserInterface` below (this
module's own callers, which already hold a live `Account`) use this
directly; everyone else goes through `performWithAccountServer`/
`performWithOptionalAccountServer`, which resolve a fresh `Account`/`Server`
from a `MaybeAccountServer` instead of holding one of their own.
-}
performWithAccount :
    Connection
    -> Account
    -> (String -> Task Grpc.Error b)
    -> Task Grpc.Error ( Account, b )
performWithAccount connection account req =
    performWithAccountNotifying connection account req
        |> Task.map (\( refreshedAccount, _, result ) -> ( refreshedAccount, result ))


{-| Like `performWithAccount`, but also surfaces the raw `AccessTokenResponse`
if a refresh happened (`Nothing` otherwise).
-}
performWithAccountNotifying :
    Connection
    -> Account
    -> (String -> Task Grpc.Error b)
    -> Task Grpc.Error ( Account, Maybe AccessTokenResponse, b )
performWithAccountNotifying connection account req =
    Time.now
        |> Task.andThen (\now -> refreshIfNeeded connection now account)
        |> Task.andThen
            (\( refreshedAccount, refreshResponse ) ->
                req refreshedAccount.accessToken.token
                    |> Task.map (\result -> ( refreshedAccount, refreshResponse, result ))
            )


resolveAccountServer : Model -> MaybeAccountServer -> Maybe ( Maybe Account, Server )
resolveAccountServer model ( maybeUserId, host ) =
    serverForHost model.servers host
        |> Maybe.andThen
            (\server ->
                -- A known-but-disconnected server (see `Server.connected`) can't
                -- actually be reached, so treat it the same as `host` not being a
                -- known server at all -- both end up failing with
                -- `Grpc.NetworkError` in `performWithAccountServer`/
                -- `performWithOptionalAccountServer`.
                if server.connected == Nothing then
                    Nothing

                else
                    Just
                        ( maybeUserId
                            |> Maybe.andThen (\userId -> model.accounts |> List.filter (\a -> a.userId == userId && a.server == host) |> List.head)
                        , server
                        )
            )


{-| Like `performWithAccount`, but takes a `MaybeAccountServer` (resolved
fresh against `model`) instead of a live `Account`, and requires that it
resolve to one -- fails with `Grpc.NetworkError` if `host` isn't a known
server, or if no matching account is found (both meaning the caller
shouldn't have gotten this far; see e.g. `Shared.MarkdownPanel.resolve`'s
own pre-flight, user-facing gating). `req` gets the resolved `Server` (for
`Grpc.setHost`) and access token string. Returns an already-built `Msg` to
dispatch (via whatever out-msg/`Effect` mechanism the caller already uses
for e.g. `Shared.AccountsPanelMsg`) if a token refresh happened, `Nothing`
otherwise -- callers never see the raw `AccessTokenResponse`.
-}
performWithAccountServer :
    Model
    -> MaybeAccountServer
    -> (Server -> String -> Task Grpc.Error b)
    -> Task Grpc.Error ( Maybe Msg, b )
performWithAccountServer model maybeAccountServer req =
    case resolveAccountServer model maybeAccountServer of
        Just ( Just account, server ) ->
            case connectionOf server of
                -- `resolveAccountServer` only ever resolves to a connected `Server`
                -- (see `Server.connected`), so this is unreachable in practice.
                Nothing ->
                    Task.fail Grpc.NetworkError

                Just connection ->
                    performWithAccountNotifying connection account (req server)
                        |> Task.map
                            (\( refreshedAccount, maybeResponse, result ) ->
                                ( Maybe.map (AccessTokenResponseReceived refreshedAccount) maybeResponse, result )
                            )

        _ ->
            Task.fail Grpc.NetworkError


{-| Like `performWithAccountServer`, but the account is optional: with a
`MaybeAccountServer` that resolves to a known account, authenticates
(refreshing first if needed) exactly like `performWithAccountServer`; with
`( Nothing, host )` (or a `userId` that doesn't resolve to an account),
performs `req` anonymously (no authorization header). Fails with
`Grpc.NetworkError` only if `host` itself isn't a known server.
-}
performWithOptionalAccountServer :
    Model
    -> MaybeAccountServer
    -> (Server -> Maybe String -> Task Grpc.Error b)
    -> Task Grpc.Error ( Maybe Msg, b )
performWithOptionalAccountServer model maybeAccountServer req =
    case resolveAccountServer model maybeAccountServer of
        Just ( Just account, server ) ->
            case connectionOf server of
                -- `resolveAccountServer` only ever resolves to a connected `Server`
                -- (see `Server.connected`), so this is unreachable in practice.
                Nothing ->
                    Task.fail Grpc.NetworkError

                Just connection ->
                    performWithAccountNotifying connection account (Just >> req server)
                        |> Task.map
                            (\( refreshedAccount, maybeResponse, result ) ->
                                ( Maybe.map (AccessTokenResponseReceived refreshedAccount) maybeResponse, result )
                            )

        Just ( Nothing, server ) ->
            req server Nothing |> Task.map (Tuple.pair Nothing)

        Nothing ->
            Task.fail Grpc.NetworkError


refreshIfNeeded :
    Connection
    -> Time.Posix
    -> Account
    -> Task Grpc.Error ( Account, Maybe AccessTokenResponse )
refreshIfNeeded connection now account =
    if not (isExpired now account.accessToken) then
        Task.succeed ( account, Nothing )

    else
        Grpc.new Jonline.accessToken { refreshToken = account.refreshToken.token, expiresAt = Nothing }
            |> Grpc.setHost (connectionUrl connection)
            |> Grpc.toTask
            |> Task.andThen
                (\resp ->
                    case resp.accessToken of
                        Just accessToken ->
                            Task.succeed
                                ( { account
                                    | accessToken = tokenFromExpirable accessToken
                                    , refreshToken =
                                        resp.refreshToken
                                            |> Maybe.map tokenFromExpirable
                                            |> Maybe.withDefault account.refreshToken
                                  }
                                , Just resp
                                )

                        Nothing ->
                            Task.fail Grpc.NetworkError
                )


withAccessToken : Maybe String -> Grpc.RpcRequest req res -> Grpc.RpcRequest req res
withAccessToken maybeToken req =
    case maybeToken of
        Just token ->
            Grpc.addHeader "authorization" token req

        Nothing ->
            req
