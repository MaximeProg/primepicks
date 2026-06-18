"use client";
import { useEffect, useState, useCallback } from "react";
import { Plus, Pencil, Trash2, Send, Search, Camera, ImageOff, PlusCircle, MinusCircle, CheckCircle2, XCircle, Ban } from "lucide-react";
import { useRef } from "react";
import Image from "next/image";
import type { CouponMatch, CouponType } from "@/lib/api";
import { api, type Coupon, type Paginated } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Pagination } from "@/components/ui/pagination";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogClose,
} from "@/components/ui/dialog";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { fmt } from "@/lib/utils";
import { toast } from "sonner";

const STATUS_OPTS = [
  { value: "", label: "Tous les statuts" },
  { value: "PENDING", label: "En attente" },
  { value: "WON", label: "Gagné" },
  { value: "LOST", label: "Perdu" },
  { value: "CANCELLED", label: "Annulé" },
];

const statusBadge: Record<Coupon["status"], { variant: "blue" | "gray" | "red" | "orange"; label: string }> = {
  PENDING:   { variant: "gray",   label: "En attente" },
  WON:       { variant: "blue",   label: "Gagné" },
  LOST:      { variant: "red",    label: "Perdu" },
  CANCELLED: { variant: "orange", label: "Annulé" },
};

type MatchDraft = { match_name: string; prediction: string; odd: string; };
const emptyMatch = (): MatchDraft => ({ match_name: "", prediction: "", odd: "" });

type FormData = {
  title: string; description: string; analysis: string;
  odds: string; bookmaker_code: string; status: Coupon["status"];
  coupon_type: CouponType;
  confidence_level: string;
};

const empty: FormData = {
  title: "", description: "", analysis: "",
  odds: "", bookmaker_code: "", status: "PENDING",
  coupon_type: "FREE", confidence_level: "",
};

const LIMIT = 15;

