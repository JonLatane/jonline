module UI.Classes exposing (classes, openClosedClass)

{-| Just `UI.classes`, split into its own leaf module so `Components.Posts`
can use it without importing `UI` itself -- `UI` imports
`Shared.StarredPostsPanel` (for the nav's Starred Posts menu), which in turn
needs `Components.Posts` (`postCard`) for its own panel view, and that would
otherwise be a cycle.
-}

import Html exposing (Attribute)
import Html.Attributes exposing (class)


{-| Combines several class names into one `class` attribute -- `Html`
attributes of the same kind don't merge, so `[ class "a", class "b" ]` would
just apply "b".
-}
classes : List String -> Attribute msg
classes names =
    class (String.join " " names)


{-| "is-open"/"is-closed", for a panel/backdrop's own transition-driving class
-- always rendered in one state or the other (see e.g. `UI.accountsPanel`)
rather than the element itself appearing/disappearing outright, so opening/
closing can be a plain CSS transition.
-}
openClosedClass : Bool -> String
openClosedClass isOpen =
    if isOpen then
        "is-open"

    else
        "is-closed"
