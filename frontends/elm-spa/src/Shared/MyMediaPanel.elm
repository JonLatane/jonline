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

The header's "Add" button doubles as this panel's upload trigger (`AddClicked`
opens the OS file picker via `File.Select.file`), and the whole panel is also
a drop target (`view`'s root `on "drop"`) -- both funnel into the same
`uploadStatus`/`startUpload`. Jonline's media upload isn't a gRPC RPC at all
(see `protos/media.proto`'s doc comment on `Media`) -- it's a plain
`POST {backendHost}/media` with the raw file bytes as the body, an
`Authorization` header, and an optional `Filename` header, returning the new
media's ID as a plaintext body on success. This mirrors
`frontends/tamagui`'s `media_uploader.tsx`, minus the client-side image
downscaling (`resize_media.ts`) and upload-progress bar (elm/http's
`Http.task` has no progress-event equivalent short of a `Cmd`+subscription
pair, not worth the added complexity here).

-}

import Bytes.Encode
import Components.MediaRenderer as MediaRenderer
import File exposing (File)
import File.Select
import Grpc
import Html exposing (Html, button, div, img, span, text)
import Html.Attributes exposing (alt, attribute, class, disabled, src)
import Html.Events exposing (on, onClick, preventDefaultOn)
import Http
import Json.Decode as Decode
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


{-| What the "Add" button/drag-and-drop upload is currently doing -- separate
from `FetchStatus` since browsing the existing grid and uploading a new item
into it are independent (an upload failure shouldn't blank out an
already-loaded grid, and vice versa). `File` is carried along in `Uploading`/
`UploadFailed` purely so `view` can keep showing its name (`File.name`)
without a separate field for it.
-}
type UploadStatus
    = NotUploading
    | Uploading File
    | UploadFailed File String


type alias Model =
    { -- The `frontendHost` of the server this panel's browsing -- resolved
      -- fresh (see `resolve`) against `AccountsPanel.Model` whenever needed,
      -- same "don't cache a live Account/Server" reasoning as
      -- `MarkdownPanel.targetHost`. `""` means "not open" (see `isOpen`).
      targetHost : String
    , purpose : Purpose
    , status : FetchStatus
    , uploadStatus : UploadStatus

    -- Whether a drag is currently hovering anywhere over this panel -- see
    -- `view`'s `on "dragenter"`/`"dragleave"`. Purely a CSS hook
    -- (`is-dragging-over`); doesn't gate `Drop` itself.
    , isDraggingOver : Bool
    }


init : Model
init =
    { targetHost = "", purpose = Browse, status = NotFetched, uploadStatus = NotUploading, isDraggingOver = False }


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
      -- The header's "Add" button -- opens the OS file picker; the file it
      -- comes back with (`GotFile`) is uploaded the same way a `Drop` is.
    | AddClicked
    | GotFile File
      -- Every file dropped anywhere on this panel (see `view`) -- only the
      -- first is actually uploaded (one at a time, same as `AddClicked`'s own
      -- picker), the rest are silently ignored rather than queued.
    | Drop (List File)
    | DragEnter
    | DragLeave
    | GotUploadResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, String ))


