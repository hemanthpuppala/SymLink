# Tasks: V1 Water Plant Discovery Platform

**Input**: Design documents from `/specs/001-water-plant-discovery/`
**Prerequisites**: plan.md ✓, spec.md ✓, data-model.md ✓, contracts/openapi.yaml ✓, research.md ✓, quickstart.md ✓

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md structure:
- **Backend**: `apps/backend/src/`
- **Admin Dashboard**: `apps/admin/src/`
- **Consumer App**: `apps/consumer-app/lib/`
- **Owner App**: `apps/owner-app/lib/`
- **Docker**: `docker/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, monorepo setup, Docker infrastructure

- [x] T001 Create monorepo root structure with pnpm-workspace.yaml at repository root
- [x] T002 [P] Create docker/docker-compose.dev.yml with PostgreSQL+PostGIS, Redis, MinIO, pgAdmin services
- [x] T003 [P] Create .env.example with all environment variables from quickstart.md
- [x] T004 [P] Initialize NestJS backend project in apps/backend/ with dependencies from plan.md
- [x] T005 [P] Initialize Next.js admin dashboard in apps/admin/ with App Router and Tailwind
- [x] T006 [P] Initialize Flutter consumer-app in apps/consumer-app/ with BLoC architecture
- [x] T007 [P] Initialize Flutter owner-app in apps/owner-app/ with BLoC architecture
- [x] T008 Create apps/backend/prisma/schema.prisma with all entities from data-model.md
- [x] T009 Run initial Prisma migration (using SQLite for development)

**Checkpoint**: All apps scaffold created, Docker services running, database schema ready ✅

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Backend Core Infrastructure

- [x] T010 Implement JWT authentication module with access/refresh tokens in apps/backend/src/modules/auth/
- [x] T011 [P] Create common response envelope transformer in apps/backend/src/common/interceptors/response.interceptor.ts
- [x] T012 [P] Create global exception filter with error codes in apps/backend/src/common/filters/http-exception.filter.ts
- [x] T013 [P] Create validation pipe configuration in apps/backend/src/common/pipes/validation.pipe.ts
- [x] T014 [P] Create JWT auth guard in apps/backend/src/common/guards/jwt-auth.guard.ts
- [x] T015 [P] Create admin role guard in apps/backend/src/common/guards/admin.guard.ts
- [x] T016 [P] Create owner role guard in apps/backend/src/common/guards/owner.guard.ts
- [x] T017 Implement storage service in apps/backend/src/modules/storage/storage.service.ts
- [x] T018 Implement cache service in apps/backend/src/modules/cache/cache.service.ts
- [x] T019 Create health check endpoint GET /v1/health in apps/backend/src/modules/health/health.controller.ts
- [x] T020 Create database seed script with admin user in apps/backend/prisma/seed.ts

### Flutter Core Infrastructure

- [x] T021 [P] Create core API client with Dio in apps/consumer-app/lib/core/api/api_client.dart
- [x] T022 [P] Create core API client with Dio in apps/owner-app/lib/core/api/api_client.dart
- [x] T023 [P] Create app theme and colors in apps/consumer-app/lib/core/theme/app_theme.dart
- [x] T024 [P] Create app theme and colors in apps/owner-app/lib/core/theme/app_theme.dart
- [x] T025 [P] Configure GoRouter navigation in apps/consumer-app/lib/core/router/app_router.dart
- [x] T026 [P] Configure GoRouter navigation in apps/owner-app/lib/core/router/app_router.dart
- [x] T027 [P] Create secure storage wrapper in apps/consumer-app/lib/core/storage/secure_storage.dart
- [x] T028 [P] Create secure storage wrapper in apps/owner-app/lib/core/storage/secure_storage.dart

### Admin Dashboard Core Infrastructure

- [x] T029 [P] Create API client with fetch in apps/admin/src/lib/api.ts
- [x] T030 [P] Configure TanStack Query provider in apps/admin/src/app/providers.tsx
- [x] T031 [P] Create auth context and hook in apps/admin/src/lib/auth.ts
- [x] T032 Create login page at apps/admin/src/app/auth/login/page.tsx
- [x] T033 Create dashboard layout with sidebar in apps/admin/src/components/layout/

**Checkpoint**: Foundation ready - all auth flows work, API client configured, user story implementation can begin ✅

---

## Phase 3: User Story 2 - Plant Owner Registers and Creates Profile (Priority: P1) 🎯 MVP

**Goal**: Water plant owners can register, create plant profile, upload photos, and submit verification documents

**Independent Test**: Complete owner registration flow, upload plant photos, submit documents, verify profile saved

### Backend Implementation for US2

- [x] T034 [US2] Create Owner module structure in apps/backend/src/modules/owner/
- [x] T035 [US2] Implement owner registration POST /v1/owner/auth/register in apps/backend/src/modules/owner/owner-auth.controller.ts
- [x] T036 [US2] Implement owner login POST /v1/owner/auth/login in apps/backend/src/modules/owner/owner-auth.controller.ts
- [x] T037 [US2] Implement owner token refresh POST /v1/owner/auth/refresh in apps/backend/src/modules/owner/owner-auth.controller.ts
- [ ] T038 [US2] Implement password reset flow POST /v1/owner/auth/password/reset and /confirm
- [x] T039 [US2] Implement GET/PATCH /v1/owner/profile in apps/backend/src/modules/owner/owner-profile.controller.ts
- [x] T040 [US2] Implement plant CRUD GET/POST/PATCH /v1/owner/plant in apps/backend/src/modules/owner/owner-plant.controller.ts
- [x] T041 [US2] Implement plant status toggle PATCH /v1/owner/plant/status in apps/backend/src/modules/owner/owner-plant.controller.ts
- [x] T042 [US2] Implement photo upload POST /v1/owner/plant/photos with storage
- [x] T043 [US2] Implement photo delete DELETE /v1/owner/plant/photos
- [x] T044 [US2] Implement verification submission POST /v1/owner/verification in apps/backend/src/modules/owner/owner-verification.controller.ts
- [x] T045 [US2] Implement verification status GET /v1/owner/verification in apps/backend/src/modules/owner/owner-verification.controller.ts
- [x] T046 [US2] Implement notifications list GET /v1/owner/notifications in apps/backend/src/modules/owner/owner-notifications.controller.ts
- [x] T047 [US2] Implement mark notification read POST /v1/owner/notifications/{id}/read in apps/backend/src/modules/owner/owner-notifications.controller.ts

### Owner App Implementation for US2

- [x] T048 [US2] Create auth feature module in apps/owner-app/lib/features/auth/
- [x] T049 [US2] Implement AuthBloc with login/register states
- [x] T050 [US2] Create registration screen with form validation in apps/owner-app/lib/core/router/app_router.dart
- [x] T051 [US2] Create login screen in apps/owner-app/lib/core/router/app_router.dart
- [x] T052 [US2] Create dashboard feature module in apps/owner-app/lib/features/dashboard/
- [x] T053 [US2] Implement DashboardBloc
- [x] T054 [US2] Create main dashboard screen with plant info in apps/owner-app/lib/features/dashboard/screens/dashboard_screen.dart
- [x] T055 [US2] Create plant_profile feature module in apps/owner-app/lib/features/plant_profile/
- [x] T056 [US2] Implement PlantProfileBloc
- [x] T057 [US2] Create plant form screen with TDS/price/hours in apps/owner-app/lib/features/plant_profile/screens/plant_form_screen.dart
- [ ] T058 [US2] Create photo manager widget with upload
- [x] T059 [US2] Create documents feature module in apps/owner-app/lib/features/documents/
- [x] T060 [US2] Implement DocumentsBloc
- [x] T061 [US2] Create verification screen in apps/owner-app/lib/features/documents/screens/verification_screen.dart
- [ ] T062 [US2] Create verification status widget
- [ ] T063 [US2] Create notifications feature module
- [ ] T064 [US2] Implement NotificationsBloc
- [ ] T065 [US2] Create notifications list screen

**Checkpoint**: Owner can register, login, create plant profile, submit verification documents ✅

---

## Phase 4: User Story 1 - Consumer Discovers Nearby Water Plants (Priority: P1) 🎯 MVP

**Goal**: Consumers can open the app, view a map of nearby water plants, tap markers to see tooltips with key info

**Independent Test**: Open consumer app, grant location, see map with markers, tap marker to see tooltip with Directions/Message buttons

### Backend Implementation for US1

- [x] T066 [US1] Create Consumer plants controller in apps/backend/src/modules/consumer/consumer-plant.controller.ts
- [ ] T067 [US1] Implement geospatial query service with PostGIS (currently using basic lat/lng filtering)
- [x] T068 [US1] Implement GET /v1/consumer/plants with lat/lng params in apps/backend/src/modules/consumer/consumer-plant.controller.ts
- [x] T069 [US1] Implement GET /v1/consumer/plants/{plantId} in apps/backend/src/modules/consumer/consumer-plant.controller.ts
- [x] T070 [US1] Create Consumer auth module in apps/backend/src/modules/consumer/
- [x] T071 [US1] Implement consumer login POST /v1/consumer/auth/login in apps/backend/src/modules/consumer/consumer-auth.controller.ts
- [x] T072 [US1] Implement consumer token refresh POST /v1/consumer/auth/refresh in apps/backend/src/modules/consumer/consumer-auth.controller.ts
- [x] T072b [US1] Implement consumer registration POST /v1/consumer/auth/register with displayName
- [x] T072c [US1] Implement consumer profile GET/PATCH /v1/consumer/profile

### Consumer App Implementation for US1

- [x] T073 [US1] Create auth feature module in apps/consumer-app/lib/features/auth/
- [x] T074 [US1] Implement AuthBloc in apps/consumer-app/lib/features/auth/bloc/auth_bloc.dart
- [x] T075 [US1] Create login screen in apps/consumer-app/lib/features/auth/screens/login_screen.dart
- [x] T076 [US1] Create plants feature module in apps/consumer-app/lib/features/plants/
- [x] T077 [US1] Implement PlantsBloc in apps/consumer-app/lib/features/plants/bloc/plants_bloc.dart
- [x] T078 [US1] Create map screen in apps/consumer-app/lib/features/plants/screens/map_screen.dart
- [x] T079 [US1] Create plant card widget in apps/consumer-app/lib/features/plants/widgets/plant_card.dart
- [x] T080 [US1] Create home screen with plant list in apps/consumer-app/lib/features/plants/screens/home_screen.dart
- [x] T081 [US1] Implement directions button (launch external maps)
- [x] T082 [US1] Implement location permission flow
- [x] T083 [US1] Create manual location entry dialog
- [x] T084 [US1] Handle empty state in plant list

**Checkpoint**: Consumer can login, view plant list/map, see plant details ✅

---

## Phase 5: User Story 3 - Admin Verifies Plant Owner Documents (Priority: P2)

**Goal**: Admins can login to web dashboard, view pending verifications, approve/reject with reason

**Independent Test**: Login as admin, view pending list, open request details, approve or reject with reason

### Backend Implementation for US3

- [x] T085 [US3] Create Admin module structure in apps/backend/src/modules/admin/
- [x] T086 [US3] Implement admin login POST /v1/admin/auth/login in apps/backend/src/modules/admin/admin-auth.controller.ts
- [x] T087 [US3] Implement admin token refresh POST /v1/admin/auth/refresh in apps/backend/src/modules/admin/admin-auth.controller.ts
- [x] T088 [US3] Implement dashboard summary GET /v1/admin/dashboard in apps/backend/src/modules/admin/admin-dashboard.controller.ts
- [x] T089 [US3] Implement verifications list GET /v1/admin/verification-requests in apps/backend/src/modules/admin/admin-verification.controller.ts
- [x] T090 [US3] Implement verification details GET /v1/admin/verification-requests/{id}
- [x] T091 [US3] Implement approve/reject PATCH /v1/admin/verification-requests/{id} in apps/backend/src/modules/admin/admin-verification.controller.ts
- [x] T092 [US3] Create notification on verification decision
- [x] T093 [US3] Implement plants list GET /v1/admin/plants
- [x] T094 [US3] Implement plant details GET /v1/admin/plants/{id}

### Admin Dashboard Implementation for US3

- [x] T095 [US3] Create dashboard home page with summary stats at apps/admin/src/app/dashboard/page.tsx
- [x] T096 [US3] Create verifications list page at apps/admin/src/app/verification/page.tsx
- [ ] T097 [US3] Create verification detail page with document viewer
- [x] T098 [US3] Create approve/reject actions in verification page
- [x] T099 [US3] Create plants list page at apps/admin/src/app/plants/page.tsx
- [x] T100 [US3] Create plant detail page
- [x] T101 [US3] Implement real-time WebSocket updates for new verifications

**Checkpoint**: Admin can login, view dashboard stats, review verifications, approve/reject ✅

---

## Phase 6: User Story 4 - Consumer Views Plant Details (Priority: P2)

**Goal**: Consumer can tap plant to see full details: photos, hours, TDS, price, contact, verified badge

**Independent Test**: Tap any plant marker/list item, view full detail page with all info, tap phone to call

### Backend Implementation for US4

- [ ] T103 [US4] Implement POST /v1/plants/{plantId}/view to record view in apps/backend/src/modules/plants/plants.controller.ts
- [ ] T104 [US4] Implement GET /v1/plants/share/{plantId} public profile in apps/backend/src/modules/plants/plants.controller.ts

### Consumer App Implementation for US4

- [ ] T105 [US4] Create plant_details feature module in apps/consumer-app/lib/features/plant_details/
- [ ] T106 [US4] Implement PlantDetailsBloc in apps/consumer-app/lib/features/plant_details/bloc/plant_details_bloc.dart
- [ ] T107 [US4] Create plant detail screen in apps/consumer-app/lib/features/plant_details/screens/plant_detail_screen.dart
- [ ] T108 [US4] Create photo carousel widget in apps/consumer-app/lib/features/plant_details/widgets/photo_carousel.dart
- [ ] T109 [US4] Create verified badge widget in apps/consumer-app/lib/features/plant_details/widgets/verified_badge.dart
- [ ] T110 [US4] Implement phone dialer action in apps/consumer-app/lib/features/plant_details/screens/plant_detail_screen.dart
- [ ] T111 [US4] Navigate to detail from map tooltip in apps/consumer-app/lib/features/map/widgets/plant_tooltip.dart

**Checkpoint**: Consumer can view full plant details, see photos, verified status, and call owner

---

## Phase 7: User Story 5 - Plant Owner Updates Information (Priority: P2)

**Goal**: Owner can update TDS, price, hours, photos and changes reflect in consumer app immediately

**Independent Test**: Update TDS reading in owner app, verify new value appears in consumer app within 5 seconds

### Implementation for US5

- [ ] T112 [US5] Ensure PATCH /v1/owner/plant updates are instant (no additional caching) in apps/backend/src/modules/owner/owner-plant.service.ts
- [ ] T113 [US5] Add open/closed toggle to owner dashboard in apps/owner-app/lib/features/dashboard/screens/dashboard_screen.dart
- [ ] T114 [US5] Create quick-edit TDS widget on dashboard in apps/owner-app/lib/features/dashboard/widgets/quick_edit_tds.dart
- [ ] T115 [US5] Create quick-edit price widget on dashboard in apps/owner-app/lib/features/dashboard/widgets/quick_edit_price.dart

**Checkpoint**: Owner can quickly update plant info from dashboard, changes appear immediately in consumer app

---

## Phase 8: User Story 9 - Consumer Messages Plant Owner (Priority: P2)

**Goal**: Consumer can message owner from tooltip, real-time chat with Instagram-style UI, message retention

**Independent Test**: Consumer sends message, owner receives in real-time, both see conversation history

### Backend Implementation for US9

- [x] T116 [US9] Create Chat module structure in apps/backend/src/modules/chat/
- [ ] T117 [US9] Implement AES-256-GCM encryption service (optional for V1)
- [x] T118 [US9] Implement consumer conversations list GET /v1/consumer/conversations in apps/backend/src/modules/chat/consumer-chat.controller.ts
- [x] T119 [US9] Implement get/create conversation POST /v1/consumer/conversations in apps/backend/src/modules/chat/consumer-chat.controller.ts
- [x] T120 [US9] Implement get messages GET /v1/consumer/conversations/{id}/messages in apps/backend/src/modules/chat/consumer-chat.controller.ts
- [x] T121 [US9] Implement send message POST /v1/consumer/conversations/{id}/messages in apps/backend/src/modules/chat/consumer-chat.controller.ts
- [x] T122 [US9] Implement mark read POST /v1/consumer/conversations/{id}/read in apps/backend/src/modules/chat/consumer-chat.controller.ts
- [ ] T123 [US9] Implement retention setting PATCH /v1/consumer/conversations/{id}/retention
- [x] T124 [US9] Implement owner conversations list GET /v1/owner/conversations in apps/backend/src/modules/chat/owner-chat.controller.ts
- [x] T125 [US9] Implement owner get messages GET /v1/owner/conversations/{id}/messages in apps/backend/src/modules/chat/owner-chat.controller.ts
- [x] T126 [US9] Implement owner send message POST /v1/owner/conversations/{id}/messages in apps/backend/src/modules/chat/owner-chat.controller.ts
- [x] T127 [US9] Implement owner mark read POST /v1/owner/conversations/{id}/read in apps/backend/src/modules/chat/owner-chat.controller.ts
- [ ] T128 [US9] Implement owner retention setting
- [x] T129 [US9] Create WebSocket gateway for real-time messaging in apps/backend/src/modules/chat/chat.gateway.ts
- [x] T130 [US9] Implement message:new, typing events in apps/backend/src/modules/chat/chat.gateway.ts
- [ ] T131 [US9] Implement Redis Pub/Sub for multi-instance support
- [ ] T132 [US9] Create message retention cron job
- [x] T133 [US9] Add new_message notification type handling in apps/backend/src/modules/chat/chat.service.ts

### Consumer App Implementation for US9

- [x] T134 [US9] Create chat screens in apps/consumer-app/lib/core/router/app_router.dart (ChatListScreen, ChatScreen)
- [x] T135 [US9] Create SyncService for WebSocket in apps/consumer-app/lib/core/sync/sync_service.dart
- [x] T136 [US9] Implement chat list with conversations
- [x] T137 [US9] Implement chat screen with messages
- [x] T138 [US9] Create Chats tab with conversation list
- [x] T139 [US9] Create conversation item in chat list
- [x] T140 [US9] Create chat screen with message bubbles
- [x] T141 [US9] Create message bubble widgets (sent/received)
- [x] T142 [US9] Create message input widget
- [x] T143 [US9] Create typing indicator widget
- [x] T144 [US9] Implement message status indicators (sent/delivered/read)
- [x] T145 [US9] Add "Message" button in plant details
- [x] T146 [US9] Add Chats tab to bottom navigation
- [ ] T147 [US9] Create retention settings screen

### Owner App Implementation for US9

- [x] T148 [US9] Create chat screens in apps/owner-app/lib/core/router/app_router.dart (ChatListScreen, ChatScreen)
- [x] T149 [US9] Create SyncService for WebSocket in apps/owner-app/lib/core/sync/sync_service.dart
- [x] T150 [US9] Implement chat list with conversations (shows consumer displayName)
- [x] T151 [US9] Implement chat screen with messages
- [x] T152 [US9] Create Chats tab with conversation list
- [x] T153 [US9] Create conversation item in chat list
- [x] T154 [US9] Create chat screen with message bubbles
- [x] T155 [US9] Create message bubble widgets (sent/received)
- [x] T156 [US9] Create message input widget
- [x] T157 [US9] Create typing indicator widget
- [x] T158 [US9] Implement message status indicators
- [x] T159 [US9] Add Chats tab to bottom navigation
- [ ] T160 [US9] Create retention settings screen
- [x] T161 [US9] Add unread message badge to dashboard

**Checkpoint**: Consumer and Owner can chat in real-time, see message status ✅

---

## Phase 9: User Story 6 - Consumer Searches and Filters Plants (Priority: P3)

**Goal**: Consumer can filter by open now, verified only; sort by distance, TDS, price

**Independent Test**: Apply "Open Now" filter, verify only open plants shown; sort by TDS ascending

### Implementation for US6

- [ ] T162 [US6] Add sort and filter params to GET /v1/plants in apps/backend/src/modules/plants/plants.controller.ts
- [ ] T163 [US6] Create filter sheet widget in apps/consumer-app/lib/features/map/widgets/filter_sheet.dart
- [ ] T164 [US6] Add filter/sort state to MapBloc in apps/consumer-app/lib/features/map/bloc/map_bloc.dart
- [ ] T165 [US6] Create list view toggle for map screen in apps/consumer-app/lib/features/map/screens/map_screen.dart
- [ ] T166 [US6] Create plant list view in apps/consumer-app/lib/features/map/widgets/plant_list_view.dart

**Checkpoint**: Consumer can filter and sort plants, toggle between map and list view

---

## Phase 10: User Story 7 - Owner Views Basic Analytics (Priority: P3)

**Goal**: Owner can see total profile views and weekly views on their dashboard

**Independent Test**: View analytics section, verify view count increments when consumer views plant

### Implementation for US7

- [ ] T167 [US7] Implement GET /v1/owner/analytics in apps/backend/src/modules/owner/owner-analytics.controller.ts
- [ ] T168 [US7] Implement view count aggregation with 7-day history in apps/backend/src/modules/owner/owner-analytics.service.ts
- [ ] T169 [US7] Add analytics widget to owner dashboard in apps/owner-app/lib/features/dashboard/widgets/analytics_card.dart
- [ ] T170 [US7] Create analytics detail screen with chart in apps/owner-app/lib/features/dashboard/screens/analytics_screen.dart

**Checkpoint**: Owner can see view counts and weekly trend on dashboard

---

## Phase 11: User Story 8 - Owner Gets Shareable Profile Link (Priority: P3)

**Goal**: Owner can get shareable link and QR code to share plant profile

**Independent Test**: Get share link, open in browser, see public profile page

### Implementation for US8

- [ ] T171 [US8] Implement GET /v1/owner/plant/share in apps/backend/src/modules/owner/owner-plant.controller.ts
- [ ] T172 [US8] Generate QR code image in apps/backend/src/modules/owner/owner-plant.service.ts
- [ ] T173 [US8] Create share profile screen in apps/owner-app/lib/features/plant_profile/screens/share_profile_screen.dart
- [ ] T174 [US8] Implement share sheet with copy/WhatsApp/social in apps/owner-app/lib/features/plant_profile/widgets/share_sheet.dart
- [ ] T175 [US8] Create public profile page (web) at apps/admin/src/app/p/[id]/page.tsx

**Checkpoint**: Owner can share link/QR, link opens public profile in browser

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements across all user stories

### Error Handling & Edge Cases

- [ ] T176 [P] Add offline mode with cached data in apps/consumer-app/lib/core/api/offline_cache.dart
- [ ] T177 [P] Add offline mode with cached data in apps/owner-app/lib/core/api/offline_cache.dart
- [ ] T178 Add clustered markers for overlapping plants in apps/consumer-app/lib/features/map/screens/map_screen.dart
- [ ] T179 Add file type validation for document uploads in apps/backend/src/modules/storage/storage.service.ts
- [ ] T180 Add request rate limiting middleware in apps/backend/src/common/guards/throttle.guard.ts

### Logging & Observability

- [ ] T181 [P] Configure structured JSON logging in apps/backend/src/main.ts
- [ ] T182 [P] Add request correlation ID middleware in apps/backend/src/common/interceptors/correlation.interceptor.ts
- [ ] T183 [P] Create audit log for admin actions in apps/backend/src/modules/admin/admin-audit.service.ts

### Security Hardening

- [ ] T184 [P] Add input sanitization to all DTOs in apps/backend/src/common/decorators/sanitize.decorator.ts
- [ ] T185 [P] Add CORS configuration in apps/backend/src/main.ts
- [ ] T186 [P] Add helmet security headers in apps/backend/src/main.ts

### Final Validation

- [ ] T187 Run full integration test: owner registers → consumer discovers → sends message → owner replies
- [ ] T188 Validate all quickstart.md steps work end-to-end
- [ ] T189 Verify all API endpoints match contracts/openapi.yaml

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **US2 Owner Registration (Phase 3)**: Depends on Phase 2 - Creates plant data needed by US1
- **US1 Consumer Discovery (Phase 4)**: Depends on Phase 2 & US2 (needs plants to discover)
- **US3 Admin Verification (Phase 5)**: Depends on Phase 2 & US2 (needs verification requests)
- **US4 Plant Details (Phase 6)**: Depends on US1 (extends consumer app)
- **US5 Owner Updates (Phase 7)**: Depends on US2 (extends owner app)
- **US9 Messaging (Phase 8)**: Depends on US1 & US2 (needs both apps)
- **US6 Search/Filter (Phase 9)**: Depends on US1 (extends discovery)
- **US7 Analytics (Phase 10)**: Depends on US2 & US4 (needs view tracking)
- **US8 Shareable Link (Phase 11)**: Depends on US2 (extends owner features)
- **Polish (Phase 12)**: Depends on all user stories

### User Story Dependencies Graph

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Foundational) ──── BLOCKS ALL ────
    │
    ├──────────────────────┐
    ▼                      ▼
Phase 3 (US2)         Phase 4 (US1)
Owner Registration    Consumer Discovery
    │                      │
    ├──────────────────────┤
    │                      │
    ▼                      ▼
Phase 5 (US3)         Phase 6 (US4)
Admin Verification    Plant Details
                           │
    ┌──────────────────────┼──────────────────────┐
    │                      │                      │
    ▼                      ▼                      ▼
Phase 7 (US5)         Phase 8 (US9)         Phase 9 (US6)
Owner Updates         Messaging              Search/Filter
    │                      │
    ▼                      │
Phase 10 (US7)             │
Analytics                  │
    │                      │
    ▼                      │
Phase 11 (US8)             │
Shareable Link             │
    │                      │
    └──────────────────────┘
                │
                ▼
         Phase 12 (Polish)
```

