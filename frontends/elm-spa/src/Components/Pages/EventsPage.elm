module Components.Pages.EventsPage exposing
    ( EventsDisplayMode(..)
    , Model
    , Msg
    , fromShared
    , init
    , subscriptions
    , update
    , view
    )

{-| The shared guts of an "upcoming events" page: fetching upcoming
`EventInstance`s from every enabled server and rendering them with fade
in/out animations -- mirrors `Components.Pages.PostsPage` almost exactly
(`ServerFeed`/`fetchNewServers`/`refetchServers`/`syncAnimations`/
`setBreadcrumbsRoot` all follow the same shape, just over
`(Event, EventInstance)` pairs instead of `Post`s), reused by `Pages.Events`
(which passes `author = Nothing`) and `Pages.Username_.Events`/
`Pages.User.UserId_.Events` (which pass the already-resolved profile `User`,
restricting the feed to that user's own events), same as `PostsPage` is
reused by `Pages.Home_`/`Pages.Username_.Posts`/`Pages.User.UserId_.Posts`.

The one real departure from `PostsPage`: this listing is itself centered on
the `EventInstance` (every `Event` can have many, see `Components.Events`'
own module doc), and it supports three interchangeable layouts
(`EventsDisplayMode`) with a smooth FLIP-animated transition _between_
layouts, not just item enter/exit -- `VerticalList`'s cards are full-width
(mirrors `PostsPage`'s own `.post-card`), `Grid`/`HorizontalList`'s are a
fixed tile width (see `events.css`), so a layout switch is a genuine
position-_and_-resize, not just a reflow. That transition reuses `UI.Flip`'s
`MoveState`/`startMoveScaled`/`moveAttributes` machinery (`startMove`'s
scaled sibling, added alongside it for exactly this) -- see
`DisplayModeChanged`'s handling below for the actual "measure old
position/size, switch layout, measure new position/size, animate the
difference away" FLIP recipe.

-}

import Animation
import Browser.Dom as Dom
import Browser.Navigation
import Components.Events as Events
import Components.Pages.UserProfilePage as UserProfilePage
import Components.Users exposing (usernameHref)
import Dict exposing (Dict)
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, a, button, div, h2, input, p, text)
import Html.Attributes exposing (class, href, id, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Keyed
import Json.Decode as Decode
import Json.Encode as Encode
import Ports
import Process
import Proto.Jonline exposing (Event, EventInstance, User)
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.Breadcrumbs as Breadcrumbs
import Shared.BrowserTimeZone as BrowserTimeZone
import Shared.Conversions as Conversions
import Shared.MediaViewerPanel as MediaViewerPanel
import Task
import Time
import UI.Classes exposing (classes, hostnameToCSSClass)
import UI.Flip
import Url.Builder



-- MODEL


{-| The three interchangeable layouts `eventsListView` can render its cards
in -- `VerticalList` (the default, a single full-width column, mirroring
`PostsPage.postsListView`'s `.flip-animated-column`), `Grid` (a wrapping
fixed-tile-width grid, reusing `flip.css`'s existing `.flip-animated-grid`,
built for `Shared.MyMediaPanel`'s media tiles), and `HorizontalList` (a
single horizontally-scrolling row of that same fixed tile width, mirroring
`Pages.Event.EventId_`'s own date-picker strip). `Grid`/`HorizontalList`
share one card size, but `VerticalList`'s is genuinely different (full-width
vs. a fixed tile), so switching to/from it is a position-_and_-resize FLIP,
not just a reflow -- see `DisplayModeChanged`.
-}
type EventsDisplayMode
    = HorizontalList
    | VerticalList
    | Grid


type ServerEvents
    = Loading
    | Loaded (List ( Event, EventInstance ))
    | Failed


{-| `accountId` is the enabled account (if any) the events were/are being
fetched with, so a later account enable/disable on the same server can be
detected as "the acting credential changed" and trigger a re-fetch -- mirrors
`Components.Pages.PostsPage.ServerFeed` exactly.
-}
type alias ServerFeed =
    { status : ServerEvents
    , accountId : Maybe String
    }


{-| One card's fade in/out state (`flip`, keyed in `eventAnimations` by
`eventAnimationKey` so it survives independently of `eventsByServer` -- see
`Components.Pages.PostsPage.PostAnimation` for why) plus its move-slide state
(`move`) for `DisplayModeChanged`'s layout-switch animation -- kept as a
_separate_ `UI.Flip.MoveState` (rather than folded into `flip`) so the two
never fight over the same node's `transform` style: `flip`'s opacity/scale
renders on this card's outer wrapper (see `eventAnimationView`), `move`'s
translate renders on a nested inner one.
-}
type alias EventAnimation =
    { host : String
    , event : Event
    , instance : EventInstance
    , flip : UI.Flip.State Msg
    , move : UI.Flip.MoveState Msg
    }


type alias Model =
    { eventsByServer : Dict String ServerFeed
    , eventAnimations : Dict String EventAnimation
    , mode : EventsDisplayMode
    , measurementPhase : MeasurementPhase
    , author : Maybe ( String, User )
    , navKey : Browser.Navigation.Key
    , path : String
    , tab : EventsTab

    -- The cutoff actually sent as `Components.Events.fetchEvents`' own
    -- `endsAfter` -- `Nothing` only ever transiently, at startup, until
    -- either the very first `GotNow` (`UpcomingEvents`) or a parsed
    -- `?ends_after=` query param (`EventsAfterDate`) resolves it, so this
    -- page never fetches at all until it has a real cutoff in hand. Fetching
    -- before that (this page used to seed a placeholder `Time.millisToPosix
    -- 0`, i.e. the UNIX epoch, so its very first request asked for events
    -- "ending after 1970") was the actual cause of very old events
    -- occasionally flashing up on first load.
    , endsAfter : Maybe Time.Posix

    -- Debounces `EndsAfterInputChanged` (500ms) -- mirrors
    -- `PostsPage.Model.searchGeneration`/`SearchDebounceElapsed` exactly,
    -- just for the date input instead of the search box: bumped on every
    -- keystroke/picker tick, so a `EndsAfterDebounceElapsed` timer that
    -- fires after a later edit already moved this past it knows to ignore
    -- itself as stale.
    , endsAfterInputGeneration : Int
    }


{-| Which of `tabsView`'s two tabs is active -- `UpcomingEvents` (the
default) filters by the live current time, refreshed on every `Poll` (see
its own handling below); `EventsAfterDate` filters by a fixed, user-picked
cutoff (`model.endsAfter`), editable via its own `<input type="datetime-local">`.
Persisted to the URL as an `ends_after` query param (see `queryParams`) --
its mere presence/absence on load is what `init` uses to decide which tab to
start on.
-}
type EventsTab
    = UpcomingEvents
    | EventsAfterDate


