module Shared.MaybeAccountRequest exposing
    ( Token
    , isExpired
    , perform
    , performWithAccount
    , timestampToPosix
    , tokenFromExpirable
    )

{-| Access tokens expire; refresh tokens (usually) don't, but can rotate.
Rather than scattering "is this token stale?" checks through every
authenticated call, `performWithAccount` wraps a request with: check the
access token against the current time, refresh it first (via the
`AccessToken` RPC, using the refresh token) if it's expired or expiring soon,
*then* make the actual request with whatever access token ends up being
current.

`perform` is the more commonly useful entry point (hence this module's name):
a request that may or may not have an `Account` behind it at all -- e.g.
fetching a post, which should work whether or not the viewer happens to be
signed into that post's server. It performs an authenticated
(`performWithAccount`) request when given `Just` an account, or an anonymous
one (`req Nothing`) otherwise, uniformly returning the (possibly-refreshed)
account back to the caller so it can persist that refresh -- see
`Shared.AccountsPanel.AccountRefreshed`.

Both work on any record with `accessToken`/`refreshToken` fields (so they're
usable directly with `Shared.AccountsPanel.Account`, or any smaller/future
account-shaped record) via an extensible record type, rather than depending
on `Shared.AccountsPanel` and risking an import cycle (that module depends on
this one, for `Token`).
-}

import Grpc
import Proto.Jonline exposing (ExpirableToken)
import Proto.Jonline.Jonline as Jonline
import Protobuf.Types.Int64 as Int64
import Task exposing (Task)
import Time


{-| Like `ExpirableToken`, but with a plain `Time.Posix` expiration instead of
a protobuf `Timestamp` (whose seconds are an `Int64`) -- directly comparable
to `Time.now`, and easy to persist as milliseconds.
-}
type alias Token =
    { token : String
    , expiresAt : Maybe Time.Posix
    }


tokenFromExpirable : ExpirableToken -> Token
tokenFromExpirable expirable =
    { token = expirable.token
    , expiresAt = Maybe.map timestampToPosix expirable.expiresAt
    }


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


{-| Whether a token is expired, or expiring within the next minute (enough
margin that it shouldn't expire mid-request). A token with no expiration
(`expiresAt == Nothing`, the default unless a server was asked for one)
never expires.
-}
isExpired : Time.Posix -> Token -> Bool
isExpired now token =
    case token.expiresAt of
        Nothing ->
            False

        Just expiresAt ->
            Time.posixToMillis now + 60000 >= Time.posixToMillis expiresAt


{-| Ensures `account`'s access token is valid as of now (refreshing it first
if needed), then performs `req` with it. `req` is given just the access token
string, ready to pass to `Grpc.addHeader "authorization"`. Returns the account
as it ended up (with refreshed tokens if a refresh happened, unchanged
otherwise) alongside `req`'s result, so the caller can persist any refreshed
tokens.
-}
performWithAccount :
    { host : String, port_ : Int, tls : Bool }
    -> { a | accessToken : Token, refreshToken : Token }
    -> (String -> Task Grpc.Error b)
    -> Task Grpc.Error ( { a | accessToken : Token, refreshToken : Token }, b )
performWithAccount connection account req =
    Time.now
        |> Task.andThen (\now -> refreshIfNeeded connection now account)
        |> Task.andThen
            (\refreshedAccount ->
                req refreshedAccount.accessToken.token
                    |> Task.map (Tuple.pair refreshedAccount)
            )


{-| Like `performWithAccount`, but the account is optional: with `Just` an
account, authenticates (refreshing first if needed) exactly like
`performWithAccount`; with `Nothing`, just performs `req` anonymously (no
authorization header). Either way, `req` gets the access token string to use,
if any.
-}
perform :
    { host : String, port_ : Int, tls : Bool }
    -> Maybe { a | accessToken : Token, refreshToken : Token }
    -> (Maybe String -> Task Grpc.Error b)
    -> Task Grpc.Error ( Maybe { a | accessToken : Token, refreshToken : Token }, b )
perform connection maybeAccount req =
    case maybeAccount of
        Just account ->
            performWithAccount connection account (Just >> req)
                |> Task.map (Tuple.mapFirst Just)

        Nothing ->
            req Nothing |> Task.map (Tuple.pair Nothing)


refreshIfNeeded :
    { host : String, port_ : Int, tls : Bool }
    -> Time.Posix
    -> { a | accessToken : Token, refreshToken : Token }
    -> Task Grpc.Error { a | accessToken : Token, refreshToken : Token }
refreshIfNeeded connection now account =
    if not (isExpired now account.accessToken) then
        Task.succeed account

    else
        Grpc.new Jonline.accessToken { refreshToken = account.refreshToken.token, expiresAt = Nothing }
            |> Grpc.setHost (connectionUrl connection)
            |> Grpc.toTask
            |> Task.andThen
                (\resp ->
                    case resp.accessToken of
                        Just accessToken ->
                            Task.succeed
                                { account
                                    | accessToken = tokenFromExpirable accessToken
                                    , refreshToken =
                                        resp.refreshToken
                                            |> Maybe.map tokenFromExpirable
                                            |> Maybe.withDefault account.refreshToken
                                }

                        Nothing ->
                            Task.fail Grpc.NetworkError
                )


connectionUrl : { host : String, port_ : Int, tls : Bool } -> String
connectionUrl connection =
    (if connection.tls then
        "https://"

     else
        "http://"
    )
        ++ connection.host
        ++ ":"
        ++ String.fromInt connection.port_
