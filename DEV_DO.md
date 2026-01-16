# DEV_DO.md - สรุปงานและสิ่งที่ต้องทำ

**อัปเดตล่าสุด:** 2026-01-16

---

## สถานะโปรเจกต์ปัจจุบัน

### ความคืบหน้า: 100% สมบูรณ์

โปรเจกต์ RiderApp พร้อมสำหรับการ deploy ขึ้น production แล้ว

| ส่วนประกอบ | สถานะ | รายละเอียด |
|-----------|--------|-----------|
| API Server | ✅ เสร็จสมบูรณ์ | 112 endpoints, 11 modules |
| Flutter App | ✅ เสร็จสมบูรณ์ | 28 หน้าจอ, ทุก role |
| Unit Tests | ✅ เสร็จสมบูรณ์ | 350+ tests |
| Widget Tests | ✅ เสร็จสมบูรณ์ | 57 tests ผ่านทั้งหมด |
| Integration Tests | ✅ เสร็จสมบูรณ์ | Auth, Incidents, Navigation flows |

---

## ฟีเจอร์ที่เสร็จแล้ว

### API Modules (11 modules, 112 endpoints)

| Module | Endpoints | คำอธิบาย |
|--------|-----------|---------|
| Auth | 12 | ลงทะเบียน, เข้าสู่ระบบ, JWT tokens |
| Users | 10 | จัดการผู้ใช้, อนุมัติ/ปฏิเสธ |
| Affiliations | 6 | หน่วยงานที่สังกัด |
| Incidents | 13 | รายงานเหตุการณ์, ไฟล์แนบ |
| Announcements | 11 | ประกาศ, กลุ่มเป้าหมาย |
| Notifications | 10 | Push notifications |
| Emergency | 13 | เบอร์ฉุกเฉิน, SOS alerts |
| Statistics | 11 | Dashboard, รายงานสถิติ |
| Chat | 8 | ส่งข้อความ real-time |
| Locations | 11 | ติดตามตำแหน่ง, แชร์ตำแหน่ง |
| Uploads | 7 | อัปโหลดไฟล์/รูปภาพ |

### Flutter Features (28 หน้าจอ)

| Feature | หน้าจอ | สถานะ |
|---------|--------|--------|
| Authentication | Login, Register, Pending Approval | ✅ |
| Home Screens | Rider, Volunteer, Police, Commander, Admin, Super Admin | ✅ |
| Incidents | List, Detail, Create, Edit, My Incidents | ✅ |
| Announcements | List, Detail | ✅ |
| Chat | Conversations, Chat Room | ✅ |
| Emergency | Contacts, SOS | ✅ |
| Profile | View, Edit | ✅ |
| Settings | Main, Notifications | ✅ |
| Notifications | List with swipe-to-delete | ✅ |
| Locations | Sharing, Nearby Users, Active Users | ✅ |
| Admin | User Management, Approvals, Stats, Config | ✅ |

### Real-time Features

- ✅ Socket.io สำหรับ Chat และ Notifications
- ✅ Location tracking แบบ real-time
- ✅ Push notifications ผ่าน Firebase Cloud Messaging

### Role-Based Chat Groups

ระบบ Chat มีกลุ่มสนทนาตาม Role ดังนี้:

| กลุ่ม | ระดับขั้นต่ำ | คำอธิบาย |
|-------|-------------|---------|
| General | Rider | ผู้ใช้ทุกคนเข้าได้ |
| อส. (Volunteer) | Volunteer | อาสาสมัครขึ้นไป |
| Police | Police | ตำรวจขึ้นไป |
| Commander | Commander | ผู้บังคับบัญชาขึ้นไป |
| Admin | Admin | ผู้ดูแลระบบขึ้นไป |

API Endpoints:
- `GET /api/v1/chat/groups` - รายการกลุ่มที่เข้าถึงได้
- `POST /api/v1/chat/groups/auto-join` - เข้าร่วมกลุ่มทั้งหมดอัตโนมัติ
- `POST /api/v1/chat/groups/:id/join` - เข้าร่วมกลุ่มที่ระบุ

### File Upload

- ✅ Profile image upload พร้อม crop
- ✅ Chat image sharing พร้อม full-screen viewer
- ✅ Incident attachments (สูงสุด 5 ไฟล์)

---

## สิ่งที่ต้องทำด้วยตนเอง

### 1. ตั้งค่า Firebase (จำเป็น)

