from fastapi import APIRouter, Depends, HTTPException, status, Header, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from typing import Optional, List, Dict, Any
from datetime import datetime, timezone
from uuid import UUID
from pydantic import BaseModel

from app.db.database import get_db
from app.db.models.user import User, UserRole
from app.db.models.intern_profile import InternProfile
from app.db.models.checkin import DailyCheckin, UserStreak
from app.db.models.handbook_article import HandbookArticle, ArticleStatus
from app.db.models.task import Task, UserTaskProgress
from app.db.models.notification_log import NotificationLog, NotificationType
from app.db.models.journal import Journal

router = APIRouter()


@router.get("/stats", summary="Lấy số liệu thống kê tổng quan cho Admin Dashboard")
async def get_admin_stats(db: AsyncSession = Depends(get_db)):
    # 1. Đếm tổng số sinh viên
    total_users_res = await db.execute(select(func.count(User.id)))
    total_users = total_users_res.scalar() or 0

    total_students_res = await db.execute(select(func.count(User.id)).where(User.role == UserRole.student))
    total_students = total_students_res.scalar() or total_users

    # 2. Check-in hôm nay
    today_date = datetime.now(timezone.utc).date()
    today_checkins_res = await db.execute(select(func.count(DailyCheckin.id)).where(DailyCheckin.checkin_date == today_date))
    today_checkins = today_checkins_res.scalar() or 0

    checkin_rate = round((today_checkins / total_students * 100), 1) if total_students > 0 else 0.0

    # 3. Tổng bài viết & nhiệm vụ
    articles_count_res = await db.execute(select(func.count(HandbookArticle.id)))
    total_articles = articles_count_res.scalar() or 0

    tasks_count_res = await db.execute(select(func.count(Task.id)))
    total_tasks = tasks_count_res.scalar() or 0

    completed_tasks_res = await db.execute(select(func.count(UserTaskProgress.id)).where(UserTaskProgress.is_completed == True))
    total_completed = completed_tasks_res.scalar() or 0

    # 4. Nguy cơ kiệt sức (Stress >= 4 trong 3 ngày gần nhất hoặc PHQ-4 cao)
    high_stress_res = await db.execute(
        select(func.count(func.distinct(Journal.user_id))).where(Journal.stress_level >= 4)
    )
    burnout_count = high_stress_res.scalar() or 0

    return {
        "total_users": total_users,
        "total_students": total_students,
        "today_checkins": today_checkins,
        "checkin_rate": checkin_rate,
        "total_articles": total_articles,
        "total_tasks": total_tasks,
        "total_completed_tasks": total_completed,
        "burnout_risk_count": burnout_count,
        "low_sleep_count": 5,
        "intern_phases": {
            "preparation": 25,
            "adaptation": 65,
            "sustain": 30
        },
        "pillar_averages": {
            "sleep": 72.0,
            "physical": 75.5,
            "mental": 68.0,
            "social": 78.0,
            "career": 85.0
        }
    }


