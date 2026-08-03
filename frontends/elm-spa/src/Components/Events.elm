module Components.Events exposing
    ( deleteEvent
    , eventCard
    , eventInstanceHref
    , eventInstancePairs
    , fetchEvent
    , fetchEvents
    , fetchEventsByInstancePostIds
    , findInstance
    , instanceEndsOrStartsAt
    , instanceStartsOrEndsAt
    , instanceWhenText
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
import Components.MediaRenderer as MediaRenderer
import Components.MultiMediaRenderer as MultiMediaRenderer
import Components.Posts as Posts
import Gen.Route
import Grpc
import Html exposing (Html, a, div, h1, h2, span, text)
import Html.Attributes exposing (attribute, class, href, rel, target)
import Proto.Jonline exposing (Event, EventInstance, GetEventsResponse, Location, Post, defaultEvent, defaultGetEventsRequest, defaultTimeFilter)
import Proto.Jonline.EventListingType exposing (EventListingType(..))
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


{-| Deletes `eventId` (the `Event`'s own id, not an `EventInstance`'s)
outright (`DeleteEvent`, owner-or-Admin gated server-side, see
`backend/src/rpcs/events/delete_event.rs`) -- nothing to overlay onto a fresh
copy first, so this just sends the id straight through, mirroring
`Components.Posts.deletePost`. Used by `Pages.Event.EventId_`'s own Delete
button, via `Shared.ConfirmEventDelete`.
-}
deleteEvent :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, Event )
deleteEvent accountsPanelModel maybeAccountServer eventId =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.deleteEvent { defaultEvent | id = eventId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
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
<date>" one, so this is deliberately not called `now` (it isn't,
always). This time filter is sent -- and still enforced -- regardless of
`searchText`; see below. `GetEventsResponse` isn't itself flattened
per-`EventInstance` -- see `eventInstancePairs`.

`searchText`, if non-blank (leading/trailing whitespace is trimmed, and a
blank string is treated the same as empty), switches the request to
`EVENT_TEXT_SEARCH` -- mirrors `Components.Posts.fetchPosts`' own
`searchText` param. Unlike `fetchPosts`, `timeFilter` is still sent either
way -- `get_search_events` (the `EVENT_TEXT_SEARCH` branch of
`backend/src/rpcs/events/get_events.rs`) still filters on it, so a search
made while on the "Upcoming Events" tab only searches upcoming events, not
every event ever.

