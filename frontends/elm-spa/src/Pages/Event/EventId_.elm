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
import Components.Users as Users
import Dict exposing (Dict)
import Effect exposing (Effect)
import Gen.Params.Event.EventId_ exposing (Params)
import Gen.Route
import Grpc
import Html exposing (Html, a, button, div, option, p, select, span, text, textarea)
import Html.Attributes exposing (attribute, class, disabled, href, id, placeholder, selected, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Encode as Encode
import Page
import Ports
import Process
import Proto.Jonline exposing (Event, EventInstance, Post)
import Proto.Jonline.EventSyncSource.Configuration as Configuration
import Proto.Jonline.Moderation exposing (Moderation(..))
import Proto.Jonline.Permission exposing (Permission(..))
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.Breadcrumbs as Breadcrumbs
import Shared.MediaViewerPanel as MediaViewerPanel
import Shared.MyMediaPanel as MyMediaPanel
import Shared.StarredPanel as StarredPanel
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


{-| Mirrors `Pages.Post.PostId_.SubmitStatus` exactly.
-}
type SubmitStatus
    = Idle
    | Submitting
    | SubmitFailed String


{-| Live only while `postFieldsEditView` is open, editing the `Event`'s own
primary `Post` -- `pending*` are the in-progress `<input>`/`<textarea>`
values, independent of the loaded `Post`'s own fields until
`PostFieldsSaveClicked` succeeds. Mirrors `Pages.Post.PostId_.VisibilityEdit`,
just over 3 fields instead of one.
-}
type alias PostFieldsEdit =
    { pendingTitle : String
    , pendingLink : String
    , pendingContent : String
    , status : SubmitStatus
    }


{-| Live only while the moderation-status selector is open -- mirrors
`PostFieldsEdit` in shape, `Pages.Post.PostId_.VisibilityEdit` in spirit.
-}
type alias ModerationEdit =
    { pending : Moderation
    , status : SubmitStatus
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

    -- Set by `MediaEditClicked`, until the `Shared.MyMediaPanel` it opens
    -- reports back a `SaveMediaClicked`/`CloseClicked` -- mirrors
    -- `Pages.Post.PostId_.Model.mediaEditActive` exactly, see its own doc for
    -- why this gating is needed at all.
    , mediaEditActive : Bool

    -- Live only while the title/link/content editor (see `postFieldsEditView`)
    -- is open, for the `Event`'s own primary `Post` -- mirrors
    -- `Pages.Post.PostId_.Model.visibilityEdit` (a `pending`-vs-loaded split,
    -- independent until save succeeds), just over 3 fields instead of one.
    , postFieldsEdit : Maybe PostFieldsEdit

    -- Live only while the moderation-status selector (see `moderationView`)
    -- is open -- mirrors `postFieldsEdit` in shape.
    , moderationEdit : Maybe ModerationEdit
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
                , mediaEditActive = False
                , postFieldsEdit = Nothing
                , moderationEdit = Nothing
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
`GetEvents` fetch the first time `targetHost` is a known, connected server
(see `AccountsPanel.knownConnectedServer` -- a known-but-still-connecting
`targetHost`, e.g. right after startup, doesn't count).
-}
fetchIfReady : Shared.Model -> Model -> ( Model, Effect Msg )
fetchIfReady shared model =
    if model.fetchStarted then
        ( model, Effect.none )

    else
        case AccountsPanel.knownConnectedServer shared.accountsPanel.servers model.targetHost of
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


{-| The connected `Server`/signed-in `Account` for `model.targetHost`, if
both exist -- what `MediaEditClicked`'s own save (via `Shared.MyMediaPanel`'s
`SaveMediaClicked`) needs to actually submit its `Posts.updatePost` task.
Mirrors `Pages.Post.PostId_.serverAndAccount`.
-}
serverAndAccount : Shared.Model -> Model -> Maybe ( AccountsPanel.Server, AccountsPanel.Account )
serverAndAccount shared model =
    Maybe.map2 Tuple.pair
        (AccountsPanel.serverForHost shared.accountsPanel.servers model.targetHost)
        (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts model.targetHost)


{-| Applies a just-saved `updatedPost` to the currently-loaded `Event`'s own
`post` field (the only one `MediaEditClicked` ever opens the picker for, not
`instance.post`) -- a no-op if the `Event` isn't loaded at all, which
shouldn't happen in practice (this is only ever called from
`GotMediaUpdateResult`, itself only reachable once `MediaEditClicked` has
already rendered from a loaded `Event`). Mirrors
`Pages.Post.PostId_.applyUpdatedPost`, just updating a nested field rather
than `Model`'s own top-level `postStatus`.
-}
applyUpdatedEventPost : Model -> Post -> Model
applyUpdatedEventPost model updatedPost =
    case model.eventStatus of
        EventLoaded event instance ->
            { model | eventStatus = EventLoaded { event | post = Just updatedPost } instance }

        _ ->
            model


