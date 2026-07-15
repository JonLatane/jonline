module UI.Flip exposing
    ( Axis(..)
    , State, restingState, enter, reappear, remove, animate, subscription, itemAttributes, syncEnter
    , MoveState, atRest, startMove, swapDeltas, moveAttributes, moveAnimate, moveSubscription
    , moveListItemBy, beginReorder, applyReorder
    , reorderButtonPair, reorderButtons
    )

{-| Generic FLIP-style ("First, Last, Invert, Play") animation helpers for
items in a keyed, flex list -- extracted from `Pages.Home_`'s original
per-post `PostAnimation` (see its history) so every animated list (recent
posts, Accounts, Servers, future ones -- including a future grid, which is why
everything below is in terms of both axes even where today's callers only
ever move along one) shares one implementation. Pair with
`.flip-animated-column`/`.flip-animated-row`/`.flip-animated-item` in
`style.css`.

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
import Browser.Dom as Dom
import Dict exposing (Dict)
import Html exposing (Attribute, Html, button, div, text)
import Html.Attributes exposing (class, classList, disabled, title)
import Html.Events exposing (onClick)
import Task


{-| Which way a list lays its items out -- `Vertical` for a column (top to
bottom, e.g. Accounts), `Horizontal` for a row (left to right, e.g. Servers).
A future grid would need a move along both axes at once, which is why
`MoveState`/`startMove` already carry a full `(x, y)` offset rather than one
scalar -- `Axis` only decides which of the two `swapDeltas` actually fills in
for a plain list.
-}
type Axis
    = Vertical
    | Horizontal



-- ENTERING / LEAVING


{-| One item's enter/leave animation state.
-}
type alias State msg =
    { removing : Bool
    , entering : Bool
    , style : Animation.Messenger.State msg
    }


{-| A static "already here, nothing animating" state -- the right thing to
default a not-yet-tracked item to, e.g. one that's about to be removed for
the first time and needs a real (visible, settled) state for `remove` to
interrupt/animate away from, unlike `enter`'s hidden/shrunk starting point.
-}
restingState : State msg
restingState =
    { removing = False
    , entering = False
    , style = Animation.style [ Animation.opacity 1, Animation.scale 1 ]
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
grow/shrink this wrapper's own height (`axis = Vertical`, for a
`.flip-animated-column`) or width (`axis = Horizontal`, for a
`.flip-animated-row`), sliding the rest of the list smoothly into the space
this item leaves/needs, on top of its own fade/scale from `style`.

The output's `msg` is a wholly separate type variable from `state`'s own --
`Animation.render` never actually produces a `msg` value (nothing here is an
event handler), so a caller isn't forced to `Html.map` a whole subtree just
because `state`'s own `msg` (e.g. `remove`'s `onRemoved`) belongs to a
different module's `Msg` than the content being wrapped does.
-}
itemAttributes : Axis -> State state -> List (Html.Attribute msg)
itemAttributes axis state =
    classList
        [ ( "flip-animated-item", True )
        , ( "horizontal", axis == Horizontal )
        , ( "flip-collapsed", state.entering || state.removing )
        ]
        :: Animation.render state.style


{-| Ensures every item in `items` has a `State` entry in `animations`,
inserting a fresh `enter` for any that don't -- so a caller can call this
after every update to a list of persistent items (accounts, servers, starred
posts, ...) and have newly-appeared ones animate in automatically, without
hunting down every individual "this added a new one" call site by hand.
Leaves existing entries (resting, still entering, or removing) untouched.

Doesn't touch entries for ids no longer in `items` -- those belong to
whatever's mid-remove (see `remove`), which cleans up its own entry once its
fade finishes; nothing here should race that.

A caller whose items already exist before any interactive add/remove (e.g.
persisted accounts/servers reloaded on startup) should pre-seed `animations`
with `restingState` for each of them (rather than starting from `Dict.empty`)
before ever calling this, so this treats them as "already known" rather than
"just appeared" the first time it runs.
-}
syncEnter : (a -> String) -> List a -> Dict String (State msg) -> Dict String (State msg)
syncEnter idOf items animations =
    List.foldl
        (\item acc ->
            let
                key =
                    idOf item
            in
            if Dict.member key acc then
                acc

            else
                Dict.insert key enter acc
        )
        animations
        items



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


