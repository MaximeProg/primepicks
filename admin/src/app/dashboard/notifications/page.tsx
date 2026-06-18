"use client";
import { useCallback, useEffect, useState } from "react";
import { Send, Search, X, Users, UserCheck, ShieldCheck, Globe, History, Bell } from "lucide-react";
import {
  api, type AdminUser, type Paginated, type NotificationInboxItem, type NotifTarget,
} from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { fmt } from "@/lib/utils";
import { toast } from "sonner";

// ── Icônes types ──────────────────────────────────────────────────────────────
const TYPE_ICONS: Record<string, string> = {
  NEW_COUPON: "🎟️", COUPON_WON: "🏆", COUPON_LOST: "❌",
  COUPON_CANCELLED: "🚫", SUB_ACTIVATED: "✅", SUB_EXPIRY_D3: "⏰",
  SUB_EXPIRY_D1: "⚠️", SUB_EXPIRED: "💤", PAYMENT_SUCCESS: "💳",
  PROMO: "📢", ROLE_CHANGED: "🔑", PAYOUT_APPROVED: "💰", TICKET_REPLIED: "💬",
};

const NOTIF_TYPES = [
  { value: "PROMO",           label: "Promo / Annonce" },
  { value: "NEW_COUPON",      label: "Nouveau coupon" },
  { value: "SUB_ACTIVATED",   label: "Abonnement activé" },
  { value: "PAYMENT_SUCCESS", label: "Paiement réussi" },
];

const TARGETS: { value: NotifTarget; label: string; icon: React.ElementType; desc: string }[] = [
  { value: "subscribers", icon: UserCheck, label: "Abonnés actifs",    desc: "Tous les abonnements actifs" },
  { value: "all_users",   icon: Globe,     label: "Tous les utilisateurs", desc: "Tous les comptes actifs" },
  { value: "admins",      icon: ShieldCheck, label: "Admins seulement", desc: "Super admins + admins" },
  { value: "custom",      icon: Users,     label: "Sélection manuelle", desc: "Choisir des utilisateurs" },
];

// ── Sélecteur d'utilisateurs ──────────────────────────────────────────────────
function UserSelector({
  selected, onChange,
}: {
  selected: AdminUser[];
  onChange: (users: AdminUser[]) => void;
}) {
  const [search, setSearch] = useState("");
  const [results, setResults] = useState<AdminUser[]>([]);
  const [searching, setSearching] = useState(false);

  const doSearch = useCallback(async (q: string) => {
    if (!q.trim()) { setResults([]); return; }
    setSearching(true);
    try {
      const data = await api.get<Paginated<AdminUser>>("/admin/users", { search: q, limit: 10 });
      setResults(data.items);
    } finally {
      setSearching(false);
    }
  }, []);

  useEffect(() => {
    const t = setTimeout(() => doSearch(search), 300);
    return () => clearTimeout(t);
  }, [search, doSearch]);

  const toggle = (u: AdminUser) => {
    if (selected.some((s) => s.id === u.id)) {
      onChange(selected.filter((s) => s.id !== u.id));
    } else {
      onChange([...selected, u]);
    }
  };

  return (
    <div className="space-y-3">
      {/* Tags sélectionnés */}
      {selected.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {selected.map((u) => (
            <span key={u.id}
              className="flex items-center gap-1 rounded-full bg-blue-100 dark:bg-blue-900/30 px-2.5 py-0.5 text-xs font-medium text-blue-700 dark:text-blue-300">
              {u.email ?? u.full_name ?? u.id.slice(0, 8)}
              <button onClick={() => toggle(u)} className="hover:text-blue-900 dark:hover:text-blue-100">
                <X className="h-3 w-3" />
              </button>
            </span>
          ))}
        </div>
      )}

      {/* Recherche */}
      <div className="relative">
        <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-gray-400" />
        <Input
          placeholder="Rechercher par nom, email…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="pl-8"
        />
      </div>

      {/* Résultats */}
      {results.length > 0 && (
        <div className="rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 divide-y divide-gray-100 dark:divide-slate-800 max-h-48 overflow-y-auto shadow-sm">
          {results.map((u) => {
            const isSelected = selected.some((s) => s.id === u.id);
            return (
              <button
                key={u.id}
                onClick={() => toggle(u)}
                className={`flex w-full items-center gap-3 px-3 py-2.5 text-left text-sm transition-colors
                  ${isSelected ? "bg-blue-50 dark:bg-blue-900/20" : "hover:bg-gray-50 dark:hover:bg-slate-800"}`}
              >
                <div className={`h-4 w-4 rounded border flex items-center justify-center shrink-0
                  ${isSelected ? "bg-blue-600 border-blue-600" : "border-gray-300 dark:border-slate-600"}`}>
                  {isSelected && <svg className="h-2.5 w-2.5 text-white" viewBox="0 0 12 12" fill="none">
                    <path d="M2 6l3 3 5-5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-gray-900 dark:text-slate-100 truncate">
                    {u.full_name ?? u.email ?? "—"}
                  </p>
                  {u.full_name && <p className="text-xs text-gray-400 dark:text-slate-500 truncate">{u.email}</p>}
                </div>
                <Badge variant={u.role === "ADMIN" || u.role === "SUPER_ADMIN" ? "blue" : "gray"} className="text-[10px]">
                  {u.role}
                </Badge>
              </button>
            );
          })}
        </div>
      )}
      {searching && <p className="text-xs text-gray-400 dark:text-slate-500">Recherche…</p>}
      <p className="text-xs text-gray-400 dark:text-slate-500">
        {selected.length} utilisateur{selected.length !== 1 ? "s" : ""} sélectionné{selected.length !== 1 ? "s" : ""}
      </p>
    </div>
  );
}

