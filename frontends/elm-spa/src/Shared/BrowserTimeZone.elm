module Shared.BrowserTimeZone exposing (BrowserTimeZone, formatDate, formatDateTime, formatDateTimeLocalInput, formatMoment, formatRange, posixFromDateTimeLocalInput)

import Shared.Conversions as Conversions
import Time


{-| The browser's local timezone, plus its short display name (e.g. "EDT",
"GMT+2") and whether its locale renders a time of day in 24-hour form.
Bundled together since every call site that needs one of these tends to need
the others too -- see `Shared.Model.browserTimeZone`.

`zone` is resolved via `Time.here` once `Shared.init`'s `Cmd` runs -- `Time.utc`
until then (never visibly wrong for long: the `Task` resolves on the same
frame the app first renders). `abbreviation`/`uses24Hour` both come from a
different source: unlike `zone`, `elm/time` has no way to derive either (a
`Time.Zone` is just a raw offset table, with no notion of a locale's
formatting conventions), so both are read once at startup from the browser's
own `Intl` API as plain flags (see `index.html`) rather than a port
round-trip -- they only matter at the instant a timestamp renders, same as
`zone`, and aren't worth keeping live across a session. `abbreviation` is
`""` (never shown), `uses24Hour` is `False`, if their respective `Intl`
lookups fail for any reason.

Lives in its own module (rather than `Shared` itself) so lower-level modules
that only need the timezone pair -- not all of `Shared.Model` -- can depend on
it without risking an import cycle (e.g. `Shared` -> `Shared.StarredPanel`
-> `Components.PostCard`, which can't import `Shared` back).

-}
type alias BrowserTimeZone =
    { zone : Time.Zone
    , abbreviation : String
    , uses24Hour : Bool
    }


{-| A plain `YYYY-MM-DD` rendering of a timestamp in `zone` -- e.g. a
profile's "Joined" date. No existing date-formatting helper/locale
infrastructure exists in this app yet, so this keeps things simple rather
than introducing one. Takes a bare `Time.Zone` rather than a full
`BrowserTimeZone` since, unlike `formatDateTime`, it has no time-of-day
component for `abbreviation` to disambiguate.
-}
formatDate : Time.Zone -> Time.Posix -> String
formatDate zone time =
    let
        pad2 n =
            String.padLeft 2 '0' (String.fromInt n)
    in
    String.fromInt (Time.toYear zone time)
        ++ "-"
        ++ pad2 (monthNumber (Time.toMonth zone time))
        ++ "-"
        ++ pad2 (Time.toDay zone time)


