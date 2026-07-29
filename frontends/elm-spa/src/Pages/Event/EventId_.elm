module Pages.Event.EventId_ exposing (Model, Msg, fromShared, page)

{-| `/event/:eventId` -- a single Event's detail/"invitation" view: the
`Event`'s own `Post` (title, link, media, content) up top, then a
horizontally-scrolling date-picker strip of the `Event`'s other
`EventInstance`s (see `instanceHistoryView`) if it has more than one, then
the specific `EventInstance` being viewed (its start/end time and location),
then that `EventInstance`'s own optional override `Post`.

`eventId` (the route segment, matching `Pages.Post.PostId_`'s own `postId`
naming) is actually an `EventInstance.id`, not an `Event.id` --
`GetEventsRequest.event_instance_id` is the only way to fetch a single Event
(see `events.proto`), and it returns that instance's whole parent `Event`
with _every_ one of its instances, not just the one asked for -- which is
exactly what makes the date-picker strip possible without a second request.

-}

import Animation
import Browser.Dom as Dom
import Components.Events as Events
import Components.Posts as Posts
import Components.ServerDependentView as ServerDependentView
import Dict exposing (Dict)
import Effect exposing (Effect)
import Gen.Params.Event.EventId_ exposing (Params)
import Grpc
import Html exposing (Html, a, button, div, p, text)
import Html.Attributes exposing (class, href, id)
import Html.Events exposing (onClick)
import Page
import Process
import Proto.Jonline exposing (Event, EventInstance, Post)
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.Breadcrumbs as Breadcrumbs
import Shared.MediaViewerPanel as MediaViewerPanel
import Task
import Time
import UI
import UI.Classes exposing (classes, hostnameToCSSClass)
import UI.Flip
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req.params
        , update = update shared req
        , view = view shared req
        , subscriptions = subscriptions
        }



-- MODEL


type EventStatus
    = LoadingEvent
    | EventLoaded Event EventInstance
    | EventFailed


{-| Which of an `Event`'s `EventInstance`s the date-picker strip (see
`instanceHistoryView`) shows -- starts `OnlyFuture` (see `init`) unless the
`EventInstance` this page is actually showing needs a broader mode than that
to even be in the strip at all, in which case it starts there instead (see
`clampHistoryDisplay`): the currently-viewed instance is never allowed to be
hidden by its own page's date picker. The history buttons above the strip
(see `historyButtons`) switch it to reveal further past dates on request
rather than dumping every instance of a long-running recurring `Event`
(weekly meetups can rack up hundreds) on the page by default.
-}
type InstanceHistoryDisplay
    = OnlyFuture
    | SinceTwoWeeksAgo
    | ShowAllInstances


{-| How `instanceHistoryView`'s strip lays out its chips -- `StripLayout`
(the default) is a single horizontally-scrolling row; `GridLayout` wraps
instead, trading the scrollbar for vertical growth. Toggled via
`instanceLayoutButtonView`, only offered at all once there's more than 3
chips to justify it (see `instanceHistoryView`).
-}
type InstanceLayout
    = StripLayout
    | GridLayout


{-| One date-picker chip's data plus its own enter/leave `UI.Flip.State` --
mirrors `Shared.MyMediaPanel.MediaAnimation` (see its own doc): keeping
`instance` here, not just looking it up from `Event.instances` by id, means a
chip that just dropped out of `instanceHistoryDisplay`'s current filter still
has something to render for the length of its own fade/collapse-out.
-}
type alias InstanceAnimation =
    { instance : EventInstance
    , flip : UI.Flip.State Msg
    }


type alias Model =
    { targetHost : String
    , eventId : String
    , eventStatus : EventStatus
    , connectStatus : ServerDependentView.ConnectStatus
    , fetchStarted : Bool

    -- Captured once via `Time.now` in `init` -- good enough to categorize
    -- `EventInstance`s as upcoming/recent/past for the length of a single
    -- page view; this page never needs to notice a date instance crossing
    -- that boundary while it's open.
    , now : Time.Posix
    , instanceHistoryDisplay : InstanceHistoryDisplay
    , instanceLayout : InstanceLayout
    , instanceAnimations : Dict String InstanceAnimation
    }


