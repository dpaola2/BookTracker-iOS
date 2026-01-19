# Reader iOS - Product Requirements Document

> Current functionality as of January 2026

---

## Overview

Reader iOS is a native SwiftUI companion app for the Reader book tracking service. Users log in with their Reader account and view their book shelves on iPhone.

---

## User Personas

**Primary User**: Existing Reader web users who want mobile access to their book library while browsing bookstores or discussing books with friends.

---

## Features

### 1. User Authentication

| Capability | Description |
|------------|-------------|
| Login | Email/password authentication against Reader API |
| Persistent Session | Credentials stored in Keychain |
| Logout | Clear credentials, return to login |

### 2. Shelves List

| Capability | Description |
|------------|-------------|
| View Shelves | List all user's shelves |
| Book Counts | Display number of books per shelf |
| Pull to Refresh | Reload shelf data from server |
| Loading State | Spinner while fetching |
| Error Handling | Retry option on failure |

---

## Current Limitations

The following features are **not yet implemented**:

| Feature | Status |
|---------|--------|
| Shelf Detail View | Planned - tap shelf to see books |
| Book Detail View | Planned - tap book to see details |
| Add/Edit Books | Not planned for v1 |
| Search | Not planned for v1 |
| Offline Mode | Not supported |
| iPad Support | Not optimized |

---

## User Flows

### Login Flow

```
App Launch
    │
    ▼
┌─────────────────┐
│ Check Keychain  │
└─────────────────┘
    │
    ├─── Has credentials ───▶ Shelves List
    │
    └─── No credentials ───▶ Login Screen
                                   │
                                   ▼
                            Enter email/password
                                   │
                                   ▼
                            POST /api/v1/sessions
                                   │
                                   ├─── Success ───▶ Store in Keychain ───▶ Shelves List
                                   │
                                   └─── Failure ───▶ Show error message
```

### Shelves View Flow

```
Shelves List appears
    │
    ▼
GET /api/v1/shelves
    │
    ├─── Success ───▶ Display shelves with counts
    │
    ├─── 401 ───▶ Session expired ───▶ Logout ───▶ Login Screen
    │
    └─── Error ───▶ Show error with retry button
```

---

## Non-Functional Requirements

| Requirement | Implementation |
|-------------|----------------|
| iOS Version | iOS 17+ |
| Authentication | Keychain storage |
| Network | Online-only, no caching |
| Data Freshness | Fetch on every screen load |

---

## Out of Scope (Current Version)

- Creating or editing books/shelves
- ISBN barcode scanning
- Cover image display
- Book search
- Offline reading list
- Push notifications
- Apple Watch support
- Widgets
