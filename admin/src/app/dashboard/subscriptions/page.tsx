"use client";
import { useEffect, useState, useCallback } from "react";
import { CheckCircle, XCircle } from "lucide-react";
import { api, type Subscription, type Paginated } from "@/lib/api";
import { Badge } from "@/components/ui/badge";
import { Pagination } from "@/components/ui/pagination";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { fmtDate } from "@/lib/utils";
import { toast } from "sonner";

const subBadge: Record<Subscription["status"], { variant: "blue" | "green" | "red" | "gray"; label: string }> = {
  PENDING:   { variant: "gray",  label: "En attente" },
  ACTIVE:    { variant: "blue",  label: "Actif" },
  EXPIRED:   { variant: "red",   label: "Expiré" },
  CANCELLED: { variant: "gray",  label: "Annulé" },
};

const STATUS_OPTS = [
  { value: "", label: "Tous les statuts" },
  { value: "PENDING", label: "En attente" },
  { value: "ACTIVE", label: "Actif" },
  { value: "EXPIRED", label: "Expiré" },
  { value: "CANCELLED", label: "Annulé" },
];

const LIMIT = 20;

export default function SubscriptionsPage() {
  const [data, setData] = useState<Paginated<Subscription>>({ items: [], total: 0, limit: LIMIT, offset: 0 });
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState("");
  const [offset, setOffset] = useState(0);
  const [updating, setUpdating] = useState<string | null>(null);
  const [confirm, setConfirm] = useState<Subscription | null>(null);

  const load = useCallback(() => {
    setLoading(true);
    api.get<Paginated<Subscription>>("/admin/subscriptions", {
      status: statusFilter || undefined,
      limit: LIMIT,
      offset,
    })
      .then(setData)
      .finally(() => setLoading(false));
  }, [statusFilter, offset]);

  useEffect(() => { load(); }, [load]);
  useEffect(() => { setOffset(0); }, [statusFilter]);

  const activate = async (s: Subscription) => {
    setUpdating(s.id);
    try {
      await api.patch(`/admin/subscriptions/${s.id}`, { status: "ACTIVE" });
      toast.success(`Abonnement ${s.plan?.name ?? ""} activé`);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setUpdating(null);
    }
  };

  const cancel = async (s: Subscription) => {
    setConfirm(s);
  };

  const doCancel = async () => {
    if (!confirm) return;
    setUpdating(confirm.id);
    try {
      await api.patch(`/admin/subscriptions/${confirm.id}`, { status: "CANCELLED" });
      toast.success("Abonnement annulé");
      setConfirm(null);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setUpdating(null);
    }
  };

  return (
    <>
    <ConfirmDialog
      open={!!confirm}
      title="Annuler l'abonnement"
      description={`Désactiver l'abonnement ${confirm?.plan?.name ?? ""} ? L'utilisateur perdra l'accès immédiatement.`}
      confirmLabel="Annuler l'abonnement"
      variant="destructive"
      loading={!!updating}
      onConfirm={doCancel}
      onCancel={() => setConfirm(null)}
    />
    <div className="space-y-4">
      {/* Filter */}
      <div className="flex items-center gap-2">
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-44">
            <SelectValue placeholder="Statut" />
          </SelectTrigger>
          <SelectContent>
            {STATUS_OPTS.map((o) => <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>)}
          </SelectContent>
        </Select>
      </div>

      {/* Table */}
      <div className="table-wrapper">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-100 dark:border-slate-800 bg-gray-50 dark:bg-slate-800/50 text-left">
              <th className="th">ID</th>
              <th className="th">Plan</th>
              <th className="th">Statut</th>
              <th className="th">Début</th>
              <th className="th">Fin</th>
              <th className="th">Renouvellement</th>
              <th className="th text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-slate-800">
            {loading ? (
              Array.from({ length: 6 }).map((_, i) => (
                <tr key={i}>{Array.from({ length: 7 }).map((_, j) => (
                  <td key={j} className="px-4 py-3">
                    <div className="h-4 w-20 animate-pulse rounded bg-gray-100 dark:bg-slate-700" />
                  </td>
                ))}</tr>
              ))
            ) : data.items.length === 0 ? (
              <tr>
                <td colSpan={7} className="py-12 text-center text-gray-400 dark:text-slate-500">
                  Aucun abonnement
                </td>
              </tr>
            ) : data.items.map((s) => {
              const b = subBadge[s.status];
              const busy = updating === s.id;
              const canActivate = s.status !== "ACTIVE";
              const canCancel = s.status === "ACTIVE";
              return (
                <tr key={s.id} className="tr-hover">
                  <td className="td font-mono text-xs text-gray-500 dark:text-slate-400">{s.id.slice(0, 8)}…</td>
                  <td className="td font-medium text-gray-900 dark:text-slate-100">
                    {s.plan?.name ?? <span className="text-gray-400 dark:text-slate-500">—</span>}
                  </td>
                  <td className="td"><Badge variant={b.variant}>{b.label}</Badge></td>
                  <td className="td text-gray-500 dark:text-slate-400">{fmtDate(s.start_date)}</td>
                  <td className="td text-gray-500 dark:text-slate-400">{fmtDate(s.end_date)}</td>
                  <td className="td">
                    <Badge variant={s.auto_renew ? "blue" : "gray"}>
                      {s.auto_renew ? "Oui" : "Non"}
                    </Badge>
                  </td>
                  <td className="td">
                    <div className="flex items-center justify-end gap-1">
                      {canActivate && (
                        <button
                          onClick={() => activate(s)}
                          disabled={busy}
                          title="Activer l'abonnement"
                          className="flex items-center gap-1 rounded px-2 py-1 text-xs font-medium text-green-600 dark:text-green-400 hover:bg-green-50 dark:hover:bg-green-900/20 disabled:opacity-50 transition-colors"
                        >
                          <CheckCircle className="h-3.5 w-3.5" />
                          Activer
                        </button>
                      )}
                      {canCancel && (
                        <button
                          onClick={() => cancel(s)}
                          disabled={busy}
                          title="Annuler l'abonnement"
                          className="flex items-center gap-1 rounded px-2 py-1 text-xs font-medium text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 disabled:opacity-50 transition-colors"
                        >
                          <XCircle className="h-3.5 w-3.5" />
                          Annuler
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        <Pagination total={data.total} limit={LIMIT} offset={offset} onChange={setOffset} />
      </div>
    </div>
    </>
  );
}