init : Shared.Model -> Params -> ( Model, Effect Msg )
init shared params =
    let
        ( eventId, targetHost ) =
            Events.parseEventRouteId shared.accountsPanel.mainFrontendHost params.eventId

        ( fetchedModel, fetchEffect ) =
            fetchIfReady shared
                { targetHost = targetHost
                , eventId = eventId
                , eventStatus = LoadingEvent
                , connectStatus = ServerDependentView.NotConnected
                , fetchStarted = False
                , now = Time.millisToPosix 0
                , instanceHistoryDisplay = OnlyFuture
                , instanceLayout = StripLayout
                , instanceAnimations = Dict.empty
                }
    in
    ( fetchedModel
    , Effect.batch
        [ fetchEffect
        , Effect.fromShared (Shared.BreadcrumbsMsg Breadcrumbs.Clear)
        , Task.perform GotNow Time.now |> Effect.fromCmd
        ]
    )


{-| Mirrors `Pages.Post.PostId_.fetchIfReady` exactly -- kicks off the actual
`GetEvents` fetch the first time `targetHost` is a known, connected server.
-}
fetchIfReady : Shared.Model -> Model -> ( Model, Effect Msg )
fetchIfReady shared model =
    if model.fetchStarted then
        ( model, Effect.none )

    else
        case AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost of
            Just _ ->
                ( { model | fetchStarted = True }
                , Events.fetchEvent shared.accountsPanel (maybeAccountServerFor shared model) model.eventId
                    |> Task.attempt GotEvent
                    |> Effect.fromCmd
                )

            Nothing ->
                ( model, Effect.none )


maybeAccountServerFor : Shared.Model -> Model -> AccountsPanel.MaybeAccountServer
maybeAccountServerFor shared model =
    ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost |> Maybe.map .userId
    , model.targetHost
    )



-- UPDATE


type Msg
    = GotEvent (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetEventsResponse ))
    | GotNow Time.Posix
    | MediaClicked Post String
    | ConnectClicked
    | GotConnectResult (Result Grpc.Error AccountsPanel.Server)
    | EnableClicked
      -- Switches which of the Event's `EventInstance`s the date-picker strip
      -- shows (see `InstanceHistoryDisplay`) -- fired by `historyButtons`.
    | HistoryDisplayChanged InstanceHistoryDisplay
      -- Switches the strip between its scrolling-row and wrapping-grid
      -- layouts (see `InstanceLayout`) -- fired by `instanceLayoutButtonView`.
    | InstanceLayoutChanged InstanceLayout
      -- Steps every date chip's enter/leave fade (`instanceAnimations`)
      -- forward on an animation-frame tick -- mirrors
      -- `Shared.MyMediaPanel.AnimateItemFlip`.
    | AnimateItemFlip Animation.Msg
      -- Fired once a chip that dropped out of the current
      -- `InstanceHistoryDisplay` filter finishes fading/collapsing out (see
      -- `UI.Flip.remove`) -- drops it from `instanceAnimations` for good.
    | RemoveInstanceAnimation String
      -- Fired once the one-time scroll-the-current-instance-into-view
      -- attempt (see `scrollToInstance`) settles, whether it actually
      -- succeeded or not -- there's nothing useful to do with a failure (the
      -- chip/strip not being found yet, say), so this is a pure no-op either
      -- way.
    | ScrolledToInstance (Result Dom.Error ())
    | Poll
    | SharedMsg Shared.Msg


fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


accountsPanelEffect : Maybe AccountsPanel.Msg -> Effect Msg
accountsPanelEffect maybeAccountsPanelMsg =
    maybeAccountsPanelMsg
        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
        |> Maybe.withDefault Effect.none


