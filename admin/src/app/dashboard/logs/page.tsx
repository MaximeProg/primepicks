"use client";
import { useEffect, useState, useCallback } from "react";
import { api, type AdminLog, type Paginated } from "@/lib/api";
import { Input } from "@/components/ui/input";
import { Pagination } from "@/components/ui/pagination";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogClose } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Search, Eye } from "lucide-react";
import { fmt } from "@/lib/utils";

const LIMIT = 30;

export default function LogsPage() {
  const [data, setData] = useState<Paginated<AdminLog>>({ items: [], total: 0, limit: LIMIT, offset: 0 });
  const [loading, setLoading] = useState(true);
  const [offset, setOffset] = useState(0);
  const [search, setSearch] = useState("");
  const [detail, setDetail] = useState<AdminLog | null>(null);

  const load = useCallback(() => {
    setLoading(true);
    api.get<Paginated<AdminLog>>("/admin/logs", {
      action: search || undefined,
      limit: LIMIT,
      offset,
    }).then(setData).finally(() => setLoading(false));
  }, [search, offset]);

  useEffect(() => { load(); }, [load]);
  useEffect(() => { setOffset(0); }, [search]);

  return (
    <>
      <Dialog open={!!detail} onOpenChange={(v) => { if (!v) setDetail(null); }}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Détails — {detail?.action}</DialogTitle>
          </DialogHeader>
          <div className="flex-1 overflow-y-auto -mx-6 px-6 py-1 space-y-3">
            <div className="text-sm text-gray-500 dark:text-slate-400">
              <span className="font-medium text-gray-700 dark:text-slate-300">Entité : </span>
              {detail?.entity_type} #{detail?.entity_id}
            </div>
            {detail?.old_data && (
              <div className="space-y-1">
                <p className="text-xs font-semibold uppercase tracking-wide text-gray-400">Avant</p>
                <pre className="rounded-lg bg-red-50 dark:bg-red-900/10 text-red-800 dark:text-red-300 p-3 text-xs overflow-auto">
                  {JSON.stringify(detail.old_data, null, 2)}
                </pre>
              </div>
            )}
            {detail?.new_data && (
              <div className="space-y-1">
                <p className="text-xs font-semibold uppercase tracking-wide text-gray-400">Après</p>
                <pre className="rounded-lg bg-green-50 dark:bg-green-900/10 text-green-800 dark:text-green-300 p-3 text-xs overflow-auto">
                  {JSON.stringify(detail.new_data, null, 2)}
                </pre>
              </div>
            )}
          </div>
          <div className="shrink-0 flex justify-end pt-2">
            <DialogClose asChild><Button variant="outline">Fermer</Button></DialogClose>
          </div>
        </DialogContent>
      </Dialog>

      <div className="space-y-4">
        <div className="flex flex-wrap items-center gap-2">
          <div className="relative max-w-xs flex-1">
            <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-gray-400" />
            <Input placeholder="Filtrer par action…" value={search}
              onChange={(e) => setSearch(e.target.value)} className="pl-8" />
          </div>
          <span className="text-sm text-gray-500 dark:text-slate-400">{data.total} entrée(s)</span>
        </div>

        <div className="table-wrapper">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 dark:border-slate-800 bg-gray-50 dark:bg-slate-800/50 text-left">
                <th className="th">Action</th>
                <th className="th">Entité</th>
                <th className="th">Admin</th>
                <th className="th">Date</th>
                <th className="th text-right">Détails</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-slate-800">
              {loading ? (
                Array.from({ length: 8 }).map((_, i) => (
                  <tr key={i}>{Array.from({ length: 5 }).map((_, j) => (
                    <td key={j} className="px-4 py-3"><div className="h-4 w-24 animate-pulse rounded bg-gray-100 dark:bg-slate-700" /></td>
                  ))}</tr>
                ))
              ) : data.items.length === 0 ? (
                <tr><td colSpan={5} className="py-12 text-center text-gray-400 dark:text-slate-500">Aucun log</td></tr>
              ) : data.items.map((log) => (
                <tr key={log.id} className="tr-hover">
                  <td className="td">
                    <span className="inline-flex items-center rounded-full bg-primary-50 dark:bg-primary-900/20 px-2 py-0.5 text-xs font-medium text-primary-700 dark:text-primary-400">
                      {log.action}
                    </span>
                  </td>
                  <td className="td text-gray-500 dark:text-slate-400">
                    {log.entity_type && <span>{log.entity_type}</span>}
                    {log.entity_id && <span className="block text-xs opacity-60">#{log.entity_id.slice(0, 8)}</span>}
                  </td>
                  <td className="td text-gray-500 dark:text-slate-400 text-xs">
                    {log.admin_id ? log.admin_id.slice(0, 8) + "…" : "—"}
                  </td>
                  <td className="td text-gray-500 dark:text-slate-400">{fmt(log.created_at)}</td>
                  <td className="td">
                    <div className="flex justify-end">
                      {(log.old_data || log.new_data) && (
                        <button onClick={() => setDetail(log)}
                          className="rounded p-1.5 text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 hover:text-gray-700 dark:hover:text-slate-300 transition-colors">
                          <Eye className="h-4 w-4" />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <Pagination total={data.total} limit={LIMIT} offset={offset} onChange={setOffset} />
        </div>
      </div>
    </>
  );
}
