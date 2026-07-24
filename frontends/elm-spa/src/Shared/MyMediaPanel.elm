module Shared.MyMediaPanel exposing (Model, Msg(..), SelectionType(..), init, isOpen, subscriptions, update, view)

{-| A single, app-wide "My Media" panel -- always scoped to one specific
server (`targetHost`, same "resolve on demand rather than cache a live
`Server`/`Account`" convention `Shared.MarkdownPanel` uses for its own
`targetHost`), opened today from a signed-in Account chip in the Accounts
Panel (see `UI.accountRow`'s new media button) to browse that account's own
uploaded media, fetched via `GetMedia` (`protos/media.proto`) and rendered as
a grid of small previews (`Components.MediaRenderer`, `ExtraSmall` sizing)
alongside each item's filename/content type.

`SelectionType` is what lets this same panel double as a single-/multi-select
"media chooser" input (for a `User`'s avatar today -- see
`Components.Pages.UserProfilePage.AvatarEditClicked` -- a post's media,
later) instead of just plain browsing: `model.selectionType == Nothing` is
today's original "just browse/manage your media" mode (opened via
`Shared.MyMediaPanelOpenForAccount`), while `Just (SingleSelect _)` swaps the
header to "Select Media" and turns a tap on a grid item (`MediaItemClicked`,
see `update`) into a selection that immediately closes the panel rather than
a no-op. There's deliberately no callback closure carried on `SingleSelect`
-- `Shared.MyMediaPanelMsg (MyMediaPanel.MediaItemClicked mediaId)` is a top-
level `Shared.Msg` (this panel's `view` is `Html.map`-wrapped once, globally,
by `UI.myMediaPanel`), so `Main.elm`'s `notifyPageOfSharedMsg` already
forwards it verbatim to whichever page is current -- the opening page just
matches on it in its own `SharedMsg`/`fromShared` case (mirrors how
`Shared.MarkdownPanel.GotSaveResult` is picked up), gated on its own
"am I mid-edit" state so an unrelated Browse-mode tap elsewhere can't be
mistaken for a selection. `MultiSelect` is a stub for a future multi-select
flow -- not wired to anything yet.

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

import Animation
import Bytes.Encode
import Components.MediaRenderer as MediaRenderer
import Dict exposing (Dict)
import File exposing (File)
import File.Select
import Grpc
import Html exposing (Html, button, div, img, input, span, text)
import Html.Attributes exposing (alt, attribute, class, disabled, src, step, style, title, type_, value)
import Html.Events exposing (on, onClick, onInput, preventDefaultOn)
import Html.Keyed
import Http
import Json.Decode as Decode
import Proto.Jonline exposing (GetMediaResponse, Media, MediaReference, defaultGetMediaRequest, defaultMedia)
import Proto.Jonline.Jonline as Jonline
import Set exposing (Set)
import Shared.AccountsPanel as AccountsPanel exposing (withAccessToken)
import Task exposing (Task)
import UI.Classes exposing (classes, openClosedClass)
import UI.Flip


{-| What a `Just` `Model.selectionType` turns this panel into -- see module
doc. `SingleSelect`'s `imagesOnly` restricts the grid to image media only
(hiding videos/PDFs/etc that couldn't be tapped-to-select anyway --
`Components.MediaRenderer.view` only ever attaches `onImageClicked` for
images in the first place, see its own doc) -- `False` for a future chooser
that's fine picking any media type. `MultiSelect` is a stub -- no fields yet,
not wired to any behavior below.
-}
type SelectionType
    = SingleSelect { imagesOnly : Bool }
    | MultiSelect


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

    -- `Nothing` is plain Browse/manage mode (today's original behavior,
    -- unaffected below); `Just` turns this panel into a media chooser -- see
    -- `SelectionType`.
    , selectionType : Maybe SelectionType
    , status : FetchStatus
    , uploadStatus : UploadStatus

    -- Whether a drag is currently hovering anywhere over this panel -- see
    -- `view`'s `on "dragenter"`/`"dragleave"`. Purely a CSS hook
    -- (`is-dragging-over`); doesn't gate `Drop` itself.
    , isDraggingOver : Bool

    -- Media IDs with a `DeleteMedia` request currently in flight -- a `Set`
    -- (not a single `Maybe`, unlike `uploadStatus`) since nothing stops the
    -- user confirming a second item's delete while the first is still
    -- in-flight. Drives disabling that item's delete button and showing
    -- "Deleting…" in its place (see `mediaItemView`).
    , deletingIds : Set String

    -- Set by the most recent failed `DeleteMedia` -- shown next to
    -- `uploadStatus` in the header (see `uploadStatusView`'s counterpart,
    -- `deleteStatusView`) until the next delete attempt or panel close.
    , deleteError : Maybe String

    -- The slider-controlled pixel size of each grid item's long edge (see
    -- `zoomSliderView`) -- carried forward across `Open`/`CloseClicked`
    -- (unlike the rest of this record, which those reset) so the user's
    -- preferred preview size sticks across panel sessions. 238 matches
    -- `ExtraSmall`'s own fixed CSS cap (`media.css`), so the slider's
    -- default looks identical to before this existed.
    , zoom : Float

    -- Each tile's enter/leave `UI.Flip.State`, keyed by `Media.id`, synced
    -- (see `syncMediaAnimations`) against `status`'s own `Fetched` list
    -- every time it changes -- newly-seen media (a fresh `Open`, or a just
    -- uploaded item once its post-upload refetch lands) fades in, and media
    -- that dropped out (a just-deleted item, once *its* refetch lands)
    -- fades/collapses out instead of disappearing outright. Mirrors
    -- `Components.Pages.UsersPage.userAnimations` -- see its own doc.
    , mediaAnimations : Dict String MediaAnimation
    }


