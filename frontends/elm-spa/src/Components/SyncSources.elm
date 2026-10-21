module Components.SyncSources exposing
    ( createSyncSource
    , deleteSyncSource
    , getSyncSources
    , intervalOptions
    , looksLikeStellarWpUrl
    , syncedCountsLabel
    , updateSyncSource
    )

{-| RPC wrappers for `SyncSource` (`protos/sync.proto`) -- mirrors
`Components.Users`' `updateUser`/`federateProfile`/etc in shape: each takes
the calling account/server as an `AccountsPanel.MaybeAccountServer` and
returns a `Task` resolving to `( Maybe AccountsPanel.Msg, response )`, so a
token refresh mid-request can still be forwarded on by the caller (see
`Shared.AccountsPanel.performWithAccountServer`).

`UserProfilePage` no longer fetches `SyncSource`s on its own initial load (it reads
`User.sync_sources`, already carried by the resolved `User`), and every mutation now triggers
a full `refetch` of that `User`. `getSyncSources` is still used, though -- by that section's
manual "Refresh" button (`SyncSourcesRefreshClicked`), which overlays just the fresh `sources`
onto the resolved `User` without a whole-profile refetch -- see `Components.AIProviders`' own
matching doc comment on `getAIProviders`.

-}

import Grpc
import Proto.Rellm exposing (GetSyncSourcesResponse, SyncSource, defaultUser)
import Proto.Rellm.Rellm as Rellm
import Proto.Rellm.SyncSource.Configuration as Configuration
import Shared.AccountsPanel as AccountsPanel
import Shared.AccountsPanel.RellmServers as RellmServers exposing (withAccessToken)
import Shared.Conversions as Conversions
import Task exposing (Task)