{-| Whether `instance` belongs in the strip under `mode` -- `ShowAllInstances`
takes everything, `SinceTwoWeeksAgo`/`OnlyFuture` cut off at 14 days before
`now`/`now` itself (via `Components.Events.instanceMoment`). An instance with
no resolvable time at all (`instanceMoment == Nothing`) always passes, same
"can't tell, so don't hide it" reasoning as `Components.Events.instanceMoment`
falling back to `startsAt`.
-}
instanceMatchesHistoryDisplay : Time.Posix -> InstanceHistoryDisplay -> EventInstance -> Bool
instanceMatchesHistoryDisplay now mode instance =
    case mode of
        ShowAllInstances ->
            True

        SinceTwoWeeksAgo ->
            instanceAtOrAfter (twoWeeksBefore now) instance

        OnlyFuture ->
            instanceAtOrAfter now instance


instanceAtOrAfter : Time.Posix -> EventInstance -> Bool
instanceAtOrAfter threshold instance =
    case Events.instanceMoment instance of
        Just moment ->
            Time.posixToMillis moment >= Time.posixToMillis threshold

        Nothing ->
            True


twoWeeksBefore : Time.Posix -> Time.Posix
twoWeeksBefore now =
    Time.millisToPosix (Time.posixToMillis now - 14 * 24 * 60 * 60 * 1000)


{-| `OnlyFuture` < `SinceTwoWeeksAgo` < `ShowAllInstances`, as an `Int` --
`OnlyFuture`'s own set of instances is always a subset of `SinceTwoWeeksAgo`'s,
which is always a subset of `ShowAllInstances`'s, so this ordering is exactly
"how restrictive a mode is" -- used by `minimumHistoryDisplayFor`/
`clampHistoryDisplay`/`historyButtons` to compare modes without a full `case`
each time.
-}
historyDisplayRank : InstanceHistoryDisplay -> Int
historyDisplayRank mode =
    case mode of
        OnlyFuture ->
            0

        SinceTwoWeeksAgo ->
            1

        ShowAllInstances ->
            2


