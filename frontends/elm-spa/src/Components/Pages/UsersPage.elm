module Components.Pages.UsersPage exposing
    ( Model
    , Msg
    , fromShared
    , init
    , subscriptions
    , update
    , view
    )

{-| The shared guts of a "list of users" page: fetching a `UserListingType`
listing of users and rendering them as `Components.Users.userCard`s -- reused
by `Pages.People` (which adds its own "People" heading and passes
`target = Nothing`, an unfiltered `EVERYONE` listing aggregated across every
enabled server, mirroring `Components.Pages.PostsPage`'s own aggregation for
`Pages.Home_`) and `Pages.Username_.{Following,Followers,Friends}`/
`Pages.User.UserId_.{Following,Followers,Friends}` (which pass the
already-resolved profile `User` paired with the host it was resolved from and
the relevant `UserListingType`, restricting the listing to that user's own
relationship, fetched from just that one host -- see `candidateServers` --
and adding a "Following | &lt;name&gt;"-style heading), mirroring
`Components.Pages.PostsPage`'s own `author` parameter and reuse by
`Pages.Username_.Posts`/`Pages.User.UserId_.Posts`.

Like `PostsPage`, cards fade/scale in and out (see `UserAnimation`) as users
appear/disappear from the listing -- e.g. a search that narrows the results,
or a server being disabled -- via `UI.Flip`.

-}

