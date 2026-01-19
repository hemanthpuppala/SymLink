# Feature Specification: V1 Water Plant Discovery Platform

**Feature Branch**: `001-water-plant-discovery`
**Created**: 2026-01-17
**Status**: Draft
**Input**: V1 from VISION.md - B2B owner app + B2C consumer app for water plant listing and discovery

## Clarifications

### Session 2026-01-17

- Q: Where should consumers be able to initiate a message to plant owners? → A: From tooltip directly AND dedicated Chats tab for conversation history (Instagram-style)
- Q: For E2E encryption key management, how should encryption keys be handled? → A: Server-managed keys (simpler for V1, server can decrypt)
- Q: For local file storage (photos, documents), where should files be stored? → A: MinIO (local S3-compatible container) - no cloud dependencies
- Q: What transport should power real-time chat message delivery? → A: WebSocket (industry standard used by WhatsApp/Instagram)
- Q: Should there be a limit on chat message history retention? → A: User-configurable retention (Snapchat-style) - if one party sets retention, applies to both

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consumer Discovers Nearby Water Plants (Priority: P1)

A consumer opens the FlowGrid app wanting to find quality water plants nearby. They see a map centered on their current location with markers showing water plants. They can tap any marker to see a quick tooltip with the plant's name, TDS reading, price per liter, and open/closed status. They can get directions to the plant or message the owner directly.

**Why this priority**: This is the core consumer value proposition. Without plant discovery, there's no reason for consumers to use the app. This drives app downloads and validates the marketplace model.

**Independent Test**: Can be fully tested by opening the app with location permission, viewing the map, and tapping on plant markers. Delivers immediate value of finding nearby water plants with quality information.

**Acceptance Scenarios**:

1. **Given** a consumer opens the app for the first time, **When** they grant location permission, **Then** they see a map centered on their current location with water plant markers within 5km radius
2. **Given** a consumer is viewing the map, **When** they tap on a plant marker, **Then** they see a tooltip showing: plant name, TDS value (or "Not available"), price per liter, open/closed status, with "Directions" and "Message" action buttons
3. **Given** a consumer is viewing a plant tooltip, **When** they tap "Directions", **Then** the device's default maps app opens with navigation to the plant
4. **Given** a consumer denies location permission, **When** they open the app, **Then** they see a prompt to enter their area/pincode manually or enable location
5. **Given** there are no plants within 5km, **When** the consumer views the map, **Then** they see a message "No water plants found nearby" with option to expand search radius

---

### User Story 2 - Plant Owner Registers and Creates Profile (Priority: P1)

A water plant owner wants to list their business on FlowGrid to get more customers. They download the owner app, register with basic details, upload photos of their plant, enter their TDS reading, set pricing, and upload business documents for verification.

**Why this priority**: Without plant owners onboarding, there's no supply for the marketplace. This is equally critical as consumer discovery - both sides of the marketplace must work for V1.

**Independent Test**: Can be fully tested by completing the registration flow, uploading documents, and seeing the profile saved. Delivers value by giving the owner a digital presence.

**Acceptance Scenarios**:

1. **Given** a plant owner opens the owner app, **When** they tap "Register", **Then** they see a registration form asking for: owner name, phone number, plant name, address, operating hours
2. **Given** an owner is registering, **When** they enter all required fields and submit, **Then** their basic profile is created and they're logged in
3. **Given** an owner has registered, **When** they access their dashboard, **Then** they can add: plant photos (up to 5), TDS reading, price per liter, description
4. **Given** an owner wants verification, **When** they go to "Get Verified" section, **Then** they can upload: government ID (Aadhaar/PAN), business registration certificate, FSSAI license (if applicable)
5. **Given** an owner has submitted documents, **When** the documents are uploaded, **Then** they see status "Pending Verification" and receive confirmation

---

### User Story 3 - Admin Verifies Plant Owner Documents (Priority: P2)

A FlowGrid admin reviews submitted documents from plant owners to verify their legitimacy. They access a web dashboard showing pending verifications, review documents, and approve or reject with comments.

**Why this priority**: Verification builds trust in the platform. While plants can be listed without verification, the "Verified" badge differentiates quality plants and protects consumers.

**Independent Test**: Can be fully tested by logging into admin dashboard, viewing pending applications, and approving/rejecting them. Delivers value by enabling the trust layer.

**Acceptance Scenarios**:

