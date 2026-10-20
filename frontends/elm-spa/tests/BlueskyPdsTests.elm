module BlueskyPdsTests exposing (suite)

{-| Finding which PDS a Bluesky account logs in at (`BlueskyAccounts.pdsHostFromEndpoint`/
`pdsHostFromDidDocument`), the `BlueskyAccount` persistence default for accounts saved before `pdsHost`
existed, and the anonymous-AppView list helpers.
-}

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Shared.AccountsPanel.BlueskyAccounts as BlueskyAccounts
import Shared.AccountsPanel.BlueskyAppViews as BlueskyAppViews
import Test exposing (Test, describe, test)


didDocument : String -> Encode.Value
didDocument endpoint =
    Encode.object
        [ ( "id", Encode.string "did:plc:abc" )
        , ( "service"
          , Encode.list identity
                [ Encode.object
                    [ ( "id", Encode.string "#atproto_labeler" )
                    , ( "type", Encode.string "AtprotoLabeler" )
                    , ( "serviceEndpoint", Encode.string "https://labeler.example" )
                    ]
                , Encode.object
                    [ ( "id", Encode.string "#atproto_pds" )
                    , ( "type", Encode.string "AtprotoPersonalDataServer" )
                    , ( "serviceEndpoint", Encode.string endpoint )
                    ]
                ]
          )
        ]


aliceAccount : Bool -> BlueskyAccounts.BlueskyAccount
aliceAccount enabled =
    { handle = "alice.bsky.social"
    , accessToken = "a"
    , refreshToken = "r"
    , enabled = enabled
    , avatarUrl = Nothing
    , displayName = Nothing
    , sortOrder = 0
    , needsReauth = False
    , pdsHost = "bsky.social"
    }


