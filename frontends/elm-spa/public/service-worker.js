// Jonline's service worker. Currently only used for Web Push notifications -- see
// `Shared.AccountsPanel`'s "Enable notifications", `index.html`'s subscribeToPush/pushSubscribed/
// unsubscribeFromPush port handlers, and `backend/src/web_push` (which sends the pushes this
// reacts to). Registered unconditionally at page load (see index.html), scoped to wherever this
// file itself is served from (`/` or `/elm/`, matching `jonlineBasePath`) -- a no-op until a user
// actually opts into notifications.

// Push payloads arrive already decrypted by the browser (Web Push's own encryption, handled
// before this event fires) as the plaintext JSON `backend/src/web_push`'s `PushPayload` sends:
// `{ title, body, url? }` -- `url` (a full `https://<frontend_host>/messages?...#message-<id>`
// deep link straight to the Message, see `web_push::notification_url`) is only present if the
// server has a configured `ExternalCdnConfig.frontend_host` to build one from. Stashed on the
// notification's own `data` (not just closed over here) since `notificationclick` below fires as
// a *separate* event, with no other way to recover which push it's reacting to.
self.addEventListener('push', function (event) {
  var payload = { title: 'Jonline', body: 'You have a new message.' };
  if (event.data) {
    try {
      payload = event.data.json();
    } catch (e) {
      payload.body = event.data.text();
    }
  }
  event.waitUntil(
    self.registration.showNotification(payload.title || 'Jonline', {
      body: payload.body || '',
      icon: '/favicon.png',
      badge: '/favicon.png',
      data: { url: payload.url || '/' }
    })
  );
});

// Navigates an already-open Jonline tab straight to the Message the notification was about (a
// full navigation, not an in-app route change -- `WindowClient.navigate()` has no way to hand
// control back to the already-running Elm app's own router), falling back to just focusing it if
// navigation isn't supported (e.g. `client.navigate` is missing in some Safari versions), or
// opening a fresh tab there if no Jonline tab is open at all.
self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var targetUrl = (event.notification.data && event.notification.data.url) || '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (windowClients) {
      for (var i = 0; i < windowClients.length; i++) {
        var client = windowClients[i];
        if (!('focus' in client)) { continue; }
        if ('navigate' in client) {
          return client.navigate(targetUrl).then(
            function (navigatedClient) { return (navigatedClient || client).focus(); },
            function () { return client.focus(); }
          );
        }
        return client.focus();
      }
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});
