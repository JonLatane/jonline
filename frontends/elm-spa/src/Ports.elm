port module Ports exposing (persist)

import Json.Encode as Encode


{-| Persists the full account/server list (with their enabled flags) to localStorage.
-}
port persist : Encode.Value -> Cmd msg
