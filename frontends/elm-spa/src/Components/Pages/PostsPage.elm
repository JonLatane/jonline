module Components.Pages.PostsPage exposing
    ( Model
    , Msg
    , fromShared
    , init
    , searchTextChanged
    , subscriptions
    , update
    , view
    )

{-| The shared guts of a "recent posts" page: fetching recent posts from every
enabled server and rendering them with fade in/out animations, plus a
search box + POST/REPLY context chooser (see `searchRowView`) that switches
the fetch to `TEXT_SEARCH` (debounced 311ms after typing stops) and persists
`search_text`/`context` as URL query params -- reused by `Pages.Home_` (which
adds its own "Recent Posts" heading and passes `author = Nothing`) and
`Pages.Username_.Posts`/`Pages.User.UserId_.Posts` (which pass the
already-resolved profile `User`, restricting the feed to that user's own
posts and adding this module's own "Posts | <name>" heading, via
`Components.Pages.UserProfilePage.nameHeader`), mirroring how
`Components.Pages.UserProfilePage` is reused by `Pages.Username_` and
`Pages.User.UserId_` themselves.
-}

import Animation
import Browser.Navigation
import Components.Posts as Posts
import Components.Users exposing (usernameHref)
import Components.Users.ProfileHeading as ProfileHeading
import Dict exposing (Dict)
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, a, button, div, h2, input, option, p, select, text)
import Html.Attributes exposing (class, href, placeholder, selected, style, title, type_, value)
import Html.Events exposing (onClick, onInput, preventDefaultOn)
import Html.Keyed
import Json.Decode as Decode
import Process
import Proto.Jonline exposing (Post, User)
import Proto.Jonline.PostContext exposing (PostContext(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.Breadcrumbs as Breadcrumbs
import Shared.BrowserTimeZone as BrowserTimeZone
import Shared.Conversions as Conversions
import Shared.MediaViewerPanel as MediaViewerPanel
import Shared.StarredPanel as StarredPanel
import Task
import Time
import UI.Classes exposing (classes, hostnameToCSSClass)
import UI.Flip
import Url.Builder



-- MODEL


type ServerPosts
    = Loading
    | Loaded (List Post)
    | Failed


{-| `accountId` is the enabled account (if any) the posts were/are being
fetched with, so a later account enable/disable on the same server can be
detected as "the acting credential changed" and trigger a re-fetch.
-}
type alias ServerFeed =
    { status : ServerPosts
    , accountId : Maybe String
    }


{-| A post's fade in/out state, keyed in `postAnimations` by `postAnimationKey`
so it survives independently of `postsByServer` -- see that dict's own doc
comment for why: a server being disabled (or re-fetched under a different
account) drops/replaces its posts in `postsByServer` immediately, but a
`removing` `flip` entry here keeps rendering its last-known `post`/`host`
until its fade-out finishes, instead of the post just vanishing. See
`UI.Flip` for what `flip` itself drives.
-}
type alias PostAnimation =
    { host : String
    , post : Post
    , flip : UI.Flip.State Msg
    }


type alias Model =
    { postsByServer : Dict String ServerFeed
    , postAnimations : Dict String PostAnimation
    , author : Maybe ( String, User )

    -- `True` for embedded copies of this model (`Pages.Home_`,
    -- `Components.Pages.UserProfilePage`, passed via `init`'s own
    -- `embeddedPage` argument) -- gates `setBreadcrumbsRoot` off entirely
    -- (see its own doc): an embedding page already owns `Shared.Breadcrumbs`
    -- itself, so this copy asserting a root of its own on every `update`
    -- (including every animation tick, e.g. from `postAnimations`) would
    -- otherwise fight the real owner for it. Mirrors
    -- `Components.Pages.EventsPage.Model.embeddedPage` exactly.
    , embeddedPage : Bool
    , navKey : Browser.Navigation.Key
    , path : String
    , searchText : String
    , context : PostContext
    , searchGeneration : Int

    -- Which of `recentPostsTabsView`'s two tabs is active -- see `PostsTab`'s own doc.
    , tab : PostsTab

    -- The cutoff actually sent as `Components.Posts.fetchPosts`' own
    -- `publishedOrCreatedBefore` whenever `tab == PostsBeforeDate` (ignored
    -- entirely on `RecentPosts` -- see `refetchServers`'s own `fetchEffect`).
    -- `Nothing` until either a `?published_before=` query param resolves it
    -- on load, or `PostsBeforeDate` is selected for the first time (see
    -- `GotNow`) -- mirrors `Components.Pages.EventsPage.Model.endsAfter`'s
    -- own "don't fetch before a real cutoff exists" doc, just seeded once
    -- rather than kept live.
    , publishedBefore : Maybe Time.Posix

    -- Debounces `PublishedBeforeInputChanged` (500ms) -- mirrors
    -- `Components.Pages.EventsPage.Model.endsAfterInputGeneration` exactly,
    -- just for this page's own date input.
    , publishedBeforeInputGeneration : Int
    }


{-| Which of `recentPostsTabsView`'s two tabs is active -- `RecentPosts` (the
default) is this page's original, unfiltered-by-time feed; `PostsBeforeDate`
filters by a fixed, user-picked `model.publishedBefore` cutoff, sent as
`GetPostsRequest.published_or_created_before` (see
`backend/src/rpcs/posts/get_posts.rs`) -- editable via its own
`<input type="datetime-local">`. Persisted to the URL as a `published_before`
query param (see `pushUrl`) -- its mere presence/absence on load is what
`init` uses to decide which tab to start on, mirroring
`Components.Pages.EventsPage.EventsTab`/`?ends_after=` exactly. Only ever
shown (via `recentPostsTabsView`) on the standalone, unfiltered Posts page
(`model.author == Nothing`, `not model.embeddedPage`) -- see that view's own
doc for why.
-}
type PostsTab
    = RecentPosts
    | PostsBeforeDate


{-| `author`, if given, restricts the feed to that user's own posts (see
`Components.PostCard.fetchRecentPosts`) and adds a "Posts | <name>"
heading (see `view`) -- `Pages.Home_` passes `Nothing`,
`Pages.Username_.Posts`/`Pages.User.UserId_.Posts` pass their
already-resolved profile `User` paired with the host it was resolved from
(`Components.Users.Resolver`'s own `targetHost`, resolved before ever calling
this, so this module never needs to fetch the `User` itself -- it only needs
the host alongside it to look up that server's `AccountsPanel.Server`/signed-in
`Account` for `authorHeadingView`'s avatar).

`navKey`/`path`, from the calling page's own `Request`, are what let
`searchRowView`'s search box/context chooser and `recentPostsTabsView`'s date
input persist `search_text`/`context`/`published_before` as URL query params
(see `pushUrl`) without this module needing to know which page-specific
`Gen.Params.*` type that `Request` is actually parameterized over -- every
caller's `Request.key`/`Request.url.path` fit this regardless. `query`, that
same `Request`'s already-parsed `.query`, seeds `searchText`/`context`/`tab`/
`publishedBefore` back out of the URL on load, so a shared/reloaded link
reproduces the same search/cutoff.

`embeddedPage` is `True` only for `Pages.Home_`'s and
`Components.Pages.UserProfilePage`'s own embedded copies -- see
`Model.embeddedPage`'s own doc.

-}
init : Shared.Model -> Maybe ( String, User ) -> Browser.Navigation.Key -> String -> Dict String String -> Bool -> ( Model, Effect Msg )
init shared author navKey path query embeddedPage =
    let
        ( tab, publishedBefore ) =
            case Dict.get "published_before" query |> Maybe.andThen Conversions.posixFromIsoUtcString of
                Just cutoff ->
                    ( PostsBeforeDate, Just cutoff )

                Nothing ->
                    ( RecentPosts, Nothing )

        ( fetchedModel, fetchEffect ) =
            fetchNewServers shared
                { postsByServer = Dict.empty
                , postAnimations = Dict.empty
                , author = author
                , embeddedPage = embeddedPage
                , navKey = navKey
                , path = path
                , searchText = Dict.get "search_text" query |> Maybe.withDefault ""
                , context = Dict.get "context" query |> Maybe.andThen postContextFromParam |> Maybe.withDefault POST
                , searchGeneration = 0
                , tab = tab
                , publishedBefore = publishedBefore
                , publishedBeforeInputGeneration = 0
                }
    in
    -- Closes any open panel (Accounts, Starred, etc.) unconditionally on
    -- load -- `setBreadcrumbsRoot` below only does this as a side effect of
    -- actually changing `shared.breadcrumbs.root` (see `Shared.update`'s
    -- `SetRoot` branch), which is a no-op for two pages that share a root,
    -- e.g. landing here right after `/people` while both are still
    -- `FromServerHost mainFrontendHost`. Mirrors
    -- `Components.Pages.UserProfilePage.init`'s own unconditional close.
    ( fetchedModel, Effect.batch [ fetchEffect, Effect.fromShared Shared.CloseAllPanels, setBreadcrumbsRoot shared fetchedModel ] )


{-| The servers this page should ever fetch from: every enabled server for an
unfiltered feed (`model.author == Nothing`, e.g. `Pages.Home_`), or, once
`author` restricts the feed to one user, _only_ that user's own resolved
host -- looked up via `AccountsPanel.serverForHost` (not `enabledServers`),
since a user profile can be resolved, and its posts fetched anonymously,
from a known server the viewer hasn't toggled "enabled" (or isn't signed
into at all) -- see `Components.Users.Resolver.fetchTask`, which resolves
`author` itself the same way. Without this restriction, both plain listing
and (especially) `TEXT_SEARCH` would fan out to every other enabled server
too, e.g. showing `jon@oakcitysocial.com`'s posts on `jon@jonline.io`'s
own posts page.
-}
relevantServers : Shared.Model -> Model -> List AccountsPanel.Server
relevantServers shared model =
    case model.author of
        Just ( host, _ ) ->
            AccountsPanel.serverForHost shared.accountsPanel.servers host
                |> Maybe.map List.singleton
                |> Maybe.withDefault []

        Nothing ->
            AccountsPanel.enabledServers shared.accountsPanel


{-| Fetches `serversToFetch` using the current `model.searchText`/
`model.context`, and drops any already-fetched server that's no longer
`relevantServers` -- shared by `fetchNewServers` (which only passes the
servers that actually need it, see its own doc comment) and
`applySearchChange` (which always passes every relevant server, since a
changed search must re-fetch everything regardless of whether that server's
acting account also happens to have changed).

A server already `Loaded` under the _same_ acting account keeps showing its
last-known posts (`status` left untouched) while the re-fetch is in flight,
rather than being reset to `Loading` first -- `Loading` isn't rendered as its
own state anywhere in this module, so the only thing resetting it did was
drop that server out of `syncAnimations`' `currentPosts`, which reads as
every one of its posts fading out and back in a moment later, even though
`applySearchChange`'s response usually still contains most of the same posts.
See `Components.Pages.EventsPage.refetchServers`'s own doc for where this was
first diagnosed (a periodic full-list flicker there) and ported from. A
genuinely new server, or one whose acting account just changed (sign-in/out),
still resets to `Loading` -- its previous posts (fetched under a different or
no account) are stale/invalid, not just "not yet refreshed," so they should
disappear rather than linger.

A no-op (nothing touched, no fetch fired) while `model.tab == PostsBeforeDate`
and `model.publishedBefore` is still `Nothing` -- mirrors
`Components.Pages.EventsPage.refetchServers`'s own guard on `model.endsAfter`:
fetching with no real cutoff yet in hand would ask for `RecentPosts`' full
feed for the brief instant before `GotNow` resolves one, rather than just
waiting.

-}
refetchServers : Shared.Model -> Model -> List AccountsPanel.Server -> ( Model, Effect Msg )
refetchServers shared model serversToFetch =
    if model.tab == PostsBeforeDate && model.publishedBefore == Nothing then
        ( model, Effect.none )

    else
        let
            enabledServers =
                relevantServers shared model

            currentAccountId server =
                AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost
                    |> Maybe.map AccountsPanel.accountId

            cutoff =
                if model.tab == PostsBeforeDate then
                    model.publishedBefore

                else
                    Nothing

            fetchEffect server =
                Posts.fetchPosts
                    shared.accountsPanel
                    ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost |> Maybe.map .userId
                    , server.frontendHost
                    )
                    (model.author |> Maybe.map (Tuple.second >> .id))
                    model.searchText
                    model.context
                    cutoff
                    |> Task.attempt (GotServerPosts server.frontendHost)
                    |> Effect.fromCmd

            prunedPostsByServer =
                Dict.filter (\host _ -> List.member host (List.map .frontendHost enabledServers)) model.postsByServer

            markServer server dict =
                let
                    accountId =
                        currentAccountId server

                    statusIfSameAccount =
                        Dict.get server.frontendHost dict
                            |> Maybe.andThen
                                (\feed ->
                                    if feed.accountId == accountId then
                                        Just feed.status

                                    else
                                        Nothing
                                )
                in
                Dict.insert server.frontendHost
                    { status = Maybe.withDefault Loading statusIfSameAccount, accountId = accountId }
                    dict
        in
        ( { model
            | postsByServer =
                List.foldl markServer prunedPostsByServer serversToFetch
          }
        , Effect.batch (List.map fetchEffect serversToFetch)
        )
            |> Tuple.mapFirst syncAnimations