{-| `Just text` unless `text` is blank, `Nothing` otherwise -- used by
`PostFieldsSaveClicked` to translate an edit form's plain `String` inputs
into `Post.title`/`Post.link`/`Post.content`'s own `Maybe String`, matching
how an empty field means "unset" everywhere else these fields are read (e.g.
`Components.Posts.postLinkText`).
-}
nonBlank : String -> Maybe String
nonBlank text =
    if String.isEmpty (String.trim text) then
        Nothing

    else
        Just text



-- UPDATE


type Msg
    = GotEvent (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetEventsResponse ))
    | GotNow Time.Posix
    | MediaClicked Post String
      -- The Event's own `Post`'s media-edit button (see `eventDetailView`) --
      -- opens the shared `Shared.MyMediaPanel` chooser in `MultiSelect` mode,
      -- mirroring `Pages.Post.PostId_.MediaEditClicked` exactly, including
      -- reusing plain `UpdatePost` (via `Posts.updatePost`) to save -- the
      -- backend's `update_post.rs` already updates `media` unconditionally
      -- for `admin || self_update` regardless of the post's own context
      -- (`Post`, `Event`, `EventInstance`, ...), so nothing about `UpdateEvent`
      -- is needed just to change which media this Post carries.
    | MediaEditClicked Post
    | GotMediaUpdateResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, Post ))
      -- The Event's own `Post`'s title/link/content editor (see
      -- `postFieldsEditView`) -- shown to the post's own author or an Admin
      -- (see `postFieldsEditButtonView`), submitted via plain `UpdatePost`
      -- (`Posts.updatePost`) the same way `MediaEditClicked`'s save is,
      -- rather than the heavier `UpdateEvent` (see that `Msg`'s own doc for
      -- why).
    | PostFieldsEditClicked Post
    | PostFieldsTitleChanged String
    | PostFieldsLinkChanged String
    | PostFieldsContentChanged String
    | PostFieldsCancelClicked
    | PostFieldsSaveClicked Post
    | GotPostFieldsSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, Post ))
      -- The Event's own `Post`'s moderation-status selector (see
      -- `moderationView`) -- shown to an Admin or a `MODERATEEVENTS` holder,
      -- also submitted via plain `UpdatePost`.
    | ModerationEditClicked Event
    | ModerationChanged String
    | ModerationCancelClicked
    | ModerationSaveClicked Event
    | GotModerationSaveResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, Post ))
      -- The Event's own delete button (see `deleteButtonView`), shown to its
      -- owner -- opens the shared "are you sure?" dialog
      -- (`Shared.ConfirmEventDelete`); its result (`Shared.GotEventDeleteResult`)
      -- is picked up in `SharedMsg` below.
    | DeleteClicked Event
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
      -- The scroll-the-current-instance-into-view measurement (see
      -- `scrollToInstance`) resolving with the target `scrollLeft` to send
      -- through `Ports.scrollElementLeft` -- `Err` (the chip/strip not
      -- found, e.g. an `Event` with only one instance) is a pure no-op.
    | GotScrollTarget (Result Dom.Error Float)
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
    case Events.instanceEndsOrStartsAt instance of
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
already switched to via `historyButtonView`, whose button for any mode below
that same `minimumHistoryDisplayFor` floor is `disabled` rather than
removed, so there's no way to have reached one of those in the first place.
In practice this is what actually picks this page's initial mode: `init`
always starts `model.instanceHistoryDisplay` at
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
chip is centered in view -- fired both whenever a new `EventInstance` becomes
"the current one" (a fresh page load, or the user clicking to a sibling
instance's own page -- see `GotEvent`) and whenever `HistoryDisplayChanged`
reveals/hides other chips around it, potentially shifting its position.
`Process.sleep delayMs` first in both cases: measuring immediately would read
some chip's still-collapsed (`grid-template-columns: 0fr`, see `flip.css`)
0-width position rather than its real, grown-in one, since a chip's own
`UI.Flip.enter`/`remove` animation is still in progress at the moment either
caller's own model update lands -- `GotEvent` passes 300ms (every chip,
including ones that were already visible, starts a fresh `enter` whenever
`syncInstanceAnimations` rebuilds `instanceAnimations` from scratch, as it
does right after `GotEvent`), `HistoryDisplayChanged` passes 400ms (only the
chips actually entering/leaving are mid-animation, but there's usually more
of them sliding at once than a fresh page load ever has, so a little more
headroom). Either way this clears `flip.css`'s own 0.25s collapse/grow transition.
Silently gives up (`GotScrollTarget`'s `Err` case is a no-op) if the strip or
chip aren't found -- e.g. an `Event` with only one instance, whose strip
`instanceHistoryView` doesn't render at all.

Only _measures_ here (`Dom.getElement`/`Dom.getViewportOf`) -- the actual
scroll happens back in `update`'s `GotScrollTarget` case, via
`Ports.scrollElementLeft` rather than `Dom.setViewportOf`. See that port's own
doc comment: `Dom.setViewportOf` always assigns `scrollLeft` from inside a
`requestAnimationFrame` callback, which silently fails to take effect at all
on an element with this strip's own `scroll-behavior: smooth` (see
`events.css`), even though the `Task` itself reports success -- confirmed by
instrumenting a real run (a `GotScrollTarget`-equivalent debug message
reported the correct computed target every time, yet `scrollLeft` never
budged) and reproducing it directly (`requestAnimationFrame(() => { el.scrollLeft
= x })`, checked a frame later, silently no-ops the same way). A port
callback is a plain (non-rAF-wrapped) JS callback, and doesn't have the
problem.

