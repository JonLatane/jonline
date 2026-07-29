module Components.Events exposing
    ( eventCard
    , eventInstanceHref
    , eventInstancePairs
    , fetchEvent
    , fetchEvents
    , findInstance
    , instanceDateText
    , instanceMoment
    , instanceTimeRangeText
    , locationText
    , meaningfulPost
    , parseEventRouteId
    , postSection
    )

{-| Shared building blocks for displaying `Proto.Jonline.Event`s/`EventInstance`s
-- used by `Pages.Event.EventId_` (a single-instance detail view: building a
`GetEvents` request scoped to a single `EventInstance` via
`Shared.MaybeAccountRequest`, parsing/building the `/event/:eventId` route's
`id`/`id@host` segment, an `EventInstance.id` despite the route/field being
named "eventId" -- see that module's own doc) and by
`Components.Pages.EventsPage` (a multi-`Event` listing: `fetchEvents`/
`eventInstancePairs`/`eventCard`), plus the `Post`/timing rendering helpers
both share.
-}

import Components.Authors as Authors
import Components.Markdown as Markdown
import Components.MultiMediaRenderer as MultiMediaRenderer
import Components.Posts as Posts
import Gen.Route
import Grpc
import Html exposing (Html, a, div, h1, h2, span, text)
import Html.Attributes exposing (attribute, class, href, rel, target)
import Proto.Jonline exposing (Event, EventInstance, GetEventsResponse, Location, Post, defaultGetEventsRequest, defaultTimeFilter)
import Proto.Jonline.Jonline as Jonline
import Shared.AccountsPanel as AccountsPanel exposing (performWithOptionalAccountServer, withAccessToken)
import Shared.BrowserTimeZone as BrowserTimeZone exposing (BrowserTimeZone)
import Shared.Conversions exposing (posixToTimestamp, timestampToPosix)
import Task exposing (Task)
import Time
import UI.Classes exposing (classes, hostnameToCSSClass)


{-| Fetches the `Event` (with all its `EventInstance`s -- see
`GetEventsResponse`'s own doc: a request scoped to one `event_instance_id`
gets every instance of that instance's parent `Event` back, not just the one
asked for) containing `eventInstanceId`, from `maybeAccountServer`'s server,
authenticated as its account if any, anonymous otherwise -- same
auth/refresh handling as `Components.Posts.fetchPost`.
-}
fetchEvent :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetEventsResponse )
fetchEvent accountsPanelModel maybeAccountServer eventInstanceId =
    performWithOptionalAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server maybeToken ->
            Grpc.new Jonline.getEvents { defaultGetEventsRequest | eventInstanceId = Just eventInstanceId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken maybeToken
                |> Grpc.toTask
        )


{-| Fetches `Event`s ending after `endsAfter` from `maybeAccountServer`'s
server, authenticated as its account if any -- for
`Components.Pages.EventsPage`'s listing, rather than `fetchEvent`'s single
`EventInstance` lookup. `authorUserId`, if given, restricts the results to
that user's own events (mirrors `Components.Posts.fetchPosts`' own
`authorUserId` param), for that module's use on a user's own events page.

`GetEventsRequest.timeFilter.endsAfter` is the only time filter
`backend/src/rpcs/events/get_events.rs` actually implements (see its
`query_visible_events!` macro), excluding any `EventInstance` that's already
ended as of `endsAfter` -- `EventsPage` passes the live current time for its
default "Upcoming Events" tab, or a user-picked cutoff for its "Events After
&lt;date&gt;" one, so this is deliberately not called `now` (it isn't,
always). `GetEventsResponse` isn't itself flattened per-`EventInstance` --
see `eventInstancePairs`.
-}
fetchEvents :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> Maybe String
    -> Time.Posix
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetEventsResponse )
fetchEvents accountsPanelModel maybeAccountServer authorUserId endsAfter =
    let
        request =
            { defaultGetEventsRequest
                | authorUserId = authorUserId
                , timeFilter = Just { defaultTimeFilter | endsAfter = Just (posixToTimestamp endsAfter) }
            }
    in
    performWithOptionalAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server maybeToken ->
            Grpc.new Jonline.getEvents request
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken maybeToken
                |> Grpc.toTask
        )


