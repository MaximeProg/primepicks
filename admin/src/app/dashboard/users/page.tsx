"use client";
import { useEffect, useState, useCallback } from "react";
import { Search, Trash2 } from "lucide-react";
import { api, type AdminUser, type UserRole, type Paginated } from "@/lib/api";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Pagination } from "@/components/ui/pagination";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { fmtDate } from "@/lib/utils";
import { toast } from "sonner";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";

const roleBadge: Record<UserRole, { variant: "blue" | "orange" | "gray" | "green"; label: string }> = {
  SUPER_ADMIN: { variant: "orange", label: "Super Admin" },
  ADMIN:       { variant: "blue",   label: "Admin" },
  AFFILIATE:   { variant: "green",  label: "Affilié" },
  USER:        { variant: "gray",   label: "Utilisateur" },
};

const ROLE_OPTS = [
  { value: "", label: "Tous les rôles" },
  { value: "USER", label: "Utilisateur" },
  { value: "AFFILIATE", label: "Affilié" },
  { value: "ADMIN", label: "Admin" },
  { value: "SUPER_ADMIN", label: "Super Admin" },
];

const STATUS_OPTS = [
  { value: "", label: "Tous" },
  { value: "true", label: "Actifs" },
  { value: "false", label: "Bloqués" },
];

const LIMIT = 20;

export default function UsersPage() {
  const [data, setData] = useState<Paginated<AdminUser>>({ items: [], total: 0, limit: LIMIT, offset: 0 });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState("");
  const [activeFilter, setActiveFilter] = useState("");
  const [offset, setOffset] = useState(0);
  const [toDelete, setToDelete] = useState<AdminUser | null>(null);
  const [deleting, setDeleting] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    api.get<Paginated<AdminUser>>("/admin/users", {
      search: search || undefined,
      role: roleFilter || undefined,
      is_active: activeFilter !== "" ? activeFilter === "true" : undefined,
      limit: LIMIT,
      offset,
    })
      .then(setData)
      .finally(() => setLoading(false));
  }, [search, roleFilter, activeFilter, offset]);

  useEffect(() => { load(); }, [load]);
  useEffect(() => { setOffset(0); }, [search, roleFilter, activeFilter]);

  const changeRole = async (u: AdminUser, role: UserRole) => {
    try {
      await api.patch(`/admin/users/${u.id}`, { role });
      toast.success(`Rôle mis à jour`);
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    }
  };

  const toggleActive = async (u: AdminUser) => {
    try {
      await api.patch(`/admin/users/${u.id}`, { is_active: !u.is_active });
      toast.success(u.is_active ? "Compte désactivé" : "Compte activé");
      load();
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    }
  };

  const doDelete = async () => {
    if (!toDelete) return;
    setDeleting(true);
    try {
      await api.delete(`/admin/users/${toDelete.id}`);
      toast.success("Utilisateur supprimé");
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
    <ConfirmDialog
      open={!!toDelete}
      title="Supprimer l'utilisateur"
      description={`Supprimer définitivement « ${toDelete?.email ?? toDelete?.full_name ?? ""} » ? Cette action est irréversible.`}
      confirmLabel="Supprimer"
      variant="destructive"
      loading={deleting}
      onConfirm={doDelete}
      onCancel={() => setToDelete(null)}
    />
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-[200px] max-w-xs">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-gray-400 dark:text-slate-500" />
          <Input
            placeholder="Nom, email, téléphone…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-8"
          />
        </div>
        <Select value={roleFilter} onValueChange={setRoleFilter}>
          <SelectTrigger className="w-40">
            <SelectValue placeholder="Rôle" />
          </SelectTrigger>
          <SelectContent>
            {ROLE_OPTS.map((o) => <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>)}
          </SelectContent>
        </Select>
        <Select value={activeFilter} onValueChange={setActiveFilter}>
          <SelectTrigger className="w-32">
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
              <th className="th">Nom</th>
              <th className="th">Email</th>
              <th className="th">Rôle</th>
              <th className="th">Points</th>
              <th className="th">Statut</th>
              <th className="th">Inscrit le</th>
              <th className="th text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-slate-800">
            {loading ? (
              Array.from({ length: 8 }).map((_, i) => (
                <tr key={i}>{Array.from({ length: 6 }).map((_, j) => (
                  <td key={j} className="px-4 py-3">
                    <div className="h-4 w-24 animate-pulse rounded bg-gray-100 dark:bg-slate-700" />
                  </td>
                ))}</tr>
              ))
            ) : data.items.length === 0 ? (
              <tr>
                <td colSpan={6} className="py-12 text-center text-gray-400 dark:text-slate-500">
                  Aucun utilisateur trouvé
                </td>
              </tr>
            ) : data.items.map((u) => {
              const rb = roleBadge[u.role];
              return (
                <tr key={u.id} className="tr-hover">
                  <td className="td font-medium text-gray-900 dark:text-slate-100">
                    {u.full_name ?? <span className="text-gray-400 dark:text-slate-500">—</span>}
                  </td>
                  <td className="td text-gray-600 dark:text-slate-400">{u.email ?? "—"}</td>
                  <td className="td">
                    <Select value={u.role} onValueChange={(v) => changeRole(u, v as UserRole)}>
                      <SelectTrigger className="h-7 w-36 text-xs">
                        <SelectValue>
                          <Badge variant={rb.variant}>{rb.label}</Badge>
                        </SelectValue>
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="USER">Utilisateur</SelectItem>
                        <SelectItem value="AFFILIATE">Affilié</SelectItem>
                        <SelectItem value="ADMIN">Admin</SelectItem>
                        <SelectItem value="SUPER_ADMIN">Super Admin</SelectItem>
                      </SelectContent>
                    </Select>
                  </td>
                  <td className="td text-gray-600 dark:text-slate-400">
                    <span className="font-medium text-accent-500">{u.loyalty_points}</span> pts
                  </td>
                  <td className="td">
                    <button onClick={() => toggleActive(u)} title="Cliquer pour changer">
                      <Badge variant={u.is_active ? "green" : "red"}>
                        {u.is_active ? "Actif" : "Bloqué"}
                      </Badge>
                    </button>
                  </td>
                  <td className="td text-gray-500 dark:text-slate-400">{fmtDate(u.created_at)}</td>
                  <td className="td">
                    <div className="flex items-center justify-end gap-1">
                      <button onClick={() => setToDelete(u)} title="Supprimer"
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
