<!--
================================================================================
SYNC IMPACT REPORT
================================================================================
Version Change: 0.0.0 → 1.0.0 (MAJOR - initial constitution ratification)

Modified Principles: N/A (initial creation)

Added Sections:
  - Core Principles (7 principles)
  - Security & Compliance
  - Development Workflow
  - Governance

Removed Sections: N/A (initial creation)

Templates Requiring Updates:
  - .specify/templates/plan-template.md: ✅ Compatible (Constitution Check section exists)
  - .specify/templates/spec-template.md: ✅ Compatible (Requirements/Success Criteria align)
  - .specify/templates/tasks-template.md: ✅ Compatible (Phase structure supports principles)
  - .specify/templates/checklist-template.md: ✅ Compatible (Can reference security/quality gates)

Follow-up TODOs: None
================================================================================
-->

# FlowGrid Constitution

## Core Principles

### I. API-First Architecture

All system functionality MUST be exposed through well-defined APIs before any UI implementation.

- Every feature MUST have a documented API contract (OpenAPI/Swagger) before implementation begins
- Internal services MUST communicate exclusively via APIs (REST or gRPC), never direct database access across service boundaries
- APIs MUST be versioned using semantic versioning (v1, v2) in the URL path
- All API responses MUST follow consistent envelope structure: `{ data, error, meta }`
- APIs MUST be designed for external consumption even if initially internal-only
- Hardware device communication MUST use standardized API protocols (MQTT for IoT, REST for management)

**Rationale**: FlowGrid's ecosystem spans consumer apps, business apps, and hardware devices. API-first ensures any component can integrate seamlessly, enables third-party partnerships, and allows independent scaling of services.

### II. DRY (Don't Repeat Yourself)

Code duplication MUST be eliminated through proper abstraction and shared libraries.

- Common functionality MUST be extracted into shared packages/modules after second occurrence
- Database models, validation schemas, and error types MUST be defined once and imported
- Configuration values MUST be centralized (environment variables, config service)
- API client code MUST be auto-generated from OpenAPI specs, never hand-written
- Shared UI components MUST live in a common component library
- Business logic MUST NOT be duplicated between backend and frontend; frontend calls backend APIs

**Rationale**: With B2B apps, B2C apps, and hardware firmware sharing business logic, duplication creates inconsistency bugs and maintenance burden that a small team cannot sustain.

### III. Security by Design

Security MUST be embedded in every layer, not added as an afterthought.

- All external inputs MUST be validated and sanitized at API boundaries
- Authentication MUST use industry-standard protocols (OAuth 2.0, JWT with short expiry)
- Authorization MUST be enforced at the API layer using role-based access control (RBAC)
- All data in transit MUST use TLS 1.2+ encryption; no HTTP allowed in production
- Sensitive data at rest (credentials, payment tokens) MUST be encrypted using AES-256
- Secrets MUST NEVER be committed to version control; use secret management (env vars, Vault, cloud KMS)
- Payment integrations MUST use PCI-DSS compliant providers (Razorpay, Cashfree); never store card data
- Hardware firmware MUST validate all commands from cloud; implement command signing
- SQL queries MUST use parameterized statements; no string concatenation
- Dependencies MUST be audited for vulnerabilities before adoption and regularly scanned

**Rationale**: FlowGrid handles financial transactions and controls physical hardware. Security breaches could cause financial loss, safety hazards, or regulatory penalties.

### IV. Test-Driven Quality

Critical paths MUST have automated tests; testing strategy MUST match risk level.

- Payment flows MUST have integration tests covering success, failure, and edge cases
- API contracts MUST have contract tests validating request/response schemas
- Hardware communication protocols MUST have integration tests with mock devices
- Database migrations MUST be tested in CI before deployment
- Unit tests SHOULD cover business logic with >80% coverage for core services
- End-to-end tests MUST cover critical user journeys (registration, payment, dispensing)
- Tests MUST run in CI pipeline; failing tests MUST block merges to main branch
- Test data MUST be isolated; tests MUST NOT depend on production data

**Rationale**: With hardware in the field and financial transactions, bugs have real-world consequences. Automated testing catches regressions before they reach production.

### V. Observability & Monitoring

All production systems MUST be observable and alert on anomalies.

- All services MUST emit structured logs (JSON format) with correlation IDs for request tracing
- Application metrics (latency, error rates, throughput) MUST be collected and dashboarded
- Hardware devices MUST report health metrics (connectivity, sensor readings, error counts)
- Alerts MUST be configured for: payment failures >1%, hardware offline >5min, API error rate >5%
- Database query performance MUST be monitored; slow queries >500ms MUST trigger alerts
- All errors MUST be captured with stack traces and context in error tracking system (Sentry, etc.)
- Audit logs MUST record all financial transactions and administrative actions

**Rationale**: FlowGrid operates distributed hardware across cities. Without observability, diagnosing issues at remote locations becomes impossible.

