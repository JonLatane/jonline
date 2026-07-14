module Shared.AdminPanel exposing (AccountsPanelTab(..), Model, Msg(..), init, isAccountPanelOpen, update)

{-| Settings/Admin state for the Accounts Panel's "Settings" and "Admin" tabs
(see `UI.elm`'s `accountsPanel`) -- `activeTab` tracks which of the panel's
tabs is showing, `allowMainServerSwitch` is the Settings tab's "switch main
server by tapping servers" flag (which changes what tapping a server chip in
the Accounts Panel does, see `UI.elm`'s `serverChip`), and `openAccountPanels`
tracks which admin-capable accounts' "web UI" panels (see `UI.elm`'s
`adminAccountPanel`) are expanded on the Admin tab -- future admin features
(moderation, ...) land here too.

The actual "set web UI" action lives in `Shared.AccountsPanel` (it needs that
module's `Account`/`Server`/RPC machinery); this module only tracks which
panels are open.
-}

import Set exposing (Set)


type AccountsPanelTab
    = AccountsAndServersTab
    | SettingsTab
    | AdminTab


type alias Model =
    { activeTab : AccountsPanelTab
    , allowMainServerSwitch : Bool
    , openAccountPanels : Set String
    }


type Msg
    = TabSelected AccountsPanelTab
    | ToggleAllowMainServerSwitch
    | ToggleAccountPanel String


init : Model
init =
    { activeTab = AccountsAndServersTab
    , allowMainServerSwitch = False
    , openAccountPanels = Set.empty
    }


isAccountPanelOpen : String -> Model -> Bool
isAccountPanelOpen id model =
    Set.member id model.openAccountPanels


update : Msg -> Model -> Model
update msg model =
    case msg of
        TabSelected tab ->
            { model | activeTab = tab }

        ToggleAllowMainServerSwitch ->
            { model | allowMainServerSwitch = not model.allowMainServerSwitch }

        ToggleAccountPanel id ->
            { model
                | openAccountPanels =
                    if Set.member id model.openAccountPanels then
                        Set.remove id model.openAccountPanels

                    else
                        Set.insert id model.openAccountPanels
            }
