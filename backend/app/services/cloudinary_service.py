import asyncio
import cloudinary
import cloudinary.uploader
from fastapi import UploadFile, HTTPException
from app.core.config import settings

cloudinary.config(
    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True,
)

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
MAX_SIZE_MB = 5


async def _validate_file(file: UploadFile) -> bytes:
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(400, "Format non supporté (jpeg, png, webp, gif)")
    content = await file.read()
    if len(content) > MAX_SIZE_MB * 1024 * 1024:
        raise HTTPException(400, f"Image trop grande (max {MAX_SIZE_MB}MB)")
    return content


def _upload_sync(content: bytes, **kwargs) -> str:
    try:
        result = cloudinary.uploader.upload(content, **kwargs)
        return result["secure_url"]
    except Exception as e:
        raise HTTPException(500, f"Erreur upload Cloudinary : {e}")


async def upload_coupon_image(file: UploadFile) -> str:
    content = await _validate_file(file)
    loop = asyncio.get_event_loop()
    kwargs = {
        "folder": "coupons",
        "transformation": [
            {"width": 900, "crop": "limit"},
            {"quality": "auto", "fetch_format": "auto"},
        ],
    }
    return await loop.run_in_executor(None, lambda: _upload_sync(content, **kwargs))


async def upload_support_media(file: UploadFile) -> str:
    content = await _validate_file(file)
    loop = asyncio.get_event_loop()
    kwargs = {
        "folder": "support",
        "transformation": [
            {"width": 1200, "crop": "limit"},
            {"quality": "auto", "fetch_format": "auto"},
        ],
    }
    return await loop.run_in_executor(None, lambda: _upload_sync(content, **kwargs))


async def upload_avatar(file: UploadFile, user_id: str) -> str:
    content = await _validate_file(file)
    loop = asyncio.get_event_loop()
    kwargs = {
        "folder": "avatars",
        "public_id": f"avatar_{user_id}",
        "overwrite": True,
        "transformation": [
            {"width": 200, "height": 200, "crop": "fill", "gravity": "face"},
            {"quality": "auto", "fetch_format": "auto"},
        ],
    }
    return await loop.run_in_executor(None, lambda: _upload_sync(content, **kwargs))
