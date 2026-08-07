(function () {
  var toc = document.getElementById('table-of-contents');
  var marker = document.querySelector('a[name="jonline-proto"]');
  if (!toc || !marker) return;

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
    extraLinks.forEach(function (entry) {
      var item = document.createElement('li');
      var link = document.createElement('a');
      link.href = entry[1];
      link.textContent = entry[0];
      item.appendChild(link);
      afterItem.insertAdjacentElement('afterend', item);
      afterItem = item;
    });
  }

  document.body.insertBefore(sidebar, document.body.firstChild);

  var darkMode = document.querySelector('dark-mode');
  if (darkMode) {
    darkMode.style.left = '';
    darkMode.style.right = '100px';
  }

  var style = document.createElement('style');
  style.textContent =
    '#toc-sidebar{position:fixed;top:0;left:0;width:260px;height:100vh;' +
    'overflow-y:auto;padding:16px;box-sizing:border-box;' +
    'border-right:1px solid rgba(128,128,128,.3);font-size:14px;' +
    'font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;}' +
    '#toc-sidebar ul,#toc-sidebar ol{padding-left:1.1em;padding-top:2px;padding-bottom:2px;}' +
    '#toc-sidebar p{margin:0;}' +
    '.markdown-style{margin-left:280px!important;}' +
    'dark-mode::part(text){font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;}';
  document.head.appendChild(style);
})();
