import { auth } from "./firebase";

const BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";

async function token(): Promise<string> {
  const user = auth.currentUser;
  if (!user) throw new Error("Non authentifié");
  return user.getIdToken();
}

type Params = Record<string, string | number | boolean | undefined | null>;

function buildUrl(path: string, params?: Params): string {
  if (!params) return path;
  const q = Object.entries(params)
    .filter(([, v]) => v !== undefined && v !== null && v !== "")
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
    .join("&");
  return q ? `${path}?${q}` : path;
}

async function req<T>(method: string, path: string, body?: unknown): Promise<T> {
  const t = await token();
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${t}`,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(err.detail ?? "Erreur serveur");
  }
  if (res.status === 204) return undefined as T;
  return res.json();
}

export const api = {
  get: <T>(path: string, params?: Params) => req<T>("GET", buildUrl(path, params)),
  post: <T>(path: string, body?: unknown) => req<T>("POST", path, body),
  patch: <T>(path: string, body: unknown) => req<T>("PATCH", path, body),
  delete: <T>(path: string) => req<T>("DELETE", path),

  async upload<T>(path: string, file: File, field = "file"): Promise<T> {
    const t = await token();
    const form = new FormData();
    form.append(field, file);
    const res = await fetch(`${BASE}${path}`, {
      method: "POST",
      headers: { Authorization: `Bearer ${t}` },
      body: form,
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: res.statusText }));
      throw new Error(err.detail ?? "Erreur serveur");
    }
    return res.json();
  },

  async csv(path: string): Promise<string> {
    const t = await token();
    const res = await fetch(`${BASE}${path}`, {
      headers: { Authorization: `Bearer ${t}` },
    });
    return res.text();
  },
};

// ── Generic types ──────────────────────────────────────────────────────────

export interface Paginated<T> {
  items: T[];
  total: number;
  limit: number;
  offset: number;
}

// ── Domain types ──────────────────────────────────────────────────────────

export type UserRole = "SUPER_ADMIN" | "ADMIN" | "AFFILIATE" | "USER";

export interface AdminUser {
  id: string;
  email: string | null;
  full_name: string | null;
  phone: string | null;
  role: UserRole;
  referral_code: string;
  loyalty_points: number;
  is_active: boolean;
  created_at: string;
}

export interface Plan {
  id: string;
  name: string;
  slug: string;
  price: number;
  duration_days: number;
  description: string | null;
  loyalty_points_reward: number;
  is_active: boolean;
  created_at: string;
}

export type CouponStatus = "PENDING" | "WON" | "LOST" | "CANCELLED";
export type CouponType = "FREE" | "PREMIUM" | "VIP";

export interface CouponMatch {
  id: string;
  coupon_id: string;
  match_name: string;
  prediction: string;
  odd: number | null;
  created_at: string;
}

export interface Coupon {
  id: string;
  title: string;
  description: string | null;
  analysis: string | null;
  odds: number | null;
  bookmaker_code: string | null;
  valid_until: string | null;
  status: CouponStatus;
  coupon_type: CouponType;
  confidence_level: number | null;
  is_published: boolean;
  published_at: string | null;
  image_url: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
  matches: CouponMatch[];
}

export type SubStatus = "PENDING" | "ACTIVE" | "EXPIRED" | "CANCELLED";

export interface Subscription {
  id: string;
  user_id: string;
  plan_id: string;
  status: SubStatus;
  start_date: string | null;
  end_date: string | null;
  auto_renew: boolean;
  created_at: string;
  plan: Plan | null;
}

export type TxStatus = "PENDING" | "PAID" | "FAILED" | "REFUNDED";

export interface Transaction {
  id: string;
  user_id: string;
  plan_id: string | null;
  amount: number;
  currency: string;
  status: TxStatus;
  fedapay_id: string | null;
  payment_url: string | null;
  paid_at: string | null;
  created_at: string;
}

export interface OverviewStats {
  total_users: number;
  active_subscribers: number;
  new_users_this_month: number;
  total_revenue: number;
  revenue_this_month: number;
  total_coupons: number;
  win_rate: number;
}

export interface MonthlyStats {
  month: string;
  total: number;
  won: number;
  lost: number;
  win_rate: number;
}

export interface RevenueStats {
  period: string;
  amount: number;
  transactions_count: number;
}

export interface NotificationLog {
  id: string;
  user_id: string | null;
  title: string;
  body: string;
  type: string;
  success_count: number;
  failure_count: number;
}

export interface Banner {
  id: string;
  title: string;
  image_url: string;
  redirect_url: string | null;
  position: number;
  is_active: boolean;
  start_date: string | null;
  end_date: string | null;
  created_at: string;
}

export interface AppSetting {
  id: string;
  platform_name: string;
  logo_url: string | null;
  favicon_url: string | null;
  support_email: string | null;
  support_phone: string | null;
  telegram_url: string | null;
  whatsapp_url: string | null;
  facebook_url: string | null;
  instagram_url: string | null;
  maintenance_mode: boolean;
  updated_at: string;
}

export type TicketStatus = "OPEN" | "IN_PROGRESS" | "CLOSED";

export interface SupportTicket {
  id: string;
  user_id: string;
  subject: string;
  message: string;
  status: TicketStatus;
  admin_reply: string | null;
  created_at: string;
  updated_at: string;
}

export interface AdminLog {
  id: string;
  admin_id: string | null;
  action: string;
  entity_type: string | null;
  entity_id: string | null;
  old_data: Record<string, unknown> | null;
  new_data: Record<string, unknown> | null;
  created_at: string;
}

export type PayoutStatus = "PENDING" | "APPROVED" | "PAID" | "REJECTED";

export interface AffiliatePayout {
  id: string;
  affiliate_id: string;
  amount: number;
  status: PayoutStatus;
  requested_at: string;
  paid_at: string | null;
}

export interface NotificationInboxItem {
  id: string;
  title: string;
  body: string;
  type: string;
  data: Record<string, unknown> | null;
  is_read: boolean;
  created_at: string;
}

export interface UnreadCount {
  count: number;
}

export type NotifTarget = "subscribers" | "all_users" | "admins" | "custom";

