module Components.QuotedLink exposing (AccountsInfo, Config, accountsInfo, targetOf, view, viewLink)

{-| The quoted post a Rellm `POST` embeds, when its `link` points at a post/event on a Rellm server
(`Shared.Federation.RellmLinks`) -- what `Components.Posts.postCard`/`postDetail`'s `quoteView` slot is
filled with. Rendered by the caller (not inside `Components.Posts`) because it needs state `Posts` can't
see without a dependency cycle: `Shared.QuoteLinks`' cache of fetched posts, and the `AccountsPanel` model for
which servers the user has and what we know about the rest.

What shows up depends on the link's server, mirroring `Components.ServerDependentView` (the Add/Enable
prompts on a post page) wherever the two overlap:

  - one of the user's servers, enabled: the quoted post as a card (`Components.Posts.quotedPostCard`) -- or,
    when it's an event's or occasion's (by `PostContext`, see `Shared.QuoteLinks.wantsEvent`), a read-only
    `Components.Events.eventCard` -- or a "Loading…" line until it arrives, or nothing if it can't be seen;
  - one of the user's servers, disabled: `ServerDependentView`'s own "Enable" prompt -- we don't read from a
    server the user switched off;
  - one the user hasn't added, that turned out to be a Rellm server: the card too (fetched anonymously, see
    `Shared.QuoteLinks`) with an "Add" button for that server under it, labelled with the logo and name
    `AccountsPanel` already previewed for it -- or, if the post itself can't be seen anonymously, just the
    button;
  - one the user hasn't added that isn't a Rellm server (or isn't known yet): nothing at all, so a post that
    merely links to some website looks exactly as it did before.

-}

import Components.Events as Events
import Components.MediaRenderer as MediaRenderer
import Components.Posts as Posts
import Components.ServerDependentView as ServerDependentView
import Dict exposing (Dict)
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, title)
import Html.Events exposing (onClick)
import Proto.Rellm exposing (Event, Occasion, Post)
import Proto.Rellm.PostContext exposing (PostContext(..))
import Set exposing (Set)
import Shared.AccountsPanel as AccountsPanel
import Shared.AccountsPanel.RellmAccounts as RellmAccounts exposing (RellmAccount)
import Shared.AccountsPanel.RellmServers as RellmServers exposing (RellmServer)
import Shared.Federation.RellmLinks as RellmLinks exposing (Target)
import Shared.QuoteLinks as QuoteLinks
import Shared.Time as SharedTime


type alias Config msg =
    { time : SharedTime.Model
    , basePath : String
    , accounts : AccountsInfo
    , quotes : QuoteLinks.Model
    , mediaPlayState : MediaRenderer.Model
    , onMediaPlayClicked : String -> msg

    -- The "Add <server>" button on a quote from a server the user hasn't added, and the "Enable" button
    -- of one they've disabled -- each gets the server's `frontendHost`.
    , onAddServerClicked : String -> msg
    , onEnableServerClicked : String -> msg

    -- For the event card's own (unused here) click handlers, which a quote doesn't offer.
    , noOp : msg
    }


{-| The parts of `AccountsPanel.Model` this view reads -- a narrower type than the whole model, so it's
buildable (and testable) on its own; callers pass `accountsInfo shared.accounts`.
-}
type alias AccountsInfo =
    { servers : List RellmServer
    , accounts : List RellmAccount
    , previews : Dict String RellmServer
    , nonRellmHosts : Set String
    , mainFrontendHost : String
    }


accountsInfo : AccountsPanel.Model -> AccountsInfo
accountsInfo model =
    { servers = model.servers
    , accounts = model.accounts
    , previews = model.recommendedServerConnections
    , nonRellmHosts = model.nonRellmHosts
    , mainFrontendHost = model.mainFrontendHost
    }


{-| What `post` quotes, if anything: only a top-level `POST` on a Rellm server (a reply's, event's or
federated post's `link` is just a link -- a federated post's own quote arrives already resolved in
`Post.quotedPost`, see `Shared.Federation.Bluesky`/`Mastodon`) whose `link` is a Rellm post/event link. `postServerHost` is the
server `post` came from, which a relative link means.
-}
targetOf : String -> Post -> Maybe Target
targetOf postServerHost post =
    if post.context == POST && not (Posts.isFederatedHost postServerHost) && post.quotedPost == Nothing then
        post.link |> Maybe.andThen (RellmLinks.parse postServerHost)

    else
        Nothing


