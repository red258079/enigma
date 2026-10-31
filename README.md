# 🌟 ENIGMA — Hệ Sinh Thái Hỗ Trợ Sức Khỏe Tinh Thần & Quản Trị Thực Tập Doanh Nghiệp

<p align="center">
  <img src="https://raw.githubusercontent.com/iamIKY2/mentality/main/Enigma/assets/images/logo.png" alt="Enigma Logo" width="110" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <b>Hệ thống đồng hành toàn diện giúp sinh viên vượt qua "Cú sốc thực tế" (Reality Shock) trong kỳ thực tập</b><br>
  <i>Tích hợp Trợ lý AI Agent RAG, Theo dõi 5 Trụ cột Sức khỏe, Trung tâm Cảnh báo Kiệt sức & Cổng Quản trị Doanh nghiệp</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/FastAPI-0.111.0-009688?logo=fastapi&logoColor=white" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/Python-3.11.9-3776AB?logo=python&logoColor=white" alt="Python"/>
  <img src="https://img.shields.io/badge/PostgreSQL-Supabase-336791?logo=postgresql&logoColor=white" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/ChromaDB-RAG_Vector-FF6F00" alt="ChromaDB"/>
  <img src="https://img.shields.io/badge/Google_Gemini-AI_Agent-8E75C2?logo=google&logoColor=white" alt="Gemini"/>
  <img src="https://img.shields.io/badge/Deployment-Render_Cloud-46E3B7?logo=render&logoColor=white" alt="Render"/>
</p>

---

## 📌 1. Giới Thiệu Dự Án

Giai đoạn thực tập tại các nhà máy, tập đoàn công nghệ (như **LG Display**, Samsung, FPT,...) là bước ngoặt quan trọng của sinh viên, nhưng cũng là thời điểm dễ phát sinh **"Cú sốc thực tế" (Reality Shock)**:
- Lệch nhịp sinh học do làm việc theo ca kíp (ca ngày 12h, ca đêm 20h - 08h).
- Đau mỏi cơ xương khớp do mang giày chống tĩnh điện (ESD), đứng liên tục trong phòng sạch (Cleanroom).
- Áp lực kỷ luật nhà máy, căng thẳng giao tiếp và mâu thuẫn sinh hoạt ký túc xá.

**ENIGMA** được thiết kế như một **Hệ sinh thái kép (Dual-Ecosystem)** gồm:
1. **Mobile App (Dành cho Sinh viên thực tập):** Trợ lý số bỏ túi theo dõi 5 trụ cột sức khỏe, nhắc nhở giấc ngủ ca đêm, điểm danh Gacha Quote giải tỏa tâm lý, nhật ký vi mô tự động phát hiện stress và chatbot AI tư vấn kinh nghiệm 24/7.
2. **Admin Web Portal (Dành cho Cố vấn & Doanh nghiệp):** Cổng điều hành thông minh, gom nhóm sinh viên theo từng **Đoàn trường đại học liên kết & Nơi tiếp nhận**, dashboard radar 5 trụ cột, trung tâm can thiệp sớm kiệt sức (Burnout Alert Center) và phát loa thông báo đẩy khẩn cấp.

---

## 🏗️ 2. Kiến Trúc Hệ Thống (System Architecture)

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             CLIENT ECOSYSTEM                                     │
│                                                                                  │
│   📱 FLUTTER MOBILE APP (Android/iOS)       💻 ADMIN WEB PORTAL (Dark Glassmorphism)  │
│   - Student Life-Log & Sleep Sensor         - Real-time Analytics & Radar Charts │
│   - Check-in Gacha Quotes                   - University Cohorts Grouping        │
│   - 3-Phase Adaptation Tasks                - Burnout Alert & 1-Click Intervene  │
│   - 24/7 RAG AI Chat Assistant              - Broadcast & Knowledge Manager      │
└───────────────────────────┬──────────────────────────────────┬───────────────────┘
                            │ REST APIs / JSON (Bearer JWT)    │ Static Mount (/admin-web)
                            ▼                                  ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                       FASTAPI BACKEND SERVICE (Python 3.11)                      │
