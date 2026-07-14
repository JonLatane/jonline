module Components.Markdown exposing (view)

{-| Renders a Markdown string as sanitized, syntax-highlighted HTML via the
`<jonline-markdown>` custom element (see `public/markdown.js` and the
libraries it vendors in `public/vendor/`: marked.js parses the Markdown,
DOMPurify sanitizes the result -- post content comes from other users and
federated servers, so it's untrusted -- and highlight.js highlights fenced
code blocks).

Elm's virtual DOM has no way to render a raw HTML string itself, so this
hands the Markdown source to the custom element as a JS *property* (not an
attribute -- properties aren't limited to strings and don't round-trip
through `attributeChangedCallback`), the pattern from
<https://guide.elm-lang.org/interop/custom_elements.html>. The element
re-renders its own contents (outside the virtual DOM's view) whenever that
property changes, which is what makes this reusable anywhere a `Post`'s
Markdown needs showing -- the full `postDetail` view here, and later,
compact previews on the Home page's feed.

-}

import Html exposing (Attribute, Html, node)
import Html.Attributes exposing (property)
import Json.Encode as Encode


view : List (Attribute msg) -> String -> Html msg
view attrs markdown =
    node "jonline-markdown"
        (property "content" (Encode.string markdown) :: attrs)
        []
