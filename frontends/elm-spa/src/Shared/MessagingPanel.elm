module Shared.MessagingPanel exposing (Model, Msg(..), hasEligibleAccount, init, isOpen, subscriptions, totalUnreadCount, update, view)

{-| The Messages nav panel -- toggled open/closed from a nav icon (mirrors
`Shared.StarredPanel`'s own toggle shape), embedding
`Components.Pages.MessagesPage` in single-pane form (`PageContext = Nothing`,
see that module's doc): groups are still expandable inline, but a
group/message click navigates to the real `/messages` page instead of
changing anything in place here.

Only shown at all (see `hasEligibleAccount`, `UI.elm`'s own nav icon gate)
when a signed-in account actually has `READ_PERSONAL_MESSAGES`/
`READ_ALL_SYSTEM_MESSAGES` (or `ADMIN`) -- mirrors
`Shared.CreateNewPanel.hasEligibleAccount`.

-}

import Components.Messages as Messages
import Components.Pages.MessagesPage as MessagesPage
import Html exposing (Html, div)
import Shared.AccountsPanel as AccountsPanel
import Shared.Time as SharedTime
import UI.Classes exposing (classes, openClosedClass)


type alias Model =
    { open : Bool
    , page : MessagesPage.Model
    }


type Msg
    = ToggleOpen
    | CloseMessagingPanel
    | PageMsg MessagesPage.Msg


init : Model
init =
    { open = False, page = MessagesPage.empty }


isOpen : Model -> Bool
isOpen model =
    model.open


hasEligibleAccount : AccountsPanel.Model -> Bool
hasEligibleAccount =
    Messages.hasEligibleAccount


{-| See `MessagesPage.totalUnreadCount`'s own doc -- this just unwraps
`model.page` to get at it.
-}
totalUnreadCount : Model -> Int
totalUnreadCount model =
    MessagesPage.totalUnreadCount model.page


{-| See `Shared.StarredPanel.update`'s own doc for why this returns a
`Maybe AccountsPanel.Msg` to forward rather than dispatching it directly --
this can't import `Shared` (that's what would let it).
-}
update : AccountsPanel.Model -> Msg -> Model -> ( Model, Cmd Msg, Maybe AccountsPanel.Msg )
update accountsPanelModel msg model =
    case msg of
        ToggleOpen ->
            if model.open then
                ( { model | open = False }, Cmd.none, Nothing )

            else
                let
                    ( newPage, cmd, maybeAccountsPanelMsg ) =
                        MessagesPage.update accountsPanelModel MessagesPage.Poll model.page
                in
                ( { model | open = True, page = newPage }, Cmd.map PageMsg cmd, maybeAccountsPanelMsg )

        CloseMessagingPanel ->
            ( { model | open = False }, Cmd.none, Nothing )

        PageMsg subMsg ->
            let
                ( newPage, cmd, maybeAccountsPanelMsg ) =
                    MessagesPage.update accountsPanelModel subMsg model.page
            in
            ( { model | page = newPage }, Cmd.map PageMsg cmd, maybeAccountsPanelMsg )


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.open then
        Sub.map PageMsg (MessagesPage.subscriptions model.page)

    else
        Sub.none


view : SharedTime.BrowserTimeZone -> AccountsPanel.Model -> Model -> Html Msg
view browserTimeZone accountsPanelModel model =
    div [ classes [ "messaging-panel", "nav-panel", openClosedClass model.open ] ]
        [ Html.map PageMsg (MessagesPage.view browserTimeZone accountsPanelModel model.page) ]
