import shortuuid
from fastapi import APIRouter, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import decode_firebase_token
from app.models.user import User
from app.models.referral import Referral
from app.schemas.user import UserResponse

router = APIRouter(prefix="/auth", tags=["Auth"])
bearer_scheme = HTTPBearer()


class SyncBody(BaseModel):
    full_name: str | None = None
    referral_code: str | None = None


@router.post("/sync", response_model=UserResponse, summary="Synchroniser l'utilisateur Firebase → DB")
async def sync_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
    body: SyncBody | None = None,
):
    if body is None:
        body = SyncBody()

    decoded = decode_firebase_token(credentials.credentials)
    firebase_uid = decoded.get("uid")
    email = decoded.get("email") or None
    name = body.full_name or decoded.get("name")
    picture = decoded.get("picture")

    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    is_new_user = user is None

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
        if name and not user.full_name:
            user.full_name = name
        if picture and not user.avatar_url:
            user.avatar_url = picture

    # Create referral link for new users who registered with a referral code
    if is_new_user and body.referral_code:
        referrer_result = await db.execute(
            select(User).where(User.referral_code == body.referral_code)
        )
        referrer = referrer_result.scalar_one_or_none()
        if referrer and referrer.id != user.id:
            user.referred_by = referrer.id
            db.add(Referral(referrer_id=referrer.id, referred_id=user.id))

    await db.commit()
    await db.refresh(user)
    return user
