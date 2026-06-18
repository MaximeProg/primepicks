"use client";
import { useEffect, useState } from "react";
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid,
} from "recharts";
import {
  Users, UserCheck, Ticket, TrendingUp, Wallet, Star,
  TrendingDown, ArrowUpRight,
} from "lucide-react";
import { api, type OverviewStats, type MonthlyStats, type RevenueStats } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { fmtAmount } from "@/lib/utils";
import { useTheme } from "next-themes";

const MONTHS = ["Jan", "Fév", "Mar", "Avr", "Mai", "Jun", "Jul", "Aoû", "Sep", "Oct", "Nov", "Déc"];

function fmtMonth(str: string) {
  const [, m] = str.split("-");
  return MONTHS[parseInt(m) - 1] ?? str;
}

const C = {
  blue:   "#2563EB",
  orange: "#EA580C",
  green:  "#16A34A",
  red:    "#DC2626",
};

// ── Tooltip ───────────────────────────────────────────────────────────────────
function ChartTooltip({
  active, payload, label, fmt,
}: {
  active?: boolean;
  payload?: { value: number; name: string; color: string }[];
  label?: string;
  fmt?: (v: number, name: string) => string;
}) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2.5 shadow-xl text-xs space-y-1">
      {label && <p className="font-semibold text-slate-600 dark:text-slate-300 mb-1">{label}</p>}
      {payload.map((p) => (
        <div key={p.name} className="flex items-center gap-2">
          <span className="h-2 w-2 rounded-full flex-shrink-0" style={{ background: p.color }} />
          <span className="text-slate-500 dark:text-slate-400">{p.name}</span>
          <span className="ml-auto pl-4 font-semibold text-slate-800 dark:text-slate-100">
            {fmt ? fmt(p.value, p.name) : p.value}
          </span>
        </div>
      ))}
    </div>
  );
}

