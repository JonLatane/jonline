port module Ports exposing (clearAccount, saveAccount)

import Json.Encode as Encode


{-| Persists the signed-in account (server, userId, username, refreshToken, accessToken) to localStorage.
-}
port saveAccount : Encode.Value -> Cmd msg


{-| Removes any persisted account from localStorage.
-}
port clearAccount : () -> Cmd msg
