module Shared.MarkdownPanel exposing (Model, Msg(..), TargetType(..), ViewMode(..), init, update, view)

{-| A single, app-wide Markdown editor: a plain monospace `<textarea>` and a
live `Components.Markdown.view` preview of the same text, with "Save"/
"Cancel" actions below. Shown side by side, or either alone, per `ViewMode`
(a 3-position slider in the header lets the user pick -- see `modeSlider`),
since a 50/50 split doesn't leave enough room for either half on a
phone-width screen. Wired into `Shared.Model`/`UI.elm` the same way
`Shared.AccountsPanel`/`Shared.StarredPostsPanel` are -- one shared instance,
opened from wherever it's needed (see `TargetType`) rather than each caller
owning its own editor state.

Knows how to edit/submit a `Proto.Jonline.Post`'s `content` (via `TargetType`)
-- editing a `Post` already in hand (`PostContent`), or composing a brand new
reply to one (`NewReply`) -- or a `Proto.Jonline.User`'s `bio` (`UserBio`, see
`Components.UserProfilePage`). More `TargetType` constructors can be added
later without touching callers that only care about the ones they use.

-}

import Components.Markdown as Markdown
import Components.Posts as Posts
import Components.Users as Users
import Grpc
import Html exposing (Html, button, div, img, span, text, textarea)
import Html.Attributes exposing (alt, attribute, class, disabled, placeholder, spellcheck, src, value)
import Html.Events exposing (onClick, onInput)
import Proto.Jonline exposing (Post, User, defaultGetPostsRequest, defaultPost)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.Permission exposing (Permission(..))
import Proto.Jonline.PostContext exposing (PostContext(..))
import Shared.AccountsPanel as AccountsPanel exposing (withAccessToken)
import Task exposing (Task)
import UI.Classes exposing (classes, openClosedClass)


{-| What a save should do once the user's done editing: `PostContent post`
overwrites `post`'s own content (via `UpdatePost`, re-fetching `post` fresh
first -- see `saveTask` -- so a stale in-hand copy can't clobber any of its
other fields, e.g. `visibility`, that changed server-side since this panel was
opened); `NewReply post` creates a brand new reply to `post` (via `CreatePost`,
`reply_to_post_id = post.id`), copying `post`'s own `visibility` for the new
reply; `UserBio user` overwrites `user`'s own `bio` (via `Users.updateUser`,
which does the same re-fetch-then-overwrite dance as `PostContent`).
-}
type TargetType
    = PostContent Post
    | NewReply Post
    | UserBio User


type SubmitStatus
    = Idle
    | Submitting
    | SubmitFailed String


{-| Which half(s) of `markdown-panel-split` to actually render -- `Split`
(the default) is the original editor+preview side by side; `TextOnly`/
`MarkdownOnly` give the full width to just one, which is what actually makes
this panel usable on a phone-width screen (see the mode slider in `view`).
-}
type ViewMode
    = TextOnly
    | Split
    | MarkdownOnly


type alias Model =
    { target : Maybe TargetType

    -- The `frontendHost` of the server `target`'s Post lives on -- needed to
    -- resolve the `AccountsPanel.Server`/signed-in `Account` to submit as,
    -- and to verify (see `resolve`) that server's still enabled and that
    -- account still has the relevant permission, right before submitting.
    , targetHost : String
    , content : String
    , status : SubmitStatus

    -- Deliberately *not* reset back to `Split` by `CancelClicked`/a
    -- successful save (see `update`) -- it's a standing display preference,
    -- not part of the in-progress edit, so it should carry over the next
    -- time this panel's opened.
    , viewMode : ViewMode
    }


init : Model
init =
    { target = Nothing
    , targetHost = ""
    , content = ""
    , status = Idle
    , viewMode = Split
    }


type Msg
    = Open TargetType String
    | ContentChanged String
    | ViewModeSelected ViewMode
    | CancelClicked
    | SaveClicked
    | GotSaveResult (Result Grpc.Error (Maybe AccountsPanel.Msg))


