# Deployment Guide - RiderApp

คู่มือการ Deploy RiderApp ขึ้น Staging Server

## Server Information

| Environment | URL | Port |
|-------------|-----|------|
| Development | `http://localhost:4000/api/v1` | 4000 |
| Staging | `https://dev-rider.makerrobotics.co.th/api/v1` | 443 (HTTPS) |
| Production | `https://api.riderapp.com/api/v1` | 443 (HTTPS) |

## Prerequisites

### Server Requirements
- Node.js 18+
- npm 9+
- MySQL/MariaDB 10.5+
- PM2 (Process Manager)
- Nginx (Reverse Proxy)

### Database
- Host: `makerrobotics.co.th`
- Database: `riderapp`
- User: `riderapp`

---

## 1. Deploy API to Staging Server

### 1.1 SSH เข้า Server
```bash
ssh user@dev-rider.makerrobotics.co.th
```

### 1.2 Clone/Pull Repository
```bash
# ครั้งแรก
cd /var/www
git clone https://github.com/jcubuntu/riderapp.git
cd riderapp

# ครั้งถัดไป (update)
cd /var/www/riderapp
git pull origin master
```

### 1.3 Install Dependencies
```bash
cd api
npm install --production
```

### 1.4 Configure Environment
```bash
# สร้าง/แก้ไขไฟล์ .env
cp .env.example .env
nano .env
```

**ตั้งค่า .env สำหรับ Staging:**
```env
# Server Configuration
NODE_ENV=production
PORT=4000
API_VERSION=v1

# Database Configuration
DB_HOST=makerrobotics.co.th
DB_PORT=3306
DB_USER=riderapp
DB_PASSWORD=b7xYU6!qhXda
DB_NAME=riderapp
DB_CONNECTION_LIMIT=20

# JWT Configuration
JWT_SECRET=<STRONG_SECRET_KEY>
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=<STRONG_REFRESH_SECRET>
JWT_REFRESH_EXPIRES_IN=30d

# CORS Configuration
CORS_ORIGIN=https://dev-rider.makerrobotics.co.th

# Socket.IO Configuration
SOCKET_CORS_ORIGIN=https://dev-rider.makerrobotics.co.th

# Logging
LOG_LEVEL=info
LOG_DIR=./logs

# Firebase (Push Notifications)
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

### 1.5 Run Database Migrations
```bash
cd api
node src/database/migrate.js status   # ตรวจสอบสถานะ
node src/database/migrate.js          # รัน migrations
```

### 1.6 Start with PM2
```bash
# ครั้งแรก
pm2 start npm --name "riderapp-api" -- start
pm2 save

# Restart (หลัง update)
pm2 restart riderapp-api

# ดู logs
pm2 logs riderapp-api

# ดู status
pm2 status
```

### 1.7 Configure Nginx
```nginx
# /etc/nginx/sites-available/dev-rider.makerrobotics.co.th

server {
    listen 80;
    server_name dev-rider.makerrobotics.co.th;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name dev-rider.makerrobotics.co.th;

    ssl_certificate /etc/letsencrypt/live/dev-rider.makerrobotics.co.th/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dev-rider.makerrobotics.co.th/privkey.pem;

    # API Proxy
    location /api {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Socket.IO
    location /socket.io {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
# Enable site และ reload nginx
sudo ln -s /etc/nginx/sites-available/dev-rider.makerrobotics.co.th /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 2. Build Flutter App for Staging

### 2.1 Switch to Staging URL
แก้ไข `lib/core/constants/api_endpoints.dart`:
```dart
/// Current base URL
static String baseUrl = stagingBaseUrl;  // เปลี่ยนจาก devBaseUrl
```

หรือใช้ environment variable:
```bash
flutter run --dart-define=API_ENV=staging
```

### 2.2 Build Android APK
```bash
cd riderapp

# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 2.3 Build iOS
```bash
cd riderapp

# Build for testing
flutter build ios --debug

# Build for release (ต้องมี Apple Developer Account)
flutter build ios --release

# เปิด Xcode เพื่อ Archive
open ios/Runner.xcworkspace
```

---

## 3. Quick Deploy Script

สร้างไฟล์ `deploy-staging.sh`:
```bash
#!/bin/bash
set -e

echo "=== Deploying RiderApp API to Staging ==="

# Variables
SERVER="user@dev-rider.makerrobotics.co.th"
APP_DIR="/var/www/riderapp"

# Deploy
ssh $SERVER << 'ENDSSH'
    cd /var/www/riderapp

    echo "Pulling latest code..."
    git pull origin master

    echo "Installing dependencies..."
    cd api && npm install --production

    echo "Running migrations..."
    node src/database/migrate.js

    echo "Restarting API..."
    pm2 restart riderapp-api

    echo "Checking status..."
    pm2 status

    echo "=== Deploy Complete ==="
ENDSSH
```

```bash
chmod +x deploy-staging.sh
./deploy-staging.sh
```

---

## 4. Verify Deployment

### 4.1 Test API Health
```bash
curl https://dev-rider.makerrobotics.co.th/api/v1/health
```

### 4.2 Test Login
```bash
curl -X POST https://dev-rider.makerrobotics.co.th/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone": "0811111111", "password": "Test1234"}'
```

### 4.3 Check PM2 Logs
```bash
ssh user@dev-rider.makerrobotics.co.th "pm2 logs riderapp-api --lines 50"
```

---

## 5. Rollback

### 5.1 Rollback Code
```bash
ssh user@dev-rider.makerrobotics.co.th << 'ENDSSH'
    cd /var/www/riderapp
    git log --oneline -5                    # ดู commits
    git reset --hard <PREVIOUS_COMMIT_SHA>  # rollback
    cd api && npm install --production
    pm2 restart riderapp-api
ENDSSH
```

### 5.2 Rollback Database
```bash
cd api
node src/database/migrate.js down   # rollback last batch
```

---

## 6. Test Users (Staging)

| Role | Phone | Password |
|------|-------|----------|
| Rider | `0811111111` | `Test1234` |
| Volunteer | `0822222222` | `Test1234` |
| Police | `0833333333` | `Test1234` |
| Admin | `0844444444` | `Test1234` |
| Super Admin | `0855555555` | `Test1234` |
| Commander | `0866666666` | `Test1234` |

---

## 7. Troubleshooting

### API ไม่ตอบ
```bash
# ตรวจสอบ process
pm2 status

# ดู logs
pm2 logs riderapp-api --err --lines 100

# Restart
pm2 restart riderapp-api
```

### Database Connection Error
```bash
# ทดสอบ connection
mysql -h makerrobotics.co.th -u riderapp -p'b7xYU6!qhXda' riderapp --skip-ssl -e "SELECT 1"
```

### Port Already in Use
```bash
# หา process ที่ใช้ port
sudo lsof -i :4000
sudo kill -9 <PID>
```

### Nginx 502 Bad Gateway
```bash
# ตรวจสอบ API running
curl http://127.0.0.1:4000/api/v1/health

# ตรวจสอบ nginx config
sudo nginx -t
sudo systemctl status nginx
```

---

## 8. Monitoring

### PM2 Monitoring
```bash
pm2 monit           # Real-time monitoring
pm2 status          # Process status
pm2 logs            # View logs
```

### Server Resources
```bash
htop                # CPU/Memory
df -h               # Disk usage
free -m             # Memory
```

---

**Last Updated:** January 2025
