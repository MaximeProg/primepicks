import { ChevronLeft, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";

interface PaginationProps {
  total: number;
  limit: number;
  offset: number;
  onChange: (offset: number) => void;
  className?: string;
}

export function Pagination({ total, limit, offset, onChange, className }: PaginationProps) {
  const totalPages = Math.ceil(total / limit);
  const currentPage = Math.floor(offset / limit) + 1;

  if (totalPages <= 1 && total > 0) return (
    <div className={cn("flex items-center justify-end border-t border-gray-200 dark:border-slate-800 px-4 py-2.5", className)}>
      <p className="text-xs text-gray-400 dark:text-slate-500">{total} résultat{total > 1 ? "s" : ""}</p>
    </div>
  );

  if (totalPages <= 1) return null;

  return (
    <div className={cn("flex items-center justify-between border-t border-gray-200 dark:border-slate-800 px-4 py-2.5", className)}>
      <p className="text-xs text-gray-500 dark:text-slate-400">
        {total === 0 ? "0" : `${offset + 1}–${Math.min(offset + limit, total)}`}
        {" "}sur{" "}{total}
      </p>
      <div className="flex items-center gap-1">
        <button
          onClick={() => onChange(Math.max(0, offset - limit))}
          disabled={currentPage === 1}
          className="flex h-7 w-7 items-center justify-center rounded border border-gray-200 dark:border-slate-700 text-gray-500 dark:text-slate-400 hover:bg-gray-50 dark:hover:bg-slate-800 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
        >
          <ChevronLeft className="h-3.5 w-3.5" />
        </button>
        <span className="px-2 text-xs font-medium text-gray-700 dark:text-slate-300">
          {currentPage} / {totalPages}
        </span>
        <button
          onClick={() => onChange(offset + limit)}
          disabled={currentPage === totalPages}
          className="flex h-7 w-7 items-center justify-center rounded border border-gray-200 dark:border-slate-700 text-gray-500 dark:text-slate-400 hover:bg-gray-50 dark:hover:bg-slate-800 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
        >
          <ChevronRight className="h-3.5 w-3.5" />
        </button>
      </div>
    </div>
  );
}