{-| Starts (or restarts) a move: `( deltaX, deltaY )` is how far, in px, the
item's *new* position differs from where it just was along each axis
(`old - new`, so a positive component means it moved backward along that axis
-- up or left -- and should slide forward into place; a negative component
means it moved forward -- down or right -- and should slide backward into
place) -- see `swapDeltas` for how a caller measures that (the "Invert" step
of FLIP) for an adjacent-swap reorder. A plain vertical or horizontal list
only ever needs one non-zero component; a future grid would set both. Pins
the item at its old position via an instant, non-animated `translate`
("Invert"), then animates back to `translate 0 0` ("Play"), so it visually
slides from where it was to where it now is instead of jumping.
-}
startMove : ( Float, Float ) -> MoveState -> MoveState
startMove ( deltaX, deltaY ) state =
    Animation.interrupt
        [ Animation.set [ Animation.translate (Animation.px deltaX) (Animation.px deltaY) ]
        , Animation.to [ Animation.translate (Animation.px 0) (Animation.px 0) ]
        ]
        state


{-| The post-swap `( deltaX, deltaY )` "Invert" offsets (see `startMove`) for
two *adjacent* items that just swapped places along `axis` -- e.g. two account
rows in a vertical list, or two server chips in a horizontal strip. Derived
entirely from their *pre-swap* rects (`Browser.Dom.getElement`), so a caller
can compute this in the very same `update` that performs the swap, without
waiting for a second DOM measurement after the swap re-renders -- since the
item that was "first" along `axis` keeps that position, and the other lands
immediately after it (plus whatever gap was between them), swapping places.

Returns `(movedItemDelta, neighborDelta)`, matching the order `moved`/
`neighbor` were passed in.
-}
swapDeltas : Axis -> Dom.Element -> Dom.Element -> ( ( Float, Float ), ( Float, Float ) )
swapDeltas axis moved neighbor =
    let
        ( ( movedPos, movedSize ), ( neighborPos, neighborSize ) ) =
            case axis of
                Vertical ->
                    ( ( moved.element.y, moved.element.height ), ( neighbor.element.y, neighbor.element.height ) )

                Horizontal ->
                    ( ( moved.element.x, moved.element.width ), ( neighbor.element.x, neighbor.element.width ) )

        ( movedDelta1D, neighborDelta1D ) =
            if movedPos < neighborPos then
                let
                    gap =
                        neighborPos - movedPos - movedSize

                    newNeighborPos =
                        movedPos

                    newMovedPos =
                        newNeighborPos + neighborSize + gap
                in
                ( movedPos - newMovedPos, neighborPos - newNeighborPos )

            else
                let
                    gap =
                        movedPos - neighborPos - neighborSize

                    newMovedPos =
                        neighborPos

                    newNeighborPos =
                        newMovedPos + movedSize + gap
                in
                ( movedPos - newMovedPos, neighborPos - newNeighborPos )

        toXY delta1D =
            case axis of
                Vertical ->
                    ( 0, delta1D )

                Horizontal ->
                    ( delta1D, 0 )
    in
    ( toXY movedDelta1D, toXY neighborDelta1D )


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



-- REORDERING A LIST


{-| Moves the item identified by `idOf`/`id` one slot earlier/later in
`items` -- `offset` is always +-1 (adjacent swap, from a pair of move
buttons) -- a no-op if that would walk off either end. Shared by every
reorderable list (Accounts, Servers, Starred Posts, ...).
-}
moveListItemBy : (a -> String) -> Int -> String -> List a -> List a
moveListItemBy idOf offset id items =
    case indexOfListItem idOf id items of
        Nothing ->
            items

        Just i ->
            let
                j =
                    i + offset

                elementAt idx =
                    List.drop idx items |> List.head
            in
            if j < 0 || j >= List.length items then
                items

            else
                case ( elementAt i, elementAt j ) of
                    ( Just ai, Just aj ) ->
                        List.indexedMap
                            (\idx item ->
                                if idx == i then
                                    aj

                                else if idx == j then
                                    ai

                                else
                                    item
                            )
                            items

                    _ ->
                        items


indexOfListItem : (a -> String) -> String -> List a -> Maybe Int
indexOfListItem idOf id items =
    items
        |> List.indexedMap Tuple.pair
        |> List.filter (\( _, item ) -> idOf item == id)
        |> List.head
        |> Maybe.map Tuple.first


