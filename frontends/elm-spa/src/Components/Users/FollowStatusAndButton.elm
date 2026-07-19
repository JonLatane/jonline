module Components.Users.FollowStatusAndButton exposing
    ( Model
    , Msg(..)
    , init
    , update
    , view
    )

{-| The follower/following/friends relationship between the signed-in viewer
and some other `Proto.Jonline.User` -- a status line ("Following," "Wants to
follow you," "Friends," etc.) plus whichever of Follow/Request Follow/Cancel
Follow Request/Unfollow/Reject Follower/Unreject Follower buttons apply,
backed by the `CreateFollow`/`UpdateFollow`/`DeleteFollow` RPCs.

Owns just enough state (`Model`, in-flight submit status) to drive those RPCs
itself -- unlike `usernameHeading`/`nameHeader` (plain `Html msg`), the
buttons here need a concrete `Msg` to dispatch on click, so a caller (e.g.
`Components.Pages.UserProfilePage`) embeds this module's `Model` alongside its
own, forwards this module's `Msg`, and re-fetches the `User` once an action
succeeds (this module doesn't refetch itself, since it only ever sees
whatever `User` its caller currently has loaded).

Two `Follow`s are relevant to any one `User` (see `users.proto`): the
viewer's own `currentUserFollow` (viewer follows `User`; its
`targetUserModeration` is moderated by `User`, not the viewer -- the viewer
can only create/cancel/delete it) and `targetCurrentUserFollow` (`User`
follows viewer; its `targetUserModeration` is moderated by the viewer, per
`defaultFollowModeration` on the viewer's own account -- the viewer may
approve/reject it via `UpdateFollow`, but never create/delete it directly).

-}

import Components.Users as Users
import Effect exposing (Effect)
import Grpc
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)
import Proto.Google.Protobuf
import Proto.Jonline exposing (Follow, User, defaultFollow)
import Proto.Jonline.Moderation exposing (Moderation(..))
import Shared
import Shared.AccountsPanel as AccountsPanel
import Task


type SubmitStatus
    = Idle
    | Submitting
    | SubmitFailed String


type alias Model =
    { status : SubmitStatus }


init : Model
init =
    { status = Idle }



-- UPDATE


type Msg
    = FollowClicked
    | UnfollowClicked
    | RejectFollowerClicked
    | UnrejectFollowerClicked
    | GotFollowResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, Follow ))
    | GotUnfollowResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, Proto.Google.Protobuf.Empty ))
    | GotModerationResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, Follow ))


{-| `account`'s own `Follow` of `user` -- the relationship the viewer
themself controls the existence (but not the moderation) of.
-}
currentUserFollowOf : AccountsPanel.Account -> User -> Follow
currentUserFollowOf account user =
    { defaultFollow | userId = account.userId, targetUserId = user.id }


{-| `user`'s `Follow` of `account` -- the relationship the viewer controls
the moderation (but not the existence) of.
-}
targetCurrentUserFollowOf : AccountsPanel.Account -> User -> Follow
targetCurrentUserFollowOf account user =
    { defaultFollow | userId = user.id, targetUserId = account.userId }


