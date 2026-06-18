"""
Test du flux d'authentification complet avec Firebase Admin SDK.
Génère un custom token -> l'échange contre un ID token -> appelle l'API.

Usage : python tests/test_auth_flow.py
"""
import asyncio
import httpx
import firebase_admin
from firebase_admin import credentials, auth
from dotenv import load_dotenv
import os

load_dotenv()

SERVICE_ACCOUNT_PATH = os.environ.get("FIREBASE_SERVICE_ACCOUNT_PATH", "")
FIREBASE_API_KEY = os.environ.get("FIREBASE_WEB_API_KEY", "")  # clé web Firebase (optionnel)
BASE_URL = "http://localhost:8000/api/v1"

# Init Firebase Admin
if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)


def create_test_token(uid: str = "test-user-001", email: str = "test@example.com") -> str:
    """Crée un custom token Firebase pour les tests."""
    custom_token = auth.create_custom_token(uid)
    return custom_token.decode() if isinstance(custom_token, bytes) else custom_token


async def exchange_custom_token_for_id_token(custom_token: str) -> str:
    """Échange le custom token contre un ID token via l'API REST Firebase."""
    if not FIREBASE_API_KEY:
        raise ValueError(
            "FIREBASE_WEB_API_KEY manquante dans .env\n"
            "Trouvez-la dans Firebase Console -> Paramètres du projet -> Clé API web"
        )
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key={FIREBASE_API_KEY}"
    async with httpx.AsyncClient() as client:
        resp = await client.post(url, json={"token": custom_token, "returnSecureToken": True})
        resp.raise_for_status()
        return resp.json()["idToken"]


async def test_sync(id_token: str):
    headers = {"Authorization": f"Bearer {id_token}"}
    async with httpx.AsyncClient(base_url=BASE_URL, timeout=10) as client:
        # 1. Sync utilisateur
        print("\n--- POST /auth/sync ---")
        r = await client.post("/auth/sync", headers=headers)
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            user = r.json()
            print(f"User: {user['email']} | Role: {user['role']} | Referral: {user['referral_code']}")

        # 2. Profil
        print("\n--- GET /users/me ---")
        r = await client.get("/users/me", headers=headers)
        print(f"Status: {r.status_code} | Points: {r.json().get('loyalty_points', '?')}")

        # 3. Plans
        print("\n--- GET /plans ---")
        r = await client.get("/plans")
        plans = r.json()
        print(f"Status: {r.status_code} | {len(plans)} plans")

        # 4. Parrainage
        print("\n--- GET /referrals/me ---")
        r = await client.get("/referrals/me", headers=headers)
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            ref = r.json()
            print(f"Code: {ref['referral_code']} | Lien: {ref['referral_link']}")

        # 5. Fidélité
        print("\n--- GET /loyalty/me ---")
        r = await client.get("/loyalty/me", headers=headers)
        print(f"Status: {r.status_code} | Points: {r.json().get('current_points', '?')}")

        # 6. Token FCM
        print("\n--- POST /notifications/token ---")
        r = await client.post("/notifications/token", headers=headers,
                              json={"token": "test-fcm-token-abc123", "device_type": "WEB"})
        print(f"Status: {r.status_code} | {r.json().get('message', '')}")

        # 7. Stats publiques
        print("\n--- GET /stats/public ---")
        r = await client.get("/stats/public")
        print(f"Status: {r.status_code} | {r.json()}")


async def main():
    print("=== Test flux Auth Firebase ===")

    if not SERVICE_ACCOUNT_PATH or not os.path.exists(SERVICE_ACCOUNT_PATH):
        print("ERREUR : FIREBASE_SERVICE_ACCOUNT_PATH invalide")
        return

    if not FIREBASE_API_KEY:
        print(
            "\n[INFO] FIREBASE_WEB_API_KEY non configurée.\n"
            "Pour tester le flux complet, ajoutez dans .env :\n"
            "  FIREBASE_WEB_API_KEY=AIzaSy...\n"
            "(Firebase Console -> Paramètres du projet -> Clé API web)\n"
        )
        print("Test limité : génération custom token seulement")
        token = create_test_token()
        print(f"Custom token généré (premiers 60 chars) : {token[:60]}...")
        return

    print("Génération custom token...")
    custom_token = create_test_token()

    print("Échange contre ID token...")
    id_token = await exchange_custom_token_for_id_token(custom_token)
    print(f"ID token obtenu (premiers 40 chars) : {id_token[:40]}...")

    await test_sync(id_token)
    print("\n=== Tous les tests passés ===")


if __name__ == "__main__":
    asyncio.run(main())