{-| Which half of `DisplayModeChanged`'s FLIP measurement round-trip (if any)
`GotMeasuredRects` is currently waiting on -- unlike the old `Task.attempt`-based
version (which baked this into the `Msg` itself, via `GotPreModeMeasurements
newMode`/`GotPostModeMeasurements oldRects`'s own arguments), a port's
incoming `Sub` is a single, untargeted `Msg`, so there's nothing to pattern
match on except state carried in the `Model` -- this is that state. See
`measureElementsEffect`/`Ports.measureElements`'s own doc for why a port
(rather than `Browser.Dom.getElement`) measures at all.
-}
type MeasurementPhase
    = NotMeasuring
    | AwaitingOldRects EventsDisplayMode
    | AwaitingNewRects EventsDisplayMode (Dict String Rect)


{-| `author`, if given, restricts the feed to that user's own events (see
`Components.Events.fetchEvents`) and adds an "Events | &lt;name&gt;" heading
(see `authorHeadingView`) -- `Pages.Events` passes `Nothing`,
`Pages.Username_.Events`/`Pages.User.UserId_.Events` pass their
already-resolved profile `User` paired with the host it was resolved from --
mirrors `Components.Pages.PostsPage.init`'s own `author` param exactly,
including `navKey`/`path` (this module's own URL persistence, see
`pushUrl`, needs the same thing `PostsPage`'s search persistence does) and
`query` (seeding `mode` back out of a `?display=` param, and `tab`/`endsAfter`
back out of a `?ends_after=` one, on load).

A parseable `?ends_after=` starts on the `EventsAfterDate` tab with that
exact cutoff -- already resolved, so this fetches right away, no need to
wait on anything. Without one, this starts on `UpcomingEvents` with
`endsAfter = Nothing` -- deliberately not yet fetching at all (see
`refetchServers`'s own guard) until the `Task.perform GotNow Time.now`
below resolves and supplies a real cutoff; see `Model.endsAfter`'s own doc
for why that matters.
-}
init : Shared.Model -> Maybe ( String, User ) -> Browser.Navigation.Key -> String -> Dict String String -> ( Model, Effect Msg )
init shared author navKey path query =
    let
        ( tab, endsAfter ) =
            case Dict.get "ends_after" query |> Maybe.andThen Conversions.posixFromIsoUtcString of
                Just customEndsAfter ->
                    ( EventsAfterDate, Just customEndsAfter )

                Nothing ->
                    ( UpcomingEvents, Nothing )

        ( fetchedModel, fetchEffect ) =
            fetchNewServers shared
                { eventsByServer = Dict.empty
                , eventAnimations = Dict.empty
                , mode = Dict.get "display" query |> Maybe.andThen displayModeFromParam |> Maybe.withDefault VerticalList
                , measurementPhase = NotMeasuring
                , author = author
                , navKey = navKey
                , path = path
                , tab = tab
                , endsAfter = endsAfter
                , endsAfterInputGeneration = 0
                }
    in
    ( fetchedModel
    , Effect.batch
        [ fetchEffect
        , setBreadcrumbsRoot shared fetchedModel
        , Task.perform GotNow Time.now |> Effect.fromCmd
        ]
    )


{-| Mirrors `Components.Pages.PostsPage.relevantServers` exactly: every
enabled server for an unfiltered feed (`Pages.Events`), or just `author`'s own
resolved host once there is one (`Pages.Username_.Events`/
`Pages.User.UserId_.Events`).
-}
relevantServers : Shared.Model -> Model -> List AccountsPanel.Server
relevantServers shared model =
    case model.author of
        Just ( host, _ ) ->
            AccountsPanel.serverForHost shared.accountsPanel.servers host
                |> Maybe.map List.singleton
                |> Maybe.withDefault []

        Nothing ->
            AccountsPanel.enabledServers shared.accountsPanel


{-| The `GetEvents` fetch (as an `Effect`, ready to batch/return directly)
for one `server`, using `endsAfter` (the already-unwrapped `model.endsAfter`
-- see `refetchServers`'s own guard for why this never runs while that's
still `Nothing`) -- mirrors `Components.Pages.PostsPage.refetchServers`'s
inline `fetchEffect`, just factored out since `GotNow` also needs to kick
every relevant server's fetch off again once a real cutoff lands.
-}
fetchServerEffect : Shared.Model -> Model -> Time.Posix -> AccountsPanel.Server -> Effect Msg
fetchServerEffect shared model endsAfter server =
    Events.fetchEvents
        shared.accountsPanel
        ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost |> Maybe.map .userId
        , server.frontendHost
        )
        (model.author |> Maybe.map (Tuple.second >> .id))
        endsAfter
        |> Task.attempt (GotServerEvents server.frontendHost)
        |> Effect.fromCmd


{-| Mirrors `Components.Pages.PostsPage.refetchServers` exactly: fetches
`serversToFetch` (marking each `Loading` first), and drops any already-fetched
server that's no longer `relevantServers`. A no-op (nothing marked `Loading`,
no fetch fired) while `model.endsAfter` is still `Nothing` -- see its own doc
comment for why this page must never fetch before that's resolved.
-}
refetchServers : Shared.Model -> Model -> List AccountsPanel.Server -> ( Model, Effect Msg )
refetchServers shared model serversToFetch =
    case model.endsAfter of
        Nothing ->
            ( model, Effect.none )

        Just endsAfter ->
            let
                enabledServers =
                    relevantServers shared model

                currentAccountId server =
                    AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost
                        |> Maybe.map AccountsPanel.accountId

                prunedEventsByServer =
                    Dict.filter (\host _ -> List.member host (List.map .frontendHost enabledServers)) model.eventsByServer
            in
            ( { model
                | eventsByServer =
                    List.foldl
                        (\server -> Dict.insert server.frontendHost { status = Loading, accountId = currentAccountId server })
                        prunedEventsByServer
                        serversToFetch
              }
            , Effect.batch (List.map (fetchServerEffect shared model endsAfter) serversToFetch)
            )
                |> Tuple.mapFirst syncAnimations


