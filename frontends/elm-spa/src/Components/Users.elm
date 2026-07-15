module Components.Users exposing
    ( authorAvatarUrl
    , avatarUrl
    , displayName
    , fetchUserById
    , fetchUserByUsername
    , formatDate
    , isAdminUser
    , isReservedUsername
    , moderationText
    , parseUserRouteId
    , permissionText
    , profileHref
    , titleName
    , userIdHref
    , usernameHref
    , visibilityText
    )

{-| Shared building blocks for displaying `Proto.Jonline.User`s -- the fetch
helpers both profile routes (`Pages.User.UserId_`, by id; `Pages.Username_`, by
username) need against a specific `Shared.AccountsPanel.Server`, the
`/user/:id[@host]`/`/:username[@host]` route id parsing/linking (mirroring
`Components.Posts`' `postHref`/`parsePostRouteId` for `/post/:id[@host]`), and
plain-English labels for a `User`'s `Visibility`/`Moderation`/`Permission`
fields.
-}

import Gen.Route
import Grpc
import Proto.Jonline exposing (Author, GetUsersResponse, User, defaultGetUsersRequest)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.Moderation exposing (Moderation(..))
import Proto.Jonline.Permission exposing (Permission(..))
import Proto.Jonline.Visibility exposing (Visibility(..))
import Set exposing (Set)
import Shared.AccountsPanel as AccountsPanel
import Shared.MaybeAccountRequest as MaybeAccountRequest
import Task exposing (Task)
import Time


{-| Fetches the user with `userId` from `server`, authenticated as
`maybeAccount` if given, anonymous otherwise -- see
`Shared.MaybeAccountRequest.perform`. Returns `maybeAccount` back (refreshed,
if it needed to be), same as `Components.Posts.fetchPost`.
-}
fetchUserById :
    AccountsPanel.Server
    -> Maybe AccountsPanel.Account
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Account, GetUsersResponse )
fetchUserById server maybeAccount userId =
    fetchUsers server maybeAccount { defaultGetUsersRequest | userId = Just userId }


{-| Like `fetchUserById`, but looks the user up by (exact) `username` instead.
-}
fetchUserByUsername :
    AccountsPanel.Server
    -> Maybe AccountsPanel.Account
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Account, GetUsersResponse )
fetchUserByUsername server maybeAccount username =
    fetchUsers server maybeAccount { defaultGetUsersRequest | username = Just username }


fetchUsers :
    AccountsPanel.Server
    -> Maybe AccountsPanel.Account
    -> Proto.Jonline.GetUsersRequest
    -> Task Grpc.Error ( Maybe AccountsPanel.Account, GetUsersResponse )
fetchUsers server maybeAccount request =
    MaybeAccountRequest.perform
        (connectionOf server)
        maybeAccount
        (\maybeToken ->
            Grpc.new Jonline.getUsers request
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAuth maybeToken
                |> Grpc.toTask
        )


connectionOf : AccountsPanel.Server -> { host : String, port_ : Int, tls : Bool }
connectionOf server =
    { host = server.backendHost, port_ = server.port_, tls = server.tls }


withAuth : Maybe String -> Grpc.RpcRequest req res -> Grpc.RpcRequest req res
withAuth maybeToken req =
    case maybeToken of
        Just token ->
            Grpc.addHeader "authorization" token req

        Nothing ->
            req



-- ROUTE / LINKS


{-| Usernames that can't be routed to via `/:username[@host]` since they'd
collide with this app's own top-level routes (`Pages.About`, elm-spa's builtin
`not-found`) or the `/user`/`/post` prefixes themselves -- e.g. a user named
"about" is only ever reachable via `/user/:id[@host]`, never `/about[@host]`.
Compared case-insensitively, since the collision is with the URL segment, not
the display name.
-}
reservedUsernames : Set String
reservedUsernames =
    Set.fromList [ "about", "not-found", "user", "post" ]


isReservedUsername : String -> Bool
isReservedUsername username =
    Set.member (String.toLower (String.trim username)) reservedUsernames


