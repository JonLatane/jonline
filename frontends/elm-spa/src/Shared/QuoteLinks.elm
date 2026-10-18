module Shared.QuoteLinks exposing
    ( Entry(..)
    , Model
    , Msg(..)
    , Plan(..)
    , World
    , advance
    , eventOf
    , entryFor
    , init
    , plan
    , receive
    , receiveEvent
    , request
    , settle
    , wantsEvent
    , unrequested
    , update
    )

{-| The app-wide cache behind post quotes: a Rellm `POST`'s `link`, when it points at a post/event on some
Rellm server (`Shared.Federation.RellmLinks`), is fetched here and shown embedded in the quoting post's card
and page (`Components.QuotedLink`). Keyed by `RellmLinks.key` -- `host|id` -- so a post quoted by a hundred
cards is fetched once, however each of them spelled the link.

Which servers this will talk to, and how, follows the app's existing conventions rather than inventing new
ones:

  - A server the user has added and enabled (`AccountsPanel.Model.servers`) is fetched from like any other
    Rellm read -- authenticated as the account enabled for it, if any (`Components.Posts.fetchPost`).
  - A server the user hasn't added gets the same preview connection the recommended-servers strip and the
    Add/Enable prompts use (`AccountsPanel.EnsureServerPreviews`, cached in
    `recommendedServerConnections`, which also loads its logo and name) -- and a quote of one of its posts
    is then fetched anonymously, so you can embed a post from any server in a post on any other.
  - A host whose preview connection failed (`AccountsPanel.Model.nonRellmHosts`) isn't a Rellm server as far
    as we can tell, so nothing is embedded and it isn't asked again -- see `plan`.
  - A server the user added but disabled isn't contacted at all (see `Components.ServerDependentView`, which
    `Components.QuotedLink` shows the usual "Enable" prompt through).

A fetched post whose `PostContext` is `EVENT` or `OCCASION` gets a `GetEvents` follow-up (`wantsEvent`), and
is shown as an event card (`LoadedEvent`) rather than a plain post card -- whichever link shape named it.

Hosts that merely _appear in a link_ are only probed when they look like a public domain name
(`RellmLinks.isProbeableHost`) -- see that function for why.

-}

import Components.Events as Events
import Components.Posts as Posts
import Dict exposing (Dict)
import Grpc
import Proto.Rellm exposing (Event, GetEventsResponse, GetPostsResponse, Occasion, Post, defaultGetEventsRequest, defaultGetPostsRequest)
import Proto.Rellm.PostContext exposing (PostContext(..))
import Proto.Rellm.Rellm as Rellm
import Set exposing (Set)
import Shared.AccountsPanel as AccountsPanel
import Shared.AccountsPanel.RellmAccounts as RellmAccounts
import Shared.AccountsPanel.RellmServers as RellmServers exposing (RellmServer)
import Shared.Federation.RellmLinks as RellmLinks exposing (Target)
import Task exposing (Task)


type alias Model =
    { entries : Dict String Entry
    }


