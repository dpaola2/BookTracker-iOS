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
| Navigate to Shelf | Tap shelf to view books |
| Pull to Refresh | Reload shelf data from server |
| Loading State | Spinner while fetching |
| Error Handling | Retry option on failure |

### 3. Shelf Detail View

| Capability | Description |
|------------|-------------|
| View Books in Shelf | List books belonging to selected shelf |
| Book Summary | Display title, author for each book |
| Navigate to Book | Tap book to view details |
| Loading State | Spinner while fetching |
| Error Handling | Retry option on failure |

**Note:** Requires `GET /api/v1/shelves/:id` backend endpoint (in progress).

### 4. Book Detail View

| Capability | Description |
|------------|-------------|
| View Book Details | Title, author, ISBN, shelf name |
| Cover Image | Display book cover (if available) |
| Comments | Display book notes/review |
| Loading State | Spinner while fetching |
| Error Handling | Retry option on failure |

**Note:** Requires `GET /api/v1/books/:id` backend endpoint (in progress).

---

## Current Limitations

| Feature | Status |
|---------|--------|
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
    │                        │
    │                        ▼ (tap shelf)
    │                   Shelf Detail View
    │
    ├─── 401 ───▶ Session expired ───▶ Logout ───▶ Login Screen
    │
    └─── Error ───▶ Show error with retry button
```

### Shelf Detail Flow

```
Shelf Detail View appears
    │
    ▼
GET /api/v1/shelves/:id
    │
    ├─── Success ───▶ Display books in shelf
    │                        │
    │                        ▼ (tap book)
    │                   Book Detail View
    │
    ├─── 401 ───▶ Session expired ───▶ Logout
    │
    └─── Error ───▶ Show error with retry button
```

### Book Detail Flow

```
Book Detail View appears
    │
    ▼
GET /api/v1/books/:id
    │
    ├─── Success ───▶ Display book info + cover + comments
    │
    ├─── 401 ───▶ Session expired ───▶ Logout
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
