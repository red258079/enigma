# 🌟 ENIGMA — Ứng Dụng Chăm Sóc Sức Khỏe Tinh Thần & Hỗ Trợ Thực Tập Sinh

<p align="center">
  <img src="assets/images/logo.png" alt="Enigma Logo" width="120" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <b>Trợ lý thông minh đồng hành cùng sinh viên vượt qua "cú sốc thực tế" trong kỳ thực tập doanh nghiệp</b><br>
  <i>Tích hợp AI Agent, Kỹ thuật RAG (Retrieval-Augmented Generation) và Hệ thống theo dõi 5 trụ cột sức khỏe</i>
</p>

---

## 📌 Giới Thiệu Dự Án

Giai đoạn thực tập doanh nghiệp là bước chuyển mình quan trọng nhưng cũng mang lại nhiều áp lực và cú sốc môi trường (Reality Shock) cho sinh viên: thay đổi lịch sinh hoạt, deadline dồn dập, lo lắng đánh giá và thiếu kỹ năng thích nghi.

**ENIGMA** ra đời như một hệ sinh thái hỗ trợ toàn diện:
- **Theo dõi sức khỏe 5 trụ cột:** Giấc ngủ (Sleep), Thể chất (Physical), Tâm lý (Mental), Xã hội (Social) và Sự nghiệp (Career).
- **Gamification tạo động lực:** Điểm danh hàng ngày nhận thông điệp tích cực (Gacha Quote), chuỗi nhiệm vụ hướng dẫn thích nghi theo 3 giai đoạn (Chuẩn bị ➔ Hòa nhập ➔ Duy trì).
- **Trợ lý AI bám sát thực tế (RAG):** Trò chuyện và nhận lời khuyên từ AI được huấn luyện dựa trên kho Cẩm nang kinh nghiệm thực tế từ các thế hệ cựu sinh viên đi trước.
- **Đánh giá & Cảnh báo sớm kiệt sức (Burnout Alert):** Phân tích tự động từ nhật ký vi mô (Micro-journal) để phát hiện sớm dấu hiệu căng thẳng quá tải.
- **Bảo mật sinh trắc học & SOS Khẩn cấp:** Hỗ trợ khóa ứng dụng bằng vân tay/FaceID và đường dây nóng hỗ trợ tâm lý 24/7.

---

## 🏗️ Kiến Trúc Hệ Thống & Công Nghệ

```
┌─────────────────────────────────────────────────────────────┐
│                 Flutter Mobile Client                       │
│  (Dart, Provider, Dio Interceptors, Google Auth, LocalAuth) │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTP / REST (JWT Auth)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 FastAPI Backend Server                      │
│        (Python 3.10+, SQLAlchemy Async, Pydantic)           │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
               ▼                              ▼
┌──────────────────────────────┐ ┌────────────────────────────┐
│   PostgreSQL (Supabase)      │ │     ChromaDB + Gemini AI   │
│  (Users, Checkins, Journals, │ │ (Vector Embeddings, RAG    │
│   Tasks, Metrics, Badges)    │ │  Knowledge Base & Chatbot) │
└──────────────────────────────┘ └────────────────────────────┘
```

