module Components.Messages exposing
    ( GroupSummary
    , eligibleServers
    , fetchMessageListing
    , fetchMessagingGroup
    , groupMessages
    , groupRouteId
    , hasEligibleAccount
    , isUnread
    , markMessagesRead
    , messageMillis
    , parseGroupRouteId
    )

{-| Shared building blocks for `Components.Pages.MessagesPage` -- the
per-account fetch helpers (mirroring `Components.Users.fetchUserListing`) and
the client-side grouping of a flat `GetMessagesResponse.messages` list into
`MessagingGroup`s (there's no `GetMessagingGroups` RPC; only `GetMessages`,
which always returns messages -- see `protos/messages.proto`).

Unlike `Components.Users.fetchUserListing`'s unfiltered `EVERYONE` listing
(every _enabled_ server, no account needed), `GetMessages` always requires
auth (`backend/src/rpcs/messages/get_messages.rs`'s `validate_permission`
rejects an anonymous `user`), so `eligibleServers` scopes this to every
signed-in account that actually has the relevant permission, one
`MessageListingType` decision per account -- see its own doc.

-}

import Dict exposing (Dict)
import Grpc
import Proto.Jonline exposing (Author, GetMessagesRequest, GetMessagesResponse, Message, MessageRead, defaultGetMessagesRequest, defaultMarkMessagesReadRequest)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.MessageListingType exposing (MessageListingType(..))
import Proto.Jonline.Permission exposing (Permission(..))
import Shared.AccountsPanel as AccountsPanel exposing (performWithAccountServer, withAccessToken)
import Shared.Conversions exposing (timestampToPosix)
import Task exposing (Task)
import Time