1. **Given** an admin logs into the dashboard, **When** they navigate to "Pending Verifications", **Then** they see a list of plant owners who have submitted documents
2. **Given** an admin is reviewing a verification request, **When** they click on a request, **Then** they see: owner details, uploaded documents (viewable/downloadable), plant information
3. **Given** an admin has reviewed documents, **When** they click "Approve", **Then** the plant gets "Verified" badge and owner receives notification
4. **Given** an admin finds issues with documents, **When** they click "Reject" and enter reason, **Then** the owner receives notification with rejection reason and can resubmit
5. **Given** an admin wants to track progress, **When** they view the dashboard, **Then** they see counts of: pending, approved, rejected verifications

---

### User Story 4 - Consumer Views Plant Details (Priority: P2)

A consumer wants more information about a specific water plant before visiting. They tap on a plant from the map or list to see the full profile including photos, operating hours, contact information, and whether it's verified.

**Why this priority**: Detailed information helps consumers make informed decisions and builds trust in the platform. It's the bridge between discovery (P1) and physical visit.

**Independent Test**: Can be fully tested by navigating to any plant's detail page and viewing all information. Delivers value by providing decision-making information.

**Acceptance Scenarios**:

1. **Given** a consumer taps on a plant marker or list item, **When** the detail page loads, **Then** they see: plant name, photos (carousel), address, operating hours, TDS reading, price per liter
2. **Given** a consumer is viewing plant details, **When** the plant is verified, **Then** they see a "Verified" badge prominently displayed
3. **Given** a consumer wants to contact the plant, **When** they tap the phone number, **Then** their phone's dialer opens with the number
4. **Given** a consumer views an unverified plant, **When** they see the profile, **Then** they see "Not yet verified" indicator (not blocking, just informational)

---

### User Story 5 - Plant Owner Updates Information (Priority: P2)

A plant owner needs to update their TDS reading, change operating hours, or update pricing. They access their dashboard and make changes that reflect immediately in the consumer app.

**Why this priority**: Stale data destroys trust. Owners must be able to keep their information current for the platform to remain useful.

**Independent Test**: Can be fully tested by changing any field in owner dashboard and verifying it appears in consumer app. Delivers value by maintaining data accuracy.

**Acceptance Scenarios**:

1. **Given** an owner is logged into their dashboard, **When** they tap "Edit Profile", **Then** they can modify: TDS reading, price, operating hours, photos, description
2. **Given** an owner updates their TDS reading, **When** they save changes, **Then** the new TDS value appears immediately in the consumer app
3. **Given** an owner wants to mark plant as temporarily closed, **When** they toggle "Currently Open" to off, **Then** the consumer app shows "Closed" status for that plant

---

### User Story 6 - Consumer Searches and Filters Plants (Priority: P3)

A consumer wants to find plants based on specific criteria - lowest TDS, nearest distance, or currently open. They use filters to narrow down options.

**Why this priority**: Improves user experience but not essential for MVP. Basic map view (P1) provides core value; filtering is enhancement.

**Independent Test**: Can be fully tested by applying various filters and verifying results match criteria. Delivers value by helping users find exactly what they need.

**Acceptance Scenarios**:

1. **Given** a consumer is viewing the map, **When** they tap "Filter", **Then** they see options: Sort by (Distance, TDS - Low to High, Price), Filter by (Open Now, Verified Only)
2. **Given** a consumer applies "Open Now" filter, **When** results update, **Then** only plants marked as currently open are shown
3. **Given** a consumer sorts by "TDS - Low to High", **When** viewing list view, **Then** plants are ordered by TDS reading ascending

---

### User Story 7 - Owner Views Basic Analytics (Priority: P3)

A plant owner wants to know how many people are finding their plant through the app. They view simple metrics on their dashboard.

**Why this priority**: Demonstrates value to owners and encourages engagement, but not essential for initial launch.

**Independent Test**: Can be fully tested by viewing analytics section showing profile views count. Delivers value by proving ROI to owners.

**Acceptance Scenarios**:

1. **Given** an owner is logged into their dashboard, **When** they view "Analytics" section, **Then** they see: total profile views (all time), profile views this week
2. **Given** a consumer views a plant's detail page, **When** they view it, **Then** the view count for that plant increments

---

### User Story 8 - Owner Gets Shareable Profile Link (Priority: P3)

A plant owner wants to share their FlowGrid profile on WhatsApp, Facebook, or print it as a QR code to display at their shop.

**Why this priority**: Drives organic growth through owner promotion, but app works without it.

**Independent Test**: Can be fully tested by copying shareable link and opening it in browser. Delivers value by enabling owner-driven marketing.

