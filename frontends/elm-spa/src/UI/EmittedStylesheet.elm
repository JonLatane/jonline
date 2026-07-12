module UI.EmittedStylesheet exposing (view)

{-| A `<style>` tag, computed fresh from the current `Shared.Model` on every
render (so it updates automatically any time a server is added/removed, or
the current server/dark-light mode changes): one text-color rule for every
link on the page, plus, for each known server, three color "utility class"
pairs so any element can be given that server's colors just by adding two
classes -- e.g. `class="jonline.io background-color-primary"` -- rather than
needing that server's `ServerTheme` threaded in as a view-function argument.

  - `<host> background-color-primary` -- `primaryColor` / `primaryTextColor`
  - `<host> background-color-nav` -- `navColor` / `navTextColor`
  - `<host> background-color-primary-background` -- `primaryBgColor` / `textColor`

This is cheap to regenerate (it's just string-building); the actual expensive
color math is already cached in `Shared.Branding`.

-}

import Char
import Html exposing (Html, node, text)
import Shared


view : Shared.Model -> Html msg
view shared =
    node "style" [] [ text (css shared) ]


css : Shared.Model -> String
css shared =
    linkRule (Shared.mainServerTheme shared).primaryAnchorColor
        ++ String.concat (List.map (serverRules shared) shared.servers)


linkRule : String -> String
linkRule anchorColor =
    "a { color: " ++ anchorColor ++ "; }\n"


serverRules : Shared.Model -> Shared.Server -> String
serverRules shared server =
    let
        theme =
            Shared.serverThemeOf shared server

        selector =
            "." ++ escapeClass server.frontendHost
    in
    String.concat
        [ colorRule (selector ++ ".background-color-primary") theme.primaryColor theme.primaryTextColor
        , colorRule (selector ++ ".background-color-nav") theme.navColor theme.navTextColor
        , colorRule (selector ++ ".background-color-primary-background") theme.primaryBgColor theme.textColor
        ]


colorRule : String -> String -> String -> String
colorRule selector backgroundColor foregroundColor =
    selector ++ " { background-color: " ++ backgroundColor ++ "; color: " ++ foregroundColor ++ "; }\n"


{-| Escapes a hostname for literal use as one segment of a CSS class
selector -- e.g. the dots in "jonline.io", which would otherwise be parsed as
separate class selectors (`.jonline.io` means "has both class `jonline` and
class `io`", not "has class `jonline.io`").
-}
escapeClass : String -> String
escapeClass hostname =
    hostname
        |> String.toList
        |> List.map escapeChar
        |> String.concat


escapeChar : Char -> String
escapeChar c =
    if Char.isAlphaNum c || c == '-' || c == '_' then
        String.fromChar c

    else
        "\\" ++ String.fromChar c
