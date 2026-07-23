module Shared.MyMediaPanel exposing (Model, Msg(..), Purpose(..), init, isOpen, update, view)

{-| A single, app-wide "My Media" panel -- always scoped to one specific
server (`targetHost`, same "resolve on demand rather than cache a live
`Server`/`Account`" convention `Shared.MarkdownPanel` uses for its own
`targetHost`), opened today from a signed-in Account chip in the Accounts
Panel (see `UI.accountRow`'s new media button) to browse that account's own
uploaded media, fetched via `GetMedia` (`protos/media.proto`) and rendered as
a grid of small previews (`Components.MediaRenderer`, `ExtraSmall` sizing)
alongside each item's filename/content type.

`Purpose` is here so `Model`/`Msg` already have a place for this panel to grow
into a single-/multi-select "media chooser" input (for a post's media, an
avatar, ...) without a later reshape of these types -- only `Browse` is
actually wired up right now; `ChooseSingle`/`ChooseMultiple` don't yet change
this module's behavior at all.

-}

import Components.MediaRenderer as MediaRenderer
import Grpc
import Html exposing (Html, button, div, img, span, text)
import Html.Attributes exposing (alt, attribute, class, src)
import Html.Events exposing (onClick)
import Proto.Jonline exposing (GetMediaResponse, Media, MediaReference, defaultGetMediaRequest)
import Proto.Jonline.Jonline as Jonline
import Shared.AccountsPanel as AccountsPanel exposing (withAccessToken)
import Task exposing (Task)
import UI.Classes exposing (classes, openClosedClass)


{-| What this panel's open for -- see module doc. Threaded through `Open` now
so a future chooser doesn't need to change that message's shape, just add
real behavior behind the `ChooseSingle`/`ChooseMultiple` cases below.
-}
type Purpose
    = Browse
    | ChooseSingle
    | ChooseMultiple


type FetchStatus
    = NotFetched
    | Fetching
    | FetchFailed String
    | Fetched (List Media)


type alias Model =
    { -- The `frontendHost` of the server this panel's browsing -- resolved
      -- fresh (see `resolve`) against `AccountsPanel.Model` whenever needed,
      -- same "don't cache a live Account/Server" reasoning as
      -- `MarkdownPanel.targetHost`. `""` means "not open" (see `isOpen`).
      targetHost : String
    , purpose : Purpose
    , status : FetchStatus
    }


init : Model
init =
    { targetHost = "", purpose = Browse, status = NotFetched }


{-| Whether the panel is currently open -- drives `openClosedClass` and
`UI.elm`'s `sharedBackdrop`, same `targetHost /= ""` convention
`MarkdownPanel` uses via its own `target /= Nothing`.
-}
isOpen : Model -> Bool
isOpen model =
    model.targetHost /= ""


type Msg
    = Open Purpose String
    | CloseClicked
    | GotMediaResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, GetMediaResponse ))
      -- Fired when a media item's preview is tapped -- a no-op today (Browse
      -- mode has nothing to do with it yet); reserved for `ChooseSingle`/
      -- `ChooseMultiple` to toggle a selection once those are wired up.
      -- Required regardless, since `Components.MediaRenderer.view` always
      -- needs an `onImageClicked : String -> msg` to attach.
    | MediaItemClicked String


{-| Needs `AccountsPanel.Model` (to resolve `targetHost` to a connected
`Server`/signed-in `Account` to fetch as -- see `resolve`) and can itself
surface an `AccountsPanel.Msg` it needs forwarded on its behalf (an
`AccessTokenResponseReceived`, if fetching had to refresh the account's token
first -- see `AccountsPanel.performWithAccountServer`) for `Shared.update` to
actually dispatch, same convention as `Shared.MarkdownPanel.update`.
-}
update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, Maybe AccountsPanel.Msg )
update accountsPanelModel msg model =
    case msg of
        Open purpose host ->
            let
                opened =
                    { targetHost = host, purpose = purpose, status = Fetching }
            in
            case resolve accountsPanelModel host of
                Ok resolved ->
                    ( opened
                    , fetchTask accountsPanelModel resolved.account
                        |> Task.attempt GotMediaResult
                    , Nothing
                    )

                Err err ->
                    ( { opened | status = FetchFailed err }, Cmd.none, Nothing )

        CloseClicked ->
            ( init, Cmd.none, Nothing )

        GotMediaResult (Ok ( maybeAccountsPanelMsg, response )) ->
            ( { model | status = Fetched response.media }, Cmd.none, maybeAccountsPanelMsg )

        GotMediaResult (Err err) ->
            ( { model | status = FetchFailed (AccountsPanel.grpcErrorToString err) }, Cmd.none, Nothing )

        MediaItemClicked _ ->
            ( model, Cmd.none, Nothing )


type alias Resolved =
    { server : AccountsPanel.Server
    , account : AccountsPanel.Account
    }


