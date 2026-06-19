"use client";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { useAuth } from "@/contexts/auth-context";
import {
  Menu, UserCircle, Settings, LogOut, ChevronDown,
  Bell, CheckCheck, Trash2, X,
} from "lucide-react";
import { ThemeToggle } from "@/components/theme/theme-toggle";
import { useNotifications } from "@/hooks/useNotifications";
import { fmt } from "@/lib/utils";

const titles: Record<string, string> = {
  "/dashboard":                "Vue d'ensemble",
  "/dashboard/coupons":        "Coupons",
  "/dashboard/plans":          "Plans",
  "/dashboard/users":          "Utilisateurs",
  "/dashboard/transactions":   "Paiements",
  "/dashboard/subscriptions":  "Abonnements",
  "/dashboard/banners":        "Bannières",
  "/dashboard/notifications":  "Notifications",
  "/dashboard/support":        "Support client",
  "/dashboard/payouts":        "Retraits affiliés",
  "/dashboard/logs":           "Historique admin",
  "/dashboard/profile":        "Mon profil",
  "/dashboard/settings":       "Paramètres",
};

// Icône par type de notification
const TYPE_ICONS: Record<string, string> = {
  NEW_COUPON:      "🎟️",
  COUPON_WON:      "🏆",
  COUPON_LOST:     "❌",
  COUPON_CANCELLED:"🚫",
  SUB_ACTIVATED:   "✅",
  SUB_EXPIRY_D3:   "⏰",
  SUB_EXPIRY_D1:   "⚠️",
  SUB_EXPIRED:     "💤",
  PAYMENT_SUCCESS: "💳",
  PROMO:           "📢",
  ROLE_CHANGED:    "🔑",
  PAYOUT_APPROVED: "💰",
  TICKET_REPLIED:  "💬",
};

interface HeaderProps {
  onMenuClick?: () => void;
}

