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
  - `<host> post-star.starred` -- `primaryAnchorColor` (text color only), used by `Components.Posts`' star button to fill in once a Post is starred (see `Shared.StarredPostsPanel`); `.post-star`'s own `transition` (in `posts.css`) is what animates it.
  - `<host> post-card-current .post-star` -- `backgroundColor` at 50% opacity (background-color only) -- backs the star button of a `Components.Posts.postCard` marked `current` (see `Shared.StarredPostsPanel.view`) with the app's own light/dark background, since its usual `primaryAnchorColor` text doesn't reliably contrast against that same card's `primaryColor` fill; semi-transparent (same "-50" convention as `border-color-primary-anchor-50`) so it reads as a tint rather than a flat patch. The pill shape itself is `posts.css`'s `.post-card-current .post-star`.

This is cheap to regenerate (it's just string-building); the actual expensive
color math is already cached in `Shared.Branding`.

-}

import Char
import Html exposing (Html, node, text)
import Shared
import Shared.AccountsPanel as AccountsPanel
import UI.ServerTheme


view : Shared.Model -> Html msg
view shared =
    node "style" [] [ text (css shared) ]


css : Shared.Model -> String
css shared =
    let
        darkMode =
            Shared.effectiveDarkMode shared

        mainTheme =
            AccountsPanel.mainServerTheme darkMode shared.accountsPanel
    in
    mainFrontendServerRules mainTheme shared.accountsPanel
        ++ String.concat
            (List.map (serverRules darkMode mainTheme shared.accountsPanel.mainFrontendHost)
                shared.accountsPanel.servers
            )


{-| Root-element rules driven by `mainFrontendHost`'s theme -- these apply
app-wide (not scoped to a per-server class) since they stand in for what used
to be the single, static `--accent` CSS var: every link's color, and the
"on" color of every toggle switch. (A selected `web-ui-button` is tinted with
its own account's server, via the per-server `background-color-primary`
utility class below -- see `UI.elm`'s `webUiButton`.)

The one exception is contrast against a switch's own row: an `account-row`
for an account on `mainFrontendHost` itself is already tinted with that
host's `primaryColor` (see `UI.elm`'s `accountRow`), so `primaryAnchorColor`
(derived from that same `primaryColor`) wouldn't read as well there as
`navAnchorColor` does. The `.account-row` rule's selector is more specific
than the plain switch rule above, so it wins there regardless of rule
order. Other accounts' rows aren't tinted with `mainFrontendHost`'s colors
at all, so they don't need (or get) this override.

-}
mainFrontendServerRules : UI.ServerTheme.ServerTheme -> AccountsPanel.Model -> String
mainFrontendServerRules theme accountsPanel =
    let
        mainHostSelector =
            "." ++ escapeClass accountsPanel.mainFrontendHost
    in
    String.concat
        [ "a { color: " ++ theme.primaryAnchorColor ++ "; }\n"
        , ".switch input:checked + .slider { background: " ++ theme.primaryAnchorColor ++ "; }\n"
        , ".account-row" ++ mainHostSelector ++ " .switch input:checked + .slider { background: " ++ theme.navAnchorColor ++ "; }\n"
        ]


serverRules : Bool -> UI.ServerTheme.ServerTheme -> String -> AccountsPanel.Server -> String
serverRules darkMode mainTheme mainFrontendHost server =
    let
        theme =
            AccountsPanel.serverThemeOf darkMode server

        selector =
            "." ++ escapeClass server.frontendHost

        -- The server chip's enable switch sits on a `background-color-nav`
        -- (this server's own navColor) tile, so its "on" color needs to
        -- contrast against *that* rather than the generic switch rule's
        -- mainFrontendHost.primaryAnchorColor (see `mainFrontendServerRules`)
        -- -- same idea as that rule's `.account-row` override, but keyed off
        -- this server's navColor lightness instead of darkMode.
        switchOnColor =
            if server.branding.nav.isDark then
                mainTheme.primaryDarkColor

            else
                mainTheme.primaryLightColor

        -- Same idea for an account row's switch, keyed off this server's
        -- primaryColor lightness (what `account-row` is tinted with) instead
        -- of navColor. Skipped for mainFrontendHost -- its account rows are
        -- already handled by `mainFrontendServerRules`' own `.account-row`
        -- override, which uses navAnchorColor rather than this
        -- light/dark-of-primaryColor logic.
        accountSwitchOnColor =
            if server.branding.primary.isDark then
                mainTheme.primaryDarkColor

            else
                mainTheme.primaryLightColor

        accountRowSwitchRule =
            if server.frontendHost == mainFrontendHost then
                ""

            else
                ".account-row" ++ selector ++ " .switch input:checked + .slider { background: " ++ accountSwitchOnColor ++ "; }\n"
    in
    String.concat
        [ colorRule (selector ++ ".background-color-primary") theme.primaryColor theme.primaryTextColor
        , colorRule (selector ++ ".background-color-primary-5") (theme.primaryColor ++ "05") theme.textColor
        , colorRule (selector ++ ".background-color-primary-10") (theme.primaryColor ++ "10") theme.textColor
        , colorRule (selector ++ ".background-color-primary-25") (theme.primaryColor ++ "40") theme.textColor
        , colorRule (selector ++ ".background-color-primary-50") (theme.primaryColor ++ "80") theme.textColor
        , colorRule (selector ++ ".background-color-nav") theme.navColor theme.navTextColor
        , colorRule (selector ++ ".background-color-primary-background") theme.primaryBgColor theme.textColor
        , borderColorRule (selector ++ ".border-color-primary") theme.primaryColor
        , borderColorRule (selector ++ ".border-color-primary-anchor") theme.primaryAnchorColor
        , borderColorRule (selector ++ ".border-color-primary-anchor-50") (theme.primaryAnchorColor ++ "80")
        , borderColorRule (selector ++ ".hover-border-color-primary-anchor:hover") theme.primaryAnchorColor
        , textColorRule (selector ++ ".post-star.starred") theme.primaryAnchorColor
        , backgroundOnlyColorRule (selector ++ ".post-card-current .post-star") (theme.backgroundColor ++ "80")
        , ".server-chip-bottom" ++ selector ++ " .switch input:checked + .slider { background: " ++ switchOnColor ++ "; }\n"
        , accountRowSwitchRule
        ]


colorRule : String -> String -> String -> String
colorRule selector backgroundColor foregroundColor =
    selector ++ " { background-color: " ++ backgroundColor ++ "; color: " ++ foregroundColor ++ "; }\n"


backgroundOnlyColorRule : String -> String -> String
backgroundOnlyColorRule selector backgroundColor =
    selector ++ " { background-color: " ++ backgroundColor ++ "; }\n"


borderColorRule : String -> String -> String
borderColorRule selector borderColor =
    selector ++ " { border-color: " ++ borderColor ++ "; }\n"


textColorRule : String -> String -> String
textColorRule selector color =
    selector ++ " { color: " ++ color ++ "; }\n"


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
