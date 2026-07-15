module UI.Modal exposing (Config, backdrop, view)

{-| A generic centered dialog: fixed backdrop + header/body/buttons frame,
always rendered (even closed) so opening/closing is a CSS transition rather
than the elements themselves appearing/disappearing outright -- see
`main.css`'s `.modal`/`.modal-backdrop`. Extracted from the Create Account
confirmation dialog (`UI.createAccountConfirmationModal`) so every
Cancel/Confirm-style dialog (Create Account, delete confirmation, and future
ones) shares one implementation. `config.class` (e.g. "create-account-modal")
names the specific dialog for its own width/content overrides, layered on top
of the shared `.modal` rules.
-}

import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import UI.Classes exposing (classes, openClosedClass)


type alias Config msg =
    { class : String
    , isOpen : Bool
    , header : Html msg
    , bodyAttrs : List (Attribute msg)
    , body : List (Html msg)
    , buttons : List (Html msg)
    }


{-| The full-viewport backdrop behind a modal -- rendered separately from
`view` since callers put it at a different point in the DOM (e.g. right after
`sharedBackdrop`, before the nav), same as the original
`createAccountConfirmationBackdrop`.
-}
backdrop : Bool -> msg -> Html msg
backdrop isOpen onBackdropClick =
    div
        [ classes [ "modal-backdrop", openClosedClass isOpen ]
        , onClick onBackdropClick
        ]
        []


view : Config msg -> Html msg
view config =
    div [ classes [ "modal", config.class, openClosedClass config.isOpen ] ]
        [ div [ class "modal-header" ] [ config.header ]
        , div (class "modal-body" :: config.bodyAttrs) config.body
        , div [ class "modal-buttons" ] config.buttons
        ]
