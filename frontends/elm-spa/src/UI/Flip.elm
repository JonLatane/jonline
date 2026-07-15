module UI.Flip exposing
    ( State, enter, reappear, remove, animate, subscription, itemAttributes
    , MoveState, atRest, startMove, moveAttributes, moveAnimate, moveSubscription
    )

{-| Generic FLIP-style ("First, Last, Invert, Play") animation helpers for
items in a keyed, flex-column list -- extracted from `Pages.Home_`'s original
per-post `PostAnimation` (see its history) so every animated list (recent
posts, Accounts, future ones) shares one implementation. Pair with
`.flip-animated-column`/`.flip-animated-item` in `style.css`.

There are two independent things a list item can animate:

  - **Entering/leaving** (`State`) -- fades/scales an item in on arrival, and
    fades/scales+collapses it out on departure while the rest of the list
    slides smoothly to fill the gap.
  - **Moving** (`MoveState`) -- an item that's still present but changed
    position (e.g. a reorder) slides from where it was to where it now is,
    rather than jumping.

A caller wraps one or both of these alongside its own per-item data, e.g.
`{ post : Post, flip : UI.Flip.State Msg }`.

-}

import Animation
import Animation.Messenger
import Html
import Html.Attributes exposing (classList)



-- ENTERING / LEAVING


{-| One item's enter/leave animation state.
-}
type alias State msg =
    { removing : Bool
    , entering : Bool
    , style : Animation.Messenger.State msg
    }


{-| A freshly-seen item: starts invisible/slightly shrunk and immediately
animates in to its natural opacity/scale.
-}
enter : State msg
enter =
    { removing = False
    , entering = True
    , style =
        Animation.style [ Animation.opacity 0, Animation.scale 0.92 ]
            |> Animation.interrupt
                [ Animation.to [ Animation.opacity 1, Animation.scale 1 ] ]
    }


{-| An item that was mid fade-out reappearing: interrupts whatever fade-out
step was queued (including its trailing removal send, so that `Msg` never
fires) and animates back in.
-}
reappear : State msg -> State msg
reappear state =
    { state
        | removing = False
        , style =
            Animation.interrupt
                [ Animation.to [ Animation.opacity 1, Animation.scale 1 ] ]
                state.style
    }


{-| Starts an item animating out, then sends `onRemoved` once the fade
finishes -- the caller uses that to actually drop it from its own collection.
-}
remove : msg -> State msg -> State msg
remove onRemoved state =
    { state
        | removing = True
        , style =
            Animation.interrupt
                [ Animation.to [ Animation.opacity 0, Animation.scale 0.92 ]
                , Animation.Messenger.send onRemoved
                ]
                state.style
    }


{-| Steps `style` forward on an `Animation.Msg` tick, and clears `entering`
(it only needs to be `True` for the one frame that gives the browser
something to transition from) -- see `Pages.Home_.update`'s `Animate` case for
how a caller folds this over every live item in one `Dict`.
-}
animate : Animation.Msg -> State msg -> ( State msg, Cmd msg )
animate animMsg state =
    let
        ( newStyle, cmd ) =
            Animation.Messenger.update animMsg state.style
    in
    ( { state | style = newStyle, entering = False }, cmd )


{-| The `Sub` for every live item's enter/leave animation -- caller batches
this in with its own subscriptions, passing `List.map .style` of whatever it's
storing `State` in.
-}
subscription : (Animation.Msg -> msg) -> List (State msg) -> Sub msg
subscription toMsg states =
    Animation.subscription toMsg (List.map .style states)


{-| Attributes for the wrapping `div` -- `.flip-collapsed` (present while
`entering` or `removing`) is what makes `.flip-animated-item` in `style.css`
grow/shrink this wrapper's own height, sliding the rest of a
`.flip-animated-column` smoothly into the space this item leaves/needs, on
top of its own fade/scale from `style`.
-}
itemAttributes : State msg -> List (Html.Attribute msg)
itemAttributes state =
    classList
        [ ( "flip-animated-item", True )
        , ( "flip-collapsed", state.entering || state.removing )
        ]
        :: Animation.render state.style



-- MOVING


{-| An item's move animation state: just a `translate`, since a move (unlike
entering/leaving) never needs a completion callback -- it settles at
`translate 0 0` and stays there, harmless to leave in a `Dict` indefinitely.
-}
type alias MoveState =
    Animation.State


{-| The identity/no-op move state -- an item that hasn't moved.
-}
atRest : MoveState
atRest =
    Animation.style [ Animation.translate (Animation.px 0) (Animation.px 0) ]


{-| Starts (or restarts) a move: `deltaY` is how far, in px, the item's *new*
position differs from where it just was (`old.top - new.top`, so a positive
`deltaY` means it moved *up* and should slide up into place from below, while
a negative `deltaY` means it moved *down* and should slide down into place
from above) -- see `Browser.Dom.getElement` for how a caller measures that
(the "Invert" step of FLIP). Pins the item at its old position via an
instant, non-animated `translate` ("Invert"), then animates back to
`translate 0 0` ("Play"), so it visually slides from where it was to where it
now is instead of jumping.
-}
startMove : Float -> MoveState -> MoveState
startMove deltaY state =
    Animation.interrupt
        [ Animation.set [ Animation.translate (Animation.px 0) (Animation.px deltaY) ]
        , Animation.to [ Animation.translate (Animation.px 0) (Animation.px 0) ]
        ]
        state


{-| Attributes (just an inline `transform`) for the moving item's own
element.
-}
moveAttributes : MoveState -> List (Html.Attribute msg)
moveAttributes state =
    Animation.render state


{-| Steps a `MoveState` forward on an `Animation.Msg` tick.
-}
moveAnimate : Animation.Msg -> MoveState -> MoveState
moveAnimate =
    Animation.update


{-| The `Sub` for every live item's move animation.
-}
moveSubscription : (Animation.Msg -> msg) -> List MoveState -> Sub msg
moveSubscription toMsg states =
    Animation.subscription toMsg states