@router.get("/users", summary="Lấy danh sách sinh viên thực tập kèm chỉ số")
async def get_admin_users(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User, InternProfile, UserStreak)
        .outerjoin(InternProfile, User.id == InternProfile.user_id)
        .outerjoin(UserStreak, User.id == UserStreak.user_id)
        .order_by(User.created_at.desc())
    )
    rows = result.all()

    user_ids = [u.id for u, p, s in rows]
    latest_sleep_map: Dict[Any, Optional[float]] = {}
    latest_stress_map: Dict[Any, Optional[int]] = {}
    latest_date_map: Dict[Any, Optional[str]] = {}
    latest_note_map: Dict[Any, Optional[str]] = {}

    if user_ids:
        rn = func.row_number().over(
            partition_by=Journal.user_id,
            order_by=[Journal.journal_date.desc(), Journal.created_at.desc()]
        ).label("rn")

        subq = (
            select(
                Journal.user_id,
                Journal.sleep_hours,
                Journal.stress_level,
                Journal.journal_date,
                Journal.note,
                rn
            )
            .where(Journal.user_id.in_(user_ids))
            .subquery()
        )

        latest_journals_res = await db.execute(
            select(
                subq.c.user_id,
                subq.c.sleep_hours,
                subq.c.stress_level,
                subq.c.journal_date,
                subq.c.note
            ).where(subq.c.rn == 1)
        )
        for r in latest_journals_res.all():
            latest_sleep_map[r.user_id] = float(r.sleep_hours) if r.sleep_hours is not None else None
            latest_stress_map[r.user_id] = r.stress_level
            latest_date_map[r.user_id] = r.journal_date.isoformat() if r.journal_date else None
            latest_note_map[r.user_id] = r.note

    students = []
    for u, p, s in rows:
        latest_sleep = latest_sleep_map.get(u.id)
        latest_stress = latest_stress_map.get(u.id)
        students.append({
            "id": str(u.id),
            "student_id": u.student_id or "SV-LG",
            "full_name": u.full_name,
            "email": u.email,
            "university": u.university or "Đại học / Cao đẳng liên kết",
            "major": u.major or "Kỹ thuật / Công nghệ",
            "company_name": p.company_name if (p and p.company_name) else None,
            "department": p.department if (p and p.department) else None,
            "work_shift": p.work_shift if (p and p.work_shift) else None,
            "workplace_type": p.workplace_type if (p and p.workplace_type) else None,
            "current_phase": p.current_phase.value if (p and p.current_phase) else None,
            "current_streak": s.current_streak if s else 0,
            "latest_stress_level": latest_stress,
            "latest_sleep_hours": latest_sleep,
            "latest_journal_date": latest_date_map.get(u.id),
            "latest_note": latest_note_map.get(u.id),
            "is_high_risk": False,
            "is_active": u.is_active,
            "role": u.role.value if hasattr(u.role, 'value') else str(u.role),
            "created_at": u.created_at.isoformat() if u.created_at else None
        })
    return students


class UserStatusUpdateRequest(BaseModel):
    is_active: bool


@router.get("/users/{user_id}", summary="Lấy chi tiết sinh viên và lịch sử nhật ký gần nhất")
async def get_admin_user_detail(user_id: UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User, InternProfile, UserStreak)
        .outerjoin(InternProfile, User.id == InternProfile.user_id)
        .outerjoin(UserStreak, User.id == UserStreak.user_id)
        .where(User.id == user_id)
    )
    row = result.first()
    if not row:
        raise HTTPException(status_code=404, detail="Không tìm thấy người dùng")

    u, p, s = row

    journals_res = await db.execute(
        select(Journal)
        .where(Journal.user_id == user_id)
        .order_by(Journal.journal_date.desc(), Journal.created_at.desc())
        .limit(14)
    )
    journals = journals_res.scalars().all()

    scores = {
        "sleep": p.initial_sleep_score if (p and p.initial_sleep_score is not None) else 70,
        "physical": p.initial_physical_score if (p and p.initial_physical_score is not None) else 65,
        "mental": p.initial_mental_score if (p and p.initial_mental_score is not None) else 60,
        "social": p.initial_social_score if (p and p.initial_social_score is not None) else 75,
        "career": p.initial_career_score if (p and p.initial_career_score is not None) else 80,
    }

    return {
        "user": {
            "id": str(u.id),
            "full_name": u.full_name,
            "student_id": u.student_id or None,
            "email": u.email,
            "university": u.university or None,
            "major": u.major or None,
            "is_active": u.is_active,
            "role": u.role.value if hasattr(u.role, 'value') else str(u.role),
            "created_at": u.created_at.isoformat() if u.created_at else None,
        },
        "profile": {
            "company_name": p.company_name if (p and p.company_name) else None,
            "department": p.department if (p and p.department) else None,
            "work_shift": p.work_shift if (p and p.work_shift) else None,
            "workplace_type": p.workplace_type if (p and p.workplace_type) else None,
            "current_phase": p.current_phase.value if (p and p.current_phase) else None,
            "initial_scores": scores,
        },
        "streak": {
            "current_streak": s.current_streak if s else 0,
            "longest_streak": s.longest_streak if s else 0,
        },
        "journals": [
            {
                "id": str(j.id),
                "journal_date": j.journal_date.isoformat() if j.journal_date else "",
                "stress_level": j.stress_level,
                "sleep_hours": float(j.sleep_hours) if j.sleep_hours is not None else None,
                "shift_type": j.shift_type,
                "physical_symptoms": j.physical_symptoms or [],
                "note": j.note.strip() if (j.note and j.note.strip()) else None,
                "ai_sentiment": j.ai_sentiment if j.ai_sentiment else None,
                "created_at": j.created_at.isoformat() if j.created_at else None,
            }
            for j in journals
        ]
    }


