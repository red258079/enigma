from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime, timezone
from uuid import UUID

from app.db.models.task import Task, UserTaskProgress, PillarType
from app.db.models.intern_profile import InternPhase


TASK_TRANSLATIONS: Dict[str, Dict[str, str]] = {
    "read the lg display handbook": {
        "title": "Đọc cẩm nang \"Hành trang LG Display\"",
        "desc": "Tìm hiểu trước về văn hóa công ty, quy định 5S và các vật dụng cần thiết mang theo khi đi làm.",
    },
    "prepare a basic first aid kit": {
        "title": "Chuẩn bị đồ dùng cá nhân y tế cơ bản",
        "desc": "Chuẩn bị urgo, thuốc nhỏ mắt, thuốc tiêu hóa và các loại thuốc cơ bản để sẵn sàng cho môi trường mới.",
    },
    "practice sleeping before 11:30 pm": {
        "title": "Tập ngủ sớm trước 23:30",
        "desc": "Điều chỉnh nhịp sinh học trước khi chính thức đi làm để không bị mệt mỏi trong những ngày đầu.",
    },
    "join the intern group chat": {
        "title": "Kết nối nhóm sinh viên cùng đợt",
        "desc": "Tham gia group Zalo/Facebook của đợt thực tập để trao đổi thông tin và tìm bạn đồng hành.",
    },
    "define your internship goals": {
        "title": "Xác định mục tiêu thực tập",
        "desc": "Viết ra 3 điều bạn muốn học được sau 3 tháng tới (kỹ năng cứng, mềm, mối quan hệ).",
    },
    "box breathing: overcome first-day anxiety": {
        "title": "Tập hít thở 4-4-4-4: Vượt qua bỡ ngỡ ngày đầu",
        "desc": "Tập hít thở chậm rãi trong 3 phút để giảm căng thẳng khi tiếp xúc với môi trường sản xuất quy mô lớn.",
    },
    "no caffeine after 3 pm": {
        "title": "Làm quen nhịp ca kíp: Không uống cà phê chiều",
        "desc": "Tránh uống cà phê hoặc nước tăng lực sau 15h để đảm bảo có thể ngủ sâu vào ban đêm.",
    },
    "neck and shoulder stretch after shift": {
        "title": "Giãn cơ vai gáy sau ca làm",
        "desc": "Thực hiện 3 động tác xoay cổ và căng vai gáy để tránh nhức mỏi.",
    },
    "have lunch with a new colleague": {
        "title": "Ăn trưa cùng một đồng nghiệp mới",
        "desc": "Mở rộng giao tiếp, hỏi han về kinh nghiệm làm việc của các anh chị đi trước.",
    },
    "first week review: what did i learn?": {
        "title": "Đánh giá tuần đầu: Những bài học đã tích lũy",
        "desc": "Ghi lại các quy trình cơ bản và thao tác máy móc bạn đã được hướng dẫn.",
    },
    "emotion check-in: identify pressure": {
        "title": "Điểm danh cảm xúc: Nhận diện áp lực ca kíp",
        "desc": "Sử dụng nhật ký để viết ra những khó khăn đang gặp phải (đứng lâu, không quen việc...).",
    },
    "warm foot soak before bed": {
        "title": "Ngâm chân nước ấm",
        "desc": "Giúp dãn mạch máu vùng bàn chân, xua tan cảm giác mỏi nhức do đứng làm việc lâu.",
    },
    "turn off screens 30 min before bed": {
        "title": "Tắt màn hình 30p trước khi ngủ",
        "desc": "Giảm tiếp xúc ánh sáng xanh để não bộ thư giãn.",
    },
    "share a difficulty with your team leader": {
        "title": "Chia sẻ một khó khăn với quản lý/nhóm trưởng",
        "desc": "Đừng ngại hỏi hoặc chia sẻ nếu bạn đang gặp bế tắc trong thao tác công việc.",
    },
    "month 1 review: what did i achieve?": {
        "title": "Đánh giá tháng 1: Bạn đã làm được gì?",
        "desc": "Nhìn lại 1 tháng vừa qua, tự thưởng cho bản thân vì đã nỗ lực thích nghi.",
    },
    "light exercise 15 minutes daily": {
        "title": "Tập thể dục nhẹ 15 phút mỗi ngày",
        "desc": "Duy trì thói quen vận động để tăng sức bền cho những tháng tiếp theo.",
    },
    "financial management: cut unnecessary costs": {
        "title": "Quản lý tài chính: Cắt giảm chi phí thừa",
        "desc": "Đọc cẩm nang về quản lý chi tiêu và lập quỹ phòng hờ.",
    },
    "keep a fixed sleep schedule (even weekends)": {
        "title": "Xây dựng thói quen ngủ cố định (kể cả ngày nghỉ)",
        "desc": "Giúp cơ thể không bị rối loạn nhịp sinh học giữa các ca làm việc.",
    },
    "study an advanced work process": {
        "title": "Tìm hiểu một quy trình làm việc nâng cao",
        "desc": "Hỏi quản lý hoặc tài liệu công ty về nguyên lý hoạt động sâu hơn của máy móc bạn đang phụ trách.",
    },
    "organize a small outing with your group": {
        "title": "Tổ chức một buổi đi chơi nhỏ cùng phòng trọ/nhóm",
        "desc": "Tái tạo năng lượng và thắt chặt tình cảm anh em.",
    },
    "burnout check": {
        "title": "Kiểm soát và phòng ngừa kiệt sức",
        "desc": "Thực hành bài kiểm tra mức độ căng thẳng để xem bạn có đang quá sức không.",
    },
    "update your cv with internship experience": {
        "title": "Cập nhật hồ sơ xin việc (CV) với kinh nghiệm thực tập",
        "desc": "Ghi lại những thành tích, số liệu và kỹ năng bạn đã tích lũy được trong 3 tháng qua.",
    },
    "say thank you and stay connected": {
        "title": "Nói lời cảm ơn và giữ liên lạc",
        "desc": "Cảm ơn những người đã hướng dẫn bạn và xin thông tin liên lạc để duy trì kết nối đồng nghiệp.",
    },
}


