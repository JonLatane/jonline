module Shared.FederatedAuth exposing
    ( Model
    , Msg(..)
    , PrivateKey
    , PublicKey
    , decrypt
    , decryptResult
    , encrypt
    , encryptResult
    , init
    , publicKeyToUrlString
    , subscriptions
    , update
    , urlStringToPublicKey
    )

{-| SSO-style cross-server account hand-off: lets one origin's SPA (e.g.
`bullcity.social`) receive an already-signed-in `Shared.AccountsPanel.Account`
from a different origin's SPA (e.g. `jonline.io`) without ever typing that
origin's password into `bullcity.social`. See `Pages.Auth.To.Key_` (the
sending side) and `Pages.Auth.From.EncodedAccount_` (the receiving side).

This origin's ECDH (P-256) keypair -- generated and persisted here -- is
what a request gets encrypted to; the actual keygen/encrypt/decrypt (ECIES-
style hybrid encryption: ephemeral ECDH + HKDF-SHA256 + AES-256-GCM) all
happens in JS behind `Ports`, via the browser's WebCrypto `SubtleCrypto` API
-- Elm has no crypto/bigint support of its own. `PublicKey`/`PrivateKey` here
are just opaque, already base64url-encoded strings handed back from JS.

The keypair is single-use: `Pages.Auth.From.EncodedAccount_` calls `discard`
once its flow reaches a terminal state (account accepted or declined), so a
used private key doesn't linger in localStorage, and a fresh keypair is
always ready for the next attempt.

-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports


type PublicKey
    = PublicKey String


type PrivateKey
    = PrivateKey String


type alias Model =
    { publicKey : Maybe PublicKey
    , privateKey : Maybe PrivateKey
    }


type Msg
    = GotKeyPair Decode.Value
    | Discarded


{-| Loads a keypair persisted from a previous session (`flags` is whatever
was under the `federatedAuthKeyPair` flag key, `null` if none), or generates
a fresh one immediately if there wasn't one.
-}
init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    case Decode.decodeValue (Decode.nullable keyPairDecoder) flags of
        Ok (Just model) ->
            ( model, Cmd.none )

        _ ->
            ( { publicKey = Nothing, privateKey = Nothing }, Ports.federatedAuthGenerateKeyPair Encode.null )


keyPairDecoder : Decoder Model
keyPairDecoder =
    Decode.map2 (\publicKey privateKey -> { publicKey = Just (PublicKey publicKey), privateKey = Just (PrivateKey privateKey) })
        (Decode.field "publicKey" Decode.string)
        (Decode.field "privateKey" Decode.string)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotKeyPair value ->
            case Decode.decodeValue keyPairDecoder value of
                Ok newModel ->
                    ( newModel, Ports.persistFederatedAuthKeyPair value )

                Err _ ->
                    ( model, Cmd.none )

        Discarded ->
            ( { publicKey = Nothing, privateKey = Nothing }
            , Cmd.batch [ Ports.clearFederatedAuthKeyPair Encode.null, Ports.federatedAuthGenerateKeyPair Encode.null ]
            )


subscriptions : Sub Msg
subscriptions =
    Ports.federatedAuthKeyPairGenerated GotKeyPair



-- PUBLIC KEY STRINGS
-- Purely a matter of wrapping/validating a string -- unlike keygen/encrypt/
-- decrypt (below), no crypto is involved, so these stay plain functions.


publicKeyToUrlString : PublicKey -> String
publicKeyToUrlString (PublicKey s) =
    s


{-| Validates that `s` at least looks like a base64url-encoded key (its
actual validity as key material is only ever checked by WebCrypto itself,
when it's used to encrypt) before wrapping it -- in particular rejecting `@`,
which would be ambiguous in the `/auth/to/:key` route's own `key@host` split.
-}
urlStringToPublicKey : String -> Maybe PublicKey
urlStringToPublicKey s =
    if String.isEmpty s || not (String.all isBase64UrlChar s) then
        Nothing

    else
        Just (PublicKey s)


isBase64UrlChar : Char -> Bool
isBase64UrlChar c =
    Char.isAlphaNum c || c == '-' || c == '_'



-- ENCRYPT / DECRYPT
-- These are one-shot, page-local request/response cycles (unlike keypair
-- generation, which is app-wide) -- callers fire `encrypt`/`decrypt`, then
-- subscribe to `Ports.federatedAuthEncrypted`/`federatedAuthDecrypted`
-- directly in their own `subscriptions`, decoding results with
-- `encryptResult`/`decryptResult`.


encrypt : PublicKey -> String -> Cmd msg
encrypt (PublicKey publicKey) plaintext =
    Ports.federatedAuthEncrypt
        (Encode.object
            [ ( "publicKey", Encode.string publicKey )
            , ( "plaintext", Encode.string plaintext )
            ]
        )


decrypt : PrivateKey -> String -> Cmd msg
decrypt (PrivateKey privateKey) encoded =
    Ports.federatedAuthDecrypt
        (Encode.object
            [ ( "privateKey", Encode.string privateKey )
            , ( "encoded", Encode.string encoded )
            ]
        )


{-| Decodes a `federatedAuthEncrypted` payload (`{ ok : Bool, value : String }`)
into a `Result` -- the ciphertext string on success, an error message
otherwise.
-}
encryptResult : Decode.Value -> Result String String
encryptResult =
    resultDecoder


{-| Decodes a `federatedAuthDecrypted` payload -- same shape as
`encryptResult`, the plaintext string on success.
-}
decryptResult : Decode.Value -> Result String String
decryptResult =
    resultDecoder


resultDecoder : Decode.Value -> Result String String
resultDecoder value =
    case
        Decode.decodeValue
            (Decode.map2 Tuple.pair (Decode.field "ok" Decode.bool) (Decode.field "value" Decode.string))
            value
    of
        Ok ( True, v ) ->
            Ok v

        Ok ( False, err ) ->
            Err err

        Err err ->
            Err (Decode.errorToString err)