export function Header({ onMenuClick }: HeaderProps) {
  const pathname = usePathname();
  const router   = useRouter();
  const { user, logout } = useAuth();
  const title = titles[pathname] ?? "Admin";

  const [profileOpen, setProfileOpen] = useState(false);
  const [bellOpen, setBellOpen]       = useState(false);
  const profileRef = useRef<HTMLDivElement>(null);
  const bellRef    = useRef<HTMLDivElement>(null);

  const notif = useNotifications(!!user);

  // Fermer les dropdowns au clic extérieur
  useEffect(() => {
    const handle = (e: MouseEvent) => {
      if (profileRef.current && !profileRef.current.contains(e.target as Node)) setProfileOpen(false);
      if (bellRef.current    && !bellRef.current.contains(e.target as Node))    setBellOpen(false);
    };
    document.addEventListener("mousedown", handle);
    return () => document.removeEventListener("mousedown", handle);
  }, []);

  const handleLogout = async () => {
    setProfileOpen(false);
    await logout();
    router.push("/login");
  };

  const initial = user?.email?.[0]?.toUpperCase() ?? "A";

  return (
    <header className="flex h-16 items-center justify-between border-b border-gray-200 dark:border-slate-800 bg-white dark:bg-slate-950 px-6">
      <div className="flex items-center gap-4">
        <button
          onClick={onMenuClick}
          className="rounded-md p-1.5 text-gray-500 dark:text-slate-400 hover:bg-gray-100 dark:hover:bg-slate-800 lg:hidden"
        >
          <Menu className="h-5 w-5" />
        </button>
        <h1 className="text-base font-semibold text-gray-900 dark:text-slate-100">{title}</h1>
      </div>

      <div className="flex items-center gap-1.5">
        <ThemeToggle />

        {/* ── Cloche ── */}
        <div ref={bellRef} className="relative">
          <button
            onClick={() => { setBellOpen((v) => !v); setProfileOpen(false); }}
            className="relative flex h-9 w-9 items-center justify-center rounded-md text-gray-500 dark:text-slate-400 hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors"
            title="Notifications"
          >
            <Bell className="h-5 w-5" />
            {notif.unread > 0 && (
              <span className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white leading-none">
                {notif.unread > 99 ? "99+" : notif.unread}
              </span>
            )}
          </button>

          {bellOpen && (
            <div className="absolute right-0 top-full mt-1.5 w-[min(320px,calc(100vw-1rem))] rounded-xl border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-xl z-50 overflow-hidden flex flex-col max-h-[480px]">
              {/* Header panel */}
              <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 dark:border-slate-800">
                <span className="text-sm font-semibold text-gray-800 dark:text-slate-100">
                  Notifications {notif.unread > 0 && <span className="ml-1 text-red-500">({notif.unread})</span>}
                </span>
                <div className="flex items-center gap-1">
                  {notif.unread > 0 && (
                    <button
                      onClick={notif.markAllRead}
                      title="Tout marquer comme lu"
                      className="rounded p-1 text-gray-400 hover:text-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors"
                    >
                      <CheckCheck className="h-4 w-4" />
                    </button>
                  )}
                  {notif.items.length > 0 && (
                    <button
                      onClick={notif.clearAll}
                      title="Tout supprimer"
                      className="rounded p-1 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  )}
                  <button
                    onClick={() => setBellOpen(false)}
                    className="rounded p-1 text-gray-400 hover:text-gray-600 dark:hover:text-slate-300 hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Liste */}
              <div className="overflow-y-auto flex-1">
                {notif.loading && notif.items.length === 0 ? (
                  <div className="py-8 text-center text-sm text-gray-400 dark:text-slate-500">Chargement…</div>
                ) : notif.items.length === 0 ? (
                  <div className="py-10 text-center">
                    <Bell className="mx-auto h-8 w-8 text-gray-200 dark:text-slate-700 mb-2" />
                    <p className="text-sm text-gray-400 dark:text-slate-500">Aucune notification</p>
                  </div>
                ) : (
                  notif.items.map((n) => (
                    <div
                      key={n.id}
                      onClick={() => !n.is_read && notif.markRead(n.id)}
                      className={`flex gap-3 px-4 py-3 border-b border-gray-50 dark:border-slate-800 cursor-pointer transition-colors
                        ${n.is_read
                          ? "bg-white dark:bg-slate-900"
                          : "bg-blue-50/60 dark:bg-blue-900/10 hover:bg-blue-50 dark:hover:bg-blue-900/20"
                        }`}
                    >
                      <span className="text-lg mt-0.5 shrink-0">{TYPE_ICONS[n.type] ?? "🔔"}</span>
                      <div className="flex-1 min-w-0">
                        <p className={`text-xs font-medium truncate ${n.is_read ? "text-gray-600 dark:text-slate-400" : "text-gray-900 dark:text-slate-100"}`}>
                          {n.title}
                        </p>
                        <p className="text-xs text-gray-500 dark:text-slate-500 line-clamp-2 mt-0.5">{n.body}</p>
                        <p className="text-[10px] text-gray-400 dark:text-slate-600 mt-1">{fmt(n.created_at)}</p>
                      </div>
                      <button
                        onClick={(e) => { e.stopPropagation(); notif.remove(n.id); }}
                        className="shrink-0 rounded p-0.5 text-gray-300 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors self-start mt-0.5"
                      >
                        <X className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  ))
                )}
              </div>

              {/* Footer */}
              <div className="border-t border-gray-100 dark:border-slate-800 px-4 py-2.5">
                <Link
                  href="/dashboard/notifications"
                  onClick={() => setBellOpen(false)}
                  className="text-xs font-medium text-blue-600 dark:text-blue-400 hover:underline"
                >
                  Gérer les notifications →
                </Link>
              </div>
            </div>
          )}
        </div>

        {/* ── Profil ── */}
        <div ref={profileRef} className="relative">
          <button
            onClick={() => { setProfileOpen((v) => !v); setBellOpen(false); }}
            className="flex items-center gap-2 rounded-md px-2 py-1.5 hover:bg-gray-50 dark:hover:bg-slate-800 transition-colors"
          >
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary-700 text-xs font-semibold text-white shrink-0">
              {initial}
            </div>
            <span className="hidden text-sm text-gray-600 dark:text-slate-400 sm:block max-w-[120px] truncate">
              {user?.email ?? "Admin"}
            </span>
            <ChevronDown className={`h-3.5 w-3.5 text-gray-400 transition-transform ${profileOpen ? "rotate-180" : ""}`} />
          </button>

          {profileOpen && (
            <div className="absolute right-0 top-full mt-1.5 w-52 rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-lg z-50 overflow-hidden">
              <div className="border-b border-gray-100 dark:border-slate-800 px-4 py-2.5">
                <p className="text-xs font-medium text-gray-900 dark:text-slate-100 truncate">{user?.email ?? "Admin"}</p>
                <p className="text-xs text-gray-400 dark:text-slate-500">Administrateur</p>
              </div>
              <div className="py-1">
                <Link href="/dashboard/profile" onClick={() => setProfileOpen(false)}
                  className="flex items-center gap-2.5 px-4 py-2 text-sm text-gray-700 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-800 transition-colors">
                  <UserCircle className="h-4 w-4 text-gray-400 dark:text-slate-500" />
                  Mon profil
                </Link>
                <Link href="/dashboard/settings" onClick={() => setProfileOpen(false)}
                  className="flex items-center gap-2.5 px-4 py-2 text-sm text-gray-700 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-800 transition-colors">
                  <Settings className="h-4 w-4 text-gray-400 dark:text-slate-500" />
                  Paramètres
                </Link>
              </div>
              <div className="border-t border-gray-100 dark:border-slate-800 py-1">
                <button onClick={handleLogout}
                  className="flex w-full items-center gap-2.5 px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors">
                  <LogOut className="h-4 w-4" />
                  Déconnexion
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