{-| Flattens a `GetEventsResponse` into `(Event, EventInstance)` pairs -- for
any listing request (unlike `fetchEvent`'s single-`event_instance_id` request,
which returns one `Event` with every one of its instances),
`get_public_and_following_events`/`get_user_events` each return **one `Event`
per matching `EventInstance` row**, with `instances` holding just that one
instance (see `events.proto`'s own doc comment on `GetEventsResponse`: "the
response will carry duplicate `Event`s with the same ID" -- one entry per
instance in the requested time frame). `Components.Pages.EventsPage` centers
its whole listing on the `EventInstance`, same as `Pages.Event.EventId_`'s own
detail view, so this is written generically (flat-mapping every `Event`'s
`instances`, however many there are) rather than assuming exactly one.
-}
eventInstancePairs : GetEventsResponse -> List ( Event, EventInstance )
eventInstancePairs response =
    response.events
        |> List.concatMap (\event -> List.map (\instance -> ( event, instance )) event.instances)



-- ROUTE / LINKS


{-| `rawEventId` is either a bare `EventInstance` id (an event on
`mainFrontendHost`) or `id@host` (one on some other, federated server) --
mirrors `Components.Posts.parsePostRouteId` exactly.
-}
parseEventRouteId : String -> String -> ( String, String )
parseEventRouteId mainFrontendHost rawEventId =
    case String.split "@" rawEventId of
        [ id, host ] ->
            ( id, host )

        _ ->
            ( rawEventId, mainFrontendHost )


{-| Finds the `EventInstance` (of `event.instances`) with the given id --
`Pages.Event.EventId_` uses this to pick out, from the full `Event` a
`GetEvents` response carries, the one specific instance the page's own route
was asking for.
-}
findInstance : String -> Event -> Maybe EventInstance
findInstance instanceId event =
    event.instances |> List.filter (\instance -> instance.id == instanceId) |> List.head


{-| The href for `instance`, as seen from `viewingServerHost` -- mirrors
`Components.Posts.postHref`, just keyed on an `EventInstance.id` (the route
segment, despite `Gen.Route`/`Gen.Params` naming it "eventId") rather than a
`Post.id`. Used by `Pages.Event.EventId_`'s date-picker strip to link between
sibling `EventInstance`s of the same `Event`.
-}
eventInstanceHref : String -> String -> String -> EventInstance -> String
eventInstanceHref basePath viewingServerHost eventServerHost instance =
    let
        routeId =
            if eventServerHost == viewingServerHost then
                instance.id

            else
                instance.id ++ "@" ++ eventServerHost
    in
    basePath ++ Gen.Route.toHref (Gen.Route.Event__EventId_ { eventId = routeId })



-- DISPLAY


