from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional, List, Dict, Any
from pydantic import BaseModel

from app.db.database import get_db
from app.db.models.user import User
from app.db.models.intern_profile import InternProfile
from app.services.user_service import get_current_user
from app.core.companies import DEFAULT_COMPANIES, find_company_by_name

router = APIRouter()


async def get_authed_user(authorization: Optional[str] = Header(None), db: AsyncSession = Depends(get_db)) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Chưa xác thực.")
    token = authorization.split(" ", 1)[1]
    user = await get_current_user(db, token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token không hợp lệ hoặc đã hết hạn.")
    return user


class UpdateWorkplaceRequest(BaseModel):
    company_name: str
    company_lat: Optional[float] = None
    company_lng: Optional[float] = None
    company_radius: Optional[int] = 500
    workplace_type: Optional[str] = "factory_locker"
    work_shift: Optional[str] = "day_12h"
    department: Optional[str] = None
    dorm_lat: Optional[float] = None
    dorm_lng: Optional[float] = None


@router.get("/companies", summary="Lấy danh mục công ty thực tập mẫu kèm tọa độ GPS")
async def get_companies():
    return DEFAULT_COMPANIES


@router.get("/profile", summary="Lấy thông tin công ty và ca làm việc hiện tại của sinh viên")
async def get_workplace_profile(
    user: User = Depends(get_authed_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(InternProfile).where(InternProfile.user_id == user.id))
    profile = result.scalar_one_or_none()

    if not profile:
        # Tự động tạo hồ sơ mặc định nếu chưa có
        matched_comp = find_company_by_name("LG Display")
        profile = InternProfile(
            user_id=user.id,
            company_name=matched_comp["name"],
            company_lat=matched_comp["latitude"],
            company_lng=matched_comp["longitude"],
            company_radius=matched_comp["radius_meters"],
            workplace_type=matched_comp["workplace_type"],
            work_shift="day_12h",
        )
        db.add(profile)
        await db.commit()
        await db.refresh(profile)

    return {
        "user_id": str(user.id),
        "full_name": user.full_name,
        "company_name": profile.company_name or "LG Display Hải Phòng",
        "department": profile.department or "Khối Sản xuất Module",
        "company_lat": profile.company_lat,
        "company_lng": profile.company_lng,
        "company_radius": profile.company_radius or 500,
        "workplace_type": profile.workplace_type or "factory_locker",
        "work_shift": profile.work_shift or "day_12h",
        "dorm_lat": profile.dorm_lat,
        "dorm_lng": profile.dorm_lng,
        "current_phase": profile.current_phase.value if hasattr(profile.current_phase, 'value') else str(profile.current_phase),
    }


@router.put("/profile", summary="Cập nhật công ty thực tập, tọa độ GPS và ca làm việc")
async def update_workplace_profile(
    payload: UpdateWorkplaceRequest,
    user: User = Depends(get_authed_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(InternProfile).where(InternProfile.user_id == user.id))
    profile = result.scalar_one_or_none()

    # Tự động điền tọa độ nếu người dùng chọn công ty trong danh mục mẫu
    comp_lat = payload.company_lat
    comp_lng = payload.company_lng
    comp_radius = payload.company_radius
    wp_type = payload.workplace_type

    matched_comp = find_company_by_name(payload.company_name)
    if matched_comp and matched_comp["latitude"] is not None:
        if comp_lat is None:
            comp_lat = matched_comp["latitude"]
        if comp_lng is None:
            comp_lng = matched_comp["longitude"]
        if comp_radius is None:
            comp_radius = matched_comp["radius_meters"]
        if wp_type is None or wp_type == "factory_locker":
            wp_type = matched_comp["workplace_type"]

    if not profile:
        profile = InternProfile(
            user_id=user.id,
            company_name=payload.company_name.strip(),
            department=payload.department.strip() if payload.department else None,
            company_lat=comp_lat,
            company_lng=comp_lng,
            company_radius=comp_radius or 500,
            workplace_type=wp_type or "factory_locker",
            work_shift=payload.work_shift or "day_12h",
            dorm_lat=payload.dorm_lat,
            dorm_lng=payload.dorm_lng,
        )
        db.add(profile)
    else:
        profile.company_name = payload.company_name.strip()
        if payload.department is not None:
            profile.department = payload.department.strip()
        profile.company_lat = comp_lat
        profile.company_lng = comp_lng
        profile.company_radius = comp_radius or profile.company_radius or 500
        profile.workplace_type = wp_type or profile.workplace_type or "factory_locker"
        profile.work_shift = payload.work_shift or profile.work_shift or "day_12h"
        if payload.dorm_lat is not None:
            profile.dorm_lat = payload.dorm_lat
        if payload.dorm_lng is not None:
            profile.dorm_lng = payload.dorm_lng

    await db.commit()
    await db.refresh(profile)

    return {
        "message": "Cập nhật hồ sơ thực tập và vị trí công ty thành công!",
        "company_name": profile.company_name,
        "work_shift": profile.work_shift,
        "workplace_type": profile.workplace_type,
        "company_lat": profile.company_lat,
        "company_lng": profile.company_lng,
        "dorm_lat": profile.dorm_lat,
        "dorm_lng": profile.dorm_lng,
    }
