module SocialMediaEmbedTests exposing (suite)

{-| `SocialMediaEmbed`: which links each network's module recognizes (and the embed page each becomes), what the
facade picks for a link, and what the rendered embed looks like. Mirrors what `react-social-media-embed` accepts,
plus the link spellings people actually paste.
-}

import Expect
import Html
import Html.Attributes
import SocialMediaEmbed
import SocialMediaEmbed.Common as Common exposing (Link)
import SocialMediaEmbed.Facebook as Facebook
import SocialMediaEmbed.Instagram as Instagram
import SocialMediaEmbed.LinkedIn as LinkedIn
import SocialMediaEmbed.Pinterest as Pinterest
import SocialMediaEmbed.TikTok as TikTok
import SocialMediaEmbed.X as X
import SocialMediaEmbed.YouTube as YouTube
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Url


{-| The embed page `link` becomes on one network, if it's that network's.
-}
embedSrc : (Link -> Maybe embed) -> (embed -> String) -> String -> Maybe String
embedSrc fromLink srcOf rawLink =
    Common.parseLink rawLink |> Maybe.andThen fromLink |> Maybe.map srcOf


resolves : (String -> Maybe String) -> String -> Maybe String -> Test
resolves toSrc link expected =
    test link <|
        \_ -> toSrc link |> Expect.equal expected


youtube : String -> Maybe String
youtube =
    embedSrc YouTube.fromLink YouTube.srcOf


instagram : String -> Maybe String
instagram =
    embedSrc Instagram.fromLink Instagram.srcOf


x : String -> Maybe String
x =
    embedSrc X.fromLink X.srcOf


facebook : String -> Maybe String
facebook =
    embedSrc Facebook.fromLink Facebook.srcOf


linkedin : String -> Maybe String
linkedin =
    embedSrc LinkedIn.fromLink LinkedIn.srcOf


pinterest : String -> Maybe String
pinterest =
    embedSrc Pinterest.fromLink Pinterest.srcOf


tiktok : String -> Maybe String
tiktok =
    embedSrc TikTok.fromLink TikTok.srcOf


network : String -> Maybe String
network rawLink =
    SocialMediaEmbed.fromLink rawLink |> Maybe.map SocialMediaEmbed.network