{-| The least-inclusive `InstanceHistoryDisplay` that still keeps `instance`
in the strip -- `OnlyFuture` for an upcoming
instance, `SinceTwoWeeksAgo` for one less than two weeks in the past,
`ShowAllInstances` for anything older than that. Used by both
`clampHistoryDisplay` (to pick this page's own initial mode) and
`historyButtons` (to never offer a switch that would hide the very instance
the page is showing) -- see either's own doc.
-}
minimumHistoryDisplayFor : Time.Posix -> EventInstance -> InstanceHistoryDisplay
minimumHistoryDisplayFor now instance =
    if instanceMatchesHistoryDisplay now OnlyFuture instance then
        OnlyFuture

    else if instanceMatchesHistoryDisplay now SinceTwoWeeksAgo instance then
        SinceTwoWeeksAgo

    else
        ShowAllInstances


{-| Raises `model.instanceHistoryDisplay` up to `minimumHistoryDisplayFor
model.now instance` if it's currently more restrictive than that -- never
lowers it, so this is safe to call every time `model.now`/the loaded `Event`
change (`GotEvent`, `GotNow`) without ever undoing a broader mode the user
already switched to via `historyButtons`, which (via that same
`minimumHistoryDisplayFor` floor) never offers a button this would need to
undo in the first place. In practice this is what actually picks this page's
initial mode: `init` always starts `model.instanceHistoryDisplay` at
`OnlyFuture` (the most restrictive possible value) before either the `Event`
or a real `now` are known, so the first call after both land is the one that
raises it to wherever the currently-viewed `instance` actually needs.
-}
clampHistoryDisplay : EventInstance -> Model -> Model
clampHistoryDisplay instance model =
    let
        minimum =
            minimumHistoryDisplayFor model.now instance
    in
    if historyDisplayRank model.instanceHistoryDisplay < historyDisplayRank minimum then
        { model | instanceHistoryDisplay = minimum }

    else
        model


{-| Reconciles `instanceAnimations` with whichever of `event.instances`
`model.instanceHistoryDisplay` currently selects -- newly-revealed instances
(switching to a broader mode, e.g. `OnlyFuture` -> `ShowAllInstances`) fade
in, newly-hidden ones (the reverse) fade/collapse out rather than just
vanishing, and the ones staying visible are left alone. A no-op while the
`Event` itself hasn't loaded yet. Mirrors
`Shared.MyMediaPanel.syncMediaAnimations` -- see its own doc; called from
every `update` branch that can change either input: `GotEvent`, `GotNow`
(the very first real `now` can flip an instance's category), and
`HistoryDisplayChanged`.
-}
syncInstanceAnimations : Model -> Model
syncInstanceAnimations model =
    case model.eventStatus of
        EventLoaded event _ ->
            let
                currentInstances : Dict String EventInstance
                currentInstances =
                    event.instances
                        |> List.filter (instanceMatchesHistoryDisplay model.now model.instanceHistoryDisplay)
                        |> List.map (\instance -> ( instance.id, instance ))
                        |> Dict.fromList
            in
            { model
                | instanceAnimations =
                    UI.Flip.syncAnimations
                        RemoveInstanceAnimation
                        (\instance -> { instance = instance, flip = UI.Flip.enter })
                        (\instance anim -> { anim | instance = instance })
                        currentInstances
                        model.instanceAnimations
            }

        _ ->
            model


{-| The DOM id `instanceHistoryView`'s scrollable strip is rendered with --
paired with `instanceChipDomId` by `scrollToInstance`.
-}
instanceStripDomId : String
instanceStripDomId =
    "event-instance-strip"


instanceChipDomId : String -> String
instanceChipDomId instanceId =
    "event-instance-chip-" ++ instanceId


{-| Scrolls `instanceStripDomId`'s strip horizontally so `instanceId`'s own
chip is centered in view -- fired once whenever a new `EventInstance` becomes
"the current one" (a fresh page load, or the user clicking to a sibling
instance's own page -- see `GotEvent`), not on every `HistoryDisplayChanged`
toggle. `Process.sleep` first: every chip (including ones that were already
visible) starts a fresh `UI.Flip.enter` whenever `syncInstanceAnimations`
rebuilds `instanceAnimations` from scratch (as it does right after this same
`GotEvent`), so measuring immediately would read every chip's still-collapsed
(`grid-template-columns: 0fr`, see `flip.css`) 0-width position rather than
its real, grown-in one -- 300ms clears `flip.css`'s own 0.25s collapse/grow
transition with a little headroom. Silently gives up (`ScrolledToInstance`
ignores its own `Result`) if the strip or chip aren't found -- e.g. an
`Event` with only one instance, whose strip `instanceHistoryView` doesn't
render at all.
-}
scrollToInstance : String -> Cmd Msg
scrollToInstance instanceId =
    Process.sleep 300
        |> Task.andThen
            (\_ ->
                Task.map3 (\chip strip viewport -> ( chip, strip, viewport ))
                    (Dom.getElement (instanceChipDomId instanceId))
                    (Dom.getElement instanceStripDomId)
                    (Dom.getViewportOf instanceStripDomId)
            )
        |> Task.andThen
            (\( chip, strip, viewport ) ->
                let
                    chipLeftWithinStrip =
                        chip.element.x - strip.element.x

                    target =
                        viewport.viewport.x
                            + chipLeftWithinStrip
                            - (viewport.viewport.width / 2)
                            + (chip.element.width / 2)
                in
                Dom.setViewportOf instanceStripDomId (max 0 target) 0
            )
        |> Task.attempt ScrolledToInstance


update : Shared.Model -> Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
update shared req msg model =
    case msg of
        GotEvent (Ok ( maybeAccountsPanelMsg, response )) ->
            let
                accountEffect =
                    accountsPanelEffect maybeAccountsPanelMsg

                newStatus =
                    case List.head response.events of
                        Just event ->
                            case Events.findInstance model.eventId event of
                                Just instance ->
                                    EventLoaded event instance

                                Nothing ->
                                    EventFailed

                        Nothing ->
                            EventFailed

                -- `Shared.Breadcrumbs.FromEvent` exists but its `rootSegment`
                -- isn't implemented yet (renders a literal "TODO" -- see its
                -- own doc comment), so this just uses `FromServerHost` like
                -- `Pages.Post.PostId_` does for a non-`REPLY` Post: shows a
                -- server chip in the trail when `targetHost` isn't
                -- `mainFrontendHost`, nothing more.
                breadcrumbsEffect =
                    Effect.fromShared
                        (Shared.BreadcrumbsMsg
                            (Breadcrumbs.SetRoot (Breadcrumbs.FromServerHost model.targetHost) model.targetHost [])
                        )

                scrollEffect =
                    case newStatus of
                        EventLoaded _ _ ->
                            scrollToInstance model.eventId |> Effect.fromCmd

                        _ ->
                            Effect.none

                modelWithNewStatus =
                    { model | eventStatus = newStatus }

                clampedModel =
                    case newStatus of
                        EventLoaded _ loadedInstance ->
                            clampHistoryDisplay loadedInstance modelWithNewStatus

                        _ ->
                            modelWithNewStatus
            in
            ( clampedModel |> syncInstanceAnimations
            , Effect.batch [ accountEffect, breadcrumbsEffect, scrollEffect ]
            )

        GotEvent (Err _) ->
            ( { model | eventStatus = EventFailed }, Effect.none )

        GotNow now ->
            let
                modelWithNow =
                    { model | now = now }

                clampedModel =
                    case model.eventStatus of
                        EventLoaded _ instance ->
                            clampHistoryDisplay instance modelWithNow

                        _ ->
                            modelWithNow
            in
            ( clampedModel |> syncInstanceAnimations, Effect.none )

        MediaClicked post mediaId ->
            ( model, Effect.fromShared (Shared.MediaViewerPanelMsg (MediaViewerPanel.Open post mediaId model.targetHost)) )

        ConnectClicked ->
            ( { model | connectStatus = ServerDependentView.Connecting }
            , AccountsPanel.connectToServer (AccountsPanel.isSecure req) model.targetHost
                |> Task.attempt GotConnectResult
                |> Effect.fromCmd
            )

        GotConnectResult (Ok server) ->
            let
                ( newModel, fetchEffect ) =
                    fetchIfReady shared { model | connectStatus = ServerDependentView.NotConnected }
            in
            ( newModel
            , Effect.batch
                [ Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.ServerConnected server))
                , fetchEffect
                ]
            )

        GotConnectResult (Err err) ->
            ( { model | connectStatus = ServerDependentView.ConnectFailed (AccountsPanel.grpcErrorToString err) }
            , Effect.none
            )

        EnableClicked ->
            ( model, Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.ToggleServerEnabled model.targetHost)) )

        HistoryDisplayChanged mode ->
            ( { model | instanceHistoryDisplay = mode } |> syncInstanceAnimations, Effect.none )

        InstanceLayoutChanged layout ->
            ( { model | instanceLayout = layout }, Effect.none )

        AnimateItemFlip animMsg ->
            let
                step id anim ( animations, accCmds ) =
                    let
                        ( newFlip, cmd ) =
                            UI.Flip.animate animMsg anim.flip
                    in
                    ( Dict.insert id { anim | flip = newFlip } animations, cmd :: accCmds )

                ( newInstanceAnimations, cmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.instanceAnimations
            in
            ( { model | instanceAnimations = newInstanceAnimations }, Cmd.batch cmds |> Effect.fromCmd )

        RemoveInstanceAnimation id ->
            ( { model | instanceAnimations = Dict.remove id model.instanceAnimations }, Effect.none )

        ScrolledToInstance _ ->
            ( model, Effect.none )

        Poll ->
            fetchIfReady shared model

        SharedMsg subMsg ->
            let
                ( fetchedModel, fetchEffect ) =
                    case subMsg of
                        Shared.AccountsPanelMsg _ ->
                            fetchIfReady shared model

                        _ ->
                            ( model, Effect.none )
            in
            ( fetchedModel, Effect.batch [ Effect.fromShared subMsg, fetchEffect ] )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ if model.fetchStarted then
            Sub.none

          else
            Time.every 30000 (\_ -> Poll)
        , UI.Flip.subscription AnimateItemFlip (Dict.values model.instanceAnimations |> List.map .flip)
        ]



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = titleFor shared model
    , body = UI.layout shared req.route SharedMsg [ bodyView shared req model ]
    }