**Acceptance Scenarios**:

1. **Given** an owner is on their dashboard, **When** they tap "Share Profile", **Then** they see a shareable link and options to copy or share via WhatsApp/social
2. **Given** someone clicks on a shared plant link, **When** they open it, **Then** they see the plant's public profile page (works even without app installed)

---

### User Story 9 - Consumer Messages Plant Owner (Priority: P2)

A consumer wants to ask a question about a water plant before visiting - perhaps about current water availability, bulk pricing, or specific timing. They tap the "Message" button from the plant tooltip or detail page, type their question, and the owner receives it in real-time. The conversation continues like Instagram DMs.

**Why this priority**: Direct communication builds trust and answers questions that static info cannot. Reduces friction between discovery and visit. Essential for complex queries.

**Independent Test**: Can be fully tested by sending a message from consumer app and verifying owner receives it in real-time. Both parties can view conversation history.

**Acceptance Scenarios**:

1. **Given** a consumer is viewing a plant tooltip, **When** they tap "Message", **Then** they see a chat interface to compose and send a message to that plant's owner
2. **Given** a consumer sends a message, **When** the message is sent, **Then** the owner receives a real-time notification and can view the message immediately
3. **Given** an owner receives a message, **When** they reply, **Then** the consumer receives the reply in real-time
4. **Given** a consumer has previous conversations, **When** they open the "Chats" tab, **Then** they see a list of all their conversations with plant owners, sorted by most recent
5. **Given** an owner has previous conversations, **When** they open the "Chats" tab in owner app, **Then** they see a list of all conversations with consumers, sorted by most recent
6. **Given** a user sets message retention (e.g., 24 hours), **When** messages exceed that age, **Then** they are deleted for both parties in that conversation
7. **Given** a user is offline when a message arrives, **When** they come online, **Then** they see the message with delivery timestamp

---

### Edge Cases

- What happens when a plant owner's documents expire after initial verification?
  - *Assumption*: V1 does not track document expiry. Manual re-verification process for V1.5.
- How does the system handle plants with no TDS reading entered?
  - Display "TDS: Not available" on tooltip and detail page. Do not exclude from results.
- What happens if owner enters unrealistic TDS value (e.g., 9999)?
  - Accept any numeric value in V1. Validation/flagging for V1.5.
- How does the app behave with poor network connectivity?
  - Show cached data if available. Display "Unable to load" with retry option if no cache.
- What if multiple plants have the exact same location?
  - Show clustered marker that expands on tap to show individual plants.
- What if owner uploads invalid file type for documents?
  - Accept only images (JPG, PNG) and PDFs. Show error message for other file types.
- What if location services are completely unavailable?
  - Allow manual city/area selection from a dropdown list.
- What happens if a message is sent while the recipient is offline?
  - Message is stored on server and delivered when recipient comes online. Show "Delivered" status when received.
- What if a consumer messages a plant whose owner has deleted their account?
  - Show "This plant is no longer available" and prevent new messages. Existing conversation history remains visible.
- How are message notifications displayed when app is in background?
  - V1 uses in-app notifications only (visible when app is open). Background push notifications deferred to V1.5.
- What happens if both parties set different retention periods?
  - The shorter retention period applies. Messages are deleted for both when shorter period expires.
- Can users delete individual messages?
  - Yes, but only from their own view. Message remains visible to other party unless retention auto-deletes it.

## Requirements *(mandatory)*

### Functional Requirements

**Consumer App (B2C)**

- **FR-001**: System MUST display a map showing water plant locations within configurable radius (default 5km)
- **FR-002**: System MUST show plant markers with visual differentiation for verified vs unverified plants
- **FR-003**: System MUST display tooltip on marker tap showing: plant name, TDS, price/liter, open/closed status
- **FR-004**: System MUST provide plant detail page with: photos, address, hours, TDS, price, contact, verification status
- **FR-005**: System MUST integrate with device maps for navigation to selected plant
- **FR-006**: System MUST request and use device location with user permission
- **FR-007**: System MUST allow manual location entry (area/pincode) if location permission denied
- **FR-008**: System MUST provide list view as alternative to map view
- **FR-009**: System MUST support filtering by: currently open, verified only
- **FR-010**: System MUST support sorting by: distance, TDS (ascending), price
- **FR-011**: System MUST cache recently viewed data for offline access
- **FR-045**: System MUST provide "Message" button in plant tooltip and detail page to initiate conversation with owner
- **FR-046**: System MUST provide dedicated "Chats" tab showing all conversations with plant owners, sorted by most recent activity
- **FR-047**: System MUST display real-time message delivery with WebSocket connection
- **FR-048**: System MUST show message status indicators (sent, delivered, read)
- **FR-049**: System MUST allow consumers to configure message retention period (options: off, 24h, 7d, 30d)
- **FR-050**: System MUST display in-app notification when new message arrives

