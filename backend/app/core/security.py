from fastapi import HTTPException, status
from app.core.firebase import verify_firebase_token


def decode_firebase_token(token: str) -> dict:
    try:
        decoded = verify_firebase_token(token)
        return decoded
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token Firebase invalide ou expiré",
            headers={"WWW-Authenticate": "Bearer"},
        )
