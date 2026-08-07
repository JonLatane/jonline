// Post-processes docs/protocol.html (after markdown-to-html-cli generates it, see
// the html_docs target in the root Makefile) to turn the "Table of Contents"
// section into a fixed, resizable, collapsible left sidebar, instead of leaving
// it inline atop the docs.
//
// What it does, in order:
//   1. Moves every element from <h2 id="table-of-contents"> through (but not
//      including) the <p><a name="jonline-proto"> marker into a new
//      <nav id="toc-sidebar">, which becomes the sidebar's content.
//   2. Inserts a few extra links (Authentication/HTTP Endpoints/API Design
//      Notes/gRPC API) into the "jonline.proto" sub-list, since protoc-gen-doc's
//      generated TOC only includes top-level message/service headings. Every
//      RPC method from the gRPC API table is then listed as a child of the
//      "gRPC API" entry, in table order; since the table has no per-row ids
//      to link to, one is added to each row as it's listed.
//   3. Appends the sidebar as the LAST child of <body> (not the first) so that
//      dragging a text selection in the main content can't "bleed" into the
//      sidebar: browsers extend a selection's focus to whatever DOM node is
//      under the cursor, and if the fixed sidebar sat earlier in the DOM than
//      the main content, the selection would visually paint across it even
//      though it's unrelated to what's actually being selected.
//   4. Adds a drag handle (resize, clamped) and a top-left toggle button
//      (collapse/expand) for the sidebar, persisting both to localStorage.
//   5. Nudges the <dark-mode> toggle out of the sidebar's way and widens the
//      main content column to make room for the sidebar. Below 640px, the
//      main content's left margin is dropped entirely -- an expanded sidebar
//      there overlays the content like a mobile nav drawer instead of
//      squeezing it.
//
// Because docs/protocol.html itself is regenerated wholesale from docs/protocol.md
// on every `make html_docs`, none of this can live as static markup in the .md
// source -- it has to run client-side, after the page (and its other inline
// scripts) has loaded.
(function () {
  var toc = document.getElementById('table-of-contents');
  var marker = document.querySelector('a[name="jonline-proto"]');
  if (!toc || !marker) return;

  var DEFAULT_WIDTH = 300;
  var MIN_WIDTH = 180;
  var MAX_WIDTH = 560;
  var NARROW_BREAKPOINT = 640;
  var WIDTH_KEY = '_jonline_docs_toc_width_';
  var COLLAPSED_KEY = '_jonline_docs_toc_collapsed_';

  function loadNumber(key, fallback) {
    try {
      var v = parseInt(localStorage.getItem(key), 10);
      return isNaN(v) ? fallback : v;
    } catch (e) {
      return fallback;
    }
  }
  function loadBool(key, fallback) {
    try {
      var v = localStorage.getItem(key);
      return v === null ? fallback : v === '1';
    } catch (e) {
      return fallback;
    }
  }
  function save(key, value) {
    try {
      localStorage.setItem(key, value);
    } catch (e) {}
  }

  var boundary = marker.closest('p');
  var sidebar = document.createElement('nav');
  sidebar.id = 'toc-sidebar';

  var node = toc;
  while (node && node !== boundary) {
    var next = node.nextElementSibling;
    sidebar.appendChild(node);
    node = next;
  }

  var jonlineLink = sidebar.querySelector('a[href="#jonline-Jonline"]');
  var jonlineItem = jonlineLink && jonlineLink.closest('li');
  if (jonlineItem) {
    var extraLinks = [
      ['Authentication', '#authentication'],
      ['HTTP Endpoints', '#http-endpoints'],
      ['API Design Notes', '#api-design-notes'],
      ['gRPC API', '#grpc-api']
    ];
    var afterItem = jonlineItem;
    var grpcApiItem = null;
    extraLinks.forEach(function (entry) {
      var item = document.createElement('li');
      var link = document.createElement('a');
      link.href = entry[1];
      link.textContent = entry[0];
      item.appendChild(link);
      afterItem.insertAdjacentElement('afterend', item);
      afterItem = item;
      if (entry[1] === '#grpc-api') grpcApiItem = item;
    });

    // List each RPC method (in the order they appear in the gRPC API table)
    // as children of the "gRPC API" TOC entry. The table has no per-row ids
    // to link to, so we add one (prefixed to avoid clashing with existing
    // message/service anchor ids) to each row as we go.
    var grpcTable = document.getElementById('grpc-api');
    grpcTable = grpcTable && grpcTable.nextElementSibling;
    if (grpcApiItem && grpcTable && grpcTable.tagName === 'TABLE') {
      var rpcList = document.createElement('ul');
      grpcTable.querySelectorAll('tbody > tr').forEach(function (row) {
        var nameCell = row.querySelector('td');
        if (!nameCell) return;
        var name = nameCell.textContent.trim();
        var id = 'grpc-api-' + name;
        row.id = id;
        var item = document.createElement('li');
        var link = document.createElement('a');
        link.href = '#' + id;
        link.textContent = name;
        item.appendChild(link);
        rpcList.appendChild(item);
      });
      grpcApiItem.appendChild(rpcList);
    }
  }

  var resizeHandle = document.createElement('div');
  resizeHandle.id = 'toc-resize-handle';
  sidebar.appendChild(resizeHandle);

  document.body.appendChild(sidebar);

  var toggle = document.createElement('button');
  toggle.id = 'toc-toggle';
  toggle.type = 'button';
  document.body.appendChild(toggle);

  var darkMode = document.querySelector('dark-mode');
  if (darkMode) {
    darkMode.style.left = '';
    darkMode.style.right = '100px';
  }

  var main = document.querySelector('.markdown-style');

  var width = Math.min(MAX_WIDTH, Math.max(MIN_WIDTH, loadNumber(WIDTH_KEY, DEFAULT_WIDTH)));
  var collapsed = loadBool(COLLAPSED_KEY, false);

  function applyLayout() {
    sidebar.style.width = width + 'px';
    sidebar.classList.toggle('collapsed', collapsed);
    toggle.textContent = collapsed ? '☰' : '✕';
    toggle.setAttribute('aria-label', collapsed ? 'Show table of contents' : 'Hide table of contents');
    var narrow = window.innerWidth < NARROW_BREAKPOINT;
    var marginLeft = (!narrow && !collapsed) ? (width + 20) + 'px' : '0px';
    main.style.setProperty('margin-left', marginLeft, 'important');
  }

  toggle.addEventListener('click', function () {
    collapsed = !collapsed;
    save(COLLAPSED_KEY, collapsed ? '1' : '0');
    applyLayout();
  });

  window.addEventListener('resize', applyLayout);

  resizeHandle.addEventListener('pointerdown', function (e) {
    e.preventDefault();
    resizeHandle.setPointerCapture(e.pointerId);
    var startX = e.clientX;
    var startWidth = width;
    function onMove(moveEvent) {
      width = Math.min(MAX_WIDTH, Math.max(MIN_WIDTH, startWidth + (moveEvent.clientX - startX)));
      applyLayout();
    }
    function onUp() {
      resizeHandle.removeEventListener('pointermove', onMove);
      resizeHandle.removeEventListener('pointerup', onUp);
      save(WIDTH_KEY, width);
    }
    resizeHandle.addEventListener('pointermove', onMove);
    resizeHandle.addEventListener('pointerup', onUp);
  });

  applyLayout();

  var style = document.createElement('style');
  style.textContent =
    '#toc-sidebar{position:fixed;top:0;left:0;height:100vh;' +
    'overflow-y:auto;padding:44px 16px 16px 16px;box-sizing:border-box;' +
    'background:var(--color-theme-bg,#fff);' +
    'border-right:1px solid rgba(128,128,128,.3);box-shadow:2px 0 8px rgba(0,0,0,.15);' +
    'font-size:14px;z-index:1000;' +
    'transition:transform .15s ease;' +
    'font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;}' +
    '#toc-sidebar.collapsed{transform:translateX(-100%);}' +
    '#toc-sidebar ul,#toc-sidebar ol{padding-left:1.1em;padding-top:2px;padding-bottom:2px;}' +
    '#toc-sidebar p{margin:0;}' +
    '#toc-resize-handle{position:absolute;top:0;right:-4px;width:8px;height:100%;cursor:col-resize;}' +
    '#toc-toggle{position:fixed;top:8px;left:8px;z-index:1001;width:28px;height:28px;' +
    'display:flex;align-items:center;justify-content:center;padding:0;' +
    'border:1px solid rgba(128,128,128,.4);border-radius:6px;' +
    'background:var(--color-theme-bg,#fff);color:var(--color-theme-text,#24292f);' +
    'font-size:14px;cursor:pointer;' +
    'font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;}' +
    '.markdown-style{max-width:1080px!important;margin-top:32px!important;transition:margin-left .15s ease;}' +
    'dark-mode{backdrop-filter:blur(4px);border-radius:4px;padding:0 6px;}' +
    'dark-mode::part(text){font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;}';
  document.head.appendChild(style);
})();
