# Research: V1 Water Plant Discovery Platform

**Feature Branch**: `001-water-plant-discovery`
**Date**: 2026-01-17
**Status**: Complete

## Executive Summary

This document captures technology decisions for the FlowGrid V1 platform based on research of production-grade systems used by Zomato, Swiggy, Uber, DoorDash, and Flutter best practices. The stack is chosen for scalability, maintainability, and alignment with Indian market requirements.

---

## 1. Backend Framework

### Decision: NestJS (Node.js + TypeScript)

### Rationale
- **Enterprise-grade architecture**: NestJS provides dependency injection, modules, decorators, and services similar to Angular - ideal for large-scale applications
- **TypeScript-first**: End-to-end type safety reduces runtime errors
- **Industry adoption**: Similar to patterns used by DoorDash (Kotlin/gRPC) and Uber (microservices)
- **Ecosystem maturity**: First-class support for PostgreSQL, Redis, JWT, OpenAPI/Swagger
- **Constitution compliance**: Supports API-first development with built-in OpenAPI generation

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| Express.js | No built-in structure; requires manual setup for DI, modules, validation |
| FastAPI (Python) | Excellent, but team expertise is in JavaScript ecosystem |
| Go/Gin | Better performance but higher learning curve; overkill for V1 scale |
| Django | Python ecosystem; less TypeScript integration for shared types with Flutter |

