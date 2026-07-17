module UI.Classes exposing (classes, escapeCSSClass, hostnameToCSSClass, openClosedClass)

{-| Just `UI.classes`, split into its own leaf module so `Components.Posts`
can use it without importing `UI` itself -- `UI` imports
`Shared.StarredPostsPanel` (for the nav's Starred Posts menu), which in turn
needs `Components.Posts` (`postCard`) for its own panel view, and that would
otherwise be a cycle.
-}

import Char
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


{-| Escapes any invalid chars to make a valid CSS class.
-}
escapeCSSClass : String -> String
escapeCSSClass input =
    let
        escapeChar : Char -> String
        escapeChar c =
            if Char.isAlphaNum c || c == '-' || c == '_' then
                String.fromChar c

            else
                "-"
    in
    input
        |> String.toList
        |> List.map escapeChar
        |> String.concat


{-| Escapes a hostname for literal use as one segment of a CSS class
selector -- e.g. the dots in "jonline.io", which would otherwise be parsed as
separate class selectors (`.jonline.io` means "has both class `jonline` and
class `io`", not "has class `jonline.io`").
-}
hostnameToCSSClass : String -> String
hostnameToCSSClass hostname =
    "server-" ++ escapeCSSClass hostname
