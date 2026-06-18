import json
import firebase_admin
from firebase_admin import credentials, auth, messaging
from app.core.config import settings

_firebase_app = None


def get_firebase_app():
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app

    # Priorité : fichier serviceAccountKey.json
    if settings.FIREBASE_SERVICE_ACCOUNT_PATH:
        cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
    elif settings.FIREBASE_PROJECT_ID and settings.FIREBASE_PRIVATE_KEY:
        # Variables d'environnement individuelles
        cred = credentials.Certificate({
            "type": "service_account",
            "project_id": settings.FIREBASE_PROJECT_ID,
            "private_key": settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n"),
            "client_email": settings.FIREBASE_CLIENT_EMAIL,
            "token_uri": "https://oauth2.googleapis.com/token",
        })
    else:
        # Mode dev sans Firebase configuré
        return None

    _firebase_app = firebase_admin.initialize_app(cred)
    return _firebase_app


def verify_firebase_token(id_token: str) -> dict:
    get_firebase_app()
    decoded = auth.verify_id_token(id_token)
    return decoded


def send_fcm_multicast(tokens: list[str], title: str, body: str, data: dict = {}) -> dict:
    if not tokens:
        return {"success": 0, "failure": 0}

    str_data = {k: str(v) for k, v in data.items()}

    message = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(title=title, body=body),
        data=str_data,
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound="default", badge=1)
            )
        ),
    )
    response = messaging.send_each_for_multicast(message)
    return {
        "success": response.success_count,
        "failure": response.failure_count,
    }