class TaskService:
    @staticmethod
    async def get_tasks_for_user(
        db: AsyncSession,
        user_id: UUID,
        phase: Optional[InternPhase] = None
    ) -> List[Dict[str, Any]]:
        query = select(Task).where(Task.is_active == True)
        if phase:
            query = query.where(Task.phase == phase)
        query = query.order_by(Task.phase.asc(), Task.sort_order.asc())
        
        result = await db.execute(query)
        tasks = result.scalars().all()

        # Fetch completion status for user
        progress_res = await db.execute(
            select(UserTaskProgress).where(UserTaskProgress.user_id == user_id)
        )
        progress_map = {p.task_id: p.is_completed for p in progress_res.scalars().all()}

        output = []
        for t in tasks:
            clean_title = (t.title or "").strip()
            clean_desc = (t.description or "").strip()

            # Chuẩn hóa tiếng Việt cho các bản ghi seed tiếng Anh cũ trong Database
            translation = TASK_TRANSLATIONS.get(clean_title.lower())
            if translation:
                final_title = translation["title"]
                final_desc = translation["desc"]
            else:
                final_title = clean_title
                final_desc = clean_desc

            output.append({
                "id": str(t.id),
                "phase": t.phase.value if hasattr(t.phase, "value") else str(t.phase),
                "pillar": t.pillar.value if hasattr(t.pillar, "value") else str(t.pillar),
                "title": final_title,
                "description": final_desc,
                "duration_minutes": t.duration_minutes,
                "unlock_day": t.unlock_day,
                "sort_order": t.sort_order,
                "is_completed": progress_map.get(t.id, False)
            })

        return output

    @staticmethod
    async def get_tasks_summary(db: AsyncSession, user_id: UUID) -> Dict[str, Any]:
        """Thống kê tổng thể tiến độ hoàn thành theo từng chặng thực tập."""
        result = await db.execute(select(Task).where(Task.is_active == True))
        all_tasks = result.scalars().all()

        progress_res = await db.execute(
            select(UserTaskProgress).where(
                UserTaskProgress.user_id == user_id,
                UserTaskProgress.is_completed == True
            )
        )
        completed_task_ids = {p.task_id for p in progress_res.scalars().all()}

        phase_stats = {
            "preparation": {"total": 0, "completed": 0, "percentage": 0.0},
            "adaptation":  {"total": 0, "completed": 0, "percentage": 0.0},
            "sustain":     {"total": 0, "completed": 0, "percentage": 0.0},
        }

        total_tasks = len(all_tasks)
        total_completed = 0

        for t in all_tasks:
            ph = t.phase.value if hasattr(t.phase, "value") else str(t.phase)
            if ph in phase_stats:
                phase_stats[ph]["total"] += 1
                if t.id in completed_task_ids:
                    phase_stats[ph]["completed"] += 1
                    total_completed += 1

        for ph, data in phase_stats.items():
            if data["total"] > 0:
                data["percentage"] = round((data["completed"] / data["total"]) * 100, 1)

        overall_percentage = round((total_completed / total_tasks * 100), 1) if total_tasks > 0 else 0.0

        return {
            "total_tasks": total_tasks,
            "total_completed": total_completed,
            "overall_percentage": overall_percentage,
            "phases": phase_stats
        }

    @staticmethod
    async def toggle_task_completion(db: AsyncSession, user_id: UUID, task_id: UUID) -> bool:
        result = await db.execute(
            select(UserTaskProgress).where(
                UserTaskProgress.user_id == user_id,
                UserTaskProgress.task_id == task_id
            )
        )
        progress = result.scalar_one_or_none()
        if not progress:
            progress = UserTaskProgress(
                user_id=user_id,
                task_id=task_id,
                is_completed=True,
                completed_at=datetime.now(timezone.utc)
            )
            db.add(progress)
        else:
            progress.is_completed = not progress.is_completed
            progress.completed_at = datetime.now(timezone.utc) if progress.is_completed else None

        await db.commit()
        return progress.is_completed

    @staticmethod
    async def create_task(
        db: AsyncSession,
        phase: InternPhase,
        pillar: PillarType,
        title: str,
        description: str,
        duration_minutes: int = 10,
        unlock_day: int = 0,
        sort_order: int = 0
    ) -> Task:
        task = Task(
            phase=phase,
            pillar=pillar,
            title=title,
            description=description,
            duration_minutes=duration_minutes,
            unlock_day=unlock_day,
            sort_order=sort_order
        )
        db.add(task)
        await db.commit()
        await db.refresh(task)
        return task
