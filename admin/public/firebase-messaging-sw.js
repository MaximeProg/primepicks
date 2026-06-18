// Firebase Messaging Service Worker
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

// La config est injectée via self.__WEB_CONFIG__ au moment du build,
// ou lue directement ici pour le service worker (les env NEXT_PUBLIC_ ne sont pas dispo dans le SW).
// On utilise une variable globale postée par le client via postMessage ou des données hardcodées.
// Solution simple : le client envoie la config via postMessage("FIREBASE_CONFIG", config).

self.addEventListener("message", (event) => {
  if (event.data && event.data.type === "FIREBASE_CONFIG") {
    initFirebase(event.data.config);
  }
});

let messaging = null;

function initFirebase(config) {
  if (firebase.apps.length === 0) {
    firebase.initializeApp(config);
  }
  messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    const { title, body } = payload.notification ?? {};
    const data = payload.data ?? {};

    self.registration.showNotification(title ?? "Nouvelle notification", {
      body: body ?? "",
      icon: "/icon-192.png",
      badge: "/icon-192.png",
      data,
      vibrate: [200, 100, 200],
    });
  });
}

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((list) => {
      if (list.length > 0) {
        return list[0].focus();
      }
      return clients.openWindow("/dashboard");
    })
  );
});
