"use client";
import { useEffect, useState } from "react";
import { api, type AdminUser } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { useAuth } from "@/contexts/auth-context";
import { User, Mail, Phone, Award, Copy, Shield } from "lucide-react";

const roleLabel: Record<string, { label: string; variant: "blue" | "orange" | "gray" | "green" }> = {
  SUPER_ADMIN: { label: "Super Admin", variant: "orange" },
  ADMIN:       { label: "Admin",       variant: "blue" },
  AFFILIATE:   { label: "Affilié",     variant: "green" },
  USER:        { label: "Utilisateur", variant: "gray" },
};

export default function ProfilePage() {
  const { user: firebaseUser } = useAuth();
  const [profile, setProfile] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({ full_name: "", phone: "" });

  useEffect(() => {
    api.get<AdminUser>("/users/me")
      .then((p) => {
        setProfile(p);
        setForm({ full_name: p.full_name ?? "", phone: p.phone ?? "" });
      })
      .finally(() => setLoading(false));
  }, []);

  const save = async () => {
    setSaving(true);
    try {
      const updated = await api.patch<AdminUser>("/users/me", {
        full_name: form.full_name || undefined,
        phone: form.phone || undefined,
      });
      setProfile(updated);
      toast.success("Profil mis à jour");
    } catch (e: unknown) {
      toast.error(e instanceof Error ? e.message : "Erreur");
    } finally {
      setSaving(false);
    }
  };

  const copyCode = () => {
    if (profile?.referral_code) {
      navigator.clipboard.writeText(profile.referral_code);
      toast.success("Code copié !");
    }
  };

  if (loading) {
    return (
      <div className="max-w-2xl space-y-4">
        {[1, 2].map((i) => (
          <Card key={i}>
            <CardHeader><div className="h-4 w-32 animate-pulse rounded bg-gray-100 dark:bg-slate-700" /></CardHeader>
            <CardContent><div className="h-24 animate-pulse rounded bg-gray-100 dark:bg-slate-700" /></CardContent>
          </Card>
        ))}
      </div>
    );
  }

  const role = roleLabel[profile?.role ?? "USER"];

  return (
    <div className="max-w-2xl space-y-4">
      {/* Carte identité */}
      <Card>
        <CardHeader>
          <CardTitle>Informations du compte</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center gap-4">
            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-primary-700 text-xl font-bold text-white">
              {(profile?.full_name ?? firebaseUser?.email ?? "A")[0].toUpperCase()}
            </div>
            <div>
              <p className="font-semibold text-gray-900 dark:text-slate-100">
                {profile?.full_name ?? "—"}
              </p>
              <div className="flex items-center gap-2 mt-1">
                <Badge variant={role.variant}><Shield className="mr-1 h-3 w-3" />{role.label}</Badge>
                <Badge variant={profile?.is_active ? "green" : "red"}>
                  {profile?.is_active ? "Actif" : "Inactif"}
                </Badge>
              </div>
            </div>
          </div>

          <div className="grid gap-3 pt-2">
            <div className="flex items-center gap-3 text-sm">
              <Mail className="h-4 w-4 text-gray-400 dark:text-slate-500 shrink-0" />
              <span className="text-gray-500 dark:text-slate-400 w-20">Email</span>
              <span className="text-gray-900 dark:text-slate-100">{firebaseUser?.email ?? "—"}</span>
            </div>
            <div className="flex items-center gap-3 text-sm">
              <Award className="h-4 w-4 text-gray-400 dark:text-slate-500 shrink-0" />
              <span className="text-gray-500 dark:text-slate-400 w-20">Points</span>
              <span className="font-semibold text-accent-500">{profile?.loyalty_points ?? 0}</span>
            </div>
            <div className="flex items-center gap-3 text-sm">
              <Copy className="h-4 w-4 text-gray-400 dark:text-slate-500 shrink-0" />
              <span className="text-gray-500 dark:text-slate-400 w-20">Code parrainage</span>
              <div className="flex items-center gap-2">
                <code className="rounded bg-gray-100 dark:bg-slate-700 px-2 py-0.5 text-xs font-mono text-gray-700 dark:text-slate-300">
                  {profile?.referral_code ?? "—"}
                </code>
                <button
                  onClick={copyCode}
                  className="text-xs text-primary-700 dark:text-primary-400 hover:underline"
                >
                  Copier
                </button>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Édition */}
      <Card>
        <CardHeader>
          <CardTitle>Modifier le profil</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="full_name">
              <User className="mr-1.5 inline h-3.5 w-3.5" />
              Nom complet
            </Label>
            <Input
              id="full_name"
              value={form.full_name}
              onChange={(e) => setForm({ ...form, full_name: e.target.value })}
              placeholder="Votre nom"
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="phone">
              <Phone className="mr-1.5 inline h-3.5 w-3.5" />
              Téléphone
            </Label>
            <Input
              id="phone"
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
              placeholder="+229 00 00 00 00"
            />
          </div>
          <div className="flex justify-end">
            <Button onClick={save} disabled={saving}>
              {saving ? "Enregistrement…" : "Sauvegarder"}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