titleFor : Shared.Model -> Model -> String
titleFor shared model =
    let
        subtitle =
            case model.eventStatus of
                EventLoaded event _ ->
                    event.post |> Maybe.map Posts.postTitleText |> Maybe.withDefault ("Event " ++ model.eventId)

                _ ->
                    "Event " ++ model.eventId
    in
    UI.pageTitle shared [ subtitle ]


bodyView : Shared.Model -> Request.With Params -> Model -> Html Msg
bodyView shared req model =
    ServerDependentView.view
        { hostname = model.targetHost
        , servers = shared.accountsPanel.servers
        , accounts = shared.accountsPanel.accounts
        , connectStatus = model.connectStatus
        , onConnectClicked = ConnectClicked
        , onEnableClicked = EnableClicked
        }
        (\_ _ ->
            case model.eventStatus of
                LoadingEvent ->
                    p [ class "event-loading" ] [ text "Loading…" ]

                EventFailed ->
                    p [ class "event-error" ]
                        [ text
                            ("Couldn't load Event "
                                ++ model.eventId
                                ++ "@"
                                ++ model.targetHost
                                ++ ". Maybe it doesn't exist, or maybe you need to be logged in?"
                            )
                        ]

                EventLoaded event instance ->
                    eventDetailView shared model event instance
        )


