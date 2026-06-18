"use client";
import { useEffect, useState, useCallback } from "react";
import { Download, Trash2 } from "lucide-react";
import { api, type Transaction, type Paginated } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Pagination } from "@/components/ui/pagination";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { fmtAmount, fmt } from "@/lib/utils";
import { toast } from "sonner";

const txBadge: Record<Transaction["status"], { variant: "blue" | "green" | "red" | "gray"; label: string }> = {
  PENDING:  { variant: "gray",  label: "En attente" },
  PAID:     { variant: "blue",  label: "Payé" },
  FAILED:   { variant: "red",   label: "Échoué" },
  REFUNDED: { variant: "gray",  label: "Remboursé" },
};

const STATUS_OPTS = [
  { value: "", label: "Tous les statuts" },
  { value: "PENDING", label: "En attente" },
  { value: "PAID", label: "Payé" },
  { value: "FAILED", label: "Échoué" },
  { value: "REFUNDED", label: "Remboursé" },
];

const LIMIT = 20;

export default function TransactionsPage() {
  const [data, setData] = useState<Paginated<Transaction>>({ items: [], total: 0, limit: LIMIT, offset: 0 });
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState("");
  const [offset, setOffset] = useState(0);
  const [toDelete, setToDelete] = useState<Transaction | null>(null);
  const [deleting, setDeleting] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    api.get<Paginated<Transaction>>("/admin/payments", {
      status: statusFilter || undefined,
      limit: LIMIT,
      offset,
    })
      .then(setData)
      .finally(() => setLoading(false));
  }, [statusFilter, offset]);

  useEffect(() => { load(); }, [load]);
  useEffect(() => { setOffset(0); }, [statusFilter]);

  const doDelete = async () => {
    if (!toDelete) return;
    setDeleting(true);
    try {
      await api.delete(`/admin/payments/${toDelete.id}`);
      toast.success("Transaction supprimée");
      setToDelete(null);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setDeleting(false);
    }
  };

  const exportCsv = async () => {
    try {
      const csv = await api.csv("/admin/payments/export/csv");
      const blob = new Blob([csv], { type: "text/csv" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url; a.download = "transactions.csv"; a.click();
      URL.revokeObjectURL(url);
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur export");
    }
  };

  return (
    <>
    <ConfirmDialog
      open={!!toDelete}
      title="Supprimer la transaction"
      description={`Supprimer la transaction ${toDelete?.id.slice(0, 8)}… (${toDelete ? fmtAmount(toDelete.amount, toDelete.currency) : ""}) ?`}
      confirmLabel="Supprimer"
      variant="destructive"
      loading={deleting}
      onConfirm={doDelete}
      onCancel={() => setToDelete(null)}
    />
    <div className="space-y-4">
      {/* Toolbar */}
      <div className="flex items-center justify-between gap-3">
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-44">
            <SelectValue placeholder="Statut" />
          </SelectTrigger>
          <SelectContent>
            {STATUS_OPTS.map((o) => <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>)}
          </SelectContent>
        </Select>
        <Button variant="outline" onClick={exportCsv}>
          <Download className="h-4 w-4" />
          Exporter CSV
        </Button>
      </div>

      {/* Table */}
      <div className="table-wrapper">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-100 dark:border-slate-800 bg-gray-50 dark:bg-slate-800/50 text-left">
              <th className="th">ID</th>
              <th className="th">Montant</th>
              <th className="th">Statut</th>
              <th className="th">FedaPay ID</th>
              <th className="th">Payé le</th>
              <th className="th">Créé le</th>
              <th className="th text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-slate-800">
            {loading ? (
              Array.from({ length: 6 }).map((_, i) => (
                <tr key={i}>{Array.from({ length: 6 }).map((_, j) => (
                  <td key={j} className="px-4 py-3">
                    <div className="h-4 w-20 animate-pulse rounded bg-gray-100 dark:bg-slate-700" />
                  </td>
                ))}</tr>
              ))
            ) : data.items.length === 0 ? (
              <tr>
                <td colSpan={6} className="py-12 text-center text-gray-400 dark:text-slate-500">
                  Aucune transaction
                </td>
              </tr>
            ) : data.items.map((t) => {
              const s = txBadge[t.status];
              return (
                <tr key={t.id} className="tr-hover">
                  <td className="td font-mono text-xs text-gray-500 dark:text-slate-400">{t.id.slice(0, 8)}…</td>
                  <td className="td font-semibold text-accent-500">{fmtAmount(t.amount, t.currency)}</td>
                  <td className="td"><Badge variant={s.variant}>{s.label}</Badge></td>
                  <td className="td font-mono text-xs text-gray-500 dark:text-slate-400">{t.fedapay_id ?? "—"}</td>
                  <td className="td text-gray-500 dark:text-slate-400">{fmt(t.paid_at)}</td>
                  <td className="td text-gray-500 dark:text-slate-400">{fmt(t.created_at)}</td>
                  <td className="td">
                    <div className="flex items-center justify-end">
                      <button onClick={() => setToDelete(t)} title="Supprimer"
                        className="rounded p-1.5 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors">
                        <Trash2 className="h-4 w-4" />
                      </button>
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
