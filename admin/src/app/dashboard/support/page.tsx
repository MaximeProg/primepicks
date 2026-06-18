"use client";
import { useEffect, useState, useCallback } from "react";
import { api, type SupportTicket, type TicketStatus, type Paginated } from "@/lib/api";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Pagination } from "@/components/ui/pagination";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogClose } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { fmt } from "@/lib/utils";
import { MessageSquare, ChevronDown } from "lucide-react";

const LIMIT = 20;

const statusVariant: Record<TicketStatus, { label: string; variant: "gray" | "blue" | "green" | "orange" }> = {
  OPEN: { label: "Ouvert", variant: "orange" },
  IN_PROGRESS: { label: "En cours", variant: "blue" },
  CLOSED: { label: "Fermé", variant: "gray" },
};

export default function SupportPage() {
  const [data, setData] = useState<Paginated<SupportTicket>>({ items: [], total: 0, limit: LIMIT, offset: 0 });
  const [loading, setLoading] = useState(true);
  const [offset, setOffset] = useState(0);
  const [statusFilter, setStatusFilter] = useState("");
  const [selected, setSelected] = useState<SupportTicket | null>(null);
  const [reply, setReply] = useState("");
  const [newStatus, setNewStatus] = useState<TicketStatus>("OPEN");
  const [saving, setSaving] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    api.get<Paginated<SupportTicket>>("/admin/support", {
      status: statusFilter || undefined,
      limit: LIMIT,
      offset,
    }).then(setData).finally(() => setLoading(false));
  }, [statusFilter, offset]);

  useEffect(() => { load(); }, [load]);
  useEffect(() => { setOffset(0); }, [statusFilter]);

  const openTicket = (t: SupportTicket) => {
    setSelected(t);
    setReply(t.admin_reply ?? "");
    setNewStatus(t.status);
  };

  const saveReply = async () => {
    if (!selected) return;
    setSaving(true);
    try {
      await api.patch(`/admin/support/${selected.id}`, {
        status: newStatus,
        admin_reply: reply || undefined,
      });
      toast.success("Ticket mis à jour");
      setSelected(null);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      {/* Dialog ticket */}
      <Dialog open={!!selected} onOpenChange={(v) => { if (!v) setSelected(null); }}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>{selected?.subject}</DialogTitle>
          </DialogHeader>
          <div className="flex-1 overflow-y-auto -mx-6 px-6 py-1 space-y-4">
            <div className="rounded-lg bg-gray-50 dark:bg-slate-800 p-4 text-sm text-gray-700 dark:text-slate-300">
              <p className="text-xs text-gray-400 dark:text-slate-500 mb-1">Message de l'utilisateur</p>
              {selected?.message}
            </div>
            <div className="space-y-1.5">
              <Label>Statut</Label>
              <Select value={newStatus} onValueChange={(v) => setNewStatus(v as TicketStatus)}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="OPEN">Ouvert</SelectItem>
                  <SelectItem value="IN_PROGRESS">En cours</SelectItem>
                  <SelectItem value="CLOSED">Fermé</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>Réponse admin</Label>
              <Textarea rows={5} placeholder="Votre réponse…" value={reply}
                onChange={(e) => setReply(e.target.value)} />
            </div>
          </div>
          <DialogFooter>
            <DialogClose asChild><Button variant="outline">Fermer</Button></DialogClose>
            <Button onClick={saveReply} disabled={saving}>{saving ? "Enregistrement…" : "Enregistrer"}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <div className="space-y-4">
        {/* Filtres */}
        <div className="flex items-center gap-3">
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-44"><SelectValue placeholder="Tous les statuts" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="">Tous</SelectItem>
              <SelectItem value="OPEN">Ouverts</SelectItem>
              <SelectItem value="IN_PROGRESS">En cours</SelectItem>
              <SelectItem value="CLOSED">Fermés</SelectItem>
            </SelectContent>
          </Select>
          <span className="text-sm text-gray-500 dark:text-slate-400">{data.total} ticket(s)</span>
        </div>

        <div className="table-wrapper">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 dark:border-slate-800 bg-gray-50 dark:bg-slate-800/50 text-left">
                <th className="th">Sujet</th>
                <th className="th">Statut</th>
                <th className="th">Date</th>
                <th className="th text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-slate-800">
              {loading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i}>{Array.from({ length: 4 }).map((_, j) => (
                    <td key={j} className="px-4 py-3"><div className="h-4 w-24 animate-pulse rounded bg-gray-100 dark:bg-slate-700" /></td>
                  ))}</tr>
                ))
              ) : data.items.length === 0 ? (
                <tr><td colSpan={4} className="py-12 text-center text-gray-400 dark:text-slate-500">Aucun ticket</td></tr>
              ) : data.items.map((t) => {
                const s = statusVariant[t.status];
                return (
                  <tr key={t.id} className="tr-hover">
                    <td className="td">
                      <div className="font-medium text-gray-900 dark:text-slate-100">{t.subject}</div>
                      <div className="text-xs text-gray-400 dark:text-slate-500 truncate max-w-xs">{t.message.slice(0, 80)}…</div>
                    </td>
                    <td className="td"><Badge variant={s.variant}>{s.label}</Badge></td>
                    <td className="td text-gray-500 dark:text-slate-400">{fmt(t.created_at)}</td>
                    <td className="td">
                      <div className="flex justify-end">
                        <button onClick={() => openTicket(t)}
                          className="flex items-center gap-1.5 rounded px-2 py-1 text-xs font-medium text-primary-700 dark:text-primary-400 hover:bg-primary-50 dark:hover:bg-primary-900/20 transition-colors">
                          <MessageSquare className="h-3.5 w-3.5" />
                          Répondre
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