-}
scrollToInstance : Float -> String -> Cmd Msg
scrollToInstance delayMs instanceId =
    Process.sleep delayMs
        |> Task.andThen
            (\_ ->
                Task.map3 (\chip strip viewport -> ( chip, strip, viewport ))
                    (Dom.getElement (instanceChipDomId instanceId))
                    (Dom.getElement instanceStripDomId)
                    (Dom.getViewportOf instanceStripDomId)
            )
        |> Task.map
            (\( chip, strip, viewport ) ->
                let
                    chipLeftWithinStrip =
                        chip.element.x - strip.element.x
                in
                viewport.viewport.x
                    + chipLeftWithinStrip
                    - (viewport.viewport.width / 2)
                    + (chip.element.width / 2)
            )
        |> Task.attempt GotScrollTarget


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
                            scrollToInstance 300 model.eventId |> Effect.fromCmd

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

        MediaEditClicked post ->
            ( { model | mediaEditActive = True }
            , Effect.fromShared
                (Shared.MyMediaPanelMsg
                    (MyMediaPanel.Open
                        (Just (MyMediaPanel.MultiSelect { initialSelection = post.media }))
                        model.targetHost
                    )
                )
            )

        GotMediaUpdateResult (Ok ( maybeAccountsPanelMsg, updatedPost )) ->
            ( applyUpdatedEventPost model updatedPost, accountsPanelEffect maybeAccountsPanelMsg )

        GotMediaUpdateResult (Err _) ->
            ( model, Effect.none )

        PostFieldsEditClicked post ->
            ( { model
                | postFieldsEdit =
                    Just
                        { pendingTitle = Maybe.withDefault "" post.title
                        , pendingLink = Maybe.withDefault "" post.link
                        , pendingContent = Maybe.withDefault "" post.content
                        , status = Idle
                        }
              }
            , Effect.none
            )

        PostFieldsTitleChanged text ->
            ( { model | postFieldsEdit = model.postFieldsEdit |> Maybe.map (\edit -> { edit | pendingTitle = text }) }, Effect.none )

        PostFieldsLinkChanged text ->
            ( { model | postFieldsEdit = model.postFieldsEdit |> Maybe.map (\edit -> { edit | pendingLink = text }) }, Effect.none )

        PostFieldsContentChanged text ->
            ( { model | postFieldsEdit = model.postFieldsEdit |> Maybe.map (\edit -> { edit | pendingContent = text }) }, Effect.none )

        PostFieldsCancelClicked ->
            ( { model | postFieldsEdit = Nothing }, Effect.none )

        PostFieldsSaveClicked post ->
            case ( model.postFieldsEdit, serverAndAccount shared model ) of
                ( Just edit, Just ( server, account ) ) ->
                    ( { model | postFieldsEdit = Just { edit | status = Submitting } }
                    , Posts.updatePost
                        shared.accountsPanel
                        ( Just account.userId, server.frontendHost )
                        post.id
                        (\freshPost ->
                            { freshPost
                                | title = nonBlank edit.pendingTitle
                                , link = nonBlank edit.pendingLink
                                , content = nonBlank edit.pendingContent
                            }
                        )
                        |> Task.attempt GotPostFieldsSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotPostFieldsSaveResult (Ok ( maybeAccountsPanelMsg, updatedPost )) ->
            let
                updatedModel =
                    applyUpdatedEventPost model updatedPost
            in
            ( { updatedModel | postFieldsEdit = Nothing }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotPostFieldsSaveResult (Err err) ->
            ( { model
                | postFieldsEdit =
                    model.postFieldsEdit |> Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })
              }
            , Effect.none
            )

        ModerationEditClicked event ->
            case event.post of
                Just post ->
                    ( { model | moderationEdit = Just { pending = post.moderation, status = Idle } }, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        ModerationChanged text ->
            ( { model
                | moderationEdit =
                    model.moderationEdit
                        |> Maybe.map (\edit -> { edit | pending = Posts.moderationFromText text |> Maybe.withDefault edit.pending })
              }
            , Effect.none
            )

        ModerationCancelClicked ->
            ( { model | moderationEdit = Nothing }, Effect.none )

        ModerationSaveClicked event ->
            case ( model.moderationEdit, event.post, serverAndAccount shared model ) of
                ( Just edit, Just post, Just ( server, account ) ) ->
                    ( { model | moderationEdit = Just { edit | status = Submitting } }
                    , Posts.updatePost
                        shared.accountsPanel
                        ( Just account.userId, server.frontendHost )
                        post.id
                        (\freshPost -> { freshPost | moderation = edit.pending })
                        |> Task.attempt GotModerationSaveResult
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotModerationSaveResult (Ok ( maybeAccountsPanelMsg, updatedPost )) ->
            let
                updatedModel =
                    applyUpdatedEventPost model updatedPost
            in
            ( { updatedModel | moderationEdit = Nothing }
            , accountsPanelEffect maybeAccountsPanelMsg
            )

        GotModerationSaveResult (Err err) ->
            ( { model
                | moderationEdit =
                    model.moderationEdit |> Maybe.map (\edit -> { edit | status = SubmitFailed (AccountsPanel.grpcErrorToString err) })
              }
            , Effect.none
            )

        DeleteClicked event ->
            ( model, Effect.fromShared (Shared.RequestDelete (Shared.ConfirmEventDelete event model.targetHost)) )

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
            if mode == model.instanceHistoryDisplay then
                -- Clicking the already-active mode's button changes nothing
                -- to animate (see `historyButtonView`'s highlighting) -- just
                -- re-centers the strip on the current instance right away,
                -- e.g. after the user's scrolled it away by hand.
                ( model, scrollToInstance 0 model.eventId |> Effect.fromCmd )

            else
                ( { model | instanceHistoryDisplay = mode } |> syncInstanceAnimations
                , scrollToInstance 1000 model.eventId |> Effect.fromCmd
                )

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

        GotScrollTarget (Ok target) ->
            ( model
            , Ports.scrollElementLeft
                (Encode.object
                    [ ( "id", Encode.string instanceStripDomId )
                    , ( "left", Encode.float (max 0 target) )
                    ]
                )
                |> Effect.fromCmd
            )

        GotScrollTarget (Err _) ->
            ( model, Effect.none )

        Poll ->
            fetchIfReady shared model

        SharedMsg subMsg ->
            let
                ( fetchedModel, fetchEffect ) =
                    case subMsg of
                        Shared.AccountsPanelMsg _ ->
                            fetchIfReady shared model

                        -- See `Pages.Post.PostId_`'s own identical branch --
                        -- `mediaEditActive` (set by `MediaEditClicked`) gates
                        -- this the same way `avatarEdit`/`mediaEditActive`
                        -- gate their own panels elsewhere, so an unrelated
                        -- Save from some other use of the panel can't be
                        -- mistaken for this page's own Event Post edit.
                        Shared.MyMediaPanelMsg (MyMediaPanel.SaveMediaClicked mediaRefs) ->
                            if model.mediaEditActive then
                                case ( model.eventStatus, serverAndAccount shared model ) of
                                    ( EventLoaded event _, Just ( server, account ) ) ->
                                        case event.post of
                                            Just eventPost ->
                                                ( { model | mediaEditActive = False }
                                                , Posts.updatePost
                                                    shared.accountsPanel
                                                    ( Just account.userId, server.frontendHost )
                                                    eventPost.id
                                                    (\freshPost -> { freshPost | media = mediaRefs })
                                                    |> Task.attempt GotMediaUpdateResult
                                                    |> Effect.fromCmd
                                                )

                                            Nothing ->
                                                ( { model | mediaEditActive = False }, Effect.none )

                                    _ ->
                                        ( { model | mediaEditActive = False }, Effect.none )

                            else
                                ( model, Effect.none )

                        Shared.MyMediaPanelMsg MyMediaPanel.CloseClicked ->
                            ( { model | mediaEditActive = False }, Effect.none )

                        -- This page's own `DeleteClicked` (via
                        -- `Shared.RequestDelete`/`Shared.ConfirmDelete`)
                        -- resolving successfully -- navigate away, since
                        -- there's nothing left here to show.
                        Shared.GotEventDeleteResult (Ok _) ->
                            ( model, Request.pushRoute Gen.Route.Home_ req |> Effect.fromCmd )

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

        -- Slotted into the primary (`Event`) `postSection` as its
        -- `extraContent`, between the byline and the media display -- the
        -- currently-viewed `EventInstance`'s own start/end/location, then
        -- (below that) the date-picker strip to switch to a sibling one.
        instanceDetailAndStrip =
            div [ class "event-instance-detail-and-strip" ]
                [ div [ class "event-instance-detail" ]
                    [ div [ class "event-instance-when" ] [ text "📅 ", Events.instanceTimeRangeText shared.browserTimeZone instance ]
                    , case instance.location |> Maybe.andThen Events.locationText of
                        Just locationLine ->
                            div [ class "event-instance-where" ] [ text "📍 ", text locationLine ]

                        Nothing ->
                            text ""
                    ]
                , instanceHistoryView shared model event instance
                ]
    in
    div [ classes [ "event-detail", hostnameToCSSClass model.targetHost, "border-color-primary-anchor-50" ] ]
        [ case event.post of
            Just eventPost ->
                case model.postFieldsEdit of
                    Just edit ->
                        postFieldsEditView edit eventPost

                    Nothing ->
                        div []
                            [ postSection
                                (MediaClicked eventPost)
                                True
                                (moderationView maybeAccount model.moderationEdit event eventPost)
                                instanceDetailAndStrip
                                eventPost
                            , div [ class "event-post-media-edit-row" ] [ Posts.mediaEditButton maybeAccount (MediaEditClicked eventPost) eventPost ]
                            , div [ class "event-post-edit-row" ]
                                [ postFieldsEditButtonView maybeAccount eventPost
                                , deleteButtonView maybeAccount event eventPost
                                ]
                            ]

            Nothing ->
                text ""
        , case instance.post |> Maybe.andThen Events.meaningfulPost of
            Just instancePost ->
                postSection (MediaClicked instancePost) False (text "") (text "") instancePost

            Nothing ->
                text ""
        , instanceMetaView shared model instance
        , syncedFromView event
        ]


{-| The Event's own `Post`'s title/link/content edit form -- replaces
`postSection` entirely while open (see `eventDetailView`), rather than
overlaying it, so there's no confusing duplicate display of the same fields
being edited. Mirrors `Pages.Post.PostId_.visibilityView`'s edit half in
spirit (a `pending`-vs-loaded split via `Model.postFieldsEdit`), just with
plain `<input>`/`<textarea>` fields instead of a `<select>`.
-}
postFieldsEditView : PostFieldsEdit -> Post -> Html Msg
postFieldsEditView edit post =
    div [ class "event-post-fields-edit" ]
        [ Html.input
            [ type_ "text"
            , class "event-post-fields-edit-title"
            , placeholder "Title"
            , value edit.pendingTitle
            , onInput PostFieldsTitleChanged
            ]
            []
        , Html.input
            [ type_ "text"
            , class "event-post-fields-edit-link"
            , placeholder "Link (optional)"
            , value edit.pendingLink
            , onInput PostFieldsLinkChanged
            ]
            []
        , textarea
            [ class "event-post-fields-edit-content"
            , placeholder "Content (optional, Markdown)"
            , value edit.pendingContent
            , onInput PostFieldsContentChanged
            ]
            []
        , div [ class "event-post-fields-edit-actions" ]
            [ button
                [ classes [ "event-post-fields-save", "background-color-primary" ]
                , onClick (PostFieldsSaveClicked post)
                , disabled (edit.status == Submitting)
                ]
                [ text
                    (if edit.status == Submitting then
                        "Saving…"

                     else
                        "Save"
                    )
                ]
            , button
                [ class "event-post-fields-cancel"
                , onClick PostFieldsCancelClicked
                , disabled (edit.status == Submitting)
                ]
                [ text "Cancel" ]
            , case edit.status of
                SubmitFailed err ->
                    span [ class "event-post-fields-error" ] [ text err ]

                _ ->
                    text ""
            ]
        ]


{-| Opens `postFieldsEditView` -- shown to `post`'s own author or an Admin,
mirroring `Pages.Post.PostId_`'s own `isAuthor account post`-gated edit
affordances (media edit, visibility edit).
-}
postFieldsEditButtonView : Maybe AccountsPanel.Account -> Post -> Html Msg
postFieldsEditButtonView maybeAccount post =
    case maybeAccount of
        Just account ->
            if Posts.isAuthor account post || List.member ADMIN account.permissions then
                button [ class "event-post-edit-button", onClick (PostFieldsEditClicked post) ] [ text "Edit" ]

            else
                text ""

        Nothing ->
            text ""


{-| The delete button for the Event's own `Post`, shown only to its own
owner (per this feature's own scope -- unlike `postFieldsEditButtonView`,
not extended to Admins here) -- opens the shared "are you sure?" dialog via
`DeleteClicked`/`Shared.ConfirmEventDelete`.
-}
deleteButtonView : Maybe AccountsPanel.Account -> Event -> Post -> Html Msg
deleteButtonView maybeAccount event post =
    case maybeAccount of
        Just account ->
            if Posts.isAuthor account post then
                button [ class "event-delete-button", onClick (DeleteClicked event) ] [ text "Delete" ]

            else
                text ""

        Nothing ->
            text ""


{-| The moderation-status segment slotted into `postSection`'s byline (see
its own `moderationView` param) -- shown only to an Admin or a
`MODERATEEVENTS` holder, mirroring `Pages.Post.PostId_.visibilityView`'s
display-vs-editing split, just for `Moderation` instead of `Visibility`, and
its own "Edit" button reading "Moderate" instead (per this feature's own
request, to read distinctly from `postFieldsEditButtonView`'s "Edit").
-}
moderationView : Maybe AccountsPanel.Account -> Maybe ModerationEdit -> Event -> Post -> Html Msg
moderationView maybeAccount maybeEdit event post =
    case maybeAccount of
        Nothing ->
            text ""

        Just account ->
            if not (List.member ADMIN account.permissions || List.member MODERATEEVENTS account.permissions) then
                text ""

            else
                case maybeEdit of
                    Just edit ->
                        span [ class "event-post-moderation-edit" ]
                            [ text " · "
                            , select [ onInput ModerationChanged ]
                                (Posts.allModerations
                                    |> List.map
                                        (\moderation ->
                                            option
                                                [ value (Users.moderationText moderation)
                                                , selected (edit.pending == moderation)
                                                ]
                                                [ text (Users.moderationText moderation) ]
                                        )
                                )
                            , button
                                [ classes [ "event-post-moderation-save", "background-color-primary" ]
                                , onClick (ModerationSaveClicked event)
                                , disabled (edit.status == Submitting)
                                ]
                                [ text
                                    (if edit.status == Submitting then
                                        "Saving…"

                                     else
                                        "Save"
                                    )
                                ]
                            , button
                                [ class "event-post-moderation-cancel"
                                , onClick ModerationCancelClicked
                                , disabled (edit.status == Submitting)
                                ]
                                [ text "Cancel" ]
                            , case edit.status of
                                SubmitFailed err ->
                                    span [ class "event-post-moderation-error" ] [ text err ]

                                _ ->
                                    text ""
                            ]

                    Nothing ->
                        span [ class "event-post-moderation-display" ]
                            [ text (" · " ++ Users.moderationText post.moderation)
                            , button [ class "event-post-moderation-edit-button", onClick (ModerationEditClicked event) ] [ text "Moderate" ]
                            ]


{-| The star button + comment count for `instance`'s own `Post` -- bottom
right of the detail view, mirroring `eventCard`'s own bottom-right meta (see
`Components.Events.eventCard`'s doc) rather than `event.post`'s: each
`EventInstance` of a recurring `Event` gets its own independent star/comment
count, the same way it gets its own `Post` row. Renders nothing if
`instance.post` is unset (shouldn't happen in practice, but the field is
optional on the wire).
-}
instanceMetaView : Shared.Model -> Model -> EventInstance -> Html Msg
instanceMetaView shared model instance =
    case instance.post of
        Just instancePost ->
            let
                displayPost =
                    StarredPanel.freshestPost model.targetHost instancePost shared.starredPanel

                starred =
                    StarredPanel.isStarred model.targetHost displayPost shared.starredPanel

                onStarClicked =
                    StarredPanel.toggleStarMsg shared.accountsPanel model.targetHost displayPost
                        |> Maybe.map (Shared.StarredPanelMsg >> SharedMsg)
            in
            div [ class "event-detail-meta" ]
                [ span [ class "post-meta-right" ]
                    [ Posts.starButton model.targetHost starred onStarClicked displayPost
                    , text (Posts.commentCountText displayPost)
                    ]
                ]

        Nothing ->
            text ""


{-| One small-text, clipped-not-wrapped line at the bottom of the event
detail view, crediting the ICS feed this `Event` was pulled in from (see
`Shared.EventSyncSourcesPanel`) -- renders nothing for a normal, non-synced
event.
-}
syncedFromView : Event -> Html Msg
syncedFromView event =
    case event.eventSyncSource |> Maybe.andThen .configuration of
        Just (Configuration.IcsSubscriptionUrl url) ->
            div [ class "event-synced-from" ]
                [ text "synced from "
                , a [ href url, class "event-synced-from-link" ] [ text url ]
                ]

        _ ->
            text ""


{-| The date-picker strip: all 3 "switch scope" buttons (see `historyButtons`)
plus, once there's more than 3 chips to justify it, a scroll/grid layout
toggle (see `instanceLayoutButtonView`), above either a
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
            minimumRank =
                historyDisplayRank (minimumHistoryDisplayFor model.now instance)

            showLayoutToggle =
                List.length event.instances > 3
        in
        div [ class "event-instance-history" ]
            [ div [ class "event-instance-history-buttons" ]
                (List.map (historyButtonView model minimumRank) (historyButtons model event)
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


{-| Icon-only toggle between the strip's two layouts (see `InstanceLayout`) --
always the same glyph (☰), rotated 90° via `.event-instance-layout-icon-rotated`
(a CSS `transition`, see `events.css`) while `GridLayout` is active, rather
than swapping to a second glyph -- labeled (via `aria-label`/`title`, for
accessibility and a hover tooltip since the glyph itself doesn't change) for
whichever layout it would switch _to_, not the current one. Always
right-aligned (`.event-instance-layout-button`, see `events.css`) in the
buttons row, regardless of how many "switch scope" buttons
(`historyButtonView`) precede it.
-}
instanceLayoutButtonView : InstanceLayout -> Html Msg
instanceLayoutButtonView layout =
    let
        ( targetLayout, targetLabel ) =
            case layout of
                StripLayout ->
                    ( GridLayout, "Grid view" )

                GridLayout ->
                    ( StripLayout, "List view" )
    in
    button
        [ classes [ "event-instance-history-button", "event-instance-layout-button" ]
        , onClick (InstanceLayoutChanged targetLayout)
        , attribute "aria-label" targetLabel
        , title targetLabel
        ]
        [ span
            [ classes
                ("event-instance-layout-icon"
                    :: (if layout == GridLayout then
                            [ "event-instance-layout-icon-rotated" ]

                        else
                            []
                       )
                )
            ]
            [ text "☰" ]
        ]


{-| One of the 3 "switch scope" buttons -- highlighted (`background-color-primary`)
if `mode` is `model.instanceHistoryDisplay` itself, disabled if `mode` is more
restrictive than `minimumRank` (see `historyButtons`' own doc) since
switching to it would hide `instance`, the very one this page is showing.
-}
historyButtonView : Model -> Int -> ( InstanceHistoryDisplay, Int ) -> Html Msg
historyButtonView model minimumRank ( mode, count ) =
    let
        isCurrent =
            mode == model.instanceHistoryDisplay
    in
    button
        [ classes
            ("event-instance-history-button"
                :: (if isCurrent then
                        [ "background-color-primary" ]

                    else
                        []
                   )
            )
        , onClick (HistoryDisplayChanged mode)
        , disabled (historyDisplayRank mode < minimumRank)
        ]
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


{-| The 3 "switch scope" buttons to show above the strip, always all 3 (see
`historyButtonView` for how the current one is highlighted instead of
omitted, and how one more restrictive than `minimumHistoryDisplayFor
model.now instance` -- which would hide `instance`, the very one this page
is showing -- is disabled instead of hidden).
-}
historyButtons : Model -> Event -> List ( InstanceHistoryDisplay, Int )
historyButtons model event =
    let
        countFor mode =
            event.instances |> List.filter (instanceMatchesHistoryDisplay model.now mode) |> List.length
    in
    [ ShowAllInstances, SinceTwoWeeksAgo, OnlyFuture ]
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
