from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.db.database import get_db
from app.schemas.auth import UserResponse, UpdateProfileRequest, ChangePasswordRequest
from app.services import user_service
from app.core.security import verify_password, hash_password

router = APIRouter()


@router.get("/me", response_model=UserResponse, summary="Lấy thông tin tài khoản")
async def get_my_profile(
    authorization: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Chưa xác thực.")
    token = authorization.split(" ", 1)[1]
    user = await user_service.get_current_user(db, token)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token không hợp lệ hoặc đã hết hạn.")
    return UserResponse.model_validate(user)


@router.put("/me", response_model=UserResponse, summary="Cập nhật thông tin tài khoản")
async def update_my_profile(
    payload: UpdateProfileRequest,
    authorization: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Chưa xác thực.")
    token = authorization.split(" ", 1)[1]
    user = await user_service.get_current_user(db, token)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token không hợp lệ hoặc đã hết hạn.")

    if payload.full_name is not None and payload.full_name.strip():
        user.full_name = payload.full_name.strip()
    if payload.student_id is not None:
        user.student_id = payload.student_id.strip() if payload.student_id.strip() else None
    if payload.university is not None:
        user.university = payload.university.strip() if payload.university.strip() else None
    if payload.major is not None:
        user.major = payload.major.strip() if payload.major.strip() else None
    if payload.avatar_url is not None:
        user.avatar_url = payload.avatar_url

    await db.commit()
    await db.refresh(user)
    return UserResponse.model_validate(user)


@router.post("/change-password", summary="Đổi mật khẩu tài khoản")
async def change_password(
    payload: ChangePasswordRequest,
    authorization: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Chưa xác thực.")
    token = authorization.split(" ", 1)[1]
    user = await user_service.get_current_user(db, token)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token không hợp lệ hoặc đã hết hạn.")

    if user.password_hash and not verify_password(payload.old_password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Mật khẩu hiện tại không chính xác.")

    user.password_hash = hash_password(payload.new_password)
    await db.commit()
    return {"message": "Đổi mật khẩu thành công."}
