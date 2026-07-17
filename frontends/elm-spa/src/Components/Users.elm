module Components.Users exposing
    ( allPermissions
    , authorAvatarUrl
    , avatarUrl
    , defederateProfile
    , displayName
    , federateProfile
    , fetchUserById
    , fetchUserByUsername
    , isAdminUser
    , isReservedUsername
    , moderationText
    , parseUserRouteId
    , permissionFromText
    , permissionText
    , profileHref
    , titleName
    , updateUser
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
import Proto.Google.Protobuf
import Proto.Jonline exposing (Author, FederatedAccount, GetUsersResponse, User, defaultGetUsersRequest)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.Moderation exposing (Moderation(..))
import Proto.Jonline.Permission exposing (Permission(..))
import Proto.Jonline.Visibility exposing (Visibility(..))
import Set exposing (Set)
import Shared.AccountsPanel as AccountsPanel exposing (performWithAccountServer, performWithOptionalAccountServer, withAccessToken)
import Task exposing (Task)


{-| Fetches the user with `userId` from `maybeAccountServer`'s server,
authenticated as its account if any, anonymous otherwise. Returns a `Msg` to
dispatch if a token refresh happened, same convention as
`Components.PostCard.fetchPost`.
-}
fetchUserById :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetUsersResponse )
fetchUserById accountsPanelModel maybeAccountServer userId =
    fetchUsers accountsPanelModel maybeAccountServer { defaultGetUsersRequest | userId = Just userId }


{-| Like `fetchUserById`, but looks the user up by (exact) `username` instead.
-}
fetchUserByUsername :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetUsersResponse )
fetchUserByUsername accountsPanelModel maybeAccountServer username =
    fetchUsers accountsPanelModel maybeAccountServer { defaultGetUsersRequest | username = Just username }


fetchUsers :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> Proto.Jonline.GetUsersRequest
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetUsersResponse )
fetchUsers accountsPanelModel maybeAccountServer request =
    performWithOptionalAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server maybeToken ->
            Grpc.new Jonline.getUsers request
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken maybeToken
                |> Grpc.toTask
        )


{-| Reloads `userId` fresh via `GetUsers` (so any fields that changed
server-side since the caller's own copy isn't clobbered), applies `updateFn`
to that fresh copy, then submits the result via `UpdateUser` -- the "reload,
then write, then update" dance `Components.UserProfilePage`'s Real Name and
permissions editors both need, mirroring `Shared.MarkdownPanel.saveTask`'s
`PostContent` case (`GetPosts`+`UpdatePost`). Returns a `Msg` to dispatch if
a token refresh happened, alongside the updated `User`, same convention as
`fetchUserById`.
-}
updateUser :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> String
    -> (User -> User)
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, User )
updateUser accountsPanelModel maybeAccountServer userId updateFn =
    performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.getUsers { defaultGetUsersRequest | userId = Just userId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
                |> Task.andThen
                    (\response ->
                        case List.head response.users of
                            Just freshUser ->
                                Grpc.new Jonline.updateUser (updateFn freshUser)
                                    |> Grpc.setHost (AccountsPanel.serverUrl server)
                                    |> withAccessToken (Just token)
                                    |> Grpc.toTask

                            Nothing ->
                                Task.fail Grpc.NetworkError
                    )
        )


{-| Federates `maybeAccountServer`'s account's own profile (identified by the
caller's auth token, not any id in the request) with `target` -- unlike
`updateUser`, `FederateProfile`/`DefederateProfile` always act on the
signed-in caller themself, so there's no "self or admin" edit gate to check
here (see `backend/src/rpcs/federation/federate_profile.rs`).
-}
federateProfile :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> FederatedAccount
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, FederatedAccount )
federateProfile accountsPanelModel maybeAccountServer target =
    performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.federateProfile target
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


{-| The inverse of `federateProfile` -- removes `target` from the account's
own `federatedProfiles`.
-}
defederateProfile :
    AccountsPanel.Model
    -> AccountsPanel.MaybeAccountServer
    -> FederatedAccount
    -> Task Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Google.Protobuf.Empty )
defederateProfile accountsPanelModel maybeAccountServer target =
    performWithAccountServer
        accountsPanelModel
        maybeAccountServer
        (\server token ->
            Grpc.new Jonline.defederateProfile target
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )



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


{-| Every real `Permission` a user could actually be granted (excludes
`PERMISSIONUNKNOWN`/`PermissionUnrecognized_`, which aren't grantable) -- the
full set an admin picks from in `Components.UserProfilePage`'s permissions
editor's "Add Permission" `<select>`. Order matches `permissionText`/
`permissions.proto`.
-}
allPermissions : List Permission
allPermissions =
    [ VIEWUSERS
    , PUBLISHUSERSLOCALLY
    , PUBLISHUSERSGLOBALLY
    , MODERATEUSERS
    , FOLLOWUSERS
    , GRANTBASICPERMISSIONS
    , VIEWGROUPS
    , CREATEGROUPS
    , PUBLISHGROUPSLOCALLY
    , PUBLISHGROUPSGLOBALLY
    , MODERATEGROUPS
    , JOINGROUPS
    , INVITEGROUPMEMBERS
    , VIEWPOSTS
    , CREATEPOSTS
    , PUBLISHPOSTSLOCALLY
    , PUBLISHPOSTSGLOBALLY
    , MODERATEPOSTS
    , REPLYTOPOSTS
    , VIEWEVENTS
    , CREATEEVENTS
    , PUBLISHEVENTSLOCALLY
    , PUBLISHEVENTSGLOBALLY
    , MODERATEEVENTS
    , RSVPTOEVENTS
    , VIEWMEDIA
    , CREATEMEDIA
    , PUBLISHMEDIALOCALLY
    , PUBLISHMEDIAGLOBALLY
    , MODERATEMEDIA
    , BUSINESS
    , RUNBOTS
    , ADMIN
    , VIEWPRIVATECONTACTMETHODS
    ]


{-| The reverse of `permissionText` -- looks up a `Permission` by its display
label. Needed because a plain HTML `<select>`'s value/`onInput` are just
strings; `Components.UserProfilePage`'s "Add Permission" picker uses
`permissionText` for each `<option>`'s label and reads this back on change.
`Nothing` for any text that isn't one of `allPermissions`' labels (shouldn't
happen, since the `<select>`'s own options are always built from
`allPermissions` in the first place).
-}
permissionFromText : String -> Maybe Permission
permissionFromText text =
    allPermissions |> List.filter (\permission -> permissionText permission == text) |> List.head