{-| Needs `AccountsPanel.Model` (to resolve `targetHost` to a connected
`Server`/signed-in `Account` to fetch/upload as -- see `resolve`) and can
itself surface an `AccountsPanel.Msg` it needs forwarded on its behalf (an
`AccessTokenResponseReceived`, if fetching/uploading had to refresh the
account's token first -- see `AccountsPanel.performWithAccountServer`) for
`Shared.update` to actually dispatch, same convention as
`Shared.MarkdownPanel.update`.
-}
update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, Maybe AccountsPanel.Msg )
update accountsPanelModel msg model =
    case msg of
        Open purpose host ->
            let
                opened =
                    { targetHost = host, purpose = purpose, status = Fetching, uploadStatus = NotUploading, isDraggingOver = False }
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

        AddClicked ->
            ( model, File.Select.file acceptedMimeTypes GotFile, Nothing )

        GotFile file ->
            startUpload accountsPanelModel model file

        Drop files ->
            case List.head files of
                Just file ->
                    startUpload accountsPanelModel { model | isDraggingOver = False } file

                Nothing ->
                    ( { model | isDraggingOver = False }, Cmd.none, Nothing )

        DragEnter ->
            ( { model | isDraggingOver = True }, Cmd.none, Nothing )

        DragLeave ->
            ( { model | isDraggingOver = False }, Cmd.none, Nothing )

        GotUploadResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            -- Re-fetch to show the new item -- cheaper to just re-run the
            -- same `GetMedia` `Open` already does than to splice a new `Media`
            -- into `Fetched`'s list, since `POST /media`'s response is just a
            -- plaintext ID, not the full `Media` `GetMedia` would return.
            case resolve accountsPanelModel model.targetHost of
                Ok resolved ->
                    ( { model | uploadStatus = NotUploading, status = Fetching }
                    , fetchTask accountsPanelModel resolved.account |> Task.attempt GotMediaResult
                    , maybeAccountsPanelMsg
                    )

                Err _ ->
                    ( { model | uploadStatus = NotUploading }, Cmd.none, maybeAccountsPanelMsg )

        GotUploadResult (Err err) ->
            case model.uploadStatus of
                Uploading file ->
                    ( { model | uploadStatus = UploadFailed file (AccountsPanel.grpcErrorToString err) }, Cmd.none, Nothing )

                _ ->
                    ( model, Cmd.none, Nothing )


{-| Shared by `GotFile`/`Drop` -- resolves `targetHost` again (same check
`Open` makes) since either can land well after the account this panel was
opened for stopped being usable (signed out mid-pick, server disabled, ...).
-}
startUpload : AccountsPanel.Model -> Model -> File -> ( Model, Cmd Msg, Maybe AccountsPanel.Msg )
startUpload accountsPanelModel model file =
    case resolve accountsPanelModel model.targetHost of
        Ok resolved ->
            ( { model | uploadStatus = Uploading file }
            , uploadTask accountsPanelModel resolved model.targetHost file
                |> Task.attempt GotUploadResult
            , Nothing
            )

        Err err ->
            ( { model | uploadStatus = UploadFailed file err }, Cmd.none, Nothing )


{-| By extension, same allowlist `frontends/tamagui`'s `media_uploader.tsx`
passes its `<FileUploader>` -- purely a hint to the OS file picker's own
filter, not enforced server-side (and not consulted by `Drop` at all, same as
the React version).
-}
acceptedMimeTypes : List String
acceptedMimeTypes =
    [ "image/jpeg", "image/png", "image/svg+xml", "image/webp", "image/gif", "application/pdf", "video/mp4", "video/quicktime", "video/webm", "audio/mpeg", "audio/ogg" ]


type alias Resolved =
    { server : AccountsPanel.Server
    , account : AccountsPanel.Account
    }


{-| Verifies `host` is actually usable right now -- it resolves to a known,
currently-enabled `Server`, and there's a signed-in `Account` on it (the
account whose media is being browsed/uploaded to). Used by `update`'s `Open`
(to gate the fetch), `startUpload` (to gate an upload), and by `view` (to show
the same problem inline instead of a silent empty panel).
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


{-| `user_id` is passed explicitly for the same reason `fetchTask` does --
keeps `performWithAccountServer`'s resolution meaningful even though this only
ever runs for the account this panel was opened for.
-}
uploadTask : AccountsPanel.Model -> Resolved -> String -> File -> Task Grpc.Error ( Maybe AccountsPanel.Msg, String )
uploadTask accountsPanelModel resolved host file =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        ( Just resolved.account.userId, host )
        (\server token -> postMediaTask server token file)


{-| The actual `POST {backendHost}/media` -- see the module doc. `Http.fileBody`
sets `Content-Type` from `file`'s own MIME type, so only `Authorization`/
`Filename` need to be added as headers.
-}
postMediaTask : AccountsPanel.Server -> String -> File -> Task Grpc.Error String
postMediaTask server token file =
    Http.task
        { method = "POST"
        , headers =
            [ Http.header "Authorization" token
            , Http.header "Filename" (File.name file)
            ]
        , url = AccountsPanel.mediaBaseUrl (AccountsPanel.connectionOf server) ++ "/media"
        , body = Http.fileBody file
        , resolver = Http.stringResolver toGrpcResult
        , timeout = Nothing
        }


