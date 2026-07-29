module Components.Events exposing
    ( eventInstanceHref
    , fetchEvent
    , findInstance
    , instanceDateText
    , instanceMoment
    , instanceTimeRangeText
    , locationText
    , parseEventRouteId
    , postSection
    )

{-| Shared building blocks for displaying `Proto.Jonline.Event`s/`EventInstance`s
-- currently just what `Pages.Event.EventId_` needs: building a `GetEvents`
request scoped to a single `EventInstance` (via `Shared.MaybeAccountRequest`),
parsing/building the `/event/:eventId` route's `id`/`id@host` segment (an
`EventInstance.id`, despite the route/field being named "eventId" -- see
`Pages.Event.EventId_`'s own module doc), and rendering the `Post`/timing each
of an `Event` and its `EventInstance`s carries.
-}

import Components.Authors as Authors
import Components.Markdown as Markdown
import Components.MultiMediaRenderer as MultiMediaRenderer
import Components.Posts as Posts
import Gen.Route
import Grpc
import Html exposing (Html, a, div, h1, h2, span, text)
import Html.Attributes exposing (class, href, rel, target)
import Proto.Jonline exposing (Event, EventInstance, GetEventsResponse, Location, Post, defaultGetEventsRequest)
import Proto.Jonline.Jonline as Jonline
import Shared.AccountsPanel as AccountsPanel exposing (performWithOptionalAccountServer, withAccessToken)
import Shared.BrowserTimeZone as BrowserTimeZone exposing (BrowserTimeZone)
import Shared.Conversions exposing (timestampToPosix)
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
