module UI.CustomNav exposing
    ( CustomTab
    , CustomTabIcon(..)
    , CustomTabTarget(..)
    , TargetKind(..)
    , defaultPathFor
    , effectiveTabs
    , iconView
    , navLinkView
    , resolvedTitle
    , selectableTargetKinds
    , targetKind
    , targetKindFromText
    , targetKindText
    , toProtoTab
    )

{-| Elm-land counterparts of `CustomNavigationTab`'s two `oneof`s (`target`/`icon`, see
`protos/server_configuration.proto`), plus the rendering/routing logic shared by the real top nav
(`UI.headerNav`, once `Shared.AccountsPanel.Model.mainFrontendHost`'s `ServerConfiguration` has a
`customTabs` set) and `Components.Pages.ServerInformationPage.SettingsTab`'s preview/editor of that
same `CustomNavigationTabSet`.

`CustomTabTarget`/`CustomTabIcon` exist because the generated `oneof` types
(`Proto.Jonline.CustomNavigationTab.Target.Target`/`...Icon.Icon`) are generic in both branches'
payload type (`Target a0 a1`/`Icon a0 a1`) -- fine for the wire format, but awkward to pattern-match
on directly everywhere this is used. `fromProtoTab`/`toProtoTab` round-trip a `CustomNavigationTab`
to/from this module's own `CustomTab`, `Nothing` only for a malformed proto value (`target`/`icon`
unset -- shouldn't happen for anything this app itself ever saves, but is possible for a
hand-edited/future-versioned config).
-}

