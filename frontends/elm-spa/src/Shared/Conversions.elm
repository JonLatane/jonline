module Shared.Conversions exposing (..)

import Animation
import Browser.Dom as Dom
import Char
import Dict exposing (Dict)
import Grpc
import Html exposing (Html, div, img, text)
import Html.Attributes exposing (alt, class, src)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports
import Proto.Jonline exposing (ExpirableToken, RefreshTokenResponse, ServerConfiguration, ServerInfo, User, defaultServerInfo)
import Proto.Jonline.Jonline as Jonline
import Proto.Jonline.Permission exposing (Permission(..), fieldNumbersPermission)
import Proto.Jonline.WebUserInterface exposing (WebUserInterface)
import Protobuf.Types.Int64 as Int64
import Request exposing (Request)
import Set
import Task exposing (Task)
import Time
import UI.Flip
import UI.ServerTheme
import Url


{-| Converts a protobuf `Timestamp` (seconds + nanos) to `Time.Posix` --
usable for any protobuf timestamp field (e.g. `ExpirableToken.expiresAt`,
`Post.publishedAt`/`.createdAt`), not just token expirations.
-}
timestampToPosix : { seconds : Int64.Int64, nanos : Int } -> Time.Posix
timestampToPosix timestamp =
    Time.millisToPosix (int64ToInt timestamp.seconds * 1000 + timestamp.nanos // 1000000)


int64ToInt : Int64.Int64 -> Int
int64ToInt value =
    let
        ( high, low ) =
            Int64.toInts value

        unsignedLow =
            if low < 0 then
                low + 4294967296

            else
                low
    in
    high * 4294967296 + unsignedLow
