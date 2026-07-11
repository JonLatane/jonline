module Pages.Home_ exposing (view)

import Html
import UI
import View exposing (View)



-- view : View msg
-- view =
--     { title = "Homepage"
--     , body = [ Html.text "Hello, world!" ]
--     }


view : View msg
view =
    { title = "Homepage"
    , body = UI.layout [ Html.text "This is the Jonline home page. Probabl still need to do more stuff here!" ]
    }