**Owner App (B2B)**

- **FR-012**: System MUST allow owner registration with: name, phone, plant name, address (with map pin), operating hours
- **FR-013**: System MUST allow owners to upload up to 5 photos of their plant (max 5MB each)
- **FR-014**: System MUST allow owners to enter and update: TDS reading (numeric), price per liter (INR), description (text)
- **FR-015**: System MUST allow owners to upload verification documents: government ID, business registration, FSSAI license
- **FR-016**: System MUST show document verification status: not submitted, pending, approved, rejected (with reason)
- **FR-017**: System MUST allow owners to toggle "Currently Open" status
- **FR-018**: System MUST display basic analytics: total profile views, weekly profile views
- **FR-019**: System MUST allow owners to update their profile information at any time
- **FR-020**: System MUST generate a shareable link and QR code for each plant profile
- **FR-021**: System MUST send notification to owner when verification status changes
- **FR-051**: System MUST provide dedicated "Chats" tab showing all conversations with consumers, sorted by most recent activity
- **FR-052**: System MUST display real-time incoming messages with WebSocket connection
- **FR-053**: System MUST show message status indicators (sent, delivered, read)
- **FR-054**: System MUST allow owners to configure message retention period (options: off, 24h, 7d, 30d)
- **FR-055**: System MUST display in-app notification badge when new messages arrive
- **FR-056**: System MUST allow owners to reply to consumer messages with text

**Admin Dashboard (Internal Web Application)**

- **FR-022**: System MUST provide web-based admin dashboard accessible via browser
- **FR-023**: System MUST require admin authentication (username: admin, password: admin for V1)
- **FR-024**: System MUST display list of pending verification requests with submission date, sortable by date
- **FR-025**: System MUST allow admins to view uploaded documents inline (images) or download (PDFs)
- **FR-026**: System MUST allow admins to approve verification with one click
- **FR-027**: System MUST allow admins to reject verification with mandatory reason text
- **FR-028**: System MUST display dashboard summary: total plants, verified count, pending count, rejected count
- **FR-029**: System MUST display all plants list with search by name and filter by verification status
- **FR-030**: System MUST allow admins to view any plant's full details and owner information

**Backend/API**

- **FR-031**: System MUST expose RESTful APIs for all consumer app functionality
- **FR-032**: System MUST expose RESTful APIs for all owner app functionality
- **FR-033**: System MUST expose RESTful APIs for admin dashboard functionality
- **FR-034**: System MUST store uploaded images and documents securely with access control
- **FR-035**: System MUST track and persist profile view counts per plant
- **FR-036**: System MUST support real-time data sync (owner updates reflect in consumer app within 5 seconds)
- **FR-037**: System MUST implement geospatial queries for "plants near location" functionality
- **FR-038**: System MUST log all admin actions for audit trail
- **FR-057**: System MUST provide WebSocket endpoint for real-time message delivery
- **FR-058**: System MUST store messages with server-managed encryption keys
- **FR-059**: System MUST enforce message retention policies and auto-delete expired messages
- **FR-060**: System MUST deliver queued messages when offline users come online
- **FR-061**: System MUST track message status (sent, delivered, read) and sync across devices
- **FR-062**: System MUST store all files (photos, documents) in MinIO (local S3-compatible storage) - no cloud dependencies

**Authentication & Security**

- **FR-039**: Consumer app MUST use simple username/password authentication for V1 (admin/admin placeholder)
- **FR-040**: Owner app MUST use phone number + password authentication with password reset capability
- **FR-041**: Admin dashboard MUST use username/password authentication (admin/admin for V1)
- **FR-042**: All APIs MUST require authentication except public plant listing endpoints
- **FR-043**: Document uploads MUST be accessible only to the owner who uploaded them and admins
- **FR-044**: Passwords MUST be stored securely (hashed, never in plain text)

### Key Entities

- **Plant**: Represents a water plant business
  - Attributes: name, address, coordinates (lat/lng), operating hours (text), TDS reading (integer ppm), price per liter (decimal INR), photos (array of URLs), description, verification status (unverified/pending/verified/rejected), is_open (boolean), view_count, created_at, updated_at
  - Relationships: belongs to one Owner