### 📱 Frontend (Mobile App)
- **Framework:** [Flutter](https://flutter.dev/) (Dart SDK)
- **State Management:** `Provider`
- **Mạng & API:** `Dio` với Interceptor tự động làm mới Access Token (JWT Token Auto-refresh)
- **Xác thực:** Google Sign-In, Email/Password, Sinh trắc học (`local_auth`)
- **Thông báo:** `firebase_messaging` (FCM) & `flutter_local_notifications`
- **Giao diện:** Modern Dark Mode, biểu đồ tiến độ `fl_chart`, hoạt ảnh mượt mà

### 🖥️ Backend (API Server)
- **Framework:** [FastAPI](https://fastapi.tiangolo.com/) (Python 3.10+, Asynchronous)
- **ORM & Database Driver:** `SQLAlchemy` (Async) + `asyncpg`
- **Database:** PostgreSQL (Hỗ trợ Supabase Cloud hoặc Local PostgreSQL)
- **Vector Database:** `ChromaDB` (Lưu trữ vector nhúng cẩm nang thực tập phục vụ RAG)
- **AI Core:** `google-generativeai` (Google Gemini Pro/Flash API)
- **Bảo mật:** `python-jose` (JWT Access & Refresh Token Rotation), `passlib` / `bcrypt` mã hóa mật khẩu
- **Dịch vụ thông báo:** Firebase Admin SDK & `aiosmtplib` gửi OTP qua Gmail

---

## 📁 Cấu Trúc Thư Mục Dự Án

```text
enigma/
├── android/                   # Cấu hình dự án Android Native
├── assets/                    # Hình ảnh, icon, âm thanh, cẩm nang tĩnh
├── backend/                   # Mã nguồn Backend FastAPI
│   ├── app/
│   │   ├── api/routes/        # Các API router (auth, checkin, journal, tasks, chat,...)
│   │   ├── core/              # Config, Security, Database connection
│   │   ├── models/            # SQLAlchemy Database Models
│   │   ├── schemas/           # Pydantic Schemas (Request/Response validation)
│   │   └── services/          # Business logic (Gemini RAG, User, Email, Firebase)
│   ├── chroma_db/             # Dữ liệu vector nhúng cẩm nang RAG
│   ├── .env                   # Biến môi trường Backend (Supabase, Gemini API, JWT)
│   ├── main.py                # Entry point FastAPI Server
│   ├── requirements.txt       # Danh sách thư viện Python
│   ├── run.ps1                # Script PowerShell khởi chạy Backend + Auto ADB reverse
│   └── schema.sql             # Script khởi tạo cơ sở dữ liệu PostgreSQL
├── docs/                      # Tài liệu thiết kế & Báo cáo tiến độ
├── lib/                       # Mã nguồn ứng dụng Flutter
│   ├── core/                  # API Client, Constants, Theme, Storage
│   ├── models/                # Data models
│   ├── providers/             # State providers & logic
│   ├── screens/               # Giao diện người dùng (Auth, Home, Checkin, Journal, Chat, Tasks, Profile)
│   └── main.dart              # Entry point Flutter
├── pubspec.yaml               # Danh sách thư viện Flutter
└── README.md                  # Hướng dẫn dự án
```

---

## 🚀 Hướng Dẫn Cài Đặt & Khởi Chạy

### 📋 Yêu Cầu Tiên Quyết (Prerequisites)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x trở lên)
- [Python](https://www.python.org/downloads/) (3.10 trở lên)
- [Android Studio](https://developer.android.com/studio) hoặc VS Code
- Thiết bị thật Android (kết nối qua cáp USB bật USB Debugging) hoặc Android Emulator

---

### 1️⃣ Khởi Chạy Backend (FastAPI)

Mở **PowerShell / Terminal** và di chuyển vào thư mục `backend`:

```powershell
cd backend

# Tạo và kích hoạt môi trường ảo (Virtual Environment)
python -m venv venv
.\venv\Scripts\Activate.ps1

# Cài đặt các thư viện phụ thuộc
pip install -r requirements.txt

# Kiểm tra file .env (Điền DATABASE_URL, GEMINI_API_KEY, SECRET_KEY)
```

**Khởi chạy server backend:**
```powershell
# Cách 1 (Khuyến nghị): Chạy script tự động (tự động cấu hình kết nối Android ADB reverse)
.\run.ps1

# Cách 2: Chạy trực tiếp qua Uvicorn
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

> 🌐 **Kiểm tra API Backend:** Mở trình duyệt truy cập Swagger UI tại: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

---

### 2️⃣ Khởi Chạy Mobile App (Flutter)

Mở một cửa sổ Terminal mới tại thư mục gốc dự án:

```powershell
# Cài đặt các gói thư viện Flutter
flutter pub get

# (Nếu dùng thiết bị Android cắm qua USB) Thiết lập chuyển tiếp cổng về máy tính:
adb reverse tcp:8000 tcp:8000

# Khởi chạy ứng dụng lên thiết bị hoặc máy ảo
flutter run
```

---

## 🔌 Danh Sách API Chính (Backend Endpoints)

| Nhóm | Phương thức | Endpoint | Mô tả |
| :--- | :--- | :--- | :--- |
| **Auth** | `POST` | `/auth/register` | Đăng ký tài khoản sinh viên mới |
| | `POST` | `/auth/login` | Đăng nhập lấy cặp JWT Token |
| | `POST` | `/auth/google` | Đăng nhập bằng Google ID Token |
| | `POST` | `/auth/refresh` | Cấp lại Access Token từ Refresh Token |
| | `GET` | `/auth/me` | Lấy thông tin tài khoản hiện tại |
| **Check-in** | `POST` | `/checkins` | Thực hiện điểm danh 5 trụ cột & nhận Gacha Quote |
| | `GET` | `/checkins/today` | Kiểm tra trạng thái điểm danh hôm nay |
| **Journal** | `POST` | `/journals` | Gửi nhật ký vi mô & nhận phân tích tâm lý từ AI |
| | `GET` | `/journals/history` | Lấy lịch sử nhật ký và biểu đồ cảm xúc |
| **Tasks** | `GET` | `/tasks` | Lấy danh sách nhiệm vụ thích nghi theo 3 chặng |
| | `PATCH` | `/tasks/{id}/toggle` | Đánh dấu hoàn thành / bỏ hoàn thành nhiệm vụ |
| **AI Chat** | `POST` | `/chat/sessions` | Tạo phiên trò chuyện mới với Trợ lý AI |
| | `POST` | `/chat/sessions/{id}/messages` | Gửi tin nhắn và nhận phản hồi RAG từ Gemini |

---

## 🛠️ Xử Lý Sự Cố Thường Gặp (Troubleshooting)

### ❓ 1. Lỗi "Không thể kết nối tới backend khi đăng ký / đăng nhập"
- **Nguyên nhân:** Điện thoại Android không thể truy cập `127.0.0.1:8000` của máy tính nếu chưa cấu hình cổng.
- **Cách khắc phục:** Chạy lệnh sau trong PowerShell để forward cổng sang điện thoại:
  ```powershell
  adb reverse tcp:8000 tcp:8000
  ```
  *(Script `backend/run.ps1` đã tích hợp tự động chạy lệnh này khi khởi động server).*

### ❓ 2. Lỗi cơ sở dữ liệu Supabase kết nối chậm / timeout
- Đảm bảo kết nối internet ổn định và chuỗi kết nối `DATABASE_URL` trong [backend/.env](file:///c:/Users/duyvs/StudioProjects/enigma%20-%20Copy/backend/.env) hợp lệ.

---

## 👥 Đội Ngũ Phát Triển

- **Dự án:** ENIGMA - Student Wellbeing & Mental Health Support System
- **Giảng viên hướng dẫn & Hội đồng bảo vệ đề tài**

---
<p align="center">Made with ❤️ for Students & Interns</p>
