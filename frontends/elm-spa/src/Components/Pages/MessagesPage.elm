module Components.Pages.MessagesPage exposing
    ( MessagingGroupRef
    , Model
    , Msg(..)
    , PageContext
    , empty
    , init
    , subscriptions
    , totalUnreadCount
    , update
    , view
    )

{-| The shared guts of a "list of MessagingGroups, expandable into their
messages" listing -- reused by `Pages.Messages` (the real, routed `/messages`
page, which can go two-pane via `?messaging_group=`) and
`Shared.MessagingPanel` (a nav-toggled panel embedding the same listing in
single-pane form, where a group/message click navigates to the real page
instead).

Unlike its nearest sibling `Components.Pages.UsersPage` (which imports
`Shared` and returns `Effect Msg`), this can't depend on `Shared` at all --
`Shared.MessagingPanel` embeds this, and `Shared` embeds
`Shared.MessagingPanel`, so a `Shared` import here would cycle. So this
follows `Shared.StarredPanel`'s signature convention instead: `AccountsPanel.Model`
in, plain `Cmd Msg` out, a `Maybe AccountsPanel.Msg` to forward on a token
refresh. `PageContext == Nothing` is how an embedding caller (the panel) says
"there's no `/messages` URL to reflect state into, and never go two-pane" --
see its doc.

-}

import Animation
import Browser.Dom as Dom
import Browser.Navigation
import Components.Authors as Authors
import Components.Messages as Messages
import Dict exposing (Dict)
import Grpc
import Html exposing (Html, button, div, p, span, text)
import Html.Attributes exposing (class, href, id, title)
import Html.Events exposing (onClick, onInput, preventDefaultOn)
import Html.Keyed
import Json.Decode as Decode
import Process
import Proto.Jonline exposing (Author, Message, defaultMessageRead)
import Proto.Jonline.MessageListingType exposing (MessageListingType(..))
import Set exposing (Set)
import Shared.AccountsPanel as AccountsPanel
import Shared.Time as SharedTime
import Task
import Time
import UI.Classes exposing (classes, hostnameToCSSClass, openClosedClass)
import UI.Flip
import Url.Builder



-- MODEL


type alias Model =
    { -- Fixed for this `Model`'s whole lifetime, set once at construction
      -- (`empty`/`init`) and never touched again by `update` -- everything
      -- below is the dynamic state that actually changes over that lifetime.
      pageContext : Maybe PageContext

    -- `True` iff `pageContext == Nothing` (`Shared.MessagingPanel`'s
    -- embedded copy) -- kept as its own field (set alongside `pageContext`
    -- at every construction site, see `empty`/`init`) since view code
    -- branching on "am I embedded" reads clearer against a plain `Bool`
    -- than re-deriving it from `pageContext` at every call site.
    , embeddedPanel : Bool
    , messagesByServer : Dict String ServerFeed

    -- One flat, FLIP-animated list covering *both* the sidebar's group rows
    -- and, for whichever groups are currently inline-open (`inlineOpenGroups`)
    -- and not in search mode, their own messages spliced in right after their
    -- row (`flattenSidebar`/`syncSidebarAnimations`) -- so expanding/collapsing
    -- a group's chevron is just its message rows entering/leaving this same
    -- list, and every row below slides smoothly to fill the gap, the same
    -- `UI.Flip` mechanism `groupsListView` already used for a group row
    -- itself appearing/disappearing. Each entry carries its own frozen
    -- `sortKey` (see `groupSortKey`/`messageSortKey`) rather than one derived
    -- fresh from `messagesByServer`/`expandedGroups` at render time -- exactly
    -- the "stable per-item sort key" `UI.Flip.remove`'s own doc calls for, so
    -- a row that's mid fade-out (its data source already gone) still renders
    -- at its last real position instead of jumping to the end.
    , sidebarAnimations : Dict String SidebarAnimation
    , expandedGroups : Dict String ExpandedGroup

    -- Which groups' `expandedGroups` entry (if any -- see `ToggleExpand`)
    -- is currently shown *inline*, under its own row in `groupsListView`
    -- (the chevron toggle) -- kept entirely separate from `expandedGroups`
    -- itself so that dict can stay a pure fetch cache, keyed the same way
    -- whether a group got there via the sidebar's own chevron or via
    -- `selectedGroup` (two-pane detail): collapsing a group's *inline*
    -- view (removing it from this `Set`) never discards its fetched
    -- messages, so the two-pane detail pane -- reading that same
    -- `expandedGroups` entry -- can't be blanked out as a side effect of
    -- the sidebar row for that same group also being toggled shut. This is
    -- what lets *every* row stay inline-expandable, including whichever one
    -- is currently `selectedGroup` -- see `groupRowView`'s own doc.
    , inlineOpenGroups : Set String
    , searchText : String
    , searchGeneration : Int
    , selectedGroup : Maybe MessagingGroupRef
    , pendingScrollMessageId : Maybe String

    -- The one message (if any) to draw attention to with a `border-color-nav`
    -- outline (`messageRowView`) -- unlike `pendingScrollMessageId`, *not*
    -- cleared after the one-shot scroll it's set alongside (`init`'s own
    -- `#message-<id>` fragment, `MessageSelected`'s own click, see that
    -- constructor's doc) -- it should keep reading as "the message you
    -- arrived here for" for as long as this page stays open, on both the
    -- right (two-pane detail, always) and left (sidebar inline-expand, only
    -- if that message's own group happens to be inline-open there too --
    -- see `groupRowView`'s own doc on why that's independent) wherever it
    -- happens to render.
    , highlightMessageId : Maybe String

    -- Two-pane mode only, and only actually visible on a narrow (< 640px)
    -- screen -- see `view`'s own doc. Always starts `False` (see `empty`):
    -- landing on a two-pane permalink should show the message itself first,
    -- not a sidebar covering it, on a phone-width screen.
    , mobileSidebarOpen : Bool

    -- The two-pane detail pane's *own* keyed copy of whichever group's
    -- messages `selectedGroup` currently means -- rendered by the same
    -- `messageThreadView` (and so the same per-message `UI.Flip` enter/
    -- remove) as the sidebar's own message rows, just synced
    -- (`syncDetailThreadAnimations`) against `selectedGroup`'s current
    -- messages instead of `sidebarAnimations`' own inline-open-groups
    -- reconciliation. Kept separate from `expandedGroups[key].messages`
    -- (a plain fetch cache with no `flip` of its own) specifically so
    -- `GroupSelected` switching to a *different* group reads as this dict's
    -- own current messages leaving (`UI.Flip.remove`) while the newly
    -- selected group's arrive (`UI.Flip.enter`) -- see
    -- `syncDetailThreadAnimations`.
    , detailThreadAnimations : Dict String MessageAnimation
    }


{-| Where a group/message row navigates/pushes state to (`Just` -- the real
`/messages` page) or doesn't at all (`Nothing` -- `Shared.MessagingPanel`'s
embedded copy: never two-pane, group/message rows are plain `href`s out to
the real page instead of `onClick`-driven in-place state, and search text
never rewrites the (unrelated) page the panel happens to be open on top of).
-}
type alias PageContext =
    { navKey : Browser.Navigation.Key
    , path : String
    }


{-| Identifies one `MessagingGroup`/`FromEmail`/`SoloMessage` group (see
`Components.Messages.MessagingGroupKind`) across every fetched server -- mirrors that
module's own `GroupSummary.key`/`.host`/`.groupId`/`.kind`.
-}
type alias MessagingGroupRef =
    { key : String
    , host : String
    , groupId : String
    , kind : Messages.MessagingGroupKind
    }


type ServerMessages
    = Loading
    | Loaded (List Message)
    | Failed


type alias ServerFeed =
    { status : ServerMessages
    , accountId : Maybe String
    , listingType : MessageListingType
    }


{-| One entry of `Model.sidebarAnimations`' flat list -- either a group's own
row, or (only for an inline-open, `ExpandLoaded`, non-search group) one of its
messages -- see that field's own doc.
-}
type SidebarRow
    = SidebarGroupRow Messages.GroupSummary
    | SidebarMessageRow MessagingGroupRef Message


type alias SidebarAnimation =
    { row : SidebarRow

    -- Frozen at whatever it was computed to be the last time this entry was
    -- still `current` (`flattenSidebar`) -- see `Model.sidebarAnimations`'
    -- own doc on why a live re-lookup at render time would break a
    -- mid-fade-out row's position.
    , sortKey : ( Int, Int )
    , flip : UI.Flip.State Msg
    }


type ExpandedStatus
    = ExpandLoading
    | ExpandLoaded
    | ExpandFailed


type alias MessageAnimation =
    { message : Message
    , flip : UI.Flip.State Msg
    }


type alias ExpandedGroup =
    { status : ExpandedStatus

    -- A plain fetch cache -- unlike `Model.sidebarAnimations`/
    -- `Model.detailThreadAnimations`, nothing here carries its own `flip`:
    -- this dict isn't rendered directly by anything anymore, just read as
    -- the *source* both of those sync against (`syncSidebarAnimations`,
    -- `syncDetailThreadAnimations`).
    , messages : Dict String Message

    -- Carried alongside `status`/`messages` (duplicating the outer
    -- `expandedGroups` Dict key) so `retryPendingExpansions` can re-issue
    -- the fetch for a still-`ExpandLoading` entry without needing a
    -- `MessagingGroupRef` from anywhere else -- see that function's own doc.
    , host : String
    , groupId : String
    , kind : Messages.MessagingGroupKind
    }


