module Shared.Federation.Common exposing (nonEmpty)

{-| Small helpers shared by every `Shared.Federation.*` protocol-translation module (currently
`Mastodon`/`Bluesky`) -- not meant to grow into a general-purpose string-utils module, just a home
for the bits those modules would otherwise each duplicate.
-}


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
