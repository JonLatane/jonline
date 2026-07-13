module UI.EmittedStylesheet exposing (view)

{-| A `<style>` tag, computed fresh from the current `Shared.Model` on every
render (so it updates automatically any time a server is added/removed, or
the current server/dark-light mode changes): `mainFrontendServerRules` (root
element rules -- `a`, switches, buttons -- driven by `mainFrontendHost`'s
theme, standing in for what used to be the static `--accent` CSS var), plus,
for each known server, a handful of color "utility class" pairs so any
element can be given that server's colors just by adding two classes -- e.g.
`class="jonline.io background-color-primary"` -- rather than needing that
server's `ServerTheme` threaded in as a view-function argument.

  - `<host> background-color-primary` -- `primaryColor` / `primaryTextColor`
  - `<host> background-color-nav` -- `navColor` / `navTextColor`
  - `<host> background-color-primary-background` -- `primaryBgColor` / `textColor`
  - `<host> border-color-primary` -- `primaryColor` (border-color only)
  - `<host> border-color-primary-anchor` -- `primaryAnchorColor` (border-color only; unused so far, but establishes the naming convention below)
  - `<host> border-color-primary-anchor-50` -- `primaryAnchorColor` at 50% opacity (border-color only)
  - `<host> hover-border-color-primary-anchor` -- `primaryAnchorColor` (border-color only), applied only on `:hover` -- pair with `border-color-primary-anchor-50` (or similar) for a border that "fills in" on hover; add `transition: border-color` yourself if you want that to animate, since this class alone is just the `:hover` color rule.

This is cheap to regenerate (it's just string-building); the actual expensive
color math is already cached in `Shared.Branding`.

-}

import Char
import Html exposing (Html, node, text)
import Shared
import Shared.AccountsPanel as AccountsPanel


view : Shared.Model -> Html msg
view shared =
    node "style" [] [ text (css shared) ]


css : Shared.Model -> String
css shared =
    let
        darkMode =
            Shared.effectiveDarkMode shared
    in
    mainFrontendServerRules darkMode shared.accountsPanel
        ++ String.concat (List.map (serverRules darkMode) shared.accountsPanel.servers)


{-| Root-element rules driven by `mainFrontendHost`'s theme -- these apply
app-wide (not scoped to a per-server class) since they stand in for what used
to be the single, static `--accent` CSS var: every link's color, and the
"on" color of every toggle switch and every selected `web-ui-button`.

The one exception is contrast against a switch's own row: an `account-row`
for an account on `mainFrontendHost` itself is already tinted with that
host's `primaryColor` (see `UI.elm`'s `accountRow`), so `primaryAnchorColor`
(derived from that same `primaryColor`) wouldn't read as well there as
`navAnchorColor` does. The `.account-row` rule's selector is more specific
than the plain switch rule above, so it wins there regardless of rule
order. Other accounts' rows aren't tinted with `mainFrontendHost`'s colors
at all, so they don't need (or get) this override.
-}
mainFrontendServerRules : Bool -> AccountsPanel.Model -> String
mainFrontendServerRules darkMode accountsPanel =
    let
        theme =
            AccountsPanel.mainServerTheme darkMode accountsPanel

        mainHostSelector =
            "." ++ escapeClass accountsPanel.mainFrontendHost
    in
    String.concat
        [ "a { color: " ++ theme.primaryAnchorColor ++ "; }\n"
        , ".switch input:checked + .slider { background: " ++ theme.primaryAnchorColor ++ "; }\n"
        , ".web-ui-button.selected { background: " ++ theme.primaryAnchorColor ++ "; border-color: " ++ theme.primaryAnchorColor ++ "; }\n"
        , ".account-row" ++ mainHostSelector ++ " .switch input:checked + .slider { background: " ++ theme.navAnchorColor ++ "; }\n"
        ]


serverRules : Bool -> AccountsPanel.Server -> String
serverRules darkMode server =
    let
        theme =
            AccountsPanel.serverThemeOf darkMode server

        selector =
            "." ++ escapeClass server.frontendHost
    in
    String.concat
        [ colorRule (selector ++ ".background-color-primary") theme.primaryColor theme.primaryTextColor
        , colorRule (selector ++ ".background-color-nav") theme.navColor theme.navTextColor
        , colorRule (selector ++ ".background-color-primary-background") theme.primaryBgColor theme.textColor
        , borderColorRule (selector ++ ".border-color-primary") theme.primaryColor
        , borderColorRule (selector ++ ".border-color-primary-anchor") theme.primaryAnchorColor
        , borderColorRule (selector ++ ".border-color-primary-anchor-50") (theme.primaryAnchorColor ++ "80")
        , borderColorRule (selector ++ ".hover-border-color-primary-anchor:hover") theme.primaryAnchorColor
        ]


colorRule : String -> String -> String -> String
colorRule selector backgroundColor foregroundColor =
    selector ++ " { background-color: " ++ backgroundColor ++ "; color: " ++ foregroundColor ++ "; }\n"


borderColorRule : String -> String -> String
borderColorRule selector borderColor =
    selector ++ " { border-color: " ++ borderColor ++ "; }\n"


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
