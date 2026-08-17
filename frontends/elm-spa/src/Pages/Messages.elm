module Pages.Messages exposing (Model, Msg, fromShared, page)

{-| `/messages` -- the signed-in user's `MessagingGroup`s, expandable into
their messages, going two-pane whenever `?messaging_group=<id>[@host]` is
set (`#message-<id>` autoscrolls to a specific message once its thread
loads). Thin `Effect`/`Shared`/URL-owning wrapper around
`Components.Pages.MessagesPage`, which can't depend on `Shared` itself since
`Shared.MessagingPanel` embeds it too -- see that module's own doc.
-}

import Components.Messages as Messages
import Components.Pages.MessagesPage as MessagesPage
import Dict
import Effect exposing (Effect)
import Gen.Params.Messages exposing (Params)
import Html exposing (button, div, h2, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Page
import Request
import Shared
import Shared.AccountsPanel as AccountsPanel
import Shared.MarkdownPanel as MarkdownPanel
import Shared.MessagingPanel as MessagingPanel
import UI
import UI.Classes exposing (hostnameToCSSClass)
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared req
        , update = update shared
        , view = view shared req
        , subscriptions = subscriptions
        }


type alias Model =
    MessagesPage.Model


type Msg
    = PageMsg MessagesPage.Msg
    | SharedMsg Shared.Msg