{-| Mirrors `Components.Pages.PostsPage.fetchNewServers` exactly: same
drop-stale-servers/re-fetch-on-account-change/poll-fallback approach, just
against `GetEvents` instead of `GetPosts`.
-}
fetchNewServers : Shared.Model -> Model -> ( Model, Effect Msg )
fetchNewServers shared model =
    let
        currentAccountId server =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost
                |> Maybe.map AccountsPanel.accountId

        serversToFetch =
            relevantServers shared model
                |> List.filter
                    (\server ->
                        case Dict.get server.frontendHost model.eventsByServer of
                            Nothing ->
                                True

                            Just feed ->
                                feed.accountId /= currentAccountId server
                    )
    in
    refetchServers shared model serversToFetch


{-| Mirrors `Components.Pages.PostsPage.setBreadcrumbsRoot` exactly, keyed
off this feed's own `author`.
-}
setBreadcrumbsRoot : Shared.Model -> Model -> Effect Msg
setBreadcrumbsRoot shared model =
    let
        ( root, host ) =
            case model.author of
                Just ( authorHost, user ) ->
                    ( Breadcrumbs.FromUser user, authorHost )

                Nothing ->
                    ( Breadcrumbs.FromServerHost shared.accountsPanel.mainFrontendHost, shared.accountsPanel.mainFrontendHost )
    in
    if shared.breadcrumbs.root == Just root then
        Effect.none

    else
        Effect.fromShared (Shared.BreadcrumbsMsg (Breadcrumbs.SetRoot root host []))



-- ANIMATION


{-| Identifies one `(host, EventInstance)` pair independently of which server
fetched it, for `eventAnimations` -- also used verbatim (prefixed) as the
card's DOM `id`, so `DisplayModeChanged`'s FLIP measurement can look the same
element back up after a layout switch. Mirrors `PostsPage.postAnimationKey`,
just keyed on `EventInstance.id` (this listing's own unit, see the module
doc) rather than `Post.id`.
-}
eventAnimationKey : String -> EventInstance -> String
eventAnimationKey host instance =
    host ++ "@" ++ instance.id


eventCardDomId : String -> String
eventCardDomId key =
    "event-card-" ++ key


{-| Reconciles `eventAnimations` with the `(Event, EventInstance)` pairs
currently `Loaded` in `eventsByServer` -- mirrors
`Components.Pages.PostsPage.syncAnimations` exactly (starts a fade-in for
newly-seen instances, a fade-out for ones that dropped out, leaves `move`
alone either way -- a content refresh never needs a position slide, only
`DisplayModeChanged` does).
-}
syncAnimations : Model -> Model
syncAnimations model =
    let
        currentEvents : Dict String ( String, Event, EventInstance )
        currentEvents =
            model.eventsByServer
                |> Dict.toList
                |> List.concatMap
                    (\( host, feed ) ->
                        case feed.status of
                            Loaded pairs ->
                                List.map (\( event, instance ) -> ( eventAnimationKey host instance, ( host, event, instance ) )) pairs

                            _ ->
                                []
                    )
                |> Dict.fromList
    in
    { model
        | eventAnimations =
            UI.Flip.syncAnimations
                RemoveEvent
                (\( host, event, instance ) -> { host = host, event = event, instance = instance, flip = UI.Flip.enter, move = UI.Flip.atRestScaled })
                (\( host, event, instance ) anim -> { anim | host = host, event = event, instance = instance })
                currentEvents
                model.eventAnimations
    }


{-| The most events `eventsListView` ever renders (and the only ones
`DisplayModeChanged` ever measures/animates) -- a long recurring `Event` can
rack up hundreds of future instances (`Pages.Event.EventId_` has the same
concern for its own date-picker strip), and rendering/measuring/sliding all
of them at once on every mode switch is both wasteful and, empirically, the
reason a switch into `HorizontalList` could visibly "glitch" -- a card whose
FLIP invert-offset was large (e.g. one that used to sit far down a long
`VerticalList` column) spent most of its slide clipped out of view by
`.events-strip`'s own `overflow-y: hidden` (see `events.css`), so only the
tail end of its animation, once back within the strip's bounds, was ever
visible. Capping the working set keeps every card's invert-offset small
enough that this is far less likely to matter in practice, on top of just
being less to measure/animate.
-}
maxDisplayedEvents : Int
maxDisplayedEvents =
    20