{-| Drops posts for servers that are no longer enabled (so disabling a server
hides its posts entirely), and re-fetches a server whose acting account (the
first enabled account signed into it, or anonymous) has changed since the
last fetch -- covering both disabling an account (falls back to anonymous)
and enabling a different one. Already-fetched-with-the-same-account servers
are cheap to skip, so this is safe to call as often as it likes.

This is event-driven -- any `AccountsPanel` message passing through `update`'s
`SharedMsg` branch triggers a call, since that covers server/account
add/remove/enable/toggle, including reconnecting persisted servers on app
startup (`Main.notifyPageOfSharedMsg` forwards those top-level `Shared`
messages into whichever page is active). `subscriptions`' poll is just a
distrustful fallback in case some future state change doesn't route through
`SharedMsg`, so it can be slow.

-}
fetchNewServers : Shared.Model -> Model -> ( Model, Effect Msg )
fetchNewServers shared model =
    let
        currentAccountId server =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost
                |> Maybe.map AccountsPanel.accountId

        serversToFetch =
            relevantServers shared model
                |> List.filter
                    (\server ->
                        case Dict.get server.frontendHost model.postsByServer of
                            Nothing ->
                                True

                            Just feed ->
                                feed.accountId /= currentAccountId server
                    )
    in
    refetchServers shared model serversToFetch


