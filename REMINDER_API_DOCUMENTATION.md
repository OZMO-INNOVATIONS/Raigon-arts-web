# RAIGON ART - Complete Reminders Management API Specification
**Version:** 2.1.0 (Comprehensive Production Edition)  
**REST API Base URL (Production):** `https://raigon-arts-api-1a3z.onrender.com/api/v1`  
**REST API Base URL (Local):** `http://localhost:5001/api/v1`  
**Supabase REST URL:** `https://nhqewkbztfmlophtzqmk.supabase.co/rest/v1/reminders`  
**Authentication:** Optional Bearer JWT Token (`Authorization: Bearer <token>`) & Supabase API Key (`apikey: <key>`)  
**Target Clients:** Raigon Art Mobile App (`raigon_app`), Web Client (`raigon_art`), and Backend Cron Scheduler  

---

## 1. System Overview & Dual-Persistence Architecture

The **Reminders Management System** enables workshop staff, artisans, and administrators to schedule, track, and automate follow-ups for customer framing orders, previews, balance payments, and custom workshop tasks.

### Architecture Highlights
```
┌────────────────────────────┐      ┌────────────────────────────┐
│   Flutter Mobile App       │      │   Flutter Web Application  │
│   (raigon_app)             │      │   (raigon_art)             │
└─────────────┬──────────────┘      └─────────────┬──────────────┘
              │                                   │
              ├───────────────────────────────────┤
              ▼                                   ▼
┌────────────────────────────────────────────────────────────────┐
│                   Dual-Persistence Flow                        │
├───────────────────────────────┬────────────────────────────────┤
│  1. REST API (Render Node.js) │  2. Direct Supabase PostgREST  │
│     POST/GET/PATCH/DELETE     │     Realtime & Direct Queries  │
│     /api/v1/reminders         │     /rest/v1/reminders         │
├───────────────────────────────┴────────────────────────────────┤
│  3. Offline-First Resilience (SharedPreferences Local Cache)   │
└───────────────────────────────┬────────────────────────────────┘
                                ▼
┌────────────────────────────────────────────────────────────────┐
│               PostgreSQL Database (Supabase Cloud)             │
│   Table: public.reminders (RLS Enabled, Indexed, Auto-Purge)   │
└────────────────────────────────────────────────────────────────┘
```

1. **Dual Synchronization**: Reads and writes sync with both the high-level Node.js REST API and Supabase Cloud DB.
2. **Offline-First Resilience**: If the device loses internet connectivity, reminders are cached locally in `SharedPreferences` and reconciled upon reconnection.
3. **Automated Server Scheduler**: A background worker (`ReminderScheduler`) runs every 60 seconds on the server, detecting due/overdue reminders and triggering alerts without requiring apps to stay open.
4. **Isolated Badge Counting**: Completed reminders are excluded from indicator badges (Bottom Bar "More", Sidebar, and "All" tab) to prevent cluttering daily task counts.

---

## 2. Database Schema (PostgreSQL / Supabase DDL)

The `public.reminders` table is deployed on Supabase project `nhqewkbztfmlophtzqmk`.

```sql
-- ============================================================================
-- RAIGON ART: Reminders Table Schema & Indexes
-- Project: nhqewkbztfmlophtzqmk
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.reminders (
    id VARCHAR(100) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    customer_name VARCHAR(150) NOT NULL,
    customer_id VARCHAR(100) DEFAULT '',
    order_id VARCHAR(100) DEFAULT '',
    description TEXT DEFAULT '',
    reminder_date VARCHAR(50) NOT NULL,          -- Format: YYYY-MM-DD (or ISO8601 string)
    reminder_time VARCHAR(50) DEFAULT '10:00 AM', -- Format: HH:mm or hh:mm a
    assigned_staff VARCHAR(150) DEFAULT 'Admin',
    priority VARCHAR(50) DEFAULT 'medium',       -- 'low' | 'medium' | 'high' | 'urgent'
    status VARCHAR(50) DEFAULT 'pending',        -- 'pending' | 'completed' | 'overdue'
    is_completed BOOLEAN DEFAULT false,          -- Syncs with status = 'completed'
    completed_at VARCHAR(100) DEFAULT '',        -- ISO8601 timestamp
    completed_by VARCHAR(150) DEFAULT '',        -- Staff / Admin identifier
    notification_triggered BOOLEAN DEFAULT false,
    created_by VARCHAR(150) DEFAULT 'Admin',
    phone VARCHAR(50) DEFAULT '',
    region VARCHAR(100) DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_reminders_date ON public.reminders (reminder_date);
CREATE INDEX IF NOT EXISTS idx_reminders_status ON public.reminders (status);
CREATE INDEX IF NOT EXISTS idx_reminders_is_completed ON public.reminders (is_completed);
CREATE INDEX IF NOT EXISTS idx_reminders_customer_id ON public.reminders (customer_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

-- Permissive Policies for Authenticated & Anon Access
DROP POLICY IF EXISTS "Allow full access for authenticated" ON public.reminders;
CREATE POLICY "Allow full access for authenticated" 
    ON public.reminders FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow full access for anon" ON public.reminders;
CREATE POLICY "Allow full access for anon" 
    ON public.reminders FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow full access for service_role" ON public.reminders;
CREATE POLICY "Allow full access for service_role" 
    ON public.reminders FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Grants
GRANT ALL ON TABLE public.reminders TO anon, authenticated, service_role, postgres;

-- Reload Schema Cache in PostgREST
NOTIFY pgrst, 'reload schema';
```

