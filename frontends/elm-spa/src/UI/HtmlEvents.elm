module UI.HtmlEvents exposing (stopPropagationAndPreventDefaultOn, stopPropagationAndPreventDefaultOnClick)

{-| Just `stopPropagationAndPreventDefaultOn(Click)`, split into its own leaf
module so `Components.Posts`/`Components.Users.FollowStatusAndButton` can use
it without importing `UI` itself -- see `UI.Classes` for why that would be a
cycle.
-}

import Html
import Html.Events
import Json.Decode as Decode


{-| An event handler that both cancels `eventName`'s default action
(`preventDefault`) and stops it from bubbling further (`stopPropagation`).
Needed for e.g. a button/badge nested inside a link or another clickable
element: `preventDefault` alone stops the enclosing `<a>`'s own "navigate to
this href", but not Elm's own `Browser.Navigation` routing, which listens for
clicks on/in an `<a>` via a plain bubble-phase listener on `document` rather
than the click's native default action -- only `stopPropagation` keeps that
from firing too.
-}
stopPropagationAndPreventDefaultOn : String -> msg -> Html.Attribute msg
stopPropagationAndPreventDefaultOn eventName msg =
    Html.Events.custom eventName
        (Decode.succeed { message = msg, stopPropagation = True, preventDefault = True })


{-| `stopPropagationAndPreventDefaultOn` for the common case, a `"click"`
handler.
-}
stopPropagationAndPreventDefaultOnClick : msg -> Html.Attribute msg
stopPropagationAndPreventDefaultOnClick msg =
    stopPropagationAndPreventDefaultOn "click" msg