-}
fetchEvents :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> Maybe String
    -> String
    -> Time.Posix
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetEventsResponse )
fetchEvents accountsPanelModel maybeAccountServer authorUserId searchText endsAfter =
    let
        trimmedSearchText =
            String.trim searchText

        baseRequest =
            { defaultGetEventsRequest
                | authorUserId = authorUserId
                , timeFilter = Just { defaultTimeFilter | endsAfter = Just (posixToTimestamp endsAfter) }
            }

        request =
            if String.isEmpty trimmedSearchText then
                baseRequest

            else
                { baseRequest
                    | listingType = EVENTTEXTSEARCH
                    , searchText = Just trimmedSearchText
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


{-| Fetches the `Event`/`EventInstance` data for a batch of `EventInstance`
Post ids on `maybeAccountServer`'s server, authenticated as its account if
any -- for `Shared.StarredPanel`, which already has a flat list of starred
`Post` ids (fetched individually via `Components.Posts.fetchPost`, see that
module's own doc) and, for whichever of those turn out to be an
`EventInstance`'s own Post (`PostContext.EVENT_INSTANCE`), wants back the
`Event`/`EventInstance` data `Components.Events.eventCard` needs to render
them -- one batched request per server rather than one per starred
`EventInstance` post. Unlike `fetchEvent`'s single `event_instance_id`
request (which returns the whole parent `Event` with _every_ one of its
instances, for the single-event detail page's date-picker strip), this
mirrors `fetchEvents`' own "one `Event` entry per matching `EventInstance`"
shape (see `eventInstancePairs`) -- each requested post id resolves to
exactly one `(Event, EventInstance)` pair, not a whole recurring series (see
`backend/src/rpcs/events/get_events.rs`'s `get_events_by_instance_post_ids`,
which this calls into via `GetEventsRequest.event_instance_post_ids`).
-}
fetchEventsByInstancePostIds :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> List String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetEventsResponse )
fetchEventsByInstancePostIds accountsPanelModel maybeAccountServer instancePostIds =
    performWithOptionalAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server maybeToken ->
            Grpc.new Jonline.getEvents { defaultGetEventsRequest | eventInstancePostIds = instancePostIds }
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
instanceEndsOrStartsAt : EventInstance -> Maybe Time.Posix
instanceEndsOrStartsAt instance =
    case instance.endsAt of
        Just ts ->
            Just (timestampToPosix ts)

        Nothing ->
            instance.startsAt |> Maybe.map timestampToPosix


{-| The instant `instance` begins -- `startsAt` if set, falling back to
`endsAt` (at least one of the two should always be set), `Nothing` only if
neither is. Unlike `instanceMoment` (which prefers `endsAt`, so an ongoing
event still counts as "current"), this is for chronological sorting -- e.g.
`Components.Pages.EventsPage.visibleAnimations`, which lists soonest-to-start
first.
-}
instanceStartsOrEndsAt : EventInstance -> Maybe Time.Posix
instanceStartsOrEndsAt instance =
    case instance.startsAt of
        Just ts ->
            Just (timestampToPosix ts)

        Nothing ->
            instance.endsAt |> Maybe.map timestampToPosix


{-| A human-friendly "when" label for `instance`, e.g. "August 1, 6-7PM",
"June 1, 10PM - June 8, 3AM", or "December 31, 2025, 9PM - January 1, 2AM" --
used identically by `eventCard`'s own "when" line, `Pages.Event.EventId_`'s
detail view (the currently-viewed instance's own when line), and that same
page's date-picker strip chips (see `instanceHistoryView`), so every place an
`EventInstance`'s date/time shows reads the same way. `now` supplies "the
viewer's own current year" (see `Shared.Model.now`), which
`BrowserTimeZone.formatRange`/`formatMoment` use to drop a redundant year --
see their own docs for the full set of examples this is designed against
(same-day ranges, cross-day ranges, and ranges crossing into a different
year on either side).

Both `startsAt` and `endsAt` are normally set (a merged range, via
`BrowserTimeZone.formatRange`); this falls back to just whichever one is set
(via `BrowserTimeZone.formatMoment`, prefixed "Until " if only `endsAt` is,
since that's the unusual case) or a placeholder if somehow neither is.
-}
instanceWhenText : Time.Posix -> BrowserTimeZone -> EventInstance -> String
instanceWhenText now browserTimeZone instance =
    case ( instance.startsAt, instance.endsAt ) of
        ( Just startTs, Just endTs ) ->
            BrowserTimeZone.formatRange now browserTimeZone (timestampToPosix startTs) (timestampToPosix endTs)

        ( Just startTs, Nothing ) ->
            BrowserTimeZone.formatMoment now browserTimeZone (timestampToPosix startTs)

        ( Nothing, Just endTs ) ->
            "Until " ++ BrowserTimeZone.formatMoment now browserTimeZone (timestampToPosix endTs)

        ( Nothing, Nothing ) ->
            "Time TBD"


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
too -- no star/edit/reply affordances baked in here, since this was
originally a read-only invitation-style view -- `moderationView` and the
three `*Override`s are the exceptions (see their own docs just below).

`titleOverride`/`linkOverride`/`contentOverride` each replace that one
field's normal display when `Just`, so `Pages.Event.EventId_` can inline its
own per-field display (plain text/link/Markdown plus its own "Edit X"
button) or, while that field's being edited, its edit form -- right in
place, without hiding the rest of the section the way swapping out this
whole function's result would. `Nothing` (always, for the secondary
`EventInstance` section, which isn't editable this way) falls back to the
plain-text/link/Markdown rendering below.

`moderationView` sits right after the visibility text in the byline --
`Pages.Event.EventId_`'s moderation selector for the primary (`Event`)
section, `text ""` for the secondary (`EventInstance`) section (mirrors
`extraContent`'s own split just below).

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
    -> Maybe (Html msg)
    -> Maybe (Html msg)
    -> Maybe (Html msg)
    -> Html msg
    -> Html msg
    -> Post
    -> Html msg
postSection browserTimeZone basePath viewingServerHost postServerHost maybeServer maybeAccount onMediaClicked primary titleOverride linkOverride contentOverride moderationView extraContent post =
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
        [ let
            titleContent =
                Maybe.withDefault (text (Posts.postTitleText post)) titleOverride
          in
          if primary then
            h1 [ class "event-post-title" ] [ titleContent ]

          else
            h2 [ class "event-post-title" ] [ titleContent ]
        , case linkOverride of
            Just override ->
                override

            Nothing ->
                case Posts.postLinkText post of
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
            , moderationView
            ]
        , extraContent
        , case maybeServer of
            Just server ->
                MultiMediaRenderer.view server maybeAccount onMediaClicked post.media

            Nothing ->
                text ""
        , case contentOverride of
            Just override ->
                override

            Nothing ->
                case post.content of
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

`starred`/`onStarClicked` drive the bottom-right star button, same as
`Components.Posts.postCard`'s own -- but keyed on `instance.post` (the
`EventInstance`'s own `Post`), not `event.post`: an `Event`'s recurring
instances each get their own independent star/comment count, the same way
each one gets its own `Post` row in the database (see `events.proto`'s own
doc). Renders neither the star button nor the comment count if
`instance.post` is unset (shouldn't happen in practice, same as `event.post`
above, but the field is optional on the wire).

`mediaSizing` picks how big `eventPost.media` renders (see
`Components.MediaRenderer.Sizing`) -- `ExtraSmall` renders via
`MultiMediaRenderer.previewExtraSmall`, anything else via
`MultiMediaRenderer.preview` (`Small` sizing). `Shared.StarredPanel` always
passes `ExtraSmall` (its post rows are tight on vertical space);
`Components.Pages.EventsPage` passes `ExtraSmall` only for its embedded copy,
`Small` otherwise (see its own `eventCardView`).

`current` mirrors `Components.Posts.postCard`'s own -- `True` swaps the card's
background for `background-color-primary` (plus an `event-card-current`
class, mirroring `post-card-current`) instead of the default
`background-color-primary-5`, highlighting the one matching whatever
`EventInstance` the viewer is already on. `Shared.StarredPanel` is the only
caller that ever passes `True` (see `UI.currentStarredEventInstanceKey`);
`Components.Pages.EventsPage`'s own listing always passes `False`.

-}
eventCard :
    Time.Posix
    -> BrowserTimeZone
    -> String
    -> String
    -> String
    -> Maybe AccountsPanel.Server
    -> Maybe AccountsPanel.Account
    -> (String -> msg)
    -> MediaRenderer.Sizing
    -> Bool
    -> Maybe msg
    -> Bool
    -> Event
    -> EventInstance
    -> Html msg
eventCard now browserTimeZone basePath viewingServerHost eventServerHost maybeServer maybeAccount onMediaClicked mediaSizing starred onStarClicked current event instance =
    case event.post of
        Nothing ->
            text ""

        Just eventPost ->
            div
                [ classes
                    ([ "event-card"
                     , hostnameToCSSClass eventServerHost
                     , "border-color-primary-anchor-50"
                     , "hover-border-color-primary-anchor"
                     ]
                        ++ (if current then
                                [ "event-card-current", "background-color-primary" ]

                            else
                                [ "background-color-primary-5" ]
                           )
                    )
                ]
                [ a
                    [ href (eventInstanceHref basePath viewingServerHost eventServerHost instance)
                    , class "event-card-link-overlay"
                    , attribute "aria-label" (Posts.postTitleText eventPost)
                    ]
                    []
                , div [ class "event-card-title" ] [ text (Posts.postTitleText eventPost) ]
                , case Posts.postLinkText eventPost of
                    Just link ->
                        a
                            [ href link
                            , target "_blank"
                            , rel "noopener noreferrer"
                            , classes [ hostnameToCSSClass eventServerHost, "event-card-link" ]
                            ]
                            [ text (Posts.stripLinkScheme link) ]

                    Nothing ->
                        text ""
                , div [ class "event-card-when" ] [ text "📅 ", span [ class "event-instance-time" ] [ text (instanceWhenText now browserTimeZone instance) ] ]
                , case instance.location |> Maybe.andThen locationText of
                    Just locationLine ->
                        div [ class "event-card-where" ] [ text "📍 ", text locationLine ]

                    Nothing ->
                        text ""
                , case maybeServer of
                    Just server ->
                        case mediaSizing of
                            MediaRenderer.ExtraSmall ->
                                MultiMediaRenderer.previewExtraSmall server maybeAccount onMediaClicked eventPost.media

                            _ ->
                                MultiMediaRenderer.preview server maybeAccount onMediaClicked eventPost.media

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
                    [ span [ class "post-meta-left" ]
                        [ Authors.link basePath viewingServerHost eventServerHost maybeServer maybeAccount eventPost.author
                        , text (" · " ++ Posts.postVisibilityText eventPost)
                        ]
                    , case instance.post of
                        Just instancePost ->
                            span [ class "post-meta-right" ]
                                [ Posts.starButton eventServerHost starred onStarClicked instancePost
                                , text (Posts.commentCountText instancePost)
                                ]

                        Nothing ->
                            text ""
                    ]
                ]
