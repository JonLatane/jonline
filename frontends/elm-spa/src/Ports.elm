port module Ports exposing (persist, persistStarredPosts, persistThemePreference, setTheme, systemPrefersDarkChanged)

import Json.Encode as Encode


{-| Persists the full account/server list (with their enabled flags) to localStorage.
-}
port persist : Encode.Value -> Cmd msg


{-| Persists the set of starred Posts (as a list of `postId@frontendHost`
strings, see `Shared.StarredPostsPanel.starKey`) to its own localStorage key
-- kept independent of `persist` for the same reason `persistThemePreference`
is: `Shared.StarredPostsPanel` doesn't need to know `Shared.AccountsPanel`'s
persisted shape, or vice versa.
-}
port persistStarredPosts : Encode.Value -> Cmd msg


{-| Persists the appearance ("auto"/"light"/"dark") preference to its own
localStorage key -- kept independent of `persist` so `Shared` and
`Shared.AccountsPanel` don't need to know about each other's persisted shape.
-}
port persistThemePreference : String -> Cmd msg


{-| Applies the effective dark/light mode to the page: "dark" or "light" sets
`<html data-theme>` (overriding the system preference); "auto" clears it
(falling back to the `prefers-color-scheme` media query).
-}
port setTheme : String -> Cmd msg


{-| Fires when the OS-level dark/light preference changes while the app is
open (relevant only in "auto" mode).
-}
port systemPrefersDarkChanged : (Bool -> msg) -> Sub msg
