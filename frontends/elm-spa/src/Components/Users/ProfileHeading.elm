module Components.Users.ProfileHeading exposing (nameHeader, usernameHeading)

{-| `usernameHeading`/`nameHeader` -- the read-only "name area" atop a profile
page (avatar, username, Admin/Run Bots badges, Real Name) -- factored out of
`Components.Pages.UserProfilePage` (which still uses both, for its own
`profileDetail`) into their own leaf module so `Components.Pages.PostsPage`/
`Components.Pages.EventsPage`/`Components.Pages.UsersPage` (which all need
`nameHeader`/`usernameHeading` for their own "Posts | <name>"/"Events | <name>"
headings) can depend on just this, rather than the whole of `UserProfilePage`
-- which itself now embeds a `PostsPage`/`EventsPage` pair of its own (see
`UserProfilePage.Model`'s `posts`/`events` fields), so `PostsPage`/`EventsPage`
importing `UserProfilePage` directly would be a module cycle.
-}

import Components.Authors as Authors
import Components.Users as Users
import Html exposing (Html, div, h1, span, text)
import Html.Attributes exposing (class)
import Proto.Jonline exposing (User)
import Shared.AccountsPanel as AccountsPanel
import UI


{-| A user's username (plus Admin/Run Bots badges, if applicable -- see
`Components.Authors.badges`) exactly as it appears atop their profile page --
factored out of `profileDetail` since `nameHeader` (below) also needs it,
unadorned by any edit affordance, so this itself stays `Html msg`-polymorphic.
Also used directly by `Components.Pages.PostsPage`/`Components.Pages.EventsPage`
as a no-avatar fallback for their "Posts | <name>"/"Events | <name>"
headings when the author's server isn't currently known/enabled (so there's no
`AccountsPanel.Server` to resolve an avatar against).
-}
usernameHeading : User -> Html msg
usernameHeading user =
    h1 [ class "profile-username" ]
        (text user.username :: Authors.badges user)


{-| The read-only "name area" atop a profile page -- `usernameHeading` plus
the Real Name, if set, with none of `Components.Pages.UserProfilePage.realNameView`'s
edit affordance (there's no viewer/edit state to check outside of that
module). Used by `Components.Pages.PostsPage`/`Components.Pages.EventsPage` for
their "Posts | <name>"/"Events | <name>" heading on a user's own
posts/events page.
-}
nameHeader : AccountsPanel.Server -> Maybe AccountsPanel.Account -> User -> Html msg
nameHeader server maybeAccount user =
    div [ class "profile-header" ]
        [ UI.imageOrInitial [ "profile-avatar" ] user.username (Users.avatarUrl server maybeAccount user)
        , div [ class "profile-header-names" ]
            [ usernameHeading user
            , if String.isEmpty (String.trim user.realName) then
                text ""

              else
                div [ class "profile-real-name-display" ]
                    [ span [ class "profile-real-name" ] [ text user.realName ] ]
            ]
        ]
