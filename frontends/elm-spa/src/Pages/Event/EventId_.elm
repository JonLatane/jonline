module Pages.Event.EventId_ exposing (Model, Msg, fromShared, page)

{-| `/event/:eventId` -- a single Event's detail/"invitation" view: the
`Event`'s own `Post` (title, link, media, content) up top, then the specific
`EventInstance` being viewed (its start/end time and location), then that
`EventInstance`'s own optional override `Post`.

`eventId` (the route segment, matching `Pages.Post.PostId_`'s own `postId`
naming) is actually an `EventInstance.id`, not an `Event.id` --
`GetEventsRequest.event_instance_id` is the only way to fetch a single Event
(see `events.proto`), and it returns that instance's whole parent `Event`
with _every_ one of its instances, not just the one asked for -- unused here
beyond picking out the one this page's own route asked for (see
`Components.Events.findInstance`).

-}

import Components.Events as Events
import Components.Posts as Posts
import Components.ServerDependentView as ServerDependentView
import Effect exposing (Effect)
import Gen.Params.Event.EventId_ exposing (Params)
import Grpc
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import Page
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


type alias Model =
    { targetHost : String
    , eventId : String
    , eventStatus : EventStatus
    , connectStatus : ServerDependentView.ConnectStatus
    , fetchStarted : Bool
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
                }
    in
    ( fetchedModel
    , Effect.batch [ fetchEffect, Effect.fromShared (Shared.BreadcrumbsMsg Breadcrumbs.Clear) ]
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
    | MediaClicked Post String
    | ConnectClicked
    | GotConnectResult (Result Grpc.Error AccountsPanel.Server)
    | EnableClicked
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
            in
            ( { model | eventStatus = newStatus }
            , Effect.batch [ accountEffect, breadcrumbsEffect ]
            )

        GotEvent (Err _) ->
            ( { model | eventStatus = EventFailed }, Effect.none )

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
    if model.fetchStarted then
        Sub.none

    else
        Time.every 30000 (\_ -> Poll)



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
