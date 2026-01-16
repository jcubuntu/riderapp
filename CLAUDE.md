# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RiderApp is a safety coordination platform for riders (delivery/motorcycle riders) and police. It's a monorepo with:
- **Flutter Mobile App** (`riderapp/`) - Cross-platform client
- **Node.js API** (`api/`) - Express backend with MySQL/MariaDB

## Build & Development Commands

### Flutter App (riderapp/)
```bash
cd riderapp

# Run the app
flutter run

# Build
flutter build apk          # Android
flutter build ios          # iOS

# Testing
flutter test               # Run all tests
flutter test test/widget_test.dart  # Single test

# Code generation (after modifying freezed/json_serializable models)
flutter pub run build_runner build --delete-conflicting-outputs

# Code analysis
flutter analyze

# Dependencies
flutter pub get
```

### API Server (api/)
```bash
cd api

# Development
npm run dev                # Run with nodemon (hot reload)
npm start                  # Production start

# Database migrations
node src/database/migrate.js           # Run pending migrations
node src/database/migrate.js status    # Show migration status
node src/database/migrate.js fresh     # Drop all + re-migrate
node src/database/migrate.js down      # Rollback last batch

# Linting
npm run lint
npm run lint:fix
```

## Architecture

### Flutter App - Clean Architecture with Riverpod

**State Management:** Riverpod (`flutter_riverpod`) with sealed class states

**Navigation:** GoRouter with role-based routing
- Routes defined in `lib/navigation/app_router.dart`
- Auth state-based redirects (login, pending approval, role-specific homes)

**Feature Structure:**
```
lib/features/{feature}/
  ├── data/
  │   ├── datasources/    # API calls
  │   └── repositories/   # Data abstraction
  ├── domain/
  │   ├── entities/       # Business models
  │   ├── repositories/   # Repository interfaces
  │   └── usecases/       # Business logic
  └── presentation/
      ├── providers/      # Riverpod providers + states
      ├── screens/        # Full page widgets
      └── widgets/        # Reusable components
```

**Core Layer:**
- `core/network/api_client.dart` - Dio HTTP client
- `core/storage/secure_storage.dart` - Secure token storage
- `core/theme/app_theme.dart` - Material 3 theming
- `core/constants/api_endpoints.dart` - API endpoint definitions

### API Server - Modular Express Architecture

**Structure:**
```
api/src/
  ├── config/           # Environment config
  ├── constants/        # Roles, statuses enums
  ├── database/
  │   └── migrations/   # SQL migration files
  ├── middleware/       # Auth, role, error handlers
  ├── modules/          # Feature modules
  │   └── {module}/
  │       ├── {module}.controller.js
  │       ├── {module}.service.js
  │       ├── {module}.repository.js
  │       └── {module}.routes.js
  ├── routes/           # Route aggregation
  └── utils/            # JWT, password, logger, response helpers
```

**API Versioning:** `/api/v1/...`

**Database:** MySQL/MariaDB with raw SQL migrations (no ORM)

**Auth:** JWT with access + refresh tokens, bcrypt password hashing

## User Roles & Hierarchy

### Role Hierarchy (Level 1-5)

| Level | Role | Description |
|-------|------|-------------|
| **Level 1** | `rider` | Motorcycle rider who can report incidents and view their own reports |
| **Level 2** | `volunteer` | Police volunteer who assists with incident coordination and monitoring |
| **Level 3** | `police` | Police officer who can manage incidents and approve users |
| **Level 4** | `admin` | System administrator with full access to all features |
| **Level 5** | `super_admin` | Super administrator with full system control including admin management |

### Role Permissions Matrix

| Permission | rider | volunteer | police | admin | super_admin |
|------------|-------|-----------|--------|-------|-------------|
| Create Incident | Yes | Yes | Yes | Yes | Yes |
| View Own Incidents | Yes | Yes | Yes | Yes | Yes |
| Update Own Incidents | Yes | Yes | Yes | Yes | Yes |
| Delete Own Incidents | No | No | No | Yes | Yes |
| View All Incidents | No | Yes | Yes | Yes | Yes |
| Manage Users | No | No | No | Yes | Yes |
| Approve Users | No | No | Yes | Yes | Yes |
| View Dashboard | No | Yes | Yes | Yes | Yes |
| Access Admin Panel | No | No | No | Yes | Yes |
| Manage Admins | No | No | No | No | Yes |
| Access System Config | No | No | No | No | Yes |

### Role Assignment Rules
- `super_admin` can assign: all roles including super_admin
- `admin` can assign: rider, volunteer, police, admin
- `police` can assign: rider, volunteer
- `rider` and `volunteer` cannot assign roles