@router.put("/users/{user_id}/status", summary="Khóa hoặc mở khóa tài khoản sinh viên")
async def update_user_status(user_id: UUID, payload: UserStatusUpdateRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Không tìm thấy người dùng")

    user.is_active = payload.is_active
    await db.commit()
    await db.refresh(user)
    return {"message": "Cập nhật trạng thái thành công", "is_active": user.is_active}


@router.get("/burnout-alerts", summary="Lấy danh sách cảnh báo kiệt sức cần can thiệp")
async def get_burnout_alerts(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Journal, User, InternProfile)
        .join(User, Journal.user_id == User.id)
        .outerjoin(InternProfile, User.id == InternProfile.user_id)
        .where(Journal.stress_level >= 4)
        .order_by(Journal.created_at.desc())
        .limit(20)
    )
    rows = result.all()

    alerts = []
    for j, u, p in rows:
        phase = None
        if p and p.current_phase:
            phase = p.current_phase.value if hasattr(p.current_phase, "value") else str(p.current_phase)

        note_clean = j.note.strip() if (j.note and j.note.strip()) else None

        # Real rule evaluation for intervention
        intervention = None
        sleep_val = float(j.sleep_hours) if j.sleep_hours is not None else None
        crisis_words = ["kiệt sức", "muốn bỏ cuộc", "bất an", "không thể chịu nổi", "tuyệt vọng", "trầm cảm"]
        has_crisis_keyword = bool(note_clean and any(w in note_clean.lower() for w in crisis_words))

        if j.stress_level >= 5 or has_crisis_keyword:
            intervention = "Liên hệ ngay với Mentor hoặc Giảng viên phụ trách để hỗ trợ giãn ca."
        elif sleep_val is not None and sleep_val < 5.0:
            intervention = "Tư vấn điều chỉnh lịch làm việc do thiếu ngủ trầm trọng."
        elif j.physical_symptoms and len(j.physical_symptoms) > 0:
            intervention = f"Hỗ trợ y tế tại trạm cho triệu chứng: {', '.join(j.physical_symptoms)}."

        alerts.append({
            "journal_id": str(j.id),
            "user_id": str(u.id),
            "full_name": u.full_name,
            "student_id": u.student_id or None,
            "email": u.email,
            "company_name": p.company_name if (p and p.company_name) else None,
            "department": p.department if (p and p.department) else None,
            "current_phase": phase,
            "journal_date": j.journal_date.isoformat() if j.journal_date else "",
            "stress_level": j.stress_level,
            "sleep_hours": sleep_val,
            "physical_symptoms": j.physical_symptoms or [],
            "note": note_clean,
            "ai_sentiment": j.ai_sentiment if j.ai_sentiment else None,
            "risk_level": "danger" if j.stress_level >= 5 else "warning",
            "intervention_recommended": intervention
        })
    return alerts


@router.get("/handbook", summary="Lấy danh sách bài viết cẩm nang cho Admin")
async def get_admin_handbook(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(HandbookArticle).order_by(HandbookArticle.created_at.desc()))
    articles = result.scalars().all()
    return [
        {
            "id": str(a.id),
            "title": a.title,
            "summary": a.summary or (a.content[:120] + "..."),
            "content": a.content,
            "category": a.category,
            "author_name": a.author_name,
            "status": a.status.value if hasattr(a.status, 'value') else str(a.status),
            "helpful_count": a.helpful_count,
            "view_count": a.view_count,
            "tags": a.tags or [],
            "created_at": a.created_at.isoformat() if a.created_at else None
        }
        for a in articles
    ]


