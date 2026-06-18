"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard,
  Ticket,
  Package,
  Users,
  CreditCard,
  CalendarCheck,
  Image,
  Bell,
  Headphones,
  History,
  Banknote,
} from "lucide-react";

const navMain = [
  { href: "/dashboard", label: "Vue d'ensemble", icon: LayoutDashboard, exact: true },
  { href: "/dashboard/coupons", label: "Coupons", icon: Ticket },
  { href: "/dashboard/plans", label: "Plans", icon: Package },
  { href: "/dashboard/users", label: "Utilisateurs", icon: Users },
  { href: "/dashboard/transactions", label: "Paiements", icon: CreditCard },
  { href: "/dashboard/subscriptions", label: "Abonnements", icon: CalendarCheck },
];

const navMarketing = [
  { href: "/dashboard/banners",       label: "Bannières",      icon: Image },
  { href: "/dashboard/notifications", label: "Notifications",  icon: Bell },
];

const navAdmin = [
  { href: "/dashboard/support", label: "Support", icon: Headphones },
  { href: "/dashboard/payouts", label: "Retraits affiliés", icon: Banknote },
  { href: "/dashboard/logs", label: "Historique admin", icon: History },
];


export function Sidebar() {
  const pathname = usePathname();

  const isActive = (href: string, exact?: boolean) =>
    exact ? pathname === href : pathname.startsWith(href);

  const navItem = (href: string, label: string, Icon: React.ElementType, exact?: boolean) => {
    const active = isActive(href, exact);
    return (
      <li key={href}>
        <Link
          href={href}
          className={cn(
            "flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition-colors",
            active
              ? "bg-primary-50 dark:bg-primary-900/20 text-primary-700 dark:text-primary-400"
              : "text-gray-600 dark:text-slate-400 hover:bg-gray-50 dark:hover:bg-slate-800 hover:text-gray-900 dark:hover:text-slate-100"
          )}
        >
          <Icon
            className={cn(
              "h-4 w-4 shrink-0",
              active ? "text-primary-700 dark:text-primary-400" : "text-gray-400 dark:text-slate-500"
            )}
          />
          {label}
          {active && (
            <span className="ml-auto h-1.5 w-1.5 rounded-full bg-primary-700 dark:bg-primary-400" />
          )}
        </Link>
      </li>
    );
  };

  const sectionLabel = (text: string) => (
    <p className="mb-1 mt-4 px-6 text-[10px] font-semibold uppercase tracking-widest text-gray-400 dark:text-slate-600">
      {text}
    </p>
  );

  return (
    <aside className="flex h-full w-60 flex-col border-r border-gray-200 dark:border-slate-800 bg-white dark:bg-slate-950">
      {/* Logo */}
      <div className="flex h-16 items-center border-b border-gray-200 dark:border-slate-800 px-5">
        <span className="text-lg font-bold text-primary-700">Coupons</span>
        <span className="ml-1 text-lg font-bold text-accent-500">Admin</span>
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto py-4">
        {sectionLabel("Navigation")}
        <ul className="space-y-0.5 px-3">
          {navMain.map(({ href, label, icon, exact }) => navItem(href, label, icon, exact))}
        </ul>

        {sectionLabel("Marketing")}
        <ul className="space-y-0.5 px-3">
          {navMarketing.map(({ href, label, icon }) => navItem(href, label, icon))}
        </ul>

        {sectionLabel("Administration")}
        <ul className="space-y-0.5 px-3">
          {navAdmin.map(({ href, label, icon }) => navItem(href, label, icon))}
        </ul>
      </nav>
    </aside>
  );
}
