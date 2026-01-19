# Data Model: V1 Water Plant Discovery Platform

**Feature Branch**: `001-water-plant-discovery`
**Date**: 2026-01-17
**Database**: PostgreSQL 16 + PostGIS

---

## Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│     Admin       │       │     Owner       │       │    Consumer     │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │       │ id (PK)         │
│ username        │       │ name            │       │ username        │
│ password_hash   │       │ phone           │       │ password_hash   │
│ role            │       │ password_hash   │       │ created_at      │
│ created_at      │       │ email           │       │ last_login      │
└────────┬────────┘       │ created_at      │       │ retention_set   │
         │                └────────┬────────┘       └────────┬────────┘
         │                         │                         │
         │    decides              │ owns (1:N)              │
         │                         │                         │
         ▼                         ▼                         │
┌─────────────────┐       ┌─────────────────┐               │
│ Verification    │       │     Plant       │               │
│   Request       │◄──────│                 │               │
├─────────────────┤       ├─────────────────┤               │
│ id (PK)         │       │ id (PK)         │               │
│ owner_id (FK)   │       │ owner_id (FK)   │               │
│ govt_id_url     │       │ name            │               │
│ business_url    │       │ address         │               │
│ fssai_url       │       │ location (GEOG) │               │
│ status          │       │ operating_hours │               │
│ rejection_reason│       │ tds_reading     │               │
│ submitted_at    │       │ price_per_liter │               │
│ decided_at      │       │ description     │               │
│ decided_by (FK) │       │ photos          │               │
└─────────────────┘       │ verification    │               │
                          │ is_open         │               │
                          │ view_count      │               │
                          │ created_at      │               │
                          │ updated_at      │               │
                          └────────┬────────┘               │
                                   │                        │
                    ┌──────────────┼────────────────────────┘
                    │              │
                    │ has (1:N)    │ participates (N:M via Conversation)
                    ▼              ▼
           ┌─────────────────┐    ┌─────────────────────────┐
           │    ViewLog      │    │     Conversation        │
           ├─────────────────┤    ├─────────────────────────┤
           │ id (PK)         │    │ id (PK)                 │
           │ plant_id (FK)   │    │ consumer_id (FK)        │
           │ viewer_type     │    │ owner_id (FK)           │
           │ viewer_id       │    │ plant_id (FK)           │
           │ viewed_at       │    │ last_message_at         │
           └─────────────────┘    │ consumer_retention      │
                                  │ owner_retention         │
                                  │ encryption_key          │
                                  │ created_at              │
                                  └────────────┬────────────┘
                                               │
                                               │ has (1:N)
                                               ▼
                                  ┌─────────────────────────┐
                                  │       Message           │
                                  ├─────────────────────────┤
                                  │ id (PK)                 │
                                  │ conversation_id (FK)    │
                                  │ sender_type             │
                                  │ sender_id               │
                                  │ content_encrypted       │
                                  │ status                  │
                                  │ sent_at                 │
                                  │ delivered_at            │
                                  │ read_at                 │
                                  │ deleted_by_consumer     │
                                  │ deleted_by_owner        │
                                  │ expires_at              │
                                  └─────────────────────────┘