{-| Re-fetches every relevant server (unconditionally -- unlike
`fetchNewServers`, a changed search has to override every already-Loaded
feed, not just servers whose acting account changed) and persists the new
`search_text`/`context` to the URL -- the single path `SearchDebounceElapsed`,
`ContextChanged`, and `ClearSearchClicked` all funnel through.
-}
applySearchChange : Shared.Model -> Model -> ( Model, Effect Msg )
applySearchChange shared model =
    let
        ( refetchedModel, refetchEffect ) =
            refetchServers shared model (relevantServers shared model)
    in
    ( refetchedModel, Effect.batch [ refetchEffect, pushUrl refetchedModel ] )


{-| Keeps `Shared.Breadcrumbs` pointed at this feed's own root: `FromServerHost
mainFrontendHost` for an unfiltered feed (`model.author == Nothing`, e.g.
`Pages.Posts`), or `FromUser` the already-resolved author once one's known
(`Pages.Username_.Posts`/`Pages.User.UserId_.Posts`, which only ever call
`init` once their own `Resolver` has actually loaded the `User` -- see
`Pages.Username_.Posts.update`) -- mirrors
`Components.Pages.UserProfilePage.setBreadcrumbsHost`, reissued after every
`update`, a no-op once already in sync via the same equality check.

Always `Effect.none` for an embedded copy (`model.embeddedPage`, e.g.
`Pages.Home_`'s or `Components.Pages.UserProfilePage`'s own) -- the embedding
page already owns `Shared.Breadcrumbs` itself, so this copy asserting a root
of its own on every `update` (including every animation tick, e.g. from
`postAnimations`) would otherwise fight the real owner for it, flickering
between the two roots whenever this page's `update` fires more often than the
embedding page's own (previously the actual cause of a breadcrumb flicker
during `Components.Pages.UserProfilePage`'s `EventsPage` animations).

-}
setBreadcrumbsRoot : Shared.Model -> Model -> Effect Msg
setBreadcrumbsRoot shared model =
    if model.embeddedPage then
        Effect.none

    else
        let
            ( root, host ) =
                case model.author of
                    Just ( authorHost, user ) ->
                        ( Breadcrumbs.FromUser user, authorHost )

                    Nothing ->
                        ( Breadcrumbs.FromServerHost shared.accountsPanel.mainFrontendHost, shared.accountsPanel.mainFrontendHost )
        in
        if shared.breadcrumbs.root == Just root then
            Effect.none

        else
            Effect.fromShared (Shared.BreadcrumbsMsg (Breadcrumbs.SetRoot root host []))


{-| Persists `model.searchText`/`model.context`/`model.tab`'s own
`publishedBefore` cutoff to the URL as `search_text`/`context`/
`published_before` query params, via `replaceUrl` (not the navigation
function `pushUrl` -- editing the search box/date input shouldn't spam
browser history with one entry per debounce fire). Each omitted entirely
while at its default (blank search, `POST` context, `RecentPosts` tab), so
the common case keeps a clean URL. Query-string-only navigation like this
doesn't re-trigger this page's `init` -- see `Main.elm`'s `ChangedUrl`
handler, which only does that when `url.path` itself changes. Built as one
combined list (rather than each concern pushing its own `replaceUrl`
independently) because `Browser.Navigation.replaceUrl`/`Url.Builder.toQuery`
replace the _whole_ query string -- independent single-param pushes would
each silently wipe out whatever the others had just set. Mirrors
`Components.Pages.EventsPage.pushUrl`/`queryParams`.
-}
pushUrl : Model -> Effect Msg
pushUrl model =
    let
        searchTextParam =
            if String.isEmpty (String.trim model.searchText) then
                []

            else
                [ Url.Builder.string "search_text" model.searchText ]

        contextParam =
            if model.context == POST then
                []

            else
                [ Url.Builder.string "context" (postContextParam model.context) ]

        publishedBeforeParam =
            case ( model.tab, model.publishedBefore ) of
                ( PostsBeforeDate, Just cutoff ) ->
                    [ Url.Builder.string "published_before" (Conversions.isoUtcString cutoff) ]

                _ ->
                    []
    in
    Browser.Navigation.replaceUrl model.navKey (model.path ++ Url.Builder.toQuery (searchTextParam ++ contextParam ++ publishedBeforeParam))
        |> Effect.fromCmd


{-| `post`/`reply` as sent via `search_text`/`context`'s URL query param and
`searchRowView`'s `<select>` `value`/`onInput` -- lowercase since it's the
URL-facing form; `postContextFromParam` reads it back case-insensitively, so
`?context=REPLY`/`?context=Reply`/etc. (e.g. a hand-edited or older link)
still work.
-}
postContextParam : PostContext -> String
postContextParam context =
    case context of
        REPLY ->
            "reply"

        _ ->
            "post"


{-| Case-insensitive inverse of `postContextParam`. Any other `PostContext`
(there are more, but only `POST`/`REPLY` are offered in the chooser -- see
`searchRowView`) round-trips back to `Nothing`/is left alone.
-}
postContextFromParam : String -> Maybe PostContext
postContextFromParam param =
    case String.toUpper param of
        "POST" ->
            Just POST

        "REPLY" ->
            Just REPLY

        _ ->
            Nothing


{-| Title-cased display label for `searchRowView`'s context chooser --
`postContextParam`/`postContextFromParam` handle the URL/`<select>` `value`
round-trip separately, since those are deliberately not title-cased.
-}
postContextLabel : PostContext -> String
postContextLabel context =
    case context of
        REPLY ->
            "Replies"

        _ ->
            "Posts"



-- ANIMATION


{-| Identifies a post independently of which server/account fetched it, for
`postAnimations` -- `postHref`'s `id@host` convention is reused here purely as
a unique dict key, not as a route.
-}
postAnimationKey : String -> Post -> String
postAnimationKey host post =
    host ++ "@" ++ post.id


{-| Reconciles `postAnimations` with the posts currently `Loaded` in
`postsByServer`: starts a fade-in for newly-seen posts, a fade-out for posts
that dropped out (rather than deleting them outright), and un-interrupts a
still-fading-out post that reappeared. Safe/cheap to call after every
`postsByServer` change, so `update` just calls it unconditionally wherever
that dict might have changed. `RemovePost` is what actually drops a gone
post's animation entry once its fade-out finishes. See `UI.Flip.syncAnimations`
for the shared reconciliation logic this hands its own `PostAnimation` shape
to (mirrored by `Components.Pages.UsersPage.syncAnimations`).
-}
syncAnimations : Model -> Model
syncAnimations model =
    let
        currentPosts : Dict String ( String, Post )
        currentPosts =
            model.postsByServer
                |> Dict.toList
                |> List.concatMap
                    (\( host, feed ) ->
                        case feed.status of
                            Loaded posts ->
                                List.map (\post -> ( postAnimationKey host post, ( host, post ) )) posts

                            _ ->
                                []
                    )
                |> Dict.fromList
    in
    { model
        | postAnimations =
            UI.Flip.syncAnimations
                RemovePost
                (\( host, post ) -> { host = host, post = post, flip = UI.Flip.enter })
                (\( host, post ) anim -> { anim | host = host, post = post })
                currentPosts
                model.postAnimations
    }



-- UPDATE


type Msg
    = GotServerPosts String (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Jonline.GetPostsResponse ))
    | Poll
    | Animate Animation.Msg
    | RemovePost String
    | SharedMsg Shared.Msg
    | SearchTextChanged String
    | SearchDebounceElapsed Int
    | ContextChanged String
    | ClearSearchClicked
      -- Switches `model.tab` -- a no-op if already active. Mirrors
      -- `Components.Pages.EventsPage.TabChanged` in spirit: no shared
      -- layout/animation to slide between, just a different fetch cutoff, so
      -- this just updates `model.tab`/refetches/persists the URL directly --
      -- except switching to `PostsBeforeDate` for the very first time (no
      -- `model.publishedBefore` yet) instead seeds one via `GotNow` first.
      -- See `recentPostsTabsView`.
    | TabChanged PostsTab
      -- `Task.perform GotNow Time.now`'s result, fired only when
      -- `PostsBeforeDate` is selected with no `model.publishedBefore` yet
      -- (see `TabChanged`) -- seeds it with the current time (a sensible
      -- starting cutoff the user can then dial back) and fetches.
    | GotNow Time.Posix
      -- The `PostsBeforeDate` tab's `<input type="datetime-local">` firing --
      -- mirrors `Components.Pages.EventsPage.EndsAfterInputChanged` exactly,
      -- just against this page's own `publishedBefore`/`publishedBeforeInputGeneration`.
    | PublishedBeforeInputChanged String
      -- `PublishedBeforeInputChanged`'s debounce timer elapsing -- mirrors
      -- `Components.Pages.EventsPage.EndsAfterDebounceElapsed`'s own stale-
      -- generation guard.
    | PublishedBeforeDebounceElapsed Int


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
(see `Main.notifyPageOfSharedMsg`) into `update`'s `SharedMsg` branch, without
exposing the `SharedMsg` constructor itself (and thus every other constructor
of this otherwise-opaque `Msg`) outside this module.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


{-| Lets a sibling page (`Pages.Home_`, keeping its embedded `EventsPage`'s search box in sync
with this module's own `model.searchText` behind the scenes -- see that module's own
`searchTextChanged` and `Pages.Home_.update`'s cross-sync) feed a search-text change in from
outside exactly as if the user had typed it into this module's own (on `Pages.Home_`, hidden --
see `view`'s `showSearchRow`) search box -- same `SearchTextChanged`/`SearchDebounceElapsed`
round-trip, same independent debounce timer, without exposing the `SearchTextChanged` constructor
itself (and thus every other constructor of this otherwise-opaque `Msg`) outside this module.
-}
searchTextChanged : String -> Msg
searchTextChanged =
    SearchTextChanged


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    let
        ( newModel, effect ) =
            updateInner shared msg model
    in
    ( newModel, Effect.batch [ effect, setBreadcrumbsRoot shared newModel ] )


updateInner : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
updateInner shared msg model =
    case msg of
        GotServerPosts frontendHost (Ok ( maybeAccountsPanelMsg, response )) ->
            let
                accountEffect =
                    maybeAccountsPanelMsg
                        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
                        |> Maybe.withDefault Effect.none
            in
            ( { model
                | postsByServer =
                    Dict.update frontendHost
                        (Maybe.map (\feed -> { feed | status = Loaded response.posts }))
                        model.postsByServer
              }
                |> syncAnimations
            , accountEffect
            )

        GotServerPosts frontendHost (Err _) ->
            ( { model
                | postsByServer =
                    Dict.update frontendHost (Maybe.map (\feed -> { feed | status = Failed })) model.postsByServer
              }
                |> syncAnimations
            , Effect.none
            )

        Poll ->
            fetchNewServers shared model

        Animate animMsg ->
            let
                step key anim ( animations, accCmds ) =
                    let
                        ( newFlip, cmd ) =
                            UI.Flip.animate animMsg anim.flip
                    in
                    ( Dict.insert key { anim | flip = newFlip } animations, cmd :: accCmds )

                ( newAnimations, cmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.postAnimations
            in
            ( { model | postAnimations = newAnimations }, Effect.batch (List.map Effect.fromCmd cmds) )

        RemovePost key ->
            ( { model | postAnimations = Dict.remove key model.postAnimations }, Effect.none )

        SharedMsg subMsg ->
            let
                ( fetchedModel, fetchEffect ) =
                    case subMsg of
                        Shared.AccountsPanelMsg _ ->
                            fetchNewServers shared model

                        _ ->
                            ( model, Effect.none )
            in
            ( fetchedModel, Effect.batch [ Effect.fromShared subMsg, fetchEffect ] )

        SearchTextChanged text ->
            let
                generation =
                    model.searchGeneration + 1
            in
            ( { model | searchText = text, searchGeneration = generation }
            , Process.sleep 311
                |> Task.perform (\_ -> SearchDebounceElapsed generation)
                |> Effect.fromCmd
            )

        SearchDebounceElapsed generation ->
            if generation == model.searchGeneration then
                applySearchChange shared model

            else
                -- A later edit (or ClearSearchClicked/ContextChanged) already
                -- bumped searchGeneration past this timer's -- it's stale, ignore it.
                ( model, Effect.none )

        ContextChanged param ->
            case postContextFromParam param of
                Just newContext ->
                    applySearchChange shared { model | context = newContext, searchGeneration = model.searchGeneration + 1 }

                Nothing ->
                    ( model, Effect.none )

        ClearSearchClicked ->
            applySearchChange shared { model | searchText = "", searchGeneration = model.searchGeneration + 1 }

        TabChanged RecentPosts ->
            if model.tab == RecentPosts then
                ( model, Effect.none )

            else
                let
                    ( refetchedModel, refetchEffect ) =
                        refetchServers shared { model | tab = RecentPosts } (relevantServers shared model)
                in
                ( refetchedModel, Effect.batch [ refetchEffect, pushUrl refetchedModel ] )

        TabChanged PostsBeforeDate ->
            if model.tab == PostsBeforeDate then
                ( model, Effect.none )

            else
                case model.publishedBefore of
                    Just _ ->
                        let
                            ( refetchedModel, refetchEffect ) =
                                refetchServers shared { model | tab = PostsBeforeDate } (relevantServers shared model)
                        in
                        ( refetchedModel, Effect.batch [ refetchEffect, pushUrl refetchedModel ] )

                    Nothing ->
                        ( { model | tab = PostsBeforeDate }, Task.perform GotNow Time.now |> Effect.fromCmd )

        GotNow now ->
            if model.tab == PostsBeforeDate && model.publishedBefore == Nothing then
                let
                    ( refetchedModel, refetchEffect ) =
                        refetchServers shared { model | publishedBefore = Just now } (relevantServers shared model)
                in
                ( refetchedModel, Effect.batch [ refetchEffect, pushUrl refetchedModel ] )

            else
                ( model, Effect.none )

        PublishedBeforeInputChanged raw ->
            case BrowserTimeZone.posixFromDateTimeLocalInput shared.browserTimeZone.zone raw of
                Nothing ->
                    ( model, Effect.none )

                Just newPublishedBefore ->
                    let
                        generation =
                            model.publishedBeforeInputGeneration + 1
                    in
                    ( { model | tab = PostsBeforeDate, publishedBefore = Just newPublishedBefore, publishedBeforeInputGeneration = generation }
                    , Process.sleep 500
                        |> Task.perform (\_ -> PublishedBeforeDebounceElapsed generation)
                        |> Effect.fromCmd
                    )

        PublishedBeforeDebounceElapsed generation ->
            if generation == model.publishedBeforeInputGeneration then
                let
                    ( refetchedModel, refetchEffect ) =
                        refetchServers shared model (relevantServers shared model)
                in
                ( refetchedModel, Effect.batch [ refetchEffect, pushUrl refetchedModel ] )

            else
                -- A later edit already bumped `publishedBeforeInputGeneration`
                -- past this timer's -- it's stale, ignore it.
                ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every 30000 (\_ -> Poll)
        , UI.Flip.subscription Animate (List.map .flip (Dict.values model.postAnimations))
        ]



-- VIEW


{-| `showSearchRow` hides `searchRowView` (the search box + POST/REPLY context chooser together)
when `False` -- used by `Pages.Home_`, which shows its own `EventsPage`'s search box instead and
keeps this module's `model.searchText` in sync with it behind the scenes (see
`Pages.Home_.update`'s cross-sync) rather than showing two redundant boxes. Every other caller
passes `True`, preserving the previous always-shown behavior.

`showAuthorHeading` hides `authorHeadingView` (the "Posts | <name>" heading) when `False`
-- used by `Components.Pages.UserProfilePage`, which embeds this module a level below its own
already-shown username/avatar header (see `profileDetail`), so a second copy of the same name
would be redundant. Every other caller passes `True`, preserving the previous always-shown
(whenever `model.author` is `Just`) behavior.

-}
view : Shared.Model -> Bool -> Bool -> Model -> Html Msg
view shared showSearchRow showAuthorHeading model =
    div []
        [ recentPostsTabsView shared model
        , if showAuthorHeading then
            authorHeadingView shared model.author model.context

          else
            text ""
        , if showSearchRow then
            searchRowView model

          else
            text ""
        , postsListView shared model
        ]


{-| The "Recent Posts"/"Recent Replies" heading's replacement on the
standalone, unfiltered Posts page (`model.author == Nothing`, `not
model.embeddedPage` -- `text ""` otherwise, so every other caller of `view`
is unaffected): two tabs (mirrors
`Components.Pages.EventsPage.tabsView`'s own look/structure), `RecentPosts`
(a plain pill button, carrying the same "Recent Posts"/"Recent Replies" label
`Pages.Posts`' own heading used to) and `PostsBeforeDate` (a `div` rather than
a `button`, since it nests a real `<input type="datetime-local">` and nesting
interactive content inside a `<button>` is invalid HTML) -- clicking either
(including anywhere in the second tab, to open the date input's native
picker, since the click still bubbles up to the wrapping `div`) or actually
changing the date both switch to it, per `TabChanged`'s own doc. Absent
entirely for `Pages.Home_`'s embedded copy (still gets its own static
"Recent Posts"/"Recent Replies" heading, see `Pages.Home_.heading`) and for
any author-scoped copy (`Pages.Username_.Posts`/`Pages.User.UserId_.Posts`/
`Components.Pages.UserProfilePage`, which show `authorHeadingView` instead).
-}
recentPostsTabsView : Shared.Model -> Model -> Html Msg
recentPostsTabsView shared model =
    if model.author /= Nothing || model.embeddedPage then
        text ""

    else
        div [ class "posts-tabs" ]
            [ button
                [ classes
                    ("posts-tab"
                        :: "posts-tab-primary"
                        :: (if model.tab == RecentPosts then
                                [ "background-color-primary" ]

                            else
                                []
                           )
                    )
                , onClick (TabChanged RecentPosts)
                ]
                [ text (recentPostsLabel model.context) ]
            , div
                [ classes
                    ("posts-tab"
                        :: (if model.tab == PostsBeforeDate then
                                [ "background-color-primary" ]

                            else
                                []
                           )
                    )
                , onClick (TabChanged PostsBeforeDate)
                ]
                [ text (postsBeforeLabel model.context ++ " ")
                , input
                    [ type_ "datetime-local"
                    , class "posts-tab-date-input"
                    , value
                        (BrowserTimeZone.formatDateTimeLocalInput
                            shared.browserTimeZone.zone
                            (Maybe.withDefault (Time.millisToPosix 0) model.publishedBefore)
                        )
                    , onInput PublishedBeforeInputChanged
                    ]
                    []
                ]
            ]


{-| "Recent Posts"/"Recent Replies", matching `context` -- mirrors
`Pages.Posts.heading`'s old label exactly (this view replaces that page's own
static heading, see `recentPostsTabsView`'s own doc).
-}
recentPostsLabel : PostContext -> String
recentPostsLabel context =
    case context of
        REPLY ->
            "Recent Replies"

        _ ->
            "Recent Posts"


{-| "Posts Before"/"Replies Before", matching `context` -- `recentPostsTabsView`'s
own `PostsBeforeDate` tab label, immediately followed by its `<input
type="datetime-local">`.
-}
postsBeforeLabel : PostContext -> String
postsBeforeLabel context =
    case context of
        REPLY ->
            "Replies Before"

        _ ->
            "Posts Before"


{-| Search box (debounced, see `SearchTextChanged`/`SearchDebounceElapsed`)
plus a POST/REPLY context chooser, side by side -- only those two contexts
are offered for now (`Proto.Jonline.PostContext` has others, e.g. `EVENT`,
that don't apply to a plain posts feed). The clear ("╳") button, styled like
`UI.elm`'s `fieldClearButton`/`.field-clear-button` (can't reuse that
directly -- it's hardcoded to `Shared.Msg`/`AccountsPanel.Msg`, not this
module's own `Msg`), only appears once there's search text to clear.
-}
searchRowView : Model -> Html Msg
searchRowView model =
    div [ class "posts-search-row" ]
        [ div [ class "posts-search-field" ]
            [ input
                [ type_ "text"
                , class "posts-search-input"
                , placeholder <|
                    case model.context of
                        REPLY ->
                            "Search replies..."

                        _ ->
                            "Search posts..."
                , value model.searchText
                , onInput SearchTextChanged
                , onEscape ClearSearchClicked
                ]
                []
            , if String.isEmpty model.searchText then
                text ""

              else
                button
                    [ type_ "button"
                    , class "field-clear-button"
                    , onClick ClearSearchClicked
                    , title "Clear search"
                    ]
                    [ text "╳" ]
            ]
        , select [ class "posts-search-context", onInput ContextChanged ]
            (List.map
                (\context ->
                    option
                        [ value (postContextParam context)
                        , selected (model.context == context)
                        ]
                        [ text (postContextLabel context) ]
                )
                [ POST, REPLY ]
            )
        ]


{-| Fires `msg` (and suppresses the key's default effect) when Escape is
pressed in a text input -- mirrors `UI.elm`'s `onEnter`, just for a different
key; defined locally rather than imported from there since `UI` is the
higher-level module that itself ends up depending on pages like this one.
-}
onEscape : msg -> Html.Attribute msg
onEscape msg =
    preventDefaultOn "keydown"
        (Decode.field "key" Decode.string
            |> Decode.andThen
                (\key ->
                    if key == "Escape" then
                        Decode.succeed ( msg, True )

                    else
                        Decode.fail "Not the Escape key"
                )
        )


{-| "Posts"/"Replies" (matching `context` -- the same POST/REPLY chooser
`searchRowView` renders just below this) alone once there's an `author` to
filter by (even before that `User` -- already resolved by the caller, see
`init` -- has actually rendered), upgraded to "Posts | <name>" via
`Components.Users.ProfileHeading.nameHeader` (with that author's avatar, via
its resolved-host `AccountsPanel.Server`/signed-in `Account`, if that host is
still a known server -- falling back to `ProfileHeading.usernameHeading`,
avatar-less, if not) -- absent entirely for `Pages.Home_`'s unfiltered feed
(`author == Nothing`), which supplies its own "Recent Posts"/"Recent Replies"
heading instead (see `Pages.Home_.heading`).
-}
authorHeadingView : Shared.Model -> Maybe ( String, User ) -> PostContext -> Html Msg
authorHeadingView shared maybeAuthor context =
    case maybeAuthor of
        Nothing ->
            text ""

        Just ( host, author ) ->
            let
                profileUrl =
                    usernameHref "" shared.accountsPanel.mainFrontendHost host author.username

                headingText =
                    case context of
                        REPLY ->
                            "Replies"

                        _ ->
                            "Posts"
            in
            div [ class "posts-page-heading" ]
                [ h2 [] [ text headingText ]
                , a [ href profileUrl, class <| hostnameToCSSClass host ]
                    [ case AccountsPanel.serverForHost shared.accountsPanel.servers host of
                        Just server ->
                            ProfileHeading.nameHeader server (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host) author

                        Nothing ->
                            ProfileHeading.usernameHeading author
                    ]
                ]


{-| `model.postAnimations`, sorted most-recent-first by `Posts.postTimestamp`'s
own "published\_at || created\_at" logic -- but only while `model.searchText`
is blank: an active text search's results come back relevance-ranked (see
`backend/src/rpcs/posts/get_posts.rs`'s `get_search_posts`), and re-sorting by
recency here would throw that ranking away. Mirrors
`Components.Pages.EventsPage.visibleAnimations`'s own identical search gate.
-}
postsListView : Shared.Model -> Model -> Html Msg
postsListView shared model =
    let
        sortedAnimations =
            model.postAnimations
                |> Dict.toList
                |> (if String.isEmpty (String.trim model.searchText) then
                        List.sortBy (\( _, anim ) -> -(Time.posixToMillis (Posts.postTimestamp anim.post)))

                    else
                        identity
                   )

        postsWord =
            case model.context of
                REPLY ->
                    "replies"

                _ ->
                    "posts"
    in
    if Dict.isEmpty model.postsByServer then
        p [ class "posts-empty" ] [ text <| "Connect to a server to see recent " ++ postsWord ++ "." ]

    else if List.isEmpty sortedAnimations then
        p [ class "posts-empty" ] [ text <| "No " ++ postsWord ++ " yet." ]

    else
        Html.Keyed.node "div"
            [ class "posts-list flip-animated-column" ]
            (List.map (postAnimationView shared) sortedAnimations)


{-| Wraps `Posts.postCard` in a fading/scaling/collapsing animated `<div>`
(see `syncAnimations`) -- the `.flip-collapsed` class (present while
`entering` or `removing`) is what makes `flip.css`'s `.flip-animated-item`
rules grow/shrink this wrapper's own height, which is what makes the _other_
posts slide smoothly into the space this one leaves/needs, on top of its own
fade -- see that rule's doc comment for how. The inner `div` is purely a clip
layer (`.flip-animated-item > *` in `flip.css`, invisible/borderless) so the
inter-post spacing it holds as `padding-bottom` can shrink away smoothly
along with everything else, rather than showing up inside `.post-card`'s own
border; it also carries `pointer-events: none` while `removing` so a
fading-out card (e.g. from a just-disabled server) can't be clicked/starred
while it's on its way out.
-}
postAnimationView : Shared.Model -> ( String, PostAnimation ) -> ( String, Html Msg )
postAnimationView shared ( key, anim ) =
    let
        pointerEventsAttr =
            if anim.flip.removing then
                [ style "pointer-events" "none" ]

            else
                []
    in
    ( key
    , div (UI.Flip.itemAttributes UI.Flip.Vertical anim.flip False)
        [ div pointerEventsAttr [ postCardView shared ( anim.host, anim.post ) ] ]
    )


postCardView : Shared.Model -> ( String, Post ) -> Html Msg
postCardView shared ( host, post ) =
    let
        displayPost =
            StarredPanel.freshestPost host post shared.starredPanel

        starred =
            StarredPanel.isStarred host displayPost shared.starredPanel

        onStarClicked =
            StarredPanel.toggleStarMsg shared.accountsPanel host displayPost
                |> Maybe.map (Shared.StarredPanelMsg >> SharedMsg)

        maybeServer =
            AccountsPanel.serverForHost shared.accountsPanel.servers host

        maybeAccount =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host

        onMediaClicked mediaId =
            SharedMsg (Shared.MediaViewerPanelMsg (MediaViewerPanel.Open displayPost mediaId host))
    in
    Posts.postCard shared.browserTimeZone shared.basePath shared.accountsPanel.mainFrontendHost host maybeServer maybeAccount onMediaClicked False False starred onStarClicked displayPost