eventDetailView : Shared.Model -> Model -> Event -> EventInstance -> Html Msg
eventDetailView shared model event instance =
    let
        maybeServer =
            AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost

        maybeAccount =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost

        postSection =
            Events.postSection
                shared.browserTimeZone
                shared.basePath
                shared.accountsPanel.mainFrontendHost
                model.targetHost
                maybeServer
                maybeAccount
    in
    div [ classes [ "event-detail", hostnameToCSSClass model.targetHost, "border-color-primary-anchor-50" ] ]
        [ case event.post of
            Just eventPost ->
                postSection (MediaClicked eventPost) True eventPost

            Nothing ->
                text ""
        , instanceHistoryView shared model event instance
        , div [ class "event-instance-detail" ]
            [ div [ class "event-instance-when" ] [ text "📅 ", Events.instanceTimeRangeText shared.browserTimeZone instance ]
            , case instance.location |> Maybe.andThen Events.locationText of
                Just locationLine ->
                    div [ class "event-instance-where" ] [ text "📍 ", text locationLine ]

                Nothing ->
                    text ""
            ]
        , case instance.post |> Maybe.andThen meaningfulPost of
            Just instancePost ->
                postSection (MediaClicked instancePost) False instancePost

            Nothing ->
                text ""
        ]