```

---

## Entity Definitions

### 1. Admin

Internal FlowGrid staff who manage the platform.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, auto-gen | Unique identifier |
| `username` | VARCHAR(50) | UNIQUE, NOT NULL | Login username |
| `password_hash` | VARCHAR(255) | NOT NULL | bcrypt hashed password |
| `role` | ENUM | NOT NULL, DEFAULT 'admin' | 'super_admin', 'admin' |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Account creation time |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update time |

**Indexes**:
- `idx_admin_username` on `username` (unique)

**Seed Data**:
```sql
INSERT INTO admins (username, password_hash, role)
VALUES ('admin', '$2b$12$...', 'super_admin'); -- password: admin
```

---

### 2. Owner

Water plant business owners who list their plants on the platform.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, auto-gen | Unique identifier |
| `name` | VARCHAR(100) | NOT NULL | Owner's full name |
| `phone` | VARCHAR(15) | UNIQUE, NOT NULL | Phone number (with country code) |
| `password_hash` | VARCHAR(255) | NOT NULL | bcrypt hashed password |
| `email` | VARCHAR(255) | UNIQUE, NULL | Optional email address |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Registration time |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update time |

**Indexes**:
- `idx_owner_phone` on `phone` (unique)
- `idx_owner_email` on `email` (unique, partial where email IS NOT NULL)

**Validation Rules**:
- Phone: Valid Indian mobile number format (+91XXXXXXXXXX)
- Name: 2-100 characters, letters and spaces only
- Email: Valid email format (if provided)

---

### 3. Consumer

App users who discover and visit water plants.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, auto-gen | Unique identifier |
| `username` | VARCHAR(50) | UNIQUE, NOT NULL | Login username |
| `password_hash` | VARCHAR(255) | NOT NULL | bcrypt hashed password |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Registration time |
| `last_login` | TIMESTAMP | NULL | Last successful login |

**Indexes**:
- `idx_consumer_username` on `username` (unique)

**V1 Seed Data**:
```sql
INSERT INTO consumers (username, password_hash)
VALUES ('admin', '$2b$12$...'); -- password: admin
```

---

### 4. Plant

Water plant business listing with geospatial data.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, auto-gen | Unique identifier |
| `owner_id` | UUID | FK → owners.id, NOT NULL | Plant owner reference |
| `name` | VARCHAR(200) | NOT NULL | Plant business name |
| `address` | TEXT | NOT NULL | Full street address |
| `location` | GEOGRAPHY(Point, 4326) | NOT NULL | Lat/lng coordinates |
| `operating_hours` | VARCHAR(200) | NULL | e.g., "8 AM - 8 PM, Mon-Sat" |
| `tds_reading` | INTEGER | NULL, CHECK >= 0 | TDS in ppm (parts per million) |
| `price_per_liter` | DECIMAL(10,2) | NULL, CHECK >= 0 | Price in INR |
| `description` | TEXT | NULL | Plant description |
| `photos` | TEXT[] | DEFAULT '{}' | Array of photo URLs (max 5) |
| `verification_status` | ENUM | NOT NULL, DEFAULT 'unverified' | See verification states |
| `is_open` | BOOLEAN | NOT NULL, DEFAULT true | Currently open for business |
| `view_count` | INTEGER | NOT NULL, DEFAULT 0 | Total profile views |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Listing creation time |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update time |

**Verification Status Enum**:
- `unverified` - No documents submitted
- `pending` - Documents submitted, awaiting review
- `verified` - Documents approved
- `rejected` - Documents rejected (can resubmit)

**Indexes**:
- `idx_plant_owner` on `owner_id`
- `idx_plant_location` on `location` (GIST spatial index)
- `idx_plant_verification` on `verification_status`
- `idx_plant_is_open` on `is_open`
- `idx_plant_created` on `created_at DESC`

**Geospatial Queries**:
```sql
-- Find plants within 5km of a location
SELECT * FROM plants
WHERE ST_DWithin(
  location,
  ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
  5000 -- meters
)
AND is_open = true
ORDER BY ST_Distance(location, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography);
```

**Validation Rules**:
- Name: 2-200 characters
- Photos: Max 5 URLs, each URL max 500 characters
- TDS: 0-9999 ppm (realistic range for drinking water)
- Price: 0.01-100.00 INR per liter

---

### 5. VerificationRequest

Document submission for plant verification.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, auto-gen | Unique identifier |
| `owner_id` | UUID | FK → owners.id, NOT NULL | Owner who submitted |
| `government_id_url` | VARCHAR(500) | NOT NULL | Aadhaar/PAN document URL |
| `business_registration_url` | VARCHAR(500) | NOT NULL | Business certificate URL |
| `fssai_license_url` | VARCHAR(500) | NULL | FSSAI license URL (optional) |
| `status` | ENUM | NOT NULL, DEFAULT 'pending' | 'pending', 'approved', 'rejected' |
| `rejection_reason` | TEXT | NULL | Reason if rejected |
| `submitted_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Submission time |
| `decided_at` | TIMESTAMP | NULL | Decision time |
| `decided_by` | UUID | FK → admins.id, NULL | Admin who decided |