{-| Where one `Target` stands. `Awaiting` is "can't fetch it yet, but might be able to": its server's
preview hasn't loaded, or the server is known but disabled/not yet connected -- `advance` re-plans it
whenever the accounts change. `Unavailable` is final for the session (a post you can't see, a deleted one, a
host that isn't a Rellm server, a failed fetch).
-}
type Entry
    = Awaiting Target
    | Loading
    | Loaded Post
      -- A link to an event: the `Event` and the `Occasion` the link names (or its first one), rendered as
      -- an event card. See `wantsEvent`.
    | LoadedEvent Event Occasion
    | Unavailable


init : Model
init =
    { entries = Dict.empty }


type Msg
    = -- `( postServerHost, link )` of every quoting post a page is showing -- see `unrequested` for how a
      -- page avoids sending the ones already known.
      RequestLinks (List ( String, String ))
      -- A quote whose post the sender already has in hand (the quote button on a post's own page): the
      -- server's `frontendHost` and the post.
    | Provide String Post
    | GotPost Target (Result Grpc.Error ( Maybe AccountsPanel.Msg, GetPostsResponse ))
      -- The follow-up fetch for a post that turned out to be an event/occasion (`wantsEvent`); the post
      -- stands in if it fails.
    | GotEvent Target Post (Result Grpc.Error ( Maybe AccountsPanel.Msg, GetEventsResponse ))


{-| What to do about one target right now. Pure -- see `World` -- so every branch of the server-selection
logic is testable on its own.
-}
type Plan
    = Fetch
    | Wait
    | GiveUp


{-| The only parts of `AccountsPanel.Model` the decisions here depend on: `servers` the user added,
`previews` (its `recommendedServerConnections`) and `nonRellmHosts`.
-}
type alias World =
    { servers : List RellmServer
    , previews : Dict String RellmServer
    , nonRellmHosts : Set String
    }


worldOf : AccountsPanel.Model -> World
worldOf accounts =
    { servers = accounts.servers
    , previews = accounts.recommendedServerConnections
    , nonRellmHosts = accounts.nonRellmHosts
    }


{-| What to do about `target`:

  - A server the user added: `Fetch` once it's enabled and connected, otherwise `Wait` (it may yet be enabled
    or connected -- `settle` re-plans).
  - Otherwise, a host known not to be Rellm: `GiveUp`. One with a connected preview: `Fetch` (anonymously).
    One that isn't safe to probe (`RellmLinks.isProbeableHost`): `GiveUp`. Anything else needs its preview
    first: `Wait`.

-}
plan : World -> Target -> Plan
plan world target =
    case RellmServers.rellmServerForHost world.servers target.host of
        Just known ->
            if known.enabled && known.connected /= Nothing then
                Fetch

            else
                Wait

        Nothing ->
            if Set.member target.host world.nonRellmHosts then
                GiveUp

            else if (Dict.get target.host world.previews |> Maybe.andThen .connected) /= Nothing then
                Fetch

            else if RellmLinks.isProbeableHost target.host then
                Wait

            else
                GiveUp


entryFor : Model -> Target -> Maybe Entry
entryFor model target =
    Dict.get (RellmLinks.key target) model.entries


{-| Of `( postServerHost, link )` pairs, the ones that parse to a target this cache hasn't seen -- so a page
only sends `RequestLinks` (and so only wakes `Shared.update`) when there's actually something new.
-}
unrequested : Model -> List ( String, String ) -> List ( String, String )
unrequested model pairs =
    pairs
        |> List.filter
            (\( postServerHost, link ) ->
                case RellmLinks.parse postServerHost link of
                    Just target ->
                        not (Dict.member (RellmLinks.key target) model.entries)

                    Nothing ->
                        False
            )


{-| `RequestLinks`, minus the effects: records an entry for every new target in `pairs` and says what has to
happen next -- which targets to fetch now, and which hosts need a preview connection first. Targets already
known are left alone.
-}
request : World -> List ( String, String ) -> Model -> { model : Model, fetch : List Target, previewHosts : List String }
request world pairs model =
    let
        targets : List Target
        targets =
            pairs
                |> List.filterMap (\( postServerHost, link ) -> RellmLinks.parse postServerHost link)
                |> dedupe
                |> List.filter (\target -> not (Dict.member (RellmLinks.key target) model.entries))

        step : Target -> { entries : Dict String Entry, fetch : List Target, previewHosts : List String } -> { entries : Dict String Entry, fetch : List Target, previewHosts : List String }
        step target acc =
            case plan world target of
                Fetch ->
                    { acc | entries = Dict.insert (RellmLinks.key target) Loading acc.entries, fetch = acc.fetch ++ [ target ] }

                Wait ->
                    { acc
                        | entries = Dict.insert (RellmLinks.key target) (Awaiting target) acc.entries
                        , previewHosts =
                            if RellmServers.rellmServerForHost world.servers target.host == Nothing && not (List.member target.host acc.previewHosts) then
                                acc.previewHosts ++ [ target.host ]

                            else
                                acc.previewHosts
                    }

                GiveUp ->
                    { acc | entries = Dict.insert (RellmLinks.key target) Unavailable acc.entries }

        result : { entries : Dict String Entry, fetch : List Target, previewHosts : List String }
        result =
            List.foldl step { entries = model.entries, fetch = [], previewHosts = [] } targets
    in
    { model = { model | entries = result.entries }, fetch = result.fetch, previewHosts = result.previewHosts }


{-| Re-plans every `Awaiting` entry against `world` -- what `advance` runs after every message, since what
unblocks one (a preview connection landing, a server being added or enabled) happens in `AccountsPanel`.
Returns the targets to fetch now.
-}
settle : World -> Model -> { model : Model, fetch : List Target }
settle world model =
    let
        step : ( String, Entry ) -> { entries : Dict String Entry, fetch : List Target } -> { entries : Dict String Entry, fetch : List Target }
        step ( entryKey, entry ) acc =
            case entry of
                Awaiting target ->
                    case plan world target of
                        Fetch ->
                            { acc | entries = Dict.insert entryKey Loading acc.entries, fetch = acc.fetch ++ [ target ] }

                        Wait ->
                            acc

                        GiveUp ->
                            { acc | entries = Dict.insert entryKey Unavailable acc.entries }

                _ ->
                    acc

        result : { entries : Dict String Entry, fetch : List Target }
        result =
            List.foldl step { entries = model.entries, fetch = [] } (Dict.toList model.entries)
    in
    { model = { model | entries = result.entries }, fetch = result.fetch }


{-| A fetch's outcome: the post (`Loaded`), or `Unavailable` if there's none -- a post the viewer can't see
reads the same as a deleted one -- or the fetch failed.
-}
receive : String -> Maybe Post -> Model -> Model
receive entryKey maybePost model =
    { model
        | entries =
            Dict.insert entryKey
                (case maybePost of
                    Just post ->
                        Loaded post

                    Nothing ->
                        Unavailable
                )
                model.entries
    }


{-| Whether a fetched post is an event's (or one of its occasions') own `Post` -- every link shape fetches with
`GetPosts` first, since a `/~id` link doesn't say what it points at, and an event then needs `GetEvents` for
its occasions to be shown as an event card.
-}
wantsEvent : Post -> Bool
wantsEvent post =
    post.context == EVENT || post.context == OCCASION