suite : Test
suite =
    describe "Bluesky multi-PDS support"
        [ describe "pdsHostFromEndpoint"
            [ test "a third-party PDS is used as-is" <|
                \_ ->
                    BlueskyAccounts.pdsHostFromEndpoint "https://eurosky.social"
                        |> Expect.equal (Just "eurosky.social")
            , test "a trailing slash and path are ignored" <|
                \_ ->
                    BlueskyAccounts.pdsHostFromEndpoint "https://pds.example.com/"
                        |> Expect.equal (Just "pds.example.com")
            , test "a non-default port is kept" <|
                \_ ->
                    BlueskyAccounts.pdsHostFromEndpoint "https://pds.example.com:2583"
                        |> Expect.equal (Just "pds.example.com:2583")
            , test "Bluesky's own PDS shards log in through the bsky.social entryway" <|
                \_ ->
                    BlueskyAccounts.pdsHostFromEndpoint "https://puffball.us-east.host.bsky.network"
                        |> Expect.equal (Just "bsky.social")
            , test "plain http is refused, since an App Password would be sent in the clear" <|
                \_ ->
                    BlueskyAccounts.pdsHostFromEndpoint "http://pds.example.com"
                        |> Expect.equal Nothing
            , test "localhost, local names and IP literals are refused" <|
                \_ ->
                    [ "https://localhost", "https://pds.local", "https://box.internal", "https://127.0.0.1", "https://192.168.1.5:2583", "https://[::1]" ]
                        |> List.map BlueskyAccounts.pdsHostFromEndpoint
                        |> Expect.equal (List.repeat 6 Nothing)
            , test "garbage is refused" <|
                \_ ->
                    BlueskyAccounts.pdsHostFromEndpoint "not a url"
                        |> Expect.equal Nothing
            ]
        , describe "pdsHostFromDidDocument"
            [ test "reads the #atproto_pds service, skipping other services" <|
                \_ ->
                    BlueskyAccounts.pdsHostFromDidDocument (didDocument "https://eurosky.social")
                        |> Expect.equal (Just "eurosky.social")
            , test "maps a Bluesky shard to the entryway" <|
                \_ ->
                    BlueskyAccounts.pdsHostFromDidDocument (didDocument "https://puffball.us-east.host.bsky.network")
                        |> Expect.equal (Just "bsky.social")
            , test "a document with no PDS service has none" <|
                \_ ->
                    BlueskyAccounts.pdsHostFromDidDocument (Encode.object [ ( "service", Encode.list identity [] ) ])
                        |> Expect.equal Nothing
            , test "a document with no service list has none" <|
                \_ ->
                    BlueskyAccounts.pdsHostFromDidDocument (Encode.object [])
                        |> Expect.equal Nothing
            ]
        , describe "BlueskyAccount persistence"
            [ test "an account saved before pdsHost existed defaults to bsky.social" <|
                \_ ->
                    let
                        legacy : Encode.Value
                        legacy =
                            Encode.list identity
                                [ Encode.object
                                    [ ( "handle", Encode.string "alice.bsky.social" )
                                    , ( "accessToken", Encode.string "a" )
                                    , ( "refreshToken", Encode.string "r" )
                                    , ( "enabled", Encode.bool True )
                                    ]
                                ]
                    in
                    Decode.decodeValue BlueskyAccounts.decoder legacy
                        |> Result.map (List.map .pdsHost)
                        |> Expect.equal (Ok [ "bsky.social" ])
            , test "pdsHost survives an encode/decode round trip" <|
                \_ ->
                    let
                        account : BlueskyAccounts.BlueskyAccount
                        account =
                            { handle = "alice.eurosky.social"
                            , accessToken = "a"
                            , refreshToken = "r"
                            , enabled = True
                            , avatarUrl = Nothing
                            , displayName = Nothing
                            , sortOrder = 3
                            , needsReauth = False
                            , pdsHost = "eurosky.social"
                            }
                    in
                    Decode.decodeValue BlueskyAccounts.decoder (BlueskyAccounts.encodeList [ account ])
                        |> Expect.equal (Ok [ account ])
            , test "authFor sends requests to the account's own PDS" <|
                \_ ->
                    BlueskyAccounts.authFor
                        { handle = "alice.eurosky.social"
                        , accessToken = "tok"
                        , refreshToken = "r"
                        , enabled = True
                        , avatarUrl = Nothing
                        , displayName = Nothing
                        , sortOrder = 0
                        , needsReauth = False
                        , pdsHost = "eurosky.social"
                        }
                        |> Expect.equal { host = "eurosky.social", accessToken = "tok" }
            ]
        , describe "cleanIdentifier"
            [ test "trims and drops a leading @" <|
                \_ ->
                    BlueskyAccounts.cleanIdentifier "  @alice.eurosky.social "
                        |> Expect.equal "alice.eurosky.social"
            ]
        , describe "applyRefresh"
            [ test "takes only the session fields from the refreshed copy" <|
                \_ ->
                    let
                        stored : BlueskyAccounts.BlueskyAccount
                        stored =
                            { handle = "alice.bsky.social"
                            , accessToken = "old"
                            , refreshToken = "oldr"
                            , enabled = False
                            , avatarUrl = Just "new-avatar"
                            , displayName = Just "Alice"
                            , sortOrder = 7
                            , needsReauth = True
                            , pdsHost = "bsky.social"
                            }

                        refreshed : BlueskyAccounts.BlueskyAccount
                        refreshed =
                            { stored | accessToken = "new", refreshToken = "newr", needsReauth = False, enabled = True, avatarUrl = Nothing, displayName = Nothing, sortOrder = 0 }
                    in
                    BlueskyAccounts.applyRefresh refreshed stored
                        |> Expect.equal { stored | accessToken = "new", refreshToken = "newr", needsReauth = False }
            ]
        , describe "BlueskyAppViews"
            [ test "the public AppView is shown as bsky.app" <|
                \_ ->
                    BlueskyAppViews.displayName "public.api.bsky.app"
                        |> Expect.equal "bsky.app"
            , test "another AppView is shown as its own host" <|
                \_ ->
                    BlueskyAppViews.displayName "api.example.com"
                        |> Expect.equal "api.example.com"
            , test "enableOnly turns exactly one on" <|
                \_ ->
                    BlueskyAppViews.enableOnly "b"
                        [ { host = "a", enabled = True, sortOrder = 0 }
                        , { host = "b", enabled = False, sortOrder = 1 }
                        ]
                        |> List.map .enabled
                        |> Expect.equal [ False, True ]
            , test "disableAll turns everything off" <|
                \_ ->
                    BlueskyAppViews.disableAll
                        [ { host = "a", enabled = True, sortOrder = 0 }
                        , { host = "b", enabled = True, sortOrder = 1 }
                        ]
                        |> List.map .enabled
                        |> Expect.equal [ False, False ]
            , test "an enabled account turns every AppView off when normalizing" <|
                \_ ->
                    BlueskyAppViews.normalize [ aliceAccount True ]
                        [ { host = "a", enabled = True, sortOrder = 0 }, { host = "b", enabled = True, sortOrder = 1 } ]
                        |> List.map .enabled
                        |> Expect.equal [ False, False ]
            , test "with no enabled account, normalizing keeps only the first enabled AppView" <|
                \_ ->
                    BlueskyAppViews.normalize [ aliceAccount False ]
                        [ { host = "a", enabled = False, sortOrder = 0 }
                        , { host = "b", enabled = True, sortOrder = 1 }
                        , { host = "c", enabled = True, sortOrder = 2 }
                        ]
                        |> List.map .enabled
                        |> Expect.equal [ False, True, False ]
            , test "a disabled account and a single enabled AppView are left alone" <|
                \_ ->
                    BlueskyAppViews.normalize [ aliceAccount False ] [ { host = "a", enabled = True, sortOrder = 0 } ]
                        |> List.map .enabled
                        |> Expect.equal [ True ]
            , test "persisted state still reads the legacy bare list of accounts" <|
                \_ ->
                    Decode.decodeValue BlueskyAppViews.stateDecoder (BlueskyAccounts.encodeList [ aliceAccount True ])
                        |> Result.map (\state -> ( List.length state.accounts, state.appViews ))
                        |> Expect.equal (Ok ( 1, [] ))
            , test "persisted state round-trips accounts and AppViews" <|
                \_ ->
                    let
                        state : BlueskyAppViews.BlueskyState
                        state =
                            { accounts = [ aliceAccount False ], appViews = [ { host = "public.api.bsky.app", enabled = True, sortOrder = 2 } ] }
                    in
                    Decode.decodeValue BlueskyAppViews.stateDecoder (BlueskyAppViews.encodeState state)
                        |> Expect.equal (Ok state)
            , test "round-trips through its persisted form" <|
                \_ ->
                    let
                        appView : BlueskyAppViews.BlueskyAppView
                        appView =
                            { host = "public.api.bsky.app", enabled = True, sortOrder = 5 }
                    in
                    Decode.decodeValue BlueskyAppViews.decoder (BlueskyAppViews.encode appView)
                        |> Expect.equal (Ok appView)
            ]
        ]
