# PLAN.md - RiderApp Implementation Plan

This document provides a comprehensive implementation plan for completing the RiderApp project. It serves as a roadmap for development across multiple sessions.

---

## Table of Contents
1. [Project Status Overview](#project-status-overview)
2. [Multi Sub-Agent Strategy](#multi-sub-agent-strategy)
3. [Implementation Phases](#implementation-phases)
4. [Detailed Task Breakdown](#detailed-task-breakdown)
5. [Testing Strategy](#testing-strategy)
6. [Dependencies & Prerequisites](#dependencies--prerequisites)

---

## Project Status Overview

### What's Completed

| Component | Status | Details |
|-----------|--------|---------|
| **Authentication (API)** | Done | Login, register, refresh, logout, sessions |
| **Authentication (Flutter)** | Done | Login screen, register screen, auth provider |
| **User Roles** | Done | 6 roles (rider, volunteer, police, commander, admin, super_admin) |
| **Role Hierarchy** | Done | Level 1-6 with permissions matrix |
| **Home Screens** | Done | All 6 role-specific home screens |
| **Role-Based Chat Groups** | Done | 5 groups (General, อส., Police, Commander, Admin) |
| **Affiliations Module** | Done | CRUD operations, admin management |
| **Database Migrations** | Done | All 13 migrations for core tables |
| **Navigation** | Done | GoRouter with role-based routing |
| **Localization** | Done | Thai/English with easy_localization |

### What's NOT Implemented (Return 501)

| Module | API Status | Flutter Status | Priority |
|--------|------------|----------------|----------|
| **Users CRUD** | 501 | Not Started | High |
| **Incidents** | 501 | Not Started | High |
| **Chat/Messages** | 501 | Not Started | Medium |
| **Announcements** | 501 | Not Started | Medium |
| **Notifications** | 501 | Not Started | Medium |
| **Locations** | 501 | Not Started | Medium |
| **Statistics** | 501 | Not Started | Low |
| **Emergency** | 501 | Not Started | Low |
| **Settings** | 501 | Not Started | Low |

### Database Tables Ready (Migrations Done)

- `users` - User accounts
- `refresh_tokens` - Session management
- `incidents` - Incident reports
- `incident_attachments` - Incident media
- `conversations` - Chat conversations
- `conversation_participants` - Group chat members
- `messages` - Chat messages
- `announcements` - System announcements
- `emergency_contacts` - Emergency hotlines (with Thailand defaults)
- `activity_logs` - Audit trail
- `notifications` - Push notifications
- `affiliations` - Organization affiliations

---

## Multi Sub-Agent Strategy for Continuous Work

### Why This Matters

Claude Code operates within context window limits. Large projects like RiderApp require:
- Breaking work into manageable chunks
- Seamless handoff between sessions
- Persistent progress tracking
- Clear resumption points

### How to Use Sub-Agents

When working on RiderApp, use the Task tool to spawn sub-agents for specific purposes:

#### 1. Task Handoff Pattern

```
Task(subagent_type="Explore") -> Understand codebase structure
Task(subagent_type="Plan")    -> Design implementation approach
Task(subagent_type="Bash")    -> Run commands/tests/migrations
Task(subagent_type="Code")    -> Implement features
```

#### 2. Before Context Fills Up

When you notice context is getting full (~70-80% through a complex task):
1. Document current progress in PROGRESS.md
2. Create TODO comments in code for next steps
3. Update this PLAN.md with any discovered requirements
4. Spawn a sub-agent to continue the next logical piece

#### 3. Checkpoint Strategy

After completing each module:

```markdown
# In PROGRESS.md
## [Module Name] - Completed YYYY-MM-DD
- Files created: [list]
- Files modified: [list]
- Tests passing: Yes/No
- Known issues: [list]
- Next: [what to work on next]
```

#### 4. Resumption Protocol

When starting a new session:

```
1. Read PLAN.md for current roadmap
2. Read PROGRESS.md for last checkpoint
3. Read CLAUDE.md for project context
4. Check for TODO comments in recent files
5. Use TodoWrite to set up task tracking
6. Continue from last checkpoint
```

### Session Handoff Template

When ending a session or spawning a sub-agent, provide context:

```markdown
## Session Handoff - [Date]

### Completed This Session
- [List of completed items]

### Current State
- Working on: [module/feature]
- Files open: [relevant files]
- Tests status: [passing/failing]

### Next Steps
1. [Specific next action]
2. [Following action]
3. [etc.]

### Blockers/Issues
- [Any blocking issues]

### Commands to Run
```bash
# Commands needed to continue
```
```

---

## Implementation Phases

### Phase 1: Core API Completion (Priority: HIGH)

**Goal:** Complete all core API modules that Flutter depends on.

**Estimated Duration:** 3-4 sessions

#### 1.1 Users Module

**Files to create:**
```
api/src/modules/users/
  ├── users.controller.js
  ├── users.service.js
  ├── users.repository.js
  ├── users.routes.js
  ├── users.validation.js
  └── index.js
```

**Endpoints:**
| Method | Endpoint | Description | Role Required |
|--------|----------|-------------|---------------|
| GET | `/users` | List users (paginated) | admin+ |
| GET | `/users/:id` | Get user by ID | admin+ (or self) |
| PUT | `/users/:id` | Update user | admin+ (or self) |
| DELETE | `/users/:id` | Soft delete user | admin+ |
| PATCH | `/users/:id/status` | Update approval status | police+ |
| PATCH | `/users/:id/role` | Change user role | admin+ |
| GET | `/users/pending` | List pending approvals | police+ |
| POST | `/users/:id/approve` | Approve user | police+ |
| POST | `/users/:id/reject` | Reject user | police+ |

**Complexity:** Medium

#### 1.2 Incidents Module

**Files to create:**
```
api/src/modules/incidents/
  ├── incidents.controller.js
  ├── incidents.service.js
  ├── incidents.repository.js
  ├── incidents.routes.js
  ├── incidents.validation.js
  └── index.js
```

**Endpoints:**
| Method | Endpoint | Description | Role Required |
|--------|----------|-------------|---------------|
| GET | `/incidents` | List incidents (filtered) | volunteer+ |
| GET | `/incidents/my` | Get own incidents | any |
| POST | `/incidents` | Create incident | any |
| GET | `/incidents/:id` | Get incident detail | owner or volunteer+ |
| PUT | `/incidents/:id` | Update incident | owner or admin |
| DELETE | `/incidents/:id` | Delete incident | admin+ |
| PATCH | `/incidents/:id/status` | Update status | police+ |
| POST | `/incidents/:id/assign` | Assign to officer | police+ |
| POST | `/incidents/:id/attachments` | Upload media | owner |
| GET | `/incidents/:id/attachments` | Get attachments | owner or volunteer+ |

**Complexity:** High

---

### Phase 2: Communication Features (Priority: MEDIUM)

**Goal:** Enable chat and announcements functionality.

**Estimated Duration:** 2-3 sessions

#### 2.1 Chat Module

**Files to create:**
```
api/src/modules/chat/
  ├── chat.controller.js
  ├── chat.service.js
  ├── chat.repository.js
  ├── chat.routes.js
  ├── chat.gateway.js      # Socket.io handler
  └── index.js
```

**Endpoints:**
| Method | Endpoint | Description | Role Required |
|--------|----------|-------------|---------------|
| GET | `/chat/conversations` | List conversations | any |
| POST | `/chat/conversations` | Create conversation | any |
| GET | `/chat/conversations/:id` | Get conversation | participant |
| DELETE | `/chat/conversations/:id` | Leave conversation | participant |
| PATCH | `/chat/conversations/:id/read` | Mark as read | participant |
| GET | `/chat/conversations/:id/messages` | Get messages | participant |
| POST | `/chat/conversations/:id/messages` | Send message | participant |
| GET | `/chat/unread-count` | Get unread count | any |
| GET | `/chat/groups` | List role-based groups | any |
| POST | `/chat/groups/auto-join` | Auto-join all accessible groups | any |
| POST | `/chat/groups/:id/join` | Join specific group | role-based |

**Socket Events:**
- `message:new` - New message received
- `message:read` - Messages marked read
- `typing:start` / `typing:stop` - Typing indicators
- `conversation:updated` - Conversation metadata changed

**Complexity:** High (requires Socket.io integration)

#### 2.2 Announcements Module

**Files to create:**
```
api/src/modules/announcements/
  ├── announcements.controller.js
  ├── announcements.service.js
  ├── announcements.repository.js
  ├── announcements.routes.js
  └── index.js
```

**Endpoints:**
| Method | Endpoint | Description | Role Required |
|--------|----------|-------------|---------------|
| GET | `/announcements` | List announcements | any |
| GET | `/announcements/:id` | Get announcement | any |
| POST | `/announcements` | Create announcement | police+ |
| PUT | `/announcements/:id` | Update announcement | admin+ |
| DELETE | `/announcements/:id` | Delete announcement | admin+ |
| PATCH | `/announcements/:id/read` | Mark as read | any |
| GET | `/announcements/unread-count` | Get unread count | any |

**Complexity:** Low

#### 2.3 Notifications Module

**Files to create:**
```
api/src/modules/notifications/
  ├── notifications.controller.js
  ├── notifications.service.js
  ├── notifications.repository.js
  ├── notifications.routes.js
  ├── notifications.gateway.js   # Socket.io handler
  └── index.js
```

**Endpoints:**
| Method | Endpoint | Description | Role Required |
|--------|----------|-------------|---------------|
| GET | `/notifications` | List notifications | any |
| GET | `/notifications/:id` | Get notification | owner |
| PATCH | `/notifications/:id/read` | Mark as read | owner |
| PATCH | `/notifications/read-all` | Mark all read | any |
| DELETE | `/notifications/:id` | Delete notification | owner |

**Complexity:** Medium

---

### Phase 3: Safety Features (Priority: MEDIUM)

**Goal:** Implement emergency contacts and location tracking.

**Estimated Duration:** 2 sessions

#### 3.1 Emergency Module

**Files to create:**
```
api/src/modules/emergency/
  ├── emergency.controller.js
  ├── emergency.service.js
  ├── emergency.repository.js
  ├── emergency.routes.js
  └── index.js
```

**Endpoints:**
| Method | Endpoint | Description | Role Required |
|--------|----------|-------------|---------------|
| GET | `/emergency/contacts` | List emergency contacts | any |
| POST | `/emergency/contacts` | Add contact (admin) | admin+ |
| PUT | `/emergency/contacts/:id` | Update contact | admin+ |
| DELETE | `/emergency/contacts/:id` | Delete contact | admin+ |
| POST | `/emergency/sos` | Trigger SOS | any |
| DELETE | `/emergency/sos` | Cancel SOS | any |
| GET | `/emergency/sos/status` | Check SOS status | any |

**Complexity:** Medium

#### 3.2 Locations Module

**Files to create:**
```
api/src/modules/locations/
  ├── locations.controller.js
  ├── locations.service.js
  ├── locations.repository.js
  ├── locations.routes.js
  ├── locations.gateway.js   # Socket.io for real-time
  └── index.js
```

**Endpoints:**
| Method | Endpoint | Description | Role Required |
|--------|----------|-------------|---------------|
| POST | `/locations/update` | Update location | any |
| GET | `/locations/riders` | Get rider locations | police+ |
| GET | `/locations/riders/:id/history` | Get location history | police+ |

**Socket Events:**
- `location:update` - Real-time location updates
- `location:subscribe` - Subscribe to rider locations (police)

**Complexity:** High (real-time tracking)

---

### Phase 4: Admin Features (Priority: LOW)

**Goal:** Complete admin dashboard and statistics.

**Estimated Duration:** 2 sessions

#### 4.1 Statistics Module

**Files to create:**
```
api/src/modules/stats/
  ├── stats.controller.js
  ├── stats.service.js
  ├── stats.repository.js
  ├── stats.routes.js
  └── index.js
```

**Endpoints:**
| Method | Endpoint | Description | Role Required |
|--------|----------|-------------|---------------|
| GET | `/stats/dashboard` | Dashboard overview | volunteer+ |
| GET | `/stats/incidents/summary` | Incident summary | volunteer+ |
| GET | `/stats/incidents/by-type` | By category | volunteer+ |
| GET | `/stats/incidents/by-status` | By status | volunteer+ |
| GET | `/stats/users/summary` | User summary | admin+ |
| GET | `/stats/users/by-role` | By role | admin+ |

**Complexity:** Medium

#### 4.2 User Approval Flow Enhancement

**Tasks:**
- Add approval workflow notifications
- Add batch approval endpoints
- Add rejection reason tracking

**Complexity:** Low

---

### Phase 5: Flutter UI (Priority: HIGH after API)

**Goal:** Build all Flutter screens and integrate with API.

**Estimated Duration:** 5-6 sessions

#### 5.1 Incidents Feature (Flutter)

**Files to create:**
```
riderapp/lib/features/incidents/
  ├── data/
  │   ├── datasources/incidents_remote_datasource.dart
  │   └── repositories/incidents_repository_impl.dart
  ├── domain/
  │   ├── entities/incident.dart
  │   ├── repositories/incidents_repository.dart
  │   └── usecases/
  │       ├── get_incidents.dart
  │       ├── create_incident.dart
  │       └── update_incident.dart
  └── presentation/
      ├── providers/
      │   ├── incidents_provider.dart
      │   └── incidents_state.dart
      ├── screens/
      │   ├── incidents_list_screen.dart
      │   ├── incident_detail_screen.dart
      │   └── create_incident_screen.dart
      └── widgets/
          ├── incident_card.dart
          ├── incident_filter.dart
          └── incident_form.dart
```

**Screens needed:**
- Incident list (with filtering)
- Incident detail
- Create incident (with location picker, image upload)
- Edit incident

**Complexity:** High

#### 5.2 Chat Feature (Flutter)

**Files to create:**
```
riderapp/lib/features/chat/
  ├── data/
  │   ├── datasources/chat_remote_datasource.dart
  │   ├── datasources/chat_socket_datasource.dart
  │   └── repositories/chat_repository_impl.dart
  ├── domain/
  │   ├── entities/
  │   │   ├── conversation.dart
  │   │   └── message.dart
  │   └── repositories/chat_repository.dart
  └── presentation/
      ├── providers/
      │   ├── chat_provider.dart
      │   └── chat_state.dart
      ├── screens/
      │   ├── conversations_list_screen.dart
      │   └── chat_screen.dart
      └── widgets/
          ├── conversation_tile.dart
          ├── message_bubble.dart
          └── chat_input.dart
```

**Screens needed:**
- Conversations list
- Chat screen (with real-time updates)

**Complexity:** High

#### 5.3 Announcements Feature (Flutter)

**Files to create:**
```
riderapp/lib/features/announcements/
  ├── data/
  │   ├── datasources/announcements_remote_datasource.dart
  │   └── repositories/announcements_repository_impl.dart
  ├── domain/
  │   ├── entities/announcement.dart
  │   └── repositories/announcements_repository.dart
  └── presentation/
      ├── providers/
      │   ├── announcements_provider.dart
      │   └── announcements_state.dart
      ├── screens/
      │   ├── announcements_list_screen.dart
      │   └── announcement_detail_screen.dart
      └── widgets/
          └── announcement_card.dart
```

**Screens needed:**
- Announcements list
- Announcement detail
- Create/edit announcement (admin only)

**Complexity:** Low

#### 5.4 Profile & Settings (Flutter)

**Files to create:**
```
riderapp/lib/features/profile/
  └── presentation/
      ├── screens/
      │   ├── profile_screen.dart
      │   └── edit_profile_screen.dart
      └── widgets/
          └── profile_avatar.dart

riderapp/lib/features/settings/
  └── presentation/
      ├── screens/
      │   ├── settings_screen.dart
      │   └── notification_settings_screen.dart
      └── widgets/
          └── settings_tile.dart
```

**Screens needed:**
- Profile view
- Edit profile
- Settings
- Notification preferences

**Complexity:** Low

#### 5.5 Admin Screens (Flutter)

**Files to create:**
```
riderapp/lib/features/admin/
  └── presentation/
      ├── screens/
      │   ├── user_management_screen.dart
      │   ├── pending_approvals_screen.dart
      │   ├── statistics_screen.dart
      │   └── system_config_screen.dart
      └── widgets/
          ├── user_list_tile.dart
          ├── approval_card.dart
          └── stat_card.dart
```

**Screens needed:**
- User management (list, search, filter)
- Pending approvals
- Statistics dashboard
- System configuration (super_admin only)

**Complexity:** Medium

#### 5.6 Emergency Features (Flutter)

**Files to create:**
```
riderapp/lib/features/emergency/
  └── presentation/
      ├── screens/
      │   ├── emergency_contacts_screen.dart
      │   └── sos_screen.dart
      └── widgets/
          ├── emergency_contact_card.dart
          └── sos_button.dart
```

**Screens needed:**
- Emergency contacts list
- SOS trigger screen

**Complexity:** Medium

---

## Detailed Task Breakdown

### API Module Template

For each new API module, follow this checklist:

```markdown
## [Module Name] Module

### Setup
- [ ] Create module directory structure
- [ ] Create index.js with exports
- [ ] Add routes to main router (routes/index.js)

### Repository Layer
- [ ] Create repository.js with SQL queries
- [ ] Implement CRUD operations
- [ ] Add pagination support
- [ ] Add filtering support

### Service Layer
- [ ] Create service.js with business logic
- [ ] Add input validation
- [ ] Add authorization checks
- [ ] Handle errors appropriately

### Controller Layer
- [ ] Create controller.js with route handlers
- [ ] Parse request parameters
- [ ] Call service methods
- [ ] Return standardized responses

### Routes
- [ ] Create routes.js with endpoint definitions
- [ ] Add authentication middleware
- [ ] Add role-based authorization
- [ ] Add request validation

### Testing
- [ ] Test with Postman/curl
- [ ] Verify error handling
- [ ] Test authorization

### Documentation
- [ ] Update routes/index.js endpoint list
- [ ] Update PROGRESS.md
```

### Flutter Feature Template

For each new Flutter feature, follow this checklist:

```markdown
## [Feature Name] Feature

### Domain Layer
- [ ] Create entity models
- [ ] Create repository interface
- [ ] Create use cases (if needed)

### Data Layer
- [ ] Create remote data source
- [ ] Implement API calls
- [ ] Create repository implementation
- [ ] Handle error mapping

### Presentation Layer
- [ ] Create state classes (sealed)
- [ ] Create Riverpod provider
- [ ] Implement screens
- [ ] Create reusable widgets

### Navigation
- [ ] Add routes to app_router.dart
- [ ] Add route guards if needed

### Testing
- [ ] Run flutter analyze
- [ ] Test on device/emulator
- [ ] Test error states

### Localization
- [ ] Add strings to en.json
- [ ] Add strings to th.json
```

---

## Testing Strategy

### API Testing

```bash
# Start API server
cd api && npm run dev

# Test endpoints with curl
curl -X GET http://localhost:3000/api/v1/health

# Or use Postman collection (to be created)
```

### Flutter Testing

```bash
# Run all tests
cd riderapp && flutter test

# Run specific test
flutter test test/features/incidents/incidents_test.dart

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

### Integration Testing

1. Start API server
2. Run Flutter app on emulator
3. Test full user flows
4. Check console for errors

### Manual Test Checklist

For each feature, test:
- [ ] Happy path (normal usage)
- [ ] Error handling (network errors, validation)
- [ ] Edge cases (empty data, long text)
- [ ] Role-based access (test with each role)
- [ ] Localization (switch languages)

---

## Dependencies & Prerequisites

### Required for API Development
- Node.js 18+
- MySQL/MariaDB running
- Database migrations applied

### Required for Flutter Development
- Flutter SDK 3.x
- Dart SDK
- Android Studio / Xcode for emulators
- API server running

### Recommended Tools
- Postman for API testing
- MySQL Workbench for database
- VS Code with Flutter/Dart extensions

---

## Quick Reference

### Start Development

```bash
# Terminal 1: Start API
cd api && npm run dev

# Terminal 2: Start Flutter
cd riderapp && flutter run
```

### Run Migrations

```bash
cd api
node src/database/migrate.js        # Run pending
node src/database/migrate.js status # Check status
```

### Generate Code (Flutter)

```bash
cd riderapp
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Notes for Future Sessions

1. **Always read PROGRESS.md first** to understand where work left off
2. **Update PROGRESS.md** after completing any significant work
3. **Use TodoWrite** to track tasks within a session
4. **Commit frequently** with descriptive messages
5. **Test thoroughly** before marking anything complete

---

*Last Updated: 2026-01-16*
