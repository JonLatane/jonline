module UI exposing (layout, page)

import Components.Markdown as Markdown
import Components.Posts as Posts
import Effect exposing (Effect)
import Gen.Route as Route exposing (Route(..))
import Html exposing (Attribute, Html, a, button, div, header, img, input, label, main_, nav, span, text)
import Html.Attributes exposing (alt, attribute, checked, class, disabled, href, id, placeholder, spellcheck, src, title, type_, value)
import Html.Events exposing (on, onClick, onInput, preventDefaultOn)
import Json.Decode as Decode
import Page
import Proto.Jonline.WebUserInterface exposing (WebUserInterface(..))
import Request
import Set
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.AdminPanel as AdminPanel
import Shared.StarredPostsPanel as StarredPostsPanel
import UI.Classes exposing (classes, openClosedClass)
import UI.EmittedStylesheet
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
    [ Html.map toMsg (UI.EmittedStylesheet.view shared)
    , Html.map toMsg (sharedBackdrop shared)
    , Html.map toMsg (headerNav shared currentRoute)
    , Html.map toMsg (createAccountConfirmationBackdrop shared)
    , Html.map toMsg (createAccountConfirmationModal shared)
    , div [ class "container" ] [ main_ [] children ]
    ]


headerNav : Shared.Model -> Route -> Html Shared.Msg
headerNav shared currentRoute =
    header [ classes [ "navbar", shared.accountsPanel.mainFrontendHost, "background-color-primary" ] ]
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
        -- `left: 0` in style.css hugs the actual screen edge instead of just
        -- the toggle's left edge. See `starredPostsPanel`.
        , if Set.isEmpty shared.starredPostsPanel.starredPostIds then
            text ""

          else
            starredPostsPanel shared currentRoute
        ]


{-| One entry in `sharedBackdrop`'s priority list: whether this panel is
currently open, the message that closes just this panel, and whether its
being open should blur/tint the shared backdrop (only the Accounts Panel
blocks interaction with the rest of the page like that -- see
`sharedBackdrop`).
-}
type alias BackdropPanel =
    { isOpen : Bool
    , closeMsg : Shared.Msg
    , blurs : Bool
    }


