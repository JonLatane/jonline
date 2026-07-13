module UI.ServerTheme exposing
    ( ColorMeta
    , ServerTheme
    , colorMetaFromArgb
    , fromColorMetas
    , neutralColorMeta
    )

{-| Ported from the Tamagui frontend's `packages/app/hooks/server_theme_hooks.ts`
(`ColorMeta`, `colorIntMeta`/`colorMeta`, `shadeColor`, `getServerTheme`), so a
server's colors are decided the same way -- same text-color choice, same
light/dark variants -- on both frontends.

The `darkColor`/`lightColor` search (`shadeColor` applied repeatedly until the
shaded color crosses the luma threshold) is the expensive part of this; see
`Shared.Branding`/`Shared.brandingFromConfig` for where that gets computed
once and cached rather than redone on every render. `fromColorMetas` is the
cheap part (picks between already-computed values based on the current
dark/light mode) and is fine to call per-render.
-}

import Bitwise
import Char


{-| Everything about a color needed to use it consistently: the color itself
(normalized to `#rrggbb`), the text color that reads on it, and variants of
itself dark/light enough to pair with white/black text respectively (`color`
itself is already one of the two -- `darkColor` when `isDark`, `lightColor`
otherwise).
-}
type alias ColorMeta =
    { color : String
    , textColor : String
    , darkColor : String
    , lightColor : String
    , luma : Float
    , isDark : Bool
    }


{-| A server's full color scheme, combining its cached `primary`/`nav`
`ColorMeta`s with the app's current dark/light mode. Field names match the
Tamagui `ServerTheme` type.
-}
type alias ServerTheme =
    { primaryColor : String
    , primaryTextColor : String
    , primaryDarkColor : String
    , primaryLightColor : String
    , primaryBgColor : String
    , primaryAnchorColor : String

    , navColor : String
    , navTextColor : String
    , navDarkColor : String
    , navLightColor : String
    , navBgColor : String
    , navAnchorColor : String

    , textColor : String
    , backgroundColor : String
    , transparentBackgroundColor : String
    , transparentPrimaryColor : String
    , barelyTransparentBackgroundColor : String

    , warningAnchorColor : String
    , darkMode : Bool
    }


{-| The neutral placeholder used before a server's real colors are known.
-}
neutralColorMeta : ColorMeta
neutralColorMeta =
    colorMetaFromRgb { r = 0x42, g = 0x42, b = 0x42 }


{-| Decodes a `ServerColors`-style ARGB `uint32` (only the low 24 bits, RGB,
are used) into a `ColorMeta`.
-}
colorMetaFromArgb : Int -> ColorMeta
colorMetaFromArgb argb =
    colorMetaFromRgb
        { r = Bitwise.and 0xFF (Bitwise.shiftRightBy 16 argb)
        , g = Bitwise.and 0xFF (Bitwise.shiftRightBy 8 argb)
        , b = Bitwise.and 0xFF argb
        }


colorMetaFromRgb : { r : Int, g : Int, b : Int } -> ColorMeta
colorMetaFromRgb rgb =
    let
        color =
            toHex rgb

        luma =
            lumaOfRgb rgb

        isDark =
            luma > 0.5
    in
    if isDark then
        { color = color
        , textColor = "#000000"
        , lightColor = color
        , darkColor = darken color
        , luma = luma
        , isDark = isDark
        }

    else
        { color = color
        , textColor = "#ffffff"
        , darkColor = color
        , lightColor = lighten color
        , luma = luma
        , isDark = isDark
        }


{-| Combines cached `primary`/`nav` `ColorMeta`s with the current dark/light
mode into the full `ServerTheme`. Cheap (no shading loops) -- fine to call on
every render.
-}
fromColorMetas : Bool -> ColorMeta -> ColorMeta -> ServerTheme
fromColorMetas darkMode primary nav =
    { primaryColor = primary.color
    , primaryTextColor = primary.textColor
    , primaryDarkColor = primary.darkColor
    , primaryLightColor = primary.lightColor
    , primaryBgColor =
        if darkMode then
            primary.darkColor

        else
            primary.lightColor
    , primaryAnchorColor =
        if not darkMode then
            primary.darkColor

        else
            primary.lightColor

    , navColor = nav.color
    , navTextColor = nav.textColor
    , navDarkColor = nav.darkColor
    , navLightColor = nav.lightColor
    , navBgColor =
        if not darkMode then
            nav.darkColor

        else
            nav.lightColor
    , navAnchorColor =
        if not darkMode then
            nav.darkColor

        else
            nav.lightColor

    , textColor =
        if darkMode then
            "#eaeaea"

        else
            "#1a1a1a"
    , backgroundColor =
        if darkMode then
            "#16181d"

        else
            "#ffffff"
    , transparentBackgroundColor =
        if darkMode then
            "#000A"

        else
            "#FFFA"
    , transparentPrimaryColor = primary.color ++ "F0"
    , barelyTransparentBackgroundColor =
        if darkMode then
            "#000D"

        else
            "#FFFD"

    , warningAnchorColor =
        if not darkMode then
            "#bf6d00"

        else
            "#EBDF1C"
    , darkMode = darkMode
    }



