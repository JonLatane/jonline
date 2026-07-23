module Components.Pages.PostsPage exposing
    ( Model
    , Msg
    , fromShared
    , init
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
posts and adding this module's own "Posts | &lt;name&gt;" heading, via
`Components.Pages.UserProfilePage.nameHeader`), mirroring how
`Components.Pages.UserProfilePage` is reused by `Pages.Username_` and
`Pages.User.UserId_` themselves.
-}

import Animation
import Browser.Navigation
import Components.Pages.UserProfilePage as UserProfilePage
import Components.Posts as Posts
import Components.Users exposing (usernameHref)
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
import Shared.MediaViewerPanel as MediaViewerPanel
import Shared.StarredPostsPanel as StarredPostsPanel
import Task
import Time
import UI.Classes exposing (hostnameToCSSClass)
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
    , navKey : Browser.Navigation.Key
    , path : String
    , searchText : String
    , context : PostContext
    , searchGeneration : Int
    }


{-| `author`, if given, restricts the feed to that user's own posts (see
`Components.PostCard.fetchRecentPosts`) and adds a "Posts | &lt;name&gt;"
heading (see `view`) -- `Pages.Home_` passes `Nothing`,
`Pages.Username_.Posts`/`Pages.User.UserId_.Posts` pass their
already-resolved profile `User` paired with the host it was resolved from
(`Components.Users.Resolver`'s own `targetHost`, resolved before ever calling
this, so this module never needs to fetch the `User` itself -- it only needs
the host alongside it to look up that server's `AccountsPanel.Server`/signed-in
`Account` for `authorHeadingView`'s avatar).

`navKey`/`path`, from the calling page's own `Request`, are what let
`searchRowView`'s search box/context chooser persist `search_text`/`context`
as URL query params (see `pushSearchUrl`) without this module needing to know
which page-specific `Gen.Params.*` type that `Request` is actually parameterized
over -- every caller's `Request.key`/`Request.url.path` fit this regardless.
`query`, that same `Request`'s already-parsed `.query`, seeds `searchText`/
`context` back out of the URL on load, so a shared/reloaded link reproduces
the same search.

-}
init : Shared.Model -> Maybe ( String, User ) -> Browser.Navigation.Key -> String -> Dict String String -> ( Model, Effect Msg )
init shared author navKey path query =
    let
        ( fetchedModel, fetchEffect ) =
            fetchNewServers shared
                { postsByServer = Dict.empty
                , postAnimations = Dict.empty
                , author = author
                , navKey = navKey
                , path = path
                , searchText = Dict.get "search_text" query |> Maybe.withDefault ""
                , context = Dict.get "context" query |> Maybe.andThen postContextFromParam |> Maybe.withDefault POST
                , searchGeneration = 0
                }
    in
    ( fetchedModel, Effect.batch [ fetchEffect, setBreadcrumbsRoot shared fetchedModel ] )


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