### VI. Scalability & Performance

Architecture MUST support horizontal scaling without code changes.

- Services MUST be stateless; session state MUST be externalized (Redis, database)
- Database access MUST use connection pooling; queries MUST be optimized with proper indexes
- APIs MUST implement pagination for list endpoints (default 20, max 100 items)
- Heavy operations (reports, bulk updates) MUST be processed asynchronously via job queues
- Static assets MUST be served via CDN
- Database MUST support read replicas for scaling read-heavy operations
- Caching MUST be implemented for frequently accessed, slowly changing data (plant profiles, configs)
- API rate limiting MUST be enforced to prevent abuse (100 req/min for authenticated users)

**Rationale**: FlowGrid targets 50,000+ plants and millions of transactions. Architecture must scale without rewrites.

### VII. Reproducibility & Environment Parity

Development, staging, and production MUST be reproducible and consistent.

- All infrastructure MUST be defined as code (Terraform, Docker Compose, Kubernetes manifests)
- Dependencies MUST be pinned to exact versions (package-lock.json, requirements.txt with ==)
- Environment configuration MUST be externalized; code MUST NOT contain environment-specific values
- Database schema changes MUST use versioned migrations; no manual DDL in production
- Deployments MUST be automated via CI/CD pipeline; no manual server changes
- Local development MUST use containerized dependencies (Docker) matching production versions
- Seed data and test fixtures MUST be version controlled for reproducible testing

**Rationale**: A bootstrapped team cannot afford "works on my machine" bugs or inconsistent environments causing production issues.

## Security & Compliance

### Authentication & Authorization

| Context | Requirement |
|---------|-------------|
| Consumer App | Phone OTP + optional email; JWT tokens with 24h expiry, refresh tokens with 30d expiry |
| Business App | Phone OTP + password; JWT tokens with 8h expiry; session invalidation on password change |
| Hardware Devices | API key + device certificate; mutual TLS for sensitive commands |
| Admin Panel | Email + password + MFA required; IP allowlisting for production access |
| Inter-service | Service-to-service authentication via signed JWTs or API keys |

### Data Protection

- PII (phone numbers, addresses) MUST be encrypted at rest
- Payment transaction logs MUST be retained for 7 years per RBI guidelines
- User data export and deletion MUST be supported for privacy compliance
- Database backups MUST be encrypted and tested monthly

### Compliance Checklist

- [ ] FSSAI compliance for water quality claims
- [ ] RBI/PCI compliance for payment handling
- [ ] GST integration for invoicing
- [ ] Data localization (India servers for Indian user data)

## Development Workflow

### SDLC Methodology

FlowGrid follows a modified Agile workflow optimized for a small team:

```
1. SPECIFY   → Define feature in spec.md (user stories, requirements)
2. PLAN      → Technical design in plan.md (architecture, data model, APIs)
3. TASK      → Break into tasks.md (implementation checklist)
4. IMPLEMENT → Code with tests, PR review required
5. VALIDATE  → QA in staging, stakeholder demo
6. DEPLOY    → Automated deployment to production
7. MONITOR   → Verify metrics, address alerts
```

### Code Review Requirements

- All code MUST be reviewed by at least one other team member before merge
- Reviews MUST check: security implications, test coverage, API contract compliance
- Self-merges are allowed ONLY for: documentation typos, config changes in non-prod, hotfixes (with post-review)

### Branch Strategy

- `main` - Production-ready code; protected, requires PR
- `staging` - Pre-production testing
- `feature/*` - Feature development branches
- `hotfix/*` - Emergency production fixes

### Release Process

- Features merge to `staging` for testing
- Staging deployed automatically on merge
- Production deploys require manual approval after staging validation
- Rollback procedure MUST be documented and tested for every release

## Governance

### Constitution Authority

This constitution supersedes all other development practices. When conflicts arise between convenience and constitution principles, the constitution wins.

### Amendment Process

1. Propose amendment via PR to constitution.md
2. Document rationale and impact assessment
3. All co-founders must approve changes to Core Principles
4. Technical amendments (Security, Workflow) require CTO approval
5. Update version number per semantic versioning:
   - MAJOR: Principle removal or fundamental redefinition
   - MINOR: New principle or significant expansion
   - PATCH: Clarification or typo fix

### Compliance Verification

- Every PR description MUST reference which principles apply
- Code reviews MUST verify principle compliance
- Monthly architecture review MUST assess overall compliance
- Violations MUST be documented in tech debt backlog with remediation plan

### Exception Process

Temporary exceptions to principles require:
1. Written justification documenting why the principle cannot be followed
2. CTO approval
3. Defined timeline for remediation (max 30 days)
4. Tracking in tech debt backlog

**Version**: 1.0.0 | **Ratified**: 2026-01-17 | **Last Amended**: 2026-01-17
