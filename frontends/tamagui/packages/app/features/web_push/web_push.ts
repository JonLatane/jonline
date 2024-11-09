import { AccountOrServer, JonlineServer } from "app/store";
import { pageInitializer } from "app/utils/page_initializer";

export const webPushSupport = pageInitializer(async () => {
  debugger;
  if ('serviceWorker' in navigator) {
    debugger;
    navigator.serviceWorker
      .register('/jonline-service-worker.js', { scope: '/' })
      .then(async (registration) => {
        debugger;
        console.log('Jonline Web Push /jonline-service-worker.js launched with scope', registration.scope);
        // const subscription = registration.pushManager.subscribe({
        //   userVisibleOnly: true,
        //   applicationServerKey,
        // });

        // await fetch('/subscription', {
        //   method: 'POST',
        //   body: JSON.stringify(subscription),
        //   headers: {
        //     'content-type': 'application/json',
        //   },
        // });
      });
  }
});

const publicVapidKey = 'BMrfFtMtL9IWl9vchDbbbYzJlbQwplyZ_fbv8Pei8gPNna_Dr1O-Ng7U7fy0LLqz5RKIxEytTIzyk6TLrcKbN30';

// Copied from the web-push documentation
const urlBase64ToUint8Array = (base64String) => {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/\-/g, '+')
    .replace(/_/g, '/');

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
};

export const subscribe = async (postId: string, accountOrServer: AccountOrServer) => {
  if (!('serviceWorker' in navigator)) return;

  const registration = await navigator.serviceWorker.ready;

  // Subscribe to push notifications
  const subscription = await registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: urlBase64ToUint8Array(publicVapidKey),
  });

  await fetch('/subscription', {
    method: 'POST',
    body: JSON.stringify(subscription),
    headers: {
      'content-type': 'application/json',
    },
  });

};
