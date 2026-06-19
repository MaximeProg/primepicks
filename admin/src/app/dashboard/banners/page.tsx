"use client";
import { useEffect, useState, useRef } from "react";
import { Plus, Pencil, Trash2, GripVertical, Camera } from "lucide-react";
import { api, type Banner } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogClose } from "@/components/ui/dialog";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { toast } from "sonner";
import Image from "next/image";
import { fmt } from "@/lib/utils";

type FormData = {
  title: string;
  redirect_url: string;
  position: string;
  start_date: string;
  end_date: string;
};

const empty: FormData = { title: "", redirect_url: "", position: "0", start_date: "", end_date: "" };

export default function BannersPage() {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Banner | null>(null);
  const [form, setForm] = useState<FormData>(empty);
  const [saving, setSaving] = useState(false);
  const [toDelete, setToDelete] = useState<Banner | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [uploading, setUploading] = useState<string | null>(null);
  const [pendingImage, setPendingImage] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const dialogFileRef = useRef<HTMLInputElement>(null);
  const uploadTargetRef = useRef<string | null>(null);

  const load = () => api.get<Banner[]>("/admin/banners").then(setBanners).finally(() => setLoading(false));
  useEffect(() => { load(); }, []);

  const openCreate = () => { setEditing(null); setForm(empty); setPendingImage(null); setImagePreview(null); setOpen(true); };
  const openEdit = (b: Banner) => {
    setEditing(b);
    setForm({
      title: b.title,
      redirect_url: b.redirect_url ?? "",
      position: b.position.toString(),
      start_date: b.start_date ? b.start_date.slice(0, 16) : "",
      end_date: b.end_date ? b.end_date.slice(0, 16) : "",
    });
    setPendingImage(null);
    setImagePreview(b.image_url);
    setOpen(true);
  };

  const save = async () => {
    if (!pendingImage && !editing?.image_url && !editing) {
      toast.error("Veuillez ajouter une image");
      return;
    }
    setSaving(true);
    try {
      const body = {
        title: form.title,
        image_url: editing?.image_url ?? "placeholder",
        redirect_url: form.redirect_url || undefined,
        position: parseInt(form.position) || 0,
        start_date: form.start_date || undefined,
        end_date: form.end_date || undefined,
      };
      let id: string;
      if (editing) {
        await api.patch<Banner>(`/admin/banners/${editing.id}`, body);
        id = editing.id;
      } else {
        const created = await api.post<Banner>("/admin/banners", body);
        id = created.id;
      }
      if (pendingImage) {
        await api.upload<Banner>(`/admin/banners/${id}/image`, pendingImage);
      }
      toast.success(editing ? "Bannière mise à jour" : "Bannière créée");
      setOpen(false);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setSaving(false);
    }
  };

  const toggleActive = async (b: Banner) => {
    try {
      await api.patch(`/admin/banners/${b.id}`, { is_active: !b.is_active });
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    }
  };

  const doDelete = async () => {
    if (!toDelete) return;
    setDeleting(true);
    try {
      await api.delete(`/admin/banners/${toDelete.id}`);
      toast.success("Bannière supprimée");
      setToDelete(null);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setDeleting(false);
    }
  };

  const handleTableUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    const id = uploadTargetRef.current;
    if (!file || !id) return;
    e.target.value = "";
    setUploading(id);
    try {
      await api.upload(`/admin/banners/${id}/image`, file);
      toast.success("Image mise à jour");
      load();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Erreur");
    } finally {
      setUploading(null);
    }
  };

  return (
    <>
      <input ref={fileInputRef} type="file" accept="image/*" className="hidden"
        onChange={handleTableUpload} />
      <input ref={dialogFileRef} type="file" accept="image/*" className="hidden"
        onChange={(e) => {
          const f = e.target.files?.[0];
          if (!f) return;
          e.target.value = "";
          setPendingImage(f);
          setImagePreview(URL.createObjectURL(f));
        }} />

      <ConfirmDialog
        open={!!toDelete}
        title="Supprimer la bannière"
        description={`Supprimer « ${toDelete?.title ?? ""} » ?`}
        confirmLabel="Supprimer"
        loading={deleting}
        onConfirm={doDelete}
        onCancel={() => setToDelete(null)}
      />

      <div className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <p className="text-sm text-gray-500 dark:text-slate-400">{banners.length} bannière(s)</p>
          <Button onClick={openCreate}><Plus className="h-4 w-4" />Nouvelle bannière</Button>
        </div>

        <div className="table-wrapper">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 dark:border-slate-800 bg-gray-50 dark:bg-slate-800/50 text-left">
                <th className="th">Image</th>
                <th className="th">Titre</th>
                <th className="th">Position</th>
                <th className="th">Statut</th>
                <th className="th">Dates</th>
                <th className="th text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-slate-800">
              {loading ? (
                Array.from({ length: 4 }).map((_, i) => (
                  <tr key={i}>{Array.from({ length: 6 }).map((_, j) => (
                    <td key={j} className="px-4 py-3"><div className="h-4 w-20 animate-pulse rounded bg-gray-100 dark:bg-slate-700" /></td>
                  ))}</tr>
                ))
              ) : banners.length === 0 ? (
                <tr><td colSpan={6} className="py-12 text-center text-gray-400 dark:text-slate-500">Aucune bannière</td></tr>
              ) : banners.map((b) => (
                <tr key={b.id} className="tr-hover">
                  <td className="px-4 py-2 w-20">
                    {uploading === b.id ? (
                      <div className="flex h-10 w-16 items-center justify-center rounded bg-gray-100 dark:bg-slate-700">
                        <div className="h-4 w-4 animate-spin rounded-full border-2 border-primary-700 border-t-transparent" />
                      </div>
                    ) : b.image_url ? (
                      <div className="relative h-10 w-16 overflow-hidden rounded border border-gray-200 dark:border-slate-700">
                        <Image src={b.image_url} alt={b.title} fill className="object-cover" unoptimized />
                      </div>
                    ) : (
                      <button
                        onClick={() => { uploadTargetRef.current = b.id; fileInputRef.current?.click(); }}
                        className="flex h-10 w-16 items-center justify-center rounded border border-dashed border-gray-300 dark:border-slate-600 text-gray-400 hover:border-primary-700 hover:text-primary-700 transition-colors"
                      >
                        <Camera className="h-4 w-4" />
                      </button>
                    )}
                  </td>
                  <td className="td font-medium text-gray-900 dark:text-slate-100">
                    {b.title}
                    {b.redirect_url && <span className="block text-xs text-gray-400 dark:text-slate-500 truncate max-w-xs">{b.redirect_url}</span>}
                  </td>
                  <td className="td text-gray-500 dark:text-slate-400">{b.position}</td>
                  <td className="td">
                    <button onClick={() => toggleActive(b)}>
                      <Badge variant={b.is_active ? "blue" : "gray"}>{b.is_active ? "Active" : "Inactive"}</Badge>
                    </button>
                  </td>
                  <td className="td text-xs text-gray-500 dark:text-slate-400">
                    {b.start_date ? fmt(b.start_date) : "—"}
                    {b.end_date && <span> → {fmt(b.end_date)}</span>}
                  </td>
                  <td className="td">
                    <div className="flex items-center justify-end gap-1">
                      <button onClick={() => { uploadTargetRef.current = b.id; fileInputRef.current?.click(); }}
                        className="rounded p-1.5 text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 hover:text-gray-700 dark:hover:text-slate-300">
                        <Camera className="h-4 w-4" />
                      </button>
                      <button onClick={() => openEdit(b)}
                        className="rounded p-1.5 text-primary-700 dark:text-primary-400 hover:bg-primary-50 dark:hover:bg-primary-900/20">
                        <Pencil className="h-4 w-4" />
                      </button>
                      <button onClick={() => setToDelete(b)}
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
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editing ? "Modifier la bannière" : "Nouvelle bannière"}</DialogTitle>
          </DialogHeader>
          <div className="flex-1 overflow-y-auto -mx-6 px-6 py-1">
            <div className="grid gap-4">
              {/* Image */}
              <div className="space-y-1.5">
                <Label>Image *</Label>
                {imagePreview ? (
                  <div className="relative overflow-hidden rounded-lg border border-gray-200 dark:border-slate-700">
                    <Image src={imagePreview} alt="aperçu" width={600} height={200} className="w-full max-h-36 object-cover" unoptimized />
                    <button type="button" onClick={() => dialogFileRef.current?.click()}
                      className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 hover:opacity-100 transition-opacity text-white text-sm font-medium gap-2">
                      <Camera className="h-4 w-4" /> Changer
                    </button>
                  </div>
                ) : (
                  <button type="button" onClick={() => dialogFileRef.current?.click()}
                    className="flex w-full flex-col items-center gap-2 rounded-lg border-2 border-dashed border-gray-300 dark:border-slate-600 py-8 text-gray-400 hover:border-primary-700 hover:text-primary-700 transition-colors">
                    <Camera className="h-6 w-6" />
                    <span className="text-sm">Cliquer pour ajouter l'image</span>
                  </button>
                )}
              </div>
              <div className="space-y-1.5">
                <Label>Titre *</Label>
                <Input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
              </div>
              <div className="space-y-1.5">
                <Label>URL de redirection</Label>
                <Input placeholder="https://..." value={form.redirect_url}
                  onChange={(e) => setForm({ ...form, redirect_url: e.target.value })} />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <Label>Position</Label>
                  <Input type="number" value={form.position} onChange={(e) => setForm({ ...form, position: e.target.value })} />
                </div>
                <div />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <Label>Date début</Label>
                  <Input type="datetime-local" value={form.start_date} onChange={(e) => setForm({ ...form, start_date: e.target.value })} />
                </div>
                <div className="space-y-1.5">
                  <Label>Date fin</Label>
                  <Input type="datetime-local" value={form.end_date} onChange={(e) => setForm({ ...form, end_date: e.target.value })} />
                </div>
              </div>
            </div>
          </div>
          <DialogFooter>
            <DialogClose asChild><Button variant="outline">Annuler</Button></DialogClose>
            <Button onClick={save} disabled={saving || !form.title}>{saving ? "Enregistrement…" : "Enregistrer"}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