**Indexes**:
- `idx_verification_owner` on `owner_id`
- `idx_verification_status` on `status`
- `idx_verification_submitted` on `submitted_at DESC`

**Business Rules**:
- Only one pending request per owner at a time
- On approval: Update all owner's plants to `verification_status = 'verified'`
- On rejection: Owner can resubmit after addressing issues

---

### 6. ViewLog

Tracks plant profile views for analytics.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, auto-gen | Unique identifier |
| `plant_id` | UUID | FK → plants.id, NOT NULL | Viewed plant |
| `viewer_type` | ENUM | NOT NULL | 'consumer', 'anonymous' |
| `viewer_id` | UUID | NULL | Consumer ID if logged in |
| `viewed_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | View timestamp |

**Indexes**:
- `idx_viewlog_plant` on `plant_id`
- `idx_viewlog_time` on `viewed_at DESC`
- `idx_viewlog_plant_week` on `plant_id, viewed_at` (for weekly analytics)

**Aggregation Query**:
```sql
-- Get weekly view count for a plant
SELECT COUNT(*) FROM view_logs
WHERE plant_id = $1
AND viewed_at >= NOW() - INTERVAL '7 days';
```

---

### 7. Conversation

Chat thread between a Consumer and Owner about a specific Plant.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, auto-gen | Unique identifier |
| `consumer_id` | UUID | FK → consumers.id, NOT NULL | Consumer participant |
| `owner_id` | UUID | FK → owners.id, NOT NULL | Owner participant |
| `plant_id` | UUID | FK → plants.id, NOT NULL | Plant being discussed |
| `last_message_at` | TIMESTAMP | NULL | Time of last message (for sorting) |
| `consumer_retention` | ENUM | NOT NULL, DEFAULT 'off' | Consumer's retention setting |
| `owner_retention` | ENUM | NOT NULL, DEFAULT 'off' | Owner's retention setting |
| `encryption_key` | VARCHAR(64) | NOT NULL | AES-256 key (hex encoded) |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Conversation creation time |

**Retention Enum**:
- `off` - No auto-deletion (keep forever)
- `24h` - Delete after 24 hours
- `7d` - Delete after 7 days
- `30d` - Delete after 30 days

**Indexes**:
- `idx_conversation_consumer` on `consumer_id`
- `idx_conversation_owner` on `owner_id`
- `idx_conversation_plant` on `plant_id`
- `idx_conversation_last_message` on `last_message_at DESC`
- `idx_conversation_unique` on `(consumer_id, plant_id)` UNIQUE

**Business Rules**:
- One conversation per consumer-plant pair
- Encryption key generated on conversation creation
- Effective retention = MIN(consumer_retention, owner_retention)

---

### 8. Message

Individual chat message within a Conversation.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, auto-gen | Unique identifier |
| `conversation_id` | UUID | FK → conversations.id, NOT NULL | Parent conversation |
| `sender_type` | ENUM | NOT NULL | 'consumer', 'owner' |
| `sender_id` | UUID | NOT NULL | ID of sender (consumer or owner) |
| `content_encrypted` | TEXT | NOT NULL | AES-256-GCM encrypted message |
| `status` | ENUM | NOT NULL, DEFAULT 'sent' | 'sent', 'delivered', 'read' |
| `sent_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | When message was sent |
| `delivered_at` | TIMESTAMP | NULL | When delivered to recipient |
| `read_at` | TIMESTAMP | NULL | When read by recipient |
| `deleted_by_consumer` | BOOLEAN | NOT NULL, DEFAULT false | Consumer deleted from their view |
| `deleted_by_owner` | BOOLEAN | NOT NULL, DEFAULT false | Owner deleted from their view |
| `expires_at` | TIMESTAMP | NULL | Auto-deletion time (from retention) |