import Animation
import Browser.Navigation
import Components.Pages.UserProfilePage as UserProfilePage
import Components.Users as Users
import Components.Users.FollowStatusAndButton as FollowStatusAndButton
import Dict exposing (Dict)
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, a, button, div, h2, input, p, text)
import Html.Attributes exposing (class, href, placeholder, style, title, type_, value)
import Html.Events exposing (onClick, onInput, preventDefaultOn)
import Html.Keyed
import Json.Decode as Decode
import Process
import Proto.Jonline exposing (GetUsersResponse, User)
import Proto.Jonline.UserListingType exposing (UserListingType(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.Breadcrumbs as Breadcrumbs
import Task
import Time
import UI.Classes exposing (hostnameToCSSClass)
import UI.Flip
import Url.Builder



-- MODEL


type ServerUsers
    = Loading
    | Loaded (List User)
    | Failed


{-| `accountId` is the enabled account (if any) the users were/are being
fetched with, so a later account enable/disable on the same server can be
detected as "the acting credential changed" and trigger a re-fetch -- same
convention as `Components.Pages.PostsPage.ServerFeed`.
-}
type alias ServerFeed =
    { status : ServerUsers
    , accountId : Maybe String
    }


{-| A user card's fade in/out state, keyed in `userAnimations` by
`followStatusAndButtonKey` (the same host+id key `followStatusAndButtons`
already uses -- both dicts identify a card the same way, so there's no need
for a second key convention) so it survives independently of `usersByServer`
-- a server being disabled (or re-fetched under a different account, or a
search narrowing the results) drops/replaces its users in `usersByServer`
immediately, but a `removing` `flip` entry here keeps rendering its
last-known `user`/`host` until its fade-out finishes, instead of the card
just vanishing. Mirrors `Components.Pages.PostsPage.PostAnimation` exactly --
see `UI.Flip` for what `flip` itself drives.
-}
type alias UserAnimation =
    { host : String
    , user : User
    , flip : UI.Flip.State Msg
    }


type alias Model =
    { usersByServer : Dict String ServerFeed
    , userAnimations : Dict String UserAnimation

    -- The user + host + listing type to restrict the listing to, if any --
    -- `Nothing` for `Pages.People`'s unfiltered `EVERYONE` listing.
    , target : Maybe ( String, User, UserListingType )

    -- One `FollowStatusAndButton.Model` per card (see `followStatusAndButtonKey`)
    -- -- missing entries (i.e. every card whose button hasn't been clicked
    -- yet) are treated as `FollowStatusAndButton.init`, same "absent means
    -- default" convention as `Components.Pages.PostsPage`'s per-post state.
    , followStatusAndButtons : Dict String FollowStatusAndButton.Model
    , navKey : Browser.Navigation.Key
    , path : String
    , searchText : String
    , searchGeneration : Int
    }


{-| `navKey`/`path`, from the calling page's own `Request`, are what let
`searchRowView`'s search box persist `search_text` as a URL query param (see
`pushSearchUrl`) without this module needing to know which page-specific
`Gen.Params.*` type that `Request` is actually parameterized over -- mirrors
`Components.Pages.PostsPage.init` exactly, just without a context param (there
being no `Users` equivalent of `PostContext` to choose between). `query`,
that same `Request`'s already-parsed `.query`, seeds `searchText` back out of
the URL on load, so a shared/reloaded link reproduces the same search.
-}
init : Shared.Model -> Maybe ( String, User, UserListingType ) -> Browser.Navigation.Key -> String -> Dict String String -> ( Model, Effect Msg )
init shared target navKey path query =
    let
        ( fetchedModel, fetchEffect ) =
            fetchNewServers shared
                { usersByServer = Dict.empty
                , userAnimations = Dict.empty
                , target = target
                , followStatusAndButtons = Dict.empty
                , navKey = navKey
                , path = path
                , searchText = Dict.get "search_text" query |> Maybe.withDefault ""
                , searchGeneration = 0
                }
    in
    ( fetchedModel, Effect.batch [ fetchEffect, setBreadcrumbsRoot shared fetchedModel ] )


{-| Which servers this listing should ever fetch from: every enabled server,
aggregated together, when there's no `target` (`Pages.People`'s unfiltered
`EVERYONE` listing, mirroring `Components.Pages.PostsPage.fetchNewServers`'s
own aggregation for `Pages.Home_`) -- but just `target`'s own host, alone,
once there is one (`Pages.Username_.{Following,Followers,Friends}`/
`Pages.User.UserId_.{Following,Followers,Friends}`), since a user's
relationships only ever live on the one server that user themself is on;
querying every other enabled server too would be pointless (nothing there
could ever match that id) and misleadingly implies the listing is itself
federated when it isn't. Not gated on `.enabled` (unlike `enabledServers`) --
mirrors `Components.Users.Resolver.fetchTask`'s own plain `serverForHost`
check, since a profile page's own relationship listings should keep working
off of whichever server that profile was actually resolved from, regardless
of whether the viewer happens to have it "enabled" for aggregation elsewhere.
-}
candidateServers : Shared.Model -> Model -> List AccountsPanel.Server
candidateServers shared model =
    case model.target of
        Nothing ->
            AccountsPanel.enabledServers shared.accountsPanel

        Just ( host, _, _ ) ->
            AccountsPanel.serverForHost shared.accountsPanel.servers host
                |> Maybe.map List.singleton
                |> Maybe.withDefault []


{-| The `GetUsers` fetch (as an `Effect`, ready to batch/return directly) for
one `server` -- shared by `fetchNewServers` (kicked off for every server that
needs a fresh fetch) and `update`'s own `FollowStatusAndButtonMsg` branch
(kicked off unconditionally for just one server, once a `FollowStatusAndButton`
action against one of its listed users succeeds).
-}
fetchServerEffect : Shared.Model -> Model -> AccountsPanel.Server -> Effect Msg
fetchServerEffect shared model server =
    Users.fetchUserListing
        shared.accountsPanel
        ( AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost |> Maybe.map .userId
        , server.frontendHost
        )
        (model.target |> Maybe.map (\( _, user, _ ) -> user.id))
        (model.target |> Maybe.map (\( _, _, listingType ) -> listingType) |> Maybe.withDefault EVERYONE)
        model.searchText
        |> Task.attempt (GotServerUsers server.frontendHost)
        |> Effect.fromCmd