{-| The `/user/:id[@host]` href for a user, as seen from `viewingServerHost`
(typically `shared.accountsPanel.mainFrontendHost`) -- mirrors
`Components.Posts.postHref`.
-}
userIdHref : String -> String -> String -> String -> String
userIdHref basePath viewingServerHost userServerHost userId =
    basePath ++ Gen.Route.toHref (Gen.Route.User__UserId_ { userId = withHostSuffix viewingServerHost userServerHost userId })


{-| The `/:username[@host]` href for a user -- only meaningful when
`username` isn't reserved (see `isReservedUsername`); prefer `profileHref`
where the username might not be usable.
-}
usernameHref : String -> String -> String -> String -> String
usernameHref basePath viewingServerHost userServerHost username =
    basePath ++ Gen.Route.toHref (Gen.Route.Username_ { username = withHostSuffix viewingServerHost userServerHost username })


{-| The best available profile link for a user: their `/:username[@host]`
route if they have one that's actually routable (non-empty, not reserved --
see `isReservedUsername`), falling back to the always-routable
`/user/:id[@host]` otherwise.
-}
profileHref : String -> String -> String -> { userId : String, username : String } -> String
profileHref basePath viewingServerHost userServerHost user =
    if String.isEmpty (String.trim user.username) || isReservedUsername user.username then
        userIdHref basePath viewingServerHost userServerHost user.userId

    else
        usernameHref basePath viewingServerHost userServerHost user.username


withHostSuffix : String -> String -> String -> String
withHostSuffix viewingServerHost userServerHost id =
    if userServerHost == viewingServerHost then
        id

    else
        id ++ "@" ++ userServerHost


{-| The inverse of `withHostSuffix`: `rawId` is either a bare id/username (a
user on `mainFrontendHost`) or `id@host`/`username@host` (a user on some other,
federated server) -- mirrors `Components.Posts.parsePostRouteId`.
-}
parseUserRouteId : String -> String -> ( String, String )
parseUserRouteId mainFrontendHost rawId =
    case String.split "@" rawId of
        [ id, host ] ->
            ( id, host )

        _ ->
            ( rawId, mainFrontendHost )



-- DISPLAY


{-| A username display enriched with the user's Real Name, if they have one --
mirrors `Shared.AccountsPanel.displayName`.
-}
displayName : User -> String
displayName user =
    if String.isEmpty (String.trim user.realName) then
        user.username

    else
        user.realName ++ " (" ++ user.username ++ ")"


{-| A user's Real Name, if they have one, otherwise just their username --
unlike `displayName`, never both at once, since this is for contexts (e.g. a
browser tab title) too terse for the parenthetical.
-}
titleName : User -> String
titleName user =
    if String.isEmpty (String.trim user.realName) then
        user.username

    else
        user.realName


