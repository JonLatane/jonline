module UI exposing (imageOrInitial, layout, page, pageTitle)

import Components.Markdown as Markdown
import Components.PostCard as Posts
import Components.Users as Users
import Dict
import Effect exposing (Effect)
import Gen.Route as Route exposing (Route(..))
import Html exposing (Attribute, Html, a, button, div, header, img, input, label, main_, nav, p, span, text)
import Html.Attributes exposing (alt, attribute, checked, class, classList, disabled, href, id, name, placeholder, spellcheck, src, style, target, title, type_, value)
import Html.Events exposing (on, onClick, onInput, onSubmit, preventDefaultOn, stopPropagationOn)
import Html.Keyed
import Json.Decode as Decode
import Page
import Proto.Jonline.WebUserInterface exposing (WebUserInterface(..))
import Request
import Set
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.AdminPanel as AdminPanel
import Shared.Breadcrumbs as Breadcrumbs
import Shared.FederatedAuth as FederatedAuth
import Shared.MarkdownPanel as MarkdownPanel
import Shared.MediaViewerPanel as MediaViewerPanel
import Shared.StarredPostsPanel as StarredPostsPanel
import UI.Classes exposing (classes, hostnameToCSSClass, openClosedClass)
import UI.EmittedStylesheet as EmittedStylesheet
import UI.Flip
import UI.Modal
import View exposing (View)


{-| Builds a page that has no state of its own beyond the shared auth/account
state, rendered inside the common `layout`. Every page that only needs the nav
and login form (i.e. doesn't need its own Model/Msg) should be built with this.

Closes the Accounts Panel on `init` -- relying on the navigating link's own
`onClick` to close the panel would race against the browser's separate
click-to-navigation handling, with no guaranteed order. Closing here instead
is deterministic: it always runs once the destination page actually loads,
regardless of how the panel got left open.

-}
page : Shared.Model -> Request.With params -> View Shared.Msg -> Page.With () Shared.Msg
page shared req body =
    Page.advanced
        { init = ( (), Effect.fromShared (Shared.AccountsPanelMsg AccountsPanel.CloseAccountsPanel) )
        , update = \msg () -> ( (), Effect.fromShared msg )
        , view = \() -> { title = body.title, body = layout shared req.route identity body.body }
        , subscriptions = \() -> Sub.none
        }


{-| The nav (`header`) is a full-width, sticky band tinted with
`mainFrontendHost`'s `primaryColor` (see `UI.EmittedStylesheet`'s
`background-color-primary` utility class) -- its own `.navbar-inner` wrapper
keeps its content lined up with the (narrower) page content below. `main` gets
its own `.container` so it's centered independently of the nav.

Generic in `msg` (via `toMsg`) so pages with their own `Model`/`Msg` -- rather
than just `page`'s no-local-state pages -- can embed this nav/login chrome
too, mapping its `Shared.Msg` clicks into their own `Msg` type. See
`Pages.Home_`/`Pages.Post.PostId_`.

-}
layout : Shared.Model -> Route -> (Shared.Msg -> msg) -> List (Html msg) -> List (Html msg)
layout shared currentRoute toMsg children =
    [ Html.map toMsg (EmittedStylesheet.view shared)
    , Html.map toMsg (sharedBackdrop shared)
    , Html.map toMsg (headerNav shared currentRoute)
    , Html.map toMsg (createAccountConfirmationBackdrop shared)
    , Html.map toMsg (createAccountConfirmationModal shared)
    , Html.map toMsg (deleteConfirmationBackdrop shared)
    , Html.map toMsg (deleteConfirmationModal shared)
    , Html.map toMsg (markdownPanel shared)
    , Html.map toMsg (mediaViewerPanel shared)
    , div [ class "container" ] [ main_ [] (children ++ [ scrollPreserver shared ]) ]
    ]


{-| A tall, empty spacer at the bottom of `main_`'s content -- shown (see
`Shared.Model.scrollPreserverVisible`) for the first 2s after navigating back
to a page (browser back button only, not a fresh link click -- see change 4 in
`Main.elm`'s module doc), so that page's content, which can still be shorter
than it was when the browser recorded the scroll offset it's now restoring,
doesn't get its scroll position yanked around while it fills back in. Always
rendered, like `sharedBackdrop`'s `is-open`/`is-closed` -- see
`UI.Classes.openClosedClass` -- rather than added/removed outright, so the
`height` change (see `main.css`) is a plain CSS transition.
-}
scrollPreserver : Shared.Model -> Html msg
scrollPreserver shared =
    div [ classes [ "scroll-preserver", openClosedClass shared.scrollPreserverVisible ] ] []