type Msg
    = GotServerMessages String (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetMessagesResponse ))
    | Poll
      -- Unconditionally refetches *every* `eligibleEntries` server's outer
      -- listing, unlike `Poll` (via `fetchNewServers`), which only fetches
      -- servers that are newly eligible or whose account/listingType just
      -- changed -- deliberately conservative there, so idle browsing/the
      -- 30s timer doesn't keep re-fetching (and reordering/re-animating) a
      -- listing that's already loaded and hasn't been told anything
      -- changed. `ForceRefresh` is for exactly the opposite case: something
      -- *did* just change server-side that this `Model` has no way to have
      -- noticed on its own -- a message was just sent (`Pages.Messages`'
      -- own `SendNewMessage` success) or marked read/unread (`GotMarkReadResult`)
      -- from *this page's own or the embedded panel's* `MessagesPage.Model`
      -- -- see both call sites' own doc comments.
    | ForceRefresh
    | Animate Animation.Msg
    | RemoveSidebarRow String
    | ToggleExpand Messages.GroupSummary
    | GotGroupMessages String (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetMessagesResponse ))
      -- Fired once per thread, batching every still-`Messages.isUnread`
      -- message in it into one `MarkMessagesRead` call, right when that
      -- thread finishes loading (`GotGroupMessages`'s own `Ok` branch
      -- already optimistically patches those same messages'
      -- `currentUserRead` locally, both in `expandedGroups` and, so
      -- `GroupSummary.unreadCount` stays in sync too, `messagesByServer` --
      -- see that branch's own doc) -- this is just the actual RPC catching
      -- up with what the UI already shows. Errors are silently dropped: a
      -- thread that failed to mark read server-side just looks read locally
      -- for the rest of this session, and gets a fresh attempt the next
      -- time it's opened (or reloaded) instead of any bespoke retry here.
    | GotMarkReadResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, List Proto.Jonline.MessageRead ))
    | SearchTextChanged String
    | SearchDebounceElapsed Int
    | ClearSearchClicked
    | GroupSelected MessagingGroupRef
      -- Fired regardless of whether the scroll itself actually succeeded
      -- (`scrollToPendingMessageCmd`'s own `Task.attempt` result is
      -- discarded, not carried on this constructor) -- either way, this
      -- was the one-shot attempt, so `pendingScrollMessageId` gets cleared
      -- the same way (see its own doc on `Model`).
    | ScrollAttempted
      -- Steps `detailThreadAnimations`' own FLIP states forward -- mirrors
      -- `Animate`, just for `Model.detailThreadAnimations` instead of
      -- `Model.sidebarAnimations`.
    | DetailMessageAnimate Animation.Msg
      -- Fired once one `detailThreadAnimations` entry's fade-out actually
      -- finishes (mirrors `RemoveSidebarRow`) -- drops it from the dict,
      -- same as any other FLIP `remove`'s `onRemoved`.
    | RemoveDetailMessage String
    | ToggleMobileSidebar
      -- Fired by `.messages-detail`'s own `onClick` (two-pane, narrow screens
      -- only -- see `view`'s own doc) -- the mobile drawer never covers the
      -- full width, so tapping the sliver of the selected conversation still
      -- peeking out beside it is exactly a "tap outside the drawer to
      -- dismiss it" gesture. Unconditionally sets `mobileSidebarOpen = False`
      -- rather than toggling (`ToggleMobileSidebar`) -- a click landing here
      -- when it's already closed (the common case) should stay a no-op, not
      -- reopen it.
    | CloseMobileSidebar
      -- Fired by a group row's `onClick` *only* when `embeddedPanel == True`
      -- (alongside its own `href`, not instead of it) -- a pure signal with
      -- no effect on this instance's own state (see its `update` branch);
      -- its only purpose is to exist as a `MessagesPage.Msg` so it flows
      -- up through `Shared.MessagingPanel.PageMsg` -> `Shared.Msg` ->
      -- `Main.elm`'s `notifyPageOfSharedMsg`, which forwards *any*
      -- `Shared.Msg` to whichever page is currently mounted. When that's
      -- the real `/messages` page, `Pages.Messages`'s own `SharedMsg`
      -- handling pattern-matches all the way down to this constructor and
      -- applies `SyncSelectedGroup` to *that* instance instead -- see its
      -- own doc for why plain `href` navigation alone doesn't already
      -- handle this (a same-path query-only change).
    | EmbeddedGroupLinkClicked MessagingGroupRef
      -- `GroupSelected`'s own effect (expand + `selectedGroup`), minus the
      -- `pushUrl` -- see `EmbeddedGroupLinkClicked`'s doc: dispatched only
      -- via that forwarding path, where the URL bar's already been updated
      -- by the embedded panel's own real `<a href>` navigation, so pushing
      -- it again here would just double up the browser history entry.
    | SyncSelectedGroup MessagingGroupRef
      -- The two-pane detail header's "Reply" button (`selectedGroupView`,
      -- real page only -- see that view's own doc). A pure signal, same
      -- forwarding trick `EmbeddedGroupLinkClicked` uses (no-op for *this*
      -- instance's own state, see its `update` branch): `Pages.Messages`'s
      -- own `PageMsg` handling intercepts it before it ever reaches
      -- `applyPageMsg`/this module's `update`, and dispatches
      -- `Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.SendNewMessage
      -- recipients) ref.host)` instead -- this module can't do that itself,
      -- it doesn't (can't) import `Shared`. The `List Author` recipients are
      -- computed at the click site (`selectedGroupView` already has
      -- `threadParticipants eg` in scope) rather than re-derived from
      -- `model` up in `Pages.Messages`, which only has this module's own
      -- opaque `Model` to work with.
    | ReplyClicked MessagingGroupRef (List Author)
      -- A message row clicked inline in the sidebar's own inline-expand
      -- (`groupRowView`/`expandedGroupView`, real page only -- the embedded
      -- panel's own inline-expand messages are plain external permalink
      -- `<a href>`s instead, see `messageInteractionFor`). Selects `ref`
      -- into the two-pane detail (same effect as `GroupSelected`, see its
      -- own doc) *and* sets both `highlightMessageId` and
      -- `pendingScrollMessageId` to `messageId`, so the clicked message
      -- itself is what the detail pane scrolls to and highlights -- same
      -- as landing on a `#message-<id>` permalink directly, just reached by
      -- clicking instead of a URL. Works the same whether or not some other
      -- group is currently selected -- clicking a message is always a real
      -- navigational choice, unlike merely toggling a group's chevron open
      -- (`ToggleExpand`, which never touches `selectedGroup` at all).
    | MessageSelected MessagingGroupRef String
      -- Fired by a message row's `onClick` *only* when `embeddedPanel ==
      -- True` (alongside its own external `<a href>` permalink, not instead
      -- of it) -- the message-level counterpart to `EmbeddedGroupLinkClicked`,
      -- for exactly the same reason: a same-path query/fragment-only URL
      -- change doesn't reach `Pages.Messages`' own `init`/`update` at all,
      -- so without this, clicking a message in the embedded panel while
      -- already on `/messages` would silently update the URL bar and
      -- nothing else. A pure signal, no effect on this instance's own state
      -- (see its `update` branch): flows up through `Shared.MessagingPanelMsg`
      -- -> `Main.notifyPageOfSharedMsg` -> `Pages.Messages`' own `SharedMsg`
      -- handling, which applies `SyncSelectedMessage` to *that* instance
      -- instead.
    | EmbeddedMessageLinkClicked MessagingGroupRef String
      -- `MessageSelected`'s own effect (expand + select + scroll/highlight),
      -- minus the `pushUrl` -- same relationship `SyncSelectedGroup` has to
      -- `GroupSelected`: the embedded panel's own `<a href>` (`messageRowView`)
      -- already carries this exact message's `#message-<id>` fragment, so
      -- the browser's own navigation is what put it in the URL bar here,
      -- not another `pushUrl`.
    | SyncSelectedMessage MessagingGroupRef String
      -- The "Mark unread" button on an already-read message row (any
      -- context -- two-pane detail, sidebar inline-expand, or embedded
      -- panel). `host` (not a whole `MessagingGroupRef`) is all `update` needs to
      -- resolve which account to fire `MarkMessagesRead { unread = True }`
      -- as -- see its own handling, which mirrors `GotGroupMessages`'
      -- optimistic-patch-then-fire-the-RPC shape, just in reverse and for a
      -- single message instead of a whole thread's unread ones.
    | MarkUnreadClicked String String
      -- The header row's "Compose" button (`searchRowView`, real page only --
      -- mirrors `ReplyClicked`'s own "pure signal, `Shared` does the actual
      -- work" pattern, since this module can't depend on `Shared`/
      -- `MarkdownPanel` itself). `Pages.Messages`'s own `PageMsg` handling
      -- intercepts this before it ever reaches `applyPageMsg`/this module's
      -- `update` (whose own handling below is a no-op), and dispatches
      -- `Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.SendNewMessage
      -- []) firstAccount.server)` instead, same as the old
      -- `Pages.Messages.sendMessageButton` used to do directly.
    | ComposeClicked
      -- A `ReplyClicked`/`ComposeClicked` send actually landing --
      -- `Pages.Messages`'s own `SharedMsg` handling of `Shared.MarkdownPanelMsg
      -- (MarkdownPanel.GotSendMessageResult (Ok ...))` dispatches this with
      -- the group the new message landed in and the message's own id, real
      -- page only (same reasoning as `ReplyClicked`/`ComposeClicked` --
      -- `Pages.Messages`'s own `SharedMsg` handling is what fires it, and
      -- only the real page has one; the embedded panel's own `Model` never
      -- gets this constructor at all). Deliberately *not* `MessageSelected`
      -- plus a plain `ForceRefresh`: `expand` (what `MessageSelected` calls)
      -- is a no-op once `ref` is already `expandedGroups`-loaded (see its own
      -- doc) -- exactly the common case for a Reply sent from a thread
      -- that's already open -- so without a dedicated force-refetch here, a
      -- just-sent reply silently wouldn't appear in the still-open thread at
      -- all until some other refetch (a poll, a collapse/re-expand) happened
      -- to catch it up.
    | MessageSent MessagingGroupRef String


{-| A `Model` with nothing fetched yet and no `PageContext` -- what
`Shared.MessagingPanel.init` seeds itself with, so the app never fires a
`GetMessages` RPC on startup before that panel's ever been opened (mirrors
`Shared.StarredPanel`'s own fetch-only-once-shown convention). `init` itself
starts from this too, immediately overriding it with a real fetch.
-}
empty : Model
empty =
    { pageContext = Nothing
    , embeddedPanel = True
    , messagesByServer = Dict.empty
    , sidebarAnimations = Dict.empty
    , expandedGroups = Dict.empty
    , inlineOpenGroups = Set.empty
    , searchText = ""
    , searchGeneration = 0
    , selectedGroup = Nothing
    , pendingScrollMessageId = Nothing
    , highlightMessageId = Nothing
    , mobileSidebarOpen = False
    , detailThreadAnimations = Dict.empty
    }


init : AccountsPanel.Model -> Maybe PageContext -> Maybe MessagingGroupRef -> Maybe String -> String -> ( Model, Cmd Msg )
init accountsPanelModel pageContext selectedGroup pendingScrollMessageId searchText =
    let
        ( fetchedModel, fetchCmd ) =
            fetchNewServers accountsPanelModel
                { empty
                    | pageContext = pageContext
                    , embeddedPanel = pageContext == Nothing
                    , searchText = searchText
                    , selectedGroup = selectedGroup
                    , pendingScrollMessageId = pendingScrollMessageId
                    , highlightMessageId = pendingScrollMessageId
                }

        ( expandedModel, expandCmd ) =
            case selectedGroup of
                Just ref ->
                    expand accountsPanelModel fetchedModel ref

                Nothing ->
                    ( fetchedModel, Cmd.none )
    in
    ( expandedModel, Cmd.batch [ fetchCmd, expandCmd ] )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every 30000 (\_ -> Poll)
        , UI.Flip.subscription Animate (List.map .flip (Dict.values model.sidebarAnimations))
        , UI.Flip.subscription DetailMessageAnimate (Dict.values model.detailThreadAnimations |> List.map .flip)
        ]



-- UPDATE


update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, Maybe AccountsPanel.Msg )
update accountsPanelModel msg model =
    case msg of
        GotServerMessages host (Ok ( maybeAccountsPanelMsg, response )) ->
            ( { model
                | messagesByServer =
                    Dict.update host (Maybe.map (\feed -> { feed | status = Loaded response.messages })) model.messagesByServer
              }
                |> syncSidebarAnimations
            , Cmd.none
            , maybeAccountsPanelMsg
            )

        GotServerMessages host (Err _) ->
            ( { model | messagesByServer = Dict.update host (Maybe.map (\feed -> { feed | status = Failed })) model.messagesByServer }
                |> syncSidebarAnimations
            , Cmd.none
            , Nothing
            )

        Poll ->
            let
                ( newModel, cmd ) =
                    fetchNewServers accountsPanelModel model

                ( retriedModel, retryCmd ) =
                    retryPendingExpansions accountsPanelModel newModel
            in
            ( retriedModel, Cmd.batch [ cmd, retryCmd ], Nothing )

        ForceRefresh ->
            let
                ( refetchedModel, cmd ) =
                    refetchServers accountsPanelModel model (eligibleEntries accountsPanelModel)
            in
            ( refetchedModel, cmd, Nothing )

        Animate animMsg ->
            let
                ( newAnimations, cmds ) =
                    animateSidebarDict animMsg model.sidebarAnimations
            in
            ( { model | sidebarAnimations = newAnimations }, Cmd.batch cmds, Nothing )

        RemoveSidebarRow key ->
            ( { model | sidebarAnimations = Dict.remove key model.sidebarAnimations }, Cmd.none, Nothing )

        ToggleExpand summary ->
            if Set.member summary.key model.inlineOpenGroups then
                ( syncSidebarAnimations { model | inlineOpenGroups = Set.remove summary.key model.inlineOpenGroups }, Cmd.none, Nothing )

            else
                let
                    ( newModel, cmd ) =
                        expand accountsPanelModel
                            { model | inlineOpenGroups = Set.insert summary.key model.inlineOpenGroups }
                            { key = summary.key, host = summary.host, groupId = summary.groupId, kind = summary.kind }
                in
                ( syncSidebarAnimations newModel, cmd, Nothing )

        GotGroupMessages key (Ok ( maybeAccountsPanelMsg, response )) ->
            let
                -- Every message in this thread that's still unread *as
                -- fetched* -- what actually gets `markMessageRead`'d below,
                -- and (via `patchMessageRead`) optimistically shown as read
                -- immediately, rather than waiting on that RPC's own
                -- round trip -- viewing a thread is what marks it read, see
                -- `GotMarkReadResult`'s own doc.
                unreadIds : Set String
                unreadIds =
                    response.messages |> List.filter Messages.isUnread |> List.map .id |> Set.fromList

                patchedMessages : List Message
                patchedMessages =
                    List.map (patchMessageRead unreadIds) response.messages

                -- The host this group's thread actually lives on -- carried
                -- on `ExpandedGroup` itself (see its own doc) precisely for
                -- self-contained lookups like this one, rather than needing
                -- a `MessagingGroupRef` threaded in from wherever `GotGroupMessages`
                -- happened to be dispatched.
                host : Maybe String
                host =
                    Dict.get key model.expandedGroups |> Maybe.map .host

                newModel : Model
                newModel =
                    { model
                        | expandedGroups =
                            Dict.update key
                                (Maybe.map
                                    (\eg ->
                                        { eg
                                            | status = ExpandLoaded
                                            , messages = patchedMessages |> List.map (\message -> ( message.id, message )) |> Dict.fromList
                                        }
                                    )
                                )
                                model.expandedGroups

                        -- Patches the *outer listing's* own copy of these
                        -- same messages too (if `host` has one), so
                        -- `syncSidebarAnimations` below recomputes each
                        -- affected `GroupSummary.unreadCount` immediately --
                        -- without this, the group card's own unread badge
                        -- wouldn't catch up until the next 30s `Poll`
                        -- refetches the outer listing fresh from the server.
                        , messagesByServer =
                            case host of
                                Just h ->
                                    Dict.update h (Maybe.map (patchServerFeedRead unreadIds)) model.messagesByServer

                                Nothing ->
                                    model.messagesByServer
                    }
                        |> syncSidebarAnimations
                        -- Re-syncs `detailThreadAnimations` (its own doc) in
                        -- case `key` is the currently `selectedGroup` -- this
                        -- is what actually starts the entrance animation for
                        -- a freshly opened group's messages, since they
                        -- weren't loaded yet at `GroupSelected`'s own sync.
                        |> syncDetailThreadAnimations

                markReadCmd : Cmd Msg
                markReadCmd =
                    case ( host, Set.toList unreadIds ) of
                        ( Just h, (_ :: _) as ids ) ->
                            let
                                accountUserId : Maybe String
                                accountUserId =
                                    Dict.get h model.messagesByServer |> Maybe.andThen .accountId
                            in
                            Messages.markMessagesRead accountsPanelModel ( accountUserId, h ) False ids
                                |> Task.attempt GotMarkReadResult

                        _ ->
                            Cmd.none
            in
            ( newModel, Cmd.batch [ scrollToPendingMessageCmd newModel, markReadCmd ], maybeAccountsPanelMsg )

        GotGroupMessages key (Err _) ->
            ( { model | expandedGroups = Dict.update key (Maybe.map (\eg -> { eg | status = ExpandFailed })) model.expandedGroups }
            , Cmd.none
            , Nothing
            )

        GotMarkReadResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            ( model, Cmd.none, maybeAccountsPanelMsg )

        GotMarkReadResult (Err _) ->
            ( model, Cmd.none, Nothing )

        MarkUnreadClicked host messageId ->
            let
                unreadIds : Set String
                unreadIds =
                    Set.singleton messageId

                -- Every `expandedGroups` entry (not just whichever one this
                -- message actually belongs to -- there's no cheap way to
                -- know that from just `host`/`messageId`) gets a pass over
                -- its own `messages`; a no-op wherever `messageId` doesn't
                -- appear.
                patchedExpandedGroups : Dict String ExpandedGroup
                patchedExpandedGroups =
                    Dict.map
                        (\_ eg -> { eg | messages = Dict.map (\_ message -> patchMessageUnread unreadIds message) eg.messages })
                        model.expandedGroups

                newModel : Model
                newModel =
                    { model
                        | expandedGroups = patchedExpandedGroups
                        , messagesByServer = Dict.update host (Maybe.map (patchServerFeedUnread unreadIds)) model.messagesByServer
                    }
                        |> syncSidebarAnimations

                accountUserId : Maybe String
                accountUserId =
                    Dict.get host model.messagesByServer |> Maybe.andThen .accountId
            in
            ( newModel
            , Messages.markMessagesRead accountsPanelModel ( accountUserId, host ) True [ messageId ]
                |> Task.attempt GotMarkReadResult
            , Nothing
            )

        SearchTextChanged newSearchText ->
            let
                generation : Int
                generation =
                    model.searchGeneration + 1
            in
            -- Forces the two-pane mobile sidebar open on every keystroke --
            -- see `view`'s own doc -- rather than only on the debounced
            -- `applySearchChange`, so it snaps open immediately, not ~300ms
            -- after typing starts. It's a plain overwrite, not a lock: the
            -- hamburger (`ToggleMobileSidebar`) can still close it again
            -- right away if the searcher wants to.
            ( { model | searchText = newSearchText, searchGeneration = generation, mobileSidebarOpen = True }
            , Process.sleep 311 |> Task.perform (\_ -> SearchDebounceElapsed generation)
            , Nothing
            )

        SearchDebounceElapsed generation ->
            if generation == model.searchGeneration then
                let
                    ( newModel, cmd ) =
                        applySearchChange accountsPanelModel model
                in
                ( newModel, cmd, Nothing )

            else
                ( model, Cmd.none, Nothing )

        ClearSearchClicked ->
            let
                ( newModel, cmd ) =
                    applySearchChange accountsPanelModel { model | searchText = "", searchGeneration = model.searchGeneration + 1 }
            in
            ( newModel, cmd, Nothing )

        GroupSelected ref ->
            case model.pageContext of
                Nothing ->
                    ( model, Cmd.none, Nothing )

                Just ctx ->
                    let
                        mostRecentId : Maybe String
                        mostRecentId =
                            mostRecentMessageIdFor model ref.key

                        ( expandedModel, expandCmd ) =
                            -- Closes the mobile sidebar overlay too (see
                            -- `view`'s own doc) -- selecting a group should
                            -- reveal what was just picked, not leave it
                            -- covered by the still-open sidebar. Scrolls to
                            -- (and highlights) `mostRecentId` -- same as
                            -- landing on a `#message-<id>` permalink to it
                            -- directly, or clicking it in the sidebar's own
                            -- inline-expand (`MessageSelected`) -- so opening
                            -- a group two-pane always lands on its newest
                            -- message, the one `messageThreadView`'s own
                            -- oldest-first sort (`selectedGroupView`) puts at
                            -- the bottom of the pane, rather than leaving the
                            -- viewer scrolled to the top of the whole thread.
                            -- `syncDetailThreadAnimations` (its own doc)
                            -- re-syncs `detailThreadAnimations` against
                            -- whatever `selectedGroup` now means -- the
                            -- previously selected group's messages (still in
                            -- that dict) start removing, and the newly
                            -- selected one's (if already loaded) start
                            -- entering.
                            expand accountsPanelModel
                                ({ model
                                    | selectedGroup = Just ref
                                    , mobileSidebarOpen = False
                                    , highlightMessageId = mostRecentId
                                    , pendingScrollMessageId = mostRecentId
                                 }
                                    |> syncDetailThreadAnimations
                                )
                                ref

                        urlFragment : String
                        urlFragment =
                            mostRecentId |> Maybe.map (\id -> "#" ++ messageDomId id) |> Maybe.withDefault ""
                    in
                    ( expandedModel
                    , Cmd.batch
                        [ expandCmd
                        , scrollToPendingMessageCmd expandedModel
                        , Browser.Navigation.pushUrl ctx.navKey (ctx.path ++ queryString accountsPanelModel expandedModel ++ urlFragment)
                        ]
                    , Nothing
                    )

        ScrollAttempted ->
            ( { model | pendingScrollMessageId = Nothing }, Cmd.none, Nothing )

        DetailMessageAnimate animMsg ->
            let
                ( newAnimations, cmds ) =
                    animateMessageDict animMsg model.detailThreadAnimations
            in
            ( { model | detailThreadAnimations = newAnimations }, Cmd.batch cmds, Nothing )

        RemoveDetailMessage messageId ->
            ( { model | detailThreadAnimations = Dict.remove messageId model.detailThreadAnimations }, Cmd.none, Nothing )

        ToggleMobileSidebar ->
            ( { model | mobileSidebarOpen = not model.mobileSidebarOpen }, Cmd.none, Nothing )

        CloseMobileSidebar ->
            ( { model | mobileSidebarOpen = False }, Cmd.none, Nothing )

        EmbeddedGroupLinkClicked _ ->
            ( model, Cmd.none, Nothing )

        SyncSelectedGroup ref ->
            let
                ( newModel, cmd ) =
                    syncSelection accountsPanelModel model ref (mostRecentMessageIdFor model ref.key)
            in
            ( newModel, cmd, Nothing )

        EmbeddedMessageLinkClicked _ _ ->
            ( model, Cmd.none, Nothing )

        SyncSelectedMessage ref messageId ->
            let
                ( newModel, cmd ) =
                    syncSelection accountsPanelModel model ref (Just messageId)
            in
            ( newModel, cmd, Nothing )

        ReplyClicked _ _ ->
            ( model, Cmd.none, Nothing )

        ComposeClicked ->
            ( model, Cmd.none, Nothing )

        MessageSelected ref messageId ->
            case model.pageContext of
                Nothing ->
                    ( model, Cmd.none, Nothing )

                Just ctx ->
                    let
                        ( expandedModel, expandCmd ) =
                            -- `syncDetailThreadAnimations`, same as
                            -- `GroupSelected` -- otherwise, if `ref`'s group
                            -- is already `ExpandLoaded` (always true for a
                            -- message clicked out of the sidebar's own
                            -- inline-expand), `expand` below is a no-op and
                            -- `detailThreadAnimations` is never resynced to
                            -- this (possibly different) group's messages, so
                            -- the two-pane detail keeps showing whichever
                            -- group was selected before.
                            expand accountsPanelModel
                                ({ model
                                    | selectedGroup = Just ref
                                    , mobileSidebarOpen = False
                                    , highlightMessageId = Just messageId
                                    , pendingScrollMessageId = Just messageId
                                 }
                                    |> syncDetailThreadAnimations
                                )
                                ref
                    in
                    ( expandedModel
                    , Cmd.batch
                        [ expandCmd
                        , scrollToPendingMessageCmd expandedModel
                        , Browser.Navigation.pushUrl ctx.navKey (ctx.path ++ queryString accountsPanelModel expandedModel ++ "#" ++ messageDomId messageId)
                        ]
                    , Nothing
                    )

        MessageSent ref messageId ->
            case model.pageContext of
                Nothing ->
                    ( model, Cmd.none, Nothing )

                Just ctx ->
                    let
                        -- `fetchExpand`, not `expand` -- see this
                        -- constructor's own doc: `ref` is, in the common
                        -- Reply case, already `ExpandLoaded`, which `expand`
                        -- would treat as a no-op.
                        ( expandedModel, expandCmd ) =
                            fetchExpand accountsPanelModel
                                { model
                                    | selectedGroup = Just ref
                                    , mobileSidebarOpen = False
                                    , highlightMessageId = Just messageId
                                    , pendingScrollMessageId = Just messageId
                                }
                                ref

                        -- Refreshes the outer listing too, same as
                        -- `ForceRefresh` -- otherwise this group's own
                        -- sidebar card (last-message preview, sort order)
                        -- wouldn't catch up with the just-sent message until
                        -- the next 30s poll.
                        ( refreshedModel, refreshCmd ) =
                            refetchServers accountsPanelModel expandedModel (eligibleEntries accountsPanelModel)
                    in
                    ( refreshedModel
                    , Cmd.batch
                        [ expandCmd
                        , refreshCmd
                        , scrollToPendingMessageCmd refreshedModel
                        , Browser.Navigation.pushUrl ctx.navKey (ctx.path ++ queryString accountsPanelModel refreshedModel ++ "#" ++ messageDomId messageId)
                        ]
                    , Nothing
                    )


