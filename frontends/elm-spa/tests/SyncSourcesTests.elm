module SyncSourcesTests exposing (suite)

{-| Tests for `Components.SyncSources`: `looksLikeStellarWpUrl` -- the detector behind the Sync Sources
section's "this looks like a StellarWP feed" suggestion -- and the `User-Agent` selector's helpers. Its positive cases are the real iCal export
URLs that motivated the StellarWP source type (The Events Calendar caps each iCal response at ~30
events, so a plain iCal source on one only sees the next couple of weeks).
-}

import Components.SyncSources as SyncSources
import Expect
import Proto.Rellm exposing (defaultSyncSource)
import Proto.Rellm.SyncSourceUserAgent as UserAgent
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "SyncSources"
        [ looksLikeStellarWpUrlTests
        , userAgentTests
        ]


looksLikeStellarWpUrlTests : Test
looksLikeStellarWpUrlTests =
    describe "looksLikeStellarWpUrl"
        [ describe "matches The Events Calendar iCal exports"
            ([ ( "?post_type=tribe_events export link"
               , "https://thetriangleweekender.com/?post_type=tribe_events&ical=1&eventDisplay=list"
               )
             , ( "shortcode list view with ical=1"
               , "https://downtowndurham.com/events/list/?shortcode=476863a3&hide_subsequent_recurrences=1&ical=1"
               )
             , ( "pretty /events/list/ path"
               , "https://example.com/events/list/?ical=1"
               )
             , ( "category export"
               , "https://example.com/?post_type=tribe_events&ical=1&tribe_events_cat=music"
               )
             , ( "tribe_eventcategory[] export"
               , "https://example.com/events/list/?tribe_paged=1&tribe_event_display=list&tribe_eventcategory%5B%5D=5&ical=1&tribe_display=list"
               )
             , ( "pretty /events/.../ical/ path"
               , "https://example.com/events/category/music/ical/"
               )
             , ( "upper-case and surrounding whitespace"
               , "  HTTPS://Example.com/?POST_TYPE=tribe_events&ICAL=1  "
               )
             ]
                |> List.map (\( name, url ) -> test name (\_ -> SyncSources.looksLikeStellarWpUrl url |> Expect.equal True))
            )
        , describe "leaves other feeds alone"
            ([ ( "a plain .ics file", "https://raleighnc.gov/events/22846/22846/events.ics" )
             , ( "a Google Calendar feed", "https://calendar.google.com/calendar/ical/abc%40group.calendar.google.com/public/basic.ics" )
             , ( "ical=1 on an unrelated site", "https://example.com/feed?ical=1" )
             , ( "tribe_events without ical=1", "https://example.com/?post_type=tribe_events" )
             , ( "an RSS feed", "https://example.com/feed/" )
             , ( "not a URL", "not a url" )
             , ( "empty", "" )
             ]
                |> List.map (\( name, url ) -> test name (\_ -> SyncSources.looksLikeStellarWpUrl url |> Expect.equal False))
            )
        ]


userAgentTests : Test
userAgentTests =
    describe "user agent"
        [ test "offers No User Agent, Rellm and curl, in that order" <|
            \_ ->
                SyncSources.userAgentOptions
                    |> List.map Tuple.second
                    |> Expect.equal [ "No User Agent", "Rellm", "curl" ]
        , test "every option's label round-trips" <|
            \_ ->
                SyncSources.userAgentOptions
                    |> List.all (\( userAgent, label ) -> SyncSources.userAgentFromLabel label == userAgent && SyncSources.userAgentLabel userAgent == label)
                    |> Expect.equal True
        , test "an unknown label reads as No User Agent" <|
            \_ ->
                SyncSources.userAgentFromLabel "Netscape"
                    |> Expect.equal UserAgent.NOUSERAGENT
        , test "a source's own setting is read back" <|
            \_ ->
                SyncSources.userAgentOf { defaultSyncSource | userAgent = Just UserAgent.CURL }
                    |> Expect.equal UserAgent.CURL
        , test "an unset source reads as No User Agent (what sources did before the setting)" <|
            \_ ->
                SyncSources.userAgentOf { defaultSyncSource | userAgent = Nothing }
                    |> Expect.equal UserAgent.NOUSERAGENT
        , test "a value this client doesn't know reads as No User Agent" <|
            \_ ->
                SyncSources.userAgentOf { defaultSyncSource | userAgent = Just (UserAgent.SyncSourceUserAgentUnrecognized_ 99) }
                    |> Expect.equal UserAgent.NOUSERAGENT
        ]
