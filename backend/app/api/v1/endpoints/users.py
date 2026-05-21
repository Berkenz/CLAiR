from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.user import FcmTokenRegisterRequest, UserResponse, UserUpdate
from app.services.user_service import user_service

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """Get current user profile (protected)."""
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_current_user_profile(
    update_data: UserUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """Update current user profile (protected)."""
    return await user_service.update_user(db, current_user.id, update_data)


@router.put("/me/fcm-token", status_code=204)
async def register_fcm_token(
    body: FcmTokenRegisterRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    """Register the device FCM token for push notifications (mobile clients)."""
    if current_user.is_anonymous:
        raise HTTPException(400, "Guest accounts cannot enable push notifications")
    token = body.token.strip()
    if not token:
        raise HTTPException(400, "FCM token is required")
    await user_service.set_fcm_token(db, current_user.id, token)


@router.delete("/me/fcm-token", status_code=204)
async def clear_fcm_token(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    """Remove the device FCM token (e.g. on sign-out)."""
    await user_service.set_fcm_token(db, current_user.id, None)


@router.post("/me/photo", response_model=UserResponse)
async def upload_profile_photo_endpoint(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    file: Annotated[UploadFile, File()],
) -> User:
    """Upload profile photo (GCS or Supabase) and update user."""
    content_type = (file.content_type or "image/jpeg").split(";")[0].strip().lower()
    if not content_type.startswith("image/"):
        raise HTTPException(400, "File must be an image (JPEG, PNG, WebP, or GIF)")

    # Normalize common variants (e.g. application/octet-stream from some clients)
    if content_type not in {
        "image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"
    }:
        content_type = "image/jpeg"

    content = await file.read()
    if not content:
        raise HTTPException(400, "File is empty")

    try:
        from app.services.storage_service import upload_profile_photo, upload_http_exception

        from app.utils.photo_url import photo_url_strip_cache_bust

        photo_url = photo_url_strip_cache_bust(
            upload_profile_photo(str(current_user.id), content, content_type)
        )
    except HTTPException:
        raise
    except Exception as e:
        raise upload_http_exception(e) from e

    update_data = UserUpdate(photo_url=photo_url)
    updated = await user_service.update_user(db, current_user.id, update_data)
    from app.services.lawyer_service import invalidate_lawyers_directory_cache

    invalidate_lawyers_directory_cache()
    return UserResponse.model_validate(updated)