{-| Needs `AccountsPanel.Model` (to resolve `targetHost` to a connected
`Server`/signed-in `Account` to submit as, and to verify -- see `resolve` --
that they're actually usable) and can itself surface an `AccountsPanel.Msg` it
needs forwarded on its behalf -- an `AccessTokenResponseReceived`, if
`saveTask` had to refresh the account's token, that `AccountsPanel.performWithAccountServer`
already builds -- for `Shared.update` to actually dispatch, same convention as
`Shared.StarredPostsPanel.update` -- paired, in that same third-tuple-slot
convention, with a `Bool` that's `True` only right after a successful save:
`Shared.update` fires `Shared.ShowScrollPreserver` on it, since the edited
Post's re-fetched content (see `saveTask`) can change its rendered height
once this panel closes and the page under it catches up, same yank
`Shared.ShowScrollPreserver` already guards against on back navigation.
-}
update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, ( Maybe AccountsPanel.Msg, Bool ) )
update accountsPanelModel msg model =
    case msg of
        Open target host ->
            ( { model
                | target = Just target
                , targetHost = host
                , content = initialContent target
                , status = Idle
              }
            , Cmd.none
            , ( Nothing, False )
            )

        ContentChanged content ->
            ( { model | content = content }, Cmd.none, ( Nothing, False ) )

        ViewModeSelected viewMode ->
            ( { model | viewMode = viewMode }, Cmd.none, ( Nothing, False ) )

        CancelClicked ->
            ( { init | viewMode = model.viewMode }, Cmd.none, ( Nothing, False ) )

        SaveClicked ->
            case model.target of
                Just target ->
                    case resolve accountsPanelModel target model.targetHost of
                        Ok resolved ->
                            ( { model | status = Submitting }
                            , saveTask accountsPanelModel ( Just resolved.account.userId, resolved.server.frontendHost ) target model.content
                                |> Task.attempt GotSaveResult
                            , ( Nothing, False )
                            )

                        Err err ->
                            ( { model | status = SubmitFailed err }, Cmd.none, ( Nothing, False ) )

                Nothing ->
                    ( model, Cmd.none, ( Nothing, False ) )

        GotSaveResult (Ok maybeAccountsPanelMsg) ->
            ( { init | viewMode = model.viewMode }, Cmd.none, ( maybeAccountsPanelMsg, True ) )

        GotSaveResult (Err err) ->
            ( { model | status = SubmitFailed (AccountsPanel.grpcErrorToString err) }, Cmd.none, ( Nothing, False ) )


initialContent : TargetType -> String
initialContent target =
    case target of
        PostContent post ->
            Maybe.withDefault "" post.content

        NewReply _ ->
            ""

        UserBio user ->
            user.bio


type alias Resolved =
    { server : AccountsPanel.Server
    , account : AccountsPanel.Account
    }


{-| Verifies `host`/`target` are actually usable right now, right before a
save: (1) `host` resolves to a known `Server` that's currently enabled (a
disabled server shouldn't be posted/edited to just because this panel was
opened before it was disabled), and (2) the account signed into that server
has the relevant permission for `target` -- the post's own author for
`PostContent` (matching `backend/src/rpcs/posts/update_post.rs`'s
`self_update` check), `REPLYTOPOSTS` for `NewReply`, or the user themself/an
`ADMIN` for `UserBio` (matching `backend/src/rpcs/users/update_user.rs`'s own
`self_update || admin` check). Used both by `SaveClicked` (to actually gate
the RPC) and by `view` (to show the same problem inline, and disable Save,
before the user even tries).
-}
resolve : AccountsPanel.Model -> TargetType -> String -> Result String Resolved
resolve accountsPanelModel target host =
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
                        case target of
                            PostContent post ->
                                if Posts.isAuthor account post then
                                    Ok { server = server, account = account }

                                else
                                    Err "You can only edit your own posts."

                            NewReply _ ->
                                if List.member REPLYTOPOSTS account.permissions then
                                    Ok { server = server, account = account }

                                else
                                    Err "You don't have permission to reply."

                            UserBio user ->
                                if account.userId == user.id || List.member ADMIN account.permissions then
                                    Ok { server = server, account = account }

                                else
                                    Err "You can only edit your own bio."