{-| Kicks off a reorder move: measures the current (pre-swap) position of the
item at `id` and its `offset` neighbor (the "First" of FLIP) before touching
the list at all, via `toMsg` -- so the resulting message has something to
compare the post-swap position against (see `applyReorder`). A no-op (no
neighbor in that direction) just does nothing.
-}
beginReorder :
    (a -> String)
    -> (String -> String)
    -> (String -> String -> Int -> Result Dom.Error ( Dom.Element, Dom.Element ) -> msg)
    -> Int
    -> String
    -> List a
    -> Cmd msg
beginReorder idOf domId toMsg offset id items =
    case indexOfListItem idOf id items of
        Nothing ->
            Cmd.none

        Just i ->
            case List.drop (i + offset) items |> List.head of
                Nothing ->
                    Cmd.none

                Just neighbor ->
                    let
                        neighborId =
                            idOf neighbor
                    in
                    Task.attempt (toMsg id neighborId offset)
                        (Task.map2 Tuple.pair
                            (Dom.getElement (domId id))
                            (Dom.getElement (domId neighborId))
                        )


{-| Applies a just-measured pre-swap pair (see `beginReorder`) to
`animations`: computes both items' slide deltas (`swapDeltas`) and
starts/restarts each one's `MoveState`.
-}
applyReorder :
    Axis
    -> String
    -> String
    -> Dom.Element
    -> Dom.Element
    -> Dict String MoveState
    -> Dict String MoveState
applyReorder axis id neighborId movedEl neighborEl animations =
    let
        ( movedDelta, neighborDelta ) =
            swapDeltas axis movedEl neighborEl

        startOrRestart key delta anims =
            Dict.insert key (startMove delta (Dict.get key anims |> Maybe.withDefault atRest)) anims
    in
    animations
        |> startOrRestart id movedDelta
        |> startOrRestart neighborId neighborDelta



-- REORDER BUTTONS


{-| One circular move-backward/move-forward pair, shared by every reorderable
list's controls -- glyph/title implied by `axis`. Returns the two buttons
separately (rather than assembling them into one container) since callers
arrange the pair differently: `reorderButtons` below stacks them into one
`.reorder-buttons` element for a vertical list; `UI.serverChip` instead splits
them to either side of a horizontal list's item content. Takes the click
`Attribute` itself (rather than a bare `msg`) so a caller whose pair sits
*inside* some other clickable element can pass `stopPropagationOn "click" ...`
instead of a plain `onClick`, so tapping an arrow doesn't also trigger that.
-}
reorderButtonPair :
    Axis
    -> { moveBackward : Attribute msg, moveForward : Attribute msg, canMoveBackward : Bool, canMoveForward : Bool }
    -> { backward : Html msg, forward : Html msg }
reorderButtonPair axis { moveBackward, moveForward, canMoveBackward, canMoveForward } =
    let
        ( ( backwardGlyph, backwardTitle ), ( forwardGlyph, forwardTitle ) ) =
            case axis of
                Vertical ->
                    ( ( "▲", "Move up" ), ( "▼", "Move down" ) )

                Horizontal ->
                    ( ( "◀", "Move left" ), ( "▶", "Move right" ) )
    in
    { backward =
        button [ class "reorder-btn", moveBackward, disabled (not canMoveBackward), title backwardTitle ] [ text backwardGlyph ]
    , forward =
        button [ class "reorder-btn", moveForward, disabled (not canMoveForward), title forwardTitle ] [ text forwardGlyph ]
    }


{-| Stacked ▲/▼ pair for a `Vertical` list (Accounts, Starred Posts), just
left of that row's own content.
-}
reorderButtons : { moveUp : msg, moveDown : msg, canMoveUp : Bool, canMoveDown : Bool } -> Html msg
reorderButtons { moveUp, moveDown, canMoveUp, canMoveDown } =
    let
        pair =
            reorderButtonPair Vertical
                { moveBackward = onClick moveUp
                , moveForward = onClick moveDown
                , canMoveBackward = canMoveUp
                , canMoveForward = canMoveDown
                }
    in
    div [ class "reorder-buttons" ] [ pair.backward, pair.forward ]