// ── Page principale ───────────────────────────────────────────────────────────
export default function NotificationsPage() {
  const [tab, setTab] = useState<"send" | "history">("send");

  // Formulaire d'envoi
  const [title, setTitle]     = useState("");
  const [body, setBody]       = useState("");
  const [type, setType]       = useState("PROMO");
  const [target, setTarget]   = useState<NotifTarget>("subscribers");
  const [selected, setSelected] = useState<AdminUser[]>([]);
  const [sending, setSending] = useState(false);

  // Historique
  const [history, setHistory]   = useState<{ id: string; title: string; body: string; type: string; success_count: number; failure_count: number }[]>([]);
  const [loadingHist, setLoadingHist] = useState(false);

  useEffect(() => {
    if (tab !== "history") return;
    setLoadingHist(true);
    api.get<typeof history>("/admin/notifications/history")
      .then(setHistory)
      .finally(() => setLoadingHist(false));
  }, [tab]);

  const send = async () => {
    if (!title.trim() || !body.trim()) {
      toast.error("Titre et message sont requis");
      return;
    }
    if (target === "custom" && selected.length === 0) {
      toast.error("Sélectionnez au moins un utilisateur");
      return;
    }
    setSending(true);
    try {
      const payload = {
        title: title.trim(),
        body: body.trim(),
        type,
        target,
        user_ids: target === "custom" ? selected.map((u) => u.id) : undefined,
      };
      const res = await api.post<{ message: string; success?: number; failure?: number }>(
        "/admin/notifications/send", payload,
      );
      toast.success(res.message + (res.success !== undefined ? ` (${res.success} envoyés)` : ""));
      setTitle(""); setBody(""); setSelected([]);
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      {/* Tabs */}
      <div className="flex gap-1 rounded-lg bg-gray-100 dark:bg-slate-800 p-1 w-fit">
        {([["send", "Envoyer", Send], ["history", "Historique", History]] as const).map(([t, l, Icon]) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`flex items-center gap-1.5 rounded-md px-4 py-1.5 text-sm font-medium transition-colors ${
              tab === t
                ? "bg-white dark:bg-slate-900 text-gray-900 dark:text-slate-100 shadow-sm"
                : "text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-300"
            }`}
          >
            <Icon className="h-3.5 w-3.5" />
            {l}
          </button>
        ))}
      </div>

      {/* ── Onglet Envoyer ── */}
      {tab === "send" && (
        <div className="space-y-5">
          {/* Cible */}
          <Card>
            <CardHeader className="pb-3">
              <CardTitle className="text-sm">Destinataires</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
                {TARGETS.map(({ value, icon: Icon, label, desc }) => (
                  <button
                    key={value}
                    onClick={() => { setTarget(value); setSelected([]); }}
                    className={`flex flex-col items-start gap-1 rounded-lg border p-3 text-left transition-colors ${
                      target === value
                        ? "border-blue-500 bg-blue-50 dark:bg-blue-900/20"
                        : "border-gray-200 dark:border-slate-700 hover:border-gray-300 dark:hover:border-slate-600"
                    }`}
                  >
                    <Icon className={`h-4 w-4 ${target === value ? "text-blue-600 dark:text-blue-400" : "text-gray-400"}`} />
                    <span className={`text-xs font-medium ${target === value ? "text-blue-700 dark:text-blue-300" : "text-gray-700 dark:text-slate-300"}`}>
                      {label}
                    </span>
                    <span className="text-[10px] text-gray-400 dark:text-slate-500">{desc}</span>
                  </button>
                ))}
              </div>

              {target === "custom" && (
                <div className="pt-1">
                  <UserSelector selected={selected} onChange={setSelected} />
                </div>
              )}
            </CardContent>
          </Card>

          {/* Contenu */}
          <Card>
            <CardHeader className="pb-3">
              <CardTitle className="text-sm">Contenu</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="mb-1.5 block text-xs font-medium text-gray-600 dark:text-slate-400">
                  Type de notification
                </label>
                <Select value={type} onValueChange={setType}>
                  <SelectTrigger className="w-56">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {NOTIF_TYPES.map((t) => (
                      <SelectItem key={t.value} value={t.value}>
                        {TYPE_ICONS[t.value]} {t.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <label className="mb-1.5 block text-xs font-medium text-gray-600 dark:text-slate-400">Titre</label>
                <Input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Ex : Nouveau coupon disponible !" />
              </div>
              <div>
                <label className="mb-1.5 block text-xs font-medium text-gray-600 dark:text-slate-400">Message</label>
                <textarea
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  placeholder="Contenu de la notification…"
                  rows={3}
                  className="w-full rounded-md border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-900 dark:text-slate-100 placeholder:text-gray-400 dark:placeholder:text-slate-500 resize-none focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                />
              </div>
              <Button onClick={send} disabled={sending} className="w-full sm:w-auto">
                <Send className="h-4 w-4" />
                {sending ? "Envoi en cours…" : "Envoyer la notification"}
              </Button>
            </CardContent>
          </Card>
        </div>
      )}

      {/* ── Onglet Historique ── */}
      {tab === "history" && (
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm">Historique des envois</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            {loadingHist ? (
              <div className="py-8 text-center text-sm text-gray-400 dark:text-slate-500">Chargement…</div>
            ) : history.length === 0 ? (
              <div className="flex flex-col items-center gap-2 py-10 text-gray-300 dark:text-slate-700">
                <Bell className="h-10 w-10" />
                <p className="text-sm text-gray-400 dark:text-slate-500">Aucune notification envoyée</p>
              </div>
            ) : (
              <div className="divide-y divide-gray-100 dark:divide-slate-800">
                {history.map((h) => (
                  <div key={h.id} className="flex items-start gap-3 px-4 py-3">
                    <span className="text-lg mt-0.5 shrink-0">{TYPE_ICONS[h.type] ?? "🔔"}</span>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 dark:text-slate-100 truncate">{h.title}</p>
                      <p className="text-xs text-gray-500 dark:text-slate-400 line-clamp-1 mt-0.5">{h.body}</p>
                    </div>
                    <div className="flex gap-2 shrink-0 text-xs">
                      <span className="text-green-600 dark:text-green-400 font-medium">{h.success_count} ✓</span>
                      {h.failure_count > 0 && (
                        <span className="text-red-400 font-medium">{h.failure_count} ✗</span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}