- **Owner**: Represents a plant owner/operator
  - Attributes: name, phone (unique), password_hash, email (optional), created_at
  - Relationships: has one or more Plants, has VerificationRequests

- **Consumer**: Represents an app user looking for water plants
  - Attributes: username (unique), password_hash, created_at, last_login
  - Relationships: none in V1 (favorites, reviews in V1.5)

- **VerificationRequest**: Represents a document verification submission
  - Attributes: government_id_url, business_registration_url, fssai_license_url (optional), status (pending/approved/rejected), rejection_reason, submitted_at, decided_at, decided_by (admin reference)
  - Relationships: belongs to one Owner, processed by one Admin

- **Admin**: Represents internal FlowGrid staff
  - Attributes: username (unique), password_hash, role (super_admin/admin), created_at
  - Relationships: processes VerificationRequests

- **ViewLog**: Tracks plant profile views (for analytics)
  - Attributes: plant_id, viewer_type (consumer/anonymous), viewed_at
  - Relationships: belongs to one Plant

- **Conversation**: Represents a chat thread between Consumer and Owner
  - Attributes: id, consumer_id, owner_id, plant_id, last_message_at, consumer_retention_setting (enum: off/24h/7d/30d), owner_retention_setting (enum: off/24h/7d/30d), created_at
  - Relationships: belongs to one Consumer, one Owner, one Plant; has many Messages
  - Constraints: Unique on (consumer_id, plant_id) - one conversation per consumer-plant pair

- **Message**: Represents a single chat message
  - Attributes: id, conversation_id, sender_type (consumer/owner), sender_id, content_encrypted (text), status (sent/delivered/read), sent_at, delivered_at, read_at, deleted_by_consumer (boolean), deleted_by_owner (boolean), expires_at (nullable timestamp)
  - Relationships: belongs to one Conversation
  - Encryption: Content encrypted with server-managed AES-256 key
  - Retention: expires_at calculated from shorter of consumer/owner retention settings

### Assumptions

- V1 targets a single city for initial launch; multi-city support structure present but not required for launch
- All prices are in Indian Rupees (INR) with 2 decimal places
- TDS is measured in ppm (parts per million) and entered as integer value
- Operating hours are stored as simple text (e.g., "8 AM - 8 PM, Mon-Sat") not structured time ranges
- Document verification is manual with no OCR; future V1.5 will add OCR capability
- Push notifications use basic in-app notification; advanced push (FCM/APNs) in V1.5
- Consumer registration is required for V1 (admin/admin); anonymous browsing considered for V1.5
- App language is English only for V1; Hindi support in V1.5 based on user feedback
- Photo uploads are compressed client-side before upload to reduce bandwidth
- Map provider is configurable (Google Maps or OpenStreetMap for cost consideration)
- **V1 is fully local** - no cloud service dependencies; all storage uses MinIO (S3-compatible) running locally in Docker
- Real-time messaging uses WebSocket (industry standard like WhatsApp/Instagram)
- Message encryption uses server-managed AES-256 keys (server can decrypt); true E2E encryption deferred to V1.5
- Both apps (consumer + owner) run on same local network during development; production will use standard HTTPS
- Message retention is user-configurable (off/24h/7d/30d); shorter setting between two parties applies to both

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Plant owners can complete registration and profile setup in under 5 minutes
- **SC-002**: Consumers can find and view details of a nearby plant in under 30 seconds after opening app
- **SC-003**: 100 water plants onboarded within first month of launch in target city
- **SC-004**: 1,000 consumer app downloads within first month
- **SC-005**: 200 weekly active users by end of month 2
- **SC-006**: Average app rating of 4.0+ stars on app stores
- **SC-007**: 80% of registered plant owners update their TDS reading at least once per week
- **SC-008**: Admin can process a verification request in under 2 minutes
- **SC-009**: 50% of onboarded plants submit verification documents within first week
- **SC-010**: System handles 500 concurrent users without performance degradation
- **SC-011**: Map loads and displays plant markers within 3 seconds on 4G mobile connection
- **SC-012**: 60% of consumers who open plant details tap "Directions", "Call", or "Message" (engagement metric)
- **SC-013**: Messages are delivered in real-time (<500ms latency on local network)
- **SC-014**: 30% of consumers who view a plant initiate a message conversation
- **SC-015**: Owners respond to consumer messages within 30 minutes (average)