{-| `formatDate` plus an `HH:mm` (24-hour) suffix, both in `browserTimeZone`'s
`zone`, plus a trailing `abbreviation` (e.g. "EDT", `""` omits it) so the
reader can tell which zone `HH:mm` is in without guessing -- for timestamps
where the time of day actually matters (e.g.
`Components.PostCard.timestampsText`'s created/updated/published times),
unlike a profile's plain "Joined" date.
-}
formatDateTime : BrowserTimeZone -> Time.Posix -> String
formatDateTime browserTimeZone time =
    let
        pad2 n =
            String.padLeft 2 '0' (String.fromInt n)
    in
    formatDate browserTimeZone.zone time
        ++ " "
        ++ pad2 (Time.toHour browserTimeZone.zone time)
        ++ ":"
        ++ pad2 (Time.toMinute browserTimeZone.zone time)
        ++ (if browserTimeZone.abbreviation == "" then
                ""

            else
                " " ++ browserTimeZone.abbreviation
           )


{-| A human-friendly single point in time, e.g. "August 1, 6PM" or (24-hour)
"August 1, 18:00" -- `now` supplies the viewer's own "current year", so
`dateLabel` can drop a redundant year (see its own doc). Used by
`Components.Events.instanceWhenText` for an `EventInstance` with only a
`startsAt` or only an `endsAt` (unusual -- normally both are set, see
`formatRange`).
-}
formatMoment : Time.Posix -> BrowserTimeZone -> Time.Posix -> String
formatMoment now browserTimeZone time =
    dateLabel browserTimeZone (Time.toYear browserTimeZone.zone now) time
        ++ ", "
        ++ timeOfDayLabel browserTimeZone time


{-| A human-friendly span between two points in time -- the building block
behind `Components.Events.instanceWhenText`'s "August 1, 6-7PM" /
"June 1, 10PM - June 8, 3AM" / "December 31, 2025, 9PM - January 1, 2AM"
formatting (see that function's own doc for the full set of examples this is
designed against). `now` supplies the viewer's own "current year" so
`dateLabel` can drop it on either side that's actually in it (e.g. a New
Year's Eve party spanning into next year still shows the upcoming year's
date bare, only the trailing year on the year that isn't the current one).

Same calendar day (in `browserTimeZone.zone`): a single `dateLabel` followed
by both times, merged onto one `-`-joined range (see `timeRangeLabel`) --
e.g. "August 1, 6-7PM". Different days: each side gets its own full
`dateLabel`, e.g. "June 1, 10PM - June 8, 3AM" -- never merged, since
"August 1, 6 - September 2, 7PM" reads as if `7PM` alone told you anything
about `August 1`'s own time.
-}
formatRange : Time.Posix -> BrowserTimeZone -> Time.Posix -> Time.Posix -> String
formatRange now browserTimeZone start end =
    let
        zone =
            browserTimeZone.zone

        sameDay =
            ( Time.toYear zone start, Time.toMonth zone start, Time.toDay zone start )
                == ( Time.toYear zone end, Time.toMonth zone end, Time.toDay zone end )
    in
    if sameDay then
        dateLabel browserTimeZone (Time.toYear zone now) start
            ++ ", "
            ++ timeRangeLabel browserTimeZone start end

    else
        dateLabel browserTimeZone (Time.toYear zone now) start
            ++ ", "
            ++ timeOfDayLabel browserTimeZone start
            ++ " - "
            ++ dateLabel browserTimeZone (Time.toYear zone now) end
            ++ ", "
            ++ timeOfDayLabel browserTimeZone end


{-| "MonthName Day", e.g. "August 1" -- plus a trailing ", Year" whenever
`time`'s own year (in `zone`) isn't `currentYear` (the viewer's own "now"),
so a date within the viewer's current year never carries the visual noise of
a year nobody needs telling, while one that isn't (a past event, or a New
Year's Eve party's other end) still says so plainly.
-}
dateLabel : BrowserTimeZone -> Int -> Time.Posix -> String
dateLabel browserTimeZone currentYear time =
    let
        zone =
            browserTimeZone.zone

        year =
            Time.toYear zone time

        base =
            monthName (Time.toMonth zone time) ++ " " ++ String.fromInt (Time.toDay zone time)
    in
    if year == currentYear then
        base

    else
        base ++ ", " ++ String.fromInt year


{-| `start`/`end`'s time-of-day, same calendar day, merged onto one range --
e.g. "6-7PM"/"8-10:30PM" (both sides share an AM/PM, so only `end` states it)
or "11:30AM-2PM" (they don't, so both state their own). 24-hour locales have
no AM/PM to (de)duplicate in the first place, so `uses24Hour` always shows
both sides in full, e.g. "18:00-19:00".
-}
timeRangeLabel : BrowserTimeZone -> Time.Posix -> Time.Posix -> String
timeRangeLabel browserTimeZone start end =
    let
        zone =
            browserTimeZone.zone

        startHour =
            Time.toHour zone start

        endHour =
            Time.toHour zone end
    in
    if browserTimeZone.uses24Hour then
        time24 zone start ++ "-" ++ time24 zone end

    else if period startHour == period endHour then
        bareTime12 zone start ++ "-" ++ timeWithPeriod zone end

    else
        timeWithPeriod zone start ++ "-" ++ timeWithPeriod zone end


{-| A single point in time's time-of-day only, honoring `uses24Hour` -- e.g.
"6PM"/"10:30PM" (12-hour, minutes omitted on the hour) or "18:00"/"22:30"
(24-hour, minutes always shown, the usual convention for that clock).
-}
timeOfDayLabel : BrowserTimeZone -> Time.Posix -> String
timeOfDayLabel browserTimeZone time =
    if browserTimeZone.uses24Hour then
        time24 browserTimeZone.zone time

    else
        timeWithPeriod browserTimeZone.zone time


{-| `"AM"`/`"PM"` for a 24-hour `hour` (`0`-`23`). -}
period : Int -> String
period hour =
    if hour < 12 then
        "AM"

    else
        "PM"


{-| A 24-hour `hour` (`0`-`23`) as its 12-hour clock face number (`1`-`12`) --
`0` and `12` both read as `12` (midnight/noon), same as any analog clock.
-}
hour12 : Int -> Int
hour12 hour =
    case modBy 12 hour of
        0 ->
            12

        h ->
            h


{-| `time`'s time-of-day, 12-hour, with no AM/PM suffix and no leading zero
-- e.g. "6", "10:30" -- minutes omitted entirely on the hour. The bare half
of `timeRangeLabel`'s "6-7PM"-style merge; `timeWithPeriod` is the version
with the suffix attached.
-}
bareTime12 : Time.Zone -> Time.Posix -> String
bareTime12 zone time =
    let
        minute =
            Time.toMinute zone time
    in
    String.fromInt (hour12 (Time.toHour zone time))
        ++ (if minute == 0 then
                ""

            else
                ":" ++ String.padLeft 2 '0' (String.fromInt minute)
           )


{-| `bareTime12` plus its own `AM`/`PM` suffix, e.g. "6PM", "10:30PM". -}
timeWithPeriod : Time.Zone -> Time.Posix -> String
timeWithPeriod zone time =
    bareTime12 zone time ++ period (Time.toHour zone time)


{-| `time`'s time-of-day, 24-hour, always `HH:mm` (e.g. "18:00", "02:30") --
the usual convention for a 24-hour clock, unlike `bareTime12`'s on-the-hour
minute omission.
-}
time24 : Time.Zone -> Time.Posix -> String
time24 zone time =
    String.padLeft 2 '0' (String.fromInt (Time.toHour zone time))
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute zone time))