export default function CouponsPage() {
  const [data, setData] = useState<Paginated<Coupon>>({ items: [], total: 0, limit: LIMIT, offset: 0 });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [offset, setOffset] = useState(0);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Coupon | null>(null);
  const [form, setForm] = useState<FormData>(empty);
  const [saving, setSaving] = useState(false);
  const [toDelete, setToDelete] = useState<Coupon | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [uploading, setUploading] = useState<string | null>(null);
  const [previewCoupon, setPreviewCoupon] = useState<Coupon | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const uploadTargetRef = useRef<string | null>(null);
  const dialogFileInputRef = useRef<HTMLInputElement>(null);
  const [pendingImage, setPendingImage] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [matches, setMatches] = useState<MatchDraft[]>([]);
  const [statusChanging, setStatusChanging] = useState<string | null>(null);

  const load = useCallback(() => {
    setLoading(true);
    api.get<Paginated<Coupon>>("/admin/coupons", {
      search: search || undefined,
      status: statusFilter || undefined,
      limit: LIMIT,
      offset,
    })
      .then(setData)
      .finally(() => setLoading(false));
  }, [search, statusFilter, offset]);

  useEffect(() => { load(); }, [load]);

  // Reset offset when filters change
  useEffect(() => { setOffset(0); }, [search, statusFilter]);

  const openCreate = () => {
    setEditing(null);
    setForm(empty);
    setPendingImage(null);
    setImagePreview(null);
    setMatches([]);
    setOpen(true);
  };
  const openEdit = (c: Coupon) => {
    setEditing(c);
    setForm({
      title: c.title, description: c.description ?? "",
      analysis: c.analysis ?? "", odds: c.odds?.toString() ?? "",
      bookmaker_code: c.bookmaker_code ?? "", status: c.status,
      coupon_type: c.coupon_type ?? "FREE",
      confidence_level: c.confidence_level?.toString() ?? "",
    });
    setPendingImage(null);
    setImagePreview(c.image_url ?? null);
    setMatches(c.matches?.map((m) => ({
      match_name: m.match_name,
      prediction: m.prediction,
      odd: m.odd?.toString() ?? "",
    })) ?? []);
    setOpen(true);
  };

  const save = async () => {
    setSaving(true);
    try {
      const body = {
        title: form.title,
        description: form.description || undefined,
        analysis: form.analysis || undefined,
        odds: form.odds ? parseFloat(form.odds) : undefined,
        bookmaker_code: form.bookmaker_code || undefined,
        status: form.status,
        coupon_type: form.coupon_type,
        confidence_level: form.confidence_level ? parseInt(form.confidence_level) : undefined,
      };
      let couponId: string;
      if (editing) {
        await api.patch<Coupon>(`/admin/coupons/${editing.id}`, body);
        couponId = editing.id;
        for (const m of editing.matches ?? []) {
          await api.delete(`/admin/coupons/${couponId}/matches/${m.id}`);
        }
      } else {
        const created = await api.post<Coupon>("/admin/coupons", body);
        couponId = created.id;
      }
      if (pendingImage) {
        await api.upload<Coupon>(`/admin/coupons/${couponId}/image`, pendingImage);
      }
      for (const m of matches) {
        if (m.match_name && m.prediction) {
          await api.post(`/admin/coupons/${couponId}/matches`, {
            match_name: m.match_name,
            prediction: m.prediction,
            odd: m.odd ? parseFloat(m.odd) : undefined,
          });
        }
      }
      toast.success(editing ? "Coupon mis à jour" : "Coupon créé");
      setOpen(false);
      setPendingImage(null);
      setImagePreview(null);
      setMatches([]);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setSaving(false);
    }
  };

  const publish = async (c: Coupon) => {
    try {
      await api.post(`/admin/coupons/${c.id}/publish`);
      toast.success("Coupon publié");
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    }
  };

  const remove = (c: Coupon) => setToDelete(c);

  const openImageUpload = (couponId: string) => {
    uploadTargetRef.current = couponId;
    fileInputRef.current?.click();
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    const id = uploadTargetRef.current;
    if (!file || !id) return;
    e.target.value = "";
    setUploading(id);
    try {
      await api.upload<Coupon>(`/admin/coupons/${id}/image`, file);
      toast.success("Capture ajoutée");
      load();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Erreur upload");
    } finally {
      setUploading(null);
    }
  };

  const changeStatus = async (c: Coupon, status: Coupon["status"]) => {
    setStatusChanging(c.id);
    try {
      await api.patch(`/admin/coupons/${c.id}/status`, { status });
      toast.success(`Statut mis à jour : ${statusBadge[status].label}`);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setStatusChanging(null);
    }
  };

  const doDelete = async () => {
    if (!toDelete) return;
    setDeleting(true);
    try {
      await api.delete(`/admin/coupons/${toDelete.id}`);
      toast.success("Coupon supprimé");
      setToDelete(null);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setDeleting(false);
    }
  };

  return (
    <>
      {/* Input file caché — table */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={handleFileChange}
      />
      {/* Input file caché — dialog */}
      <input
        ref={dialogFileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (!file) return;
          e.target.value = "";
          setPendingImage(file);
          setImagePreview(URL.createObjectURL(file));
        }}
      />

      {/* Dialog aperçu image */}
      <Dialog open={!!previewCoupon} onOpenChange={(v) => { if (!v) setPreviewCoupon(null); }}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>{previewCoupon?.title}</DialogTitle>
          </DialogHeader>
          {previewCoupon?.image_url && (
            <div className="relative w-full overflow-hidden rounded-lg">
              <Image
                src={previewCoupon.image_url}
                alt={previewCoupon.title}
                width={800}
                height={600}
                className="w-full object-contain"
                unoptimized
              />
            </div>
          )}
          <div className="flex justify-end gap-2 mt-2">
            <Button
              variant="outline"
              onClick={() => { setPreviewCoupon(null); openImageUpload(previewCoupon!.id); }}
            >
              <Camera className="h-4 w-4" />
              Changer la capture
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={!!toDelete}
        title="Supprimer le coupon"
        description={`Supprimer définitivement « ${toDelete?.title ?? ""} » ? Cette action est irréversible.`}
        confirmLabel="Supprimer"
        variant="destructive"
        loading={deleting}
        onConfirm={doDelete}
        onCancel={() => setToDelete(null)}
      />
      <div className="space-y-4">
        {/* Toolbar */}
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex flex-1 items-center gap-2">
            <div className="relative max-w-xs flex-1">
              <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-gray-400 dark:text-slate-500" />
              <Input
                placeholder="Rechercher un coupon…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-8"
              />
            </div>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-40">
                <SelectValue placeholder="Statut" />
              </SelectTrigger>
              <SelectContent>
                {STATUS_OPTS.map((o) => (
                  <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <Button onClick={openCreate}>
            <Plus className="h-4 w-4" />
            Nouveau
          </Button>
        </div>

        {/* Table */}
        <div className="table-wrapper">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 dark:border-slate-800 bg-gray-50 dark:bg-slate-800/50 text-left">
                <th className="th">Capture</th>
                <th className="th">Titre</th>
                <th className="th">Cote</th>
                <th className="th">Statut</th>
                <th className="th">Publication</th>
                <th className="th">Créé le</th>
                <th className="th text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-slate-800">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i}>
                    {Array.from({ length: 7 }).map((_, j) => (
                      <td key={j} className="px-4 py-3">
                        <div className="h-4 w-24 animate-pulse rounded bg-gray-100 dark:bg-slate-700" />
                      </td>
                    ))}
                  </tr>
                ))
              ) : data.items.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-gray-400 dark:text-slate-500">
                    Aucun coupon trouvé
                  </td>
                </tr>
              ) : (
                data.items.map((c) => {
                  const s = statusBadge[c.status];
                  return (
                    <tr key={c.id} className="tr-hover">
                      {/* Capture / miniature */}
                      <td className="px-4 py-2 w-16">
                        {uploading === c.id ? (
                          <div className="flex h-10 w-14 items-center justify-center rounded bg-gray-100 dark:bg-slate-700">
                            <div className="h-4 w-4 animate-spin rounded-full border-2 border-primary-700 border-t-transparent" />
                          </div>
                        ) : c.image_url ? (
                          <button
                            onClick={() => setPreviewCoupon(c)}
                            className="relative block h-10 w-14 overflow-hidden rounded border border-gray-200 dark:border-slate-700 hover:opacity-80 transition-opacity"
                            title="Voir / changer la capture"
                          >
                            <Image
                              src={c.image_url}
                              alt={c.title}
                              fill
                              className="object-cover"
                              unoptimized
                            />
                          </button>
                        ) : (
                          <button
                            onClick={() => openImageUpload(c.id)}
                            className="flex h-10 w-14 items-center justify-center rounded border border-dashed border-gray-300 dark:border-slate-600 text-gray-400 dark:text-slate-500 hover:border-primary-700 hover:text-primary-700 dark:hover:text-primary-400 transition-colors"
                            title="Ajouter une capture"
                          >
                            <Camera className="h-4 w-4" />
                          </button>
                        )}
                      </td>
                      <td className="td max-w-xs truncate font-medium text-gray-900 dark:text-slate-100">{c.title}</td>
                      <td className="td">
                        {c.odds ? <span className="font-semibold text-accent-500">{c.odds}</span> : "—"}
                      </td>
                      <td className="td"><Badge variant={s.variant}>{s.label}</Badge></td>
                      <td className="td">
                        {c.is_published
                          ? <Badge variant="blue">Publié</Badge>
                          : <span className="text-gray-400 dark:text-slate-500 text-xs">Non publié</span>}
                      </td>
                      <td className="td text-gray-500 dark:text-slate-400">{fmt(c.created_at)}</td>
                      <td className="td">
                        <div className="flex items-center justify-end gap-1">
                          {/* Changement de statut — visible si publié et en attente */}
                          {c.is_published && c.status === "PENDING" && (
                            <>
                              <button onClick={() => changeStatus(c, "WON")} title="Marquer Gagné"
                                disabled={statusChanging === c.id}
                                className="rounded p-1.5 text-green-600 dark:text-green-400 hover:bg-green-50 dark:hover:bg-green-900/20 disabled:opacity-40">
                                <CheckCircle2 className="h-4 w-4" />
                              </button>
                              <button onClick={() => changeStatus(c, "LOST")} title="Marquer Perdu"
                                disabled={statusChanging === c.id}
                                className="rounded p-1.5 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 disabled:opacity-40">
                                <XCircle className="h-4 w-4" />
                              </button>
                              <button onClick={() => changeStatus(c, "CANCELLED")} title="Annuler"
                                disabled={statusChanging === c.id}
                                className="rounded p-1.5 text-gray-400 dark:text-slate-500 hover:bg-gray-100 dark:hover:bg-slate-700 disabled:opacity-40">
                                <Ban className="h-4 w-4" />
                              </button>
                            </>
                          )}
                          {!c.is_published && (
                            <button onClick={() => publish(c)} title="Publier"
                              className="rounded p-1.5 text-accent-500 hover:bg-accent-50 dark:hover:bg-orange-900/20">
                              <Send className="h-4 w-4" />
                            </button>
                          )}
                          <button
                            onClick={() => openImageUpload(c.id)}
                            title={c.image_url ? "Changer la capture" : "Ajouter une capture"}
                            className="rounded p-1.5 text-gray-400 dark:text-slate-500 hover:bg-gray-100 dark:hover:bg-slate-700 hover:text-gray-700 dark:hover:text-slate-300"
                          >
                            {c.image_url ? <Camera className="h-4 w-4" /> : <ImageOff className="h-4 w-4" />}
                          </button>
                          <button onClick={() => openEdit(c)} title="Modifier"
                            className="rounded p-1.5 text-primary-700 dark:text-primary-400 hover:bg-primary-50 dark:hover:bg-primary-900/20">
                            <Pencil className="h-4 w-4" />
                          </button>
                          <button onClick={() => remove(c)} title="Supprimer"
                            className="rounded p-1.5 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20">
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
          <Pagination total={data.total} limit={LIMIT} offset={offset} onChange={setOffset} />
        </div>
      </div>

      {/* Modal */}
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editing ? "Modifier le coupon" : "Nouveau coupon"}</DialogTitle>
          </DialogHeader>
          <div className="flex-1 overflow-y-auto -mx-6 px-6 py-1">
          <div className="grid gap-4">
            <div className="space-y-1.5">
              <Label>Titre *</Label>
              <Input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <Label>Cote</Label>
                <Input type="number" step="0.01" value={form.odds}
                  onChange={(e) => setForm({ ...form, odds: e.target.value })} />
              </div>
              <div className="space-y-1.5">
                <Label>Code bookmaker</Label>
                <Input value={form.bookmaker_code}
                  onChange={(e) => setForm({ ...form, bookmaker_code: e.target.value })} />
              </div>
            </div>
            <div className="space-y-1.5">
              <Label>Description</Label>
              <Textarea rows={2} value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })} />
            </div>
            <div className="space-y-1.5">
              <Label>Analyse</Label>
              <Textarea rows={3} value={form.analysis}
                onChange={(e) => setForm({ ...form, analysis: e.target.value })} />
            </div>
            {/* Type et confiance */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <Label>Type de coupon</Label>
                <Select value={form.coupon_type}
                  onValueChange={(v) => setForm({ ...form, coupon_type: v as CouponType })}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="FREE">Gratuit</SelectItem>
                    <SelectItem value="PREMIUM">Premium</SelectItem>
                    <SelectItem value="VIP">VIP</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Confiance (1–5)</Label>
                <Select value={form.confidence_level}
                  onValueChange={(v) => setForm({ ...form, confidence_level: v })}>
                  <SelectTrigger><SelectValue placeholder="—" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">—</SelectItem>
                    <SelectItem value="1">1 — Faible</SelectItem>
                    <SelectItem value="2">2 — Moyen</SelectItem>
                    <SelectItem value="3">3 — Bon</SelectItem>
                    <SelectItem value="4">4 — Élevé</SelectItem>
                    <SelectItem value="5">5 — Très élevé</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            {editing && (
              <div className="space-y-1.5">
                <Label>Statut</Label>
                <Select value={form.status}
                  onValueChange={(v) => setForm({ ...form, status: v as Coupon["status"] })}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {STATUS_OPTS.slice(1).map((o) => (
                      <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}

            {/* Matchs */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label>Matchs ({matches.length})</Label>
                <button type="button" onClick={() => setMatches([...matches, emptyMatch()])}
                  className="flex items-center gap-1 text-xs font-medium text-primary-700 dark:text-primary-400 hover:underline">
                  <PlusCircle className="h-3.5 w-3.5" /> Ajouter un match
                </button>
              </div>
              {matches.map((m, i) => (
                <div key={i} className="flex items-center gap-2 rounded-lg border border-gray-200 dark:border-slate-700 p-2">
                  <div className="flex-1 grid grid-cols-3 gap-2">
                    <Input placeholder="Ex: Man City vs Arsenal" value={m.match_name}
                      onChange={(e) => { const n = [...matches]; n[i].match_name = e.target.value; setMatches(n); }} />
                    <Input placeholder="Prédiction (ex: 1 / BTTS)" value={m.prediction}
                      onChange={(e) => { const n = [...matches]; n[i].prediction = e.target.value; setMatches(n); }} />
                    <Input type="number" step="0.01" placeholder="Cote" value={m.odd}
                      onChange={(e) => { const n = [...matches]; n[i].odd = e.target.value; setMatches(n); }} />
                  </div>
                  <button type="button" onClick={() => setMatches(matches.filter((_, j) => j !== i))}
                    className="text-red-400 hover:text-red-600 transition-colors shrink-0">
                    <MinusCircle className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>

            {/* Capture bookmaker */}
            <div className="space-y-1.5">
              <Label>Capture bookmaker</Label>
              {imagePreview ? (
                <div className="relative overflow-hidden rounded-lg border border-gray-200 dark:border-slate-700 bg-gray-50 dark:bg-slate-800">
                  <Image
                    src={imagePreview}
                    alt="Aperçu capture"
                    width={600}
                    height={300}
                    className="w-full max-h-48 object-contain"
                    unoptimized
                  />
                  <button
                    type="button"
                    onClick={() => dialogFileInputRef.current?.click()}
                    className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 hover:opacity-100 transition-opacity text-white text-sm font-medium gap-2"
                  >
                    <Camera className="h-4 w-4" />
                    Changer la capture
                  </button>
                </div>
              ) : (
                <button
                  type="button"
                  onClick={() => dialogFileInputRef.current?.click()}
                  className="flex w-full flex-col items-center justify-center gap-2 rounded-lg border-2 border-dashed border-gray-300 dark:border-slate-600 py-8 text-gray-400 dark:text-slate-500 hover:border-primary-700 hover:text-primary-700 dark:hover:text-primary-400 transition-colors"
                >
                  <Camera className="h-6 w-6" />
                  <span className="text-sm">Cliquer pour ajouter la capture du bookmaker</span>
                  <span className="text-xs opacity-60">JPG, PNG, WebP — max 5 MB</span>
                </button>
              )}
            </div>
          </div>
          </div>
          <DialogFooter>
            <DialogClose asChild><Button variant="outline">Annuler</Button></DialogClose>
            <Button onClick={save} disabled={saving || !form.title}>
              {saving ? "Enregistrement…" : "Enregistrer"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
