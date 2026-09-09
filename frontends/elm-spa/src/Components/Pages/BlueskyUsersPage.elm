module Components.Pages.BlueskyUsersPage exposing (ListingType(..), Model, Msg, init, update, view)

{-| A Bluesky account's followers or "follows" list, read-only -- up to the first 40 (see
`Shared.Federation.Bluesky.fetchFollowers`/`fetchFollows`'s own doc on why there's no pagination
yet), each linking to its own `Components.Pages.BlueskyUserProfilePage`. No follow/moderation
affordances at all -- unlike `Components.Pages.UsersPage`'s real Rellm listings, this is someone
else's federated account list, not one Rellm itself has any notion of following/moderating.

Routed to from `Pages.UsernameOrCustomTab_/Followers`/`Following` once
`Components.Users.parseFederatedUserId` recognizes the route's host as Bluesky's -- see
`Components.Pages.BlueskyUserProfilePage`'s own doc for the single-profile counterpart, and
`Components.Pages.MastodonUsersPage` for the ActivityPub equivalent of this module.

Fails outright (mirrors `Components.Pages.BlueskyUserProfilePage.init`) if no Bluesky account is
connected at all -- AT Protocol has no anonymous access to anything.

-}

import Components.Users as Users
import Effect exposing (Effect)
import Html exposing (Html, a, div, h2, p, text)
import Html.Attributes exposing (class, href)
import Http
import Shared
import Shared.Federation.Bluesky as Bluesky
import Task


type ListingType
    = Followers
    | Following


type alias Model =
    { handle : String
    , listingType : ListingType
    , status : ListingStatus
    }


type ListingStatus
    = Loading
    | Listed (List Bluesky.ActorProfile)
    | Failed


type Msg
    = GotListing (Result Http.Error (List Bluesky.ActorProfile))


{-| `handle` comes from the same `Components.Users.parseFederatedUserId` split
`Components.Pages.BlueskyUserProfilePage.init` uses, authenticated against whichever connected
Bluesky account comes first -- see this module's own doc on why one has to be connected at all.
-}
init : Shared.Model -> String -> ListingType -> ( Model, Effect Msg )
init shared handle listingType =
    let
        fetchTask : Task.Task Http.Error (List Bluesky.ActorProfile)
        fetchTask =
            case shared.accounts.blueskyAccounts of
                account :: _ ->
                    let
                        fetch : String -> String -> Task.Task Http.Error (List Bluesky.ActorProfile)
                        fetch =
                            case listingType of
                                Followers ->
                                    Bluesky.fetchFollowers

                                Following ->
                                    Bluesky.fetchFollows
                    in
                    fetch account.accessToken handle

                [] ->
                    Task.fail (Http.BadStatus 401)
    in
    ( { handle = handle, listingType = listingType, status = Loading }
    , fetchTask
        |> Task.attempt GotListing
        |> Effect.fromCmd
    )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotListing (Ok profiles) ->
            ( { model | status = Listed profiles }, Effect.none )

        GotListing (Err _) ->
            ( { model | status = Failed }, Effect.none )


view : Shared.Model -> Model -> Html Msg
view shared model =
    div [ class "profile-detail" ]
        [ h2 [] [ text (title model) ]
        , case model.status of
            Loading ->
                p [ class "post-loading" ] [ text "Loading…" ]

            Failed ->
                p [ class "post-error" ]
                    [ text
                        (if List.isEmpty shared.accounts.blueskyAccounts then
                            "Connect a Bluesky account to view this list."

                         else
                            "Couldn't load this list."
                        )
                    ]

            Listed [] ->
                p [] [ text "Nobody here yet." ]

            Listed profiles ->
                div [] (List.map (profileRow shared) profiles)
        ]


profileRow : Shared.Model -> Bluesky.ActorProfile -> Html Msg
profileRow shared profile =
    a
        [ href (Users.usernameHref "" shared.accounts.mainFrontendHost ("bluesky:" ++ profile.handle) profile.handle)
        , class "user-card"
        ]
        [ Users.userCardAvatar profile.handle profile.avatarUrl
        , div [ class "user-card-details" ]
            [ div [] [ text ("⇄ " ++ (profile.displayName |> Maybe.withDefault ("@" ++ profile.handle))) ]
            , div [ class "user-card-meta" ] [ text ("@" ++ profile.handle) ]
            ]
        ]


title : Model -> String
title model =
    case model.listingType of
        Followers ->
            "Followers"

        Following ->
            "Following"