{-| `model.eventAnimations`, soonest-first (mirrors `PostsPage.postsListView`'s
own per-item sort key), truncated to `maxDisplayedEvents` -- both
`eventsListView`'s rendering and `DisplayModeChanged`'s FLIP measurement work
from this exact same list, so a card excluded here is never measured or
animated either.
-}
visibleAnimations : Model -> List ( String, EventAnimation )
visibleAnimations model =
    model.eventAnimations
        |> Dict.toList
        |> List.sortBy
            (\( _, anim ) ->
                Events.instanceMoment anim.instance
                    |> Maybe.withDefault (Time.millisToPosix 0)
                    |> Time.posixToMillis
            )
        |> List.take maxDisplayedEvents


{-| A card's measured position/size (page coordinates, matching
`Browser.Dom.Element.element`'s own convention) -- the "First"/"Last"
measurement step of FLIP, used both before and after `DisplayModeChanged`
switches `model.mode` (see that branch's own doc for the full recipe).
Deliberately not `Browser.Dom.Element` itself: that type carries `scene`/
`viewport` fields this module never needs, and (more importantly) is what
`Ports.measureElements` exists to avoid depending on `Browser.Dom.getElement`
for at all -- see that port's own doc comment.
-}
type alias Rect =
    { x : Float
    , y : Float
    , width : Float
    , height : Float
    }


{-| Decodes `Ports.elementsMeasured`'s payload -- keyed by each entry's own
`key` field (see that port's own doc comment: deliberately _not_ the DOM
`id`, so this dict's keys always match `model.eventAnimations`' own keys
directly, with no reverse-derivation needed).
-}
rectsDecoder : Decode.Decoder (Dict String Rect)
rectsDecoder =
    Decode.map2 Tuple.pair
        (Decode.field "key" Decode.string)
        (Decode.map4 Rect
            (Decode.field "x" Decode.float)
            (Decode.field "y" Decode.float)
            (Decode.field "width" Decode.float)
            (Decode.field "height" Decode.float)
        )
        |> Decode.list
        |> Decode.map Dict.fromList


{-| Fires off `Ports.measureElements` for every one of `keys`' cards --
sending each as a `{ key, id }` pair (`id` via `eventCardDomId`) so
`rectsDecoder`'s result comes back keyed the same way `keys` itself already
is. See that port's own doc for why this replaces a `Task.sequence` over
`Browser.Dom.getElement` calls.
-}
measureElementsEffect : List String -> Effect Msg
measureElementsEffect keys =
    keys
        |> Encode.list
            (\key ->
                Encode.object
                    [ ( "key", Encode.string key )
                    , ( "id", Encode.string (eventCardDomId key) )
                    ]
            )
        |> Ports.measureElements
        |> Effect.fromCmd



-- UPDATE


type Msg
    = GotServerEvents String (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetEventsResponse ))
    | GotNow Time.Posix
    | Poll
    | Animate Animation.Msg
    | AnimateMove Animation.Msg
    | RemoveEvent String
    | MoveSettled String
    | SharedMsg Shared.Msg
      -- Switches `model.mode` -- see this branch's own handling below for
      -- the FLIP "measure old positions, switch, measure new positions,
      -- animate the difference away" recipe.
    | DisplayModeChanged EventsDisplayMode
      -- `Ports.elementsMeasured` firing -- which half of the FLIP round-trip
      -- this is (if any) is read off `model.measurementPhase`, not this
      -- `Msg`'s own (untargeted, port-delivered) payload. A payload that
      -- fails to decode is treated the same as `measurementPhase` already
      -- being `NotMeasuring` -- give up silently, same fallback
      -- `EventId_.scrollToInstance` already relies on for its own
      -- `Dom`-adjacent calls.
    | GotMeasuredRects Decode.Value
      -- One deliberate `requestAnimationFrame` wait (via a throwaway
      -- `Browser.Dom.getViewport` task -- see this branch's own handling
      -- below for why) between the mode switch actually landing in the
      -- model and firing the *second* `measureElementsEffect` -- Elm's own
      -- `Browser.application` runtime (`_Browser_makeAnimator` in the
      -- compiled output) defers painting a model change to the *next* rAF
      -- rather than doing it synchronously when `update` returns, so
      -- measuring immediately (as a first cut of this port-based rewrite
      -- did) could race ahead of the DOM actually having the new mode's
      -- classes applied yet -- silently measuring the *old* layout twice
      -- and animating a zero delta, which read as "no animation at all"
      -- (confirmed live: barely any `AnimateMove` ticks, `MoveSettled`
      -- firing almost immediately). This costs exactly one frame,
      -- regardless of how many cards there are -- nothing like the
      -- original N-frames-per-element `Browser.Dom.getElement` bug this
      -- whole port replaced.
    | ReadyToMeasureNew
      -- Switches `model.tab` -- a no-op if already active. Mirrors
      -- `DisplayModeChanged` in spirit but needs none of its FLIP
      -- machinery: there's no shared layout to slide between, just a
      -- different fetch cutoff, so this just updates `model.tab`/refetches/
      -- persists the URL directly. See `tabsView`.
    | TabChanged EventsTab
      -- The `EventsAfterDate` tab's `<input type="datetime-local">` firing
      -- -- parsed via `Shared.BrowserTimeZone.posixFromDateTimeLocalInput`;
      -- an unparseable (e.g. momentarily incomplete while typing) value is
      -- just ignored, same "give up silently" convention as everywhere
      -- else in this module. A valid one switches to that tab too (even if
      -- `UpcomingEvents` was active), per `tabsView`'s own doc. Updates
      -- `model.endsAfter` (so the input/tab reflect it immediately) but
      -- only *fetches*, debounced 500ms -- see `EndsAfterDebounceElapsed`.
    | EndsAfterInputChanged String
      -- `EndsAfterInputChanged`'s debounce timer elapsing -- mirrors
      -- `PostsPage.SearchDebounceElapsed` exactly: a no-op if a later edit
      -- already bumped `model.endsAfterInputGeneration` past this timer's
      -- own (i.e. this one's stale).
    | EndsAfterDebounceElapsed Int


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
(see `Main.notifyPageOfSharedMsg`) into `update`'s `SharedMsg` branch --
mirrors `Components.Pages.PostsPage.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


accountsPanelEffect : Maybe AccountsPanel.Msg -> Effect Msg
accountsPanelEffect maybeAccountsPanelMsg =
    maybeAccountsPanelMsg
        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
        |> Maybe.withDefault Effect.none


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    let
        ( newModel, effect ) =
            updateInner shared msg model
    in
    ( newModel, Effect.batch [ effect, setBreadcrumbsRoot shared newModel ] )


updateInner : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
updateInner shared msg model =
    case msg of
        GotServerEvents frontendHost (Ok ( maybeAccountsPanelMsg, response )) ->
            ( { model
                | eventsByServer =
                    Dict.update frontendHost
                        (Maybe.map (\feed -> { feed | status = Loaded (Events.eventInstancePairs response) }))
                        model.eventsByServer
              }
                |> syncAnimations
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotServerEvents frontendHost (Err _) ->
            ( { model
                | eventsByServer =
                    Dict.update frontendHost (Maybe.map (\feed -> { feed | status = Failed })) model.eventsByServer
              }
                |> syncAnimations
            , Effect.none
            )

        GotNow now ->
            -- Only `UpcomingEvents` ever wants the live clock -- a stale
            -- `Task.perform GotNow Time.now` still in flight from before the
            -- user switched to `EventsAfterDate` (or a fixed `?ends_after=`
            -- on load) must not clobber their fixed cutoff.
            if model.tab == UpcomingEvents then
                refetchServers shared { model | endsAfter = Just now } (relevantServers shared model)

            else
                ( model, Effect.none )

        Poll ->
            if model.tab == UpcomingEvents then
                -- Refreshes the live cutoff first (via `GotNow`, which
                -- itself refetches) rather than just re-fetching with
                -- whatever `endsAfter` was captured last -- otherwise
                -- "upcoming" would silently stop advancing after the
                -- initial load.
                ( model, Task.perform GotNow Time.now |> Effect.fromCmd )

            else
                fetchNewServers shared model

        Animate animMsg ->
            let
                step key anim ( animations, accCmds ) =
                    let
                        ( newFlip, cmd ) =
                            UI.Flip.animate animMsg anim.flip
                    in
                    ( Dict.insert key { anim | flip = newFlip } animations, cmd :: accCmds )

                ( newAnimations, cmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.eventAnimations
            in
            ( { model | eventAnimations = newAnimations }, Effect.batch (List.map Effect.fromCmd cmds) )

        AnimateMove animMsg ->
            let
                step key anim ( animations, accCmds ) =
                    let
                        ( newMove, cmd ) =
                            UI.Flip.moveAnimate animMsg anim.move
                    in
                    ( Dict.insert key { anim | move = newMove } animations, cmd :: accCmds )

                ( newAnimations, cmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.eventAnimations
            in
            ( { model | eventAnimations = newAnimations }, Effect.batch (List.map Effect.fromCmd cmds) )

        RemoveEvent key ->
            ( { model | eventAnimations = Dict.remove key model.eventAnimations }, Effect.none )

        MoveSettled key ->
            let
                newModel =
                    { model
                        | eventAnimations =
                            Dict.update key (Maybe.map (\anim -> { anim | move = { moving = False, style = anim.move.style } })) model.eventAnimations
                    }
            in
            ( newModel, pushUrlWhenIdle newModel )

        SharedMsg subMsg ->
            let
                ( fetchedModel, fetchEffect ) =
                    case subMsg of
                        Shared.AccountsPanelMsg _ ->
                            fetchNewServers shared model

                        _ ->
                            ( model, Effect.none )
            in
            ( fetchedModel, Effect.batch [ Effect.fromShared subMsg, fetchEffect ] )

        DisplayModeChanged newMode ->
            if newMode == model.mode then
                ( model, Effect.none )

            else
                ( { model | measurementPhase = AwaitingOldRects newMode }
                , measureElementsEffect (List.map Tuple.first (visibleAnimations model))
                )

        GotMeasuredRects value ->
            case Decode.decodeValue rectsDecoder value of
                Err _ ->
                    applyMeasurementFailure model

                Ok rects ->
                    case model.measurementPhase of
                        NotMeasuring ->
                            -- A stray/late result with nothing pending -- ignore.
                            ( model, Effect.none )

                        AwaitingOldRects newMode ->
                            let
                                newModel =
                                    { model | mode = newMode, measurementPhase = AwaitingNewRects newMode rects }
                            in
                            ( newModel, Task.attempt (\_ -> ReadyToMeasureNew) Dom.getViewport |> Effect.fromCmd )

                        AwaitingNewRects _ oldRects ->
                            let
                                startMoveFor key oldRect animations =
                                    case ( Dict.get key rects, Dict.get key animations ) of
                                        ( Just newRect, Just anim ) ->
                                            let
                                                delta =
                                                    ( oldRect.x - newRect.x, oldRect.y - newRect.y )

                                                scale =
                                                    ( oldRect.width / newRect.width, oldRect.height / newRect.height )
                                            in
                                            Dict.insert key { anim | move = UI.Flip.startMoveScaled (MoveSettled key) delta scale anim.move } animations

                                        _ ->
                                            animations

                                newModel =
                                    { model
                                        | eventAnimations = Dict.foldl startMoveFor model.eventAnimations oldRects
                                        , measurementPhase = NotMeasuring
                                    }
                            in
                            ( newModel, pushUrlWhenIdle newModel )

        ReadyToMeasureNew ->
            case model.measurementPhase of
                AwaitingNewRects _ oldRects ->
                    ( model, measureElementsEffect (Dict.keys oldRects) )

                _ ->
                    -- Nothing pending anymore (e.g. superseded by another
                    -- `DisplayModeChanged` in the meantime) -- nothing to do.
                    ( model, Effect.none )

        TabChanged UpcomingEvents ->
            if model.tab == UpcomingEvents then
                ( model, Effect.none )

            else
                let
                    newModel =
                        { model | tab = UpcomingEvents }
                in
                ( newModel
                , Effect.batch
                    [ Task.perform GotNow Time.now |> Effect.fromCmd
                    , pushUrl newModel
                    ]
                )

        TabChanged EventsAfterDate ->
            if model.tab == EventsAfterDate then
                ( model, Effect.none )

            else
                -- `endsAfter` itself isn't changing (this just starts the
                -- picker off wherever `UpcomingEvents`' live clock last left
                -- it) so there's nothing to refetch, just the tab/URL.
                let
                    newModel =
                        { model | tab = EventsAfterDate }
                in
                ( newModel, pushUrl newModel )

        EndsAfterInputChanged raw ->
            case BrowserTimeZone.posixFromDateTimeLocalInput shared.browserTimeZone.zone raw of
                Nothing ->
                    ( model, Effect.none )

                Just newEndsAfter ->
                    let
                        generation =
                            model.endsAfterInputGeneration + 1
                    in
                    ( { model | tab = EventsAfterDate, endsAfter = Just newEndsAfter, endsAfterInputGeneration = generation }
                    , Process.sleep 500
                        |> Task.perform (\_ -> EndsAfterDebounceElapsed generation)
                        |> Effect.fromCmd
                    )

        EndsAfterDebounceElapsed generation ->
            if generation == model.endsAfterInputGeneration then
                let
                    ( refetchedModel, refetchEffect ) =
                        refetchServers shared model (relevantServers shared model)
                in
                ( refetchedModel, Effect.batch [ refetchEffect, pushUrl refetchedModel ] )

            else
                -- A later edit already bumped `endsAfterInputGeneration`
                -- past this timer's -- it's stale, ignore it.
                ( model, Effect.none )


{-| `GotMeasuredRects`'s fallback for a payload that failed to decode (should
never actually happen -- `Ports.measureElements`'s JS side always sends a
well-formed array -- but mirrors `EventId_.GotScrollTarget (Err _)`'s "give
up silently" convention regardless): still applies a pending mode switch if
`model.measurementPhase` had one in flight, just with no slide animation,
rather than leaving the click seemingly do nothing.
-}
applyMeasurementFailure : Model -> ( Model, Effect Msg )
applyMeasurementFailure model =
    case model.measurementPhase of
        NotMeasuring ->
            ( model, Effect.none )

        AwaitingOldRects newMode ->
            let
                newModel =
                    { model | mode = newMode, measurementPhase = NotMeasuring }
            in
            ( newModel, pushUrlWhenIdle newModel )

        AwaitingNewRects _ _ ->
            let
                newModel =
                    { model | measurementPhase = NotMeasuring }
            in
            ( newModel, pushUrlWhenIdle newModel )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every 30000 (\_ -> Poll)
        , Ports.elementsMeasured GotMeasuredRects
        , UI.Flip.subscription Animate (List.map .flip (Dict.values model.eventAnimations))
        , UI.Flip.moveSubscription AnimateMove (List.map .move (Dict.values model.eventAnimations))
        ]



-- URL PERSISTENCE


{-| `grid`/`row`, sent/read as a `?display=` URL query param --
`VerticalList` (the default) round-trips to/from its absence entirely,
mirroring `PostsPage.postContextParam`'s own default-omission convention.
-}
displayModeParam : EventsDisplayMode -> String
displayModeParam mode =
    case mode of
        Grid ->
            "grid"

        HorizontalList ->
            "row"

        VerticalList ->
            "list"


{-| Case-insensitive inverse of `displayModeParam` -- mirrors
`PostsPage.postContextFromParam`.
-}
displayModeFromParam : String -> Maybe EventsDisplayMode
displayModeFromParam param =
    case String.toLower param of
        "grid" ->
            Just Grid

        "row" ->
            Just HorizontalList

        "list" ->
            Just VerticalList

        _ ->
            Nothing


{-| Every query param this page persists, read fresh off `model` -- `display`
(see `displayModeParam`) and `ends_after` (a standard `YYYY-MM-DDTHH:mm:ssZ`
UTC timestamp, via `Shared.Conversions.isoUtcString`, only while
`EventsAfterDate` is the active tab; `UpcomingEvents` -- the default -- omits
it entirely, same "round-trip to/from absence" convention `display` already
uses for its own default). Built as one combined list (rather than each
concern pushing its own `replaceUrl` independently) because
`Browser.Navigation.replaceUrl`/`Url.Builder.toQuery` replace the *whole*
query string -- two independent single-param pushes would each silently
wipe out whatever the other had just set.
-}
queryParams : Model -> List Url.Builder.QueryParameter
queryParams model =
    (if model.mode == VerticalList then
        []

     else
        [ Url.Builder.string "display" (displayModeParam model.mode) ]
    )
        ++ (case ( model.tab, model.endsAfter ) of
                ( EventsAfterDate, Just endsAfter ) ->
                    [ Url.Builder.string "ends_after" (Conversions.isoUtcString endsAfter) ]

                _ ->
                    []
           )


{-| `pushUrl`, but only once every card has actually finished its
`DisplayModeChanged` slide (`Effect.none` otherwise) -- deliberately _not_
fired the instant `model.mode` itself changes (`GotPreModeMeasurements`'s
`Ok` branch used to call this directly there), because that `replaceUrl`
call triggers `Main.elm`'s own `ChangedUrl`, which -- even though it doesn't
re-init this page for a query-only change -- still forces a full top-level
`view`/diff/patch pass. Landing that extra render in the one genuinely
vulnerable window this FLIP recipe has (after `model.mode` flips but before
`GotPostModeMeasurements` has actually applied each card's invert transform,
during which every card is still sitting at its plain, un-inverted resting
position) gave the browser an extra chance to actually paint that
in-between frame -- visible as the whole layout "glitching" to its final
position before the slide-back-into-place ever played. Deferring the URL
write until nothing is `moving` removes that extra render from the window
entirely, rather than just narrowing it. Every branch that can leave
`model.mode` changed with nothing left to animate (a failed measurement, or
a mode switch with no cards to move at all) calls this too, so the URL
still ends up correct even when there's no slide to wait on.

Tab/`endsAfter` changes have no such animation to race, so `TabChanged`/
`EndsAfterInputChanged` call `pushUrl` directly instead.
-}
pushUrlWhenIdle : Model -> Effect Msg
pushUrlWhenIdle model =
    if List.any (\anim -> anim.move.moving) (Dict.values model.eventAnimations) then
        Effect.none

    else
        pushUrl model


{-| Persists `queryParams model` to the URL via `replaceUrl` (not `pushUrl`
the navigation function -- switching layouts/tabs/dates shouldn't spam
browser history) -- mirrors `PostsPage.pushSearchUrl`.
-}
pushUrl : Model -> Effect Msg
pushUrl model =
    Browser.Navigation.replaceUrl model.navKey (model.path ++ Url.Builder.toQuery (queryParams model))
        |> Effect.fromCmd



-- VIEW


view : Shared.Model -> Model -> Html Msg
view shared model =
    div []
        [ authorHeadingView shared model.author
        , div [ class "events-controls-row" ]
            [ tabsView shared model
            , modeButtonsView model.mode
            ]
        , eventsListView shared model
        ]


{-| "Events" alone once there's an `author` to filter by, upgraded to
"Events | &lt;name&gt;"-style via `Components.Pages.UserProfilePage.nameHeader`
-- absent entirely for `Pages.Events`' unfiltered feed (`author == Nothing`),
which supplies its own heading instead. Mirrors
`Components.Pages.PostsPage.authorHeadingView`, minus the POST/REPLY-style
context this listing has no equivalent of.
-}
authorHeadingView : Shared.Model -> Maybe ( String, User ) -> Html Msg
authorHeadingView shared maybeAuthor =
    case maybeAuthor of
        Nothing ->
            text ""

        Just ( host, author ) ->
            let
                profileUrl =
                    usernameHref "" shared.accountsPanel.mainFrontendHost host author.username
            in
            div [ class "posts-page-heading" ]
                [ h2 [] [ text "Events" ]
                , a [ href profileUrl, class <| hostnameToCSSClass host ]
                    [ case AccountsPanel.serverForHost shared.accountsPanel.servers host of
                        Just server ->
                            UserProfilePage.nameHeader server (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host) author

                        Nothing ->
                            UserProfilePage.usernameHeading author
                    ]
                ]


{-| The 2 tabs (see `EventsTab`) -- "Upcoming Events" (a plain pill button,
mirrors `modeButtonView`'s own styling) and "Events After &lt;date&gt;",
which -- since it has to contain a real `<input type="datetime-local">`,
and nesting interactive content inside a `<button>` is invalid HTML -- is a
plain `div` with its own `onClick` instead. Clicking anywhere in that
second tab (including to open the date input's native picker, since the
click still bubbles up to the wrapping `div`) or actually changing the date
both switch to it, per `EventsTab`'s own doc -- `onClick`/`onInput` are
otherwise independent (a plain `TabChanged EventsAfterDate` is a no-op once
already active, so the two never conflict). The input's own `value` reflects
`model.endsAfter` (falling back to the UNIX epoch only for the brief instant
before the very first `GotNow`/`?ends_after=` resolves one -- see
`Model.endsAfter`'s own doc) formatted in the viewer's own local time zone,
so the picker shows/accepts wall-clock time the viewer actually recognizes
rather than raw UTC.
-}
tabsView : Shared.Model -> Model -> Html Msg
tabsView shared model =
    div [ class "events-tabs" ]
        [ button
            [ classes
                ("events-tab"
                    :: "events-tab-primary"
                    :: (if model.tab == UpcomingEvents then
                            [ "background-color-primary" ]

                        else
                            []
                       )
                )
            , onClick (TabChanged UpcomingEvents)
            ]
            [ text "Upcoming Events" ]
        , div
            [ classes
                ("events-tab"
                    :: (if model.tab == EventsAfterDate then
                            [ "background-color-primary" ]

                        else
                            []
                       )
                )
            , onClick (TabChanged EventsAfterDate)
            ]
            [ text "Events After "
            , input
                [ type_ "datetime-local"
                , class "events-tab-date-input"
                , value
                    (BrowserTimeZone.formatDateTimeLocalInput
                        shared.browserTimeZone.zone
                        (Maybe.withDefault (Time.millisToPosix 0) model.endsAfter)
                    )
                , onInput EndsAfterInputChanged
                ]
                []
            ]
        ]


{-| The 3 layout-switch buttons (see `EventsDisplayMode`), always all 3,
highlighted (`background-color-nav` -- unlike `tabsView`'s own tabs, which
use `background-color-primary`, so the two rows read as visually distinct
kinds of control sharing one row) for `current`, and pushed to the row's
right edge (see `events.css`'s `.events-controls-row`/`.events-mode-buttons`)
-- mirrors `Pages.Event.EventId_.historyButtonView`'s pill styling.
-}
modeButtonsView : EventsDisplayMode -> Html Msg
modeButtonsView current =
    div [ class "events-mode-buttons" ]
        (List.map (modeButtonView current) [ VerticalList, Grid, HorizontalList ])


modeButtonView : EventsDisplayMode -> EventsDisplayMode -> Html Msg
modeButtonView current target =
    button
        [ classes
            ("events-mode-button"
                :: (if target == current then
                        [ "background-color-nav" ]

                    else
                        []
                   )
            )
        , onClick (DisplayModeChanged target)
        ]
        [ text (modeLabel target) ]


modeLabel : EventsDisplayMode -> String
modeLabel mode =
    case mode of
        VerticalList ->
            "List"

        Grid ->
            "Grid"

        HorizontalList ->
            "Row"


{-| `model.mode`'s own container class + `UI.Flip.Axis` -- `VerticalList`
collapses/reflows vertically (mirrors `PostsPage.postsListView`'s own
`.flip-animated-column`), `Grid`/`HorizontalList` both collapse/reflow
horizontally (mirrors `EventId_.instanceContainerAttributes`' own choice for
its strip/grid).

While any card is still mid `DisplayModeChanged` slide (`anim.move.moving`),
an extra `events-mode-transitioning` class is added -- `events.css` uses it
to lift `.events-strip`'s normal `overflow-x: auto; overflow-y: hidden` for
just that moment, since a card's FLIP invert-offset can visually place it
well outside the settled layout's own box (e.g. sliding in from a
`VerticalList` position far below a single-row strip), and CSS's overflow-x/
overflow-y pairing rule means a lone `overflow-x: auto` already forces the
other axis to clip too (just optionally with a scrollbar) -- only `visible`
on both actually avoids clipping a card mid-flight. See `maxDisplayedEvents`'
own doc for how this was diagnosed.

-}
eventsListView : Shared.Model -> Model -> Html Msg
eventsListView shared model =
    let
        animations =
            visibleAnimations model

        transitioning =
            List.any (\( _, anim ) -> anim.move.moving) animations

        ( modeClass, axis ) =
            case model.mode of
                VerticalList ->
                    ( "events-list flip-animated-column", UI.Flip.Vertical )

                Grid ->
                    ( "events-grid flip-animated-grid", UI.Flip.Horizontal )

                HorizontalList ->
                    ( "events-strip flip-animated-row", UI.Flip.Horizontal )

        containerClass =
            if transitioning then
                modeClass ++ " events-mode-transitioning"

            else
                modeClass
    in
    if Dict.isEmpty model.eventsByServer then
        p [ class "posts-empty" ] [ text "Connect to a server to see upcoming events." ]

    else if List.isEmpty animations then
        p [ class "posts-empty" ] [ text "No upcoming events." ]

    else
        Html.Keyed.node "div"
            [ class containerClass ]
            (List.map (eventAnimationView shared axis) animations)


{-| Wraps `eventCardView` in a fading/scaling/collapsing animated `<div>`
(`anim.flip`, see `syncAnimations`) around an inner move-and-resize-sliding
`<div>` (`anim.move`, see `DisplayModeChanged`) -- mirrors
`Components.Pages.PostsPage.postAnimationView`'s own two-level structure,
just with the extra inner `moveAttributes` layer. The outer `div`'s `id` (see
`eventCardDomId`) is what `measureAll` looks up on a mode switch; it's safe
to measure regardless of `anim.flip`'s own state since that only ever
contributes an inert `scale(1)`/`opacity 1` unless actively entering/removing.
The inner div's `event-card-move` class (see `events.css`) sets
`transform-origin: top left` -- see `UI.Flip.startMoveScaled`'s own doc for
why that's needed alongside a scale.
-}
eventAnimationView : Shared.Model -> UI.Flip.Axis -> ( String, EventAnimation ) -> ( String, Html Msg )
eventAnimationView shared axis ( key, anim ) =
    let
        pointerEventsAttr =
            if anim.flip.removing then
                [ style "pointer-events" "none" ]

            else
                []
    in
    ( key
    , div (id (eventCardDomId key) :: UI.Flip.itemAttributes axis anim.flip anim.move.moving)
        [ div (class "event-card-move" :: pointerEventsAttr ++ UI.Flip.moveAttributes anim.move)
            [ eventCardView shared ( anim.host, anim.event, anim.instance ) ]
        ]
    )


eventCardView : Shared.Model -> ( String, Event, EventInstance ) -> Html Msg
eventCardView shared ( host, event, instance ) =
    let
        maybeServer =
            AccountsPanel.serverForHost shared.accountsPanel.servers host

        maybeAccount =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host

        onMediaClicked mediaId =
            case event.post of
                Just eventPost ->
                    SharedMsg (Shared.MediaViewerPanelMsg (MediaViewerPanel.Open eventPost mediaId host))

                Nothing ->
                    SharedMsg Shared.NoOp
    in
    Events.eventCard
        shared.browserTimeZone
        shared.basePath
        shared.accountsPanel.mainFrontendHost
        host
        maybeServer
        maybeAccount
        onMediaClicked
        event
        instance
