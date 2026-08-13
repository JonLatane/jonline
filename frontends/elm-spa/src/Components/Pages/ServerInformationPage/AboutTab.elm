module Components.Pages.ServerInformationPage.AboutTab exposing (AdminsStatus(..), Model, Msg, VersionStatus(..), applySharedMsg, init, update, view)

{-| The About tab of `Components.Pages.ServerInformationPage` -- the server's name (renameable by
an admin, via `Shared.AccountsPanel.RenameServerClicked` so the app's cached `Server` list stays in
sync), its description/privacy policy/media policy (each editable in place through the shared
`Shared.MarkdownPanel` panel, same edit-in-panel/Save flow as post content on `Pages.Post.PostId_`),
its version, and its admin list.

`AdminsStatus`/`VersionStatus` are fetched by the parent module (as soon as a server's known,
regardless of which tab is active -- see `ServerInformationPage.fetchAdmins`/`fetchVersion`), not
here; this module only owns how they're *displayed*, exposing the two types so the parent's own
`Model`/`Msg` can hold/produce them without a circular import.
-}

import Components.Markdown as Markdown
import Components.Pages.ServerInformationPage.Common as Common
import Components.Users as Users
import Effect exposing (Effect)
import Html exposing (Html, button, div, h2, h3, input, p, text)
import Html.Attributes exposing (class, disabled, value)
import Html.Events exposing (onClick, onInput)
import Proto.Jonline exposing (User)
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.MarkdownPanel as MarkdownPanel



-- MODEL


type alias Model =
    { renameStatus : RenameStatus
    }


type Msg
    = RenameClicked String
    | RenameChanged String
    | RenameCancelClicked
    | RenameSaveClicked
    | EditDescriptionClicked AccountsPanel.Server
    | EditPrivacyPolicyClicked AccountsPanel.Server
    | EditMediaPolicyClicked AccountsPanel.Server


{-| Live only while the server's name is being edited by an admin -- `pending` is the in-progress
`<input>` value, independent of the actual name until `RenameSaveClicked` succeeds. Mirrors
`Pages.Post.PostId_`'s `VisibilityEdit`.
-}
type RenameStatus
    = NotRenaming
    | Renaming String AccountsPanel.FormStatus


type AdminsStatus
    = AdminsNotLoaded
    | LoadingAdmins
    | AdminsLoaded (List User)
    | AdminsFailed


type VersionStatus
    = VersionNotLoaded
    | LoadingVersion
    | VersionLoaded String
    | VersionFailed


init : Model
init =
    { renameStatus = NotRenaming }



-- UPDATE


update : Shared.Model -> String -> Msg -> Model -> ( Model, Effect Msg )
update shared targetHost msg model =
    case msg of
        RenameClicked currentName ->
            ( { model | renameStatus = Renaming currentName AccountsPanel.Idle }, Effect.none )

        RenameChanged newText ->
            ( { model
                | renameStatus =
                    case model.renameStatus of
                        Renaming _ status ->
                            Renaming newText status

                        NotRenaming ->
                            NotRenaming
              }
            , Effect.none
            )

        RenameCancelClicked ->
            ( { model | renameStatus = NotRenaming }, Effect.none )

        RenameSaveClicked ->
            case ( model.renameStatus, Common.adminAccountFor shared targetHost ) of
                ( Renaming pendingName _, Just account ) ->
                    ( { model | renameStatus = Renaming pendingName AccountsPanel.Submitting }
                    , Effect.fromShared (Shared.AccountsPanelMsg (AccountsPanel.RenameServerClicked (AccountsPanel.accountId account) pendingName))
                    )

                _ ->
                    ( model, Effect.none )

        EditDescriptionClicked server ->
            ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.ServerDescription server) targetHost)) )

        EditPrivacyPolicyClicked server ->
            ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.ServerPrivacyPolicy server) targetHost)) )

        EditMediaPolicyClicked server ->
            ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.ServerMediaPolicy server) targetHost)) )


