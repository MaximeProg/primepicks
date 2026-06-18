"use client";
import { useEffect, useState, useCallback } from "react";
import { api, type AffiliatePayout, type PayoutStatus, type Paginated } from "@/lib/api";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Pagination } from "@/components/ui/pagination";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { toast } from "sonner";
import { fmt, fmtAmount } from "@/lib/utils";
import { CheckCircle, XCircle, Banknote } from "lucide-react";

const LIMIT = 20;

const statusMeta: Record<PayoutStatus, { label: string; variant: "gray" | "blue" | "green" | "orange" | "red" }> = {
  PENDING: { label: "En attente", variant: "orange" },
  APPROVED: { label: "Approuvé", variant: "blue" },
  PAID: { label: "Payé", variant: "green" },
  REJECTED: { label: "Rejeté", variant: "gray" },
};

export default function PayoutsPage() {
  const [data, setData] = useState<Paginated<AffiliatePayout>>({ items: [], total: 0, limit: LIMIT, offset: 0 });
  const [loading, setLoading] = useState(true);
  const [offset, setOffset] = useState(0);
  const [statusFilter, setStatusFilter] = useState("");
  const [confirm, setConfirm] = useState<{ payout: AffiliatePayout; action: PayoutStatus } | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    api.get<Paginated<AffiliatePayout>>("/admin/affiliate-payouts", {
      status: statusFilter || undefined,
      limit: LIMIT,
      offset,
    }).then(setData).finally(() => setLoading(false));
  }, [statusFilter, offset]);

  useEffect(() => { load(); }, [load]);
  useEffect(() => { setOffset(0); }, [statusFilter]);

  const doAction = async () => {
    if (!confirm) return;
    setSaving(true);
    try {
      await api.patch(`/admin/affiliate-payouts/${confirm.payout.id}`, { status: confirm.action });
      const labels: Record<PayoutStatus, string> = { PENDING: "", APPROVED: "Approuvé", PAID: "Marqué payé", REJECTED: "Rejeté" };
      toast.success(labels[confirm.action]);
      setConfirm(null);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <ConfirmDialog
        open={!!confirm}
        title={confirm?.action === "APPROVED" ? "Approuver le retrait" :
               confirm?.action === "PAID" ? "Marquer comme payé" : "Rejeter le retrait"}
        description={`Montant : ${confirm ? fmtAmount(confirm.payout.amount) : ""}`}
        confirmLabel={confirm?.action === "APPROVED" ? "Approuver" :
                      confirm?.action === "PAID" ? "Confirmer le paiement" : "Rejeter"}
        variant={confirm?.action === "REJECTED" ? "destructive" : "warning"}
        loading={saving}
        onConfirm={doAction}
        onCancel={() => setConfirm(null)}
      />

      <div className="space-y-4">
        <div className="flex items-center gap-3">
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-44"><SelectValue placeholder="Tous les statuts" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="">Tous</SelectItem>
              <SelectItem value="PENDING">En attente</SelectItem>
              <SelectItem value="APPROVED">Approuvés</SelectItem>
              <SelectItem value="PAID">Payés</SelectItem>
              <SelectItem value="REJECTED">Rejetés</SelectItem>
            </SelectContent>
          </Select>
          <span className="text-sm text-gray-500 dark:text-slate-400">{data.total} retrait(s)</span>
        </div>

        <div className="table-wrapper">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 dark:border-slate-800 bg-gray-50 dark:bg-slate-800/50 text-left">
                <th className="th">Affilié</th>
                <th className="th">Montant</th>
                <th className="th">Statut</th>
                <th className="th">Demandé le</th>
                <th className="th">Payé le</th>
                <th className="th text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-slate-800">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i}>{Array.from({ length: 6 }).map((_, j) => (
                    <td key={j} className="px-4 py-3"><div className="h-4 w-20 animate-pulse rounded bg-gray-100 dark:bg-slate-700" /></td>
                  ))}</tr>
                ))
              ) : data.items.length === 0 ? (
                <tr><td colSpan={6} className="py-12 text-center text-gray-400 dark:text-slate-500">Aucun retrait</td></tr>
              ) : data.items.map((p) => {
                const s = statusMeta[p.status];
                return (
                  <tr key={p.id} className="tr-hover">
                    <td className="td text-xs text-gray-500 dark:text-slate-400">{p.affiliate_id.slice(0, 8)}…</td>
                    <td className="td font-semibold text-accent-500">{fmtAmount(p.amount)}</td>
                    <td className="td"><Badge variant={s.variant}>{s.label}</Badge></td>
                    <td className="td text-gray-500 dark:text-slate-400">{fmt(p.requested_at)}</td>
                    <td className="td text-gray-500 dark:text-slate-400">{p.paid_at ? fmt(p.paid_at) : "—"}</td>
                    <td className="td">
                      <div className="flex items-center justify-end gap-1">
                        {p.status === "PENDING" && (
                          <>
                            <button
                              onClick={() => setConfirm({ payout: p, action: "APPROVED" })}
                              className="flex items-center gap-1 rounded px-2 py-1 text-xs font-medium text-green-600 dark:text-green-400 hover:bg-green-50 dark:hover:bg-green-900/20 transition-colors">
                              <CheckCircle className="h-3.5 w-3.5" /> Approuver
                            </button>
                            <button
                              onClick={() => setConfirm({ payout: p, action: "REJECTED" })}
                              className="flex items-center gap-1 rounded px-2 py-1 text-xs font-medium text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors">
                              <XCircle className="h-3.5 w-3.5" /> Rejeter
                            </button>
                          </>
                        )}
                        {p.status === "APPROVED" && (
                          <button
                            onClick={() => setConfirm({ payout: p, action: "PAID" })}
                            className="flex items-center gap-1 rounded px-2 py-1 text-xs font-medium text-primary-700 dark:text-primary-400 hover:bg-primary-50 dark:hover:bg-primary-900/20 transition-colors">
                            <Banknote className="h-3.5 w-3.5" /> Marquer payé
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