// ── KPI card ──────────────────────────────────────────────────────────────────
function KpiCard({
  icon: Icon, label, value, sub, trend, accent = false,
}: {
  icon: React.ElementType;
  label: string;
  value: string | number;
  sub?: string;
  trend?: "up" | "down";
  accent?: boolean;
}) {
  return (
    <Card className="relative overflow-hidden">
      {accent && (
        <div className="absolute inset-0 bg-gradient-to-br from-orange-50 to-orange-100/40 dark:from-orange-950/20 dark:to-orange-900/10 pointer-events-none" />
      )}
      <CardContent className="pt-5 pb-4">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-xs font-medium text-slate-500 dark:text-slate-400 mb-1.5">{label}</p>
            <p className={`text-2xl font-bold tracking-tight ${accent ? "text-orange-600 dark:text-orange-400" : "text-slate-800 dark:text-slate-100"}`}>
              {value}
            </p>
            {sub && (
              <p className="mt-1 flex items-center gap-1 text-xs text-slate-400 dark:text-slate-500">
                {trend === "up"   && <ArrowUpRight className="h-3 w-3 text-green-500" />}
                {trend === "down" && <TrendingDown className="h-3 w-3 text-red-400" />}
                {sub}
              </p>
            )}
          </div>
          <div className={`flex h-9 w-9 items-center justify-center rounded-xl ${
            accent ? "bg-orange-100 dark:bg-orange-900/30" : "bg-blue-50 dark:bg-blue-900/20"
          }`}>
            <Icon className={`h-4 w-4 ${accent ? "text-orange-600 dark:text-orange-400" : "text-blue-600 dark:text-blue-400"}`} />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
function Skeleton() {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
        {Array.from({ length: 6 }).map((_, i) => (
          <Card key={i}>
            <CardContent className="pt-5 pb-4">
              <div className="h-3 w-24 animate-pulse rounded bg-slate-100 dark:bg-slate-800 mb-3" />
              <div className="h-7 w-20 animate-pulse rounded bg-slate-100 dark:bg-slate-800" />
            </CardContent>
          </Card>
        ))}
      </div>
      <div className="grid gap-6 lg:grid-cols-5">
        <Card className="lg:col-span-3">
          <CardContent className="pt-5">
            <div className="h-56 animate-pulse rounded-lg bg-slate-100 dark:bg-slate-800" />
          </CardContent>
        </Card>
        <Card className="lg:col-span-2">
          <CardContent className="pt-5">
            <div className="h-56 animate-pulse rounded-lg bg-slate-100 dark:bg-slate-800" />
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

// ── Empty ─────────────────────────────────────────────────────────────────────
function EmptyChart({ label }: { label: string }) {
  return (
    <div className="flex h-52 flex-col items-center justify-center gap-2 text-slate-200 dark:text-slate-700">
      <TrendingUp className="h-10 w-10" />
      <p className="text-sm text-slate-400 dark:text-slate-500">{label}</p>
    </div>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────
export default function DashboardPage() {
  const [stats, setStats]     = useState<OverviewStats | null>(null);
  const [revenue, setRevenue] = useState<RevenueStats[]>([]);
  const [coupons, setCoupons] = useState<MonthlyStats[]>([]);
  const [loading, setLoading] = useState(true);
  const { resolvedTheme }     = useTheme();

  const dark      = resolvedTheme === "dark";
  const gridColor = dark ? "#1e293b" : "#f1f5f9";
  const axisColor = dark ? "#64748b" : "#94a3b8";

  useEffect(() => {
    Promise.all([
      api.get<OverviewStats>("/admin/stats/overview"),
      api.get<RevenueStats[]>("/admin/stats/revenue/monthly"),
      api.get<MonthlyStats[]>("/admin/stats/coupons/monthly"),
    ])
      .then(([s, r, c]) => {
        setStats(s);
        setRevenue(r.map((x) => ({ ...x, period: fmtMonth(x.period) })));
        setCoupons(c.map((x) => ({ ...x, month: fmtMonth(x.month) })));
      })
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <Skeleton />;

  const donutData = [
    { name: "Gagnés",    value: stats?.win_rate ?? 0,          fill: C.green },
    { name: "Autres",    value: 100 - (stats?.win_rate ?? 0),  fill: dark ? "#1e293b" : "#e2e8f0" },
  ];

  return (
    <div className="space-y-6">

      {/* KPI */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
        <KpiCard icon={Users}     label="Utilisateurs"     value={stats?.total_users ?? 0}
          sub={`+${stats?.new_users_this_month ?? 0} ce mois`} trend="up" />
        <KpiCard icon={UserCheck} label="Abonnés actifs"   value={stats?.active_subscribers ?? 0} />
        <KpiCard icon={Ticket}    label="Coupons publiés"  value={stats?.total_coupons ?? 0} />
        <KpiCard icon={Star}      label="Taux de victoire" value={`${stats?.win_rate ?? 0}%`} />
        <KpiCard icon={Wallet}    label="Revenus totaux"   value={fmtAmount(stats?.total_revenue ?? 0)}  accent />
        <KpiCard icon={TrendingUp} label="Revenus ce mois" value={fmtAmount(stats?.revenue_this_month ?? 0)}
          sub="Paiements validés" trend="up" accent />
      </div>

      {/* Revenus + Donut */}
      <div className="grid gap-6 lg:grid-cols-5">

        {/* Area revenus */}
        <Card className="lg:col-span-3">
          <CardHeader className="pb-0">
            <CardTitle className="text-sm font-semibold text-slate-700 dark:text-slate-200">
              Revenus mensuels
            </CardTitle>
            <p className="text-xs text-slate-400 dark:text-slate-500">Paiements confirmés (XOF)</p>
          </CardHeader>
          <CardContent className="pt-4">
            {revenue.length === 0 ? (
              <EmptyChart label="Aucune transaction confirmée cette année" />
            ) : (
              <ResponsiveContainer width="100%" height={210}>
                <AreaChart data={revenue} margin={{ top: 6, right: 6, left: -10, bottom: 0 }}>
                  <defs>
                    <linearGradient id="revGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%"  stopColor={C.orange} stopOpacity={0.18} />
                      <stop offset="95%" stopColor={C.orange} stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid stroke={gridColor} strokeDasharray="4 4" vertical={false} />
                  <XAxis dataKey="period" tick={{ fontSize: 11, fill: axisColor }} axisLine={false} tickLine={false} />
                  <YAxis
                    tick={{ fontSize: 11, fill: axisColor }} axisLine={false} tickLine={false}
                    tickFormatter={(v) => v >= 1000 ? `${(v / 1000).toFixed(0)}k` : String(v)}
                  />
                  <Tooltip
                    content={<ChartTooltip fmt={(v) => fmtAmount(v)} />}
                    cursor={{ stroke: C.orange, strokeWidth: 1, strokeDasharray: "4 4" }}
                  />
                  <Area
                    dataKey="amount" name="Revenus"
                    stroke={C.orange} strokeWidth={2.5}
                    fill="url(#revGrad)" dot={false}
                    activeDot={{ r: 5, fill: C.orange, stroke: "white", strokeWidth: 2 }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        {/* Donut win rate */}
        <Card className="lg:col-span-2">
          <CardHeader className="pb-0">
            <CardTitle className="text-sm font-semibold text-slate-700 dark:text-slate-200">
              Taux de victoire
            </CardTitle>
            <p className="text-xs text-slate-400 dark:text-slate-500">Coupons résolus cette saison</p>
          </CardHeader>
          <CardContent className="flex flex-col items-center justify-center pt-2 pb-5">
            {(stats?.total_coupons ?? 0) === 0 ? (
              <EmptyChart label="Aucun coupon résolu" />
            ) : (
              <>
                <div className="relative w-[180px] h-[180px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={donutData}
                        cx="50%" cy="50%"
                        innerRadius={60} outerRadius={80}
                        startAngle={90} endAngle={-270}
                        dataKey="value" strokeWidth={0}
                      >
                        {donutData.map((d, i) => <Cell key={i} fill={d.fill} />)}
                      </Pie>
                    </PieChart>
                  </ResponsiveContainer>
                  <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                    <span className="text-3xl font-bold text-slate-800 dark:text-slate-100">
                      {stats?.win_rate ?? 0}%
                    </span>
                    <span className="text-[11px] text-slate-400 dark:text-slate-500 mt-0.5">win rate</span>
                  </div>
                </div>
                <div className="mt-2 flex gap-5">
                  <div className="flex items-center gap-1.5 text-xs text-slate-500 dark:text-slate-400">
                    <span className="h-2.5 w-2.5 rounded-full" style={{ background: C.green }} />
                    Gagnés
                  </div>
                  <div className="flex items-center gap-1.5 text-xs text-slate-500 dark:text-slate-400">
                    <span className="h-2.5 w-2.5 rounded-full bg-slate-200 dark:bg-slate-700" />
                    Autres
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Coupons par mois */}
      <Card>
        <CardHeader className="pb-0">
          <CardTitle className="text-sm font-semibold text-slate-700 dark:text-slate-200">
            Résultats des coupons par mois
          </CardTitle>
          <p className="text-xs text-slate-400 dark:text-slate-500">
            Gagnés vs perdus — {new Date().getFullYear()}
          </p>
        </CardHeader>
        <CardContent className="pt-4">
          {coupons.length === 0 ? (
            <EmptyChart label="Aucun coupon publié cette année" />
          ) : (
            <ResponsiveContainer width="100%" height={220}>
              <BarChart
                data={coupons}
                barSize={16} barCategoryGap="35%" barGap={3}
                margin={{ top: 6, right: 6, left: -10, bottom: 0 }}
              >
                <CartesianGrid stroke={gridColor} strokeDasharray="4 4" vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: axisColor }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fill: axisColor }} axisLine={false} tickLine={false} allowDecimals={false} />
                <Tooltip
                  content={<ChartTooltip />}
                  cursor={{ fill: dark ? "rgba(255,255,255,0.03)" : "rgba(0,0,0,0.03)", radius: 6 }}
                />
                <Bar dataKey="won"  name="Gagnés" fill={C.green} radius={[4, 4, 0, 0]} />
                <Bar dataKey="lost" name="Perdus" fill={C.red}   radius={[4, 4, 0, 0]} opacity={0.75} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </CardContent>
      </Card>

    </div>
  );
}