### Within Each User Story

- Backend implementation before Flutter/Admin implementation
- Models/services before controllers
- Core components before UI screens
- Story complete before moving to dependent phases

### Parallel Opportunities

**Setup Phase:**
```
T002, T003, T004, T005, T006, T007 can all run in parallel
```

**Foundational Phase:**
```
After T010 (auth): T011, T012, T013, T014, T015, T016 can run in parallel
T021, T022, T023, T024, T025, T026, T027, T028, T029, T030, T031 can run in parallel
```

**US2 Backend:**
```
After T034: T035, T036, T037, T038 can run in parallel (auth endpoints)
After T040: T041, T042, T043 can run in parallel (plant endpoints)
```

**US9 Chat Implementation:**
```
Backend: T118-T128 (REST endpoints) parallel with T129-T132 (WebSocket)
Consumer App: T134-T147 can run parallel with Owner App: T148-T161
```

---

## Implementation Strategy

### MVP First (Phase 1-4: US2 + US1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: US2 (Owner Registration)
4. Complete Phase 4: US1 (Consumer Discovery)
5. **STOP and VALIDATE**: Test owner can register plant, consumer can discover it
6. Deploy/demo - This is MVP!

### Full P1+P2 Delivery

1. MVP (above)
2. Add Phase 5: US3 (Admin Verification)
3. Add Phase 6: US4 (Plant Details)
4. Add Phase 7: US5 (Owner Updates)
5. Add Phase 8: US9 (Messaging) ← Major feature
6. Test end-to-end with chat

### Complete V1

1. Full P1+P2 (above)
2. Add Phase 9: US6 (Search/Filter)
3. Add Phase 10: US7 (Analytics)
4. Add Phase 11: US8 (Shareable Link)
5. Add Phase 12: Polish
6. Final validation and deploy

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each phase should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
- Backend tasks should be completed before corresponding Flutter/Admin tasks
- WebSocket implementation requires Redis to be running
- MinIO must be configured before photo/document uploads work