**Message Status Enum**:
- `sent` - Message sent to server
- `delivered` - Message delivered to recipient device
- `read` - Message read by recipient

**Indexes**:
- `idx_message_conversation` on `conversation_id`
- `idx_message_sent_at` on `sent_at DESC`
- `idx_message_expires` on `expires_at` WHERE `expires_at IS NOT NULL`
- `idx_message_status` on `conversation_id, status`

**Encryption Details**:
```typescript
// Encryption format
const encrypt = (plaintext: string, key: Buffer): string => {
  const iv = crypto.randomBytes(12); // 96-bit IV for GCM
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const tag = cipher.getAuthTag();
  // Format: base64(iv + tag + ciphertext)
  return Buffer.concat([iv, tag, encrypted]).toString('base64');
};
```

**Retention Auto-Deletion**:
```sql
-- Background job runs hourly
DELETE FROM messages
WHERE expires_at IS NOT NULL
AND expires_at < NOW();
```

---

### 9. Notification

In-app notifications for owners (verification status, new messages).

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, auto-gen | Unique identifier |
| `owner_id` | UUID | FK → owners.id, NOT NULL | Recipient owner |
| `type` | ENUM | NOT NULL | Notification type |
| `title` | VARCHAR(100) | NOT NULL | Notification title |
| `message` | TEXT | NOT NULL | Notification body |
| `data` | JSONB | NULL | Additional data (e.g., conversation_id) |
| `is_read` | BOOLEAN | NOT NULL, DEFAULT false | Read status |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Creation time |

**Notification Type Enum**:
- `verification_approved` - Documents approved
- `verification_rejected` - Documents rejected
- `new_message` - New chat message received
- `system` - System announcement

**Indexes**:
- `idx_notification_owner` on `owner_id`
- `idx_notification_unread` on `owner_id, is_read` WHERE `is_read = false`
- `idx_notification_created` on `created_at DESC`

---

## Prisma Schema