#### Android
1. ไปที่ [Firebase Console](https://console.firebase.google.com/)
2. สร้างโปรเจกต์ใหม่หรือใช้โปรเจกต์ที่มีอยู่
3. เพิ่ม Android app ด้วย package name: `com.example.riderapp` (หรือที่กำหนดเอง)
4. ดาวน์โหลด `google-services.json`
5. วางไฟล์ที่ `riderapp/android/app/google-services.json`

#### iOS
1. เพิ่ม iOS app ใน Firebase Console
2. ดาวน์โหลด `GoogleService-Info.plist`
3. วางไฟล์ที่ `riderapp/ios/Runner/GoogleService-Info.plist`

#### API Server
1. ไปที่ Firebase Console > Project Settings > Service Accounts
2. Generate new private key
3. บันทึกไฟล์ JSON ไว้ที่ `api/config/firebase-service-account.json`
4. อัปเดต `.env`:
```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

### 2. ตั้งค่า Google Maps API Key (ถ้าต้องการใช้แผนที่)

#### Android
แก้ไข `riderapp/android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

#### iOS
แก้ไข `riderapp/ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

### 3. ตั้งค่า Environment Variables

#### API Server (`api/.env`)
```env
# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=riderapp

# JWT
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
JWT_REFRESH_SECRET=your-refresh-secret-key-min-32-chars
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Server
PORT=3000
NODE_ENV=production

# Firebase (ดูหัวข้อ 1)
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=

# File Uploads
UPLOAD_MAX_SIZE=52428800
UPLOAD_ALLOWED_TYPES=image/jpeg,image/png,image/gif,image/webp
```

#### Flutter App
แก้ไข `riderapp/lib/core/constants/api_endpoints.dart`:
```dart
static const String baseUrl = 'https://your-production-api.com/api/v1';
```

### 4. รัน Database Migrations

```bash
cd api
node src/database/migrate.js
```

### 5. Seed Test Users (ถ้าต้องการ)

```bash
# เชื่อมต่อ database และรัน SQL
mysql -h localhost -u root -p riderapp < seed_users.sql
```

หรือสร้างผู้ใช้ผ่าน API register endpoint

---

## คำสั่งที่ใช้บ่อย

### Development

```bash
# รัน API Server (development)
cd api && npm run dev

# รัน Flutter App
cd riderapp && flutter run

# รัน Flutter Web
cd riderapp && flutter run -d chrome
```

### Testing

```bash
# รัน Flutter unit tests
cd riderapp && flutter test

# รัน Flutter integration tests (ต้องรัน API server ก่อน)
cd riderapp && flutter test integration_test/

# รัน API tests
cd api && npm test

# ตรวจสอบ code quality
cd riderapp && flutter analyze
```

### Build

```bash
# Build Android APK
cd riderapp && flutter build apk --release

# Build Android App Bundle (สำหรับ Play Store)
cd riderapp && flutter build appbundle --release

# Build iOS (ต้องใช้ Mac)
cd riderapp && flutter build ios --release
```

### Database

```bash
# ดูสถานะ migrations
cd api && node src/database/migrate.js status

# รัน pending migrations
cd api && node src/database/migrate.js

# Rollback migration ล่าสุด
cd api && node src/database/migrate.js down

# Reset database (ลบทั้งหมดแล้วสร้างใหม่)
cd api && node src/database/migrate.js fresh
```

---

## Test Users (สำหรับทดสอบ)

| Role | เบอร์โทร | รหัสผ่าน | ชื่อ |
|------|---------|---------|------|
| Rider | `0811111111` | `Test1234` | Test Rider |
| Volunteer | `0822222222` | `Test1234` | Test Volunteer |
| Police | `0833333333` | `Test1234` | Test Police |
| Commander | `0866666666` | `Test1234` | Test Commander |
| Admin | `0844444444` | `Test1234` | Test Admin |
| Super Admin | `0855555555` | `Test1234` | Test Super Admin |

---

## โครงสร้างโฟลเดอร์

```
riderapp/
├── api/                          # Node.js API Server
│   ├── src/
│   │   ├── config/              # Configuration files
│   │   ├── constants/           # Role, status enums
│   │   ├── database/migrations/ # SQL migrations (15 files)
│   │   ├── middleware/          # Auth, role, error handlers
│   │   ├── modules/             # Feature modules (11 modules)
│   │   ├── routes/              # Route aggregation
│   │   ├── socket/              # Socket.io handlers
│   │   └── utils/               # Helper utilities
│   └── uploads/                 # Uploaded files directory
│
├── riderapp/                     # Flutter Mobile App
│   ├── lib/
│   │   ├── core/                # Core utilities
│   │   │   ├── constants/       # API endpoints, app constants
│   │   │   ├── network/         # Dio HTTP client
│   │   │   ├── storage/         # Secure storage
│   │   │   ├── theme/           # Material 3 theming
│   │   │   ├── socket/          # Socket.io client
│   │   │   ├── upload/          # File upload service
│   │   │   ├── notifications/   # FCM service
│   │   │   └── deep_link/       # Deep link handler
│   │   ├── features/            # Feature modules
│   │   │   ├── auth/            # Authentication
│   │   │   ├── home/            # Home screens (6 roles)
│   │   │   ├── incidents/       # Incident reporting
│   │   │   ├── announcements/   # Announcements
│   │   │   ├── chat/            # Real-time chat
│   │   │   ├── emergency/       # Emergency contacts & SOS
│   │   │   ├── profile/         # User profile
│   │   │   ├── settings/        # App settings
│   │   │   ├── notifications/   # Notifications UI
│   │   │   ├── locations/       # Location tracking
│   │   │   └── admin/           # Admin screens
│   │   ├── navigation/          # GoRouter configuration
│   │   └── shared/              # Shared models, widgets
│   ├── test/                    # Unit & Widget tests
│   ├── integration_test/        # Integration tests
│   └── assets/translations/     # i18n (TH/EN)
│
├── CLAUDE.md                    # คำแนะนำสำหรับ Claude Code
├── PLAN.md                      # แผนการพัฒนา
├── PROGRESS.md                  # บันทึกความคืบหน้า
└── DEV_DO.md                    # ไฟล์นี้
```

---

## Checklist ก่อน Deploy Production

- [ ] ตั้งค่า Firebase และวางไฟล์ config
- [ ] ตั้งค่า Google Maps API Key
- [ ] อัปเดต API base URL สำหรับ production
- [ ] ตั้งค่า environment variables ทั้งหมด
- [ ] รัน database migrations บน production server
- [ ] ทดสอบ Push Notifications
- [ ] ทดสอบ Google Maps
- [ ] Build และ sign APK/IPA
- [ ] ทดสอบบนอุปกรณ์จริง
- [ ] อัปโหลดขึ้น Play Store / App Store

---

## ติดต่อและช่วยเหลือ

- ดูรายละเอียดเพิ่มเติมที่ `CLAUDE.md`
- ดูแผนการพัฒนาที่ `PLAN.md`
- ดูบันทึกการทำงานที่ `PROGRESS.md`

---

*สร้างโดย Claude Code - 2026-01-16*
