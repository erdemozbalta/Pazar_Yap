# Pazar Yap

**Local Open-Air Market Delivery Platform**

<p align="center">
  <a href="./README.md"><img src="https://img.shields.io/badge/Language-Türkçe-E31E24?style=for-the-badge" alt="Türkçe" /></a>
  <a href="./README_EN.md"><img src="https://img.shields.io/badge/Language-English-00247D?style=for-the-badge" alt="English" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Prisma-2D3748?style=for-the-badge&logo=prisma&logoColor=white" alt="Prisma" />
  <img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL" />
  <img src="https://img.shields.io/badge/Express.js-000000?style=for-the-badge&logo=express&logoColor=white" alt="Express" />
</p>

Pazar Yap is an end-to-end ordering and delivery platform that brings fresh and affordable produce from local open-air markets into the digital world, allowing customers to order directly to their doorsteps.

---

## Table of Contents

- [About the Project](#about-the-project)
- [Problem and Motivation](#problem-and-motivation)
- [Target Audience](#target-audience)
- [Features](#features)
- [Application Flow](#application-flow)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Database Structure](#database-structure)
- [API Structure](#api-structure)
- [Installation and Setup](#installation-and-setup)
- [Project Structure](#project-structure)
- [Security](#security)
- [License](#license)

---

## About the Project

Pazar Yap is a full-stack application that transforms traditional open-air market shopping into a mobile platform. The system manages four distinct user roles within a single application:

- **Customer**: Views nearby active open-air markets, compares products across vendor stalls, creates a cart, and places orders.
- **Courier**: Accepts orders, visits the market to collect items from vendor stalls, and delivers them to the customer.
- **Market Employee**: Enters real-time field data regarding prices, units, and stall photos to keep product listings accurate and live.
- **Admin**: Monitors and manages the entire operational lifecycle through a centralized administrative dashboard.

The application is built with Flutter, supporting both Android and iOS platforms. The server side is developed with Node.js/Express.js and TypeScript, utilizing MySQL as the database and Prisma as the ORM.

---

## Problem and Motivation

In Turkey, local open-air markets offer a vital alternative to supermarkets regarding produce freshness and price advantages. However, due to modern busy lifestyles, physical access difficulties, and time constraints, many consumers are unable to benefit from these markets.

Existing grocery delivery apps operate out of supermarket warehouses, failing to offer true market freshness or open-air market pricing.

**Pazar Yap was designed to bridge this gap:**

- Items are picked directly from open-air market vendor stalls active on that day, not from static supermarket warehouses.
- Couriers physically visit the market and gather products stall by stall.
- Prices reflect genuine market prices without added warehouse, distribution, or shelf overhead.
- Supports digital transformation for local market vendors.
- Offers independent couriers flexible working hours and a fair earnings model.

---

## Target Audience

| Segment | Challenge | Solution |
|---------|-----------|----------|
| **Customers** | Unable to visit markets due to busy schedules, age, or mobility constraints | Order fresh produce directly from local market stalls at genuine market prices from home |
| **Couriers** | Seeking fair and transparent earnings with flexible hours | Availability toggle with dynamic distance- and weight-tiered compensation models |
| **Market Vendors** | Customer reach limited strictly to physical market visitors | Digitally list stall products via dedicated field data employees |

---

## Features

### Customer Module

- **Location-based market discovery:** Uses GPS location to calculate distances via the Haversine formula, listing and sorting active local markets nearby.
- **Category navigation:** Browse 9 primary product categories: Fruits, Vegetables, Greens, Cheese & Dairy, Bakery Products, Breakfast & Jams/Honey, Olives & Delicatessen, Nuts & Legumes, Spices.
- **Stall-by-stall comparison:** Compare prices, photos, and quality ratings side-by-side for the same product across different vendor stalls in the market.
- **Cart management:** Add items by weight (kg) or unit, leave item-specific notes (e.g., "Choose firm tomatoes"), maintain separate carts per market.
- **Checkout Preview:** Transparently view subtotal, courier fee, platform service fee (5%), and total cost before order confirmation, along with estimated delivery distance in kilometers.
- **Real-time order tracking:** Track order status across 7 distinct lifecycle stages in real time.
- **Order history:** View all completed and canceled past orders complete with date, total amount, and status details.
- **Address management:** Save multiple delivery addresses (Home, Work, etc.), set default address, store latitude/longitude coordinates.
- **Notification system:** Receive in-app notifications for order status changes, system announcements, and promotions.
- **Profile management:** Edit first name, last name, email, and phone details.

### Courier Module

- **Availability control (Online/Offline toggle):** Turn availability on or off at any time. Availability cannot be turned online without selecting a market.
- **Tiered fee calculation:** Automatically calculates earnings using base fee × distance tier multiplier × weight tier multiplier. Tiers can be configured as percentage boosts or fixed TL additions.
- **Product collection checklist:** Checklist displaying which stall to pick each item from. Couriers mark each item as collected. The "Out for Delivery" button remains disabled until all items are checked, guaranteeing complete order fulfillment.
- **Status transitions:** Sequential workflow: Start Shopping → Collect Products → Out for Delivery → Delivered. Each transition is audited in the server's `OrderStatusHistory` table.
- **Earnings dashboard:** View total earnings, total completed deliveries, and average courier rating.

### Market Employee Module

- **Market assignment system:** Employees assigned to specific markets by admins can only input field data for their assigned markets.
- **Stall-based data entry:** Update product price, unit (kg/piece/bundle/pack/crate), quality rating, and stall location per vendor.
- **Photo upload:** Upload product photos directly from camera or device gallery. Base64-encoded images are processed and stored server-side (Supported formats: JPEG, PNG, WebP).

### Admin Module

- **Market management:** Define new markets, manage market name, city, district, neighborhood, full address, lat/long coordinates, operating days/hours, and market cover photos.
- **User management:** Filter and list all platform users by role, create employee accounts, toggle account active/inactive status.
- **Employee assignment:** Assign market employees to specific markets and manage existing assignments.
- **Analytics dashboard:** Monitor total orders, order details, active couriers, active markets, and platform revenue metrics.

### Shared Features (All Roles)

- **JWT session management:** Secure authentication via Access Token (15 min) and Refresh Token (7 days). Token refresh is handled seamlessly via Dio interceptor.
- **Role-based access control (RBAC):** Every API endpoint is guarded by `requireRole()` middleware.
- **Verification infrastructure:** SMS and email verification code dispatch/validation via VerificationCode model.
- **Notification infrastructure:** Send targeted notifications for status updates, announcements, and promos with read/unread tracking.
- **Location services & distance enforcement:** Location data is actively utilized across all user roles using Haversine formula calculation for GPS-based distance business rules. Customers can only view and order from nearby active markets. Couriers cannot toggle online without selecting a valid market within range. Market employees can only edit data for markets assigned by admins. Location data is strictly used for functional application purposes and never shared with third parties.

---

## Application Flow

Order lifecycle steps:

```
Stage 1 — Platform Setup (Admin)
1. Admin        → Secure login (Password + 6-digit PIN verification)
2. Admin        → Creates open-air market (Name, coordinates, active days, operating hours)
3. Admin        → Adds vendor stalls to market
4. Admin        → Creates employee account & assigns to market
5. Admin        → Creates courier account

Stage 2 — Field Data Entry (Market Employee)
1. Employee     → Selects assigned market
2. Employee     → Adds products to stalls (Name, category, unit)
3. Employee     → Inputs live prices, quality scores, and stall location
4. Employee     → Uploads product photos taken via camera or gallery
5. Employee     → Keeps prices and stock updated on market days

Stage 3 — Order Creation (Customer)
1. Customer     → Discovers active nearby open-air markets based on location
2. Customer     → Selects market, browses categories
3. Customer     → Compares prices across different stalls
4. Customer     → Adds items to cart by weight/unit, leaves item notes
5. Customer     → Confirms cart, selects delivery address
6. Customer     → Reviews checkout preview (Subtotal + Courier Fee + Service Fee)
7. Customer     → Completes payment and places order

Stage 4 — Order Acceptance & Delivery (Courier)
1. Courier      → Selects working market, toggles status Online
2. Courier      → Reviews order dispatch details (Items, distance, estimated earnings)
3. Courier      → Accepts order
4. Courier      → Arrives at market, taps "Start Shopping"
5. Courier      → Follows stall location cards to gather items stall by stall
6. Courier      → Checks off items on checklist as collected
7. Courier      → Taps "Out for Delivery" once all items are checked off
8. Courier      → Delivers to customer, taps "Delivered" (Earnings credited to courier balance)
```

**Fee Breakdown:**

- **Subtotal:** Sum of (unit price × quantity) for all cart items.
- **Courier Fee:** Calculated via `Base Fee × Distance Multiplier × Weight Multiplier`.
- **Service Fee:** 5% platform service commission applied to subtotal.

---

## Screenshots

### Auth Screens

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/auth/auth_1.png" width="250"/></td>
    <td align="center"><img src="docs/screenshots/auth/auth_2.png" width="250"/></td>
    <td align="center"><img src="docs/screenshots/auth/auth_3.png" width="250"/></td>
  </tr>
</table>

### Customer Screens

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/customer/customer_1.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_2.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_3.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/customer/customer_4.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_5.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_6.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/customer/customer_7.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_8.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_9.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/customer/customer_10.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_11.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_12.png" width="220"/></td>
  </tr>
</table>

### Courier Screens

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/courier/courier_1.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_2.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_3.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/courier/courier_4.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_5.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_6.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/courier/courier_7.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_8.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_9.png" width="220"/></td>
  </tr>
</table>

### Market Employee Screens

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/employee/employee_1.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/employee/employee_2.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/employee/employee_3.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/employee/employee_4.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/employee/employee_5.png" width="220"/></td>
  </tr>
</table>

### Admin Screens

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/admin/admin_1.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/admin/admin_2.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/admin/admin_3.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/admin/admin_4.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/admin/admin_5.png" width="220"/></td>
  </tr>
</table>

---

## Tech Stack

| Layer | Technology | Description |
|-------|------------|-------------|
| **Mobile App** | Flutter / Dart | Cross-platform Android & iOS codebase |
| **State Management** | Riverpod | Reactive state management across application |
| **Navigation** | GoRouter | Declarative URL-based routing |
| **HTTP Client** | Dio | Interceptor support, automatic token refresh, error handling |
| **Backend** | Node.js / Express.js | RESTful API server |
| **Language** | TypeScript | Type-safe server-side development |
| **ORM** | Prisma | Type-safe database queries, schema management & migrations |
| **Database** | MySQL | Relational database management system |
| **Authentication** | JWT (JSON Web Token) | Access Token (15 min) + Refresh Token (7 days) |
| **Encryption** | bcryptjs | Salt rounds: 12 one-way password hashing |
| **Validation** | Zod | Request body and parameter schema validation |
| **Security** | Helmet | HTTP security headers (XSS, clickjacking prevention) |
| **File Upload** | Multer | Multipart form-data processing |
| **Storage** | Storage Provider (Abstracted) | Local or cloud file storage integration |
| **Distance Math** | Haversine Formula | GPS coordinate distance calculation in km |
| **Unique ID** | UUID v4 | Universal unique identifiers for database records |

---

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                      │
│                                                            │
│   State: Riverpod  |  Navigation: GoRouter  |  HTTP: Dio   │
└──────────────────────────┬─────────────────────────────────┘
                           │
                           │  REST API (JSON over HTTP)
                           │
┌──────────────────────────▼─────────────────────────────────┐
│                 Node.js / Express.js Backend                │
│                                                            │
│   Lang: TypeScript  |  Auth: JWT  |  Validation: Zod       │
└──────────────────────────┬─────────────────────────────────┘
                           │
                           │  Prisma ORM
                           │
┌──────────────────────────▼─────────────────────────────────┐
│                     MySQL Database                         │
│                                                            │
│   17 tables  |  4 enums  |  Relational Data Model          │
└────────────────────────────────────────────────────────────┘
```

---

## Database Structure

Key Prisma models:

| Table | Description |
|-------|-------------|
| `users` | All platform users (Customer, Courier, Employee, Admin). Role & auth data. |
| `refresh_tokens` | JWT refresh tokens. |
| `verification_codes` | SMS and email verification codes. |
| `addresses` | Customer delivery addresses (Title, full address, coordinates). |
| `markets` | Open-air markets (Location, operating days/hours). |
| `vendors` | Market vendor stalls. |
| `product_categories` | Product categories (9 categories). |
| `products` | Base product catalog (Name, unit, category). |
| `vendor_products` | Vendor-product relation (Price, photo, quality score, stall position). |
| `courier_profiles` | Courier profiles (Availability, balance, ratings). |
| `courier_distance_tiers` | Distance compensation tiers. |
| `courier_weight_tiers` | Weight compensation tiers. |
| `carts` / `cart_items` | Active carts and cart items. |
| `orders` / `order_items` | Orders and line items (Includes picking checklist status). |
| `order_status_history` | Audit trail of order status transitions. |
| `payments` | Payment logs (Amount, status, provider ref). |
| `notifications` | In-app notifications. |
| `ratings` | Per-order customer reviews and ratings. |
| `favorites` | Favorite products per user. |
| `employee_assignments` | Market employee assignments. |

---

## API Structure

Backend provides 9 REST API modules:

| Module | Base Path | Description |
|--------|-----------|-------------|
| **Auth** | `/api/auth` | Registration, login, token refresh, password ops |
| **Users** | `/api/users` | User profile & account management |
| **Markets** | `/api/markets` | Market listing, detail, location search |
| **Products** | `/api/products` | Category, product, vendor-product management, photo uploads |
| **Cart** | `/api/cart` | Cart creation, item CRUD |
| **Orders** | `/api/orders` | Order creation, status updates, history |
| **Couriers** | `/api/couriers` | Courier profile, availability, fee tiers, earnings |
| **Admin** | `/api/admin` | Market/user/employee management, analytics |
| **Notifications** | `/api/notifications` | Notification listing, read markers |

---

## Installation and Setup

### Prerequisites

- [Node.js](https://nodejs.org/) (v18 or higher)
- [MySQL](https://dev.mysql.com/downloads/) (v8.0 or higher)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x)
- [Git](https://git-scm.com/)

### 1. Clone Repository

```bash
git clone https://github.com/jnost/Pazar_Yap.git
cd Pazar_Yap
```

### 2. Backend Setup

```bash
cd backend
npm install
```

Create `.env` file in `backend/`:

```env
PORT=3000
DATABASE_URL="mysql://root:yourpassword@localhost:3306/pazar_yap"
JWT_SECRET=strong-jwt-secret-key
JWT_REFRESH_SECRET=strong-refresh-secret-key
```

Setup database tables and seed initial data:

```bash
npx prisma db push
npx prisma db seed
```

Start server:

```bash
npx ts-node src/index.ts
```

### 3. Mobile App Setup

```bash
cd mobile
flutter pub get
flutter run
```

---

## Project Structure

```
Pazar_Yap/
├── backend/
│   ├── prisma/
│   │   ├── schema.prisma          # Database schema definition
│   │   └── seed.ts                # Initial seed script
│   ├── src/
│   │   ├── index.ts               # Express entry point
│   │   ├── config/                # Database config
│   │   ├── middleware/            # Auth, role check, validation middleware
│   │   ├── modules/               # Modules (admin, auth, cart, couriers, markets, etc.)
│   │   ├── services/              # External services (payment, storage, verification)
│   │   └── utils/                 # Utility functions (distance, fee calculations)
│   ├── package.json
│   └── tsconfig.json
├── mobile/
│   ├── lib/
│   │   ├── main.dart              # Flutter entry point
│   │   ├── app/                   # Router, theme, app config
│   │   ├── core/                  # Constants, API client, helpers
│   │   ├── features/              # Feature modules (admin, auth, cart, checkout, courier, etc.)
│   │   └── shared/                # Shared widgets and models
│   └── pubspec.yaml
├── docs/
│   └── screenshots/               # Application screenshots
├── .gitignore
├── README.md                        # Turkish documentation
├── README_EN.md                     # English documentation
└── package-lock.json
```

---

## Security

- **Password storage:** Hashed using `bcryptjs` (salt rounds: 12).
- **Token authentication:** Access Token (15 min) and Refresh Token (7 days) pairs. Auto-renewed via Dio interceptor.
- **Request validation:** Validated via Zod schemas.
- **HTTP security headers:** Protected with Helmet middleware against XSS and clickjacking.
- **Admin access control:** Requires 6-digit security PIN in addition to master password.
- **File upload security:** MIME type verification (JPEG, PNG, WebP) and 5 MB size limit.
- **Role-based access control:** Protected by `requireRole()` middleware.

---

## License

This project is not published under an open-source license. All rights reserved.

---

<p align="center">
  Copyright &copy; 2026 Erdem Özbalta. All rights reserved.<br/>
  <a href="mailto:erdemozbalta@gmail.com">erdemozbalta@gmail.com</a>
</p>
