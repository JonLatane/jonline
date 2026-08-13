module Shared.AccountsPanel.AdminTab exposing (Model, Msg(..), init, isAccountPanelOpen, update)

{-| State for the Accounts Panel's "Admin" tab (see `Shared.AccountsPanel.Tab`,
`UI.elm`'s `adminTab`) -- `openAccountPanels` tracks which admin-capable accounts' "web
UI" panels (see `UI.elm`'s `adminAccountPanel`) are expanded; future admin features
(moderation, ...) land here too. Session-only, like `Shared.AccountsPanel.DebugTab`'s
flags -- not persisted, so every panel is back closed after a page refresh.

The actual "set web UI" action lives in `Shared.AccountsPanel` itself (it needs that
module's `Account`/`Server`/RPC machinery); this module only tracks which panels are
open.

-}

import Set exposing (Set)


type alias Model =
    { openAccountPanels : Set String
    }


type Msg
    = ToggleAccountPanel String


init : Model
init =
    { openAccountPanels = Set.empty }


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleAccountPanel id ->
            { model
                | openAccountPanels =
                    if Set.member id model.openAccountPanels then
                        Set.remove id model.openAccountPanels

                    else
                        Set.insert id model.openAccountPanels
            }


isAccountPanelOpen : String -> Model -> Bool
isAccountPanelOpen id model =
    Set.member id model.openAccountPanels