│                                                                                  │
│   [Auth & RBAC]        [Life-Log & Geofence]   [Admin & Analytics Service]       │
│   - Google OAuth       - Sleep Auto-detection  - Real data aggregates            │
│   - JWT Rotation       - GPS Geofence Check    - Burnout rules engine            │
│                                                                                  │
│   [AI & RAG Engine]                            [Notification Dispatcher]         │
│   - Google Gemini Pro/Flash                    - Firebase Cloud Messaging (FCM)  │
│   - ChromaDB Vector Store                      - Async SMTP Email Service        │
└───────────────────────────┬──────────────────────────────────┬───────────────────┘
                            │                                  │
                            ▼                                  ▼
┌──────────────────────────────────────────────┐  ┌────────────────────────────────┐
│            POSTGRESQL (SUPABASE)             │  │      CHROMADB VECTOR STORE     │
│ - Users & Intern Profiles (Workplace, Shifts)│  │ - 19+ Chunks Cẩm nang thực tập │
│ - Daily Check-ins, Journals & Life Logs      │  │ - Vector Embeddings đa chiều   │
│ - 3-Phase Tasks, Streaks & Interventions     │  │ - Semantic Search cho AI RAG   │
└──────────────────────────────────────────────┘  └────────────────────────────────┘
```

---

## 🚀 3. Điểm Nổi Bật Của Hệ Thống

### 3.1. Phía Sinh Viên (Mobile App)
* **Theo dõi 5 Trụ Cột Sức Khỏe (5 Pillars):** Giấc ngủ (Sleep), Thể chất (Physical), Tâm lý (Mental), Xã hội (Social), Sự nghiệp (Career).
* **Điểm danh Gacha Quote:** Mỗi ngày điểm danh nhận 1 câu trích dẫn truyền cảm hứng giải tỏa stress và duy trì chuỗi ngọn lửa (Streak).
* **Nhật Ký Vi Mô & Tự Động Phân Tích Cảm Xúc (Micro-journaling):** AI phân tích sắc thái cảm xúc (Sentiment Analysis) và ghi nhận mức độ căng thẳng.
* **Theo Dõi Giấc Ngủ Thông Minh (Sleep Tracking v2):** Hỗ trợ đặc thù sinh viên làm ca đêm (ngủ bù ban ngày), tích hợp cảm biến gia tốc và tự động đồng bộ.
* **Trợ Lý AI Đồng Hành (RAG Chat):** Chatbot sử dụng dữ liệu Cẩm nang kinh nghiệm thực tế (Quy tắc 5S, an toàn phòng sạch, đối phó mỏi chân khi mang giày ESD, cân bằng tiền bạc,...).
* **Nhiệm Vụ Thích Nghi 3 Giai Đoạn:** Lộ trình 30 ngày gồm:
  1. *Giai đoạn 1: Chuẩn bị (Preparation)* — Tuần đầu làm quen văn hóa và an toàn.
  2. *Giai đoạn 2: Hòa nhập (Adaptation)* — Thích nghi nhịp ca kíp và môi trường làm việc.
  3. *Giai đoạn 3: Duy trì (Sustain)* — Nâng cao hiệu suất và chăm sóc bản thân bền vững.

### 3.2. Phía Cố Vấn & Quản Lý (Admin Web Portal)
* **Gom Nhóm Quản Lý Theo Trường Đại Học & Nơi Thực Tập (University Cohorts):**
  * Tự động phân chia sinh viên thành từng khối trường trực quan (VD: *Đại Học Bình Dương ➔ Thực tập tại LG Display*, *ĐH Bách Khoa Hà Nội ➔ LG Display*, *ĐH Công Nghiệp ➔ LG Display*...).
  * Thống kê nhanh từng trường: Tổng sinh viên, số SV làm ca đêm, số ca cần can thiệp tâm lý.
  * Thanh Quick Filter Chips và Bộ lọc Dropdown 2 tầng giúp chuyển đổi giữa các trường chỉ với 1 click.
  * Cho phép chuyển đổi linh hoạt giữa chế độ **[ Theo Trường ]** và **[ Bảng Toàn Bộ ]**.
* **Trung Tâm Cảnh Báo Kiệt Sức (Burnout Alert Center):**
  * Tự động quét và gắn cờ các sinh viên có dấu hiệu quá tải (Stress level ≥ 4 hoặc giấc ngủ < 5h/ngày).
  * **Hộp thoại Can thiệp Tâm lý 1-Click (Intervention Modal):** Cố vấn có thể chọn nhanh lời khuyên mẫu chuyên gia (Hồi phục ca đêm, Xả stress, Hẹn gặp 1-1, Giảm đau mỏi ESD) và gửi tức thì qua Push Notification & Hộp thư sinh viên.
* **Bảng Điều Khiển Trực Quan (Real-time Analytics):**
  * Biểu đồ Radar 5 Trụ cột toàn khóa.
  * Biểu đồ Phân bổ Mức độ Căng thẳng & Ca kíp.
  * Hoạt động điểm danh & Gacha quote gần nhất lấy từ dữ liệu thực tế.

---

## 📁 4. Cấu Trúc Mã Nguồn

```text
enigma/
├── android/                         # Cấu hình dự án Android (Gradle, Manifest, Permissions)
├── assets/                          # Assets đồ họa, logo, font, dữ liệu tĩnh
├── backend/                         # MÃ NGUỒN BACKEND FASTAPI
│   ├── admin_web/                   # Web Portal Quản trị (HTML5 / Vanilla CSS / Modern JS)
│   │   ├── index.html               # Giao diện chính Admin Portal (Responsive, Dark Theme)
│   │   ├── styles.css               # Hệ thống Design Tokens, Glassmorphism, animations
│   │   └── app.js                   # Logic kết nối API, Charts, University Grouping, Modals
│   ├── app/
│   │   ├── api/routes/              # API Endpoints
│   │   │   ├── admin.py             # Router quản trị (Stats, Users, Burnout, Interventions)
│   │   │   ├── auth.py              # Đăng ký, đăng nhập JWT, Google OAuth
│   │   │   ├── checkins.py          # Điểm danh 5 trụ cột & Gacha Quote
│   │   │   ├── journals.py          # Nhật ký vi mô & phân tích tâm lý
│   │   │   ├── life_logs.py         # Theo dõi giấc ngủ & sinh hoạt hàng ngày
│   │   │   ├── tasks.py             # Nhiệm vụ 3 giai đoạn
│   │   │   ├── chat.py              # Phiên hội thoại AI Chat RAG
│   │   │   ├── handbook.py          # Cẩm nang thực tập sinh
│   │   │   ├── workplace.py         # Quản lý địa điểm công ty, GPS Geofence & ca kíp
│   │   │   └── notifications.py     # Lịch sử thông báo & phát loa
│   │   ├── core/                    # Cấu hình hệ thống, biến môi trường, bảo mật
│   │   ├── db/                      # Kết nối Database PostgreSQL & SQLAlchemy Models
│   │   ├── schemas/                 # Pydantic Schemas (Input/Output validation)
│   │   └── services/                # Nghiệp vụ: Gemini AI, RAG, FCM, Email, Sync
│   ├── chroma_db/                   # Thư mục lưu trữ vector database ChromaDB
│   ├── main.py                      # File khởi chạy FastAPI Server & Static Mount
│   ├── requirements.txt             # Danh sách thư viện Python
│   ├── runtime.txt                  # Phiên bản Python (3.11.9) dùng cho Render Cloud
│   └── schema.sql                   # Cấu trúc SQL Database DDL
├── docs/                            # Tài liệu nghiên cứu & đặc tả yêu cầu
├── lib/                             # MÃ NGUỒN FLUTTER CLIENT
│   ├── core/                        # API Client (Dio Interceptors), Storage, Themes, Geofence
│   ├── models/                      # Dart Data Models
│   ├── providers/                   # Quản lý State (Auth, Chat, App State)
│   ├── navigation/                  # Navigation & Bottom Bar sinh viên
│   ├── screens/                     # Màn hình chức năng (Home, Chat, Tasks, LifeLog, Checkin)
│   ├── widgets/                     # Các UI Component tái sử dụng
│   └── main.dart                    # Điểm khởi chạy ứng dụng Flutter
├── pubspec.yaml                     # Cấu hình dependencies Flutter
└── README.md                        # Hướng dẫn dự án toàn diện
```

---

## 🛠️ 5. Hướng Dẫn Cài Đặt & Chạy Hệ Thống

### 5.1. Yêu cầu môi trường
* **Python:** 3.10 hoặc 3.11 (Khuyến nghị Python 3.11.9)
* **Flutter SDK:** 3.x trở lên
* **PostgreSQL:** Tài khoản Supabase hoặc PostgreSQL Local
* **Git**

---

### 5.2. Khởi chạy Backend & Admin Web

1. **Di chuyển vào thư mục backend:**
   ```bash
   cd backend
   ```

2. **Tạo và kích hoạt môi trường ảo (Virtual Environment):**
   ```bash
   # Windows (PowerShell)
   python -m venv venv
   .\venv\Scripts\Activate.ps1

   # Linux / macOS
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Cài đặt thư viện dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Cấu hình file biến môi trường `.env`** (Tạo file `backend/.env`):
   ```ini
   DATABASE_URL=postgresql+asyncpg://postgres:YOUR_PASSWORD@YOUR_HOST:5432/YOUR_DB
   SECRET_KEY=enigma_super_secret_jwt_key_2026
   GEMINI_API_KEY=YOUR_GOOGLE_GEMINI_API_KEY
   SMTP_USER=your_email@gmail.com
   SMTP_PASSWORD=your_app_password
   DEBUG=True
   ```