{-| Covers everything except the top nav (which sits in its own, higher
stacking context -- see `.navbar` in style.css) for every panel that closes
via a background tap -- currently the Starred Posts panel and the Accounts
Panel, with more expected to join this list later. Always rendered, like the
panels themselves, so opening/closing (and the blur) is a plain CSS
transition rather than the element appearing/disappearing outright, and only
receives clicks (`pointer-events`) while at least one listed panel is open.

Listed nearest-first: when several panels are open at once, a background tap
closes only the first one in this list (see `topmostOpenPanel`) -- one tap per
panel to peel them off in order, front-to-back, rather than closing everything
at once. Right now that means tapping the background closes the Starred Posts
panel first, then (on a second tap) the Accounts Panel behind it -- swap their
order here to change that priority. Only blurs/tints the page while a panel
with `blurs = True` is open (currently just the Accounts Panel, which blocks
interaction with the rest of the page while its login/server-management forms
are open); the Starred Posts panel doesn't, since starring/unstarring posts
while it's open is an expected, encouraged interaction rather than something
to block.
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


{-| A full-viewport-covering `div`, always rendered (even "closed") so opening/
closing can be a plain CSS transition rather than the element itself
appearing/disappearing outright -- used by `createAccountConfirmationBackdrop`
(`sharedBackdrop` needs its own click-priority logic, so it builds its `div`
directly rather than going through this).
-}
overlayBackdrop : String -> Bool -> Shared.Msg -> Html Shared.Msg
overlayBackdrop backdropClass isOpen closeMsg =
    div
        [ classes [ backdropClass, openClosedClass isOpen ]
        , onClick closeMsg
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
class (regardless of `isCurrent`) so `style.css` can give its bigger,
stacked `RegularServerLogo` content (see `homeLinkContent`) the same
negative-margin overflow treatment as the Accounts Panel toggle.
-}
navLink : Shared.Model -> Route -> Html msg -> Route -> Html msg
navLink shared currentRoute content linkRoute =
    let
        isCurrent =
            linkRoute == currentRoute
    in
    a
        [ href (shared.basePath ++ Route.toHref linkRoute)
        , classes
            ("nav-link"
                :: (if linkRoute == Route.Home_ then
                        [ "nav-link-home" ]

                    else
                        []
                   )
                ++ (if isCurrent then
                        [ shared.accountsPanel.mainFrontendHost, "background-color-nav" ]

                    else
                        []
                   )
            )
        ]
        [ content ]


{-| The Home link's content is normally the browsing server's own
logo/name (via `AccountsPanel.serverNameAndLogo`), same `RegularServerLogo`
(stacked glyph-above-multi-line-name) style as the server chips in the
Accounts Panel -- just bigger, per `.nav-link-home` in `style.css` -- falling
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

        toggleClasses =
            "accounts-menu-toggle"
                :: (if List.isEmpty enabledAccounts then
                        []

                    else
                        [ "has-avatars" ]
                   )
                ++ (if List.length (AccountsPanel.enabledServers shared.accountsPanel) == 1 then
                        []

                    else
                        [ "has-summary" ]
                   )
    in
    div [ class "accounts-menu" ]
        [ div [ class "accounts-menu-row" ]
            [ button
                [ classes toggleClasses
                , onClick (Shared.AccountsPanelMsg AccountsPanel.ToggleAccountsPanel)
                ]
                [ accountsMenuButtonContent shared enabledAccounts
                , accountsMenuServerSummary shared.accountsPanel
                ]
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
common single-server case, "N servers" for any other count, or "No servers ⚠️"
when every server's been disabled. If any account's server is currently
unreachable (see `AccountsPanel.unreachableAccountHosts`, surfaced below as
"Couldn't reach: ..."), the count is always shown -- even "1 server" -- with
its own ⚠️, so that warning isn't silently hidden behind the usual
single-server blank state. Recomputed on every render (so it updates live as
servers are toggled/reconnected) directly off `AccountsPanel.enabledServers`
and `AccountsPanel.unreachableAccountHosts`.
-}
accountsMenuServerSummary : AccountsPanel.Model -> Html Shared.Msg
accountsMenuServerSummary accountsPanelModel =
    let
        count =
            List.length (AccountsPanel.enabledServers accountsPanelModel)

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
    case count of
        0 ->
            div [ class "accounts-menu-server-summary" ] [ text "No servers ⚠️" ]

        1 ->
            if hasUnreachableServers then
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
                        [ account.server, "border-color-primary" ]

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
outright -- see `.accounts-panel`/`.accounts-panel.is-closed` in style.css.

-}
accountsPanel : Shared.Model -> Html Shared.Msg
accountsPanel shared =
    let
        accountsPanelModel =
            shared.accountsPanel
    in
    div [ classes [ "accounts-panel", openClosedClass accountsPanelModel.showAccountsPanel ] ]
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


{-| How many Settings the Settings tab currently holds -- just the "switch
main server by tapping servers" toggle (admin-only) for now, but tracked as a
count rather than a bare `Bool` so the tab can grow more (non-admin-gated)
settings later without changing how its visibility is decided.
-}
settingsCount : Shared.Model -> Int
settingsCount shared =
    if AccountsPanel.hasAdminAccount shared.accountsPanel then
        1

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


{-| Just the "switch main server by tapping servers" toggle (see `serverChip`)
for now -- only shown (via `settingsCount`) while an admin account is signed
in.
-}
settingsTab : Shared.Model -> Html Shared.Msg
settingsTab shared =
    div [ class "accounts-panel-tab-content" ]
        [ label [ class "admin-switch-row" ]
            [ switchInput shared.adminPanel.allowMainServerSwitch (Shared.AdminPanelMsg AdminPanel.ToggleAllowMainServerSwitch)
            , span [] [ text "Switch main server by tapping servers" ]
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
    div [ class "servers-strip" ]
        (List.map (serverChip shared) shared.accountsPanel.servers)


{-| Top portion (logo/name/host) gets that server's `background-color-primary`
utility classes (see `UI.EmittedStylesheet`); the enable switch and delete
button sit in a bottom portion using `background-color-nav` instead.

The top portion is always clickable: tapping it fills the Account form's
Server field with this server's `frontendHost` (`ServerChipClicked`), so
switching which known server you're logging into/adding an account on is a
single tap. When the Server Admin Panel's "switch main server" toggle is also
on (see `Shared.AdminPanel`), that tap additionally sets this server as
`mainFrontendHost` (`MainServerSelected`, which fills the Server field too --
see its handler in `Shared.AccountsPanel`) instead of just filling the field.

-}
serverChip : Shared.Model -> AccountsPanel.Server -> Html Shared.Msg
serverChip shared server =
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
            [ "server-chip-top", "selectable", server.frontendHost, "background-color-primary" ]

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
    in
    div [ class "server-chip" ]
        [ div topAttrs
            [ AccountsPanel.serverNameAndLogo server AccountsPanel.RegularServerLogo
            , div [ class "server-chip-host" ] [ text server.frontendHost ]
            , if isMainServer then
                div [ class "server-chip-main-badge" ] [ text "★ Main" ]

              else
                text ""
            ]
        , div [ classes [ "server-chip-bottom", server.frontendHost, "background-color-nav" ] ]
            [ switchInput server.enabled (Shared.AccountsPanelMsg (AccountsPanel.ToggleServerEnabled server.frontendHost))
            , button
                [ class "remove-btn"
                , onClick (Shared.AccountsPanelMsg (AccountsPanel.RemoveServerClicked server.frontendHost))
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
                [ text "×" ]
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
    if List.isEmpty shared.accountsPanel.accounts then
        div [ class "accounts-empty" ] [ text "No accounts yet." ]

    else
        div [ class "accounts-list" ] (List.map (accountRow shared) shared.accountsPanel.accounts)


{-| The whole row is tinted with the account's server's `background-color-primary`
(background = `primaryColor`, text = `primaryTextColor`, inherited by the
username); the "host | server name" badge underneath it uses
`background-color-nav` instead, layered on top as a normal (not
absolutely-positioned) element now that the row isn't split into bands.
-}
accountRow : Shared.Model -> AccountsPanel.Account -> Html Shared.Msg
accountRow shared account =
    let
        id =
            AccountsPanel.accountId account

        branding =
            AccountsPanel.brandingFor shared.accountsPanel.servers account.server
    in
    div [ classes [ "account-row", account.server, "background-color-primary" ] ]
        [ switchInput account.enabled (Shared.AccountsPanelMsg (AccountsPanel.ToggleAccountEnabled id))
        , avatarOrPlaceholder shared.accountsPanel.servers account
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
            ]
        , button
            [ class "remove-btn"
            , onClick (Shared.AccountsPanelMsg (AccountsPanel.RemoveAccountClicked id))
            ]
            [ text "×" ]
        ]


avatarOrPlaceholder : List AccountsPanel.Server -> AccountsPanel.Account -> Html msg
avatarOrPlaceholder servers account =
    imageOrInitial [ "account-avatar" ] account.username (AccountsPanel.accountAvatarUrl servers account)


{-| A checkbox styled as a toggle switch.
-}
switchInput : Bool -> Shared.Msg -> Html Shared.Msg
switchInput isChecked toggleMsg =
    label [ class "switch" ]
        [ input
            [ type_ "checkbox"
            , checked isChecked
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
            if knownServer then
                String.trim form.server

            else
                accountsPanelModel.mainFrontendHost

        serverEnterMsg =
            if knownServer then
                AccountsPanel.FocusInput "account-form-username"

            else
                AccountsPanel.AddServerClicked
    in
    div [ class "account-form" ]
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
                [ onClick (Shared.AccountsPanelMsg AccountsPanel.AddServerClicked)
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
        , input
            [ id "account-form-username"
            , type_ "text"
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
        , input
            [ id "account-form-password"
            , type_ "password"
            , placeholder "Password"
            , value form.password
            , onInput (AccountsPanel.PasswordChanged >> Shared.AccountsPanelMsg)
            , onEnter (Shared.AccountsPanelMsg AccountsPanel.LoginClicked)
            , disabled accountFieldsDisabled
            ]
            []
        , div [ class "account-form-buttons" ]
            [ button
                [ onClick (Shared.AccountsPanelMsg AccountsPanel.LoginClicked)
                , disabled accountFieldsDisabled
                , classes [ themeHost, "background-color-primary" ]
                ]
                [ text "Login" ]
            , button
                [ onClick (Shared.AccountsPanelMsg AccountsPanel.CreateAccountClicked)
                , disabled accountFieldsDisabled
                , classes [ themeHost, "background-color-nav" ]
                ]
                [ text "Create Account" ]
            ]
        , case ( form.status, addForm.status ) of
            ( AccountsPanel.Errored err, _ ) ->
                div [ class "auth-error" ] [ text err ]

            ( _, AccountsPanel.Errored err ) ->
                div [ class "auth-error" ] [ text err ]

            _ ->
                text ""
        ]



-- CREATE ACCOUNT CONFIRMATION


{-| Covers the whole page (including the Accounts Panel) while the Create
Account confirmation step is up -- higher `z-index` than `sharedBackdrop`
since it can appear on top of the (already open) Accounts Panel. Always
rendered, like the other backdrops, so opening/closing is a CSS transition.
-}
createAccountConfirmationBackdrop : Shared.Model -> Html Shared.Msg
createAccountConfirmationBackdrop shared =
    overlayBackdrop "create-account-backdrop"
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
            div [ classes [ "create-account-modal", "is-closed" ] ] []

        Just pending ->
            let
                info =
                    AccountsPanel.serverInfoOf pending.server

                submitting =
                    shared.accountsPanel.accountForm.status == AccountsPanel.Submitting
            in
            div [ classes [ "create-account-modal", "is-open" ] ]
                [ div [ class "create-account-modal-header" ]
                    [ AccountsPanel.serverNameAndLogo pending.server AccountsPanel.RegularServerLogo ]
                , div
                    [ class "create-account-modal-body"
                    , id AccountsPanel.createAccountModalBodyId
                    , on "scroll" (Decode.map (AccountsPanel.CreateAccountModalScrolled >> Shared.AccountsPanelMsg) scrolledToBottomDecoder)
                    ]
                    [ policyMarkdown "" info.description
                    , policyMarkdown "Privacy Policy" info.privacyPolicy
                    , policyMarkdown "Media Policy" info.mediaPolicy
                    ]
                , div [ class "create-account-modal-buttons" ]
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
                ]


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
can hug the actual screen edge (see `.starred-posts-panel` in style.css).
-}
starredPostsToggle : Shared.Model -> Html Shared.Msg
starredPostsToggle shared =
    div [ class "admin-menu" ]
        [ button
            [ classes [ "accounts-menu-toggle", "circular" ]
            , onClick (Shared.StarredPostsPanelMsg StarredPostsPanel.ToggleStarredPostsPanel)
            , title "Starred Posts"
            ]
            [ text "⭐"
            , span
                [ classes
                    [ "starred-posts-count-badge"
                    , shared.accountsPanel.mainFrontendHost
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
        (StarredPostsPanel.view shared.basePath shared.accountsPanel (currentStarredPostKey shared currentRoute) shared.starredPostsPanel)


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
            webUiToggleRow id currentUi

          else
            text ""
        ]


{-| Flutter is included for parity with the other two, but permanently
disabled -- see `WebUserInterface`'s doc comment: it's badly behind React/Elm
and not meant to be chosen going forward.
-}
webUiToggleRow : String -> WebUserInterface -> Html Shared.Msg
webUiToggleRow id currentUi =
    div [ class "web-ui-toggle-row" ]
        [ webUiButton "Flutter" True (currentUi == FLUTTERWEB) (AccountsPanel.SetWebUserInterfaceClicked id FLUTTERWEB)
        , webUiButton "React" False (currentUi == REACTTAMAGUI) (AccountsPanel.SetWebUserInterfaceClicked id REACTTAMAGUI)
        , webUiButton "Elm" False (currentUi == ELMSPA) (AccountsPanel.SetWebUserInterfaceClicked id ELMSPA)
        ]


webUiButton : String -> Bool -> Bool -> AccountsPanel.Msg -> Html Shared.Msg
webUiButton label_ isDisabled isSelected msg =
    button
        [ classes
            ("web-ui-button"
                :: (if isSelected then
                        [ "selected" ]

                    else
                        []
                   )
            )
        , disabled isDisabled
        , onClick (Shared.AccountsPanelMsg msg)
        ]
        [ text label_ ]