{-| The instant that best represents "when" an `EventInstance` is -- `endsAt`
if set (an instance stays current until it actually ends), falling back to
`startsAt` (at least one of the two should always be set), `Nothing` only if
neither is. Used both for filtering/sorting an `Event`'s instances by
recency (see `Pages.Event.EventId_`'s `InstanceHistoryDisplay`) and, via
`instanceDateText`, for display.
-}
instanceMoment : EventInstance -> Maybe Time.Posix
instanceMoment instance =
    case instance.endsAt of
        Just ts ->
            Just (timestampToPosix ts)

        Nothing ->
            instance.startsAt |> Maybe.map timestampToPosix


{-| A compact, date-only label for `instance` (in `browserTimeZone`) -- e.g.
for `Pages.Event.EventId_`'s date-picker strip, where a full
`instanceTimeRangeText` would be too wide for a chip. Prefers `startsAt`
(the date someone would actually plan around), falling back to `endsAt`.
-}
instanceDateText : BrowserTimeZone -> EventInstance -> String
instanceDateText browserTimeZone instance =
    case instance.startsAt of
        Just ts ->
            BrowserTimeZone.formatDate browserTimeZone.zone (timestampToPosix ts)

        Nothing ->
            case instance.endsAt of
                Just ts ->
                    BrowserTimeZone.formatDate browserTimeZone.zone (timestampToPosix ts)

                Nothing ->
                    "Date TBD"


{-| An `EventInstance`'s start/end time, both in `browserTimeZone` -- just the
start if there's no end time, "Until `end`" if (unusually) there's an end but
no start, or a placeholder if somehow neither is set.
-}
instanceTimeRangeText : BrowserTimeZone -> EventInstance -> Html msg
instanceTimeRangeText browserTimeZone instance =
    let
        startText =
            Maybe.map (timestampToPosix >> BrowserTimeZone.formatDateTime browserTimeZone) instance.startsAt

        endText =
            Maybe.map (timestampToPosix >> BrowserTimeZone.formatDateTime browserTimeZone) instance.endsAt

        rangeText =
            case ( startText, endText ) of
                ( Just start, Just end ) ->
                    start ++ " – " ++ end

                ( Just start, Nothing ) ->
                    start

                ( Nothing, Just end ) ->
                    "Until " ++ end

                ( Nothing, Nothing ) ->
                    "Time TBD"
    in
    span [ class "event-instance-time" ] [ text rangeText ]


{-| `location.uniformlyFormattedAddress`, trimmed -- `Nothing` if blank, same
convention as `Components.Posts.postLinkText`.
-}
locationText : Location -> Maybe String
locationText location =
    let
        trimmed =
            String.trim location.uniformlyFormattedAddress
    in
    if String.isEmpty trimmed then
        Nothing

    else
        Just trimmed


{-| Renders one of an `Event`/`EventInstance`'s `Post`s -- title, link, a
byline (author + visibility), `extraContent`, then media and content.
`primary` picks an `h1` (for the `Event`'s own `Post`, the thing actually
titling the page) vs. an `h2` (for an `EventInstance`'s own override `Post`,
a secondary "about this date" block) -- unlike `Components.Posts.postDetail`,
there's no title-vs-context-chip branching here: both an `Event`'s and an
`EventInstance`'s `Post` carry a real name of their own (see `events.proto`'s
doc on `EventInstance.post`), not a generic reply/thread entry, so both
always get a real heading. Deliberately lighter than `postDetail` otherwise
too -- no star/edit/reply affordances, since `Pages.Event.EventId_` is a
read-only invitation-style view, not a full post management page.

`extraContent` sits right after the byline and before media -- e.g.
`Pages.Event.EventId_` slots the currently-viewed `EventInstance`'s own
date/location and its date-picker strip in there for the primary (`Event`)
section, `text ""` for the secondary (`EventInstance`) section, which has
nothing of its own to add there.

-}
postSection :
    BrowserTimeZone
    -> String
    -> String
    -> String
    -> Maybe AccountsPanel.Server
    -> Maybe AccountsPanel.Account
    -> (String -> msg)
    -> Bool
    -> Html msg
    -> Post
    -> Html msg
postSection browserTimeZone basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked primary extraContent post =
    div
        [ classes
            [ "event-post-section"
            , hostnameToCSSClass postServerHost
            , if primary then
                "event-post-primary"

              else
                "event-post-secondary"
            ]
        ]
        [ if primary then
            h1 [ class "event-post-title" ] [ text (Posts.postTitleText post) ]

          else
            h2 [ class "event-post-title" ] [ text (Posts.postTitleText post) ]
        , case Posts.postLinkText post of
            Just link ->
                a
                    [ href link
                    , target "_blank"
                    , rel "noopener noreferrer"
                    , classes [ hostnameToCSSClass postServerHost, "event-post-link" ]
                    ]
                    [ text link ]

            Nothing ->
                text ""
        , div [ class "event-post-meta" ]
            [ text "by "
            , Authors.link basePath viewingServerHost postServerHost maybeServer maybeAccount post.author
            , text (" · " ++ Posts.postVisibilityText post)
            ]
        , extraContent
        , case maybeServer of
            Just server ->
                MultiMediaRenderer.view server maybeAccount onMediaClicked post.media

            Nothing ->
                text ""
        , case post.content of
            Just content ->
                Markdown.view [ class "event-post-content" ] content

            Nothing ->
                text ""
        ]


