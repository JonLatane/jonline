port module Ports exposing (persist, setTheme, systemPrefersDarkChanged)

import Json.Encode as Encode


{-| Persists the full account/server list (with their enabled flags) to localStorage.
-}
port persist : Encode.Value -> Cmd msg


{-| Applies the effective dark/light mode to the page: "dark" or "light" sets
`<html data-theme>` (overriding the system preference); "auto" clears it
(falling back to the `prefers-color-scheme` media query).
-}
port setTheme : String -> Cmd msg


{-| Fires when the OS-level dark/light preference changes while the app is
open (relevant only in "auto" mode).
-}
port systemPrefersDarkChanged : (Bool -> msg) -> Sub msg
