port module Ports exposing
    ( clearFederatedAuthKeyPair
    , federatedAuthDecrypt
    , federatedAuthDecrypted
    , federatedAuthEncrypt
    , federatedAuthEncrypted
    , federatedAuthGenerateKeyPair
    , federatedAuthKeyPairGenerated
    , persist
    , persistFederatedAuthKeyPair
    , persistStarredPosts
    , persistThemePreference
    , setTheme
    , systemPrefersDarkChanged
    )

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



-- FEDERATED AUTH (see `Shared.FederatedAuth`) -- SSO-style cross-server
-- account hand-off, encrypted with a per-browser ECDH keypair via the
-- browser's WebCrypto `SubtleCrypto` API (no crypto primitives in Elm
-- itself). See `public/index.html` for the JS side of all of these.


{-| Generates a fresh ECDH (P-256) keypair; the result arrives via
`federatedAuthKeyPairGenerated`. The argument is unused (ports need a
JSON-encodable payload) -- always call with `Encode.null`.
-}
port federatedAuthGenerateKeyPair : Encode.Value -> Cmd msg


{-| `{ publicKey : String, privateKey : String }`, both base64url-encoded --
see `Shared.FederatedAuth.keyPairDecoder`.
-}
port federatedAuthKeyPairGenerated : (Encode.Value -> msg) -> Sub msg


{-| Persists the current keypair (see `federatedAuthKeyPairGenerated`) to its
own localStorage key, mirroring `persistStarredPosts`/`persistThemePreference`.
-}
port persistFederatedAuthKeyPair : Encode.Value -> Cmd msg


{-| Drops the persisted keypair from localStorage -- called once a received
account has been accepted or declined (see `Shared.FederatedAuth.Discarded`),
so a used private key doesn't linger. The argument is unused, same as
`federatedAuthGenerateKeyPair`.
-}
port clearFederatedAuthKeyPair : Encode.Value -> Cmd msg


{-| Encrypts `{ publicKey : String, plaintext : String }` (the recipient's
public key and the plaintext to encrypt to it) via ECIES-style hybrid
encryption (ephemeral ECDH + HKDF-SHA256 + AES-256-GCM); the result arrives
via `federatedAuthEncrypted`.
-}
port federatedAuthEncrypt : Encode.Value -> Cmd msg


{-| `{ ok : Bool, value : String }` -- `value` is the encrypted, url-safe
ciphertext string on success, or an error message on failure.
-}
port federatedAuthEncrypted : (Encode.Value -> msg) -> Sub msg


{-| Decrypts `{ privateKey : String, encoded : String }` (this origin's own
private key and a ciphertext string produced by `federatedAuthEncrypt`
elsewhere); the result arrives via `federatedAuthDecrypted`.
-}
port federatedAuthDecrypt : Encode.Value -> Cmd msg


{-| `{ ok : Bool, value : String }` -- `value` is the decrypted plaintext on
success, or an error message on failure (wrong key, tampered ciphertext,
etc).
-}
port federatedAuthDecrypted : (Encode.Value -> msg) -> Sub msg