{-| One grid tile's enter/leave fade state, paired with the `Media` it was
last rendered with -- mirrors `Components.Pages.UsersPage.UserAnimation` (see
its own doc): keeping `media` here, not just relying on `status`'s own
`Fetched` list, lets a just-deleted tile keep rendering its last-known
preview/name for the length of its fade-out, rather than needing to somehow
survive in `Fetched` itself once it's gone from the server.
-}
type alias MediaAnimation =
    { media : Media
    , flip : UI.Flip.State Msg
    }


init : Model
init =
    { targetHost = "", selectionType = Nothing, status = NotFetched, uploadStatus = NotUploading, isDraggingOver = False, deletingIds = Set.empty, deleteError = Nothing, zoom = 238, mediaAnimations = Dict.empty }


{-| Whether the panel is currently open -- drives `openClosedClass` and
`UI.elm`'s `sharedBackdrop`, same `targetHost /= ""` convention
`MarkdownPanel` uses via its own `target /= Nothing`.
-}
isOpen : Model -> Bool
isOpen model =
    model.targetHost /= ""


type Msg
    = Open (Maybe SelectionType) String
    | CloseClicked
    | GotMediaResult (Result Grpc.Error ( Maybe AccountsPanel.Msg, GetMediaResponse ))
      -- Fired when a media item's preview is tapped -- a no-op in Browse mode
      -- (`model.selectionType == Nothing`); while `Just (SingleSelect _)`,
      -- `update` closes the panel instead (see its own doc on why that alone
      -- is enough to deliver the selection to whichever page opened this).
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
      -- The delete button on a grid item (see `mediaItemView`) -- doesn't
      -- delete anything itself, just bubbles `media` up through `update`'s
      -- own extra return value for `Shared.update` to turn into a
      -- `Shared.RequestDelete`, the same shared "are you sure?" flow
      -- `UI.serverChip`/`UI.accountRow` use (see `Shared.DeleteConfirmation`).
    | DeleteClicked Media
      -- Fired back from `Shared.update`'s `ConfirmDelete` once the user's
      -- confirmed the dialog `DeleteClicked` requested -- this is what
      -- actually calls `DeleteMedia`.
    | DeleteConfirmed Media
    | GotDeleteResult Media (Result Grpc.Error ( Maybe AccountsPanel.Msg, () ))
      -- Steps every tile's enter/leave fade (`mediaAnimations`) forward on
      -- an animation-frame tick -- mirrors `AccountsPanel.AnimateItemFlip`.
    | AnimateItemFlip Animation.Msg
      -- Fired once a removing tile's fade-out finishes (see
      -- `UI.Flip.remove`) -- actually drops it from `mediaAnimations` for
      -- good.
    | RemoveMediaAnimation String
      -- The bottom-right zoom slider (see `zoomSliderView`) -- `Float` since
      -- that's what an `input[type=range]`'s value parses as.
    | ZoomChanged Float