{-| Fetches `serversToFetch` (marking each `Loading` first) using the current
`model.searchText`, and drops any already-fetched server that's no longer a
`candidateServers` member -- shared by `fetchNewServers` (which only passes
the servers that actually need it) and `applySearchChange` (which always
passes every `candidateServers` member, since a changed search must re-fetch
everything regardless of whether that server's acting account also happens to
have changed) -- mirrors `Components.Pages.PostsPage.refetchServers` exactly.
-}
refetchServers : Shared.Model -> Model -> List AccountsPanel.Server -> ( Model, Effect Msg )
refetchServers shared model serversToFetch =
    let
        servers =
            candidateServers shared model

        currentAccountId server =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost
                |> Maybe.map AccountsPanel.accountId

        fetchEffect server =
            fetchServerEffect shared model server

        prunedUsersByServer =
            Dict.filter (\host _ -> List.member host (List.map .frontendHost servers)) model.usersByServer
    in
    ( { model
        | usersByServer =
            List.foldl
                (\server -> Dict.insert server.frontendHost { status = Loading, accountId = currentAccountId server })
                prunedUsersByServer
                serversToFetch
      }
    , Effect.batch (List.map fetchEffect serversToFetch)
    )
        |> Tuple.mapFirst syncAnimations


{-| See `Components.Pages.PostsPage.fetchNewServers`'s doc comment -- same
drop-stale-servers/re-fetch-on-account-change/poll-fallback approach, just
against `GetUsers` instead of `GetPosts`, and scoped to `candidateServers`
rather than unconditionally every enabled server.
-}
fetchNewServers : Shared.Model -> Model -> ( Model, Effect Msg )
fetchNewServers shared model =
    let
        servers =
            candidateServers shared model

        currentAccountId server =
            AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts server.frontendHost
                |> Maybe.map AccountsPanel.accountId

        serversToFetch =
            servers
                |> List.filter
                    (\server ->
                        case Dict.get server.frontendHost model.usersByServer of
                            Nothing ->
                                True

                            Just feed ->
                                feed.accountId /= currentAccountId server
                    )
    in
    refetchServers shared model serversToFetch


{-| Re-fetches every `candidateServers` member (unconditionally -- unlike
`fetchNewServers`, a changed search has to override every already-Loaded
feed, not just servers whose acting account changed) and persists the new
`search_text` to the URL -- the single path `SearchDebounceElapsed` and
`ClearSearchClicked` both funnel through. Mirrors
`Components.Pages.PostsPage.applySearchChange` exactly.
-}
applySearchChange : Shared.Model -> Model -> ( Model, Effect Msg )
applySearchChange shared model =
    let
        ( refetchedModel, refetchEffect ) =
            refetchServers shared model (candidateServers shared model)
    in
    ( refetchedModel, Effect.batch [ refetchEffect, pushSearchUrl refetchedModel ] )


{-| Keeps `Shared.Breadcrumbs` pointed at this listing's own root:
`FromServerHost mainFrontendHost` for `Pages.People`'s unfiltered listing
(`model.target == Nothing`), or `FromUser` the already-resolved `target` user
once there is one (`Pages.Username_.{Following,Followers,Friends}`/
`Pages.User.UserId_.{Following,Followers,Friends}`) -- mirrors
`Components.Pages.PostsPage.setBreadcrumbsRoot` exactly, just keyed off
`target`'s `User` instead of `author`'s, reissued after every `update`, a
no-op once already in sync via the same equality check.
-}
setBreadcrumbsRoot : Shared.Model -> Model -> Effect Msg
setBreadcrumbsRoot shared model =
    let
        ( root, host ) =
            case model.target of
                Just ( targetHost, user, _ ) ->
                    ( Breadcrumbs.FromUser user, targetHost )

                Nothing ->
                    ( Breadcrumbs.FromServerHost shared.accountsPanel.mainFrontendHost, shared.accountsPanel.mainFrontendHost )
    in
    if shared.breadcrumbs.root == Just root then
        Effect.none

    else
        Effect.fromShared (Shared.BreadcrumbsMsg (Breadcrumbs.SetRoot root host []))