```prisma
// schema.prisma

generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["postgresqlExtensions"]
}

datasource db {
  provider   = "postgresql"
  url        = env("DATABASE_URL")
  extensions = [postgis]
}

enum AdminRole {
  super_admin
  admin
}

enum VerificationStatus {
  unverified
  pending
  verified
  rejected
}

enum RequestStatus {
  pending
  approved
  rejected
}

enum ViewerType {
  consumer
  anonymous
}

enum RetentionPeriod {
  off
  h24   @map("24h")
  d7    @map("7d")
  d30   @map("30d")
}

enum SenderType {
  consumer
  owner
}

enum MessageStatus {
  sent
  delivered
  read
}

enum NotificationType {
  verification_approved
  verification_rejected
  new_message
  system
}

model Admin {
  id                    String                @id @default(uuid())
  username              String                @unique @db.VarChar(50)
  passwordHash          String                @map("password_hash") @db.VarChar(255)
  role                  AdminRole             @default(admin)
  createdAt             DateTime              @default(now()) @map("created_at")
  updatedAt             DateTime              @updatedAt @map("updated_at")
  verificationDecisions VerificationRequest[]

  @@map("admins")
}

model Owner {
  id                   String                @id @default(uuid())
  name                 String                @db.VarChar(100)
  phone                String                @unique @db.VarChar(15)
  passwordHash         String                @map("password_hash") @db.VarChar(255)
  email                String?               @unique @db.VarChar(255)
  createdAt            DateTime              @default(now()) @map("created_at")
  updatedAt            DateTime              @updatedAt @map("updated_at")
  plants               Plant[]
  verificationRequests VerificationRequest[]
  conversations        Conversation[]
  notifications        Notification[]

  @@map("owners")
}

model Consumer {
  id            String         @id @default(uuid())
  username      String         @unique @db.VarChar(50)
  passwordHash  String         @map("password_hash") @db.VarChar(255)
  createdAt     DateTime       @default(now()) @map("created_at")
  lastLogin     DateTime?      @map("last_login")
  conversations Conversation[]

  @@map("consumers")
}

model Plant {
  id                 String                            @id @default(uuid())
  ownerId            String                            @map("owner_id")
  name               String                            @db.VarChar(200)
  address            String
  location           Unsupported("geography(Point, 4326)")
  operatingHours     String?                           @map("operating_hours") @db.VarChar(200)
  tdsReading         Int?                              @map("tds_reading")
  pricePerLiter      Decimal?                          @map("price_per_liter") @db.Decimal(10, 2)
  description        String?
  photos             String[]                          @default([])
  verificationStatus VerificationStatus                @default(unverified) @map("verification_status")
  isOpen             Boolean                           @default(true) @map("is_open")
  viewCount          Int                               @default(0) @map("view_count")
  createdAt          DateTime                          @default(now()) @map("created_at")
  updatedAt          DateTime                          @updatedAt @map("updated_at")
  owner              Owner                             @relation(fields: [ownerId], references: [id])
  viewLogs           ViewLog[]
  conversations      Conversation[]

  @@index([ownerId], map: "idx_plant_owner")
  @@index([verificationStatus], map: "idx_plant_verification")
  @@index([isOpen], map: "idx_plant_is_open")
  @@index([createdAt(sort: Desc)], map: "idx_plant_created")
  @@map("plants")
}

model VerificationRequest {
  id                      String        @id @default(uuid())
  ownerId                 String        @map("owner_id")
  governmentIdUrl         String        @map("government_id_url") @db.VarChar(500)
  businessRegistrationUrl String        @map("business_registration_url") @db.VarChar(500)
  fssaiLicenseUrl         String?       @map("fssai_license_url") @db.VarChar(500)
  status                  RequestStatus @default(pending)
  rejectionReason         String?       @map("rejection_reason")
  submittedAt             DateTime      @default(now()) @map("submitted_at")
  decidedAt               DateTime?     @map("decided_at")
  decidedBy               String?       @map("decided_by")
  owner                   Owner         @relation(fields: [ownerId], references: [id])
  admin                   Admin?        @relation(fields: [decidedBy], references: [id])

  @@index([ownerId], map: "idx_verification_owner")
  @@index([status], map: "idx_verification_status")
  @@index([submittedAt(sort: Desc)], map: "idx_verification_submitted")
  @@map("verification_requests")
}

model ViewLog {
  id         String     @id @default(uuid())
  plantId    String     @map("plant_id")
  viewerType ViewerType @map("viewer_type")
  viewerId   String?    @map("viewer_id")
  viewedAt   DateTime   @default(now()) @map("viewed_at")
  plant      Plant      @relation(fields: [plantId], references: [id])

  @@index([plantId], map: "idx_viewlog_plant")
  @@index([viewedAt(sort: Desc)], map: "idx_viewlog_time")
  @@index([plantId, viewedAt], map: "idx_viewlog_plant_week")
  @@map("view_logs")
}

model Conversation {
  id                String          @id @default(uuid())
  consumerId        String          @map("consumer_id")
  ownerId           String          @map("owner_id")
  plantId           String          @map("plant_id")
  lastMessageAt     DateTime?       @map("last_message_at")
  consumerRetention RetentionPeriod @default(off) @map("consumer_retention")
  ownerRetention    RetentionPeriod @default(off) @map("owner_retention")
  encryptionKey     String          @map("encryption_key") @db.VarChar(64)
  createdAt         DateTime        @default(now()) @map("created_at")
  consumer          Consumer        @relation(fields: [consumerId], references: [id])
  owner             Owner           @relation(fields: [ownerId], references: [id])
  plant             Plant           @relation(fields: [plantId], references: [id])
  messages          Message[]

  @@unique([consumerId, plantId], map: "idx_conversation_unique")
  @@index([consumerId], map: "idx_conversation_consumer")
  @@index([ownerId], map: "idx_conversation_owner")
  @@index([plantId], map: "idx_conversation_plant")
  @@index([lastMessageAt(sort: Desc)], map: "idx_conversation_last_message")
  @@map("conversations")
}

model Message {
  id                String        @id @default(uuid())
  conversationId    String        @map("conversation_id")
  senderType        SenderType    @map("sender_type")
  senderId          String        @map("sender_id")
  contentEncrypted  String        @map("content_encrypted")
  status            MessageStatus @default(sent)
  sentAt            DateTime      @default(now()) @map("sent_at")
  deliveredAt       DateTime?     @map("delivered_at")
  readAt            DateTime?     @map("read_at")
  deletedByConsumer Boolean       @default(false) @map("deleted_by_consumer")
  deletedByOwner    Boolean       @default(false) @map("deleted_by_owner")
  expiresAt         DateTime?     @map("expires_at")
  conversation      Conversation  @relation(fields: [conversationId], references: [id])

  @@index([conversationId], map: "idx_message_conversation")
  @@index([sentAt(sort: Desc)], map: "idx_message_sent_at")
  @@index([expiresAt], map: "idx_message_expires")
  @@index([conversationId, status], map: "idx_message_status")
  @@map("messages")
}

model Notification {
  id        String           @id @default(uuid())
  ownerId   String           @map("owner_id")
  type      NotificationType
  title     String           @db.VarChar(100)
  message   String
  data      Json?
  isRead    Boolean          @default(false) @map("is_read")
  createdAt DateTime         @default(now()) @map("created_at")
  owner     Owner            @relation(fields: [ownerId], references: [id])

  @@index([ownerId], map: "idx_notification_owner")
  @@index([ownerId, isRead], map: "idx_notification_unread")
  @@index([createdAt(sort: Desc)], map: "idx_notification_created")
  @@map("notifications")
}
```