{-| Tapping the navbar anywhere outside the Home link, the Starred Posts
toggle/panel, or the Accounts menu/panel scrolls the page to top -- same
`Shared.ScrollToTop` that re-tapping Home while already on it fires (see
`navLink`'s doc). Those three carve themselves out of this via
`stopPropagationOn "click"` on their own root elements (`navLink`,
`starredPostsToggle`, `accountsMenu`'s `.accounts-menu` div) rather than
`onClick`, so a tap on any of them (or their own dropdowns/menus) never
bubbles up to this handler; `starredPostsPanel` isn't itself one of those
three roots (it's rendered as its own `.navbar` child, not nested under
`starredPostsToggle` -- see the comment below), so it gets its own wrapper
here instead.
-}
headerNav : Shared.Model -> Route -> Html Shared.Msg
headerNav shared currentRoute =
    header
        [ classes [ "navbar", hostnameToCSSClass shared.accountsPanel.mainFrontendHost, "background-color-primary" ]
        , onClick Shared.ScrollToTop
        ]
        [ div [ class "navbar-inner" ]
            [ nav [ class "nav-links" ]
                [ navLink shared currentRoute (homeLinkContent shared) Route.Home_
                , if Set.isEmpty shared.starredPostsPanel.starredPostIds then
                    text ""

                  else
                    starredPostsToggle shared
                ]
            , div [ class "nav-right" ] [ accountsMenu shared ]
            ]

        -- A direct child of `.navbar` itself (a positioned ancestor spanning
        -- the full viewport width), not of `.admin-menu` (the toggle's own
        -- narrow wrapper, off to one side) -- so `.starred-posts-panel`'s
        -- `left: 0` in starred_posts_panel.css hugs the actual screen edge instead of just
        -- the toggle's left edge. See `starredPostsPanel`.
        --
        -- Wrapped in its own `stopPropagationOn`-bearing `div` (a plain,
        -- unpositioned element, so it doesn't disturb the `left`/`top` math
        -- above -- that's all resolved against `.navbar` itself, the nearest
        -- *positioned* ancestor, not the immediate parent) so taps inside the
        -- open panel don't also bubble up to this `Shared.ScrollToTop`
        -- tap-anywhere handler.
        , if Set.isEmpty shared.starredPostsPanel.starredPostIds then
            text ""

          else
            div [ stopPropagationOn "click" (Decode.succeed ( Shared.NoOp, True )) ]
                [ starredPostsPanel shared currentRoute ]

        -- Sits below `.navbar-inner`, at the very bottom of `.navbar` itself
        -- -- see `breadcrumbsBar`.
        , breadcrumbsBar shared

        -- A direct child of `.navbar` too (not just `breadcrumbsBar`'s own
        -- wrapper), same reasoning as `starredPostsPanel` above -- so it's
        -- anchored to the full-width `.navbar`'s own bottom edge (which
        -- includes `breadcrumbsBar`'s row) rather than just some narrower
        -- element's. See `breadcrumbsReplyPanel`.
        , breadcrumbsReplyPanel shared
        ]


{-| One entry in `sharedBackdrop`'s priority list: whether this panel is
currently open, the message that closes just this panel, and whether its
being open should blur/tint the shared backdrop (the Accounts Panel and the
Markdown panel both block interaction with the rest of the page like that --
see `sharedBackdrop`).
-}
type alias BackdropPanel =
    { isOpen : Bool
    , closeMsg : Shared.Msg
    , blurs : Bool
    }


{-| Covers everything except the top nav (which sits in its own, higher
stacking context -- see `.navbar` in nav.css) for every panel that closes
via a background tap -- currently the Starred Posts panel, the Accounts
Panel, the Breadcrumbs reply viewer and the Markdown panel, with more
expected to join this list later. Always rendered, like the panels
themselves, so opening/closing (and the blur) is a plain CSS transition
rather than the element appearing/disappearing outright, and only receives
clicks (`pointer-events`) while at least one listed panel is open.

The Media Viewer panel is deliberately not one of these -- unlike the others,
its own box already spans the whole viewport rather than a small, anchored
dropdown, and it sits above `.navbar` itself (see media\_viewer\_panel.css), so
it can't rely on this backdrop (below `.navbar`, see nav.css) for its own
dimming/click-to-close anyway. It owns both outright instead: its own
background _is_ the dimmed/blurred overlay, and its own root `onClick` is
the background-tap-to-close, both self-contained in
`Shared.MediaViewerPanel`/media\_viewer\_panel.css -- see their own doc
comments.

Listed nearest-first: when several panels are open at once, a background tap
closes only the first one in this list (see `topmostOpenPanel`) -- one tap per
panel to peel them off in order, front-to-back, rather than closing everything
at once. Right now that means tapping the background closes the Starred Posts
panel first, then the Accounts Panel, then the Breadcrumbs reply viewer, then
(on a fourth tap) the Markdown panel behind all three -- matching the actual
paint order. `.breadcrumb-reply-panel` is (like the Accounts/Starred Posts
panels) a `.navbar` descendant, so all three render above `.markdown-panel`
(a `.navbar` _sibling_) regardless of their own individual z-indices, purely
because `.navbar`'s own z-index (28) beats `.markdown-panel`'s (26) as whole
stacking contexts; _within_ `.navbar`, `.breadcrumb-reply-panel`'s lower
z-index (see nav.css) is what then keeps it under the Accounts/Starred Posts
panels specifically. Swap their order here to change that priority. Only
blurs/tints the page while a panel with `blurs = True` is open (currently the
Accounts Panel, the Breadcrumbs reply viewer and the Markdown panel, all of
which block interaction with the rest of the page while open); the Starred
Posts panel doesn't, since starring/unstarring posts while it's open is an
expected, encouraged interaction rather than something to block.

-}
sharedBackdrop : Shared.Model -> Html Shared.Msg
sharedBackdrop shared =
    let
        panels : List BackdropPanel
        panels =
            [ { isOpen = shared.starredPostsPanel.showStarredPostsPanel
              , closeMsg = Shared.StarredPostsPanelMsg StarredPostsPanel.ToggleStarredPostsPanel
              , blurs = False
              }
            , { isOpen = shared.accountsPanel.showAccountsPanel
              , closeMsg = Shared.AccountsPanelMsg AccountsPanel.ToggleAccountsPanel
              , blurs = True
              }
            , { isOpen = shared.breadcrumbs.viewing /= Nothing
              , closeMsg = Shared.BreadcrumbsMsg Breadcrumbs.CloseViewer
              , blurs = True
              }
            , { isOpen = shared.markdownPanel.target /= Nothing
              , closeMsg = Shared.MarkdownPanelMsg MarkdownPanel.CancelClicked
              , blurs = True
              }
            ]

        topmostOpenPanel : Maybe BackdropPanel
        topmostOpenPanel =
            List.filter .isOpen panels |> List.head
    in
    div
        [ classes
            ([ "shared-backdrop", openClosedClass (topmostOpenPanel /= Nothing) ]
                ++ (if List.any (\panel -> panel.isOpen && panel.blurs) panels then
                        [ "blurred" ]

                    else
                        []
                   )
            )
        , onClick
            (topmostOpenPanel
                |> Maybe.map .closeMsg
                |> Maybe.withDefault (Shared.AccountsPanelMsg AccountsPanel.ToggleAccountsPanel)
            )
        ]
        []


{-| Fires `msg` (and suppresses the key's default effect, e.g. inserting a
newline) when Enter is pressed in a text input -- used to chain focus through
the login form and to trigger "Add Server"/"Login" the same way clicking
their buttons would.
-}
onEnter : msg -> Attribute msg
onEnter msg =
    preventDefaultOn "keydown"
        (Decode.field "key" Decode.string
            |> Decode.andThen
                (\key ->
                    if key == "Enter" then
                        Decode.succeed ( msg, True )

                    else
                        Decode.fail "Not the Enter key"
                )
        )


{-| A nav link styled as a button: the current page's link additionally gets
`mainFrontendHost`'s `background-color-nav` utility class, tinting it with
`navColor`/`navTextColor` so it stands out against the `primaryColor`-tinted
navbar around it; other links just inherit that surrounding primary color/text
color by not overriding them. The Home link also gets its own `nav-link-home`
class (regardless of `isCurrent`) so `nav.css` can give its bigger,
stacked `RegularServerLogo` content (see `homeLinkContent`) the same
negative-margin overflow treatment as the Accounts Panel toggle, and its own
`onClick` (`Shared.HomeLinkClicked`) closing the Starred Posts panel and,
when `isCurrent` (tapping Home while already on it), firing
`Shared.ScrollToTop` -- unlike the Accounts Panel (see `UI.page`'s doc
comment on why that one closes on a destination page's `init` instead),
there's no dedicated "just navigated Home" hook to close it or scroll from,
since `Pages.Home_` keeps its own `Model` alive across a same-route re-click
that no `init`/`ChangedUrl` would rerun for -- so this is the only place
that reliably still fires every time. Uses `stopPropagationOn`, not plain
`onClick`, so this doesn't also trigger `headerNav`'s own tap-anywhere
`Shared.ScrollToTop` (redundant when `isCurrent` already fires it above, and
undesired when navigating away instead).
-}
navLink : Shared.Model -> Route -> Html Shared.Msg -> Route -> Html Shared.Msg
navLink shared currentRoute content linkRoute =
    let
        isCurrent =
            linkRoute == currentRoute

        isHome =
            linkRoute == Route.Home_
    in
    a
        ([ href (shared.basePath ++ Route.toHref linkRoute)
         , classes
            ("nav-link"
                :: (if isHome && mainServer shared /= Nothing then
                        [ "nav-link-home" ]

                    else
                        []
                   )
                ++ (if isCurrent then
                        [ hostnameToCSSClass shared.accountsPanel.mainFrontendHost, "background-color-nav" ]

                    else
                        []
                   )
            )
         ]
            ++ (if isHome then
                    [ stopPropagationOn "click" (Decode.succeed ( Shared.HomeLinkClicked isCurrent, True )) ]

                else
                    []
               )
        )
        [ content ]


{-| The Home link's content is normally the browsing server's own
logo/name (via `AccountsPanel.serverNameAndLogo`), same `RegularServerLogo`
(stacked glyph-above-multi-line-name) style as the server chips in the
Accounts Panel -- just bigger, per `.nav-link-home` in `nav.css` -- falling
back to the literal text "Home" only for the brief window before
`mainFrontendHost` has actually finished connecting (see
`AccountsPanel.init`/`GotMainServerResult`), when it isn't in `servers` yet.
-}
homeLinkContent : Shared.Model -> Html msg
homeLinkContent shared =
    case mainServer shared of
        Just server ->
            AccountsPanel.serverNameAndLogo server AccountsPanel.RegularServerLogo

        Nothing ->
            text "Home"


{-| Looks up a known server by `frontendHost` -- a thin wrapper around
`AccountsPanel.serverForHost` for callers that already have a `Shared.Model`
in scope rather than the bare `List AccountsPanel.Server`.
-}
findServer : Shared.Model -> String -> Maybe AccountsPanel.Server
findServer shared frontendHost =
    AccountsPanel.serverForHost shared.accountsPanel.servers frontendHost


mainServer : Shared.Model -> Maybe AccountsPanel.Server
mainServer shared =
    findServer shared shared.accountsPanel.mainFrontendHost


{-| Every page's browser tab title, built from `segments` (most-specific
first, e.g. a post's title, or -- once posts/profiles can belong to one --
that title _and_ its Group's name) followed by `mainFrontendHost`'s own
branding name, e.g. `"My Post | My Server"`. An empty `segments` (the Home
page) is just the server name on its own, with no leading `" | "`.

Centralizing this means every page's title updates together if the format
ever changes, and a future segment (like that Group name) is just another
list entry for the page to prepend -- not a new format to invent.

-}
pageTitle : Shared.Model -> List String -> String
pageTitle shared segments =
    String.join " | " (segments ++ [ serverName shared ])


{-| `mainFrontendHost`'s branding name, falling back to the bare hostname for
the brief window before that server's finished connecting (see `mainServer`).
-}
serverName : Shared.Model -> String
serverName shared =
    mainServer shared
        |> Maybe.map (.branding >> .name)
        |> Maybe.withDefault shared.accountsPanel.mainFrontendHost


{-| The former "About" nav link, now a small circular "i" button stacked above
the theme toggle at the Accounts Panel's top-right corner (see
`accountsPanel`).
-}
infoButton : Shared.Model -> Html Shared.Msg
infoButton shared =
    a
        [ classes [ "panel-icon-button", "info-button" ]
        , href (shared.basePath ++ Route.toHref Route.About)
        , onClick (Shared.AccountsPanelMsg AccountsPanel.CloseAccountsPanel)
        , title "About"
        ]
        [ text "i" ]


{-| Cycles Auto -> Light -> Dark -> Auto. "Auto" follows the OS preference
(and reacts live if it changes); "Light"/"Dark" force it.
-}
themeToggle : Shared.Model -> Html Shared.Msg
themeToggle shared =
    let
        icon =
            case shared.themePreference of
                Shared.ThemeAuto ->
                    "🌓"

                Shared.ThemeLight ->
                    "☀️"

                Shared.ThemeDark ->
                    "🌙"
    in
    button
        [ classes [ "panel-icon-button", "theme-toggle" ]
        , onClick Shared.ThemePreferenceClicked
        , title ("Appearance: " ++ Shared.themePreferenceLabel shared.themePreference ++ " (click to change)")
        ]
        [ text icon ]



-- ACCOUNTS MENU


accountsMenu : Shared.Model -> Html Shared.Msg
accountsMenu shared =
    let
        enabledAccounts =
            AccountsPanel.enabledAccounts shared.accountsPanel

        -- Signed into exactly one account on exactly one enabled server --
        -- since only one account per server can be enabled at a time (see
        -- `AccountsPanel.ToggleAccountEnabled`), this is the "single user"
        -- case: there's no second avatar to stack and no server count worth
        -- a subtitle, so the toggle becomes one larger avatar circle instead
        -- of the usual pill (see `.accounts-menu-toggle.single-avatar`).
        singleAccountSingleServer =
            case ( AccountsPanel.enabledServers shared.accountsPanel, enabledAccounts ) of
                ( [ _ ], [ _ ] ) ->
                    True

                _ ->
                    False

        toggleClasses =
            "accounts-menu-toggle"
                :: openClosedClass shared.accountsPanel.showAccountsPanel
                :: (if List.isEmpty enabledAccounts then
                        []

                    else
                        [ "has-avatars" ]
                   )
                ++ (if singleAccountSingleServer then
                        [ "single-avatar" ]

                    else
                        []
                   )
    in
    div
        [ class "accounts-menu"

        -- Stops both the toggle and everything in the dropdown it wraps
        -- (`accountsPanel`, below) from also bubbling up into `headerNav`'s
        -- own tap-anywhere `Shared.ScrollToTop`.
        , stopPropagationOn "click" (Decode.succeed ( Shared.NoOp, True ))
        ]
        [ div [ class "accounts-menu-row" ]
            [ button
                [ classes toggleClasses
                , onClick (Shared.AccountsPanelMsg AccountsPanel.ToggleAccountsPanel)
                ]
                (if singleAccountSingleServer then
                    [ accountsMenuButtonContent shared enabledAccounts ]

                 else
                    [ accountsMenuButtonContent shared enabledAccounts
                    , accountsMenuServerSummary shared.accountsPanel
                    ]
                )
            , hostMismatchWarning shared
            ]
        , accountsPanel shared
        ]


{-| The accounts-menu toggle button's content: "Login" with nobody signed in,
otherwise a small avatar/placeholder per signed-in account (see
`accountsMenuAvatar`) in place of any username/count text.
-}
accountsMenuButtonContent : Shared.Model -> List AccountsPanel.Account -> Html Shared.Msg
accountsMenuButtonContent shared enabledAccounts =
    case enabledAccounts of
        [] ->
            text "Login"

        accounts ->
            div [ class "accounts-menu-avatars" ] (List.map (accountsMenuAvatar shared) accounts)


{-| A small-font subtitle under the accounts-menu toggle button's "Login" text/
avatars, summarizing how many servers are currently enabled: nothing for the
common single-server case where that server is `mainFrontendHost`, that
server's branding name when it's the lone enabled server but not
`mainFrontendHost` (so it's clear which server is actually being browsed),
"N servers" for any other count, or "No servers ⚠️" when every server's been
disabled. If any account's server is currently unreachable (see
`AccountsPanel.unreachableAccountHosts`, surfaced below as "Couldn't reach:
..."), the count is always shown -- even "1 server" -- with its own ⚠️, so
that warning isn't silently hidden behind the usual single-server blank
state. Recomputed on every render (so it updates live as servers are
toggled/reconnected) directly off `AccountsPanel.enabledServers` and
`AccountsPanel.unreachableAccountHosts`.
-}
accountsMenuServerSummary : AccountsPanel.Model -> Html Shared.Msg
accountsMenuServerSummary accountsPanelModel =
    let
        servers =
            AccountsPanel.enabledServers accountsPanelModel

        count =
            List.length servers

        hasUnreachableServers =
            not (List.isEmpty (AccountsPanel.unreachableAccountHosts accountsPanelModel))

        serversText =
            String.fromInt count
                ++ " server"
                ++ (if count == 1 then
                        ""

                    else
                        "s"
                   )
                ++ (if hasUnreachableServers then
                        " ⚠️"

                    else
                        ""
                   )
    in
    case servers of
        [] ->
            div [ class "accounts-menu-server-summary" ] [ text "No servers ⚠️" ]

        [ singleServer ] ->
            if hasUnreachableServers || not (singleServer.frontendHost == accountsPanelModel.mainFrontendHost) then
                div [ class "accounts-menu-server-summary" ] [ text serversText ]

            else
                text ""

        _ ->
            div [ class "accounts-menu-server-summary" ] [ text serversText ]


{-| A small avatar/placeholder for the accounts-menu toggle button, bordered
with the account's server's `primaryColor` (via `border-color-primary`, see
`UI.EmittedStylesheet`) -- but only for accounts on a server other than
`mainFrontendHost`, so the common case (only signed into the main server)
doesn't show a border at all.
-}
accountsMenuAvatar : Shared.Model -> AccountsPanel.Account -> Html Shared.Msg
accountsMenuAvatar shared account =
    let
        accountsPanelModel =
            shared.accountsPanel

        avatarClasses =
            "accounts-menu-avatar"
                :: (if account.server /= accountsPanelModel.mainFrontendHost then
                        [ hostnameToCSSClass account.server, "border-color-primary" ]

                    else
                        []
                   )
    in
    imageOrInitial avatarClasses account.username (AccountsPanel.accountAvatarUrl accountsPanelModel.servers account)


{-| `browsingHost` and `mainFrontendHost` differ when the host we're actually
being viewed from turns out to be a backend-only host with a different public
identity (see `Shared.AccountsPanel`'s `resolvedFrontendHost`) -- worth
flagging, since the user probably has the "wrong" (if working) URL open.
Clicking it force-resets `mainFrontendHost` back to `browsingHost`
(`ResetMainFrontendHost`) rather than navigating anywhere.

Always shown next to the Accounts Panel toggle (regardless of whether an admin
account is signed in -- the Admin Panel now lives inside the Accounts Panel
itself as a tab, see `adminTab`), rather than being folded into it.

-}
hostMismatchWarning : Shared.Model -> Html Shared.Msg
hostMismatchWarning shared =
    let
        accountsPanelModel =
            shared.accountsPanel
    in
    if hostMismatch shared then
        span
            [ class "host-mismatch-warning"
            , onClick (Shared.AccountsPanelMsg AccountsPanel.ResetMainFrontendHost)
            , title
                ("You're browsing from "
                    ++ accountsPanelModel.browsingHost
                    ++ ", but it's configured to look like "
                    ++ accountsPanelModel.mainFrontendHost
                    ++ ". Click to browse from "
                    ++ accountsPanelModel.browsingHost
                    ++ " instead."
                )
            ]
            [ text "⚠️" ]

    else
        text ""


{-| True when `browsingHost` and `mainFrontendHost` differ -- see
`hostMismatchWarning`.
-}
hostMismatch : Shared.Model -> Bool
hostMismatch shared =
    shared.accountsPanel.browsingHost /= shared.accountsPanel.mainFrontendHost


{-| Servers scroll horizontally in a short strip (there are usually few, and it
keeps them visually distinct from the taller, vertically-scrolling account
list below), which itself scrolls vertically since accounts are the thing
you'll accumulate the most of.

Always rendered (even "closed"), so opening/closing can be a plain CSS
transition (fade + slide) rather than the panel just appearing/disappearing
outright -- see `.nav-panel`/`.nav-panel.is-closed` in main.css.

-}
accountsPanel : Shared.Model -> Html Shared.Msg
accountsPanel shared =
    let
        accountsPanelModel =
            shared.accountsPanel
    in
    div [ classes [ "accounts-panel", "nav-panel", openClosedClass accountsPanelModel.showAccountsPanel ] ]
        [ accountsPanelTabBar shared
        , case activeTab shared of
            AdminPanel.AccountsAndServersTab ->
                accountsAndServersTab shared

            AdminPanel.SettingsTab ->
                settingsTab shared

            AdminPanel.AdminTab ->
                adminTab shared
        ]


{-| The tab bar itself: the "Accounts and Servers"/Settings/Admin tabs (see
`accountsPanelTab`) on the left, the info/brightness buttons -- horizontal
here, unlike their old stacked-in-the-corner layout -- on the right.
-}
accountsPanelTabBar : Shared.Model -> Html Shared.Msg
accountsPanelTabBar shared =
    div [ class "accounts-panel-tab-bar" ]
        [ div [ class "accounts-panel-tabs" ]
            (List.filterMap identity
                [ Just (accountsPanelTab shared AdminPanel.AccountsAndServersTab "Accounts & Servers" False)
                , if settingsCount shared > 0 then
                    Just (accountsPanelTab shared AdminPanel.SettingsTab "⚙️" True)

                  else
                    Nothing
                , if AccountsPanel.hasAdminAccount shared.accountsPanel then
                    Just (accountsPanelTab shared AdminPanel.AdminTab "🛡️" True)

                  else
                    Nothing
                ]
            )
        , div [ class "panel-icon-row" ] [ themeToggle shared, infoButton shared ]
        ]


accountsPanelTab : Shared.Model -> AdminPanel.AccountsPanelTab -> String -> Bool -> Html Shared.Msg
accountsPanelTab shared tab label isNarrow =
    button
        [ classes
            ("accounts-panel-tab"
                :: (if isNarrow then
                        [ "narrow" ]

                    else
                        []
                   )
                ++ (if activeTab shared == tab then
                        [ "selected" ]

                    else
                        []
                   )
            )
        , onClick (Shared.AdminPanelMsg (AdminPanel.TabSelected tab))
        ]
        [ text label ]


{-| How many Settings the Settings tab currently holds -- the "switch main
server by tapping servers" and "Sign into other hosts with username/password"
toggles (both admin-only) for now, but tracked as a count rather than a bare
`Bool` so the tab can grow more (non-admin-gated) settings later without
changing how its visibility is decided.
-}
settingsCount : Shared.Model -> Int
settingsCount shared =
    if AccountsPanel.hasAdminAccount shared.accountsPanel then
        2

    else
        0


{-| `shared.adminPanel.activeTab`, falling back to `AccountsAndServersTab`
whenever the selected tab isn't actually visible right now (e.g. the signed-in
admin account was just removed while the Admin tab was showing) -- so the
panel never ends up rendering a tab's content with no matching tab button
selected.
-}
activeTab : Shared.Model -> AdminPanel.AccountsPanelTab
activeTab shared =
    case shared.adminPanel.activeTab of
        AdminPanel.SettingsTab ->
            if settingsCount shared > 0 then
                AdminPanel.SettingsTab

            else
                AdminPanel.AccountsAndServersTab

        AdminPanel.AdminTab ->
            if AccountsPanel.hasAdminAccount shared.accountsPanel then
                AdminPanel.AdminTab

            else
                AdminPanel.AccountsAndServersTab

        AdminPanel.AccountsAndServersTab ->
            AdminPanel.AccountsAndServersTab


{-| The current UI of the Accounts Panel, minus the info/brightness buttons
(now in `accountsPanelTabBar` instead). Always shows, for everyone.
-}
accountsAndServersTab : Shared.Model -> Html Shared.Msg
accountsAndServersTab shared =
    div [ class "accounts-panel-tab-content" ]
        [ serversStrip shared
        , unreachableServersWarning shared
        , div [ class "panel-divider" ] []
        , accountsList shared
        , div [ class "panel-divider" ] []
        , formView shared
        ]


{-| The "switch main server by tapping servers" (see `serverChip`) and "Sign
into other hosts with username/password" (see `addAccountForm`) toggles --
only shown (via `settingsCount`) while an admin account is signed in.
-}
settingsTab : Shared.Model -> Html Shared.Msg
settingsTab shared =
    div [ class "accounts-panel-tab-content" ]
        [ label [ class "admin-switch-row" ]
            [ switchInput shared.adminPanel.allowMainServerSwitch False (Shared.AdminPanelMsg AdminPanel.ToggleAllowMainServerSwitch)
            , span [] [ text "Switch main server by tapping servers" ]
            ]
        , label [ class "admin-switch-row" ]
            [ switchInput shared.adminPanel.allowUsernamePasswordForOtherHosts False (Shared.AdminPanelMsg AdminPanel.ToggleAllowUsernamePasswordForOtherHosts)
            , span [] [ text "Sign into other hosts with username/password" ]
            ]
        ]


{-| The per-admin-Account sections (see `adminAccountPanel`) from the old
standalone Admin Panel.
-}
adminTab : Shared.Model -> Html Shared.Msg
adminTab shared =
    let
        adminAccounts =
            List.filter AccountsPanel.isAdmin shared.accountsPanel.accounts
    in
    div [ class "accounts-panel-tab-content" ]
        [ if List.isEmpty adminAccounts then
            text ""

          else
            div [ class "admin-accounts-list" ] (List.map (adminAccountPanel shared) adminAccounts)
        ]



-- SERVERS


serversStrip : Shared.Model -> Html Shared.Msg
serversStrip shared =
    let
        servers =
            shared.accountsPanel.servers

        count =
            List.length servers
    in
    Html.Keyed.node "div"
        [ classes [ "servers-strip", "flip-animated-row" ] ]
        (List.indexedMap
            (\index server -> ( server.frontendHost, serverChipFlip shared count index server ))
            servers
        )


{-| Wraps `serverChip` in a fading/scaling/collapsing animated outer `div`
(entering when freshly added, removing when deleted -- see
`AccountsPanel.serverAnimations`/`UI.Flip`) -- the `UI.Flip.Horizontal`
counterpart of `accountRowFlip`, whose doc covers the two-layer reasoning
(fade/collapse here vs. `serverChip`'s own, independent reorder-slide) in
full.
-}
serverChipFlip : Shared.Model -> Int -> Int -> AccountsPanel.Server -> Html Shared.Msg
serverChipFlip shared count index server =
    let
        flipState =
            Dict.get server.frontendHost shared.accountsPanel.serverAnimations
                |> Maybe.withDefault UI.Flip.restingState

        isMoving =
            Dict.get server.frontendHost shared.accountsPanel.serverMoveAnimations
                |> Maybe.map .moving
                |> Maybe.withDefault False

        pointerEventsAttr =
            if flipState.removing then
                [ style "pointer-events" "none" ]

            else
                []
    in
    div (UI.Flip.itemAttributes UI.Flip.Horizontal flipState isMoving)
        [ div pointerEventsAttr [ serverChip shared count index server ] ]


{-| Top portion (logo/name/host) gets that server's `background-color-primary`
utility classes (see `UI.EmittedStylesheet`); the enable switch, an external
link (opening the server's own `https://` site in a new tab -- omitted for
whichever server we're actually `browsingHost`-ing from, since that one's
already open here), and the delete button sit in a bottom portion using
`background-color-nav` instead.

The top portion is always clickable: tapping it fills the Account form's
Server field with this server's `frontendHost` (`ServerChipClicked`), so
switching which known server you're logging into/adding an account on is a
single tap. When the Server Admin Panel's "switch main server" toggle is also
on (see `Shared.AdminPanel`), that tap additionally sets this server as
`mainFrontendHost` (`MainServerSelected`, which fills the Server field too --
see its handler in `Shared.AccountsPanel`) instead of just filling the field.

-}
serverChip : Shared.Model -> Int -> Int -> AccountsPanel.Server -> Html Shared.Msg
serverChip shared count index server =
    let
        accountsPanelModel =
            shared.accountsPanel

        isMainServer =
            server.frontendHost == accountsPanelModel.mainFrontendHost

        hasAccounts =
            AccountsPanel.serverHasAccounts accountsPanelModel.accounts server.frontendHost

        removable =
            not hasAccounts && not isMainServer

        canSelectMain =
            shared.adminPanel.allowMainServerSwitch

        topClasses =
            [ "server-chip-top", "selectable", hostnameToCSSClass server.frontendHost, "background-color-primary" ]

        topAttrs =
            [ classes topClasses
            , onClick
                (Shared.AccountsPanelMsg
                    (if canSelectMain then
                        AccountsPanel.MainServerSelected server.frontendHost

                     else
                        AccountsPanel.ServerChipClicked server.frontendHost
                    )
                )
            , title
                (if canSelectMain then
                    "Set as main server"

                 else
                    "Use this server in the login form"
                )
            ]

        moveAttrs =
            accountsPanelModel.serverMoveAnimations
                |> Dict.get server.frontendHost
                |> Maybe.map UI.Flip.moveAttributes
                |> Maybe.withDefault []

        -- `stopPropagationOn`, not `onClick` -- these two buttons sit inside
        -- `topAttrs`'s own "select this server" click target (see
        -- `reorderButtonPair`'s doc), so a plain `onClick` here would also
        -- fire that.
        stopClick msg =
            stopPropagationOn "click" (Decode.succeed ( msg, True ))

        -- The main server (always `index == 0` -- see
        -- `AccountsPanel.sortMainServerFirst`) is pinned in place and isn't
        -- reorderable at all, so neither of its arrows is interactive. The
        -- server right after it can't move left into the main server's fixed
        -- slot, so its left arrow isn't interactive either; the last server
        -- can't move right past the end, so its right arrow isn't. Both
        -- conditions naturally leave a lone non-main server (`count == 2`)
        -- with neither arrow interactive. Non-interactive arrows still
        -- render (`reorder-arrow-hidden` just fades/no-ops them) rather than
        -- disappearing, so the chip's width/layout doesn't jump around
        -- depending on position.
        showBackward =
            index > 1

        showForward =
            index > 0 && index < count - 1

        reorderPair =
            UI.Flip.reorderButtonPair UI.Flip.Horizontal
                { moveBackward = stopClick (Shared.AccountsPanelMsg (AccountsPanel.MoveServerLeftClicked server.frontendHost))
                , moveForward = stopClick (Shared.AccountsPanelMsg (AccountsPanel.MoveServerRightClicked server.frontendHost))
                , canMoveBackward = showBackward
                , canMoveForward = showForward
                }
    in
    div
        (id (AccountsPanel.serverChipDomId server.frontendHost)
            :: class "server-chip"
            :: moveAttrs
        )
        [ div topAttrs
            [ div [ class "server-chip-logo-row" ]
                [ div [ classList [ ( "reorder-arrow", True ), ( "reorder-arrow-hidden", not showBackward ) ] ] [ reorderPair.backward ]
                , AccountsPanel.serverNameAndLogo server AccountsPanel.RegularServerLogo
                , div [ classList [ ( "reorder-arrow", True ), ( "reorder-arrow-hidden", not showForward ) ] ] [ reorderPair.forward ]
                ]
            , div [ class "server-chip-host" ] [ text server.frontendHost ]

            -- , if isMainServer then
            --     div [ class "server-chip-main-badge" ] [ text "★ Main" ]
            --   else
            --     text ""
            ]
        , div [ classes [ "server-chip-bottom", hostnameToCSSClass server.frontendHost, "background-color-nav" ] ]
            [ switchInput server.enabled False (Shared.AccountsPanelMsg (AccountsPanel.ToggleServerEnabled server.frontendHost))
            , if server.frontendHost /= accountsPanelModel.browsingHost then
                a
                    [ class "external-link-btn"
                    , href ("https://" ++ server.frontendHost)
                    , target "_blank"
                    , title ("Open " ++ server.frontendHost ++ " in a new tab")
                    ]
                    [ text "↗" ]

              else
                text ""
            , button
                [ class "remove-btn"
                , onClick (Shared.RequestDelete (Shared.ConfirmServerDelete server))
                , disabled (not removable)
                , title
                    (if isMainServer then
                        "Can't remove the server you're currently browsing from"

                     else if hasAccounts then
                        "Can't remove a server with accounts on it"

                     else
                        "Remove server"
                    )
                ]
                [ text "╳" ]
            ]
        ]


logoOrPlaceholder : AccountsPanel.Branding -> Html msg
logoOrPlaceholder branding =
    imageOrInitial [ "server-chip-logo" ] branding.name branding.logoUrl


{-| An `img` if `maybeUrl` is present, otherwise a `div` showing the first
letter of `name`, upper-cased (via `AccountsPanel.initialLetter`) -- shared by
every avatar/logo that falls back to an initial when there's no image: account
avatars (`avatarOrPlaceholder`, `accountsMenuAvatar`) and server logos
(`logoOrPlaceholder`). `baseClasses` names the element itself (e.g.
"account-avatar"); the placeholder `div` additionally gets a "placeholder"
class alongside it.
-}
imageOrInitial : List String -> String -> Maybe String -> Html msg
imageOrInitial baseClasses name maybeUrl =
    case maybeUrl of
        Just url ->
            img [ classes baseClasses, src url, alt name ] []

        Nothing ->
            div [ classes ("placeholder" :: baseClasses) ] [ text (AccountsPanel.initialLetter name) ]


{-| Accounts are kept around even when their server currently has no `Server`
entry (down, moved, unreachable -- see `AccountsPanel.unreachableAccountHosts`),
so they wouldn't otherwise show up anywhere in `serversStrip`. Surfaced here as
a plain-text note of just their hosts, rather than a full chip, since there's
nothing (name/logo/theme) to render for a server we can't currently reach.
-}
unreachableServersWarning : Shared.Model -> Html msg
unreachableServersWarning shared =
    let
        hosts =
            AccountsPanel.unreachableAccountHosts shared.accountsPanel
    in
    if List.isEmpty hosts then
        text ""

    else
        div [ class "servers-unreachable-warning" ]
            [ text ("Couldn't reach: " ++ String.join ", " hosts) ]



-- ACCOUNTS


accountsList : Shared.Model -> Html Shared.Msg
accountsList shared =
    let
        accounts =
            shared.accountsPanel.accounts

        count =
            List.length accounts

        -- Accounts on the main server always sort to the front (see
        -- `AccountsPanel.sortMainServerAccountsFirst`), so they're exactly
        -- the leading `mainCount` accounts here -- `accountRow` uses this to
        -- hide any arrow that would cross that group boundary.
        mainCount =
            accounts
                |> List.filter (\a -> a.server == shared.accountsPanel.mainFrontendHost)
                |> List.length
    in
    if List.isEmpty accounts then
        div [ class "accounts-empty" ] [ text "No accounts yet." ]

    else
        Html.Keyed.node "div"
            [ classes [ "accounts-list", "flip-animated-column" ] ]
            (List.indexedMap
                (\index account -> ( AccountsPanel.accountId account, accountRowFlip shared count mainCount index account ))
                accounts
            )


{-| Wraps `accountRow` in a fading/scaling/collapsing animated outer `div`
(entering when freshly added, removing when deleted -- see
`AccountsPanel.accountAnimations`/`UI.Flip`), mirroring `Pages.Home_`'s
`postAnimationView`. The inner clip-layer `div` (same reasoning as there)
holds the FLIP-collapse's own `padding-bottom` spacing; `accountRow` itself --
with its _own_, independent reorder-slide `moveAttrs` -- lives one layer
further in, so the two animations (fade/collapse vs. reorder-slide) apply to
different elements and never fight over the same `transform`.
-}
accountRowFlip : Shared.Model -> Int -> Int -> Int -> AccountsPanel.Account -> Html Shared.Msg
accountRowFlip shared count mainCount index account =
    let
        flipState =
            Dict.get (AccountsPanel.accountId account) shared.accountsPanel.accountAnimations
                |> Maybe.withDefault UI.Flip.restingState

        isMoving =
            Dict.get (AccountsPanel.accountId account) shared.accountsPanel.moveAnimations
                |> Maybe.map .moving
                |> Maybe.withDefault False

        pointerEventsAttr =
            if flipState.removing then
                [ style "pointer-events" "none" ]

            else
                []
    in
    div (UI.Flip.itemAttributes UI.Flip.Vertical flipState isMoving)
        [ div pointerEventsAttr [ accountRow shared count mainCount index account ] ]


{-| The whole row is tinted with the account's server's `background-color-primary`
(background = `primaryColor`, text = `primaryTextColor`, inherited by the
username); the "host | server name" badge underneath it uses
`background-color-nav` instead, layered on top as a normal (not
absolutely-positioned) element now that the row isn't split into bands.

`moveAttrs` is an inline `transform` -- present only while this account is
mid-slide after `reorderButtons` moved it (see `UI.Flip.MoveState`,
`AccountsPanel.moveAnimations`), empty (identity) otherwise. The row's own DOM
`id` (`AccountsPanel.accountRowDomId`) is what lets `AccountsPanel.update`
measure its position before/after a reorder to drive that slide.

`mainCount` (see `accountsList`) is how many leading accounts belong to the
main server -- `canMoveUp`/`canMoveDown` use it to hide (see
`AccountsPanel.sortMainServerAccountsFirst`'s doc) whichever arrow would
otherwise move an account across the main/non-main boundary, rather than
just checking this account's own position against the list's two ends.

-}
accountRow : Shared.Model -> Int -> Int -> Int -> AccountsPanel.Account -> Html Shared.Msg
accountRow shared count mainCount index account =
    let
        accId =
            AccountsPanel.accountId account

        branding =
            AccountsPanel.brandingFor shared.accountsPanel.servers account.server

        moveAttrs =
            shared.accountsPanel.moveAnimations
                |> Dict.get accId
                |> Maybe.map UI.Flip.moveAttributes
                |> Maybe.withDefault []

        isMainServerAccount =
            account.server == shared.accountsPanel.mainFrontendHost

        canMoveUp =
            if isMainServerAccount then
                index > 0

            else
                index > mainCount

        canMoveDown =
            if isMainServerAccount then
                index < mainCount - 1

            else
                index < count - 1

        reorderPair =
            UI.Flip.reorderButtonPair UI.Flip.Vertical
                { moveBackward = onClick (Shared.AccountsPanelMsg (AccountsPanel.MoveAccountUpClicked accId))
                , moveForward = onClick (Shared.AccountsPanelMsg (AccountsPanel.MoveAccountDownClicked accId))
                , canMoveBackward = canMoveUp
                , canMoveForward = canMoveDown
                }
    in
    div
        (id (AccountsPanel.accountRowDomId accId)
            :: classes [ "account-row", hostnameToCSSClass account.server, "background-color-primary" ]
            :: moveAttrs
        )
        [ switchInput account.enabled account.needsPassword (Shared.AccountsPanelMsg (AccountsPanel.ToggleAccountEnabled accId))
        , a
            [ class "account-row-profile-link"
            , href (Users.profileHref shared.basePath shared.accountsPanel.mainFrontendHost account.server { userId = account.userId, username = account.username })
            ]
            [ avatarOrPlaceholder shared.accountsPanel.servers account
            , div [ class "account-row-label" ]
                [ div [ class "account-row-username" ]
                    [ text (AccountsPanel.displayName account)
                    , if AccountsPanel.isAdmin account then
                        span [ class "account-admin-badge", title "Admin on this server" ] [ text "🛡️" ]

                      else
                        text ""
                    ]
                , div [ classes [ "account-row-server-badge", account.server, "background-color-nav" ] ]
                    [ text (account.server ++ " | " ++ branding.name) ]
                , if account.needsPassword then
                    -- `preventDefaultOn`, not `onClick` -- this button sits inside the
                    -- profile-link `a` above, so a plain `onClick` here would still let
                    -- the anchor's own default action (navigating to the profile) fire
                    -- too, since it's a native browser default action tied to
                    -- `preventDefault`, not to `stopPropagation` (unlike `serverChip`'s
                    -- `stopClick`, whose enclosing "click target" is a plain `div`, with
                    -- no default action of its own to prevent).
                    button
                        [ type_ "button"
                        , class "account-needs-password"
                        , preventDefaultOn "click" (Decode.succeed ( Shared.AccountsPanelMsg (AccountsPanel.PasswordNeededClicked account), True ))
                        ]
                        [ text "password required" ]

                  else
                    text ""
                ]
            ]
        , div [ class "reorder-buttons" ]
            [ div [ classList [ ( "reorder-arrow", True ), ( "reorder-arrow-hidden", not canMoveUp ) ] ] [ reorderPair.backward ]
            , div [ classList [ ( "reorder-arrow", True ), ( "reorder-arrow-hidden", not canMoveDown ) ] ] [ reorderPair.forward ]
            ]
        , button
            [ class "remove-btn"
            , onClick (Shared.RequestDelete (Shared.ConfirmAccountDelete account))
            ]
            [ text "╳" ]
        ]


avatarOrPlaceholder : List AccountsPanel.Server -> AccountsPanel.Account -> Html msg
avatarOrPlaceholder servers account =
    imageOrInitial [ "account-avatar" ] account.username (AccountsPanel.accountAvatarUrl servers account)


{-| A checkbox styled as a toggle switch.
-}
switchInput : Bool -> Bool -> Shared.Msg -> Html Shared.Msg
switchInput isChecked isDisabled toggleMsg =
    label [ classList [ ( "switch", True ), ( "disabled", isDisabled ) ] ]
        [ input
            [ type_ "checkbox"
            , checked isChecked
            , disabled isDisabled
            , onClick toggleMsg
            ]
            []
        , span [ class "slider" ] []
        ]



-- LOGIN FORM


{-| The Server field is shared between logging in/creating an account and
adding a new server (see `AccountsPanel.AddServerClicked`): as soon as it names
a server we're not already connected to, Username/Password/Login/Create
Account are disabled and a full-width "Add Server" button appears right below
it instead. Once that succeeds (or the field already named a known server),
those re-enable, themed with _that_ server's colors rather than
`mainFrontendHost`'s -- see `AccountsPanel.GotNewServerResult` for the focus
handoff to Username that completes the "type a host, Enter, type a username,
Enter, type a password" flow.
-}
formView : Shared.Model -> Html Shared.Msg
formView shared =
    if AccountsPanel.shouldShowAddAccountForm shared.accountsPanel then
        addAccountForm shared

    else
        div [ class "account-form" ]
            [ button
                [ classes [ "show-add-account-form-button", hostnameToCSSClass <| formThemeHost shared.accountsPanel, "background-color-primary" ]
                , onClick (Shared.AccountsPanelMsg AccountsPanel.ShowAddAccountFormClicked)
                ]
                [ text "Add Account/Server..." ]
            ]


{-| The server whose theme the form's own controls (Login/Create Account,
and the collapsed "Add Account/Server..." button) should be tinted with: the
Server field's own host once it names a server we're connected to, falling
back to `mainFrontendHost` otherwise (e.g. the field is empty, still being
typed, or naming an unknown host -- see `AccountsPanel.AddServerClicked`).
-}
formThemeHost : AccountsPanel.Model -> String
formThemeHost accountsPanelModel =
    let
        form =
            accountsPanelModel.accountForm
    in
    if AccountsPanel.isKnownServer accountsPanelModel form.server then
        String.trim form.server

    else
        accountsPanelModel.mainFrontendHost


addAccountForm : Shared.Model -> Html Shared.Msg
addAccountForm shared =
    let
        accountsPanelModel =
            shared.accountsPanel

        form =
            accountsPanelModel.accountForm

        addForm =
            accountsPanelModel.addServerForm

        knownServer =
            AccountsPanel.isKnownServer accountsPanelModel form.server

        submitting =
            form.status == AccountsPanel.Submitting

        addingServer =
            addForm.status == AccountsPanel.Submitting

        accountFieldsDisabled =
            not knownServer || submitting

        themeHost =
            formThemeHost accountsPanelModel

        -- Username/password auth is only ever offered for our own main
        -- server, unless an admin has flipped
        -- `AdminPanel.allowUsernamePasswordForOtherHosts` -- see
        -- `AccountsPanel.isMainServer`.
        showUsernamePasswordFields =
            AccountsPanel.isMainServer accountsPanelModel form.server
                || shared.adminPanel.allowUsernamePasswordForOtherHosts

        serverEnterMsg =
            if not knownServer then
                AccountsPanel.AddServerClicked

            else if showUsernamePasswordFields then
                AccountsPanel.FocusInput "account-form-username"

            else
                AccountsPanel.NoOp
    in
    Html.form
        [ class "account-form"

        -- Real `<form>` (rather than `div`) so Safari/Chrome/password
        -- managers recognize `account-form-username`/`account-form-password`
        -- as a credential pair worth offering to fill/save. Every button
        -- below is explicitly `type_ "button"`, so this never natively
        -- submits (which would reload the page); `onSubmit` just guards
        -- against a stray implicit submission (e.g. Enter in a field) ever
        -- doing that, without duplicating any button's own `onClick`.
        , onSubmit (Shared.AccountsPanelMsg AccountsPanel.NoOp)
        ]
        [ input
            [ id "account-form-server"
            , type_ "url"
            , attribute "autocapitalize" "none"
            , attribute "autocorrect" "off"
            , spellcheck False
            , placeholder "Server"
            , value form.server
            , onInput (AccountsPanel.ServerChanged >> Shared.AccountsPanelMsg)
            , onEnter (Shared.AccountsPanelMsg serverEnterMsg)
            ]
            []
        , if knownServer then
            text ""

          else
            button
                [ type_ "button"
                , onClick (Shared.AccountsPanelMsg AccountsPanel.AddServerClicked)
                , disabled (addingServer || String.isEmpty (String.trim form.server))
                , classes [ "add-server-button", accountsPanelModel.mainFrontendHost, "background-color-nav" ]
                ]
                [ text
                    (if addingServer then
                        "Checking…"

                     else
                        "Add Server"
                    )
                ]
        , if showUsernamePasswordFields then
            div [ class "account-form-field" ]
                [ input
                    [ id "account-form-username"
                    , type_ "text"
                    , name "username"
                    , attribute "autocapitalize" "none"
                    , attribute "autocorrect" "off"
                    , attribute "autocomplete" "username"
                    , spellcheck False
                    , placeholder "Username"
                    , value form.username
                    , onInput (AccountsPanel.UsernameChanged >> Shared.AccountsPanelMsg)
                    , onEnter (Shared.AccountsPanelMsg (AccountsPanel.FocusInput "account-form-password"))
                    , disabled accountFieldsDisabled
                    ]
                    []
                , fieldClearButton accountFieldsDisabled
                    (not (String.isEmpty form.username))
                    (AccountsPanel.UsernameChanged "")
                    "Clear username"
                ]

          else
            text ""
        , if showUsernamePasswordFields then
            div [ class "account-form-field password-field" ]
                [ input
                    [ id "account-form-password"
                    , type_
                        (if form.passwordVisible then
                            "text"

                         else
                            "password"
                        )
                    , name "current-password"

                    -- "current-password" (not "new-password") even though this
                    -- field also doubles as Create Account's password: it's the
                    -- more common case (logging into an existing account), and
                    -- it's the token that lets a password manager offer to fill
                    -- a saved password here at all. "new-password" would only
                    -- gain a generated-password suggestion for the signup path,
                    -- at the cost of breaking autofill for the login path.
                    , attribute "autocomplete" "current-password"
                    , placeholder "Password"
                    , value form.password
                    , onInput (AccountsPanel.PasswordChanged >> Shared.AccountsPanelMsg)
                    , onEnter (Shared.AccountsPanelMsg AccountsPanel.LoginClicked)
                    , disabled accountFieldsDisabled
                    ]
                    []
                , if String.isEmpty form.password then
                    text ""

                  else
                    button
                        [ type_ "button"
                        , classList
                            [ ( "password-toggle-button", True )
                            , ( "revealed", form.passwordVisible )
                            ]
                        , onClick (Shared.AccountsPanelMsg AccountsPanel.PasswordVisibilityToggled)
                        , disabled accountFieldsDisabled
                        , title
                            (if form.passwordVisible then
                                "Hide password"

                             else
                                "Show password"
                            )
                        ]
                        [ text "👁" ]
                , fieldClearButton accountFieldsDisabled
                    (not (String.isEmpty form.password))
                    (AccountsPanel.PasswordChanged "")
                    "Clear password"
                ]

          else
            text ""
        , if showUsernamePasswordFields then
            div [ class "account-form-buttons" ]
                [ button
                    [ type_ "button"
                    , onClick (Shared.AccountsPanelMsg AccountsPanel.LoginClicked)
                    , disabled accountFieldsDisabled
                    , classes [ hostnameToCSSClass <| formThemeHost shared.accountsPanel, "background-color-primary" ]
                    ]
                    [ text "Login" ]
                , button
                    [ type_ "button"
                    , onClick (Shared.AccountsPanelMsg AccountsPanel.CreateAccountClicked)
                    , disabled accountFieldsDisabled
                    , classes [ hostnameToCSSClass <| formThemeHost shared.accountsPanel, "background-color-nav" ]
                    ]
                    [ text "Create Account" ]
                ]

          else
            text ""
        , signInFromButton shared accountFieldsDisabled
        , case ( form.status, addForm.status ) of
            ( AccountsPanel.Errored err, _ ) ->
                div [ class "auth-error" ] [ text err ]

            ( _, AccountsPanel.Errored err ) ->
                div [ class "auth-error" ] [ text err ]

            _ ->
                text ""
        ]


{-| A small circular "×" button overlaid on a field (see `addAccountForm`'s
username/password fields) that clears it in one click -- shown only once
there's something typed in to clear.
-}
fieldClearButton : Bool -> Bool -> AccountsPanel.Msg -> String -> Html Shared.Msg
fieldClearButton fieldDisabled visible clearMsg titleText =
    if visible then
        button
            [ type_ "button"
            , class "field-clear-button"
            , onClick (Shared.AccountsPanelMsg clearMsg)
            , disabled fieldDisabled
            , title titleText
            ]
            [ text "╳" ]

    else
        text ""


{-| Cross-server SSO hand-off (see `Shared.FederatedAuth`): lets someone who's
already signed into the Server field's host, elsewhere, sign in here without
retyping that host's password into this origin. Sends this origin's public
key (once generated -- near-instant after app load) to
`https://{form.server}/elm/auth/to/{publicKey}@{browsingHost}`, which is
`Pages.Auth.To.Key_` on that host -- a plain cross-origin `<a>` is enough,
`Main.elm`'s `onUrlRequest` already falls through to a full page load for it.

Only shown once the Server field names a host other than our own
(`AccountsPanel.isMainServer`) -- username/password auth (see
`addAccountForm`'s `showUsernamePasswordFields`) is the only way into our own
server, and this SSO hand-off is (ordinarily) the only way into anywhere
else. `AdminPanel.allowUsernamePasswordForOtherHosts` can additionally enable
username/password for other hosts too, but never suppresses this button for
`browsingHost`/`mainFrontendHost` themselves.

-}
signInFromButton : Shared.Model -> Bool -> Html Shared.Msg
signInFromButton shared accountFieldsDisabled =
    let
        accountsPanelModel =
            shared.accountsPanel

        server =
            String.trim accountsPanelModel.accountForm.server
    in
    case ( shared.federatedAuth.publicKey, not (String.isEmpty server) && not (AccountsPanel.isMainServer accountsPanelModel server) ) of
        ( Just publicKey, True ) ->
            button
                [ type_ "button"
                , onClick
                    (Shared.NavigateExternal
                        ("https://"
                            ++ server
                            ++ "/elm/auth/to/"
                            ++ FederatedAuth.publicKeyToUrlString publicKey
                            ++ "@"
                            ++ accountsPanelModel.browsingHost
                        )
                    )
                , disabled accountFieldsDisabled
                , classes [ "sign-in-from-button", hostnameToCSSClass <| formThemeHost accountsPanelModel, "background-color-primary" ]
                ]
                [ text ("Sign in from " ++ server ++ "…") ]

        _ ->
            text ""



-- CREATE ACCOUNT CONFIRMATION


{-| Covers the whole page (including the Accounts Panel) while the Create
Account confirmation step is up -- higher `z-index` than `sharedBackdrop`
since it can appear on top of the (already open) Accounts Panel. Always
rendered, like the other backdrops, so opening/closing is a CSS transition.
-}
createAccountConfirmationBackdrop : Shared.Model -> Html Shared.Msg
createAccountConfirmationBackdrop shared =
    UI.Modal.backdrop
        (shared.accountsPanel.createAccountConfirmation /= Nothing)
        (Shared.AccountsPanelMsg AccountsPanel.CancelCreateAccountClicked)


{-| The confirmation step shown after clicking "Create Account", before the
account is actually created: the target server's identity (the same
glyph+name as `homeLinkContent`, per the "home button style" this was asked
to reuse) plus its description/privacy policy/media policy from `ServerInfo`
-- fields the Elm frontend otherwise never surfaces, despite being meant for
exactly this per their proto doc comments -- so the user can see what
they're signing up for before confirming.

A centered dialog (unlike the edge-anchored Accounts/Starred Posts panels)
since it interrupts a specific action rather than being an ambient panel.
Always rendered (empty when closed) so the backdrop's fade isn't paired with
the dialog itself just popping in/out.

-}
createAccountConfirmationModal : Shared.Model -> Html Shared.Msg
createAccountConfirmationModal shared =
    case shared.accountsPanel.createAccountConfirmation of
        Nothing ->
            UI.Modal.view
                { class = "create-account-modal", isOpen = False, header = text "", bodyAttrs = [], body = [], buttons = [] }

        Just pending ->
            let
                info =
                    AccountsPanel.serverInfoOf pending.server

                submitting =
                    shared.accountsPanel.accountForm.status == AccountsPanel.Submitting
            in
            UI.Modal.view
                { class = "create-account-modal"
                , isOpen = True
                , header = AccountsPanel.serverNameAndLogo pending.server AccountsPanel.RegularServerLogo
                , bodyAttrs =
                    [ id AccountsPanel.createAccountModalBodyId
                    , on "scroll" (Decode.map (AccountsPanel.CreateAccountModalScrolled >> Shared.AccountsPanelMsg) scrolledToBottomDecoder)
                    ]
                , body =
                    [ policyMarkdown "" info.description
                    , policyMarkdown "Privacy Policy" info.privacyPolicy
                    , policyMarkdown "Media Policy" info.mediaPolicy
                    ]
                , buttons =
                    [ button
                        [ onClick (Shared.AccountsPanelMsg AccountsPanel.CancelCreateAccountClicked)
                        , disabled submitting
                        ]
                        [ text "Cancel" ]
                    , button
                        [ onClick (Shared.AccountsPanelMsg AccountsPanel.ConfirmCreateAccountClicked)
                        , disabled (submitting || not pending.reachedBottom)
                        , classes [ pending.server.frontendHost, "background-color-primary" ]
                        , title
                            (if pending.reachedBottom then
                                ""

                             else
                                "Please scroll down to read the rest first"
                            )
                        ]
                        [ text
                            (if submitting then
                                "Creating…"

                             else
                                "Create Account"
                            )
                        ]
                    ]
                }



-- DELETE CONFIRMATION


{-| Covers the whole page while a delete confirmation is up -- same reasoning
as `createAccountConfirmationBackdrop`, and the two never appear at once (both
only ever come from actions inside the Accounts Panel, which can only have one
such step in flight).
-}
deleteConfirmationBackdrop : Shared.Model -> Html Shared.Msg
deleteConfirmationBackdrop shared =
    UI.Modal.backdrop (shared.confirmingDeleteFor /= Nothing) Shared.CancelDelete


{-| The shared "are you sure you want to delete this?" dialog for every kind
of delete in the app (currently Accounts and Servers -- see
`Shared.DeleteConfirmation`) -- built on `UI.Modal` the same way
`createAccountConfirmationModal` is, so a future Post delete (etc.) needs only
a new `DeleteConfirmation` constructor and a case here, not a whole new dialog.
-}
deleteConfirmationModal : Shared.Model -> Html Shared.Msg
deleteConfirmationModal shared =
    case shared.confirmingDeleteFor of
        Nothing ->
            UI.Modal.view
                { class = "confirm-delete-modal", isOpen = False, header = text "", bodyAttrs = [], body = [], buttons = [] }

        Just confirmation ->
            let
                ( heading, message ) =
                    case confirmation of
                        Shared.ConfirmAccountDelete account ->
                            ( "Remove Account?"
                            , "Remove "
                                ++ AccountsPanel.displayName account
                                ++ " ("
                                ++ account.server
                                ++ ")? You'll need to log in again to use it."
                            )

                        Shared.ConfirmServerDelete server ->
                            ( "Remove Server?"
                            , "Remove " ++ server.frontendHost ++ " from your server list?"
                            )
            in
            UI.Modal.view
                { class = "confirm-delete-modal"
                , isOpen = True
                , header = text heading
                , bodyAttrs = []
                , body = [ p [ class "confirm-delete-message" ] [ text message ] ]
                , buttons =
                    [ button [ onClick Shared.CancelDelete ] [ text "Cancel" ]
                    , button [ onClick Shared.ConfirmDelete, class "confirm-delete-button" ] [ text "Delete" ]
                    ]
                }


{-| Reads a `scroll` event's target `scrollTop`/`clientHeight`/`scrollHeight`
to decide whether it's scrolled (near enough) to the bottom -- used to gate
the Create Account confirmation modal's submit button on the user having
actually scrolled through its policy text (see `createAccountConfirmationModal`).
A couple pixels of slack absorbs sub-pixel layout rounding some browsers
produce, which would otherwise leave the true bottom permanently
unreachable.
-}
scrolledToBottomDecoder : Decode.Decoder Bool
scrolledToBottomDecoder =
    Decode.map3 (\scrollTop clientHeight scrollHeight -> scrollTop + clientHeight >= scrollHeight - 2)
        (Decode.at [ "target", "scrollTop" ] Decode.float)
        (Decode.at [ "target", "clientHeight" ] Decode.float)
        (Decode.at [ "target", "scrollHeight" ] Decode.float)


{-| One optional block of server-supplied policy Markdown (rendered via
`Components.Markdown.view`, same as post content), omitted entirely when
blank (most servers won't set all of description/privacy policy/media
policy). An empty `heading` is used for the plain description, which gets no
heading of its own.
-}
policyMarkdown : String -> Maybe String -> Html msg
policyMarkdown heading maybeText =
    case Maybe.map String.trim maybeText of
        Just body ->
            if body == "" then
                text ""

            else
                div [ class "create-account-policy" ]
                    [ if heading == "" then
                        text ""

                      else
                        div [ class "create-account-policy-heading" ] [ text heading ]
                    , Markdown.view [ classes [ "post-detail-content", "create-account-policy-body" ] ] body
                    ]

        Nothing ->
            text ""



-- STARRED POSTS TOGGLE


{-| Only shown at all once at least one Post has been starred (see
`Shared.StarredPostsPanel.starKey`) -- only show the nav icon once there's
something behind it. Just the toggle button -- unlike `accountsMenu`, its
panel (`starredPostsPanel`) is rendered separately, as a direct child of
`.navbar` itself rather than of this button's own `.admin-menu` wrapper, so it
can hug the actual screen edge (see `.starred-posts-panel` in starred\_posts\_panel.css).
Uses `stopPropagationOn`, not plain `onClick`, so tapping it doesn't also
trigger `headerNav`'s own tap-anywhere `Shared.ScrollToTop`.
-}
starredPostsToggle : Shared.Model -> Html Shared.Msg
starredPostsToggle shared =
    div [ class "admin-menu" ]
        [ button
            [ classes [ "nav-menu-toggle", "circular", openClosedClass shared.starredPostsPanel.showStarredPostsPanel ]
            , stopPropagationOn "click" (Decode.succeed ( Shared.StarredPostsPanelMsg StarredPostsPanel.ToggleStarredPostsPanel, True ))
            , title "Starred Posts"
            ]
            [ text "⭐"
            , span
                [ classes
                    [ "starred-posts-count-badge"
                    , hostnameToCSSClass shared.accountsPanel.mainFrontendHost
                    , "background-color-nav"
                    ]
                ]
                [ text (String.fromInt (Set.size shared.starredPostsPanel.starredPostIds)) ]
            ]
        ]


{-| The Starred Posts panel's content -- see `starredPostsToggle` for why this
is separate from (and rendered outside) the toggle button. Its own content is
`StarredPostsPanel.view` -- it returns `Html StarredPostsPanel.Msg` rather
than `Html Shared.Msg` (unlike the rest of this module's panels), since
`Shared.StarredPostsPanel` can't itself import `Shared` (that'd be a cycle --
`Shared` already imports it for `Shared.Model`'s `starredPostsPanel` field),
so it's mapped into `Shared.Msg` here instead.
-}
starredPostsPanel : Shared.Model -> Route -> Html Shared.Msg
starredPostsPanel shared currentRoute =
    Html.map Shared.StarredPostsPanelMsg
        (StarredPostsPanel.view shared.browserTimeZone shared.basePath shared.accountsPanel (currentStarredPostKey shared currentRoute) shared.starredPostsPanel)


{-| The `starKey` of the Post currently being viewed (see
`Pages.Post.PostId_`), if `currentRoute` is that page -- lets
`Shared.StarredPostsPanel.view` highlight the matching entry, if any, with
its server's colors. `params.postId` is either a bare id (a post on
`mainFrontendHost`) or `id@host` -- see `Components.Posts.parsePostRouteId`.
-}
currentStarredPostKey : Shared.Model -> Route -> Maybe String
currentStarredPostKey shared currentRoute =
    case currentRoute of
        Route.Post__PostId_ params ->
            let
                ( postId, host ) =
                    Posts.parsePostRouteId shared.accountsPanel.mainFrontendHost params.postId
            in
            Just (StarredPostsPanel.rawKey postId host)

        _ ->
            Nothing


{-| A collapsible panel, one per admin-capable signed-in account, for setting
which frontend (Flutter/React/Elm) that account's server serves at its root
(`ServerInfo.webUserInterface`, via `AccountsPanel.SetWebUserInterfaceClicked`).
Shows that account's username/avatar/server so it's clear which admin
identity a change would be made as, since the RPC is authenticated per-account
rather than "whichever account is currently active".
-}
adminAccountPanel : Shared.Model -> AccountsPanel.Account -> Html Shared.Msg
adminAccountPanel shared account =
    let
        id =
            AccountsPanel.accountId account

        isOpen =
            AdminPanel.isAccountPanelOpen id shared.adminPanel

        currentUi =
            findServer shared account.server
                |> Maybe.andThen (\s -> s.configuration.serverInfo)
                |> Maybe.andThen .webUserInterface
                |> Maybe.withDefault REACTTAMAGUI
    in
    div [ class "admin-account-panel" ]
        [ button
            [ class "admin-account-toggle"
            , onClick (Shared.AdminPanelMsg (AdminPanel.ToggleAccountPanel id))
            ]
            [ avatarOrPlaceholder shared.accountsPanel.servers account
            , span [ class "admin-account-username" ] [ text (AccountsPanel.displayName account) ]
            , span [ class "admin-account-server" ] [ text account.server ]
            , span
                [ classes
                    ("admin-account-chevron"
                        :: (if isOpen then
                                [ "open" ]

                            else
                                []
                           )
                    )
                ]
                [ text "▾" ]
            ]
        , if isOpen then
            webUiToggleRow id account.server currentUi

          else
            text ""
        ]


{-| The app-wide Markdown editor (see `Shared.MarkdownPanel`) -- unlike the
Accounts/Starred Posts panels, it isn't toggled from a nav icon of its own;
it's opened contextually (e.g. `Pages.Post.PostId_`'s Edit/Reply buttons) via
`Shared.MarkdownPanelMsg (MarkdownPanel.Open ...)`, so it's mounted directly in
`layout` rather than inside `headerNav`. Given the lowest z-index of the
panels mounted here (see `markdown_panel.css`) -- if a post's Edit button is
used while the Accounts/Starred Posts panel, or the Media Viewer panel, also
happens to be open, those still layer above it rather than being hidden
behind it.
-}
markdownPanel : Shared.Model -> Html Shared.Msg
markdownPanel shared =
    Html.map Shared.MarkdownPanelMsg (MarkdownPanel.view shared.accountsPanel shared.markdownPanel)


{-| The breadcrumb trail (see `Shared.Breadcrumbs`) at the bottom of `.navbar`
-- unlike the Starred Posts toggle/panel, there's no nav icon of its own;
whichever page has a chain to show (currently just `Pages.Post.PostId_`) sets
it directly via `Shared.BreadcrumbsMsg (Breadcrumbs.SetRoot ...)`, so this just
renders whatever's currently there (empty if nothing is).
-}
breadcrumbsBar : Shared.Model -> Html Shared.Msg
breadcrumbsBar shared =
    Html.map Shared.BreadcrumbsMsg (Breadcrumbs.bar shared.accountsPanel shared.breadcrumbs)


{-| The popup opened by tapping a breadcrumb segment (see
`Shared.Breadcrumbs.replyPanel`), anchored just under `breadcrumbsBar`'s own
row -- mounted as a `.navbar` descendant (see `headerNav`), not directly in
`layout` like `markdownPanel` above, so its positioning (`position: absolute`,
see nav.css) resolves against `.navbar` itself.
-}
breadcrumbsReplyPanel : Shared.Model -> Html Shared.Msg
breadcrumbsReplyPanel shared =
    Html.map Shared.BreadcrumbsMsg (Breadcrumbs.replyPanel shared.basePath shared.accountsPanel shared.breadcrumbs)


{-| The app-wide fullscreen image/video viewer (see `Shared.MediaViewerPanel`)
-- opened contextually, same as `markdownPanel` above, by tapping a Post's
media (`Components.PostCard`'s `onMediaClicked`), not from a nav icon, so it's
mounted directly in `layout` too. Sits above both the Markdown panel and the
Accounts/Starred Posts panels (see `media_viewer_panel.css`'s z-index) -- a
fullscreen image reasonably wins over a stale editor left open behind it, and
stays on top even if the nav's own dropdowns are then opened over it.
-}
mediaViewerPanel : Shared.Model -> Html Shared.Msg
mediaViewerPanel shared =
    Html.map Shared.MediaViewerPanelMsg (MediaViewerPanel.view shared.accountsPanel shared.mediaViewerPanel)


{-| Flutter is included for parity with the other two, but permanently
disabled -- see `WebUserInterface`'s doc comment: it's badly behind React/Elm
and not meant to be chosen going forward.
-}
webUiToggleRow : String -> String -> WebUserInterface -> Html Shared.Msg
webUiToggleRow id serverHost currentUi =
    div [ class "web-ui-toggle-row" ]
        [ webUiButton "Flutter" True (currentUi == FLUTTERWEB) serverHost (AccountsPanel.SetWebUserInterfaceClicked id FLUTTERWEB)
        , webUiButton "React" False (currentUi == REACTTAMAGUI) serverHost (AccountsPanel.SetWebUserInterfaceClicked id REACTTAMAGUI)
        , webUiButton "Elm" False (currentUi == ELMSPA) serverHost (AccountsPanel.SetWebUserInterfaceClicked id ELMSPA)
        ]


{-| When selected, tinted with `serverHost`'s own `background-color-primary`
(see `UI.EmittedStylesheet`) -- this button is per-account, so it should
reflect that account's server, not `mainFrontendHost`.
-}
webUiButton : String -> Bool -> Bool -> String -> AccountsPanel.Msg -> Html Shared.Msg
webUiButton label_ isDisabled isSelected serverHost msg =
    button
        [ classes
            ("web-ui-button"
                :: (if isSelected then
                        [ serverHost, "background-color-primary" ]

                    else
                        []
                   )
            )
        , disabled isDisabled
        , onClick (Shared.AccountsPanelMsg msg)
        ]
        [ text label_ ]
