module Shared.AdminPanel exposing (Model, Msg(..), init, update)

{-| The Server Admin Panel: only shown (see `Shared.AccountsPanel.hasAdminAccount`)
when at least one signed-in account has `ADMIN` on its server. For now, this
just holds the "allow switching main server" flag, which changes what tapping
a server chip in the Accounts Panel does (see `UI.elm`'s `serverChip`) --
future admin features (moderation, server configuration, ...) land here too.
-}


type alias Model =
    { showAdminPanel : Bool
    , allowMainServerSwitch : Bool
    }


type Msg
    = ToggleAdminPanel
    | ToggleAllowMainServerSwitch


init : Model
init =
    { showAdminPanel = False
    , allowMainServerSwitch = False
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleAdminPanel ->
            { model | showAdminPanel = not model.showAdminPanel }

        ToggleAllowMainServerSwitch ->
            { model | allowMainServerSwitch = not model.allowMainServerSwitch }