{-| Reacts to a `Shared.Msg` forwarded through by the parent's own `SharedMsg` branch -- only
`AccountsPanel.GotRenameServerResult` (the Rename save's own result) matters here; everything else
leaves `renameStatus` untouched.
-}
applySharedMsg : Shared.Msg -> Model -> Model
applySharedMsg subMsg model =
    { model
        | renameStatus =
            case subMsg of
                Shared.AccountsPanelMsg (AccountsPanel.GotRenameServerResult _ (Ok _)) ->
                    NotRenaming

                Shared.AccountsPanelMsg (AccountsPanel.GotRenameServerResult _ (Err err)) ->
                    case model.renameStatus of
                        Renaming pending _ ->
                            Renaming pending (AccountsPanel.Errored (AccountsPanel.grpcErrorToString err))

                        NotRenaming ->
                            NotRenaming

                _ ->
                    model.renameStatus
    }



-- VIEW


view : Shared.Model -> AccountsPanel.Server -> Maybe AccountsPanel.Account -> AdminsStatus -> VersionStatus -> Model -> Html Msg
view shared server maybeAdminAccount adminsStatus versionStatus model =
    let
        info : Proto.Jonline.ServerInfo
        info =
            AccountsPanel.serverInfoOf server

        name : String
        name =
            Maybe.withDefault server.frontendHost info.name
    in
    div [ class "server-details-tab-content server-details-about" ]
        [ h2 [ class "server-details-name" ] (nameView name model.renameStatus maybeAdminAccount)
        , versionView versionStatus
        , policySectionView "server-details-description" Nothing (EditDescriptionClicked server) maybeAdminAccount info.description
        , policySectionView "server-details-policy" (Just "Privacy Policy") (EditPrivacyPolicyClicked server) maybeAdminAccount info.privacyPolicy
        , policySectionView "server-details-policy" (Just "Media Policy") (EditMediaPolicyClicked server) maybeAdminAccount info.mediaPolicy
        , adminsView shared server adminsStatus
        ]


{-| One about-tab Markdown field backed by `Shared.MarkdownPanel` -- `description` (`heading =
Nothing`) or `privacyPolicy`/`mediaPolicy` (each headed). Renders nothing for a non-admin viewer
when the field's unset, same as before this page supported editing it; an admin sees an "Edit"
button either way -- even when unset, so they can set it for the first time, not just change
existing text -- mirroring `nameView`'s Rename button.
-}
policySectionView : String -> Maybe String -> Msg -> Maybe AccountsPanel.Account -> Maybe String -> Html Msg
policySectionView sectionClass heading editClicked maybeAdminAccount content =
    case ( content, maybeAdminAccount ) of
        ( Nothing, Nothing ) ->
            text ""

        _ ->
            div [ class sectionClass ]
                [ case heading of
                    Just headingText ->
                        h3 [] [ text headingText ]

                    Nothing ->
                        text ""
                , case content of
                    Just markdown ->
                        Markdown.view [] markdown

                    Nothing ->
                        p [ class "server-details-policy-unset" ] [ text "Not set." ]
                , case maybeAdminAccount of
                    Just _ ->
                        button [ class "server-details-rename-button", onClick editClicked ] [ text "Edit" ]

                    Nothing ->
                        text ""
                ]


nameView : String -> RenameStatus -> Maybe AccountsPanel.Account -> List (Html Msg)
nameView name renameStatus maybeAdminAccount =
    case ( renameStatus, maybeAdminAccount ) of
        ( Renaming pendingName status, Just _ ) ->
            [ input
                [ class "server-details-rename-input"
                , value pendingName
                , onInput RenameChanged
                , disabled (status == AccountsPanel.Submitting)
                ]
                []
            , Common.editSaveButton RenameSaveClicked status
            , Common.editCancelButton RenameCancelClicked status
            , Common.editErrorView status
            ]

        _ ->
            [ text name
            , case maybeAdminAccount of
                Just _ ->
                    button [ class "server-details-rename-button", onClick (RenameClicked name) ] [ text "Rename" ]

                Nothing ->
                    text ""
            ]


versionView : VersionStatus -> Html Msg
versionView status =
    case status of
        VersionNotLoaded ->
            text ""

        LoadingVersion ->
            text ""

        VersionLoaded version ->
            p [ class "server-details-version" ] [ text ("v" ++ version) ]

        VersionFailed ->
            text ""


adminsView : Shared.Model -> AccountsPanel.Server -> AdminsStatus -> Html Msg
adminsView shared server status =
    div [ class "server-details-admins" ]
        [ h3 [] [ text "Admins" ]
        , case status of
            AdminsNotLoaded ->
                text ""

            LoadingAdmins ->
                p [] [ text "Loading admins…" ]

            AdminsFailed ->
                p [] [ text "Couldn't load admins." ]

            AdminsLoaded [] ->
                p [] [ text "No admins found." ]

            AdminsLoaded admins ->
                div [ class "users-list" ] (List.map (adminCardView shared server) admins)
        ]


{-| One admin's `Users.userCard` -- links to that admin's profile (same card used by
`Components.Pages.UsersPage`'s People/Following/Followers/Friends listings), with no
follow-status/button slot (`text ""`) since this page is otherwise entirely read-only (see the
module doc) and doesn't track any per-card `FollowStatusAndButton.Model` state to back one.
-}
adminCardView : Shared.Model -> AccountsPanel.Server -> User -> Html Msg
adminCardView shared server user =
    Users.userCard shared.basePath
        shared.accounts.mainFrontendHost
        server
        (AccountsPanel.enabledAccountForServer shared.accounts.accounts server.frontendHost)
        (text "")
        user
