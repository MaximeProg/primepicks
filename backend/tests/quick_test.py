import asyncio, httpx, os, sys
os.chdir(r"e:\coupons\backend")
from dotenv import load_dotenv; load_dotenv()
import firebase_admin
from firebase_admin import credentials, auth as fb_auth

if not firebase_admin._apps:
    firebase_admin.initialize_app(credentials.Certificate(os.environ["FIREBASE_SERVICE_ACCOUNT_PATH"]))

WEB_KEY = os.environ["FIREBASE_WEB_API_KEY"]

async def run():
    custom = fb_auth.create_custom_token("test-user-diag")
    s = custom.decode() if isinstance(custom, bytes) else custom

    async with httpx.AsyncClient(timeout=30) as c:
        r = await c.post(
            "https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=" + WEB_KEY,
            json={"token": s, "returnSecureToken": True}
        )
        tok = r.json()["idToken"]
        print("Token OK, uid claim:", r.json().get("localId"))

    async with httpx.AsyncClient(base_url="http://localhost:8000/api/v1", timeout=30) as c:
        r = await c.post("/auth/sync", headers={"Authorization": "Bearer " + tok})
        print("auth/sync status:", r.status_code)
        print("auth/sync body:", r.text[:1000])

        if r.status_code == 200:
            r2 = await c.get("/users/me", headers={"Authorization": "Bearer " + tok})
            print("users/me status:", r2.status_code)
            print("users/me body:", r2.text[:500])

asyncio.run(run())
firebase_admin.delete_app(firebase_admin.get_app())