5. **Khởi động server:**
   ```bash
   python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

6. **Truy cập ứng dụng:**
   * 🖥️ **Admin Web Portal:** [http://localhost:8000/admin-web/](http://localhost:8000/admin-web/)
   * 📚 **API Swagger UI:** [http://localhost:8000/docs](http://localhost:8000/docs)
   * 🩺 **Health Check:** [http://localhost:8000/](http://localhost:8000/)

---

### 5.3. Khởi chạy Ứng dụng Mobile Flutter

1. **Di chuyển về thư mục gốc dự án:**
   ```bash
   cd ..
   ```

2. **Cài đặt các gói Flutter:**
   ```bash
   flutter pub get
   ```

3. **Chuyển tiếp cổng ADB (Dành cho điện thoại Android cắm cáp USB):**
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```

4. **Khởi chạy ứng dụng:**
   ```bash
   flutter run
   ```

---

## ☁️ 6. Triển Khai Lên Render Cloud (Production Deployment)

Hệ thống được cấu hình sẵn sàng triển khai trên **Render.com Web Service**:

* **Repository triển khai:** `https://github.com/iamIKY2/mentality.git`
* **Root Directory trên Render:** `backend` (hoặc để trống nếu chạy build script từ thư mục gốc)
* **Build Command:** `pip install -r requirements.txt`
* **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
* **Python Runtime:** Tự động nhận diện từ [backend/runtime.txt](file:///d:/enigma/backend/runtime.txt) (`python-3.11.9`)
* **Environment Variables trên Render:**
  * `DATABASE_URL`: Chuỗi kết nối PostgreSQL Supabase (chế độ Session Pooler port 5432 hoặc 6543)
  * `SECRET_KEY`: Khóa bí mật JWT
  * `GEMINI_API_KEY`: API Key từ Google AI Studio
  * `PYTHON_VERSION`: `3.11.9`

> 💡 **Lưu ý:** Khi deploy thành công trên Render:
> * API Base: `https://mentality-38jh.onrender.com`
> * Web Admin Portal: `https://mentality-38jh.onrender.com/admin-web/`
> * JavaScript [app.js](file:///d:/enigma/backend/admin_web/app.js) tự động nhận diện `window.location.origin` nên sẽ kết nối đúng với server cloud mà không cần sửa code.

---

## 📡 7. Danh Mục API Endpoints Chính

| Phân hệ | Phương thức | Đường dẫn (Path) | Mục đích sử dụng |
| :--- | :---: | :--- | :--- |
| **Auth** | `POST` | `/auth/register` | Đăng ký tài khoản sinh viên mới |
| | `POST` | `/auth/login` | Đăng nhập cấp cặp Access/Refresh Token |
| | `POST` | `/auth/google` | Xác thực đăng nhập Google Sign-In |
| | `POST` | `/auth/refresh` | Làm mới Access Token |
| | `GET` | `/auth/me` | Lấy hồ sơ người dùng đăng nhập |
| **Check-in** | `POST` | `/checkins` | Điểm danh 5 trụ cột & nhận ngẫu nhiên Gacha Quote |
| | `GET` | `/checkins/today` | Kiểm tra trạng thái điểm danh trong ngày |
| **Journal** | `POST` | `/journals` | Ghi nhật ký vi mô & phân tích tâm lý bằng AI |
| | `GET` | `/journals/history` | Lịch sử nhật ký và biểu đồ cảm xúc gần nhất |
| **Life Log** | `POST` | `/life-logs/sleep` | Ghi nhận dữ liệu giấc ngủ (hỗ trợ ca đêm) |
| | `GET` | `/life-logs/today` | Tổng quan chỉ số sinh hoạt trong ngày |
| **Tasks** | `GET` | `/tasks` | Danh sách nhiệm vụ theo 3 chặng (Chuẩn bị, Hòa nhập, Duy trì) |
| | `PATCH` | `/tasks/{id}/toggle` | Đánh dấu hoàn thành / bỏ hoàn thành nhiệm vụ |
| **AI Chat** | `POST` | `/chat/sessions` | Khởi tạo phiên tư vấn tâm lý mới |
| | `POST` | `/chat/sessions/{id}/messages` | Nhắn tin với Trợ lý AI (Truy vấn RAG Cẩm nang) |
| **Handbook** | `GET` | `/handbook` | Đọc danh mục cẩm nang kinh nghiệm thực tập |
| **Workplace**| `GET` | `/workplace/companies` | Danh sách các công ty đối tác & tọa độ nhà máy |
| | `PUT` | `/workplace/profile` | Cập nhật ca làm việc (ca ngày/ca đêm) & vị trí GPS |
| **Admin** | `GET` | `/admin/stats` | Tổng hợp chỉ số KPI điều hành toàn hệ thống |
| | `GET` | `/admin/users` | Danh sách sinh viên (phục vụ gom nhóm trường & công ty) |
| | `GET` | `/admin/users/{id}` | Chi tiết hồ sơ, lịch sử nhật ký & điểm số 5 trụ cột |
| | `GET` | `/admin/burnout-alerts` | Danh sách cảnh báo sinh viên có nguy cơ kiệt sức |
| | `POST` | `/admin/interventions` | Gửi can thiệp tâm lý & lời khuyên khẩn cấp (Push Notification) |
| | `GET` | `/admin/feed` | Hoạt động điểm danh & Gacha quote thực tế thời gian thực |

---

## 🔒 8. An Toàn Thông Tin & Quyền Riêng Tư

* **Mã Hóa Dữ Liệu:** Mật khẩu được mã hóa an toàn bằng thuật toán `bcrypt` với muối ngẫu nhiên (salt).
* **Token Rotation:** Cặp JWT Token gồm Access Token (hạn 60 phút) và Refresh Token (hạn 30 ngày) tự động xoay vòng.
* **Quyền Riêng Tư:** Nhật ký vi mô và tâm sự của sinh viên được bảo mật, quản trị viên chỉ tiếp cận các chỉ số tổng hợp cảnh báo nguy cơ kiệt sức để kịp thời trợ giúp, không can thiệp trái phép vào đời tư cá nhân.
* **Cơ Chế Khóa Sinh Trắc Học:** Ứng dụng di động hỗ trợ xác thực vân tay / Face ID trước khi mở app.

---

## 👥 9. Bản Quyền & Đội Ngũ Phát Triển

* **Dự án:** **ENIGMA — Student Wellbeing & Internship Adaptation Ecosystem**
* **Mục tiêu:** Đồng hành và nâng đỡ tinh thần cho hàng ngàn sinh viên vững bước trên con đường lập nghiệp.

---
<p align="center">
  <b>ENIGMA Team © 2026 — Built with Passion & Empathy for Interns</b>
</p>
