// Backs the `<jonline-markdown>` custom element used throughout the app
// (see `Components.Markdown` on the Elm side) to render post Markdown with
// syntax-highlighted code blocks, without routing content through ports --
// Elm just sets the `content` property on the node via `Html.Attributes.property`,
// same pattern as https://guide.elm-lang.org/interop/custom_elements.html.
//
// Libraries are vendored (not CDN-loaded) so the app keeps working offline
// and doesn't depend on a third-party host being reachable -- see
// `vendor/`. Markdown authors can be anyone federating with this server, so
// the parsed HTML is untrusted and always run through DOMPurify before
// being assigned as `innerHTML`.
(function () {
  function renderMarkdown(el) {
    var raw = window.marked.parse(el._content || "", { breaks: true, gfm: true });
    var clean = window.DOMPurify.sanitize(raw, { ADD_ATTR: ["target"] });
    el.innerHTML = clean;
    el.querySelectorAll("pre code").forEach(function (block) {
      window.hljs.highlightElement(block);
    });
  }

  class JonlineMarkdown extends HTMLElement {
    connectedCallback() {
      renderMarkdown(this);
    }

    set content(value) {
      this._content = value;
      if (this.isConnected) {
        renderMarkdown(this);
      }
    }

    get content() {
      return this._content || "";
    }
  }

  customElements.define("jonline-markdown", JonlineMarkdown);

  // Keeps highlight.js's theme in sync with the app's own dark/light mode
  // (see `index.html`'s `setTheme` port subscription, which calls this any
  // time the effective mode changes -- including once, right at startup).
  window.jonlineUpdateCodeTheme = function (isDark) {
    var link = document.getElementById("hljs-theme");
    if (!link) {
      return;
    }
    var base = link.getAttribute("data-base-href");
    link.setAttribute("href", base + (isDark ? "highlight-dark.css" : "highlight-light.css"));
  };
})();
