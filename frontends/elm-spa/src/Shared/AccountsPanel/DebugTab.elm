module Shared.AccountsPanel.DebugTab exposing (Model, Msg(..), init, update)

{-| State for the Accounts Panel's "Debug" tab (see `Shared.AccountsPanel.Tab`,
`UI.elm`'s `debugTab`) -- admin-only debug settings, not meant for regular users:
`allowMainServerSwitch` (which changes what tapping a server chip in the Accounts Panel
does, see `UI.elm`'s `serverChip`), `allowUsernamePasswordForOtherHosts` (which lets the
Account form's Username/Password/Login/Create Account controls show for any server, not
just `AccountsPanel.isMainServer` ones -- see `UI.elm`'s `addAccountForm` -- though it
never enables `signInFromButton`'s cross-server SSO hand-off for `browsingHost`/
`mainFrontendHost` themselves), and `showAllEventLayouts` (which un-hides
`Components.Pages.EventsPage`'s List/Grid/Row mode buttons everywhere -- see that
module's `modeButtonsView` for the default, flag-off visibility rules it overrides).

All three are session-only, like the rest of the Accounts Panel's Debug/Admin state --
none of them are persisted, so they're back off after a page refresh (the Debug tab doc
in `UI.elm` notes this too).

-}


type alias Model =
    { allowMainServerSwitch : Bool
    , allowUsernamePasswordForOtherHosts : Bool
    , showAllEventLayouts : Bool
    }


type Msg
    = ToggleAllowMainServerSwitch
    | ToggleAllowUsernamePasswordForOtherHosts
    | ToggleShowAllEventLayouts


init : Model
init =
    { allowMainServerSwitch = False
    , allowUsernamePasswordForOtherHosts = False
    , showAllEventLayouts = False
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleAllowMainServerSwitch ->
            { model | allowMainServerSwitch = not model.allowMainServerSwitch }

        ToggleAllowUsernamePasswordForOtherHosts ->
            { model | allowUsernamePasswordForOtherHosts = not model.allowUsernamePasswordForOtherHosts }

        ToggleShowAllEventLayouts ->
            { model | showAllEventLayouts = not model.showAllEventLayouts }
