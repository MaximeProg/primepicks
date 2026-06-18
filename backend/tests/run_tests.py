"""Test complet de l'API avec authentification Firebase."""
import asyncio
import httpx
import os
import sys

os.chdir(r"e:\coupons\backend")
from dotenv import load_dotenv
load_dotenv()

import firebase_admin
from firebase_admin import credentials, auth as fb_auth

SERVICE_ACCOUNT = os.environ["FIREBASE_SERVICE_ACCOUNT_PATH"]
WEB_KEY = os.environ["FIREBASE_WEB_API_KEY"]
BASE = "http://localhost:8000/api/v1"

if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT)
    firebase_admin.initialize_app(cred)

ok_count = 0
fail_count = 0


def check(label, r, expected=200):
    global ok_count, fail_count
    sym = "[OK]  " if r.status_code == expected else "[FAIL]"
    if r.status_code != expected:
        fail_count += 1
    else:
        ok_count += 1

    detail = ""
    try:
        j = r.json()
        if isinstance(j, dict):
            detail = str(j)[:120]
        elif isinstance(j, list):
            detail = f"{len(j)} element(s)"
    except Exception:
        detail = r.text[:120]

    print(f"  {sym} [{r.status_code}] {label}  {detail}")


async def get_id_token(uid: str) -> str:
    custom = fb_auth.create_custom_token(uid)
    custom_str = custom.decode() if isinstance(custom, bytes) else custom
    async with httpx.AsyncClient(timeout=15) as c:
        r = await c.post(
            f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key={WEB_KEY}",
            json={"token": custom_str, "returnSecureToken": True},
        )
        r.raise_for_status()
        return r.json()["idToken"]