---

## Database Migrations

### Migration 001: Enable PostGIS
```sql
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
```

### Migration 002: Create Tables
```sql
-- Create enum types
CREATE TYPE admin_role AS ENUM ('super_admin', 'admin');
CREATE TYPE verification_status AS ENUM ('unverified', 'pending', 'verified', 'rejected');
CREATE TYPE request_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE viewer_type AS ENUM ('consumer', 'anonymous');

-- Tables created via Prisma migrations
```

### Migration 003: Add Spatial Index
```sql
-- Create spatial index on plant location
CREATE INDEX idx_plant_location ON plants USING GIST (location);
```

---

## Data Validation Rules

### Phone Number (India)
```typescript
const INDIA_PHONE_REGEX = /^\+91[6-9]\d{9}$/;
// Valid: +919876543210
// Invalid: 9876543210, +911234567890
```

### TDS Reading
```typescript
const TDS_MIN = 0;
const TDS_MAX = 9999; // ppm
// Typical drinking water: 50-300 ppm
// Hard water: 300-500 ppm
```

### Price per Liter
```typescript
const PRICE_MIN = 0.01; // INR
const PRICE_MAX = 100.00; // INR
// Typical range: 0.50 - 5.00 INR
```

### Photo URLs
```typescript
const MAX_PHOTOS = 5;
const MAX_URL_LENGTH = 500;
const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp'];
```

---

## Caching Strategy

| Entity | Cache Key Pattern | TTL | Invalidation |
|--------|-------------------|-----|--------------|
| Plant List (by location) | `plants:lat:{lat}:lng:{lng}:radius:{r}` | 60s | On any plant update in area |
| Plant Details | `plant:{id}` | 300s | On plant update |
| Owner Profile | `owner:{id}` | 300s | On owner update |
| Verification Counts | `verification:counts` | 60s | On any verification action |

---

## Audit Trail

All mutations to critical entities are logged:

```typescript
interface AuditLog {
  id: string;
  entityType: 'plant' | 'owner' | 'verification';
  entityId: string;
  action: 'create' | 'update' | 'delete';
  actorType: 'owner' | 'admin' | 'system';
  actorId: string;
  changes: Record<string, { old: any; new: any }>;
  timestamp: Date;
}
```

Stored in a separate `audit_logs` table for compliance requirements.