{-| Persists `model.searchText` to the URL as a `search_text` query param, via
`replaceUrl` (not `pushUrl` -- editing the search box shouldn't spam browser
history with one entry per debounce fire). Omitted entirely when blank, so
the common case keeps a clean URL. Mirrors
`Components.Pages.PostsPage.pushSearchUrl`, just without a `context` param.
-}
pushSearchUrl : Model -> Effect Msg
pushSearchUrl model =
    let
        searchTextParam =
            if String.isEmpty (String.trim model.searchText) then
                []

            else
                [ Url.Builder.string "search_text" model.searchText ]
    in
    Browser.Navigation.replaceUrl model.navKey (model.path ++ Url.Builder.toQuery searchTextParam)
        |> Effect.fromCmd



-- ANIMATION


{-| Reconciles `userAnimations` with the users currently `Loaded` in
`usersByServer`: starts a fade-in for newly-seen users, a fade-out for users
that dropped out (rather than deleting them outright), and un-interrupts a
still-fading-out card that reappeared. Safe/cheap to call after every
`usersByServer` change, so `update`/`refetchServers` just call it
unconditionally wherever that dict might have changed. `RemoveUser` is what
actually drops a gone user's animation entry once its fade-out finishes. See
`UI.Flip.syncAnimations` for the shared reconciliation logic this hands its
own `UserAnimation` shape to (mirrored by `Components.Pages.PostsPage.syncAnimations`).
-}
syncAnimations : Model -> Model
syncAnimations model =
    let
        currentUsers : Dict String ( String, User )
        currentUsers =
            model.usersByServer
                |> Dict.toList
                |> List.concatMap
                    (\( host, feed ) ->
                        case feed.status of
                            Loaded users ->
                                List.map (\user -> ( followStatusAndButtonKey host user, ( host, user ) )) users

                            _ ->
                                []
                    )
                |> Dict.fromList
    in
    { model
        | userAnimations =
            UI.Flip.syncAnimations
                RemoveUser
                (\( host, user ) -> { host = host, user = user, flip = UI.Flip.enter })
                (\( host, user ) anim -> { anim | host = host, user = user })
                currentUsers
                model.userAnimations
    }



-- UPDATE