---

## 3. REST API Endpoints Specification

### 3.1 Get Reminder Summary & Statistics
Retrieves active, due, today, upcoming, overdue, and completed counts.

* **Method:** `GET`
* **URL:** `/api/v1/reminders/summary/stats`
* **Headers:**  
  `Content-Type: application/json`  
  `Authorization: Bearer <token>` *(optional)*
* **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "all": 8,
    "today": 2,
    "upcoming": 4,
    "overdue": 1,
    "completed": 1,
    "dueCount": 3
  }
}
```

---

### 3.2 List Reminders (with Filters, Search & Pagination)
Lists reminders filtered by status tier, search query, priority, staff, or customer.

* **Method:** `GET`
* **URL:** `/api/v1/reminders`
* **Query Parameters:**
  | Parameter | Type | Default | Description |
  | :--- | :--- | :--- | :--- |
  | `filter` | string | `all` | `all`, `today`, `upcoming`, `overdue`, `completed` |
  | `search` | string | `""` | Search in title, customerName, customerId, phone |
  | `priority` | string | `""` | `low`, `medium`, `high`, `urgent` |
  | `assignedStaff` | string | `""` | Staff name |
  | `customerId` | string | `""` | Customer identifier |
  | `page` | integer | `1` | Page number |
  | `limit` | integer | `50` | Maximum items per page (max 100) |
  | `sortBy` | string | `reminderDate` | `reminderDate`, `priority`, `createdAt` |
  | `sortOrder` | string | `asc` | `asc` or `desc` |

* **Response (200 OK):**
```json
{
  "success": true,
  "meta": {
    "total": 1,
    "page": 1,
    "limit": 50,
    "totalPages": 1,
    "stats": {
      "all": 3,
      "today": 1,
      "upcoming": 1,
      "overdue": 1,
      "completed": 0,
      "dueCount": 2
    }
  },
  "data": [
    {
      "id": "REM-1793433664393",
      "title": "Confirm Frame Preview Material",
      "customerName": "Ananthu Krishnan",
      "customerId": "RA-1001",
      "orderId": "RA-1001",
      "description": "Call customer regarding teak frame corner finish.",
      "reminderDate": "2026-11-05",
      "reminderTime": "14:30",
      "assignedStaff": "Workshop Staff",
      "priority": "high",
      "status": "pending",
      "isCompleted": false,
      "completedBy": "",
      "completedAt": "",
      "notificationTriggered": false,
      "phone": "9876543210",
      "region": "South Region",
      "createdAt": "2026-10-31T08:00:00.000Z",
      "updatedAt": "2026-10-31T08:00:00.000Z"
    }
  ]
}
```

---

### 3.3 Get Reminder by ID
Retrieves details of a single reminder.

* **Method:** `GET`
* **URL:** `/api/v1/reminders/:id`
* **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "REM-1793433664393",
    "title": "Confirm Frame Preview Material",
    "customerName": "Ananthu Krishnan",
    "customerId": "RA-1001",
    "orderId": "RA-1001",
    "description": "Call customer regarding teak frame corner finish.",
    "reminderDate": "2026-11-05",
    "reminderTime": "14:30",
    "assignedStaff": "Workshop Staff",
    "priority": "high",
    "status": "pending",
    "isCompleted": false,
    "phone": "9876543210",
    "region": "South Region",
    "createdAt": "2026-10-31T08:00:00.000Z",
    "updatedAt": "2026-10-31T08:00:00.000Z"
  }
}
```
* **Response (404 Not Found):**
```json
{
  "success": false,
  "message": "Reminder with ID REM-999 not found."
}
```

---

### 3.4 Create Reminder
Creates a new reminder. Supports both `YYYY-MM-DD` and full ISO8601 date inputs.