{-| One eligible `(Server, Account, MessageListingType)` triple to fetch
messages from -- one entry per signed-in account that has the relevant
permission (or `ADMIN`) on its own server, never more than one entry per
account. Prefers `PERSONALMESSAGES` (a user's own inbox) over
`ALLSYSTEMMESSAGES` (the whole server's firehose) whenever an account has
both -- an account signed in somewhere is far more likely to want their own
messages front and center than every message on the server; there's no UI
toggle between the two in v1.

Resolves `account.server` via `AccountsPanel.knownConnectedServer`, not plain
`serverForHost` -- `GetMessages` is a real route-driven fetch (see
`MessagesPage.fetchNewServers`), and `knownConnectedServer`'s own doc comment
explains why: `serverForHost` alone would happily match the disconnected
placeholder `AccountsPanel.init` seeds every persisted server with before its
reconnect resolves, letting the very first fetch fire (and fail instantly,
client-side, no network call) against a server that isn't actually reachable
yet -- and since `fetchNewServers` only retries an entry when its
account/listingType changes, that failure would stick around unretried for
the rest of the page's lifetime, even once the real connection lands moments
later. Excluding a not-yet-connected account from `eligibleServers` entirely
instead means no fetch (and no `Failed` status) is ever recorded for it, so
the very next `Poll` (fired off the `Shared.AccountsPanelMsg` that connecting
itself dispatches -- see `Pages.Messages.update`) sees it as brand new and
fetches for the first time, successfully.

-}
eligibleServers : AccountsPanel.Model -> List { server : AccountsPanel.Server, account : AccountsPanel.Account, listingType : MessageListingType }
eligibleServers accountsPanelModel =
    AccountsPanel.enabledAccounts accountsPanelModel
        |> List.filterMap
            (\account ->
                let
                    listingType : Maybe MessageListingType
                    listingType =
                        if AccountsPanel.isAdmin account || List.member READPERSONALMESSAGES account.permissions then
                            Just PERSONALMESSAGES

                        else if List.member READALLSYSTEMMESSAGES account.permissions then
                            Just ALLSYSTEMMESSAGES

                        else
                            Nothing
                in
                Maybe.map2 (\server lt -> { server = server, account = account, listingType = lt })
                    (AccountsPanel.knownConnectedServer accountsPanelModel.servers account.server)
                    listingType
            )


{-| Whether `accountsPanelModel` has at least one `eligibleServers` entry --
gates both the Messages nav icon (`Shared.MessagingPanel.hasEligibleAccount`)
and the page's own "nothing to show" empty state. Mirrors
`Shared.CreateNewPanel.hasEligibleAccount`.
-}
hasEligibleAccount : AccountsPanel.Model -> Bool
hasEligibleAccount accountsPanelModel =
    not (List.isEmpty (eligibleServers accountsPanelModel))


{-| The `*_TEXT_SEARCH` counterpart of `listingType` -- mirrors
`Components.Users.textSearchListingType`.
-}
textSearchListingType : MessageListingType -> MessageListingType
textSearchListingType listingType =
    case listingType of
        PERSONALMESSAGES ->
            PERSONALMESSAGESTEXTSEARCH

        ALLSYSTEMMESSAGES ->
            ALLSYSTEMMESSAGESTEXTSEARCH

        other ->
            other


{-| Fetches `listingType`'s listing (or its `textSearchListingType`
counterpart, if `searchText` isn't blank) from `maybeAccountServer`'s server,
authenticated as its account -- mirrors `Components.Users.fetchUserListing`.
-}
fetchMessageListing :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> MessageListingType
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetMessagesResponse )
fetchMessageListing accountsPanelModel maybeAccountServer listingType searchText =
    let
        trimmedSearchText : String
        trimmedSearchText =
            String.trim searchText

        request : GetMessagesRequest
        request =
            if String.isEmpty trimmedSearchText then
                { defaultGetMessagesRequest | listingType = listingType }

            else
                { defaultGetMessagesRequest
                    | listingType = textSearchListingType listingType
                    , searchText = Just trimmedSearchText
                }
    in
    fetchMessages accountsPanelModel maybeAccountServer request


{-| Fetches every message in `groupId` (most-recent-first, per
`get_messaging_group_messages`) -- what expanding a group (or two-pane
`selectedGroup`) in `Components.Pages.MessagesPage` fetches. `listingType`
should be the same `PERSONALMESSAGES`/`ALLSYSTEMMESSAGES` (never the
`*_TEXT_SEARCH` variant -- a group's own full thread isn't itself filtered by
the outer listing's search) the group was found under, from `eligibleServers`.

Never called for a "solo" (Bcc-only) pseudo-group (see `groupMessages`) --
there's only ever the one already-in-hand message for those, no group id to
fetch by.

-}
fetchMessagingGroup :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> MessageListingType
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetMessagesResponse )
fetchMessagingGroup accountsPanelModel maybeAccountServer listingType groupId =
    fetchMessages accountsPanelModel maybeAccountServer { defaultGetMessagesRequest | listingType = listingType, messageGroupId = Just groupId }


fetchMessages :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> GetMessagesRequest
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetMessagesResponse )
fetchMessages accountsPanelModel maybeAccountServer request =
    performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.getMessages request
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


{-| One `MessagingGroup` (or Bcc-only solo pseudo-group) summarized down to
its most recent message -- what `Components.Pages.MessagesPage`'s outer list
renders/sorts/animates. `key` is globally unique across every fetched server
(`"<host>|<groupId>"`, or `"<host>|<messageId>"` for a solo group -- a raw
`MessagingGroup.id`/`Message.id` alone isn't unique across servers, same
reasoning as `Components.Users.followStatusAndButtonKey`). `unreadCount`
counts every fetched message in the group with `isUnread == True` -- not just
whether `mostRecent` itself is unread -- so it stays accurate once an older
message's read status changes independently (e.g. `MessagesPage` marking a
whole thread read on expand doesn't necessarily touch every message at once).
-}
type alias GroupSummary =
    { key : String
    , host : String
    , groupId : String
    , isSolo : Bool
    , members : List Author
    , mostRecent : Message
    , unreadCount : Int
    }