{-| The `Event` and `Occasion` to show for a fetched event `post`: the occasion `post` is (an `OCCASION`
link), or the event's first one. `Nothing` if `event` has no such occasion.
-}
eventOf : Post -> Event -> Maybe ( Event, Occasion )
eventOf post event =
    (if post.context == OCCASION then
        Events.findOccasion post.id event

     else
        List.head event.occasions
    )
        |> Maybe.map (\occasion -> ( event, occasion ))


{-| `GetEvents`' outcome for `post`: an event card if there's an occasion to show, else the plain post.
-}
receiveEvent : String -> Post -> Maybe Event -> Model -> Model
receiveEvent entryKey post maybeEvent model =
    { model
        | entries =
            Dict.insert entryKey
                (case maybeEvent |> Maybe.andThen (eventOf post) of
                    Just ( event, occasion ) ->
                        LoadedEvent event occasion

                    Nothing ->
                        Loaded post
                )
                model.entries
    }


{-| The third part of the result is the `AccountsPanel` messages this needs sent on its behalf:
`EnsureServerPreviews` for hosts with no connection yet, and any token refresh a fetch ended up doing.
-}
update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, List AccountsPanel.Msg )
update accounts msg model =
    case msg of
        RequestLinks pairs ->
            let
                result : { model : Model, fetch : List Target, previewHosts : List String }
                result =
                    request (worldOf accounts) pairs model

            in
            ( result.model
            , Cmd.batch (List.map (fetchCmd accounts) result.fetch)
            , if List.isEmpty result.previewHosts then
                []

              else
                [ AccountsPanel.EnsureServerPreviews result.previewHosts ]
            )

        Provide host post ->
            let
                target : Target
                target =
                    { host = host, id = post.id }
            in
            if wantsEvent post then
                -- An event's own page only has the `Post`; its occasions still have to be fetched.
                ( { model | entries = Dict.insert (RellmLinks.key target) Loading model.entries }
                , fetchEventCmd accounts target post
                , []
                )

            else
                ( receive (RellmLinks.key target) (Just post) model, Cmd.none, [] )

        GotPost target result ->
            case result of
                Ok ( maybeAccountsPanelMsg, response ) ->
                    let
                        accountsMsgs : List AccountsPanel.Msg
                        accountsMsgs =
                            maybeAccountsPanelMsg |> Maybe.map List.singleton |> Maybe.withDefault []
                    in
                    case List.head response.posts of
                        Just post ->
                            if wantsEvent post then
                                ( model, fetchEventCmd accounts target post, accountsMsgs )

                            else
                                ( receive (RellmLinks.key target) (Just post) model, Cmd.none, accountsMsgs )

                        Nothing ->
                            ( receive (RellmLinks.key target) Nothing model, Cmd.none, accountsMsgs )

                Err _ ->
                    ( receive (RellmLinks.key target) Nothing model, Cmd.none, [] )

        GotEvent target post result ->
            case result of
                Ok ( maybeAccountsPanelMsg, response ) ->
                    ( receiveEvent (RellmLinks.key target) post (List.head response.events) model
                    , Cmd.none
                    , maybeAccountsPanelMsg |> Maybe.map List.singleton |> Maybe.withDefault []
                    )

                Err _ ->
                    ( receiveEvent (RellmLinks.key target) post Nothing model, Cmd.none, [] )


