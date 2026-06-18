"use client";
import { useEffect, useState } from "react";
import { api, type NotificationLog, type AppSetting } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { Bell, Info, History, Send, Settings, AlertTriangle } from "lucide-react";
import { fmt } from "@/lib/utils";

const ENV = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";

export default function SettingsPage() {
  const [settings, setSettings] = useState<AppSetting | null>(null);
  const [settingsSaving, setSettingsSaving] = useState(false);
  const [form, setForm] = useState({
    platform_name: "", support_email: "", support_phone: "",
    telegram_url: "", whatsapp_url: "", facebook_url: "", instagram_url: "",
    maintenance_mode: false,
  });

  const [notifLogs, setNotifLogs] = useState<NotificationLog[]>([]);
  const [logsLoading, setLogsLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [notifForm, setNotifForm] = useState({ title: "", body: "" });

  useEffect(() => {
    api.get<AppSetting>("/admin/settings").then((s) => {
      setSettings(s);
      setForm({
        platform_name: s.platform_name,
        support_email: s.support_email ?? "",
        support_phone: s.support_phone ?? "",
        telegram_url: s.telegram_url ?? "",
        whatsapp_url: s.whatsapp_url ?? "",
        facebook_url: s.facebook_url ?? "",
        instagram_url: s.instagram_url ?? "",
        maintenance_mode: s.maintenance_mode,
      });
    });
    api.get<NotificationLog[]>("/admin/notifications")
      .then(setNotifLogs)
      .finally(() => setLogsLoading(false));
  }, []);

  const saveSettings = async () => {
    setSettingsSaving(true);
    try {
      const updated = await api.patch<AppSetting>("/admin/settings", {
        platform_name: form.platform_name || undefined,
        support_email: form.support_email || undefined,
        support_phone: form.support_phone || undefined,
        telegram_url: form.telegram_url || undefined,
        whatsapp_url: form.whatsapp_url || undefined,
        facebook_url: form.facebook_url || undefined,
        instagram_url: form.instagram_url || undefined,
        maintenance_mode: form.maintenance_mode,
      });
      setSettings(updated);
      toast.success("Paramètres enregistrés");
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setSettingsSaving(false);
    }
  };

  const sendBroadcast = async () => {
    if (!notifForm.title || !notifForm.body) { toast.error("Titre et message requis"); return; }
    setSending(true);
    try {
      await api.post("/admin/notifications/send", { title: notifForm.title, body: notifForm.body, type: "PROMO" });
      toast.success("Notification envoyée à tous les abonnés");
      setNotifForm({ title: "", body: "" });
      const logs = await api.get<NotificationLog[]>("/admin/notifications");
      setNotifLogs(logs);
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="max-w-2xl space-y-4">
      {/* Paramètres plateforme */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings className="h-4 w-4" />
            Paramètres de la plateforme
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5 col-span-2">
              <Label>Nom de la plateforme</Label>
              <Input value={form.platform_name}
                onChange={(e) => setForm({ ...form, platform_name: e.target.value })} />
            </div>
            <div className="space-y-1.5">
              <Label>Email support</Label>
              <Input type="email" value={form.support_email}
                onChange={(e) => setForm({ ...form, support_email: e.target.value })} />
            </div>
            <div className="space-y-1.5">
              <Label>Téléphone support</Label>
              <Input value={form.support_phone}
                onChange={(e) => setForm({ ...form, support_phone: e.target.value })} />
            </div>
            <div className="space-y-1.5">
              <Label>Telegram</Label>
              <Input placeholder="https://t.me/..." value={form.telegram_url}
                onChange={(e) => setForm({ ...form, telegram_url: e.target.value })} />
            </div>
            <div className="space-y-1.5">
              <Label>WhatsApp</Label>
              <Input placeholder="https://wa.me/..." value={form.whatsapp_url}
                onChange={(e) => setForm({ ...form, whatsapp_url: e.target.value })} />
            </div>
            <div className="space-y-1.5">
              <Label>Facebook</Label>
              <Input placeholder="https://facebook.com/..." value={form.facebook_url}
                onChange={(e) => setForm({ ...form, facebook_url: e.target.value })} />
            </div>
            <div className="space-y-1.5">
              <Label>Instagram</Label>
              <Input placeholder="https://instagram.com/..." value={form.instagram_url}
                onChange={(e) => setForm({ ...form, instagram_url: e.target.value })} />
            </div>
          </div>

          {/* Mode maintenance */}
          <div className={`flex items-center justify-between rounded-lg border p-3 ${
            form.maintenance_mode
              ? "border-orange-200 dark:border-orange-800 bg-orange-50 dark:bg-orange-900/20"
              : "border-gray-200 dark:border-slate-700"
          }`}>
            <div className="flex items-center gap-2">
              <AlertTriangle className={`h-4 w-4 ${form.maintenance_mode ? "text-accent-500" : "text-gray-400"}`} />
              <div>
                <p className="text-sm font-medium text-gray-900 dark:text-slate-100">Mode maintenance</p>
                <p className="text-xs text-gray-500 dark:text-slate-400">L'application sera inaccessible aux utilisateurs</p>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setForm({ ...form, maintenance_mode: !form.maintenance_mode })}
              className={`relative inline-flex h-5 w-9 shrink-0 rounded-full border-2 border-transparent transition-colors ${
                form.maintenance_mode ? "bg-accent-500" : "bg-gray-200 dark:bg-slate-700"
              }`}
            >
              <span className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow ring-0 transition-transform ${
                form.maintenance_mode ? "translate-x-4" : "translate-x-0"
              }`} />
            </button>
          </div>

          <div className="flex justify-end">
            <Button onClick={saveSettings} disabled={settingsSaving}>
              {settingsSaving ? "Enregistrement…" : "Enregistrer"}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* App info */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Info className="h-4 w-4" />
            Informations système
          </CardTitle>
        </CardHeader>
        <CardContent>
          <dl className="grid grid-cols-2 gap-x-4 gap-y-3 text-sm">
            {[
              { label: "Version", value: "1.0.0" },
              { label: "Environnement", value: process.env.NODE_ENV ?? "production" },
              { label: "API", value: ENV },
            ].map(({ label, value }) => (
              <div key={label} className="flex flex-col gap-0.5">
                <dt className="text-gray-500 dark:text-slate-400">{label}</dt>
                <dd className="font-medium text-gray-900 dark:text-slate-100 truncate">{value}</dd>
              </div>
            ))}
          </dl>
        </CardContent>
      </Card>

      {/* Broadcast notification */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Bell className="h-4 w-4" />
            Diffusion de notification
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-xs text-gray-500 dark:text-slate-400">
            Envoie une notification push à tous les abonnés actifs.
          </p>
          <div className="space-y-1.5">
            <Label>Titre</Label>
            <Input value={notifForm.title} onChange={(e) => setNotifForm({ ...notifForm, title: e.target.value })}
              placeholder="Ex : Nouveau coupon disponible !" />
          </div>
          <div className="space-y-1.5">
            <Label>Message</Label>
            <Textarea rows={3} value={notifForm.body}
              onChange={(e) => setNotifForm({ ...notifForm, body: e.target.value })}
              placeholder="Ex : Connectez-vous pour voir notre dernier coupon premium." />
          </div>
          <div className="flex justify-end">
            <Button onClick={sendBroadcast} disabled={sending || !notifForm.title || !notifForm.body}>
              <Send className="h-4 w-4" />
              {sending ? "Envoi…" : "Envoyer à tous"}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Notification history */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <History className="h-4 w-4" />
            Historique des notifications
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {logsLoading ? (
            <div className="space-y-2 p-4">
              {[1, 2, 3].map((i) => <div key={i} className="h-10 animate-pulse rounded bg-gray-100 dark:bg-slate-700" />)}
            </div>
          ) : notifLogs.length === 0 ? (
            <p className="py-8 text-center text-sm text-gray-400 dark:text-slate-500">Aucune notification envoyée</p>
          ) : (
            <ul className="divide-y divide-gray-100 dark:divide-slate-800">
              {notifLogs.slice(0, 10).map((log) => (
                <li key={log.id} className="flex items-start justify-between gap-4 px-4 py-3">
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-gray-900 dark:text-slate-100 truncate">{log.title}</p>
                    <p className="text-xs text-gray-500 dark:text-slate-400 truncate">{log.body}</p>
                  </div>
                  <div className="flex shrink-0 flex-col items-end gap-1">
                    <Badge variant="green">{log.success_count} ok</Badge>
                    {log.failure_count > 0 && <Badge variant="red">{log.failure_count} échec</Badge>}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
