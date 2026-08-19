// Jonline's service worker. Currently only used for Web Push notifications -- see
// `Shared.AccountsPanel`'s "Enable notifications", `index.html`'s subscribeToPush/pushSubscribed/
// unsubscribeFromPush port handlers, and `backend/src/web_push` (which sends the pushes this
// reacts to). Registered unconditionally at page load (see index.html), scoped to wherever this
// file itself is served from (`/` or `/elm/`, matching `jonlineBasePath`) -- a no-op until a user
// actually opts into notifications.

// Push payloads arrive already decrypted by the browser (Web Push's own encryption, handled
// before this event fires) as the plaintext JSON `backend/src/web_push`'s `PushPayload` sends:
// `{ title, body }`. Deliberately minimal for now -- there's no per-message deep link yet, so
// `notificationclick` below just brings the app to the front rather than navigating anywhere
// message-specific.
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
      badge: '/favicon.png'
    })
  );
});

// Focuses an already-open Jonline tab if there is one, otherwise opens a new one.
self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (windowClients) {
      for (var i = 0; i < windowClients.length; i++) {
        if ('focus' in windowClients[i]) {
          return windowClients[i].focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
