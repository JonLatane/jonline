module UI exposing (layout)

import Html exposing (Html)
import Html.Attributes as Attr


layout : List (Html msg) -> List (Html msg)
layout children =
    let
        viewLink : String -> String -> Html msg
        viewLink label url =
            Html.a [ Attr.href url ] [ Html.text label ]
    in
    [ Html.div [ Attr.class "container" ]
        [ Html.header [ Attr.class "navbar" ]
            [ viewLink "Home" "/"
            , viewLink "About" "/about"
            ]
        , Html.main_ [] children
        ]
    ]