{-| The date-picker strip: up to two "switch scope" buttons (see
`historyButtons`) plus, once there's more than 3 chips to justify it, a
scroll/grid layout toggle (see `instanceLayoutButtonView`), above either a
horizontally-scrolling row or a wrapping grid (`model.instanceLayout`) of
every `EventInstance` currently selected by `model.instanceHistoryDisplay`,
each linking to that instance's own page. Renders nothing at all for an
`Event` with only one instance -- there's no other date to pick.
-}
instanceHistoryView : Shared.Model -> Model -> Event -> EventInstance -> Html Msg
instanceHistoryView shared model event instance =
    if List.length event.instances <= 1 then
        text ""

    else
        let
            buttons =
                historyButtons model event instance

            showLayoutToggle =
                List.length event.instances > 3
        in
        div [ class "event-instance-history" ]
            [ if List.isEmpty buttons && not showLayoutToggle then
                text ""

              else
                div [ class "event-instance-history-buttons" ]
                    (List.map historyButtonView buttons
                        ++ (if showLayoutToggle then
                                [ instanceLayoutButtonView model.instanceLayout ]

                            else
                                []
                           )
                    )
            , div
                (id instanceStripDomId :: instanceContainerAttributes model.instanceLayout)
                (event.instances
                    |> List.filterMap (\eventInstance -> Dict.get eventInstance.id model.instanceAnimations)
                    |> List.map (instanceChipView shared model)
                )
            ]


{-| The strip container's own layout classes -- `StripLayout` is a plain
`UI.Flip.Horizontal` row (`flip-animated-row`/`.event-instance-strip`,
scrolling), `GridLayout` wraps instead (`flip-animated-grid`/
`.event-instance-grid`, no scrollbar, grows vertically) -- see `flip.css` for
how each of those first classes drives a chip's own collapse/grow direction
via `UI.Flip.itemAttributes`' `.horizontal` (used for both layouts here; see
`instanceChipView`).
-}
instanceContainerAttributes : InstanceLayout -> List (Html.Attribute Msg)
instanceContainerAttributes layout =
    case layout of
        StripLayout ->
            [ classes [ "event-instance-strip", "flip-animated-row" ] ]

        GridLayout ->
            [ classes [ "event-instance-grid", "flip-animated-grid" ] ]


{-| Toggles `model.instanceLayout` -- labeled for whichever layout it would
switch _to_, not the current one.
-}
instanceLayoutButtonView : InstanceLayout -> Html Msg
instanceLayoutButtonView layout =
    case layout of
        StripLayout ->
            button
                [ class "event-instance-history-button", onClick (InstanceLayoutChanged GridLayout) ]
                [ text "Grid view" ]

        GridLayout ->
            button
                [ class "event-instance-history-button", onClick (InstanceLayoutChanged StripLayout) ]
                [ text "List view" ]


historyButtonView : ( InstanceHistoryDisplay, Int ) -> Html Msg
historyButtonView ( mode, count ) =
    button
        [ class "event-instance-history-button", onClick (HistoryDisplayChanged mode) ]
        [ text (historyButtonLabel mode count) ]


historyButtonLabel : InstanceHistoryDisplay -> Int -> String
historyButtonLabel mode count =
    let
        dateWord =
            if count == 1 then
                "date"

            else
                "dates"
    in
    case mode of
        ShowAllInstances ->
            String.fromInt count ++ " total " ++ dateWord

        SinceTwoWeeksAgo ->
            String.fromInt count ++ " " ++ dateWord ++ " since 2 weeks ago"

        OnlyFuture ->
            String.fromInt count ++ " upcoming " ++ dateWord


