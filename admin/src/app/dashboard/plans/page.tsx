"use client";
import { useEffect, useState } from "react";
import { Plus, Pencil, Trash2, Search } from "lucide-react";
import { api, type Plan } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogClose,
} from "@/components/ui/dialog";
import { fmtAmount } from "@/lib/utils";
import { toast } from "sonner";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";

type FormData = {
  name: string; slug: string; price: string;
  duration_days: string; description: string; loyalty_points_reward: string;
};
const empty: FormData = { name: "", slug: "", price: "", duration_days: "", description: "", loyalty_points_reward: "0" };

export default function PlansPage() {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Plan | null>(null);
  const [form, setForm] = useState<FormData>(empty);
  const [saving, setSaving] = useState(false);
  const [toDelete, setToDelete] = useState<Plan | null>(null);
  const [deleting, setDeleting] = useState(false);

  const load = () => api.get<Plan[]>("/admin/plans").then(setPlans).finally(() => setLoading(false));
  useEffect(() => { load(); }, []);

  const filtered = plans.filter((p) =>
    !search || p.name.toLowerCase().includes(search.toLowerCase()) || p.slug.includes(search.toLowerCase())
  );

  const openCreate = () => { setEditing(null); setForm(empty); setOpen(true); };
  const openEdit = (p: Plan) => {
    setEditing(p);
    setForm({
      name: p.name, slug: p.slug, price: p.price.toString(),
      duration_days: p.duration_days.toString(),
      description: p.description ?? "", loyalty_points_reward: p.loyalty_points_reward.toString(),
    });
    setOpen(true);
  };

  const save = async () => {
    setSaving(true);
    try {
      const body = {
        name: form.name, slug: form.slug,
        price: parseFloat(form.price), duration_days: parseInt(form.duration_days),
        description: form.description || undefined,
        loyalty_points_reward: parseInt(form.loyalty_points_reward) || 0,
      };
      if (editing) {
        await api.patch(`/admin/plans/${editing.id}`, body);
        toast.success("Plan mis à jour");
      } else {
        await api.post("/admin/plans", body);
        toast.success("Plan créé");
      }
      setOpen(false); load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setSaving(false);
    }
  };

  const remove = (p: Plan) => setToDelete(p);

  const doDelete = async () => {
    if (!toDelete) return;
    setDeleting(true);
    try {
      await api.delete(`/admin/plans/${toDelete.id}`);
      toast.success("Plan supprimé");
      setToDelete(null);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setDeleting(false);
    }
  };

  const toggleActive = async (p: Plan) => {
    try {
      await api.patch(`/admin/plans/${p.id}`, { is_active: !p.is_active });
      toast.success(p.is_active ? "Plan désactivé" : "Plan activé"); load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    }
  };

  return (
    <>
      <ConfirmDialog
        open={!!toDelete}
        title="Supprimer le plan"
        description={`Supprimer définitivement le plan « ${toDelete?.name ?? ""} » ? Cette action est irréversible.`}
        confirmLabel="Supprimer"
        variant="destructive"
        loading={deleting}
        onConfirm={doDelete}
        onCancel={() => setToDelete(null)}
      />
      <div className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="relative max-w-xs flex-1">
            <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-gray-400 dark:text-slate-500" />
            <Input placeholder="Rechercher un plan…" value={search}
              onChange={(e) => setSearch(e.target.value)} className="pl-8" />
          </div>
          <Button onClick={openCreate}><Plus className="h-4 w-4" />Nouveau plan</Button>
        </div>

        <div className="table-wrapper">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 dark:border-slate-800 bg-gray-50 dark:bg-slate-800/50 text-left">
                <th className="th">Nom</th>
                <th className="th">Prix</th>
                <th className="th">Durée</th>
                <th className="th">Points fidélité</th>
                <th className="th">Statut</th>
                <th className="th text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-slate-800">
              {loading ? (
                Array.from({ length: 4 }).map((_, i) => (
                  <tr key={i}>{Array.from({ length: 6 }).map((_, j) => (
                    <td key={j} className="px-4 py-3">
                      <div className="h-4 w-20 animate-pulse rounded bg-gray-100 dark:bg-slate-700" />
                    </td>
                  ))}</tr>
                ))
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-gray-400 dark:text-slate-500">
                    Aucun plan trouvé
                  </td>
                </tr>
              ) : filtered.map((p) => (
                <tr key={p.id} className="tr-hover">
                  <td className="td font-medium text-gray-900 dark:text-slate-100">{p.name}</td>
                  <td className="td font-semibold text-accent-500">{fmtAmount(p.price)}</td>
                  <td className="td text-gray-600 dark:text-slate-400">{p.duration_days} j</td>
                  <td className="td text-gray-600 dark:text-slate-400">
                    <span className="font-medium text-primary-700 dark:text-primary-400">{p.loyalty_points_reward}</span> pts
                  </td>
                  <td className="td">
                    <button onClick={() => toggleActive(p)}>
                      <Badge variant={p.is_active ? "blue" : "gray"}>
                        {p.is_active ? "Actif" : "Inactif"}
                      </Badge>
                    </button>
                  </td>
                  <td className="td">
                    <div className="flex items-center justify-end gap-1">
                      <button onClick={() => openEdit(p)}
                        className="rounded p-1.5 text-primary-700 dark:text-primary-400 hover:bg-primary-50 dark:hover:bg-primary-900/20">
                        <Pencil className="h-4 w-4" />
                      </button>
                      <button onClick={() => remove(p)}
                        className="rounded p-1.5 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20">
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editing ? "Modifier le plan" : "Nouveau plan"}</DialogTitle>
          </DialogHeader>
          <div className="flex-1 overflow-y-auto -mx-6 px-6 py-1">
          <div className="grid gap-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <Label>Nom *</Label>
                <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
              </div>
              <div className="space-y-1.5">
                <Label>Slug *</Label>
                <Input value={form.slug} onChange={(e) => setForm({ ...form, slug: e.target.value })} />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <Label>Prix (XOF) *</Label>
                <Input type="number" value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })} />
              </div>
              <div className="space-y-1.5">
                <Label>Durée (jours) *</Label>
                <Input type="number" value={form.duration_days}
                  onChange={(e) => setForm({ ...form, duration_days: e.target.value })} />
              </div>
            </div>
            <div className="space-y-1.5">
              <Label>Points fidélité offerts</Label>
              <Input type="number" value={form.loyalty_points_reward}
                onChange={(e) => setForm({ ...form, loyalty_points_reward: e.target.value })} />
            </div>
            <div className="space-y-1.5">
              <Label>Description</Label>
              <Textarea rows={2} value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })} />
            </div>
          </div>
          </div>
          <DialogFooter>
            <DialogClose asChild><Button variant="outline">Annuler</Button></DialogClose>
            <Button onClick={save} disabled={saving || !form.name || !form.price || !form.duration_days}>
              {saving ? "Enregistrement…" : "Enregistrer"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