{-| Handles every click here -- `server`/`account` are the viewer's own
(resolved by the caller, e.g. `Components.Pages.UserProfilePage.serverAndAccount`),
`user` is whoever this component is currently showing follow status/buttons
for. On any successful result, the caller is expected to notice (by matching
on this module's `Msg` constructors, mirroring `Components.Users.Resolver.Msg`)
and re-fetch `user` fresh, since a `Follow` mutation changes fields
(`currentUserFollow`/`targetCurrentUserFollow`/`followerCount`/`followingCount`)
on both `user` and the viewer's own `User` that this module has no way to
patch up itself.
-}
update : Shared.Model -> AccountsPanel.Server -> AccountsPanel.Account -> User -> Msg -> Model -> ( Model, Effect Msg )
update shared server account user msg model =
    let
        maybeAccountServer =
            ( Just account.userId, server.frontendHost )
    in
    case msg of
        FollowClicked ->
            ( { model | status = Submitting }
            , Users.createFollow shared.accountsPanel maybeAccountServer (currentUserFollowOf account user)
                |> Task.attempt GotFollowResult
                |> Effect.fromCmd
            )

        UnfollowClicked ->
            ( { model | status = Submitting }
            , Users.deleteFollow shared.accountsPanel maybeAccountServer (currentUserFollowOf account user)
                |> Task.attempt GotUnfollowResult
                |> Effect.fromCmd
            )

        RejectFollowerClicked ->
            ( { model | status = Submitting }
            , Users.updateFollow shared.accountsPanel
                maybeAccountServer
                (let
                    follow =
                        targetCurrentUserFollowOf account user
                 in
                 { follow | targetUserModeration = REJECTED }
                )
                |> Task.attempt GotModerationResult
                |> Effect.fromCmd
            )

        UnrejectFollowerClicked ->
            ( { model | status = Submitting }
            , Users.updateFollow shared.accountsPanel
                maybeAccountServer
                (let
                    follow =
                        targetCurrentUserFollowOf account user
                 in
                 { follow | targetUserModeration = APPROVED }
                )
                |> Task.attempt GotModerationResult
                |> Effect.fromCmd
            )

        GotFollowResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            ( { model | status = Idle }, accountsPanelEffect maybeAccountsPanelMsg )

        GotFollowResult (Err err) ->
            ( { model | status = SubmitFailed (AccountsPanel.grpcErrorToString err) }, Effect.none )

        GotUnfollowResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            ( { model | status = Idle }, accountsPanelEffect maybeAccountsPanelMsg )

        GotUnfollowResult (Err err) ->
            ( { model | status = SubmitFailed (AccountsPanel.grpcErrorToString err) }, Effect.none )

        GotModerationResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            ( { model | status = Idle }, accountsPanelEffect maybeAccountsPanelMsg )

        GotModerationResult (Err err) ->
            ( { model | status = SubmitFailed (AccountsPanel.grpcErrorToString err) }, Effect.none )


accountsPanelEffect : Maybe AccountsPanel.Msg -> Effect Msg
accountsPanelEffect maybeAccountsPanelMsg =
    maybeAccountsPanelMsg
        |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
        |> Maybe.withDefault Effect.none



-- VIEW


{-| `Nothing` for an anonymous viewer, or when `user` is the viewer's own
profile -- there's no follow relationship to show/act on in either case.
-}
view : Model -> Maybe AccountsPanel.Account -> User -> Html Msg
view model maybeAccount user =
    case maybeAccount of
        Just account ->
            if account.userId == user.id then
                text ""

            else
                viewFor model user

        Nothing ->
            text ""


viewFor : Model -> User -> Html Msg
viewFor model user =
    let
        currentUserFollowModeration =
            Maybe.map .targetUserModeration user.currentUserFollow

        targetCurrentUserFollowModeration =
            Maybe.map .targetUserModeration user.targetCurrentUserFollow

        following =
            Maybe.map Users.moderationPasses currentUserFollowModeration |> Maybe.withDefault False

        followingPending =
            Maybe.map Users.moderationPending currentUserFollowModeration |> Maybe.withDefault False

        followedByPasses =
            Maybe.map Users.moderationPasses targetCurrentUserFollowModeration |> Maybe.withDefault False

        followedByPending =
            Maybe.map Users.moderationPending targetCurrentUserFollowModeration |> Maybe.withDefault False

        statusText =
            if following && followedByPasses then
                "Friends"

            else if followingPending && followedByPending then
                "Mutual Follow Requests"

            else if followedByPending then
                "Wants to follow you"

            else if followedByPasses then
                "Follows you"

            else if following then
                "Following"

            else if followingPending then
                "Follow requested"

            else
                ""

        requiresApproval =
            Users.moderationPending user.defaultFollowModeration

        showFollow =
            not following && not followingPending

        showCancelFollowRequest =
            followingPending

        showUnfollow =
            following

        showRejectFollower =
            user.targetCurrentUserFollow /= Nothing && not (Maybe.map Users.moderationRejected targetCurrentUserFollowModeration |> Maybe.withDefault False)

        showUnrejectFollower =
            user.targetCurrentUserFollow /= Nothing && not followedByPasses

        buttons =
            List.concat
                [ if showFollow then
                    [ followActionButton model.status FollowClicked "follow-status-follow" (followButtonText requiresApproval) ]

                  else
                    []
                , if showCancelFollowRequest then
                    [ followActionButton model.status UnfollowClicked "follow-status-cancel" "Cancel Follow Request" ]

                  else
                    []
                , if showUnfollow then
                    [ followActionButton model.status UnfollowClicked "follow-status-unfollow" "Unfollow" ]

                  else
                    []
                , if showRejectFollower then
                    [ followActionButton model.status RejectFollowerClicked "follow-status-reject" "Reject Follower" ]

                  else
                    []
                , if showUnrejectFollower then
                    [ followActionButton model.status UnrejectFollowerClicked "follow-status-unreject" "Unreject Follower" ]

                  else
                    []
                ]
    in
    div [ class "follow-status-and-button" ]
        [ if String.isEmpty statusText then
            text ""

          else
            div [ class "follow-status-text" ] [ text statusText ]
        , if List.isEmpty buttons then
            text ""

          else
            div [ class "follow-status-buttons" ] buttons
        , case model.status of
            SubmitFailed err ->
                div [ class "follow-status-error" ] [ text err ]

            _ ->
                text ""
        ]


followButtonText : Bool -> String
followButtonText requiresApproval =
    if requiresApproval then
        "Request Follow"

    else
        "Follow"


followActionButton : SubmitStatus -> Msg -> String -> String -> Html Msg
followActionButton status clickMsg buttonClass label =
    button
        [ class "follow-status-button"
        , class buttonClass
        , onClick clickMsg
        , disabled (status == Submitting)
        ]
        [ text label ]