{-| Which "switch scope" buttons to show above the strip -- at most 2 (one
for each `InstanceHistoryDisplay` other than `model.instanceHistoryDisplay`
itself), skipping any whose count is redundant with what's already visible:
e.g. if every instance is upcoming, `ShowAllInstances`/`SinceTwoWeeksAgo`
would reveal the exact same set `OnlyFuture` already shows, so neither button
appears; if only `ShowAllInstances` would add anything, only its button does.
Also never offers a mode more restrictive than `minimumHistoryDisplayFor
model.now instance` -- switching to one of those would hide `instance`, the
very one this page is showing (see `clampHistoryDisplay`, which keeps
`model.instanceHistoryDisplay` itself out of that territory in the first
place, so there's nothing here to filter `model.instanceHistoryDisplay`
itself against).

Processes the two non-current, non-too-restrictive modes from most to least
restrictive (`OnlyFuture`, then `SinceTwoWeeksAgo`, then `ShowAllInstances`),
dropping any whose count matches the last kept count (starting from the
current mode's own count) -- since `OnlyFuture`'s set is always a subset of
`SinceTwoWeeksAgo`'s, which is always a subset of `ShowAllInstances`'s, equal
counts mean equal sets, so a button whose target would show exactly what's
already on screen is never worth offering. The result is re-sorted back into
`ShowAllInstances`, `SinceTwoWeeksAgo`, `OnlyFuture` order for display either
way.

-}
historyButtons : Model -> Event -> EventInstance -> List ( InstanceHistoryDisplay, Int )
historyButtons model event instance =
    let
        countFor mode =
            event.instances |> List.filter (instanceMatchesHistoryDisplay model.now mode) |> List.length

        currentCount =
            countFor model.instanceHistoryDisplay

        minimumRank =
            historyDisplayRank (minimumHistoryDisplayFor model.now instance)

        ( _, kept ) =
            [ OnlyFuture, SinceTwoWeeksAgo, ShowAllInstances ]
                |> List.filter
                    (\mode -> mode /= model.instanceHistoryDisplay && historyDisplayRank mode >= minimumRank)
                |> List.foldl
                    (\mode ( lastCount, acc ) ->
                        let
                            count =
                                countFor mode
                        in
                        if count == lastCount then
                            ( lastCount, acc )

                        else
                            ( count, mode :: acc )
                    )
                    ( currentCount, [] )
    in
    [ ShowAllInstances, SinceTwoWeeksAgo, OnlyFuture ]
        |> List.filter (\mode -> List.member mode kept)
        |> List.map (\mode -> ( mode, countFor mode ))


{-| One date chip -- links to `anim.instance`'s own page (see
`Components.Events.eventInstanceHref`), highlighted if it's the instance
currently being viewed (`model.eventId`). Wrapped in `UI.Flip.itemAttributes`
so it fades/collapses in and out as `model.instanceHistoryDisplay` changes
which instances `instanceHistoryView` selects (see `syncInstanceAnimations`).
-}
instanceChipView : Shared.Model -> Model -> InstanceAnimation -> Html Msg
instanceChipView shared model anim =
    let
        instance =
            anim.instance

        isCurrent =
            instance.id == model.eventId
    in
    div (UI.Flip.itemAttributes UI.Flip.Horizontal anim.flip False)
        [ a
            [ href (Events.eventInstanceHref shared.basePath shared.accountsPanel.mainFrontendHost model.targetHost instance)
            , id (instanceChipDomId instance.id)
            , classes
                ([ "event-instance-chip", hostnameToCSSClass model.targetHost ]
                    ++ (if isCurrent then
                            [ "event-instance-chip-current", "background-color-primary" ]

                        else
                            []
                       )
                )
            ]
            [ text (Events.instanceDateText shared.browserTimeZone instance) ]
        ]


{-| `post` itself, unless it has nothing an `EventInstance`'s own override
`Post` would actually add over the parent `Event`'s -- no title, link,
content, or media, just the empty shell every `EventInstance` carries
whether or not its creator actually filled one in. Showing `postSection` for
one of these would render nothing but a redundant author/visibility line
(see `Components.Events.postSection`), so `eventDetailView` skips the whole
section instead.
-}
meaningfulPost : Post -> Maybe Post
meaningfulPost post =
    let
        hasTitle =
            post.title |> Maybe.map (String.trim >> String.isEmpty >> not) |> Maybe.withDefault False

        hasContent =
            post.content |> Maybe.map (String.trim >> String.isEmpty >> not) |> Maybe.withDefault False

        hasLink =
            Posts.postLinkText post /= Nothing

        hasMedia =
            not (List.isEmpty post.media)
    in
    if hasTitle || hasContent || hasLink || hasMedia then
        Just post

    else
        Nothing
