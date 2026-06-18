import shortuuid
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import decode_firebase_token
from app.models.user import User
from app.schemas.user import UserResponse

router = APIRouter(prefix="/auth", tags=["Auth"])
bearer_scheme = HTTPBearer()


@router.post("/sync", response_model=UserResponse, summary="Synchroniser l'utilisateur Firebase → DB")
async def sync_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
):
    decoded = decode_firebase_token(credentials.credentials)
    firebase_uid = decoded.get("uid")
    email = decoded.get("email") or None
    name = decoded.get("name")
    picture = decoded.get("picture")

    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()

    if not user:
        user = User(
            firebase_uid=firebase_uid,
            email=email,
            full_name=name,
            avatar_url=picture,
            referral_code=shortuuid.ShortUUID().random(length=8).upper(),
        )
        db.add(user)
        await db.flush()
    else:
        # Mise à jour des infos Firebase si changées
        if name and not user.full_name:
            user.full_name = name
        if picture and not user.avatar_url:
            user.avatar_url = picture

    await db.commit()
    await db.refresh(user)
    return user