{-| `PostContent` re-fetches its Post fresh (via `GetPosts`) before submitting
`UpdatePost` -- only `content` from `model.content` is overlaid onto that fresh
copy, so any of its other fields (`visibility`, `media`, ...) that changed
server-side since this panel opened aren't clobbered by a stale in-hand
snapshot (`UpdatePost` takes -- and unconditionally applies -- a whole `Post`,
see `backend/src/rpcs/posts/update_post.rs`). `NewReply` has no such race to
guard against -- it's creating a brand new Post, not overwriting an existing
one -- so it submits straight from the `post` it was opened with. `UserBio`
does the same re-fetch-then-overwrite dance as `PostContent`, via
`Users.updateUser`. Only a `Msg` to dispatch (if a token refresh happened) is
returned -- none of these three cases' updated entities are used by any
caller (see `Pages.Post.PostId_`/`Components.UserProfilePage`'s
`GotSaveResult` handling, which just refetches their own copy on success).
-}
saveTask : AccountsPanel.Model -> AccountsPanel.MaybeAccountServer -> TargetType -> String -> Task Grpc.Error (Maybe AccountsPanel.Msg)
saveTask accountsPanelModel maybeAccountServer target content =
    case target of
        PostContent post ->
            AccountsPanel.performWithAccountServer
                accountsPanelModel
                maybeAccountServer
                (\server token ->
                    Grpc.new Jonline.getPosts { defaultGetPostsRequest | postId = Just post.id }
                        |> Grpc.setHost (AccountsPanel.serverUrl server)
                        |> withAccessToken (Just token)
                        |> Grpc.toTask
                        |> Task.andThen
                            (\response ->
                                case List.head response.posts of
                                    Just freshPost ->
                                        Grpc.new Jonline.updatePost { freshPost | content = Just content }
                                            |> Grpc.setHost (AccountsPanel.serverUrl server)
                                            |> withAccessToken (Just token)
                                            |> Grpc.toTask

                                    Nothing ->
                                        Task.fail Grpc.NetworkError
                            )
                )
                |> Task.map Tuple.first

        NewReply post ->
            AccountsPanel.performWithAccountServer
                accountsPanelModel
                maybeAccountServer
                (\server token ->
                    Grpc.new Jonline.createPost
                        { defaultPost
                            | replyToPostId = Just post.id
                            , content = Just content
                            , context = REPLY
                            , visibility = post.visibility
                        }
                        |> Grpc.setHost (AccountsPanel.serverUrl server)
                        |> withAccessToken (Just token)
                        |> Grpc.toTask
                )
                |> Task.map Tuple.first

        UserBio user ->
            Users.updateUser accountsPanelModel maybeAccountServer user.id (\freshUser -> { freshUser | bio = content })
                |> Task.map Tuple.first



-- VIEW


{-| Always rendered (even "closed"), same as `UI.elm`'s Accounts/Starred Posts
panels, so opening/closing is a plain CSS transition -- see `openClosedClass`.
Needs `AccountsPanel.Model` for the same reason `update` does -- resolving
`targetHost` to show who's actually about to post/edit (`accountRow`), and any
problem with that (`resolve`) inline, before the user even taps Save.
-}
view : AccountsPanel.Model -> Model -> Html Msg
view accountsPanelModel model =
    let
        resolution =
            model.target |> Maybe.map (\target -> resolve accountsPanelModel target model.targetHost)

        canSave =
            case resolution of
                Just (Ok _) ->
                    True

                _ ->
                    False

        errorMessage =
            case model.status of
                SubmitFailed err ->
                    Just err

                _ ->
                    case resolution of
                        Just (Err err) ->
                            Just err

                        _ ->
                            Nothing
    in
    div [ classes [ "markdown-panel", "nav-panel", openClosedClass (model.target /= Nothing) ] ]
        [ div [ class "markdown-panel-header" ]
            [ modeSlider model.targetHost model.viewMode
            , accountRow accountsPanelModel model
            ]
        , div [ classes [ "markdown-panel-split", viewModeClass model.viewMode ] ]
            (case model.viewMode of
                TextOnly ->
                    [ editorView model ]

                Split ->
                    [ editorView model, previewView model ]

                MarkdownOnly ->
                    [ previewView model ]
            )
        , case errorMessage of
            Just err ->
                div [ class "markdown-panel-error" ] [ text err ]

            Nothing ->
                text ""
        , div [ class "markdown-panel-actions" ]
            [ button
                [ class "markdown-panel-cancel"
                , onClick CancelClicked
                , disabled (model.status == Submitting)
                ]
                [ text "Cancel" ]
            , button
                [ classes [ "markdown-panel-save", model.targetHost, "background-color-primary" ]
                , onClick SaveClicked
                , disabled (model.status == Submitting || not canSave)
                ]
                [ text
                    (if model.status == Submitting then
                        "Saving…"

                     else
                        "Save"
                    )
                ]
            ]
        ]