{-| Groups a flat, `created_at DESC`-sorted `messages` list (as
`GetMessagesResponse` always returns them) by `messagingGroup.id` -- there's
no `GetMessagingGroups` RPC, only `GetMessages`, so this is the only way to
derive a group listing at all. A message with `messagingGroup == Nothing`
(the client was Bcc'ed, per `Message.messaging_group`'s own proto doc: no
group access) becomes its own "solo" pseudo-group instead, keyed by its own
message id -- there's exactly one message in it, and no real group id to
group it under. Result is sorted by each group's `mostRecent` message,
most-recent-first.
-}
groupMessages : String -> List Message -> List GroupSummary
groupMessages host messages =
    let
        addMessage : Message -> Dict String GroupSummary -> Dict String GroupSummary
        addMessage message groups =
            let
                ( groupId, isSolo, members ) =
                    case message.messagingGroup of
                        Just group ->
                            ( group.id, False, group.members )

                        Nothing ->
                            ( message.id, True, message.sender |> Maybe.map List.singleton |> Maybe.withDefault [] )

                key : String
                key =
                    host ++ "|" ++ groupId

                increment : Int
                increment =
                    if isUnread message then
                        1

                    else
                        0
            in
            case Dict.get key groups of
                Nothing ->
                    Dict.insert key
                        { key = key, host = host, groupId = groupId, isSolo = isSolo, members = members, mostRecent = message, unreadCount = increment }
                        groups

                Just existing ->
                    Dict.insert key
                        { existing
                            | mostRecent =
                                if messageMillis message > messageMillis existing.mostRecent then
                                    message

                                else
                                    existing.mostRecent
                            , unreadCount = existing.unreadCount + increment
                        }
                        groups
    in
    List.foldl addMessage Dict.empty messages
        |> Dict.values
        |> List.sortBy (\group -> -(messageMillis group.mostRecent))


{-| `True` iff `message.currentUserRead` hasn't been set -- see that field's
own proto doc comment. Used both to compute `GroupSummary.unreadCount` and by
`MessagesPage` to decide which messages to `markMessageRead` once their
thread's actually been viewed.
-}
isUnread : Message -> Bool
isUnread message =
    message.currentUserRead == Nothing


{-| Marks every id in `messageIds` read or unread (`MarkMessagesReadRequest.unread`),
all in one request, as `maybeAccountServer`'s account. Two callers:
`MessagesPage` fires this with `unread = False` once per thread, for every
`isUnread` message in it at once, right when that thread's finished loading
(see its own `GotGroupMessages` handling); its own "Mark unread" button
(`MarkUnreadClicked`) fires it with `unread = True` for a single already-read
message instead. `messageIds` empty is a caller bug (the RPC itself rejects
it) -- both callers only ever call this with a non-empty list.
-}
markMessagesRead :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> Bool
    -> List String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, List MessageRead )
markMessagesRead accountsPanelModel maybeAccountServer unread messageIds =
    performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.markMessagesRead { defaultMarkMessagesReadRequest | messageIds = messageIds, unread = unread }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )
        |> Task.map (Tuple.mapSecond .messageReads)


{-| `message.createdAt`, in epoch milliseconds -- what `groupMessages` sorts
by, and what `Components.Pages.MessagesPage` sorts an expanded group's own
messages by too. `0` (the epoch -- always sorts last) for the
never-actually-happens case of a missing `createdAt`, same fallback
convention as this codebase's other optional-timestamp sorts.
-}
messageMillis : Message -> Int
messageMillis message =
    message.createdAt
        |> Maybe.map (timestampToPosix >> Time.posixToMillis)
        |> Maybe.withDefault 0


{-| The inverse of `groupRouteId`: `raw` is either a bare group id (a group on
`mainFrontendHost`) or `id@host` (a group on some other, federated-in-account
server) -- mirrors `Components.Users.parseUserRouteId`/
`Components.Posts.parsePostRouteId`.
-}
parseGroupRouteId : String -> String -> ( String, String )
parseGroupRouteId mainFrontendHost raw =
    case String.split "@" raw of
        [ id, host ] ->
            ( id, host )

        _ ->
            ( raw, mainFrontendHost )


{-| The `?messaging_group=` value for a group on `groupHost` -- mirrors
`Components.Users`' own (private) `withHostSuffix`.
-}
groupRouteId : String -> String -> String -> String
groupRouteId mainFrontendHost groupHost groupId =
    if groupHost == mainFrontendHost then
        groupId

    else
        groupId ++ "@" ++ groupHost
