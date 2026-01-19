# Quickstart Guide: V1 Water Plant Discovery Platform

**Feature Branch**: `001-water-plant-discovery`
**Date**: 2026-01-17

This guide provides step-by-step instructions to set up the development environment and run all services locally.

---

## Prerequisites

### Required Software

| Tool | Version | Installation |
|------|---------|--------------|
| **Node.js** | 20.x LTS | [nodejs.org](https://nodejs.org/) or `nvm install 20` |
| **pnpm** | 8.x | `npm install -g pnpm` |
| **Flutter** | 3.x | [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started/install) |
| **Docker** | 24.x | [docker.com](https://docs.docker.com/get-docker/) |
| **Docker Compose** | 2.x | Included with Docker Desktop |
| **PostgreSQL Client** | 16.x | Optional, for direct DB access |

### Verify Installation

```bash
# Check all prerequisites
node --version      # v20.x.x
pnpm --version      # 8.x.x
flutter --version   # Flutter 3.x.x
docker --version    # Docker version 24.x.x
docker compose version  # Docker Compose version v2.x.x
```

---

## Repository Structure

```text
flowgrid/
├── apps/
│   ├── backend/              # NestJS API server
│   │   ├── src/
│   │   │   ├── modules/      # Feature modules
│   │   │   ├── common/       # Shared utilities
│   │   │   └── main.ts
│   │   ├── prisma/
│   │   │   ├── schema.prisma
│   │   │   └── migrations/
│   │   ├── test/
│   │   └── package.json
│   │
│   ├── admin/                # Next.js admin dashboard
│   │   ├── src/
│   │   │   ├── app/          # App router pages
│   │   │   ├── components/   # UI components
│   │   │   └── lib/          # Utilities
│   │   └── package.json
│   │
│   ├── consumer-app/         # Flutter consumer app
│   │   ├── lib/
│   │   │   ├── core/         # Core utilities
│   │   │   ├── features/     # Feature modules
│   │   │   └── main.dart
│   │   └── pubspec.yaml
│   │
│   └── owner-app/            # Flutter owner app
│       ├── lib/
│       │   ├── core/
│       │   ├── features/
│       │   └── main.dart
│       └── pubspec.yaml
│
├── packages/                 # Shared packages (future)
│   └── flutter-ui/           # Shared Flutter components
│
├── docker/
│   ├── docker-compose.yml
│   ├── docker-compose.dev.yml
│   └── Dockerfile.backend
│
├── specs/                    # Feature specifications
│   └── 001-water-plant-discovery/
│
├── .env.example
├── pnpm-workspace.yaml
└── README.md
```

---

## Quick Setup (5 minutes)

### 1. Clone and Install

```bash
# Clone repository
git clone https://github.com/hemanthpuppala/SymLink.git flowgrid
cd flowgrid

# Install Node.js dependencies
pnpm install

# Install Flutter dependencies
cd apps/consumer-app && flutter pub get && cd ../..
cd apps/owner-app && flutter pub get && cd ../..
```

### 2. Start Infrastructure

```bash
# Start PostgreSQL + Redis + MinIO via Docker
docker compose -f docker/docker-compose.dev.yml up -d

# Verify services are running
docker compose -f docker/docker-compose.dev.yml ps

# Expected output: 4 services running
# - flowgrid-postgres (5432)
# - flowgrid-redis (6379)
# - flowgrid-minio (9000, 9001)
# - flowgrid-pgadmin (5050)
```

### 3. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your local settings (defaults work for local dev)
```

**Default `.env` values:**

```env
# Database
DATABASE_URL="postgresql://flowgrid:flowgrid@localhost:5432/flowgrid?schema=public"

# Redis
REDIS_URL="redis://localhost:6379"

# JWT
JWT_SECRET="local-dev-secret-change-in-production"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"

# MinIO (Local S3-Compatible Storage)
MINIO_ENDPOINT="localhost"
MINIO_PORT=9000
MINIO_ACCESS_KEY="flowgrid"
MINIO_SECRET_KEY="flowgrid123"
MINIO_BUCKET_PHOTOS="flowgrid-photos"
MINIO_BUCKET_DOCUMENTS="flowgrid-documents"
MINIO_USE_SSL=false

# Message Encryption
MESSAGE_ENCRYPTION_KEY="32-byte-hex-key-for-aes-256-gcm"

# API
API_PORT=3000
API_PREFIX="v1"

# WebSocket
WS_PORT=3000
WS_PATH="/chat"
```

### 4. Initialize Database

```bash
# Navigate to backend
cd apps/backend

# Run migrations
pnpm prisma migrate dev

# Seed initial data (creates admin/admin user)
pnpm prisma db seed

# Generate Prisma client
pnpm prisma generate
```

### 5. Start Development Servers

```bash
# Terminal 1: Start backend API
cd apps/backend
pnpm dev

# Terminal 2: Start admin dashboard
cd apps/admin
pnpm dev

# Terminal 3: Start consumer app (iOS/Android emulator required)
cd apps/consumer-app
flutter run

# Terminal 4: Start owner app
cd apps/owner-app
flutter run
```

---

## Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Backend API** | http://localhost:3000/v1 | - |
| **WebSocket (Chat)** | ws://localhost:3000/chat | JWT token required |
| **API Docs (Swagger)** | http://localhost:3000/api-docs | - |
| **Admin Dashboard** | http://localhost:3001 | admin / admin |
| **PostgreSQL** | localhost:5432 | flowgrid / flowgrid |
| **Redis** | localhost:6379 | - |
| **MinIO Console** | http://localhost:9001 | flowgrid / flowgrid123 |
| **MinIO S3 API** | http://localhost:9000 | flowgrid / flowgrid123 |
| **pgAdmin** | http://localhost:5050 | admin@flowgrid.io / admin |

---

## Docker Compose Configuration

**docker/docker-compose.dev.yml:**

```yaml
version: '3.8'

services:
  postgres:
    image: postgis/postgis:16-3.4
    container_name: flowgrid-postgres
    environment:
      POSTGRES_USER: flowgrid
      POSTGRES_PASSWORD: flowgrid
      POSTGRES_DB: flowgrid
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U flowgrid"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: flowgrid-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

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
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Create default buckets on startup
  minio-setup:
    image: minio/mc:latest
    container_name: flowgrid-minio-setup
    depends_on:
      minio:
        condition: service_healthy
    entrypoint: >
      /bin/sh -c "
      mc alias set myminio http://minio:9000 flowgrid flowgrid123;
      mc mb --ignore-existing myminio/flowgrid-photos;
      mc mb --ignore-existing myminio/flowgrid-documents;
      mc anonymous set download myminio/flowgrid-photos;
      echo 'MinIO buckets created successfully';
      "

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: flowgrid-pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@flowgrid.io
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "5050:80"
    depends_on:
      - postgres

volumes:
  postgres_data:
  redis_data:
  minio_data:
```

---

## Common Commands

### Backend (NestJS)

```bash
cd apps/backend

# Development
pnpm dev                    # Start dev server with hot reload
pnpm build                  # Build for production
pnpm start:prod             # Start production server

# Database
pnpm prisma studio          # Open Prisma Studio (visual DB editor)
pnpm prisma migrate dev     # Run migrations
pnpm prisma migrate reset   # Reset database (destructive!)
pnpm prisma db seed         # Seed database

# Testing
pnpm test                   # Run unit tests
pnpm test:e2e               # Run E2E tests
pnpm test:cov               # Test coverage

# Linting
pnpm lint                   # Run ESLint
pnpm lint:fix               # Fix ESLint issues
```

### Admin Dashboard (Next.js)

```bash
cd apps/admin

# Development
pnpm dev                    # Start dev server (port 3001)
pnpm build                  # Build for production
pnpm start                  # Start production server

# Testing
pnpm test                   # Run tests
pnpm test:e2e               # Run E2E tests (Playwright)

# Linting
pnpm lint                   # Run ESLint
```

### Flutter Apps

```bash
cd apps/consumer-app  # or apps/owner-app

# Development
flutter run                 # Run on connected device/emulator
flutter run -d chrome       # Run on web (for testing)
flutter run --release       # Run release build

# Testing
flutter test                # Run unit tests
flutter test --coverage     # Test coverage

# Build
flutter build apk           # Build Android APK
flutter build appbundle     # Build Android App Bundle
flutter build ios           # Build iOS (macOS only)

# Code generation
flutter pub run build_runner build  # Generate code (BLoC, JSON serialization)

# Linting
flutter analyze             # Run Dart analyzer
```

### Docker

```bash
# Start all services
docker compose -f docker/docker-compose.dev.yml up -d

# Stop all services
docker compose -f docker/docker-compose.dev.yml down

# View logs
docker compose -f docker/docker-compose.dev.yml logs -f

# View specific service logs
docker compose -f docker/docker-compose.dev.yml logs -f postgres

# Reset everything (destructive!)
docker compose -f docker/docker-compose.dev.yml down -v
```

---

## Flutter Development Setup

### Android Setup

1. Install Android Studio
2. Install Android SDK (API 34 recommended)
3. Create an Android Virtual Device (AVD)
4. Configure Flutter:

```bash
flutter config --android-sdk /path/to/android/sdk
flutter doctor --android-licenses
flutter doctor  # Verify Android setup
```

### iOS Setup (macOS only)

1. Install Xcode from App Store
2. Install CocoaPods: `sudo gem install cocoapods`
3. Configure:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
flutter doctor  # Verify iOS setup
```

### VS Code Extensions

Recommended extensions for Flutter development:

- Dart
- Flutter
- Awesome Flutter Snippets
- Flutter Intl (for i18n)
- Error Lens

---

## Troubleshooting

### Database Connection Issues

```bash
# Check if PostgreSQL is running
docker compose -f docker/docker-compose.dev.yml ps

# Check PostgreSQL logs
docker compose -f docker/docker-compose.dev.yml logs postgres

# Reset database
docker compose -f docker/docker-compose.dev.yml down -v
docker compose -f docker/docker-compose.dev.yml up -d
```

### PostGIS Extension

If PostGIS extension fails to load:

```bash
# Connect to PostgreSQL
docker exec -it flowgrid-postgres psql -U flowgrid

# Enable PostGIS manually
CREATE EXTENSION IF NOT EXISTS postgis;
\q
```

### Flutter Build Issues

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Reset iOS pods (macOS only)
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
```

### Port Conflicts

If ports are in use:

```bash
# Find process using port
lsof -i :3000

# Kill process
kill -9 <PID>

# Or change ports in docker-compose.dev.yml and .env
```

### Node.js Memory Issues

```bash
# Increase Node.js memory limit
export NODE_OPTIONS="--max-old-space-size=4096"
```

---

## API Testing with curl

### Health Check

```bash
curl http://localhost:3000/v1/health
```

### Consumer Login

```bash
curl -X POST http://localhost:3000/v1/consumer/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin"}'
```

### List Plants Near Location

```bash
# Get plants near Hyderabad (17.385, 78.486)
curl "http://localhost:3000/v1/plants?lat=17.385&lng=78.486&radius=5000"
```

### Admin Login

```bash
curl -X POST http://localhost:3000/v1/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin"}'
```

---

## Next Steps

1. **Read the spec**: `specs/001-water-plant-discovery/spec.md`
2. **Understand the data model**: `specs/001-water-plant-discovery/data-model.md`
3. **Review API contracts**: `specs/001-water-plant-discovery/contracts/openapi.yaml`
4. **Check the implementation plan**: `specs/001-water-plant-discovery/plan.md`
5. **Start with tasks**: `specs/001-water-plant-discovery/tasks.md` (after running `/speckit.tasks`)
