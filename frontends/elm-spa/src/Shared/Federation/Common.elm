module Shared.Federation.Common exposing (jsonResolver, nonEmpty)

{-| Small helpers shared across Rellm's federation-protocol integrations -- currently
`Shared.Federation.Mastodon`/`Bluesky`'s own post-fetching, and `Shared.AccountsPanel`'s Mastodon/
Bluesky account-connection tasks. Not meant to grow into a general-purpose utils module, just a home
for the bits those would otherwise each duplicate.
-}

import Http
import Json.Decode as Decode


{-| `""` -> `Nothing`, anything else -> `Just` itself -- several third-party APIs (Mastodon's
`display_name`, when unset) use a blank string rather than a missing/null field as their own
"nothing set" convention.
-}
nonEmpty : String -> Maybe String
nonEmpty s =
    if String.isEmpty s then
        Nothing

    else
        Just s


{-| Builds an `Http.task`'s `resolver` for a JSON API: decodes `decoder` out of a `GoodStatus_`
body (`Http.BadBody` on a decode failure), maps `NetworkError_`/`Timeout_`/`BadUrl_` onto their own
`Http.Error` constructors, and hands a `BadStatus_`'s metadata/body to `onBadStatus` to build
whatever `Http.Error` is most useful for that specific API's own error shape -- e.g.
`Shared.AccountsPanel.verifyMastodonCredentialsTask`'s just uses the bare status code, while
`createBlueskySessionTask`'s tries to pull a human-readable `message` out of the body first. Shared
by every caller so this `GoodStatus_`/`NetworkError_`/`Timeout_`/`BadUrl_` boilerplate isn't
duplicated across them.
-}
jsonResolver : Decode.Decoder a -> (Http.Metadata -> String -> Http.Error) -> Http.Resolver Http.Error a
jsonResolver decoder onBadStatus =
    Http.stringResolver
        (\response ->
            case response of
                Http.GoodStatus_ _ body ->
                    case Decode.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (Http.BadBody (Decode.errorToString err))

                Http.BadStatus_ metadata body ->
                    Err (onBadStatus metadata body)

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)
        )
