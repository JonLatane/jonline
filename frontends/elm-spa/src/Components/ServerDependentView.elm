module Components.ServerDependentView exposing (ConnectStatus(..), view)

{-| A view for content that belongs to a specific server (by hostname) which
the app might not actually know about yet -- e.g. a post linked from another
Jonline server (see `Pages.Post.PostId_`). Resolves the hostname against the
app's known servers and either renders `render` with what it finds (the
matching `Server`, and whichever of its accounts is currently enabled, if
any), or -- if the server isn't known at all -- shows a prompt to connect to
it instead.

Connecting is entirely up to the caller (`onConnectClicked`/`connectStatus`),
typically by kicking off `Shared.AccountsPanel.connectToServer` and, once it
resolves, dispatching `Shared.AccountsPanel.ServerConnected` to register it
(and then whatever the caller actually wanted the server for -- e.g. fetching
the post it was after all along).
-}

import Html exposing (Html, button, div, p, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)
import Shared.AccountsPanel as AccountsPanel


{-| The status of a caller-driven attempt to connect to the not-yet-known
server -- `Components.ServerDependentView` only displays this; it doesn't
track it itself, so it stays in sync with whatever else the caller does once
connecting succeeds (see the module doc).
-}
type ConnectStatus
    = NotConnected
    | Connecting
    | ConnectFailed String


view :
    { hostname : String
    , servers : List AccountsPanel.Server
    , accounts : List AccountsPanel.Account
    , connectStatus : ConnectStatus
    , onConnectClicked : msg
    }
    -> (AccountsPanel.Server -> Maybe AccountsPanel.Account -> Html msg)
    -> Html msg
view config render =
    case AccountsPanel.serverForHost config.servers config.hostname of
        Just server ->
            render server (AccountsPanel.enabledAccountForServer config.accounts config.hostname)

        Nothing ->
            let
                connecting =
                    config.connectStatus == Connecting
            in
            div [ class "server-dependent-prompt" ]
                [ p [] [ text ("This is on " ++ config.hostname ++ ", which isn't one of your servers yet.") ]
                , button [ onClick config.onConnectClicked, disabled connecting ]
                    [ text
                        (if connecting then
                            "Connecting…"

                         else
                            "Add " ++ config.hostname
                        )
                    ]
                , case config.connectStatus of
                    ConnectFailed err ->
                        p [ class "server-dependent-error" ] [ text err ]

                    _ ->
                        text ""
                ]
