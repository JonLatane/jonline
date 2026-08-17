module Components.Pages.MessagesPage exposing
    ( GroupRef
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


{-| Identifies one `MessagingGroup` (or solo pseudo-group, see
`Components.Messages.groupMessages`) across every fetched server -- mirrors
that module's own `GroupSummary.key`/`.host`/`.groupId`.
-}
type alias GroupRef =
    { key : String
    , host : String
    , groupId : String
    }


type alias Model =
    { messagesByServer : Dict String ServerFeed
    , groupAnimations : Dict String GroupAnimation
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
    , pageContext : Maybe PageContext

    -- `True` iff `pageContext == Nothing` (`Shared.MessagingPanel`'s
    -- embedded copy) -- kept as its own field (set alongside `pageContext`
    -- at every construction site, see `empty`/`init`) since view code
    -- branching on "am I embedded" reads clearer against a plain `Bool`
    -- than re-deriving it from `pageContext` at every call site.
    , embeddedPanel : Bool
    , searchText : String
    , searchGeneration : Int
    , selectedGroup : Maybe GroupRef
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


type alias GroupAnimation =
    { summary : Messages.GroupSummary
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
    , messageAnimations : Dict String MessageAnimation

    -- Carried alongside `status`/`messageAnimations` (duplicating the outer
    -- `expandedGroups` Dict key) so `retryPendingExpansions` can re-issue
    -- the fetch for a still-`ExpandLoading` entry without needing a
    -- `GroupRef` from anywhere else -- see that function's own doc.
    , host : String
    , groupId : String
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
    | MessageAnimate Animation.Msg
    | RemoveGroup String
    | RemoveMessage String String
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
    | GroupSelected GroupRef
    | ScrollAttempted (Result Dom.Error ())
    | ToggleMobileSidebar
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
    | EmbeddedGroupLinkClicked GroupRef
      -- `GroupSelected`'s own effect (expand + `selectedGroup`), minus the
      -- `pushUrl` -- see `EmbeddedGroupLinkClicked`'s doc: dispatched only
      -- via that forwarding path, where the URL bar's already been updated
      -- by the embedded panel's own real `<a href>` navigation, so pushing
      -- it again here would just double up the browser history entry.
    | SyncSelectedGroup GroupRef
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
    | ReplyClicked GroupRef (List Author)
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
    | MessageSelected GroupRef String
      -- The "Mark unread" button on an already-read message row (any
      -- context -- two-pane detail, sidebar inline-expand, or embedded
      -- panel). `host` (not a whole `GroupRef`) is all `update` needs to
      -- resolve which account to fire `MarkMessagesRead { unread = True }`
      -- as -- see its own handling, which mirrors `GotGroupMessages`'
      -- optimistic-patch-then-fire-the-RPC shape, just in reverse and for a
      -- single message instead of a whole thread's unread ones.
    | MarkUnreadClicked String String


{-| A `Model` with nothing fetched yet and no `PageContext` -- what
`Shared.MessagingPanel.init` seeds itself with, so the app never fires a
`GetMessages` RPC on startup before that panel's ever been opened (mirrors
`Shared.StarredPanel`'s own fetch-only-once-shown convention). `init` itself
starts from this too, immediately overriding it with a real fetch.
-}
empty : Model
empty =
    { messagesByServer = Dict.empty
    , groupAnimations = Dict.empty
    , expandedGroups = Dict.empty
    , inlineOpenGroups = Set.empty
    , pageContext = Nothing
    , embeddedPanel = True
    , searchText = ""
    , searchGeneration = 0
    , selectedGroup = Nothing
    , pendingScrollMessageId = Nothing
    , highlightMessageId = Nothing
    , mobileSidebarOpen = False
    }


init : AccountsPanel.Model -> Maybe PageContext -> Maybe GroupRef -> Maybe String -> String -> ( Model, Cmd Msg )
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
        , UI.Flip.subscription Animate (List.map .flip (Dict.values model.groupAnimations))
        , UI.Flip.subscription MessageAnimate
            (model.expandedGroups
                |> Dict.values
                |> List.concatMap (\eg -> Dict.values eg.messageAnimations |> List.map .flip)
            )
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
                |> syncAnimations
            , Cmd.none
            , maybeAccountsPanelMsg
            )

        GotServerMessages host (Err _) ->
            ( { model | messagesByServer = Dict.update host (Maybe.map (\feed -> { feed | status = Failed })) model.messagesByServer }
                |> syncAnimations
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
                    animateGroupDict animMsg model.groupAnimations
            in
            ( { model | groupAnimations = newAnimations }, Cmd.batch cmds, Nothing )

        MessageAnimate animMsg ->
            let
                ( newExpanded, cmds ) =
                    animateExpandedGroups animMsg model.expandedGroups
            in
            ( { model | expandedGroups = newExpanded }, Cmd.batch cmds, Nothing )

        RemoveGroup key ->
            ( { model | groupAnimations = Dict.remove key model.groupAnimations }, Cmd.none, Nothing )

        RemoveMessage groupKey messageId ->
            ( { model
                | expandedGroups =
                    Dict.update groupKey
                        (Maybe.map (\eg -> { eg | messageAnimations = Dict.remove messageId eg.messageAnimations }))
                        model.expandedGroups
              }
            , Cmd.none
            , Nothing
            )

        ToggleExpand summary ->
            if Set.member summary.key model.inlineOpenGroups then
                ( { model | inlineOpenGroups = Set.remove summary.key model.inlineOpenGroups }, Cmd.none, Nothing )

            else
                let
                    ( newModel, cmd ) =
                        expand accountsPanelModel { model | inlineOpenGroups = Set.insert summary.key model.inlineOpenGroups }
                            { key = summary.key, host = summary.host, groupId = summary.groupId }
                in
                ( newModel, cmd, Nothing )

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
                -- a `GroupRef` threaded in from wherever `GotGroupMessages`
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
                                            , messageAnimations = syncMessageAnimations key patchedMessages eg.messageAnimations
                                        }
                                    )
                                )
                                model.expandedGroups

                        -- Patches the *outer listing's* own copy of these
                        -- same messages too (if `host` has one), so
                        -- `syncAnimations` below recomputes each affected
                        -- `GroupSummary.unreadCount` immediately -- without
                        -- this, the group card's own unread badge wouldn't
                        -- catch up until the next 30s `Poll` refetches the
                        -- outer listing fresh from the server.
                        , messagesByServer =
                            case host of
                                Just h ->
                                    Dict.update h (Maybe.map (patchServerFeedRead unreadIds)) model.messagesByServer

                                Nothing ->
                                    model.messagesByServer
                    }
                        |> syncAnimations

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
                -- its own `messageAnimations`; a no-op wherever `messageId`
                -- doesn't appear.
                patchedExpandedGroups : Dict String ExpandedGroup
                patchedExpandedGroups =
                    Dict.map
                        (\_ eg ->
                            { eg
                                | messageAnimations =
                                    Dict.map (\_ anim -> { anim | message = patchMessageUnread unreadIds anim.message }) eg.messageAnimations
                            }
                        )
                        model.expandedGroups

                newModel : Model
                newModel =
                    { model
                        | expandedGroups = patchedExpandedGroups
                        , messagesByServer = Dict.update host (Maybe.map (patchServerFeedUnread unreadIds)) model.messagesByServer
                    }
                        |> syncAnimations

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
            ( { model | searchText = newSearchText, searchGeneration = generation }
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
                        ( expandedModel, expandCmd ) =
                            -- Closes the mobile sidebar overlay too (see
                            -- `view`'s own doc) -- selecting a group should
                            -- reveal what was just picked, not leave it
                            -- covered by the still-open sidebar.
                            expand accountsPanelModel { model | selectedGroup = Just ref, mobileSidebarOpen = False } ref
                    in
                    ( expandedModel
                    , Cmd.batch [ expandCmd, Browser.Navigation.pushUrl ctx.navKey (ctx.path ++ queryString accountsPanelModel expandedModel) ]
                    , Nothing
                    )

        ScrollAttempted _ ->
            ( { model | pendingScrollMessageId = Nothing }, Cmd.none, Nothing )

        ToggleMobileSidebar ->
            ( { model | mobileSidebarOpen = not model.mobileSidebarOpen }, Cmd.none, Nothing )

        EmbeddedGroupLinkClicked _ ->
            ( model, Cmd.none, Nothing )

        SyncSelectedGroup ref ->
            let
                ( expandedModel, expandCmd ) =
                    expand accountsPanelModel { model | selectedGroup = Just ref, mobileSidebarOpen = False } ref
            in
            ( expandedModel, expandCmd, Nothing )

        ReplyClicked _ _ ->
            ( model, Cmd.none, Nothing )

        MessageSelected ref messageId ->
            case model.pageContext of
                Nothing ->
                    ( model, Cmd.none, Nothing )

                Just ctx ->
                    let
                        ( expandedModel, expandCmd ) =
                            expand accountsPanelModel
                                { model
                                    | selectedGroup = Just ref
                                    , mobileSidebarOpen = False
                                    , highlightMessageId = Just messageId
                                    , pendingScrollMessageId = Just messageId
                                }
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


{-| Expands `ref` (a no-op if already expanded): a "solo" (Bcc-only) group is
already fully in hand from the outer listing fetch (see
`Components.Messages.groupMessages`), so this just seeds it directly with no
RPC; every other group fetches its full thread via `GetMessages
{ messageGroupId = Just ref.groupId }`. Falls back to `PERSONALMESSAGES`/no
known account when `ref.host` isn't (yet) in `messagesByServer` at all -- e.g.
a `?messaging_group=` permalink to a group whose host the viewer isn't
currently signed into with a matching permission -- so the fetch still fires
(and, most likely, 404s into `ExpandFailed`'s "not found" rendering) rather
than silently doing nothing.
-}
expand : AccountsPanel.Model -> Model -> GroupRef -> ( Model, Cmd Msg )
expand accountsPanelModel model ref =
    if Dict.member ref.key model.expandedGroups then
        ( model, Cmd.none )

    else
        case Dict.get ref.key model.groupAnimations |> Maybe.map .summary of
            Just summary ->
                if summary.isSolo then
                    ( { model
                        | expandedGroups =
                            Dict.insert ref.key
                                { status = ExpandLoaded
                                , messageAnimations = Dict.singleton summary.mostRecent.id { message = summary.mostRecent, flip = UI.Flip.enter }
                                , host = ref.host
                                , groupId = ref.groupId
                                }
                                model.expandedGroups
                      }
                    , Cmd.none
                    )

                else
                    fetchExpand accountsPanelModel model ref

            Nothing ->
                fetchExpand accountsPanelModel model ref


{-| Fires (or re-fires, see `retryPendingExpansions`) the actual `GetMessages
{ messageGroupId = ... }` fetch for `ref` -- unless `ref.host` isn't yet a
`knownConnectedServer` (see that function's own doc on the disconnected
placeholder every persisted server starts as), in which case this leaves the
entry `ExpandLoading` (never firing a doomed, instantly-failing request
against it) for `retryPendingExpansions` to actually attempt once the real
connection lands -- mirrors `Components.Messages.eligibleServers`'s own fix
for the exact same race, just for a single group's fetch instead of the
whole listing. A genuine failure (the fetch *did* reach a connected server,
and it came back an error -- not found, no access, ...) still lands in
`ExpandFailed` as before, via `GotGroupMessages`'s own `Err` branch -- that
one's terminal, not retried.
-}
fetchExpand : AccountsPanel.Model -> Model -> GroupRef -> ( Model, Cmd Msg )
fetchExpand accountsPanelModel model ref =
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

        existingMessageAnimations : Dict String MessageAnimation
        existingMessageAnimations =
            Dict.get ref.key model.expandedGroups |> Maybe.map .messageAnimations |> Maybe.withDefault Dict.empty

        cmd : Cmd Msg
        cmd =
            case AccountsPanel.knownConnectedServer accountsPanelModel.servers ref.host of
                Nothing ->
                    Cmd.none

                Just _ ->
                    Messages.fetchMessagingGroup accountsPanelModel ( accountUserId, ref.host ) listingType ref.groupId
                        |> Task.attempt (GotGroupMessages ref.key)
    in
    ( { model
        | expandedGroups =
            Dict.insert ref.key
                { status = ExpandLoading, messageAnimations = existingMessageAnimations, host = ref.host, groupId = ref.groupId }
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
        pending : List GroupRef
        pending =
            model.expandedGroups
                |> Dict.toList
                |> List.filterMap
                    (\( key, eg ) ->
                        if eg.status == ExpandLoading then
                            Just { key = key, host = eg.host, groupId = eg.groupId }

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


{-| Once a group's thread finishes loading, scrolls `pendingScrollMessageId`
(from the initial `#message-<id>` fragment, see `Pages.Messages.init`) into
view if it's actually present in what just loaded -- a one-shot attempt;
`ScrollAttempted` always clears it afterward (success or failure) so a
missing/not-yet-loaded target doesn't keep retrying every render.
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
                        |> List.any (\eg -> Dict.member messageId eg.messageAnimations)
            in
            if isPresent then
                Dom.getElement (messageDomId messageId)
                    |> Task.andThen (\el -> Dom.setViewport 0 (max 0 (el.element.y - 96)))
                    |> Task.attempt ScrollAttempted

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
though, this can only ever reflect what's *already been fetched* into this
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
    model.groupAnimations
        |> Dict.values
        |> List.map (\anim -> anim.summary.unreadCount)
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
        |> Tuple.mapFirst syncAnimations


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


{-| `?search_text=`/`?messaging_group=` together, reflecting `model`'s
current state -- shared by `applySearchChange` (via `replaceUrl`, so
per-keystroke debounce ticks don't spam history) and `GroupSelected` (via
`pushUrl`, a real navigational choice) so neither ever clobbers the other's
half of the query string.
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
                |> Maybe.map (\ref -> [ Url.Builder.string "messaging_group" (Messages.groupRouteId accountsPanelModel.mainFrontendHost ref.host ref.groupId) ])
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


syncAnimations : Model -> Model
syncAnimations model =
    let
        currentGroups : Dict String Messages.GroupSummary
        currentGroups =
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
    in
    { model
        | groupAnimations =
            UI.Flip.syncAnimations
                RemoveGroup
                (\summary -> { summary = summary, flip = UI.Flip.enter })
                (\summary anim -> { anim | summary = summary })
                currentGroups
                model.groupAnimations
    }


syncMessageAnimations : String -> List Message -> Dict String MessageAnimation -> Dict String MessageAnimation
syncMessageAnimations groupKey messages animations =
    let
        currentMessages : Dict String Message
        currentMessages =
            messages |> List.map (\message -> ( message.id, message )) |> Dict.fromList
    in
    UI.Flip.syncAnimations
        (RemoveMessage groupKey)
        (\message -> { message = message, flip = UI.Flip.enter })
        (\message anim -> { anim | message = message })
        currentMessages
        animations


animateGroupDict : Animation.Msg -> Dict String GroupAnimation -> ( Dict String GroupAnimation, List (Cmd Msg) )
animateGroupDict animMsg animations =
    let
        step : String -> GroupAnimation -> ( Dict String GroupAnimation, List (Cmd Msg) ) -> ( Dict String GroupAnimation, List (Cmd Msg) )
        step key anim ( acc, cmds ) =
            let
                ( newFlip, cmd ) =
                    UI.Flip.animate animMsg anim.flip
            in
            ( Dict.insert key { anim | flip = newFlip } acc, cmd :: cmds )
    in
    Dict.foldl step ( Dict.empty, [] ) animations


animateExpandedGroups : Animation.Msg -> Dict String ExpandedGroup -> ( Dict String ExpandedGroup, List (Cmd Msg) )
animateExpandedGroups animMsg expandedGroups =
    let
        stepGroup : String -> ExpandedGroup -> ( Dict String ExpandedGroup, List (Cmd Msg) ) -> ( Dict String ExpandedGroup, List (Cmd Msg) )
        stepGroup groupKey eg ( acc, cmds ) =
            let
                stepMessage : String -> MessageAnimation -> ( Dict String MessageAnimation, List (Cmd Msg) ) -> ( Dict String MessageAnimation, List (Cmd Msg) )
                stepMessage msgKey anim ( innerAcc, innerCmds ) =
                    let
                        ( newFlip, cmd ) =
                            UI.Flip.animate animMsg anim.flip
                    in
                    ( Dict.insert msgKey { anim | flip = newFlip } innerAcc, cmd :: innerCmds )

                ( newAnimations, msgCmds ) =
                    Dict.foldl stepMessage ( Dict.empty, [] ) eg.messageAnimations
            in
            ( Dict.insert groupKey { eg | messageAnimations = newAnimations } acc, msgCmds ++ cmds )
    in
    Dict.foldl stepGroup ( Dict.empty, [] ) expandedGroups



-- VIEW


{-| `.messages-page` breaks out of `UI.layout`'s usual 800px-capped
`.container` to use the full page width instead (see messages.css's own
`margin-left`/`margin-right` trick, mirrored from `Components.Pages.EventsPage`'s
grid/strip views -- the only other place in this codebase doing this).

In two-pane mode, `.messages-sidebar` is a normal, always-visible column
alongside `.messages-detail` at any reasonable width -- but on a narrow
(< 640px) screen, messages.css turns it into a fixed-position overlay instead
(there's no room for two columns), toggled by `searchRowView`'s hamburger
button (`ToggleMobileSidebar`) rather than shown outright.
`openClosedClass model.mobileSidebarOpen` only actually matters at that
width; wider viewports override it back to always-visible in CSS.
-}
view : SharedTime.BrowserTimeZone -> AccountsPanel.Model -> Model -> Html Msg
view browserTimeZone accountsPanelModel model =
    div [ class "messages-page" ]
        [ searchRowView model
        , case model.selectedGroup of
            Nothing ->
                groupsListView browserTimeZone accountsPanelModel model

            Just selected ->
                div [ class "messages-two-pane" ]
                    [ div [ classes [ "messages-sidebar", openClosedClass model.mobileSidebarOpen ] ] [ groupsListView browserTimeZone accountsPanelModel model ]
                    , div [ class "messages-detail" ] [ selectedGroupView browserTimeZone accountsPanelModel model selected ]
                    ]
        ]


searchRowView : Model -> Html Msg
searchRowView model =
    div [ class "filter-controls-row" ]
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
            text ""
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


groupsListView : SharedTime.BrowserTimeZone -> AccountsPanel.Model -> Model -> Html Msg
groupsListView browserTimeZone accountsPanelModel model =
    if Dict.isEmpty model.messagesByServer then
        p [ class "posts-empty" ] [ text "Sign in with permission to read messages to see them here." ]

    else
        let
            sortedAnimations : List ( String, GroupAnimation )
            sortedAnimations =
                model.groupAnimations
                    |> Dict.toList
                    |> List.sortBy (\( _, anim ) -> -(Messages.messageMillis anim.summary.mostRecent))
        in
        if List.isEmpty sortedAnimations then
            p [ class "posts-empty" ] [ text "No messages yet." ]

        else
            Html.Keyed.node "div"
                [ class "messages-group-list flip-animated-column" ]
                (List.map (groupAnimationView browserTimeZone accountsPanelModel model) sortedAnimations)


groupAnimationView : SharedTime.BrowserTimeZone -> AccountsPanel.Model -> Model -> ( String, GroupAnimation ) -> ( String, Html Msg )
groupAnimationView browserTimeZone accountsPanelModel model ( key, anim ) =
    let
        pointerEventsAttr : List (Html.Attribute Msg)
        pointerEventsAttr =
            if anim.flip.removing then
                [ Html.Attributes.style "pointer-events" "none" ]

            else
                []
    in
    ( key
    , div (UI.Flip.itemAttributes UI.Flip.Vertical anim.flip False)
        [ div pointerEventsAttr [ groupRowView browserTimeZone accountsPanelModel model anim.summary ] ]
    )


groupRowView : SharedTime.BrowserTimeZone -> AccountsPanel.Model -> Model -> Messages.GroupSummary -> Html Msg
groupRowView browserTimeZone accountsPanelModel model summary =
    let
        isSelected : Bool
        isSelected =
            model.selectedGroup |> Maybe.map .key |> (==) (Just summary.key)

        rowClasses : List String
        rowClasses =
            "messages-group-row"
                :: (if isSelected then
                        [ "selected" ]

                    else
                        []
                   )

        content : List (Html Msg)
        content =
            [ div [ class "messages-group-row-body" ]
                [ participantsView accountsPanelModel summary.host summary.members
                , span [ classes [ "messages-group-time", hostnameToCSSClass summary.host ] ]
                    [ text (SharedTime.formatDateTime browserTimeZone (Messages.messageMillis summary.mostRecent |> Time.millisToPosix)) ]
                , unreadBadgeView summary.host summary.unreadCount
                ]
            ]

        isInlineOpen : Bool
        isInlineOpen =
            Set.member summary.key model.inlineOpenGroups

        -- Always shown, on *every* row -- including whichever one is
        -- `selectedGroup` (see `inlineOpenGroups`' own doc on `Model` for
        -- why that no longer conflicts with the two-pane detail pane).
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
                , href ("/messages" ++ Url.Builder.toQuery [ Url.Builder.string "messaging_group" (Messages.groupRouteId accountsPanelModel.mainFrontendHost summary.host summary.groupId) ])
                , onClick (EmbeddedGroupLinkClicked { key = summary.key, host = summary.host, groupId = summary.groupId })
                ]
                (expandChevron :: content)

          else
            div
                [ classes rowClasses
                , onClick (GroupSelected { key = summary.key, host = summary.host, groupId = summary.groupId })
                ]
                (expandChevron :: content)
        , if isInlineOpen then
            expandedGroupView browserTimeZone accountsPanelModel model summary.key

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
old subject heading -- see both their own docs for why.
-}
participantsView : AccountsPanel.Model -> String -> List Author -> Html msg
participantsView accountsPanelModel host members =
    div [ class "messages-participants" ] (List.map (participantChipView accountsPanelModel host) members)


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
        span [ classes [ "messages-unread-badge", hostnameToCSSClass host, "background-color-nav", "border-color-primary-text" ] ]
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
permalink -- "clicking a message... takes you to the [real page]" per that
panel's own spec (`ExternalLink`). The real page's own two-pane detail
(`selectedGroupView`) is already showing the message, so its own rows are
plain, non-navigating content (`NoInteraction`). The real page's *sidebar*
inline-expand (`groupRowView`'s chevron) is the one case with somewhere to
go that isn't a full page navigation -- clicking one of its rows selects
that message's group into the two-pane detail *and* scrolls/highlights that
exact message there, same as landing on its `#message-<id>` permalink
directly (`SelectGroup`, see `MessageSelected`'s own doc). Deliberately
*not* affected by whether some *other* group is currently `selectedGroup` --
clicking a message is always a real choice, unlike merely toggling a row's
chevron open (`ToggleExpand`, `inlineOpenGroups`), which never touches
`selectedGroup` at all.
-}
type MessageInteraction
    = NoInteraction
    | ExternalLink MessageLinkTarget
    | SelectGroup GroupRef


type alias MessageLinkTarget =
    { mainFrontendHost : String, host : String, groupId : String }


messageInteractionFor : AccountsPanel.Model -> Model -> Messages.GroupSummary -> MessageInteraction
messageInteractionFor accountsPanelModel model summary =
    if model.embeddedPanel then
        ExternalLink { mainFrontendHost = accountsPanelModel.mainFrontendHost, host = summary.host, groupId = summary.groupId }

    else
        SelectGroup { key = summary.key, host = summary.host, groupId = summary.groupId }


expandedGroupView : SharedTime.BrowserTimeZone -> AccountsPanel.Model -> Model -> String -> Html Msg
expandedGroupView browserTimeZone accountsPanelModel model groupKey =
    case ( Dict.get groupKey model.expandedGroups, Dict.get groupKey model.groupAnimations ) of
        ( Just eg, Just anim ) ->
            case eg.status of
                ExpandLoading ->
                    p [ class "messages-thread-status" ] [ text "Loading messages…" ]

                ExpandFailed ->
                    p [ class "messages-thread-status" ] [ text "Couldn't load this messaging group." ]

                ExpandLoaded ->
                    messageThreadView browserTimeZone accountsPanelModel anim.summary.host (messageInteractionFor accountsPanelModel model anim.summary) model.highlightMessageId eg

        _ ->
            text ""


{-| A thread's participants -- derived straight from the `messagingGroup` of
whichever loaded message has one (they all share the same group, so the
first is enough), *not* from `model.groupAnimations` -- this way it's just as
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
            eg.messageAnimations |> Dict.values |> List.map .message

        fromGroup : List Author
        fromGroup =
            messages |> List.filterMap .messagingGroup |> List.head |> Maybe.map .members |> Maybe.withDefault []
    in
    if List.isEmpty fromGroup then
        messages |> List.filterMap .sender

    else
        fromGroup


selectedGroupView : SharedTime.BrowserTimeZone -> AccountsPanel.Model -> Model -> GroupRef -> Html Msg
selectedGroupView browserTimeZone accountsPanelModel model selected =
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
                            [ participantsView accountsPanelModel selected.host (threadParticipants eg)
                            , replyButtonView accountsPanelModel selected eg
                            ]
                        , messageThreadView browserTimeZone accountsPanelModel selected.host NoInteraction model.highlightMessageId eg
                        ]


{-| "Reply" -- fires `ReplyClicked` with every other thread participant
(`threadParticipants`, minus whoever's actually signed in on `selected.host`
-- no point pre-selecting yourself as your own recipient, `SendMessage`
auto-adds the sender to the group either way, see `send_message.rs`'s
`find_or_create_messaging_group`) as its pre-seeded recipients. Hidden
entirely with nobody signed in on `selected.host` -- same "no point offering
a button that can only fail" reasoning `Pages.Messages.sendMessageButton`
already follows.
-}
replyButtonView : AccountsPanel.Model -> GroupRef -> ExpandedGroup -> Html Msg
replyButtonView accountsPanelModel selected eg =
    case AccountsPanel.enabledAccountForServer accountsPanelModel.accounts selected.host of
        Nothing ->
            text ""

        Just account ->
            let
                recipients : List Author
                recipients =
                    threadParticipants eg |> List.filter (\author -> author.userId /= account.userId)
            in
            button
                [ Html.Attributes.type_ "button"
                , classes [ "messages-reply-button", hostnameToCSSClass selected.host, "background-color-primary" ]
                , onClick (ReplyClicked selected recipients)
                ]
                [ text "Reply" ]


messageThreadView : SharedTime.BrowserTimeZone -> AccountsPanel.Model -> String -> MessageInteraction -> Maybe String -> ExpandedGroup -> Html Msg
messageThreadView browserTimeZone accountsPanelModel host interaction highlightMessageId eg =
    let
        sortedAnimations : List ( String, MessageAnimation )
        sortedAnimations =
            eg.messageAnimations
                |> Dict.toList
                |> List.sortBy (\( _, anim ) -> -(Messages.messageMillis anim.message))
    in
    Html.Keyed.node "div"
        [ class "messages-thread-list flip-animated-column" ]
        (List.map (messageAnimationView browserTimeZone accountsPanelModel host interaction highlightMessageId) sortedAnimations)


messageAnimationView : SharedTime.BrowserTimeZone -> AccountsPanel.Model -> String -> MessageInteraction -> Maybe String -> ( String, MessageAnimation ) -> ( String, Html Msg )
messageAnimationView browserTimeZone accountsPanelModel host interaction highlightMessageId ( key, anim ) =
    let
        pointerEventsAttr : List (Html.Attribute Msg)
        pointerEventsAttr =
            if anim.flip.removing then
                [ Html.Attributes.style "pointer-events" "none" ]

            else
                []
    in
    ( key
    , div (UI.Flip.itemAttributes UI.Flip.Vertical anim.flip False)
        [ div (id (messageDomId anim.message.id) :: pointerEventsAttr) [ messageRowView browserTimeZone accountsPanelModel host interaction highlightMessageId anim.message ] ]
    )


messageRowView : SharedTime.BrowserTimeZone -> AccountsPanel.Model -> String -> MessageInteraction -> Maybe String -> Message -> Html Msg
messageRowView browserTimeZone accountsPanelModel host interaction highlightMessageId message =
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
                    [ text (SharedTime.formatDateTime browserTimeZone (Messages.messageMillis message |> Time.millisToPosix)) ]
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
                        ++ Url.Builder.toQuery [ Url.Builder.string "messaging_group" (Messages.groupRouteId target.mainFrontendHost target.host target.groupId) ]
                        ++ "#"
                        ++ messageDomId message.id
                    )
                ]
                content


{-| "Mark unread" -- hidden entirely on an already-`Messages.isUnread`
message (re-marking it unread would be a no-op) or one with no `.id` fetched
yet (never actually happens -- every rendered `Message` came straight from a
`GetMessages` response). `Html.Events.custom`, not plain `onClick` -- this
button lives inside `messageRowView`'s own `content`, which every
`MessageInteraction` case wraps in something clickable/navigable of its own
(`SelectGroup`'s `onClick`, `ExternalLink`'s `<a href>`) -- same
stop-propagation-*and*-prevent-default reasoning `groupRowView`'s own
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