* **Method:** `POST`
* **URL:** `/api/v1/reminders`
* **Request Body (`application/json`):**
```json
{
  "id": "REM-1793433664393",
  "title": "Acrylic Glass Verification",
  "customerName": "Deepa Nair",
  "customerId": "RA-1002",
  "orderId": "RA-1002",
  "description": "Verify anti-reflective acrylic glass cut with workshop artisan.",
  "reminderDate": "2026-11-04",
  "reminderTime": "11:00 AM",
  "priority": "high",
  "assignedStaff": "Admin",
  "phone": "9998887776",
  "region": "Central Hub"
}
```
* **Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "REM-1793433664393",
    "title": "Acrylic Glass Verification",
    "customerName": "Deepa Nair",
    "customerId": "RA-1002",
    "orderId": "RA-1002",
    "description": "Verify anti-reflective acrylic glass cut with workshop artisan.",
    "reminderDate": "2026-11-04",
    "reminderTime": "11:00 AM",
    "assignedStaff": "Admin",
    "priority": "high",
    "status": "pending",
    "isCompleted": false,
    "phone": "9998887776",
    "region": "Central Hub",
    "createdAt": "2026-10-31T08:05:00.000Z",
    "updatedAt": "2026-10-31T08:05:00.000Z"
  }
}
```

---

### 3.5 Update Reminder / Mark as Completed / Reopen
Updates reminder details. When `status: "completed"` or `isCompleted: true` is passed, the server automatically sets `completedBy` and `completedAt`.

* **Method:** `PATCH` or `PUT`
* **URL:** `/api/v1/reminders/:id`

#### A. Marking as Completed:
* **Request Body:**
```json
{
  "status": "completed",
  "completedBy": "Workshop Staff"
}
```
* **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "REM-1793433664393",
    "status": "completed",
    "isCompleted": true,
    "completedBy": "Workshop Staff",
    "completedAt": "2026-10-31T08:10:00.000Z",
    "updatedAt": "2026-10-31T08:10:00.000Z"
  }
}
```

#### B. Reopening a Completed Reminder:
* **Request Body:**
```json
{
  "status": "pending",
  "isCompleted": false
}
```
* **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "REM-1793433664393",
    "status": "pending",
    "isCompleted": false,
    "completedBy": "",
    "completedAt": "",
    "updatedAt": "2026-10-31T08:15:00.000Z"
  }
}
```

---

### 3.6 Delete Reminder
Deletes a reminder permanently across Supabase, REST DB, and local cache.

* **Method:** `DELETE`
* **URL:** `/api/v1/reminders/:id`
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Reminder REM-1793433664393 deleted successfully."
}
```

---

## 4. Direct Supabase PostgREST API Endpoints

Clients may directly query Supabase PostgREST via `https://nhqewkbztfmlophtzqmk.supabase.co/rest/v1`:

| Operation | Method | Endpoint URL | Required Headers |
| :--- | :--- | :--- | :--- |
| **Fetch All Reminders** | `GET` | `/rest/v1/reminders?select=*&order=reminder_date.asc` | `apikey`, `Authorization: Bearer <key>` |
| **Filter Active Only** | `GET` | `/rest/v1/reminders?is_completed=eq.false&select=*` | `apikey`, `Authorization: Bearer <key>` |
| **Filter Completed** | `GET` | `/rest/v1/reminders?is_completed=eq.true&select=*` | `apikey`, `Authorization: Bearer <key>` |
| **Insert / Upsert** | `POST` | `/rest/v1/reminders` | `apikey`, `Authorization: Bearer <key>`, `Prefer: resolution=merge-duplicates` |
| **Mark Completed** | `PATCH` | `/rest/v1/reminders?id=eq.{id}` | `apikey`, `Authorization: Bearer <key>` |
| **Delete** | `DELETE` | `/rest/v1/reminders?id=eq.{id}` | `apikey`, `Authorization: Bearer <key>` |

---

## 5. Render Production Deployment & Environment Settings

### 5.1 IPv4 Connection Pooler Setup (Resolves `ENETUNREACH`)
Direct connections to Supabase PostgreSQL on port 5432 resolve to IPv6 on Render free tier, throwing `connect ENETUNREACH 2406:da14:...`.

To resolve this permanently, set the following environment variable in the **Render Dashboard -> Environment**:

```env
# Supabase IPv4 Pooler URL (Region: ap-northeast-1, Port: 6543)
DATABASE_URL=postgresql://postgres.[PROJECT_REF]:[YOUR-PASSWORD]@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres

# Supabase API Configuration
SUPABASE_URL=https://[PROJECT_REF].supabase.co
SUPABASE_ANON_KEY=[YOUR-SUPABASE-ANON-KEY]
SUPABASE_SERVICE_ROLE_KEY=[YOUR-SUPABASE-SERVICE-ROLE-KEY]
```

---

## 6. Client Application Integration Guidelines

### 6.1 Reminder Status Life Cycle
```
[Create Reminder] ──► PENDING (Future date)
                         │
                         ├─► DUE TODAY (reminder_date == today)
                         │
                         ├─► OVERDUE (reminder_date < today)
                         │
                         ▼
                  [Mark Completed] ──► COMPLETED (Excluded from Active Badges)
                         │
                         ▼
                  [Reopen] ──────────► PENDING / DUE TODAY / OVERDUE
```

### 6.2 Badge Indicator Rule
* **Bottom Bar ("More")**: Shows `activeCount` (`!r.isCompleted`). When 0, the badge is hidden.
* **Sidebar ("Reminders")**: Shows `dueCount > 0 ? dueCount : (activeCount > 0 ? activeCount : null)`.
* **Reminders Screen ("All" Tab)**: Shows `activeCount`. Completed reminders are displayed under the separate **Completed** tab.
