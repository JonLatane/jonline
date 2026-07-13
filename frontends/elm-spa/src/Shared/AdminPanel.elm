module Shared.AdminPanel exposing (Model, Msg(..), init, isAccountPanelOpen, update)

{-| The Server Admin Panel: only shown (see `Shared.AccountsPanel.hasAdminAccount`)
when at least one signed-in account has `ADMIN` on its server. Holds the
"allow switching main server" flag, which changes what tapping a server chip
in the Accounts Panel does (see `UI.elm`'s `serverChip`), plus which
admin-capable accounts' "web UI" panels (see `UI.elm`'s `adminAccountPanel`)
are expanded -- future admin features (moderation, ...) land here too.

The actual "set web UI" action lives in `Shared.AccountsPanel` (it needs that
module's `Account`/`Server`/RPC machinery); this module only tracks which
panels are open.
-}

import Set exposing (Set)


type alias Model =
    { showAdminPanel : Bool
    , allowMainServerSwitch : Bool
    , openAccountPanels : Set String
    }


type Msg
    = ToggleAdminPanel
    | ToggleAllowMainServerSwitch
    | ToggleAccountPanel String


init : Model
init =
    { showAdminPanel = False
    , allowMainServerSwitch = False
    , openAccountPanels = Set.empty
    }


isAccountPanelOpen : String -> Model -> Bool
isAccountPanelOpen id model =
    Set.member id model.openAccountPanels


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleAdminPanel ->
            { model | showAdminPanel = not model.showAdminPanel }

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
