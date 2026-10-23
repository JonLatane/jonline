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

  var basePath = /^\/elm(\/|$)/.test(window.location.pathname) ? "/elm" : "";

  // In-app profile route for an `@` mention, or null if it isn't one. Shapes (profile routes are
  // `/:username[@host]`, see `Components.Users.parseFederatedUserId`):
  //   @server.tld/user     Rellm server    -> /user@server.tld
  //   @user@server.tld     Rellm server, Mastodon-style syntax -> /user@server.tld
  // (Mastodon's own content never reaches here as text: its mentions are `a.mention` links, which
  // `linkifyMentions` re-points at `/user@mastodon:instance.tld`.)
  //   @handle.tld          Bluesky handle  -> /handle.tld@bluesky:bsky.social
  //   @user                Rellm, this one -> /user
  // Rellm usernames are `[\w.-]+` with Rust's Unicode `\w` (`validate_username`), hence \p{...} here.
  var W = "\\p{L}\\p{N}\\p{M}_";
  var USERNAME_RE = new RegExp("^[" + W + ".-]+$", "u");
  var LOCAL_USERNAME_RE = new RegExp("^[" + W + "-]+$", "u");

  function profilePath(username, host) {
    return basePath + "/" + encodeURIComponent(username) + (host ? "@" + host : "");
  }

  function mentionHref(mention) {
    var m;
    if ((m = /^(.+)@([A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+)$/.exec(mention)) && USERNAME_RE.test(m[1])) {
      return profilePath(m[1], m[2]);
    }
    if ((m = /^([A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+)\/(.+)$/.exec(mention)) && USERNAME_RE.test(m[2])) {
      return profilePath(m[2], m[1]);
    }
    if (/^[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$/.test(mention)) {
      return profilePath(mention, "bluesky:bsky.social");
    }
    if (LOCAL_USERNAME_RE.test(mention)) {
      return profilePath(mention);
    }
    return null;
  }

  var MENTION_RE = new RegExp(
    "(^|[^" + W + "@./:+-])@([" + W + ".-]+(?:/[" + W + ".-]+|@[A-Za-z0-9.-]+)?)",
    "gu"
  );

  function linkifyText(node) {
    var text = node.nodeValue;
    var frag = document.createDocumentFragment();
    var last = 0;
    var found = false;
    var m;
    MENTION_RE.lastIndex = 0;
    while ((m = MENTION_RE.exec(text))) {
      var mention = m[2].replace(/[.-]+$/, "");
      var href = mentionHref(mention);
      if (!href) {
        continue;
      }
      found = true;
      var start = m.index + m[1].length;
      frag.appendChild(document.createTextNode(text.slice(last, start)));
      var a = document.createElement("a");
      a.href = href;
      a.className = "mention-link";
      a.textContent = "@" + mention;
      frag.appendChild(a);
      last = start + 1 + mention.length;
      MENTION_RE.lastIndex = last;
    }
    if (found) {
      frag.appendChild(document.createTextNode(text.slice(last)));
      node.parentNode.replaceChild(frag, node);
    }
  }

  // Makes `@` mentions open the mentioned profile in-app: plain-text ones (Bluesky post text, Rellm
  // Markdown) are wrapped in links, and Mastodon's own `a.mention` links (which point at the remote
  // instance's web UI) are re-pointed at our profile route.
  function linkifyMentions(root) {
    root.querySelectorAll("a.mention").forEach(function (a) {
      var m = /^https?:\/\/([^/]+)\/(?:@|users\/)([\w.-]+)\/?$/.exec(a.getAttribute("href") || "");
      if (m) {
        a.setAttribute("href", basePath + "/" + m[2] + "@mastodon:" + m[1]);
        a.removeAttribute("target");
      }
    });
    // marked's GFM autolinker turns the `bob@mastodon.social` of `@bob@mastodon.social` into a
    // mailto: link; fold the leading `@` back in and make it a profile link instead.
    root.querySelectorAll('a[href^="mailto:"]').forEach(function (a) {
      var prev = a.previousSibling;
      var href = prev && prev.nodeType === 3 && new RegExp("(^|[^" + W + "@./:+-])@$", "u").test(prev.nodeValue) && mentionHref(a.textContent);
      if (href) {
        prev.nodeValue = prev.nodeValue.slice(0, -1);
        a.setAttribute("href", href);
        a.className = "mention-link";
        a.textContent = "@" + a.textContent;
      }
    });
    var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode: function (n) {
        return n.parentNode.closest("a, pre, code") && root.contains(n.parentNode.closest("a, pre, code"))
          ? NodeFilter.FILTER_REJECT
          : NodeFilter.FILTER_ACCEPT;
      },
    });
    var nodes = [];
    while (walker.nextNode()) {
      if (walker.currentNode.nodeValue.indexOf("@") !== -1) {
        nodes.push(walker.currentNode);
      }
    }
    nodes.forEach(linkifyText);
  }

  function renderMarkdown(el) {
    var content = el._content || "";
    var raw = looksLikeHtml(content) ? content : window.marked.parse(content, { breaks: true, gfm: true });
    var clean = window.DOMPurify.sanitize(raw, { ADD_ATTR: ["target"] });
    el.innerHTML = clean;
    linkifyMentions(el);
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