async def run():
    print("\n" + "=" * 55)
    print("  TESTS API COUPONS PARIS SPORTIFS")
    print("=" * 55)

    # --- Token utilisateur de test ---
    print("\n[1] Obtention token Firebase...")
    id_token = await get_id_token("test-user-001")
    print(f"  [OK]  ID token obtenu ({id_token[:40]}...)")
    ok_count_ref = [0]

    h = {"Authorization": f"Bearer {id_token}"}

    async with httpx.AsyncClient(base_url=BASE, timeout=15) as c:

        # ── AUTH ──────────────────────────────────────────────
        print("\n[2] Auth")
        r = await c.post("/auth/sync", headers=h)
        check("POST /auth/sync", r)
        plan_id = None
        if r.status_code == 200:
            user = r.json()
            print(f"       email={user['email']} role={user['role']} ref={user['referral_code']}")

        # ── UTILISATEUR ───────────────────────────────────────
        print("\n[3] Utilisateur")
        r = await c.get("/users/me", headers=h)
        check("GET  /users/me", r)
        r = await c.patch("/users/me", headers=h, json={"full_name": "Test User"})
        check("PATCH /users/me", r)
        r = await c.get("/users/me/subscriptions", headers=h)
        check("GET  /users/me/subscriptions", r)
        r = await c.get("/users/me/transactions", headers=h)
        check("GET  /users/me/transactions", r)

        # ── PLANS ─────────────────────────────────────────────
        print("\n[4] Plans")
        r = await c.get("/plans")
        check("GET  /plans", r)
        if r.status_code == 200 and r.json():
            plan_id = r.json()[0]["id"]
            print(f"       {len(r.json())} plans, premier: {r.json()[0]['name']} - {r.json()[0]['price']} XOF")

        # ── STATS PUBLIQUES ───────────────────────────────────
        print("\n[5] Stats publiques")
        r = await c.get("/stats/public")
        check("GET  /stats/public", r)
        if r.status_code == 200:
            s = r.json()
            print(f"       total={s['total_coupons']} won={s['won']} lost={s['lost']} rate={s['win_rate']}%")

        # ── COUPONS ───────────────────────────────────────────
        print("\n[6] Coupons")
        r = await c.get("/coupons/public")
        check("GET  /coupons/public", r)
        r = await c.get("/coupons", headers=h)
        check("GET  /coupons (sans abo -> 403)", r, expected=403)

        # ── ABONNEMENTS ───────────────────────────────────────
        print("\n[7] Abonnements")
        r = await c.get("/subscriptions/me", headers=h)
        check("GET  /subscriptions/me (null attendu)", r)

        if plan_id:
            r = await c.post("/subscriptions", headers=h, json={"plan_id": plan_id})
            check("POST /subscriptions (initie FedaPay)", r)
            if r.status_code == 200:
                data = r.json()
                print(f"       amount={data['amount']} XOF")
                print(f"       payment_url={data.get('payment_url','')[:60]}...")

        # ── NOTIFICATIONS ─────────────────────────────────────
        print("\n[8] Notifications")
        r = await c.post("/notifications/token", headers=h,
                         json={"token": "fcm-test-token-abc", "device_type": "WEB"})
        check("POST /notifications/token", r)
        r = await c.delete("/notifications/token?device_type=WEB", headers=h)
        check("DELETE /notifications/token", r)
        r = await c.post("/notifications/token", headers=h,
                         json={"token": "fcm-test-token-abc", "device_type": "WEB"})
        check("POST /notifications/token (re-register)", r)

        # ── PARRAINAGE ────────────────────────────────────────
        print("\n[9] Parrainage")
        r = await c.get("/referrals/me", headers=h)
        check("GET  /referrals/me", r)
        if r.status_code == 200:
            ref = r.json()
            print(f"       code={ref['referral_code']} filleuls={ref['total_referred']}")
        r = await c.get("/referrals/me/stats", headers=h)
        check("GET  /referrals/me/stats", r)

        # ── FIDELITE ─────────────────────────────────────────
        print("\n[10] Fidelite")
        r = await c.get("/loyalty/me", headers=h)
        check("GET  /loyalty/me", r)
        if r.status_code == 200:
            print(f"       points={r.json()['current_points']}")
        r = await c.post("/loyalty/redeem", headers=h, json={"reward_key": "discount_10"})
        check("POST /loyalty/redeem (insuffisant -> 400)", r, expected=400)

        # ── AFFILIATION ───────────────────────────────────────
        print("\n[11] Affiliation")
        r = await c.post("/affiliates/apply", headers=h)
        # Accepte 200 (nouveau) ou 400 (deja affilie)
        check("POST /affiliates/apply", r, expected=r.status_code if r.status_code in (200, 400) else 200)
        r = await c.post("/affiliates/apply", headers=h)
        check("POST /affiliates/apply (doublon -> 400)", r, expected=400)
        r = await c.get("/affiliates/me", headers=h)
        check("GET  /affiliates/me", r)
        if r.status_code == 200:
            print(f"       code={r.json()['affiliate_code']} rate={r.json()['commission_rate']}%")
        r = await c.get("/affiliates/me/conversions", headers=h)
        check("GET  /affiliates/me/conversions", r)
        r = await c.get("/affiliates/me/earnings", headers=h)
        check("GET  /affiliates/me/earnings", r)

        # ── ADMIN (acces refuse pour user normal) ─────────────
        print("\n[12] Acces admin (refus 403 attendu)")
        for path in ["/admin/stats/overview", "/admin/coupons", "/admin/users", "/admin/plans"]:
            r = await c.get(path, headers=h)
            check(f"GET  {path} -> 403", r, expected=403)

    # ── BILAN ─────────────────────────────────────────────────
    total = ok_count + fail_count
    print("\n" + "=" * 55)
    print(f"  BILAN : {ok_count}/{total} OK  |  {fail_count} FAIL")
    print("=" * 55 + "\n")
    return fail_count


if __name__ == "__main__":
    fails = asyncio.run(run())
    firebase_admin.delete_app(firebase_admin.get_app())
    sys.exit(0 if fails == 0 else 1)