{-| Needs `AccountsPanel.Model` (to resolve `targetHost` to a connected
`Server`/signed-in `Account` to fetch/upload as -- see `resolve`) and can
itself surface an `AccountsPanel.Msg` it needs forwarded on its behalf (an
`AccessTokenResponseReceived`, if fetching/uploading had to refresh the
account's token first -- see `AccountsPanel.performWithAccountServer`) for
`Shared.update` to actually dispatch, same convention as
`Shared.MarkdownPanel.update`. The extra `Maybe Media` alongside it is
`DeleteClicked`'s own request for `Shared.update` to open the shared delete
confirmation dialog for -- same "second forwarded value" convention
`Shared.StarredPostsPanel.update` uses for its own `Maybe MediaViewerPanel.Msg`.
-}
update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, ( Maybe AccountsPanel.Msg, Maybe Media ) )
update accountsPanelModel msg model =
    case msg of
        Open selectionType host ->
            let
                opened =
                    { targetHost = host, selectionType = selectionType, status = Fetching, uploadStatus = NotUploading, isDraggingOver = False, deletingIds = Set.empty, deleteError = Nothing, zoom = model.zoom, mediaAnimations = Dict.empty }
            in
            case resolve accountsPanelModel host of
                Ok resolved ->
                    ( opened
                    , fetchTask accountsPanelModel resolved.account
                        |> Task.attempt GotMediaResult
                    , ( Nothing, Nothing )
                    )

                Err err ->
                    ( { opened | status = FetchFailed err }, Cmd.none, ( Nothing, Nothing ) )

        CloseClicked ->
            ( { init | zoom = model.zoom }, Cmd.none, ( Nothing, Nothing ) )

        GotMediaResult (Ok ( maybeAccountsPanelMsg, response )) ->
            -- `GotUploadResult`/`GotDeleteResult` both re-run `fetchTask`
            -- (see their own docs) *without* first bouncing `status` back to
            -- `Fetching` -- so it's still `Fetched <previous list>` right up
            -- until this replaces it with the fresh one, and `contentView`
            -- keeps rendering the (still-accurate-enough) grid the entire
            -- time instead of swapping to "Loading…" and back around it.
            -- That matters here specifically because `syncMediaAnimations`
            -- (below) is what starts a just-gone tile's removing-fade -- if
            -- the grid had been unmounted in between, that tile would have
            -- no prior on-screen frame to fade *from*, and would just appear
            -- already-collapsed instead of animating.
            ( syncMediaAnimations { model | status = Fetched response.media }, Cmd.none, ( maybeAccountsPanelMsg, Nothing ) )

        GotMediaResult (Err err) ->
            ( { model | status = FetchFailed (AccountsPanel.grpcErrorToString err) }, Cmd.none, ( Nothing, Nothing ) )

        MediaItemClicked _ ->
            case model.selectionType of
                Just (SingleSelect _) ->
                    -- The tapped id itself isn't needed here -- `Main.elm`
                    -- forwards this same `MediaItemClicked` verbatim to
                    -- whichever page opened this panel (see module doc), so
                    -- all this needs to do is close the panel as the visible
                    -- "selection made" feedback.
                    ( { init | zoom = model.zoom }, Cmd.none, ( Nothing, Nothing ) )

                _ ->
                    ( model, Cmd.none, ( Nothing, Nothing ) )

        AddClicked ->
            ( model, File.Select.file acceptedMimeTypes GotFile, ( Nothing, Nothing ) )

        GotFile file ->
            startUpload accountsPanelModel model file

        Drop files ->
            case List.head files of
                Just file ->
                    startUpload accountsPanelModel { model | isDraggingOver = False } file

                Nothing ->
                    ( { model | isDraggingOver = False }, Cmd.none, ( Nothing, Nothing ) )

        DragEnter ->
            ( { model | isDraggingOver = True }, Cmd.none, ( Nothing, Nothing ) )

        DragLeave ->
            ( { model | isDraggingOver = False }, Cmd.none, ( Nothing, Nothing ) )

        GotUploadResult (Ok ( maybeAccountsPanelMsg, _ )) ->
            -- Re-fetch to show the new item -- cheaper to just re-run the
            -- same `GetMedia` `Open` already does than to splice a new `Media`
            -- into `Fetched`'s list, since `POST /media`'s response is just a
            -- plaintext ID, not the full `Media` `GetMedia` would return.
            -- Deliberately leaves `status` (and so the still-`Fetched` grid
            -- `contentView` renders from it) alone rather than bouncing it
            -- through `Fetching` -- see `GotMediaResult`'s own doc on why.
            case resolve accountsPanelModel model.targetHost of
                Ok resolved ->
                    ( { model | uploadStatus = NotUploading }
                    , fetchTask accountsPanelModel resolved.account |> Task.attempt GotMediaResult
                    , ( maybeAccountsPanelMsg, Nothing )
                    )

                Err _ ->
                    ( { model | uploadStatus = NotUploading }, Cmd.none, ( maybeAccountsPanelMsg, Nothing ) )

        GotUploadResult (Err err) ->
            case model.uploadStatus of
                Uploading file ->
                    ( { model | uploadStatus = UploadFailed file (AccountsPanel.grpcErrorToString err) }, Cmd.none, ( Nothing, Nothing ) )

                _ ->
                    ( model, Cmd.none, ( Nothing, Nothing ) )

        DeleteClicked media ->
            ( model, Cmd.none, ( Nothing, Just media ) )

        DeleteConfirmed media ->
            case resolve accountsPanelModel model.targetHost of
                Ok resolved ->
                    ( { model | deletingIds = Set.insert media.id model.deletingIds, deleteError = Nothing }
                    , deleteTask accountsPanelModel resolved.account media
                        |> Task.attempt (GotDeleteResult media)
                    , ( Nothing, Nothing )
                    )

                Err err ->
                    ( { model | deleteError = Just err }, Cmd.none, ( Nothing, Nothing ) )

        GotDeleteResult media (Ok ( maybeAccountsPanelMsg, _ )) ->
            -- Re-fetch rather than just filtering `media` out of `Fetched`'s
            -- own list locally -- same reasoning `GotUploadResult` gives for
            -- doing the same after an upload. Also leaves `status` alone
            -- (see that same comment) -- deliberately so, since it's what
            -- lets the just-deleted tile's own removing-fade actually play
            -- (see `GotMediaResult`'s doc) instead of the whole grid
            -- unmounting to "Loading…" and back around it.
            let
                clearedModel =
                    { model | deletingIds = Set.remove media.id model.deletingIds }
            in
            case resolve accountsPanelModel model.targetHost of
                Ok resolved ->
                    ( { clearedModel | status = Fetching }
                    , fetchTask accountsPanelModel resolved.account |> Task.attempt GotMediaResult
                    , ( maybeAccountsPanelMsg, Nothing )
                    )

                Err _ ->
                    ( clearedModel, Cmd.none, ( maybeAccountsPanelMsg, Nothing ) )

        GotDeleteResult media (Err err) ->
            ( { model
                | deletingIds = Set.remove media.id model.deletingIds
                , deleteError = Just (AccountsPanel.grpcErrorToString err)
              }
            , Cmd.none
            , ( Nothing, Nothing )
            )

        AnimateItemFlip animMsg ->
            let
                step id anim ( animations, accCmds ) =
                    let
                        ( newFlip, cmd ) =
                            UI.Flip.animate animMsg anim.flip
                    in
                    ( Dict.insert id { anim | flip = newFlip } animations, cmd :: accCmds )

                ( newMediaAnimations, cmds ) =
                    Dict.foldl step ( Dict.empty, [] ) model.mediaAnimations
            in
            ( { model | mediaAnimations = newMediaAnimations }, Cmd.batch cmds, ( Nothing, Nothing ) )

        RemoveMediaAnimation id ->
            ( { model | mediaAnimations = Dict.remove id model.mediaAnimations }
            , Cmd.none
            , ( Nothing, Nothing )
            )

        ZoomChanged zoom ->
            ( { model | zoom = zoom }, Cmd.none, ( Nothing, Nothing ) )


{-| Reconciles `mediaAnimations` with `status`'s current `Fetched` list:
starts a fade-in for newly-seen media (a fresh `Open`, or a just-uploaded
item once its post-upload refetch lands), a fade-out for media no longer
present (a just-deleted item, once _its_ refetch lands), and un-interrupts a
still-fading-out item that reappeared. Only ever called from `GotMediaResult`
-- deliberately _not_ whenever `status` merely passes through `Fetching`
(e.g. `GotUploadResult`/`GotDeleteResult` kicking off their own refetch),
since that's a transient state with no real `Fetched` list of its own to
reconcile against -- calling this then would read every currently-tracked
tile as "gone" and fade the whole grid out for the length of every refetch.
Mirrors `Components.Pages.UsersPage.syncAnimations` -- see its own doc --
keyed by `Media.id` instead.
-}
syncMediaAnimations : Model -> Model
syncMediaAnimations model =
    let
        currentMedia : Dict String Media
        currentMedia =
            case model.status of
                Fetched media ->
                    media |> List.map (\m -> ( m.id, m )) |> Dict.fromList

                _ ->
                    Dict.empty

        addOrRefresh id media animations =
            case Dict.get id animations of
                Nothing ->
                    Dict.insert id { media = media, flip = UI.Flip.enter } animations

                Just anim ->
                    if anim.flip.removing then
                        Dict.insert id { media = media, flip = UI.Flip.reappear anim.flip } animations

                    else
                        Dict.insert id { anim | media = media } animations

        withCurrent =
            Dict.foldl addOrRefresh model.mediaAnimations currentMedia

        startRemovingIfGone id anim animations =
            if anim.flip.removing || Dict.member id currentMedia then
                animations

            else
                Dict.insert id { anim | flip = UI.Flip.remove (RemoveMediaAnimation id) anim.flip } animations
    in
    { model | mediaAnimations = Dict.foldl startRemovingIfGone withCurrent withCurrent }


{-| The `Sub` driving every tile's enter/leave fade -- gated on `isOpen`
(unlike e.g. `Shared.StarredPostsPanel.subscriptions`' own `AnimateItemFlip`
sub, this panel's tiles only ever render while it's open, so nothing outside
`view` could still be mid-animation once it's closed).
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    if isOpen model then
        UI.Flip.subscription AnimateItemFlip (Dict.values model.mediaAnimations |> List.map .flip)

    else
        Sub.none


{-| Shared by `GotFile`/`Drop` -- resolves `targetHost` again (same check
`Open` makes) since either can land well after the account this panel was
opened for stopped being usable (signed out mid-pick, server disabled, ...).
-}
startUpload : AccountsPanel.Model -> Model -> File -> ( Model, Cmd Msg, ( Maybe AccountsPanel.Msg, Maybe Media ) )
startUpload accountsPanelModel model file =
    case resolve accountsPanelModel model.targetHost of
        Ok resolved ->
            ( { model | uploadStatus = Uploading file }
            , uploadTask accountsPanelModel resolved model.targetHost file
                |> Task.attempt GotUploadResult
            , ( Nothing, Nothing )
            )

        Err err ->
            ( { model | uploadStatus = UploadFailed file err }, Cmd.none, ( Nothing, Nothing ) )


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
backend's "no user\_id means the caller's own media" fallback, keeps this
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


{-| The `DeleteMedia` RPC (`protos/jonline.proto`) takes a `Media`, but
`backend/src/rpcs/media/delete_media.rs` only ever looks at its `id` --
`defaultMedia` fills in the rest with placeholders nothing on the backend
reads. Its response is `google.protobuf.Empty`; mapped away to `()` here
purely so `GotDeleteResult` doesn't need its own import of that type.
-}
deleteTask : AccountsPanel.Model -> AccountsPanel.Account -> Media -> Task Grpc.Error ( Maybe AccountsPanel.Msg, () )
deleteTask accountsPanelModel account media =
    AccountsPanel.performWithAccountServer
        accountsPanelModel
        ( Just account.userId, account.server )
        (\server token ->
            Grpc.new Jonline.deleteMedia { defaultMedia | id = media.id }
                |> Grpc.setHost (AccountsPanel.serverUrl server)
                |> withAccessToken (Just token)
                |> Grpc.toTask
                |> Task.map (always ())
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
all on an element that didn't call `preventDefault` on the _last_ `dragover`
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
            [ span [ class "my-media-panel-title" ] [ text (headerTitle model.selectionType) ]
            , div [ class "my-media-panel-header-right" ]
                [ uploadStatusView model.uploadStatus
                , deleteStatusView model.deleteError
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
        , if hasMedia model then
            zoomSliderView model

          else
            text ""
        ]


{-| Whether `contentView` currently has a non-empty grid worth zooming --
gates `zoomSliderView` (see `view`), which would otherwise float uselessly
over "Loading…"/"No media yet."/error text. Reads `mediaAnimations` rather
than `status` directly so the slider stays put through a last remaining
tile's own delete fade-out, instead of vanishing out from under the user's
cursor the instant `status` itself goes empty.
-}
hasMedia : Model -> Bool
hasMedia model =
    not (Dict.isEmpty model.mediaAnimations)


{-| "My Media" in plain Browse mode, "Select Media" while `selectionType` is
`Just` anything -- see module doc.
-}
headerTitle : Maybe SelectionType -> String
headerTitle selectionType =
    case selectionType of
        Just _ ->
            "Select Media"

        Nothing ->
            "My Media"


{-| Whether `media` belongs in the grid at all under `selectionType` -- only
`SingleSelect`'s `imagesOnly` ever excludes anything (any media type is fine
in Browse mode or under a future `imagesOnly = False` chooser); mirrors
`Components.MediaRenderer.view`'s own content-type switch, which already
only ever attaches a click handler to images in the first place.
-}
mediaAllowed : Maybe SelectionType -> Media -> Bool
mediaAllowed selectionType media =
    case selectionType of
        Just (SingleSelect { imagesOnly }) ->
            not imagesOnly || String.startsWith "image/" media.contentType

        Just MultiSelect ->
            True

        Nothing ->
            True


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


{-| Per `File.decoder`'s own doc example.
-}
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


{-| `uploadStatusView`'s counterpart for `deleteError` -- deletes don't have
an in-progress message of their own here (that's shown inline on the item
itself, see `mediaItemView`'s "Deleting…"), only a failure.
-}
deleteStatusView : Maybe String -> Html Msg
deleteStatusView deleteError =
    case deleteError of
        Nothing ->
            text ""

        Just err ->
            span [ classes [ "my-media-panel-upload-status", "my-media-panel-upload-error" ] ]
                [ text ("Couldn't delete: " ++ err) ]


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
            let
                orderedAnimations =
                    mediaAnimationsInOrder model
                        |> List.filter (\( _, anim ) -> mediaAllowed model.selectionType anim.media)
            in
            if not (List.isEmpty orderedAnimations) then
                -- Keeps the grid itself mounted (so already-there tiles keep
                -- their DOM nodes, key for key) through a *re*-fetch's own
                -- transient `Fetching` -- `GotUploadResult`/`GotDeleteResult`
                -- both set `status` back to `Fetching` while their own
                -- refetch is in flight (see `update`). Swapping the whole
                -- grid out for a "Loading…" message and back, as a plain
                -- `case model.status of` would, unmounts and remounts every
                -- tile in between -- a freshly-mounted node has no prior
                -- frame to transition *from*, so `syncMediaAnimations`
                -- marking a just-deleted tile `removing` right as it
                -- remounts would just render it already-collapsed instead of
                -- animating the collapse. `status` still gates *which*
                -- `Fetching`/`FetchFailed`/`NotFetched` message to show
                -- below -- just only once there's nothing left to show in
                -- its place.
                [ Html.Keyed.node "div"
                    [ classes [ "my-media-panel-grid", "flip-animated-grid" ]

                    -- Read by `my_media_panel.css`'s own override of
                    -- `.media-renderer-extra-small`'s fixed max-width/
                    -- height (see `media.css`) -- letting `zoomSliderView`
                    -- resize every item without `MediaRenderer` itself
                    -- needing a third, continuously-sized `Sizing`.
                    --
                    -- This has to go through `attribute "style"` (a raw
                    -- style-attribute *string*, parsed by the browser's
                    -- own CSS parser) rather than `Html.Attributes.style`
                    -- -- elm/virtual-dom applies the latter as
                    -- `domNode.style[key] = value` (plain bracket
                    -- assignment), which silently no-ops for a custom
                    -- property (`--*`) key: the DOM only picks up custom
                    -- properties set via `style.setProperty` or, as here,
                    -- parsed from the attribute string. A named property
                    -- like `color` works with either, which is why this
                    -- doesn't show up anywhere else in this codebase.
                    , attribute "style" ("--my-media-zoom-size: " ++ String.fromFloat model.zoom ++ "px;")
                    ]
                    (List.map (mediaAnimationView resolved.server resolved.account model) orderedAnimations)
                ]

            else
                case model.status of
                    NotFetched ->
                        []

                    Fetching ->
                        [ div [ class "my-media-panel-message" ] [ text "Loading…" ] ]

                    FetchFailed err ->
                        [ div [ class "my-media-panel-message" ] [ text err ] ]

                    Fetched _ ->
                        [ div [ class "my-media-panel-message" ] [ text "No media yet." ] ]


{-| `mediaAnimations` in display order: every currently-`Fetched` id in that
list's own order, followed by any id that's only still around because it's
mid removing-fade (a just-deleted item -- see `syncMediaAnimations`) --
grouping fading-out tiles at the end rather than trying to preserve their
exact prior slot, since nothing here tracks a stable position for an id once
it's dropped out of `status`'s own list.
-}
mediaAnimationsInOrder : Model -> List ( String, MediaAnimation )
mediaAnimationsInOrder model =
    let
        fetchedOrder =
            case model.status of
                Fetched media ->
                    List.map .id media

                _ ->
                    []

        removingOnlyIds =
            model.mediaAnimations
                |> Dict.toList
                |> List.filter (\( id, anim ) -> anim.flip.removing && not (List.member id fetchedOrder))
                |> List.map Tuple.first
    in
    (fetchedOrder ++ removingOnlyIds)
        |> List.filterMap (\id -> Dict.get id model.mediaAnimations |> Maybe.map (\anim -> ( id, anim )))


{-| Wraps `mediaItemView` in a fading/scaling/collapsing animated outer `div`
(entering when freshly uploaded/loaded, removing when deleted -- see
`mediaAnimations`) -- the `UI.Flip.Horizontal` axis matches the grid's own
left-to-right, wrap-to-next-row flow (see `flip.css`'s `.flip-animated-grid`
doc). Mirrors `UI.serverChipFlip` -- see its own doc.
-}
mediaAnimationView : AccountsPanel.Server -> AccountsPanel.Account -> Model -> ( String, MediaAnimation ) -> ( String, Html Msg )
mediaAnimationView server account model ( mediaId, anim ) =
    let
        pointerEventsAttr =
            if anim.flip.removing then
                [ style "pointer-events" "none" ]

            else
                []
    in
    ( mediaId
    , div (UI.Flip.itemAttributes UI.Flip.Horizontal anim.flip False)
        [ div pointerEventsAttr [ mediaItemView server account model.deletingIds anim.media ] ]
    )


mediaItemView : AccountsPanel.Server -> AccountsPanel.Account -> Set String -> Media -> Html Msg
mediaItemView server account deletingIds media =
    let
        deleting =
            Set.member media.id deletingIds
    in
    div [ class "my-media-panel-item" ]
        [ div [ class "my-media-panel-item-preview" ]
            [ MediaRenderer.view MediaRenderer.ExtraSmall server (Just account) MediaItemClicked (toMediaReference media)
            , button
                [ classes [ "remove-btn", "my-media-panel-item-delete" ]
                , onClick (DeleteClicked media)
                , disabled deleting
                , title "Delete this media"
                ]
                [ text "╳" ]
            ]
        , div [ class "my-media-panel-item-name" ] [ text (Maybe.withDefault "Untitled" media.name) ]
        , div [ class "my-media-panel-item-type" ]
            [ text
                (if deleting then
                    "Deleting…"

                 else
                    media.contentType
                )
            ]
        ]


{-| Floats over `.my-media-panel-content`'s own scrolling (see
`my_media_panel.css`'s `.my-media-panel-zoom`, `position: absolute` within
this panel's `position: fixed` root) rather than sitting inline in the
header/content flow, so it stays reachable at a constant spot regardless of
how far the grid's scrolled. Drives every item's size via a CSS custom
property rather than each `input` event re-rendering the whole grid through
`Sizing` -- see `contentView`'s `Fetched` branch.
-}
zoomSliderView : Model -> Html Msg
zoomSliderView model =
    div [ class "my-media-panel-zoom" ]
        [ span [ class "my-media-panel-zoom-icon" ] [ text "🔍" ]
        , input
            [ type_ "range"
            , Html.Attributes.min "72"
            , Html.Attributes.max "480"
            , step "8"
            , value (String.fromFloat model.zoom)
            , onInput (\v -> ZoomChanged (String.toFloat v |> Maybe.withDefault model.zoom))
            , title "Preview size"
            ]
            []
        ]