{-| `settle`, with the fetches started -- run by `Shared.update` after every message, like its other "try again
now" hooks. Cheap when nothing's waiting.
-}
advance : AccountsPanel.Model -> Model -> ( Model, Cmd Msg )
advance accounts model =
    let
        result : { model : Model, fetch : List Target }
        result =
            settle (worldOf accounts) model
    in
    ( result.model, Cmd.batch (List.map (fetchCmd accounts) result.fetch) )


dedupe : List Target -> List Target
dedupe targets =
    List.foldl
        (\target acc ->
            if List.any (\seen -> RellmLinks.key seen == RellmLinks.key target) acc then
                acc

            else
                acc ++ [ target ]
        )
        []
        targets


fetchCmd : AccountsPanel.Model -> Target -> Cmd Msg
fetchCmd accounts target =
    fetchTask accounts target
        |> Task.attempt (GotPost target)


fetchEventCmd : AccountsPanel.Model -> Target -> Post -> Cmd Msg
fetchEventCmd accounts target post =
    fetchEventTask accounts target post.id
        |> Task.attempt (GotEvent target post)


{-| A server the user added is read like any other (authenticated as its enabled account, if any, with the
usual token-refresh handling); one only we have a preview connection for is read anonymously, straight off
that connection -- a public `GetPosts`, so a post only an account could see simply comes back not found.
-}
fetchTask : AccountsPanel.Model -> Target -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetPostsResponse )
fetchTask accounts target =
    case RellmServers.knownConnectedRellmServer accounts.servers target.host of
        Just _ ->
            Posts.fetchPost accounts
                ( RellmAccounts.enabledRellmAccountForServer accounts.accounts target.host |> Maybe.map .userId, target.host )
                target.id

        Nothing ->
            case Dict.get target.host accounts.recommendedServerConnections |> Maybe.andThen (\server -> Maybe.map (\_ -> server) server.connected) of
                Just previewServer ->
                    Grpc.new Rellm.getPosts { defaultGetPostsRequest | postId = Just target.id }
                        |> Grpc.setHost (RellmServers.rellmServerUrl previewServer)
                        |> Grpc.setTimeout 10000
                        |> Grpc.toTask
                        |> Task.map (\response -> ( Nothing, response ))

                Nothing ->
                    Task.fail Grpc.NetworkError


{-| `fetchTask`, for `GetEvents` -- the event (all its occasions) behind a fetched event/occasion post.
-}
fetchEventTask : AccountsPanel.Model -> Target -> String -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetEventsResponse )
fetchEventTask accounts target postId =
    case RellmServers.knownConnectedRellmServer accounts.servers target.host of
        Just _ ->
            Events.fetchEvent accounts
                ( RellmAccounts.enabledRellmAccountForServer accounts.accounts target.host |> Maybe.map .userId, target.host )
                Nothing
                postId

        Nothing ->
            case Dict.get target.host accounts.recommendedServerConnections |> Maybe.andThen (\server -> Maybe.map (\_ -> server) server.connected) of
                Just previewServer ->
                    Grpc.new Rellm.getEvents { defaultGetEventsRequest | postId = Just postId }
                        |> Grpc.setHost (RellmServers.rellmServerUrl previewServer)
                        |> Grpc.setTimeout 10000
                        |> Grpc.toTask
                        |> Task.map (\response -> ( Nothing, response ))

                Nothing ->
                    Task.fail Grpc.NetworkError