{-| Recast as a `Grpc.Error` (rather than `Http.Error`) purely so `update` can
reuse `AccountsPanel.grpcErrorToString` for a user-facing message, same as
`GotMediaResult`'s own error path -- this isn't a real gRPC call, so
`BadStatus`'s `status`/`response` fields are filled with placeholders nothing
here actually inspects.
-}
toGrpcResult : Http.Response String -> Result Grpc.Error String
toGrpcResult response =
    case response of
        Http.BadUrl_ url ->
            Err (Grpc.BadUrl url)

        Http.Timeout_ ->
            Err Grpc.Timeout

        Http.NetworkError_ ->
            Err Grpc.NetworkError

        Http.BadStatus_ metadata body ->
            Err
                (Grpc.BadStatus
                    { metadata = metadata
                    , response = Bytes.Encode.encode (Bytes.Encode.string body)
                    , errMessage = ifNonEmpty body |> Maybe.withDefault metadata.statusText
                    , status = Grpc.Unknown
                    }
                )

        Http.GoodStatus_ _ body ->
            Ok (String.trim body)


ifNonEmpty : String -> Maybe String
ifNonEmpty s =
    if String.isEmpty (String.trim s) then
        Nothing

    else
        Just (String.trim s)


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

The whole panel (this root node) is a drop target -- `dragenter`/`dragover`
toggle `is-dragging-over` (a pure CSS hook, see my\_media\_panel.css) and
`drop` hands the dropped files to `Drop`. `dragover` needs its own
`preventDefault` (not just `dragenter`'s) -- browsers refuse to fire `drop` at
all on an element that didn't call `preventDefault` on the *last* `dragover`
before the drop, not just the first `dragenter`. `dragleave` firing whenever
the pointer crosses from this panel onto one of its own children (not just
when it actually leaves the panel) means `is-dragging-over` can flicker off
briefly while dragging over a media item -- a cosmetic rough edge, not
something `Drop`'s own correctness depends on.
-}
view : AccountsPanel.Model -> Model -> Html Msg
view accountsPanelModel model =
    div
        (classes
            ([ "my-media-panel", "nav-panel", openClosedClass (isOpen model) ]
                ++ (if model.isDraggingOver then
                        [ "is-dragging-over" ]

                    else
                        []
                   )
            )
            :: dropTargetAttributes
        )
        [ div [ class "my-media-panel-header" ]
            [ span [ class "my-media-panel-title" ] [ text "My Media" ]
            , div [ class "my-media-panel-header-right" ]
                [ uploadStatusView model.uploadStatus
                , accountBadge accountsPanelModel model
                , button
                    [ class "my-media-panel-add"
                    , onClick AddClicked
                    , disabled (isUploading model.uploadStatus)
                    ]
                    [ text "+ Add" ]
                , button [ class "my-media-panel-close", onClick CloseClicked ] [ text "✕" ]
                ]
            ]
        , div [ class "my-media-panel-content" ] (contentView accountsPanelModel model)
        ]


isUploading : UploadStatus -> Bool
isUploading status =
    case status of
        Uploading _ ->
            True

        _ ->
            False


dropTargetAttributes : List (Html.Attribute Msg)
dropTargetAttributes =
    [ preventDefaultOn "dragover" (Decode.succeed ( DragEnter, True ))
    , on "dragenter" (Decode.succeed DragEnter)
    , on "dragleave" (Decode.succeed DragLeave)
    , preventDefaultOn "drop" (Decode.map (\files -> ( Drop files, True )) droppedFilesDecoder)
    ]


{-| Per `File.decoder`'s own doc example. -}
droppedFilesDecoder : Decode.Decoder (List File)
droppedFilesDecoder =
    Decode.field "dataTransfer" (Decode.field "files" (Decode.list File.decoder))


uploadStatusView : UploadStatus -> Html Msg
uploadStatusView status =
    case status of
        NotUploading ->
            text ""

        Uploading file ->
            span [ class "my-media-panel-upload-status" ] [ text ("Uploading " ++ File.name file ++ "…") ]

        UploadFailed file err ->
            span [ classes [ "my-media-panel-upload-status", "my-media-panel-upload-error" ] ]
                [ text ("Couldn't upload " ++ File.name file ++ ": " ++ err) ]


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