-- COLOR MATH


{-| Repeatedly darkens a color (in -20% steps) until it's dark enough to pair
with white text, matching the Tamagui app's search exactly. Capped well above
what the loop should ever need, purely as a termination guarantee.
-}
darken : String -> String
darken color =
    darkenHelper (shade color -20) 0


darkenHelper : String -> Int -> String
darkenHelper color iterations =
    if lumaOfHex color <= 0.5 || iterations > 40 then
        color

    else
        let
            shaded =
                shade color -20
        in
        if shaded == color then
            color

        else
            darkenHelper shaded (iterations + 1)


{-| Repeatedly lightens a color (in +20% steps) until it's light enough to
pair with black text.
-}
lighten : String -> String
lighten color =
    lightenHelper (shade color 20) 0


lightenHelper : String -> Int -> String
lightenHelper color iterations =
    if lumaOfHex color >= 0.5 || iterations > 40 then
        color

    else
        let
            shaded =
                shade color 20
        in
        if shaded == color then
            color

        else
            lightenHelper shaded (iterations + 1)


{-| Shades a `#rrggbb` color by `percent` (e.g. `-20` or `20`), matching the
Tamagui app's `shadeColor` channel math (including its "nudge by 1 if
rounding would otherwise be a no-op" step) exactly.

Deliberately does *not* floor/ceiling-clamp each channel to `[10, 245]`
before scaling it, the way the naive "shade a color" recipe this was
originally based on does. That clamp forces near-0 channels (e.g. the blue
in a pure yellow) to hover around 10 forever while the other channels keep
shrinking freely, so the ratio between channels drifts and saturation drains
out -- a dark yellow ends up looking brown/olive instead of a darker yellow.
Scaling every channel by the same `multiplier` with no floor preserves
hue and saturation exactly (in HSV terms, only `V` changes), so darkened/
lightened colors keep reading as the same color.
-}
shade : String -> Int -> String
shade colorHex percent =
    let
        rgb =
            rgbFromHex colorHex

        multiplier =
            (100 + toFloat percent) / 100

        adjust n0 =
            let
                n =
                    toFloat n0

                result =
                    n * multiplier

                nudged =
                    if round result == round n then
                        if multiplier > 1 then
                            n + 1

                        else if multiplier < 1 then
                            n - 1

                        else
                            result

                    else
                        result
            in
            round (clamp 0 255 nudged)
    in
    toHex { r = adjust rgb.r, g = adjust rgb.g, b = adjust rgb.b }


lumaOfHex : String -> Float
lumaOfHex hex =
    lumaOfRgb (rgbFromHex hex)


{-| The Tamagui app's simple (non-gamma-corrected) luma formula -- distinct
from, and simpler than, the WCAG relative-luminance formula, since the
"which text color reads better" decisions need to match across frontends.
-}
lumaOfRgb : { r : Int, g : Int, b : Int } -> Float
lumaOfRgb { r, g, b } =
    0.2126 * (toFloat r / 255) + 0.7152 * (toFloat g / 255) + 0.0722 * (toFloat b / 255)


toHex : { r : Int, g : Int, b : Int } -> String
toHex { r, g, b } =
    "#" ++ toHexByte r ++ toHexByte g ++ toHexByte b


toHexByte : Int -> String
toHexByte n =
    let
        hexDigit d =
            String.slice d (d + 1) "0123456789abcdef"
    in
    hexDigit (n // 16) ++ hexDigit (modBy 16 n)


rgbFromHex : String -> { r : Int, g : Int, b : Int }
rgbFromHex hex =
    { r = hexByteAt 1 hex
    , g = hexByteAt 3 hex
    , b = hexByteAt 5 hex
    }


hexByteAt : Int -> String -> Int
hexByteAt offset hex =
    String.slice offset (offset + 2) hex
        |> hexToInt
        |> Maybe.withDefault 0


hexToInt : String -> Maybe Int
hexToInt s =
    String.foldl (\c acc -> Maybe.map2 (\a d -> a * 16 + d) acc (hexDigitValue c)) (Just 0) s


hexDigitValue : Char -> Maybe Int
hexDigitValue c =
    if Char.isDigit c then
        Just (Char.toCode c - Char.toCode '0')

    else
        case Char.toLower c of
            'a' ->
                Just 10

            'b' ->
                Just 11

            'c' ->
                Just 12

            'd' ->
                Just 13

            'e' ->
                Just 14

            'f' ->
                Just 15

            _ ->
                Nothing