import Gen.Route as Route exposing (Route)
import Html exposing (Html, a, img, span, text)
import Html.Attributes exposing (alt, attribute, href, src, title)
import Proto.Jonline exposing (CustomNavigationTab, CustomNavigationTabSet)
import Proto.Jonline.CustomNavigationTab.Icon as ProtoIcon
import Proto.Jonline.CustomNavigationTab.Target as ProtoTarget
import Proto.Jonline.NavigationTab exposing (NavigationTab(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import UI.Classes exposing (classes, hostnameToCSSClass)


{-| Elm-land mirror of `CustomNavigationTab`'s `target` `oneof` -- one of the app's own predefined
tabs (`NavigationTab`), a specific Post (e.g. a custom business site's page), or a user profile
(`TargetProfile`, from the proto's `is_profile` branch) -- unlike the other two, that branch carries
no payload of its own on the wire (just `bool`), so which profile is entirely determined by the
enclosing `CustomNavigationTabWithPath.path` (see `CustomTab.path`'s own doc) -- the tab's url *is*
that username's own `/:username` route, just also featured as a styled nav tab.
-}
type CustomTabTarget
    = TargetTab NavigationTab
    | TargetPost String
    | TargetProfile


{-| Elm-land mirror of `CustomNavigationTab`'s `icon` `oneof` -- an emoji glyph, or a `Media` id
(rendered via `AccountsPanel.mediaUrl`, see `iconView`).
-}
type CustomTabIcon
    = EmojiIcon String
    | MediaIcon String


{-| Elm-land mirror of `CustomNavigationTab` itself, plus its enclosing `CustomNavigationTabWithPath`'s
own `path` -- `target`/`icon` are always present (unlike the proto's own `Maybe`-wrapped `oneof`s),
since `fromProtoTab` already filters out anything missing either. `title` stays `Maybe String`, same
meaning as the proto's own field ("defaults to the predefined tab's/Post's title if unset" -- see
`resolvedTitle`). `path` is admin-editable (see `SettingsTab.customTabEditChip`'s own Path
`<input>`) but not yet wired into actual routing (see `routeFor`'s own doc) -- it's carried here
purely so the editor can show/edit the real saved value instead of re-deriving a stand-in every time.
-}
type alias CustomTab =
    { target : CustomTabTarget
    , icon : CustomTabIcon
    , title : Maybe String
    , path : String
    }


fromProtoTarget : ProtoTarget.Target NavigationTab String Bool -> CustomTabTarget
fromProtoTarget target =
    case target of
        ProtoTarget.Tab navTab ->
            TargetTab navTab

        ProtoTarget.PostId postId ->
            TargetPost postId

        -- The payload itself is ignored -- selecting this `oneof` branch at all is what means
        -- "this is a profile tab" (see `CustomTabTarget`'s own doc); there's no reason this
        -- would ever actually be saved as `false`.
        ProtoTarget.IsProfile _ ->
            TargetProfile


toProtoTarget : CustomTabTarget -> ProtoTarget.Target NavigationTab String Bool
toProtoTarget target =
    case target of
        TargetTab navTab ->
            ProtoTarget.Tab navTab

        TargetPost postId ->
            ProtoTarget.PostId postId

        TargetProfile ->
            ProtoTarget.IsProfile True


fromProtoIcon : ProtoIcon.Icon String String -> CustomTabIcon
fromProtoIcon icon =
    case icon of
        ProtoIcon.EmojiIcon emoji ->
            EmojiIcon emoji

        ProtoIcon.IconMediaId mediaId ->
            MediaIcon mediaId


toProtoIcon : CustomTabIcon -> ProtoIcon.Icon String String
toProtoIcon icon =
    case icon of
        EmojiIcon emoji ->
            ProtoIcon.EmojiIcon emoji

        MediaIcon mediaId ->
            ProtoIcon.IconMediaId mediaId


fromProtoTab : String -> CustomNavigationTab -> Maybe CustomTab
fromProtoTab path proto =
    Maybe.map2
        (\target icon -> { target = fromProtoTarget target, icon = fromProtoIcon icon, title = proto.title, path = path })
        proto.target
        proto.icon


toProtoTab : CustomTab -> CustomNavigationTab
toProtoTab tab =
    { target = Just (toProtoTarget tab.target)
    , icon = Just (toProtoIcon tab.icon)
    , title = tab.title
    }


{-| The four tabs Jonline shows today (`Events`/`Posts`/`People`/`About`, see `UI.eventsLink`/etc.)
recast as `CustomTab`s -- both `effectiveTabs`' fallback for an unset `CustomNavigationTabSet.tabs`,
and `SettingsTab`'s starting point for a freshly-opened editor. Each one's `path` is just
`defaultPathFor`'s own slug for its `target` -- see that function's own doc.
-}
defaultTabs : List CustomTab
defaultTabs =
    [ { target = TargetTab EVENTSTAB, icon = EmojiIcon "📅", title = Nothing, path = defaultPathFor (TargetTab EVENTSTAB) }
    , { target = TargetTab POSTSTAB, icon = EmojiIcon "📝", title = Nothing, path = defaultPathFor (TargetTab POSTSTAB) }
    , { target = TargetTab PEOPLETAB, icon = EmojiIcon "👥", title = Nothing, path = defaultPathFor (TargetTab PEOPLETAB) }
    , { target = TargetTab ABOUTTAB, icon = EmojiIcon "i", title = Nothing, path = defaultPathFor (TargetTab ABOUTTAB) }
    ]


{-| A `ServerConfiguration.customTabs`' `tabs` list, or `defaultTabs` if `customTabs` itself is
unset entirely -- an explicitly-saved empty `tabs` list (an admin who's deliberately removed every
tab) is respected as "no tabs," not coerced back to the defaults. Malformed entries (`customTab`
unset, or its own `target`/`icon` unset -- see `fromProtoTab`) are silently skipped.
-}
effectiveTabs : Maybe CustomNavigationTabSet -> List CustomTab
effectiveTabs maybeSet =
    case maybeSet of
        Nothing ->
            defaultTabs

        Just set ->
            set.tabs |> List.filterMap (\entry -> entry.customTab |> Maybe.andThen (fromProtoTab entry.path))


navigationTabLabel : NavigationTab -> String
navigationTabLabel navTab =
    case navTab of
        HOMETAB ->
            "Home"

        EVENTSTAB ->
            "Events"

        POSTSTAB ->
            "Posts"

        PEOPLETAB ->
            "People"

        ABOUTTAB ->
            "About"

        NavigationTabUnrecognized_ _ ->
            "Tab"


targetLabel : CustomTabTarget -> String
targetLabel target =
    case target of
        TargetTab navTab ->
            navigationTabLabel navTab

        TargetPost _ ->
            "Post"

        TargetProfile ->
            "Profile"


{-| A tab's shown title -- its own `title` if set, otherwise the predefined tab's name (or "Post"
for a Post target, since resolving an actual Post's title would mean an extra fetch this preview/nav
doesn't do -- see this module's own doc). Mirrors the proto field's own doc ("defaults to the
predefined tab's/Post's title if unset").
-}
resolvedTitle : CustomTab -> String
resolvedTitle tab =
    tab.title |> Maybe.withDefault (targetLabel tab.target)


{-| `CustomTab.path`'s starting value for a freshly-added tab (`SettingsTab.CustomTabAddClicked`) or
one of `defaultTabs` -- once a tab exists, its `path` is admin-editable (see `SettingsTab.customTabEditChip`'s
Path `<input>`) and no longer re-derived from this. The backend's own `validate_configuration` (see
`backend/src/rpcs/validations/configuration_validation.rs`) rejects anything that isn't `[a-z_]+` for
every target *except* `TargetProfile` -- notably *not* a real href (no leading `/`, no digits, no
hyphens), which a Post's own id would violate -- so this is just a lowercase, underscore-only
starting slug the admin's expected to customize (e.g. to `gigs` or `weddings`); for `TargetProfile`
it's really a placeholder username instead (see `CustomTabTarget`'s own doc), not actually reachable
from `SettingsTab.CustomTabTargetKindChanged` (which leaves an existing `path` alone across a kind
switch), but still a safe, valid starting value if this is ever called for one directly.
-}
defaultPathFor : CustomTabTarget -> String
defaultPathFor target =
    case target of
        TargetTab navTab ->
            case navTab of
                HOMETAB ->
                    "home"

                EVENTSTAB ->
                    "events"

                POSTSTAB ->
                    "posts"

                PEOPLETAB ->
                    "people"

                ABOUTTAB ->
                    "about"

                NavigationTabUnrecognized_ _ ->
                    "home"

        TargetPost _ ->
            "post"

        TargetProfile ->
            "profile"


{-| A `CustomTabTarget`'s kind, ignoring a `TargetPost`'s specific id -- what `SettingsTab`'s "type
of tab" `<select>` actually offers a choice between (see `selectableTargetKinds`), since a `TargetPost`'s
id is its own separate `<input>`, not part of the `<select>`. `KindTab` deliberately never wraps
`HOMETAB` -- that's not a selectable choice for a regular tab (see `selectableTargetKinds`).
-}
type TargetKind
    = KindTab NavigationTab
    | KindPost
    | KindProfile


targetKind : CustomTabTarget -> TargetKind
targetKind target =
    case target of
        TargetTab navTab ->
            KindTab navTab

        TargetPost _ ->
            KindPost

        TargetProfile ->
            KindProfile


targetKindText : TargetKind -> String
targetKindText kind =
    case kind of
        KindTab navTab ->
            navigationTabLabel navTab

        KindPost ->
            "Post"

        KindProfile ->
            "Profile"


{-| Every `TargetKind` `SettingsTab`'s "type of tab" `<select>` offers -- the four non-Home
predefined tabs, plus Post and Profile. Mirrors `SettingsTab.allowedDefaultModerations`' own "the
full enum has more values than are actually choosable here" reasoning.
-}
selectableTargetKinds : List TargetKind
selectableTargetKinds =
    [ KindTab EVENTSTAB, KindTab POSTSTAB, KindTab PEOPLETAB, KindTab ABOUTTAB, KindPost, KindProfile ]


targetKindFromText : String -> Maybe TargetKind
targetKindFromText text =
    selectableTargetKinds |> List.filter (\kind -> targetKindText kind == text) |> List.head


{-| A `CustomTabIcon`'s content -- an emoji is wrapped in a `[data-glyph=<emoji>]` `span` (rather
than a bare text node) so CSS can single out specific glyphs for their own treatment without this
module having to know about it -- today that's just `nav.css`'s `[data-glyph="i"]` rule (the same
serif-italic look `UI.aboutLink`'s own hard-coded `.info-button` class gives its "i", for the
default About tab's glyph -- but once a tab's rendered generically through here, whether that's
`ABOUTTAB` isn't available to key off of the way it is there, so this keys off the glyph itself
instead, which is the one thing still true either way). A `MediaIcon` renders an `<img>` resolved
against `server`'s own media (via `AccountsPanel.mediaUrl`, the same helper the server logo/avatar
pickers use), falling back to a placeholder glyph if that id doesn't resolve to a URL (e.g. a media
item deleted out from under a still-configured tab).
-}
iconView : AccountsPanel.Server -> CustomTabIcon -> Html msg
iconView server icon =
    case icon of
        EmojiIcon emoji ->
            span [ attribute "data-glyph" emoji ] [ text emoji ]

        MediaIcon mediaId ->
            case AccountsPanel.mediaUrl server mediaId of
                Just url ->
                    img [ Html.Attributes.class "custom-nav-tab-icon-image", src url, alt "" ] []

                Nothing ->
                    text "🖼️"


{-| One custom tab's actual top-nav link -- same `.nav-link`/`background-color-nav`-when-current
treatment as `UI.eventsLink`/`UI.postsLink`/`UI.peopleLink`/`UI.aboutLink`, just generic over any
`CustomTab` instead of one hard-coded route/glyph each. `server` is whichever server's
`ServerConfiguration` this `CustomTab` came from (always `UI.mainServer shared` for the real nav,
but `SettingsTab`'s preview reuses this for whichever server is being viewed/edited). Generic in
`msg` (no `Shared.Msg`-specific click handling, unlike `UI.navLink`'s own Home link) since a plain
`href` is all routing here needs -- elm-spa's own link interception handles the rest.

Links to `tab.path` itself (via `Route.UsernameOrCustomTab_`), not `tab.target`'s own canonical
route -- `Pages.UsernameOrCustomTab_` is what actually resolves that path back to `target` at
request time (see its own `customTabFor`), so this always matches whatever url a visitor would
land on, e.g. a `path` of `gigs` links to (and highlights as current on) `/gigs`, not `/events`,
even though `target` is `EVENTSTAB`.
-}
navLinkView : Shared.Model -> Route -> AccountsPanel.Server -> CustomTab -> Html msg
navLinkView shared currentRoute server tab =
    let
        route : Route
        route =
            Route.UsernameOrCustomTab_ { usernameOrCustomTab = tab.path }

        isCurrent : Bool
        isCurrent =
            route == currentRoute
    in
    a
        [ href (shared.basePath ++ Route.toHref route)
        , classes
            ("nav-link"
                :: (if isCurrent then
                        [ hostnameToCSSClass shared.accounts.mainFrontendHost, "background-color-nav" ]

                    else
                        []
                   )
            )
        , title (resolvedTitle tab)
        ]
        [ iconView server tab.icon ]
