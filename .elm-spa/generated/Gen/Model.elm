module Gen.Model exposing (Model(..))

import Gen.Params.NotFound
import Pages.NotFound


type Model
    = Redirecting_
    | NotFound Gen.Params.NotFound.Params