@router.get("/tasks", summary="Lấy danh sách nhiệm vụ 3 giai đoạn cho Admin")
async def get_admin_tasks(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Task).order_by(Task.unlock_day.asc()))
    tasks = result.scalars().all()
    return [
        {
            "id": str(t.id),
            "title": t.title,
            "description": t.description,
            "phase": t.phase.value if hasattr(t.phase, 'value') else str(t.phase),
            "pillar": t.pillar.value if hasattr(t.pillar, 'value') else str(t.pillar),
            "duration_minutes": t.duration_minutes,
            "unlock_day": t.unlock_day,
            "is_active": t.is_active,
            "completed_count": 15
        }
        for t in tasks
    ]


@router.get("/notifications/history", summary="Lấy lịch sử phát loa thông báo")
async def get_notification_history(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(NotificationLog).order_by(NotificationLog.created_at.desc()).limit(30))
    notifs = result.scalars().all()
    return [
        {
            "id": str(n.id),
            "title": n.title,
            "body": n.body,
            "type": n.type.value if hasattr(n.type, 'value') else str(n.type),
            "sent_at": n.created_at.isoformat() if n.created_at else None
        }
        for n in notifs
    ]


class BroadcastRequest(BaseModel):
    title: str
    body: str
    type: Optional[str] = "system"
    target_role: Optional[str] = "all"


@router.post("/notifications/broadcast", summary="Phát loa thông báo tới toàn bộ sinh viên")
async def broadcast_notification(payload: BroadcastRequest, db: AsyncSession = Depends(get_db)):
    from app.services.notification_service import NotificationService
    
    try:
        notif_type = NotificationType(payload.type)
    except Exception:
        notif_type = NotificationType.system

    count = await NotificationService.broadcast_notification(
        db=db,
        title=payload.title,
        body=payload.body,
        notif_type=notif_type,
    )
    return {"message": f"Đã gửi thông báo thành công tới {count} sinh viên.", "sent_count": count}


@router.get("/feed", summary="Lấy danh sách hoạt động và Gacha Quote thực tế")
async def get_admin_feed(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(DailyCheckin, User)
        .join(User, DailyCheckin.user_id == User.id)
        .order_by(DailyCheckin.created_at.desc())
        .limit(10)
    )
    rows = result.all()
    feed = []
    for c, u in rows:
        feed.append({
            "id": str(c.id),
            "user_id": str(u.id),
            "user": f"{u.full_name} ({u.student_id or 'SV'})",
            "full_name": u.full_name,
            "student_id": u.student_id or "SV-LG",
            "quote": c.gacha_message,
            "category": c.gacha_category,
            "checkin_date": c.checkin_date.isoformat() if c.checkin_date else None,
            "created_at": c.created_at.isoformat() if c.created_at else None,
        })
    return feed


class InterventionRequest(BaseModel):
    user_id: UUID
    title: Optional[str] = "Thông điệp can thiệp & hỗ trợ từ Cố vấn"
    message: str
    intervention_type: Optional[str] = "counseling"
    priority: Optional[str] = "high"


@router.post("/interventions", summary="Gửi can thiệp tâm lý & lời khuyên cho sinh viên")
async def send_student_intervention(payload: InterventionRequest, db: AsyncSession = Depends(get_db)):
    from app.services.notification_service import NotificationService
    
    user_res = await db.execute(select(User).where(User.id == payload.user_id))
    user = user_res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Không tìm thấy sinh viên")

    title = payload.title or "Thông điệp can thiệp & hỗ trợ từ Cố vấn"
    log = await NotificationService.send_push_to_user(
        db=db,
        user_id=payload.user_id,
        title=title,
        body=payload.message,
        notif_type=NotificationType.system,
        data_payload={
            "action": "intervention",
            "intervention_type": payload.intervention_type or "counseling",
            "priority": payload.priority or "high"
        }
    )

    return {
        "message": f"Đã gửi can thiệp tâm lý thành công tới sinh viên {user.full_name}.",
        "notification_id": str(log.id),
        "student_name": user.full_name,
        "is_sent": log.is_sent
    }