### Role Files

**API Role Constants:** `api/src/constants/roles.js`
- `ROLES` - Role enum object
- `ROLE_HIERARCHY` - Level mapping
- `ROLE_PERMISSIONS` - Permission matrix
- Helper functions: `hasMinimumRole()`, `getAssignableRoles()`, `hasPermission()`

**Flutter Role Model:** `riderapp/lib/shared/models/user_model.dart`
- `UserRole` enum with `displayName` and `fromString()`
- Permission getters: `canManageUsers`, `canApproveUsers`, `canManageAdmins`, etc.

## Key Files & Screens

### Home Screens (Flutter)
Each role has a dedicated home screen:
- `lib/features/home/presentation/screens/rider_home_screen.dart` - Rider dashboard
- `lib/features/home/presentation/screens/volunteer_home_screen.dart` - Volunteer dashboard
- `lib/features/home/presentation/screens/police_home_screen.dart` - Police dashboard
- `lib/features/home/presentation/screens/admin_home_screen.dart` - Admin dashboard
- `lib/features/home/presentation/screens/super_admin_home_screen.dart` - Super Admin dashboard

### Auth Flow
- Uses sealed classes for state (`AuthState` in `auth_state.dart`)
- States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthPendingApproval`, `AuthUnauthenticated`, `AuthError`, `AuthRejected`
- Role-based home routing in `app_router.dart`

### Database Migrations
Located in `api/src/database/migrations/`:
1. `001_create_users.sql` - Users table
2. `002_create_refresh_tokens.sql` - Session tokens
3. `003_create_incidents.sql` - Incident reports
4. `004_create_incident_attachments.sql` - Incident media
5. `005_create_conversations.sql` - Chat conversations
6. `006_create_messages.sql` - Chat messages
7. `007_create_announcements.sql` - System announcements
8. `008_create_emergency_contacts.sql` - Emergency contacts (with Thailand defaults)
9. `009_create_activity_logs.sql` - Audit logging
10. `010_create_notifications.sql` - Push notifications
11. `011_create_affiliations.sql` - Organization affiliations
12. `012_make_email_nullable.sql` - Schema update
13. `013_add_volunteer_super_admin_roles.sql` - New role support

## Conventions

### Flutter
- Private members: underscore prefix (`_PrivateClass`)
- Widgets: PascalCase (`MyWidget`)
- Files: snake_case (`my_file.dart`)
- State classes: sealed + Equatable
- Models: Use freezed for immutability + JSON serialization

### API
- Files: kebab-case (`auth.controller.js`)
- Response format: `{ success: boolean, data/message/error }`
- Error handling: Centralized via `error.middleware.js`
- Validation: Joi schemas

## Environment Setup

### API (.env in api/)
```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=riderapp
JWT_SECRET=your-secret
JWT_REFRESH_SECRET=your-refresh-secret
PORT=3000
```

### Direct Database Access
To connect to the production database directly:
```bash
mysql -h makerrobotics.co.th -u riderapp -p'b7xYU6!qhXda' riderapp --skip-ssl -e "YOUR_SQL_QUERY"
```

**Important:** Always use `--skip-ssl` flag when connecting to this database.

## Test Users

| Role | Phone | Password | Name |
|------|-------|----------|------|
| Rider | `0811111111` | `Test1234` | Test Rider |
| Volunteer | `0822222222` | `Test1234` | Test Volunteer |
| Police | `0833333333` | `Test1234` | Test Police |
| Admin | `0844444444` | `Test1234` | Test Admin |
| Super Admin | `0855555555` | `Test1234` | Test Super Admin |

All test users are pre-approved and can log in immediately.

## Key Dependencies

### Flutter
- riverpod, go_router, dio, flutter_secure_storage
- easy_localization (Thai/English)
- freezed + json_serializable for code generation
- socket_io_client for real-time features

### API
- express, helmet, cors, compression
- jsonwebtoken, bcryptjs
- mysql2, socket.io
- winston (logging), multer (file uploads)

## Implementation Status

### Completed
- Authentication module (API + Flutter)
- User registration with phone-based auth
- Role-based routing and home screens for all 5 roles
- Affiliations module (API + Flutter)
- Database migrations for all core tables

### Not Yet Implemented (Return 501)
- Users module (CRUD beyond auth)
- Incidents module
- Locations/Tracking module
- Notifications module
- Statistics/Dashboard module
- Chat module
- Announcements module
- Emergency features

See `PLAN.md` for detailed implementation roadmap.
See `PROGRESS.md` for current development status.
