module Shared.Conversions exposing (..)

import Protobuf.Types.Int64 as Int64
import Time


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