suite : Test
suite =
    describe "SocialMediaEmbed"
        [ describe "Common.parseLink"
            [ test "a full URL" <|
                \_ ->
                    Common.parseLink "https://www.Example.com/a/b%20c?x=1&y=two%20words#frag"
                        |> Expect.equal (Just { raw = "https://www.Example.com/a/b%20c?x=1&y=two%20words#frag", host = "example.com", segments = [ "a", "b c" ], query = [ ( "x", "1" ), ( "y", "two words" ) ] })
            , test "no scheme" <|
                \_ -> Common.parseLink "youtu.be/abc" |> Maybe.map (\link -> ( link.host, link.raw )) |> Expect.equal (Just ( "youtu.be", "https://youtu.be/abc" ))
            , test "not a web address" <|
                \_ -> [ "", "   ", "/post/abc", "hello world", "localhost", "not a link.com" ] |> List.map Common.parseLink |> Expect.equalLists (List.repeat 6 Nothing)
            , test "hostIs matches subdomains but not look-alikes" <|
                \_ ->
                    [ "https://m.youtube.com/x", "https://youtube.com/x", "https://notyoutube.com/x", "https://youtube.com.evil.example/x" ]
                        |> List.map (\raw -> Common.parseLink raw |> Maybe.map (Common.hostIs "youtube.com"))
                        |> Expect.equalLists [ Just True, Just True, Just False, Just False ]
            ]
        , describe "YouTube"
            [ resolves youtube "https://www.youtube.com/watch?v=dQw4w9WgXcQ" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ")
            , resolves youtube "https://youtube.com/watch?feature=share&v=dQw4w9WgXcQ&list=PLx" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ")
            , resolves youtube "https://m.youtube.com/watch?v=dQw4w9WgXcQ" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ")
            , resolves youtube "https://youtu.be/dQw4w9WgXcQ" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ")
            , resolves youtube "youtu.be/dQw4w9WgXcQ?si=abc" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ")
            , resolves youtube "https://www.youtube.com/shorts/dQw4w9WgXcQ" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ")
            , resolves youtube "https://www.youtube.com/live/dQw4w9WgXcQ?feature=share" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ")
            , resolves youtube "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ")
            , resolves youtube "https://youtu.be/dQw4w9WgXcQ?t=90" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ?start=90")
            , resolves youtube "https://youtu.be/dQw4w9WgXcQ?t=1m30s" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ?start=90")
            , resolves youtube "https://youtu.be/dQw4w9WgXcQ?t=1h2m3s" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ?start=3723")
            , resolves youtube "https://www.youtube.com/watch?v=dQw4w9WgXcQ&start=42" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ?start=42")
            , resolves youtube "https://youtu.be/dQw4w9WgXcQ?t=banana" (Just "https://www.youtube.com/embed/dQw4w9WgXcQ")
            , resolves youtube "https://www.youtube.com/@somechannel" Nothing
            , resolves youtube "https://www.youtube.com/playlist?list=PLx" Nothing
            , resolves youtube "https://www.youtube.com/watch?v=short" Nothing
            , resolves youtube "https://example.com/watch?v=dQw4w9WgXcQ" Nothing
            ]
        , describe "Instagram"
            [ resolves instagram "https://www.instagram.com/p/CsY_NinvWDW/" (Just "https://www.instagram.com/p/CsY_NinvWDW/embed/captioned/")
            , resolves instagram "https://instagram.com/p/CsY_NinvWDW" (Just "https://www.instagram.com/p/CsY_NinvWDW/embed/captioned/")
            , resolves instagram "https://www.instagram.com/reel/CsY_NinvWDW/?igsh=abc" (Just "https://www.instagram.com/reel/CsY_NinvWDW/embed/captioned/")
            , resolves instagram "https://www.instagram.com/someone/p/CsY_NinvWDW/" (Just "https://www.instagram.com/p/CsY_NinvWDW/embed/captioned/")
            , resolves instagram "https://www.instagram.com/someone/reel/CsY_NinvWDW/" (Just "https://www.instagram.com/reel/CsY_NinvWDW/embed/captioned/")
            , resolves instagram "https://www.instagram.com/tv/CsY_NinvWDW/" (Just "https://www.instagram.com/tv/CsY_NinvWDW/embed/captioned/")
            , resolves instagram "https://www.instagram.com/someone/" Nothing
            , resolves instagram "https://www.instagram.com/stories/someone/123/" Nothing
            ]
        , describe "X"
            [ resolves x "https://x.com/jack/status/20" (Just (xSrc "20"))
            , resolves x "https://twitter.com/jack/status/1234567890123456789?s=20" (Just (xSrc "1234567890123456789"))
            , resolves x "https://mobile.twitter.com/jack/status/20" (Just (xSrc "20"))
            , resolves x "https://x.com/jack/status/20/photo/1" (Just (xSrc "20"))
            , resolves x "https://x.com/i/web/status/20" (Just (xSrc "20"))
            , resolves x "https://x.com/jack" Nothing
            , resolves x "https://x.com/jack/status/notanumber" Nothing
            , resolves x "https://notx.com/jack/status/20" Nothing
            ]
        , describe "Facebook"
            [ resolves facebook "https://www.facebook.com/zuck/posts/10102577175875681" (Just (facebookPost "https://www.facebook.com/zuck/posts/10102577175875681"))
            , resolves facebook "https://m.facebook.com/zuck/posts/10102577175875681?ref=x" (Just (facebookPost "https://www.facebook.com/zuck/posts/10102577175875681?ref=x"))
            , resolves facebook "https://www.facebook.com/photo.php?fbid=123&set=a.456" (Just (facebookPost "https://www.facebook.com/photo.php?fbid=123&set=a.456"))
            , resolves facebook "https://www.facebook.com/permalink.php?story_fbid=123&id=456" (Just (facebookPost "https://www.facebook.com/permalink.php?story_fbid=123&id=456"))
            , resolves facebook "https://www.facebook.com/zuck/videos/123456" (Just (facebookVideo "https://www.facebook.com/zuck/videos/123456"))
            , resolves facebook "https://www.facebook.com/watch/?v=123456" (Just (facebookVideo "https://www.facebook.com/watch/?v=123456"))
            , resolves facebook "https://www.facebook.com/reel/123456" (Just (facebookVideo "https://www.facebook.com/reel/123456"))
            , resolves facebook "https://www.facebook.com/share/p/AbCdEf/" (Just (facebookPost "https://www.facebook.com/share/p/AbCdEf/"))
            , resolves facebook "https://www.facebook.com/share/v/AbCdEf/" (Just (facebookVideo "https://www.facebook.com/share/v/AbCdEf/"))
            , resolves facebook "https://www.facebook.com/zuck" Nothing
            , resolves facebook "https://www.facebook.com/" Nothing
            , resolves facebook "https://www.facebook.com/watch/" Nothing
            ]
        , describe "LinkedIn"
            [ resolves linkedin "https://www.linkedin.com/embed/feed/update/urn:li:share:6898694772484112384" (Just "https://www.linkedin.com/embed/feed/update/urn:li:share:6898694772484112384")
            , resolves linkedin "https://www.linkedin.com/feed/update/urn:li:activity:7012345678901234567/" (Just "https://www.linkedin.com/embed/feed/update/urn:li:activity:7012345678901234567")
            , resolves linkedin "https://www.linkedin.com/posts/someone_a-great-title-activity-7012345678901234567-AbCd" (Just "https://www.linkedin.com/embed/feed/update/urn:li:activity:7012345678901234567")
            , resolves linkedin "https://www.linkedin.com/posts/someone_title-ugcPost-7012345678901234567-AbCd?utm_source=share" (Just "https://www.linkedin.com/embed/feed/update/urn:li:ugcPost:7012345678901234567")
            , resolves linkedin "https://www.linkedin.com/in/jonlatane/" Nothing
            , resolves linkedin "https://www.linkedin.com/feed/update/urn:li:person:123" Nothing
            , resolves linkedin "https://www.linkedin.com/posts/someone_no-id-here" Nothing
            ]
        , describe "Pinterest"
            [ resolves pinterest "https://www.pinterest.com/pin/875105771321194304/" (Just "https://assets.pinterest.com/ext/embed.html?id=875105771321194304")
            , resolves pinterest "https://www.pinterest.com/pin/875105771321194304/sent/?invite_code=e86262c989ee4f559a08a4494c300ba3&sfo=1" (Just "https://assets.pinterest.com/ext/embed.html?id=875105771321194304")
            , resolves pinterest "https://pinterest.co.uk/pin/875105771321194304" (Just "https://assets.pinterest.com/ext/embed.html?id=875105771321194304")
            , resolves pinterest "https://de.pinterest.com/pin/875105771321194304/" (Just "https://assets.pinterest.com/ext/embed.html?id=875105771321194304")
            , resolves pinterest "https://www.pinterest.com/someone/a-board/" Nothing
            , resolves pinterest "https://pinterest.evil.example/pin/875105771321194304/" Nothing
            ]
        , describe "TikTok"
            [ resolves tiktok "https://www.tiktok.com/@epicgardening/video/7055411162212633903?is_copy_url=1&is_from_webapp=v1" (Just "https://www.tiktok.com/embed/v2/7055411162212633903")
            , resolves tiktok "https://tiktok.com/@epicgardening/video/7055411162212633903" (Just "https://www.tiktok.com/embed/v2/7055411162212633903")
            , resolves tiktok "https://www.tiktok.com/embed/v2/7055411162212633903" (Just "https://www.tiktok.com/embed/v2/7055411162212633903")
            , resolves tiktok "https://www.tiktok.com/@epicgardening" Nothing
            , resolves tiktok "https://vm.tiktok.com/ZMabc123/" Nothing
            , resolves tiktok "https://www.tiktok.com/@epicgardening/video/notanumber" Nothing
            ]
        , describe "SocialMediaEmbed.fromLink picks the network by host"
            [ test "each supported network" <|
                \_ ->
                    [ "https://youtu.be/dQw4w9WgXcQ"
                    , "https://x.com/jack/status/20"
                    , "https://twitter.com/jack/status/20"
                    , "https://www.instagram.com/p/CsY_NinvWDW/"
                    , "https://www.facebook.com/zuck/posts/1"
                    , "https://www.tiktok.com/@a/video/1"
                    , "https://www.pinterest.com/pin/1/"
                    , "https://www.linkedin.com/feed/update/urn:li:activity:1"
                    ]
                        |> List.map network
                        |> Expect.equalLists (List.map Just [ "youtube", "x", "x", "instagram", "facebook", "tiktok", "pinterest", "linkedin" ])
            , test "anything else is nothing" <|
                \_ ->
                    [ "https://example.com/article", "https://bsky.app/profile/a.bsky.social/post/3k", "not a link", "" ]
                        |> List.map network
                        |> Expect.equalLists (List.repeat 4 Nothing)
            ]
        , describe "view"
            [ test "an iframe on the embed page, lazy-loaded and sandboxed, in a box named for the network" <|
                \_ ->
                    rendered "https://www.facebook.com/zuck/posts/1"
                        |> Expect.all
                            [ Query.has [ Selector.class "rsme-embed", Selector.class "rsme-facebook-embed" ]
                            , Query.find [ Selector.tag "iframe" ]
                                >> Query.has
                                    [ Selector.attribute (Html.Attributes.attribute "loading" "lazy")
                                    , Selector.attribute (Html.Attributes.attribute "sandbox" "allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox allow-presentation allow-forms")
                                    , Selector.attribute (Html.Attributes.attribute "referrerpolicy" "strict-origin-when-cross-origin")
                                    ]
                            ]
            , test "the iframe's src is the embed page" <|
                \_ ->
                    rendered "https://x.com/jack/status/20"
                        |> Query.find [ Selector.tag "iframe" ]
                        |> Query.has [ Selector.attribute (Html.Attributes.src (xSrc "20")) ]
            , test "a placeholder link to the original post sits under it" <|
                \_ ->
                    rendered "https://x.com/jack/status/20?s=20"
                        |> Query.find [ Selector.class "rsme-placeholder" ]
                        |> Expect.all
                            [ Query.has [ Selector.attribute (Html.Attributes.href "https://x.com/jack/status/20?s=20"), Selector.text "View post on X" ]
                            , Query.has [ Selector.attribute (Html.Attributes.rel "noopener noreferrer") ]
                            ]
            , test "a video keeps a 16:9 box" <|
                \_ -> rendered "https://youtu.be/dQw4w9WgXcQ" |> Query.has [ Selector.style "aspect-ratio" "16 / 9" ]
            , test "a post's box takes its height from its iframe, so a resized iframe leaves no blank space" <|
                \_ ->
                    rendered "https://x.com/jack/status/20"
                        |> Query.findAll [ Selector.style "min-height" "350px" ]
                        |> Query.count (Expect.equal 0)
            , test "a post's iframe gets a fixed height (until the embed reports its own)" <|
                \_ ->
                    rendered "https://www.instagram.com/p/CsY_NinvWDW/"
                        |> Query.find [ Selector.tag "iframe" ]
                        |> Query.has [ Selector.style "height" "600px" ]
            ]
        ]


rendered : String -> Query.Single msg
rendered rawLink =
    case SocialMediaEmbed.fromLink rawLink of
        Just embed ->
            Query.fromHtml (SocialMediaEmbed.view embed)

        Nothing ->
            Query.fromHtml (Html.text "no embed")


xSrc : String -> String
xSrc id =
    "https://platform.twitter.com/embed/Tweet.html?dnt=true&frame=false&hideCard=false&hideThread=false&lang=en&theme=light&id=" ++ id


facebookPost : String -> String
facebookPost href =
    "https://www.facebook.com/plugins/post.php?href=" ++ percentEncode href ++ "&show_text=true&width=550"


facebookVideo : String -> String
facebookVideo href =
    "https://www.facebook.com/plugins/video.php?href=" ++ percentEncode href ++ "&show_text=true&width=550"


percentEncode : String -> String
percentEncode =
    Url.percentEncode