{-| `post` itself, unless it has nothing an `EventInstance`'s own override
`Post` would actually add over the parent `Event`'s -- no title, link,
content, or media, just the empty shell every `EventInstance` carries whether
or not its creator actually filled one in. `Pages.Event.EventId_.eventDetailView`
uses this to skip its own secondary `postSection` entirely for one of these;
`eventCard` uses it the same way, to skip an instance-specific note line.
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


{-| A compact, read-only card for one `(Event, EventInstance)` pair --
`Components.Pages.EventsPage`'s per-item rendering, centered on `instance`
(its own start/end/location) the same way `Pages.Event.EventId_`'s detail view
is, but titled/linked/media'd off `event.post` (the `Event`'s own name/link/
media -- the "primary" `Post`, same primacy `eventDetailView` gives it),
mirroring `Components.Posts.postCard`'s stretched-link-overlay card shape.
Renders nothing if `event.post` is unset (shouldn't happen in practice --
every `Event` is created with one -- but the field is optional on the wire).
-}
eventCard :
    BrowserTimeZone
    -> String
    -> String
    -> String
    -> Maybe AccountsPanel.Server
    -> Maybe AccountsPanel.Account
    -> (String -> msg)
    -> Event
    -> EventInstance
    -> Html msg
eventCard browserTimeZone basePath viewingServerHost eventServerHost maybeServer maybeAccount onMediaClicked event instance =
    case event.post of
        Nothing ->
            text ""

        Just eventPost ->
            div
                [ classes
                    [ "event-card"
                    , hostnameToCSSClass eventServerHost
                    , "border-color-primary-anchor-50"
                    , "hover-border-color-primary-anchor"
                    , "background-color-primary-5"
                    ]
                ]
                [ a
                    [ href (eventInstanceHref basePath viewingServerHost eventServerHost instance)
                    , class "event-card-link-overlay"
                    , attribute "aria-label" (Posts.postTitleText eventPost)
                    ]
                    []
                , div [ class "event-card-title" ] [ text (Posts.postTitleText eventPost) ]
                , div [ class "event-card-when" ] [ text "📅 ", instanceTimeRangeText browserTimeZone instance ]
                , case instance.location |> Maybe.andThen locationText of
                    Just locationLine ->
                        div [ class "event-card-where" ] [ text "📍 ", text locationLine ]

                    Nothing ->
                        text ""
                , case maybeServer of
                    Just server ->
                        MultiMediaRenderer.previewExtraSmall server maybeAccount onMediaClicked eventPost.media

                    Nothing ->
                        text ""
                , case eventPost.content of
                    Just content ->
                        Markdown.view
                            [ classes
                                (if String.length content > Posts.contentPreviewFadeThreshold then
                                    [ "event-card-content-preview", "event-card-content-preview-fade" ]

                                 else
                                    [ "event-card-content-preview" ]
                                )
                            ]
                            content

                    Nothing ->
                        text ""
                , case instance.post |> Maybe.andThen meaningfulPost of
                    Just instancePost ->
                        div [ class "event-card-instance-note" ] [ text (Posts.postTitleText instancePost) ]

                    Nothing ->
                        text ""
                , div [ class "event-card-meta" ]
                    [ Authors.link basePath viewingServerHost eventServerHost maybeServer maybeAccount eventPost.author
                    , text (" · " ++ Posts.postVisibilityText eventPost)
                    ]
                ]