{-| An ICS or StellarWP source's "N events" alone when every event has exactly one occasion
(the common non-recurring case, where naming both is redundant) -- otherwise
"N events and M occasions". An RSS/Atom source (which syncs plain Posts, not
Events -- see `posts.proto`'s `Post.sync_source`) instead shows "N posts",
read off `source.postCount`. Used by both `Components.Pages.UserProfilePage`
(each row's "delete along with its events/posts" button) and `UI`'s shared
delete-confirmation dialog for the same source, so it lives here rather than
on either caller.
-}
syncedCountsLabel : SyncSource -> String
syncedCountsLabel source =
    case source.configuration of
        Just (Configuration.IcsSubscriptionUrl _) ->
            eventsAndOccasionsLabel source

        Just (Configuration.StellarwpSubscriptionEndpoint _) ->
            eventsAndOccasionsLabel source

        _ ->
            pluralCount (Conversions.int64ToInt source.postCount) "post"


eventsAndOccasionsLabel : SyncSource -> String
eventsAndOccasionsLabel source =
    let
        eventCount : Int
        eventCount =
            Conversions.int64ToInt source.eventCount

        occasionCount : Int
        occasionCount =
            Conversions.int64ToInt source.occasionCount
    in
    if eventCount == occasionCount then
        pluralCount eventCount "event"

    else
        pluralCount eventCount "event"
            ++ " and "
            ++ pluralCount occasionCount "occasion"


pluralCount : Int -> String -> String
pluralCount count noun =
    String.fromInt count
        ++ " "
        ++ noun
        ++ (if count == 1 then
                ""

            else
                "s"
           )


{-| Whether `url` looks like an iCal export from [The Events Calendar](https://theeventscalendar.com/)
(the StellarWP WordPress plugin) -- its `?ical=1` export, which the plugin caps at one page of events
(30 on many sites), so a plain iCal source on it only ever sees the next couple of weeks. Such a
source should be a `StellarwpSubscriptionEndpoint` instead, which follows the plugin's pagination
(see `protos/sync.proto`). Used to suggest exactly that switch in `Components.Pages.UserProfilePage`'s
Sync Sources section.

Matches `ical=1` together with any of the plugin's own query parameters (`post_type=tribe_events`,
`eventDisplay`, `tribe_display`, `tribe-bar-*`, `tribe_events_cat`, `tribe_eventcategory`,
`tribe_paged`, `shortcode`), or with an `/events/` path -- covering both the `?post_type=tribe_events`
form of the export link and the pretty `/events/list/?ical=1` and `/events/.../ical/` forms. A
plain `.ics` file (which never carries `ical=1`) never matches.

-}
looksLikeStellarWpUrl : String -> Bool
looksLikeStellarWpUrl url =
    let
        ( beforeQuery, query ) =
            case String.split "?" (String.toLower (String.trim url)) of
                [] ->
                    ( "", "" )

                path :: rest ->
                    ( path, String.join "?" rest )

        params : List String
        params =
            query
                |> String.split "#"
                |> List.head
                |> Maybe.withDefault ""
                |> String.split "&"

        paramNamed : String -> Bool
        paramNamed name =
            List.any (\param -> String.startsWith (name ++ "=") param || param == name) params

        paramNameStartsWith : String -> Bool
        paramNameStartsWith prefix =
            List.any (String.startsWith prefix) params

        isTribeEventsExport : Bool
        isTribeEventsExport =
            List.member "ical=1" params
                && (List.member "post_type=tribe_events" params
                    || List.any paramNamed [ "eventdisplay", "tribe_display", "tribe_events_cat", "tribe_paged", "shortcode" ]
                    || paramNameStartsWith "tribe-bar-"
                    || paramNameStartsWith "tribe_eventcategory"
                    || String.contains "/events/" beforeQuery
                   )

        isTribeEventsPrettyIcalPath : Bool
        isTribeEventsPrettyIcalPath =
            String.contains "/events/" beforeQuery
                && (String.endsWith "/ical/" beforeQuery || String.endsWith "/ical" beforeQuery)
    in
    String.startsWith "http" beforeQuery && (isTribeEventsExport || isTribeEventsPrettyIcalPath)


{-| `targetUserId = ""` asks the backend for the caller's own sources (see
`backend/src/rpcs/sync_sources/get_sync_sources.rs`); any other
id asks for that user's sources instead, which only succeeds for an Admin
caller.
-}
getSyncSources :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetSyncSourcesResponse )
getSyncSources accountsPanelModel maybeAccountServer targetUserId =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Rellm.getSyncSources { defaultUser | id = targetUserId }
                |> Grpc.setHost (RellmServers.rellmServerUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


{-| Always creates a source owned by the calling account -- the backend
ignores/overrides any `owner` sent (see `create_sync_source.rs`), so
there's no `targetUserId` parameter here unlike `getSyncSources`.
-}
createSyncSource :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> SyncSource
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, SyncSource )
createSyncSource accountsPanelModel maybeAccountServer source =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Rellm.createSyncSource source
                |> Grpc.setHost (RellmServers.rellmServerUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


updateSyncSource :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> SyncSource
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, SyncSource )
updateSyncSource accountsPanelModel maybeAccountServer source =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Rellm.updateSyncSource source
                |> Grpc.setHost (RellmServers.rellmServerUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


deleteSyncSource :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> SyncSource
    -> Bool
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, () )
deleteSyncSource accountsPanelModel maybeAccountServer source deleteSyncedEvents =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Rellm.deleteSyncSource
                { source = Just source, deleteSyncedEvents = deleteSyncedEvents }
                |> Grpc.setHost (RellmServers.rellmServerUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
                |> Task.map (always ())
        )


{-| The fixed set of sync intervals offered in the UI (seconds, label) --
matches what was asked for: 5/15/30 minutes, 1/4/8 hours, 1 day.
-}
intervalOptions : List ( Int, String )
intervalOptions =
    [ ( 60, "1 minute" )
    , ( 300, "5 minutes" )
    , ( 900, "15 minutes" )
    , ( 1800, "30 minutes" )
    , ( 3600, "1 hour" )
    , ( 14400, "4 hours" )
    , ( 28800, "8 hours" )
    , ( 86400, "1 day" )
    ]