type Msg
    = GotServerUsers String (Result Grpc.Error ( Maybe AccountsPanel.Msg, GetUsersResponse ))
    | Poll
    | Animate Animation.Msg
    | RemoveUser String
    | SharedMsg Shared.Msg
    | FollowStatusAndButtonMsg String FollowStatusAndButton.Msg
    | SearchTextChanged String
    | SearchDebounceElapsed Int
    | ClearSearchClicked


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page
(see `Main.notifyPageOfSharedMsg`) into `update`'s `SharedMsg` branch, without
exposing the `SharedMsg` constructor itself -- mirrors
`Components.Pages.PostsPage.fromShared`.
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
        GotServerUsers frontendHost (Ok ( maybeAccountsPanelMsg, response )) ->
            let
                accountEffect =
                    maybeAccountsPanelMsg
                        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
                        |> Maybe.withDefault Effect.none
            in
            ( { model
                | usersByServer =
                    Dict.update frontendHost
                        (Maybe.map (\feed -> { feed | status = Loaded response.users }))
                        model.usersByServer
              }
                |> syncAnimations
            , accountEffect
            )

        GotServerUsers frontendHost (Err _) ->
            ( { model
                | usersByServer =
                    Dict.update frontendHost (Maybe.map (\feed -> { feed | status = Failed })) model.usersByServer
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
                    Dict.foldl step ( Dict.empty, [] ) model.userAnimations
            in
            ( { model | userAnimations = newAnimations }, Effect.batch (List.map Effect.fromCmd cmds) )

        RemoveUser key ->
            ( { model | userAnimations = Dict.remove key model.userAnimations }, Effect.none )

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

        FollowStatusAndButtonMsg key subMsg ->
            case findUserForKey shared model key of
                Just ( server, account, user ) ->
                    let
                        ( newFollowStatusAndButton, followEffect ) =
                            FollowStatusAndButton.update shared
                                server
                                account
                                user
                                subMsg
                                (Dict.get key model.followStatusAndButtons |> Maybe.withDefault FollowStatusAndButton.init)

                        newModel =
                            { model | followStatusAndButtons = Dict.insert key newFollowStatusAndButton model.followStatusAndButtons }

                        mappedFollowEffect =
                            Effect.map (FollowStatusAndButtonMsg key) followEffect
                    in
                    case subMsg of
                        FollowStatusAndButton.GotFollowResult (Ok _) ->
                            ( newModel, Effect.batch [ mappedFollowEffect, fetchServerEffect shared newModel server ] )

                        FollowStatusAndButton.GotUnfollowResult (Ok _) ->
                            ( newModel, Effect.batch [ mappedFollowEffect, fetchServerEffect shared newModel server ] )

                        FollowStatusAndButton.GotModerationResult (Ok _) ->
                            ( newModel, Effect.batch [ mappedFollowEffect, fetchServerEffect shared newModel server ] )

                        _ ->
                            ( newModel, mappedFollowEffect )

                Nothing ->
                    ( model, Effect.none )

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
                -- A later edit (or ClearSearchClicked) already bumped searchGeneration past this
                -- timer's -- it's stale, ignore it.
                ( model, Effect.none )

        ClearSearchClicked ->
            applySearchChange shared { model | searchText = "", searchGeneration = model.searchGeneration + 1 }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every 30000 (\_ -> Poll)
        , UI.Flip.subscription Animate (List.map .flip (Dict.values model.userAnimations))
        ]



-- VIEW


view : Shared.Model -> Model -> Html Msg
view shared model =
    div []
        [ targetHeadingView shared model.target
        , searchRowView model
        , usersListView shared model
        ]


{-| Search box (debounced, see `SearchTextChanged`/`SearchDebounceElapsed`) --
mirrors `Components.Pages.PostsPage.searchRowView`, just without a context
chooser (there's no `Users` equivalent of `PostContext` to pick between), and
reusing that same module's `.posts-search-row`/`.posts-search-field`/
`.posts-search-input`/`.field-clear-button` CSS classes -- already shared
across Posts/Users pages (see `targetHeadingView`'s own reuse of
`.posts-page-heading` below), so no new CSS is needed here.
-}
searchRowView : Model -> Html Msg
searchRowView model =
    div [ class "posts-search-row" ]
        [ div [ class "posts-search-field" ]
            [ input
                [ type_ "text"
                , class "posts-search-input"
                , placeholder "Search people..."
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
        ]


{-| Fires `msg` (and suppresses the key's default effect) when Escape is
pressed in a text input -- mirrors `Components.Pages.PostsPage.onEscape`.
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


{-| "Following"/"Followers"/"Friends" alone once there's a `target` to filter
by (even before that `User` -- already resolved by the caller, see `init` --
has actually rendered), upgraded to e.g. "Following | &lt;name&gt;" via
`Components.Pages.UserProfilePage.nameHeader` -- absent entirely for
`Pages.People`'s unfiltered listing (`target == Nothing`), which supplies its
own "People" heading instead. Mirrors
`Components.Pages.PostsPage.authorHeadingView` exactly.
-}
targetHeadingView : Shared.Model -> Maybe ( String, User, UserListingType ) -> Html Msg
targetHeadingView shared maybeTarget =
    case maybeTarget of
        Nothing ->
            text ""

        Just ( host, targetUser, listingType ) ->
            let
                profileUrl =
                    Users.usernameHref "" shared.accountsPanel.mainFrontendHost host targetUser.username
            in
            div [ class "posts-page-heading" ]
                [ h2 [] [ text (listingTypeHeading listingType) ]
                , a [ href profileUrl, class <| hostnameToCSSClass host ]
                    [ case AccountsPanel.serverForHost shared.accountsPanel.servers host of
                        Just server ->
                            UserProfilePage.nameHeader server (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host) targetUser

                        Nothing ->
                            UserProfilePage.usernameHeading targetUser
                    ]
                ]


listingTypeHeading : UserListingType -> String
listingTypeHeading listingType =
    case listingType of
        FOLLOWING ->
            "Following"

        FOLLOWERS ->
            "Followers"

        FRIENDS ->
            "Friends"

        _ ->
            "People"


usersListView : Shared.Model -> Model -> Html Msg
usersListView shared model =
    let
        sortedAnimations =
            model.userAnimations
                |> Dict.toList
                |> List.sortBy (\( _, anim ) -> String.toLower anim.user.username)
    in
    if Dict.isEmpty model.usersByServer then
        p [ class "posts-empty" ] [ text "Connect to a server to see people." ]

    else if List.isEmpty sortedAnimations then
        p [ class "posts-empty" ] [ text "No people yet." ]

    else
        Html.Keyed.node "div"
            [ class "users-list flip-animated-column" ]
            (List.map (userAnimationView shared model) sortedAnimations)


{-| Wraps `userCardView` in a fading/scaling/collapsing animated `<div>` (see
`syncAnimations`) -- mirrors `Components.Pages.PostsPage.postAnimationView`
exactly, including the inner clip `div`'s `pointer-events: none` while
`removing`, so a fading-out card can't be clicked/followed while it's on its
way out.
-}
userAnimationView : Shared.Model -> Model -> ( String, UserAnimation ) -> ( String, Html Msg )
userAnimationView shared model ( key, anim ) =
    let
        pointerEventsAttr =
            if anim.flip.removing then
                [ style "pointer-events" "none" ]

            else
                []
    in
    ( key
    , div (UI.Flip.itemAttributes UI.Flip.Vertical anim.flip False)
        [ div pointerEventsAttr [ userCardView shared model ( anim.host, anim.user ) ] ]
    )


userCardView : Shared.Model -> Model -> ( String, User ) -> Html Msg
userCardView shared model ( host, user ) =
    case AccountsPanel.serverForHost shared.accountsPanel.servers host of
        Just server ->
            let
                key =
                    followStatusAndButtonKey host user

                followStatusAndButtonModel =
                    Dict.get key model.followStatusAndButtons |> Maybe.withDefault FollowStatusAndButton.init

                maybeAccount =
                    AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host
            in
            Users.userCard shared.basePath
                shared.accountsPanel.mainFrontendHost
                server
                maybeAccount
                (Html.map (FollowStatusAndButtonMsg key) (FollowStatusAndButton.view followStatusAndButtonModel maybeAccount user))
                user

        Nothing ->
            text ""


{-| Identifies one card's `FollowStatusAndButton.Model` in
`model.followStatusAndButtons` -- a `User.id` alone isn't unique across every
listed server (see `Components.Users.Resolver`'s own by-id/by-username
`Lookup`, federated ids aren't globally unique either), so `host` disambiguates,
mirroring `Components.Pages.UserProfilePage.federatedKey`.
-}
followStatusAndButtonKey : String -> User -> String
followStatusAndButtonKey host user =
    user.id ++ "@" ++ host


{-| The `AccountsPanel.Server`/signed-in `AccountsPanel.Account`/`User` a
`FollowStatusAndButtonMsg key` refers to -- looked up fresh out of
`model.usersByServer` each time (rather than carried in the `Msg` itself),
since the `User` a `Follow` action needs is whatever's currently loaded, not
a stale snapshot from whenever the button was rendered.
-}
findUserForKey : Shared.Model -> Model -> String -> Maybe ( AccountsPanel.Server, AccountsPanel.Account, User )
findUserForKey shared model key =
    model.usersByServer
        |> Dict.toList
        |> List.concatMap
            (\( host, feed ) ->
                case feed.status of
                    Loaded users ->
                        users
                            |> List.filter (\user -> followStatusAndButtonKey host user == key)
                            |> List.map (\user -> ( host, user ))

                    _ ->
                        []
            )
        |> List.head
        |> Maybe.andThen
            (\( host, user ) ->
                Maybe.map2 (\server account -> ( server, account, user ))
                    (AccountsPanel.serverForHost shared.accountsPanel.servers host)
                    (AccountsPanel.enabledAccountForServer shared.accountsPanel.accounts host)
            )
