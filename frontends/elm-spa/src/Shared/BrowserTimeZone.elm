module Shared.BrowserTimeZone exposing (BrowserTimeZone, formatDate, formatDateTime)

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
it without risking an import cycle (e.g. `Shared` -> `Shared.StarredPostsPanel`
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
