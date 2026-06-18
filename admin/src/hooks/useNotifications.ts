"use client";
import { useEffect, useRef, useState, useCallback } from "react";
import { api, type NotificationInboxItem } from "@/lib/api";

const POLL_MS = 30_000; // toutes les 30 secondes

export function useNotifications(enabled: boolean) {
  const [items, setItems]       = useState<NotificationInboxItem[]>([]);
  const [unread, setUnread]     = useState(0);
  const [loading, setLoading]   = useState(false);
  const timerRef                = useRef<ReturnType<typeof setInterval> | null>(null);

  const refresh = useCallback(async () => {
    if (!enabled) return;
    try {
      const [inbox, cnt] = await Promise.all([
        api.get<NotificationInboxItem[]>("/notifications/inbox", { limit: 20 }),
        api.get<{ count: number }>("/notifications/inbox/unread-count"),
      ]);
      setItems(inbox);
      setUnread(cnt.count);
    } catch {
      // silencieux — ne pas crasher si offline
    }
  }, [enabled]);

  const markRead = useCallback(async (id: string) => {
    await api.patch(`/notifications/inbox/${id}/read`, {});
    setItems((prev) => prev.map((n) => n.id === id ? { ...n, is_read: true } : n));
    setUnread((c) => Math.max(0, c - 1));
  }, []);

  const markAllRead = useCallback(async () => {
    await api.post("/notifications/inbox/read-all");
    setItems((prev) => prev.map((n) => ({ ...n, is_read: true })));
    setUnread(0);
  }, []);

  const remove = useCallback(async (id: string) => {
    const notif = items.find((n) => n.id === id);
    await api.delete(`/notifications/inbox/${id}`);
    setItems((prev) => prev.filter((n) => n.id !== id));
    if (notif && !notif.is_read) setUnread((c) => Math.max(0, c - 1));
  }, [items]);

  const clearAll = useCallback(async () => {
    await api.delete("/notifications/inbox");
    setItems([]);
    setUnread(0);
  }, []);

  useEffect(() => {
    if (!enabled) return;
    setLoading(true);
    refresh().finally(() => setLoading(false));
    timerRef.current = setInterval(refresh, POLL_MS);
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [enabled, refresh]);

  return { items, unread, loading, refresh, markRead, markAllRead, remove, clearAll };
}
