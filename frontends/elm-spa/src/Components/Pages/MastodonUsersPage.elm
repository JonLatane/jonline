module Components.Pages.MastodonUsersPage exposing (ListingType(..), Model, Msg, init, update, view)

{-| A Mastodon account's followers or following list, read-only -- up to the first 40 (see
`Shared.Federation.Mastodon.fetchFollowers`/`fetchFollowing`'s own doc on why there's no pagination
yet), each linking to its own `Components.Pages.MastodonUserProfilePage`. No follow/moderation
affordances at all -- unlike `Components.Pages.UsersPage`'s real Rellm listings, this is someone
else's federated account list, not one Rellm itself has any notion of following/moderating.

Routed to from `Pages.UsernameOrCustomTab_/Followers`/`Following` once
`Components.Users.parseFederatedUserId` recognizes the route's host as Mastodon's -- see
`Components.Pages.MastodonUserProfilePage`'s own doc for the single-profile counterpart, and
`Components.Pages.BlueskyUsersPage` for the AT Protocol equivalent of this module.

-}

import Components.Users as Users
import Effect exposing (Effect)
import Html exposing (Html, a, div, h2, p, text)
import Html.Attributes exposing (class, href)
import Http
import Shared
import Shared.Federation.Mastodon as Mastodon
import Task


type ListingType
    = Followers
    | Following


type alias Model =
    { instanceHost : String
    , username : String
    , listingType : ListingType
    , status : ListingStatus
    }


type ListingStatus
    = ResolvingAccount
    | Listed (List Mastodon.Account)
    | Failed


type Msg
    = GotAccount (Result Http.Error Mastodon.Account)
    | GotListing (Result Http.Error (List Mastodon.Account))


{-| `instanceHost`/`username` come from the same `Components.Users.parseFederatedUserId` split
`Components.Pages.MastodonUserProfilePage.init` uses -- resolving `username` to its own `Account.id`
first (via `Mastodon.lookupAccount`), since `fetchFollowers`/`fetchFollowing` both key off that, not
the username itself.
-}
init : String -> String -> ListingType -> ( Model, Effect Msg )
init instanceHost username listingType =
    ( { instanceHost = instanceHost, username = username, listingType = listingType, status = ResolvingAccount }
    , Mastodon.lookupAccount instanceHost username
        |> Task.attempt GotAccount
        |> Effect.fromCmd
    )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotAccount (Ok account) ->
            ( model
            , (case model.listingType of
                Followers ->
                    Mastodon.fetchFollowers model.instanceHost account.id

                Following ->
                    Mastodon.fetchFollowing model.instanceHost account.id
              )
                |> Task.attempt GotListing
                |> Effect.fromCmd
            )

        GotAccount (Err _) ->
            ( { model | status = Failed }, Effect.none )

        GotListing (Ok accounts) ->
            ( { model | status = Listed accounts }, Effect.none )

        GotListing (Err _) ->
            ( { model | status = Failed }, Effect.none )


view : Shared.Model -> Model -> Html Msg
view shared model =
    div [ class "profile-detail" ]
        [ h2 [] [ text (title model) ]
        , case model.status of
            ResolvingAccount ->
                p [ class "post-loading" ] [ text "Loading…" ]

            Failed ->
                p [ class "post-error" ] [ text "Couldn't load this list. The account may not exist, or that instance may be unreachable." ]

            Listed [] ->
                p [] [ text "Nobody here yet." ]

            Listed accounts ->
                div [] (List.map (accountRow shared model.instanceHost) accounts)
        ]


accountRow : Shared.Model -> String -> Mastodon.Account -> Html Msg
accountRow shared instanceHost account =
    let
        handle : String
        handle =
            account.username ++ "@" ++ instanceHost
    in
    a
        [ href (Users.usernameHref "" shared.accounts.mainFrontendHost ("mastodon:" ++ instanceHost) account.username)
        , class "user-card"
        ]
        [ Users.userCardAvatar handle account.avatarUrl
        , div [ class "user-card-details" ]
            [ div [] [ text ("⇄ " ++ (account.displayName |> Maybe.withDefault ("@" ++ handle))) ]
            , div [ class "user-card-meta" ] [ text ("@" ++ handle) ]
            ]
        ]


title : Model -> String
title model =
    case model.listingType of
        Followers ->
            "Followers"

        Following ->
            "Following"