{-| Fetches `serversToFetch` (marking each `Loading` first) using the current
`model.searchText`/`model.context`, and drops any already-fetched server
that's no longer `relevantServers` -- shared by `fetchNewServers` (which only
passes the servers that actually need it, see its own doc comment) and
`applySearchChange` (which always passes every relevant server, since a
changed search must re-fetch everything regardless of whether that server's
acting account also happens to have changed).
-}
refetchServers : Shared.Model -> Model -> List AccountsPanel.Server -> ( Model, Effect Msg )
refetchServers shared model serversToFetch =
    let
        enabledServers =
            relevantServers shared model

        currentAccountId server =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost
                |> Maybe.map AccountsPanel.accountId

        fetchEffect server =
            Posts.fetchPosts
                shared.accountsPanel
                ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost |> Maybe.map .userId
                , server.frontendHost
                )
                (model.author |> Maybe.map (Tuple.second >> .id))
                model.searchText
                model.context
                |> Task.attempt (GotServerPosts server.frontendHost)
                |> Effect.fromCmd

        prunedPostsByServer =
            Dict.filter (\host _ -> List.member host (List.map .frontendHost enabledServers)) model.postsByServer
    in
    ( { model
        | postsByServer =
            List.foldl
                (\server -> Dict.insert server.frontendHost { status = Loading, accountId = currentAccountId server })
                prunedPostsByServer
                serversToFetch
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
    ( refetchedModel, Effect.batch [ refetchEffect, pushSearchUrl refetchedModel ] )


{-| Keeps `Shared.Breadcrumbs` pointed at this feed's own root: `FromServerHost
mainFrontendHost` for an unfiltered feed (`model.author == Nothing`, e.g.
`Pages.Home_`), or `FromUser` the already-resolved author once one's known
(`Pages.Username_.Posts`/`Pages.User.UserId_.Posts`, which only ever call
`init` once their own `Resolver` has actually loaded the `User` -- see
`Pages.Username_.Posts.update`) -- mirrors
`Components.Pages.UserProfilePage.setBreadcrumbsHost`, reissued after every
`update`, a no-op once already in sync via the same equality check.
-}
setBreadcrumbsRoot : Shared.Model -> Model -> Effect Msg
setBreadcrumbsRoot shared model =
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


{-| Persists `model.searchText`/`model.context` to the URL as `search_text`/
`context` query params, via `replaceUrl` (not `pushUrl` -- editing the search
box shouldn't spam browser history with one entry per debounce fire).
Omitted entirely when at their defaults (blank search, `POST` context), so
the common case keeps a clean URL. Query-string-only navigation like this
doesn't re-trigger this page's `init` -- see `Main.elm`'s `ChangedUrl`
handler, which only does that when `url.path` itself changes.
-}
pushSearchUrl : Model -> Effect Msg
pushSearchUrl model =
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
    in
    Browser.Navigation.replaceUrl model.navKey (model.path ++ Url.Builder.toQuery (searchTextParam ++ contextParam))
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


{-| A freshly-seen post: starts invisible/slightly shrunk and immediately
animates in to its natural opacity/scale.
-}
newPostAnimation : String -> Post -> PostAnimation
newPostAnimation host post =
    { host = host, post = post, flip = UI.Flip.enter }


{-| A post that was mid fade-out (its server got disabled, then re-enabled --
or its feed got re-fetched -- before the fade-out finished) reappearing:
interrupts whatever fade-out step was queued (including its trailing
`RemovePost` send, so that message never fires for this key) and animates
back in.
-}
reappearingPostAnimation : String -> Post -> PostAnimation -> PostAnimation
reappearingPostAnimation host post anim =
    { anim | host = host, post = post, flip = UI.Flip.reappear anim.flip }


{-| A post no longer present in `postsByServer` (its server was disabled, or
its feed is being re-fetched under a different account): animates out, then
sends `RemovePost` to actually drop it from `postAnimations` once the fade
finishes.
-}
removingPostAnimation : String -> PostAnimation -> PostAnimation
removingPostAnimation key anim =
    { anim | flip = UI.Flip.remove (RemovePost key) anim.flip }


{-| Reconciles `postAnimations` with the posts currently `Loaded` in
`postsByServer`: starts a fade-in for newly-seen posts, a fade-out for posts
that dropped out (rather than deleting them outright), and un-interrupts a
still-fading-out post that reappeared. Safe/cheap to call after every
`postsByServer` change, so `update` just calls it unconditionally wherever
that dict might have changed.
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

        addOrRefresh key ( host, post ) animations =
            case Dict.get key animations of
                Nothing ->
                    Dict.insert key (newPostAnimation host post) animations

                Just anim ->
                    if anim.flip.removing then
                        Dict.insert key (reappearingPostAnimation host post anim) animations

                    else
                        Dict.insert key { anim | host = host, post = post } animations

        withCurrent =
            Dict.foldl addOrRefresh model.postAnimations currentPosts

        startRemovingIfGone key anim animations =
            if anim.flip.removing || Dict.member key currentPosts then
                animations

            else
                Dict.insert key (removingPostAnimation key anim) animations
    in
    { model | postAnimations = Dict.foldl startRemovingIfGone withCurrent withCurrent }



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


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
(see `Main.notifyPageOfSharedMsg`) into `update`'s `SharedMsg` branch, without
exposing the `SharedMsg` constructor itself (and thus every other constructor
of this otherwise-opaque `Msg`) outside this module.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg


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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every 30000 (\_ -> Poll)
        , UI.Flip.subscription Animate (List.map .flip (Dict.values model.postAnimations))
        ]



-- VIEW


view : Shared.Model -> Model -> Html Msg
view shared model =
    div []
        [ authorHeadingView shared model.author model.context
        , searchRowView model
        , postsListView shared model
        ]


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
                , placeholder "Search posts..."
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
`init` -- has actually rendered), upgraded to "Posts | &lt;name&gt;" via
`Components.Pages.UserProfilePage.nameHeader` (with that author's avatar, via
its resolved-host `AccountsPanel.Server`/signed-in `Account`, if that host is
still a known server -- falling back to `UserProfilePage.usernameHeading`,
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
                            UserProfilePage.nameHeader server (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host) author

                        Nothing ->
                            UserProfilePage.usernameHeading author
                    ]
                ]


postsListView : Shared.Model -> Model -> Html Msg
postsListView shared model =
    let
        sortedAnimations =
            model.postAnimations
                |> Dict.toList
                |> List.sortBy (\( _, anim ) -> -(Time.posixToMillis (Posts.postTimestamp anim.post)))
    in
    if Dict.isEmpty model.postsByServer then
        p [ class "posts-empty" ] [ text "Connect to a server to see recent posts." ]

    else if List.isEmpty sortedAnimations then
        p [ class "posts-empty" ] [ text "No posts yet." ]

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
            StarredPostsPanel.freshestPost host post shared.starredPostsPanel

        starred =
            StarredPostsPanel.isStarred host displayPost shared.starredPostsPanel

        onStarClicked =
            StarredPostsPanel.toggleStarMsg shared.accountsPanel host displayPost
                |> Maybe.map (Shared.StarredPostsPanelMsg >> SharedMsg)

        maybeServer =
            AccountsPanel.serverForHost shared.accountsPanel.servers host

        maybeAccount =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host

        onMediaClicked mediaId =
            SharedMsg (Shared.MediaViewerPanelMsg (MediaViewerPanel.Open displayPost mediaId host))
    in
    Posts.postCard shared.browserTimeZone shared.basePath shared.accountsPanel.mainFrontendHost host maybeServer maybeAccount onMediaClicked False False starred onStarClicked displayPost
