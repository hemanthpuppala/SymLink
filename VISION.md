# FlowGrid Ecosystem Vision Document

> **Working Title:** FlowGrid (or your chosen name)
> **Tagline:** "Scan. Pay. Flow." — Unified infrastructure for everyday utilities
> **Document Version:** 1.0
> **Date:** January 2026

---

## Executive Summary

FlowGrid is building the **infrastructure layer for self-service utility dispensing** across India. Starting with water, we're creating a unified platform where consumers can discover, pay, and access essential utilities (water, fuel, EV charging) through a single app, while businesses operate automated, unmanned dispensing points with full remote visibility.

**The thesis:** Every utility that flows (water, fuel, electricity, milk) will become self-service. We're building the hardware + software stack to make that transition seamless for businesses and delightful for consumers.

---

## Table of Contents

1. [The Problem](#1-the-problem)
2. [The Solution](#2-the-solution)
3. [Ecosystem Overview](#3-ecosystem-overview)
4. [Product Roadmap (V1-V8)](#4-product-roadmap-v1-v8)
5. [Business Model & Revenue](#5-business-model--revenue)
6. [Unit Economics](#6-unit-economics)
7. [Competitive Moat](#7-competitive-moat)
8. [Go-To-Market Strategy](#8-go-to-market-strategy)
9. [Scaling Playbook](#9-scaling-playbook)
10. [Financial Projections](#10-financial-projections)
11. [Risk Analysis](#11-risk-analysis)
12. [Team & Resources](#12-team--resources)
13. [Success Metrics](#13-success-metrics)
14. [Long-Term Vision](#14-long-term-vision)

---

## 1. The Problem

### For Consumers

| Pain Point | Current Reality |
|------------|-----------------|
| Discovery | Don't know where quality water/fuel is nearby |
| Transparency | No visibility into quality (TDS, fuel purity) |
| Waiting | Queues, slow manual service, limited hours |
| Payment friction | Cash dependency, no unified payment |
| Trust | Uncertain quality, no accountability |

### For Business Owners (Water Plants, Fuel Stations, etc.)

| Pain Point | Current Reality |
|------------|-----------------|
| Labor costs | ₹10,000-20,000/month for attendants |
| Limited hours | Can only operate when staff present |
| Theft/pilferage | No visibility when owner is away |
| Manual tracking | Paper records, no real-time data |
| Customer reach | Only walk-in customers, no online presence |

### Market Reality

- **Water:** 2 lakh+ water plants in India, mostly manual, no digital presence
- **Fuel:** 80,000+ petrol pumps, minimal self-service adoption
- **EV Charging:** Fragmented, multiple apps, poor reliability data
- **Common thread:** All these utilities lack unified discovery, quality transparency, and self-service infrastructure

---

## 2. The Solution

### FlowGrid Platform

A **two-sided platform** connecting utility consumers with utility providers, powered by **smart dispensing hardware** and a **unified consumer app**.

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLOWGRID ECOSYSTEM                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │   CONSUMER APP   │              │   BUSINESS APP   │         │
│  │                  │              │                  │         │
│  │ • Discover nearby│              │ • Remote monitor │         │
│  │ • See quality    │              │ • Control on/off │         │
│  │ • Scan & pay     │              │ • View revenue   │         │
│  │ • Earn points    │              │ • Get alerts     │         │
│  │ • Track history  │              │ • Analytics      │         │
│  └────────┬─────────┘              └────────┬─────────┘         │
│           │                                 │                   │
│           └──────────────┬──────────────────┘                   │
│                          ▼                                      │
│           ┌──────────────────────────────┐                      │
│           │      FLOWGRID HARDWARE       │                      │
│           │                              │                      │
│           │  • Quality sensors (TDS,etc) │                      │
│           │  • Flow meters               │                      │
│           │  • Smart valves              │                      │
│           │  • Payment terminals         │                      │
│           │  • Cellular connectivity     │                      │
│           └──────────────────────────────┘                      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    FLOWGRID POINTS                       │   │
│  │   Universal rewards earned on any utility, redeemable    │   │
│  │   across the ecosystem (water → fuel → EV → partners)    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Core Value Propositions

**For Consumers:**
- One app for water, fuel, EV charging, and more
- Transparent quality metrics before purchase
- Zero waiting — scan, pay, dispense
- Earn and redeem points across all utilities

**For Business Owners:**
- Eliminate labor costs (unmanned operation)
- 24/7 operation capability
- Real-time remote monitoring
- Increased customer reach via app discovery
- Professional online presence

---

## 3. Ecosystem Overview

### The Flywheel

```
                    ┌─────────────────────┐
                    │  More Businesses    │
                    │  Join Platform      │
                    └──────────┬──────────┘
                               │
                               ▼
┌─────────────────┐   ┌─────────────────────┐   ┌─────────────────┐
│ Businesses See  │   │  Better Consumer    │   │ More Consumers  │
│ ROI, Refer      │◀──│  Experience         │◀──│ Download App    │
│ Others          │   │  (More Options)     │   │                 │
└─────────────────┘   └─────────────────────┘   └────────┬────────┘
        │                                                │
        │                                                │
        └─────────────────────┬──────────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  Transaction Volume │
                    │  Increases          │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  Revenue Grows      │
                    │  Reinvest in Growth │
                    └─────────────────────┘
```

### Ecosystem Products (Current & Future)

| Category | Products | Status |
|----------|----------|--------|
| **Water** | Water plant discovery, Self-service kiosks, Delivery | V1-V3 |
| **Fuel** | Petrol pump discovery, Self-service dispensers | V6-V7 |
| **EV** | Charging station discovery, Smart chargers | V5-V6 |
| **Dairy** | Milk ATMs, Dairy product dispensers | V7+ |
| **Gas** | LPG cylinder booking & delivery | V8+ |
| **Retail** (Optional) | Partner integrations for point redemption | V4+ |

---

## 4. Product Roadmap (V1-V8)

### V1: Water Plant Discovery (Free Listing)
**Timeline:** Month 1-2
**Investment:** ₹50,000 (development + initial marketing)

**What:**
- Consumer app: Map-based water plant discovery
- Owner app: Free registration, profile, manual TDS entry
- Basic quality transparency (owner-entered data)

**Features:**
| Consumer App | Owner App |
|--------------|-----------|
| Map view of nearby plants | Registration & profile |
| Plant profiles with TDS | Operating hours |
| Distance & directions | Manual TDS entry |
| Open/closed status | Shareable link |
| Call button | View visitors count |

**Revenue:** ₹0 (Traction building phase)

**Success Metrics:**
- 100 plants onboarded (1 city)
- 1,000 app downloads
- 200 weekly active users

---

### V1.5: Engagement & Trust
**Timeline:** Month 2-3
**Investment:** ₹30,000

**What:**
- Verified badges for plants with documentation
- Consumer ratings & reviews
- Basic analytics for owners
- Push notifications

**Features Added:**
- "Quality Verified" badge (for license upload)
- Star ratings from consumers
- Review system
- Owner analytics dashboard
- Favorite plants for consumers

**Revenue:** ₹0 (Still building trust)

**Success Metrics:**
- 50% of plants have "Verified" badge
- Average 4+ rating across plants
- 500 weekly active users
- 30% week-over-week retention

---

### V2: Hardware Integration (Self-Service Kiosks)
**Timeline:** Month 3-6
**Investment:** ₹3,00,000 (hardware R&D + initial inventory)

**What:**
- Smart dispensing hardware for water plants
- Real-time quality monitoring (TDS sensors)
- Self-service payment & dispensing
- Remote monitoring dashboard for owners

**Hardware Components:**
| Component | Function | Est. Cost |
|-----------|----------|-----------|
| TDS Sensor | Real-time water quality | ₹800 |
| Water Level Sensor | Tank monitoring | ₹400 |
| Flow Meter | Accurate dispensing | ₹2,000 |
| Solenoid Valve | Flow control | ₹1,500 |
| Controller (ESP32) | Brain of the system | ₹600 |
| 4G Module | Connectivity | ₹1,200 |
| Display + QR | User interface | ₹1,500 |
| Enclosure + Wiring | Protection | ₹2,000 |
| **Total BOM** | | **₹10,000** |
| **Selling Price** | | **₹18,000-22,000** |

**Revenue Model:**
- Hardware sale: ₹18,000-22,000 per unit (80% margin on BOM)
- Transaction fee: 2-3% of each transaction
- Optional: ₹499/month premium dashboard

**Owner ROI Calculation:**
```
Current State:
- Attendant salary: ₹12,000/month
- Operating hours: 10 hours/day
- Monthly transactions: ₹60,000

With FlowGrid:
- Hardware cost: ₹20,000 (one-time)
- Transaction fee: ₹1,200/month (2%)
- Operating hours: 24/7
- Attendant: ₹0

Monthly savings: ₹12,000 - ₹1,200 = ₹10,800
Payback period: < 2 months
```

**Success Metrics:**
- 50 hardware units sold
- 95%+ uptime reliability
- ₹10,00,000 monthly transaction volume
- 3 repeat hardware orders

---

### V3: Delivery Integration
**Timeline:** Month 6-9
**Investment:** ₹2,00,000

**What:**
- Water can delivery through the app
- Real-time order tracking
- Delivery partner network
- Subscription options for regular delivery

**Features:**
- Schedule delivery (one-time or recurring)
- Choose cans (5L, 10L, 20L)
- Track delivery in real-time
- Rate delivery experience
- Subscription management

**Revenue Model:**
- Delivery fee: ₹10-20 per delivery (consumer pays)
- Commission: 5-8% from plant owner
- Subscription: ₹199/month unlimited free delivery

**Success Metrics:**
- 500 deliveries/month
- 20% of active users try delivery
- 15% convert to subscription
- Positive unit economics per delivery

---

### V4: Points & Rewards Ecosystem
**Timeline:** Month 9-12
**Investment:** ₹1,50,000

**What:**
- FlowGrid Points system across all transactions
- Partner integrations for redemption
- Gamification and engagement features

**How Points Work:**
```
EARNING:
- ₹100 spent on water = 10 points
- ₹100 spent on fuel = 10 points (future)
- Referral = 50 points
- Review = 5 points
- Daily check-in = 1 point

REDEMPTION:
- 100 points = ₹10 discount on any FlowGrid service
- Partner redemptions (future): Swiggy, Amazon, etc.
```

**Why This Matters:**
- Increases stickiness (points lock-in)
- Cross-sells between verticals (use water points for fuel)
- Data on consumer spending patterns
- Partnership revenue potential

**Revenue Model:**
- Points are a liability (~1% of transaction value)
- Offset by increased retention and frequency
- Partner integrations can be revenue-positive

**Success Metrics:**
- 50% of users have points balance
- 10% increase in transaction frequency
- Points redemption rate < 60% (breakage)

---

### V5: EV Charging Stations
**Timeline:** Month 12-18
**Investment:** ₹10,00,000

**What:**
- Discover EV charging stations
- Real-time availability and pricing
- Book and pay through app
- Smart charger hardware for station owners

**Market Opportunity:**
- India EV market growing 40%+ annually
- Fragmented charging infrastructure
- No dominant discovery + payment platform

**Hardware:**
| Component | Function | Est. Cost |
|-----------|----------|-----------|
| Charge Controller | Power management | ₹15,000 |
| Energy Meter | Billing accuracy | ₹3,000 |
| Connectivity Module | 4G/WiFi | ₹1,500 |
| Payment Terminal | UPI integration | ₹2,000 |
| Enclosure | Weatherproofing | ₹5,000 |
| **Total BOM** | | **₹26,500** |
| **Selling Price** | | **₹45,000-55,000** |

**Revenue Model:**
- Hardware sale: ₹45,000-55,000 per unit
- Transaction fee: 3-5% per charge
- Premium listing: ₹999/month

**Why It Fits:**
- Same infrastructure pattern (discover → pay → dispense)
- Shared consumer base (eco-conscious, app-savvy)
- Points interoperability (water points → EV discount)
- B2B sales motion similar to water plants

**Success Metrics:**
- 20 charging stations onboarded
- 200 charging sessions/month
- Average session value: ₹150

---

### V6: Petrol Pump Discovery
**Timeline:** Month 18-24
**Investment:** ₹5,00,000

**What:**
- Discover petrol pumps with fuel quality ratings
- Price comparison across stations
- Community-reported quality issues
- Partnership with pump owners

**Note:** Full self-service petrol dispensing requires regulatory approval. Initial version focuses on discovery and transparency.

**Features:**
- Map of nearby petrol pumps
- Price display (updated by community/owners)
- Quality ratings and reviews
- Report issues (adulteration, short-filling)
- Directions and wait time estimates

**Revenue Model:**
- Premium listing for pumps: ₹1,999/month
- Lead generation fee: ₹5 per customer directed
- Advertising: Promoted listings

**Success Metrics:**
- 500 pumps listed (1-2 cities)
- 5,000 monthly searches
- 50 premium subscribers

---

### V7: Self-Service Petrol Dispensers
**Timeline:** Month 24-36
**Investment:** ₹25,00,000

**What:**
- Smart retrofit hardware for petrol pumps
- Self-service payment integration
- Remote monitoring for pump owners
- Anti-adulteration sensors

**Regulatory Consideration:**
Self-service petrol is allowed in India but not common. Requires partnership with oil marketing companies (IOC, BPCL, HPCL) for approval.

**Hardware (Complex):**
- Flow meter (high precision): ₹25,000
- Payment terminal: ₹5,000
- Controller + connectivity: ₹10,000
- Safety sensors: ₹15,000
- Integration with existing pump: ₹20,000
- **Total per nozzle: ₹75,000**
- **Selling price: ₹1,20,000**

**Revenue Model:**
- Hardware sale: ₹1,20,000 per nozzle
- Transaction fee: 0.5-1% per transaction
- Data licensing to oil companies

**Success Metrics:**
- 10 pumps retrofitted
- Regulatory approval secured
- ₹1 Cr monthly transaction volume

---

### V8+: Expansion Verticals
**Timeline:** Month 36+

**Potential Additions:**

| Vertical | Description | Revenue Model |
|----------|-------------|---------------|
| **Milk ATMs** | Self-service milk dispensing | Hardware + 3% transaction |
| **LPG Booking** | Cylinder booking & delivery | Commission per booking |
| **Grocery Kiosks** | Automated grocery dispensing | Hardware + transaction fee |
| **Laundry Stations** | Self-service laundromats | Hardware + time-based fee |
| **Water Purifier Subscriptions** | Home RO monitoring & maintenance | ₹299/month subscription |

**Selection Criteria for New Verticals:**
1. Fits "discover → pay → dispense" pattern
2. B2B hardware sale + B2C app usage
3. Clear labor cost savings for businesses
4. Recurring transaction revenue
5. Data/quality transparency angle

---

## 5. Business Model & Revenue

### Revenue Streams by Phase

```
PHASE 1 (V1-V2): Foundation
├── Hardware sales: ₹20,000 per unit
├── Transaction fees: 2-3%
└── Total: Hardware + Transaction

PHASE 2 (V3-V4): Expansion
├── Hardware sales (multiple verticals)
├── Transaction fees: 2-5%
├── Delivery fees: ₹10-20 per order
├── Subscriptions: ₹199-499/month
└── Total: Diversified revenue

PHASE 3 (V5+): Platform
├── Hardware across verticals
├── Transaction fees at scale
├── Points/rewards ecosystem
├── Data licensing
├── Partner integrations
├── Advertising/promoted listings
└── Total: Platform economics
```

### Revenue Model Summary

| Stream | Description | Margin |
|--------|-------------|--------|
| **Hardware Sale** | One-time device sale to businesses | 60-80% gross |
| **Transaction Fee** | % of each consumer transaction | 100% (net revenue) |
| **Subscription** | Monthly premium features for owners | 90% gross |
| **Delivery Fee** | Per-delivery charge to consumers | 30-40% after rider cost |
| **Partner Commission** | Referral fees from partners | 100% |
| **Advertising** | Promoted listings, banner ads | 90% gross |

---

## 6. Unit Economics

### Water Plant Unit Economics (V2)

**Per Plant (Monthly):**
```
Assumptions:
- Average daily transactions: 80
- Average transaction value: ₹30
- Days operating: 30

Gross Transaction Value (GTV): ₹72,000/month

Revenue:
- Transaction fee (2.5%): ₹1,800/month

Cost:
- Server/connectivity (allocated): ₹100/month
- Support (allocated): ₹200/month
- Total cost: ₹300/month

Net Revenue per Plant: ₹1,500/month
```

**Hardware Sale Economics:**
```
BOM Cost: ₹10,000
Selling Price: ₹20,000
Gross Margin: ₹10,000 (50%)

Additional revenue over 24 months:
- Transaction fees: ₹1,500 × 24 = ₹36,000

Total Revenue per Plant (2 years): ₹10,000 + ₹36,000 = ₹46,000
```

**Customer Acquisition Cost (CAC):**
```
Sales effort: 2 hours per plant owner
Sales cost: ₹500/hour = ₹1,000
Marketing materials: ₹200

Total CAC: ₹1,200
LTV: ₹46,000 (over 2 years)
LTV:CAC Ratio: 38:1 ✓ (Excellent)
```

### Consumer Unit Economics

**Per Consumer (Monthly):**
```
Assumptions:
- Transactions per month: 4
- Average transaction value: ₹50
- GTV per user: ₹200/month

Revenue per user:
- Transaction fee (2.5%): ₹5/month
- Annual value: ₹60/year

CAC:
- Organic (owner promotion): ₹0
- Paid (if needed): ₹20-30

LTV:CAC: 2-3x minimum (acceptable for free tier)
```

---

## 7. Competitive Moat

### Moat Components

| Moat Type | How We Build It |
|-----------|-----------------|
| **Network Effects** | More plants → more consumers → more plants |
| **Data Moat** | Quality data across thousands of plants/stations |
| **Hardware Lock-in** | Our hardware = our platform (switching cost) |
| **Brand Trust** | "FlowGrid Verified" becomes quality standard |
| **Ecosystem Lock-in** | Points accumulation across verticals |

### Competitive Landscape

**Water:**
| Competitor | What They Do | Our Advantage |
|------------|--------------|---------------|
| Existing hardware vendors | Hardware only, no app | Full platform + consumer app |
| Water delivery apps | Delivery only | Discovery + self-service + delivery |
| Google Maps | Basic listings | Quality metrics, payment, specialized |

**EV Charging:**
| Competitor | What They Do | Our Advantage |
|------------|--------------|---------------|
| Tata Power EZ Charge | Own network only | Aggregator + any station |
| Statiq | Discovery focused | Hardware + discovery |
| Ather Grid | Ather bikes only | Universal |

**Why We Win:**
1. **Vertical integration:** Hardware + Software + Payments
2. **Cross-vertical synergy:** Water customer → EV customer → Fuel customer
3. **B2B + B2C:** Revenue from both sides
4. **Data advantage:** Quality metrics no one else has

---

## 8. Go-To-Market Strategy

### Phase 1: Water (City 1)

**Month 1-2: Seed Supply**
```
Target: 100 water plants in one city
Method: Direct sales (founders + 1 sales person)
Approach:
1. Map all water plants in target area
2. Door-to-door pitch: "Free listing, more customers"
3. Onboard 5-10 plants/day
4. Provide promotional materials
```

**Month 2-3: Drive Demand**
```
Target: 1,000 app downloads, 300 WAU
Method: Owner-driven + local marketing
Approach:
1. Owners promote to existing customers
2. Local social media (area-specific groups)
3. Flyers in apartments/societies
4. "Check your water quality" campaign
```

**Month 3-6: Hardware Sales**
```
Target: 50 hardware installations
Method: Warm leads from free tier
Approach:
1. Identify high-engagement plant owners
2. Offer pilot at discounted price (₹15,000)
3. Document ROI (labor savings)
4. Use success stories for next sales
```

### Phase 2: Expansion (City 1 Depth + City 2)

**Month 6-12:**
```
City 1:
- 300+ plants listed
- 100+ with hardware
- Delivery launched
- 5,000+ app users

City 2:
- Repeat Phase 1 playbook
- Learnings applied (faster execution)
- Target: 100 plants, 50 hardware in 3 months
```

### Channel Strategy

| Channel | Purpose | Cost |
|---------|---------|------|
| **Founder Sales** | Initial plant onboarding | Time only |
| **Owner Referrals** | Plant-to-plant growth | Free hardware discount |
| **Consumer Word-of-Mouth** | App downloads | ₹0 (organic) |
| **Local Facebook/Instagram** | Area-specific targeting | ₹5,000/month |
| **Apartment Partnerships** | Bulk user acquisition | Revenue share |
| **PR/Media** | Credibility + awareness | ₹0-20,000 |

---

## 9. Scaling Playbook

### City Expansion Model

```
City Maturity Stages:

STAGE 1: Seeding (Month 1-2)
├── 50-100 free listings
├── 500 app downloads
├── 1 person on ground
└── Investment: ₹50,000

STAGE 2: Traction (Month 2-4)
├── 200+ listings
├── 2,000 app downloads
├── 20+ hardware sales
├── 1-2 people on ground
└── Investment: ₹2,00,000

STAGE 3: Maturity (Month 4-8)
├── 400+ listings
├── 10,000 app downloads
├── 100+ hardware installations
├── Delivery operational
├── Profitable at city level
└── Investment: ₹5,00,000

STAGE 4: Expansion (Month 8+)
├── Expand to adjacent verticals (EV)
├── Team of 3-5 for city operations
├── Self-sustaining growth
└── Net positive cash flow
```

### Scaling Milestones

| Milestone | Trigger | Action |
|-----------|---------|--------|
| 100 plants (free) | Demand validated | Launch hardware sales |
| 50 hardware units | Hardware validated | Expand to City 2 |
| ₹50L MRR | Revenue validated | Raise seed round (optional) |
| 3 cities mature | Model proven | Aggressive expansion |
| 10 cities | Scale achieved | Add new vertical (EV) |

---

## 10. Financial Projections

### Year 1 Projections

| Quarter | Plants (Free) | Hardware Sold | GTV | Revenue |
|---------|---------------|---------------|-----|---------|
| Q1 | 100 | 10 | ₹5L | ₹2.1L |
| Q2 | 250 | 40 | ₹25L | ₹9L |
| Q3 | 500 | 80 | ₹60L | ₹18L |
| Q4 | 800 | 120 | ₹1.2Cr | ₹32L |
| **Year 1** | **800** | **250** | **₹2.1Cr** | **₹61L** |

**Revenue Breakdown (Year 1):**
- Hardware sales (250 × ₹20,000): ₹50,00,000
- Transaction fees (2.5% of GTV): ₹5,25,000
- Delivery (Q3-Q4): ₹3,00,000
- Subscriptions: ₹2,75,000
- **Total: ₹61,00,000**

### Year 2 Projections (2 Cities + EV Launch)

| Metric | Target |
|--------|--------|
| Plants Listed | 2,000 |
| Hardware Installed | 600 |
| EV Stations | 50 |
| Monthly GTV | ₹1.5 Cr |
| Annual Revenue | ₹2.5 Cr |
| Team Size | 15 |

### Year 3 Projections (5 Cities + Multi-Vertical)

| Metric | Target |
|--------|--------|
| Water Plants | 5,000 |
| EV Stations | 200 |
| Petrol Pumps (discovery) | 1,000 |
| Monthly GTV | ₹5 Cr |
| Annual Revenue | ₹8 Cr |
| Gross Margin | 60% |
| Team Size | 40 |

### Path to Profitability

```
Breakeven Analysis:

Fixed Costs (Monthly):
- Team (5 people): ₹3,00,000
- Server/Infrastructure: ₹30,000
- Office/Operations: ₹50,000
- Marketing: ₹50,000
- Total Fixed: ₹4,30,000

Variable Costs:
- Hardware COGS: 40% of hardware revenue
- Delivery costs: 60% of delivery revenue
- Payment gateway: 2% of GTV

Breakeven requires:
- ~₹6,00,000 monthly revenue
- OR 30 hardware units/month + ₹30L GTV

Expected breakeven: Month 10-12
```

---

## 11. Risk Analysis

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Hardware reliability issues | Medium | High | Extensive testing, warranty support |
| Connectivity failures | Medium | Medium | Offline mode, auto-retry |
| Payment integration issues | Low | High | Multiple payment providers |
| App crashes/bugs | Medium | Medium | Thorough QA, crash monitoring |

### Market Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Low owner adoption | Medium | High | Free tier, proven ROI, referral incentives |
| Low consumer adoption | Medium | High | Owner-driven distribution, local marketing |
| Price sensitivity | High | Medium | Focus on value (savings), not premium pricing |
| Competition from big players | Low | High | Move fast, build moat, consider acquisition |

### Operational Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Installation/support scaling | Medium | Medium | Train local technicians, video guides |
| Cash flow management | Medium | High | Hardware deposits, quick payment cycles |
| Team burnout | Medium | Medium | Hire ahead of growth, clear roles |

### Regulatory Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Water quality regulations | Low | Medium | Work with licensed plants only |
| Payment regulations | Low | Medium | Use licensed payment gateways |
| Fuel dispensing regulations | Medium | High | Partner with oil companies, get approvals |

---

## 12. Team & Resources

### Current Team (Bootstrapped)

| Role | Person | Responsibility |
|------|--------|----------------|
| CEO / Product | Co-founder 1 | Strategy, product decisions, B2B sales |
| CTO / Engineering | Co-founder 2 | App development, hardware integration |
| Operations / Sales | Co-founder 3 | Plant onboarding, support, logistics |

### Hiring Plan

| Role | When | Monthly Cost |
|------|------|--------------|
| Full-stack Developer | Month 2 | ₹60,000 |
| Sales Executive (City 1) | Month 3 | ₹30,000 |
| Hardware Technician | Month 4 | ₹25,000 |
| Sales Executive (City 2) | Month 6 | ₹30,000 |
| Customer Support | Month 6 | ₹20,000 |

### Resource Requirements (Year 1)

| Category | Amount | Notes |
|----------|--------|-------|
| Development | ₹5,00,000 | Tools, hosting, APIs |
| Hardware R&D | ₹3,00,000 | Prototypes, testing |
| Hardware Inventory | ₹5,00,000 | Initial stock (50 units) |
| Marketing | ₹2,00,000 | Local campaigns |
| Operations | ₹3,00,000 | Office, travel, misc |
| Salaries | ₹15,00,000 | Team of 5 average |
| **Total Year 1** | **₹33,00,000** | |

### Funding Strategy

**Option A: Stay Bootstrapped**
- Slower growth, maintain control
- Hardware sales fund operations
- Break even by Month 12
- Expand 1 city at a time

**Option B: Raise Seed (₹50L-1Cr)**
- Faster expansion (3 cities in Year 1)
- Hire faster, market more aggressively
- Higher burn, higher growth
- Raise when City 1 is proven (Month 6)

**Recommendation:** Prove model in City 1 bootstrapped, then decide.

---

## 13. Success Metrics

### North Star Metric

**Monthly Gross Transaction Value (GTV)** — Total value of transactions through our platform

### Key Metrics by Phase

**V1 (Discovery):**
| Metric | Target |
|--------|--------|
| Plants listed | 100 |
| App downloads | 1,000 |
| Weekly Active Users | 200 |
| App rating | 4.0+ |

**V2 (Hardware):**
| Metric | Target |
|--------|--------|
| Hardware units sold | 50 |
| Hardware uptime | 99% |
| Transactions per unit/day | 50+ |
| Owner NPS | 40+ |

**V3 (Delivery):**
| Metric | Target |
|--------|--------|
| Deliveries per month | 500 |
| Delivery NPS | 40+ |
| Subscription conversion | 15% |
| Repeat delivery rate | 60% |

**V4+ (Ecosystem):**
| Metric | Target |
|--------|--------|
| Cross-vertical usage | 20% |
| Points redemption rate | 50% |
| Monthly Active Users | 50,000 |
| Revenue per user | ₹50/month |

### Tracking Dashboard

```
DAILY:
- Transactions count & value
- App opens
- New user signups
- Hardware alerts

WEEKLY:
- WAU / DAU ratio
- Plant onboarding
- Conversion rates
- Support tickets

MONTHLY:
- Revenue (all streams)
- Unit economics
- City-level P&L
- Cohort retention
```

---

## 14. Long-Term Vision

### 5-Year Vision

> FlowGrid becomes India's default infrastructure for self-service utilities — the "UPI of physical services." Any utility that flows (water, fuel, electricity) is discovered, paid for, and dispensed through our platform.

### Market Position (Year 5)

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLOWGRID ECOSYSTEM (2031)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────┐  │
│  │   WATER     │ │     EV      │ │    FUEL     │ │   MORE    │  │
│  │   50,000    │ │   5,000     │ │   10,000    │ │  Milk,Gas │  │
│  │   plants    │ │  stations   │ │   pumps     │ │  Grocery  │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └───────────┘  │
│                                                                 │
│                    ┌─────────────────┐                          │
│                    │  10M+ USERS     │                          │
│                    │  ₹500Cr GTV/yr  │                          │
│                    │  ₹50Cr Revenue  │                          │
│                    └─────────────────┘                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                 FLOWGRID POINTS                         │    │
│  │    Universal utility currency accepted everywhere       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Potential Outcomes

| Outcome | Path | Likelihood |
|---------|------|------------|
| **IPO** | Scale to ₹100Cr revenue, profitability | Low (5+ years) |
| **Acquisition** | Acquired by Reliance, Tata, or foreign player | Medium |
| **Profitable SMB** | Stay bootstrapped, ₹10-20Cr revenue | High |
| **Pivot** | Core thesis wrong, pivot to adjacent market | Low-Medium |

### Exit Scenarios

**Strategic Acquirers:**
- Reliance Jio (JioMart, EV ecosystem)
- Tata (Tata Power EV, retail)
- Amazon India (delivery infrastructure)
- International: Shell, BP (fuel + EV transition)

**Acquisition Value Drivers:**
- User base and transaction data
- Hardware deployment capability
- B2B relationships with plant/station owners
- Ecosystem lock-in

---

## Appendix

### A. Competitive Analysis Detail

*(To be expanded with specific competitor research)*

### B. Technical Architecture Overview

*(To be created during development)*

### C. Legal & Compliance Checklist

- [ ] Company registration
- [ ] GST registration
- [ ] Payment gateway compliance
- [ ] Data privacy policy
- [ ] Terms of service
- [ ] Water quality disclaimers
- [ ] Hardware warranty terms

### D. References

- India water purifier market report
- EV charging infrastructure data
- Petrol retail regulations
- UPI transaction growth data

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Jan 2026 | Initial vision document |

---

*This is a living document. Update quarterly based on learnings and market changes.*