{-| Shared guts of `SyncSelectedGroup`/`SyncSelectedMessage` -- expands `ref`,
selects it, and highlights/scrolls to `messageId` (`Nothing` just lands on the
top of the thread, same as `expand` alone) -- everything `GroupSelected`/
`MessageSelected` do, minus their own `pushUrl`, since both callers exist
precisely because the embedded panel's own `<a href>` already put the right
URL in the bar (see either constructor's own doc on `Msg`).
-}
syncSelection : AccountsPanel.Model -> Model -> MessagingGroupRef -> Maybe String -> ( Model, Cmd Msg )
syncSelection accountsPanelModel model ref messageId =
    let
        ( expandedModel, expandCmd ) =
            -- `syncDetailThreadAnimations`, same as `GroupSelected`/
            -- `MessageSelected` -- otherwise, if `ref`'s group is already
            -- `ExpandLoaded`, `expand` below is a no-op and
            -- `detailThreadAnimations` never picks up this (possibly
            -- different) group's messages.
            expand accountsPanelModel
                ({ model
                    | selectedGroup = Just ref
                    , mobileSidebarOpen = False
                    , highlightMessageId = messageId
                    , pendingScrollMessageId = messageId
                 }
                    |> syncDetailThreadAnimations
                )
                ref
    in
    ( expandedModel, Cmd.batch [ expandCmd, scrollToPendingMessageCmd expandedModel ] )


{-| The id of `key`'s own `GroupSummary.mostRecent` message, read straight off
`currentGroupSummaries` (the outer listing, always fetched before any row is
clickable at all -- unlike `expandedGroups`, no full-thread fetch is needed
just to know which message is newest). `Nothing` for a group not (yet, or
ever) in that listing -- e.g. a `?messaging_group=` permalink to a group that
was never in the general listing at all (see `fetchExpand`'s own doc on that
case) -- in which case `GroupSelected`/`SyncSelectedGroup` simply don't get a
scroll target or `#message-<id>` fragment to add, same as before this
existed.
-}
mostRecentMessageIdFor : Model -> String -> Maybe String
mostRecentMessageIdFor model key =
    Dict.get key (currentGroupSummaries model) |> Maybe.map (.mostRecent >> .id)


{-| Expands `ref` (re-fires the fetch if it's already `ExpandFailed`, a no-op
for any other already-expanded status -- see that branch's own doc): a
`SoloMessage` (see `Components.Messages.MessagingGroupKind`) is already fully in hand
from the outer listing fetch (`Components.Messages.groupMessages`), so this
just seeds it directly with no RPC; every other group fetches its full thread
via `fetchExpand`, which dispatches to the right `GetMessages` filter for
`ref.kind`. Falls back to `PERSONALMESSAGES`/no known account when `ref.host`
isn't (yet) in `messagesByServer` at all -- e.g. a `?messaging_group=`
permalink to a group whose host the viewer isn't currently signed into with a
matching permission -- so the fetch still fires (and, most likely, 404s into
`ExpandFailed`'s "not found" rendering) rather than silently doing nothing.
-}
expand : AccountsPanel.Model -> Model -> MessagingGroupRef -> ( Model, Cmd Msg )
expand accountsPanelModel model ref =
    case Dict.get ref.key model.expandedGroups |> Maybe.map .status of
        Just ExpandFailed ->
            fetchExpand accountsPanelModel model ref

        Just _ ->
            ( model, Cmd.none )

        Nothing ->
            case Dict.get ref.key (currentGroupSummaries model) of
                Just summary ->
                    if summary.kind == Messages.SoloMessage then
                        ( { model
                            | expandedGroups =
                                Dict.insert ref.key
                                    { status = ExpandLoaded
                                    , messages = Dict.singleton summary.mostRecent.id summary.mostRecent
                                    , host = ref.host
                                    , groupId = ref.groupId
                                    , kind = summary.kind
                                    }
                                    model.expandedGroups
                          }
                        , Cmd.none
                        )

                    else
                        fetchExpand accountsPanelModel model ref

                Nothing ->
                    fetchExpand accountsPanelModel model ref


{-| Fires (or re-fires, see `retryPendingExpansions` and `expand`'s own
`ExpandFailed` branch) the actual `GetMessages` fetch for `ref` -- one of
`fetchMessagingGroup`/`fetchFromEmail`/`fetchMessage` depending on `ref.kind`
(`Components.Messages.MessagingGroupKind`), so a cold permalink (one whose `ref`
never came from an already-fetched `GroupSummary`, e.g. `expand`'s own
`Nothing` branches) always resolves through the RPC filter that actually
matches what `ref.groupId` means, rather than assuming it's always a real
`MessagingGroup.id`. Unless `ref.host` isn't yet a `knownConnectedServer`
(see that function's own doc on the disconnected placeholder every persisted
server starts as), in which case this leaves the entry `ExpandLoading` (never
firing a doomed, instantly-failing request against it) for
`retryPendingExpansions` to actually attempt once the real connection lands
-- mirrors `Components.Messages.eligibleServers`'s own fix for the exact same
race, just for a single group's fetch instead of the whole listing. A genuine
failure (the fetch _did_ reach a connected server, and it came back an error
-- not found, no access, ...) still lands in `ExpandFailed` as before, via
`GotGroupMessages`'s own `Err` branch -- that one isn't auto-retried (`Poll`'s
`retryPendingExpansions` deliberately skips it), but a user re-clicking the
same row's chevron (`ToggleExpand` -> `expand`) fires this again rather than
just re-showing the stale "Couldn't load this messaging group." message.
-}
fetchExpand : AccountsPanel.Model -> Model -> MessagingGroupRef -> ( Model, Cmd Msg )
fetchExpand accountsPanelModel model ref =
    let
        existingMessages : Dict String Message
        existingMessages =
            Dict.get ref.key model.expandedGroups |> Maybe.map .messages |> Maybe.withDefault Dict.empty

        cmd : Cmd Msg
        cmd =
            case AccountsPanel.knownConnectedServer accountsPanelModel.servers ref.host of
                Nothing ->
                    Cmd.none

                Just _ ->
                    let
                        feed : Maybe ServerFeed
                        feed =
                            Dict.get ref.host model.messagesByServer

                        accountUserId : Maybe String
                        accountUserId =
                            feed |> Maybe.andThen .accountId

                        listingType : MessageListingType
                        listingType =
                            feed |> Maybe.map .listingType |> Maybe.withDefault PERSONALMESSAGES

                        accountServer : AccountsPanel.MaybeAccountServer
                        accountServer =
                            ( accountUserId, ref.host )

                        fetchTask : Task.Task Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetMessagesResponse )
                        fetchTask =
                            case ref.kind of
                                Messages.MessagingGroup ->
                                    Messages.fetchMessagingGroup accountsPanelModel accountServer listingType ref.groupId

                                Messages.FromEmail ->
                                    Messages.fetchFromEmail accountsPanelModel accountServer listingType ref.groupId

                                Messages.SoloMessage ->
                                    Messages.fetchMessage accountsPanelModel accountServer listingType ref.groupId
                    in
                    fetchTask
                        |> Task.attempt (GotGroupMessages ref.key)
    in
    ( { model
        | expandedGroups =
            Dict.insert ref.key
                { status = ExpandLoading, messages = existingMessages, host = ref.host, groupId = ref.groupId, kind = ref.kind }
                model.expandedGroups
      }
    , cmd
    )


{-| Retries every `ExpandLoading` entry in `expandedGroups` -- called from
`Poll` (both the 30s timer and, via `Pages.Messages`' own `SharedMsg`
handling of `Shared.AccountsPanelMsg`, right after a server actually
connects), so a group whose first `fetchExpand` attempt was skipped because
its server wasn't a `knownConnectedServer` yet (see that function's own doc)
gets a real attempt as soon as one exists, rather than sitting in
"Loading messages…" forever. Deliberately doesn't touch `ExpandFailed`
entries -- those already got a real answer from a connected server, so
retrying them on a timer would just be repeatedly re-asking about a group
that's genuinely not found/accessible.
-}
retryPendingExpansions : AccountsPanel.Model -> Model -> ( Model, Cmd Msg )
retryPendingExpansions accountsPanelModel model =
    let
        pending : List MessagingGroupRef
        pending =
            model.expandedGroups
                |> Dict.toList
                |> List.filterMap
                    (\( key, eg ) ->
                        if eg.status == ExpandLoading then
                            Just { key = key, host = eg.host, groupId = eg.groupId, kind = eg.kind }

                        else
                            Nothing
                    )
    in
    List.foldl
        (\ref ( accModel, cmds ) ->
            let
                ( newModel, cmd ) =
                    fetchExpand accountsPanelModel accModel ref
            in
            ( newModel, cmd :: cmds )
        )
        ( model, [] )
        pending
        |> Tuple.mapSecond Cmd.batch


{-| The two-pane detail pane's own `.messages-thread-list` -- see
`messageThreadView`'s own doc on why this needs a stable id at all (only its
copy is ever `scrollToPendingMessageCmd`'s target). Shared as one constant
between `messageThreadView` (which sets the id) and `scrollToPendingMessageCmd`
(which targets it), rather than each hand-typing the same string, so they
can't quietly drift apart.
-}
messagesDetailThreadListId : String
messagesDetailThreadListId =
    "messages-detail-thread-list"


{-| Once a group's thread finishes loading, scrolls `pendingScrollMessageId`
(from the initial `#message-<id>` fragment, see `Pages.Messages.init`) into
view if it's actually present in what just loaded -- a one-shot attempt;
`ScrollAttempted` always clears it afterward (success or failure) so a
missing/not-yet-loaded target doesn't keep retrying every render.

Scrolls `messagesDetailThreadListId` itself (via `Dom.setViewportOf`), not
the page (`Dom.setViewport`) -- the two-pane pane bounds itself to the
viewport and scrolls its own message list internally now (see
messages.css's own doc on `.messages-thread`), so the page usually has
nothing left to scroll at all; targeting it would silently do nothing.
Centers the target vertically within that pane rather than pinning it near
the top, and animates there smoothly rather than jumping -- both purely a
CSS concern (`scroll-behavior: smooth` on `.messages-thread .messages-thread-list`,
messages.css), not something this `Task` has to orchestrate itself, since a
plain `setViewportOf` already respects it.

The offset math: `container`/`target` (both `Dom.getElement`, so both
measured in the same _current-viewport-relative_ coordinate space, per
`Browser.Dom.getElement`'s own doc) gives `target.element.y - container.element.y`,
`target`'s position relative to the container's own _visible_ top edge right
now -- adding that to `containerViewport.viewport.y` (the container's own
_current_ scroll offset, from `Dom.getViewportOf`) converts it into a
position within the container's full scrollable content, independent of
however it's scrolled at the moment this runs. Subtracting half the
container's height and adding half the target's own centers it; `setViewportOf`
clamps the result into range on its own (see its own doc), so an
over/undershoot at either end of the thread is harmless.

-}
scrollToPendingMessageCmd : Model -> Cmd Msg
scrollToPendingMessageCmd model =
    case model.pendingScrollMessageId of
        Nothing ->
            Cmd.none

        Just messageId ->
            let
                isPresent : Bool
                isPresent =
                    model.expandedGroups
                        |> Dict.values
                        |> List.any (\eg -> Dict.member messageId eg.messages)
            in
            if isPresent then
                Task.map3 (\containerViewport container target -> ( containerViewport, container, target ))
                    (Dom.getViewportOf messagesDetailThreadListId)
                    (Dom.getElement messagesDetailThreadListId)
                    (Dom.getElement (messageDomId messageId))
                    |> Task.andThen
                        (\( containerViewport, container, target ) ->
                            let
                                newScrollTop : Float
                                newScrollTop =
                                    containerViewport.viewport.y
                                        + (target.element.y - container.element.y)
                                        - (container.element.height / 2)
                                        + (target.element.height / 2)
                            in
                            Dom.setViewportOf messagesDetailThreadListId containerViewport.viewport.x newScrollTop
                        )
                    |> Task.attempt (\_ -> ScrollAttempted)

            else
                Cmd.none


{-| Optimistically marks `message` read (a synthetic `defaultMessageRead`,
just enough for `Components.Messages.isUnread`/`messageRowView`'s own
`currentUserRead == Nothing` checks to flip -- its exact contents are never
read back out) if its id is in `readIds` -- see `GotGroupMessages`'s own doc
on why this doesn't wait for `markMessageRead`'s round trip.
-}
patchMessageRead : Set String -> Message -> Message
patchMessageRead readIds message =
    if Set.member message.id readIds then
        { message | currentUserRead = Just { defaultMessageRead | messageId = message.id } }

    else
        message


{-| `patchMessageRead`, applied across a whole `ServerFeed`'s own `Loaded`
messages -- a no-op (returns `feed` as-is) for any other `ServerMessages`
status, or for a message id `readIds` doesn't mention.
-}
patchServerFeedRead : Set String -> ServerFeed -> ServerFeed
patchServerFeedRead readIds feed =
    case feed.status of
        Loaded messages ->
            { feed | status = Loaded (List.map (patchMessageRead readIds) messages) }

        _ ->
            feed


{-| `patchMessageRead`'s inverse -- optimistically clears `message.currentUserRead`
back to `Nothing` if its id is in `unreadIds`, for `MarkUnreadClicked`'s own
"Mark unread" button.
-}
patchMessageUnread : Set String -> Message -> Message
patchMessageUnread unreadIds message =
    if Set.member message.id unreadIds then
        { message | currentUserRead = Nothing }

    else
        message


{-| `patchMessageUnread`, applied across a whole `ServerFeed`'s own `Loaded`
messages -- mirrors `patchServerFeedRead`.
-}
patchServerFeedUnread : Set String -> ServerFeed -> ServerFeed
patchServerFeedUnread unreadIds feed =
    case feed.status of
        Loaded messages ->
            { feed | status = Loaded (List.map (patchMessageUnread unreadIds) messages) }

        _ ->
            feed


{-| Every currently-known `GroupSummary.unreadCount`, summed -- what
`Shared.MessagingPanel`/`UI.messagingToggle` badge with a number, mirroring
`Shared.StarredPanel`'s own `Set.size starredPostIds` badge. Unlike that one,
though, this can only ever reflect what's _already been fetched_ into this
`Model` -- there's no local, always-available record of "how many unread
messages do I have" the way starring's own locally-persisted `starredPostIds`
is (see that module's own `init`, which reads it straight out of `flags` at
boot, no RPC needed) -- so a freshly-opened `Shared.MessagingPanel` that
hasn't fetched anything yet (`empty`, see its own doc) reads `0` here until
its first `Poll`/`ToggleOpen` fetch resolves, same as every other count this
module surfaces.
-}
totalUnreadCount : Model -> Int
totalUnreadCount model =
    currentGroupSummaries model
        |> Dict.values
        |> List.map .unreadCount
        |> List.sum


eligibleEntries : AccountsPanel.Model -> List { server : AccountsPanel.Server, account : AccountsPanel.Account, listingType : MessageListingType }
eligibleEntries =
    Messages.eligibleServers


refetchServers :
    AccountsPanel.Model
    -> Model
    -> List { server : AccountsPanel.Server, account : AccountsPanel.Account, listingType : MessageListingType }
    -> ( Model, Cmd Msg )
refetchServers accountsPanelModel model entriesToFetch =
    let
        entries : List { server : AccountsPanel.Server, account : AccountsPanel.Account, listingType : MessageListingType }
        entries =
            eligibleEntries accountsPanelModel

        fetchCmd : { server : AccountsPanel.Server, account : AccountsPanel.Account, listingType : MessageListingType } -> Cmd Msg
        fetchCmd entry =
            Messages.fetchMessageListing accountsPanelModel ( Just entry.account.userId, entry.server.frontendHost ) entry.listingType model.searchText
                |> Task.attempt (GotServerMessages entry.server.frontendHost)

        prunedMessagesByServer : Dict String ServerFeed
        prunedMessagesByServer =
            Dict.filter (\host _ -> List.member host (List.map (.server >> .frontendHost) entries)) model.messagesByServer

        markEntry : { server : AccountsPanel.Server, account : AccountsPanel.Account, listingType : MessageListingType } -> Dict String ServerFeed -> Dict String ServerFeed
        markEntry entry dict =
            let
                statusIfSame : Maybe ServerMessages
                statusIfSame =
                    Dict.get entry.server.frontendHost dict
                        |> Maybe.andThen
                            (\feed ->
                                if feed.accountId == Just entry.account.userId && feed.listingType == entry.listingType then
                                    Just feed.status

                                else
                                    Nothing
                            )
            in
            Dict.insert entry.server.frontendHost
                { status = Maybe.withDefault Loading statusIfSame, accountId = Just entry.account.userId, listingType = entry.listingType }
                dict
    in
    ( { model | messagesByServer = List.foldl markEntry prunedMessagesByServer entries }
    , Cmd.batch (List.map fetchCmd entriesToFetch)
    )
        |> Tuple.mapFirst syncSidebarAnimations


fetchNewServers : AccountsPanel.Model -> Model -> ( Model, Cmd Msg )
fetchNewServers accountsPanelModel model =
    let
        entriesToFetch : List { server : AccountsPanel.Server, account : AccountsPanel.Account, listingType : MessageListingType }
        entriesToFetch =
            eligibleEntries accountsPanelModel
                |> List.filter
                    (\entry ->
                        case Dict.get entry.server.frontendHost model.messagesByServer of
                            Nothing ->
                                True

                            Just feed ->
                                feed.accountId /= Just entry.account.userId || feed.listingType /= entry.listingType
                    )
    in
    refetchServers accountsPanelModel model entriesToFetch


applySearchChange : AccountsPanel.Model -> Model -> ( Model, Cmd Msg )
applySearchChange accountsPanelModel model =
    let
        ( refetchedModel, refetchCmd ) =
            refetchServers accountsPanelModel model (eligibleEntries accountsPanelModel)
    in
    ( refetchedModel, Cmd.batch [ refetchCmd, replaceQueryUrl accountsPanelModel refetchedModel ] )


{-| Whether `model.searchText` (trimmed) is non-empty -- shared by `view`/
`searchRowView` (search active forces the two-pane mobile sidebar open and
disables its hamburger toggle, since hiding it would hide the search
results) and `groupRowView` (search active forces every row's inline-expand
open, see that call site's own doc).
-}
isSearchActive : Model -> Bool
isSearchActive model =
    not (String.isEmpty (String.trim model.searchText))


{-| The query param(s) identifying `ref` -- `?messaging_group=`/`?message=`
(via `Messages.groupRouteId`'s shared `id`-or-`id@host` encoding, see its own
doc) for the two opaque-id kinds, or `?from_email=` (plus `&from_email_host=`
if `ref.host` isn't `mainFrontendHost`) for `FromEmail`: an email address
already contains its own `@`, so it can't reuse `groupRouteId`'s federation
suffix without an ambiguous double-`@` string, hence the separate param.
Generic over any record with `MessagingGroupRef`'s `host`/`groupId`/`kind` fields, so
this covers both `MessagingGroupRef` itself and `MessageLinkTarget`'s inline
`ExternalLink` permalinks (see `messageInteractionFor`) without needing an
intermediate `MessagingGroupRef` built just to call this.
-}
groupQueryParams : String -> { r | host : String, groupId : String, kind : Messages.MessagingGroupKind } -> List Url.Builder.QueryParameter
groupQueryParams mainFrontendHost ref =
    case ref.kind of
        Messages.MessagingGroup ->
            [ Url.Builder.string "messaging_group" (Messages.groupRouteId mainFrontendHost ref.host ref.groupId) ]

        Messages.SoloMessage ->
            [ Url.Builder.string "message" (Messages.groupRouteId mainFrontendHost ref.host ref.groupId) ]

        Messages.FromEmail ->
            Url.Builder.string "from_email" ref.groupId
                :: (if ref.host == mainFrontendHost then
                        []

                    else
                        [ Url.Builder.string "from_email_host" ref.host ]
                   )


{-| `?search_text=`/`?messaging_group=`/`?from_email=`/`?message=` together,
reflecting `model`'s current state -- shared by `applySearchChange` (via
`replaceUrl`, so per-keystroke debounce ticks don't spam history) and
`GroupSelected` (via `pushUrl`, a real navigational choice) so neither ever
clobbers the other's half of the query string.
-}
queryString : AccountsPanel.Model -> Model -> String
queryString accountsPanelModel model =
    let
        searchParam : List Url.Builder.QueryParameter
        searchParam =
            if String.isEmpty (String.trim model.searchText) then
                []

            else
                [ Url.Builder.string "search_text" model.searchText ]

        groupParam : List Url.Builder.QueryParameter
        groupParam =
            model.selectedGroup
                |> Maybe.map (groupQueryParams accountsPanelModel.mainFrontendHost)
                |> Maybe.withDefault []
    in
    Url.Builder.toQuery (searchParam ++ groupParam)


replaceQueryUrl : AccountsPanel.Model -> Model -> Cmd Msg
replaceQueryUrl accountsPanelModel model =
    case model.pageContext of
        Nothing ->
            Cmd.none

        Just ctx ->
            Browser.Navigation.replaceUrl ctx.navKey (ctx.path ++ queryString accountsPanelModel model)



-- ANIMATION


{-| Every currently-fetched group's own summary, freshly derived from
`messagesByServer` -- the single source of truth `flattenSidebar`/
`totalUnreadCount`/`mostRecentMessageIdFor`/`expand` all read, replacing the
old standalone `groupAnimations` cache now that its own `flip` state lives in
`sidebarAnimations` instead (see that field's own doc).
-}
currentGroupSummaries : Model -> Dict String Messages.GroupSummary
currentGroupSummaries model =
    model.messagesByServer
        |> Dict.toList
        |> List.concatMap
            (\( host, feed ) ->
                case feed.status of
                    Loaded messages ->
                        Messages.groupMessages host messages |> List.map (\group -> ( group.key, group ))

                    _ ->
                        []
            )
        |> Dict.fromList


{-| A group row's own sort key -- primary component shared with every one of
its own message rows (`messageSortKey`), so a whole group's block (its row
plus, if inline-open, its messages) always sorts as one contiguous unit,
newest group first. The secondary component just needs to sort _before_ any
of that same group's own messages (see `messageSortKey`) -- one less than the
group's own (negated) timestamp always does that, since no message's
timestamp exceeds its group's `mostRecent`.
-}
groupSortKey : Messages.GroupSummary -> ( Int, Int )
groupSortKey summary =
    let
        t : Int
        t =
            negate (Messages.messageMillis summary.mostRecent)
    in
    ( t, t - 1 )


messageSortKey : Messages.GroupSummary -> Message -> ( Int, Int )
messageSortKey summary message =
    ( negate (Messages.messageMillis summary.mostRecent), negate (Messages.messageMillis message) )


{-| `summary`'s own message rows for `flattenSidebar`, in no particular order
(their `sortKey` is what actually places them) -- `[]` whenever there's
nothing to splice in: search mode has its own separate, non-animated
rendering (`searchResultThreadView`, still nested under the group's own row),
the group isn't inline-open at all, or its fetch hasn't resolved to
`ExpandLoaded` yet (a `Loading`/`Failed` placeholder, also still nested under
the row rather than a flat entry of its own -- see `groupRowView`).
-}
groupMessageRows : Model -> Messages.GroupSummary -> List ( String, { row : SidebarRow, sortKey : ( Int, Int ) } )
groupMessageRows model summary =
    if isSearchActive model || not (Set.member summary.key model.inlineOpenGroups) then
        []

    else
        case Dict.get summary.key model.expandedGroups of
            Just eg ->
                if eg.status == ExpandLoaded then
                    let
                        ref : MessagingGroupRef
                        ref =
                            { key = summary.key, host = summary.host, groupId = summary.groupId, kind = summary.kind }
                    in
                    eg.messages
                        |> Dict.values
                        |> List.map
                            (\message ->
                                ( "message:" ++ message.id
                                , { row = SidebarMessageRow ref message, sortKey = messageSortKey summary message }
                                )
                            )

                else
                    []

            Nothing ->
                []


{-| Every entry `Model.sidebarAnimations` should currently show, in display
order (each with its own `sortKey`, not that a `Dict`'s own iteration order
means anything) -- see that field's own doc.
-}
flattenSidebar : Model -> List ( String, { row : SidebarRow, sortKey : ( Int, Int ) } )
flattenSidebar model =
    currentGroupSummaries model
        |> Dict.values
        |> List.concatMap
            (\summary ->
                ( "group:" ++ summary.key, { row = SidebarGroupRow summary, sortKey = groupSortKey summary } )
                    :: groupMessageRows model summary
            )


{-| Reconciles `Model.sidebarAnimations` against `flattenSidebar`'s current
list -- called after anything that can change either a group's own summary
(`messagesByServer`), which groups are inline-open (`ToggleExpand`), or an
inline-open group's own messages (`GotGroupMessages`, `MarkUnreadClicked`).
Starts a fade-in for a group/message row that just appeared, and a fade-out
(still rendered at its last known `sortKey`, per `UI.Flip.remove`'s own doc)
for one that dropped out -- collapsing a group's chevron is exactly the
latter for its own message rows, which is what gives that toggle its
animation for free.
-}
syncSidebarAnimations : Model -> Model
syncSidebarAnimations model =
    let
        current : Dict String { row : SidebarRow, sortKey : ( Int, Int ) }
        current =
            Dict.fromList (flattenSidebar model)
    in
    { model
        | sidebarAnimations =
            UI.Flip.syncAnimations
                RemoveSidebarRow
                (\entry -> { row = entry.row, sortKey = entry.sortKey, flip = UI.Flip.enter })
                (\entry anim -> { anim | row = entry.row, sortKey = entry.sortKey })
                current
                model.sidebarAnimations
    }


{-| Re-syncs `Model.detailThreadAnimations` (its own doc has the full "why")
against whichever messages `model.selectedGroup` currently means -- called
right after anything that can change either one: `GroupSelected` (a
different group's now selected) and `GotGroupMessages`' `Ok` branch (the
currently selected group's own fetch just resolved, e.g. its very first
load). `[]` whenever there's nothing to show yet (`selectedGroup == Nothing`,
or that group's `expandedGroups` entry isn't `ExpandLoaded` yet) -- every
message still in `detailThreadAnimations` from whatever was showing before
starts removing, same as switching to any other group, and there's nothing
new to sync in until a later call sees `ExpandLoaded` messages.
-}
syncDetailThreadAnimations : Model -> Model
syncDetailThreadAnimations model =
    let
        currentMessages : Dict String Message
        currentMessages =
            model.selectedGroup
                |> Maybe.andThen (\ref -> Dict.get ref.key model.expandedGroups)
                |> Maybe.andThen
                    (\eg ->
                        if eg.status == ExpandLoaded then
                            Just (Dict.values eg.messages)

                        else
                            Nothing
                    )
                |> Maybe.withDefault []
                |> List.map (\message -> ( message.id, message ))
                |> Dict.fromList
    in
    { model
        | detailThreadAnimations =
            UI.Flip.syncAnimations
                RemoveDetailMessage
                (\message -> { message = message, flip = UI.Flip.enter })
                (\message anim -> { anim | message = message })
                currentMessages
                model.detailThreadAnimations
    }


animateSidebarDict : Animation.Msg -> Dict String SidebarAnimation -> ( Dict String SidebarAnimation, List (Cmd Msg) )
animateSidebarDict animMsg animations =
    let
        step : String -> SidebarAnimation -> ( Dict String SidebarAnimation, List (Cmd Msg) ) -> ( Dict String SidebarAnimation, List (Cmd Msg) )
        step key anim ( acc, cmds ) =
            let
                ( newFlip, cmd ) =
                    UI.Flip.animate animMsg anim.flip
            in
            ( Dict.insert key { anim | flip = newFlip } acc, cmd :: cmds )
    in
    Dict.foldl step ( Dict.empty, [] ) animations


{-| `animateSidebarDict`'s own twin for `Model.detailThreadAnimations` --
identical shape (`Dict String { r | flip : State msg }`), just not worth
genericizing over given the two dicts hold otherwise-unrelated data.
-}
animateMessageDict : Animation.Msg -> Dict String MessageAnimation -> ( Dict String MessageAnimation, List (Cmd Msg) )
animateMessageDict animMsg animations =
    let
        step : String -> MessageAnimation -> ( Dict String MessageAnimation, List (Cmd Msg) ) -> ( Dict String MessageAnimation, List (Cmd Msg) )
        step key anim ( acc, cmds ) =
            let
                ( newFlip, cmd ) =
                    UI.Flip.animate animMsg anim.flip
            in
            ( Dict.insert key { anim | flip = newFlip } acc, cmd :: cmds )
    in
    Dict.foldl step ( Dict.empty, [] ) animations



-- VIEW


{-| `.messages-page` breaks out of `UI.layout`'s usual 800px-capped
`.container` to use the full page width instead (see messages.css's own
`margin-left`/`margin-right` trick, mirrored from `Components.Pages.EventsPage`'s
grid/strip views -- the only other place in this codebase doing this).

In two-pane mode, `.messages-sidebar` is a normal, always-visible column
alongside `.messages-detail` at any reasonable width -- but on a narrow
(< 640px) screen, messages.css turns it into a fixed-position overlay instead
(there's no room for two columns), toggled by `searchRowView`'s hamburger
button (`ToggleMobileSidebar`) rather than shown outright. `SearchTextChanged`
also forces it open (see that branch's own doc) -- typing a search is what
the overlay's contents are for, so it shouldn't stay hidden through that --
but it's still just the plain `mobileSidebarOpen` flag here, freely toggled
shut again afterward like any other manual open. `openClosedClass`'s result
only actually matters at that width; wider viewports override it back to
always-visible in CSS. The drawer itself never covers the full width
(messages.css's own doc on why), so `.messages-detail`'s own `onClick`
(`CloseMobileSidebar`) is what lets tapping the sliver of the selected
conversation still peeking out beside it dismiss the drawer too, the same
"tap outside to close" gesture the hamburger's own toggle offers explicitly.

-}
view : SharedTime.Model -> AccountsPanel.Model -> Model -> Html Msg
view time accountsPanelModel model =
    div [ class "messages-page" ]
        [ searchRowView accountsPanelModel model
        , case model.selectedGroup of
            Nothing ->
                groupsListView time accountsPanelModel model

            Just selected ->
                div [ class "messages-two-pane" ]
                    [ div [ classes [ "messages-sidebar", openClosedClass model.mobileSidebarOpen ] ] [ groupsListView time accountsPanelModel model ]
                    , div [ class "messages-detail", onClick CloseMobileSidebar ] [ selectedGroupView time accountsPanelModel model selected ]
                    ]
        ]


{-| The header row -- hamburger (two-pane, narrow screens only), search
field, and (real page only, see below) the "Compose" button. `class
"messages-header-row"` alongside the shared `"filter-controls-row"` layout
(`ui/filter_bar.css`) is what messages.css hooks its own sticky positioning
onto, without touching that shared class's own rule (which every other
`*Page.searchRowView` -- `PostsPage`, `EventsPage`, `UsersPage` -- also
uses, none of which want to go sticky).
-}
searchRowView : AccountsPanel.Model -> Model -> Html Msg
searchRowView accountsPanelModel model =
    div [ classes [ "filter-controls-row", "messages-header-row" ] ]
        [ if model.selectedGroup == Nothing then
            text ""

          else
            button
                [ Html.Attributes.type_ "button"
                , class "messages-mobile-sidebar-toggle"
                , onClick ToggleMobileSidebar
                , title
                    (if model.mobileSidebarOpen then
                        "Hide conversations"

                     else
                        "Show conversations"
                    )
                ]
                [ text "☰" ]
        , div [ class "filter-search-field" ]
            [ Html.input
                [ Html.Attributes.type_ "text"
                , class "filter-search-input"
                , Html.Attributes.placeholder "Search messages..."
                , Html.Attributes.value model.searchText
                , onInput SearchTextChanged
                , onEscape ClearSearchClicked
                ]
                []
            , if String.isEmpty model.searchText then
                text ""

              else
                button
                    [ Html.Attributes.type_ "button"
                    , class "field-clear-button"
                    , onClick ClearSearchClicked
                    , title "Clear search"
                    ]
                    [ text "╳" ]
            ]
        , if model.embeddedPanel then
            div [ class "filter-controls-trailing" ]
                [ Html.a [ class "panel-icon-button", href "/messages", title "Open Messages" ] [ text "⛶" ] ]

          else
            composeButtonView accountsPanelModel
        ]


{-| The real page's own "Compose" button, trailing the search field in
`searchRowView` (`filter-controls-trailing`) -- moved down from its old spot
as a standalone heading row above the search box (`Pages.Messages`' own
former `sendMessageButton`), so the whole header reads as one row. Hidden
entirely with nobody signed in anywhere, same as that old button -- there's
no point offering a button that can only ever fail. `ComposeClicked` is a
pure signal; `Pages.Messages` is what actually opens the Markdown panel
(this module can't depend on `Shared`/`MarkdownPanel` itself), using the
same first-enabled-account "sending as" default -- see that constructor's
own doc.
-}
composeButtonView : AccountsPanel.Model -> Html Msg
composeButtonView accountsPanelModel =
    case AccountsPanel.enabledAccounts accountsPanelModel of
        [] ->
            text ""

        firstAccount :: _ ->
            div [ class "filter-controls-trailing" ]
                [ button
                    [ Html.Attributes.type_ "button"
                    , Html.Attributes.classList
                        [ ( "messages-send-button", True )
                        , ( hostnameToCSSClass firstAccount.server, True )
                        , ( "background-color-primary", True )
                        ]
                    , onClick ComposeClicked
                    ]
                    [ text "Compose" ]
                ]


onEscape : msg -> Html.Attribute msg
onEscape msg =
    preventDefaultOn "keydown"
        (Decode.field "key" Decode.string
            |> Decode.andThen
                (\key ->
                    if key == "Escape" then
                        Decode.succeed ( msg, True )

                    else
                        Decode.fail "Not the Escape key"
                )
        )


groupsListView : SharedTime.Model -> AccountsPanel.Model -> Model -> Html Msg
groupsListView time accountsPanelModel model =
    if Dict.isEmpty model.messagesByServer then
        p [ class "posts-empty" ] [ text "Sign in with permission to read messages to see them here." ]

    else
        let
            sortedAnimations : List ( String, SidebarAnimation )
            sortedAnimations =
                model.sidebarAnimations
                    |> Dict.toList
                    |> List.sortBy (\( _, anim ) -> anim.sortKey)
        in
        if List.isEmpty sortedAnimations then
            p [ class "posts-empty" ] [ text "No messages yet." ]

        else
            Html.Keyed.node "div"
                [ class "messages-group-list flip-animated-column" ]
                (List.map (sidebarRowView time accountsPanelModel model) sortedAnimations)


{-| One `Model.sidebarAnimations` entry -- either a group's own row
(`groupRowView`) or one of its messages (`messageRowView`, same rendering the
two-pane detail's own rows use, just without a `message-<id>` dom id -- see
`messageAnimationView`'s own doc on why that id is detail-pane-only). Every
entry, whichever kind, gets the exact same `UI.Flip.itemAttributes` treatment
as any other FLIP list in this file, which is what makes a group's message
rows entering/leaving (as its chevron toggles) slide the rest of this shared
list smoothly, same as a group itself appearing/disappearing already did.
-}
sidebarRowView : SharedTime.Model -> AccountsPanel.Model -> Model -> ( String, SidebarAnimation ) -> ( String, Html Msg )
sidebarRowView time accountsPanelModel model ( key, anim ) =
    let
        pointerEventsAttr : List (Html.Attribute Msg)
        pointerEventsAttr =
            if anim.flip.removing then
                [ Html.Attributes.style "pointer-events" "none" ]

            else
                []

        content : Html Msg
        content =
            case anim.row of
                SidebarGroupRow summary ->
                    groupRowView time accountsPanelModel model summary

                SidebarMessageRow ref message ->
                    div [ class "messages-sidebar-message-row" ]
                        [ messageRowView time accountsPanelModel ref.host (messageInteractionFor accountsPanelModel model ref) model.highlightMessageId message ]
    in
    ( key
    , div (UI.Flip.itemAttributes UI.Flip.Vertical anim.flip False)
        [ div pointerEventsAttr [ content ] ]
    )


groupRowView : SharedTime.Model -> AccountsPanel.Model -> Model -> Messages.GroupSummary -> Html Msg
groupRowView time accountsPanelModel model summary =
    let
        isSelected : Bool
        isSelected =
            model.selectedGroup |> Maybe.map .key |> (==) (Just summary.key)

        rowClasses : List String
        rowClasses =
            "messages-group-row"
                :: (if isSelected then
                        [ "selected", "border-color-primary", hostnameToCSSClass summary.host ]

                    else
                        []
                   )

        ( messageCount, messageCountComplete ) =
            groupMessageCount model summary

        content : List (Html Msg)
        content =
            [ div [ class "messages-group-row-body" ]
                [ div [ class "messages-group-badges" ]
                    [ messageCountBadgeView messageCount messageCountComplete
                    , unreadBadgeView summary.host summary.unreadCount
                    ]
                , fromEmailView summary.kind summary.groupId
                , participantsView accountsPanelModel summary.host summary.members
                , span [ classes [ "messages-group-time", hostnameToCSSClass summary.host ] ]
                    [ hostLabelView accountsPanelModel.mainFrontendHost summary.host
                    , text (SharedTime.formatMoment time (Messages.messageMillis summary.mostRecent |> Time.millisToPosix))
                    ]
                ]
            ]

        -- A search in progress puts every group's inline-expand into a
        -- different, read-only mode -- see `searchResultThreadView`'s own
        -- doc -- rather than the usual per-group manual toggle, so there's
        -- no "collapse" to offer (`expandChevron`, below) and every row
        -- counts as open regardless of `inlineOpenGroups`' own (untouched)
        -- membership, which simply resumes governing things once the
        -- search is cleared.
        isInlineOpen : Bool
        isInlineOpen =
            isSearchActive model || Set.member summary.key model.inlineOpenGroups

        -- Always shown, on *every* row -- including whichever one is
        -- `selectedGroup` (see `inlineOpenGroups`' own doc on `Model` for
        -- why that no longer conflicts with the two-pane detail pane) --
        -- *unless* a search is active (see `isSearchActive`'s own doc):
        -- there's nothing left to toggle then, every row's inline-expand is
        -- driven by the search instead.
        -- `Html.Events.custom` (not `stopPropagationOn`, what this used
        -- before) sets *both* `stopPropagation` (so the row's own
        -- `onClick`/`href` doesn't also fire, same as before) *and*
        -- `preventDefault` -- needed for `model.embeddedPanel`'s rows,
        -- which are real `<a href>` elements: without it, the browser's
        -- own default action for a click landing anywhere inside an anchor
        -- (a descendant button included) still navigates regardless of
        -- `stopPropagation`, which only ever stops the event from reaching
        -- *other JS listeners*, not the anchor's own native default action.
        expandChevron : Html Msg
        expandChevron =
            if isSearchActive model then
                text ""

            else
                button
                    [ class "messages-group-expand-toggle"
                    , Html.Events.custom "click" (Decode.succeed { message = ToggleExpand summary, stopPropagation = True, preventDefault = True })
                    , title
                        (if isInlineOpen then
                            "Collapse"

                         else
                            "Expand"
                        )
                    ]
                    [ text
                        (if isInlineOpen then
                            "▾"

                         else
                            "▸"
                        )
                    ]
    in
    div [ class "messages-group" ]
        [ if model.embeddedPanel then
            Html.a
                [ classes rowClasses
                , href
                    ("/messages"
                        ++ Url.Builder.toQuery (groupQueryParams accountsPanelModel.mainFrontendHost summary)
                        -- Lands the real page's two-pane detail already
                        -- scrolled to the group's newest message -- see
                        -- `GroupSelected`'s own doc on why (the same
                        -- `#message-<id>` fragment `SyncSelectedGroup`
                        -- applies for this exact click, when this page is
                        -- already mounted underneath the panel).
                        ++ "#"
                        ++ messageDomId summary.mostRecent.id
                    )
                , onClick (EmbeddedGroupLinkClicked { key = summary.key, host = summary.host, groupId = summary.groupId, kind = summary.kind })
                ]
                (expandChevron :: content)

          else
            div
                [ classes rowClasses
                , onClick (GroupSelected { key = summary.key, host = summary.host, groupId = summary.groupId, kind = summary.kind })
                ]
                (expandChevron :: content)
        , if isSearchActive model then
            searchResultThreadView time accountsPanelModel model summary

          else if isInlineOpen then
            inlineStatusView model summary

          else
            text ""
        ]


{-| One participant's avatar + name, for `participantsView` -- mirrors
`Components.Pages.UserProfilePage`'s "Federated Profiles" chip
(`profile-federated-link`/`-avatar`/`-names`), just built from an `Author`
(what a `MessagingGroup`'s `members` -- and a `Message`'s own `sender` --
already carry) instead of a `User`.
-}
participantChipView : AccountsPanel.Model -> String -> Author -> Html msg
participantChipView accountsPanelModel host author =
    let
        name : String
        name =
            Authors.name (Just author)

        maybeUrl : Maybe String
        maybeUrl =
            Authors.avatarUrl
                (AccountsPanel.serverForHost accountsPanelModel.servers host)
                (AccountsPanel.enabledAccountForServer accountsPanelModel.accounts host)
                (Just author)
    in
    span [ class "messages-participant-chip" ]
        [ avatarView "messages-participant-avatar" name maybeUrl
        , span [ class "messages-participant-name" ] [ text name ]
        ]


{-| All of a group's members, each as `participantChipView` -- what a group
card (`groupRowView`) shows in place of any subject/snippet, and what the
two-pane detail view (`selectedGroupView`) shows at the top in place of the
old subject heading -- see both their own docs for why. Always excludes
whoever's actually signed in on `host` (`visibleParticipants`, below) -- no
point naming yourself among your own conversation's recipients.
-}
participantsView : AccountsPanel.Model -> String -> List Author -> Html msg
participantsView accountsPanelModel host members =
    div [ class "messages-participants" ] (List.map (participantChipView accountsPanelModel host) (visibleParticipants accountsPanelModel host members))


{-| The raw sender address for a `FromEmail`-kind group (`groupId` is that
`Message.from` value verbatim, see `Components.Messages.MessagingGroupKind`'s own
doc) -- shown _alongside_ `participantsView`'s own member chips, not instead
of them, since a `FromEmail` group's `members` (any locally-resolvable
`Message.sender`) is still worth showing when present. `text ""` for every
other kind, so this is a no-op to include unconditionally at every
`participantsView` call site. Deliberately plain text, not a chip styled
like a real participant -- see `selectedGroupView`'s own `messages-thread-header`
spoofable-address warning for why a `from` address shouldn't visually read as
a verified identity.
-}
fromEmailView : Messages.MessagingGroupKind -> String -> Html msg
fromEmailView kind fromEmail =
    case kind of
        Messages.FromEmail ->
            div [ class "messages-from-email" ] [ text fromEmail ]

        _ ->
            text ""


{-| `members`, minus whoever's actually signed in on `host` -- unless that
would leave nothing to show at all, which only happens for a group that's
_only_ that one signed-in user (a self-note solo group, or a real
`MessagingGroup` with no other members left in it) -- showing yourself as
your own sole participant there is more useful than showing an empty card.
Mirrors `replyButtonView`'s own, separate self-exclusion for `ReplyClicked`'s
recipients (that one has no such fallback -- an empty recipients list is a
perfectly valid "reply to yourself" there).
-}
visibleParticipants : AccountsPanel.Model -> String -> List Author -> List Author
visibleParticipants accountsPanelModel host members =
    case AccountsPanel.enabledAccountForServer accountsPanelModel.accounts host of
        Nothing ->
            members

        Just account ->
            let
                withoutSelf : List Author
                withoutSelf =
                    List.filter (\author -> author.userId /= account.userId) members
            in
            if List.isEmpty withoutSelf then
                members

            else
                withoutSelf


{-| `summary.messageCount` (a floor, not a total -- see that field's own doc)
paired with whether it's actually the group's true total: `True` once its
full thread has separately been fetched (`expand`), reading straight off
that fetch's own `messages` count rather than the outer listing's; `False`
(still just the floor) otherwise, whatever the group's own
`inlineOpenGroups`/`selectedGroup` status -- a chevron that's merely been
clicked open, with the fetch still `ExpandLoading`/`ExpandFailed`, doesn't
actually know the true count yet either.
-}
groupMessageCount : Model -> Messages.GroupSummary -> ( Int, Bool )
groupMessageCount model summary =
    case Dict.get summary.key model.expandedGroups of
        Just eg ->
            if eg.status == ExpandLoaded then
                ( Dict.size eg.messages, True )

            else
                ( summary.messageCount, False )

        Nothing ->
            ( summary.messageCount, False )


{-| A group card's own message count, to the left of `unreadBadgeView` --
hidden at `count <= 1` (a single message is already fully represented by the
row's own timestamp/snippet, nothing a count would add). `isComplete`
(`groupMessageCount`) is what decides the trailing "+" -- appended whenever
`count` might just be how many of this group's messages happened to fall in
the outer listing's own recency window, not the group's true total, so the
badge reads as "2+" (at least two) rather than a flatly wrong "2" when
there's actually more. Shares `.messages-count-badge`'s own box geometry with
`unreadBadgeView`, but flat gray/white (`.messages-message-count-badge`,
messages.css) rather than host-branded -- this one's just a fact about the
thread, not an actionable "something's new here" signal the way the unread
count is.
-}
messageCountBadgeView : Int -> Bool -> Html msg
messageCountBadgeView count isComplete =
    if count <= 1 then
        text ""

    else
        span [ class "messages-count-badge messages-message-count-badge" ]
            [ text (String.fromInt count ++ ("+" |> withDefaultUnless isComplete)) ]


{-| `"+"` unless `isComplete`, in which case `""` -- a tiny helper just so
`messageCountBadgeView`'s own string-building reads left-to-right instead of
needing an `if/then/else` block for one conditional suffix.
-}
withDefaultUnless : Bool -> String -> String
withDefaultUnless isComplete suffix =
    if isComplete then
        ""

    else
        suffix


{-| `host`, prefixed to `.messages-group-time`'s own timestamp, whenever a
group isn't on `mainFrontendHost` -- e.g. a federated-in account's own
messages, otherwise indistinguishable from a `mainFrontendHost` group except
by the row's own (subtle, color-only) `hostnameToCSSClass` tinting. Hidden
entirely on `mainFrontendHost` itself, the common case, so most rows don't
carry the extra label at all.
-}
hostLabelView : String -> String -> Html msg
hostLabelView mainFrontendHost host =
    if host == mainFrontendHost then
        text ""

    else
        text (host ++ " · ")


{-| A group card's own unread-message count (`GroupSummary.unreadCount`) --
hidden entirely at `0`, same "only show chrome when there's something behind
it" reasoning as `UI.starredPostsToggle`'s own badge. Styled with `host`'s
own brand color (`background-color-nav`/`border-color-primary-text`, see
`UI.EmittedStylesheet`'s doc comment on those utility classes) rather than a
fixed color, since a group card's participants can be on any of several
eligible servers, not just `mainFrontendHost`.
-}
unreadBadgeView : String -> Int -> Html msg
unreadBadgeView host count =
    if count <= 0 then
        text ""

    else
        span [ classes [ "messages-count-badge", "messages-unread-badge", hostnameToCSSClass host, "background-color-nav", "border-color-primary-text" ] ]
            [ text (String.fromInt count) ]


{-| Duplicated (rather than reusing `UI.imageOrInitial`) since `UI` itself
imports `Shared.MessagingPanel`, which embeds this module -- importing `UI`
back here would cycle, same reasoning as `Components.UserPicker.avatarView`.
-}
avatarView : String -> String -> Maybe String -> Html msg
avatarView baseClass name maybeUrl =
    case maybeUrl of
        Just url ->
            Html.img [ class baseClass, Html.Attributes.src url, Html.Attributes.alt name, Html.Attributes.attribute "loading" "lazy" ] []

        Nothing ->
            div [ classes [ baseClass, "placeholder" ] ] [ text (AccountsPanel.initialLetter name) ]


{-| A message's own `subject`, if it has a non-blank one -- shown on the
individual message itself (`messageRowView`) only, never at the top of a
group's card or its two-pane detail view (`participantsView` covers those
instead, see its own doc) -- a `MessagingGroup` has members but no subject of
its own; only a `Message` does.
-}
messageSubjectView : Message -> Html msg
messageSubjectView message =
    case message.subject |> Maybe.map String.trim |> Maybe.andThen (\s -> ifNonEmpty s) of
        Just subject ->
            p [ class "message-row-subject" ] [ text subject ]

        Nothing ->
            text ""


ifNonEmpty : String -> Maybe String
ifNonEmpty s =
    if String.isEmpty s then
        Nothing

    else
        Just s


{-| What clicking a message row (`messageRowView`) actually does, per
context: embedded (`Shared.MessagingPanel`) rows have nowhere of their own to
show a message, so they're a real `<a href>` out to its `/messages`
permalink (`ExternalLink`), paired -- same trick `groupRowView`'s own
`EmbeddedGroupLinkClicked` `onClick` uses alongside its `href` -- with an
`EmbeddedMessageLinkClicked` pure signal, so that if `Pages.Messages` turns
out to be the page mounted underneath this exact panel, it syncs to that
message in place (`SyncSelectedMessage`) instead of just updating the URL bar
and stopping there (a same-path query/fragment-only change `Pages.Messages`'
own `init`/`update` would never otherwise notice). The real page's own
two-pane detail (`selectedGroupView`) is already showing the message, so its
own rows are plain, non-navigating content (`NoInteraction`). The real page's
_sidebar_ inline-expand (`groupRowView`'s chevron) is the one case with
somewhere to go that isn't a full page navigation -- clicking one of its rows
selects that message's group into the two-pane detail _and_ scrolls/highlights
that exact message there, same as landing on its `#message-<id>` permalink
directly (`SelectGroup`, see `MessageSelected`'s own doc). Deliberately
_not_ affected by whether some _other_ group is currently `selectedGroup` --
clicking a message is always a real choice, unlike merely toggling a row's
chevron open (`ToggleExpand`, `inlineOpenGroups`), which never touches
`selectedGroup` at all.
-}
type MessageInteraction
    = NoInteraction
    | ExternalLink MessageLinkTarget
    | SelectGroup MessagingGroupRef


type alias MessageLinkTarget =
    { mainFrontendHost : String, key : String, host : String, groupId : String, kind : Messages.MessagingGroupKind }


messageInteractionFor : AccountsPanel.Model -> Model -> { r | key : String, host : String, groupId : String, kind : Messages.MessagingGroupKind } -> MessageInteraction
messageInteractionFor accountsPanelModel model ref =
    if model.embeddedPanel then
        ExternalLink { mainFrontendHost = accountsPanelModel.mainFrontendHost, key = ref.key, host = ref.host, groupId = ref.groupId, kind = ref.kind }

    else
        SelectGroup { key = ref.key, host = ref.host, groupId = ref.groupId, kind = ref.kind }


{-| `groupRowView`'s own nested placeholder for an inline-open group whose
fetch hasn't resolved to `ExpandLoaded` yet -- once it does, that group's
messages render as their own flat `sidebarAnimations` entries instead (see
`groupMessageRows`), not here. `text ""` for `ExpandLoaded` (nothing left for
this placeholder to say) and for a group with no `expandedGroups` entry at
all (a chevron that's only just been clicked, `expand`'s own `Cmd` not
resolved into the model yet).
-}
inlineStatusView : Model -> Messages.GroupSummary -> Html msg
inlineStatusView model summary =
    case Dict.get summary.key model.expandedGroups |> Maybe.map .status of
        Just ExpandLoading ->
            p [ class "messages-thread-status" ] [ text "Loading messages…" ]

        Just ExpandFailed ->
            p [ class "messages-thread-status" ] [ text "Couldn't load this messaging group." ]

        _ ->
            text ""


{-| `groupRowView`'s own search-mode counterpart to `expandedGroupView` --
while a search is active, every group's inline-expand (see `isSearchActive`/
`isInlineOpen`, `groupRowView`'s own doc) shows _only_ the messages that
matched the search, sourced directly from the outer listing's own response
(`model.messagesByServer`, already the `*_TEXT_SEARCH` variant while
searching -- see `Messages.fetchMessageListing`) -- not a group's full
thread narrowed down client-side, and not a separate per-group fetch at all
(`model.expandedGroups`/`fetchMessagingGroup` are untouched by this). A
deliberately different, simpler data path from the normal manual-expand flow
-- see this function's own two callers in `groupRowView` for the full
before/after split.
-}
searchResultThreadView : SharedTime.Model -> AccountsPanel.Model -> Model -> Messages.GroupSummary -> Html Msg
searchResultThreadView time accountsPanelModel model summary =
    let
        sortedMessages : List Message
        sortedMessages =
            searchResultMessagesFor model summary
                |> List.sortBy (\message -> -(Messages.messageMillis message))

        interaction : MessageInteraction
        interaction =
            messageInteractionFor accountsPanelModel model summary
    in
    Html.Keyed.node "div"
        [ class "messages-thread-list flip-animated-column" ]
        (List.map
            (\message ->
                ( message.id
                , div (UI.Flip.itemAttributes UI.Flip.Vertical UI.Flip.restingState False)
                    [ div [] [ messageRowView time accountsPanelModel summary.host interaction model.highlightMessageId message ] ]
                )
            )
            sortedMessages
        )


{-| `summary`'s own slice of `model.messagesByServer[summary.host]`'s
already-fetched listing response -- see `searchResultThreadView`'s own doc.
Matches messages the same way `Components.Messages.groupMessages` grouped
them into `summary` in the first place: by `messagingGroup.id`, falling back
to the lone message's own id for a "solo" (Bcc-only) pseudo-group (see that
function's own doc).
-}
searchResultMessagesFor : Model -> Messages.GroupSummary -> List Message
searchResultMessagesFor model summary =
    case Dict.get summary.host model.messagesByServer |> Maybe.map .status of
        Just (Loaded messages) ->
            List.filter (messageBelongsToGroup summary.groupId) messages

        _ ->
            []


messageBelongsToGroup : String -> Message -> Bool
messageBelongsToGroup groupId message =
    case message.messagingGroup of
        Just group ->
            group.id == groupId

        Nothing ->
            message.id == groupId


{-| A thread's participants -- derived straight from the `messagingGroup` of
whichever loaded message has one (they all share the same group, so the
first is enough), _not_ from `currentGroupSummaries` -- this way it's just as
correct for a group reached only by a `?messaging_group=` permalink that
never appeared in the general listing at all (see `fetchExpand`'s own doc on
that case) as for one that did. Falls back to the loaded messages' own
senders for a "solo" (Bcc-only) group, whose lone message has no
`messagingGroup` of its own (see `Components.Messages.groupMessages`) to read
members from in the first place.
-}
threadParticipants : ExpandedGroup -> List Author
threadParticipants eg =
    let
        messages : List Message
        messages =
            Dict.values eg.messages

        fromGroup : List Author
        fromGroup =
            messages |> List.filterMap .messagingGroup |> List.head |> Maybe.map .members |> Maybe.withDefault []
    in
    if List.isEmpty fromGroup then
        messages |> List.filterMap .sender

    else
        fromGroup


selectedGroupView : SharedTime.Model -> AccountsPanel.Model -> Model -> MessagingGroupRef -> Html Msg
selectedGroupView time accountsPanelModel model selected =
    case Dict.get selected.key model.expandedGroups of
        Nothing ->
            p [ class "messages-thread-status" ] [ text "Loading messages…" ]

        Just eg ->
            case eg.status of
                ExpandLoading ->
                    p [ class "messages-thread-status" ] [ text "Loading messages…" ]

                ExpandFailed ->
                    p [ class "messages-thread-status" ] [ text "Messaging group not found." ]

                ExpandLoaded ->
                    div [ class "messages-thread" ]
                        [ div [ class "messages-thread-header" ]
                            [ div [ class "messages-thread-header-info" ]
                                (fromEmailView selected.kind eg.groupId
                                    :: participantsView accountsPanelModel selected.host (threadParticipants eg)
                                    :: spoofableEmailWarningView selected.kind
                                )
                            , replyButtonView accountsPanelModel selected eg
                            ]
                        , messageThreadView time accountsPanelModel selected.host NoInteraction model.highlightMessageId (Just messagesDetailThreadListId) model.detailThreadAnimations
                        ]


{-| A caution shown at the top of the two-pane detail (`selectedGroupView`,
inside `.messages-thread-header`) whenever `kind == FromEmail` -- unlike a
real `MessagingGroup`'s members (each an authenticated Jonline `Author`), a
`FromEmail` group's identity is nothing but an email `From:` header, which
`GetMessagesRequest.from_email`'s own proto doc already flags as
unauthenticated: anyone can put any address there. `[]` (nothing rendered)
for every other kind.
-}
spoofableEmailWarningView : Messages.MessagingGroupKind -> List (Html msg)
spoofableEmailWarningView kind =
    case kind of
        Messages.FromEmail ->
            [ p [ class "messages-spoofable-warning" ]
                [ text "Email senders aren't verified. Anyone could have sent this claiming to be this address." ]
            ]

        _ ->
            []


{-| "Reply" -- fires `ReplyClicked` with every other thread participant
(`threadParticipants`, minus whoever's actually signed in on `selected.host`
-- no point pre-selecting yourself as your own recipient, `SendMessage`
auto-adds the sender to the group either way, see `send_message.rs`'s
`find_or_create_messaging_group`) as its pre-seeded recipients -- _unless_
that filter would leave nobody at all, i.e. `selected` is a "note to self"
group with no other members to begin with: excluding yourself there would
pre-seed `SendNewMessage`'s picker with zero recipients, tripping
`MarkdownPanel.sendNewMessageProblem`'s "choose at least one recipient"
and leaving Reply unusable for the one case it's _only_ ever yourself. Hidden
entirely with nobody signed in on `selected.host` -- same "no point offering
a button that can only fail" reasoning `Pages.Messages.sendMessageButton`
already follows.
-}
replyButtonView : AccountsPanel.Model -> MessagingGroupRef -> ExpandedGroup -> Html Msg
replyButtonView accountsPanelModel selected eg =
    case AccountsPanel.enabledAccountForServer accountsPanelModel.accounts selected.host of
        Nothing ->
            text ""

        Just account ->
            let
                allParticipants : List Author
                allParticipants =
                    threadParticipants eg

                otherParticipants : List Author
                otherParticipants =
                    allParticipants |> List.filter (\author -> author.userId /= account.userId)

                recipients : List Author
                recipients =
                    if List.isEmpty otherParticipants then
                        allParticipants

                    else
                        otherParticipants
            in
            button
                [ Html.Attributes.type_ "button"
                , classes [ "messages-reply-button", hostnameToCSSClass selected.host, "background-color-primary" ]
                , onClick (ReplyClicked selected recipients)
                ]
                [ text "Reply" ]


{-| Always sorts newest-first (DOM order) -- the two-pane detail pane's own,
sole caller (`selectedGroupView`) wants that DOM order paired with
`column-reverse` (scoped `.messages-thread .messages-thread-list`,
messages.css) so it *reads* top-to-bottom like a chat transcript (oldest
first, newest at the bottom) while still being newest-first in the DOM.
That's not just a preference: `column-reverse` is what lets a short thread
bottom-anchor for free (the flex line's own `flex-start` edge is the _bottom_
in a reversed column) while an overflowing one still scrolls correctly --
`justify-content: flex-end` on a plain, non-reversed column looks equivalent
at rest but breaks scrolling to the overflowed (start-side) messages once a
thread's too long to fit, a well-known flex/overflow interaction gotcha
`column-reverse` sidesteps entirely by never needing `justify-content` to be
anything but its own `flex-start` default. (The sidebar's own message rows --
`groupMessageRows`/`sidebarRowView` -- render straight off `messageRowView`
instead, as flat entries in `Model.sidebarAnimations`, not through this
function at all.)

`domId`: always `Just "messages-detail-thread-list"` at this function's one
remaining call site -- a stable, unique DOM id `scrollToPendingMessageCmd`
can target with `Browser.Dom`'s `*Of` functions to scroll _that specific
scrolling region_ (not the whole page, which -- now that `.messages-thread`
bounds itself to the viewport and scrolls internally, see messages.css's own
doc -- usually has nothing left to scroll at all).

`messageAnimations`: `model.detailThreadAnimations`, kept in sync with
`selectedGroup` separately (`syncDetailThreadAnimations`) precisely so _this_
function's own existing per-message `UI.Flip.enter`/`remove` (below) is what
plays out when `GroupSelected` swaps which group's messages that dict holds
-- the previous group's rows leave, the newly selected group's arrive, the
same FLIP list transition an ordinary new message already gets.

-}
messageThreadView : SharedTime.Model -> AccountsPanel.Model -> String -> MessageInteraction -> Maybe String -> Maybe String -> Dict String MessageAnimation -> Html Msg
messageThreadView time accountsPanelModel host interaction highlightMessageId domId messageAnimations =
    let
        sortedAnimations : List ( String, MessageAnimation )
        sortedAnimations =
            messageAnimations
                |> Dict.toList
                |> List.sortBy (\( _, anim ) -> -(Messages.messageMillis anim.message))

        -- Whether this is the two-pane detail's own copy (`domId /= Nothing`,
        -- see this function's own doc) -- threaded down to `messageAnimationView`
        -- so *only* that copy's own message rows get a `message-<id>` DOM id
        -- (below). The same message can easily be on screen twice at once
        -- (inline-expanded in the sidebar *and* the two-pane's current
        -- `selectedGroup`, e.g. right after clicking it there) -- giving
        -- both copies the same id would leave two elements answering to it,
        -- and `Dom.getElement`/`getElementById` always resolves to whichever
        -- is first in the DOM (the sidebar's, since it renders before
        -- `.messages-detail`) regardless of which one `scrollToPendingMessageCmd`
        -- actually means to measure -- silently scrolling the *wrong*
        -- element/container's coordinates entirely.
        isDetailPane : Bool
        isDetailPane =
            domId /= Nothing

        domIdAttrs : List (Html.Attribute Msg)
        domIdAttrs =
            case domId of
                Just i ->
                    [ id i ]

                Nothing ->
                    []
    in
    Html.Keyed.node "div"
        (class "messages-thread-list flip-animated-column" :: domIdAttrs)
        (List.map (messageAnimationView time accountsPanelModel host interaction highlightMessageId isDetailPane) sortedAnimations)


messageAnimationView : SharedTime.Model -> AccountsPanel.Model -> String -> MessageInteraction -> Maybe String -> Bool -> ( String, MessageAnimation ) -> ( String, Html Msg )
messageAnimationView time accountsPanelModel host interaction highlightMessageId isDetailPane ( key, anim ) =
    let
        pointerEventsAttr : List (Html.Attribute Msg)
        pointerEventsAttr =
            if anim.flip.removing then
                [ Html.Attributes.style "pointer-events" "none" ]

            else
                []

        -- See `messageThreadView`'s own doc on `isDetailPane` -- only the
        -- two-pane copy gets a `message-<id>` id at all, since
        -- `scrollToPendingMessageCmd`'s `Dom.getElement (messageDomId ...)`
        -- is the only thing that ever looks one up, and it only ever means
        -- *that* copy.
        idAttr : List (Html.Attribute Msg)
        idAttr =
            if isDetailPane then
                [ id (messageDomId anim.message.id) ]

            else
                []
    in
    ( key
    , div (UI.Flip.itemAttributes UI.Flip.Vertical anim.flip False)
        [ div (idAttr ++ pointerEventsAttr) [ messageRowView time accountsPanelModel host interaction highlightMessageId anim.message ] ]
    )


messageRowView : SharedTime.Model -> AccountsPanel.Model -> String -> MessageInteraction -> Maybe String -> Message -> Html Msg
messageRowView time accountsPanelModel host interaction highlightMessageId message =
    let
        senderName : String
        senderName =
            Authors.name message.sender

        senderAvatarUrl : Maybe String
        senderAvatarUrl =
            Authors.avatarUrl
                (AccountsPanel.serverForHost accountsPanelModel.servers host)
                (AccountsPanel.enabledAccountForServer accountsPanelModel.accounts host)
                message.sender

        content : List (Html Msg)
        content =
            [ div [ class "message-row-header" ]
                [ avatarView "message-row-avatar" senderName senderAvatarUrl
                , span [ class "message-row-sender" ] [ text senderName ]
                , if Messages.isUnread message then
                    span [ classes [ "message-row-unread-dot", hostnameToCSSClass host, "background-color-nav" ] ] []

                  else
                    text ""
                , span [ class "message-row-time" ]
                    [ text (SharedTime.formatMoment time (Messages.messageMillis message |> Time.millisToPosix)) ]
                ]
            , messageSubjectView message
            , p [ class "message-row-body" ] [ text message.bodyText ]
            , markUnreadButtonView host message
            ]

        -- `border-color-nav` -- see `Model.highlightMessageId`'s own doc --
        -- relies on `.message-row`'s already-existing `border` (messages.css)
        -- for its width/style, same "utility class only sets the color"
        -- convention every `border-color-*` class in `UI.EmittedStylesheet`
        -- follows. `message-row-unread` just bolds the row -- see
        -- `Components.Messages.isUnread` -- the small `message-row-unread-dot`
        -- above is what actually carries the server's brand color; a
        -- highlighted *and* unread message gets both.
        rowClasses : List String
        rowClasses =
            "message-row"
                :: (if Messages.isUnread message then
                        [ "message-row-unread" ]

                    else
                        []
                   )
                ++ (if highlightMessageId == Just message.id then
                        [ hostnameToCSSClass host, "border-color-nav" ]

                    else
                        []
                   )
    in
    case interaction of
        NoInteraction ->
            div [ classes rowClasses ] content

        SelectGroup ref ->
            div [ classes ("message-row-clickable" :: rowClasses), onClick (MessageSelected ref message.id) ] content

        ExternalLink target ->
            Html.a
                [ classes rowClasses
                , href
                    ("/messages"
                        ++ Url.Builder.toQuery (groupQueryParams target.mainFrontendHost target)
                        ++ "#"
                        ++ messageDomId message.id
                    )
                , onClick (EmbeddedMessageLinkClicked { key = target.key, host = target.host, groupId = target.groupId, kind = target.kind } message.id)
                ]
                content


{-| "Mark unread" -- hidden entirely on an already-`Messages.isUnread`
message (re-marking it unread would be a no-op) or one with no `.id` fetched
yet (never actually happens -- every rendered `Message` came straight from a
`GetMessages` response). `Html.Events.custom`, not plain `onClick` -- this
button lives inside `messageRowView`'s own `content`, which every
`MessageInteraction` case wraps in something clickable/navigable of its own
(`SelectGroup`'s `onClick`, `ExternalLink`'s `<a href>`) -- same
stop-propagation-_and_-prevent-default reasoning `groupRowView`'s own
`expandChevron` doc explains, needed here for exactly the same reason (an
embedded panel's `ExternalLink` row is a real anchor; without `preventDefault`
this click would navigate away instead of just marking unread in place).
-}
markUnreadButtonView : String -> Message -> Html Msg
markUnreadButtonView host message =
    if Messages.isUnread message then
        text ""

    else
        button
            [ Html.Attributes.type_ "button"
            , class "message-row-mark-unread"
            , Html.Events.custom "click" (Decode.succeed { message = MarkUnreadClicked host message.id, stopPropagation = True, preventDefault = True })
            ]
            [ text "Mark unread" ]


messageDomId : String -> String
messageDomId messageId =
    "message-" ++ messageId
