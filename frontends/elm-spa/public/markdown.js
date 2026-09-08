// Backs the `<rellm-markdown>` custom element used throughout the app
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
  // A Mastodon `Status.content` (see `Shared.Federation.Mastodon.toPost`'s own doc) is already
  // server-sanitized HTML, not Markdown source -- e.g. `"<p>Hello <a href=...>world</a></p>"`.
  // Feeding that through `marked.parse` first mostly doesn't do what you'd want (its HTML-block
  // grammar is whitespace/line-sensitive and this is compact, single-line markup), so a leading `<`
  // (after trimming) is treated as a signal to skip straight to DOMPurify instead. Real post
  // Markdown essentially never starts with a literal `<` -- and even if it did, the fallback here is
  // just an HTML parse of that text, which degrades reasonably rather than breaking anything.
  function looksLikeHtml(content) {
    return /^\s*</.test(content);
  }

  function renderMarkdown(el) {
    var content = el._content || "";
    var raw = looksLikeHtml(content) ? content : window.marked.parse(content, { breaks: true, gfm: true });
    var clean = window.DOMPurify.sanitize(raw, { ADD_ATTR: ["target"] });
    el.innerHTML = clean;
    el.querySelectorAll("pre code").forEach(function (block) {
      window.hljs.highlightElement(block);
    });
  }

  class RellmMarkdown extends HTMLElement {
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

  customElements.define("rellm-markdown", RellmMarkdown);

  // Keeps highlight.js's theme in sync with the app's own dark/light mode
  // (see `index.html`'s `setTheme` port subscription, which calls this any
  // time the effective mode changes -- including once, right at startup).
  window.rellmUpdateCodeTheme = function (isDark) {
    var link = document.getElementById("hljs-theme");
    if (!link) {
      return;
    }
    var base = link.getAttribute("data-base-href");
    link.setAttribute("href", base + (isDark ? "highlight-dark.css" : "highlight-light.css"));
  };
})();