{-| The embed for `post`'s quote -- `text ""` when it doesn't have one, or there's nothing to show (yet).
-}
view : Config msg -> String -> Post -> Html msg
view config postServerHost post =
    case targetOf postServerHost post of
        Just target ->
            viewTarget config target

        Nothing ->
            text ""


{-| The embed for a bare `link` (what `Shared.CreateNewPanel` previews) -- `postServerHost` is what a relative
one means, as for `Shared.Federation.RellmLinks.parse`.
-}
viewLink : Config msg -> String -> String -> Html msg
viewLink config postServerHost link =
    case RellmLinks.parse postServerHost link of
        Just target ->
            viewTarget config target

        Nothing ->
            text ""


viewTarget : Config msg -> Target -> Html msg
viewTarget config target =
    case RellmServers.rellmServerForHost config.accounts.servers target.host of
        Just _ ->
            ServerDependentView.view
                { hostname = target.host
                , servers = config.accounts.servers
                , accounts = config.accounts.accounts
                , connectStatus = ServerDependentView.NotConnected
                , previews = config.accounts.previews
                , onConnectClicked = config.onAddServerClicked target.host
                , onEnableClicked = config.onEnableServerClicked target.host
                }
                (\_ _ -> entryView config target)

        Nothing ->
            if Set.member target.host config.accounts.nonRellmHosts then
                text ""

            else
                case QuoteLinks.entryFor config.quotes target of
                    Just (QuoteLinks.Loaded quoted) ->
                        div [ class "quoted-post" ] [ card config target quoted, addServerRow config target ]

                    Just (QuoteLinks.LoadedEvent event occasion) ->
                        div [ class "quoted-post" ] [ eventCard config target event occasion, addServerRow config target ]

                    _ ->
                        -- Not (yet) a post we can show -- but if the host did turn out to be a Rellm server, the
                        -- button is still worth having (the post may just need an account there).
                        if (Dict.get target.host config.accounts.previews |> Maybe.andThen .connected) /= Nothing then
                            div [ class "quoted-post" ] [ addServerRow config target ]

                        else
                            text ""


entryView : Config msg -> Target -> Html msg
entryView config target =
    case QuoteLinks.entryFor config.quotes target of
        Just (QuoteLinks.Loaded quoted) ->
            card config target quoted

        Just (QuoteLinks.LoadedEvent event occasion) ->
            eventCard config target event occasion

        Just (QuoteLinks.Awaiting _) ->
            div [ class "quoted-post-loading" ] [ text "Loading quoted post…" ]

        Just QuoteLinks.Loading ->
            div [ class "quoted-post-loading" ] [ text "Loading quoted post…" ]

        _ ->
            text ""


card : Config msg -> Target -> Post -> Html msg
card config target quoted =
    Posts.quotedPostCard
        config.time
        config.basePath
        config.accounts.mainFrontendHost
        target.host
        config.mediaPlayState
        config.onMediaPlayClicked
        Nothing
        quoted


{-| A quoted event as `Components.Events.eventCard` -- the card an events listing shows, read-only: no RSVP,
calendar-export or sync controls (`Events.noCardSlots`), which need the page's own state.
-}
eventCard : Config msg -> Target -> Event -> Occasion -> Html msg
eventCard config target event occasion =
    Events.eventCard
        config.time
        config.basePath
        config.accounts.mainFrontendHost
        target.host
        (RellmServers.rellmServerForHost config.accounts.servers target.host)
        (RellmAccounts.enabledRellmAccountForServer config.accounts.accounts target.host)
        (\_ -> config.noOp)
        config.mediaPlayState
        config.onMediaPlayClicked
        MediaRenderer.ExtraSmall
        False
        Nothing
        False
        False
        False
        Nothing
        (\_ -> False)
        (\_ -> Nothing)
        (\_ -> config.noOp)
        (\_ _ -> config.noOp)
        Events.noCardSlots
        event
        occasion


{-| "Add <logo> <name>" -- `ServerDependentView`'s own button, label and wording, for a quote's server the
user hasn't added.
-}
addServerRow : Config msg -> Target -> Html msg
addServerRow config target =
    div [ class "quoted-post-server-row" ]
        [ button
            [ class "server-action-button"
            , onClick (config.onAddServerClicked target.host)
            , title ("Add " ++ target.host)
            ]
            [ text "Add "
            , ServerDependentView.hostLabel
                (RellmServers.previewOf config.accounts.servers config.accounts.previews target.host)
            ]
        ]