editorView : Model -> Html Msg
editorView model =
    textarea
        [ class "markdown-panel-editor"
        , value model.content
        , onInput ContentChanged
        , spellcheck False
        , placeholder "Write some Markdown…"
        ]
        []


previewView : Model -> Html Msg
previewView model =
    Markdown.view [ class "markdown-panel-preview" ] model.content


viewModeClass : ViewMode -> String
viewModeClass mode =
    case mode of
        TextOnly ->
            "mode-text"

        Split ->
            "mode-split"

        MarkdownOnly ->
            "mode-markdown"


{-| A single sliding 3-position control -- Text / Split / Markdown -- rather
than three separate buttons, so the "which one's active" state reads as one
moving thumb (`markdown-panel-mode-thumb`, positioned purely in CSS off
`viewModeClass`) instead of three independently-highlighted pills. Small
enough to sit centered under the title/account row on a phone-width screen
(see markdown\_panel.css).
-}
modeSlider : String -> ViewMode -> Html Msg
modeSlider targetHost mode =
    div [ classes [ "markdown-panel-mode-slider", viewModeClass mode ] ]
        [ div [ classes [ "markdown-panel-mode-thumb", targetHost, "background-color-primary" ] ] []
        , modeOption mode TextOnly "Text"
        , modeOption mode Split "Split"
        , modeOption mode MarkdownOnly "Preview"
        ]


modeOption : ViewMode -> ViewMode -> String -> Html Msg
modeOption current target label =
    button
        [ classes
            ("markdown-panel-mode-option"
                :: (if current == target then
                        [ "selected" ]

                    else
                        []
                   )
            )
        , onClick (ViewModeSelected target)
        ]
        [ text label ]


{-| "Editing as <avatar> username" / "Posting as <avatar> username" -- no
link, just enough to make clear which signed-in account (of possibly several
on this server) is about to make the edit/reply. Blank if `targetHost` has no
signed-in account at all -- `resolve`'s own "You're not signed in on that
server" error (see `errorMessage`) already covers that case.
-}
accountRow : AccountsPanel.Model -> Model -> Html Msg
accountRow accountsPanelModel model =
    case AccountsPanel.enabledAccountForServer accountsPanelModel.accounts model.targetHost of
        Just account ->
            div [ class "markdown-panel-account" ]
                [ text (verbFor model.target)
                , accountAvatar accountsPanelModel.servers account
                , span [ class "markdown-panel-account-name" ] [ text account.username ]
                ]

        Nothing ->
            text ""


verbFor : Maybe TargetType -> String
verbFor target =
    case target of
        Just (NewReply _) ->
            "Posting as "

        _ ->
            "Editing as "


accountAvatar : List AccountsPanel.Server -> AccountsPanel.Account -> Html msg
accountAvatar servers account =
    case AccountsPanel.accountAvatarUrl servers account of
        Just url ->
            img [ class "markdown-panel-account-avatar", src url, alt account.username, attribute "loading" "lazy" ] []

        Nothing ->
            div [ classes [ "markdown-panel-account-avatar", "placeholder" ] ] [ text (AccountsPanel.initialLetter account.username) ]