init : Shared.Model -> Request.With Params -> ( Model, Effect Msg )
init shared req =
    let
        selectedGroup : Maybe MessagesPage.GroupRef
        selectedGroup =
            Dict.get "messaging_group" req.query
                |> Maybe.map
                    (\raw ->
                        let
                            ( groupId, host ) =
                                Messages.parseGroupRouteId shared.accounts.mainFrontendHost raw
                        in
                        { key = host ++ "|" ++ groupId, host = host, groupId = groupId }
                    )

        pendingScrollMessageId : Maybe String
        pendingScrollMessageId =
            req.url.fragment
                |> Maybe.andThen
                    (\fragment ->
                        if String.startsWith "message-" fragment then
                            Just (String.dropLeft 8 fragment)

                        else
                            Nothing
                    )

        searchText : String
        searchText =
            Dict.get "search_text" req.query |> Maybe.withDefault ""

        ( model, cmd ) =
            MessagesPage.init shared.accounts (Just { navKey = req.key, path = req.url.path }) selectedGroup pendingScrollMessageId searchText
    in
    ( model, Effect.batch [ Effect.fromCmd (Cmd.map PageMsg cmd), Effect.fromShared Shared.CloseAllPanels ] )


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        -- Intercepted before `applyPageMsg`/`MessagesPage.update` (whose own
        -- handling is a no-op, see the constructor's own doc) -- this is the
        -- one `MessagesPage.Msg` that actually needs `Shared`, which that
        -- module can't depend on itself. Opens the shared Markdown panel on
        -- a `SendNewMessage` pre-seeded with `recipients` (the other thread
        -- participants, computed at the button's own click site) and
        -- `ref.host` (a reply always sends from the same server the
        -- messaging group lives on).
        PageMsg (MessagesPage.ReplyClicked ref recipients) ->
            ( model, Effect.fromShared (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.SendNewMessage recipients) ref.host)) )

        -- A "Mark [un]read" round trip (either the auto-mark-read that
        -- fires when a thread's viewed, or the explicit "Mark unread"
        -- button, see `MessagesPage.GotMarkReadResult`'s own doc) landing
        -- while this page owns the mounted `MessagesPage.Model` -- also
        -- refreshes `Shared.MessagingPanel`'s own, *separate* embedded copy
        -- (`MessagesPage.ForceRefresh`, same "unconditionally refetch"
        -- mechanism the `SendNewMessage`-succeeded case already uses for it
        -- -- see `Shared.elm`'s own `MarkdownPanelMsg` branch, and
        -- `ForceRefresh`'s own doc on why plain `Poll` can't do this),
        -- since it doesn't otherwise learn this page's read/unread changes
        -- at all.
        PageMsg ((MessagesPage.GotMarkReadResult (Ok _)) as subMsg) ->
            let
                ( updatedModel, pageEffect ) =
                    applyPageMsg shared subMsg model
            in
            ( updatedModel
            , Effect.batch [ pageEffect, Effect.fromShared (Shared.MessagingPanelMsg (MessagingPanel.PageMsg MessagesPage.ForceRefresh)) ]
            )

        PageMsg subMsg ->
            applyPageMsg shared subMsg model

        SharedMsg subMsg ->
            let
                ( updatedModel, updateEffect ) =
                    case subMsg of
                        Shared.AccountsPanelMsg _ ->
                            applyPageMsg shared MessagesPage.Poll model

                        -- A group link clicked in the embedded `Shared.MessagingPanel`
                        -- while already on this very page -- see
                        -- `MessagesPage.EmbeddedGroupLinkClicked`'s own doc for the
                        -- full "why" (a same-path query-only URL change doesn't
                        -- otherwise reach this page's `init`/`update` at all).
                        Shared.MessagingPanelMsg (MessagingPanel.PageMsg (MessagesPage.EmbeddedGroupLinkClicked ref)) ->
                            applyPageMsg shared (MessagesPage.SyncSelectedGroup ref) model

                        -- The reverse of `PageMsg (MessagesPage.GotMarkReadResult
                        -- (Ok _))`, above -- a "Mark [un]read" round trip
                        -- completing *inside the embedded panel itself*
                        -- (open on top of this very page) refetches this
                        -- page's own, separate `Model` too, so both copies
                        -- of the same messages stay in sync regardless of
                        -- which surface the read/unread change was actually
                        -- made from.
                        Shared.MessagingPanelMsg (MessagingPanel.PageMsg (MessagesPage.GotMarkReadResult (Ok _))) ->
                            applyPageMsg shared MessagesPage.ForceRefresh model

                        -- Any Markdown panel save succeeding while this is
                        -- the mounted page -- in practice always a
                        -- `SendNewMessage`/"Reply" save, the only
                        -- `MarkdownPanel.TargetType` reachable from here at
                        -- all (`sendMessageButton`/`MessagesPage.ReplyClicked`,
                        -- both above) -- unconditionally refetches
                        -- (`ForceRefresh`, not plain `Poll` -- see that
                        -- constructor's own doc) so the just-sent message
                        -- shows up without waiting for the next 30s poll,
                        -- which wouldn't otherwise refetch an
                        -- already-loaded listing at all. `Shared.MessagingPanel`'s
                        -- own embedded copy gets the same treatment directly
                        -- from `Shared.update` (see its `MarkdownPanelMsg`
                        -- branch), since it isn't reachable through this
                        -- page-forwarding mechanism at all.
                        Shared.MarkdownPanelMsg (MarkdownPanel.GotSaveResult (Ok _)) ->
                            applyPageMsg shared MessagesPage.ForceRefresh model

                        _ ->
                            ( model, Effect.none )
            in
            ( updatedModel, Effect.batch [ Effect.fromShared subMsg, updateEffect ] )


applyPageMsg : Shared.Model -> MessagesPage.Msg -> Model -> ( Model, Effect Msg )
applyPageMsg shared subMsg model =
    let
        ( newModel, cmd, maybeAccountsPanelMsg ) =
            MessagesPage.update shared.accounts subMsg model

        accountEffect : Effect Msg
        accountEffect =
            maybeAccountsPanelMsg
                |> Maybe.map (Shared.AccountsPanelMsg >> Effect.fromShared)
                |> Maybe.withDefault Effect.none
    in
    ( newModel, Effect.batch [ Effect.fromCmd (Cmd.map PageMsg cmd), accountEffect ] )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map PageMsg (MessagesPage.subscriptions model)


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = UI.pageTitle shared [ "Messages" ]
    , body =
        UI.layout shared
            req.route
            SharedMsg
            [ div [ class "messages-page-heading" ]
                [ h2 [] [ text "Messages" ]
                , sendMessageButton shared
                ]
            , Html.map PageMsg (MessagesPage.view shared.time.browserTimeZone shared.accounts model)
            ]
    }


{-| Opens `Shared.MarkdownPanel` on a fresh `MarkdownPanel.SendNewMessage`
draft -- only on this real page (`Shared.MessagingPanel`'s embedded copy has
no button of its own, per its own spec). Hidden entirely with nobody signed
in anywhere (`MarkdownPanel.resolve`'s "you're not signed in" error would
just cover it otherwise, but there's no point offering a button that can
only ever fail). `defaultHost`, the initial "sending as" server
`sendMessagePostingAsRow` starts from, is just the first enabled account's
server -- `PostingAsChanged` lets the user switch it once the panel's open.
-}
sendMessageButton : Shared.Model -> Html.Html Msg
sendMessageButton shared =
    case AccountsPanel.enabledAccounts shared.accounts of
        [] ->
            text ""

        firstAccount :: _ ->
            button
                [ Html.Attributes.classList
                    [ ( "messages-send-button", True )
                    , ( hostnameToCSSClass firstAccount.server, True )
                    , ( "background-color-primary", True )
                    ]
                , onClick (SharedMsg (Shared.MarkdownPanelMsg (MarkdownPanel.Open (MarkdownPanel.SendNewMessage []) firstAccount.server)))
                ]
                [ text "Send Message" ]


{-| Lets `Main` forward a `Shared.Msg` that didn't originate from this page --
see `Components.Pages.UsersPage.fromShared`.
-}
fromShared : Shared.Msg -> Msg
fromShared =
    SharedMsg
