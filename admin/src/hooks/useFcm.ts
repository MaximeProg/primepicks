"use client";
import { useEffect } from "react";
import { getToken, onMessage } from "firebase/messaging";
import { getFirebaseMessaging, firebaseConfig } from "@/lib/firebase";
import { api } from "@/lib/api";
import { toast } from "sonner";

const VAPID_KEY = process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY ?? "";

async function registerServiceWorker(): Promise<ServiceWorkerRegistration | null> {
  if (!("serviceWorker" in navigator)) return null;
  try {
    const reg = await navigator.serviceWorker.register("/firebase-messaging-sw.js", {
      scope: "/",
    });
    // Envoyer la config Firebase au service worker
    const sw = reg.installing ?? reg.waiting ?? reg.active;
    if (sw) {
      sw.postMessage({ type: "FIREBASE_CONFIG", config: firebaseConfig });
    }
    // Attendre que le SW soit actif
    await navigator.serviceWorker.ready;
    return reg;
  } catch {
    return null;
  }
}

export function useFcm(enabled: boolean) {
  useEffect(() => {
    if (!enabled) return;

    let unsubscribe: (() => void) | null = null;

    (async () => {
      // 1. Demander la permission
      const permission = await Notification.requestPermission();
      if (permission !== "granted") return;

      // 2. Enregistrer le service worker
      await registerServiceWorker();

      // 3. Obtenir le token FCM
      const messaging = getFirebaseMessaging();
      if (!messaging || !VAPID_KEY) return;

      let token: string;
      try {
        token = await getToken(messaging, { vapidKey: VAPID_KEY });
      } catch {
        return;
      }

      // 4. Enregistrer le token côté backend
      try {
        await api.post("/notifications/token", { token, device_type: "WEB" });
      } catch {
        // Non bloquant — l'admin est connecté même sans push
      }

      // 5. Gérer les notifications en foreground (app ouverte)
      unsubscribe = onMessage(messaging, (payload) => {
        const title = payload.notification?.title ?? "Notification";
        const body  = payload.notification?.body  ?? "";
        toast.info(`${title} — ${body}`, { duration: 6000 });
      });
    })();

    return () => {
      unsubscribe?.();
    };
  }, [enabled]);
}