{-| The URL for a user's avatar, authorized with `maybeAccount`'s access token
if given -- avatars can be visibility-restricted, so an anonymous request (or
one from an account that isn't allowed to see it) may still 403 despite this
returning `Just` a URL. Mirrors `Shared.AccountsPanel.accountAvatarUrl`.
-}
avatarUrl : AccountsPanel.Server -> Maybe AccountsPanel.Account -> User -> Maybe String
avatarUrl server maybeAccount user =
    mediaReferenceUrl server maybeAccount user.avatar


{-| Like `avatarUrl`, but for an `Author` (the smaller, post-embedded version
of a `User` -- see `Components.Posts.postAuthorHref`) instead of a full `User`.
-}
authorAvatarUrl : AccountsPanel.Server -> Maybe AccountsPanel.Account -> Author -> Maybe String
authorAvatarUrl server maybeAccount author =
    mediaReferenceUrl server maybeAccount author.avatar


mediaReferenceUrl : AccountsPanel.Server -> Maybe AccountsPanel.Account -> Maybe Proto.Jonline.MediaReference -> Maybe String
mediaReferenceUrl server maybeAccount maybeMedia =
    maybeMedia
        |> Maybe.map
            (\media ->
                let
                    base =
                        AccountsPanel.mediaUrl server media.id
                in
                case maybeAccount of
                    Just account ->
                        base ++ "?authorization=" ++ account.accessToken.token

                    Nothing ->
                        base
            )


isAdminUser : User -> Bool
isAdminUser user =
    List.member ADMIN user.permissions


{-| Display text for a User's visibility -- mirrors
`Components.Posts.postVisibilityText`, which is Post-specific.
-}
visibilityText : Visibility -> String
visibilityText visibility =
    case visibility of
        PRIVATE ->
            "Private"

        LIMITED ->
            "Limited"

        SERVERPUBLIC ->
            "Server Public"

        GLOBALPUBLIC ->
            "Global Public"

        DIRECT ->
            "Direct"

        VISIBILITYUNKNOWN ->
            "Unknown"

        VisibilityUnrecognized_ _ ->
            "Unknown"


moderationText : Moderation -> String
moderationText moderation =
    case moderation of
        UNMODERATED ->
            "Unmoderated"

        PENDING ->
            "Pending"

        APPROVED ->
            "Approved"

        REJECTED ->
            "Rejected"

        MODERATIONUNKNOWN ->
            "Unknown"

        ModerationUnrecognized_ _ ->
            "Unknown"


{-| A plain-English label for a `Permission` -- e.g. for a profile's
permissions list. Order matches `permissions.proto`.
-}
permissionText : Permission -> String
permissionText permission =
    case permission of
        PERMISSIONUNKNOWN ->
            "Unknown"

        VIEWUSERS ->
            "View Users"

        PUBLISHUSERSLOCALLY ->
            "Publish Users Locally"

        PUBLISHUSERSGLOBALLY ->
            "Publish Users Globally"

        MODERATEUSERS ->
            "Moderate Users"

        FOLLOWUSERS ->
            "Follow Users"

        GRANTBASICPERMISSIONS ->
            "Grant Basic Permissions"

        VIEWGROUPS ->
            "View Groups"

        CREATEGROUPS ->
            "Create Groups"

        PUBLISHGROUPSLOCALLY ->
            "Publish Groups Locally"

        PUBLISHGROUPSGLOBALLY ->
            "Publish Groups Globally"

        MODERATEGROUPS ->
            "Moderate Groups"

        JOINGROUPS ->
            "Join Groups"

        INVITEGROUPMEMBERS ->
            "Invite Group Members"

        VIEWPOSTS ->
            "View Posts"

        CREATEPOSTS ->
            "Create Posts"

        PUBLISHPOSTSLOCALLY ->
            "Publish Posts Locally"

        PUBLISHPOSTSGLOBALLY ->
            "Publish Posts Globally"

        MODERATEPOSTS ->
            "Moderate Posts"

        REPLYTOPOSTS ->
            "Reply To Posts"

        VIEWEVENTS ->
            "View Events"

        CREATEEVENTS ->
            "Create Events"

        PUBLISHEVENTSLOCALLY ->
            "Publish Events Locally"

        PUBLISHEVENTSGLOBALLY ->
            "Publish Events Globally"

        MODERATEEVENTS ->
            "Moderate Events"

        RSVPTOEVENTS ->
            "RSVP To Events"

        VIEWMEDIA ->
            "View Media"

        CREATEMEDIA ->
            "Create Media"

        PUBLISHMEDIALOCALLY ->
            "Publish Media Locally"

        PUBLISHMEDIAGLOBALLY ->
            "Publish Media Globally"

        MODERATEMEDIA ->
            "Moderate Media"

        BUSINESS ->
            "Business"

        RUNBOTS ->
            "Run Bots"

        ADMIN ->
            "Admin"

        VIEWPRIVATECONTACTMETHODS ->
            "View Private Contact Methods"

        PermissionUnrecognized_ _ ->
            "Unknown"


{-| A plain `YYYY-MM-DD` rendering (UTC) of a timestamp -- e.g. a profile's
"Joined" date. No existing date-formatting helper/locale infrastructure exists
in this app yet, so this keeps things simple rather than introducing one.
-}
formatDate : Time.Posix -> String
formatDate time =
    let
        pad2 n =
            String.padLeft 2 '0' (String.fromInt n)
    in
    String.fromInt (Time.toYear Time.utc time)
        ++ "-"
        ++ pad2 (monthNumber (Time.toMonth Time.utc time))
        ++ "-"
        ++ pad2 (Time.toDay Time.utc time)


monthNumber : Time.Month -> Int
monthNumber month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12
