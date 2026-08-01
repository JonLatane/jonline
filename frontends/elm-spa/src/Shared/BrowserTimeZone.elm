module Shared.BrowserTimeZone exposing (BrowserTimeZone, formatDate, formatDateTime, formatDateTimeLocalInput, posixFromDateTimeLocalInput)

import Shared.Conversions as Conversions
import Time


{-| The browser's local timezone, plus its short display name (e.g. "EDT",
"GMT+2"). Bundled together since every call site that needs one needs the
other -- see `Shared.Model.browserTimeZone`.

`zone` is resolved via `Time.here` once `Shared.init`'s `Cmd` runs -- `Time.utc`
until then (never visibly wrong for long: the `Task` resolves on the same
frame the app first renders). `abbreviation` comes from a different source:
unlike `zone`, `elm/time` has no way to derive it (a `Time.Zone` is just a raw
offset table), so it's read once at startup from the browser's own `Intl` API
as a plain flag (see `index.html`) rather than a port round-trip -- it only
matters at the instant a timestamp renders, same as `zone`, and isn't worth
keeping live across the rare mid-session DST flip. `""` (never shown) if
`Intl` lookup fails for any reason.

Lives in its own module (rather than `Shared` itself) so lower-level modules
that only need the timezone pair -- not all of `Shared.Model` -- can depend on
it without risking an import cycle (e.g. `Shared` -> `Shared.StarredPanel`
-> `Components.PostCard`, which can't import `Shared` back).

-}
type alias BrowserTimeZone =
    { zone : Time.Zone
    , abbreviation : String
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
