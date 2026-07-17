module UI.Responsive exposing (WindowSize, isNarrow, narrowBreakpoint)

{-| Shared breakpoint(s) for layout decisions that need to be made from
`update` rather than pure CSS -- e.g. the Accounts Panel and Starred Posts
Panel closing one another when the other opens on a narrow screen (see
`Shared.Model`'s `windowSize` and `Shared.update`'s `AccountsPanelMsg`/
`StarredPostsPanelMsg` branches), where CSS alone can't reach into another
panel's state.
-}


type alias WindowSize =
    { width : Int
    , height : Int
    }


{-| Below this width, the Accounts Panel and Starred Posts Panel are too wide
to show side-by-side (both are full-width slide-out panels on small screens),
so opening one closes the other.
-}
narrowBreakpoint : Int
narrowBreakpoint =
    600


isNarrow : WindowSize -> Bool
isNarrow windowSize =
    windowSize.width < narrowBreakpoint