{-| Full month name, e.g. "August" -- unlike `monthNumber`, for
`dateLabel`'s human-friendly rendering rather than a zero-padded numeric
date.
-}
monthName : Time.Month -> String
monthName month =
    case month of
        Time.Jan ->
            "January"

        Time.Feb ->
            "February"

        Time.Mar ->
            "March"

        Time.Apr ->
            "April"

        Time.May ->
            "May"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December"


monthNumber : Time.Month -> Int
monthNumber month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


{-| `YYYY-MM-DDTHH:mm` in `zone` -- the exact format an `<input
type="datetime-local">` element's `value` attribute expects, so a date/time
picker (e.g. `Components.Pages.EventsPage`'s "Events After <date>" tab)
can be a plain controlled input: this formats a `Time.Posix` to populate it,
and `posixFromDateTimeLocalInput` parses back whatever the user (or the
browser's own native picker widget) sets it to.
-}
formatDateTimeLocalInput : Time.Zone -> Time.Posix -> String
formatDateTimeLocalInput zone time =
    let
        pad2 n =
            String.padLeft 2 '0' (String.fromInt n)
    in
    formatDate zone time
        ++ "T"
        ++ pad2 (Time.toHour zone time)
        ++ ":"
        ++ pad2 (Time.toMinute zone time)


{-| The inverse of `formatDateTimeLocalInput` -- parses an `<input
type="datetime-local">`'s value string (`YYYY-MM-DDTHH:mm`, always the
viewer's own local wall-clock time, with no timezone of its own) back into
the absolute `Time.Posix` it represents in `zone`.

`elm/time`'s `Time.Zone` only goes one direction (instant -> local wall
clock, via `Time.toHour`/etc.) -- there's no built-in inverse. This gets
there by guessing (treating the input's Y/M/D/H/M as if they were already
UTC, via `Shared.Conversions.daysFromCivil`), reading back what `zone` says
the wall-clock is at that guess, and correcting by the difference --
re-derived from the _original_ guess a second time (not chained onto the
already-corrected candidate, which would double-count a stable offset
instead of converging) so a guess landing right on a DST boundary still
converges (this app's own use, picking a cutoff date for an events filter,
doesn't need sub-minute precision across a boundary, but there's no reason
not to get it right).

-}
posixFromDateTimeLocalInput : Time.Zone -> String -> Maybe Time.Posix
posixFromDateTimeLocalInput zone raw =
    let
        offsetMinutesAt posix =
            let
                localAsUtcMillis =
                    (Conversions.daysFromCivil (Time.toYear zone posix) (Conversions.monthToNumber (Time.toMonth zone posix)) (Time.toDay zone posix)
                        * 86400
                        + Time.toHour zone posix
                        * 3600
                        + Time.toMinute zone posix
                        * 60
                    )
                        * 1000
            in
            (localAsUtcMillis - Time.posixToMillis posix) // 60000
    in
    case String.split "T" raw of
        [ datePart, timePart ] ->
            Maybe.map2
                (\( year, month, day ) ( hour, minute, _ ) ->
                    let
                        guessMillis =
                            (Conversions.daysFromCivil year month day * 86400 + hour * 3600 + minute * 60) * 1000

                        correctFromGuess offset =
                            guessMillis - offset * 60000

                        candidate1 =
                            correctFromGuess (offsetMinutesAt (Time.millisToPosix guessMillis))

                        candidate2 =
                            correctFromGuess (offsetMinutesAt (Time.millisToPosix candidate1))
                    in
                    Time.millisToPosix candidate2
                )
                (Conversions.parseDateParts datePart)
                (Conversions.parseTimeParts timePart)

        _ ->
            Nothing
