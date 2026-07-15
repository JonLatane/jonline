module Components.ServerDependentView exposing (ConnectStatus(..), availableServer, view)

{-| A view for content that belongs to a specific server (by hostname) which
the app might not actually know about yet -- e.g. a post linked from another
Jonline server (see `Pages.Post.PostId_`). Resolves the hostname against the
app's known servers and either renders `render` with what it finds (the
matching `Server`, and whichever of its accounts is currently enabled, if
any), or shows a prompt instead -- to connect to the server, if it isn't known
at all, or noting that it's disabled, if it's known but the user has toggled
it off (see `Shared.AccountsPanel`'s `Server.enabled`) -- either way, `render`
just isn't called, so the caller never has to itself branch on "is this
server actually usable right now".

Connecting is entirely up to the caller (`onConnectClicked`/`connectStatus`),
typically by kicking off `Shared.AccountsPanel.connectToServer` and, once it
resolves, dispatching `Shared.AccountsPanel.ServerConnected` to register it
(and then whatever the caller actually wanted the server for -- e.g. fetching
the post it was after all along). Re-enabling a disabled server is simpler --
just `AccountsPanel.ToggleServerEnabled` -- so `onEnableClicked` is a plain
`msg` rather than needing a status to track, unlike `onConnectClicked`.

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
    , onEnableClicked : msg
    }
    -> (AccountsPanel.Server -> Maybe AccountsPanel.Account -> Html msg)
    -> Html msg
view config render =
    case AccountsPanel.serverForHost config.servers config.hostname of
        Just server ->
            if server.enabled then
                render server (AccountsPanel.enabledAccountForServer config.accounts config.hostname)

            else
                div [ class "server-dependent-prompt" ]
                    [ p [] [ text (config.hostname ++ " is disabled. Re-enable it in your Servers to see it.") ]
                    , button [ onClick config.onEnableClicked ] [ text ("Enable " ++ config.hostname) ]
                    ]

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


{-| `hostname` resolved to its `Server`, but only if it's both known and
`enabled` -- `Nothing` either way otherwise. The same "is this content's
server actually usable right now" condition `view` itself gates on above,
exposed for callers (e.g. `Shared.StarredPostsPanel`'s fetching) that need to
gate something other than rendering on it, without duplicating the `.enabled`
check themselves.
-}
availableServer : List AccountsPanel.Server -> String -> Maybe AccountsPanel.Server
availableServer servers hostname =
    AccountsPanel.serverForHost servers hostname
        |> Maybe.andThen
            (\server ->
                if server.enabled then
                    Just server

                else
                    Nothing
            )
