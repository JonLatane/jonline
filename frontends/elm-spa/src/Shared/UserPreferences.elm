module Shared.UserPreferences exposing (Model, Msg(..), init, update)

{-| Small, app-wide user preferences that aren't tied to any one page's own
URL/local state -- currently just `prefersCalendar` (see its own doc), a
single JSON object persisted to its own localStorage key (`Ports.persistUserPreferences`).

Mirrors `Shared.StarredPanel`'s persist-to-localStorage half exactly, minus
the `BroadcastChannel` live cross-tab push -- see `Ports.persistUserPreferences`'s
own doc for why these are only ever picked up by other tabs on their next
load, not pushed into ones already open.
-}

import Json.Decode as Decode
import Json.Encode as Encode
import Ports


type alias Model =
    -- Whether `Components.Pages.EventsPage` should default to `Calendar`
    -- mode rather than its ordinary Row/List default -- set (from
    -- `Pages.Home_`/`Pages.Events` only, see `EventsPage.Model.syncsCalendarPreference`)
    -- whenever the user switches that page's own copy into or out of
    -- `Calendar` mode, then read back by *every* `EventsPage` copy (including
    -- `Components.Pages.UserProfilePage`'s and `Pages.Username_.Events`/
    -- `Pages.User.UserId_.Events`'s, which never write it) to decide their
    -- own initial mode -- see `EventsPage.defaultMode`.
    { prefersCalendar : Bool }


type Msg
    = SetPrefersCalendar Bool


{-| `flags` is the raw, persisted JSON object (see `Ports.persistUserPreferences`)
handed down from `Shared.init`, un-decoded -- same convention as
`Shared.StarredPanel.init`'s flags.
-}
init : Decode.Value -> Model
init flags =
    { prefersCalendar =
        Decode.decodeValue (Decode.field "prefersCalendar" Decode.bool) flags
            |> Result.withDefault False
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetPrefersCalendar prefersCalendar ->
            let
                newModel =
                    { model | prefersCalendar = prefersCalendar }
            in
            ( newModel, persistCmd newModel )


persistCmd : Model -> Cmd Msg
persistCmd model =
    Ports.persistUserPreferences (encode model)


encode : Model -> Encode.Value
encode model =
    Encode.object [ ( "prefersCalendar", Encode.bool model.prefersCalendar ) ]