### References
- [NestJS + TypeORM + PostgreSQL: The Enterprise Node.js Stack in 2025](https://medium.com/@lucaswade0595/typenestjs-typeorm-postgresql-the-enterprise-node-js-stack-in-2025-cba739f350a8)

---

## 2. Database

### Decision: PostgreSQL 16 with PostGIS Extension

### Rationale
- **Geospatial support**: PostGIS enables "find plants within 5km" queries with spatial indexing
- **Production proven**: Used by Swiggy, DoorDash for relational data
- **ACID compliance**: Critical for financial transactions (future V2+)
- **Constitution compliance**: Supports data localization requirement (Indian hosting available on AWS/GCP)
- **Mature ecosystem**: Excellent ORM support (Prisma, TypeORM, Drizzle)

### PostGIS Capabilities Required
- `ST_DWithin()` for radius-based queries
- `ST_Distance()` for calculating distances
- `GEOGRAPHY` type for accurate Earth-surface calculations
- Spatial indexing (GIST) for query performance

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| MongoDB | Less suitable for relational data (owner-plant relationships); weaker geospatial |
| MySQL | PostGIS is more mature than MySQL spatial extensions |
| CockroachDB | Overkill for V1 scale; adds operational complexity |

### References
- [API with NestJS #185: Operations with PostGIS Polygons](https://wanago.io/2025/01/27/api-nestjs-postgis-polygons-operations-postgresql-drizzle/)
- [Simplifying Geospatial Operations with PostGIS in Node.js](https://jsuyog2.medium.com/simplifying-geospatial-operations-with-postgis-in-node-js-fc0f1d59a9a1)

---

## 3. ORM Layer

### Decision: Prisma ORM

### Rationale
- **Type safety**: Auto-generated TypeScript types from schema
- **Migration management**: Built-in versioned migrations (Constitution compliance)
- **Developer experience**: Intuitive query API, excellent documentation
- **PostGIS support**: Via `prisma-postgis` extension for geography types
- **Production ready**: Used by many Next.js and NestJS production apps

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| TypeORM | More boilerplate; decorator-heavy; migration system less intuitive |
| Drizzle ORM | Newer, less mature ecosystem; Prisma has better community support |
| Knex.js | Query builder only; no schema management or type generation |

---

## 4. Caching Layer

### Decision: Redis 7

### Rationale
- **Industry standard**: Used by Uber, Swiggy, DoorDash for caching and session management
- **Low latency**: Sub-millisecond reads for frequently accessed data (plant profiles)
- **Data structures**: Supports sorted sets for leaderboards, hashes for sessions
- **Constitution compliance**: Enables stateless services by externalizing session state

### Use Cases in V1
- Session token storage (JWT refresh tokens)
- Plant profile caching (TTL: 5 minutes)
- Rate limiting counters
- Geospatial caching (plant locations by city)

---

## 5. Mobile App Framework

### Decision: Flutter 3.x with Clean Architecture + BLoC

### Rationale
- **Cross-platform**: Single codebase for iOS and Android (cost-effective for bootstrapped team)
- **Performance**: Near-native performance with compiled Dart
- **UI flexibility**: Pixel-perfect dark theme implementation possible
- **Industry adoption**: Used by Alibaba, Google Pay, BMW
- **Clean Architecture**: Separation of concerns enables testability and maintainability

### Architecture Pattern
```
lib/
├── core/                  # Shared utilities, themes, constants
│   ├── theme/            # Dark theme, colors, typography
│   ├── network/          # API client, interceptors
│   └── utils/            # Helpers, extensions
├── features/             # Feature-first organization
│   ├── auth/
│   │   ├── data/         # Repositories, data sources
│   │   ├── domain/       # Entities, use cases
│   │   └── presentation/ # BLoC, screens, widgets
│   ├── discovery/        # Map, plant list
│   ├── plant_details/
│   └── profile/
└── main.dart
```

### State Management: BLoC

- **Predictable**: Unidirectional data flow
- **Testable**: Easy to unit test business logic
- **Scalable**: Handles complex state across features
- **Production proven**: Recommended for enterprise Flutter apps

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| React Native | Performance concerns for map-heavy UI; requires bridge for native features |
| Native (Kotlin + Swift) | 2x development cost; team resource constraint |
| Riverpod | Excellent but BLoC has more enterprise adoption and testing patterns |

### References
- [Flutter Clean Architecture: Build Scalable Apps](https://www.djamware.com/post/68fd9dee1157e31c6604ab8f/flutter-clean-architecture-build-scalable-apps-stepbystep)
- [Flutter Official Architecture Guide](https://docs.flutter.dev/app-architecture/guide)

---

## 6. Admin Dashboard

### Decision: Next.js 15 + shadcn/ui + Tailwind CSS

### Rationale
- **Server-side rendering**: Fast initial load for admin operations
- **App Router**: Modern React patterns with server components
- **shadcn/ui**: Accessible, customizable components (not a dependency, copied into project)
- **Tailwind CSS**: Rapid UI development, consistent with design system
- **Constitution compliance**: Follows DRY principle with shared design tokens

### Key Libraries
- `@tanstack/react-table` - Data tables with sorting, filtering, pagination
- `react-hook-form` + `zod` - Form handling with validation
- `recharts` - Analytics charts
- `next-auth` - Authentication (future)
- `next-themes` - Light/dark mode

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| React Admin | Opinionated; harder to customize for our specific workflow |
| Retool | External SaaS; data privacy concerns for admin dashboard |
| Vue.js + Vuetify | Team expertise is React-focused |

### References
- [Next.js + shadcn/ui Admin Dashboard Template](https://vercel.com/templates/next.js/next-js-and-shadcn-ui-admin-dashboard)
- [Admin Dashboard Starter with Next.js 16 and Shadcn UI](https://github.com/Kiranism/next-shadcn-dashboard-starter)

---

## 7. File Storage

### Decision: MinIO (Local S3-Compatible Storage)

### Rationale
- **V1 is fully local**: No cloud dependencies - everything runs on local Docker
- **S3-compatible API**: Uses standard AWS S3 SDK, zero code changes when migrating to cloud
- **Production-ready**: Used by companies like Alibaba, Adobe for object storage
- **Self-hosted**: Full control over data, no external service dependencies
- **Easy migration path**: Switch to AWS S3/DigitalOcean Spaces by changing endpoint URL

### Implementation
- MinIO runs as Docker container alongside PostgreSQL and Redis
- Plant photos: Public bucket served via Nginx reverse proxy
- Verification documents: Private bucket with pre-signed URLs (15-minute expiry)
- Image optimization: Sharp.js for server-side resizing before upload
- Backup: Docker volume mounts for persistent storage

### Docker Configuration
```yaml
minio:
  image: minio/minio:latest
  container_name: flowgrid-minio
  command: server /data --console-address ":9001"
  environment:
    MINIO_ROOT_USER: flowgrid
    MINIO_ROOT_PASSWORD: flowgrid123
  ports:
    - "9000:9000"   # S3 API
    - "9001:9001"   # Console UI
  volumes:
    - minio_data:/data
```

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| AWS S3 | Cloud dependency; V1 must be fully local |
| Local filesystem | No S3 API compatibility; harder migration later |
| Cloudflare R2 | Cloud dependency |

---

## 8. Authentication

### Decision: JWT with Refresh Tokens

### Rationale
- **Stateless**: No server-side session storage required
- **Scalable**: Works across multiple API instances
- **Industry standard**: Used by all major platforms
- **Constitution compliance**: Short-lived access tokens (15 min), longer refresh tokens (7 days)

### Implementation
- Access token: 15 minutes expiry, stored in memory (Flutter) / httpOnly cookie (web)
- Refresh token: 7 days expiry, stored in secure storage (Flutter) / httpOnly cookie (web)
- Password hashing: bcrypt with 12 rounds
- Future: Phone OTP via Twilio/MSG91 for V1.5

### V1 Simplification
- Consumer app: admin/admin placeholder (per spec)
- Owner app: Phone + password
- Admin dashboard: admin/admin placeholder (per spec)

---

## 9. Maps Integration

### Decision: Google Maps (Primary) with OpenStreetMap (Fallback)

### Rationale
- **Accuracy**: Best map data for India, especially rural areas
- **Flutter support**: Official `google_maps_flutter` package
- **Features**: Clustering, custom markers, directions API
- **Fallback**: OpenStreetMap via `flutter_map` for cost optimization

### Cost Consideration
- Google Maps: $7/1000 loads (mobile), $2/1000 Geocoding requests
- Budget: ~$200/month for 30k active users
- Optimization: Cache geocoding results, use clustering to reduce marker renders

---

## 10. Deployment & Infrastructure

### Decision: Docker + Cloud Platform (AWS/GCP/DigitalOcean)

### Rationale
- **Reproducibility**: Same environment from dev to production (Constitution compliance)
- **Scalability**: Easy horizontal scaling with container orchestration
- **Cost**: Start with single VM, scale as needed

### V1 Infrastructure (Fully Local - Docker Compose)
```
┌─────────────────────────────────────────────────────────────────┐
│                    Local Docker Environment                      │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Nginx     │  │   NestJS    │  │   PostgreSQL + PostGIS  │  │
│  │   (Proxy)   │──│ (API + WS)  │──│   (Database)            │  │
│  │   :80/:443  │  │   :3000     │  │   :5432                 │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│         │                │                                       │
│         │         ┌──────┴──────┐    ┌─────────────────────┐    │
│         │         │    Redis    │    │       MinIO         │    │
│         │         │ (Cache+Pub) │    │   (S3 Storage)      │    │
│         │         │   :6379     │    │   :9000/:9001       │    │
│         │         └─────────────┘    └─────────────────────┘    │
│         │                                                        │
│  ┌──────┴──────┐  ┌─────────────┐                               │
│  │   Next.js   │  │   pgAdmin   │                               │
│  │   (Admin)   │  │ (DB Admin)  │                               │
│  │   :3001     │  │   :5050     │                               │
│  └─────────────┘  └─────────────┘                               │
└─────────────────────────────────────────────────────────────────┘

Mobile Apps (Flutter):
- Consumer App → connects to localhost:3000 (HTTP + WebSocket)
- Owner App → connects to localhost:3000 (HTTP + WebSocket)
```

### V1 Development Environment
- **Cost**: $0 (all local containers)
- **Requirements**: Docker Desktop, 8GB RAM minimum
- **Network**: All services on same Docker network; apps connect via localhost

### Production Migration Path (V2+)
- Replace MinIO endpoint with AWS S3
- Replace local PostgreSQL with managed (RDS/Cloud SQL)
- Add load balancer for horizontal scaling
- Add CDN for static assets

---

## 11. Real-Time Messaging

### Decision: WebSocket with NestJS Gateway + Server-Managed Encryption

### Rationale
- **Industry standard**: WhatsApp, Instagram, Snapchat all use persistent connections (WebSocket/MQTT)
- **Low latency**: <500ms message delivery on local network
- **Bidirectional**: Real-time typing indicators, read receipts, presence possible
- **NestJS native**: Built-in WebSocket gateway with decorators
- **Server-managed encryption**: Simpler for V1; true E2E in V1.5

### Architecture
```
┌─────────────────┐     WebSocket      ┌─────────────────────┐
│  Consumer App   │◄──────────────────►│                     │
│   (Flutter)     │                    │   NestJS Gateway    │
└─────────────────┘                    │                     │
                                       │  - Connection mgmt  │
┌─────────────────┐     WebSocket      │  - Room management  │
│   Owner App     │◄──────────────────►│  - Message routing  │
│   (Flutter)     │                    │  - Presence tracking│
└─────────────────┘                    └──────────┬──────────┘
                                                  │
                                       ┌──────────┴──────────┐
                                       │   Redis Pub/Sub     │
                                       │   (Multi-instance)  │
                                       └──────────┬──────────┘
                                                  │
                                       ┌──────────┴──────────┐
                                       │   PostgreSQL        │
                                       │   (Message Store)   │
                                       └─────────────────────┘
```

### WebSocket Events
```typescript
// Client → Server
'message:send'      { conversationId, content }
'message:read'      { conversationId, messageId }
'typing:start'      { conversationId }
'typing:stop'       { conversationId }

// Server → Client
'message:new'       { message }
'message:delivered' { messageId }
'message:read'      { messageId, readAt }
'typing:indicator'  { conversationId, userId }
'notification:new'  { type, data }
```

### Message Encryption
- **Algorithm**: AES-256-GCM (authenticated encryption)
- **Key management**: Server generates and stores symmetric key per conversation
- **Storage**: Messages stored encrypted; decrypted only when delivered
- **Future V1.5**: Signal Protocol for true E2E encryption

### Message Retention (Snapchat-style)
- Users configure retention: off, 24h, 7d, 30d
- If both parties have settings, shorter period applies
- Background job runs hourly to delete expired messages
- Deletion is hard delete (not soft delete)

### Flutter Implementation
```dart
// Using web_socket_channel package
class ChatService {
  late WebSocketChannel _channel;

  void connect(String token) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:3000/chat?token=$token')
    );
  }

  void sendMessage(String conversationId, String content) {
    _channel.sink.add(jsonEncode({
      'event': 'message:send',
      'data': { 'conversationId': conversationId, 'content': content }
    }));
  }
}
```

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| Firebase Realtime DB | Cloud dependency; V1 must be local |
| Socket.io | More overhead; NestJS WebSocket gateway is sufficient |
| Server-Sent Events | One-way only; need bidirectional for typing indicators |
| HTTP Polling | Higher latency; more server load |
| MQTT | Better for IoT; overkill for chat |

---

## 12. Design System

### Decision: Custom Dark Theme with FlowGrid Brand

### Rationale
- User requested: Professional, clean, dark-themed, no emojis
- Consistent across: Consumer app, Owner app, Admin dashboard

### Color Palette
```
Primary Colors:
- Background:     #0A0A0A (Rich Black)
- Surface:        #1A1A1A (Dark Gray)
- Surface Light:  #2A2A2A (Ash Gray)

Accent Colors:
- Primary Blue:   #3B82F6 (Vibrant Blue)
- Primary Hover:  #2563EB (Darker Blue)

Text Colors:
- Primary:        #FFFFFF (White)
- Secondary:      #A1A1AA (Gray)
- Muted:          #71717A (Dark Gray)

Status Colors:
- Success:        #22C55E (Green)
- Warning:        #F59E0B (Amber)
- Error:          #EF4444 (Red)
- Verified Badge: #3B82F6 (Blue)

Border:           #27272A (Subtle Gray)
```

### Typography
- **Font Family**: Inter (clean, professional, excellent readability)
- **Headings**: Inter Semi-Bold (600)
- **Body**: Inter Regular (400)
- **Captions**: Inter Medium (500)

### Design Principles
1. **No emojis** - Use icons from Lucide React / Flutter Icons
2. **High contrast** - WCAG AA compliance for accessibility
3. **Consistent spacing** - 4px grid system
4. **Subtle animations** - 200ms transitions, no flashy effects

---

## 12. Testing Strategy

### Decision: Multi-layer Testing Approach

### Backend (NestJS)
- **Unit tests**: Jest for services and utilities (>80% coverage for core)
- **Integration tests**: Supertest for API endpoints
- **Contract tests**: Validate OpenAPI spec compliance

### Flutter Apps
- **Unit tests**: Test use cases and BLoCs
- **Widget tests**: Test UI components in isolation
- **Integration tests**: End-to-end user journeys (optional for V1)

### Admin Dashboard (Next.js)
- **Unit tests**: Jest + React Testing Library
- **E2E tests**: Playwright for critical admin workflows (optional for V1)

---

## 13. Security Implementation

### Constitution Compliance Checklist

| Requirement | Implementation |
|-------------|----------------|
| Input validation | Zod schemas on all API endpoints |
| JWT authentication | Access (15min) + Refresh (7d) tokens |
| RBAC | Guard decorators in NestJS |
| TLS encryption | HTTPS enforced via Nginx/Cloudflare |
| Password hashing | bcrypt (12 rounds) |
| SQL injection prevention | Prisma parameterized queries |
| Rate limiting | NestJS throttler (100 req/min) |
| Audit logging | Admin actions logged to database |
| Secret management | Environment variables (dotenv) |

---

## 14. Monitoring & Observability

### Decision: Lightweight Stack for V1

| Component | Tool | Rationale |
|-----------|------|-----------|
| Error tracking | Sentry | Free tier, Flutter + Node.js support |
| Logging | Pino (structured JSON) | Fast, production-ready |
| Uptime | UptimeRobot | Free monitoring for critical endpoints |
| Analytics | PostHog (self-hosted) | Privacy-friendly, free tier |

### Future (V2+)
- Prometheus + Grafana for metrics
- Jaeger for distributed tracing
- ELK stack for log aggregation

---

## 15. Architecture Pattern

### Decision: Modular Monolith (V1) with Microservices-Ready Design

### Rationale
- **V1 Reality**: Small team (3 co-founders + 2-3 engineers) cannot operate true microservices
- **Future-Ready**: Module boundaries designed for easy extraction to microservices
- **Industry Pattern**: DoorDash and Uber started as monoliths, migrated to microservices at scale

### V1 Architecture (Modular Monolith)
```
┌─────────────────────────────────────────────────────────────────────┐
│                         API Gateway (Nginx)                         │
│                    (Rate limiting, SSL termination)                 │
└─────────────────────────────────────┬───────────────────────────────┘
                                      │
┌─────────────────────────────────────┴───────────────────────────────┐
│                        NestJS Application                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────────┐  │
│  │   Auth      │ │   Plants    │ │   Owners    │ │   Admin       │  │
│  │   Module    │ │   Module    │ │   Module    │ │   Module      │  │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └───────┬───────┘  │
│         │               │               │                │          │
│         └───────────────┼───────────────┼────────────────┘          │
│                         │               │                           │
│                  ┌──────┴───────────────┴──────┐                    │
│                  │    Shared Services Layer    │                    │
│                  │  (Events, Cache, Storage)   │                    │
│                  └─────────────┬───────────────┘                    │
└────────────────────────────────┼────────────────────────────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────┴─────────┐ ┌──────────┴──────────┐ ┌────────┴────────┐
│   PostgreSQL      │ │       Redis         │ │      S3         │
│   + PostGIS       │ │   (Cache + Events)  │ │   (Storage)     │
└───────────────────┘ └─────────────────────┘ └─────────────────┘
```

### Event-Driven Communication (Internal)

V1 uses Redis Pub/Sub for internal events, designed for future Kafka migration:

```typescript
// Event types defined for loose coupling
PlantCreated { plantId, ownerId, location }
PlantUpdated { plantId, changes }
VerificationSubmitted { ownerId, documentIds }
VerificationDecided { ownerId, status, adminId }
PlantViewed { plantId, viewerId }
```

### Future Microservices Path (V3+)
```
                    ┌─────────────────────────────┐
                    │      API Gateway            │
                    │   (Kong / AWS API Gateway)  │
                    └─────────────┬───────────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
┌────────┴────────┐    ┌──────────┴──────────┐   ┌────────┴────────┐
│   Auth Service  │    │   Plant Service     │   │  Owner Service  │
│   (Go/Node.js)  │    │   (Node.js/Go)      │   │   (Node.js)     │
└────────┬────────┘    └──────────┬──────────┘   └────────┬────────┘
         │                        │                        │
         └────────────────────────┼────────────────────────┘
                                  │
                    ┌─────────────┴───────────────┐
                    │    Kafka (Event Bus)        │
                    └─────────────────────────────┘
```

### API Design: REST with GraphQL Consideration

- **V1**: RESTful APIs with OpenAPI/Swagger documentation
- **Future**: GraphQL for mobile apps (single request for complex data)
- **Rationale**: REST is simpler to implement and debug; GraphQL adds complexity

### Cache Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cache Layers                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Layer 1: CDN (CloudFront/Cloudflare)                          │
│  └── Static assets, plant photos                               │
│                                                                 │
│  Layer 2: API Response Cache (Redis)                           │
│  └── Plant listings by location (TTL: 60s)                     │
│  └── Plant details (TTL: 300s, invalidate on update)           │
│                                                                 │
│  Layer 3: Database Query Cache (Prisma)                        │
│  └── Frequently accessed queries                               │
│                                                                 │
│  Layer 4: Client Cache (Flutter)                               │
│  └── Offline-first with Hive/SQLite                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Summary: Final Tech Stack

| Layer | Technology | Version |
|-------|------------|---------|
| **Mobile Apps** | Flutter + BLoC | 3.x |
| **Admin Dashboard** | Next.js + shadcn/ui | 15.x |
| **Backend API** | NestJS (TypeScript) | 10.x |
| **Real-Time** | WebSocket (NestJS Gateway) | - |
| **API Gateway** | Nginx (local) | 1.x |
| **Database** | PostgreSQL + PostGIS | 16.x |
| **ORM** | Prisma | 5.x |
| **Cache** | Redis | 7.x |
| **Event Bus** | Redis Pub/Sub | - |
| **File Storage** | MinIO (local S3) | latest |
| **Message Encryption** | AES-256-GCM (server-managed) | - |
| **Maps** | Google Maps | - |
| **Auth** | JWT + bcrypt | - |
| **Containerization** | Docker + Docker Compose | - |
| **CI/CD** | GitHub Actions | - |

**V1 Constraint**: Everything runs locally in Docker. No cloud dependencies.

---

## Open Questions Resolved

| Question | Resolution |
|----------|------------|
| Which backend framework? | NestJS for enterprise patterns and TypeScript |
| How to handle geospatial queries? | PostGIS extension with spatial indexing |
| State management in Flutter? | BLoC for predictability and testability |
| Admin dashboard framework? | Next.js with shadcn/ui for customization |
| Where to host V1? | **Fully local** - Docker Compose with all services |
| How to handle file uploads? | **MinIO** (local S3-compatible) with signed URLs |
| How to implement real-time chat? | **WebSocket** via NestJS Gateway (industry standard) |
| How to encrypt messages? | **AES-256-GCM** with server-managed keys (V1); E2E in V1.5 |
| How to handle message retention? | **User-configurable** (off/24h/7d/30d); shorter setting wins |
| Where to initiate chat? | **Tooltip + Chats tab** (Instagram-style UX) |