{-| Verifies `host` is actually usable right now -- it resolves to a known,
currently-enabled `Server`, and there's a signed-in `Account` on it (the
account whose media is being browsed). Used both by `update`'s `Open` (to
gate the fetch) and by `view` (to show the same problem inline instead of a
silent empty panel).
-}
resolve : AccountsPanel.Model -> String -> Result String Resolved
resolve accountsPanelModel host =
    case AccountsPanel.serverForHost accountsPanelModel.servers host of
        Nothing ->
            Err "That server isn't connected."

        Just server ->
            if not server.enabled then
                Err (server.frontendHost ++ " is disabled.")

            else
                case AccountsPanel.enabledAccountForServer accountsPanelModel.accounts host of
                    Nothing ->
                        Err "You're not signed in on that server."

                    Just account ->
                        Ok { server = server, account = account }


{-| `user_id` is required by `GetMediaRequest` whenever `media_id` isn't set
(`backend/src/rpcs/media/get_media.rs` errors otherwise) -- passing
`account.userId` explicitly, rather than leaving it unset and relying on the
backend's "no user_id means the caller's own media" fallback, keeps this
request meaningful even though today it only ever runs for the signed-in
account's own chip.
-}
fetchTask : AccountsPanel.Model -> AccountsPanel.Account -> Task Grpc.Error ( Maybe AccountsPanel.Msg, GetMediaResponse )
fetchTask accountsPanelModel account =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        ( Just account.userId, account.server )
        (\server token ->
            Grpc.new Jonline.getMedia { defaultGetMediaRequest | userId = Just account.userId }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
        )


{-| `Components.MediaRenderer.view` renders a `MediaReference`, not the fuller
`Media` `GetMedia` actually returns -- just the fields it shares with
`MediaReference` are needed to preview it.
-}
toMediaReference : Media -> MediaReference
toMediaReference media =
    { contentType = media.contentType, id = media.id, name = media.name, generated = media.generated }



-- VIEW


{-| Always rendered (even "closed"), same as `UI.elm`'s other panels, so
opening/closing is a plain CSS transition -- see `openClosedClass`. Needs
`AccountsPanel.Model` for the same reason `update` does -- resolving
`targetHost` to the `Server`/`Account` needed to render each media item's URL
and to show `resolve`'s error inline if either's no longer usable.
-}
view : AccountsPanel.Model -> Model -> Html Msg
view accountsPanelModel model =
    div [ classes [ "my-media-panel", "nav-panel", openClosedClass (isOpen model) ] ]
        [ div [ class "my-media-panel-header" ]
            [ span [ class "my-media-panel-title" ] [ text "My Media" ]
            , div [ class "my-media-panel-header-right" ]
                [ accountBadge accountsPanelModel model
                , button [ class "my-media-panel-close", onClick CloseClicked ] [ text "✕" ]
                ]
            ]
        , div [ class "my-media-panel-content" ] (contentView accountsPanelModel model)
        ]


{-| The account whose media this panel is browsing, shown as an avatar +
username between the title and close button so it's clear whose media is on
screen -- resolves the same way `contentView` does, but renders nothing if
`resolve` fails (that error's already shown in the content area below, no
need to duplicate it up here).
-}
accountBadge : AccountsPanel.Model -> Model -> Html Msg
accountBadge accountsPanelModel model =
    case resolve accountsPanelModel model.targetHost of
        Err _ ->
            text ""

        Ok resolved ->
            div [ class "my-media-panel-account" ]
                [ avatarOrInitial accountsPanelModel.servers resolved.account
                , span [ class "my-media-panel-username" ] [ text (AccountsPanel.displayName resolved.account) ]
                ]


{-| A trimmed-down copy of `UI.imageOrInitial`, scoped to this panel's own
avatar -- `UI` itself imports this module (to embed `MyMediaPanel.view`), so
importing it back here to reuse that helper would be a circular import.
-}
avatarOrInitial : List AccountsPanel.Server -> AccountsPanel.Account -> Html msg
avatarOrInitial servers account =
    case AccountsPanel.accountAvatarUrl servers account of
        Just url ->
            img [ class "my-media-panel-avatar", src url, alt account.username, attribute "loading" "lazy" ] []

        Nothing ->
            div [ classes [ "my-media-panel-avatar", "placeholder" ] ] [ text (AccountsPanel.initialLetter account.username) ]


contentView : AccountsPanel.Model -> Model -> List (Html Msg)
contentView accountsPanelModel model =
    case resolve accountsPanelModel model.targetHost of
        Err err ->
            [ div [ class "my-media-panel-message" ] [ text err ] ]

        Ok resolved ->
            case model.status of
                NotFetched ->
                    []

                Fetching ->
                    [ div [ class "my-media-panel-message" ] [ text "Loading…" ] ]

                FetchFailed err ->
                    [ div [ class "my-media-panel-message" ] [ text err ] ]

                Fetched [] ->
                    [ div [ class "my-media-panel-message" ] [ text "No media yet." ] ]

                Fetched media ->
                    [ div [ class "my-media-panel-grid" ]
                        (List.map (mediaItemView resolved.server resolved.account) media)
                    ]


mediaItemView : AccountsPanel.Server -> AccountsPanel.Account -> Media -> Html Msg
mediaItemView server account media =
    div [ class "my-media-panel-item" ]
        [ MediaRenderer.view MediaRenderer.ExtraSmall server (Just account) MediaItemClicked (toMediaReference media)
        , div [ class "my-media-panel-item-name" ] [ text (Maybe.withDefault "Untitled" media.name) ]
        , div [ class "my-media-panel-item-type" ] [ text media.contentType ]
        ]
